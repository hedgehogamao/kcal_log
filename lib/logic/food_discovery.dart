import '../data/db.dart';

/// Explicit per-100g conditions, not health claims or personalized advice.
enum FoodNutritionFilter { all, protein, energy, fat }

enum FoodDiscoverySort { relevance, protein, energy }

extension FoodNutritionFilterX on FoodNutritionFilter {
  String get labelKey =>
      'nutrition${name[0].toUpperCase()}${name.substring(1)}';

  bool matches(Food food) {
    bool valid(double n) => n.isFinite && n >= 0;
    return switch (this) {
      FoodNutritionFilter.all => true,
      FoodNutritionFilter.protein =>
        valid(food.protein100) && food.protein100 >= 10,
      FoodNutritionFilter.energy => valid(food.kcal100) && food.kcal100 <= 100,
      FoodNutritionFilter.fat => valid(food.fat100) && food.fat100 <= 3,
    };
  }
}

extension FoodDiscoverySortX on FoodDiscoverySort {
  String get labelKey => 'foodSort${name[0].toUpperCase()}${name.substring(1)}';
}

/// Receives already search/category/source-filtered rows. Never mutates rows or
/// the input; ties retain original search relevance/favorite order.
List<Food> discoverFoods(
  Iterable<Food> input, {
  FoodNutritionFilter filter = FoodNutritionFilter.all,
  FoodDiscoverySort sort = FoodDiscoverySort.relevance,
}) {
  final rows = input.where(filter.matches).toList();
  if (sort == FoodDiscoverySort.relevance) return rows;
  final indexed = rows.indexed.toList();
  double value(Food f) =>
      sort == FoodDiscoverySort.protein ? f.protein100 : f.kcal100;
  indexed.sort((a, b) {
    final av = value(a.$2), bv = value(b.$2);
    final aValid = av.isFinite && av >= 0;
    final bValid = bv.isFinite && bv >= 0;
    if (aValid != bValid) return aValid ? -1 : 1;
    final byValue = !aValid
        ? 0
        : sort == FoodDiscoverySort.protein
        ? bv.compareTo(av)
        : av.compareTo(bv);
    return byValue != 0 ? byValue : a.$1.compareTo(b.$1);
  });
  return [for (final (_, food) in indexed) food];
}
