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
import 'package:kcal_log/logic/stats_summary.dart';
import 'package:kcal_log/main.dart';
import 'package:kcal_log/ui/pages/stats_page.dart';
import 'package:kcal_log/ui/widgets/app_segmented.dart';
import 'package:kcal_log/ui/widgets/charts.dart';

void main() {
  FoodEntry row(String date, double kcal) => FoodEntry(
    id: 1,
    date: date,
    meal: MealType.lunch,
    name: 'fixture',
    kcal: kcal,
    protein: 0,
    fat: 0,
    carb: 0,
    createdAt: DateTime(2026),
  );
  test('统计零摄入是有记录，缺失为 null，区间外不参与均值', () {
    final summary = StatsSummary(
      [row('2026-09-29', 500), row('2026-09-28', 0), row('2026-09-01', 1000)],
      end: DateTime(2026, 9, 29),
      days: 7,
    );
    expect(summary.recordedDays, 2);
    expect(summary.missingDays, 5);
    expect(summary.average, 250);
    expect(summary.values(useKj: false), [
      null,
      null,
      null,
      null,
      null,
      0,
      500,
    ]);
    expect(summary.values(useKj: true).last, 2092);
    expect(summary.values(useKj: true)[5], 0);
  });
  test('空区间没有假零热量点和除零', () {
    final summary = StatsSummary([], end: DateTime(2026, 9, 29), days: 30);
    expect(summary.recordedDays, 0);
    expect(summary.average, 0);
    expect(summary.values(useKj: false), everyElement(isNull));
  });
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
  late String yesterday;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    today = dateKey(DateTime.now());
    yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    await db.saveProfile(
      ProfilesCompanion(id: const Value(1), kcalGoal: const Value(2000)),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: today,
        meal: MealType.lunch,
        name: '午餐',
        kcal: 500,
        protein: const Value(20),
        fat: const Value(10),
        carb: const Value(60),
      ),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: yesterday,
        meal: MealType.lunch,
        name: '零热量记录',
        kcal: 0,
      ),
    );
    await db.addEntry(
      EntriesCompanion.insert(
        date: dateKey(DateTime.now().subtract(const Duration(days: 8))),
        meal: MealType.lunch,
        name: '较早记录',
        kcal: 1000,
      ),
    );
    await db.addWeight(today, 70);
    await db.addWeight(yesterday, 70.5);
  });
  tearDown(() => db.close());
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> open(
    WidgetTester tester, {
    bool kj = false,
    AppLang lang = AppLang.zh,
    bool dark = false,
    double width = 390,
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      'lang': lang.code,
      'useKj': kj,
      'themeMode': (dark ? ThemeMode.dark : ThemeMode.light).index,
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(width, 1050);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => drain(tester));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: const KcalLogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(switch (lang) {
        AppLang.zh => '统计',
        AppLang.en => 'Stats',
        AppLang.es => 'Estadísticas',
      }),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(StatsPage))).scale(10),
      scale * 10,
    );
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        300,
        scrollable: find
            .descendant(
              of: find.byType(StatsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    } else {
      await tester.ensureVisible(target);
    }
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('完整应用 7/30 区间、日均分母与缺失日明细一致', (tester) async {
    await open(tester);
    expect(find.text('500 kcal'), findsOneWidget);
    expect(find.text('3 / 30'), findsOneWidget);
    await capture(tester, 'stats_redesign_latest');
    await tester.tap(find.text('7天'));
    await tester.pumpAndSettle();
    expect(find.text('250 kcal'), findsOneWidget);
    expect(find.text('2 / 7'), findsOneWidget);
    expect(find.text('2 天'), findsOneWidget);
    final chart = tester.widget<SimpleLineChart>(
      find.byKey(const ValueKey('energy-trend')),
    );
    expect(chart.values, [null, null, null, null, null, 0, 500]);
    expect(chart.goal, 2000);
    await reveal(tester, find.byKey(const ValueKey('stats-daily-details')));
    await tester.tap(find.text('查看每日明细'));
    await tester.pumpAndSettle();
    expect(find.text('0.0 kcal'), findsOneWidget);
    expect(find.text('未记录'), findsWidgets);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('kJ 数值和目标都换算，不只改坐标轴文字', (tester) async {
    await open(tester, kj: true);
    final chart = tester.widget<SimpleLineChart>(
      find.byKey(const ValueKey('energy-trend')),
    );
    expect(chart.values.last, 2092);
    expect(chart.goal, 8368);
    expect(chart.yUnit, 'kJ');
    expect(find.text('2092 kJ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('热力图有日期与目标比例，零记录与缺失明确区分', (tester) async {
    await open(tester);
    await reveal(tester, find.byType(Heatmap));
    final messages = tester
        .widgetList<Tooltip>(
          find.descendant(
            of: find.byType(Heatmap),
            matching: find.byType(Tooltip),
          ),
        )
        .map((w) => w.message)
        .toList();
    expect(messages, contains('$today · 每日目标的 25%'));
    expect(messages, contains('$yesterday · 每日目标的 0%'));
    expect(messages.any((m) => m?.contains('未记录') == true), isTrue);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('空统计引导记录，不画假零趋势或宏量', (tester) async {
    await db.delete(db.entries).go();
    await open(tester);
    expect(find.text('记录一餐后，这里会显示热量趋势。'), findsOneWidget);
    expect(find.byKey(const ValueKey('energy-trend')), findsNothing);
    await reveal(tester, find.text('近 7 天还没有营养记录。'));
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('记录体重内联验证，取消不写入，保存同步个人资料', (tester) async {
    await open(tester);
    final add = find.byKey(const ValueKey('stats-add-weight'));
    await reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    for (final value in ['NaN', 'Infinity', '0', '501', 'abc']) {
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入大于 0 且不超过 500 kg 的体重。'), findsOneWidget);
      expect(
        (await db.select(db.weights).get())
            .firstWhere((w) => w.date == today)
            .kg,
        70,
      );
    }
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.weights).get()).firstWhere((w) => w.date == today).kg,
      70,
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '69.8');
    await tester.pump();
    expect(find.text('请输入大于 0 且不超过 500 kg 的体重。'), findsNothing);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.weights).get()).firstWhere((w) => w.date == today).kg,
      69.8,
    );
    final profile = await db.select(db.profiles).getSingle();
    expect(profile.weightKg, 69.8);
    expect(profile.kcalGoal, 2000);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('只展示最近90条体重但不删除其他记录', (tester) async {
    for (var i = 0; i < 100; i++) {
      await db.addWeight(
        dateKey(DateTime.now().subtract(Duration(days: i))),
        70 + i / 100,
      );
    }
    await open(tester);
    await reveal(tester, find.byKey(const ValueKey('weight-trend')));
    expect(
      tester
          .widget<SimpleLineChart>(find.byKey(const ValueKey('weight-trend')))
          .values,
      hasLength(90),
    );
    expect(await db.select(db.weights).get(), hasLength(100));
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  for (final lang in AppLang.values) {
    testWidgets('统计页320px2倍字号深色三语完整内容：${lang.code}', (tester) async {
      await open(
        tester,
        lang: lang,
        dark: true,
        width: 320,
        scale: 2,
        kj: true,
      );
      expect(tester.takeException(), isNull);
      await reveal(tester, find.byType(Heatmap));
      expect(tester.takeException(), isNull);
      if (lang == AppLang.zh) {
        await capture(tester, 'stats_redesign_accessible_latest');
      }
      await reveal(tester, find.byKey(const ValueKey('weight-trend')));
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }
  testWidgets('统计桌面布局居中限制960px', (tester) async {
    await open(tester, width: 1280);
    final list = find.descendant(
      of: find.byType(StatsPage),
      matching: find.byType(ListView),
    );
    expect(tester.getSize(list).width, lessThanOrEqualTo(960));
    await capture(tester, 'stats_redesign_desktop_latest');
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('区间控件在无界Row中可布局，键盘可切换，点击区至少44', (tester) async {
    int selected = 7;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppSegmented<int>(
                segments: const [(7, '7 days'), (30, '30 days')],
                selected: 7,
                onChanged: (v) => selected = v,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final button = find.ancestor(
      of: find.text('30 days'),
      matching: find.byType(TextButton),
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    Focus.of(tester.element(find.text('30 days'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 30);
    await drain(tester);
  });
}
