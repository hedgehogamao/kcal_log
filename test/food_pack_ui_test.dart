import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/pages/food_packs_page.dart';
import 'package:kcal_log/ui/theme.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

class PackPicker extends FilePicker {
  FilePickerResult? result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => result;
  void file(Map<String, dynamic> data) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    result = FilePickerResult([
      PlatformFile(name: 'food-pack.json', size: bytes.length, bytes: bytes),
    ]);
  }
}

void main() {
  late AppDatabase db;
  late PackPicker picker;
  late FilePicker original;
  setUpAll(() async {
    try {
      original = FilePicker.platform;
    } on Error {
      original = PackPicker();
    }
    for (final (family, path) in [
      ('Roboto', '/Library/Fonts/Arial Unicode.ttf'),
      (
        'MaterialIcons',
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final font = File(path);
      if (font.existsSync()) {
        await (FontLoader(family)..addFont(
              Future.value(ByteData.view(font.readAsBytesSync().buffer)),
            ))
            .load();
      }
    }
  });
  tearDownAll(() => FilePicker.platform = original);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedIfEmpty(db);
    picker = PackPicker();
    FilePicker.platform = picker;
  });
  tearDown(() => db.close());
  Map<String, dynamic> data(int revision, {double kcal = 100}) => {
    'app': 'kcal_log.food_pack',
    'schema': 1,
    'packId': 'ui.test',
    'revision': revision,
    'title': '食物包演示',
    'foods': [
      {
        'id': 'new',
        'name': '食物包测试食物',
        'category': 'other',
        'kcal100': kcal,
        'protein100': 1,
        'fat100': 2,
        'carb100': 10,
      },
    ],
  };
  Future<void> open(
    WidgetTester t, {
    AppLang lang = AppLang.zh,
    bool dark = false,
    double scale = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    t.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 200));
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: LangScope(
          lang: lang,
          child: MaterialApp(
            theme: dark ? buildDarkTheme() : buildLightTheme(),
            home: const FoodsPage(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('food-pack-open')));
    await t.pumpAndSettle();
    expect(find.byType(FoodPacksPage), findsOneWidget);
  }

  Future<void> pick(WidgetTester t) async {
    final control = find.byKey(const ValueKey('food-pack-pick'));
    await t.ensureVisible(control);
    await t.tap(control);
    await t.pumpAndSettle();
  }

  for (final lang in AppLang.values) {
    packTestWidgets(
      '320px 2x ${lang.code}: preview cancellation, load, next data revision without app update',
      (t) async {
        await open(t, lang: lang, scale: 2, dark: lang == AppLang.es);
        picker.file(data(1));
        await pick(t);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(await db.foodCount(), 1000);
        await t.tap(find.text(tText(lang, 'cancel')));
        await t.pumpAndSettle();
        expect(await db.foodCount(), 1000);
        await pick(t);
        await t.tap(find.byKey(const ValueKey('food-pack-apply')));
        await t.pumpAndSettle();
        expect(await db.foodCount(), 1001);
        final first = (await db.searchFoods('食物包测试食物')).single;
        expect(first.kcal100, 100);
        picker.file(data(2, kcal: 120));
        await pick(t);
        await t.tap(find.byKey(const ValueKey('food-pack-apply')));
        await t.pumpAndSettle();
        final second = (await db.searchFoods('食物包测试食物')).single;
        expect(second.id, first.id);
        expect(second.kcal100, 120);
        expect(await db.foodCount(), 1001);
        await pick(t);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(tText(lang, 'packCurrent')), findsOneWidget);
        expect(t.takeException(), isNull);
        if (lang == AppLang.zh) {
          final bytes = await t.runAsync(() async {
            final image = await captureImage(
              find.byType(Navigator).evaluate().first,
            );
            return image.toByteData(format: ui.ImageByteFormat.png);
          });
          File('verification/redesign_20260929/food_pack_loaded.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        await t.pageBack();
        await t.pumpAndSettle();
        // Data-pack foods are visible in the normal All list, not just in SQLite.
        final input = find.byType(TextField).first;
        await t.enterText(input, '食物包测试食物');
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(FoodListItem),
            matching: find.text('食物包测试食物'),
          ),
          findsOneWidget,
        );
      },
    );
  }

  packTestWidgets(
    '5000 JSON loads through existing App picker preview confirm and normal search',
    (t) async {
      final raw = jsonDecode(
        File('food-packs/common-foods-5000.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final newName = ((raw['foods'] as List)[1000] as Map)['name'] as String;
      await open(t);
      picker.file(raw);
      await pick(t);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await db.foodCount(), 1000);
      await t.tap(find.text(tText(AppLang.zh, 'cancel')));
      await t.pumpAndSettle();
      expect(await db.foodCount(), 1000);
      await pick(t);
      await t.tap(find.byKey(const ValueKey('food-pack-apply')));
      await t.pumpAndSettle();
      expect(await db.foodCount(), 5000);
      expect((await db.select(db.foodCatalogs).get()).single.revision, 3);
      await pick(t);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(tText(AppLang.zh, 'packCurrent')), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, newName);
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(FoodListItem),
          matching: find.text(newName),
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );

  packTestWidgets(
    'invalid pack and picker cancel leave foods and metadata unchanged',
    (t) async {
      await open(t);
      await pick(t);
      expect(await db.foodCount(), 1000);
      picker.file({'app': 'kcal_log', 'schema': 1, 'foods': []});
      await pick(t);
      expect(find.byKey(const ValueKey('food-pack-error')), findsOneWidget);
      expect(await db.foodCount(), 1000);
      expect(await db.select(db.foodCatalogs).get(), isEmpty);
      expect(t.takeException(), isNull);
    },
  );
}

String tText(AppLang lang, String key) => t(lang, key);

// Dispose active Drift streams inside the test body, before binding invariants.
void packTestWidgets(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
