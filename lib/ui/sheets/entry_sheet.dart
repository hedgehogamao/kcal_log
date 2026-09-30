import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../theme.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/smart_field.dart';

Future<void> showEntrySheet(
  BuildContext context, {
  required String date,
  MealType? meal,
  Food? food,
  FoodEntry? entry,
}) {
  assert(food != null || entry != null);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        EntrySheet(date: date, meal: meal, food: food, entry: entry),
  );
}

/// Preview a single meal record before committing its nutrition snapshot.
class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({
    super.key,
    required this.date,
    this.meal,
    this.food,
    this.entry,
  });
  final String date;
  final MealType? meal;
  final Food? food;
  final FoodEntry? entry;

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  late MealType _meal;
  late final TextEditingController _gramsCtrl;
  late final TextEditingController _kcalCtrl;
  late final String _initialEnergyText;
  late final bool _inputUseKj;
  bool _saving = false;
  String? _error;

  bool get _kcalMode => widget.food == null && widget.entry?.foodId == null;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal ?? widget.entry?.meal ?? currentMealType();
    _inputUseKj = ref.read(settingsProvider).useKj;
    final food = widget.food;
    final entry = widget.entry;
    final serving = food?.servingGrams;
    _gramsCtrl = TextEditingController(
      text: food != null
          ? round1(
              serving != null && serving.isFinite && serving > 0
                  ? serving
                  : 100,
            ).toString()
          : entry?.grams == null
          ? ''
          : round1(entry!.grams!).toString(),
    );
    _initialEnergyText = entry == null
        ? ''
        : round1(_inputUseKj ? kcalToKj(entry.kcal) : entry.kcal).toString();
    _kcalCtrl = TextEditingController(text: _initialEnergyText);
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  double? _positiveNumber(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  double? get _energyKcal {
    final value = _positiveNumber(_kcalCtrl.text);
    if (value == null) return null;
    // Do not round an unchanged stored snapshot just because its display is rounded.
    if (_kcalCtrl.text == _initialEnergyText) return widget.entry?.kcal;
    return _inputUseKj ? kjToKcal(value) : value;
  }

  (double, double, double, double)? _preview(double? grams) {
    if (grams == null) return null;
    final food = widget.food;
    final entry = widget.entry;
    final (double, double, double, double) result;
    if (food != null) {
      final factor = grams / 100;
      result = (
        food.kcal100 * factor,
        food.protein100 * factor,
        food.fat100 * factor,
        food.carb100 * factor,
      );
    } else if (entry != null &&
        entry.grams != null &&
        entry.grams!.isFinite &&
        entry.grams! > 0) {
      final factor = grams / entry.grams!;
      result = (
        entry.kcal * factor,
        entry.protein * factor,
        entry.fat * factor,
        entry.carb * factor,
      );
    } else {
      return null;
    }
    return [
          result.$1,
          result.$2,
          result.$3,
          result.$4,
        ].every((value) => value.isFinite && value >= 0)
        ? result
        : null;
  }

  void _inputChanged(String _) => setState(() => _error = null);

  Future<void> _save() async {
    if (_saving) return;
    final entry = widget.entry;
    final grams = _positiveNumber(_gramsCtrl.text);
    final preview = _preview(grams);
    final kcal = _energyKcal;
    final error = _kcalMode
        ? kcal == null
              ? tr(context, 'needPositiveEnergy')
              : null
        : grams == null
        ? tr(context, 'needPositiveGrams')
        : preview == null
        ? tr(context, 'cantCompute')
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final db = ref.read(dbProvider);
      if (_kcalMode && entry != null) {
        await db.updateEntry(
          entry.copyWith(meal: _meal, kcal: kcal!, protein: 0, fat: 0, carb: 0),
        );
      } else if (widget.food != null) {
        await db.addEntry(
          EntriesCompanion.insert(
            date: widget.date,
            meal: _meal,
            name: widget.food!.name,
            foodId: Value(widget.food!.id),
            grams: Value(grams),
            kcal: preview!.$1,
            protein: Value(preview.$2),
            fat: Value(preview.$3),
            carb: Value(preview.$4),
          ),
        );
      } else if (entry != null) {
        await db.updateEntry(
          entry.copyWith(
            meal: _meal,
            grams: Value(grams),
            kcal: preview!.$1,
            protein: preview.$2,
            fat: preview.$3,
            carb: preview.$4,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (_saving || entry == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(dbProvider).deleteEntry(entry.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final food = widget.food;
    final entry = widget.entry;
    final grams = _positiveNumber(_gramsCtrl.text);
    final preview = _preview(grams);
    final previewKcal = _kcalMode ? _energyKcal : preview?.$1;
    final title = food?.name ?? entry?.name ?? tr(context, 'entry');
    final useKj = _kcalMode ? _inputUseKj : settings.useKj;
    final presets = <double>[50, 100, 200];
    final serving = food?.servingGrams;
    final customServing =
        serving != null &&
        serving.isFinite &&
        serving > 0 &&
        food?.servingDesc?.trim().isNotEmpty == true;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (food?.brand?.trim().isNotEmpty == true)
                    Text(
                      food!.brand!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'entryDate', {'date': widget.date}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MealType>(
                    initialValue: _meal,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr(context, 'mealField'),
                    ),
                    items: [
                      for (final meal in MealType.values)
                        DropdownMenuItem(
                          value: meal,
                          child: Text(mealLabel(context, meal)),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (meal) {
                            if (meal != null) setState(() => _meal = meal);
                          },
                  ),
                  const SizedBox(height: 20),
                  SmartField(
                    label: tr(
                      context,
                      _kcalMode ? 'kcalField' : 'servingField',
                    ),
                    controller: _kcalMode ? _kcalCtrl : _gramsCtrl,
                    autofocus: entry == null,
                    maxLength: 9,
                    showCounter: false,
                    unit: _kcalMode
                        ? energyUnit(_inputUseKj)
                        : tr(context, 'gramUnit'),
                    errorText: _error,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: _inputChanged,
                  ),
                  if (_kcalMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'quickAddNote'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in presets)
                          ChoiceChip(
                            label: Text('${preset.round()}g'),
                            selected: grams == preset,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _gramsCtrl.text = preset.round().toString();
                                    _error = null;
                                  }),
                          ),
                        if (customServing)
                          ChoiceChip(
                            label: Text(
                              '${food!.servingDesc} (${round1(serving)}g)',
                            ),
                            selected: grams == serving,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _gramsCtrl.text = round1(serving)
                                        .toString();
                                    _error = null;
                                  }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'entryPreview'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        if (previewKcal == null)
                          Text(
                            tr(
                              context,
                              _kcalMode ? 'needPositiveEnergy' : 'previewHint',
                            ),
                          )
                        else ...[
                          Text(
                            '${fmtEnergy(previewKcal, useKj)} ${energyUnit(useKj)}',
                            style: numberStyle(28, LabelColors.energyOf(dark)),
                          ),
                          if (preview != null && !_kcalMode) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                for (final (label, value, color) in [
                                  (
                                    'proteinShort',
                                    preview.$2,
                                    LabelColors.proteinOf(dark),
                                  ),
                                  (
                                    'fatShort',
                                    preview.$3,
                                    LabelColors.fatOf(dark),
                                  ),
                                  (
                                    'carbShort',
                                    preview.$4,
                                    LabelColors.carbOf(dark),
                                  ),
                                ])
                                  Text(
                                    '${tr(context, label)} ${round1(value)}g',
                                    style: TextStyle(color: color),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomActionBar(
            leading: entry == null
                ? null
                : IconButton(
                    tooltip: tr(context, 'delete'),
                    onPressed: _saving ? null : _delete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
            info: _RemainingInfo(
              date: widget.date,
              projectedKcal: previewKcal,
              replacedEntryId: entry?.id,
            ),
            actionLabel: _saving
                ? tr(context, 'saving')
                : tr(context, entry == null ? 'addEntry' : 'saveEdit'),
            onAction: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _RemainingInfo extends ConsumerWidget {
  const _RemainingInfo({
    required this.date,
    required this.projectedKcal,
    this.replacedEntryId,
  });
  final String date;
  final double? projectedKcal;
  final int? replacedEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final entries = ref.watch(entriesProvider(date)).valueOrNull;
    final projecting = projectedKcal != null;
    final total =
        (entries ?? const <FoodEntry>[])
            .where((e) => !projecting || e.id != replacedEntryId)
            .fold(0.0, (sum, entry) => sum + entry.kcal) +
        (projectedKcal ?? 0);
    final goal = profile?.kcalGoal;
    final label = goal == null
        ? tr(context, projecting ? 'afterConsumed' : 'consumed')
        : tr(
            context,
            total > goal
                ? projecting
                      ? 'afterOver'
                      : 'over'
                : projecting
                ? 'afterRemaining'
                : 'remaining',
          );
    final value = fmtEnergy(
      goal == null ? total : (total - goal).abs(),
      settings.useKj,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: LabelColors.inkSoftOf(dark)),
        ),
        const SizedBox(height: 2),
        Text(
          '$value ${energyUnit(settings.useKj)}',
          style: numberStyle(17, LabelColors.energyOf(dark)),
        ),
      ],
    );
  }
}
