import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../../logic/stats_summary.dart';
import '../theme.dart';
import '../widgets/app_segmented.dart';
import '../widgets/charts.dart';
import '../widgets/lang_button.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _days = 30;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = dateKey(now);
    final entries = ref
        .watch(
          entriesRangeProvider((
            dateKey(now.subtract(Duration(days: _days - 1))),
            today,
          )),
        )
        .valueOrNull;
    final heatEntries = ref
        .watch(
          entriesRangeProvider((
            dateKey(now.subtract(const Duration(days: 69))),
            today,
          )),
        )
        .valueOrNull;
    final weights = ref.watch(weightsProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    if (entries == null || heatEntries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final summary = StatsSummary(entries, end: now, days: _days);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unit = energyUnit(settings.useKj);
    final goal =
        profile?.kcalGoal != null &&
            profile!.kcalGoal!.isFinite &&
            profile.kcalGoal! > 0
        ? profile.kcalGoal
        : null;
    final streak = streakDays(heatEntries.map((e) => e.date), today);
    final ratios = <String, double>{};
    if (goal != null) {
      for (final e in heatEntries) {
        ratios[e.date] = (ratios[e.date] ?? 0) + e.kcal / goal;
      }
    }
    final weekFrom = dateKey(now.subtract(const Duration(days: 6)));
    final weekEntries = heatEntries
        .where((e) => e.date.compareTo(weekFrom) >= 0)
        .toList();
    final weekDays = weekEntries.map((e) => e.date).toSet().length;
    final pAvg = weekDays == 0
        ? 0.0
        : weekEntries.fold(0.0, (sum, e) => sum + e.protein) / weekDays;
    final fAvg = weekDays == 0
        ? 0.0
        : weekEntries.fold(0.0, (sum, e) => sum + e.fat) / weekDays;
    final cAvg = weekDays == 0
        ? 0.0
        : weekEntries.fold(0.0, (sum, e) => sum + e.carb) / weekDays;
    final defaults = goal == null ? null : defaultMacroGoals(goal);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabStats')),
        actions: const [LangButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr(context, 'trendTitle'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      AppSegmented<int>(
                        segments: [
                          (7, tr(context, 'd7')),
                          (30, tr(context, 'd30')),
                        ],
                        selected: _days,
                        onChanged: (days) => setState(() => _days = days),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _Metric(
                            label: tr(context, 'loggedDayAverage'),
                            value:
                                '${fmtEnergy(summary.average, settings.useKj)} $unit',
                            color: LabelColors.energyOf(dark),
                          ),
                          _Metric(
                            label: tr(context, 'recordedDays'),
                            value: '${summary.recordedDays} / $_days',
                          ),
                          _Metric(
                            label: tr(context, 'loggingStreak'),
                            value: tr(context, 'dayCount', {'n': '$streak'}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(context, 'missingDaysNote', {
                          'n': '${summary.missingDays}',
                        }),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recordedDays == 0)
                        Text(tr(context, 'noTrendYet'))
                      else ...[
                        Text(
                          tr(context, 'chartUnit', {'unit': unit}),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SimpleLineChart(
                          key: const ValueKey('energy-trend'),
                          values: summary.values(useKj: settings.useKj),
                          xLabels: [
                            for (final d in summary.dates)
                              d.substring(5).replaceFirst('-', '/'),
                          ],
                          goal: goal == null
                              ? null
                              : settings.useKj
                              ? kcalToKj(goal)
                              : goal,
                          goalLabel: goal == null ? null : tr(context, 'goal'),
                          color: LabelColors.energyOf(dark),
                          yUnit: unit,
                          zeroBaseline: true,
                        ),
                      ],
                      const SizedBox(height: 8),
                      ExpansionTile(
                        key: const ValueKey('stats-daily-details'),
                        tilePadding: EdgeInsets.zero,
                        title: Text(tr(context, 'dailyDetails')),
                        children: [
                          for (final d in summary.dates.reversed)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(d)),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      summary.totals[d] == null
                                          ? tr(context, 'notLogged')
                                          : '${fmtEnergy(summary.totals[d]!, settings.useKj)} $unit',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr(context, 'heatTitle'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (goal == null)
                        Text(
                          tr(context, 'heatHint'),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Heatmap(ratioByDate: ratios, today: now),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr(context, 'macroTitle'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'macroAverageNote', {'n': '$weekDays'}),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (weekDays == 0)
                        Text(tr(context, 'noMacroYet'))
                      else
                        MacroBars(
                          protein: pAvg,
                          fat: fAvg,
                          carb: cAvg,
                          goals: (
                            profile?.proteinGoal ?? defaults?.$1,
                            profile?.fatGoal ?? defaults?.$2,
                            profile?.carbGoal ?? defaults?.$3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _WeightCard(weights: weights ?? const [], today: now),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        value,
        style: numberStyle(
          24,
          color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}

class _WeightCard extends ConsumerStatefulWidget {
  const _WeightCard({required this.weights, required this.today});
  final List<WeightRec> weights;
  final DateTime today;
  @override
  ConsumerState<_WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends ConsumerState<_WeightCard> {
  bool _saving = false;
  Future<void> _add() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final value = await showDialog<double>(
        context: context,
        builder: (_) => _WeightEntryDialog(
          initial: widget.weights.isEmpty ? null : widget.weights.first.kg,
        ),
      );
      if (value == null || !mounted) return;
      final db = ref.read(dbProvider);
      await db.transaction(() async {
        await db.addWeight(dateKey(widget.today), value);
        await db.saveProfile(
          ProfilesCompanion(id: const Value(1), weightKg: Value(value)),
        );
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(context, 'saveFail'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weights = widget.weights;
    final latest = weights.isEmpty ? null : weights.first;
    final delta = weights.length < 2
        ? null
        : weights.first.kg - weights.last.kg;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: const ValueKey('stats-weight-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, 'weightTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'weightAllRecords'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('stats-add-weight'),
                onPressed: _saving ? null : _add,
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr(context, _saving ? 'saving' : 'weightLogTitle')),
              ),
            ),
            if (latest == null)
              Text(tr(context, 'noWeight'))
            else ...[
              const SizedBox(height: 12),
              Text(
                '${round1(latest.kg)} kg',
                style: numberStyle(26, LabelColors.weightOf(dark)),
              ),
              const SizedBox(height: 4),
              Text(latest.date, style: Theme.of(context).textTheme.bodySmall),
              if (delta != null)
                Text(
                  tr(context, 'weightComparison', {
                    'd': '${delta >= 0 ? '+' : ''}${round1(delta)}',
                    'date': weights.last.date,
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              SimpleLineChart(
                key: const ValueKey('weight-trend'),
                values: [for (final w in weights.reversed) w.kg],
                xLabels: [
                  for (final w in weights.reversed)
                    w.date.substring(5).replaceFirst('-', '/'),
                ],
                yUnit: 'kg',
                color: LabelColors.weightOf(dark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({this.initial});
  final double? initial;
  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == null ? '' : round1(widget.initial!).toString(),
  );
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || !value.isFinite || value <= 0 || value > 500) {
      setState(() => _error = tr(context, 'invalidWeight'));
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(context, 'weightLogTitle')),
    content: SingleChildScrollView(
      child: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: tr(context, 'weightTitle'),
          suffixText: 'kg',
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(onPressed: _submit, child: Text(tr(context, 'save'))),
    ],
  );
}
