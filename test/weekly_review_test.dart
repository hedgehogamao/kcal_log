import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/weekly_review.dart';
import 'package:kcal_log/ui/widgets/weekly_review_card.dart';

FoodEntry row(
  String date,
  double kcal, {
  int id = 1,
  MealType meal = MealType.lunch,
}) => FoodEntry(
  id: id,
  date: date,
  meal: meal,
  name: 'fixture',
  kcal: kcal,
  protein: 0,
  fat: 0,
  carb: 0,
  createdAt: DateTime.utc(2026),
);
void main() {
  test('two explicit calendar windows exclude today and future', () {
    final r = WeeklyReview([
      row('2026-11-03', 9000),
      row('2026-11-02', 100),
      row('2026-10-27', 200),
      row('2026-10-20', 500),
      row('2026-10-26', 700),
      row('2026-10-19', 9999),
      row('2026-11-04', 9999),
    ], today: DateTime(2026, 11, 3, 20));
    expect(r.currentDates.first, '2026-10-27');
    expect(r.currentDates.last, '2026-11-02');
    expect(r.previousDates.first, '2026-10-20');
    expect(r.currentAverage, 150);
    expect(r.previousAverage, 600);
    expect(r.difference, -450);
  });
  test('missing days stay missing while a real zero entry counts', () {
    final r = WeeklyReview([
      row('2026-11-02', 0),
    ], today: DateTime(2026, 11, 3));
    expect(r.currentTotals.length, 1);
    expect(r.currentAverage, 0);
    expect(r.previousAverage, isNull);
    expect(r.difference, isNull);
  });
  test('multiple entries count one logged day and meal-day', () {
    final r = WeeklyReview([
      row('2026-11-02', 100),
      row('2026-11-02', 200, id: 2),
      row('2026-11-02', 30, id: 3, meal: MealType.snack),
    ], today: DateTime(2026, 11, 3));
    expect(r.currentAverage, 330);
    expect(r.currentTotals.length, 1);
    expect(r.mealDays[MealType.lunch]!.length, 1);
    expect(r.mealDays[MealType.snack]!.length, 1);
    expect(r.mealDays[MealType.breakfast], isEmpty);
  });
  test('empty history has no fabricated comparison', () {
    final r = WeeklyReview([], today: DateTime(2026, 11, 3));
    expect(r.currentAverage, isNull);
    expect(r.previousAverage, isNull);
    expect(r.difference, isNull);
  });
  test('leap month calendar boundaries do not shift days', () {
    final r = WeeklyReview([], today: DateTime(2024, 3, 1));
    expect(r.currentDates.last, '2024-02-29');
    expect(r.currentDates.first, '2024-02-23');
    expect(r.previousDates.last, '2024-02-22');
  });
  for (final lang in AppLang.values) {
    testWidgets('weekly summary 320px 2x ${lang.code}', (t) async {
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final r = WeeklyReview([
        row('2026-11-02', 100),
        row('2026-10-25', 200),
      ], today: DateTime(2026, 11, 3));
      await t.pumpWidget(
        LangScope(
          lang: lang,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeeklyReviewCard(review: r, useKj: lang == AppLang.es),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('weekly-review')), findsOneWidget);
      expect(find.textContaining('2026-10-27'), findsOneWidget);
      if (lang == AppLang.es) expect(find.textContaining('kJ'), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
