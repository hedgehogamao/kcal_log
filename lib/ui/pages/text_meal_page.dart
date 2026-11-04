import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/local_meal_text.dart';
import '../../logic/food_search.dart';
import '../../logic/providers.dart';

class TextMealPage extends ConsumerStatefulWidget {
  const TextMealPage({super.key, required this.date});
  final String date;
  @override
  ConsumerState<TextMealPage> createState() => _TextMealPageState();
}

class _TextMealPageState extends ConsumerState<TextMealPage> {
  final _input = TextEditingController();
  MealType _meal = currentMealType();
  bool _busy = false;
  String? _error;
  List<(String, double, List<Food>)> _rows = [];
  List<Food?> _selected = [];
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _rows = [];
      _selected = [];
    });
    try {
      final (meal, parts) = parseLocalMealText(_input.text);
      final db = ref.read(dbProvider);
      final rows = <(String, double, List<Food>)>[];
      final selected = <Food?>[];
      for (final (name, grams) in parts) {
        final matches = await db.searchFoods(name, limit: 12);
        rows.add((name, grams, matches));
        final exact = matches
            .where(
              (f) =>
                  normalizeFoodSearchText(f.name) ==
                  normalizeFoodSearchText(name),
            )
            .toList();
        selected.add(exact.length == 1 ? exact.single : null);
      }
      if (mounted) {
        setState(() {
          _meal = meal ?? _meal;
          _rows = rows;
          _selected = selected;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'textMealInvalid'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _selected.isEmpty || _selected.any((f) => f == null)) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(dbProvider);
      await db.transaction(() async {
        for (var i = 0; i < _rows.length; i++) {
          final chosen = _selected[i]!;
          final current = await (db.select(
            db.foods,
          )..where((f) => f.id.equals(chosen.id))).getSingleOrNull();
          if (current == null ||
              current.name != chosen.name ||
              current.kcal100 != chosen.kcal100 ||
              current.protein100 != chosen.protein100 ||
              current.fat100 != chosen.fat100 ||
              current.carb100 != chosen.carb100) {
            throw StateError('changed');
          }
          final factor = _rows[i].$2 / 100;
          final values = [
            chosen.kcal100,
            chosen.protein100,
            chosen.fat100,
            chosen.carb100,
          ].map((n) => n * factor).toList();
          if (values.any((n) => !n.isFinite || n < 0)) {
            throw StateError('invalid');
          }
          await db.addEntry(
            EntriesCompanion.insert(
              date: widget.date,
              meal: _meal,
              name: chosen.name,
              foodId: Value(chosen.id),
              grams: Value(_rows[i].$2),
              kcal: values[0],
              protein: Value(values[1]),
              fat: Value(values[2]),
              carb: Value(values[3]),
            ),
          );
        }
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'textMealChanged'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'textMealTitle'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${widget.date} · ${tr(context, 'textMealHelp')}'),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('text-meal-input'),
                controller: _input,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                onChanged: (_) => setState(() {
                  _rows = [];
                  _selected = [];
                  _error = null;
                }),
                decoration: InputDecoration(
                  hintText: tr(context, 'textMealExample'),
                  border: const OutlineInputBorder(),
                ),
              ),
              FilledButton(
                key: const ValueKey('text-meal-parse'),
                onPressed: _busy ? null : _parse,
                child: Text(tr(context, 'textMealParse')),
              ),
              DropdownButtonFormField<MealType>(
                initialValue: _meal,
                key: ValueKey(_meal),
                isExpanded: true,
                items: [
                  for (final m in MealType.values)
                    DropdownMenuItem(
                      value: m,
                      child: Text(mealLabel(context, m)),
                    ),
                ],
                onChanged: _busy ? null : (m) => setState(() => _meal = m!),
              ),
              if (_error != null)
                Text(
                  _error!,
                  key: const ValueKey('text-meal-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              for (var i = 0; i < _rows.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${_rows[i].$1} · ${round1(_rows[i].$2)} g'),
                        if (_rows[i].$3.isEmpty)
                          Text(tr(context, 'textMealNoMatch'))
                        else
                          DropdownButtonFormField<int>(
                            key: ValueKey('text-meal-choice-$i-${_rows[i].$1}'),
                            initialValue: _selected[i]?.id,
                            isExpanded: true,
                            hint: Text(tr(context, 'textMealChoose')),
                            items: [
                              for (final f in _rows[i].$3)
                                DropdownMenuItem(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (id) => setState(
                                    () => _selected[i] = _rows[i].$3.firstWhere(
                                      (f) => f.id == id,
                                    ),
                                  ),
                          ),
                        if (_selected[i] != null)
                          Text(
                            '${fmtEnergy(_selected[i]!.kcal100 * _rows[i].$2 / 100, settings.useKj)} ${energyUnit(settings.useKj)}',
                          ),
                      ],
                    ),
                  ),
                ),
              if (_rows.isNotEmpty)
                FilledButton(
                  key: const ValueKey('text-meal-confirm'),
                  onPressed: _busy || _selected.any((f) => f == null)
                      ? null
                      : _save,
                  child: Text(
                    tr(context, 'textMealConfirm', {'n': '${_rows.length}'}),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
