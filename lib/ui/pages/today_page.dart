import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../sheets/entry_sheet.dart';
import '../sheets/food_picker_sheet.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/collapsible_card.dart';
import '../widgets/flip_card.dart';
import '../widgets/meal_progress_card.dart';
import '../widgets/lang_button.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key, this.onGoSettings});

  final VoidCallback? onGoSettings;

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  DateTime _date = DateTime.now();

  bool get _isToday => dateKey(_date) == dateKey(DateTime.now());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _deleteEntry(FoodEntry e) async {
    await ref.read(dbProvider).deleteEntry(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(context, 'deleted', {'name': e.name})),
      action: SnackBarAction(
        label: tr(context, 'undo'),
        onPressed: () => ref.read(dbProvider).addEntry(EntriesCompanion.insert(
              date: e.date,
              meal: e.meal,
              name: e.name,
              foodId: Value(e.foodId),
              grams: Value(e.grams),
              kcal: e.kcal,
              protein: Value(e.protein),
              fat: Value(e.fat),
              carb: Value(e.carb),
            )),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateKeyStr = dateKey(_date);
    final entriesAsync = ref.watch(entriesProvider(dateKeyStr));
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider(dateKeyStr)).valueOrNull;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final entries = entriesAsync.valueOrNull;
    if (entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final kcalTotal = entries.fold(0.0, (s, e) => s + e.kcal);
    final pTotal = entries.fold(0.0, (s, e) => s + e.protein);
    final fTotal = entries.fold(0.0, (s, e) => s + e.fat);
    final cTotal = entries.fold(0.0, (s, e) => s + e.carb);

    final kcalGoal = profile?.kcalGoal;
    final overGoal = kcalGoal != null && kcalTotal > kcalGoal;
    final goals = profile == null
        ? null
        : (
            profile.proteinGoal ??
                (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$1),
            profile.fatGoal ??
                (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$2),
            profile.carbGoal ??
                (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$3),
          );

    final dateText =
        '${formatDateShort(_date, LangScope.of(context))}'
        '${_isToday ? ' · ${tr(context, 'today')}' : ''}';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'today-add',
        onPressed: () => openAddEntryFlow(context, date: dateKeyStr),
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'add')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // ---- 日期导航 + 语言切换 ----
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _date = _date.subtract(const Duration(days: 1))),
                      icon: Icon(Icons.chevron_left, color: LabelColors.blueOf(dark)),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          dateText,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isToday
                          ? null
                          : () => setState(() => _date = _date.add(const Duration(days: 1))),
                      icon: Icon(Icons.chevron_right, color: LabelColors.blueOf(dark)),
                    ),
                  ],
                ),
                const Positioned(right: 0, child: LangButton()),
              ],
            ),
            const SizedBox(height: 8),
            // ---- 总览卡（正面数据 / 背面计算规则，点按翻转） ----
            FlipCard(
              front: _OverviewFront(
                kcalGoal: kcalGoal,
                kcalTotal: kcalTotal,
                pTotal: pTotal,
                fTotal: fTotal,
                cTotal: cTotal,
                goals: goals,
                overGoal: overGoal,
                settings: settings,
                onGoSettings: widget.onGoSettings,
              ),
              back: _OverviewBack(dark: dark),
            ),
            const SizedBox(height: 8),
            // ---- 四餐进度（已记录/当前/未记录，点节点看详情） ----
            MealProgressCard(
              entries: entries,
              isToday: _isToday,
              useKj: settings.useKj,
            ),
            const SizedBox(height: 8),
            // ---- 饮水 ----
            _WaterCard(
              ml: water?.ml ?? 0,
              goalMl: settings.waterGoalMl,
              dateKeyStr: dateKeyStr,
            ),
            const SizedBox(height: 8),
            // ---- 四餐 ----
            for (final meal in MealType.values)
              _MealSection(
                date: dateKeyStr,
                meal: meal,
                entries: entries.where((e) => e.meal == meal).toList(),
                useKj: settings.useKj,
                onEdit: (e) => showEntrySheet(context,
                    date: dateKeyStr, food: null, entry: e),
                onDelete: _deleteEntry,
                onAdd: () =>
                    openAddEntryFlow(context, date: dateKeyStr, meal: meal),
              ),
          ],
        ),
      ),
    );
  }
}

/// 总览卡正面：活动环 + 已摄入/剩余 + 宏量
class _OverviewFront extends ConsumerWidget {
  const _OverviewFront({
    required this.kcalGoal,
    required this.kcalTotal,
    required this.pTotal,
    required this.fTotal,
    required this.cTotal,
    required this.goals,
    required this.overGoal,
    required this.settings,
    this.onGoSettings,
  });

