import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../theme.dart';

/// 签名元素：Apple Fitness 活动圆环。
/// 粗描边圆环从 12 点方向顺时针填充，底轨为同色低透明度。
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.progress,
    this.size = 132,
    this.center,
  });

  /// 已摄入 / 目标，>1 表示超标
  final double progress;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final over = progress > 1;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ActivityRingPainter(
              progress: clamp01(progress),
              activeColor: over
                  ? LabelColors.errorOf(dark)
                  : LabelColors.energyOf(dark),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  _ActivityRingPainter({required this.progress, required this.activeColor});

  final double progress;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.085;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.shortestSide - stroke,
      size.shortestSide - stroke,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = activeColor.withValues(alpha: 0.15);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (progress > 0) {
      final active = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = activeColor;
      // 从 12 点方向顺时针
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, active);
    }
  }

  @override
  bool shouldRepaint(_ActivityRingPainter old) =>
      old.progress != progress || old.activeColor != activeColor;
}

/// 宏量营养：堆叠比例条 + 三色图例（Apple Health 配色）
class MacroBars extends StatelessWidget {
  const MacroBars({
    super.key,
    required this.protein,
    required this.fat,
    required this.carb,
    this.goals,
  });

  final double protein;
  final double fat;
  final double carb;

  /// (蛋白质g, 脂肪g, 碳水g) 目标，可为空
  final (double?, double?, double?)? goals;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rule = Theme.of(context).colorScheme.surfaceContainerHighest;
    final soft = Theme.of(context).colorScheme.onSurfaceVariant;
    final labelC = Theme.of(context).colorScheme.onSurface;
    final pC = LabelColors.proteinOf(dark);
    final fC = LabelColors.fatOf(dark);
    final cC = LabelColors.carbOf(dark);

