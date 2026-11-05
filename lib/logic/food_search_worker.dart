import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'food_search.dart';

class FoodSearchRecord {
  const FoodSearchRecord(
    this.name,
    this.brand,
    this.barcode,
    this.category,
    this.source,
    this.favorite,
    this.id,
  );
  final String name, category, source;
  final String? brand, barcode;
  final bool favorite;
  final int id;
}

class FoodSearchFailure implements Exception {
  const FoodSearchFailure(this.code);
  final String code;
  @override
  String toString() => 'FoodSearchFailure($code)';
}

class FoodSearchCancelled implements Exception {
  const FoodSearchCancelled();
}

/// The same ranking rules as the original library. Only CPU placement changes.
List<int> rankFoodSearchRecords(List<FoodSearchRecord> rows, String query) {
  final searching = query.trim().isNotEmpty;
  final matches = <(int, int)>[];
  for (var i = 0; i < rows.length; i++) {
    final f = rows[i];
    final rank = foodMatchRank(
      name: f.name,
      query: query,
      brand: f.brand,
      barcode: f.barcode,
      category: f.category,
    );
    if (rank != null) matches.add((i, rank));
  }
  int group(FoodSearchRecord f) => f.favorite
      ? 0
      : f.source == 'custom'
      ? 1
      : f.source == 'builtin'
      ? 2
      : 3;
  matches.sort((a, b) {
    if (searching) {
      final byRank = a.$2.compareTo(b.$2);
      if (byRank != 0) return byRank;
    }
    final af = rows[a.$1], bf = rows[b.$1];
    final byGroup = group(af).compareTo(group(bf));
    if (byGroup != 0) return byGroup;
    if (searching) {
      final byLength = af.name.length.compareTo(bf.name.length);
      if (byLength != 0) return byLength;
    }
    return af.source == 'builtin'
        ? af.id.compareTo(bf.id)
        : bf.id.compareTo(af.id);
  });
  return [for (final m in matches) m.$1];
}

void foodSearchWorkerEntry(SendPort reply) {
  final input = ReceivePort();
  reply.send(input.sendPort);
  input.listen((dynamic message) {
    final m = message as List;
    final id = m[0] as int;
    try {
      reply.send([
        id,
        rankFoodSearchRecords(m[1] as List<FoodSearchRecord>, m[2] as String),
      ]);
    } catch (_) {
      reply.send([id, null]);
    }
  });
}

class _SearchJob {
  _SearchJob(this.id, this.rows, this.query, this.owner);
  final int id;
  final List<FoodSearchRecord> rows;
  final String query;
  final Object? owner;
  final result = Completer<List<int>>();
  Timer? timer;
}

/// One persistent worker, one in-flight batch, a bounded pending queue. Repeated
/// queries from a subscription replace its older pending work, never spawn storms.
class FoodSearchWorker {
  FoodSearchWorker({
    this.inlineThreshold = 128,
    this.maxPending = 8,
    this.startTimeout = const Duration(seconds: 4),
    this.jobTimeout = const Duration(seconds: 8),
    this.entryPoint = foodSearchWorkerEntry,
  });
  final int inlineThreshold, maxPending;
  final Duration startTimeout, jobTimeout;
  final void Function(SendPort) entryPoint;
  final _pending = Queue<_SearchJob>();
  _SearchJob? _active;
  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _responses, _errors, _exits;
  Completer<void>? _ready;
  Timer? _startupTimer;
  bool _disposed = false;
  int _next = 0, _generation = 0;
  int get pendingCount => _pending.length;
  int get activeCount => _active == null ? 0 : 1;
  Future<List<int>> rank(
    List<FoodSearchRecord> rows,
    String query, {
    Object? owner,
  }) {
    if (_disposed) return Future.error(const FoodSearchFailure('closed'));
    if (query.length > 256) {
      return Future.error(const FoodSearchFailure('queryTooLong'));
    }
    if (rows.length <= inlineThreshold) {
      return Future.value(rankFoodSearchRecords(rows, query));
    }
    if (owner != null) {
      for (final old
          in _pending.where((j) => identical(j.owner, owner)).toList()) {
        _pending.remove(old);
        old.result.completeError(const FoodSearchCancelled());
      }
    }
    if (_pending.length >= maxPending) {
      return Future.error(const FoodSearchFailure('busy'));
    }
    final job = _SearchJob(++_next, rows, query, owner);
    _pending.add(job);
    _pump();
    return job.result.future;
  }

