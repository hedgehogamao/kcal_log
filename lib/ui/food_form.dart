import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../logic/calc.dart';
import '../logic/food_category.dart';
import '../logic/i18n.dart';
import '../logic/providers.dart';
import 'widgets/food_list_item.dart';
import 'widgets/food_category_filter.dart';

double? _p(String s) => double.tryParse(s.trim());

bool _validOptionalNonNegative(TextEditingController controller) {
  final text = controller.text.trim();
  if (text.isEmpty) return true;
  final value = _p(text);
  return value != null && value.isFinite && value >= 0;
}

/// 新建 / 编辑食物
Future<Food?> showFoodForm(
  BuildContext context, {
  Food? existing,
  FoodCategory? initialCategory,
}) {
  return showDialog<Food>(
    context: context,
    builder: (_) =>
        _FoodForm(existing: existing, initialCategory: initialCategory),
  );
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({this.existing, this.initialCategory});
  final Food? existing;
  final FoodCategory? initialCategory;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carb;
  late final TextEditingController _servingDesc;
  late final TextEditingController _servingGrams;
  String? _error;
  FoodCategory _category = FoodCategory.other;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _category = f == null
        ? widget.initialCategory ?? FoodCategory.other
        : FoodCategory.fromCode(f.category);
    _name = TextEditingController(text: f?.name);
    _brand = TextEditingController(text: f?.brand);
    _barcode = TextEditingController(text: f?.barcode);
    _kcal = TextEditingController(
      text: f == null ? '' : round1(f.kcal100).toString(),
    );
    _protein = TextEditingController(
      text: f == null ? '' : round1(f.protein100).toString(),
    );
    _fat = TextEditingController(
      text: f == null ? '' : round1(f.fat100).toString(),
    );
    _carb = TextEditingController(
      text: f == null ? '' : round1(f.carb100).toString(),
    );
    _servingDesc = TextEditingController(text: f?.servingDesc);
    _servingGrams = TextEditingController(
      text: f?.servingGrams == null ? '' : round1(f!.servingGrams!).toString(),
    );
    for (final c in [
      _name,
      _brand,
      _barcode,
      _kcal,
      _protein,
      _fat,
      _carb,
      _servingDesc,
      _servingGrams,
    ]) {
      c.addListener(_clearError);
    }
  }

  void _clearError() {
    if (_error != null && mounted) setState(() => _error = null);
  }

  void _showError(String key) {
    if (mounted) setState(() => _error = tr(context, key));
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _barcode,
      _kcal,
      _protein,
      _fat,
      _carb,
      _servingDesc,
      _servingGrams,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint, isDense: true);

  Widget _numField(TextEditingController c, String label, {String? hint}) =>
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(label, hint: hint),
      );

  Future<void> _save() async {
    final name = _name.text.trim();
    final kcal = _p(_kcal.text);
    if (name.isEmpty || kcal == null || !kcal.isFinite || kcal < 0) {
      _showError('needNameKcal');
      return;
    }
    if (![_protein, _fat, _carb].every(_validOptionalNonNegative)) {
      _showError('invalidNutrition');
      return;
    }
    final grams = _p(_servingGrams.text);
    if (_servingGrams.text.trim().isNotEmpty &&
        (grams == null || !grams.isFinite || grams <= 0)) {
      _showError('invalidServing');
      return;
    }
    final barcode = _barcode.text.trim();
    final db = ref.read(dbProvider);
    if (barcode.isNotEmpty) {
      final matching = await db.foodByBarcode(barcode);
      if (matching != null && matching.id != widget.existing?.id) {
        _showError('barcodeInUse');
        return;
      }
      if (!mounted) return;
    }
    try {
      final saved = await db.upsertFood(
        FoodsCompanion.insert(
          name: name,
          kcal100: kcal,
          id: widget.existing == null
              ? const Value.absent()
              : Value(widget.existing!.id),
          brand: Value(_brand.text.trim().isEmpty ? null : _brand.text.trim()),
          barcode: Value(barcode.isEmpty ? null : barcode),
          category: Value(_category.code),
          protein100: Value(_p(_protein.text) ?? 0),
          fat100: Value(_p(_fat.text) ?? 0),
          carb100: Value(_p(_carb.text) ?? 0),
          servingDesc: Value(
            _servingDesc.text.trim().isEmpty ? null : _servingDesc.text.trim(),
          ),
          servingGrams: Value((grams == null || grams <= 0) ? null : grams),
        ),
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      _showError('saveFail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? tr(context, 'customFood')
            : tr(context, 'editFood'),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _name,
                decoration: _dec(tr(context, 'nameField')),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<FoodCategory>(
                initialValue: _category,
                decoration: _dec(tr(context, 'foodCategory')),
                items: [
                  for (final category in FoodCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label(context)),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? FoodCategory.other),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brand,
                      decoration: _dec(tr(context, 'brand')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _barcode,
                      decoration: _dec(tr(context, 'barcodeField')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _numField(_kcal, tr(context, 'kcal100Field'), hint: 'kcal'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _numField(_protein, tr(context, 'proteinG'))),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(_fat, tr(context, 'fatG'))),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(_carb, tr(context, 'carbG'))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'per100Note'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _servingDesc,
                      decoration: _dec(
                        tr(context, 'servingDesc'),
                        hint: tr(context, 'servingDescHint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numField(
                      _servingGrams,
                      tr(context, 'servingGrams'),
                      hint: tr(context, 'egGrams'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(tr(context, 'save'))),
      ],
    );
  }
}

/// 搜索并选择一个本地食物（供组合餐编辑使用）
Future<Food?> showFoodSearchDialog(BuildContext context) {
  return showDialog<Food>(
    context: context,
    builder: (_) => const _FoodSearch(),
  );
}

class _FoodSearch extends ConsumerStatefulWidget {
  const _FoodSearch();

  @override
  ConsumerState<_FoodSearch> createState() => _FoodSearchState();
}

class _FoodSearchState extends ConsumerState<_FoodSearch> {
  final _search = TextEditingController();
  FoodCategory? _category;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final mq = MediaQuery.of(context);
    final available =
        mq.size.height - mq.viewInsets.bottom - mq.padding.vertical;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.all(16),
      title: Text(tr(context, 'pickFood')),
      scrollable: true,
      // The result viewport contracts when the keyboard appears.
      content: SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr(context, 'searchLibrary'),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: tr(context, 'clearSearch'),
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            FoodCategoryFilter(
              selected: _category,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: (available - 450).clamp(160.0, 420.0),
              child: StreamBuilder<List<Food>>(
                stream: db.watchFoods(
                  _search.text,
                  favoritesOnly: _favoritesOnly,
                ),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: () => setState(() {}),
                        child: Text(tr(context, 'retry')),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!
                      .where(
                        (food) =>
                            _category == null ||
                            food.category == _category!.code,
                      )
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(context, 'foodResultCount', {
                                'n': '${list.length}',
                              }),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            tooltip: tr(context, 'fav'),
                            isSelected: _favoritesOnly,
                            selectedIcon: const Icon(Icons.star_rounded),
                            icon: const Icon(Icons.star_outline_rounded),
                            onPressed: () => setState(
                              () => _favoritesOnly = !_favoritesOnly,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text(tr(context, 'noMatchShort')),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _search.clear();
                                        _category = null;
                                        _favoritesOnly = false;
                                      }),
                                      child: Text(tr(context, 'clearFilters')),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: list.length,
                                itemBuilder: (context, i) => FoodListItem(
                                  food: list[i],
                                  compact: true,
                                  onTap: () => Navigator.pop(context, list[i]),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
      ],
    );
  }
}
