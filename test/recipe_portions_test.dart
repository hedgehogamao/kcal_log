import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/recipe_portions.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/recipe_portions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Food ingredient() => Food(
  id: 1,
  name: '食材',
  source: 'custom',
  category: 'other',
  kcal100: 200,
  protein100: 10,
  fat100: 5,
  carb100: 30,
  favorite: false,
  createdAt: DateTime(2026),
);
void main() {
  test(
    'measured cooked weight changes concentration but not ingredient totals',
    () {
      final r = RecipePortions(
        [(ingredient(), 200)],
        finishedGrams: 400,
        portions: 4,
      );
      expect(r.totals, [400, 20, 10, 60]);
      expect(r.per100, [100, 5, 2.5, 15]);
      expect(r.perPortion, [100, 5, 2.5, 15]);
      expect(r.servingGrams, 100);
    },
  );
  test('portions only change serving size, no invented cooking loss', () {
    final r = RecipePortions(
      [(ingredient(), 200)],
      finishedGrams: 200,
      portions: 2,
    );
    expect(r.totals[0], 400);
    expect(r.per100[0], 200);
    expect(r.perPortion[0], 200);
  });
  test('invalid weights and impossible nutrient concentration rejected', () {
    for (final w in [0.0, -1.0, double.nan, double.infinity, 1.0]) {
      expect(
        () => RecipePortions(
          [(ingredient(), 200)],
          finishedGrams: w,
          portions: 2,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => RecipePortions([], finishedGrams: 100, portions: 1),
      throwsFormatException,
    );
    expect(
      () => RecipePortions(
        [(ingredient(), 100)],
        finishedGrams: 200,
        portions: 0,
      ),
      throwsFormatException,
    );
  });
  for (final lang in AppLang.values) {
    testWidgets('recipe preview/save snapshot without logging ${lang.code}', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final f = await db.upsertFood(
          FoodsCompanion.insert(
            name: '食材',
            kcal100: 200,
            protein100: const Value(10),
            fat100: const Value(5),
            carb100: const Value(30),
          ),
        );
        await db.saveTemplate('测试食谱', [(f.id, 200)]);
        t.view.physicalSize = const Size(320, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              prefsProvider.overrideWithValue(prefs),
            ],
            child: LangScope(
              lang: lang,
              child: MaterialApp(
                home: Builder(
                  builder: (c) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(c).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RecipePortionsPage(),
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        final choose = find.byKey(const ValueKey('recipe-template'));
        await t.scrollUntilVisible(
          choose,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(choose);
        await t.pumpAndSettle();
        await t.tap(find.text('测试食谱').last);
        await t.pumpAndSettle();
        for (final (key, text) in [
          ('recipe-weight', '400'),
          ('recipe-count', '4'),
        ]) {
          final field = find.byKey(ValueKey(key));
          await t.scrollUntilVisible(
            field,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.enterText(field, text);
        }
        final calculate = find.byKey(const ValueKey('recipe-calculate'));
        await t.scrollUntilVisible(
          calculate,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(calculate);
        await t.pumpAndSettle();
        expect(await db.foodCount(), 1);
        expect(await db.select(db.entries).get(), isEmpty);
        final save = find.byKey(const ValueKey('recipe-save'));
        await t.scrollUntilVisible(
          save,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(save);
        await t.pumpAndSettle();
        expect(await db.foodCount(), 2);
        expect(await db.select(db.entries).get(), isEmpty);
        final food = (await db.searchFoods('测试食谱')).single;
        expect(food.kcal100, 100);
        expect(food.protein100, 5);
        expect(food.servingGrams, 100);
        expect(food.source, 'custom');
        expect((await db.allTemplates()).single.name, '测试食谱');
        final backup = await db.exportJson();
        await db.importJson(backup);
        expect((await db.searchFoods('测试食谱')).single.servingGrams, 100);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await db.close();
      }
    });
  }
}
