import 'dart:convert';

import 'package:drift/drift.dart';

import '../logic/food_category.dart';
import 'db.dart';
import 'seed_data.dart';

const foodPackMaxBytes = 5 * 1024 * 1024;
const foodPackMaxFoods = 10000;

class FoodPackException implements Exception {
  const FoodPackException(this.code);
  final String code;
  @override
  String toString() => 'FoodPackException($code)';
}

String _text(dynamic v, int max) {
  if (v is! String || v.trim().isEmpty || v != v.trim() || v.length > max) {
    throw const FoodPackException('packInvalid');
  }
  return v;
}

double _number(dynamic value, double maximum, {bool positive = false}) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value > maximum ||
      (positive && value == 0)) {
    throw const FoodPackException('packInvalid');
  }
  return value.toDouble();
}

String _nameKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class PackedFood {
  PackedFood._(this.key, Map<String, dynamic> fields)
    : fields = Map.unmodifiable(fields);
  final String key;
  final Map<String, dynamic> fields;
  String get name => fields['name'] as String;

  static PackedFood parse(dynamic raw) {
    if (raw is! Map<String, dynamic> ||
        raw.keys.any(
          (k) => !{
            'id',
            'name',
            'category',
            'kcal100',
            'protein100',
            'fat100',
            'carb100',
            'brand',
            'servingDesc',
            'servingGrams',
          }.contains(k),
        )) {
      throw const FoodPackException('packInvalid');
    }
    final key = _text(raw['id'], 120);
    final category = _text(raw['category'], 32);
    if (!FoodCategory.values.any((c) => c.code == category)) {
      throw const FoodPackException('packInvalid');
    }
    final desc = raw['servingDesc'] == null
        ? null
        : _text(raw['servingDesc'], 120);
    final grams = raw['servingGrams'] == null
        ? null
        : _number(raw['servingGrams'], 100000, positive: true);
    if ((desc == null) != (grams == null)) {
      throw const FoodPackException('packInvalid');
    }
    return PackedFood._(key, {
      'name': _text(raw['name'], 120),
      'category': category,
      'kcal100': _number(raw['kcal100'], 900),
      'protein100': _number(raw['protein100'], 100),
      'fat100': _number(raw['fat100'], 100),
      'carb100': _number(raw['carb100'], 100),
      'brand': raw['brand'] == null ? null : _text(raw['brand'], 120),
      'barcode': null,
      'source': 'pack',
      'servingDesc': desc,
      'servingGrams': grams,
    });
  }

  FoodsCompanion companion({int? id}) => FoodsCompanion.insert(
    id: id == null ? const Value.absent() : Value(id),
    name: name,
    source: const Value('pack'),
    category: Value(fields['category'] as String),
    kcal100: fields['kcal100'] as double,
    protein100: Value(fields['protein100'] as double),
    fat100: Value(fields['fat100'] as double),
    carb100: Value(fields['carb100'] as double),
    brand: Value(fields['brand'] as String?),
    servingDesc: Value(fields['servingDesc'] as String?),
    servingGrams: Value(fields['servingGrams'] as double?),
  );

  Map<String, dynamic> toJson() => {
    'id': key,
    for (final entry in fields.entries)
      if (entry.key != 'source' && entry.key != 'barcode')
        entry.key: entry.value,
  };
}

class FoodPack {
  FoodPack._(this.id, this.revision, this.title, List<PackedFood> foods)
    : foods = List.unmodifiable(foods);
  final String id, title;
  final int revision;
  final List<PackedFood> foods;

  static FoodPack decode(Uint8List bytes) {
    if (bytes.length > foodPackMaxBytes) {
      throw const FoodPackException('packTooLarge');
    }
    try {
      return parse(jsonDecode(utf8.decode(bytes)));
    } on FoodPackException {
      rethrow;
    } catch (_) {
      throw const FoodPackException('packInvalid');
    }
  }

  static FoodPack parse(dynamic raw) {
    if (raw is! Map<String, dynamic> ||
        raw['app'] != 'kcal_log.food_pack' ||
        raw['schema'] != 1 ||
        raw.keys.any(
          (k) => !{
            'app',
            'schema',
            'packId',
            'revision',
            'title',
            'foods',
          }.contains(k),
        )) {
      throw const FoodPackException('packInvalid');
    }
    final id = _text(raw['packId'], 80);
    final revision = raw['revision'];
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(id) ||
        revision is! int ||
        revision < 1 ||
        revision > 2147483647 ||
        raw['foods'] is! List ||
        (raw['foods'] as List).isEmpty ||
        (raw['foods'] as List).length > foodPackMaxFoods) {
      throw const FoodPackException('packInvalid');
    }
    final foods = (raw['foods'] as List).map(PackedFood.parse).toList();
    if (foods.map((f) => f.key).toSet().length != foods.length ||
        foods.map((f) => _nameKey(f.name)).toSet().length != foods.length) {
      throw const FoodPackException('packInvalid');
    }
    return FoodPack._(id, revision, _text(raw['title'], 120), foods);
  }

  Map<String, dynamic> toJson() => {
    'app': 'kcal_log.food_pack',
    'schema': 1,
    'packId': id,
    'revision': revision,
    'title': title,
    'foods': foods.map((f) => f.toJson()).toList(),
  };

  // Canonical sorted stable IDs make reordering JSON irrelevant to identity.
  String get fingerprint {
    final sorted = [...foods]..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      ...toJson(),
      'foods': sorted.map((f) => f.toJson()).toList(),
    });
  }
}

