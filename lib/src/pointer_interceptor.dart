/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/material.dart';

/// Created by box on 2021/5/16.
///
/// 拦截[OverlayWindow]和[StackWindow]点击消失事件
class PointerInterceptor extends StatelessWidget {
  /// 构造函数
  const PointerInterceptor({
    Key key,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  /// child
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
