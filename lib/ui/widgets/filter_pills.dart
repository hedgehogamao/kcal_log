import 'package:flutter/material.dart';

import '../theme.dart';

/// 筛选胶囊：选中态实底（蓝底白字），未选中灰底；
/// 数量多、超出宽度时整行横向滚动。
class FilterPills<T> extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: Semantics(
                button: true,
                selected: items[i].$1 == selected,
                label: items[i].$2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(items[i].$1),
                  child: AnimatedContainer(
                    constraints: const BoxConstraints(minHeight: 44),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: items[i].$1 == selected
                          ? LabelColors.blueOf(dark)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: items[i].$1 == selected
                            ? Colors.white
                            : LabelColors.inkOf(dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
