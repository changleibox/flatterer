/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/flatterer_route.dart';
import 'package:flatterer/src/geometry.dart';
import 'package:flutter/material.dart';

/// Created by changlei on 2020/7/27.
///
/// 跟随控件的弹出框的锚控件
class PopupWindowAnchor extends StatefulWidget {
  /// 跟随控件的弹出框
  const PopupWindowAnchor({
    Key? key,
    required this.child,
    required this.builder,
    this.offset = 0,
    this.direction = Axis.vertical,
    this.indicateSize = defaultIndicateSize,
    this.margin = defaultMargin,
    this.alignment = 0,
    this.backgroundColor = Colors.white,
    this.borderRadius = defaultBorderRadius,
    this.shadows = defaultShadows,
    this.side = defaultSide,
    this.barrierDismissible = true,
    this.barrierColor,
    this.preferBelow = true,
  })  : assert(alignment >= -1 && alignment <= 1),
        super(key: key);

  /// 对齐的child
  final Widget child;

  /// 弹出框的内容
  final WidgetBuilder builder;

  /// 相对位移
  final double offset;

  /// 三角形大小
  final Size indicateSize;

  /// 方向
  final Axis direction;

  /// 边距
  final double margin;

  /// 优先地位置，[[-1, 1]]
  final double alignment;

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

  /// 点击外部区域弹窗是否消失
  final bool barrierDismissible;

  /// 遮罩颜色
  final Color? barrierColor;

  /// 优先显示在末尾
  final bool preferBelow;

  @override
  PopupWindowAnchorState createState() => PopupWindowAnchorState();
}

/// 跟随控件的弹出框state
class PopupWindowAnchorState extends State<PopupWindowAnchor> {
  /// 显示
  ///
  /// [anchor]-锚点，在屏幕中的位置
  /// [bounds]-边界，在屏幕中的位置
  Future<T?> show<T>({Rect? anchor, Rect? bounds}) {
    return showPopupWindow<T>(
      context,
      anchor: anchor,
      bounds: bounds,
      builder: widget.builder,
      offset: widget.offset,
      indicateSize: widget.indicateSize,
      direction: widget.direction,
      margin: widget.margin,
      alignment: widget.alignment,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      side: widget.side,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
    );
  }

  /// 隐藏
  void hide<T>([T? result]) {
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 显示popupWindow
///
/// [anchor]-锚点，在屏幕中的位置
/// [bounds]-边界，在屏幕中的位置
Future<T?> showPopupWindow<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Rect? anchor,
  Rect? bounds,
  double offset = 0,
  Size indicateSize = defaultIndicateSize,
  Axis direction = Axis.vertical,
  double margin = defaultMargin,
  double alignment = 0,
  Color backgroundColor = Colors.white,
  BorderRadiusGeometry borderRadius = defaultBorderRadius,
  List<BoxShadow> shadows = defaultShadows,
  BorderSide side = defaultSide,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  Color? barrierColor,
  RouteSettings? settings,
  bool preferBelow = true,
}) {
  assert(margin >= 0);
  assert(alignment.abs() <= 1);
  final navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  return navigator.push<T>(
    FlattererRoute<T>(
      builder,
      anchor ?? localToGlobal(context),
      offset: offset,
      direction: direction,
      indicateSize: indicateSize,
      margin: margin,
      alignment: alignment,
      bounds: bounds,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      shadows: shadows,
      side: side,
      preferBelow: preferBelow,
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      settings: settings,
    ),
  );
}
