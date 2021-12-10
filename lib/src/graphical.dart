/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

const _topRadius = 2.0;
const _bottomRadius = 1.5;

/// Created by changlei on 2021/12/10.
///
/// 计算各种图形
/// 三角形
Path trianglePath(double width, double height, [double radius = 0]) {
  final compensate = heightCompensate(width, height, radius / _topRadius);
  return cornerPath(
    width,
    compensate,
    radius,
  ).shift(Offset(-width / 2, height - compensate));
}

/// 补偿
double heightCompensate(double width, double height, [double radius = 0]) {
  final of = height - radius;
  final bf = width / 2;
  final bo = math.sqrt(math.pow(of, 2) + math.pow(bf, 2));
  final bof = math.atan(bf / of);
  final boe = math.acos(radius / bo);
  final newRadians = bof + boe - math.pi / 2;
  return bf / math.tan(newRadians);
}

/// 创建元素path
Rect pathBounds(
  double radians,
  double radius, {
  double rotation = 0,
  Offset offset = Offset.zero,
}) {
  final ae = radius / math.tan(radians);
  final ag = ae * math.cos(radians);
  final eg = ae * math.sin(radians);
  final ai = ae / math.cos(radians) - radius;

  final matrix4 = Matrix4.rotationZ(rotation);
  final rect = Rect.fromPoints(Offset(-eg, ai), Offset(eg, ag));
  return MatrixUtils.transformRect(matrix4, rect).shift(offset);
}

/// 创建各个角
Path cornerPath(double width, double height, double radius) {
  final radians = math.atan(width / 2 / height);

  final top = pathBounds(
    radians,
    radius / _topRadius,
    rotation: 0,
    offset: Offset(width / 2, 0),
  );

  final left = pathBounds(
    (math.pi / 2 + radians) / 2,
    radius * _bottomRadius,
    rotation: math.pi - (math.pi / 2 - radians) / 2,
    offset: Offset(0, height),
  );

  final path = Path();
  path.moveTo(top.topCenter.dx, top.top);
  path.arcToPoint(top.bottomLeft, radius: Radius.circular(radius / _topRadius), clockwise: false);
  path.lineTo(left.right, left.top);
  path.arcToPoint(left.bottomLeft, radius: Radius.circular(radius * _bottomRadius), clockwise: true);
  path.lineTo(top.right, left.bottom);
  path.close();

  return Path.combine(
    PathOperation.union,
    path,
    path.transform(Matrix4.rotationY(math.pi).storage).shift(Offset(width, 0)),
  );
}
