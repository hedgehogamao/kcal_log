// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('custom'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carb100Meta = const VerificationMeta(
    'carb100',
  );
  @override
  late final GeneratedColumn<double> carb100 = GeneratedColumn<double>(
    'carb100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _servingDescMeta = const VerificationMeta(
    'servingDesc',
  );
  @override
  late final GeneratedColumn<String> servingDesc = GeneratedColumn<String>(
    'serving_desc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingGramsMeta = const VerificationMeta(
    'servingGrams',
  );
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
    'serving_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    barcode,
    source,
    category,
    kcal100,
    protein100,
    fat100,
    carb100,
    servingDesc,
    servingGrams,
    favorite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcal100Meta);
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    }
    if (data.containsKey('carb100')) {
      context.handle(
        _carb100Meta,
        carb100.isAcceptableOrUnknown(data['carb100']!, _carb100Meta),
      );
    }
    if (data.containsKey('serving_desc')) {
      context.handle(
        _servingDescMeta,
        servingDesc.isAcceptableOrUnknown(
          data['serving_desc']!,
          _servingDescMeta,
        ),
      );
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
        _servingGramsMeta,
        servingGrams.isAcceptableOrUnknown(
          data['serving_grams']!,
          _servingGramsMeta,
        ),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      )!,
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      )!,
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      )!,
      carb100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb100'],
      )!,
      servingDesc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_desc'],
      ),
      servingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_grams'],
      ),
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }
}

