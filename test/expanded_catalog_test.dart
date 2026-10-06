import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/food_pack.dart';
import 'package:kcal_log/data/seed_data.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<FoodPack> expandedPack() async => FoodPack.decode(
    await File('food-packs/common-foods-1000.json').readAsBytes(),
  );
  Future<void> legacy() async {
    await db.batch((batch) {
      batch.insertAll(db.foods, [
        for (final f in kLegacySeedFoods)
          FoodsCompanion.insert(
            name: f.name,
            source: const Value('builtin'),
            category: Value(seedFoodCategories[f.name]!.code),
            kcal100: f.kcal,
            protein100: Value(f.protein),
            fat100: Value(f.fat),
            carb100: Value(f.carb),
            servingDesc: Value(f.servingDesc),
            servingGrams: Value(f.servingGrams),
          ),
      ]);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('builtinFoodCatalogVersion', 2);
  }

  Future<Food> named(String name) async =>
      (await db.searchFoods(name)).firstWhere((f) => f.name == name);

  test(
    '1000 valid pack rows exactly match compiled seeds and stable IDs',
    () async {
      final pack = await expandedPack();
      final original = FoodPack.decode(
        await File('food-packs/common-foods.json').readAsBytes(),
      );
      expect(pack.id, original.id);
      expect(pack.revision, 2);
      expect(pack.foods.length, 1000);
      expect(kSeedFoods.length, 1000);
      expect(kLegacySeedFoods.length, 237);
      expect(seedFoodCategories.length, 1000);
      expect(seedFoodPackIds.values.toSet().length, 1000);
      expect(
        pack.foods.take(237).map((f) => f.toJson()),
        original.foods.map((f) => f.toJson()),
      );
      for (final f in pack.foods) {
        final seed = kSeedFoods.firstWhere((s) => s.name == f.name);
        expect(f.key, seedFoodPackIds[seed.name]);
        expect(f.fields['category'], seedFoodCategories[seed.name]!.code);
        expect(f.fields['kcal100'], seed.kcal);
        expect(f.fields['protein100'], seed.protein);
        expect(f.fields['fat100'], seed.fat);
        expect(f.fields['carb100'], seed.carb);
        expect(f.fields['servingDesc'], seed.servingDesc);
        expect(f.fields['servingGrams'], seed.servingGrams);
      }
    },
  );

  test(
    'new App directly seeds 1000 searchable categorized foods offline',
    () async {
      await seedIfEmpty(db);
      expect(await db.foodCount(), 1000);
      expect((await db.searchFoods('豆腐')).length, greaterThan(1));
      expect((await db.searchFoods('Quinoa')).length, greaterThan(0));
      for (final row in await db.select(db.foods).get()) {
        expect(row.category, seedFoodCategories[row.name]!.code);
        expect(row.source, 'builtin');
      }
      await seedIfEmpty(db);
      expect(await db.foodCount(), 1000);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('builtinFoodCatalogVersion'), 3);
    },
  );

  test('v2 upgrade protects deleted legacy, custom collision, favorite, history and template', () async {
    await legacy();
    final rice = await named('米饭');
    await db.toggleFavorite(rice);
    await (db.update(db.foods)..where((f) => f.id.equals(rice.id))).write(
      const FoodsCompanion(kcal100: Value(777)),
    );
    final apple = await named('苹果');
    await (db.delete(db.foods)..where((f) => f.id.equals(apple.id))).go();
    final newName = kSeedFoods[237].name;
    final custom = await db.upsertFood(
      FoodsCompanion.insert(name: newName, kcal100: 666),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-10-06',
        meal: MealType.lunch,
        name: '米饭',
        foodId: Value(rice.id),
        kcal: 116,
      ),
    );
    final template = await db.saveTemplate('keep', [(rice.id, 100)]);
    await seedIfEmpty(db);
    expect(await db.foodCount(), 999);
    expect((await db.searchFoods('苹果')).where((f) => f.name == '苹果'), isEmpty);
    expect((await named('米饭')).id, rice.id);
    expect((await named('米饭')).kcal100, 777);
    expect((await named('米饭')).favorite, isTrue);
    expect((await named(newName)).id, custom.id);
    expect((await named(newName)).kcal100, 666);
    expect((await named(newName)).source, 'custom');
    expect((await db.watchEntries('2026-10-06').first).single.kcal, 116);
    expect((await db.itemsOf(template)).single.foodId, rice.id);
    final added = await named(kSeedFoods[238].name);
    await (db.delete(db.foods)..where((f) => f.id.equals(added.id))).go();
    await seedIfEmpty(db);
    expect(await db.foodCount(), 998);
    expect(await db.searchFoods(added.name), isEmpty);
  });

  test(
    'deleting the entire migrated catalog does not reseed it at each launch',
    () async {
      await seedIfEmpty(db);
      await db.delete(db.foods).go();
      await seedIfEmpty(db);
      expect(await db.foodCount(), 0);
    },
  );

  test(
    'data pack alone upgrades 237 to 1000 without an App version change',
    () async {
      final version = File('pubspec.yaml').readAsStringSync();
      final loader = FoodPackLoader(db);
      final old = FoodPack.decode(
        await File('food-packs/common-foods.json').readAsBytes(),
      );
      await loader.apply(old);
      final rice = await named('米饭');
      final preview = await loader.preview(await expandedPack());
      expect(preview.added, 763);
      expect(await db.foodCount(), 237);
      await loader.apply(await expandedPack());
      expect(await db.foodCount(), 1000);
      expect((await named('米饭')).id, rice.id);
      expect((await loader.apply(await expandedPack())).current, isTrue);
      await expectLater(loader.apply(old), throwsA(isA<FoodPackException>()));
      expect(File('pubspec.yaml').readAsStringSync(), version);
    },
  );

  test(
    'new compiled built-ins can be adopted by the independent 1000 pack',
    () async {
      await seedIfEmpty(db);
      final result = await FoodPackLoader(db).apply(await expandedPack());
      expect(result.added, 0);
      expect(result.protected, 0);
      expect(result.updated, 1000);
      expect(await db.foodCount(), 1000);
      final backup = await db.exportJson();
      expect((backup['foods'] as List).length, 1000);
      await db.importJson(backup);
      expect(await db.foodCount(), 1000);
      expect(
        (await FoodPackLoader(db).apply(await expandedPack())).current,
        isTrue,
      );
    },
  );

  test('failed v2 expansion is atomic and does not advance catalog version', () async {
    await legacy();
    final name = kSeedFoods[300].name.replaceAll("'", "''");
    await db.customStatement(
      "CREATE TRIGGER reject_expansion BEFORE INSERT ON foods WHEN NEW.name = '$name' BEGIN SELECT RAISE(ABORT, 'test failure'); END;",
    );
    await expectLater(seedIfEmpty(db), throwsA(anything));
    expect(await db.foodCount(), 237);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('builtinFoodCatalogVersion'), 2);
    await db.customStatement('DROP TRIGGER reject_expansion');
    await seedIfEmpty(db);
    expect(await db.foodCount(), 1000);
  });
}
