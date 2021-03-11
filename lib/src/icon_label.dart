/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/widget_group.dart';
import 'package:flutter/widgets.dart';

/// Created by changlei on 2020/8/4.
///
/// 由一个icon和label组成的控件
class IconLabel extends StatelessWidget {
  /// 由一个icon和label组成的控件
  const IconLabel({
    Key key,
    this.leftIcon,
    this.topIcon,
    this.rightIcon,
    this.bottomIcon,
    @required this.label,
    this.verticalSpacing = 0,
    this.horizontalSpacing = 0,
    this.alignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  })  : assert(label != null),
        assert(verticalSpacing != null),
        assert(horizontalSpacing != null),
        assert(alignment != null),
        assert(crossAxisAlignment != null),
        assert(mainAxisSize != null),
        super(key: key);

  /// 图标
  final Widget leftIcon;

  /// 图标
  final Widget topIcon;

  /// 图标
  final Widget rightIcon;

  /// 图标
  final Widget bottomIcon;

  /// 文本
  final Widget label;

  /// 垂直间距
  final double verticalSpacing;

  /// 水平间距
  final double horizontalSpacing;

  /// 主方向对齐方式
  final MainAxisAlignment alignment;

  /// 交叉方向对齐方式
  final CrossAxisAlignment crossAxisAlignment;

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    var child = label;
    if (leftIcon != null || rightIcon != null) {
      child = WidgetGroup.spacing(
        alignment: alignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        spacing: horizontalSpacing,
        children: <Widget>[
          if (leftIcon != null) leftIcon,
          child,
          if (rightIcon != null) rightIcon,
        ],
      );
    }
    if (topIcon != null || bottomIcon != null) {
      child = WidgetGroup.spacing(
        alignment: alignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        direction: Axis.vertical,
        spacing: verticalSpacing,
        children: <Widget>[
          if (topIcon != null) topIcon,
          child,
          if (bottomIcon != null) bottomIcon,
        ],
      );
    }
    return child;
  }
}
