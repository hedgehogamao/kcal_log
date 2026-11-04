import '../data/db.dart';

/// Strict local grammar: names plus explicit grams. No AI weight estimation.
(MealType?, List<(String, double)>) parseLocalMealText(String input) {
  if (input.trim().isEmpty || input.length > 1000) {
    throw const FormatException('textMealInvalid');
  }
  var text = input.trim();
  MealType? meal;
  for (final (label, value) in [
    ('早餐', MealType.breakfast),
    ('午餐', MealType.lunch),
    ('晚餐', MealType.dinner),
    ('加餐', MealType.snack),
    ('breakfast', MealType.breakfast),
    ('lunch', MealType.lunch),
    ('dinner', MealType.dinner),
    ('snack', MealType.snack),
    ('desayuno', MealType.breakfast),
    ('almuerzo', MealType.lunch),
    ('cena', MealType.dinner),
  ]) {
    if (text.toLowerCase().startsWith(label) &&
        text.length > label.length &&
        RegExp(r'^[\s:：]').hasMatch(text.substring(label.length))) {
      meal = value;
      text = text.substring(label.length).replaceFirst(RegExp(r'^[\s:：]+'), '');
      break;
    }
  }
  final rows = <(String, double)>[];
  var end = 0;
  final pattern = RegExp(
    r'([^\d]+?)(\d+(?:\.\d+)?)\s*(克|grams?\b|g\b)',
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(text)) {
    if (text
        .substring(end, match.start)
        .replaceAll(RegExp(r'[\s,，、;+；]'), '')
        .isNotEmpty) {
      throw const FormatException('textMealInvalid');
    }
    final name = match[1]!.replaceAll(RegExp(r'^[\s,，、;+；]+|[\s,，、;+；]+$'), '');
    final grams = double.parse(match[2]!);
    if (name.isEmpty ||
        name.endsWith('-') ||
        name.endsWith('.') ||
        !grams.isFinite ||
        grams <= 0 ||
        grams > 100000 ||
        rows.length >= 20) {
      throw const FormatException('textMealInvalid');
    }
    rows.add((name, grams));
    end = match.end;
  }
  if (rows.isEmpty ||
      text.substring(end).replaceAll(RegExp(r'[\s,，、;+；]'), '').isNotEmpty) {
    throw const FormatException('textMealInvalid');
  }
  return (meal, rows);
}
