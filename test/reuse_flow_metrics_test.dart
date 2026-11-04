import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/pages/today_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> snap(WidgetTester t, String name) async {
  final bytes = await t.runAsync(() async {
    final image = await captureImage(find.byType(Navigator).evaluate().first);
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  final output = File('verification/redesign_20260929/$name');
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    for (final (family, paths) in [
      ('Roboto', ['/Library/Fonts/Arial Unicode.ttf']),
      (
        'MaterialIcons',
        [
          '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ],
      ),
    ]) {
      final loader = FontLoader(family);
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) {
          loader.addFont(
            Future.value(ByteData.view(file.readAsBytesSync().buffer)),
          );
        }
      }
      await loader.load();
    }
  });
  testWidgets('controlled three-food logging action and search metrics', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now();
    final today = dateKey(now),
        yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
    try {
      final foods = <Food>[];
      for (final name in ['甲米饭', '乙豆腐', '丙鸡蛋']) {
        final f = await db.upsertFood(
          FoodsCompanion.insert(name: name, kcal100: 100),
        );
        foods.add(f);
        await db.addEntry(
          EntriesCompanion.insert(
            date: yesterday,
            meal: currentMealType(),
            name: f.name,
            foodId: Value(f.id),
            grams: const Value(100),
            kcal: 100,
          ),
        );
      }
      var hits = 0;
      for (final f in foods) {
        final matches = await db.searchFoods(f.name);
        if (matches.isNotEmpty && matches.first.id == f.id) hits++;
      }
      expect(hits, 3);
      t.view.physicalSize = const Size(1200, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      Future<void> page(Widget page) async {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              prefsProvider.overrideWithValue(prefs),
            ],
            child: LangScope(
              lang: AppLang.zh,
              child: MaterialApp(theme: buildLightTheme(), home: page),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await page(const FoodsPage());
      var manualActions = 0;
      for (final f in foods) {
        await t.enterText(find.byType(TextField).first, f.name);
        manualActions++;
        await t.pumpAndSettle();
        await t.tap(
          find
              .descendant(
                of: find.byType(FoodListItem),
                matching: find.text(f.name),
              )
              .first,
        );
        manualActions++;
        await t.pumpAndSettle();
        if (f.id == foods.first.id) await snap(t, 'acceptance_desktop.png');
        final save = find.descendant(
          of: find.byKey(const ValueKey('desktop-food-portion')),
          matching: find.text(tText(AppLang.zh, 'addEntry')),
        );
        await t.tap(save);
        manualActions++;
        await t.pumpAndSettle();
      }
      expect((await db.entriesBetween(today, today)).length, 3);
      // Reset only this in-memory fixture to compare equal starting conditions.
      await (db.delete(db.entries)..where((e) => e.date.equals(today))).go();
      t.view.physicalSize = const Size(500, 1600);
      await page(const TodayPage());
      var reuseActions = 0;
      await t.tap(find.byKey(const ValueKey('copy-day-open')));
      reuseActions++;
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('copy-meal-confirm')));
      reuseActions++;
      await t.pumpAndSettle();
      await snap(t, 'acceptance_reuse_result.png');
      final copied = await db.entriesBetween(today, today);
      expect(copied.length, 3);
      expect(copied.every((e) => e.grams == 100 && e.kcal == 100), isTrue);
      await t.tap(find.text(tText(AppLang.zh, 'undo')));
      await t.pumpAndSettle();
      expect(await db.entriesBetween(today, today), isEmpty);
      expect((await db.entriesBetween(yesterday, yesterday)).length, 3);
      // Literal fixture measurements are test evidence, not production logging.
      // ignore: avoid_print
      print(
        'CONTROLLED_FIXTURE: SEARCH_TOP1=$hits/3;MANUAL_READY_SCREEN_ACTIONS=$manualActions;WHOLE_DAY_REUSE_TAPS=$reuseActions;COPIED_ROWS=${copied.length};UNDO_TAPS=1;REMAINING_TODAY_ROWS=0;REAL_USER_STUDY=NOT_RUN',
      );
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 200));
      await db.close();
    }
  });
}

String tText(AppLang lang, String key) => t(lang, key);
