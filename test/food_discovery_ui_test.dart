import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Roboto', '/Library/Fonts/Arial Unicode.ttf'),
      (
        'MaterialIcons',
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final font = File(path);
      if (font.existsSync()) {
        await (FontLoader(family)..addFont(
              Future.value(ByteData.view(font.readAsBytesSync().buffer)),
            ))
            .load();
      }
    }
  });
  for (final lang in AppLang.values) {
    testWidgets(
      'nutrition sort reset and no-match recovery 320px 2x ${lang.code}',
      (t) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          for (final (name, kcal, protein, fat) in [
            ('自选鸡胸肉', 160.0, 20.0, 4.0),
            ('自选豆腐', 90.0, 10.0, 2.0),
            ('自选米饭', 116.0, 2.0, 0.5),
          ]) {
            await db.upsertFood(
              FoodsCompanion.insert(
                name: name,
                kcal100: kcal,
                protein100: Value(protein),
                fat100: Value(fat),
                source: Value(name == '自选豆腐' ? 'builtin' : 'custom'),
                category: Value(name == '自选米饭' ? 'staple' : 'protein'),
              ),
            );
          }
          final before = await db.exportJson()
            ..remove('exportedAt');
          t.view.physicalSize = const Size(320, 900);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          t.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await t.pumpWidget(
            ProviderScope(
              overrides: [dbProvider.overrideWithValue(db)],
              child: LangScope(
                lang: lang,
                child: MaterialApp(
                  theme: lang == AppLang.es
                      ? buildDarkTheme()
                      : buildLightTheme(),
                  home: const FoodsPage(),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          Future<List<String>> names() async {
            final lists = find.byType(ListView);
            if (lists.evaluate().isEmpty) return [];
            final scroll = find
                .descendant(of: lists.last, matching: find.byType(Scrollable))
                .first;
            final position = t.state<ScrollableState>(scroll).position;
            final names = <String>{};
            position.jumpTo(0);
            await t.pumpAndSettle();
            while (true) {
              names.addAll(
                t
                    .widgetList<FoodListItem>(find.byType(FoodListItem))
                    .map((w) => w.food.name),
              );
              if (position.pixels >= position.maxScrollExtent) break;
              position.jumpTo(
                (position.pixels + 100).clamp(0, position.maxScrollExtent),
              );
              await t.pumpAndSettle();
            }
            position.jumpTo(0);
            await t.pumpAndSettle();
            return names.toList();
          }

          Future<void> menu(String control, String item) async {
            await t.tap(find.byKey(ValueKey(control)));
            await t.pumpAndSettle();
            await t.ensureVisible(find.byKey(ValueKey(item)));
            await t.tap(find.byKey(ValueKey(item)));
            await t.pumpAndSettle();
          }

          await t.enterText(find.byType(TextField).first, '自选');
          await t.pumpAndSettle();
          await menu('food-nutrition-filter', 'nutrition-protein');
          expect((await names()).toSet(), {'自选鸡胸肉', '自选豆腐'});
          await menu('food-discovery-sort', 'food-sort-energy');
          expect(await names(), ['自选豆腐', '自选鸡胸肉']);
          expect(t.takeException(), isNull);
          if (lang == AppLang.zh) {
            final bytes = await t.runAsync(() async {
              final image = await captureImage(
                find.byType(Navigator).evaluate().first,
              );
              return image.toByteData(format: ui.ImageByteFormat.png);
            });
            File('verification/redesign_20260929/smart_discovery_preview.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          }
          await t.tap(find.byKey(const ValueKey('reset-food-discovery')));
          await t.pumpAndSettle();
          expect(
            find.byType(TextField).evaluate().first.widget is TextField,
            isTrue,
          );
          expect(
            (t.widget<TextField>(find.byType(TextField).first))
                .controller!
                .text,
            '自选',
          );
          expect(
            find.text(tText(lang, 'foodResults', {'n': '3'})),
            findsOneWidget,
          );
          await t.enterText(find.byType(TextField).first, '自选米饭');
          await t.pumpAndSettle();
          await menu('food-nutrition-filter', 'nutrition-protein');
          expect(await names(), isEmpty);
          final clear = find.text(tText(lang, 'clearFilters'));
          await t.ensureVisible(clear);
          await t.tap(clear);
          await t.pumpAndSettle();
          expect(
            find.text(tText(lang, 'foodResults', {'n': '3'})),
            findsOneWidget,
          );
          expect(
            (t.widget<TextField>(find.byType(TextField).first))
                .controller!
                .text,
            isEmpty,
          );
          await menu('food-nutrition-filter', 'nutrition-energy');
          expect(await names(), ['自选豆腐']);
          await menu('food-nutrition-filter', 'nutrition-fat');
          expect((await names()).toSet(), {'自选豆腐', '自选米饭'});
          final custom = find.text(tText(lang, 'sourceCustom'));
          await t.ensureVisible(custom);
          await t.tap(custom);
          await t.pumpAndSettle();
          expect(await names(), ['自选米饭']);
          await t.tap(find.byTooltip(tText(lang, 'foodCategory')));
          await t.pumpAndSettle();
          final proteinCategory = find.byWidgetPredicate(
            (w) => w is CheckedPopupMenuItem<String> && w.value == 'protein',
          );
          await t.ensureVisible(proteinCategory);
          await t.tap(proteinCategory);
          await t.pumpAndSettle();
          expect(await names(), isEmpty);
          await menu('food-nutrition-filter', 'nutrition-protein');
          expect(await names(), ['自选鸡胸肉']);
          await t.tap(find.byKey(const ValueKey('reset-food-discovery')));
          await t.pumpAndSettle();
          expect(await names(), ['自选鸡胸肉']); // source/category remain selected
          await t.tap(find.byTooltip(tText(lang, 'clearCategory')));
          await t.pumpAndSettle();
          expect(
            find.text(tText(lang, 'foodResults', {'n': '2'})),
            findsOneWidget,
          );

          expect(
            await db.exportJson()
              ..remove('exportedAt'),
            before,
          );
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(milliseconds: 300));
          await db.close();
        }
      },
    );
  }
}

String tText(
  AppLang lang,
  String key, [
  Map<String, String> values = const {},
]) => t(lang, key, values);
