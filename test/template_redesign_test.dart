import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/main.dart';
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/ui/pages/today_page.dart';
import 'package:kcal_log/ui/pages/stats_page.dart';
import 'package:kcal_log/ui/pages/settings_page.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:kcal_log/logic/food_category.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/food_form.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/sheets/food_picker_sheet.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_category_filter.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

void main() {
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
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
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedIfEmpty(db);
  });
  tearDown(() => db.close());

  Future<Food> apple() async =>
      (await db.searchFoods('苹果')).firstWhere((food) => food.name == '苹果');
  Future<Food> banana() async =>
      (await db.searchFoods('香蕉')).firstWhere((food) => food.name == '香蕉');
  Future<void> mount(
    WidgetTester t, {
    Widget? home,
    double width = 390,
    double scale = 1,
    AppLang lang = AppLang.zh,
    bool dark = false,
  }) async {
    t.view.physicalSize = Size(width, 1050);
    t.view.devicePixelRatio = 1;
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 100));
      t.view.reset();
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: LangScope(
          lang: lang,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? buildDarkTheme() : buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: home ?? const FoodsPage(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> drain(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> newMeal(WidgetTester t, AppLang lang) async {
    await tap(t, find.text(tText(lang, 'templates')));
    await tap(t, find.text(tText(lang, 'newTemplate')));
  }

  Future<void> selectApple(WidgetTester t, AppLang lang) async {
    await tap(t, find.text(tText(lang, 'addFood')));
    await t.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog).last,
            matching: find.byType(TextField),
          )
          .first,
      '水果 苹果',
    );
    await t.pumpAndSettle();
    await tap(
      t,
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.text('苹果'),
      ),
    );
  }

  Future<void> capture(WidgetTester t, String name) async {
    final bytes = await t.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('分类独立于搜索，收藏无结果可恢复，选中返回真实食物', (t) async {
    Food? chosen;
    await mount(
      t,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await showFoodSearchDialog(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tap(t, find.text('open'));
    final field = find.byType(TextField);
    await t.enterText(field, '水果 苹果');
    await t.pumpAndSettle();
    await tap(t, find.byTooltip('食物分类'));
    await tap(
      t,
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<String> && widget.value == 'fruit',
      ),
    );
    expect(
      t.widget<FoodCategoryFilter>(find.byType(FoodCategoryFilter)).selected,
      FoodCategory.fruit,
    );
    expect(
      find.text('${(await db.searchFoods('水果 苹果')).length} 项食物'),
      findsOneWidget,
    );
    await tap(t, find.byTooltip('清除分类'));
    expect(t.widget<TextField>(field).controller!.text, '水果 苹果');
    await tap(t, find.byTooltip('收藏'));
    expect(find.text('0 项食物'), findsOneWidget);
    await tap(t, find.byTooltip('收藏'));
    await tap(t, find.byTooltip('清除搜索'));
    expect(find.text('1000 项食物'), findsOneWidget);
    await t.enterText(field, '不存在xyz');
    await t.pumpAndSettle();
    await tap(t, find.text('清除搜索与筛选'));
    await t.enterText(field, 'fruit 苹果');
    await t.pumpAndSettle();
    await tap(t, find.text('苹果'));
    expect(chosen!.id, (await apple()).id);
    await drain(t);
  });

  testWidgets('创建组合保留小数步进、拒绝非有限输入，保存不产生饮食记录', (t) async {
    await mount(t);
    await newMeal(t, AppLang.zh);
    await t.enterText(find.byKey(const ValueKey('template_name')), '水果餐');
    await selectApple(t, AppLang.zh);
    final grams = find.byKey(
      ValueKey('template_grams_${(await apple()).id}_0'),
    );
    await t.enterText(grams, '2.5');
    await t.pumpAndSettle();
    await tap(t, find.byTooltip('增加 50 克'));
    expect(t.widget<TextField>(grams).controller!.text, '52.5');
    for (final bad in ['NaN', 'Infinity', '-2', '0', '100001', 'abc']) {
      await t.enterText(grams, bad);
      await t.pumpAndSettle();
      await tap(t, find.text('保存'));
      expect(await db.allTemplates(), isEmpty);
      expect(find.text('请输入大于 0、至多 100000 克'), findsOneWidget);
    }
    await t.enterText(grams, '125.25');
    await t.pumpAndSettle();
    await tap(t, find.text('保存'));
    final meals = await db.allTemplates();
    expect(meals.single.name, '水果餐');
    expect((await db.itemsOf(meals.single.id)).single.grams, 125.25);
    expect(await db.recentEntries(), isEmpty);
    await drain(t);
  });

  testWidgets('编辑取消保持原数据，原始精度不变，移除食物后可保存', (t) async {
    final a = await apple(), b = await banana();
    final id = await db.saveTemplate('组合', [(a.id, 125.123456), (b.id, 50)]);
    await mount(t);
    await tap(t, find.text('组合餐'));
    await tap(t, find.text('组合'));
    expect(
      t
          .widget<TextField>(find.byKey(ValueKey('template_grams_${a.id}_0')))
          .controller!
          .text,
      '125.123456',
    );
    await t.enterText(find.byKey(const ValueKey('template_name')), '不会保存');
    await tap(t, find.text('取消'));
    expect((await db.allTemplates()).single.name, '组合');
    await tap(t, find.text('组合'));
    await tap(t, find.byTooltip('移除香蕉'));
    await tap(t, find.text('保存'));
    final items = await db.itemsOf(id);
    expect(items.single.grams, 125.123456);
    expect(items.single.foodId, a.id);
    await drain(t);
  });

  testWidgets('保存失败保持输入并允许重试，事务不留半条组合', (t) async {
    await db.customStatement(
      "CREATE TRIGGER fail_template BEFORE INSERT ON template_items BEGIN SELECT RAISE(ABORT, 'fixture'); END",
    );
    await mount(t);
    await newMeal(t, AppLang.zh);
    await t.enterText(find.byKey(const ValueKey('template_name')), '重试餐');
    await selectApple(t, AppLang.zh);
    await tap(t, find.text('保存'));
    expect(find.text('保存失败'), findsOneWidget);
    expect(await db.allTemplates(), isEmpty);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('template_name')))
          .controller!
          .text,
      '重试餐',
    );
    await db.customStatement('DROP TRIGGER fail_template');
    await tap(t, find.text('保存'));
    expect((await db.allTemplates()).single.name, '重试餐');
    await drain(t);
  });

  test('数据层拒绝无效份量/缺失食物，更新和记录失败均保持原数据', () async {
    final a = await apple(), b = await banana();
    for (final bad in [double.nan, double.infinity, -1.0, 0.0, 100001.0]) {
      await expectLater(
        db.saveTemplate('bad', [(a.id, bad)]),
        throwsArgumentError,
      );
    }
    expect(await db.allTemplates(), isEmpty);
    final id = await db.saveTemplate('safe', [(a.id, 100), (b.id, 50)]);
    await expectLater(
      db.updateTemplate(id, 'bad', [(a.id, 0)]),
      throwsArgumentError,
    );
    expect((await db.allTemplates()).single.name, 'safe');
    expect((await db.itemsOf(id)).length, 2);
    await expectLater(
      db.saveTemplate('missing', [(999999, 100)]),
      throwsStateError,
    );
    await db.customStatement(
      "CREATE TRIGGER fail_entry BEFORE INSERT ON entries WHEN NEW.name = '香蕉' BEGIN SELECT RAISE(ABORT, 'fixture'); END",
    );
    await expectLater(
      db.addEntriesFromTemplate(id, '2026-01-02', MealType.dinner),
      throwsA(anything),
    );
    expect(await db.recentEntries(), isEmpty);
    await db.customStatement('DROP TRIGGER fail_entry');
    expect(
      await db.addEntriesFromTemplate(id, '2026-01-02', MealType.dinner),
      2,
    );
    expect(
      (await db.recentEntries()).every(
        (entry) => entry.date == '2026-01-02' && entry.meal == MealType.dinner,
      ),
      isTrue,
    );
  });

  testWidgets('记录组合先显示日期餐次和kJ预览，取消不写入，双击确认只写一次', (t) async {
    await prefs.setBool('useKj', true);
    final a = await apple(), b = await banana();
    await db.saveTemplate('水果套餐', [(a.id, 200), (b.id, 100)]);
    await mount(
      t,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openAddEntryFlow(
              context,
              date: '2026-01-02',
              meal: MealType.dinner,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tap(t, find.text('open'));
    await tap(t, find.text('水果套餐'));
    expect(find.text('2026-01-02 · 晚餐'), findsOneWidget);
    expect(find.text('苹果 · 200.0 g'), findsOneWidget);
    expect(find.textContaining('kJ'), findsWidgets);
    await capture(t, 'template_review_latest');
    expect(await db.recentEntries(), isEmpty);
    await tap(t, find.text('取消'));
    expect(await db.recentEntries(), isEmpty);
    await tap(t, find.text('水果套餐'));
    final confirmPoint = t.getCenter(find.text('记录组合餐'));
    await t.tapAt(confirmPoint);
    await t.tapAt(confirmPoint);
    await t.pumpAndSettle();
    final entries = await db.recentEntries();
    expect(entries.length, 2);
    expect(
      entries.every(
        (entry) => entry.date == '2026-01-02' && entry.meal == MealType.dinner,
      ),
      isTrue,
    );
    expect(
      entries.fold(0.0, (double sum, entry) => sum + entry.kcal),
      a.kcal100 * 2 + b.kcal100,
    );
    await drain(t);
  });

  testWidgets('整餐写入失败不留部分记录，保持入口可重试', (t) async {
    final a = await apple(), b = await banana();
    await db.saveTemplate('事务餐', [(a.id, 200), (b.id, 100)]);
    await db.customStatement(
      "CREATE TRIGGER fail_entry BEFORE INSERT ON entries WHEN NEW.name = '香蕉' BEGIN SELECT RAISE(ABORT, 'fixture'); END",
    );
    await mount(
      t,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openAddEntryFlow(
              context,
              date: '2026-01-02',
              meal: MealType.dinner,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tap(t, find.text('open'));
    await tap(
      t,
      find.ancestor(of: find.text('事务餐'), matching: find.byType(ActionChip)),
    );
    await tap(t, find.text('记录组合餐'));
    expect(await db.recentEntries(), isEmpty);
    expect(find.byType(FoodPickerSheet), findsOneWidget);
    expect(find.text('保存失败'), findsOneWidget);
    await db.customStatement('DROP TRIGGER fail_entry');
    await tap(
      t,
      find.ancestor(of: find.text('事务餐'), matching: find.byType(ActionChip)),
    );
    await tap(t, find.text('记录组合餐'));
    expect((await db.recentEntries()).length, 2);
    await drain(t);
  });

  testWidgets('320x700双倍字号和键盘下可滚动搜索并选择', (t) async {
    await mount(t, width: 320, scale: 2, lang: AppLang.es, dark: true);
    t.view.physicalSize = const Size(320, 700);
    await newMeal(t, AppLang.es);
    await tap(t, find.text(tText(AppLang.es, 'addFood')));
    t.view.viewInsets = const FakeViewPadding(bottom: 250);
    await t.pumpAndSettle();
    await t.enterText(
      find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.byType(TextField),
      ),
      '水果 苹果',
    );
    await t.pumpAndSettle();
    await tap(t, find.text('苹果'));
    expect(t.takeException(), isNull);
    t.view.resetViewInsets();
    await t.pumpAndSettle();
    await drain(t);
  });

  testWidgets('完整App贯穿分类选食物、组合创建、历史晚餐、统计和能量单位', (t) async {
    await mount(t);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: const KcalLogApp(),
      ),
    );
    await t.pumpAndSettle();
    await tap(t, find.text('食物库'));
    await newMeal(t, AppLang.zh);
    await t.enterText(find.byKey(const ValueKey('template_name')), '完整流程餐');
    await selectApple(t, AppLang.zh);
    await t.enterText(
      find.byKey(ValueKey('template_grams_${(await apple()).id}_0')),
      '100',
    );
    await t.pumpAndSettle();
    await tap(t, find.text('保存'));
    expect(await db.recentEntries(), isEmpty);
    await tap(t, find.text('今日'));
    await tap(t, find.byKey(const ValueKey('today-previous-day')));
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    Future<void> reveal(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await t.scrollUntilVisible(
          finder,
          250,
          scrollable: find
              .descendant(
                of: find.byType(TodayPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      } else {
        await t.ensureVisible(finder);
      }
      await t.pumpAndSettle();
    }

    await reveal(find.byKey(const ValueKey('meal-node-dinner')));
    await tap(t, find.byKey(const ValueKey('meal-node-dinner')));
    await reveal(find.byKey(const ValueKey('meal-progress-add')));
    await tap(t, find.byKey(const ValueKey('meal-progress-add')));
    await tap(
      t,
      find.ancestor(of: find.text('完整流程餐'), matching: find.byType(ActionChip)),
    );
    expect(find.text('$yesterday · 晚餐'), findsOneWidget);
    await tap(t, find.text('记录组合餐'));
    final entries = await db.recentEntries();
    expect(entries.single.date, yesterday);
    expect(entries.single.meal, MealType.dinner);
    expect(entries.single.kcal, 52);
    expect(
      entries.where((entry) => entry.date == dateKey(DateTime.now())),
      isEmpty,
    );
    await tap(t, find.text('统计'));
    expect(find.byType(StatsPage), findsOneWidget);
    await tap(t, find.byKey(const ValueKey('stats-daily-details')));
    expect(find.textContaining(yesterday), findsWidgets);
    await tap(t, find.text('设置'));
    final unitSwitch = find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(CupertinoSwitch),
    );
    if (unitSwitch.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        unitSwitch,
        250,
        scrollable: find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.pumpAndSettle();
    }
    await tap(t, unitSwitch);
    expect(prefs.getBool('useKj'), isTrue);
    await tap(t, find.text('统计'));
    expect(find.textContaining('kJ'), findsWidgets);
    await tap(t, find.text('食物库'));
    await tap(t, find.text('食物'));
    await t.enterText(find.byType(TextField).first, '水果 苹果');
    await t.pumpAndSettle();
    expect(find.byType(FoodListItem), findsWidgets);
    expect(find.descendant(of: find.byType(FoodListItem), matching: find.text('苹果')), findsOneWidget);
    final expectedAppleIds = (await db.searchFoods('水果 苹果'))
        .map((f) => f.id)
        .toSet();
    expect(expectedAppleIds.length, greaterThan(1));
    for (final widget in t.widgetList<FoodListItem>(
      find.byType(FoodListItem),
    )) {
      expect(expectedAppleIds, contains(widget.food.id));
    }
    expect(await db.foodCount(), 1000);
    await capture(t, 'redesign_final_food_library');
    expect(t.takeException(), isNull);
    await drain(t);
  });

  for (final (lang, width, scale, dark, name) in [
    (AppLang.zh, 390.0, 1.0, false, 'template_editor_latest'),
    (AppLang.zh, 320.0, 2.0, true, 'template_editor_accessible_latest'),
    (AppLang.en, 320.0, 2.0, true, 'template_editor_accessible_en'),
    (AppLang.es, 320.0, 2.0, true, 'template_editor_accessible_es'),
    (AppLang.zh, 1280.0, 1.0, false, 'template_editor_desktop_latest'),
  ]) {
    testWidgets('组合餐完整布局 ${lang.code} $width $scale', (t) async {
      await mount(t, width: width, scale: scale, lang: lang, dark: dark);
      await newMeal(t, lang);
      await t.enterText(find.byKey(const ValueKey('template_name')), '水果早餐');
      await selectApple(t, lang);
      await t.ensureVisible(find.byTooltip(tText(lang, 'templateLess')));
      await t.pumpAndSettle();
      final step = find
          .ancestor(
            of: find.byTooltip(tText(lang, 'templateLess')),
            matching: find.byType(IconButton),
          )
          .first;
      // Tooltip is inside IconButton on current Flutter; also test semantics via the actionable widget.
      final action = step.evaluate().isEmpty
          ? find.byTooltip(tText(lang, 'templateLess'))
          : step;
      expect(t.getSize(action).width, greaterThanOrEqualTo(44));
      expect(t.getSize(action).height, greaterThanOrEqualTo(44));
      await capture(t, name);
      await tap(t, find.text(tText(lang, 'addFood')));
      t.view.viewInsets = const FakeViewPadding(bottom: 250);
      await t.pumpAndSettle();
      await t.enterText(
        find.descendant(
          of: find.byType(AlertDialog).last,
          matching: find.byType(TextField),
        ),
        '水果 苹果',
      );
      await t.pumpAndSettle();
      expect(find.byType(FoodListItem), findsWidgets);
      expect(find.descendant(of: find.byType(FoodListItem), matching: find.text('苹果')), findsOneWidget);
      final expectedAppleIds = (await db.searchFoods('水果 苹果'))
          .map((f) => f.id)
          .toSet();
      expect(expectedAppleIds.length, greaterThan(1));
      for (final widget in t.widgetList<FoodListItem>(
        find.byType(FoodListItem),
      )) {
        expect(expectedAppleIds, contains(widget.food.id));
      }
      await capture(t, '${name}_search');
      expect(t.takeException(), isNull);
      await tap(
        t,
        find.descendant(
          of: find.byType(AlertDialog).last,
          matching: find.text(tText(lang, 'cancel')),
        ),
      );
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      await tap(t, find.text(tText(lang, 'cancel')));
      expect(await db.allTemplates(), isEmpty);
      await drain(t);
    });
  }
}

String tText(AppLang lang, String key) => t(lang, key);
