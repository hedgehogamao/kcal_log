import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup.dart';
import 'package:kcal_log/logic/food_category.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/widgets/food_category_filter.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

final list = find.byKey(const PageStorageKey('food-library-list'));
final category = find.byType(FoodCategoryFilter);
NestedScrollViewState scrollState(WidgetTester t) =>
    t.state<NestedScrollViewState>(
      find.byKey(const ValueKey('food-library-scroll')),
    );
Future<AppDatabase> mount(
  WidgetTester t, {
  AppLang lang = AppLang.zh,
  Size size = const Size(390, 900),
  double textScale = 1,
  bool reduce = false,
  int count = 100,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  for (var i = 0; i < count; i++) {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: i.isEven ? '米饭$i' : '鸡胸肉$i',
        kcal100: 100,
        protein100: Value(i.isEven ? 3 : 25),
        category: Value(i.isEven ? 'staple' : 'protein'),
        source: Value(i < 25 ? 'custom' : 'builtin'),
      ),
    );
  }
  t.view.physicalSize = size;
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
        child: MaterialApp(
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduce,
            ),
            child: w!,
          ),
          home: const FoodsPage(),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return db;
}

Future<void> close(WidgetTester t, AppDatabase db) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(milliseconds: 200));
  await t.runAsync(db.close);
}

Future<void> hide(WidgetTester t) async {
  await t.drag(list, const Offset(0, -650));
  await t.pumpAndSettle();
  expect(category.hitTestable(), findsNothing);
}

Future<void> reveal(WidgetTester t) async {
  await t.drag(list, const Offset(0, 100));
  await t.pumpAndSettle();
  expect(category.hitTestable(), findsOneWidget);
}

