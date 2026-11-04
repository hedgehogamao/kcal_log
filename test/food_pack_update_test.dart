import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/data/food_pack_update.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/pages/food_packs_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final payload = utf8.encode(
  jsonEncode({
    'app': 'kcal_log.food_pack',
    'schema': 1,
    'packId': 'kcal-log.common-foods',
    'revision': 3,
    'title': '测试更新',
    'foods': [
      {
        'id': 'new-food',
        'name': '新增食物',
        'category': 'other',
        'kcal100': 123,
        'protein100': 1,
        'fat100': 2,
        'carb100': 3,
      },
    ],
  }),
);
FoodPackUpdateService service({
  bool badHash = false,
  String? url,
  int status = 200,
  List<String>? calls,
}) => FoodPackUpdateService(
  MockClient((r) async {
    calls?.add(r.url.toString());
    if (r.url.host == 'api.github.com') {
      return http.Response(
        jsonEncode({
          'draft': false,
          'assets': [
            {
              'name': 'common-foods-5000.json',
              'browser_download_url': url ?? 'https://github.com/hedgehogamao/kcal_log/releases/download/v0.1.2/common-foods-5000.json',
              'digest':
                  'sha256:${badHash ? '0' * 64 : sha256.convert(payload)}',
            },
          ],
        }),
        status,
      );
    }
    return http.Response.bytes(payload, 200);
  }),
);
void main() {
  test('official data digest and schema verified', () async {
    final p = await service().check();
    expect(p.revision, 3);
    expect(p.foods.single.name, '新增食物');
  });
  test('wrong SHA256 rejected before import', () async {
    await expectLater(service(badHash: true).check(), throwsA(anything));
  });
  test('third-party download rejected before request', () async {
    final calls = <String>[];
    await expectLater(
      service(url: 'https://evil.invalid/payload.json', calls: calls).check(),
      throwsA(anything),
    );
    expect(calls.length, 1);
  });
  test('offline/server error reported and no fallback guessing', () async {
    await expectLater(service(status: 503).check(), throwsA(anything));
  });
  testWidgets('no auto network, download preview cancel and confirmed import', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final calls = <String>[];
    try {
      t.view.physicalSize = const Size(500, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            prefsProvider.overrideWithValue(prefs),
            foodPackUpdateProvider.overrideWithValue(service(calls: calls)),
          ],
          child: const LangScope(
            lang: AppLang.zh,
            child: MaterialApp(home: FoodPacksPage()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(calls, isEmpty);
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('food-pack-check-online')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      expect(calls.length, 2);
      expect(await db.foodCount(), 0);
      await t.tap(find.byKey(const ValueKey('food-pack-online-preview')));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(find.text('取消'));
      await t.pumpAndSettle();
      expect(await db.foodCount(), 0);
      await t.tap(find.byKey(const ValueKey('food-pack-online-preview')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('food-pack-apply')));
      await t.pumpAndSettle();
      expect(await db.foodCount(), 1);
      expect((await db.select(db.foodCatalogs).get()).single.revision, 3);
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 200));
      await db.close();
    }
  });
}
