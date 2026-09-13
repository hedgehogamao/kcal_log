import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// 滑动确认条：滑过 80% 才触发，不足则带回弹动画返回起点。
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.successLabel,
    required this.onConfirm,
  });

  final String label;
  final String successLabel;
  final VoidCallback onConfirm;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const _thumb = 40.0;
  static const _threshold = 0.8;

  double _p = 0; // 0..1
  bool _done = false;
  double _fromP = 0;
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    _settle.addListener(_onSettle);
  }

  void _onSettle() {
    if (!_settle.isAnimating) return;
    setState(() {
      // easeOutCubic：快速启动、平缓落回 0
      _p = _fromP * (1 - Curves.easeOutCubic.transform(_settle.value));
    });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _springBack() {
    if (_p <= 0) return;
    _fromP = _p;
    _settle.forward(from: 0);
  }

  void _finish() {
    setState(() {
      _done = true;
      _p = 1;
    });
    // 等选中块落到最右端再回调
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) widget.onConfirm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ok = LabelColors.proteinOf(dark);
    final accent = _done ? ok : LabelColors.blueOf(dark);

    return LayoutBuilder(builder: (context, c) {
      final maxDx = math.max(0.0, c.maxWidth - _thumb - 4);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _done ? null : (_) => _settle.stop(),
        onHorizontalDragUpdate: _done
            ? null
            : (d) => setState(() {
                  _p = (_p + d.delta.dx / maxDx).clamp(0.0, 1.0);
                }),
        onHorizontalDragEnd: _done
            ? null
            : (_) {
                if (_p >= _threshold) {
                  _finish();
                } else {
                  _springBack();
                }
              },
        onHorizontalDragCancel: _done ? null : _springBack,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _done
                ? ok.withValues(alpha: 0.14)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: _done
                        ? 1
                        : (1 - _p * 1.4).clamp(0.0, 1.0),
                    child: Text(
                      _done ? widget.successLabel : widget.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _done ? ok : LabelColors.inkSoftOf(dark),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 2 + _p.clamp(0.0, 1.0) * maxDx,
                  top: 2,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Icon(
                      _done
                          ? CupertinoIcons.check_mark
                          : CupertinoIcons.chevron_right_2,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
