import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../../logic/recipe_portions.dart';

class RecipePortionsPage extends ConsumerStatefulWidget {
  const RecipePortionsPage({super.key});
  @override
  ConsumerState<RecipePortionsPage> createState() => _RecipePortionsPageState();
}

class _RecipePortionsPageState extends ConsumerState<RecipePortionsPage> {
  final _weight = TextEditingController(),
      _portions = TextEditingController(text: '1'),
      _name = TextEditingController();
  int? _template;
  RecipePortions? _preview;
  List<String> _ingredients = [];
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _weight.dispose();
    _portions.dispose();
    _name.dispose();
    super.dispose();
  }

  void _clear(String _) => setState(() => _preview = null);
  Future<void> _calculate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final db = ref.read(dbProvider);
      if (_template == null) throw const FormatException('recipeInvalid');
      final items = await db.itemsOf(_template!);
      final foods = await db.foodsByIds(items.map((i) => i.foodId).toList());
      final ingredients = <(Food, double)>[];
      for (final item in items) {
        final food = foods.where((f) => f.id == item.foodId).firstOrNull;
        if (food == null) throw const FormatException('recipeInvalid');
        ingredients.add((food, item.grams));
      }
      final result = RecipePortions(
        ingredients,
        finishedGrams: double.tryParse(_weight.text) ?? 0,
        portions: double.tryParse(_portions.text) ?? 0,
      );
      if (mounted) {
        setState(() {
          _preview = result;
          _ingredients = [
            for (final (f, g) in ingredients) '${f.name} · ${round1(g)} g',
          ];
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'recipeInvalid'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _preview == null) return;
    final result = _preview!;
    if (_name.text.trim().isEmpty || _name.text.trim().length > 120) {
      setState(() => _error = tr(context, 'recipeInvalid'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(dbProvider)
          .upsertFood(
            FoodsCompanion.insert(
              name: _name.text.trim(),
              source: const Value('custom'),
              category: const Value('dish'),
              kcal100: result.per100[0],
              protein100: Value(result.per100[1]),
              fat100: Value(result.per100[2]),
              carb100: Value(result.per100[3]),
              servingGrams: Value(result.servingGrams),
              servingDesc: Value(
                tr(context, 'recipeServing', {
                  'weight': '${round1(result.finishedGrams)}',
                  'n': '${round1(result.portions)}',
                }),
              ),
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final useKj = ref.watch(settingsProvider).useKj;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'recipeTitle'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: StreamBuilder<List<MealTemplate>>(
            stream: db.watchTemplates(),
            builder: (context, snap) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ExpansionTile(
                  title: Text(tr(context, 'recipeHelpTitle')),
                  children: [Text(tr(context, 'recipeHelp'))],
                ),
                const SizedBox(height: 12),
                if ((snap.data ?? []).isEmpty) Text(tr(context, 'noTemplates')),
                DropdownButtonFormField<int>(
                  key: const ValueKey('recipe-template'),
                  initialValue: _template,
                  isExpanded: true,
                  hint: Text(tr(context, 'recipeChoose')),
                  items: [
                    for (final t in snap.data ?? <MealTemplate>[])
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: _busy
                      ? null
                      : (id) => setState(() {
                          _template = id;
                          _preview = null;
                          _name.text = snap.data!
                              .firstWhere((t) => t.id == id)
                              .name;
                        }),
                ),
                TextField(
                  key: const ValueKey('recipe-name'),
                  controller: _name,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: tr(context, 'recipeName'),
                  ),
                ),
                TextField(
                  key: const ValueKey('recipe-weight'),
                  controller: _weight,
                  enabled: !_busy,
                  onChanged: _clear,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: tr(context, 'recipeWeight'),
                  ),
                ),
                TextField(
                  key: const ValueKey('recipe-count'),
                  controller: _portions,
                  enabled: !_busy,
                  onChanged: _clear,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: tr(context, 'recipeCount'),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('recipe-calculate'),
                  onPressed: _busy ? null : _calculate,
                  child: Text(tr(context, 'recipeCalculate')),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    key: const ValueKey('recipe-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_preview != null) ...[
                  for (final ingredient in _ingredients) Text(ingredient),
                  Text(
                    '${tr(context, 'per100g')}: ${fmtEnergy(_preview!.per100[0], useKj)} ${energyUnit(useKj)}',
                  ),
                  Text(
                    '${tr(context, 'recipePerServing')}: ${round1(_preview!.servingGrams)} g · ${fmtEnergy(_preview!.perPortion[0], useKj)} ${energyUnit(useKj)}',
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (var i = 1; i < 4; i++)
                        Text(
                          '${tr(context, ['', 'proteinShort', 'fatShort', 'carbShort'][i])}: ${round1(_preview!.per100[i])} g / 100 g · ${round1(_preview!.perPortion[i])} g / ${tr(context, 'recipePerServing')}',
                        ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('recipe-save'),
                    onPressed: _busy ? null : _save,
                    child: Text(tr(context, 'recipeSave')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
