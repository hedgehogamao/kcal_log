import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final lang in AppLang.values) {
    testWidgets('visible filter values at 320px and 2x ${lang.code}', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.upsertFood(FoodsCompanion.insert(name: '示例食物', kcal100: 100));
        t.view.physicalSize = const Size(320, 1000);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              prefsProvider.overrideWithValue(prefs),
            ],
            child: LangScope(
              lang: lang,
              child: const MaterialApp(home: FoodsPage()),
            ),
          ),
        );
        await t.pumpAndSettle();
        final filter = find.byKey(const ValueKey('food-nutrition-filter'));
        final sort = find.byKey(const ValueKey('food-discovery-sort'));
        expect(
          find.descendant(
            of: filter,
            matching: find.textContaining(tText(lang, 'nutritionFilter')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sort,
            matching: find.textContaining(tText(lang, 'foodSort')),
          ),
          findsOneWidget,
        );
        await t.tap(filter);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('nutrition-energy')));
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: filter,
            matching: find.textContaining(tText(lang, 'nutritionEnergy')),
          ),
          findsOneWidget,
        );
        expect(await db.select(db.entries).get(), isEmpty);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await db.close();
      }
    });
  }
}

String tText(AppLang lang, String key) => t(lang, key);
