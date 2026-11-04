import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/i18n.dart';
import 'package:kcal_log/logic/food_search.dart';
import 'package:kcal_log/logic/providers.dart';
import 'package:kcal_log/ui/widgets/food_provenance.dart';

Food sample() => Food(
  id: 7,
  name: '土豆 · Potatoes, raw, skin',
  source: 'pack',
  category: 'vegetable',
  kcal100: 70,
  protein100: 2,
  fat100: 0,
  carb100: 15,
  favorite: false,
  createdAt: DateTime(2026),
);
FoodCatalog catalog(String id, int foodId, {bool blocked = false}) =>
    FoodCatalog(
      packId: id,
      revision: 3,
      title: '示例包',
      stateJson: jsonEncode({
        'items': {
          'food-key': {'foodId': foodId, 'blocked': blocked},
        },
      }),
      appliedAt: DateTime(2026),
    );
void main() {
  test(
    'revision only from exact ownership, not the newest unrelated catalog',
    () {
      final links = linkedFoodRevisions(sample(), [
        catalog('other-pack', 8),
        catalog('correct-pack', 7),
      ]);
      expect(links.length, 1);
      expect(links.single, contains('correct-pack · r3 · food-key'));
    },
  );
  test('corrupt metadata is not invented; protected association is still labelled as association', () {
    final bad = catalog('bad', 7).copyWith(stateJson: '{');
    expect(linkedFoodRevisions(sample(), [bad]), isEmpty);
    expect(
      linkedFoodRevisions(sample(), [
        catalog('protected', 7, blocked: true),
      ]).length,
      1,
    );
  });
  test(
    'known Chinese search synonyms are shown without changing stored name',
    () {
      final f = sample();
      expect(foodSearchAliases(f.name), containsAll(['马铃薯', '洋芋']));
      expect(f.name, '土豆 · Potatoes, raw, skin');
    },
  );
  test('no synonyms or raw/cooked metadata invented for an unknown food', () {
    expect(foodSearchAliases('UNKNOWN FOOD'), isEmpty);
  });
  for (final lang in AppLang.values) {
    testWidgets('full provenance wraps at 320px 2x ${lang.code}', (t) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db
            .into(db.foodCatalogs)
            .insert(
              FoodCatalogsCompanion.insert(
                packId: 'correct-pack',
                appliedAt: DateTime(2026),
                revision: 3,
                title: '示例包',
                stateJson: catalog('correct-pack', 7).stateJson,
              ),
            );
        t.view.physicalSize = const Size(320, 1000);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: LangScope(
              lang: lang,
              child: MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: FoodProvenance(food: sample()),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text(tText(lang, 'foodProvenance')));
        await t.pumpAndSettle();
        expect(find.text(sample().name), findsOneWidget);
        expect(
          find.textContaining('correct-pack · r3 · food-key'),
          findsOneWidget,
        );
        expect(find.text(tText(lang, 'foodPreparationHint')), findsOneWidget);
        expect(find.text(tText(lang, 'foodRevisionHint')), findsOneWidget);
        expect(await db.select(db.entries).get(), isEmpty);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(milliseconds: 200));
        await db.close();
      }
    });
  }
}

String tText(AppLang lang, String key) => t(lang, key);
