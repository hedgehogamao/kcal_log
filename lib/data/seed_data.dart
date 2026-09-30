import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';
import '../logic/food_category.dart';

/// 内置常见食物种子数据（每 100 g；数值为常见估算值，用户可随时编辑）
class SeedFood {
  const SeedFood(
    this.name,
    this.kcal,
    this.protein,
    this.fat,
    this.carb, {
    this.servingDesc,
    this.servingGrams,
  });
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
  // 扩充：谷物、面点与薯类（以下均为每 100 g 常见估算值）
  _s('糙米饭', 111, 2.6, 0.9, 23.0),
  _s('杂粮饭', 118, 3.0, 0.8, 24.0),
  _s('紫米饭', 120, 2.8, 0.5, 26.0),
  _s('小米粥', 46, 1.4, 0.7, 8.4, servingDesc: '1碗', servingGrams: 250),
  _s('八宝粥', 80, 2.5, 0.7, 16.0, servingDesc: '1碗', servingGrams: 250),
  _s('绿豆粥', 65, 2.4, 0.3, 13.0),
  _s('荞麦面(熟)', 99, 3.8, 0.1, 21.4),
  _s('乌冬面(熟)', 105, 2.6, 0.4, 21.6),
  _s('意大利面(熟)', 158, 5.8, 0.9, 30.9),
  _s('米线(熟)', 106, 1.8, 0.2, 24.0),
  _s('河粉(熟)', 109, 1.6, 0.2, 25.0),
  _s('年糕', 154, 3.3, 0.6, 34.7),
  _s('吐司', 263, 8.5, 3.6, 49.0, servingDesc: '1片', servingGrams: 30),
  _s('贝果', 257, 10.0, 1.5, 50.0, servingDesc: '1个', servingGrams: 90),
  _s('玉米片', 357, 7.5, 0.4, 84.0),
  _s('藜麦(熟)', 120, 4.4, 1.9, 21.3),
  _s('南瓜粥', 56, 1.1, 0.3, 12.0),
  _s('红豆沙包', 230, 5.5, 1.5, 49.0, servingDesc: '1个', servingGrams: 80),
  _s('烧卖', 210, 7.0, 7.5, 28.0, servingDesc: '1个', servingGrams: 35),
  _s('春卷', 260, 7.0, 12.0, 31.0, servingDesc: '1个', servingGrams: 50),
  _s('紫薯', 82, 1.5, 0.2, 19.0),
  _s('荸荠', 59, 1.2, 0.2, 14.2),
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
  // 扩充：蛋、肉、鱼、豆制品（生熟、部位不同会有差异）
  _s('鸡蛋白', 46, 11.6, 0.1, 0.7),
  _s('鸡蛋黄', 328, 15.2, 28.2, 3.4),
  _s('鹌鹑蛋', 160, 12.8, 11.1, 2.1),
  _s('鸡腿(带皮)', 181, 19.0, 11.0, 0.0),
  _s('鸡胗', 118, 19.2, 2.8, 4.0),
  _s('鸡肝', 121, 16.6, 4.8, 2.8),
  _s('火鸡胸肉', 114, 24.0, 1.2, 0.0),
  _s('猪瘦肉', 143, 20.3, 6.2, 1.5),
  _s('猪肉末(肥瘦)', 270, 17.0, 22.0, 0.0),
  _s('猪肝', 129, 19.3, 3.5, 5.0),
  _s('牛腱子', 130, 21.0, 4.5, 0.5),
  _s('牛排(瘦)', 165, 25.0, 6.0, 0.0),
  _s('牛肉末(瘦)', 176, 21.0, 10.0, 0.0),
  _s('羊肉(瘦)', 118, 20.5, 3.9, 0.2),
  _s('鱼肉(白身)', 90, 19.0, 1.0, 0.0),
  _s('鳕鱼', 88, 20.4, 0.9, 0.0),
  _s('鲈鱼', 105, 18.6, 3.4, 0.0),
  _s('鲫鱼', 108, 17.1, 2.7, 3.8),
  _s('金枪鱼(水浸罐头)', 100, 23.0, 0.8, 0.0),
  _s('沙丁鱼', 208, 24.6, 11.5, 0.0),
  _s('扇贝', 60, 11.0, 0.6, 2.6),
  _s('蛤蜊', 62, 10.1, 1.1, 2.8),
  _s('蟹肉', 95, 19.4, 1.5, 0.0),
  _s('北豆腐', 99, 12.2, 4.8, 1.8),
  _s('嫩豆腐', 55, 5.7, 2.7, 2.0),
  _s('豆腐干', 142, 16.2, 3.6, 11.5),
  _s('豆皮', 250, 24.0, 16.0, 3.0),
  _s('天贝', 193, 20.3, 10.8, 7.6),
  _s('无糖豆浆', 31, 3.0, 1.6, 1.2, servingDesc: '1杯', servingGrams: 250),
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
  // 扩充：常见蔬菜与菌菇
  _s('油麦菜', 15, 1.4, 0.4, 1.9),
  _s('小白菜', 15, 1.5, 0.3, 2.2),
  _s('空心菜', 20, 2.2, 0.3, 3.6),
  _s('菜花', 25, 2.1, 0.2, 4.6),
  _s('芦笋', 22, 2.2, 0.2, 3.9),
  _s('西葫芦', 19, 0.8, 0.2, 3.8),
  _s('苦瓜', 19, 1.0, 0.2, 3.5),
  _s('丝瓜', 20, 1.0, 0.2, 4.2),
  _s('白萝卜', 16, 0.7, 0.1, 3.4),
  _s('青椒', 22, 1.0, 0.2, 4.6),
  _s('红甜椒', 31, 1.0, 0.3, 6.0),
  _s('洋葱', 40, 1.1, 0.1, 9.3),
  _s('大葱', 30, 1.7, 0.3, 6.5),
  _s('蒜薹', 66, 2.1, 0.4, 13.5),
  _s('四季豆', 31, 2.0, 0.2, 6.0),
  _s('荷兰豆', 42, 2.5, 0.2, 7.5),
  _s('秋葵', 33, 1.9, 0.2, 7.5),
  _s('竹笋', 27, 2.6, 0.3, 5.2),
  _s('金针菇', 37, 2.4, 0.4, 7.8),
  _s('口蘑', 28, 2.7, 0.3, 4.5),
  _s('海带(水发)', 13, 1.2, 0.1, 2.4),
  _s('紫菜(干)', 250, 26.7, 1.1, 44.1),
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
  // 扩充：水果（可食部，每 100 g）
  _s('柚子', 42, 0.8, 0.2, 9.5),
  _s('柠檬', 35, 1.1, 0.3, 6.2),
  _s('桃子', 42, 0.9, 0.1, 10.1),
  _s('油桃', 44, 1.1, 0.3, 10.6),
  _s('李子', 46, 0.7, 0.3, 11.4),
  _s('杏', 48, 1.4, 0.4, 11.1),
  _s('樱桃', 63, 1.1, 0.2, 16.0),
  _s('菠萝', 50, 0.5, 0.1, 13.1),
  _s('木瓜', 43, 0.5, 0.3, 10.8),
  _s('火龙果', 55, 1.2, 0.2, 13.3),
  _s('哈密瓜', 34, 0.8, 0.2, 8.2),
  _s('石榴', 83, 1.7, 1.2, 18.7),
  _s('百香果', 97, 2.2, 0.7, 23.4),
  _s('椰子肉', 354, 3.3, 33.5, 15.2),
  _s('鳄梨', 160, 2.0, 14.7, 8.5),
  _s('无花果', 74, 0.8, 0.3, 19.2),
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
  // 扩充：乳制品、坚果、零食
  _s('低脂牛奶', 45, 3.4, 1.5, 5.0, servingDesc: '1杯', servingGrams: 250),
  _s('希腊酸奶(无糖)', 97, 9.0, 5.0, 3.6),
  _s('原味酸奶(含糖)', 85, 3.2, 2.5, 12.0),
  _s('奶粉(全脂)', 496, 25.0, 27.0, 38.0),
  _s('马苏里拉奶酪', 280, 28.0, 17.0, 3.1),
  _s('杏仁', 579, 21.2, 49.9, 21.6),
  _s('腰果', 553, 18.2, 43.8, 30.2),
  _s('开心果', 562, 20.2, 45.3, 27.2),
  _s('葵花籽仁', 584, 20.8, 51.5, 20.0),
  _s('南瓜籽仁', 559, 30.2, 49.1, 10.7),
  _s('葡萄干', 299, 3.1, 0.5, 79.2),
  _s('红枣(干)', 287, 3.7, 1.1, 67.8),
  _s('苏打饼干', 408, 8.0, 9.0, 74.0),
  _s('奥利奥饼干', 480, 5.0, 20.0, 70.0),
  _s('蛋糕(原味)', 350, 5.0, 15.0, 50.0),
  _s('蛋挞', 335, 6.0, 21.0, 31.0, servingDesc: '1个', servingGrams: 55),
  _s('爆米花(原味)', 387, 12.9, 4.5, 77.8),
  // 饮品/快餐
  _s('可乐', 43, 0, 0, 10.6, servingDesc: '1罐', servingGrams: 330),
  _s('啤酒', 43, 0.5, 0, 3.6, servingDesc: '1罐', servingGrams: 330),
  _s('橙汁', 45, 0.7, 0.2, 10.4, servingDesc: '1杯', servingGrams: 250),
  _s('奶茶', 55, 1.2, 2.0, 8.0, servingDesc: '1杯', servingGrams: 500),
  _s('拿铁咖啡(全脂)', 55, 3.0, 2.9, 4.8, servingDesc: '1杯', servingGrams: 300),
  _s('美式咖啡', 2, 0.1, 0, 0.4, servingDesc: '1杯', servingGrams: 300),
  // 扩充：饮品（按 100 g 近似 100 ml；配方差异较大）
  _s('无糖可乐', 0, 0, 0, 0, servingDesc: '1罐', servingGrams: 330),
  _s('绿茶(无糖)', 0, 0, 0, 0, servingDesc: '1杯', servingGrams: 300),
  _s('红茶(无糖)', 1, 0, 0, 0.2, servingDesc: '1杯', servingGrams: 300),
  _s('椰子水', 19, 0.7, 0.2, 3.7, servingDesc: '1瓶', servingGrams: 330),
  _s('苹果汁', 46, 0.1, 0.1, 11.3, servingDesc: '1杯', servingGrams: 250),
  _s('牛奶咖啡(无糖)', 30, 1.6, 1.5, 2.4, servingDesc: '1杯', servingGrams: 300),
  _s('卡布奇诺(全脂)', 50, 2.7, 2.6, 4.0, servingDesc: '1杯', servingGrams: 250),
  _s('豆奶(含糖)', 55, 2.0, 1.5, 8.5, servingDesc: '1杯', servingGrams: 250),
  _s('运动饮料', 25, 0, 0, 6.0, servingDesc: '1瓶', servingGrams: 500),
  _s('红葡萄酒', 85, 0.1, 0, 2.6, servingDesc: '1杯', servingGrams: 150),
  // 常见菜(估值)
  _s('番茄炒蛋', 87, 4.5, 6.0, 4.5),
  _s('麻婆豆腐', 128, 8.0, 9.0, 4.0),
  _s('宫保鸡丁', 194, 13.0, 12.0, 8.0),
  _s('鱼香肉丝', 148, 9.0, 9.0, 8.0),
  _s('青椒肉丝', 160, 10.0, 11.0, 5.0),
  _s('红烧肉', 478, 12.0, 46.0, 6.0),
  _s('清炒时蔬', 65, 2.0, 5.0, 3.5),
  _s('皮蛋瘦肉粥', 62, 3.0, 1.5, 9.0, servingDesc: '1碗', servingGrams: 300),
  // 扩充：家常菜与外食（烹调油、酱汁、份量差异较大）
  _s('清蒸鱼', 110, 19.0, 3.0, 1.0),
  _s('白切鸡', 165, 21.0, 8.0, 0.0),
  _s('水煮鸡胸肉', 151, 29.0, 3.0, 0.0),
  _s('卤牛肉', 170, 26.0, 6.0, 2.0),
  _s('卤鸡蛋', 150, 13.0, 10.0, 3.0, servingDesc: '1个', servingGrams: 55),
  _s('凉拌黄瓜', 48, 1.0, 3.5, 3.5),
  _s('蒜蓉西兰花', 65, 3.5, 4.5, 4.0),
  _s('清炒菠菜', 75, 2.5, 5.5, 4.5),
  _s('干煸四季豆', 160, 3.0, 12.0, 10.0),
  _s('酸辣土豆丝', 130, 2.0, 6.0, 17.0),
  _s('地三鲜', 120, 1.5, 8.0, 11.0),
  _s('西红柿牛腩', 140, 13.0, 8.0, 4.0),
  _s('咖喱鸡', 170, 14.0, 10.0, 6.0),
  _s('糖醋里脊', 260, 13.0, 14.0, 20.0),
  _s('回锅肉', 350, 12.0, 30.0, 7.0),
  _s('肉末茄子', 140, 6.0, 10.0, 7.0),
  _s('虾仁炒蛋', 145, 12.0, 9.0, 3.0),
  _s('蛋炒饭', 185, 5.5, 6.5, 26.0),
  _s('牛肉面', 125, 7.0, 4.0, 16.0, servingDesc: '1碗', servingGrams: 500),
  _s('云吞面', 110, 5.0, 3.0, 16.0, servingDesc: '1碗', servingGrams: 400),
  _s('小笼包', 230, 9.0, 10.0, 26.0, servingDesc: '1个', servingGrams: 25),
  _s('牛肉汉堡', 250, 13.0, 10.0, 27.0, servingDesc: '1个', servingGrams: 180),
  _s('披萨(芝士)', 266, 11.0, 10.0, 33.0, servingDesc: '1片', servingGrams: 100),
  _s('炸薯条', 312, 3.4, 15.0, 41.0),
  _s('炸鸡块', 280, 15.0, 18.0, 15.0),
  _s('三明治(鸡蛋)', 220, 9.0, 9.0, 26.0, servingDesc: '1份', servingGrams: 180),
];

