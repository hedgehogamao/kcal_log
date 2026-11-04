import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/food_pack.dart';
import 'package:kcal_log/logic/food_discovery.dart';

Food row(int id, {double protein = 0, double kcal = 100, double fat = 0}) =>
    Food(
      id: id,
      name: 'food$id',
      source: 'custom',
      category: 'other',
      kcal100: kcal,
      protein100: protein,
      fat100: fat,
      carb100: 0,
      favorite: false,
      createdAt: DateTime.utc(2026, 11, 3),
    );

void main() {
  test('protein threshold is inclusive and per100g, not a serving', () {
    final rows = [
      row(1, protein: 9.99),
      row(2, protein: 10),
      row(3, protein: 20),
    ];
    expect(
      discoverFoods(rows, filter: FoodNutritionFilter.protein).map((f) => f.id),
      [2, 3],
    );
  });
  test('energy and fat thresholds include boundaries', () {
    final rows = [
      row(1, kcal: 100, fat: 3),
      row(2, kcal: 100.1, fat: 3.01),
      row(3, kcal: 0, fat: 0),
    ];
    expect(
      discoverFoods(rows, filter: FoodNutritionFilter.energy).map((f) => f.id),
      [1, 3],
    );
    expect(
      discoverFoods(rows, filter: FoodNutritionFilter.fat).map((f) => f.id),
      [1, 3],
    );
  });
  test('default preserves exact input ordering and never mutates input', () {
    final rows = [row(3), row(1), row(2)];
    expect(discoverFoods(rows), rows);
    discoverFoods(rows, sort: FoodDiscoverySort.energy);
    expect(rows.map((f) => f.id), [3, 1, 2]);
  });
  test('protein sorting is descending with stable original relevance ties', () {
    final rows = [
      row(1, protein: 10),
      row(2, protein: 20),
      row(3, protein: 20),
    ];
    expect(
      discoverFoods(rows, sort: FoodDiscoverySort.protein).map((f) => f.id),
      [2, 3, 1],
    );
  });
  test(
    'energy sorting is ascending with stable ties and composes with filter',
    () {
      final rows = [
        row(1, protein: 10, kcal: 200),
        row(2, protein: 9, kcal: 10),
        row(3, protein: 11, kcal: 150),
      ];
      expect(
        discoverFoods(
          rows,
          filter: FoodNutritionFilter.protein,
          sort: FoodDiscoverySort.energy,
        ).map((f) => f.id),
        [3, 1],
      );
      expect(
        discoverFoods([
          row(1),
          row(2),
        ], sort: FoodDiscoverySort.energy).map((f) => f.id),
        [1, 2],
      );
    },
  );
  test('nonfinite or negative values cannot qualify and sort last', () {
    final rows = [
      row(1, protein: double.nan, kcal: double.infinity, fat: -1),
      row(2, protein: double.infinity, kcal: -1, fat: double.nan),
      row(3, protein: 10, kcal: 100, fat: 3),
    ];
    for (final filter in FoodNutritionFilter.values.skip(1)) {
      expect(discoverFoods(rows, filter: filter).map((f) => f.id), [3]);
    }
    expect(
      discoverFoods(rows, sort: FoodDiscoverySort.protein).map((f) => f.id),
      [3, 1, 2],
    );
    expect(
      discoverFoods(rows, sort: FoodDiscoverySort.energy).map((f) => f.id),
      [3, 1, 2],
    );
    expect(discoverFoods([], filter: FoodNutritionFilter.protein), isEmpty);
  });
  test('real 5000 pack filtering sorting is correct and strictly read-only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final pack = FoodPack.decode(
        await File('food-packs/common-foods-5000.json').readAsBytes(),
      );
      await FoodPackLoader(db).apply(pack);
      final before = await db.exportJson()
        ..remove('exportedAt');
      final foods = await db.watchFoods('').first;
      expect(foods.length, 5000);
      final timer = Stopwatch()..start();
      final result = discoverFoods(
        foods,
        filter: FoodNutritionFilter.protein,
        sort: FoodDiscoverySort.energy,
      );
      timer.stop();
      expect(result.length, foods.where((f) => f.protein100 >= 10).length);
      expect(result, isNotEmpty);
      for (var i = 1; i < result.length; i++) {
        expect(result[i].kcal100, greaterThanOrEqualTo(result[i - 1].kcal100));
      }
      expect(
        await db.exportJson()
          ..remove('exportedAt'),
        before,
      );
      // ignore: avoid_print
      print(
        'DISCOVERY5000_ROWS=${foods.length};PROTEIN_MATCHES=${result.length};FILTER_SORT_US=${timer.elapsedMicroseconds};DATABASE_UNCHANGED=true',
      );
    } finally {
      await db.close();
    }
  });
}
