import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/top_tabs.dart';
import 'package:kcal_log/ui/widgets/motion_page_stack.dart';

class _RememberPage extends StatefulWidget {
  const _RememberPage();
  @override
  State<_RememberPage> createState() => _RememberPageState();
}

class _RememberPageState extends State<_RememberPage> {
  final query = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(key: const ValueKey('remember-query'), controller: query),
      Expanded(
        child: ListView.builder(
          key: const ValueKey('remember-list'),
          controller: scroll,
          itemCount: 50,
          itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
        ),
      ),
    ],
  );
}

TabController tabs(WidgetTester t) =>
    t.widget<TabBar>(find.byKey(const ValueKey('motion-tab-bar'))).controller!;
Future<void> mount(
  WidgetTester t, {
  bool reduce = false,
  bool rtl = false,
  double scale = 1,
  List<String> labels = const ['Records', 'Library'],
  Widget Function(BuildContext, int)? builder,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduce,
          textScaler: TextScaler.linear(scale),
        ),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: Scaffold(
        body: TopTabs(
          tabs: labels,
          pageBuilder:
              builder ??
              (_, i) => i == 0
                  ? const _RememberPage()
                  : const Center(child: Text('second page')),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'drag is proportional, depth is subtle and pageBuilder does not rerun each frame',
    (t) async {
      var builds = 0;
      await mount(
        t,
        builder: (_, i) {
          builds++;
          return i == 0
              ? const _RememberPage()
              : const Center(child: Text('second page'));
        },
      );
      final before = builds;
      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('motion-tab-pages'))),
      );
      await gesture.moveBy(const Offset(-30, 0));
      await t.pump();
      await gesture.moveBy(const Offset(-230, 0));
      await t.pump(const Duration(milliseconds: 16));
      expect(tabs(t).animation!.value, inExclusiveRange(0, 1));
      final matrix = t
          .widget<Transform>(find.byKey(const ValueKey('tab-depth-0')))
          .transform;
      expect(matrix.entry(0, 0), inExclusiveRange(.988, 1));
      expect(builds, before);
      await gesture.up();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('rapid reverse preserves query and list position', (t) async {
    await mount(t);
    await t.enterText(find.byKey(const ValueKey('remember-query')), '米饭150g');
    await t.drag(
      find.byKey(const ValueKey('remember-list')),
      const Offset(0, -300),
    );
    await t.pumpAndSettle();
    final state = t.state<_RememberPageState>(find.byType(_RememberPage));
    final offset = state.scroll.offset;
    await t.tap(find.text('Library'));
    await t.pump(const Duration(milliseconds: 65));
    await t.tap(find.text('Records'));
    await t.pumpAndSettle();
    expect(state.query.text, '米饭150g');
    expect(state.scroll.offset, offset);
    expect(tabs(t).index, 0);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'reverse after visible movement settles back to the requested tab',
    (t) async {
      await mount(t);
      await t.tap(find.text('Library'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final page = t
          .widget<PageView>(find.byKey(const ValueKey('motion-tab-pages')))
          .controller!;
      expect(page.page, inExclusiveRange(0, 1));
      await t.tap(find.text('Records'));
      await t.pumpAndSettle();
      expect(page.page, 0);
      expect(tabs(t).index, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('manual drag can take over an in-flight tab selection', (
    t,
  ) async {
    await mount(t);
    await t.tap(find.text('Library'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('motion-tab-pages'))),
    );
    await gesture.moveBy(const Offset(35, 0));
    await t.pump();
    await gesture.moveBy(const Offset(350, 0));
    await t.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await t.pumpAndSettle();
    expect(tabs(t).index, 0);
    expect(find.byKey(const ValueKey('remember-query')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('reduce motion jumps on tap and removes scale effect', (t) async {
    await mount(t, reduce: true);
    await t.tap(find.text('Library'));
    await t.pump();
    expect(tabs(t).index, 1);
    expect(tabs(t).indexIsChanging, isFalse);
    await t.pump();
    expect(
      t
          .widget<Transform>(find.byKey(const ValueKey('tab-depth-1')))
          .transform
          .entry(0, 0),
      1,
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('keyboard arrows select immediately and honor RTL', (t) async {
    await mount(t, rtl: true);
    Focus.of(t.element(find.byKey(const ValueKey('motion-tab-bar'))))
        .requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await t.pump();
    expect(tabs(t).index, 1);
    expect(tabs(t).indexIsChanging, isFalse);
    await t.sendKeyEvent(LogicalKeyboardKey.home);
    await t.pump();
    expect(tabs(t).index, 0);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'keyboard Enter activates focused tab without a traveling animation',
    (t) async {
      await mount(t);
      Focus.of(t.element(find.text('Library'))).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(tabs(t).index, 1);
      expect(tabs(t).indexIsChanging, isFalse);
      await t.pump();
      expect(find.text('second page'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('vertical list scrolling does not hijack a page turn', (t) async {
    await mount(t);
    await t.drag(
      find.byKey(const ValueKey('remember-list')),
      const Offset(0, -220),
    );
    await t.pumpAndSettle();
    expect(tabs(t).index, 0);
    expect(
      t.state<_RememberPageState>(find.byType(_RememberPage)).scroll.offset,
      greaterThan(0),
    );
    expect(t.takeException(), isNull);
  });
  testWidgets(
    '320px 2x long labels remain selectable and dynamic count is safe',
    (t) async {
      t.view.physicalSize = const Size(320, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await mount(
        t,
        scale: 2,
        labels: const ['Registros de alimentos', 'Biblioteca y recetas'],
      );
      tabs(t).index = 1;
      await t.pumpAndSettle();
      expect(find.text('second page'), findsOneWidget);
      await mount(t, scale: 2, labels: const ['Solo']);
      expect(tabs(t).length, 1);
      expect(tabs(t).index, 0);
      expect(t.takeException(), isNull);
    },
  );
  for (final reduce in [false, true]) {
    testWidgets(
      'main navigation retains state, hides inactive focus and respects motion=$reduce',
      (t) async {
        late StateSetter set;
        var index = 0;
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: StatefulBuilder(
                builder: (_, update) {
                  set = update;
                  return Scaffold(
                    body: MotionPageStack(
                      index: index,
                      pages: const [
                        _RememberPage(),
                        Center(child: Text('destination 1')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const ValueKey('remember-query')), 'keep');
        set(() => index = 1);
        await t.pump();
        final matrix = t
            .widget<Transform>(
              find.byKey(const ValueKey('destination-motion-1')),
            )
            .transform;
        expect(matrix.entry(0, 3), reduce ? 0 : greaterThan(0));
        expect(find.byKey(const ValueKey('remember-query')), findsNothing);
        await t.pump(const Duration(milliseconds: 50));
        set(() => index = 0);
        await t.pumpAndSettle();
        expect(
          t
              .widget<TextField>(find.byKey(const ValueKey('remember-query')))
              .controller!
              .text,
          'keep',
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('keyboard-initiated main destination has zero travel', (t) async {
    late StateSetter set;
    var index = 0;
    await t.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, update) {
            set = update;
            return Scaffold(
              body: MotionPageStack(
                index: index,
                animate: false,
                pages: const [Text('first'), Text('second')],
              ),
            );
          },
        ),
      ),
    );
    set(() => index = 1);
    await t.pump();
    expect(
      t
          .widget<Transform>(find.byKey(const ValueKey('destination-motion-1')))
          .transform
          .entry(0, 3),
      0,
    );
    expect(t.takeException(), isNull);
  });
}
