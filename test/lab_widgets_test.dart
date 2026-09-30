import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/ui/widgets/app_segmented.dart';
import 'package:kcal_log/ui/widgets/filter_pills.dart';
import 'package:kcal_log/ui/widgets/top_tabs.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_category_filter.dart';
import 'package:kcal_log/logic/food_category.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/ui/widgets/slide_to_confirm.dart';
import 'package:kcal_log/ui/widgets/smart_field.dart';

void main() {
  test('DateTimeInputFormatter 自动插入分隔符并截断超长输入', () {
    const f = DateTimeInputFormatter();
    TextEditingValue fmt(String s) =>
        f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s));
    expect(fmt('2026').text, '2026-');
    expect(fmt('202609').text, '2026-09-');
    expect(fmt('20260913').text, '2026-09-13 ');
    expect(fmt('2026091314').text, '2026-09-13 14:');
    expect(fmt('202609131430').text, '2026-09-13 14:30');
    expect(fmt('20260913143099').text, '2026-09-13 14:30');
  });

  test('dateTimePartsValid 校验非法日期时间', () {
    expect(dateTimePartsValid('2026-09-13 14:30'), isTrue);
    expect(dateTimePartsValid('2024-02-29 00:00'), isTrue); // 闰年
    expect(dateTimePartsValid('2026-13-01 00:00'), isFalse);
    expect(dateTimePartsValid('2026-09-31 00:00'), isFalse);
    expect(dateTimePartsValid('2026-02-30 00:00'), isFalse);
    expect(dateTimePartsValid('2026-09-13 24:00'), isFalse);
    expect(dateTimePartsValid('2026-09-13 14:60'), isFalse);
  });

  testWidgets('AppSegmented / FilterPills 点击回调', (tester) async {
    int? seg;
    String? pill;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppSegmented<int>(
                segments: const [(7, '7 days'), (30, '30 days')],
                selected: 7,
                onChanged: (v) => seg = v,
              ),
              FilterPills<String>(
                items: const [('a', 'All'), ('b', 'Fav')],
                selected: 'a',
                onChanged: (v) => pill = v,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('30 days'));
    await tester.tap(find.text('Fav'));
    expect(seg, 30);
    expect(pill, 'b');

    final allSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'All',
      ),
    );
    expect(allSemantics.properties.button, isTrue);
    expect(allSemantics.properties.selected, isTrue);
    pill = null;
    Focus.of(tester.element(find.text('Fav'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(pill, 'b');
  });

  testWidgets('筛选胶囊在 2 倍字号不裁切并保留点击高度', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: FilterPills<String>(
              items: const [('a', '收藏')],
              selected: 'a',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text('收藏'));
    expect(
      paragraph.size.height + .1,
      greaterThanOrEqualTo(
        paragraph.computeMinIntrinsicHeight(paragraph.size.width),
      ),
    );
    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('分类菜单支持 Enter 打开、方向键选择和 Tab 清除', (tester) async {
    FoodCategory? selected;
    await tester.pumpWidget(
      LangScope(
        lang: AppLang.zh,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => FoodCategoryFilter(
                  selected: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('全部分类'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(10));
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, FoodCategory.drink);
    expect(find.text('饮品'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(find.text('全部分类'), findsOneWidget);
  });

  testWidgets('标题与页签继承主题字体，大字号下仍可切换页签', (tester) async {
    final theme = buildLightTheme();
    expect(
      theme.appBarTheme.titleTextStyle!.fontFamily,
      theme.textTheme.titleMedium!.fontFamily,
    );
    expect(
      theme.navigationRailTheme.selectedLabelTextStyle!.fontFamily,
      theme.textTheme.bodyMedium!.fontFamily,
    );
    expect(
      theme.navigationRailTheme.unselectedLabelTextStyle!.fontFamily,
      theme.textTheme.bodyMedium!.fontFamily,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: TopTabs(
            tabs: const ['食物', '组合餐'],
            pageBuilder: (_, i) => Text('page $i'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final styles = tester.widgetList<AnimatedDefaultTextStyle>(
      find.descendant(
        of: find.byType(TopTabs),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    );
    expect(
      styles.every(
        (w) => w.style.fontFamily == theme.textTheme.bodyMedium!.fontFamily,
      ),
      isTrue,
    );
    await tester.tap(find.text('组合餐'));
    await tester.pumpAndSettle();
    expect(find.text('page 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SlideToConfirm 不足 80% 回弹不触发，超过则触发', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'Slide',
                successLabel: 'Done',
                onConfirm: () => confirmed = true,
              ),
            ),
          ),
        ),
      ),
    );
    // 拖动约 23%：不触发，回弹
    final center = tester.getCenter(find.byType(SlideToConfirm));
    var g = await tester.startGesture(center);
    await g.moveBy(const Offset(60, 0));
    await g.up();
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);

    // 拖过 80%：触发
    g = await tester.startGesture(center);
    await g.moveBy(const Offset(280, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(confirmed, isTrue);
  });

  testWidgets('SmartField 输入自动分隔并显示字数', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: SmartField(
              label: 'Date',
              maxLength: 16,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                const DateTimeInputFormatter(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '20260913');
    await tester.pump();
    expect(find.text('2026-09-13 '), findsOneWidget);
    expect(find.text('11/16'), findsOneWidget);
  });
}

// 实验室整页 headless 渲染：捕获溢出/布局异常（不依赖字体与屏幕）
