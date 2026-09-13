import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/calc.dart';

void main() {
  group('estimateTdee (Mifflin-St Jeor)', () {
    test('male × moderate', () {
      final year = DateTime.now().year - 30;
      final tdee = estimateTdee(
        sex: Sex.male,
        birthYear: year,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.moderate,
      );
      final bmr = 10 * 70 + 6.25 * 175 - 5 * 30 + 5;
      expect(tdee, closeTo(bmr * 1.55, 0.01));
    });

    test('female × sedentary', () {
      final year = DateTime.now().year - 30;
      final tdee = estimateTdee(
        sex: Sex.female,
        birthYear: year,
        heightCm: 160,
        weightKg: 55,
        activity: ActivityLevel.sedentary,
      );
      final bmr = 10 * 55 + 6.25 * 160 - 5 * 30 - 161;
      expect(tdee, closeTo(bmr * 1.2, 0.01));
    });

    test('missing fields return null', () {
      expect(
        estimateTdee(birthYear: 1990, weightKg: 70),
        isNull,
      );
    });
  });

  test('defaultMacroGoals 2000kcal → 20/25/55%', () {
    final (p, f, c) = defaultMacroGoals(2000);
    expect(p, closeTo(100, 0.01));
    expect(f, closeTo(2000 * 0.25 / 9, 0.01));
    expect(c, closeTo(275, 0.01));
  });

  test('kcal ↔ kJ conversion', () {
    expect(kcalToKj(100), closeTo(418.4, 0.01));
    expect(kjToKcal(kcalToKj(100)), closeTo(100, 0.001));
  });

  test('streakDays', () {
    final now = DateTime.now();
    final today = dateKey(now);
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    expect(streakDays([today, yesterday, '2000-01-01'], today), 2);
    expect(streakDays([yesterday], today), 1);
    expect(streakDays(const [], today), 0);
  });

  test('fmtEnergy respects kJ mode', () {
    expect(fmtEnergy(200, false), '200');
    expect(fmtEnergy(200, true), '837');
  });
}
