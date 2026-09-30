import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Accessible range switch with a bounded intrinsic size even inside a Row.
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
    if (segments.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scaler = MediaQuery.textScalerOf(context);
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontSize: 13, fontWeight: FontWeight.w600);
    var labelWidth = 0.0;
    var labelHeight = 0.0;
    for (final (_, label) in segments) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      labelWidth = math.max(labelWidth, painter.width);
      labelHeight = math.max(labelHeight, painter.height);
      painter.dispose();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (labelWidth + 28) * segments.length + 4;
        final height = math.max(44.0, labelHeight * 2 + 16);
        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  for (final (key, label) in segments)
                    Expanded(
                      child: Semantics(
                        selected: key == selected,
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: key == selected
                                ? dark
                                      ? LabelColors.dCard
                                      : LabelColors.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: TextButton(
                            onPressed: () => onChanged(key),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: style,
                              foregroundColor: key == selected
                                  ? LabelColors.inkOf(dark)
                                  : LabelColors.inkSoftOf(dark),
                            ),
                            child: Text(label, textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
