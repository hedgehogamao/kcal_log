import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 可翻转卡片：正面核心信息、背面规则说明。
/// 旋转角超过 90° 的瞬间换面（背面预先镜像，保证文字始终正向可读）。
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 620),
  });

  final Widget front;
  final Widget back;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  void _flip() {
    if (_c.status == AnimationStatus.completed) {
      _c.reverse();
    } else {
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final angle = _t.value * math.pi;
          final showFront = angle < math.pi / 2; // 中途换面
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016) // 透视
              ..rotateY(angle),
            child: showFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}
