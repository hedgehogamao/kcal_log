import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/ui/widgets/app_segmented.dart';
import 'package:kcal_log/ui/widgets/filter_pills.dart';
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
    await tester.pumpWidget(MaterialApp(
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
    ));
    await tester.tap(find.text('30 days'));
    await tester.tap(find.text('Fav'));
    expect(seg, 30);
    expect(pill, 'b');
  });

  testWidgets('SlideToConfirm 不足 80% 回弹不触发，超过则触发', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(MaterialApp(
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
    ));
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
    await tester.pumpWidget(MaterialApp(
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
    ));
    await tester.enterText(find.byType(TextFormField), '20260913');
    await tester.pump();
    expect(find.text('2026-09-13 '), findsOneWidget);
    expect(find.text('11/16'), findsOneWidget);
  });
}

// 实验室整页 headless 渲染：捕获溢出/布局异常（不依赖字体与屏幕）
