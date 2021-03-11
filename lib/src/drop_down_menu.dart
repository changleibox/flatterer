/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/popup_window.dart';
import 'package:flatterer/src/widget_group.dart';
import 'package:flutter/material.dart';

/// 构建下拉列表item
typedef DropDownMenuItemBuilder = List<Widget> Function(BuildContext context);

const _constraints = BoxConstraints(
  minWidth: 150,
  maxWidth: 300,
  maxHeight: 300,
);

/// Created by changlei on 2020/10/24.
///
/// 下拉框
class DropDownMenu extends StatelessWidget {
  /// 更多弹框
  const DropDownMenu({
    Key key,
    @required this.items,
    this.divider = const Divider(
      indent: 40,
      endIndent: 10,
    ),
    this.constraints = _constraints,
  })  : assert(items != null),
        assert(constraints != null),
        super(key: key);

  /// item
  final List<Widget> items;

  /// 分割线
  final Widget divider;

  /// 约束
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    Widget child = SingleChildScrollView(
      child: WidgetGroup(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        direction: Axis.vertical,
        divider: divider,
        children: items,
      ),
    );
    if (animation != null) {
      child = SizeTransition(
        axisAlignment: -1,
        sizeFactor: CurvedAnimation(
          parent: ModalRoute.of(context).animation,
          curve: const Interval(0.2, 0.8),
          reverseCurve: const Interval(0.2, 0.8),
        ),
        child: child,
      );
    }
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: child,
      ),
    );
  }
}

/// 显示DropDownMenu
Future<T> showDropDownMenu<T>({
  @required BuildContext context,
  @required List<Widget> items,
  Widget divider = const Divider(
    indent: 40,
    endIndent: 10,
  ),
  Axis direction = Axis.vertical,
  Size indicateSize = const Size(24, 12),
  double offset = -10,
  double margin = 10,
  BoxConstraints constraints = _constraints,
}) async {
  assert(context != null);
  assert(direction != null);
  assert(items?.isNotEmpty == true);
  assert(indicateSize != null);
  assert(offset != null);
  assert(margin != null);
  assert(constraints != null);
  return await showPopupWindow<T>(
    context,
    indicateSize: indicateSize,
    offset: offset,
    margin: margin,
    direction: direction,
    builder: (context) {
      return DropDownMenu(
        items: items,
        divider: divider,
        constraints: constraints,
      );
    },
  );
}
