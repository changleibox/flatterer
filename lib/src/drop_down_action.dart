/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/support_icon_button.dart';
import 'package:flutter/material.dart';

/// Created by changlei on 2020/9/22.
///
/// 下拉列表按钮
class DropDownAction extends StatelessWidget {
  /// 下拉列表按钮
  const DropDownAction({
    Key? key,
    this.icon,
    this.endIcon,
    required this.label,
    this.isAutoPop = true,
    this.minSize = 40,
    this.padding = EdgeInsets.zero,
    this.spacing = 17,
    this.onPressed,
  }) : super(key: key);

  /// 图标
  final Widget? icon;

  /// 末尾图标图标
  final Widget? endIcon;

  /// 文本
  final Widget label;

  /// 是否自动关闭
  final bool isAutoPop;

  /// 高度
  final double minSize;

  /// padding
  final EdgeInsetsGeometry padding;

  /// space
  final double spacing;

  /// 点击事件
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var leftIcon = icon;
    if (leftIcon != null) {
      leftIcon = IconTheme(
        data: IconThemeData(
          color: textTheme.bodyText1?.color,
          size: 15,
        ),
        child: leftIcon,
      );
    }
    var rightIcon = endIcon;
    if (rightIcon != null) {
      rightIcon = IconTheme(
        data: IconThemeData(
          color: textTheme.bodyText1?.color,
          size: 15,
        ),
        child: rightIcon,
      );
    }
    var label = this.label;
    if (leftIcon != null || rightIcon != null) {
      label = Expanded(
        child: label,
      );
    }
    return SupportIconButton(
      onPressed: () {
        if (isAutoPop) {
          Navigator.pop(context);
        }
        onPressed?.call();
      },
      padding: padding,
      spacing: spacing,
      minSize: minSize,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      label: label,
    );
  }
}
