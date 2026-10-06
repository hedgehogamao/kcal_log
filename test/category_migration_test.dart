import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/data/db.dart';

void main() {
  test('v1 food rows survive category-column migration', () async {
    final dir = await Directory.systemTemp.createTemp(
      'kcal-category-migration-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/old.sqlite';
    final old = AppDatabase.forTesting(NativeDatabase(File(path)));
    await old
        .into(old.foods)
        .insert(
          FoodsCompanion.insert(
            name: '米饭',
            kcal100: 999,
            source: const Value('builtin'),
          ),
        );
    // Recreate the v1 schema shape and version on disk before reopening.
    await old.customStatement('ALTER TABLE foods DROP COLUMN category');
    await old.customStatement('DROP TABLE food_catalogs');
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);
    final rows = await db.select(db.foods).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, '米饭');
    expect(rows.single.kcal100, 999);
    expect(rows.single.category, 'legacy');
  });
}
