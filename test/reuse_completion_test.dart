import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/today_page.dart';
import 'package:kcal_log/ui/sheets/food_picker_sheet.dart';
import 'package:kcal_log/ui/sheets/entry_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final lang in AppLang.values) {
    testWidgets(
      'meal-specific frequent foods use last explicit grams ${lang.code}',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          final food = await db.upsertFood(
            FoodsCompanion.insert(name: '早餐米饭', kcal100: 100),
          );
          final dinner = await db.upsertFood(
            FoodsCompanion.insert(name: '晚餐豆腐', kcal100: 200),
          );
          await db.addEntry(
            EntriesCompanion.insert(
              date: '2026-11-02',
              meal: MealType.breakfast,
              name: food.name,
              foodId: Value(food.id),
              grams: const Value(150),
              kcal: 150,
            ),
          );
          await db.addEntry(
            EntriesCompanion.insert(
              date: '2026-11-01',
              meal: MealType.breakfast,
              name: food.name,
              foodId: Value(food.id),
              grams: const Value(50),
              kcal: 50,
            ),
          );
          await db.addEntry(
            EntriesCompanion.insert(
              date: '2026-11-02',
              meal: MealType.dinner,
              name: dinner.name,
              foodId: Value(dinner.id),
              grams: const Value(300),
              kcal: 600,
            ),
          );
          t.view.physicalSize = const Size(500, 1000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                dbProvider.overrideWithValue(db),
                prefsProvider.overrideWithValue(prefs),
              ],
              child: LangScope(
                lang: lang,
                child: const MaterialApp(
                  home: Scaffold(
                    body: FoodPickerSheet(
                      date: '2026-11-03',
                      meal: MealType.breakfast,
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          await t.tap(find.byTooltip(tText(lang, 'moreActions')));
          await t.pumpAndSettle();
          await t.tap(find.text(tText(lang, 'mealFrequent')));
          await t.pumpAndSettle();
          expect(find.text('晚餐豆腐'), findsNothing);
          await t.tap(find.text('早餐米饭'));
          await t.pumpAndSettle();
          final input = find.descendant(
            of: find.byType(EntrySheet),
            matching: find.byType(TextField),
          );
          expect(t.widget<TextField>(input).controller!.text, '150.0');
          expect((await db.select(db.entries).get()).length, 3);
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(milliseconds: 200));
          await db.close();
        }
      },
    );
    testWidgets(
      'whole-day copy preserves meal snapshots and supports cancel/undo ${lang.code}',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          final now = DateTime.now();
          final today = dateKey(now),
              yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
          for (final meal in [MealType.breakfast, MealType.dinner]) {
            await db.addEntry(
              EntriesCompanion.insert(
                date: yesterday,
                meal: meal,
                name: meal.name,
                kcal: 123,
              ),
            );
          }
          t.view.physicalSize = const Size(500, 1600);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                dbProvider.overrideWithValue(db),
                prefsProvider.overrideWithValue(prefs),
              ],
              child: LangScope(
                lang: lang,
                child: const MaterialApp(home: TodayPage()),
              ),
            ),
          );
          await t.pumpAndSettle();
          final copy = find.byKey(const ValueKey('copy-day-open'));
          await t.tap(copy);
          await t.pumpAndSettle();
          await t.tap(find.text(tText(lang, 'cancel')));
          await t.pumpAndSettle();
          expect(await db.entriesBetween(today, today), isEmpty);
          await t.tap(copy);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('copy-meal-confirm')));
          await t.pumpAndSettle();
          final rows = await db.entriesBetween(today, today);
          expect(rows.length, 2);
          expect(rows.map((e) => e.meal).toSet(), {
            MealType.breakfast,
            MealType.dinner,
          });
          expect(rows.every((e) => e.kcal == 123), isTrue);
          await t.tap(find.text(tText(lang, 'undo')));
          await t.pumpAndSettle();
          expect(await db.entriesBetween(today, today), isEmpty);
          expect((await db.entriesBetween(yesterday, yesterday)).length, 2);
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(milliseconds: 200));
          await db.close();
        }
      },
    );
  }
}

String tText(AppLang lang, String key) => t(lang, key);
