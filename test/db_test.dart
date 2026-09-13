import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kcal_log/data/db.dart';
import 'package:kcal_log/logic/calc.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Food> addRice() => db.upsertFood(FoodsCompanion.insert(
        name: '米饭',
        kcal100: 116,
        protein100: const Value(2.6),
        fat100: const Value(0.3),
        carb100: const Value(25.9),
      ));

  test('food + entry roundtrip', () async {
    final rice = await addRice();
    final today = dateKey(DateTime.now());
    await db.addEntry(EntriesCompanion.insert(
      date: today,
      meal: MealType.lunch,
      name: rice.name,
      foodId: Value(rice.id),
      grams: const Value(200),
      kcal: 232,
      protein: const Value(5.2),
      fat: const Value(0.6),
      carb: const Value(51.8),
    ));

    final entries = await db.watchEntries(today).first;
    expect(entries, hasLength(1));
    expect(entries.first.kcal, 232);
    expect(entries.first.meal, MealType.lunch);
    expect(entries.first.foodId, rice.id);
  });

  test('quick add stores kcal-only entry', () async {
    final today = dateKey(DateTime.now());
    await db.addEntry(EntriesCompanion.insert(
      date: today,
      meal: MealType.snack,
      name: '快速添加',
      kcal: 150,
    ));
    final entries = await db.watchEntries(today).first;
    expect(entries.first.foodId, isNull);
    expect(entries.first.grams, isNull);
    expect(entries.first.kcal, 150);
  });

  test('deleting a food keeps entry snapshots', () async {
    final rice = await addRice();
    final today = dateKey(DateTime.now());
    await db.addEntry(EntriesCompanion.insert(
      date: today,
      meal: MealType.dinner,
      name: rice.name,
      foodId: Value(rice.id),
      grams: const Value(100),
      kcal: 116,
    ));
    await db.deleteFood(rice.id);

    expect(await db.foodCount(), 0);
    final entries = await db.watchEntries(today).first;
    expect(entries, hasLength(1));
    expect(entries.first.name, '米饭');
    expect(entries.first.kcal, 116);
    expect(entries.first.foodId, isNull);
  });

  test('template save and apply', () async {
    final rice = await addRice();
    final egg = await db.upsertFood(FoodsCompanion.insert(
      name: '鸡蛋',
      kcal100: 144,
    ));
    final id = await db.saveTemplate('早餐套餐', [(rice.id, 200), (egg.id, 100)]);

    final today = dateKey(DateTime.now());
    final count =
        await db.addEntriesFromTemplate(id, today, MealType.breakfast);
    expect(count, 2);

    final entries = await db.watchEntries(today).first;
    final kcals = entries.map((e) => e.kcal).toSet();
    expect(kcals, containsAll([232.0, 144.0]));
    expect(entries.every((e) => e.meal == MealType.breakfast), isTrue);
  });

  test('water upsert accumulates', () async {
    final today = dateKey(DateTime.now());
    await db.addWater(today, 250);
    await db.addWater(today, 250);
    await db.addWater(today, -100);
    final w = await db.watchWater(today).first;
    expect(w!.ml, 400);
  });

  test('weight upsert by date', () async {
    final today = dateKey(DateTime.now());
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    await db.addWeight(today, 70.5);
    await db.addWeight(today, 70.3);
    await db.addWeight(yesterday, 70.8);
    final list = await db.watchWeights().first;
    expect(list, hasLength(2));
    expect(list.first.date, today);
    expect(list.first.kg, 70.3);
  });

  test('export → import roundtrip into fresh db', () async {
    final rice = await addRice();
    final today = dateKey(DateTime.now());
    await db.addEntry(EntriesCompanion.insert(
      date: today,
      meal: MealType.lunch,
      name: rice.name,
      foodId: Value(rice.id),
      grams: const Value(200),
      kcal: 232,
    ));
    await db.addWater(today, 300);
    await db.addWeight(today, 70.2);
    await db.saveProfile(ProfilesCompanion(
      id: const Value(1),
      kcalGoal: const Value(2000),
      sex: const Value(Sex.male),
    ));
    final templateId = await db.saveTemplate('套餐', [(rice.id, 100)]);

    final json = await db.exportJson();

    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db2.close);
    await db2.importJson(json);

    expect(await db2.foodCount(), 1);
    final entries = await db2.watchEntries(today).first;
    expect(entries, hasLength(1));
    expect(entries.first.foodId, rice.id);
    expect((await db2.watchWater(today).first)!.ml, 300);
    expect((await db2.watchWeights().first).first.kg, 70.2);
    final profile = await db2.watchProfile().first;
    expect(profile!.kcalGoal, 2000);
    expect(profile.sex, Sex.male);
    final applied =
        await db2.addEntriesFromTemplate(templateId, today, MealType.dinner);
    expect(applied, 1);
  });

  test('favorite toggle', () async {
    final rice = await addRice();
    expect(rice.favorite, isFalse);
    await db.toggleFavorite(rice);
    final foods = await db.searchFoods('米饭');
    expect(foods.single.favorite, isTrue);
  });
}
