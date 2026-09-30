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
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _deleteEntry(FoodEntry e) async {
    await ref.read(dbProvider).deleteEntry(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'deleted', {'name': e.name})),
        action: SnackBarAction(
          label: tr(context, 'undo'),
          onPressed: () => ref
              .read(dbProvider)
              .addEntry(
                EntriesCompanion.insert(
                  date: e.date,
                  meal: e.meal,
                  name: e.name,
                  foodId: Value(e.foodId),
                  grams: Value(e.grams),
                  kcal: e.kcal,
                  protein: Value(e.protein),
                  fat: Value(e.fat),
                  carb: Value(e.carb),
                ),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKeyStr = dateKey(_date);
    final entriesAsync = ref.watch(entriesProvider(dateKeyStr));
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider(dateKeyStr)).valueOrNull;
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
        label: Text(tr(context, 'logFood')),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'tabToday'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const LangButton(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('today-previous-day'),
                      tooltip: tr(context, 'previousDay'),
                      onPressed: _date.isAfter(DateTime(2020))
                          ? () => setState(
                              () => _date = _date.subtract(
                                const Duration(days: 1),
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('today-date-picker'),
                        onPressed: _pickDate,
                        child: Text(dateText, textAlign: TextAlign.center),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('today-next-day'),
                      tooltip: tr(context, 'nextDay'),
                      onPressed:
                          _date.isBefore(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ),
                          )
                          ? () => setState(
                              () => _date = _date.add(const Duration(days: 1)),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (!_isToday)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      key: const ValueKey('today-back-to-now'),
                      onPressed: () => setState(() => _date = DateTime.now()),
                      icon: const Icon(Icons.today, size: 18),
                      label: Text(tr(context, 'backToToday')),
                    ),
                  ),
                const SizedBox(height: 8),
                // Energy and macros remain visible; calculation help is explicit.
                _OverviewFront(
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
                const SizedBox(height: 8),
                // ---- 四餐进度（已记录/当前/未记录，点节点看详情） ----
                MealProgressCard(
                  entries: entries,
                  isToday: _isToday,
                  useKj: settings.useKj,
                  onAdd: (meal) =>
                      openAddEntryFlow(context, date: dateKeyStr, meal: meal),
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
                    onEdit: (e) => showEntrySheet(
                      context,
                      date: dateKeyStr,
                      food: null,
                      entry: e,
                    ),
                    onDelete: _deleteEntry,
                    onAdd: () =>
                        openAddEntryFlow(context, date: dateKeyStr, meal: meal),
                  ),
              ],
            ),
          ),
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
    final goal = kcalGoal != null && kcalGoal!.isFinite && kcalGoal! > 0
        ? kcalGoal
        : null;
    final over = goal != null && kcalTotal > goal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 21;
            final ring = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RingProgress(
                  progress: goal == null ? 0 : kcalTotal / goal,
                  size: stacked ? 184 : 140,
                  center: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmtEnergy(kcalTotal, settings.useKj),
                          textAlign: TextAlign.center,
                          style: numberStyle(
                            stacked ? 20 : 24,
                            LabelColors.energyOf(dark),
                          ),
                        ),
                        Text(
                          energyUnit(settings.useKj),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context, 'consumed'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    context,
                    goal == null
                        ? 'goalNotSet'
                        : over
                        ? 'over'
                        : 'remaining',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (goal != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${fmtEnergy((goal - kcalTotal).abs(), settings.useKj)} ${energyUnit(settings.useKj)}',
                    style: numberStyle(
                      28,
                      over
                          ? Theme.of(context).colorScheme.error
                          : LabelColors.energyOf(dark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'dailyEnergyGoal', {
                      'value':
                          '${fmtEnergy(goal, settings.useKj)} ${energyUnit(settings.useKj)}',
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onGoSettings,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: Text(tr(context, 'setGoalCta')),
                  ),
                ],
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stacked) ...[
                  Center(child: ring),
                  const SizedBox(height: 16),
                  summary,
                ] else
                  Row(
                    children: [
                      ring,
                      const SizedBox(width: 20),
                      Expanded(child: summary),
                    ],
                  ),
                const SizedBox(height: 20),
                MacroBars(
                  protein: pTotal,
                  fat: fTotal,
                  carb: cTotal,
                  goals: goals == null
                      ? null
                      : (goals!.$1, goals!.$2, goals!.$3),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('today-calculation-help'),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                tr(context, 'calcRulesTitle'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(tr(context, 'calcRules')),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr(context, 'close')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(tr(context, 'calcHelp')),
                  ),
                ),
              ],
            );
          },
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
    final ratio = goalMl <= 0 ? 0.0 : clamp01(ml / goalMl);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: LabelColors.blueOf(dark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(context, 'water'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$ml / $goalMl ml${goalMl <= 0 ? '' : ' · ${(ratio * 100).round()}%'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('today-water-remove'),
                  onPressed: ml <= 0
                      ? null
                      : () => ref.read(dbProvider).addWater(dateKeyStr, -250),
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('250 ml'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('today-water-add'),
                  onPressed: () =>
                      ref.read(dbProvider).addWater(dateKeyStr, 250),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('250 ml'),
                ),
              ],
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
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mealLabel(context, meal),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                key: ValueKey('meal-add-${meal.name}'),
                tooltip: tr(context, 'addTo', {
                  'meal': mealLabel(context, meal),
                }),
                onPressed: onAdd,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: LabelColors.blueOf(dark),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                entries.isEmpty
                    ? tr(context, 'empty')
                    : tr(context, entries.length == 1 ? 'itemsOne' : 'items', {
                        'n': '${entries.length}',
                      }),
                style: captionStyle(context),
              ),
              if (entries.isNotEmpty)
                Text(
                  '${fmtEnergy(subtotal, useKj)} ${energyUnit(useKj)}',
                  style: numberStyle(15, LabelColors.energyOf(dark)),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
              child: InkWell(
                onTap: () => onEdit(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        e.name,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (e.grams != null)
                            Text(
                              '${round1(e.grams!)}g',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            '${fmtEnergy(e.kcal, useKj)} ${energyUnit(useKj)}',
                            style: numberStyle(
                              14,
                              LabelColors.energyOf(dark),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (e.protein + e.fat + e.carb > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${tr(context, 'proteinShort')} ${round1(e.protein)} · '
                          '${tr(context, 'fatShort')} ${round1(e.fat)} · ${tr(context, 'carbShort')} ${round1(e.carb)} g',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (i != entries.length - 1) const Divider(indent: 16, height: 1),
          ],
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr(context, 'emptyMealAction'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
