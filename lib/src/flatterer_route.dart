/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/geometry.dart';
import 'package:flatterer/src/indicate_border.dart';
import 'package:flutter/material.dart';

/// Created by changlei on 2020/8/6.
///
/// 追随锚点控件的动态弹窗
class FlattererRoute<T> extends PageRoute<T> {
  /// 追随锚点控件的动态弹窗
  FlattererRoute(
    this.builder,
    this.anchor, {
    this.offset = 0,
    this.direction = Axis.vertical,
    this.indicateSize = defaultIndicateSize,
    this.margin = defaultMargin,
    this.alignment = 0,
    this.bounds,
    this.backgroundColor = Colors.white,
    this.borderRadius = defaultBorderRadius,
    this.shadows = defaultShadows,
    this.side = defaultSide,
    this.barrierDismissible = true,
    this.barrierColor,
    this.preferBelow = true,
    @required this.capturedThemes,
    RouteSettings settings,
  })  : assert(builder != null),
        assert(anchor != null),
        assert(offset != null),
        assert(direction != null),
        assert(indicateSize != null),
        assert(margin != null),
        assert(alignment != null),
        assert(backgroundColor != null),
        assert(borderRadius != null),
        assert(shadows != null),
        assert(side != null),
        assert(barrierDismissible != null),
        assert(preferBelow != null),
        assert(capturedThemes != null),
        super(
          settings: settings,
        );

  /// 构建显示内容
  final WidgetBuilder builder;

  /// 锚点
  final Rect anchor;

  /// 水平或垂直方向上的偏移量
  final double offset;

  /// 显示的方向，上下结构和左右结构
  final Axis direction;

  /// 三角指示器的大小
  final Size indicateSize;

  /// 距离屏幕或者[boundsSize]的距离
  final double margin;

  /// 对齐方式，[-1,1]，0为居中，-1为最左边，1为最右边
  final double alignment;

  /// 边界，也可以是随意指定，限制弹窗的范围
  final Rect bounds;

  /// 窗口背景颜色
  final Color backgroundColor;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 阴影
  final List<BoxShadow> shadows;

  /// The border outline's color and weight.
  ///
  /// If [side] is [BorderSide.none], which is the default, an outline is not drawn.
  /// Otherwise the outline is centered over the shape's boundary.
  final BorderSide side;

  /// 优先显示在末尾
  final bool preferBelow;

  /// 样式
  final CapturedThemes capturedThemes;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  String get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Builder(
      builder: (context) {
        return CustomSingleChildLayout(
          delegate: _FlattererLayoutDelegate(
            anchor,
            offset + indicateSize.height,
            direction,
            margin,
            alignment,
            bounds: bounds,
            preferBelow: preferBelow,
          ),
          child: _Flatterer(
            anchor: anchor,
            direction: direction,
            indicateSize: indicateSize,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            shadows: shadows,
            side: side,
            child: capturedThemes.wrap(builder(context)),
          ),
        );
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      ),
      child: child,
    );
  }

  @override
  Duration get transitionDuration => fadeDuration;

  @override
  bool get maintainState => true;
}

class _Flatterer extends StatelessWidget {
  const _Flatterer({
    Key key,
    @required this.child,
    @required this.anchor,
    @required this.direction,
    @required this.indicateSize,
    @required this.backgroundColor,
    @required this.borderRadius,
    @required this.shadows,
    @required this.side,
  })  : assert(child != null),
        assert(anchor != null),
        assert(direction != null),
        assert(indicateSize != null),
        assert(backgroundColor != null),
        assert(borderRadius != null),
        assert(shadows != null),
        assert(side != null),
        super(key: key);

  final Widget child;
  final Rect anchor;
  final Axis direction;
  final Size indicateSize;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow> shadows;

  /// The border outline's color and weight.
  ///
  /// If [side] is [BorderSide.none], which is the default, an outline is not drawn.
  /// Otherwise the outline is centered over the shape's boundary.
  final BorderSide side;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: IndicateBorder(
            borderRadius: borderRadius,
            indicateSize: indicateSize,
            direction: direction,
            anchor: anchor,
            side: side,
          ),
          shadows: shadows,
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: child,
        ),
      ),
    );
  }
}

class _FlattererLayoutDelegate extends SingleChildLayoutDelegate {
  _FlattererLayoutDelegate(
    this.anchor,
    this.offset,
    this.direction,
    this.margin,
    this.alignment, {
    this.bounds,
    this.preferBelow = true,
  });

  final Rect bounds;
  final Rect anchor;
  final double offset;
  final Axis direction;
  final double margin;
  final double alignment;
  final bool preferBelow;

  @override
  Size getSize(BoxConstraints constraints) {
    return bounds?.size ?? super.getSize(constraints);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(EdgeInsets.all(margin));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final boundsOffset = _computeBoundsOffset(direction, bounds);
    final childOffset = positionDependentBoxPopupWindow(
      size: bounds?.size ?? size,
      childSize: childSize,
      target: anchor.shift(-boundsOffset).center,
      offset: _offset,
      margin: margin,
      preferBelow: preferBelow,
      direction: direction,
      alignment: alignment,
    );
    return childOffset + boundsOffset;
  }

  double get _offset {
    return offset + (direction == Axis.vertical ? anchor.height : anchor.width) / 2;
  }

  @override
  bool shouldRelayout(_FlattererLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        offset != oldDelegate.offset ||
        direction != oldDelegate.direction ||
        margin != oldDelegate.margin ||
        alignment != oldDelegate.alignment ||
        bounds != oldDelegate.bounds;
  }

  Offset _computeBoundsOffset(Axis direction, Rect bounds) {
    if (bounds == null) {
      return Offset.zero;
    }
    return direction == Axis.horizontal ? Offset(0, bounds.top) : Offset(bounds.left, 0);
  }
}
