import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/logic/food_search_worker.dart';

void controlledWorker(SendPort reply) {
  final input = ReceivePort();
  reply.send(input.sendPort);
  input.listen((dynamic message) {
    final m = message as List;
    if (m[2] == 'crash-fixture') throw StateError('fixture');
    reply.send([
      m[0],
      rankFoodSearchRecords(m[1] as List<FoodSearchRecord>, m[2] as String),
    ]);
  });
}

void stalledWorker(SendPort reply) {
  final input = ReceivePort();
  reply.send(input.sendPort);
  input.listen((_) {});
}

List<FoodSearchRecord> rows() => [
  for (var i = 0; i < 5000; i++)
    FoodSearchRecord(
      'Chicken breast $i',
      null,
      null,
      'protein',
      'pack',
      i == 0,
      i,
    ),
];
void main() {
  test('background ranking exactly matches canonical ordering on the real 5000 catalog', () async {
    final raw = jsonDecode(
      File('food-packs/common-foods-5000.json').readAsStringSync(),
    ) as Map;
    final foods = [
      for (final f in raw['foods'] as List)
        FoodSearchRecord(
          (f as Map)['name'] as String,
          null,
          null,
          (f['category'] as String?) ?? 'other',
          'pack',
          false,
          raw['foods'].indexOf(f) as int,
        ),
    ];
    final worker = FoodSearchWorker();
    addTearDown(worker.dispose);
    for (final q in ['jxr', 'chikcen', '水果 苹果', '']) {
      expect(await worker.rank(foods, q), rankFoodSearchRecords(foods, q));
    }
  });
  test(
    'rapid typing replaces pending requests and uses at most one active worker',
    () async {
      final worker = FoodSearchWorker();
      addTearDown(worker.dispose);
      final owner = Object();
      final results = <Future<Object?>>[];
      final data = rows();
      for (var i = 0; i < 50; i++) {
        results.add(
          worker
              .rank(data, 'Chicken $i', owner: owner)
              .then<Object?>(
                (x) => x,
                onError: (Object e) {
                  if (e is FoodSearchCancelled) return null;
                  throw e;
                },
              ),
        );
        expect(worker.activeCount, lessThanOrEqualTo(1));
        expect(worker.pendingCount, lessThanOrEqualTo(1));
      }
      final complete = await Future.wait(results);
      expect(complete.where((x) => x == null).length, 48);
      expect(complete.last, isA<List<int>>());
      expect(worker.pendingCount, 0);
      expect(worker.activeCount, 0);
    },
  );
  test(
    'queue cap rejects overload instead of starting unbounded isolates',
    () async {
      final worker = FoodSearchWorker(maxPending: 2);
      addTearDown(worker.dispose);
      final data = rows();
      final accepted = [
        for (var i = 0; i < 3; i++) worker.rank(data, 'Chicken $i'),
      ];
      await expectLater(
        worker.rank(data, 'Chicken 4'),
        throwsA(isA<FoodSearchFailure>()),
      );
      await Future.wait(accepted);
      expect(worker.pendingCount, 0);
    },
  );
  test('owner cancellation and disposal complete futures, next calls reject closed service', () async {
    final worker = FoodSearchWorker();
    final owner = Object();
    final a = worker.rank(rows(), 'Chicken', owner: owner);
    final observed = expectLater(a, throwsA(isA<FoodSearchCancelled>()));
    worker.cancelOwner(owner);
    await observed;
    worker.dispose();
    await expectLater(
      worker.rank(rows(), 'Chicken'),
      throwsA(isA<FoodSearchFailure>()),
    );
  });
  test(
    'worker exit is recoverable on the next request without restart storms',
    () async {
      final worker = FoodSearchWorker(entryPoint: controlledWorker);
      addTearDown(worker.dispose);
      await expectLater(
        worker.rank(rows(), 'crash-fixture'),
        throwsA(isA<FoodSearchFailure>()),
      );
      expect((await worker.rank(rows(), 'Chicken')).length, 5000);
      expect(worker.activeCount, 0);
    },
  );
  test(
    'stalled worker times out and fails pending jobs instead of hanging',
    () async {
      final worker = FoodSearchWorker(
        entryPoint: stalledWorker,
        jobTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(worker.dispose);
      final a = expectLater(
        worker.rank(rows(), 'Chicken'),
        throwsA(isA<FoodSearchFailure>()),
      );
      final b = expectLater(
        worker.rank(rows(), 'Chicken 2'),
        throwsA(isA<FoodSearchFailure>()),
      );
      await Future.wait([a, b]);
      expect(worker.activeCount, 0);
      expect(worker.pendingCount, 0);
    },
  );
  test('long input rejected explicitly; small inputs need no worker', () async {
    final worker = FoodSearchWorker();
    addTearDown(worker.dispose);
    await expectLater(
      worker.rank(rows(), 'a' * 257),
      throwsA(isA<FoodSearchFailure>()),
    );
    expect(
      await worker.rank([
        const FoodSearchRecord(
          '鸡胸肉',
          null,
          null,
          'protein',
          'custom',
          false,
          1,
        ),
      ], 'jxr'),
      [0],
    );
    expect(worker.activeCount, 0);
  });
}
