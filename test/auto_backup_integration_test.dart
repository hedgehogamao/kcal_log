import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup.dart';
import 'package:kcal_log/logic/auto_backup_controller.dart';
import 'package:kcal_log/logic/providers.dart';

void main() {
  test('actual DB changes automatically trigger snapshots; inactive and disabled do not', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('kcal-auto-trigger-');
    var now = DateTime.utc(2026, 11, 4);
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        backupDirectoryProvider.overrideWithValue(
          () async => Directory('${dir.path}/managed'),
        ),
        backupClockProvider.overrideWithValue(() => now),
      ],
    );
    try {
      final control = c.read(autoBackupProvider.notifier);
      await control.setEnabled(true);
      expect(c.read(autoBackupProvider).items.length, 1);
      now = now.add(const Duration(minutes: 16));
      await db.addWater('2026-11-04', 250);
      for (
        var i = 0;
        i < 500 && c.read(autoBackupProvider).items.length < 2;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        c.read(autoBackupProvider).items.length,
        2,
        reason: 'No manual backup call: database stream must trigger snapshot',
      );
      control.setActive(false);
      now = now.add(const Duration(minutes: 16));
      await db.addWater('2026-11-04', 250);
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      expect(c.read(autoBackupProvider).items.length, 2);
      control.setActive(true);
      for (
        var i = 0;
        i < 200 && c.read(autoBackupProvider).items.length < 3;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(c.read(autoBackupProvider).items.length, 3);
      await control.setEnabled(false);
      await db.addWater('2026-11-04', 250);
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      expect((await control.service.list()).length, 3);
      expect(prefs.getBool('autoBackupEnabled'), isFalse);
    } finally {
      c.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  });
  test('all database tables, pack ownership, historical snapshots and goals round trip exactly', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory()),
        restored = AppDatabase.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('kcal-all-backup-');
    try {
      final food = await db.upsertFood(
        FoodsCompanion.insert(
          name: '个人鸡胸肉',
          kcal100: 123,
          category: const Value('protein'),
          favorite: const Value(true),
          servingGrams: const Value(150),
        ),
      );
      await db.addEntry(
        EntriesCompanion.insert(
          date: '2026-11-03',
          meal: MealType.dinner,
          name: '当时名称',
          grams: const Value(120),
          foodId: Value(food.id),
          kcal: 147.6,
          protein: const Value(30),
        ),
      );
      await db.saveProfile(
        ProfilesCompanion(
          id: const Value(1),
          kcalGoal: const Value(1800),
          weightKg: const Value(60),
        ),
      );
      await db.addWeight('2026-11-03', 60);
      await db.addWater('2026-11-03', 500);
      await db.saveTemplate('我的餐', [(food.id, 150)]);
      for (final id in ['pack-a', 'pack-b']) {
        await db
            .into(db.foodCatalogs)
            .insert(
              FoodCatalogsCompanion.insert(
                packId: id,
                revision: 3,
                title: id,
                stateJson: '{}',
                appliedAt: DateTime.utc(2026, 11, 1),
              ),
            );
      }
      final service = AutoBackupService(
        directory: () async => Directory('${dir.path}/managed'),
        export: () => db.transaction(db.exportJson),
      )..enabled = true;
      final record = (await service.capture())!;
      final data = await service.read(record);
      await restored.importJson(data);
      final before = await db.exportJson(), after = await restored.exportJson();
      before.remove('exportedAt');
      after.remove('exportedAt');
      expect(after, before);
      final preview = await service.preview(record, {
        ...data,
        'foodCatalogs': [],
      });
      expect(preview.changes['foodCatalogs'], (2, 0, 0));
    } finally {
      await db.close();
      await restored.close();
      await dir.delete(recursive: true);
    }
  });
  test(
    'byte budget, not just version count, bounds managed snapshots',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'kcal-backup-byte-limit-',
      );
      var now = DateTime.utc(2026, 11, 4);
      try {
        final payload = {
          'app': 'kcal_log',
          'schema': 1,
          'foods': [],
          'entries': [],
          'weights': [],
          'waters': [],
          'templates': [],
          'templateItems': [],
          'profile': null,
        };
        final s = AutoBackupService(
          directory: () async => dir,
          export: () async => payload,
          now: () => now,
          maxFiles: 14,
          maxTotalBytes: 900,
        )..enabled = true;
        for (var i = 0; i < 5; i++) {
          now = now.add(const Duration(minutes: 16));
          await s.capture(force: true);
        }
        final records = await s.list();
        expect(records.length, lessThan(5));
        expect(
          records.fold<int>(0, (n, x) => n + x.bytes),
          lessThanOrEqualTo(900),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
