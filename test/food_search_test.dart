import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/food_search.dart';

void main() {
  test('同义词、大小写和空格分词均能命中', () {
    expect(foodMatchRank(name: '番茄炒蛋', query: '西红柿'), isNotNull);
    expect(foodMatchRank(name: '西红柿牛腩', query: '番茄 牛腩'), isNotNull);
    expect(foodMatchRank(name: '土豆丝', query: '马铃薯'), isNotNull);
    expect(foodMatchRank(name: '红薯', query: '地瓜'), 0);
    expect(foodMatchRank(name: '鸡胸肉', query: '鸡脯'), isNotNull);
    expect(foodMatchRank(name: '牛肉面', query: '牛肉 饭'), isNull);
    expect(
      foodMatchRank(name: 'Oat Milk', brand: 'OATLY', query: 'oatly'),
      isNotNull,
    );
  });

  test('分类词可与食物名称组合搜索，其他分类不会误命中', () {
    expect(
      foodMatchRank(name: '苹果', category: 'fruit', query: '水果 苹果'),
      isNotNull,
    );
    expect(
      foodMatchRank(name: '苹果', category: 'fruit', query: 'fruit 苹果'),
      isNotNull,
    );
    expect(
      foodMatchRank(name: '苹果', category: 'fruit', query: 'frutas 苹果'),
      isNotNull,
    );
    expect(
      foodMatchRank(
        name: '燕麦片',
        category: 'staple',
        query: 'Grains & starches',
      ),
      5,
    );
    expect(foodMatchRank(name: '苹果', category: 'protein', query: '水果'), isNull);
    expect(foodMatchRank(name: '苹果', category: 'fruit', query: '蔬菜'), isNull);
    expect(foodMatchRank(name: '水果', category: 'fruit', query: '水果'), 0);
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('精准名称优先、可按品牌条码查找，% 不再成为通配符', () async {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '番茄炒蛋',
        kcal100: 87,
        source: const Value('builtin'),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '番茄',
        kcal100: 20,
        source: const Value('builtin'),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '燕麦饮',
        kcal100: 45,
        brand: const Value('OATLY'),
        barcode: const Value('1234567890123'),
      ),
    );

    expect((await db.searchFoods('西红柿')).first.name, '番茄');
    expect((await db.searchFoods('西红柿', limit: 1)).single.name, '番茄');
    expect((await db.searchFoods('oatly')).single.name, '燕麦饮');
    expect((await db.searchFoods('1234567890123')).single.name, '燕麦饮');
    expect(await db.searchFoods('%'), isEmpty);
    expect(await db.searchFoods('_'), isEmpty);
    expect(await db.searchFoods('燕麦 不存在'), isEmpty);
  });

  test('默认先收藏和自定义，收藏筛选随数据库变更更新', () async {
    final builtIn = await db.upsertFood(
      FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        source: const Value('builtin'),
      ),
    );
    final custom = await db.upsertFood(
      FoodsCompanion.insert(name: '我的早餐', kcal100: 200),
    );
    expect((await db.searchFoods('')).map((f) => f.name), ['我的早餐', '米饭']);
    await db.toggleFavorite(builtIn);
    expect((await db.searchFoods('')).first.name, '米饭');
    expect(
      (await db.watchFoods('', favoritesOnly: true).first).single.name,
      '米饭',
    );
    expect(custom.favorite, isFalse);
  });

  test('数据库搜索分类词只返回相应类别', () async {
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '苹果',
        kcal100: 52,
        category: const Value('fruit'),
      ),
    );
    await db.upsertFood(
      FoodsCompanion.insert(
        name: '西兰花',
        kcal100: 36,
        category: const Value('vegetable'),
      ),
    );
    expect((await db.searchFoods('水果')).map((f) => f.name), ['苹果']);
    expect((await db.searchFoods('frutas 苹果')).single.name, '苹果');
    expect(await db.searchFoods('水果 西兰花'), isEmpty);
  });
}
