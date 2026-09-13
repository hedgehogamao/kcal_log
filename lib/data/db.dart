import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

enum MealType { breakfast, lunch, dinner, snack }

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, high }

@DataClassName('Food')
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable().unique()();
  // custom / off / builtin
  TextColumn get source => text().withDefault(const Constant('custom'))();
  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real().withDefault(const Constant(0))();
  RealColumn get fat100 => real().withDefault(const Constant(0))();
  RealColumn get carb100 => real().withDefault(const Constant(0))();
  TextColumn get servingDesc => text().nullable()();
  RealColumn get servingGrams => real().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('FoodEntry')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // yyyy-MM-dd 本地日期
  IntColumn get meal => intEnum<MealType>()();
  IntColumn get foodId => integer().nullable().references(Foods, #id)();
  // 快照：食物名与营养值在记录时固化，改食物库不影响历史
  TextColumn get name => text()();
  RealColumn get grams => real().nullable()();
  RealColumn get kcal => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get carb => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Profile')
class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get sex => intEnum<Sex>().nullable()();
  IntColumn get birthYear => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get activity => intEnum<ActivityLevel>()
      .withDefault(Constant(ActivityLevel.moderate.index))();
  RealColumn get kcalGoal => real().nullable()();
  RealColumn get proteinGoal => real().nullable()();
  RealColumn get fatGoal => real().nullable()();
  RealColumn get carbGoal => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeightRec')
class Weights extends Table {
  TextColumn get date => text()(); // yyyy-MM-dd 主键
  RealColumn get kg => real()();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('WaterRec')
class Waters extends Table {
  TextColumn get date => text()(); // yyyy-MM-dd 主键
  IntColumn get ml => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('MealTemplate')
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DataClassName('TemplateItem')
class TemplateItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(Templates, #id,
      onDelete: KeyAction.cascade)();
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
}

@DriftDatabase(
  tables: [Foods, Entries, Profiles, Weights, Waters, Templates, TemplateItems],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kcallog'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ---------- entries ----------
  Stream<List<FoodEntry>> watchEntries(String date) =>
      (select(entries)..where((e) => e.date.equals(date))).watch();

  Stream<List<FoodEntry>> watchEntriesBetween(String from, String to) =>
      (select(entries)..where((e) =>
              e.date.isBiggerOrEqualValue(from) & e.date.isSmallerOrEqualValue(to)))
          .watch();

  Future<List<FoodEntry>> entriesBetween(String from, String to) =>
      (select(entries)..where((e) =>
              e.date.isBiggerOrEqualValue(from) & e.date.isSmallerOrEqualValue(to)))
          .get();

  Future<List<FoodEntry>> recentEntries({int limit = 120}) =>
      (select(entries)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])..limit(limit))
          .get();

  Future<void> addEntry(EntriesCompanion c) => into(entries).insert(c);

  Future<void> updateEntry(FoodEntry row) => update(entries).replace(row);

  Future<void> deleteEntry(int id) =>
      (delete(entries)..where((e) => e.id.equals(id))).go();

  // ---------- foods ----------
  Stream<List<Food>> watchFoods(String query, {bool favoritesOnly = false}) {
    final q = select(foods);
    final text = query.trim();
    if (text.isNotEmpty) q.where((f) => f.name.like('%$text%'));
    if (favoritesOnly) q.where((f) => f.favorite.equals(true));
    q.orderBy([
      (f) => OrderingTerm.desc(f.favorite),
      (f) => OrderingTerm.desc(f.id),
    ]);
    return q.watch();
  }

  Future<List<Food>> searchFoods(String query, {int limit = 30}) {
    final q = select(foods);
    final text = query.trim();
    if (text.isNotEmpty) q.where((f) => f.name.like('%$text%'));
    q.orderBy([(f) => OrderingTerm.desc(f.favorite), (f) => OrderingTerm.desc(f.id)]);
    q.limit(limit);
    return q.get();
  }

  Future<Food?> foodByBarcode(String code) =>
      (select(foods)..where((f) => f.barcode.equals(code))).getSingleOrNull();

  Future<int> foodCount() => foods.count().getSingle();

  Future<Food> upsertFood(FoodsCompanion c) async {
    final id = await into(foods).insertOnConflictUpdate(c);
    return (select(foods)..where((f) => f.id.equals(id))).getSingle();
  }

  Future<void> toggleFavorite(Food f) =>
      update(foods).replace(f.copyWith(favorite: !f.favorite));

  Future<void> deleteFood(int id) => transaction(() async {
        // 记录里已固化营养快照，只解除关联，不删记录
        await (update(entries)..where((e) => e.foodId.equals(id)))
            .write(const EntriesCompanion(foodId: Value(null)));
        await (delete(templateItems)..where((t) => t.foodId.equals(id))).go();
        await (delete(foods)..where((f) => f.id.equals(id))).go();
      });

  // ---------- profile ----------
  Stream<Profile?> watchProfile() =>
      (select(profiles)..where((p) => p.id.equals(1))).watchSingleOrNull();

  Future<void> saveProfile(ProfilesCompanion c) =>
      into(profiles).insertOnConflictUpdate(c);

  // ---------- weights ----------
  Stream<List<WeightRec>> watchWeights({int limit = 90}) =>
      (select(weights)..orderBy([(w) => OrderingTerm.desc(w.date)])..limit(limit))
          .watch();

  Future<void> addWeight(String date, double kg) =>
      into(weights).insertOnConflictUpdate(WeightsCompanion.insert(date: date, kg: kg));

  // ---------- waters ----------
  Stream<WaterRec?> watchWater(String date) =>
      (select(waters)..where((w) => w.date.equals(date))).watchSingleOrNull();

  Future<void> addWater(String date, int deltaMl) async {
    final row = await (select(waters)..where((w) => w.date.equals(date))).getSingleOrNull();
    final current = row?.ml ?? 0;
    final next = (current + deltaMl).clamp(0, 20000);
    await into(waters).insertOnConflictUpdate(
        WatersCompanion.insert(date: date, ml: Value(next)));
  }

  // ---------- templates ----------
  Stream<List<MealTemplate>> watchTemplates() => select(templates).watch();

  Future<List<MealTemplate>> allTemplates() => select(templates).get();

  Future<List<TemplateItem>> itemsOf(int templateId) =>
      (select(templateItems)..where((t) => t.templateId.equals(templateId))).get();

  Future<List<Food>> foodsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(foods)..where((f) => f.id.isIn(ids))).get();
  }

  Future<int> saveTemplate(String name, List<(int, double)> items) =>
      transaction(() async {
        final id = await into(templates).insert(TemplatesCompanion.insert(name: name));
        for (final (foodId, grams) in items) {
          await into(templateItems).insert(TemplateItemsCompanion.insert(
              templateId: id, foodId: foodId, grams: grams));
        }
        return id;
      });

  Future<void> updateTemplate(int id, String name, List<(int, double)> items) =>
      transaction(() async {
        await (update(templates)..where((t) => t.id.equals(id)))
            .write(TemplatesCompanion(name: Value(name)));
        await (delete(templateItems)..where((t) => t.templateId.equals(id))).go();
        for (final (foodId, grams) in items) {
          await into(templateItems).insert(TemplateItemsCompanion.insert(
              templateId: id, foodId: foodId, grams: grams));
        }
      });

  Future<void> deleteTemplate(int id) async {
    await (delete(templateItems)..where((t) => t.templateId.equals(id))).go();
    await (delete(templates)..where((t) => t.id.equals(id))).go();
  }

  /// 把组合餐按当前日期与餐次写入饮食记录，返回写入条数
  Future<int> addEntriesFromTemplate(int templateId, String date, MealType meal) =>
      transaction(() async {
        final items = await itemsOf(templateId);
        if (items.isEmpty) return 0;
        final foods =
            await foodsByIds(items.map((i) => i.foodId).toList());
        final byId = {for (final f in foods) f.id: f};
        var count = 0;
        for (final it in items) {
          final f = byId[it.foodId];
          if (f == null || it.grams <= 0) continue;
          await addEntry(EntriesCompanion.insert(
            date: date,
            meal: meal,
            name: f.name,
            foodId: Value(f.id),
            grams: Value(it.grams),
            kcal: f.kcal100 * it.grams / 100,
            protein: Value(f.protein100 * it.grams / 100),
            fat: Value(f.fat100 * it.grams / 100),
            carb: Value(f.carb100 * it.grams / 100),
          ));
          count++;
        }
        return count;
      });

  // ---------- export / import ----------
  Future<Map<String, dynamic>> exportJson() async {
    return {
      'schema': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'kcal_log',
      'profile': (await (select(profiles)..where((p) => p.id.equals(1))).getSingleOrNull())
          ?.let(_profileMap),
      'foods': (await select(foods).get()).map(_foodMap).toList(),
      'entries': (await select(entries).get()).map(_entryMap).toList(),
      'weights': (await select(weights).get()).map((w) => {'date': w.date, 'kg': w.kg}).toList(),
      'waters': (await select(waters).get()).map((w) => {'date': w.date, 'ml': w.ml}).toList(),
      'templates': (await select(templates).get())
          .map((t) => {'id': t.id, 'name': t.name})
          .toList(),
      'templateItems': (await select(templateItems).get())
          .map((t) => {'id': t.id, 'templateId': t.templateId, 'foodId': t.foodId, 'grams': t.grams})
          .toList(),
    };
  }

  Future<void> importJson(Map<String, dynamic> json) => transaction(() async {
        await delete(entries).go();
        await delete(templateItems).go();
        await delete(templates).go();
        await delete(waters).go();
        await delete(weights).go();
        await delete(foods).go();
        await delete(profiles).go();

        final p = json['profile'] as Map<String, dynamic>?;
        if (p != null) await into(profiles).insert(_profileFromMap(p));
        await batch((b) {
          b.insertAll(
              foods,
              (json['foods'] as List).map((m) => _foodFromMap(m as Map<String, dynamic>)).toList());
          b.insertAll(
              entries,
              (json['entries'] as List)
                  .map((m) => _entryFromMap(m as Map<String, dynamic>))
                  .toList());
          b.insertAll(
              weights,
              (json['weights'] as List)
                  .map((m) => WeightsCompanion.insert(
                      date: m['date'] as String, kg: _d(m['kg']) ?? 0))
                  .toList());
          b.insertAll(
              waters,
              (json['waters'] as List)
                  .map((m) => WatersCompanion.insert(
                      date: m['date'] as String, ml: Value((m['ml'] as num?)?.toInt() ?? 0)))
                  .toList());
          b.insertAll(
              templates,
              (json['templates'] as List)
                  .map((m) => TemplatesCompanion.insert(
                      id: Value((m['id'] as num).toInt()), name: m['name'] as String))
                  .toList());
          b.insertAll(
              templateItems,
              (json['templateItems'] as List)
                  .map((m) => TemplateItemsCompanion.insert(
                      id: Value((m['id'] as num).toInt()),
                      templateId: (m['templateId'] as num).toInt(),
                      foodId: (m['foodId'] as num).toInt(),
                      grams: _d(m['grams']) ?? 0))
                  .toList());
        });
      });
}

