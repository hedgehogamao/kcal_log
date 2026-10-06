import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/food_pack.dart';
import 'package:kcal_log/data/seed_data.dart';

/// Run explicitly: flutter test tool/export_food_pack_test.dart
/// Later data-only revisions can edit the JSON directly, retaining stable IDs.
void main() {
  test('export and validate all 1000 built-in foods as independent data', () {
    final pack = FoodPack.parse({
      'app': 'kcal_log.food_pack',
      'schema': 1,
      'packId': 'kcal-log.common-foods',
      'revision': 2,
      'title': '常见食物库 · 1000 条',
      'foods': [
        for (final food in kSeedFoods)
          {
            'id': seedFoodPackIds[food.name]!,
            'name': food.name,
            'category': seedFoodCategories[food.name]!.code,
            'kcal100': food.kcal,
            'protein100': food.protein,
            'fat100': food.fat,
            'carb100': food.carb,
            'servingDesc': food.servingDesc,
            'servingGrams': food.servingGrams,
          },
      ],
    });
    expect(pack.foods.length, 1000);
    Directory('food-packs').createSync();
    File('food-packs/common-foods-1000.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(pack.toJson())}\n',
    );
    // ignore: avoid_print
    print(
      'FOOD_PACK=food-packs/common-foods-1000.json;SCHEMA=1;REVISION=2;FOODS=1000',
    );
  });
}
