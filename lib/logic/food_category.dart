import 'package:flutter/widgets.dart';

import 'i18n.dart';

/// Persisted category codes, independent of the display language.
enum FoodCategory {
  staple('staple', 'categoryStaple'),
  protein('protein', 'categoryProtein'),
  vegetable('vegetable', 'categoryVegetable'),
  fruit('fruit', 'categoryFruit'),
  dairy('dairy', 'categoryDairy'),
  snack('snack', 'categorySnack'),
  drink('drink', 'categoryDrink'),
  dish('dish', 'categoryDish'),
  other('other', 'categoryOther');

  const FoodCategory(this.code, this.labelKey);
  final String code;
  final String labelKey;

  static FoodCategory fromCode(String code) => FoodCategory.values.firstWhere(
        (category) => category.code == code,
        orElse: () => FoodCategory.other,
      );

  String label(BuildContext context) => tr(context, labelKey);
}
