import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Paint-only, reversible growth at either vertical viewport edge. No timers,
/// entrance delay or layout changes; no effect outside a vertical scroll view.
class ScrollScaleReveal extends StatelessWidget {
  const ScrollScaleReveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => _ScalePaint(
    position: Scrollable.maybeOf(context, axis: Axis.vertical)?.position,
    enabled:
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context),
    child: RepaintBoundary(child: child),
  );
}

class _ScalePaint extends SingleChildRenderObjectWidget {
  const _ScalePaint({
    required this.position,
    required this.enabled,
    required super.child,
  });
  final ScrollPosition? position;
  final bool enabled;
  @override
  RenderScrollScaleReveal createRenderObject(BuildContext context) =>
      RenderScrollScaleReveal(position, enabled);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderScrollScaleReveal renderObject,
  ) {
    renderObject
      ..position = position
      ..enabled = enabled;
  }
}

class RenderScrollScaleReveal extends RenderProxyBox {
  RenderScrollScaleReveal(this._position, this._enabled);
  ScrollPosition? _position;
  bool _enabled;
  set position(ScrollPosition? value) {
    if (identical(value, _position)) return;
    if (attached) _position?.removeListener(_scrollChanged);
    _position = value;
    if (attached) _position?.addListener(_scrollChanged);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void _scrollChanged() {
    if (_enabled) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position?.addListener(_scrollChanged);
  }

  @override
  void detach() {
    _position?.removeListener(_scrollChanged);
    super.detach();
  }

  double get scale {
    if (!_enabled || _position == null || !hasSize || size.isEmpty) return 1;
    final viewport = RenderAbstractViewport.maybeOf(parent);
    if (viewport is! RenderBox) return 1;
    final box = viewport as RenderBox;
    if (!box.hasSize) return 1;
    final bounds = MatrixUtils.transformRect(
      getTransformTo(box),
      Offset.zero & size,
    );
    final height = box.size.height;
    if (height <= 0) return 1;
    final visibleDepth = math.min(bounds.bottom, height - bounds.top);
    final ramp = math.min(120.0, math.min(size.height, height / 2));
    final progress = (visibleDepth / ramp).clamp(0.0, 1.0);
    return .94 + .06 * Curves.easeOutCubic.transform(progress);
  }

  Matrix4 get _paintTransform {
    return _transformFor(scale);
  }

  Matrix4 _transformFor(double s) {
    return Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
  }

  @override
  bool get alwaysNeedsCompositing => _enabled && child != null;
  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final factor = scale;
    if (factor == 1) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transformFor(factor),
      super.paint,
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _paintTransform,
        position: position,
        hitTest: (result, position) =>
            super.hitTestChildren(result, position: position),
      );
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_paintTransform);
  }
}
