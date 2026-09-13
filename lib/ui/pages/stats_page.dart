import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
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
  int _dir = 1; // 切换方向：内容横滑动画用

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = dateKey(now);
    final rangeFrom = dateKey(now.subtract(Duration(days: _days - 1)));
    final heatFrom = dateKey(now.subtract(const Duration(days: 69)));

    final entries = ref.watch(entriesRangeProvider((rangeFrom, todayKey))).valueOrNull;
    final heatEntries = ref.watch(entriesRangeProvider((heatFrom, todayKey))).valueOrNull;
    final weights = ref.watch(weightsProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);

    if (entries == null || heatEntries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final kcalGoal = profile?.kcalGoal;
    final unit = energyUnit(settings.useKj);

    // ---- 区间统计 ----
    final byDate = <String, double>{};
    final macrosByDate = <String, List<double>>{};
    for (final e in entries) {
      byDate[e.date] = (byDate[e.date] ?? 0) + e.kcal;
      final m = macrosByDate.putIfAbsent(e.date, () => [0, 0, 0]);
      m[0] += e.protein;
      m[1] += e.fat;
      m[2] += e.carb;
    }
    final recordedDays = byDate.values.where((v) => v > 0).length;
    final avg = recordedDays == 0
        ? 0.0
        : byDate.values.fold(0.0, (s, v) => s + v) / recordedDays;
    final streak = streakDays(
        heatEntries.where((e) => e.kcal > 0).map((e) => e.date), todayKey);

    final days = List.generate(_days, (i) => now.subtract(Duration(days: _days - 1 - i)));
    final chartValues = [for (final d in days) byDate[dateKey(d)] ?? 0.0];
    final chartLabels = [for (final d in days) '${d.month}/${d.day}'];

    // ---- 热力图 ----
    final ratioByDate = <String, double>{};
    for (final e in heatEntries) {
      ratioByDate[e.date] = (ratioByDate[e.date] ?? 0) + e.kcal;
    }
    if (kcalGoal != null && kcalGoal > 0) {
      for (final k in ratioByDate.keys.toList()) {
        ratioByDate[k] = ratioByDate[k]! / kcalGoal;
      }
    } else {
      ratioByDate.clear();
    }

    // ---- 近7天宏量均值 ----
    final weekFrom = dateKey(now.subtract(const Duration(days: 6)));
    final weekEntries = heatEntries.where((e) => e.date.compareTo(weekFrom) >= 0);
    final weekDays = weekEntries.map((e) => e.date).toSet().length;
    final pAvg = weekDays == 0 ? 0.0 : weekEntries.fold(0.0, (s, e) => s + e.protein) / weekDays;
    final fAvg = weekDays == 0 ? 0.0 : weekEntries.fold(0.0, (s, e) => s + e.fat) / weekDays;
    final cAvg = weekDays == 0 ? 0.0 : weekEntries.fold(0.0, (s, e) => s + e.carb) / weekDays;
    double? pGoal, fGoal, cGoal;
    if (profile != null) {
      pGoal = profile.proteinGoal ??
          (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$1);
      fGoal = profile.fatGoal ??
          (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$2);
      cGoal = profile.carbGoal ??
          (kcalGoal == null ? null : defaultMacroGoals(kcalGoal).$3);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabStats')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- 热量趋势 ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(tr(context, 'trendTitle'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      AppSegmented<int>(
                        segments: [
                          (7, tr(context, 'd7')),
                          (30, tr(context, 'd30')),
                        ],
                        selected: _days,
                        onChanged: (v) => setState(() {
                          _dir = v > _days ? 1 : -1;
                          _days = v;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 内容区随分段切换横向滑入滑出
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.05 * _dir, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_days),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'statsSub', {
                              'd': '$recordedDays',
                              'a': fmtEnergy(avg, settings.useKj),
                              'u': unit,
                              's': '$streak',
                            }),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SimpleLineChart(
                            values: chartValues,
                            xLabels: chartLabels,
                            goal: kcalGoal,
                            goalLabel:
                                kcalGoal == null ? null : tr(context, 'goal'),
                            color: LabelColors.energyOf(Theme.of(context)
                                        .brightness ==
                                    Brightness.dark),
                            yUnit: settings.useKj ? 'kJ' : '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---- 热力图 ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'heatTitle'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  kcalGoal == null
                      ? Text(tr(context, 'heatHint'),
                          style: Theme.of(context).textTheme.bodySmall)
                      : Heatmap(ratioByDate: ratioByDate, today: now),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---- 宏量均值 ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'macroTitle'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  MacroBars(
                    protein: pAvg,
                    fat: fAvg,
                    carb: cAvg,
                    goals: (pGoal, fGoal, cGoal),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---- 体重 ----
          _WeightCard(weights: weights ?? const [], today: now),
        ],
      ),
    );
  }
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard({required this.weights, required this.today});

  final List<WeightRec> weights;
  final DateTime today;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final latest = weights.isEmpty ? null : weights.first.kg;
    final v = await showNumberDialog(
      context,
      title: tr(context, 'weightLogTitle'),
      initial: latest == null ? null : round1(latest).toString(),
      suffix: 'kg',
    );
    if (v == null || v <= 0 || v > 500) return;
    final db = ref.read(dbProvider);
    await db.addWeight(dateKey(today), v);
    // 同步更新个人资料里的当前体重（用于 TDEE 估算）
    final profile = await (db.select(db.profiles)..where((p) => p.id.equals(1)))
        .getSingleOrNull();
    if (profile != null) {
      await db.saveProfile(ProfilesCompanion(id: const Value(1), weightKg: Value(v)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartWeights = weights.reversed.toList(); // 时间升序
    final latest = weights.isEmpty ? null : weights.first;
    final delta = weights.length >= 2 ? weights.first.kg - weights.last.kg : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tr(context, 'weightTitle'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr(context, 'add')),
                ),
              ],
            ),
            if (latest == null) ...[
              Text(tr(context, 'noWeight'),
                  style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${round1(latest.kg)} kg',
                      style: numberStyle(
                          24,
                          LabelColors.inkOf(Theme.of(context).brightness ==
                              Brightness.dark))),
                  const SizedBox(width: 12),
                  if (delta != null)
                    Text(
                      tr(context, 'vsFirst',
                          {'d': '${delta >= 0 ? '+' : ''}${round1(delta)}'}),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SimpleLineChart(
                values: [for (final w in chartWeights) w.kg],
                xLabels: [
                  for (final w in chartWeights)
                    w.date.substring(w.date.length - 5).replaceFirst('-', '/')
                ],
                color: LabelColors.weightOf(
                    Theme.of(context).brightness == Brightness.dark),
                yUnit: 'kg',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