void main() {
  for (final lang in AppLang.values) {
    for (final wide in [false, true]) {
      testWidgets(
        'scroll management and use category, sort, search mid-list ${lang.code} wide=$wide',
        (t) async {
          final db = await mount(
            t,
            lang: lang,
            size: wide ? const Size(1200, 900) : const Size(390, 900),
          );
          try {
            final before = AutoBackupService.contentHash(await db.exportJson());
            await hide(t);
            final offset = scrollState(t).innerController.offset;
            expect(offset, greaterThan(0));
            await reveal(t);
            expect(
              scrollState(t).innerController.offset,
              greaterThan(0),
              reason: 'Reverse drag must not jump to list start',
            );
            expect(scrollState(t).innerController.positions.length, 1);
            await t.tap(find.byTooltip(tText(lang, 'foodCategory')));
            await t.pumpAndSettle();
            await t.tap(
              find.byWidgetPredicate(
                (w) =>
                    w is CheckedPopupMenuItem<String> && w.value == 'protein',
              ),
            );
            await t.pumpAndSettle();
            expect(
              t.widget<FoodCategoryFilter>(category).selected,
              FoodCategory.protein,
            );
            expect(find.byType(FoodListItem), findsWidgets);
            for (final row in t.widgetList<FoodListItem>(
              find.byType(FoodListItem),
            )) {
              expect(row.food.category, 'protein');
            }
            await t.tap(find.byKey(const ValueKey('food-discovery-sort')));
            await t.pumpAndSettle();
            await t.tap(find.byKey(const ValueKey('food-sort-protein')));
            await t.pumpAndSettle();
            await t.enterText(find.byType(TextField).first, 'jxr');
            await t.pumpAndSettle();
            expect(
              t
                  .widget<TextField>(find.byType(TextField).first)
                  .controller!
                  .text,
              'jxr',
            );
            await hide(t);
            await reveal(t);
            expect(
              t.widget<FoodCategoryFilter>(category).selected,
              FoodCategory.protein,
            );
            expect(
              t
                  .widget<TextField>(find.byType(TextField).first)
                  .controller!
                  .text,
              'jxr',
            );
            await t.tap(find.byTooltip(tText(lang, 'clearCategory')));
            await t.pumpAndSettle();
            expect(t.widget<FoodCategoryFilter>(category).selected, isNull);
            expect(
              AutoBackupService.contentHash(await db.exportJson()),
              before,
            );
            expect(t.takeException(), isNull);
          } finally {
            await close(t, db);
          }
        },
      );
    }
  }
  for (final reduce in [false, true]) {
    testWidgets(
      'small window large text measures management height and stays usable reduce=$reduce',
      (t) async {
        final db = await mount(
          t,
          size: const Size(320, 720),
          textScale: 2,
          reduce: reduce,
        );
        try {
          expect(t.takeException(), isNull);
          await hide(t);
          await reveal(t);
          await t.tap(find.byTooltip(tText(AppLang.zh, 'foodCategory')));
          await t.pumpAndSettle();
          await t.tap(
            find.byWidgetPredicate(
              (w) => w is CheckedPopupMenuItem<String> && w.value == 'staple',
            ),
          );
          await t.pumpAndSettle();
          expect(
            t.widget<FoodCategoryFilter>(category).selected,
            FoodCategory.staple,
          );
          expect(t.takeException(), isNull);
        } finally {
          await close(t, db);
        }
      },
    );
  }
  testWidgets('mouse wheel hides management and reverses to show it mid-list', (
    t,
  ) async {
    final db = await mount(t, size: const Size(1200, 900));
    try {
      final position = t.getCenter(list);
      t.binding.handlePointerEvent(
        PointerScrollEvent(
          position: position,
          scrollDelta: const Offset(0, 800),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await t.pumpAndSettle();
      expect(category.hitTestable(), findsNothing);
      t.binding.handlePointerEvent(
        PointerScrollEvent(
          position: position,
          scrollDelta: const Offset(0, -120),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await t.pumpAndSettle();
      expect(category.hitTestable(), findsOneWidget);
      expect(scrollState(t).innerController.offset, greaterThan(0));
      expect(t.takeException(), isNull);
    } finally {
      await close(t, db);
    }
  });
  testWidgets(
    'vertical dragging over management itself scrolls the same list',
    (t) async {
      final db = await mount(t);
      try {
        await t.drag(category, const Offset(0, -550));
        await t.pumpAndSettle();
        expect(category.hitTestable(), findsNothing);
        await reveal(t);
        expect(t.takeException(), isNull);
      } finally {
        await close(t, db);
      }
    },
  );
  testWidgets(
    'desktop selected portion stays independent while list management collapses',
    (t) async {
      final db = await mount(t, size: const Size(1200, 900));
      try {
        await t.tap(find.byType(FoodListItem).first);
        await t.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('desktop-food-portion')),
          findsOneWidget,
        );
        await hide(t);
        await reveal(t);
        expect(
          find.byKey(const ValueKey('desktop-food-portion')),
          findsOneWidget,
        );
        expect(scrollState(t).innerController.positions.length, 1);
        expect(await db.select(db.entries).get(), isEmpty);
        expect(t.takeException(), isNull);
      } finally {
        await close(t, db);
      }
    },
  );
  testWidgets(
    'no-results state still has usable category and clearing search recovers',
    (t) async {
      final db = await mount(t, size: const Size(320, 720), textScale: 2);
      try {
        await hide(t);
        await reveal(t);
        await t.enterText(find.byType(TextField).first, 'does-not-exist-123');
        await t.pumpAndSettle();
        final clear = find.text(tText(AppLang.zh, 'clearFilters'));
        await t.ensureVisible(clear);
        await t.tap(clear);
        await t.pumpAndSettle();
        expect(find.byType(FoodListItem), findsWidgets);
        expect(category.hitTestable(), findsOneWidget);
        expect(t.takeException(), isNull);
      } finally {
        await close(t, db);
      }
    },
  );
}

String tText(AppLang lang, String key) => t(lang, key);
