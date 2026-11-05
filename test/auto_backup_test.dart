import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup.dart';
import 'package:kcal_log/logic/auto_backup_controller.dart';
import 'package:kcal_log/logic/providers.dart';

Map<String, dynamic> payload([String name = 'original']) => {
  'app': 'kcal_log',
  'schema': 1,
  'exportedAt': DateTime.now().toIso8601String(),
  'foods': [
    {'id': 1, 'name': name, 'kcal100': 100},
  ],
  'entries': [],
  'weights': [],
  'waters': [],
  'templates': [],
  'templateItems': [],
  'foodCatalogs': [],
  'profile': null,
};
void main() {
  late Directory dir;
  late DateTime now;
  late Map<String, dynamic> data;
  late AutoBackupService service;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kcal-backup-test-');
    now = DateTime.utc(2026, 11, 4);
    data = payload();
    service = AutoBackupService(
      directory: () async => Directory('${dir.path}/managed'),
      export: () async => data,
      now: () => now,
    );
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test('disabled means no export, directory creation or file writes', () async {
    var exports = 0;
    final s = AutoBackupService(
      directory: () async => Directory('${dir.path}/off'),
      export: () async {
        exports++;
        return data;
      },
    );
    expect(await s.capture(), isNull);
    expect(exports, 0);
    expect(await Directory('${dir.path}/off').exists(), isFalse);
  });
  test('daily snapshots, changed-data interval, restart dedupe and manual snapshot while off', () async {
    service.enabled = true;
    final first = (await service.capture())!;
    expect(await service.read(first), data);
    expect(await service.capture(), isNull);
    data = payload('changed');
    now = now.add(const Duration(minutes: 14));
    expect(await service.capture(), isNull);
    now = now.add(const Duration(minutes: 1));
    expect(await service.capture(), isNotNull);
    final restarted = AutoBackupService(
      directory: service.directory,
      export: () => Future.value(data),
      now: () => now,
    )..enabled = true;
    expect(await restarted.capture(), isNull);
    now = now.add(const Duration(days: 1));
    expect(await restarted.capture(), isNotNull);
    restarted.enabled = false;
    expect(await restarted.capture(), isNull);
    expect(
      await restarted.capture(force: true, userInitiated: true),
      isNotNull,
    );
    expect((await service.list()).length, 4);
  });
  test('bounded retention ignores unrelated files and symlinks; current snapshot always retained', () async {
    service = AutoBackupService(
      directory: service.directory,
      export: () async => data,
      now: () => now,
      maxFiles: 2,
      maxTotalBytes: 5000,
    )..enabled = true;
    await service.capture(force: true);
    final root = await service.directory();
    await File('${root.path}/personal.json').writeAsString('untouched');
    if (!Platform.isWindows) {
      await Link(
        '${root.path}/kcallog-auto-20261104T000000000000Z-aaaaaaaaaaaa.json',
      ).create('${dir.path}/outside');
    }
    for (var i = 0; i < 5; i++) {
      now = now.add(const Duration(minutes: 16));
      data = payload('$i');
      await service.capture(force: true);
    }
    final all = await service.list();
    expect(all.length, 2);
    expect(all.fold<int>(0, (n, x) => n + x.bytes), lessThanOrEqualTo(5000));
    expect(
      await File('${root.path}/personal.json').readAsString(),
      'untouched',
    );
  });
  test(
    'byte limit and failed partial writes preserve previous valid snapshots',
    () async {
      service.enabled = true;
      final first = (await service.capture())!;
      final original = await first.file.readAsBytes();
      final s = AutoBackupService(
        directory: service.directory,
        export: () async => data,
        now: () => now,
        writer: (f, b) async {
          await f.writeAsBytes([1, 2]);
          throw const FileSystemException('fixture write failure');
        },
      )..enabled = true;
      await expectLater(
        s.capture(force: true),
        throwsA(isA<FileSystemException>()),
      );
      expect(await first.file.readAsBytes(), original);
      final limited = AutoBackupService(
        directory: service.directory,
        export: () async => data,
        maxFileBytes: 10,
      )..enabled = true;
      await expectLater(limited.capture(force: true), throwsFormatException);
      expect((await service.list()).length, 1);
      expect(
        (await (await service.directory()).list().toList()).where(
          (e) => e.path.endsWith('.part'),
        ),
        isEmpty,
      );
    },
  );
  test('checksum corruption refuses restore and differences compare actual row identities', () async {
    service.enabled = true;
    final first = (await service.capture())!;
    data = payload('changed');
    data['entries'] = [
      {'id': 7, 'name': 'new'},
    ];
    final preview = await service.preview(first, data);
    expect(preview.changes['foods'], (0, 1, 0));
    expect(preview.changes['entries'], (0, 0, 1));
    final raw = jsonDecode(await first.file.readAsString()) as Map;
    ((raw['payload'] as Map)['foods'] as List).first['name'] = 'tampered';
    await first.file.writeAsString(jsonEncode(raw));
    await expectLater(service.read(first), throwsFormatException);
    expect((await service.list()).single.valid, isFalse);
  });
  test('concurrent captures serialize and disabling during export prevents a write', () async {
    final pending = Completer<Map<String, dynamic>>();
    final s = AutoBackupService(
      directory: service.directory,
      export: () => pending.future,
    )..enabled = true;
    final a = s.capture(), b = s.capture();
    s.enabled = false;
    pending.complete(data);
    expect(await a, isNull);
    expect(await b, isNull);
    expect(await (await s.directory()).exists(), isFalse);
  });
  test('real DB controller opt-in, preview/cancel, safety snapshot, restore and stale-preview rejection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        backupDirectoryProvider.overrideWithValue(
          () async => Directory('${dir.path}/controller'),
        ),
      ],
    );
    try {
      await db.upsertFood(FoodsCompanion.insert(name: '原食物', kcal100: 100));
      final controller = container.read(autoBackupProvider.notifier);
      expect(container.read(autoBackupProvider).enabled, isFalse);
      await controller.setEnabled(true);
      expect(prefs.getBool('autoBackupEnabled'), isTrue);
      final first = container.read(autoBackupProvider).items.first;
      await db.upsertFood(FoodsCompanion.insert(name: '新增食物', kcal100: 200));
      final preview = await controller.preview(first);
      expect(preview.changes['foods'], (0, 0, 1));
      expect((await db.select(db.foods).get()).length, 2);
      final before = (await controller.service.list()).length;
      await controller.restore(preview);
      expect((await db.select(db.foods).get()).single.name, '原食物');
      expect((await controller.service.list()).length, before + 1);
      final newPreview = await controller.preview(first);
      await db.upsertFood(FoodsCompanion.insert(name: '预览后新增', kcal100: 50));
      await expectLater(controller.restore(newPreview), throwsStateError);
      expect((await db.select(db.foods).get()).length, 2);
      await controller.setEnabled(false);
      expect(prefs.getBool('autoBackupEnabled'), isFalse);
    } finally {
      container.dispose();
      await db.close();
    }
  });
}
