import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../theme.dart';

/// Four meal states, with a direct recording action for the selected meal.
class MealProgressCard extends StatefulWidget {
  const MealProgressCard({
    super.key,
    required this.entries,
    required this.isToday,
    required this.useKj,
    this.onAdd,
  });
  final List<FoodEntry> entries;
  final bool isToday;
  final bool useKj;
  final ValueChanged<MealType>? onAdd;
  @override
  State<MealProgressCard> createState() => _MealProgressCardState();
}

class _MealProgressCardState extends State<MealProgressCard> {
  MealType? _picked;
  @override
  Widget build(BuildContext context) {
    final current = widget.isToday ? currentMealType() : null;
    final selected = _picked ?? current ?? MealType.breakfast;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final byMeal = {for (final meal in MealType.values) meal: <FoodEntry>[]};
    for (final entry in widget.entries) {
      byMeal[entry.meal]!.add(entry);
    }
    final pickedEntries = byMeal[selected]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final grid =
                    constraints.maxWidth < 270 ||
                    MediaQuery.textScalerOf(context).scale(13) > 19.5;
                if (grid) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final meal in MealType.values)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _node(
                            context,
                            meal,
                            byMeal[meal]!,
                            selected: selected,
                            current: current,
                            horizontal: true,
                          ),
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (final (i, meal) in MealType.values.indexed) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: i <= selected.index
                                  ? LabelColors.blueOf(dark)
                                  : fill,
                            ),
                          ),
                        ),
                      _node(
                        context,
                        meal,
                        byMeal[meal]!,
                        selected: selected,
                        current: current,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Container(
                key: ValueKey(selected),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          mealLabel(context, selected),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (selected == current)
                          Text(
                            tr(context, 'mealNow'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: LabelColors.blueOf(dark)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickedEntries.isEmpty
                          ? tr(context, 'empty')
                          : '${tr(context, pickedEntries.length == 1 ? 'itemsOne' : 'items', {'n': '${pickedEntries.length}'})} · '
                                '${fmtEnergy(pickedEntries.fold(0.0, (sum, e) => sum + e.kcal), widget.useKj)} ${energyUnit(widget.useKj)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (widget.onAdd != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('meal-progress-add'),
                        onPressed: () => widget.onAdd!(selected),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          tr(context, 'addTo', {
                            'meal': mealLabel(context, selected),
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _node(
    BuildContext context,
    MealType meal,
    List<FoodEntry> entries, {
    required MealType selected,
    required MealType? current,
    bool horizontal = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final logged = entries.isNotEmpty;
    final picked = meal == selected;
    final marker = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: logged
            ? LabelColors.proteinOf(dark)
            : picked
            ? LabelColors.blueOf(dark)
            : fill,
      ),
      child: Icon(
        logged ? Icons.check : Icons.circle,
        size: logged ? 16 : 8,
        color: logged || picked ? Colors.white : LabelColors.inkSoftOf(dark),
      ),
    );
    final label = Text(
      mealLabel(context, meal),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: picked || meal == current
            ? FontWeight.w600
            : FontWeight.w400,
        color: picked ? LabelColors.inkOf(dark) : LabelColors.inkSoftOf(dark),
      ),
    );
    return Semantics(
      button: true,
      selected: picked,
      child: InkWell(
        key: ValueKey('meal-node-${meal.name}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _picked = meal),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: horizontal
                ? Row(
                    children: [
                      marker,
                      const SizedBox(width: 6),
                      Expanded(child: label),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [marker, const SizedBox(height: 6), label],
                  ),
          ),
        ),
      ),
    );
  }
}
