import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';

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
    expect((await db.searchFoods('牛肉面')).single.source, 'builtin');
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
      expect((await db.searchFoods('牛肉面')).single.source, 'builtin');

      final deleted = (await db.searchFoods('牛肉面')).single;
      await db.deleteFood(deleted.id);
      await seedIfEmpty(db);
      expect(await db.searchFoods('牛肉面'), isEmpty);
    },
  );
}