  final double? kcalGoal;
  final double kcalTotal;
  final double pTotal;
  final double fTotal;
  final double cTotal;
  final (double?, double?, double?)? goals;
  final bool overGoal;
  final AppSettings settings;
  final VoidCallback? onGoSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = LabelColors.inkOf(dark);
    // 局部变量以获得空值提升
    final goal = kcalGoal;
    final g = goals;
    final ringValue = goal == null
        ? fmtEnergy(kcalTotal, settings.useKj)
        : fmtEnergy(
            overGoal ? kcalTotal - goal : goal - kcalTotal,
            settings.useKj);
    final ringCaption = goal == null
        ? '${tr(context, 'consumed')} · ${energyUnit(settings.useKj)}'
        : '${tr(context, overGoal ? 'over' : 'remaining')} · ${energyUnit(settings.useKj)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RingProgress(
                  progress: goal == null || goal <= 0
                      ? 0
                      : kcalTotal / goal,
                  size: 140,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ringValue,
                        style: numberStyle(
                            30,
                            overGoal
                                ? Theme.of(context).colorScheme.error
                                : LabelColors.energyOf(dark)),
                      ),
                      const SizedBox(height: 4),
                      Text(ringCaption, style: captionStyle(context)),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                              goal == null
                                  ? tr(context, 'goalNotSet')
                                  : fmtEnergy(kcalTotal, settings.useKj),
                              style: numberStyle(20, ink)),
                          if (goal != null) ...[
                            const SizedBox(width: 4),
                            Text(
                                ' / ${fmtEnergy(goal, settings.useKj)} '
                                '${energyUnit(settings.useKj)}',
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      MacroBars(
                        protein: pTotal,
                        fat: fTotal,
                        carb: cTotal,
                        goals: g == null ? null : (g.$1, g.$2, g.$3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (goal == null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onGoSettings,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(tr(context, 'setGoalCta')),
              ),
            ],
            const SizedBox(height: 10),
            // 翻转提示
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tr(context, 'flipHint'), style: captionStyle(context)),
                const SizedBox(width: 4),
                Icon(Icons.rotate_right,
                    size: 13, color: LabelColors.inkSoftOf(dark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 总览卡背面：数值是怎么算出来的
class _OverviewBack extends StatelessWidget {
  const _OverviewBack({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LabelColors.fillOf(dark),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'calcRulesTitle'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              tr(context, 'calcRules'),
              style: TextStyle(
                  fontSize: 13, height: 1.6, color: LabelColors.inkOf(dark)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tr(context, 'flipHint'), style: captionStyle(context)),
                const SizedBox(width: 4),
                Icon(Icons.rotate_right,
                    size: 13, color: LabelColors.inkSoftOf(dark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({
    required this.ml,
    required this.goalMl,
    required this.dateKeyStr,
  });

  final int ml;
  final int goalMl;
  final String dateKeyStr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ratio = goalMl <= 0 ? null : clamp01(ml / goalMl);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, color: LabelColors.blueOf(dark)),
                const SizedBox(width: 8),
                Text(tr(context, 'water'),
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                // 就地回显：当前量 / 目标 · 百分比
                Flexible(
                  child: Text(
                    '$ml / $goalMl ml'
                    '${ratio == null ? '' : ' · ${(ratio * 100).round()}%'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: LabelColors.inkOf(dark),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '-250 ml',
                  onPressed: ml <= 0
                      ? null
                      : () => ref.read(dbProvider).addWater(dateKeyStr, -250),
                  icon: Icon(Icons.remove_circle_outline,
                      size: 20, color: LabelColors.blueOf(dark)),
                ),
                IconButton(
                  tooltip: '+250 ml',
                  onPressed: () =>
                      ref.read(dbProvider).addWater(dateKeyStr, 250),
                  icon: Icon(Icons.add_circle_outline,
                      size: 20, color: LabelColors.blueOf(dark)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.date,
    required this.meal,
    required this.entries,
    required this.useKj,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final String date;
  final MealType meal;
  final List<FoodEntry> entries;
  final bool useKj;
  final void Function(FoodEntry) onEdit;
  final void Function(FoodEntry) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = entries.fold(0.0, (s, e) => s + e.kcal);
    return CollapsibleCard(
      initiallyExpanded: true,
      contentPadding: EdgeInsets.zero,
      header: Row(
        children: [
          Text(mealLabel(context, meal),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(
            entries.isEmpty
                ? tr(context, 'empty')
                : tr(context, entries.length == 1 ? 'itemsOne' : 'items',
                    {'n': '${entries.length}'}),
            style: captionStyle(context),
          ),
          const Spacer(),
          if (entries.isNotEmpty)
            Text('${fmtEnergy(subtotal, useKj)} ${energyUnit(useKj)}',
                style: numberStyle(15, LabelColors.energyOf(dark))),
          IconButton(
            tooltip: tr(context, 'add'),
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline,
                size: 20, color: LabelColors.blueOf(dark)),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final (i, e) in entries.indexed) ...[
            Dismissible(
              key: ValueKey('entry-${e.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDelete(e),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Theme.of(context).colorScheme.error,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Text(
                  '${e.name}${e.grams == null ? '' : ' · ${round1(e.grams!)}g'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: e.protein + e.fat + e.carb > 0
                    ? Text(
                        '${tr(context, 'proteinShort')} ${round1(e.protein)} · '
                        '${tr(context, 'fatShort')} ${round1(e.fat)} · '
                        '${tr(context, 'carbShort')} ${round1(e.carb)} g',
                        style: Theme.of(context).textTheme.bodySmall)
                    : null,
                trailing: Text('${fmtEnergy(e.kcal, useKj)} ${energyUnit(useKj)}',
                    style: numberStyle(14, LabelColors.energyOf(dark),
                        weight: FontWeight.w600)),
                onTap: () => onEdit(e),
              ),
            ),
            if (i != entries.length - 1)
              const Divider(indent: 16, height: 1),
          ],
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(tr(context, 'emptyMealTip'),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }
}
