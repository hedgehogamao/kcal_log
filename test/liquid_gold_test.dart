import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/main.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';
import 'package:kcal_log/ui/widgets/liquid_gold_backdrop.dart';

LiquidGoldPainter painter(WidgetTester t) =>
    t
            .widget<CustomPaint>(
              find.byKey(const ValueKey('liquid-gold-canvas')),
            )
            .painter!
        as LiquidGoldPainter;
Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(milliseconds: 200));
}

Future<void> mount(
  WidgetTester t, {
  bool animate = true,
  bool reduce = false,
  bool accessible = false,
  bool dark = true,
  Widget? child,
}) async {
  t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await t.pumpWidget(
    MaterialApp(
      theme: dark ? buildDarkTheme() : buildLightTheme(),
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: reduce, accessibleNavigation: accessible),
        child: body!,
      ),
      home: Scaffold(
        body: LiquidGoldBackdrop(
          animate: animate,
          child: child ?? const Center(child: Text('content')),
        ),
      ),
    ),
  );
  await t.pump();
}

void main() {
  testWidgets('real repaint phase advances without rebuilding content', (
    t,
  ) async {
    var builds = 0;
    await mount(
      t,
      child: Builder(
        builder: (_) {
          builds++;
          return const Text('data');
        },
      ),
    );
    final before = painter(t).phase;
    await t.pump(const Duration(milliseconds: 800));
    expect(painter(t).phase, greaterThan(before));
    expect(builds, 1);
    expect(t.takeException(), isNull);
    await drain(t);
  });
  testWidgets('explicit static preview has no recurring motion', (t) async {
    await mount(t, animate: false);
    final before = painter(t).phase;
    await t.pump(const Duration(seconds: 2));
    expect(painter(t).phase, before);
    expect(t.binding.hasScheduledFrame, isFalse);
    await drain(t);
  });
  for (final accessible in [false, true]) {
    testWidgets('motion preference freezes liquid accessible=$accessible', (
      t,
    ) async {
      await mount(t, reduce: !accessible, accessible: accessible);
      final before = painter(t).phase;
      await t.pump(const Duration(seconds: 2));
      expect(painter(t).phase, before);
      expect(t.binding.hasScheduledFrame, isFalse);
      await drain(t);
    });
  }
  testWidgets('light mode does not run a gold canvas', (t) async {
    await mount(t, dark: false);
    expect(find.byKey(const ValueKey('liquid-gold-canvas')), findsNothing);
    expect(t.binding.hasScheduledFrame, isFalse);
    await drain(t);
  });
  testWidgets('inactive app freezes and resumes without a phase jump', (
    t,
  ) async {
    await mount(t);
    await t.pump(const Duration(milliseconds: 600));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final before = painter(t).phase;
    await t.pump(const Duration(seconds: 2));
    expect(painter(t).phase, before);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(painter(t).phase, greaterThan(before));
    expect(painter(t).phase - before, lessThan(.05));
    await drain(t);
  });
  testWidgets('TickerMode pauses hidden scene and permits resume', (t) async {
    late StateSetter set;
    var active = true;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: StatefulBuilder(
          builder: (_, update) {
            set = update;
            return TickerMode(
              enabled: active,
              child: const Scaffold(
                body: LiquidGoldBackdrop(child: Text('still')),
              ),
            );
          },
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    set(() => active = false);
    await t.pump();
    final before = painter(t).phase;
    await t.pump(const Duration(seconds: 1));
    expect(painter(t).phase, before);
    set(() => active = true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(painter(t).phase, greaterThan(before));
    await drain(t);
  });
  testWidgets('decorative layer does not intercept taps', (t) async {
    var taps = 0;
    await mount(
      t,
      child: Center(
        child: TextButton(onPressed: () => taps++, child: const Text('save')),
      ),
    );
    await t.tap(find.text('save'));
    await t.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
    expect(t.takeException(), isNull);
    await drain(t);
  });
  testWidgets(
    'actual app flow keeps editing stable, no diary writes, and safe card contrast',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      t.view.physicalSize = const Size(1280, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      try {
        await db.upsertFood(FoodsCompanion.insert(name: '米饭', kcal100: 116));
        await db.upsertFood(FoodsCompanion.insert(name: '鸡蛋', kcal100: 151));
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              prefsProvider.overrideWithValue(prefs),
            ],
            child: const KcalLogApp(),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        final before = painter(t).phase;
        await t.tap(find.byIcon(CupertinoIcons.book));
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        await t.pump();
        final field = find
            .descendant(
              of: find.byType(FoodsPage),
              matching: find.byType(TextField),
            )
            .first;
        await t.enterText(field, '米饭');
        for (var i = 0; i < 3; i++) {
          await t.pump(const Duration(milliseconds: 80));
        }
        expect(t.widget<TextField>(field).controller!.text, '米饭');
        final rectBefore = t.getRect(field);
        await t.pump(const Duration(milliseconds: 400));
        expect(t.getRect(field), rectBefore);
        final rowMaterial = t.widget<Material>(
          find
              .descendant(
                of: find.byType(FoodListItem).first,
                matching: find.byType(Material),
              )
              .first,
        );
        expect(rowMaterial.color!.a, greaterThanOrEqualTo(.9));
        expect(painter(t).phase, greaterThan(before));
        expect(await db.foodCount(), 2);
        expect(await db.select(db.entries).get(), isEmpty);
        final theme = Theme.of(t.element(find.byType(FoodsPage)));
        final card = Color.alphaBlend(theme.cardTheme.color!, Colors.white);
        final fg = theme.colorScheme.onSurfaceVariant;
        final ratio =
            (fg.computeLuminance() + .05) / (card.computeLuminance() + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
        expect(t.takeException(), isNull);
      } finally {
        await drain(t);
        await t.runAsync(db.close);
      }
    },
  );
  test('fluid geometry actually moves and wraps seamlessly', () {
    const size = Size(800, 600);
    for (var band = 0; band < 3; band++) {
      final a = LiquidGoldPainter.ribbonY(.3, band, size, 0);
      final b = LiquidGoldPainter.ribbonY(.3, band, size, .25);
      final end = LiquidGoldPainter.ribbonY(.3, band, size, 1);
      expect((a - b).abs(), greaterThan(1));
      expect(end, closeTo(a, 1e-8));
    }
  });
}
