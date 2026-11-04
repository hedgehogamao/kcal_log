import '../data/db.dart';

/// Nutrient estimate from ingredient weights and measured cooked yield.
/// No inferred cooking loss, oil absorption or bowl/serving weight.
class RecipePortions {
  RecipePortions(
    List<(Food, double)> ingredients, {
    required this.finishedGrams,
    required this.portions,
  }) {
    if (ingredients.isEmpty ||
        !finishedGrams.isFinite ||
        finishedGrams <= 0 ||
        finishedGrams > 100000 ||
        !portions.isFinite ||
        portions <= 0 ||
        portions > 1000) {
      throw const FormatException('recipeInvalid');
    }
    totals = [0, 0, 0, 0];
    for (final (food, grams) in ingredients) {
      if (!grams.isFinite || grams <= 0 || grams > 100000) {
        throw const FormatException('recipeInvalid');
      }
      final values = [food.kcal100, food.protein100, food.fat100, food.carb100];
      for (var i = 0; i < 4; i++) {
        if (!values[i].isFinite || values[i] < 0) {
          throw const FormatException('recipeInvalid');
        }
        totals[i] += values[i] * grams / 100;
      }
    }
    per100 = [for (final n in totals) n / finishedGrams * 100];
    perPortion = [for (final n in totals) n / portions];
    if (per100.any((v) => !v.isFinite || v < 0) ||
        per100[0] > 900 ||
        per100.skip(1).any((v) => v > 100)) {
      throw const FormatException('recipeInvalid');
    }
  }
  final double finishedGrams, portions;
  late final List<double> totals, per100, perPortion;
  double get servingGrams => finishedGrams / portions;
}
