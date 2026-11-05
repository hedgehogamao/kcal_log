import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup.dart';
import 'package:kcal_log/logic/auto_backup_controller.dart';
import 'package:kcal_log/logic/providers.dart';

void main() {
  test('failed pre-restore write or malformed import leaves all database bytes logically unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('kcal-restore-failure-');
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        backupDirectoryProvider.overrideWithValue(() async => dir),
      ],
    );
    try {
      await db.upsertFood(FoodsCompanion.insert(name: '原始', kcal100: 100));
      final control = c.read(autoBackupProvider.notifier);
      await control.check(manual: true);
      final originalService = control.service,
          first = c.read(autoBackupProvider).items.first;
      await db.upsertFood(FoodsCompanion.insert(name: '保留新增', kcal100: 200));
      final preview = await control.preview(first);
      final before = AutoBackupService.contentHash(await db.exportJson());
      control.service = AutoBackupService(
        directory: () async => dir,
        export: () => db.transaction(db.exportJson),
        writer: (_, _) async =>
            throw const FileSystemException('fixture disk full'),
      );
      await expectLater(
        control.restore(preview),
        throwsA(isA<FileSystemException>()),
      );
      expect(AutoBackupService.contentHash(await db.exportJson()), before);
      control.service = originalService;
      final invalid = {
        ...await db.exportJson(),
        'foods': [
          {'id': 1, 'name': null, 'kcal100': 100},
        ],
      };
      final malformed = AutoBackupService(
        directory: () async => dir,
        export: () async => invalid,
      );
      final bad = (await malformed.capture(force: true, userInitiated: true))!;
      final badPreview = await control.preview(bad);
      await expectLater(control.restore(badPreview), throwsA(anything));
      expect(AutoBackupService.contentHash(await db.exportJson()), before);
      expect(
        (await originalService.list()).where((x) => x.valid).length,
        greaterThanOrEqualTo(3),
      );
    } finally {
      c.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
