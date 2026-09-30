import 'dart:math' as math;

import '../data/db.dart';

const double kcalPerKj = 4.184;

/// Mifflin-St Jeor 基础代谢 × 活动系数 = 每日总消耗估算
double? estimateTdee({
  Sex? sex,
  int? birthYear,
  double? heightCm,
  double? weightKg,
  ActivityLevel activity = ActivityLevel.moderate,
}) {
  if (sex == null ||
      birthYear == null ||
      heightCm == null ||
      weightKg == null) {
    return null;
  }
  if (!heightCm.isFinite ||
      !weightKg.isFinite ||
      heightCm <= 0 ||
      heightCm > 300 ||
      weightKg <= 0 ||
      weightKg > 500) {
    return null;
  }
  final age = DateTime.now().year - birthYear;
  if (age < 10 || age > 100) return null;
  final base = sex == Sex.female
      ? 10 * weightKg + 6.25 * heightCm - 5 * age - 161
      : 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
  const factors = {
    ActivityLevel.sedentary: 1.2,
    ActivityLevel.light: 1.375,
    ActivityLevel.moderate: 1.55,
    ActivityLevel.high: 1.725,
  };
  final result = base * factors[activity]!;
  return result.isFinite && result > 0 ? result : null;
}

/// 默认宏量目标：蛋白质 20% / 脂肪 25% / 碳水 55%
(double proteinG, double fatG, double carbG) defaultMacroGoals(
  double kcalGoal,
) {
  const pPct = 0.20, fPct = 0.25, cPct = 0.55;
  return (
    kcalGoal * pPct / 4, // 蛋白质 4 kcal/g
    kcalGoal * fPct / 9, // 脂肪 9 kcal/g
    kcalGoal * cPct / 4, // 碳水 4 kcal/g
  );
}

double kcalToKj(double kcal) => kcal * kcalPerKj;

double kjToKcal(double kj) => kj / kcalPerKj;

/// 连续记录天数：从今天（或昨天）往前数有记录的日子
int streakDays(Iterable<String> dateKeys, String todayKey) {
  final dates = dateKeys.toSet();
  if (dates.isEmpty) return 0;
  var cursor = DateTime.parse(todayKey);
  if (!dates.contains(_key(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (dates.contains(_key(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 按当前时间推断餐次
MealType currentMealType() {
  final now = DateTime.now();
  final h = now.hour + now.minute / 60;
  if (h < 10.5) return MealType.breakfast;
  if (h < 14.5) return MealType.lunch;
  if (h < 21) return MealType.dinner;
  return MealType.snack;
}

/// 能量数值格式化（kJ 模式自动换算）
String fmtEnergy(double kcal, bool useKj) {
  final v = useKj ? kcalToKj(kcal) : kcal;
  return v.abs() >= 100 ? v.round().toString() : round1(v).toString();
}

String energyUnit(bool useKj) => useKj ? 'kJ' : 'kcal';

String _key(DateTime d) => dateKey(d);

double round1(double v) => (v * 10).round() / 10;

double clamp01(double v) => math.min(1.0, math.max(0.0, v));
