import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
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
    builder: (_) => EntrySheet(date: date, meal: meal, food: food, entry: entry),
  );
}

/// 记录份量并写入饮食记录；也用于编辑已有记录
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
  final Food? food; // 新增模式
  final FoodEntry? entry; // 编辑模式

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  late MealType _meal;
  late final TextEditingController _gramsCtrl;
  late final TextEditingController _kcalCtrl;

  bool get _kcalMode => widget.food == null && (widget.entry?.foodId == null);

  @override
  void initState() {
    super.initState();
    _meal = widget.meal ?? widget.entry?.meal ?? currentMealType();
    _gramsCtrl = TextEditingController();
    _kcalCtrl = TextEditingController();
    final food = widget.food;
    final entry = widget.entry;
    if (food != null) {
      _gramsCtrl.text = (food.servingGrams ?? 100).round().toString();
    } else if (entry != null) {
      if (entry.grams != null) _gramsCtrl.text = round1(entry.grams!).toString();
      _kcalCtrl.text = round1(entry.kcal).toString();
    }
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  /// 按输入克数折算营养快照；无法折算时返回 null
  (double kcal, double p, double f, double c)? _preview(double grams) {
    final food = widget.food;
    if (food != null) {
      final k = grams / 100;
      return (food.kcal100 * k, food.protein100 * k, food.fat100 * k, food.carb100 * k);
    }
    final e = widget.entry;
    if (e != null && e.grams != null && e.grams! > 0) {
      final k = grams / e.grams!;
      return (e.kcal * k, e.protein * k, e.fat * k, e.carb * k);
    }
    return null;
  }

  Future<void> _save() async {
    final db = ref.read(dbProvider);
    final entry = widget.entry;
    if (_kcalMode) {
      final kcal = double.tryParse(_kcalCtrl.text.trim());
      if (kcal == null || kcal <= 0) {
        _toast(tr(context, 'needKcal'));
        return;
      }
      if (entry == null) return;
      await db.updateEntry(entry.copyWith(
        meal: _meal,
        kcal: kcal,
        protein: 0,
        fat: 0,
        carb: 0,
      ));
    } else {
      final grams = double.tryParse(_gramsCtrl.text.trim());
      if (grams == null || grams <= 0) {
        _toast(tr(context, 'needGrams'));
        return;
      }
      final preview = _preview(grams);
      if (preview == null) {
        _toast(tr(context, 'cantCompute'));
        return;
      }
      final (kcal, p, f, c) = preview;
      if (widget.food != null) {
        await db.addEntry(EntriesCompanion.insert(
          date: widget.date,
          meal: _meal,
          name: widget.food!.name,
          foodId: Value(widget.food!.id),
          grams: Value(grams),
          kcal: kcal,
          protein: Value(p),
          fat: Value(f),
          carb: Value(c),
        ));
      } else if (entry != null) {
        await db.updateEntry(entry.copyWith(
          meal: _meal,
          grams: Value(grams),
          kcal: kcal,
          protein: p,
          fat: f,
          carb: c,
        ));
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    await ref.read(dbProvider).deleteEntry(entry.id);
    if (mounted) Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final food = widget.food;
    final entry = widget.entry;
    final grams = double.tryParse(_gramsCtrl.text.trim());
    final preview = grams == null || grams <= 0 ? null : _preview(grams);
    final title = food?.name ?? entry?.name ?? tr(context, 'entry');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 内容区可滚动；操作栏固定吸底
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if (food?.brand != null)
                  Text(food!.brand!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            CupertinoSlidingSegmentedControl<MealType>(
              groupValue: _meal,
              onValueChanged: (m) => setState(() => _meal = m!),
              thumbColor: const CupertinoDynamicColor.withBrightness(
                color: Color(0xFFFFFFFF),
                darkColor: Color(0xFF636366),
              ),
              children: {
                for (final m in MealType.values)
                  m: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    child: Text(mealLabel(context, m),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
              },
            ),
            const SizedBox(height: 16),
            if (_kcalMode) ...[
              SmartField(
                label: tr(context, 'kcalField'),
                controller: _kcalCtrl,
                autofocus: true,
                maxLength: 6,
                unit: energyUnit(settings.useKj),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(tr(context, 'quickAddNote'),
                  style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              SmartField(
                label: tr(context, 'servingField'),
                controller: _gramsCtrl,
                autofocus: widget.entry == null,
                maxLength: 6,
                unit: tr(context, 'gramUnit'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final g in const [50.0, 100.0, 200.0])
                    ActionChip(
                      label: Text('${g.round()}g'),
                      onPressed: () =>
                          setState(() => _gramsCtrl.text = g.round().toString()),
                    ),
                  if (food?.servingDesc != null && food?.servingGrams != null)
                    ActionChip(
                      label: Text(
                          '${food!.servingDesc} (${round1(food.servingGrams!)}g)'),
                      onPressed: () => setState(() =>
                          _gramsCtrl.text = round1(food.servingGrams!).toString()),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: preview == null && !_kcalMode
                  ? Text(tr(context, 'previewHint'),
                      style: Theme.of(context).textTheme.bodySmall)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kcalMode
                              ? '${fmtEnergy(double.tryParse(_kcalCtrl.text) ?? 0, settings.useKj)} ${energyUnit(settings.useKj)}'
                              : '${fmtEnergy(preview!.$1, settings.useKj)} ${energyUnit(settings.useKj)}',
                          style: numberStyle(
                              28, LabelColors.energyOf(dark)),
                        ),
                        if (!_kcalMode) ...[
                          const SizedBox(height: 6),
                          Text(
                            tr(context, 'previewMacro', {
                              'p': '${round1(preview!.$2)}',
                              'f': '${round1(preview.$3)}',
                              'c': '${round1(preview.$4)}',
                            }),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 8),
          ]),
            ),
          ),
          // 吸底操作栏：左侧实时剩余/已摄入，右侧主按钮，编辑时最左删除
          BottomActionBar(
            leading: entry != null
                ? IconButton(
                    tooltip: tr(context, 'delete'),
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                  )
                : null,
            info: _RemainingInfo(date: widget.date, kcalMode: _kcalMode),
            actionLabel:
                entry == null ? tr(context, 'add') : tr(context, 'saveEdit'),
            onAction: _save,
          ),
        ],
      ),
    );
  }
}

/// 底部操作栏左侧的实时关键信息：有目标→还可摄入 x；无目标→已摄入 x
class _RemainingInfo extends ConsumerWidget {
  const _RemainingInfo({required this.date, required this.kcalMode});

  final String date;
  final bool kcalMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final entries = ref.watch(entriesProvider(date)).valueOrNull;
    final total = entries?.fold(0.0, (s, e) => s + e.kcal) ?? 0;
    final goal = profile?.kcalGoal;
    final unit = energyUnit(settings.useKj);

    final label = goal == null
        ? tr(context, 'consumed')
        : tr(context, total > goal ? 'over' : 'remaining');
    final value = goal == null
        ? fmtEnergy(total, settings.useKj)
        : fmtEnergy((total - goal).abs(), settings.useKj);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: LabelColors.inkSoftOf(dark))),
        const SizedBox(height: 1),
        Text('$value $unit',
            style: numberStyle(17, LabelColors.energyOf(dark))),
      ],
    );
  }
}
