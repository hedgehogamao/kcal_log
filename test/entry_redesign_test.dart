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
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/sheets/entry_sheet.dart';
import 'package:kcal_log/ui/theme.dart';

class _RetryDatabase extends AppDatabase {
  _RetryDatabase() : super.forTesting(NativeDatabase.memory());
  bool fail = true;
  @override
  Future<void> addEntry(EntriesCompanion c) => fail
      ? Future.error(StateError('fixture write failure'))
      : super.addEntry(c);
}

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Roboto', '/Library/Fonts/Arial Unicode.ttf'),
      ('Ahem', '/Library/Fonts/Arial Unicode.ttf'),
      (
        'MaterialIcons',
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
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
  late Food rice;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    rice = await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        protein100: const Value(2.6),
        fat100: const Value(0.3),
        carb100: const Value(25.9),
        servingGrams: const Value(250),
        servingDesc: const Value('一碗'),
      ),
    );
    await db.saveProfile(
      ProfilesCompanion(id: const Value(1), kcalGoal: const Value(1000)),
    );
  });
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester, {
    FoodEntry? entry,
    AppLang lang = AppLang.zh,
    bool kj = false,
    bool dark = false,
    double width = 390,
    double scale = 1,
    double keyboard = 0,
  }) async {
    SharedPreferences.setMockInitialValues({'useKj': kj});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(width, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
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
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showEntrySheet(
                    context,
                    date: '2026-09-28',
                    meal: MealType.lunch,
                    food: entry == null ? rice : null,
                    entry: entry,
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(find.byType(Navigator).evaluate().first);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('份量选中态、记录后剩余、重复点击只保存一次', (tester) async {
    await open(tester);
    expect(find.text('记录日期：2026-09-28'), findsOneWidget);
    expect(find.text('290 kcal'), findsOneWidget);
    expect(find.text('710 kcal'), findsOneWidget);
    expect(find.textContaining('/9'), findsNothing);
    await tester.tap(find.text('200g'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('200g'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.text('232 kcal'), findsOneWidget);
    expect(find.text('768 kcal'), findsOneWidget);
    await capture(tester, 'entry_redesign_latest');
    final action = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    final saved = await db.select(db.entries).getSingle();
    expect(saved.date, '2026-09-28');
    expect(saved.meal, MealType.lunch);
    expect(saved.grams, 200);
    expect(saved.kcal, 232);
    expect(saved.protein, closeTo(5.2, 0.001));
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  testWidgets('取消份量与餐次修改不写入数据库', (tester) async {
    await open(tester);
    await tester.tap(find.byType(DropdownButtonFormField<MealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('晚餐').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('50g'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(await db.select(db.entries).get(), isEmpty);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });
  for (final kj in [false, true]) {
    testWidgets('仅热量编辑的输入、预览与保存单位一致：kj=$kj', (tester) async {
      await db.addEntry(
        EntriesCompanion.insert(
          date: '2026-09-28',
          meal: MealType.lunch,
          name: '仅热量',
          kcal: 100,
        ),
      );
      final entry = await db.select(db.entries).getSingle();
      await open(tester, entry: entry, kj: kj);
      final field = find.byType(TextField).first;
      expect(
        tester.widget<TextField>(field).controller!.text,
        kj ? '418.4' : '100.0',
      );
      await tester.enterText(field, kj ? '836.8' : '200');
      await tester.pumpAndSettle();
      expect(find.text(kj ? '837 kJ' : '200 kcal'), findsOneWidget);
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(
        (await db.select(db.entries).getSingle()).kcal,
        closeTo(200, 0.001),
      );
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }
  testWidgets('未改动的 kJ 显示不舍入存储快照', (tester) async {
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-09-28',
        meal: MealType.lunch,
        name: '仅热量',
        kcal: 100.03,
      ),
    );
    final entry = await db.select(db.entries).getSingle();
    await open(tester, entry: entry, kj: true);
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    expect((await db.select(db.entries).getSingle()).kcal, 100.03);
    await drain(tester);
  });
  testWidgets('编辑份量预览替换旧记录，不重复计入热量', (tester) async {
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-09-28',
        meal: MealType.lunch,
        name: '米饭',
        foodId: Value(rice.id),
        grams: const Value(100),
        kcal: 116,
      ),
    );
    final entry = await db.select(db.entries).getSingle();
    await db.addEntry(
      EntriesCompanion.insert(
        date: '2026-09-28',
        meal: MealType.breakfast,
        name: '其他',
        kcal: 200,
      ),
    );
    await open(tester, entry: entry);
    await tester.tap(find.text('200g'));
    await tester.pumpAndSettle();
    expect(find.text('568 kcal'), findsOneWidget);
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    final rows = await db.select(db.entries).get();
    expect(rows, hasLength(2));
    expect(rows.firstWhere((e) => e.id == entry.id).kcal, 232);
    await drain(tester);
  });
  testWidgets('无效份量内联报错，修正后清除，不写入无效值', (tester) async {
    await open(tester);
    for (final invalid in ['0', '2..0', 'Infinity', 'NaN']) {
      final field = tester.widget<TextField>(find.byType(TextField).first);
      field.controller!.text = invalid;
      await tester.tap(find.text('确认记录'));
      await tester.pumpAndSettle();
      expect(find.text('请输入大于 0 的份量（克）'), findsOneWidget);
      expect(await db.select(db.entries).get(), isEmpty);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(find.byType(TextField).first, '150');
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的份量（克）'), findsNothing);
    await tester.tap(find.text('确认记录'));
    await tester.pumpAndSettle();
    expect((await db.select(db.entries).getSingle()).kcal, 174);
    await drain(tester);
  });
  testWidgets('保存错误保留输入且允许重试', (tester) async {
    await db.close();
    final retry = _RetryDatabase();
    db = retry;
    rice = await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        servingGrams: const Value(250),
      ),
    );
    await open(tester);
    await tester.tap(find.text('确认记录'));
    await tester.pumpAndSettle();
    expect(find.text('保存失败'), findsOneWidget);
    expect(find.byType(EntrySheet), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '250.0',
    );
    expect(await db.select(db.entries).get(), isEmpty);
    retry.fail = false;
    await tester.tap(find.text('确认记录'));
    await tester.pumpAndSettle();
    expect(await db.select(db.entries).get(), hasLength(1));
    await drain(tester);
  });
  for (final lang in AppLang.values) {
    testWidgets('320px 深色、2倍字体、键盘打开仍能记录：${lang.code}', (tester) async {
      await open(
        tester,
        lang: lang,
        dark: true,
        width: 320,
        scale: 2,
        keyboard: 200,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
      if (lang == AppLang.zh) {
        await capture(tester, 'entry_redesign_accessible_latest');
      }
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(await db.select(db.entries).get(), hasLength(1));
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }
}
