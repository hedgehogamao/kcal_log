import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/food_pack.dart';
import 'package:kcal_log/data/seed_data.dart';

Map<String, dynamic> item(String id, {String? name, double kcal = 100}) => {
  'id': id,
  'name': name ?? id,
  'category': 'other',
  'kcal100': kcal,
  'protein100': 1,
  'fat100': 2,
  'carb100': 10,
};
Map<String, dynamic> payload(
  int revision,
  List<Map<String, dynamic>> foods, {
  String id = 'test.pack',
}) => {
  'app': 'kcal_log.food_pack',
  'schema': 1,
  'packId': id,
  'revision': revision,
  'title': 'Test food pack',
  'foods': foods,
};
FoodPack pack(
  int revision,
  List<Map<String, dynamic>> foods, {
  String id = 'test.pack',
}) => FoodPack.parse(payload(revision, foods, id: id));

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());
  Matcher error(String code) =>
      isA<FoodPackException>().having((e) => e.code, 'code', code);

  test('strict data schema rejects code fields, backups, duplicates and invalid bounds', () {
    for (final value in [double.nan, double.infinity, -1.0, 901.0]) {
      expect(
        () => pack(1, [item('x', kcal: value)]),
        throwsA(error('packInvalid')),
      );
    }
    for (final data in [
      payload(1, []),
      payload(0, [item('x')]),
      payload(1, [item('x'), item('x')]),
      payload(1, [item('a', name: 'Food'), item('b', name: 'food')]),
      payload(1, [
        {...item('x'), 'category': 'unknown'},
      ]),
      payload(1, [
        {...item('x'), 'source': 'builtin'},
      ]),
      payload(1, [
        {...item('x'), 'protein100': 101},
      ]),
      payload(1, [
        {...item('x'), 'servingGrams': 100},
      ]),
      payload(1, [
        {...item('x'), 'servingDesc': 'one', 'servingGrams': 0},
      ]),
      {
        ...payload(1, [item('x')]),
        'script': 'not executable',
      },
      {
        ...payload(1, [item('x')]),
        'app': 'kcal_log',
      },
      {
        ...payload(1, [item('x')]),
        'schema': 99,
      },
    ]) {
      expect(() => FoodPack.parse(data), throwsA(error('packInvalid')));
    }
    expect(
      () => FoodPack.decode(Uint8List(foodPackMaxBytes + 1)),
      throwsA(error('packTooLarge')),
    );
    expect(
      () => FoodPack.decode(Uint8List.fromList([255])),
      throwsA(error('packInvalid')),
    );
    expect(
      () => pack(1, [item('x')]).foods.single.fields['name'] = 'edit',
      throwsUnsupportedError,
    );
  });

  test('preview is read-only; repeated revisions are idempotent; reorder is identical', () async {
    final loader = FoodPackLoader(db);
    final first = pack(1, [item('a'), item('b')]);
    expect((await loader.preview(first)).added, 2);
    expect(await db.foodCount(), 0);
    expect(await db.select(db.foodCatalogs).get(), isEmpty);
    expect((await loader.apply(first)).added, 2);
    expect(await db.foodCount(), 2);
    expect(
      (await loader.apply(pack(1, [item('b'), item('a')]))).current,
      isTrue,
    );
    expect(await db.foodCount(), 2);
    await expectLater(
      loader.apply(pack(1, [item('a', kcal: 120), item('b')])),
      throwsA(error('packRevisionChanged')),
    );
  });

  test('update preserves stable food id, favorites, historical snapshot and templates', () async {
    final loader = FoodPackLoader(db);
    await loader.apply(pack(1, [item('a')]));
    final original = (await db.searchFoods('a')).single;
    await db.toggleFavorite(original);
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-09-30',
        meal: MealType.lunch,
        name: original.name,
        foodId: Value(original.id),
        kcal: 100,
      ),
    );
    final template = await db.saveTemplate('Combo', [(original.id, 100)]);
    final change = await loader.apply(
      pack(2, [item('a', name: 'new name', kcal: 120)]),
    );
    expect(change.updated, 1);
    final updated = (await db.select(db.foods).get()).single;
    expect(updated.id, original.id);
    expect(updated.kcal100, 120);
    expect(updated.favorite, isTrue);
    final history = (await db.watchEntries('2026-09-30').first).single;
    expect(history.name, 'a');
    expect(history.kcal, 100);
    expect(history.foodId, original.id);
    expect((await db.itemsOf(template)).single.foodId, original.id);
    await expectLater(
      loader.apply(pack(1, [item('a')])),
      throwsA(error('packOlder')),
    );
  });

  test(
    'custom foods, edited managed foods and user deletions remain protected',
    () async {
      final loader = FoodPackLoader(db);
      await db.upsertFood(FoodsCompanion.insert(name: 'custom', kcal100: 77));
      await loader.apply(
        pack(1, [item('custom'), item('edited'), item('deleted')]),
      );
      final edit = (await db.searchFoods('edited')).single;
      await (db.update(db.foods)..where((f) => f.id.equals(edit.id))).write(
        const FoodsCompanion(
          name: Value('my renamed food'),
          kcal100: Value(333),
        ),
      );
      final deleted = (await db.searchFoods('deleted')).single;
      await db.deleteFood(deleted.id);
      final applied = await loader.apply(
        pack(2, [
          item('custom', kcal: 200),
          item('edited', kcal: 200),
          item('deleted', kcal: 200),
          item('new'),
        ]),
      );
      expect(applied.protected, 3);
      expect(applied.added, 1);
      expect((await db.searchFoods('custom')).single.kcal100, 77);
      expect((await db.searchFoods('my renamed food')).single.kcal100, 333);
      expect(await db.searchFoods('deleted'), isEmpty);
      await loader.apply(
        pack(3, [item('custom'), item('edited'), item('deleted'), item('new')]),
      );
      expect(await db.searchFoods('deleted'), isEmpty);
    },
  );

  test(
    '237 pack adopts only pristine built-ins and preserves edited built-ins',
    () async {
      await seedIfEmpty(db);
      final rice = (await db.searchFoods('米饭'))
          .firstWhere((f) => f.name == '米饭');
      await (db.update(db.foods)..where((f) => f.id.equals(rice.id))).write(
        const FoodsCompanion(kcal100: Value(777)),
      );
      final apple = (await db.searchFoods('苹果'))
          .firstWhere((f) => f.name == '苹果');
      await db.toggleFavorite(apple);
      final official = FoodPack.decode(
        await File('food-packs/common-foods.json').readAsBytes(),
      );
      expect(official.foods.length, 237);
      final result = await FoodPackLoader(db).apply(official);
      expect(result.added, 0);
      expect(result.updated, 236);
      expect(result.protected, 1);
      expect(await db.foodCount(), 1000);
      expect(
        (await db.searchFoods('米饭')).firstWhere((f) => f.name == '米饭').kcal100,
        777,
      );
      expect(
        (await db.searchFoods('苹果')).firstWhere((f) => f.name == '苹果').favorite,
        isTrue,
      );
      for (final food in official.foods) {
        final seed = kSeedFoods.firstWhere((s) => s.name == food.name);
        expect(food.fields['kcal100'], seed.kcal);
      }
    },
  );

  test(
    'pack omissions do not delete; another pack cannot take ownership',
    () async {
      final loader = FoodPackLoader(db);
      await loader.apply(pack(1, [item('a'), item('b')]));
      await loader.apply(pack(2, [item('a', kcal: 120)]));
      expect(await db.foodCount(), 2);
      final other = await loader.apply(
        pack(1, [item('foreign', name: 'a', kcal: 800)], id: 'another.pack'),
      );
      expect(other.protected, 1);
      expect((await db.searchFoods('a')).single.kcal100, 120);
    },
  );

  test(
    'preview-to-apply edits are rechecked in the write transaction',
    () async {
      final loader = FoodPackLoader(db);
      await loader.apply(pack(1, [item('a')]));
      final update = pack(2, [item('a', kcal: 120)]);
      expect((await loader.preview(update)).updated, 1);
      final a = (await db.searchFoods('a')).single;
      await (db.update(db.foods)..where((f) => f.id.equals(a.id))).write(
        const FoodsCompanion(kcal100: Value(999)),
      );
      expect((await loader.apply(update)).protected, 1);
      expect((await db.searchFoods('a')).single.kcal100, 999);
    },
  );

  test(
    'transaction failure rolls back every food and pack metadata write',
    () async {
      await db.customStatement(
        "CREATE TRIGGER reject_food BEFORE INSERT ON foods WHEN NEW.name = 'fail' BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
      );
      await expectLater(
        FoodPackLoader(db).apply(pack(1, [item('ok'), item('fail')])),
        throwsA(anything),
      );
      expect(await db.foodCount(), 0);
      expect(await db.select(db.foodCatalogs).get(), isEmpty);
    },
  );

  test(
    'backup roundtrip retains ownership; old backup cannot guess ownership',
    () async {
      final loader = FoodPackLoader(db);
      await loader.apply(pack(1, [item('a')]));
      final backup = await db.exportJson();
      await db.importJson(backup);
      expect((await loader.apply(pack(2, [item('a', kcal: 120)]))).updated, 1);
      final old = await db.exportJson();
      old.remove('foodCatalogs');
      await db.importJson(old);
      expect(
        (await loader.apply(pack(3, [item('a', kcal: 500)]))).protected,
        1,
      );
      expect((await db.searchFoods('a')).single.kcal100, 120);
    },
  );

  test(
    'v2 database gains pack table without losing personal rows or snapshots',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp('kcal-pack-migration-');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/old.sqlite';
      final old = AppDatabase.forTesting(NativeDatabase(File(path)));
      await old.upsertFood(
        FoodsCompanion.insert(name: 'personal', kcal100: 333),
      );
      await old.addEntry(
        EntriesCompanion.insert(
          date: '2026-09-30',
          meal: MealType.dinner,
          name: 'snapshot',
          kcal: 42,
        ),
      );
      await old.customStatement('DROP TABLE food_catalogs');
      await old.customStatement('PRAGMA user_version = 2');
      await old.close();
      final upgraded = AppDatabase.forTesting(NativeDatabase(File(path)));
      db = upgraded;
      expect((await upgraded.searchFoods('personal')).single.kcal100, 333);
      expect((await upgraded.watchEntries('2026-09-30').first).single.kcal, 42);
      expect(await upgraded.select(upgraded.foodCatalogs).get(), isEmpty);
      expect(
        (await FoodPackLoader(upgraded).apply(pack(1, [item('a')]))).added,
        1,
      );
    },
  );

  test('rename collision is protected without duplicate names', () async {
    final loader = FoodPackLoader(db);
    await loader.apply(pack(1, [item('a')]));
    await db.upsertFood(FoodsCompanion.insert(name: 'occupied', kcal100: 777));
    final result = await loader.apply(pack(2, [item('a', name: 'occupied')]));
    expect(result.protected, 1);
    expect(await db.foodCount(), 2);
    expect((await db.searchFoods('a')).single.name, 'a');
  });
}
