import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/seed_data.dart';
import 'auto_backup.dart';
import 'providers.dart';

final backupClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final backupDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => () async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/kcal_log/automatic-backups');
  },
);

class AutoBackupState {
  const AutoBackupState({
    this.enabled = false,
    this.busy = false,
    this.items = const [],
    this.path,
    this.error,
  });
  final bool enabled, busy;
  final List<BackupInfo> items;
  final String? path, error;
}

final autoBackupProvider =
    NotifierProvider<AutoBackupController, AutoBackupState>(
      AutoBackupController.new,
    );

class AutoBackupController extends Notifier<AutoBackupState> {
  late AutoBackupService service;
  Timer? _timer, _debounce;
  StreamSubscription? _changes;
  bool _disposed = false, _active = true;
  @override
  AutoBackupState build() {
    final enabled =
        ref.read(prefsProvider).getBool('autoBackupEnabled') ?? false;
    service = AutoBackupService(
      now: ref.read(backupClockProvider),
      directory: ref.read(backupDirectoryProvider),
      export: () =>
          ref.read(dbProvider).transaction(ref.read(dbProvider).exportJson),
    )..enabled = enabled;
    ref.onDispose(() {
      _disposed = true;
      _stop();
    });
    if (enabled) {
      Future.microtask(() {
        if (!_disposed) {
          _connect();
          check();
        }
      });
    }
    return AutoBackupState(enabled: enabled);
  }

  void _stop() {
    _timer?.cancel();
    _debounce?.cancel();
    _changes?.cancel();
    _changes = null;
  }

  void _connect() {
    _stop();
    if (!service.enabled || _disposed) return;
    final db = ref.read(dbProvider);
    _changes = db
        .customSelect(
          'SELECT 1 AS snapshot_trigger',
          readsFrom: {
            db.foods,
            db.entries,
            db.profiles,
            db.weights,
            db.waters,
            db.templates,
            db.templateItems,
            db.foodCatalogs,
          },
        )
        .watch()
        .listen(
          (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(seconds: 3), () {
              check();
            });
          },
          onError: (_) {
            if (!_disposed) {
              state = AutoBackupState(
                enabled: state.enabled,
                items: state.items,
                path: state.path,
                error: 'autoBackupFailed',
              );
            }
          },
        );
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      check();
    });
  }

  void setActive(bool active) {
    _active = active;
    if (!active) {
      _debounce?.cancel();
    } else if (state.enabled) {
      check();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.busy) return;
    try {
      if (!await ref
          .read(prefsProvider)
          .setBool('autoBackupEnabled', enabled)) {
        throw StateError('Preference save failed');
      }
      if (_disposed) return;
      service.enabled = enabled;
      state = AutoBackupState(
        enabled: enabled,
        items: state.items,
        path: state.path,
      );
      if (enabled) {
        _connect();
        await check();
      } else {
        _stop();
      }
    } catch (_) {
      if (!_disposed) {
        state = AutoBackupState(
          enabled: state.enabled,
          items: state.items,
          path: state.path,
          error: 'autoBackupFailed',
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_disposed || state.busy) return;
    state = AutoBackupState(
      enabled: service.enabled,
      busy: true,
      items: state.items,
      path: state.path,
    );
    try {
      final items = await service.list(), dir = await service.directory();
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: items,
          path: dir.path,
        );
      }
    } catch (_) {
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: state.items,
          path: state.path,
          error: 'autoBackupFailed',
        );
      }
    }
  }

  Future<void> check({bool manual = false}) async {
    if (_disposed ||
        state.busy ||
        (!manual && (!service.enabled || !_active))) {
      return;
    }
    state = AutoBackupState(
      enabled: service.enabled,
      busy: true,
      items: state.items,
      path: state.path,
    );
    try {
      await service.capture(force: manual, userInitiated: manual);
      final items = await service.list(), dir = await service.directory();
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: items,
          path: dir.path,
        );
      }
    } catch (_) {
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: state.items,
          path: state.path,
          error: 'autoBackupFailed',
        );
      }
    }
  }

  Future<BackupPreview> preview(BackupInfo info) async => service.preview(
    info,
    await ref.read(dbProvider).transaction(ref.read(dbProvider).exportJson),
  );
  Future<void> restore(BackupPreview preview) async {
    if (state.busy || _disposed) {
      throw StateError('Backup operation in progress');
    }
    state = AutoBackupState(
      enabled: service.enabled,
      busy: true,
      items: state.items,
      path: state.path,
    );
    try {
      // Refuse a changed/corrupt file. The payload is re-read, never blindly trusted from the dialog.
      final payload = await service.read(preview.info);
      final db = ref.read(dbProvider);
      await db.transaction(() async {
        if (AutoBackupService.contentHash(await db.exportJson()) !=
            preview.currentHash) {
          throw StateError('Data changed since preview; review again');
        }
        final safeguard = await service.capture(
          force: true,
          userInitiated: true,
        );
        if (safeguard == null) {
          throw StateError('Pre-restore snapshot required');
        }
        await db.importJson(payload);
        await backfillBuiltInFoodCategories(db);
      });
      final items = await service.list(), dir = await service.directory();
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: items,
          path: dir.path,
        );
      }
    } catch (_) {
      if (!_disposed) {
        state = AutoBackupState(
          enabled: service.enabled,
          items: state.items,
          path: state.path,
          error: 'autoBackupFailed',
        );
      }
      rethrow;
    }
  }
}
