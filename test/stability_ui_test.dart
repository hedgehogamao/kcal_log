import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/logic/food_search_worker.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';
import 'package:kcal_log/ui/widgets/scroll_scale_reveal.dart';

class CountingDb extends AppDatabase {
  CountingDb({this.failFirst = false})
    : super.forTesting(NativeDatabase.memory());
  final bool failFirst;
  final calls = <String>[];
  @override
  Stream<List<Food>> watchFoods(String query, {bool favoritesOnly = false}) {
    calls.add(query);
    if (failFirst && calls.length == 1) {
      return Stream.error(const FoodSearchFailure('workerFailed'));
    }
    return super.watchFoods(query, favoritesOnly: favoritesOnly);
  }
}

Future<void> mount(WidgetTester t, CountingDb db, AppLang lang) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  for (var i = 0; i < 8; i++) {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '鸡胸肉$i',
        kcal100: 123,
        protein100: const Value(25),
        category: const Value('protein'),
      ),
    );
  }
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
}

Future<void> close(WidgetTester t, AppDatabase db) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(milliseconds: 200));
  await t.runAsync(db.close);
}

void main() {
  for (final lang in AppLang.values) {
    testWidgets(
      'search failure is localized and retry recovers without changing data ${lang.code}',
      (t) async {
        final db = CountingDb(failFirst: true);
        try {
          await mount(t, db, lang);
          final before = AutoBackupService.contentHash(await db.exportJson());
          expect(
            find.byKey(const ValueKey('food-search-error')),
            findsOneWidget,
          );
          expect(find.byType(CircularProgressIndicator), findsNothing);
          await t.tap(find.byKey(const ValueKey('food-search-retry')));
          await t.pumpAndSettle();
          expect(find.byType(FoodListItem), findsWidgets);
          expect(AutoBackupService.contentHash(await db.exportJson()), before);
          expect(t.takeException(), isNull);
        } finally {
          await close(t, db);
        }
      },
    );
  }
  testWidgets(
    'selection and sort reuse one stream; rapid typing searches latest only and hides stale rows',
    (t) async {
      final db = CountingDb();
      try {
        await mount(t, db, AppLang.zh);
        expect(db.calls, ['']);
        await t.tap(find.byType(FoodListItem).first);
        await t.pumpAndSettle();
        expect(db.calls, ['']);
        await t.tap(find.byKey(const ValueKey('food-discovery-sort')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('food-sort-protein')));
        await t.pumpAndSettle();
        expect(db.calls, ['']);
        final field = find.byType(TextField).first;
        for (final q in ['j', 'jx', 'jxr']) {
          await t.enterText(field, q);
          await t.pump(const Duration(milliseconds: 20));
        }
        expect(db.calls, ['']);
        expect(find.byType(FoodListItem), findsNothing);
        await t.pumpAndSettle();
        expect(db.calls, ['', 'jxr']);
        expect(find.byType(FoodListItem), findsWidgets);
        expect(await db.select(db.entries).get(), isEmpty);
        expect(t.takeException(), isNull);
      } finally {
        await close(t, db);
      }
    },
  );
  testWidgets(
    'clear cancels a pending query and overlong input is recoverable',
    (t) async {
      final db = CountingDb();
      try {
        await mount(t, db, AppLang.zh);
        final field = find.byType(TextField).first;
        await t.enterText(field, 'jxr');
        await t.pump(const Duration(milliseconds: 20));
        await t.tap(find.byTooltip(tText(AppLang.zh, 'clearSearch')));
        await t.pumpAndSettle();
        expect(db.calls, ['']);
        await t.enterText(field, 'a' * 257);
        await t.pumpAndSettle();
        expect(find.text(tText(AppLang.zh, 'searchTooLong')), findsOneWidget);
        await t.tap(find.byTooltip(tText(AppLang.zh, 'clearSearch')));
        await t.pumpAndSettle();
        expect(find.byType(FoodListItem), findsWidgets);
        expect(t.takeException(), isNull);
      } finally {
        await close(t, db);
      }
    },
  );
  testWidgets(
    'fully visible rows avoid transform layers while edge scale is retained',
    (t) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      t.view.physicalSize = const Size(400, 400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemExtent: 100,
              itemCount: 30,
              itemBuilder: (_, i) => ScrollScaleReveal(
                key: ValueKey('row-$i'),
                child: Text('row $i'),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      controller.jumpTo(60);
      await t.pump();
      RenderScrollScaleReveal row(int i) =>
          t.renderObject<RenderScrollScaleReveal>(
            find.descendant(
              of: find.byKey(ValueKey('row-$i')),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_ScalePaint',
              ),
            ),
          );
      expect(row(2).scale, 1);
      expect(row(2).debugLayer, isNull);
      expect(row(4).scale, lessThan(1));
      expect(row(4).debugLayer, isA<TransformLayer>());
      expect(t.takeException(), isNull);
    },
  );
}

String tText(AppLang lang, String key) => t(lang, key);
