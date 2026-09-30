import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/main.dart';
import 'package:kcal_log/ui/pages/today_page.dart';
import 'package:kcal_log/ui/sheets/entry_sheet.dart';
import 'package:kcal_log/ui/sheets/food_picker_sheet.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';
import 'package:kcal_log/ui/widgets/meal_progress_card.dart';

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Roboto', '/Library/Fonts/Arial Unicode.ttf'),
      (
        'MaterialIcons',
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
      (
        'packages/cupertino_icons/CupertinoIcons',
        '/Users/zhuang/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf',
      ),
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        await (FontLoader(
              family,
            )..addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer))))
            .load();
      }
    }
  });
  late AppDatabase db;
  late String today;
  late Food rice;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    today = dateKey(DateTime.now());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedIfEmpty(db);
    rice = (await db.searchFoods('米饭')).firstWhere((e) => e.name == '米饭');
    await db.saveProfile(
      ProfilesCompanion(id: const Value(1), kcalGoal: const Value(1800)),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: today,
        meal: MealType.lunch,
        name: rice.name,
        foodId: Value(rice.id),
        grams: const Value(200),
        kcal: 232,
        protein: const Value(5.2),
        fat: const Value(0.6),
        carb: const Value(51.8),
      ),
    );
    await db.addWater(today, 750);
  });
  tearDown(() => db.close());
  Future<List<FoodEntry>> entriesFor(String day) =>
      (db.select(db.entries)..where((e) => e.date.equals(day))).get();
  Future<WaterRec?> waterFor(String day) => (db.select(
    db.waters,
  )..where((e) => e.date.equals(day))).getSingleOrNull();
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> open(
    WidgetTester tester, {
    AppLang lang = AppLang.zh,
    bool dark = false,
    double width = 390,
    double scale = 1,
    bool kj = false,
    int waterGoal = 2000,
  }) async {
    SharedPreferences.setMockInitialValues({
      'lang': lang.code,
      'useKj': kj,
      'themeMode': (dark ? ThemeMode.dark : ThemeMode.light).index,
      'waterGoalMl': waterGoal,
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(width, 1050);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    addTearDown(() => drain(tester));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1050),
            textScaler: TextScaler.linear(scale),
          ),
          child: const KcalLogApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(TodayPage))).scale(10),
      scale * 10,
    );
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    bool reverse = false,
  }) async {
    if (finder.evaluate().isEmpty) {
      final scrollable = find
          .descendant(
            of: find.byType(TodayPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        finder,
        reverse ? -300 : 300,
        scrollable: scrollable,
      );
    } else {
      await tester.ensureVisible(finder);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('完整应用首页：热量明确、计算说明不会隐藏总览', (tester) async {
    await open(tester);
    expect(find.text('1568 kcal'), findsOneWidget);
    expect(find.text('每日目标：1800 kcal'), findsOneWidget);
    await capture(tester, 'today_redesign_latest');
    final help = find.byKey(const ValueKey('today-calculation-help'));
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.text('数字是怎么算的'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('1568 kcal'), findsOneWidget);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('历史日期与选中餐次贯穿分类搜索到份量确认', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('today-previous-day')));
    await tester.pumpAndSettle();
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    expect(find.byKey(const ValueKey('today-back-to-now')), findsOneWidget);
    final node = find.byKey(const ValueKey('meal-node-dinner'));
    await reveal(tester, node);
    await tester.tap(node);
    await tester.pumpAndSettle();
    final add = find.byKey(const ValueKey('meal-progress-add'));
    await reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    final picker = tester.widget<FoodPickerSheet>(find.byType(FoodPickerSheet));
    expect(picker.date, yesterday);
    expect(picker.meal, MealType.dinner);
    await tester.enterText(find.byType(TextField).first, '水果 苹果');
    await tester.pumpAndSettle();
    final apple = find.byWidgetPredicate(
      (w) => w is FoodListItem && w.food.name == '苹果',
    );
    expect(apple, findsOneWidget);
    await tester.tap(apple);
    await tester.pumpAndSettle();
    expect(tester.widget<EntrySheet>(find.byType(EntrySheet)).date, yesterday);
    expect(
      tester.widget<EntrySheet>(find.byType(EntrySheet)).meal,
      MealType.dinner,
    );
    await tester.enterText(find.byType(TextField).last, '200');
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认记录'));
    await tester.pumpAndSettle();
    final rows = await entriesFor(yesterday);
    expect(rows, hasLength(1));
    expect(rows.single.name, '苹果');
    expect(rows.single.meal, MealType.dinner);
    expect(rows.single.grams, 200);
    expect(rows.single.kcal, 104);
    expect(await entriesFor(today), hasLength(1));
    // Picker remains available for another food; dismiss it before returning to today.
    if (find.byType(FoodPickerSheet).evaluate().isNotEmpty) {
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
    final back = find.byKey(const ValueKey('today-back-to-now'));
    await reveal(tester, back, reverse: true);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-back-to-now')), findsNothing);
    await reveal(
      tester,
      find.byKey(const ValueKey('today-next-day')),
      reverse: true,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('today-next-day')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('饮水加减只影响正在查看的日期，历史日可回到今天', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('today-previous-day')));
    await tester.pumpAndSettle();
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final add = find.byKey(const ValueKey('today-water-add'));
    await reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect((await waterFor(yesterday))!.ml, 250);
    final remove = find.byKey(const ValueKey('today-water-remove'));
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect((await waterFor(yesterday))!.ml, 0);
    expect((await waterFor(today))!.ml, 750);
    expect(tester.widget<OutlinedButton>(remove).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('记录可编辑、左滑删除并撤销恢复营养快照', (tester) async {
    await open(tester);
    final original = (await entriesFor(today)).single;
    final row = find.byKey(ValueKey('entry-${original.id}'));
    await reveal(tester, row);
    await tester.tap(
      find.descendant(of: row, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(EntrySheet), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    final edited = (await entriesFor(today)).single;
    expect(edited.id, original.id);
    expect(edited.kcal, 116);
    expect(edited.grams, 100);
    await reveal(tester, row);
    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(await entriesFor(today), isEmpty);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    final restored = (await entriesFor(today)).single;
    expect(restored.name, edited.name);
    expect(restored.kcal, edited.kcal);
    expect(restored.grams, edited.grams);
    expect(restored.protein, edited.protein);
    expect(restored.fat, edited.fat);
    expect(restored.carb, edited.carb);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  for (final lang in AppLang.values) {
    testWidgets('今日页 320px、2倍字号、深色和 kJ，完整内容滚动可读：${lang.code}', (tester) async {
      await open(
        tester,
        lang: lang,
        dark: true,
        width: 320,
        scale: 2,
        kj: true,
      );
      expect(tester.takeException(), isNull);
      final progress = find.byType(MealProgressCard);
      await reveal(tester, progress);
      expect(tester.takeException(), isNull);
      if (lang == AppLang.zh) {
        await capture(tester, 'today_redesign_accessible_latest');
      }
      final water = find.byKey(const ValueKey('today-water-add'));
      await reveal(tester, water);
      expect(tester.takeException(), isNull);
      final entry = find.byType(Dismissible);
      await reveal(tester, entry);
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }
  testWidgets('宽屏今日内容居中限制宽度，不拉满窗口', (tester) async {
    await open(tester, width: 1280);
    expect(find.byType(NavigationRail), findsOneWidget);
    final list = find.descendant(
      of: find.byType(TodayPage),
      matching: find.byType(ListView),
    );
    expect(tester.getSize(list).width, lessThanOrEqualTo(960));
    await capture(tester, 'today_redesign_desktop_latest');
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('未设置饮水目标不展示无限加载进度', (tester) async {
    await open(tester, waterGoal: 0);
    final add = find.byKey(const ValueKey('today-water-add'));
    await reveal(tester, add);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
}
