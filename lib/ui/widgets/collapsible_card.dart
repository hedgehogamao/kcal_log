import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// 折叠卡片：高度、内容透明度、箭头角度三者由同一个控制器、
/// 同一条缓动曲线（easeInOutCubic）驱动。
///
/// [header] 是整行自定义头部（餐次名、小计、附加按钮等），
/// 卡片自动在其末尾追加带角度动画的折叠箭头。
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = true,
    this.contentPadding = const EdgeInsets.fromLTRB(14, 0, 14, 14),
  });

  final Widget header;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry contentPadding;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.initiallyExpanded ? 1 : 0,
  );

  // 高度 / 透明度 / 箭头角度共用这一条曲线
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_c.status == AnimationStatus.completed) {
      _c.reverse();
    } else {
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Material 而非带色 Container：ListTile 的墨水涟漪才有落点
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 10, 4),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  AnimatedBuilder(
                    animation: _t,
                    builder: (context, _) => Transform.rotate(
                      angle: _t.value * math.pi,
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: LabelColors.inkSoftOf(dark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _t,
            builder: (context, _) => ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _t.value.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: _t.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: widget.contentPadding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
