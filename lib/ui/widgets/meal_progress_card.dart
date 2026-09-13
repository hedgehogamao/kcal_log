import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../theme.dart';

/// 今日四餐进度卡片：节点三态——
/// 已记录（绿底白勾）/ 当前选中（蓝底高亮，下方展开该餐详情）/ 未记录（灰底灰点）。
/// 点按节点切换下方展开的详情；默认选中当前餐（仅今天按钟点判断）。
class MealProgressCard extends StatefulWidget {
  const MealProgressCard({
    super.key,
    required this.entries,
    required this.isToday,
    required this.useKj,
  });

  final List<FoodEntry> entries;
  final bool isToday;
  final bool useKj;

  @override
  State<MealProgressCard> createState() => _MealProgressCardState();
}

class _MealProgressCardState extends State<MealProgressCard> {
  /// 用户点选的餐次；null = 跟随当前餐
  MealType? _picked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final meals = MealType.values;
    final current = widget.isToday ? currentMealType() : null;
    final selected = _picked ?? current ?? meals.first;

    final byMeal = {for (final m in meals) m: <FoodEntry>[]};
    for (final e in widget.entries) {
      byMeal[e.meal]!.add(e);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < meals.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          // 连接线：选中节点之前的段落点亮
                          color: i <= meals.indexOf(selected)
                              ? LabelColors.blueOf(dark)
                              : fill,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  _node(context, meals[i], byMeal[meals[i]]!,
                      current: current, selected: selected),
                ],
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(selected),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: fill, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(mealLabel(context, selected),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              if (selected == current) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: LabelColors.blueOf(dark)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    tr(context, 'mealNow'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: LabelColors.blueOf(dark)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            byMeal[selected]!.isEmpty
                                ? tr(context, 'empty')
                                : '${tr(context, byMeal[selected]!.length == 1 ? 'itemsOne' : 'items', {'n': '${byMeal[selected]!.length}'})}'
                                    ' · ${fmtEnergy(byMeal[selected]!.fold(0.0, (s, e) => s + e.kcal), widget.useKj)} ${energyUnit(widget.useKj)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: LabelColors.inkSoftOf(dark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _node(BuildContext context, MealType meal, List<FoodEntry> entries,
      {required MealType? current, required MealType selected}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final logged = entries.isNotEmpty;
    final isCurrent = meal == current;
    final isSelected = meal == selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _picked = meal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: logged
                  ? LabelColors.proteinOf(dark)
                  : isSelected
                      ? LabelColors.blueOf(dark)
                      : fill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: logged
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : LabelColors.inkSoftOf(dark),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mealLabel(context, meal),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected || isCurrent
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: isSelected
                  ? LabelColors.inkOf(dark)
                  : LabelColors.inkSoftOf(dark),
            ),
          ),
        ],
      ),
    );
  }
}
