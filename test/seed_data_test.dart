import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:kcal_log/logic/food_category.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('expanded catalog has unique names and valid nutrients', () {
    expect(kSeedFoods.length, greaterThanOrEqualTo(200));
    expect(kSeedFoods.map((f) => f.name).toSet().length, kSeedFoods.length);
    for (final food in kSeedFoods) {
      expect(food.name.trim(), isNotEmpty);
      expect(food.kcal, inInclusiveRange(0, 900));
      expect(food.protein, inInclusiveRange(0, 100));
      expect(food.fat, inInclusiveRange(0, 100));
      expect(food.carb, inInclusiveRange(0, 100));
      if (food.servingGrams != null) {
        expect(food.servingGrams!, greaterThan(0));
      }
    }
  });

  test('fresh install seeds full catalog', () async {
    await seedIfEmpty(db);
    expect(await db.foodCount(), kSeedFoods.length);
    expect(
      (await db.searchFoods('牛肉面')).firstWhere((f) => f.name == '牛肉面').source,
      'builtin',
    );
    expect(seedFoodCategories.length, 1000);
    expect(seedFoodCategories.values.toSet(), containsAll(FoodCategory.values));
    expect(
      (await db.searchFoods('米饭')).firstWhere((f) => f.name == '米饭').category,
      'staple',
    );
    expect(
      (await db.searchFoods('鸡蛋')).firstWhere((f) => f.name == '鸡蛋').category,
      'protein',
    );
    expect(
      (await db.searchFoods('苹果')).firstWhere((f) => f.name == '苹果').category,
      'fruit',
    );
    expect(
      (await db.searchFoods('杏仁')).firstWhere((f) => f.name == '杏仁').category,
      'snack',
    );
    expect(
      (await db.searchFoods('可乐')).firstWhere((f) => f.name == '可乐').category,
      'drink',
    );
    expect(
      (await db.searchFoods('番茄炒蛋'))
          .firstWhere((f) => f.name == '番茄炒蛋')
          .category,
      'dish',
    );
  });

  test(
    'upgraded built-ins gain categories without changing custom rows',
    () async {
      final builtin = await db.upsertFood(
        FoodsCompanion.insert(
          name: '米饭',
          kcal100: 999,
          source: const Value('builtin'),
          category: const Value('legacy'),
        ),
      );
      final custom = await db.upsertFood(
        FoodsCompanion.insert(name: '苹果', kcal100: 777),
      );
      SharedPreferences.setMockInitialValues({'builtinFoodCatalogVersion': 2});
      await seedIfEmpty(db);
      final upgraded = (await db.searchFoods('米饭'))
          .firstWhere((f) => f.name == '米饭');
      expect(upgraded.id, builtin.id);
      expect(upgraded.kcal100, 999);
      expect(upgraded.category, 'staple');
      final untouched = (await db.searchFoods('苹果'))
          .firstWhere((f) => f.name == '苹果');
      expect(untouched.id, custom.id);
      expect(untouched.kcal100, 777);
      expect(untouched.category, 'other');
      expect(await db.foodCount(), 765);
    },
  );

  test(
    'old backup import regains categories without duplicating foods',
    () async {
      await seedIfEmpty(db);
      final backup = await db.exportJson();
      for (final food in backup['foods'] as List) {
        (food as Map<String, dynamic>).remove('category');
      }
      await db.importJson(backup);
      expect(
        (await db.searchFoods('米饭')).firstWhere((f) => f.name == '米饭').category,
        'legacy',
      );
      await backfillBuiltInFoodCategories(db);
      expect(await db.foodCount(), 1000);
      expect(
        (await db.searchFoods('米饭')).firstWhere((f) => f.name == '米饭').category,
        'staple',
      );
    },
  );

  test('explicit Other category on built-in food is not overwritten', () async {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        source: const Value('builtin'),
        category: const Value('other'),
      ),
    );
    SharedPreferences.setMockInitialValues({'builtinFoodCatalogVersion': 2});
    await seedIfEmpty(db);
    final rice = (await db.searchFoods('米饭')).firstWhere((f) => f.name == '米饭');
    expect(rice.category, 'other');
    final backup = await db.exportJson();
    await db.importJson(backup);
    await backfillBuiltInFoodCategories(db);
    final restored = (await db.searchFoods('米饭'))
        .firstWhere((f) => f.name == '米饭');
    expect(restored.category, 'other');
  });

  test(
    'upgrade adds only missing foods and preserves existing edits',
    () async {
      await db.upsertFood(
        FoodsCompanion.insert(
          name: '米饭',
          kcal100: 999,
          source: const Value('custom'),
        ),
      );
      await seedIfEmpty(db);
      expect(await db.foodCount(), kSeedFoods.length);
      final rice = (await db.searchFoods('米饭'))
          .singleWhere((food) => food.name == '米饭');
      expect(rice.kcal100, 999);
      expect(rice.source, 'custom');
      expect(
        (await db.searchFoods('牛肉面')).firstWhere((f) => f.name == '牛肉面').source,
        'builtin',
      );

      final deleted = (await db.searchFoods('牛肉面'))
          .firstWhere((f) => f.name == '牛肉面');
      await db.deleteFood(deleted.id);
      await seedIfEmpty(db);
      expect(await db.searchFoods('牛肉面'), isEmpty);
    },
  );
}