  void cancelOwner(Object owner) {
    for (final job
        in _pending.where((j) => identical(j.owner, owner)).toList()) {
      _pending.remove(job);
      if (!job.result.isCompleted) {
        job.result.completeError(const FoodSearchCancelled());
      }
    }
    final active = _active;
    if (active != null &&
        identical(active.owner, owner) &&
        !active.result.isCompleted) {
      active.result.completeError(const FoodSearchCancelled());
    }
  }

  void _pump() {
    if (_disposed || _active != null || _pending.isEmpty) return;
    final job = _pending.removeFirst();
    _active = job;
    () async {
      try {
        await _ensureWorker();
        if (_disposed || !identical(_active, job)) return;
        job.timer = Timer(jobTimeout, () {
          if (identical(_active, job)) {
            _failWorker(const FoodSearchFailure('timeout'));
          }
        });
        _send!.send([job.id, job.rows, job.query]);
      } catch (_) {
        if (identical(_active, job)) {
          _failWorker(const FoodSearchFailure('workerFailed'));
        }
      }
    }();
  }

  Future<void> _ensureWorker() {
    if (_send != null) return Future.value();
    if (_ready != null) return _ready!.future;
    final generation = ++_generation;
    final ready = Completer<void>();
    _ready = ready;
    _responses = ReceivePort();
    _errors = ReceivePort();
    _exits = ReceivePort();
    _responses!.listen((dynamic message) {
      if (_disposed || generation != _generation) return;
      if (message is SendPort) {
        _send = message;
        _startupTimer?.cancel();
        if (!ready.isCompleted) ready.complete();
        return;
      }
      final m = message as List;
      final job = _active;
      if (job == null || m[0] != job.id) return;
      job.timer?.cancel();
      _active = null;
      if (!job.result.isCompleted) {
        if (m[1] is List<int>) {
          job.result.complete(m[1] as List<int>);
        } else {
          job.result.completeError(const FoodSearchFailure('workerFailed'));
        }
      }
      _pump();
    });
    void failed(dynamic _) {
      if (!_disposed && generation == _generation) {
        _failWorker(const FoodSearchFailure('workerFailed'));
      }
    }

    _errors!.listen(failed);
    _exits!.listen(failed);
    _startupTimer = Timer(startTimeout, () {
      if (generation == _generation) {
        _failWorker(const FoodSearchFailure('timeout'));
      }
    });
    unawaited(
      Isolate.spawn<SendPort>(
        entryPoint,
        _responses!.sendPort,
        onError: _errors!.sendPort,
        onExit: _exits!.sendPort,
        errorsAreFatal: true,
        debugName: 'kcal-food-search',
      ).then(
        (i) {
          if (_disposed || generation != _generation) {
            i.kill(priority: Isolate.immediate);
          } else {
            _isolate = i;
          }
        },
        onError: (Object e, StackTrace s) {
          failed(e);
        },
      ),
    );
    return ready.future;
  }

  void _failWorker(Object error) {
    _generation++;
    _startupTimer?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _send = null;
    _responses?.close();
    _errors?.close();
    _exits?.close();
    _responses = null;
    _errors = null;
    _exits = null;
    final ready = _ready;
    _ready = null;
    if (ready != null && !ready.isCompleted) ready.completeError(error);
    final jobs = [?_active, ..._pending];
    _active = null;
    _pending.clear();
    for (final job in jobs) {
      job.timer?.cancel();
      if (!job.result.isCompleted) job.result.completeError(error);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _failWorker(const FoodSearchCancelled());
  }
}
