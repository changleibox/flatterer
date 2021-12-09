/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/icon_label.dart';
import 'package:flutter/cupertino.dart';

/// Created by changlei on 2020/9/4.
///
/// iconButton
class SupportIconButton extends StatelessWidget {
  /// iconButton
  const SupportIconButton({
    Key? key,
    required this.label,
    this.leftIcon,
    this.topIcon,
    this.rightIcon,
    this.bottomIcon,
    this.spacing = 4,
    this.padding,
    this.color,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    this.minSize = kMinInteractiveDimensionCupertino,
    this.pressedOpacity = 0.4,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.alignment = Alignment.centerLeft,
    required this.onPressed,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  })  : assert(pressedOpacity >= 0.0 && pressedOpacity <= 1.0),
        super(key: key);

  /// 文本
  final Widget label;

  /// 图标
  final Widget? leftIcon;

  /// 图标
  final Widget? topIcon;

  /// 图标
  final Widget? rightIcon;

  /// 图标
  final Widget? bottomIcon;

  /// 间距
  final double spacing;

  /// 主方向对齐方式
  final MainAxisAlignment mainAxisAlignment;

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

  /// The amount of space to surround the child inside the bounds of the button.
  ///
  /// Defaults to 16.0 pixels.
  final EdgeInsetsGeometry? padding;

  /// The color of the button's background.
  ///
  /// Defaults to null which produces a button with no background or border.
  ///
  /// Defaults to the [CupertinoTheme]'s `primaryColor` when the
  /// [CupertinoButton.filled] constructor is used.
  final Color? color;

  /// The color of the button's background when the button is disabled.
  ///
  /// Ignored if the [CupertinoButton] doesn't also have a [color].
  ///
  /// Defaults to [CupertinoColors.quaternarySystemFill] when [color] is
  /// specified. Must not be null.
  final Color disabledColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Minimum size of the button.
  ///
  /// Defaults to kMinInteractiveDimensionCupertino which the iOS Human
  /// Interface Guidelines recommends as the minimum tappable area.
  final double minSize;

  /// The opacity that the button will fade to when it is pressed.
  /// The button will have an opacity of 1.0 when it is not pressed.
  ///
  /// This defaults to 0.4. If null, opacity will not change on pressed if using
  /// your own custom effects is desired.
  final double pressedOpacity;

  /// The radius of the button's corners when it has a background color.
  ///
  /// Defaults to round corners of 8 logical pixels.
  final BorderRadius borderRadius;

  /// The alignment of the button's [child].
  ///
  /// Typically buttons are sized to be just big enough to contain the child and its
  /// [padding]. If the button's size is constrained to a fixed size, for example by
  /// enclosing it with a [SizedBox], this property defines how the child is aligned
  /// within the available space.
  ///
  /// Always defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: color,
      disabledColor: disabledColor,
      padding: padding,
      minSize: minSize,
      alignment: alignment,
      borderRadius: borderRadius,
      pressedOpacity: pressedOpacity,
      onPressed: onPressed,
      child: IconLabel(
        leftIcon: leftIcon,
        topIcon: topIcon,
        rightIcon: rightIcon,
        bottomIcon: bottomIcon,
        label: label,
        horizontalSpacing: spacing,
        verticalSpacing: spacing,
        alignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
      ),
    );
  }
}
