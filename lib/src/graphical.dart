import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// 最小精度
const minAccuracy = 1e+10;

/// 180度对应的弧度
const radians180 = math.pi;

/// 90度对应的弧度
const radians90 = math.pi / 2;

/// 90度对应的弧度
const radians270 = math.pi * 3 / 2;

/// 360度对应的弧度
const radians360 = math.pi * 2;

/// Created by changlei on 2021/12/10.
///
/// 计算各种图形
Path circlePath({
  required double width,
  required double height,
  required double radius,
  double? blRadius,
  double? brRadius,
  bool avoidOffset = false,
}) {
  return cornerPath(
    width: width,
    height: height,
    radius: radius,
    blRadius: blRadius,
    brRadius: brRadius,
    avoidOffset: avoidOffset,
    visitor: (path, top, left, right) {
      path.addOval(top.circle);
      path.addOval(left.circle);
      path.addOval(right.circle);
    },
  );
}

/// 三角形
Path trianglePath({
  required double width,
  required double height,
  double radius = 0,
  double? blRadius,
  double? brRadius,
  bool avoidOffset = false,
}) {
  return cornerPath(
    width: width,
    height: height,
    radius: radius,
    blRadius: blRadius,
    brRadius: brRadius,
    avoidOffset: avoidOffset,
    visitor: (path, top, left, right) {
      top.middle.moveTo(path);
      top.begin.arcToPoint(path, radius: Radius.circular(top.radius), clockwise: false);
      left.begin.lineTo(path);
      left.end.arcToPoint(path, radius: Radius.circular(left.radius), clockwise: true);
      right.begin.lineTo(path);
      right.end.arcToPoint(path, radius: Radius.circular(right.radius), clockwise: true);
      top.end.lineTo(path);
      top.middle.arcToPoint(path, radius: Radius.circular(top.radius), clockwise: false);
      path.close();
    },
  );
}

/// 创建各个角
Path cornerPath({
  required double width,
  required double height,
  required double radius,
  double? blRadius,
  double? brRadius,
  bool avoidOffset = false,
  void Function(Path path, Incircle top, Incircle left, Incircle right)? visitor,
}) {
  final path = Path();
  if (width <= 0 || height <= 0 || width.isInfinite || height.isInfinite) {
    return path;
  }
  final size = Size(width, height);
  final topRadius = radius;
  final leftRadius = blRadius ?? radius;
  final rightRadius = brRadius ?? radius;

  final topRadians = size.semiRadians;
  final topOffset = Offset(width / 2, 0);
  final top = Incircle.fromSize(size, topRadius, avoidOffset: avoidOffset).shift(topOffset);

  final leftRadians = (radians90 + topRadians) / 2;
  final leftRotation = radians90 + leftRadians;
  final leftOffset = Offset(0, height);
  final left = Incircle.fromRadians(leftRadians, leftRadius).rotationZ(leftRotation).shift(leftOffset);

  final rightRadians = (radians90 + topRadians) / 2;
  final rightRotation = radians270 - leftRadians;
  final rightOffset = Offset(width, height);
  final right = Incircle.fromRadians(rightRadians, rightRadius).rotationZ(rightRotation).shift(rightOffset);

  visitor?.call(path, top, left, right);
  return path;
}

/// 角的指定半径的内切圆
class Incircle {
  /// 构造[Incircle]，[begin]和[end]分别为角内切圆与两边的切点，[middle]为角平分线与内切圆的交点
  Incircle._({
    required this.begin,
    required this.middle,
    required this.end,
  }) : center = centerOf(begin, end, middle);

  /// 根据一个角度和角内切圆的半径构建一个[Incircle]，[radians]为角对应的弧度，[radius]内切圆半径
  factory Incircle.fromRadians(double radians, double radius) {
    final eg = radius * math.cos(radians);
    final ai = radius / math.sin(radians) - radius;
    final ag = ai + radius - radius * math.sin(radians);

    return Incircle._(
      begin: Offset(-eg, ag),
      middle: Offset(0, ai),
      end: Offset(eg, ag),
    );
  }

  /// 根据一个角度和角内切圆的半径构建一个[Incircle]，以[size]作为等腰三角形的底和高计算顶角的弧度，[radius]内切圆半径
  factory Incircle.fromSize(Size size, double radius, {bool avoidOffset = false}) {
    final width = size.width;
    final height = size.height;
    var offsetHeight = height;
    if (avoidOffset) {
      offsetHeight = Incircle.offsetOf(size, radius);
    }
    final radians = Size(width, offsetHeight).semiRadians;
    return Incircle.fromRadians(radians, radius).shift(Offset(0, height - offsetHeight));
  }

  /// 内切圆的左切点
  final Offset begin;

  /// 角平分线与内切圆相交的的近点
  final Offset middle;

  /// 内切圆的右切点
  final Offset end;

  /// 内切圆圆心
  final Offset center;

  /// 内切圆半径
  double get radius => (center - middle).distance.abs();

  /// 内切圆
  Rect get circle => Rect.fromCircle(center: center, radius: radius);

  /// 角的弧度
  double get radians {
    return math.acos((begin - end).distance / (2 * radius)) % radians360;
  }

  /// 旋转的弧度
  double get rotation {
    return (end - begin).direction % radians360;
  }

