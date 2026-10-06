import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/seed_data.dart';
import 'package:kcal_log/logic/calc.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/main.dart';
import 'package:kcal_log/ui/pages/settings_page.dart';
import 'package:kcal_log/ui/widgets/app_segmented.dart';

class FixturePicker extends FilePicker {
  String? path;
  FilePickerResult? picked;
  Completer<String?>? pending;
  bool unsupported = false;
  int saveCalls = 0, pickCalls = 0;
  Uint8List? suppliedBytes;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saveCalls++;
    suppliedBytes = bytes;
    if (unsupported) throw UnsupportedError('fixture');
    return pending == null ? path : await pending!.future;
  }

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
  }) async {
    pickCalls++;
    return picked;
  }

  void backup(Map<String, dynamic> data) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    picked = FilePickerResult([
      PlatformFile(name: 'fixture.json', size: bytes.length, bytes: bytes),
    ]);
  }
}

void main() {
  late FilePicker originalPicker;
  test('估算要求明确性别、有限正身高体重，不把缺失性别当男性', () {
    final year = DateTime.now().year - 30;
    expect(estimateTdee(birthYear: year, heightCm: 175, weightKg: 70), isNull);
    for (final value in [double.nan, double.infinity, 0.0, -1.0, 501.0]) {
      expect(
        estimateTdee(
          sex: Sex.male,
          birthYear: year,
          heightCm: 175,
          weightKg: value,
        ),
        isNull,
      );
    }
    expect(
      estimateTdee(
        sex: Sex.female,
        birthYear: year,
        heightCm: double.infinity,
        weightKg: 70,
      ),
      isNull,
    );
    expect(
      estimateTdee(
        sex: Sex.male,
        birthYear: DateTime.now().year,
        heightCm: 175,
        weightKg: 70,
      ),
      isNull,
    );
    expect(
      estimateTdee(sex: Sex.male, birthYear: year, heightCm: 175, weightKg: 70),
      closeTo(2555.5625, 0.0001),
    );
  });
  setUpAll(() async {
    try {
      originalPicker = FilePicker.platform;
    } on Error {
      originalPicker = FixturePicker();
    }
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
  late Directory directory;
  late FixturePicker picker;
  String? copiedPath;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedIfEmpty(db);
    await db.saveProfile(
      ProfilesCompanion(
        id: const Value(1),
        kcalGoal: const Value(2000),
        proteinGoal: const Value(100),
        weightKg: const Value(70),
      ),
    );
    directory = Directory.systemTemp.createTempSync('kcal-settings-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => directory.path);
    copiedPath = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedPath = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    picker = FixturePicker();
    FilePicker.platform = picker;
  });
  tearDown(() async {
    FilePicker.platform = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await db.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });
  Future<void> drain(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> open(
    WidgetTester t, {
    bool kj = false,
    bool dark = false,
    AppLang lang = AppLang.zh,
    double scale = 1,
    double width = 390,
  }) async {
    SharedPreferences.setMockInitialValues({
      'useKj': kj,
      'lang': lang.code,
      'themeMode': (dark ? ThemeMode.dark : ThemeMode.light).index,
    });
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = Size(width, 1050);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => drain(t));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
        ],
        child: const KcalLogApp(),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(
      find.text(switch (lang) {
        AppLang.zh => '设置',
        AppLang.en => 'Settings',
        AppLang.es => 'Ajustes',
      }),
    );
    await t.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(t.element(find.byType(SettingsPage))).scale(10),
      scale * 10,
    );
  }

  Future<void> reveal(WidgetTester t, Finder target) async {
    if (target.evaluate().isEmpty) {
      final scrollable = find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      final state = t.state<ScrollableState>(scrollable);
      state.position.jumpTo(state.position.minScrollExtent);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(target, 300, scrollable: scrollable);
    } else {
      await t.ensureVisible(target);
    }
    await t.pumpAndSettle();
  }

  Future<void> capture(WidgetTester t, String name) async {
    final bytes = await t.runAsync(() async {
      final img = await captureImage(find.byType(Navigator).evaluate().first);
      return img.toByteData(format: ui.ImageByteFormat.png);
    });
    File('verification/redesign_20260929/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  Future<void> profile(WidgetTester t) async {
    await reveal(t, find.byKey(const ValueKey('profile-row')));
    await t.tap(find.byKey(const ValueKey('profile-row')));
    await t.pumpAndSettle();
  }

  Future<void> fill(WidgetTester t, String key, String value) async {
    final f = find.byKey(ValueKey(key));
    await reveal(t, f);
    await t.enterText(f, value);
    await t.pumpAndSettle();
  }

  Future<void> validProfile(WidgetTester t) async {
    await reveal(t, find.byKey(const ValueKey('profile-sex')));
    await t.tap(find.byKey(const ValueKey('profile-sex')));
    await t.pumpAndSettle();
    await t.tap(find.text('男').last);
    await t.pumpAndSettle();
    await fill(t, 'profile-year', '${DateTime.now().year - 30}');
    await fill(t, 'profile-height', '175');
    await fill(t, 'profile-weight', '70');
  }

  Future<void> awaitIO(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 200; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await t.pump(const Duration(milliseconds: 10));
      if (ready() &&
          find.byKey(const ValueKey('backup-result')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(ready(), isTrue);
    expect(find.byKey(const ValueKey('backup-result')), findsOneWidget);
    await t.pumpAndSettle();
  }

  testWidgets('能量目标kJ输入显示与保存一致，清除和取消明确', (t) async {
    await open(t, kj: true);
    expect(find.text('8368 kJ'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('goal-kcal')));
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('number-input')))
          .controller!
          .text,
      '8368.0',
    );
    await t.enterText(find.byKey(const ValueKey('number-input')), '10041.6');
    await t.tap(find.text('确定'));
    await t.pumpAndSettle();
    var p = await db.select(db.profiles).getSingle();
    expect(p.kcalGoal, closeTo(2400, 0.00001));
    expect(p.proteinGoal, 100);
    await t.tap(find.byKey(const ValueKey('goal-kcal')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('number-input')), '777');
    await t.tap(find.text('取消'));
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).kcalGoal, p.kcalGoal);
    await t.tap(find.byKey(const ValueKey('goal-kcal')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('number-input')), '');
    await t.tap(find.text('确定'));
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).kcalGoal, isNull);
    await drain(t);
  });
  testWidgets('未改动的舍入目标不损失原始精度，显式按钮清除宏量', (t) async {
    await db.saveProfile(
      ProfilesCompanion(id: const Value(1), kcalGoal: const Value(1800.12345)),
    );
    await open(t, kj: true);
    await t.tap(find.byKey(const ValueKey('goal-kcal')));
    await t.pumpAndSettle();
    await t.tap(find.text('确定'));
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).kcalGoal, 1800.12345);
    await t.tap(find.byKey(const ValueKey('goal-protein')));
    await t.pumpAndSettle();
    await t.tap(find.text('清除目标'));
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).proteinGoal, isNull);
    await drain(t);
  });
  testWidgets('无效数字留在目标弹窗，修改可恢复，Enter确认', (t) async {
    await open(t);
    await t.tap(find.byKey(const ValueKey('goal-kcal')));
    await t.pumpAndSettle();
    for (final bad in ['NaN', 'Infinity', '-2', '0', '10000001', 'abc']) {
      await t.enterText(find.byKey(const ValueKey('number-input')), bad);
      await t.tap(find.text('确定'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('number-input')))
            .decoration!
            .errorText,
        isNotNull,
      );
      expect((await db.select(db.profiles).getSingle()).kcalGoal, 2000);
    }
    await t.enterText(find.byKey(const ValueKey('number-input')), '1900');
    await t.pump();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('number-input')))
          .decoration!
          .errorText,
      isNull,
    );
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).kcalGoal, 1900);
    await drain(t);
  });
  testWidgets('资料不会默认选男性或自动覆盖目标，保存同步今天体重', (t) async {
    await open(t);
    await profile(t);
    expect(find.text('请选择'), findsOneWidget);
    await validProfile(t);
    await reveal(t, find.byKey(const ValueKey('apply-estimate')));
    expect(
      t
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('apply-estimate')),
          )
          .value,
      isFalse,
    );
    await t.tap(find.byKey(const ValueKey('save-profile')));
    await t.pumpAndSettle();
    final p = await db.select(db.profiles).getSingle();
    expect(p.sex, Sex.male);
    expect(p.heightCm, 175);
    expect(p.weightKg, 70);
    expect(p.kcalGoal, 2000);
    expect(p.proteinGoal, 100);
    expect(
      (await db.select(db.weights).getSingle()).date,
      dateKey(DateTime.now()),
    );
    await drain(t);
  });
  testWidgets('明确勾选后，估算目标与宏量在一次事务中保存', (t) async {
    await open(t, kj: true);
    await profile(t);
    await validProfile(t);
    await reveal(t, find.byKey(const ValueKey('apply-estimate')));
    await t.tap(find.byKey(const ValueKey('apply-estimate')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('save-profile')));
    await t.pumpAndSettle();
    final p = await db.select(db.profiles).getSingle();
    expect(p.kcalGoal, closeTo(2555.5625, 0.001));
    final (protein, fat, carb) = defaultMacroGoals(p.kcalGoal!);
    expect(p.proteinGoal, protein);
    expect(p.fatGoal, fat);
    expect(p.carbGoal, carb);
    await drain(t);
  });
  testWidgets('资料校验内联、取消不写入，保存失败回滚且能重试', (t) async {
    await open(t);
    await profile(t);
    await fill(t, 'profile-year', '3000');
    await fill(t, 'profile-height', 'NaN');
    await fill(t, 'profile-weight', 'Infinity');
    await t.tap(find.byKey(const ValueKey('save-profile')));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect((await db.select(db.profiles).getSingle()).birthYear, isNull);
    await t.tap(find.text('取消'));
    await t.pumpAndSettle();
    expect(await db.select(db.weights).get(), isEmpty);
    await profile(t);
    await validProfile(t);
    await db.customStatement(
      "CREATE TRIGGER fail_weight BEFORE INSERT ON weights BEGIN SELECT RAISE(FAIL, 'fixture'); END",
    );
    await t.tap(find.byKey(const ValueKey('save-profile')));
    await t.pumpAndSettle();
    expect(find.text('保存失败'), findsOneWidget);
    expect((await db.select(db.profiles).getSingle()).sex, isNull);
    expect(await db.select(db.weights).get(), isEmpty);
    await db.customStatement('DROP TRIGGER fail_weight');
    await t.tap(find.byKey(const ValueKey('save-profile')));
    await t.pumpAndSettle();
    expect((await db.select(db.profiles).getSingle()).sex, Sex.male);
    await drain(t);
  });
  testWidgets('饮水目标写入偏好且主题与能量控件可切换', (t) async {
    await open(t);
    await reveal(t, find.byKey(const ValueKey('water-goal-row')));
    await t.tap(find.byKey(const ValueKey('water-goal-row')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('number-input')), '0.1');
    await t.tap(find.text('确定'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getInt('waterGoalMl'),
      isNull,
    );
    await t.enterText(find.byKey(const ValueKey('number-input')), '2500');
    await t.tap(find.text('确定'));
    await t.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getInt('waterGoalMl'), 2500);
    await reveal(t, find.byType(AppSegmented<ThemeMode>));
    await t.tap(find.text('深色'));
    await t.pumpAndSettle();
    expect(
      Theme.of(t.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    final toggle = find.byType(CupertinoSwitch);
    await reveal(t, toggle);
    await t.tap(toggle);
    await t.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool('useKj'), isTrue);
    await drain(t);
  });
  testWidgets('桌面导出实际写入JSON，取消无隐式文件，忙时不能重复提交', (t) async {
    await open(t);
    await reveal(t, find.byKey(const ValueKey('export-row')));
    picker.pending = Completer<String?>();
    await t.tap(find.byKey(const ValueKey('export-row')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('export-row')));
    await t.pump();
    expect(picker.saveCalls, 1);
    picker.pending!.complete(null);
    await t.pumpAndSettle();
    expect(directory.listSync(), isEmpty);
    picker.pending = null;
    picker.path = '${directory.path}/chosen.json';
    await t.tap(find.byKey(const ValueKey('export-row')));
    await awaitIO(t, () => File(picker.path!).existsSync());
    final backup = jsonDecode(
      File(picker.path!).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(backup['app'], 'kcal_log');
    expect((backup['foods'] as List).length, 1000);
    expect(picker.suppliedBytes, isNull);
    expect(find.byKey(const ValueKey('backup-result')), findsOneWidget);
    await drain(t);
  });
  testWidgets('不支持另存为时写入备用目录并显示真实路径', (t) async {
    picker.unsupported = true;
    await open(t);
    await reveal(t, find.byKey(const ValueKey('export-row')));
    await t.tap(find.byKey(const ValueKey('export-row')));
    final file = File(
      '${directory.path}/kcallog-backup-${dateKey(DateTime.now())}.json',
    );
    await awaitIO(t, () => file.existsSync());
    expect(jsonDecode(file.readAsStringSync())['app'], 'kcal_log');
    expect(find.byKey(const ValueKey('backup-result')), findsOneWidget);
    await drain(t);
  });
  testWidgets('导入有文件内容预览、明确确认和取消；保存后1000分类仍在', (t) async {
    final backup = await db.exportJson();
    await db.addEntry(
      EntriesCompanion.insert(
        date: dateKey(DateTime.now()),
        meal: MealType.lunch,
        name: 'current fixture',
        kcal: 120,
      ),
    );
    picker.backup(backup);
    await open(t);
    await reveal(t, find.byKey(const ValueKey('import-row')));
    await t.tap(find.byKey(const ValueKey('import-row')));
    await t.pumpAndSettle();
    expect(find.text('1000 条食物 · 0 条记录'), findsOneWidget);
    expect(
      t
          .widget<FilledButton>(find.byKey(const ValueKey('confirm-import')))
          .onPressed,
      isNull,
    );
    await t.tap(find.text('取消'));
    await t.pumpAndSettle();
    expect((await db.select(db.entries).get()).length, 1);
    await t.tap(find.byKey(const ValueKey('import-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('import-ack')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('confirm-import')));
    await t.pumpAndSettle();
    expect(await db.select(db.entries).get(), isEmpty);
    final foods = await db.select(db.foods).get();
    expect(foods.length, 1000);
    expect(foods.every((f) => f.category != 'legacy'), isTrue);
    expect(find.text('导入完成'), findsOneWidget);
    await drain(t);
  });
  testWidgets('错误备份不会改库，事务导入失败仍保留全部原数据', (t) async {
    await db.addEntry(
      EntriesCompanion.insert(
        date: dateKey(DateTime.now()),
        meal: MealType.dinner,
        name: 'keep',
        kcal: 111,
      ),
    );
    final backup = await db.exportJson();
    picker.backup({'app': 'wrong'});
    await open(t);
    await reveal(t, find.byKey(const ValueKey('import-row')));
    await t.tap(find.byKey(const ValueKey('import-row')));
    await t.pumpAndSettle();
    expect(find.text('不是本应用的备份文件'), findsOneWidget);
    expect((await db.select(db.entries).get()).single.name, 'keep');
    backup['foods'] = [
      {'id': 'not numeric', 'name': 'broken'},
    ];
    picker.backup(backup);
    await t.tap(find.byKey(const ValueKey('import-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('import-ack')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('confirm-import')));
    await t.pumpAndSettle();
    expect((await db.select(db.foods).get()).length, 1000);
    expect((await db.select(db.entries).get()).single.kcal, 111);
    expect((await db.select(db.profiles).getSingle()).kcalGoal, 2000);
    expect(find.text('导入失败'), findsOneWidget);
    await drain(t);
  });
  testWidgets('数据路径与Drift实际默认目录一致且可完整复制', (t) async {
    await open(t);
    await reveal(t, find.text('${directory.path}/kcallog.sqlite'));
    expect(find.text('${directory.path}/kcallog.sqlite'), findsOneWidget);
    await t.tap(find.text('复制路径'));
    await t.pumpAndSettle();
    expect(copiedPath, '${directory.path}/kcallog.sqlite');
    await drain(t);
  });
  for (final lang in AppLang.values) {
    testWidgets('设置和资料320px两倍字号深色三语：${lang.code}', (t) async {
      await open(t, lang: lang, scale: 2, width: 320, dark: true, kj: true);
      if (lang == AppLang.zh) {
        await capture(t, 'settings_redesign_accessible_latest');
      }
      final list = find.descendant(
        of: find.byType(SettingsPage),
        matching: find.byType(ListView),
      );
      for (var i = 0; i < 7; i++) {
        await t.drag(list, const Offset(0, -550));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      await profile(t);
      await reveal(t, find.byKey(const ValueKey('profile-activity')));
      expect(t.takeException(), isNull);
      // A green layout result must not hide a horizontally clipped form.
      expect(
        t.getSize(find.byType(Form)).width,
        lessThanOrEqualTo(t.getSize(find.byType(AlertDialog)).width - 48),
      );
      // ignore: avoid_print
      print(
        'PROFILE_FORM_${lang.code}=${t.getSize(find.byType(Form))};DIALOG=${t.getSize(find.byType(AlertDialog))}',
      );
      await capture(t, 'profile_redesign_accessible_${lang.code}');
      if (lang == AppLang.zh) {
        await capture(t, 'profile_redesign_accessible_latest');
      }
      // Close using the translated action, not a label that varies with scrolling.
      await t.tap(
        find.text(switch (lang) {
          AppLang.zh => '取消',
          AppLang.en => 'Cancel',
          AppLang.es => 'Cancelar',
        }),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await drain(t);
    });
  }
  testWidgets('设置390px和桌面960px阅读宽度预览', (t) async {
    await open(t);
    await capture(t, 'settings_redesign_latest');
    await drain(t);
    await open(t, width: 1280);
    expect(
      t
          .getSize(
            find.descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(ListView),
            ),
          )
          .width,
      lessThanOrEqualTo(960),
    );
    await capture(t, 'settings_redesign_desktop_latest');
    expect(t.takeException(), isNull);
    await drain(t);
  });
}
