import 'package:drift/drift.dart' show Value;
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
    testWidgets(
      'desktop selection, per-100g and per-serving, switching and save ${lang.code}',
      (t) async {
        SharedPreferences.setMockInitialValues({'useKj': lang == AppLang.es});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          await db.upsertFood(
            FoodsCompanion.insert(
              name: '甲米饭',
              kcal100: 100,
              servingGrams: const Value(100),
              servingDesc: const Value('一份'),
            ),
          );
          await db.upsertFood(
            FoodsCompanion.insert(
              name: '乙豆腐',
              kcal100: 200,
              servingGrams: const Value(200),
              servingDesc: const Value('一大份'),
              source: const Value('pack'),
            ),
          );
          t.view.physicalSize = const Size(1200, 900);
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
                child: const MaterialApp(home: FoodsPage()),
              ),
            ),
          );
          await t.pumpAndSettle();
          final pane = find.byKey(const ValueKey('desktop-food-preview'));
          expect(pane, findsOneWidget);
          await t.tap(find.text('甲米饭').first);
          await t.pumpAndSettle();
          expect(await db.select(db.entries).get(), isEmpty);
          final part = find.byKey(const ValueKey('desktop-food-portion'));
          expect(part, findsOneWidget);
          Finder grams() =>
              find.descendant(of: part, matching: find.byType(TextField));
          expect(t.widget<TextField>(grams()).controller!.text, '100.0');
          await t.enterText(grams(), '50');
          await t.pumpAndSettle();
          expect(await db.select(db.entries).get(), isEmpty);
          await t.tap(find.text('乙豆腐').first);
          await t.pumpAndSettle();
          expect(t.widget<TextField>(grams()).controller!.text, '200.0');
          expect(
            find.descendant(of: part, matching: find.textContaining('每100g')),
            lang == AppLang.zh ? findsOneWidget : findsNothing,
          );
          if (lang == AppLang.es) {
            expect(
              find.descendant(of: part, matching: find.textContaining('kJ')),
              findsWidgets,
            );
          }
          final save = find.descendant(
            of: part,
            matching: find.text(tText(lang, 'addEntry')),
          );
          await t.ensureVisible(save);
          await t.tap(save);
          await t.pumpAndSettle();
          final entries = await db.select(db.entries).get();
          expect(entries.length, 1);
          expect(entries.single.name, '乙豆腐');
          expect(entries.single.grams, 200);
          expect(entries.single.kcal, 400);
          expect(
            find.byKey(const ValueKey('desktop-food-portion')),
            findsNothing,
          );
          expect(find.byType(FoodsPage), findsOneWidget);
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(milliseconds: 200));
          await db.close();
        }
      },
    );
  }
  testWidgets(
    'narrow screen retains modal and does not create entry until confirmed',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.upsertFood(FoodsCompanion.insert(name: '窄屏米饭', kcal100: 100));
        t.view.physicalSize = const Size(390, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              prefsProvider.overrideWithValue(p),
            ],
            child: const LangScope(
              lang: AppLang.zh,
              child: MaterialApp(home: FoodsPage()),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('desktop-food-preview')),
          findsNothing,
        );
        await t.tap(find.text('窄屏米饭'));
        await t.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(await db.select(db.entries).get(), isEmpty);
        Navigator.of(t.element(find.byType(BottomSheet))).pop();
        await t.pumpAndSettle();
        expect(await db.select(db.entries).get(), isEmpty);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await db.close();
      }
    },
  );
}

String tText(AppLang lang, String key) => t(lang, key);
