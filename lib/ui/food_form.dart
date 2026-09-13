import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../logic/calc.dart';
import '../logic/i18n.dart';
import '../logic/providers.dart';

double? _p(String s) => double.tryParse(s.trim());

/// 新建 / 编辑食物
Future<bool?> showFoodForm(BuildContext context, {Food? existing}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _FoodForm(existing: existing),
  );
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({this.existing});
  final Food? existing;

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

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _name = TextEditingController(text: f?.name);
    _brand = TextEditingController(text: f?.brand);
    _barcode = TextEditingController(text: f?.barcode);
    _kcal = TextEditingController(text: f == null ? '' : round1(f.kcal100).toString());
    _protein = TextEditingController(text: f == null ? '' : round1(f.protein100).toString());
    _fat = TextEditingController(text: f == null ? '' : round1(f.fat100).toString());
    _carb = TextEditingController(text: f == null ? '' : round1(f.carb100).toString());
    _servingDesc = TextEditingController(text: f?.servingDesc);
    _servingGrams = TextEditingController(text: f?.servingGrams == null ? '' : round1(f!.servingGrams!).toString());
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _barcode, _kcal, _protein, _fat, _carb, _servingDesc, _servingGrams]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
      );

  Widget _numField(TextEditingController c, String label, {String? hint}) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(label, hint: hint),
      );

  Future<void> _save() async {
    final name = _name.text.trim();
    final kcal = _p(_kcal.text);
    if (name.isEmpty || kcal == null || kcal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'needNameKcal'))));
      return;
    }
    final grams = _p(_servingGrams.text);
    final barcode = _barcode.text.trim();
    await ref.read(dbProvider).upsertFood(FoodsCompanion.insert(
          name: name,
          kcal100: kcal,
          id: widget.existing == null ? const Value.absent() : Value(widget.existing!.id),
          brand: Value(_brand.text.trim().isEmpty ? null : _brand.text.trim()),
          barcode: Value(barcode.isEmpty ? null : barcode),
          protein100: Value(_p(_protein.text) ?? 0),
          fat100: Value(_p(_fat.text) ?? 0),
          carb100: Value(_p(_carb.text) ?? 0),
          servingDesc: Value(_servingDesc.text.trim().isEmpty ? null : _servingDesc.text.trim()),
          servingGrams: Value((grams == null || grams <= 0) ? null : grams),
        ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? tr(context, 'customFood')
          : tr(context, 'editFood')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _name, decoration: _dec(tr(context, 'nameField'))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: _brand, decoration: _dec(tr(context, 'brand')))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _barcode, decoration: _dec(tr(context, 'barcodeField')))),
              ]),
              const SizedBox(height: 10),
              _numField(_kcal, tr(context, 'kcal100Field'), hint: 'kcal'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _numField(_protein, tr(context, 'proteinG'))),
                const SizedBox(width: 10),
                Expanded(child: _numField(_fat, tr(context, 'fatG'))),
                const SizedBox(width: 10),
                Expanded(child: _numField(_carb, tr(context, 'carbG'))),
              ]),
              const SizedBox(height: 6),
              Text(tr(context, 'per100Note'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: _servingDesc, decoration: _dec(tr(context, 'servingDesc'), hint: tr(context, 'servingDescHint')))),
                const SizedBox(width: 10),
                Expanded(child: _numField(_servingGrams, tr(context, 'servingGrams'), hint: tr(context, 'egGrams'))),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel'))),
        FilledButton(onPressed: _save, child: Text(tr(context, 'save'))),
      ],
    );
  }
}

/// 搜索并选择一个本地食物（供组合餐编辑使用）
Future<Food?> showFoodSearchDialog(BuildContext context) {
  return showDialog<Food>(context: context, builder: (_) => const _FoodSearch());
}

class _FoodSearch extends ConsumerStatefulWidget {
  const _FoodSearch();

  @override
  ConsumerState<_FoodSearch> createState() => _FoodSearchState();
}

class _FoodSearchState extends ConsumerState<_FoodSearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return AlertDialog(
      title: Text(tr(context, 'pickFood')),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr(context, 'searchLibrary'),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Food>>(
                stream: db.watchFoods(_query),
                builder: (context, snap) {
                  final list = snap.data ?? const <Food>[];
                  if (list.isEmpty) {
                    return Center(child: Text(tr(context, 'noMatchShort')));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final f = list[i];
                      return ListTile(
                        dense: true,
                        title: Text(f.name),
                        subtitle: Text(
                            '${tr(context, 'per100g')} ${round1(f.kcal100)} kcal'),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
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
            child: Text(tr(context, 'cancel'))),
      ],
    );
  }
}
