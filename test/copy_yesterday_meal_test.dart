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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());
  Future<List<FoodEntry>> day(String date) => db.entriesBetween(date, date);
  test(
    'snapshots copied atomically and undo only deletes the created IDs',
    () async {
      final food = await db.upsertFood(
        FoodsCompanion.insert(name: '米饭', kcal100: 100),
      );
      await db.addEntry(
        EntriesCompanion.insert(
          date: '2026-01-31',
          meal: MealType.lunch,
          name: '原来的米饭',
          foodId: Value(food.id),
          grams: const Value(150),
          kcal: 123,
          protein: const Value(3),
        ),
      );
      await db.addEntry(
        EntriesCompanion.insert(
          date: '2026-01-31',
          meal: MealType.lunch,
          name: '自记热量',
          kcal: 44,
        ),
      );
      final original = await day('2026-01-31');
      await db.deleteFood(
        food.id,
      ); // snapshots must still copy even when source is deleted
      final ids = await db.copyMealSnapshots(original, '2026-02-01');
      final copied = await day('2026-02-01');
      expect(copied.map((e) => e.name), ['原来的米饭', '自记热量']);
      expect(copied.first.kcal, 123);
      expect(copied.first.grams, 150);
      expect(copied.first.foodId, isNull);
      expect(copied.first.protein, 3);
      await db.addEntry(
        EntriesCompanion.insert(
          date: '2026-02-01',
          meal: MealType.lunch,
          name: '保留',
          kcal: 8,
        ),
      );
      await db.deleteCopiedEntries(ids);
      expect((await day('2026-02-01')).single.name, '保留');
      expect((await day('2026-01-31')).length, 2);
    },
  );
  test('failure in second insertion rolls back the first', () async {
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-01-31',
        meal: MealType.lunch,
        name: 'first',
        kcal: 10,
      ),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-01-31',
        meal: MealType.lunch,
        name: 'reject',
        kcal: 20,
      ),
    );
    final rows = await day('2026-01-31');
    await db.customStatement(
      "CREATE TRIGGER reject_copy BEFORE INSERT ON entries WHEN NEW.name = 'reject' AND NEW.date = '2026-02-01' BEGIN SELECT RAISE(ABORT, 'failure'); END",
    );
    await expectLater(
      db.copyMealSnapshots(rows, '2026-02-01'),
      throwsA(anything),
    );
    expect(await day('2026-02-01'), isEmpty);
    expect((await day('2026-01-31')).length, 2);
  });
  for (final lang in AppLang.values) {
    testWidgets('yesterday preview cancel confirm and undo ${lang.code}', (
      t,
    ) async {
      final now = DateTime.now();
      final today = dateKey(now);
      final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
      await db.addEntry(
        EntriesCompanion.insert(
          date: yesterday,
          meal: MealType.breakfast,
          name: '昨日早餐',
          grams: const Value(150),
          kcal: 234,
          protein: const Value(6),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useKj', lang == AppLang.es);
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      try {
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
        expect(t.takeException(), isNull, reason: 'phase trace');
        final button = find.byKey(const ValueKey('meal-copy-breakfast'));
        await t.scrollUntilVisible(
          button,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(t.element(button), alignment: 0.5);
        await t.pumpAndSettle();
        await t.tap(button);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phase trace');
        expect(
          find.text(
            '昨日早餐 · 150.0 g · ${fmtEnergy(234, lang == AppLang.es)} ${energyUnit(lang == AppLang.es)}',
          ),
          findsOneWidget,
        );
        expect(await day(today), isEmpty);
        await t.tap(find.text(tText(lang, 'cancel')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phase trace');
        expect(await day(today), isEmpty);
        await Scrollable.ensureVisible(t.element(button), alignment: 0.5);
        await t.pumpAndSettle();
        await t.tap(button);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phase trace');
        await t.tap(find.byKey(const ValueKey('copy-meal-confirm')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phase trace');
        final copied = await day(today);
        expect(copied.length, 1);
        expect(copied.single.kcal, 234);
        expect(copied.single.protein, 6);
        await t.tap(find.text(tText(lang, 'undo')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phase trace');
        expect(await day(today), isEmpty);
        expect((await day(yesterday)).length, 1);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
      }
    });
  }
}

String tText(AppLang lang, String key) => t(lang, key);
