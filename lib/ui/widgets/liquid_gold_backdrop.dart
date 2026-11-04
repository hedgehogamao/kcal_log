import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// One decorative canvas below the entire app. Content never follows its motion.
class LiquidGoldScene extends StatelessWidget {
  const LiquidGoldScene({super.key, required this.child, this.animate = true});
  final Widget child;
  final bool animate;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return child;
    return LiquidGoldBackdrop(
      animate: animate,
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: LabelColors.dPaper.withValues(alpha: .95),
          ),
          cardTheme: theme.cardTheme.copyWith(
            color: LabelColors.dCard.withValues(alpha: .94),
          ),
          navigationRailTheme: theme.navigationRailTheme.copyWith(
            backgroundColor: LabelColors.dPaper.withValues(alpha: .92),
          ),
          navigationBarTheme: theme.navigationBarTheme.copyWith(
            backgroundColor: LabelColors.dCard.withValues(alpha: .98),
          ),
        ),
        child: child,
      ),
    );
  }
}

class LiquidGoldBackdrop extends StatefulWidget {
  const LiquidGoldBackdrop({
    super.key,
    required this.child,
    this.animate = true,
  });
  final Widget child;

  /// False supports static embeds/previews; user-facing app defaults to motion.
  final bool animate;
  @override
  State<LiquidGoldBackdrop> createState() => _LiquidGoldBackdropState();
}

class _LiquidGoldBackdropState extends State<LiquidGoldBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  late AppLifecycleState _lifecycle;
  bool _allowed = false;
  @override
  void initState() {
    super.initState();
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowed =
        Theme.of(context).brightness == Brightness.dark &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(LiquidGoldBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _sync();
  }

  void _sync() {
    final play =
        widget.animate && _allowed && _lifecycle == AppLifecycleState.resumed;
    if (play && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!play && _clock.isAnimating) {
      _clock.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey('liquid-gold-canvas'),
                  painter: LiquidGoldPainter(animation: _clock),
                  isComplex: true,
                  willChange:
                      widget.animate &&
                      _allowed &&
                      _lifecycle == AppLifecycleState.resumed,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// Deterministic, seamless fluid ribbons and metallic filaments. No blur,
/// bitmap downloads or per-frame widget rebuilds; only the canvas repaints.
class LiquidGoldPainter extends CustomPainter {
  LiquidGoldPainter({required this.animation}) : super(repaint: animation);
  final Animation<double> animation;
  double get phase => animation.value;
  static double ribbonY(double x, int band, Size size, double phase) {
    final angle = phase * math.pi * 2;
    final direction = band.isEven ? 1.0 : -1.0;
    return size.height *
        (.17 +
            band * .31 -
            .28 * (x - .5) +
            .065 *
                math.sin(x * 2.8 * math.pi + angle * direction + band * 1.7) +
            .035 * math.sin(x * 5.2 * math.pi - angle + band));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final angle = phase * math.pi * 2;
    canvas.drawRect(rect, Paint()..color = LabelColors.dPaper);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(math.sin(angle) * .6, math.cos(angle) * .4),
          radius: 1.1,
          colors: [
            LabelColors.goldDark.withValues(alpha: .075),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    for (var band = 0; band < 3; band++) {
      final upper = <Offset>[], lower = <Offset>[];
      for (var step = 0; step <= 64; step++) {
        final x = -.1 + step / 64 * 1.2;
        final y = ribbonY(x, band, size, phase);
        final thickness =
            size.height *
            (.022 + .018 * (1 + math.sin(x * 3 * math.pi + angle + band)));
        upper.add(Offset(x * size.width, y));
        lower.add(Offset(x * size.width, y + thickness));
      }
      final ribbon = Path()..moveTo(upper.first.dx, upper.first.dy);
      for (final point in upper.skip(1)) {
        ribbon.lineTo(point.dx, point.dy);
      }
      for (final point in lower.reversed) {
        ribbon.lineTo(point.dx, point.dy);
      }
      ribbon.close();
      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-1, -.8 + .2 * math.sin(angle)),
            end: const Alignment(1, 1),
            colors: [
              const Color(0xFF17130C),
              const Color(0xFF86602A).withValues(alpha: .72),
              const Color(0xFFD3AE69).withValues(alpha: .78),
              const Color(0xFFFFE8AE).withValues(alpha: .72),
              const Color(0xFF73501E).withValues(alpha: .65),
              const Color(0xFF15120D),
            ],
            stops: const [0, .27, .46, .50, .57, 1],
          ).createShader(rect),
      );
      for (var filament = 0; filament < 3; filament++) {
        final line = Path();
        for (var step = 0; step <= 64; step++) {
          final x = -.1 + step / 64 * 1.2;
          final y =
              ribbonY(x, band, size, phase) +
              filament * 3.5 +
              2 * math.sin(x * 8 + angle + filament);
          if (step == 0) {
            line.moveTo(x * size.width, y);
          } else {
            line.lineTo(x * size.width, y);
          }
        }
        canvas.drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = filament == 0 ? 1.35 : .65
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                LabelColors.goldDark.withValues(
                  alpha: filament == 0 ? .68 : .26,
                ),
                const Color(0xFFFFE8AE)
                    .withValues(alpha: filament == 0 ? .60 : .18),
                Colors.transparent,
              ],
              stops: const [0, .38, .60, 1],
            ).createShader(rect),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LiquidGoldPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