class Food extends DataClass implements Insertable<Food> {
  final int id;
  final String name;
  final String? brand;
  final String? barcode;
  final String source;
  final String category;
  final double kcal100;
  final double protein100;
  final double fat100;
  final double carb100;
  final String? servingDesc;
  final double? servingGrams;
  final bool favorite;
  final DateTime createdAt;
  const Food({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.source,
    required this.category,
    required this.kcal100,
    required this.protein100,
    required this.fat100,
    required this.carb100,
    this.servingDesc,
    this.servingGrams,
    required this.favorite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['source'] = Variable<String>(source);
    map['category'] = Variable<String>(category);
    map['kcal100'] = Variable<double>(kcal100);
    map['protein100'] = Variable<double>(protein100);
    map['fat100'] = Variable<double>(fat100);
    map['carb100'] = Variable<double>(carb100);
    if (!nullToAbsent || servingDesc != null) {
      map['serving_desc'] = Variable<String>(servingDesc);
    }
    if (!nullToAbsent || servingGrams != null) {
      map['serving_grams'] = Variable<double>(servingGrams);
    }
    map['favorite'] = Variable<bool>(favorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      source: Value(source),
      category: Value(category),
      kcal100: Value(kcal100),
      protein100: Value(protein100),
      fat100: Value(fat100),
      carb100: Value(carb100),
      servingDesc: servingDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(servingDesc),
      servingGrams: servingGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(servingGrams),
      favorite: Value(favorite),
      createdAt: Value(createdAt),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      source: serializer.fromJson<String>(json['source']),
      category: serializer.fromJson<String>(json['category']),
      kcal100: serializer.fromJson<double>(json['kcal100']),
      protein100: serializer.fromJson<double>(json['protein100']),
      fat100: serializer.fromJson<double>(json['fat100']),
      carb100: serializer.fromJson<double>(json['carb100']),
      servingDesc: serializer.fromJson<String?>(json['servingDesc']),
      servingGrams: serializer.fromJson<double?>(json['servingGrams']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'barcode': serializer.toJson<String?>(barcode),
      'source': serializer.toJson<String>(source),
      'category': serializer.toJson<String>(category),
      'kcal100': serializer.toJson<double>(kcal100),
      'protein100': serializer.toJson<double>(protein100),
      'fat100': serializer.toJson<double>(fat100),
      'carb100': serializer.toJson<double>(carb100),
      'servingDesc': serializer.toJson<String?>(servingDesc),
      'servingGrams': serializer.toJson<double?>(servingGrams),
      'favorite': serializer.toJson<bool>(favorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Food copyWith({
    int? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    String? source,
    String? category,
    double? kcal100,
    double? protein100,
    double? fat100,
    double? carb100,
    Value<String?> servingDesc = const Value.absent(),
    Value<double?> servingGrams = const Value.absent(),
    bool? favorite,
    DateTime? createdAt,
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    barcode: barcode.present ? barcode.value : this.barcode,
    source: source ?? this.source,
    category: category ?? this.category,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    fat100: fat100 ?? this.fat100,
    carb100: carb100 ?? this.carb100,
    servingDesc: servingDesc.present ? servingDesc.value : this.servingDesc,
    servingGrams: servingGrams.present ? servingGrams.value : this.servingGrams,
    favorite: favorite ?? this.favorite,
    createdAt: createdAt ?? this.createdAt,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      source: data.source.present ? data.source.value : this.source,
      category: data.category.present ? data.category.value : this.category,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      carb100: data.carb100.present ? data.carb100.value : this.carb100,
      servingDesc: data.servingDesc.present
          ? data.servingDesc.value
          : this.servingDesc,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('fat100: $fat100, ')
          ..write('carb100: $carb100, ')
          ..write('servingDesc: $servingDesc, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('favorite: $favorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    barcode,
    source,
    category,
    kcal100,
    protein100,
    fat100,
    carb100,
    servingDesc,
    servingGrams,
    favorite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.barcode == this.barcode &&
          other.source == this.source &&
          other.category == this.category &&
          other.kcal100 == this.kcal100 &&
          other.protein100 == this.protein100 &&
          other.fat100 == this.fat100 &&
          other.carb100 == this.carb100 &&
          other.servingDesc == this.servingDesc &&
          other.servingGrams == this.servingGrams &&
          other.favorite == this.favorite &&
          other.createdAt == this.createdAt);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> barcode;
  final Value<String> source;
  final Value<String> category;
  final Value<double> kcal100;
  final Value<double> protein100;
  final Value<double> fat100;
  final Value<double> carb100;
  final Value<String?> servingDesc;
  final Value<double?> servingGrams;
  final Value<bool> favorite;
  final Value<DateTime> createdAt;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.carb100 = const Value.absent(),
    this.servingDesc = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.favorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
    required double kcal100,
    this.protein100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.carb100 = const Value.absent(),
    this.servingDesc = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.favorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       kcal100 = Value(kcal100);
  static Insertable<Food> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? barcode,
    Expression<String>? source,
    Expression<String>? category,
    Expression<double>? kcal100,
    Expression<double>? protein100,
    Expression<double>? fat100,
    Expression<double>? carb100,
    Expression<String>? servingDesc,
    Expression<double>? servingGrams,
    Expression<bool>? favorite,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (barcode != null) 'barcode': barcode,
      if (source != null) 'source': source,
      if (category != null) 'category': category,
      if (kcal100 != null) 'kcal100': kcal100,
      if (protein100 != null) 'protein100': protein100,
      if (fat100 != null) 'fat100': fat100,
      if (carb100 != null) 'carb100': carb100,
      if (servingDesc != null) 'serving_desc': servingDesc,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (favorite != null) 'favorite': favorite,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? barcode,
    Value<String>? source,
    Value<String>? category,
    Value<double>? kcal100,
    Value<double>? protein100,
    Value<double>? fat100,
    Value<double>? carb100,
    Value<String?>? servingDesc,
    Value<double?>? servingGrams,
    Value<bool>? favorite,
    Value<DateTime>? createdAt,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      source: source ?? this.source,
      category: category ?? this.category,
      kcal100: kcal100 ?? this.kcal100,
      protein100: protein100 ?? this.protein100,
      fat100: fat100 ?? this.fat100,
      carb100: carb100 ?? this.carb100,
      servingDesc: servingDesc ?? this.servingDesc,
      servingGrams: servingGrams ?? this.servingGrams,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (carb100.present) {
      map['carb100'] = Variable<double>(carb100.value);
    }
    if (servingDesc.present) {
      map['serving_desc'] = Variable<String>(servingDesc.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('fat100: $fat100, ')
          ..write('carb100: $carb100, ')
          ..write('servingDesc: $servingDesc, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('favorite: $favorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, int> meal =
      GeneratedColumn<int>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MealType>($EntriesTable.$convertermeal);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbMeta = const VerificationMeta('carb');
  @override
  late final GeneratedColumn<double> carb = GeneratedColumn<double>(
    'carb',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    meal,
    foodId,
    name,
    grams,
    kcal,
    protein,
    fat,
    carb,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    if (data.containsKey('carb')) {
      context.handle(
        _carbMeta,
        carb.isAcceptableOrUnknown(data['carb']!, _carbMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      meal: $EntriesTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal'],
        )!,
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
      carb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermeal =
      const EnumIndexConverter<MealType>(MealType.values);
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final int id;
  final String date;
  final MealType meal;
  final int? foodId;
  final String name;
  final double? grams;
  final double kcal;
  final double protein;
  final double fat;
  final double carb;
  final DateTime createdAt;
  const FoodEntry({
    required this.id,
    required this.date,
    required this.meal,
    this.foodId,
    required this.name,
    this.grams,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    {
      map['meal'] = Variable<int>($EntriesTable.$convertermeal.toSql(meal));
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || grams != null) {
      map['grams'] = Variable<double>(grams);
    }
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['fat'] = Variable<double>(fat);
    map['carb'] = Variable<double>(carb);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      date: Value(date),
      meal: Value(meal),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      name: Value(name),
      grams: grams == null && nullToAbsent
          ? const Value.absent()
          : Value(grams),
      kcal: Value(kcal),
      protein: Value(protein),
      fat: Value(fat),
      carb: Value(carb),
      createdAt: Value(createdAt),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      meal: $EntriesTable.$convertermeal.fromJson(
        serializer.fromJson<int>(json['meal']),
      ),
      foodId: serializer.fromJson<int?>(json['foodId']),
      name: serializer.fromJson<String>(json['name']),
      grams: serializer.fromJson<double?>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      fat: serializer.fromJson<double>(json['fat']),
      carb: serializer.fromJson<double>(json['carb']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'meal': serializer.toJson<int>($EntriesTable.$convertermeal.toJson(meal)),
      'foodId': serializer.toJson<int?>(foodId),
      'name': serializer.toJson<String>(name),
      'grams': serializer.toJson<double?>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'fat': serializer.toJson<double>(fat),
      'carb': serializer.toJson<double>(carb),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FoodEntry copyWith({
    int? id,
    String? date,
    MealType? meal,
    Value<int?> foodId = const Value.absent(),
    String? name,
    Value<double?> grams = const Value.absent(),
    double? kcal,
    double? protein,
    double? fat,
    double? carb,
    DateTime? createdAt,
  }) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    meal: meal ?? this.meal,
    foodId: foodId.present ? foodId.value : this.foodId,
    name: name ?? this.name,
    grams: grams.present ? grams.value : this.grams,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carb: carb ?? this.carb,
    createdAt: createdAt ?? this.createdAt,
  );
  FoodEntry copyWithCompanion(EntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      meal: data.meal.present ? data.meal.value : this.meal,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      name: data.name.present ? data.name.value : this.name,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      fat: data.fat.present ? data.fat.value : this.fat,
      carb: data.carb.present ? data.carb.value : this.carb,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carb: $carb, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    meal,
    foodId,
    name,
    grams,
    kcal,
    protein,
    fat,
    carb,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.meal == this.meal &&
          other.foodId == this.foodId &&
          other.name == this.name &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.fat == this.fat &&
          other.carb == this.carb &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<int> id;
  final Value<String> date;
  final Value<MealType> meal;
  final Value<int?> foodId;
  final Value<String> name;
  final Value<double?> grams;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> fat;
  final Value<double> carb;
  final Value<DateTime> createdAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.meal = const Value.absent(),
    this.foodId = const Value.absent(),
    this.name = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carb = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required MealType meal,
    this.foodId = const Value.absent(),
    required String name,
    this.grams = const Value.absent(),
    required double kcal,
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carb = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       meal = Value(meal),
       name = Value(name),
       kcal = Value(kcal);
  static Insertable<FoodEntry> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? meal,
    Expression<int>? foodId,
    Expression<String>? name,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? fat,
    Expression<double>? carb,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (meal != null) 'meal': meal,
      if (foodId != null) 'food_id': foodId,
      if (name != null) 'name': name,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (carb != null) 'carb': carb,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<MealType>? meal,
    Value<int?>? foodId,
    Value<String>? name,
    Value<double?>? grams,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? fat,
    Value<double>? carb,
    Value<DateTime>? createdAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carb: carb ?? this.carb,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (meal.present) {
      map['meal'] = Variable<int>(
        $EntriesTable.$convertermeal.toSql(meal.value),
      );
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (carb.present) {
      map['carb'] = Variable<double>(carb.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carb: $carb, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Sex?, int> sex =
      GeneratedColumn<int>(
        'sex',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Sex?>($ProfilesTable.$convertersexn);
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, int> activity =
      GeneratedColumn<int>(
        'activity',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(ActivityLevel.moderate.index),
      ).withConverter<ActivityLevel>($ProfilesTable.$converteractivity);
  static const VerificationMeta _kcalGoalMeta = const VerificationMeta(
    'kcalGoal',
  );
  @override
  late final GeneratedColumn<double> kcalGoal = GeneratedColumn<double>(
    'kcal_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGoalMeta = const VerificationMeta(
    'proteinGoal',
  );
  @override
  late final GeneratedColumn<double> proteinGoal = GeneratedColumn<double>(
    'protein_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGoalMeta = const VerificationMeta(
    'fatGoal',
  );
  @override
  late final GeneratedColumn<double> fatGoal = GeneratedColumn<double>(
    'fat_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbGoalMeta = const VerificationMeta(
    'carbGoal',
  );
  @override
  late final GeneratedColumn<double> carbGoal = GeneratedColumn<double>(
    'carb_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    birthYear,
    heightCm,
    weightKg,
    activity,
    kcalGoal,
    proteinGoal,
    fatGoal,
    carbGoal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('kcal_goal')) {
      context.handle(
        _kcalGoalMeta,
        kcalGoal.isAcceptableOrUnknown(data['kcal_goal']!, _kcalGoalMeta),
      );
    }
    if (data.containsKey('protein_goal')) {
      context.handle(
        _proteinGoalMeta,
        proteinGoal.isAcceptableOrUnknown(
          data['protein_goal']!,
          _proteinGoalMeta,
        ),
      );
    }
    if (data.containsKey('fat_goal')) {
      context.handle(
        _fatGoalMeta,
        fatGoal.isAcceptableOrUnknown(data['fat_goal']!, _fatGoalMeta),
      );
    }
    if (data.containsKey('carb_goal')) {
      context.handle(
        _carbGoalMeta,
        carbGoal.isAcceptableOrUnknown(data['carb_goal']!, _carbGoalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sex: $ProfilesTable.$convertersexn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sex'],
        ),
      ),
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      activity: $ProfilesTable.$converteractivity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}activity'],
        )!,
      ),
      kcalGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_goal'],
      ),
      proteinGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_goal'],
      ),
      fatGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_goal'],
      ),
      carbGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_goal'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, int, int> $convertersex =
      const EnumIndexConverter<Sex>(Sex.values);
  static JsonTypeConverter2<Sex?, int?, int?> $convertersexn =
      JsonTypeConverter2.asNullable($convertersex);
  static JsonTypeConverter2<ActivityLevel, int, int> $converteractivity =
      const EnumIndexConverter<ActivityLevel>(ActivityLevel.values);
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final Sex? sex;
  final int? birthYear;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel activity;
  final double? kcalGoal;
  final double? proteinGoal;
  final double? fatGoal;
  final double? carbGoal;
  const Profile({
    required this.id,
    this.sex,
    this.birthYear,
    this.heightCm,
    this.weightKg,
    required this.activity,
    this.kcalGoal,
    this.proteinGoal,
    this.fatGoal,
    this.carbGoal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<int>($ProfilesTable.$convertersexn.toSql(sex));
    }
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    {
      map['activity'] = Variable<int>(
        $ProfilesTable.$converteractivity.toSql(activity),
      );
    }
    if (!nullToAbsent || kcalGoal != null) {
      map['kcal_goal'] = Variable<double>(kcalGoal);
    }
    if (!nullToAbsent || proteinGoal != null) {
      map['protein_goal'] = Variable<double>(proteinGoal);
    }
    if (!nullToAbsent || fatGoal != null) {
      map['fat_goal'] = Variable<double>(fatGoal);
    }
    if (!nullToAbsent || carbGoal != null) {
      map['carb_goal'] = Variable<double>(carbGoal);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      activity: Value(activity),
      kcalGoal: kcalGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(kcalGoal),
      proteinGoal: proteinGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinGoal),
      fatGoal: fatGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(fatGoal),
      carbGoal: carbGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(carbGoal),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      sex: $ProfilesTable.$convertersexn.fromJson(
        serializer.fromJson<int?>(json['sex']),
      ),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      activity: $ProfilesTable.$converteractivity.fromJson(
        serializer.fromJson<int>(json['activity']),
      ),
      kcalGoal: serializer.fromJson<double?>(json['kcalGoal']),
      proteinGoal: serializer.fromJson<double?>(json['proteinGoal']),
      fatGoal: serializer.fromJson<double?>(json['fatGoal']),
      carbGoal: serializer.fromJson<double?>(json['carbGoal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<int?>($ProfilesTable.$convertersexn.toJson(sex)),
      'birthYear': serializer.toJson<int?>(birthYear),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'activity': serializer.toJson<int>(
        $ProfilesTable.$converteractivity.toJson(activity),
      ),
      'kcalGoal': serializer.toJson<double?>(kcalGoal),
      'proteinGoal': serializer.toJson<double?>(proteinGoal),
      'fatGoal': serializer.toJson<double?>(fatGoal),
      'carbGoal': serializer.toJson<double?>(carbGoal),
    };
  }

  Profile copyWith({
    int? id,
    Value<Sex?> sex = const Value.absent(),
    Value<int?> birthYear = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    ActivityLevel? activity,
    Value<double?> kcalGoal = const Value.absent(),
    Value<double?> proteinGoal = const Value.absent(),
    Value<double?> fatGoal = const Value.absent(),
    Value<double?> carbGoal = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    sex: sex.present ? sex.value : this.sex,
    birthYear: birthYear.present ? birthYear.value : this.birthYear,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    activity: activity ?? this.activity,
    kcalGoal: kcalGoal.present ? kcalGoal.value : this.kcalGoal,
    proteinGoal: proteinGoal.present ? proteinGoal.value : this.proteinGoal,
    fatGoal: fatGoal.present ? fatGoal.value : this.fatGoal,
    carbGoal: carbGoal.present ? carbGoal.value : this.carbGoal,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      activity: data.activity.present ? data.activity.value : this.activity,
      kcalGoal: data.kcalGoal.present ? data.kcalGoal.value : this.kcalGoal,
      proteinGoal: data.proteinGoal.present
          ? data.proteinGoal.value
          : this.proteinGoal,
      fatGoal: data.fatGoal.present ? data.fatGoal.value : this.fatGoal,
      carbGoal: data.carbGoal.present ? data.carbGoal.value : this.carbGoal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activity: $activity, ')
          ..write('kcalGoal: $kcalGoal, ')
          ..write('proteinGoal: $proteinGoal, ')
          ..write('fatGoal: $fatGoal, ')
          ..write('carbGoal: $carbGoal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    birthYear,
    heightCm,
    weightKg,
    activity,
    kcalGoal,
    proteinGoal,
    fatGoal,
    carbGoal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.birthYear == this.birthYear &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.activity == this.activity &&
          other.kcalGoal == this.kcalGoal &&
          other.proteinGoal == this.proteinGoal &&
          other.fatGoal == this.fatGoal &&
          other.carbGoal == this.carbGoal);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<Sex?> sex;
  final Value<int?> birthYear;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<ActivityLevel> activity;
  final Value<double?> kcalGoal;
  final Value<double?> proteinGoal;
  final Value<double?> fatGoal;
  final Value<double?> carbGoal;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activity = const Value.absent(),
    this.kcalGoal = const Value.absent(),
    this.proteinGoal = const Value.absent(),
    this.fatGoal = const Value.absent(),
    this.carbGoal = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activity = const Value.absent(),
    this.kcalGoal = const Value.absent(),
    this.proteinGoal = const Value.absent(),
    this.fatGoal = const Value.absent(),
    this.carbGoal = const Value.absent(),
  });
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<int>? sex,
    Expression<int>? birthYear,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<int>? activity,
    Expression<double>? kcalGoal,
    Expression<double>? proteinGoal,
    Expression<double>? fatGoal,
    Expression<double>? carbGoal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birth_year': birthYear,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activity != null) 'activity': activity,
      if (kcalGoal != null) 'kcal_goal': kcalGoal,
      if (proteinGoal != null) 'protein_goal': proteinGoal,
      if (fatGoal != null) 'fat_goal': fatGoal,
      if (carbGoal != null) 'carb_goal': carbGoal,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<Sex?>? sex,
    Value<int?>? birthYear,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<ActivityLevel>? activity,
    Value<double?>? kcalGoal,
    Value<double?>? proteinGoal,
    Value<double?>? fatGoal,
    Value<double?>? carbGoal,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      kcalGoal: kcalGoal ?? this.kcalGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      carbGoal: carbGoal ?? this.carbGoal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<int>(
        $ProfilesTable.$convertersexn.toSql(sex.value),
      );
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (activity.present) {
      map['activity'] = Variable<int>(
        $ProfilesTable.$converteractivity.toSql(activity.value),
      );
    }
    if (kcalGoal.present) {
      map['kcal_goal'] = Variable<double>(kcalGoal.value);
    }
    if (proteinGoal.present) {
      map['protein_goal'] = Variable<double>(proteinGoal.value);
    }
    if (fatGoal.present) {
      map['fat_goal'] = Variable<double>(fatGoal.value);
    }
    if (carbGoal.present) {
      map['carb_goal'] = Variable<double>(carbGoal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activity: $activity, ')
          ..write('kcalGoal: $kcalGoal, ')
          ..write('proteinGoal: $proteinGoal, ')
          ..write('fatGoal: $fatGoal, ')
          ..write('carbGoal: $carbGoal')
          ..write(')'))
        .toString();
  }
}

class $WeightsTable extends Weights with TableInfo<$WeightsTable, WeightRec> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weights';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightRec> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  WeightRec map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightRec(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
    );
  }

  @override
  $WeightsTable createAlias(String alias) {
    return $WeightsTable(attachedDatabase, alias);
  }
}

class WeightRec extends DataClass implements Insertable<WeightRec> {
  final String date;
  final double kg;
  const WeightRec({required this.date, required this.kg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['kg'] = Variable<double>(kg);
    return map;
  }

  WeightsCompanion toCompanion(bool nullToAbsent) {
    return WeightsCompanion(date: Value(date), kg: Value(kg));
  }

  factory WeightRec.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightRec(
      date: serializer.fromJson<String>(json['date']),
      kg: serializer.fromJson<double>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'kg': serializer.toJson<double>(kg),
    };
  }

  WeightRec copyWith({String? date, double? kg}) =>
      WeightRec(date: date ?? this.date, kg: kg ?? this.kg);
  WeightRec copyWithCompanion(WeightsCompanion data) {
    return WeightRec(
      date: data.date.present ? data.date.value : this.date,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightRec(')
          ..write('date: $date, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightRec && other.date == this.date && other.kg == this.kg);
}

class WeightsCompanion extends UpdateCompanion<WeightRec> {
  final Value<String> date;
  final Value<double> kg;
  final Value<int> rowid;
  const WeightsCompanion({
    this.date = const Value.absent(),
    this.kg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightsCompanion.insert({
    required String date,
    required double kg,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       kg = Value(kg);
  static Insertable<WeightRec> custom({
    Expression<String>? date,
    Expression<double>? kg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (kg != null) 'kg': kg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightsCompanion copyWith({
    Value<String>? date,
    Value<double>? kg,
    Value<int>? rowid,
  }) {
    return WeightsCompanion(
      date: date ?? this.date,
      kg: kg ?? this.kg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightsCompanion(')
          ..write('date: $date, ')
          ..write('kg: $kg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatersTable extends Waters with TableInfo<$WatersTable, WaterRec> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [date, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waters';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterRec> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  WaterRec map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterRec(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml'],
      )!,
    );
  }

  @override
  $WatersTable createAlias(String alias) {
    return $WatersTable(attachedDatabase, alias);
  }
}

class WaterRec extends DataClass implements Insertable<WaterRec> {
  final String date;
  final int ml;
  const WaterRec({required this.date, required this.ml});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['ml'] = Variable<int>(ml);
    return map;
  }

  WatersCompanion toCompanion(bool nullToAbsent) {
    return WatersCompanion(date: Value(date), ml: Value(ml));
  }

  factory WaterRec.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterRec(
      date: serializer.fromJson<String>(json['date']),
      ml: serializer.fromJson<int>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'ml': serializer.toJson<int>(ml),
    };
  }

  WaterRec copyWith({String? date, int? ml}) =>
      WaterRec(date: date ?? this.date, ml: ml ?? this.ml);
  WaterRec copyWithCompanion(WatersCompanion data) {
    return WaterRec(
      date: data.date.present ? data.date.value : this.date,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterRec(')
          ..write('date: $date, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterRec && other.date == this.date && other.ml == this.ml);
}

class WatersCompanion extends UpdateCompanion<WaterRec> {
  final Value<String> date;
  final Value<int> ml;
  final Value<int> rowid;
  const WatersCompanion({
    this.date = const Value.absent(),
    this.ml = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatersCompanion.insert({
    required String date,
    this.ml = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<WaterRec> custom({
    Expression<String>? date,
    Expression<int>? ml,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (ml != null) 'ml': ml,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatersCompanion copyWith({
    Value<String>? date,
    Value<int>? ml,
    Value<int>? rowid,
  }) {
    return WatersCompanion(
      date: date ?? this.date,
      ml: ml ?? this.ml,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatersCompanion(')
          ..write('date: $date, ')
          ..write('ml: $ml, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, MealTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class MealTemplate extends DataClass implements Insertable<MealTemplate> {
  final int id;
  final String name;
  const MealTemplate({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(id: Value(id), name: Value(name));
  }

  factory MealTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  MealTemplate copyWith({int? id, String? name}) =>
      MealTemplate(id: id ?? this.id, name: name ?? this.name);
  MealTemplate copyWithCompanion(TemplatesCompanion data) {
    return MealTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplate(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplate && other.id == this.id && other.name == this.name);
}

class TemplatesCompanion extends UpdateCompanion<MealTemplate> {
  final Value<int> id;
  final Value<String> name;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<MealTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TemplatesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TemplatesCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $TemplateItemsTable extends TemplateItems
    with TableInfo<$TemplateItemsTable, TemplateItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, templateId, foodId, grams];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  $TemplateItemsTable createAlias(String alias) {
    return $TemplateItemsTable(attachedDatabase, alias);
  }
}

class TemplateItem extends DataClass implements Insertable<TemplateItem> {
  final int id;
  final int templateId;
  final int foodId;
  final double grams;
  const TemplateItem({
    required this.id,
    required this.templateId,
    required this.foodId,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['food_id'] = Variable<int>(foodId);
    map['grams'] = Variable<double>(grams);
    return map;
  }

  TemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return TemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      foodId: Value(foodId),
      grams: Value(grams),
    );
  }

  factory TemplateItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateItem(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      foodId: serializer.fromJson<int>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'foodId': serializer.toJson<int>(foodId),
      'grams': serializer.toJson<double>(grams),
    };
  }

  TemplateItem copyWith({
    int? id,
    int? templateId,
    int? foodId,
    double? grams,
  }) => TemplateItem(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
  );
  TemplateItem copyWithCompanion(TemplateItemsCompanion data) {
    return TemplateItem(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateItem(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, foodId, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateItem &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.foodId == this.foodId &&
          other.grams == this.grams);
}

class TemplateItemsCompanion extends UpdateCompanion<TemplateItem> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> foodId;
  final Value<double> grams;
  const TemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
  });
  TemplateItemsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required int foodId,
    required double grams,
  }) : templateId = Value(templateId),
       foodId = Value(foodId),
       grams = Value(grams);
  static Insertable<TemplateItem> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? foodId,
    Expression<double>? grams,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
    });
  }

  TemplateItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? foodId,
    Value<double>? grams,
  }) {
    return TemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }
}

class $FoodCatalogsTable extends FoodCatalogs
    with TableInfo<$FoodCatalogsTable, FoodCatalog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packId,
    revision,
    title,
    stateJson,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_catalogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodCatalog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId};
  @override
  FoodCatalog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodCatalog(
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $FoodCatalogsTable createAlias(String alias) {
    return $FoodCatalogsTable(attachedDatabase, alias);
  }
}

class FoodCatalog extends DataClass implements Insertable<FoodCatalog> {
  final String packId;
  final int revision;
  final String title;
  final String stateJson;
  final DateTime appliedAt;
  const FoodCatalog({
    required this.packId,
    required this.revision,
    required this.title,
    required this.stateJson,
    required this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<String>(packId);
    map['revision'] = Variable<int>(revision);
    map['title'] = Variable<String>(title);
    map['state_json'] = Variable<String>(stateJson);
    map['applied_at'] = Variable<DateTime>(appliedAt);
    return map;
  }

  FoodCatalogsCompanion toCompanion(bool nullToAbsent) {
    return FoodCatalogsCompanion(
      packId: Value(packId),
      revision: Value(revision),
      title: Value(title),
      stateJson: Value(stateJson),
      appliedAt: Value(appliedAt),
    );
  }

  factory FoodCatalog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodCatalog(
      packId: serializer.fromJson<String>(json['packId']),
      revision: serializer.fromJson<int>(json['revision']),
      title: serializer.fromJson<String>(json['title']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      appliedAt: serializer.fromJson<DateTime>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<String>(packId),
      'revision': serializer.toJson<int>(revision),
      'title': serializer.toJson<String>(title),
      'stateJson': serializer.toJson<String>(stateJson),
      'appliedAt': serializer.toJson<DateTime>(appliedAt),
    };
  }

  FoodCatalog copyWith({
    String? packId,
    int? revision,
    String? title,
    String? stateJson,
    DateTime? appliedAt,
  }) => FoodCatalog(
    packId: packId ?? this.packId,
    revision: revision ?? this.revision,
    title: title ?? this.title,
    stateJson: stateJson ?? this.stateJson,
    appliedAt: appliedAt ?? this.appliedAt,
  );
  FoodCatalog copyWithCompanion(FoodCatalogsCompanion data) {
    return FoodCatalog(
      packId: data.packId.present ? data.packId.value : this.packId,
      revision: data.revision.present ? data.revision.value : this.revision,
      title: data.title.present ? data.title.value : this.title,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodCatalog(')
          ..write('packId: $packId, ')
          ..write('revision: $revision, ')
          ..write('title: $title, ')
          ..write('stateJson: $stateJson, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(packId, revision, title, stateJson, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodCatalog &&
          other.packId == this.packId &&
          other.revision == this.revision &&
          other.title == this.title &&
          other.stateJson == this.stateJson &&
          other.appliedAt == this.appliedAt);
}

class FoodCatalogsCompanion extends UpdateCompanion<FoodCatalog> {
  final Value<String> packId;
  final Value<int> revision;
  final Value<String> title;
  final Value<String> stateJson;
  final Value<DateTime> appliedAt;
  final Value<int> rowid;
  const FoodCatalogsCompanion({
    this.packId = const Value.absent(),
    this.revision = const Value.absent(),
    this.title = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodCatalogsCompanion.insert({
    required String packId,
    required int revision,
    required String title,
    required String stateJson,
    required DateTime appliedAt,
    this.rowid = const Value.absent(),
  }) : packId = Value(packId),
       revision = Value(revision),
       title = Value(title),
       stateJson = Value(stateJson),
       appliedAt = Value(appliedAt);
  static Insertable<FoodCatalog> custom({
    Expression<String>? packId,
    Expression<int>? revision,
    Expression<String>? title,
    Expression<String>? stateJson,
    Expression<DateTime>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (revision != null) 'revision': revision,
      if (title != null) 'title': title,
      if (stateJson != null) 'state_json': stateJson,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodCatalogsCompanion copyWith({
    Value<String>? packId,
    Value<int>? revision,
    Value<String>? title,
    Value<String>? stateJson,
    Value<DateTime>? appliedAt,
    Value<int>? rowid,
  }) {
    return FoodCatalogsCompanion(
      packId: packId ?? this.packId,
      revision: revision ?? this.revision,
      title: title ?? this.title,
      stateJson: stateJson ?? this.stateJson,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodCatalogsCompanion(')
          ..write('packId: $packId, ')
          ..write('revision: $revision, ')
          ..write('title: $title, ')
          ..write('stateJson: $stateJson, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $WeightsTable weights = $WeightsTable(this);
  late final $WatersTable waters = $WatersTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateItemsTable templateItems = $TemplateItemsTable(this);
  late final $FoodCatalogsTable foodCatalogs = $FoodCatalogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foods,
    entries,
    profiles,
    weights,
    waters,
    templates,
    templateItems,
    foodCatalogs,
  ];
}

typedef $$FoodsTableCreateCompanionBuilder =
    FoodsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<String> source,
      Value<String> category,
      required double kcal100,
      Value<double> protein100,
      Value<double> fat100,
      Value<double> carb100,
      Value<String?> servingDesc,
      Value<double?> servingGrams,
      Value<bool> favorite,
      Value<DateTime> createdAt,
    });
typedef $$FoodsTableUpdateCompanionBuilder =
    FoodsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<String> source,
      Value<String> category,
      Value<double> kcal100,
      Value<double> protein100,
      Value<double> fat100,
      Value<double> carb100,
      Value<String?> servingDesc,
      Value<double?> servingGrams,
      Value<bool> favorite,
      Value<DateTime> createdAt,
    });

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb100 => $composableBuilder(
    column: $table.carb100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingDesc => $composableBuilder(
    column: $table.servingDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb100 => $composableBuilder(
    column: $table.carb100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingDesc => $composableBuilder(
    column: $table.servingDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<double> get carb100 =>
      $composableBuilder(column: $table.carb100, builder: (column) => column);

  GeneratedColumn<String> get servingDesc => $composableBuilder(
    column: $table.servingDesc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
          Food,
          PrefetchHooks Function()
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> kcal100 = const Value.absent(),
                Value<double> protein100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<double> carb100 = const Value.absent(),
                Value<String?> servingDesc = const Value.absent(),
                Value<double?> servingGrams = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                source: source,
                category: category,
                kcal100: kcal100,
                protein100: protein100,
                fat100: fat100,
                carb100: carb100,
                servingDesc: servingDesc,
                servingGrams: servingGrams,
                favorite: favorite,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> category = const Value.absent(),
                required double kcal100,
                Value<double> protein100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<double> carb100 = const Value.absent(),
                Value<String?> servingDesc = const Value.absent(),
                Value<double?> servingGrams = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                source: source,
                category: category,
                kcal100: kcal100,
                protein100: protein100,
                fat100: fat100,
                carb100: carb100,
                servingDesc: servingDesc,
                servingGrams: servingGrams,
                favorite: favorite,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
      Food,
      PrefetchHooks Function()
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required String date,
      required MealType meal,
      Value<int?> foodId,
      required String name,
      Value<double?> grams,
      required double kcal,
      Value<double> protein,
      Value<double> fat,
      Value<double> carb,
      Value<DateTime> createdAt,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<MealType> meal,
      Value<int?> foodId,
      Value<String> name,
      Value<double?> grams,
      Value<double> kcal,
      Value<double> protein,
      Value<double> fat,
      Value<double> carb,
      Value<DateTime> createdAt,
    });

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, int> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, int> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get carb =>
      $composableBuilder(column: $table.carb, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          FoodEntry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (FoodEntry, BaseReferences<_$AppDatabase, $EntriesTable, FoodEntry>),
          FoodEntry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<MealType> meal = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carb = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                date: date,
                meal: meal,
                foodId: foodId,
                name: name,
                grams: grams,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carb: carb,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required MealType meal,
                Value<int?> foodId = const Value.absent(),
                required String name,
                Value<double?> grams = const Value.absent(),
                required double kcal,
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carb = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                date: date,
                meal: meal,
                foodId: foodId,
                name: name,
                grams: grams,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carb: carb,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      FoodEntry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (FoodEntry, BaseReferences<_$AppDatabase, $EntriesTable, FoodEntry>),
      FoodEntry,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<Sex?> sex,
      Value<int?> birthYear,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<ActivityLevel> activity,
      Value<double?> kcalGoal,
      Value<double?> proteinGoal,
      Value<double?> fatGoal,
      Value<double?> carbGoal,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<Sex?> sex,
      Value<int?> birthYear,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<ActivityLevel> activity,
      Value<double?> kcalGoal,
      Value<double?> proteinGoal,
      Value<double?> fatGoal,
      Value<double?> carbGoal,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Sex?, Sex, int> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, int>
  get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get kcalGoal => $composableBuilder(
    column: $table.kcalGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatGoal => $composableBuilder(
    column: $table.fatGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbGoal => $composableBuilder(
    column: $table.carbGoal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcalGoal => $composableBuilder(
    column: $table.kcalGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatGoal => $composableBuilder(
    column: $table.fatGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbGoal => $composableBuilder(
    column: $table.carbGoal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sex?, int> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, int> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<double> get kcalGoal =>
      $composableBuilder(column: $table.kcalGoal, builder: (column) => column);

  GeneratedColumn<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatGoal =>
      $composableBuilder(column: $table.fatGoal, builder: (column) => column);

  GeneratedColumn<double> get carbGoal =>
      $composableBuilder(column: $table.carbGoal, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Sex?> sex = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<ActivityLevel> activity = const Value.absent(),
                Value<double?> kcalGoal = const Value.absent(),
                Value<double?> proteinGoal = const Value.absent(),
                Value<double?> fatGoal = const Value.absent(),
                Value<double?> carbGoal = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                sex: sex,
                birthYear: birthYear,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: activity,
                kcalGoal: kcalGoal,
                proteinGoal: proteinGoal,
                fatGoal: fatGoal,
                carbGoal: carbGoal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Sex?> sex = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<ActivityLevel> activity = const Value.absent(),
                Value<double?> kcalGoal = const Value.absent(),
                Value<double?> proteinGoal = const Value.absent(),
                Value<double?> fatGoal = const Value.absent(),
                Value<double?> carbGoal = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                sex: sex,
                birthYear: birthYear,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: activity,
                kcalGoal: kcalGoal,
                proteinGoal: proteinGoal,
                fatGoal: fatGoal,
                carbGoal: carbGoal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$WeightsTableCreateCompanionBuilder =
    WeightsCompanion Function({
      required String date,
      required double kg,
      Value<int> rowid,
    });
typedef $$WeightsTableUpdateCompanionBuilder =
    WeightsCompanion Function({
      Value<String> date,
      Value<double> kg,
      Value<int> rowid,
    });

class $$WeightsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$WeightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightsTable,
          WeightRec,
          $$WeightsTableFilterComposer,
          $$WeightsTableOrderingComposer,
          $$WeightsTableAnnotationComposer,
          $$WeightsTableCreateCompanionBuilder,
          $$WeightsTableUpdateCompanionBuilder,
          (WeightRec, BaseReferences<_$AppDatabase, $WeightsTable, WeightRec>),
          WeightRec,
          PrefetchHooks Function()
        > {
  $$WeightsTableTableManager(_$AppDatabase db, $WeightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<double> kg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightsCompanion(date: date, kg: kg, rowid: rowid),
          createCompanionCallback:
              ({
                required String date,
                required double kg,
                Value<int> rowid = const Value.absent(),
              }) => WeightsCompanion.insert(date: date, kg: kg, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightsTable,
      WeightRec,
      $$WeightsTableFilterComposer,
      $$WeightsTableOrderingComposer,
      $$WeightsTableAnnotationComposer,
      $$WeightsTableCreateCompanionBuilder,
      $$WeightsTableUpdateCompanionBuilder,
      (WeightRec, BaseReferences<_$AppDatabase, $WeightsTable, WeightRec>),
      WeightRec,
      PrefetchHooks Function()
    >;
typedef $$WatersTableCreateCompanionBuilder =
    WatersCompanion Function({
      required String date,
      Value<int> ml,
      Value<int> rowid,
    });
typedef $$WatersTableUpdateCompanionBuilder =
    WatersCompanion Function({
      Value<String> date,
      Value<int> ml,
      Value<int> rowid,
    });

class $$WatersTableFilterComposer
    extends Composer<_$AppDatabase, $WatersTable> {
  $$WatersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatersTableOrderingComposer
    extends Composer<_$AppDatabase, $WatersTable> {
  $$WatersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatersTable> {
  $$WatersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$WatersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatersTable,
          WaterRec,
          $$WatersTableFilterComposer,
          $$WatersTableOrderingComposer,
          $$WatersTableAnnotationComposer,
          $$WatersTableCreateCompanionBuilder,
          $$WatersTableUpdateCompanionBuilder,
          (WaterRec, BaseReferences<_$AppDatabase, $WatersTable, WaterRec>),
          WaterRec,
          PrefetchHooks Function()
        > {
  $$WatersTableTableManager(_$AppDatabase db, $WatersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> ml = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatersCompanion(date: date, ml: ml, rowid: rowid),
          createCompanionCallback:
              ({
                required String date,
                Value<int> ml = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatersCompanion.insert(date: date, ml: ml, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatersTable,
      WaterRec,
      $$WatersTableFilterComposer,
      $$WatersTableOrderingComposer,
      $$WatersTableAnnotationComposer,
      $$WatersTableCreateCompanionBuilder,
      $$WatersTableUpdateCompanionBuilder,
      (WaterRec, BaseReferences<_$AppDatabase, $WatersTable, WaterRec>),
      WaterRec,
      PrefetchHooks Function()
    >;
typedef $$TemplatesTableCreateCompanionBuilder =
    TemplatesCompanion Function({Value<int> id, required String name});
typedef $$TemplatesTableUpdateCompanionBuilder =
    TemplatesCompanion Function({Value<int> id, Value<String> name});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          MealTemplate,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (
            MealTemplate,
            BaseReferences<_$AppDatabase, $TemplatesTable, MealTemplate>,
          ),
          MealTemplate,
          PrefetchHooks Function()
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TemplatesCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TemplatesCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      MealTemplate,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (
        MealTemplate,
        BaseReferences<_$AppDatabase, $TemplatesTable, MealTemplate>,
      ),
      MealTemplate,
      PrefetchHooks Function()
    >;
typedef $$TemplateItemsTableCreateCompanionBuilder =
    TemplateItemsCompanion Function({
      Value<int> id,
      required int templateId,
      required int foodId,
      required double grams,
    });
typedef $$TemplateItemsTableUpdateCompanionBuilder =
    TemplateItemsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> foodId,
      Value<double> grams,
    });

class $$TemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);
}

class $$TemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateItemsTable,
          TemplateItem,
          $$TemplateItemsTableFilterComposer,
          $$TemplateItemsTableOrderingComposer,
          $$TemplateItemsTableAnnotationComposer,
          $$TemplateItemsTableCreateCompanionBuilder,
          $$TemplateItemsTableUpdateCompanionBuilder,
          (
            TemplateItem,
            BaseReferences<_$AppDatabase, $TemplateItemsTable, TemplateItem>,
          ),
          TemplateItem,
          PrefetchHooks Function()
        > {
  $$TemplateItemsTableTableManager(_$AppDatabase db, $TemplateItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
              }) => TemplateItemsCompanion(
                id: id,
                templateId: templateId,
                foodId: foodId,
                grams: grams,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required int foodId,
                required double grams,
              }) => TemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                foodId: foodId,
                grams: grams,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateItemsTable,
      TemplateItem,
      $$TemplateItemsTableFilterComposer,
      $$TemplateItemsTableOrderingComposer,
      $$TemplateItemsTableAnnotationComposer,
      $$TemplateItemsTableCreateCompanionBuilder,
      $$TemplateItemsTableUpdateCompanionBuilder,
      (
        TemplateItem,
        BaseReferences<_$AppDatabase, $TemplateItemsTable, TemplateItem>,
      ),
      TemplateItem,
      PrefetchHooks Function()
    >;
typedef $$FoodCatalogsTableCreateCompanionBuilder =
    FoodCatalogsCompanion Function({
      required String packId,
      required int revision,
      required String title,
      required String stateJson,
      required DateTime appliedAt,
      Value<int> rowid,
    });
typedef $$FoodCatalogsTableUpdateCompanionBuilder =
    FoodCatalogsCompanion Function({
      Value<String> packId,
      Value<int> revision,
      Value<String> title,
      Value<String> stateJson,
      Value<DateTime> appliedAt,
      Value<int> rowid,
    });

class $$FoodCatalogsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodCatalogsTable> {
  $$FoodCatalogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodCatalogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodCatalogsTable> {
  $$FoodCatalogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packId => $composableBuilder(
    column: $table.packId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodCatalogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodCatalogsTable> {
  $$FoodCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$FoodCatalogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodCatalogsTable,
          FoodCatalog,
          $$FoodCatalogsTableFilterComposer,
          $$FoodCatalogsTableOrderingComposer,
          $$FoodCatalogsTableAnnotationComposer,
          $$FoodCatalogsTableCreateCompanionBuilder,
          $$FoodCatalogsTableUpdateCompanionBuilder,
          (
            FoodCatalog,
            BaseReferences<_$AppDatabase, $FoodCatalogsTable, FoodCatalog>,
          ),
          FoodCatalog,
          PrefetchHooks Function()
        > {
  $$FoodCatalogsTableTableManager(_$AppDatabase db, $FoodCatalogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodCatalogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<DateTime> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodCatalogsCompanion(
                packId: packId,
                revision: revision,
                title: title,
                stateJson: stateJson,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packId,
                required int revision,
                required String title,
                required String stateJson,
                required DateTime appliedAt,
                Value<int> rowid = const Value.absent(),
              }) => FoodCatalogsCompanion.insert(
                packId: packId,
                revision: revision,
                title: title,
                stateJson: stateJson,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodCatalogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodCatalogsTable,
      FoodCatalog,
      $$FoodCatalogsTableFilterComposer,
      $$FoodCatalogsTableOrderingComposer,
      $$FoodCatalogsTableAnnotationComposer,
      $$FoodCatalogsTableCreateCompanionBuilder,
      $$FoodCatalogsTableUpdateCompanionBuilder,
      (
        FoodCatalog,
        BaseReferences<_$AppDatabase, $FoodCatalogsTable, FoodCatalog>,
      ),
      FoodCatalog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$WeightsTableTableManager get weights =>
      $$WeightsTableTableManager(_db, _db.weights);
  $$WatersTableTableManager get waters =>
      $$WatersTableTableManager(_db, _db.waters);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$TemplateItemsTableTableManager get templateItems =>
      $$TemplateItemsTableTableManager(_db, _db.templateItems);
  $$FoodCatalogsTableTableManager get foodCatalogs =>
      $$FoodCatalogsTableTableManager(_db, _db.foodCatalogs);
}