    final kP = protein * 4, kF = fat * 9, kC = carb * 4;
    final total = kP + kF + kC;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: total <= 0
                ? ColoredBox(color: rule)
                : Row(
                    children: [
                      Expanded(
                        flex: (kP * 100).round(),
                        child: ColoredBox(color: pC),
                      ),
                      const SizedBox(width: 1.5),
                      Expanded(
                        flex: (kF * 100).round(),
                        child: ColoredBox(color: fC),
                      ),
                      const SizedBox(width: 1.5),
                      Expanded(
                        flex: (kC * 100).round(),
                        child: ColoredBox(color: cC),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _chip(
              tr(context, 'proteinShort'),
              protein,
              goals?.$1,
              pC,
              soft,
              labelC,
            ),
            _chip(tr(context, 'fatShort'), fat, goals?.$2, fC, soft, labelC),
            _chip(tr(context, 'carbShort'), carb, goals?.$3, cC, soft, labelC),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    double value,
    double? goal,
    Color dot,
    Color soft,
    Color labelC,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(fontSize: 12, height: 1.0, color: soft),
                ),
                TextSpan(
                  text: ' ${round1(value)}g',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                    color: labelC,
                  ),
                ),
                if (goal != null && goal > 0)
                  TextSpan(
                    text: ' / ${round1(goal)}g',
                    style: TextStyle(fontSize: 12, height: 1.0, color: soft),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 简易折线图（含目标虚线），无第三方依赖
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.values,
    required this.xLabels,
    this.goal,
    this.goalLabel,
    this.color,
    this.yUnit = '',
    this.zeroBaseline = false,
  });
  final List<double?> values;
  final List<String> xLabels;
  final double? goal;
  final String? goalLabel;
  final Color? color;
  final String yUnit;
  final bool zeroBaseline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final description = [
      for (var i = 0; i < values.length; i++)
        '${i < xLabels.length ? xLabels[i] : i + 1}: ${values[i] == null ? tr(context, 'notLogged') : '${round1(values[i]!)} $yUnit'}',
    ].join('; ');
    return Semantics(
      image: true,
      label: description,
      child: SizedBox(
        height: 190 + (scaler.scale(12) - 12).clamp(0, 48) * 4,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(
            values: values,
            xLabels: xLabels,
            goal: goal,
            goalLabel: goalLabel,
            color: color ?? theme.colorScheme.secondary,
            labelStyle: theme.textTheme.bodySmall!.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            gridColor: theme.colorScheme.surfaceContainerHighest,
            yUnit: yUnit,
            scaler: scaler,
            direction: Directionality.of(context),
            zeroBaseline: zeroBaseline,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.xLabels,
    required this.goal,
    required this.goalLabel,
    required this.color,
    required this.labelStyle,
    required this.gridColor,
    required this.yUnit,
    required this.scaler,
    required this.direction,
    required this.zeroBaseline,
  });
  final List<double?> values;
  final List<String> xLabels;
  final double? goal;
  final String? goalLabel;
  final Color color;
  final TextStyle labelStyle;
  final Color gridColor;
  final String yUnit;
  final TextScaler scaler;
  final TextDirection direction;
  final bool zeroBaseline;

  TextPainter _label(String text, {double maxWidth = double.infinity}) =>
      TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
  String _fmt(double v) =>
      v.abs() >= 100 ? v.round().toString() : round1(v).toString();
  @override
  void paint(Canvas canvas, Size size) {
    final numbers = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    if (numbers.isEmpty) return;
    final validGoal = goal != null && goal!.isFinite ? goal : null;
    var lo = zeroBaseline ? 0.0 : numbers.reduce(math.min);
    var hi = numbers.reduce(math.max);
    if (validGoal != null) {
      lo = math.min(lo, validGoal);
      hi = math.max(hi, validGoal);
    }
    if ((hi - lo).abs() < 0.01) {
      hi += zeroBaseline ? 1 : 0.5;
      if (!zeroBaseline) lo -= 0.5;
    }
    final pad = (hi - lo) * 0.12;
    hi += pad;
    if (!zeroBaseline) lo -= pad;
    final ticks = [hi, (hi + lo) / 2, lo];
    var widest = 0.0;
    var height = 0.0;
    for (final tick in ticks) {
      final label = _label('${_fmt(tick)} $yUnit');
      widest = math.max(widest, label.width);
      height = math.max(height, label.height);
      label.dispose();
    }
    final left = math.min(size.width * 0.45, widest + 12);
    final chart = Rect.fromLTRB(
      left,
      height / 2 + 6,
      size.width - 8,
      size.height - height - 12,
    );
    if (chart.width <= 0 || chart.height <= 0) return;
    double x(int i) =>
        chart.left +
        (values.length == 1
            ? chart.width / 2
            : chart.width * i / (values.length - 1));
    double y(double v) => chart.bottom - (v - lo) / (hi - lo) * chart.height;
    final grid = Paint()
      ..strokeWidth = 1
      ..color = gridColor;
    for (final tick in ticks) {
      canvas.drawLine(
        Offset(chart.left, y(tick)),
        Offset(chart.right, y(tick)),
        grid,
      );
      final label = _label(
        '${_fmt(tick)} $yUnit',
        maxWidth: math.max(1, left - 8),
      );
      label.paint(canvas, Offset(0, y(tick) - label.height / 2));
      label.dispose();
    }
    if (validGoal != null) {
      final goalPaint = Paint()
        ..strokeWidth = 1.4
        ..color = color.withAlpha(140);
      for (var dx = chart.left; dx < chart.right; dx += 10) {
        canvas.drawLine(
          Offset(dx, y(validGoal)),
          Offset(math.min(dx + 5, chart.right), y(validGoal)),
          goalPaint,
        );
      }
      if (goalLabel != null) {
        final label = _label(goalLabel!, maxWidth: chart.width);
        label.paint(
          canvas,
          Offset(
            chart.right - label.width,
            math.max(0, y(validGoal) - label.height - 3),
          ),
        );
        label.dispose();
      }
    }
    final path = Path();
    var connected = false;
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null || !value.isFinite) {
        connected = false;
        continue;
      }
      final point = Offset(x(i), y(value));
      if (connected) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
      }
      connected = true;
      canvas.drawCircle(point, 2.5, dot);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    if (xLabels.isNotEmpty) {
      final first = _label(xLabels.first, maxWidth: chart.width / 2);
      first.paint(canvas, Offset(chart.left, chart.bottom + 6));
      if (xLabels.length > 1) {
        final last = _label(xLabels.last, maxWidth: chart.width / 2);
        last.paint(canvas, Offset(chart.right - last.width, chart.bottom + 6));
        if (xLabels.length > 4) {
          final mid = _label(xLabels[xLabels.length ~/ 2]);
          if (chart.width > first.width + last.width + mid.width + 24) {
            mid.paint(
              canvas,
              Offset(chart.center.dx - mid.width / 2, chart.bottom + 6),
            );
          }
          mid.dispose();
        }
        last.dispose();
      }
      first.dispose();
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.xLabels != xLabels ||
      old.goal != goal ||
      old.goalLabel != goalLabel ||
      old.color != color ||
      old.yUnit != yUnit ||
      old.labelStyle != labelStyle ||
      old.gridColor != gridColor ||
      old.scaler != scaler ||
      old.direction != direction ||
      old.zeroBaseline != zeroBaseline;
}

/// Ten calendar weeks aligned Monday–Sunday, with explicit missing-day labels.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.ratioByDate,
    required this.today,
    this.weeks = 10,
  });
  final Map<String, double> ratioByDate;
  final DateTime today;
  final int weeks;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final empty = Theme.of(context).colorScheme.surfaceContainerHighest;
    final full = LabelColors.proteinOf(dark);
    final over = LabelColors.energyOf(dark);
    final end = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: 7 - today.weekday));
    final start = end.subtract(Duration(days: weeks * 7 - 1));
    final labels = switch (LangScope.of(context)) {
      AppLang.zh => const ['一', '二', '三', '四', '五', '六', '日'],
      AppLang.es => const ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
      AppLang.en => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    };
    final cellHeight = math.max(
      18.0,
      MediaQuery.textScalerOf(context).scale(11) + 4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${dateKey(start)} – ${dateKey(today)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (final label in labels)
                  SizedBox(
                    height: cellHeight,
                    width: 22,
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(18.0, constraints.maxWidth / weeks);
                  return Row(
                    children: [
                      for (var w = 0; w < weeks; w++)
                        Column(
                          children: [
                            for (var day = 0; day < 7; day++)
                              Builder(
                                builder: (context) {
                                  final date = start.add(
                                    Duration(days: w * 7 + day),
                                  );
                                  final future = date.isAfter(
                                    DateTime(
                                      today.year,
                                      today.month,
                                      today.day,
                                    ),
                                  );
                                  final ratio = ratioByDate[dateKey(date)];
                                  final color = future || ratio == null
                                      ? empty
                                      : ratio > 1
                                      ? over
                                      : ratio > 0.9
                                      ? full
                                      : ratio > 0.6
                                      ? full.withAlpha(150)
                                      : ratio > 0.25
                                      ? full.withAlpha(90)
                                      : full.withAlpha(50);
                                  final cell = Container(
                                    width: math.max(1, width - 3),
                                    height: cellHeight - 3,
                                    margin: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: future
                                          ? Colors.transparent
                                          : color,
                                      borderRadius: BorderRadius.circular(3.5),
                                    ),
                                  );
                                  if (future) {
                                    return ExcludeSemantics(child: cell);
                                  }
                                  return Tooltip(
                                    message:
                                        '${dateKey(date)} · ${ratio == null ? tr(context, 'notLogged') : tr(context, 'goalPercent', {'n': '${(ratio * 100).round()}'})}',
                                    child: cell,
                                  );
                                },
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr(context, 'notLogged'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final c in [
              empty,
              full.withAlpha(50),
              full.withAlpha(150),
              full,
              over,
            ])
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            Text(
              tr(context, 'more'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
