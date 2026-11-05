import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/auto_backup_controller.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/foods_page.dart';
import 'package:kcal_log/ui/widgets/auto_backup_panel.dart';
import 'package:kcal_log/ui/widgets/food_list_item.dart';

void main() {
  for (final lang in AppLang.values) {
    testWidgets(
      'actual food library pinyin/typo candidates require explicit entry confirmation ${lang.code}',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          await db.upsertFood(FoodsCompanion.insert(name: '鸡胸肉', kcal100: 123));
          t.view.physicalSize = const Size(1200, 900);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                dbProvider.overrideWithValue(db),
                prefsProvider.overrideWithValue(prefs),
              ],
              child: LangScope(
                lang: lang,
                child: const MaterialApp(home: FoodsPage()),
              ),
            ),
          );
          await t.pumpAndSettle();
          final field = find.byType(TextField).first;
          await t.enterText(field, 'jxr');
          await t.pumpAndSettle();
          expect(find.text('鸡胸肉'), findsOneWidget);
          expect(await db.select(db.entries).get(), isEmpty);
          await t.enterText(field, '鸡胸内');
          await t.pumpAndSettle();
          expect(
            find.textContaining(tText(lang, 'search2Approximate')),
            findsWidgets,
          );
          await t.tap(find.byType(FoodListItem).first);
          await t.pumpAndSettle();
          expect(await db.select(db.entries).get(), isEmpty);
          expect(
            find.byKey(const ValueKey('desktop-food-portion')),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(milliseconds: 200));
          await db.close();
        }
      },
    );
    testWidgets(
      'backup UI opt-in, actual snapshot, preview cancel/ack/restore ${lang.code}',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final dir = (await t.runAsync(
          () => Directory.systemTemp.createTemp('kcal-backup-ui-'),
        ))!;
        try {
          await db.upsertFood(FoodsCompanion.insert(name: '原食物', kcal100: 100));
          t.view.physicalSize = const Size(1000, 1500);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                dbProvider.overrideWithValue(db),
                prefsProvider.overrideWithValue(prefs),
                backupDirectoryProvider.overrideWithValue(
                  () async => Directory('${dir.path}/managed'),
                ),
              ],
              child: LangScope(
                lang: lang,
                child: const MaterialApp(
                  home: Scaffold(
                    body: SingleChildScrollView(child: AutoBackupPanel()),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(
            await t.runAsync(() => Directory('${dir.path}/managed').exists()),
            isFalse,
          );
          final context = t.element(find.byType(AutoBackupPanel));
          final container = ProviderScope.containerOf(context);
          Future<void> settleIO() async {
            for (var i = 0; i < 200; i++) {
              await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await t.pump(const Duration(milliseconds: 20));
              if (!container.read(autoBackupProvider).busy && i >= 10) break;
            }
            expect(
              container.read(autoBackupProvider).busy,
              isFalse,
              reason: 'Real backup I/O must finish',
            );
          }

          Future<void> realTap(Finder finder) async {
            await t.tap(finder);
            await settleIO();
            await t.pumpAndSettle();
          }

          await realTap(find.byKey(const ValueKey('auto-backup-toggle')));
          expect(container.read(autoBackupProvider).enabled, isTrue);
          expect(container.read(autoBackupProvider).items, isNotEmpty);
          await db.upsertFood(
            FoodsCompanion.insert(name: '后来食物', kcal100: 200),
          );
          await realTap(find.byKey(const ValueKey('auto-backup-manage')));
          await t.pumpAndSettle();
          await t.runAsync(() async {
            await container.read(autoBackupProvider.notifier).refresh();
          });
          await t.pumpAndSettle();
          final restore = find.byWidgetPredicate(
            (w) =>
                w is TextButton &&
                w.key.toString().contains('auto-backup-restore-'),
          );
          await realTap(restore.first);
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await t.pumpAndSettle();
          expect(find.byType(BackupRestoreDialog), findsOneWidget);
          expect(
            t
                .widget<FilledButton>(
                  find.byKey(const ValueKey('auto-backup-confirm-restore')),
                )
                .onPressed,
            isNull,
          );
          await t.tap(find.text(tText(lang, 'cancel')));
          await t.pumpAndSettle();
          expect((await db.select(db.foods).get()).length, 2);
          await realTap(restore.first);
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('auto-backup-restore-ack')));
          await t.pump();
          await realTap(
            find.byKey(const ValueKey('auto-backup-confirm-restore')),
          );
          await t.runAsync(() async {
            for (var i = 0; i < 100; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              if (!container.read(autoBackupProvider).busy) break;
            }
          });
          await t.pumpAndSettle();
          expect((await db.select(db.foods).get()).single.name, '原食物');
          expect(container.read(autoBackupProvider).items.length, 2);
          expect(t.takeException(), isNull);
        } finally {
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(milliseconds: 200));
          await t.runAsync(db.close);
          await t.runAsync(() => dir.delete(recursive: true));
        }
      },
    );
  }
}

String tText(AppLang l, String k) => t(l, k);
