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
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/today_page.dart';
import 'package:kcal_log/ui/sheets/entry_sheet.dart';

/// 离屏截图：今日页（总览卡正/反两面）与记录弹层。
/// 用内存数据库 + 预置数据渲染为 PNG 写入 test/goldens/，
/// 不经过显示器；只产出图片，不做比对，不影响常规测试。
///
/// 字体：测试默认字体是 Ahem 方块（宽度失真，会误报溢出），
/// 这里把系统 SF/中文黑体注入 Material 默认的 Roboto 字族，
/// 让布局按真实字体计量；顺带 PNG 里文字可读。
Future<void> _loadRealFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      final f = File(p);
      if (!f.existsSync()) continue;
      final data = f.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(data.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    '/System/Library/Fonts/SFNS.ttf',
    '/System/Library/Fonts/STHeiti Medium.ttc',
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ]);
}

void main() {
  setUpAll(_loadRealFonts);
  late AppDatabase db;
  late SharedPreferences prefs;
  late String today;
  late Food rice;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    today = dateKey(DateTime.now());

    rice = await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        protein100: const Value(2.6),
        fat100: const Value(0.3),
        carb100: const Value(25.9),
      ),
    );
    final egg = await db.upsertFood(
      FoodsCompanion.insert(
        name: '水煮蛋',
        kcal100: 151,
        protein100: const Value(12.6),
        fat100: const Value(10.6),
        carb100: const Value(1.6),
      ),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: today,
        meal: MealType.breakfast,
        name: egg.name,
        foodId: Value(egg.id),
        grams: const Value(100),
        kcal: 151,
        protein: const Value(12.6),
        fat: const Value(10.6),
        carb: const Value(1.6),
      ),
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
    await db.saveProfile(
      ProfilesCompanion(id: const Value(1), kcalGoal: const Value(1800)),
    );
    await db.addWater(today, 750);
  });

  tearDown(() => db.close());

  Future<void> snap(WidgetTester tester, String name) async {
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('test/goldens/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  /// 测试收尾：卸载 ProviderScope（会触发 drift 流取消并留下零延时
  /// Timer），随后推进 fake-async 时钟把 pending timer 排干，
  /// 否则测试框架的「无 pending timer」不变量会失败。
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  ProviderScope app({required WidgetBuilder home}) => ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
    ],
    child: LangScope(
      lang: AppLang.zh,
      child: MaterialApp(home: Builder(builder: home)),
    ),
  );

  testWidgets('今日页正面（活动环+四餐进度+饮水+折叠餐次）', (tester) async {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(home: (_) => TodayPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('早餐'), findsWidgets);
    expect(find.text('当前餐'), findsOneWidget);
    await snap(tester, 'today_front.png');
    await drain(tester);
  });

  testWidgets('今日页明确打开计算说明，不隐藏总览', (tester) async {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(home: (_) => TodayPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('today-calculation-help')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('数字是怎么算的'), findsOneWidget);
    await snap(tester, 'today_back.png');
    await drain(tester);
  });

  testWidgets('记录弹层（SmartField + 吸底操作栏）', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        home: (_) => Scaffold(
          body: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showEntrySheet(
                  context,
                  date: today,
                  meal: MealType.lunch,
                  food: rice,
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('确认记录'), findsOneWidget); // 新增模式
    // 输入份量 → 预览与底栏剩余同步刷新
    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pumpAndSettle();
    await snap(tester, 'entry_sheet.png');
    await drain(tester);
  });
}