// These boundary names mirror the contiguous sections above. Keeping category
// metadata separate leaves all 237 nutritional records unchanged.
const _categoryStarts = <String, FoodCategory>{
  '米饭': FoodCategory.staple,
  '鸡蛋': FoodCategory.protein,
  '西兰花': FoodCategory.vegetable,
  '苹果': FoodCategory.fruit,
  '牛奶(全脂)': FoodCategory.dairy,
  '坚果(混合)': FoodCategory.snack,
  '低脂牛奶': FoodCategory.dairy,
  '杏仁': FoodCategory.snack,
  '可乐': FoodCategory.drink,
  '番茄炒蛋': FoodCategory.dish,
};

final Map<String, FoodCategory> seedFoodCategories = () {
  var category = FoodCategory.other;
  final result = <String, FoodCategory>{};
  for (final food in kSeedFoods) {
    category = _categoryStarts[food.name] ?? category;
    result[food.name] = category;
  }
  return result;
}();

/// 首次安装写入全部内置食物；版本升级时只补充缺失名称。
/// 不覆盖用户修改过的食物，也不在每次启动时重新添加用户删除的食物。
const _catalogVersion = 2;
const _catalogVersionKey = 'builtinFoodCatalogVersion';

Future<void> seedIfEmpty(AppDatabase db) async {
  final prefs = await SharedPreferences.getInstance();
  await backfillBuiltInFoodCategories(db);
  if ((prefs.getInt(_catalogVersionKey) ?? 0) >= _catalogVersion &&
      await db.foodCount() > 0) {
    return;
  }

  final existingNames = (await db.select(db.foods).get())
      .map((food) => food.name)
      .toSet();
  final missing = kSeedFoods.where(
    (food) => !existingNames.contains(food.name),
  );
  await db.batch((batch) {
    batch.insertAll(
      db.foods,
      missing
          .map(
            (food) => FoodsCompanion.insert(
              name: food.name,
              source: const Value('builtin'),
              category: Value(seedFoodCategories[food.name]!.code),
              kcal100: food.kcal,
              protein100: Value(food.protein),
              fat100: Value(food.fat),
              carb100: Value(food.carb),
              servingDesc: Value(food.servingDesc),
              servingGrams: Value(food.servingGrams),
            ),
          )
          .toList(),
    );
  });
  await prefs.setInt(_catalogVersionKey, _catalogVersion);
}

/// Also run after backup import: old backups do not contain the category field.
/// Explicit "Other" choices, edited names, and user-created foods stay untouched.
Future<void> backfillBuiltInFoodCategories(AppDatabase db) async {
  final builtins = await (db.select(db.foods)
        ..where((f) => f.source.equals('builtin') & f.category.equals('legacy')))
      .get();
  if (builtins.isEmpty) return;
  await db.batch((batch) {
    for (final food in builtins) {
      final category = seedFoodCategories[food.name] ?? FoodCategory.other;
      batch.update(
        db.foods,
        FoodsCompanion(category: Value(category.code)),
        where: (f) => f.id.equals(food.id),
      );
    }
  });
}
