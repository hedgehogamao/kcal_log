import 'package:flutter/material.dart';

/// Retains only visited destinations; inactive pages cannot animate, focus,
/// receive input or expose semantics. Keyboard/reduced-motion changes are instant.
class MotionPageStack extends StatefulWidget {
  const MotionPageStack({
    super.key,
    required this.index,
    required this.pages,
    this.animate = true,
  });
  final int index;
  final List<Widget> pages;
  final bool animate;
  @override
  State<MotionPageStack> createState() => _MotionPageStackState();
}

class _MotionPageStackState extends State<MotionPageStack>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final Set<int> _visited = {widget.index};
  double _direction = 1;
  bool get _reduce =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  @override
  void didUpdateWidget(MotionPageStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _visited.add(widget.index);
      _direction = widget.index > oldWidget.index ? 1 : -1;
      if (_reduce || !widget.animate) {
        _motion.value = 1;
      } else {
        _motion.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce) _motion.value = 1;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < widget.pages.length; i++)
            Offstage(
              key: ValueKey('destination-$i'),
              offstage: i != widget.index,
              child: _visited.contains(i)
                  ? TickerMode(
                      enabled: i == widget.index,
                      child: Focus(
                        canRequestFocus: i == widget.index,
                        skipTraversal: true,
                        descendantsAreFocusable: i == widget.index,
                        child: AnimatedBuilder(
                          animation: _motion,
                          child: widget.pages[i],
                          builder: (context, child) {
                            final progress = _reduce || i != widget.index
                                ? 1.0
                                : Curves.easeOutCubic.transform(_motion.value);
                            return Transform.translate(
                              key: ValueKey('destination-motion-$i'),
                              offset: Offset(
                                (1 - progress) * 12 * _direction * rtl,
                                0,
                              ),
                              child: Opacity(
                                opacity: .94 + .06 * progress,
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