  /// 角的顶点
  Offset get vertex {
    final dy = radius / math.sin(radians) - radius;
    return Offset(
      middle.dx + dy * math.sin(rotation),
      middle.dy - dy * math.cos(rotation),
    );
  }

  /// 边界
  Rect get bounds {
    final dxs = [begin.dx, middle.dx, end.dx];
    final dys = [begin.dy, middle.dy, end.dy];
    return Rect.fromLTRB(
      dxs.reduce(math.min),
      dys.reduce(math.min),
      dxs.reduce(math.max),
      dys.reduce(math.max),
    );
  }

  /// Returns a new [Incircle] translated by the given offset.
  ///
  /// To translate a rectangle by separate x and y components rather than by an
  /// [Offset], consider [translate].
  Incircle shift(Offset offset) {
    return Incircle._(
      begin: begin + offset,
      middle: middle + offset,
      end: end + offset,
    );
  }

  /// 绕着Z轴顺时针旋转[radians]
  Incircle rotationX(double radians) {
    return Incircle._(
      begin: begin.rotationX(radians),
      middle: middle.rotationX(radians),
      end: end.rotationX(radians),
    );
  }

  /// 绕着Z轴顺时针旋转[radians]
  Incircle rotationY(double radians) {
    return Incircle._(
      begin: begin.rotationY(radians),
      middle: middle.rotationY(radians),
      end: end.rotationY(radians),
    );
  }

  /// 绕着Z轴顺时针旋转[radians]
  Incircle rotationZ(double radians) {
    return Incircle._(
      begin: begin.rotationZ(radians),
      middle: middle.rotationZ(radians),
      end: end.rotationZ(radians),
    );
  }

  /// 绕着角平分线旋转180度
  Incircle get flipped {
    return Incircle._(
      begin: end,
      middle: middle,
      end: begin,
    );
  }

  /// 修正因内切圆造成的位移
  static double offsetOf(Size size, double radius) {
    size = Size(size.width / 2, size.height - radius);
    final bof = size.radians;
    final boe = math.acos(radius / size.distance);
    return size.width / math.tan(bof + boe - radians90);
  }

  /// 根据圆上三个点计算圆心
  static Offset centerOf(Offset point1, Offset point2, Offset point3) {
    final x1 = point1.dx;
    final y1 = point1.dy;
    final x2 = point2.dx;
    final y2 = point2.dy;
    final x3 = point3.dx;
    final y3 = point3.dy;

    final a = 2 * (x2 - x1);
    final b = 2 * (y2 - y1);
    final c = math.pow(x2, 2) + math.pow(y2, 2) - math.pow(x1, 2) - math.pow(y1, 2);
    final d = 2 * (x3 - x2);
    final e = 2 * (y3 - y2);
    final f = math.pow(x3, 2) + math.pow(y3, 2) - math.pow(x2, 2) - math.pow(y2, 2);
    final dx = (b * f - e * c) / (b * d - e * a);
    final dy = (d * c - a * f) / (b * d - e * a);
    return Offset(dx, dy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incircle &&
          runtimeType == other.runtimeType &&
          begin == other.begin &&
          middle == other.middle &&
          end == other.end;

  @override
  int get hashCode => begin.hashCode ^ middle.hashCode ^ end.hashCode;
}

/// 扩展Size
extension SizeExtension on Size {
  /// 半角
  double get semiRadians => flipped.centerRight(Offset.zero).direction;

  /// 半角
  double get radians => flipped.bottomRight(Offset.zero).direction;

  /// The magnitude of the offset.
  ///
  /// If you need this value to compare it to another [Offset]'s distance,
  /// consider using [distanceSquared] instead, since it is cheaper to compute.
  double get distance => bottomRight(Offset.zero).distance;
}

/// 扩展Offset
extension OffsetExtension on Offset {
  /// 绕X轴旋转
  Offset rotationX(double radians) {
    return Offset(dx, dy * math.cos(radians));
  }

  /// 绕Y轴旋转
  Offset rotationY(double radians) {
    return Offset(dx * math.cos(radians), dy);
  }

  /// 绕Z轴旋转
  Offset rotationZ(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return Offset(
      dx * cos - dy * sin,
      dy * cos + dx * sin,
    );
  }

  /// [Path.moveTo]
  void moveTo(Path path) {
    path.moveTo(dx, dy);
  }

  /// [Path.lineTo]
  void lineTo(Path path) {
    path.lineTo(dx, dy);
  }

  /// [Path.arcToPoint]
  void arcToPoint(
    Path path, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    path.arcToPoint(
      this,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}

/// 扩展double
extension DoubleExtension on double {
  /// 修复精度，省略10位小数后的值
  double get exact => (this * minAccuracy).toInt() / minAccuracy;
}

/// 扩展path
extension PathExtension on Path {
  /// [Matrix4.rotationX]
  Path rotationX(double radians) {
    return transform(Matrix4.rotationX(radians).storage);
  }

  /// [Matrix4.rotationY]
  Path rotationY(double radians) {
    return transform(Matrix4.rotationY(radians).storage);
  }

  /// [Matrix4.rotationZ]
  Path rotationZ(double radians) {
    return transform(Matrix4.rotationZ(radians).storage);
  }

  /// 沿着Y轴做镜像
  Path mirrorY(double from) {
    return Path.combine(
      PathOperation.union,
      this,
      rotationY(radians180).shift(Offset(from * 2, 0)),
    );
  }
}
