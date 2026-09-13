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
              activeColor:
                  over ? LabelColors.errorOf(dark) : LabelColors.energyOf(dark),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  _ActivityRingPainter({
    required this.progress,
    required this.activeColor,
  });

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
                          child: ColoredBox(color: pC)),
                      const SizedBox(width: 1.5),
                      Expanded(
                          flex: (kF * 100).round(),
                          child: ColoredBox(color: fC)),
                      const SizedBox(width: 1.5),
                      Expanded(
                          flex: (kC * 100).round(),
                          child: ColoredBox(color: cC)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _chip(tr(context, 'proteinShort'), protein, goals?.$1, pC, soft, labelC),
            _chip(tr(context, 'fatShort'), fat, goals?.$2, fC, soft, labelC),
            _chip(tr(context, 'carbShort'), carb, goals?.$3, cC, soft, labelC),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, double value, double? goal, Color dot,
      Color soft, Color labelC) {
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
                  style: TextStyle(fontSize: 12, height: 1.0, color: soft)),
              TextSpan(
                text: ' ${round1(value)}g',
                style: TextStyle(
                    fontSize: 12, height: 1.0, fontWeight: FontWeight.w600,
                    color: labelC),
              ),
              if (goal != null && goal > 0)
                TextSpan(
                    text: ' / ${round1(goal)}g',
                    style: TextStyle(fontSize: 12, height: 1.0, color: soft)),
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
  });

  final List<double> values;
  final List<String> xLabels;
  final double? goal;
  final String? goalLabel;
  final Color? color;
  final String yUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: const Size(double.infinity, 190),
      painter: _LinePainter(
        values: values,
        xLabels: xLabels,
        goal: goal,
        goalLabel: goalLabel,
        color: color ?? scheme.secondary,
        labelColor: scheme.onSurfaceVariant,
        gridColor: scheme.surfaceContainerHighest,
        yUnit: yUnit,
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
    required this.labelColor,
    required this.gridColor,
    required this.yUnit,
  });

  final List<double> values;
  final List<String> xLabels;
  final double? goal;
  final String? goalLabel;
  final Color color;
  final Color labelColor;
  final Color gridColor;
  final String yUnit;

  static const _left = 44.0, _top = 10.0, _right = 8.0, _bottom = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);
    if (values.isEmpty || chart.width <= 0) return;

    double lo = goal ?? double.infinity;
    double hi = goal ?? double.negativeInfinity;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (hi - lo < 1) {
      hi += 10;
      lo -= 10;
    }
    final pad = (hi - lo) * 0.12;
    hi += pad;
    lo -= pad;

    double x(int i) => chart.left +
        (values.length == 1 ? chart.width / 2 : chart.width * i / (values.length - 1));
    double y(double v) => chart.bottom - (v - lo) / (hi - lo) * chart.height;

    // 网格与 Y 轴标签
    final grid = Paint()
      ..strokeWidth = 1
      ..color = gridColor;
    final labelStyle = TextStyle(fontSize: 10, color: labelColor);
    for (final v in [hi, (hi + lo) / 2, lo]) {
      canvas.drawLine(Offset(chart.left, y(v)), Offset(chart.right, y(v)), grid);
      _text(canvas, '${_fmt(v)}$yUnit', Offset(4, y(v) - 6), labelStyle);
    }

    // 目标虚线
    if (goal != null) {
      final gp = Paint()
        ..strokeWidth = 1.4
        ..color = color.withAlpha(140);
      for (double dx = chart.left; dx < chart.right; dx += 10) {
        canvas.drawLine(Offset(dx, y(goal!)), Offset(math.min(dx + 5, chart.right), y(goal!)), gp);
      }
      if (goalLabel != null) {
        _text(canvas, goalLabel!, Offset(chart.right - 74, y(goal!) - 16),
            TextStyle(fontSize: 10, color: labelColor));
      }
    }

    // 折线（Apple Health 风：无圆点、圆润描边）
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(x(i), y(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(path, line);

    // X 轴标签：首/中/尾
    if (xLabels.isNotEmpty) {
      _text(canvas, xLabels.first, Offset(chart.left, chart.bottom + 6), labelStyle);
      if (xLabels.length > 4) {
        final mid = xLabels[xLabels.length ~/ 2];
        final tp = TextPainter(
          text: TextSpan(text: mid, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((chart.left + chart.right) / 2 - tp.width / 2, chart.bottom + 6));
      }
      if (xLabels.length > 1) {
        final tp = TextPainter(
          text: TextSpan(text: xLabels.last, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(chart.right - tp.width, chart.bottom + 6));
      }
    }
  }

  String _fmt(double v) {
    if (v.abs() >= 100) return v.round().toString();
    return round1(v).toString();
  }

  void _text(Canvas canvas, String s, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.goal != goal || old.color != color;
}

/// GitHub 风格日历热力图（每列一周，最后一列为当前周）
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.ratioByDate,
    required this.today,
    this.weeks = 10,
  });

  final Map<String, double> ratioByDate; // dateKey -> 摄入/目标
  final DateTime today;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final empty = Theme.of(context).colorScheme.surfaceContainerHighest;
    final full = LabelColors.proteinOf(dark);
    final over = LabelColors.energyOf(dark);
    final days = List<DateTime?>.generate(
      weeks * 7,
      (i) {
        final diff = weeks * 7 - 1 - i;
        final d = today.subtract(Duration(days: diff));
        return d.isAfter(today) ? null : d;
      },
    );
    // 让“今天”处于最后一列最后一行
    final leadingPad = List<DateTime?>.filled(6 - ((days.length - 1) % 7), null);
    final cells = [...leadingPad, ...days];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var w = 0; w < weeks; w++)
              Column(
                children: [
                  for (var j = 0; j < 7; j++)
                    Builder(builder: (context) {
                      final cell = cells[w * 7 + j];
                      final color = _colorFor(cell, empty, full, over);
                      return Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      );
                    }),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(tr(context, 'less'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 4),
            for (final c in [
              empty,
              full.withAlpha(70),
              full.withAlpha(150),
              full,
              over,
            ])
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            const SizedBox(width: 4),
            Text(tr(context, 'more'), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Color _colorFor(DateTime? d, Color empty, Color full, Color over) {
    if (d == null) return empty.withAlpha(90);
    final ratio = ratioByDate[dateKey(d)];
    if (ratio == null) return empty;
    if (ratio > 1.08) return over;
    if (ratio > 0.9) return full;
    if (ratio > 0.6) return full.withAlpha(150);
    if (ratio > 0.25) return full.withAlpha(90);
    return full.withAlpha(50);
  }
}
