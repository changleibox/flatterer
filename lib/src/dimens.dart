/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/material.dart';

/// Created by box on 2021/5/15.
///
/// 资源文件

/// 动画执行时间
const fadeDuration = Duration(milliseconds: 300);

/// 三角形大小
const defaultIndicateSize = Size(30, 16);

/// 四周的边距
const defaultMargin = 20.0;

/// 默认阴影
const defaultShadows = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    spreadRadius: 10,
    blurRadius: 30,
    offset: Offset(0, 0),
  ),
];

/// 边框
const defaultSide = BorderSide(
  color: Color(0x1F000000),
  width: 1,
);

/// 默认圆角
const defaultBorderRadius = BorderRadius.all(Radius.circular(10));
