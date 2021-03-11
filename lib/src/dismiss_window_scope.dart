/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flutter/material.dart';

/// Created by changlei on 2020/8/14.
///
/// dimiss弹出框
class DismissWindowScope extends InheritedWidget {
  /// dimiss弹出框
  const DismissWindowScope({
    Key key,
    @required this.dismiss,
    @required Widget child,
  })  : assert(dismiss != null),
        assert(child != null),
        super(key: key, child: child);

  /// 关闭
  final VoidCallback dismiss;

  /// 获取锚点state
  static DismissWindowScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DismissWindowScope>();
  }

  @override
  bool updateShouldNotify(DismissWindowScope oldWidget) => dismiss != oldWidget.dismiss;
}
