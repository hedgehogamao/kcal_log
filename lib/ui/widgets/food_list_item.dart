import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/food_category.dart';
import '../../logic/i18n.dart';
import '../theme.dart';

/// 搜索和食物库共用的信息卡：名称与热量优先，宏量营养不再挤在一行里。
class FoodListItem extends StatelessWidget {
  const FoodListItem({
    super.key,
    required this.food,
    this.onTap,
    this.onFavorite,
    this.menu,
    this.compact = false,
  });

  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final Widget? menu;

  /// Dialog results use the entire available width and stack energy below name.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final source = switch (food.source) {
      'off' => 'OFF',
      'builtin' => tr(context, 'sourceBuiltin'),
      _ => tr(context, 'sourceCustom'),
    };
    final detail = [
      FoodCategory.fromCode(food.category).label(context),
      source,
      if (food.brand != null && food.brand!.trim().isNotEmpty) food.brand!,
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 0 : 16, 0, compact ? 0 : 16, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${round1(food.kcal100)} kcal',
                    style: numberStyle(17, LabelColors.energyOf(dark)),
                  ),
                  Text(
                    '$detail · ${tr(context, 'per100g')}',
                    style: captionStyle(context),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${round1(food.kcal100)} kcal',
                        style: numberStyle(17, LabelColors.energyOf(dark)),
                      ),
                    ],
                  ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: captionStyle(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(context, 'per100g'),
                        style: captionStyle(context),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: food.protein100 + food.fat100 + food.carb100 == 0
                          ? Text(
                              tr(context, 'caloriesOnly'),
                              style: captionStyle(context),
                            )
                          : Wrap(
                              spacing: 10,
                              runSpacing: 2,
                              children: [
                                _macro(
                                  context,
                                  tr(context, 'proteinShort'),
                                  food.protein100,
                                  LabelColors.proteinOf(dark),
                                ),
                                _macro(
                                  context,
                                  tr(context, 'fatShort'),
                                  food.fat100,
                                  LabelColors.fatOf(dark),
                                ),
                                _macro(
                                  context,
                                  tr(context, 'carbShort'),
                                  food.carb100,
                                  LabelColors.carbOf(dark),
                                ),
                              ],
                            ),
                    ),
                    if (onFavorite != null)
                      IconButton(
                        tooltip: tr(
                          context,
                          food.favorite ? 'favRemove' : 'favAdd',
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavorite,
                        icon: Icon(
                          food.favorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: food.favorite ? LabelColors.fatOf(dark) : null,
                          size: 21,
                        ),
                      ),
                    ?menu,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macro(
    BuildContext context,
    String label,
    double grams,
    Color color,
  ) => Text(
    '$label ${round1(grams)}g',
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
  );
}
