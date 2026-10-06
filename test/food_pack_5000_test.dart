import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/food_pack.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late FoodPack previous;
  late FoodPack expanded;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    previous = FoodPack.decode(
      await File('food-packs/common-foods-1000.json').readAsBytes(),
    );
    expanded = FoodPack.decode(
      await File('food-packs/common-foods-5000.json').readAsBytes(),
    );
  });
  tearDown(() => db.close());
  Future<Food> named(String name) async =>
      (await db.searchFoods(name)).firstWhere((f) => f.name == name);
  const limit = Timeout(Duration(minutes: 2));

  test('5000 schema-valid rows preserve all 1000 previous rows and IDs', () {
    final raw = jsonDecode(
      File('food-packs/common-foods-5000.json').readAsStringSync(),
    ) as Map;
    final old = jsonDecode(
      File('food-packs/common-foods-1000.json').readAsStringSync(),
    ) as Map;
    expect(expanded.id, previous.id);
    expect(expanded.revision, 3);
    expect(expanded.foods.length, 5000);
    expect((raw['foods'] as List).take(1000).toList(), old['foods']);
    expect(expanded.foods.map((f) => f.key).toSet().length, 5000);
    expect(
      File('food-packs/common-foods-5000.json').lengthSync(),
      lessThan(foodPackMaxBytes),
    );
    expect(
      kSeedFoods.length,
      1000,
    ); // the independent pack does not require a new App
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: 0.1.2+3'),
    );
  });

  test('v0.1.2 built-ins import 5000 offline with read-only preview and no duplicates', () async {
    await seedIfEmpty(db);
    final loader = FoodPackLoader(db);
    final preview = await loader.preview(expanded);
    expect(preview.added, 4000);
    expect(preview.updated, 1000);
    expect(preview.protected, 0);
    expect(await db.foodCount(), 1000);
    await loader.apply(expanded);
    expect(await db.foodCount(), 5000);
    final expected = {for (final f in expanded.foods) f.name: f};
    for (final row in await db.select(db.foods).get()) {
      final packed = expected[row.name]!;
      expect(row.category, packed.fields['category']);
      expect(row.kcal100, packed.fields['kcal100']);
      expect(row.source, 'pack');
    }
    expect((await loader.apply(expanded)).current, isTrue);
    expect(await db.foodCount(), 5000);
  }, timeout: limit);

  test('revision2 to revision3 preserves edits deletions custom collisions favorites history templates', () async {
    final loader = FoodPackLoader(db);
    await loader.apply(previous);
    final original = await named(previous.foods.first.name);
    final deleted = await named(previous.foods[1].name);
    await db.toggleFavorite(original);
    await (db.update(db.foods)..where((f) => f.id.equals(original.id))).write(
      const FoodsCompanion(kcal100: Value(777)),
    );
    await db.deleteFood(deleted.id);
    final custom = await db.upsertFood(
      FoodsCompanion.insert(
        name: expanded.foods[1000].name,
        kcal100: 666,
        source: const Value('custom'),
      ),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-10-06',
        meal: MealType.lunch,
        name: original.name,
        foodId: Value(original.id),
        kcal: 42,
      ),
    );
    final template = await db.saveTemplate('keep', [(original.id, 100)]);
    final result = await loader.apply(expanded);
    expect(result.protected, 3);
    expect(result.added, 3999);
    expect(await db.foodCount(), 4999);
    final retained = await named(original.name);
    expect(retained.id, original.id);
    expect(retained.kcal100, 777);
    expect(retained.favorite, isTrue);
    expect(
      (await db.searchFoods(deleted.name)).where((f) => f.name == deleted.name),
      isEmpty,
    );
    expect((await named(custom.name)).id, custom.id);
    expect((await named(custom.name)).kcal100, 666);
    expect((await db.watchEntries('2026-10-06').first).single.kcal, 42);
    expect((await db.itemsOf(template)).single.foodId, original.id);
    expect((await loader.apply(expanded)).current, isTrue);
    expect(await db.foodCount(), 4999);
  }, timeout: limit);

  test(
    '5000 reorder is idempotent and older revision cannot downgrade',
    () async {
      final loader = FoodPackLoader(db);
      await loader.apply(expanded);
      final raw = expanded.toJson();
      raw['foods'] = (raw['foods'] as List).reversed.toList();
      expect((await loader.apply(FoodPack.parse(raw))).current, isTrue);
      await expectLater(
        loader.apply(previous),
        throwsA(isA<FoodPackException>()),
      );
      expect(await db.foodCount(), 5000);
    },
    timeout: limit,
  );

  test(
    '5000 personal backup retains data-pack identity and revision',
    () async {
      final loader = FoodPackLoader(db);
      await loader.apply(expanded);
      final backup = await db.exportJson();
      expect((backup['foods'] as List).length, 5000);
      await db.importJson(backup);
      expect(await db.foodCount(), 5000);
      expect((await loader.apply(expanded)).current, isTrue);
      expect((await db.select(db.foodCatalogs).get()).single.revision, 3);
    },
    timeout: limit,
  );

  test('failed 5000 import is atomic and retry succeeds', () async {
    final loader = FoodPackLoader(db);
    await loader.apply(previous);
    final rowsBefore = await db.select(db.foods).get();
    final stateBefore = await db.select(db.foodCatalogs).get();
    final reject = expanded.foods.last.name.replaceAll("'", "''");
    await db.customStatement(
      "CREATE TRIGGER reject_5000 BEFORE INSERT ON foods WHEN NEW.name = '$reject' BEGIN SELECT RAISE(ABORT, 'fixture failure'); END;",
    );
    await expectLater(loader.apply(expanded), throwsA(anything));
    expect(await db.select(db.foods).get(), rowsBefore);
    expect(await db.select(db.foodCatalogs).get(), stateBefore);
    expect(await db.foodCount(), 1000);
    await db.customStatement('DROP TRIGGER reject_5000');
    await loader.apply(expanded);
    expect(await db.foodCount(), 5000);
  }, timeout: limit);
}
