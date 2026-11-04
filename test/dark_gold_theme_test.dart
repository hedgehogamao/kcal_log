import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/filter_pills.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);
void main() {
  test('dark palette uses warm black surfaces and muted gold primary', () {
    final t = buildDarkTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, const Color(0xFF12110F));
    expect(t.cardTheme.color, const Color(0xFF1E1B16));
    expect(t.colorScheme.primary, const Color(0xFFC7A45D));
    expect(t.appBarTheme.backgroundColor, t.scaffoldBackgroundColor);
  });
  test(
    'explicit light mode retains a coordinated ivory and dark-gold palette',
    () {
      final t = buildLightTheme();
      expect(t.brightness, Brightness.light);
      expect(t.scaffoldBackgroundColor, const Color(0xFFF4F0E8));
      expect(t.colorScheme.primary, const Color(0xFF806128));
    },
  );
  for (final dark in [false, true]) {
    test('readable ordinary text and filled-control contrast dark=$dark', () {
      final t = dark ? buildDarkTheme() : buildLightTheme();
      final s = t.colorScheme;
      for (final (fg, bg) in [
        (s.onSurface, s.surface),
        (s.onSurfaceVariant, s.surface),
        (s.onPrimary, s.primary),
        (s.onSecondary, s.secondary),
        (s.onTertiary, s.tertiary),
        (s.onError, s.error),
        (t.snackBarTheme.actionTextColor!, t.snackBarTheme.backgroundColor!),
      ]) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(s.primary, t.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
    });
    test(
      'nutrient and warning colors stay distinct and readable dark=$dark',
      () {
        final t = dark ? buildDarkTheme() : buildLightTheme();
        final colors = [
          LabelColors.energyOf(dark),
          LabelColors.proteinOf(dark),
          LabelColors.fatOf(dark),
          LabelColors.carbOf(dark),
          LabelColors.weightOf(dark),
          LabelColors.errorOf(dark),
        ];
        expect(colors.toSet().length, 6);
        for (final c in colors) {
          expect(contrast(c, t.cardTheme.color!), greaterThanOrEqualTo(4.5));
        }
      },
    );
    testWidgets('selected pill uses contrast-safe gold foreground dark=$dark', (
      t,
    ) async {
      final theme = dark ? buildDarkTheme() : buildLightTheme();
      String? picked;
      await t.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FilterPills<String>(
              items: const [('a', 'All'), ('b', 'Favorites')],
              selected: 'a',
              onChanged: (v) => picked = v,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final text = t.widget<Text>(find.text('All'));
      expect(text.style!.color, theme.colorScheme.onPrimary);
      await t.tap(find.text('Favorites'));
      expect(picked, 'b');
      expect(t.takeException(), isNull);
    });
  }
  test('unset mode defaults dark without writing preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(p)],
    );
    addTearDown(c.dispose);
    expect(c.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(p.containsKey('themeMode'), isFalse);
    expect(const AppSettings().themeMode, ThemeMode.dark);
  });
  for (final mode in ThemeMode.values) {
    test('explicit mode remains unchanged ${mode.name}', () async {
      SharedPreferences.setMockInitialValues({'themeMode': mode.index});
      final p = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(p)],
      );
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).themeMode, mode);
      expect(p.getInt('themeMode'), mode.index);
    });
  }
}
