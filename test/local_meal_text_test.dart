import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/local_meal_text.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/text_meal_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('meal names do not consume food prefixes such as luncheon meat', () {
    final result = parseLocalMealText('午餐肉100克');
    expect(result.$1, isNull);
    expect(result.$2.single.$1, '午餐肉');
    expect(parseLocalMealText('almuerzo arroz 100g').$1, MealType.lunch);
  });
  test('multiple explicit gram quantities and meal parsed locally', () {
    final (meal, rows) = parseLocalMealText('午餐 米饭150克、鸡胸肉100克');
    expect(meal, MealType.lunch);
    expect(rows, [('米饭', 150.0), ('鸡胸肉', 100.0)]);
  });
  test('decimal grams and English meal accepted', () {
    expect(parseLocalMealText('dinner rice 12.5g, tofu 100 grams').$2, [
      ('rice', 12.5),
      ('tofu', 100.0),
    ]);
  });
  test('no guessed bowl, ml, negative or zero weight', () {
    for (final s in [
      '米饭一碗',
      '牛奶100ml',
      '米饭-100克',
      '米饭0克',
      '米饭1000000克',
      '米饭100克，多吃一点',
      '',
    ]) {
      expect(() => parseLocalMealText(s), throwsFormatException);
    }
  });
  test('item count capped at20 and length capped', () {
    expect(
      () => parseLocalMealText(List.filled(21, '米饭1g').join(',')),
      throwsFormatException,
    );
    expect(() => parseLocalMealText('米' * 1001), throwsFormatException);
  });
  for (final lang in AppLang.values) {
    testWidgets('text review read only then atomic confirm ${lang.code}', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.upsertFood(FoodsCompanion.insert(name: '米饭', kcal100: 100));
        await db.upsertFood(FoodsCompanion.insert(name: '鸡胸肉', kcal100: 200));
        if (lang == AppLang.zh) {
          await db.upsertFood(
            FoodsCompanion.insert(name: '鸡胸肉（熟）', kcal100: 300),
          );
        }
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
                          builder: (_) =>
                              const TextMealPage(date: '2026-10-01'),
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
        await t.enterText(
          find.byKey(const ValueKey('text-meal-input')),
          lang == AppLang.zh ? '午餐 米饭150克、鸡胸100克' : '午餐 米饭150克、鸡胸肉100克',
        );
        await t.tap(find.byKey(const ValueKey('text-meal-parse')));
        await t.pumpAndSettle();
        expect(await db.select(db.entries).get(), isEmpty);
        final confirm = find.byKey(const ValueKey('text-meal-confirm'));
        await t.scrollUntilVisible(
          confirm,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        if (lang == AppLang.zh) {
          expect(t.widget<FilledButton>(confirm).onPressed, isNull);
          final choice = find.byKey(const ValueKey('text-meal-choice-1-鸡胸'));
          await t.ensureVisible(choice);
          await t.pumpAndSettle();
          await t.tap(choice);
          await t.pumpAndSettle();
          await t.tap(find.text('鸡胸肉').last);
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
            confirm,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pumpAndSettle();
        }
        if (lang == AppLang.es) {
          await db.customStatement(
            "CREATE TRIGGER fail_text BEFORE INSERT ON entries WHEN NEW.name = '鸡胸肉' BEGIN SELECT RAISE(ABORT, 'fixture'); END",
          );
          await t.tap(confirm);
          await t.pumpAndSettle();
          expect(await db.select(db.entries).get(), isEmpty);
          await db.customStatement('DROP TRIGGER fail_text');
          await t.scrollUntilVisible(
            confirm,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pumpAndSettle();
        }
        await t.tap(confirm);
        await t.pumpAndSettle();
        final entries = await db.entriesBetween('2026-10-01', '2026-10-01');
        expect(entries.length, 2);
        expect(entries.map((e) => e.kcal), [150, 200]);
        expect(entries.every((e) => e.meal == MealType.lunch), isTrue);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await db.close();
      }
    });
  }
}