// ---------- JSON 映射 ----------

double? _d(dynamic v) => (v as num?)?.toDouble();

Map<String, dynamic> _foodMap(Food f) => {
      'id': f.id,
      'name': f.name,
      'brand': f.brand,
      'barcode': f.barcode,
      'source': f.source,
      'kcal100': f.kcal100,
      'protein100': f.protein100,
      'fat100': f.fat100,
      'carb100': f.carb100,
      'servingDesc': f.servingDesc,
      'servingGrams': f.servingGrams,
      'favorite': f.favorite,
      'createdAt': f.createdAt.toIso8601String(),
    };

Food _foodFromMap(Map<String, dynamic> m) => Food(
      id: (m['id'] as num).toInt(),
      name: m['name'] as String,
      brand: m['brand'] as String?,
      barcode: m['barcode'] as String?,
      source: (m['source'] as String?) ?? 'custom',
      kcal100: _d(m['kcal100']) ?? 0,
      protein100: _d(m['protein100']) ?? 0,
      fat100: _d(m['fat100']) ?? 0,
      carb100: _d(m['carb100']) ?? 0,
      servingDesc: m['servingDesc'] as String?,
      servingGrams: _d(m['servingGrams']),
      favorite: (m['favorite'] as bool?) ?? false,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );

Map<String, dynamic> _entryMap(FoodEntry e) => {
      'id': e.id,
      'date': e.date,
      'meal': e.meal.index,
      'foodId': e.foodId,
      'name': e.name,
      'grams': e.grams,
      'kcal': e.kcal,
      'protein': e.protein,
      'fat': e.fat,
      'carb': e.carb,
      'createdAt': e.createdAt.toIso8601String(),
    };

