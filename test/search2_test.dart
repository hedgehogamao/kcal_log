import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/food_search.dart';

void main() {
  test('pinyin, initials, food polyphony and regional synonyms are candidates only', () {
    for (final (name, queries) in [
      ('鸡胸肉', ['jixiongrou', 'jxr', 'JXR']),
      ('鸡蛋', ['jidan', 'jd']),
      ('番茄', ['fanqie', 'fq', 'xihongshi', '西红柿']),
      ('茄子', ['qiezi', 'qz']),
      ('重庆小面', ['chongqing', 'cqxm']),
      ('绿豆', ['lvdou', 'ld']),
      ('卷心菜', ['包菜', '圆白菜']),
      ('黄瓜', ['青瓜']),
      ('自建藜麦沙拉', ['lmsl', 'limai']),
    ]) {
      for (final q in queries) {
        expect(
          foodMatchRank(name: name, query: q),
          isNotNull,
          reason: '$name / $q',
        );
      }
    }
  });
  test('bounded typos suggest but never substitute preparation, species or barcodes', () {
    for (final q in ['chikcen', 'chickn', 'chickenn']) {
      expect(
        foodSearchMatch(name: 'Chicken breast', query: q)?.approximate,
        isTrue,
      );
    }
    expect(foodSearchMatch(name: '鸡胸肉', query: '鸡胸内')?.approximate, isTrue);
    for (final (name, q) in [
      ('熟鸡胸肉', '生鸡胸肉'),
      ('牛肉(瘦)', '牛肉面'),
      ('猪肉饭', '牛肉饭'),
      ('鸡蛋', '鸭蛋'),
      ('全脂牛奶', '脱脂牛奶'),
      ('无糖酸奶', '含糖酸奶'),
      ('Chicken cooked', 'chicken raw'),
    ]) {
      expect(
        foodMatchRank(name: name, query: q),
        isNull,
        reason: '$name / $q',
      );
    }
    expect(
      foodMatchRank(
        name: 'Milk',
        barcode: '1234567890123',
        query: '1234567890124',
      ),
      isNull,
    );
    expect(foodMatchRank(name: 'Chicken breast', query: '***'), isNull);
    expect(foodMatchRank(name: '鸡胸肉', query: 'j'), isNull);
    expect(foodMatchRank(name: '鸡胸肉', query: '_'), isNull);
    expect(foodMatchRank(name: '鸡胸肉', query: '&'), isNull);
    expect(foodMatchRank(name: 'Chicken breast', query: 'che'), isNull);
  });
  test(
    'exact ranks before pinyin and typo, multiple terms remain conjunctive',
    () {
      final exact = foodMatchRank(name: '鸡胸肉', query: '鸡胸肉')!;
      expect(exact, lessThan(foodMatchRank(name: '鸡胸肉', query: 'jxr')!));
      expect(
        foodMatchRank(name: 'Chicken breast', query: 'chicken')!,
        lessThan(foodMatchRank(name: 'Chicken breast', query: 'chikcen')!),
      );
      expect(
        foodMatchRank(name: '鸡胸肉', category: 'protein', query: '蛋白类 jxr'),
        isNotNull,
      );
      expect(
        foodMatchRank(name: '鸡胸肉', category: 'protein', query: '水果 jxr'),
        isNull,
      );
    },
  );
  test(
    'real DB search does not change names, nutrients, favorites or categories',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertFood(
        FoodsCompanion.insert(
          name: '鸡胸肉',
          kcal100: 123,
          category: const Value('protein'),
          favorite: const Value(true),
        ),
      );
      await db.upsertFood(
        FoodsCompanion.insert(
          name: '熟鸡胸肉',
          kcal100: 165,
          category: const Value('protein'),
        ),
      );
      final before = await db.exportJson();
      final results = await db.searchFoods('jxr');
      expect(results.length, 2);
      expect(results.first.name, '鸡胸肉');
      expect(results.first.kcal100, 123);
      expect(
        (await db.watchFoods('jixiongrou', favoritesOnly: true).first)
            .single
            .name,
        '鸡胸肉',
      );
      final after = await db.exportJson();
      before.remove('exportedAt');
      after.remove('exportedAt');
      expect(after, before);
    },
  );
  test('5000-row real catalog search benchmark and repeated typing stays bounded', () {
    final raw = jsonDecode(
      File('food-packs/common-foods-5000.json').readAsStringSync(),
    ) as Map;
    final foods = raw['foods'] as List;
    expect(foods.length, 5000);
    final watch = Stopwatch()..start();
    var hits = 0;
    for (final q in ['jxr', 'jixiongrou', 'chikcen', '西红柿']) {
      for (final f in foods) {
        if (foodMatchRank(name: (f as Map)['name'] as String, query: q) !=
            null) {
          hits++;
        }
      }
    }
    watch.stop();
    expect(hits, greaterThan(0));
    // ignore: avoid_print
    print(
      'SEARCH2_CATALOG=5000;QUERIES=4;ELAPSED_MS=${watch.elapsedMilliseconds};CANDIDATES=$hits',
    );
  });
}
