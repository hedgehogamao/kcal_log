import '../data/db.dart';
import 'calc.dart';

/// Two rolling windows of seven completed local calendar days. Today is excluded.
class WeeklyReview {
  WeeklyReview(Iterable<FoodEntry> rows, {required DateTime today}) {
    final day = DateTime(today.year, today.month, today.day);
    currentDates = List.generate(
      7,
      (i) => dateKey(DateTime(day.year, day.month, day.day - 7 + i)),
    );
    previousDates = List.generate(
      7,
      (i) => dateKey(DateTime(day.year, day.month, day.day - 14 + i)),
    );
    currentTotals = {};
    previousTotals = {};
    mealDays = {for (final m in MealType.values) m: <String>{}};
    for (final e in rows) {
      if (currentDates.contains(e.date)) {
        currentTotals[e.date] = (currentTotals[e.date] ?? 0) + e.kcal;
        mealDays[e.meal]!.add(e.date);
      } else if (previousDates.contains(e.date)) {
        previousTotals[e.date] = (previousTotals[e.date] ?? 0) + e.kcal;
      }
    }
  }
  late final List<String> currentDates, previousDates;
  late final Map<String, double> currentTotals, previousTotals;
  late final Map<MealType, Set<String>> mealDays;
  double? _average(Map<String, double> values) => values.isEmpty
      ? null
      : values.values.fold(0.0, (a, b) => a + b) / values.length;
  double? get currentAverage => _average(currentTotals);
  double? get previousAverage => _average(previousTotals);
  double? get difference => currentAverage == null || previousAverage == null
      ? null
      : currentAverage! - previousAverage!;
}
