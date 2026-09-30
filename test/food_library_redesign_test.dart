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
import 'package:kcal_log/main.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/food_category.dart';
import 'package:kcal_log/ui/food_form.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/sheets/food_picker_sheet.dart';
import 'package:kcal_log/ui/sheets/entry_sheet.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Roboto', '/Library/Fonts/Arial Unicode.ttf'),
      ('Ahem', '/Library/Fonts/Arial Unicode.ttf'),
      (
        'MaterialIcons',
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
      (
        'packages/cupertino_icons/CupertinoIcons',
        '/Users/zhuang/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf',
      ),
    ]) {
      final font = File(path);
      if (font.existsSync()) {
        final loader = FontLoader(family)
          ..addFont(Future.value(ByteData.view(font.readAsBytesSync().buffer)));
        await loader.load();
      }
    }
  });

  late AppDatabase db;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        source: const Value('builtin'),
        category: const Value('staple'),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '番茄炒蛋',
        kcal100: 87,
        source: const Value('builtin'),
        category: const Value('dish'),
        protein100: const Value(4.5),
        fat100: const Value(6),
        carb100: const Value(4.5),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '我的早餐',
        kcal100: 250,
        category: const Value('dish'),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '燕麦饮',
        kcal100: 45,
        brand: const Value('OATLY'),
        category: const Value('drink'),
      ),
    );
  });
  tearDown(() => db.close());

  testWidgets('食物库分组可读，别名搜索与清除搜索正常', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: const FoodsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('4 种食物'), findsOneWidget);
    expect(find.text('我的食物 · 2'), findsOneWidget);
    expect(find.text('内置 · 2'), findsOneWidget);
    expect(find.text('主食 · 内置'), findsOneWidget);
    expect(find.text('饮品 · 自定义 · OATLY'), findsOneWidget);

    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/food_library_mobile.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());

    await tester.enterText(find.byType(TextField).first, '西红柿');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('番茄炒蛋'), findsOneWidget);
    expect(find.text('1 种食物'), findsOneWidget);

    await tester.tap(find.byTooltip('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('4 种食物'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '饮品');
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('燕麦饮'), findsOneWidget);
    await tester.tap(find.byTooltip('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('4 种食物'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  for (final lang in AppLang.values) {
    testWidgets('完整分类菜单在窄屏可选且单独清除保留搜索：${lang.code}', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String label(String key) {
        final values = kStrings[key]!;
        return switch (lang) {
          AppLang.en => values.$1,
          AppLang.es => values.$2,
          AppLang.zh => values.$3,
        };
      }

      for (final picker in [false, true]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: LangScope(
              lang: lang,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildLightTheme(),
                home: picker
                    ? const Scaffold(
                        body: FoodPickerSheet(
                          date: '2026-09-29',
                          meal: MealType.lunch,
                        ),
                      )
                    : const FoodsPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!picker) {
          await tester.ensureVisible(find.text(label('sourceCustom')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label('sourceCustom')));
          await tester.pumpAndSettle();
        }
        await tester.enterText(find.byType(TextField).first, '燕麦');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(label('foodCategory')));
        await tester.pumpAndSettle();
        expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(10));
        if (lang == AppLang.zh && !picker) {
          final bytes = await tester.runAsync(() async {
            final image = await captureImage(
              find.byType(Navigator).evaluate().first,
            );
            return image.toByteData(format: ui.ImageByteFormat.png);
          });
          File('verification/redesign_20260929/category_menu_narrow.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        final drinkItem = find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<String> && widget.value == 'drink',
        );
        await tester.ensureVisible(drinkItem);
        await tester.tap(drinkItem);
        await tester.pumpAndSettle();
        expect(find.text(label('categoryDrink')), findsOneWidget);
        expect(
          find.text(label('foodResults').replaceAll('{n}', '1')),
          findsOneWidget,
        );
        expect(find.text('燕麦饮'), findsOneWidget);
        await tester.tap(find.byTooltip(label('clearCategory')));
        await tester.pumpAndSettle();
        expect(find.text(label('allCategories')), findsOneWidget);
        expect(
          find.text(label('foodResults').replaceAll('{n}', '1')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          '燕麦',
        );
        await tester.tap(find.byTooltip(label('clearSearch')));
        await tester.pumpAndSettle();
        expect(
          find.text(label('foodResults').replaceAll('{n}', picker ? '4' : '2')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  }

  for (final lang in AppLang.values) {
    testWidgets('深色大字号食物库与添加弹层无溢出：${lang.code}', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final picker in [false, true]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: LangScope(
              lang: lang,
              child: MaterialApp(
                theme: buildDarkTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                home: picker
                    ? const Scaffold(
                        body: FoodPickerSheet(
                          date: '2026-09-29',
                          meal: MealType.lunch,
                        ),
                      )
                    : const FoodsPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField).first, '燕麦');
        await tester.pumpAndSettle();
        expect(find.text('燕麦饮'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  }

  testWidgets('完整应用的食物库、分类组合搜索与桌面布局交付预览', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Reuse this test's isolated executor instead of opening a second database.
    for (final food in await db.searchFoods('', limit: 1000)) {
      await db.deleteFood(food.id);
    }
    final previewDb = db;
    await seedIfEmpty(previewDb);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(previewDb),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: const KcalLogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('食物库'));
    await tester.pumpAndSettle();
    expect(find.text('237 种食物'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Future<void> capture(String name) async {
      final bytes = await tester.runAsync(() async {
        final image = await captureImage(
          find.byType(Navigator).evaluate().first,
        );
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('verification/redesign_20260929/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    await capture('food_library_latest');
    await tester.enterText(find.byType(TextField).first, '水果 苹果');
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('苹果'), findsOneWidget);
    await capture('food_search_latest');
    await tester.tap(find.byTooltip('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('237 种食物'), findsOneWidget);
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('237 种食物'), findsOneWidget);
    await capture('food_library_desktop_latest');
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(find.byType(FoodsPage), findsOneWidget);
      expect(find.byType(FoodPickerSheet), findsNothing);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        2,
      );
    }
    Focus.of(tester.element(find.byType(FoodsPage))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      0,
    );
    expect(await previewDb.foodCount(), 237);
    expect(await previewDb.recentEntries(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('食物类型筛选和搜索交集正确', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(theme: buildLightTheme(), home: const FoodsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('食物分类'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<String> && widget.value == 'staple',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('米饭'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '西红柿');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的食物'), findsOneWidget);
    await tester.tap(find.text('清除搜索与筛选'));
    await tester.pumpAndSettle();
    expect(find.text('4 种食物'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '西红柿');
    await tester.pumpAndSettle();
    expect(find.text('番茄炒蛋'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('添加食物弹层在窄屏可搜索，不挤压操作项', (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: const Scaffold(
              body: FoodPickerSheet(date: '2026-09-29', meal: MealType.lunch),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('4 种食物'), findsOneWidget);
    final favorite = find.text('收藏').first;
    final modeViewport = find
        .ancestor(of: favorite, matching: find.byType(SingleChildScrollView))
        .first;
    expect(
      tester.getRect(favorite).right,
      lessThanOrEqualTo(tester.getRect(modeViewport).right),
    );
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/food_picker_narrow.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());

    await tester.tap(find.byTooltip('食物分类'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<String> && widget.value == 'staple',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('OFF 在线'), findsOneWidget);
    await tester.tap(find.text('OFF 在线'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.text('全部分类'), findsNothing);
    expect(find.text('在线结果未分类'), findsOneWidget);
    expect(find.text('4 种食物'), findsOneWidget);
    final onlineBytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/food_picker_online.png')
        .writeAsBytesSync(onlineBytes!.buffer.asUint8List());
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OFF 在线 ✓'));
    await tester.pumpAndSettle();
    expect(find.text('全部分类'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '西红柿');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('番茄炒蛋'), findsOneWidget);
    expect(find.text('1 种食物'), findsOneWidget);
    await tester.tap(find.byTooltip('食物分类'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<String> && widget.value == 'staple',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的食物'), findsOneWidget);
    await tester.tap(find.text('清除搜索与筛选'));
    await tester.pumpAndSettle();
    expect(find.text('4 种食物'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('最近列表开启 OFF 时切回全部并展示在线区', (tester) async {
    final rice = (await db.searchFoods('米饭')).single;
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-09-29',
        meal: MealType.lunch,
        name: rice.name,
        foodId: Value(rice.id),
        kcal: 116,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(
              body: FoodPickerSheet(date: '2026-09-29', meal: MealType.lunch),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);

    await tester.tap(find.byTooltip('OFF 在线'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('4 种食物'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Open Food Facts（在线结果）'), findsOneWidget);
    expect(find.text('输入至少 2 个字符后搜索在线食物'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('桌面宽屏食物列表保持居中可读宽度', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: const FoodsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final item = find.byType(FoodListItem).first;
    final width = tester.getSize(item).width;
    final left = tester.getTopLeft(item).dx;
    expect(width, lessThanOrEqualTo(960));
    expect(left, greaterThan(200));
    expect(left + width, lessThan(1240));

    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/food_library_desktop.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('搜索无结果后可新建食物并立刻搜到', (tester) async {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '已有条码食物',
        kcal100: 80,
        barcode: const Value('123456789'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(theme: buildLightTheme(), home: const FoodsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '香蕉燕麦杯');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的食物'), findsOneWidget);
    await tester.tap(find.text('新建自定义食物'));
    await tester.pumpAndSettle();

    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.enterText(field('名称 *'), '香蕉燕麦杯');
    await tester.enterText(field('热量 (每100g) *'), '115');
    await tester.enterText(field('条码'), '123456789');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('这个条码已被其他食物使用'), findsOneWidget);
    expect((await db.foodByBarcode('123456789'))!.name, '已有条码食物');

    await tester.enterText(field('条码'), '987654321');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('香蕉燕麦杯'), findsWidgets);
    final saved = (await db.searchFoods('香蕉燕麦杯')).single;
    expect(saved.kcal100, 115);
    expect(saved.source, 'custom');
    expect(saved.barcode, '987654321');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('新建沿用分类，取消保留筛选，保存定位到用户最终选择的分类', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(theme: buildLightTheme(), home: const FoodsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('食物分类'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<String> && w.value == 'drink',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('内置'));
    await tester.enterText(find.byType(TextField).first, '原搜索词');
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建自定义食物'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<FoodCategory>>(
            find.byType(DropdownButtonFormField<FoodCategory>),
          )
          .initialValue,
      FoodCategory.drink,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '原搜索词',
    );
    expect(find.text('饮品'), findsOneWidget);
    final builtin = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '内置',
      ),
    );
    expect(builtin.properties.selected, isTrue);
    expect(await db.foodCount(), 4);

    await tester.tap(find.text('新建自定义食物'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.enterText(field('名称 *'), '我的果汁');
    await tester.enterText(field('热量 (每100g) *'), '50');
    await tester.tap(find.byType(DropdownButtonFormField<FoodCategory>));
    await tester.pumpAndSettle();
    final fruitItem = find
        .widgetWithText(DropdownMenuItem<FoodCategory>, '水果')
        .last;
    await tester.tap(
      find.ancestor(of: fruitItem, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '我的果汁',
    );
    expect(find.text('水果'), findsOneWidget);
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('我的果汁'), findsWidgets);
    final food = (await db.searchFoods('我的果汁')).single;
    expect(food.category, 'fruit');
    expect(food.source, 'custom');
    expect(await db.recentEntries(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('收藏筛选下新建食物后在添加弹层可见，但不自动记餐', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(
              body: FoodPickerSheet(date: '2026-09-29', meal: MealType.lunch),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('食物分类'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<String> && w.value == 'drink',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '原搜索词');
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建自定义食物'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<FoodCategory>>(
            find.byType(DropdownButtonFormField<FoodCategory>),
          )
          .initialValue,
      FoodCategory.drink,
    );
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.enterText(field('名称 *'), '新建测试饮品');
    await tester.enterText(field('热量 (每100g) *'), '50');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('1 种食物'), findsOneWidget);
    expect(find.text('新建测试饮品'), findsWidgets);
    expect(find.byType(EntrySheet), findsNothing);
    expect((await db.searchFoods('新建测试饮品')).single.category, 'drink');
    expect(await db.recentEntries(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('在线模式手动新建后切回本地结果，不发搜索请求或自动记餐', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(
              body: FoodPickerSheet(date: '2026-09-29', meal: MealType.lunch),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('OFF 在线'));
    await tester.pumpAndSettle();
    expect(find.text('在线结果未分类'), findsOneWidget);
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义食物'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.enterText(field('名称 *'), '在线后手动新建');
    await tester.enterText(field('热量 (每100g) *'), '75');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('在线结果未分类'), findsNothing);
    expect(find.text('在线后手动新建'), findsWidgets);
    expect(find.text('1 种食物'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration!
          .hintText,
      '搜索食物',
    );
    expect(await db.recentEntries(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('编辑已有食物忽略新建默认分类，并返回正确的保存对象', (tester) async {
    var existing = (await db.searchFoods('米饭')).single;
    await db.toggleFavorite(existing);
    existing = (await db.searchFoods('米饭')).single;
    Food? returned;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => returned = await showFoodForm(
                    context,
                    existing: existing,
                    initialCategory: FoodCategory.drink,
                  ),
                  child: const Text('打开编辑'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<FoodCategory>>(
            find.byType(DropdownButtonFormField<FoodCategory>),
          )
          .initialValue,
      FoodCategory.staple,
    );
    final kcal = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '热量 (每100g) *',
    );
    await tester.enterText(kcal, '120');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(returned!.id, existing.id);
    expect(returned!.name, '米饭');
    expect(returned!.kcal100, 120);
    expect(returned!.favorite, isTrue);
    expect(returned!.source, 'builtin');
    expect(returned!.category, 'staple');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('新建食物拒绝非有限热量、负营养值和无效份量', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(theme: buildLightTheme(), home: const FoodsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新建自定义食物'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.enterText(field('名称 *'), '校验食品');
    await tester.enterText(field('热量 (每100g) *'), 'NaN');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请填写食物名称和每100g热量'), findsOneWidget);

    await tester.enterText(field('热量 (每100g) *'), '100');
    await tester.pump();
    expect(find.text('请填写食物名称和每100g热量'), findsNothing);
    await tester.enterText(field('蛋白质 g'), '-2');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('营养值必须是非负数字'), findsOneWidget);

    await tester.enterText(field('蛋白质 g'), '2');
    await tester.pump();
    expect(find.text('营养值必须是非负数字'), findsNothing);
    await tester.enterText(field('份量克数'), 'abc');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('每份克数必须是正数'), findsOneWidget);

    await tester.enterText(field('份量克数'), '50');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final saved = (await db.searchFoods('校验食品')).single;
    expect(saved.kcal100, 100);
    expect(saved.protein100, 2);
    expect(saved.servingGrams, 50);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('点食物卡先打开份量记录，未确认前不写入', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: LangScope(
          lang: AppLang.zh,
          child: MaterialApp(theme: buildLightTheme(), home: const FoodsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rice = find.byWidgetPredicate(
      (widget) => widget is FoodListItem && widget.food.name == '米饭',
    );
    await tester.ensureVisible(rice);
    await tester.tap(rice);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(EntrySheet), findsOneWidget);
    expect(await db.recentEntries(), isEmpty);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: rice, matching: find.byType(PopupMenuButton<String>)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑食物'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