FoodEntry _entryFromMap(Map<String, dynamic> m) => FoodEntry(
      id: (m['id'] as num).toInt(),
      date: m['date'] as String,
      meal: MealType.values[((m['meal'] as num?)?.toInt() ?? 0)
          .clamp(0, MealType.values.length - 1)],
      foodId: (m['foodId'] as num?)?.toInt(),
      name: m['name'] as String,
      grams: _d(m['grams']),
      kcal: _d(m['kcal']) ?? 0,
      protein: _d(m['protein']) ?? 0,
      fat: _d(m['fat']) ?? 0,
      carb: _d(m['carb']) ?? 0,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );

Map<String, dynamic> _profileMap(Profile p) => {
      'id': p.id,
      'sex': p.sex?.index,
      'birthYear': p.birthYear,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'activity': p.activity.index,
      'kcalGoal': p.kcalGoal,
      'proteinGoal': p.proteinGoal,
      'fatGoal': p.fatGoal,
      'carbGoal': p.carbGoal,
    };

Profile _profileFromMap(Map<String, dynamic> m) => Profile(
      id: 1,
      sex: (m['sex'] as num?) == null
          ? null
          : Sex.values[((m['sex'] as num).toInt()).clamp(0, Sex.values.length - 1)],
      birthYear: (m['birthYear'] as num?)?.toInt(),
      heightCm: _d(m['heightCm']),
      weightKg: _d(m['weightKg']),
      activity: ActivityLevel
          .values[((m['activity'] as num?)?.toInt() ?? ActivityLevel.moderate.index)
              .clamp(0, ActivityLevel.values.length - 1)],
      kcalGoal: _d(m['kcalGoal']),
      proteinGoal: _d(m['proteinGoal']),
      fatGoal: _d(m['fatGoal']),
      carbGoal: _d(m['carbGoal']),
    );

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

extension MealLabel on MealType {
  String get label => switch (this) {
        MealType.breakfast => '早餐',
        MealType.lunch => '午餐',
        MealType.dinner => '晚餐',
        MealType.snack => '加餐',
      };
}
