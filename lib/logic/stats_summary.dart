import '../data/db.dart';
import 'calc.dart';

/// Missing days stay null; an actual zero-energy entry is a recorded day.
class StatsSummary {
  StatsSummary(
    Iterable<FoodEntry> entries, {
    required DateTime end,
    required int days,
  }) {
    dates = List.generate(
      days,
      (i) => dateKey(end.subtract(Duration(days: days - 1 - i))),
    );
    final allowed = dates.toSet();
    totals = {};
    for (final entry in entries) {
      if (allowed.contains(entry.date)) {
        totals[entry.date] = (totals[entry.date] ?? 0) + entry.kcal;
      }
    }
  }
  late final List<String> dates;
  late final Map<String, double> totals;
  int get recordedDays => totals.length;
  int get missingDays => dates.length - recordedDays;
  double get average => totals.isEmpty
      ? 0
      : totals.values.fold(0.0, (a, b) => a + b) / recordedDays;
  List<double?> values({required bool useKj}) => [
    for (final date in dates)
      totals[date] == null
          ? null
          : useKj
          ? kcalToKj(totals[date]!)
          : totals[date],
  ];
}
