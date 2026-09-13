import 'package:drift/drift.dart' show Value;

import 'db.dart';

/// 内置常见食物种子数据（每 100 g；数值为常见估算值，用户可随时编辑）
class SeedFood {
  const SeedFood(this.name, this.kcal, this.protein, this.fat, this.carb,
      {this.servingDesc, this.servingGrams});
  final String name;
  final double kcal, protein, fat, carb;
  final String? servingDesc;
  final double? servingGrams;
}

const _s = SeedFood.new;

final List<SeedFood> kSeedFoods = [
  // 主食
  _s('米饭', 116, 2.6, 0.3, 25.9, servingDesc: '1碗', servingGrams: 200),
  _s('白粥', 46, 1.1, 0.3, 9.9, servingDesc: '1碗', servingGrams: 250),
  _s('馒头', 223, 7.0, 1.1, 47.0, servingDesc: '1个', servingGrams: 100),
  _s('面条(熟)', 110, 3.9, 0.4, 22.8, servingDesc: '1碗', servingGrams: 250),
  _s('米粉(熟)', 109, 1.6, 0.2, 25.0),
  _s('全麦面包', 246, 9.0, 3.4, 45.0, servingDesc: '1片', servingGrams: 35),
  _s('白面包', 280, 8.0, 3.5, 53.0, servingDesc: '1片', servingGrams: 30),
  _s('燕麦片', 367, 15.0, 6.7, 61.0, servingDesc: '1份', servingGrams: 40),
  _s('红薯', 102, 1.1, 0.2, 24.7, servingDesc: '1个', servingGrams: 150),
  _s('土豆', 81, 2.6, 0.2, 17.8),
  _s('玉米', 112, 4.0, 1.2, 22.8, servingDesc: '1根', servingGrams: 200),
  _s('山药', 57, 1.9, 0.2, 12.4),
  _s('芋头', 56, 1.3, 0.2, 12.7),
  _s('饺子(猪肉)', 239, 8.0, 9.0, 30.0, servingDesc: '1个', servingGrams: 25),
  _s('包子(猪肉)', 227, 7.5, 8.5, 30.0, servingDesc: '1个', servingGrams: 80),
  _s('油条', 388, 6.9, 17.6, 51.0, servingDesc: '1根', servingGrams: 60),
  _s('炒饭', 186, 5.5, 6.8, 25.4),
  _s('炒面', 163, 5.0, 5.5, 23.5),
  // 蛋白类
  _s('鸡蛋', 144, 13.3, 8.8, 2.8, servingDesc: '1个', servingGrams: 55),
  _s('鸡胸肉', 133, 24.0, 3.4, 0.6),
  _s('鸡腿(去皮)', 146, 20.0, 7.0, 0.0, servingDesc: '1个', servingGrams: 120),
  _s('鸡翅', 194, 17.4, 11.8, 4.6),
  _s('鸭肉', 240, 15.5, 19.7, 0.2),
  _s('猪里脊', 155, 20.2, 7.9, 0.7),
  _s('五花肉', 568, 7.7, 59.0, 0.9),
  _s('排骨', 278, 16.7, 23.1, 0.7),
  _s('牛肉(瘦)', 125, 22.2, 3.3, 2.4),
  _s('羊肉(肥瘦)', 294, 19.0, 14.1, 0.0),
  _s('火腿肠', 212, 14.0, 10.4, 15.6),
  _s('培根', 541, 37.0, 42.0, 2.0),
  _s('豆腐', 81, 8.1, 3.7, 4.2),
  _s('腐竹', 461, 44.6, 21.7, 22.3),
  _s('毛豆', 131, 13.1, 5.0, 10.5),
  _s('豆浆', 31, 3.0, 1.6, 1.2, servingDesc: '1杯', servingGrams: 250),
  _s('虾', 93, 18.6, 0.8, 2.8),
  _s('三文鱼', 139, 17.2, 7.8, 0.0),
  _s('带鱼', 127, 17.7, 4.9, 3.1),
  _s('鱿鱼', 84, 17.4, 1.6, 0.0),
  // 蔬菜
  _s('西兰花', 36, 4.1, 0.6, 4.3),
  _s('菠菜', 28, 2.6, 0.3, 4.5),
  _s('生菜', 15, 1.3, 0.3, 2.0),
  _s('白菜', 18, 1.5, 0.2, 3.2),
  _s('芹菜', 22, 1.2, 0.2, 4.5),
  _s('韭菜', 26, 2.4, 0.4, 4.6),
  _s('番茄', 20, 0.9, 0.2, 4.0),
  _s('黄瓜', 16, 0.8, 0.2, 2.9),
  _s('茄子', 23, 1.1, 0.2, 4.9),
  _s('胡萝卜', 39, 1.0, 0.2, 8.8),
  _s('冬瓜', 12, 0.4, 0.2, 2.6),
  _s('南瓜', 23, 0.7, 0.1, 5.3),
  _s('莲藕', 47, 1.2, 0.2, 11.5),
  _s('豆芽', 19, 1.7, 0.1, 2.7),
  _s('香菇(鲜)', 26, 2.2, 0.3, 5.2),
  _s('木耳(水发)', 27, 1.5, 0.2, 6.0),
  _s('豌豆', 111, 7.4, 0.3, 21.2),
  // 水果
  _s('苹果', 52, 0.2, 0.2, 13.5, servingDesc: '1个', servingGrams: 200),
  _s('香蕉', 93, 1.4, 0.2, 22.0, servingDesc: '1根', servingGrams: 120),
  _s('橙子', 48, 0.8, 0.2, 11.1, servingDesc: '1个', servingGrams: 180),
  _s('梨', 44, 0.4, 0.2, 11.3),
  _s('葡萄', 45, 0.4, 0.3, 10.3),
  _s('西瓜', 31, 0.5, 0.3, 6.8),
  _s('猕猴桃', 61, 0.8, 0.6, 14.5),
  _s('草莓', 32, 1.0, 0.2, 7.1),
  _s('蓝莓', 57, 0.7, 0.3, 14.5),
  _s('芒果', 60, 0.8, 0.2, 15.0),
  _s('荔枝', 71, 0.9, 0.2, 16.6),
  // 奶制品/其他
  _s('牛奶(全脂)', 65, 3.3, 3.6, 4.9, servingDesc: '1杯', servingGrams: 250),
  _s('牛奶(脱脂)', 34, 3.4, 0.1, 5.0, servingDesc: '1杯', servingGrams: 250),
  _s('酸奶(无糖)', 59, 3.5, 3.3, 4.7, servingDesc: '1杯', servingGrams: 200),
  _s('奶酪', 328, 25.7, 23.5, 3.5),
  _s('坚果(混合)', 600, 18.0, 52.0, 17.0, servingDesc: '1小袋', servingGrams: 25),
  _s('花生', 574, 24.8, 44.3, 21.7),
  _s('核桃', 646, 14.9, 58.8, 19.1),
  _s('黑巧克力', 546, 7.8, 37.0, 47.0),
  _s('薯片', 548, 7.0, 37.6, 47.8),
  _s('冰淇淋', 207, 3.5, 11.0, 24.0),
  _s('白糖', 400, 0, 0, 99.9),
  _s('蜂蜜', 321, 0.4, 1.9, 75.6),
  _s('黄油', 888, 1.4, 98.0, 0.5),
  _s('食用油', 899, 0, 99.9, 0, servingDesc: '1勺', servingGrams: 10),
  _s('蛋黄酱', 680, 1.0, 75.0, 2.0),
  // 饮品/快餐
  _s('可乐', 43, 0, 0, 10.6, servingDesc: '1罐', servingGrams: 330),
  _s('啤酒', 43, 0.5, 0, 3.6, servingDesc: '1罐', servingGrams: 330),
  _s('橙汁', 45, 0.7, 0.2, 10.4, servingDesc: '1杯', servingGrams: 250),
  _s('奶茶', 55, 1.2, 2.0, 8.0, servingDesc: '1杯', servingGrams: 500),
  _s('拿铁咖啡(全脂)', 55, 3.0, 2.9, 4.8, servingDesc: '1杯', servingGrams: 300),
  _s('美式咖啡', 2, 0.1, 0, 0.4, servingDesc: '1杯', servingGrams: 300),
  // 常见菜(估值)
  _s('番茄炒蛋', 87, 4.5, 6.0, 4.5),
  _s('麻婆豆腐', 128, 8.0, 9.0, 4.0),
  _s('宫保鸡丁', 194, 13.0, 12.0, 8.0),
  _s('鱼香肉丝', 148, 9.0, 9.0, 8.0),
  _s('青椒肉丝', 160, 10.0, 11.0, 5.0),
  _s('红烧肉', 478, 12.0, 46.0, 6.0),
  _s('清炒时蔬', 65, 2.0, 5.0, 3.5),
  _s('皮蛋瘦肉粥', 62, 3.0, 1.5, 9.0, servingDesc: '1碗', servingGrams: 300),
];

/// 食物库为空时写入内置种子数据
Future<void> seedIfEmpty(AppDatabase db) async {
  final count = await db.foodCount();
  if (count > 0) return;
  await db.batch((b) {
    b.insertAll(
      db.foods,
      kSeedFoods
          .map((f) => FoodsCompanion.insert(
                name: f.name,
                source: const Value('builtin'),
                kcal100: f.kcal,
                protein100: Value(f.protein),
                fat100: Value(f.fat),
                carb100: Value(f.carb),
                servingDesc: Value(f.servingDesc),
                servingGrams: Value(f.servingGrams),
              ))
          .toList(),
    );
  });
}