Map<String, dynamic> _snapshot(Food food) => {
  'name': food.name,
  'category': food.category,
  'kcal100': food.kcal100,
  'protein100': food.protein100,
  'fat100': food.fat100,
  'carb100': food.carb100,
  'brand': food.brand,
  'barcode': food.barcode,
  'source': food.source,
  'servingDesc': food.servingDesc,
  'servingGrams': food.servingGrams,
};

bool _equal(Map<String, dynamic> a, Map<String, dynamic> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

bool _pristineBuiltin(Food row) {
  if (row.source != 'builtin') return false;
  final seed = kSeedFoods.where((f) => f.name == row.name).firstOrNull;
  if (seed == null) return false;
  return _equal(_snapshot(row), {
    'name': seed.name,
    'category': seedFoodCategories[seed.name]!.code,
    'kcal100': seed.kcal,
    'protein100': seed.protein,
    'fat100': seed.fat,
    'carb100': seed.carb,
    'brand': null,
    'barcode': null,
    'source': 'builtin',
    'servingDesc': seed.servingDesc,
    'servingGrams': seed.servingGrams,
  });
}

class FoodPackPlan {
  FoodPackPlan(
    this.pack,
    this.added,
    this.updated,
    this.protected,
    this.unchanged,
    this.current,
    this._items,
    this._writes,
  );
  final FoodPack pack;
  final int added, updated, protected, unchanged;
  final bool current;
  final Map<String, dynamic> _items;
  final List<(PackedFood, int?)> _writes;
}

class FoodPackLoader {
  FoodPackLoader(this.db);
  final AppDatabase db;

  Future<FoodPackPlan> preview(FoodPack pack) => _plan(pack);

  Future<FoodPackPlan> _plan(FoodPack pack) async {
    final installed = await (db.select(
      db.foodCatalogs,
    )..where((p) => p.packId.equals(pack.id))).getSingleOrNull();
    Map<String, dynamic> state = {};
    if (installed != null) {
      if (pack.revision < installed.revision) {
        throw const FoodPackException('packOlder');
      }
      try {
        state = jsonDecode(installed.stateJson) as Map<String, dynamic>;
      } catch (_) {
        throw const FoodPackException('packStateInvalid');
      }
      if (pack.revision == installed.revision) {
        if (state['fingerprint'] != pack.fingerprint) {
          throw const FoodPackException('packRevisionChanged');
        }
        return FoodPackPlan(pack, 0, 0, 0, pack.foods.length, true, {}, []);
      }
    }
    final items = Map<String, dynamic>.from((state['items'] ?? {}) as Map);
    final rows = await db.select(db.foods).get();
    final byId = {for (final f in rows) f.id: f};
    final byName = <String, List<Food>>{};
    for (final f in rows) {
      (byName[_nameKey(f.name)] ??= []).add(f);
    }
    var added = 0, updated = 0, protected = 0, unchanged = 0;
    final writes = <(PackedFood, int?)>[];
    for (final food in pack.foods) {
      final previous = items[food.key] as Map?;
      Food? row;
      if (previous != null) {
        row = byId[previous['foodId']];
        if (previous['blocked'] == true ||
            row == null ||
            previous['snapshot'] is! Map ||
            !_equal(
              _snapshot(row),
              Map<String, dynamic>.from(previous['snapshot'] as Map),
            )) {
          items[food.key] = {...previous, 'blocked': true};
          protected++;
          continue;
        }
        final matches = byName[_nameKey(food.name)] ?? [];
        if (matches.any((f) => f.id != row!.id)) {
          protected++;
          continue;
        }
      } else {
        final matches = byName[_nameKey(food.name)] ?? [];
        if (matches.isNotEmpty) {
          if (matches.length != 1 || !_pristineBuiltin(matches.single)) {
            items[food.key] = {'blocked': true};
            protected++;
            continue;
          }
          row = matches.single;
        }
      }
      if (row == null) {
        added++;
        writes.add((food, null));
      } else if (!_equal(_snapshot(row), food.fields)) {
        updated++;
        writes.add((food, row.id));
      } else {
        unchanged++;
      }
      items[food.key] = {
        'foodId': row?.id,
        'snapshot': food.fields,
        'blocked': false,
      };
    }
    return FoodPackPlan(
      pack,
      added,
      updated,
      protected,
      unchanged,
      false,
      items,
      writes,
    );
  }

  Future<FoodPackPlan> apply(FoodPack pack) => db.transaction(() async {
    // Re-check in the write transaction: edits after preview are protected too.
    final plan = await _plan(pack);
    if (plan.current) return plan;
    for (final (food, id) in plan._writes) {
      final row = await db.upsertFood(food.companion(id: id));
      plan._items[food.key] = {
        'foodId': row.id,
        'snapshot': _snapshot(row),
        'blocked': false,
      };
    }
    await db
        .into(db.foodCatalogs)
        .insertOnConflictUpdate(
          FoodCatalogsCompanion.insert(
            packId: pack.id,
            revision: pack.revision,
            title: pack.title,
            stateJson: jsonEncode({
              'fingerprint': pack.fingerprint,
              'items': plan._items,
            }),
            appliedAt: DateTime.now(),
          ),
        );
    return plan;
  });
}
