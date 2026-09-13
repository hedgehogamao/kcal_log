import 'package:flutter/material.dart';

import '../theme.dart';

/// 分段控件：选中块（白底圆角）跟随位移滑动。
/// 配合 PageView 使用可实现「内容区同步横向切换」。
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    var i = segments.indexWhere((s) => s.$1 == selected);
    if (i < 0) i = 0;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / segments.length;
        return Stack(
          children: [
            // 选中块：跟随位移
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              left: i * segW,
              width: segW,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? LabelColors.dCard : LabelColors.card,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  for (final (key, label) in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(key),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: key == selected
                                  ? LabelColors.inkOf(dark)
                                  : LabelColors.inkSoftOf(dark),
                            ),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
