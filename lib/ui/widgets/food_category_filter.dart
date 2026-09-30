import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../logic/food_category.dart';
import '../../logic/i18n.dart';

/// All categories are reachable from one control; the current selection never
/// scrolls out of view. Clearing a category preserves the search and source.
class FoodCategoryFilter extends StatelessWidget {
  const FoodCategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FoodCategory? selected;
  final ValueChanged<FoodCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: tr(context, 'foodCategory'),
            initialValue: selected?.code ?? 'all',
            onSelected: (code) =>
                onChanged(code == 'all' ? null : FoodCategory.fromCode(code)),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'all',
                checked: selected == null,
                child: Text(tr(context, 'allCategories')),
              ),
              for (final category in FoodCategory.values)
                CheckedPopupMenuItem(
                  value: category.code,
                  checked: selected == category,
                  child: Text(category.label(context)),
                ),
            ],
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.square_grid_2x2, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected?.label(context) ?? tr(context, 'allCategories'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 14),
                ],
              ),
            ),
          ),
        ),
        if (selected != null)
          IconButton(
            tooltip: tr(context, 'clearCategory'),
            onPressed: () => onChanged(null),
            icon: const Icon(CupertinoIcons.xmark_circle, size: 22),
          ),
      ],
    );
  }
}
