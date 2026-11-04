import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/ui/widgets/scroll_scale_reveal.dart';

RenderScrollScaleReveal render(WidgetTester t, int i) =>
    t.renderObject<RenderScrollScaleReveal>(
      find.descendant(
        of: find.byKey(ValueKey('reveal-$i')),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ScalePaint',
        ),
      ),
    );
Future<void> mount(
  WidgetTester t,
  ScrollController controller, {
  bool reduce = false,
  bool accessible = false,
  bool reverse = false,
  VoidCallback? onTap,
  Map<int, int>? builds,
}) async {
  t.view.physicalSize = const Size(400, 400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduce,
          accessibleNavigation: accessible,
        ),
        child: Scaffold(
          body: ListView.builder(
            controller: controller,
            reverse: reverse,
            itemExtent: 100,
            itemCount: 30,
            itemBuilder: (_, i) {
              builds?.update(i, (v) => v + 1, ifAbsent: () => 1);
              return ScrollScaleReveal(
                key: ValueKey('reveal-$i'),
                child: ColoredBox(
                  color: Colors.blue,
                  child: Center(
                    child: TextButton(onPressed: onTap, child: Text('hit $i')),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('downward viewport entry grows progressively to full size', (
    t,
  ) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await mount(t, c);
    c.jumpTo(20);
    await t.pump();
    final small = render(t, 4).scale;
    c.jumpTo(60);
    await t.pump();
    final larger = render(t, 4).scale;
    c.jumpTo(100);
    await t.pump();
    final full = render(t, 4).scale;
    expect(small, inExclusiveRange(.94, 1));
    expect(larger, greaterThan(small));
    expect(full, 1);
    expect(t.takeException(), isNull);
  });
  testWidgets('upward entry uses the same reversible growth', (t) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await mount(t, c);
    c.jumpTo(80);
    await t.pump();
    final small = render(t, 0).scale;
    c.jumpTo(40);
    await t.pump();
    final larger = render(t, 0).scale;
    c.jumpTo(0);
    await t.pump();
    expect(render(t, 0).scale, 1);
    expect(larger, greaterThan(small));
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'layout extent stays fixed and transformed button hit is correct',
    (t) async {
      final c = ScrollController();
      addTearDown(c.dispose);
      var taps = 0;
      await mount(t, c, onTap: () => taps++);
      c.jumpTo(60);
      await t.pump();
      expect(render(t, 4).size.height, 100);
      expect(c.position.maxScrollExtent, 2600);
      await t.tap(find.text('hit 4'));
      await t.pump();
      expect(taps, 1);
      expect(c.offset, 60);
      expect(t.takeException(), isNull);
    },
  );
  for (final accessible in [false, true]) {
    testWidgets('motion preference removes scaling accessible=$accessible', (
      t,
    ) async {
      final c = ScrollController();
      addTearDown(c.dispose);
      await mount(t, c, reduce: !accessible, accessible: accessible);
      c.jumpTo(20);
      await t.pump();
      expect(render(t, 4).scale, 1);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('outside vertical scrolling there is no scale effect', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScrollScaleReveal(
            key: ValueKey('reveal-0'),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await t.pump();
    expect(render(t, 0).scale, 1);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              ScrollScaleReveal(
                key: ValueKey('reveal-0'),
                child: SizedBox(width: 100),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    expect(render(t, 0).scale, 1);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'reverse vertical lists still grow at the physical viewport edge',
    (t) async {
      final c = ScrollController();
      addTearDown(c.dispose);
      await mount(t, c, reverse: true);
      c.jumpTo(20);
      await t.pump();
      final small = render(t, 4).scale;
      c.jumpTo(60);
      await t.pump();
      expect(render(t, 4).scale, greaterThan(small));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'scroll paint does not rebuild visible content and detaches listeners',
    (t) async {
      final c = ScrollController();
      final counts = <int, int>{};
      await mount(t, c, builds: counts);
      final before = counts[4];
      for (final offset in [20.0, 40.0, 60.0]) {
        c.jumpTo(offset);
        await t.pump();
      }
      expect(counts[4], before);
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
}
