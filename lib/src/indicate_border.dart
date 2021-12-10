/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:math' as math;

import 'package:flatterer/src/graphical.dart' as graphical;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

const _cornerRadius = 8.0;

/// Created by box on 2020/7/28.
///
/// 带有指示器的自定义border
class IndicateBorder extends OutlinedBorder {
  /// 带有指示器的自定义border
  const IndicateBorder({
    Size? indicateSize,
    BorderRadiusGeometry? borderRadius,
    Rect? anchor,
    this.direction = Axis.vertical,
    BorderSide side = BorderSide.none,
  })  : indicateSize = indicateSize ?? Size.zero,
        borderRadius = borderRadius ?? BorderRadius.zero,
        anchor = anchor ?? Rect.zero,
        super(side: side);

  /// 三角形的大小，宽高对应三角形的底边和高
  final Size indicateSize;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 锚点的位置大小
  final Rect anchor;

  /// 绘制的方向
  final Axis direction;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return IndicateBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
      indicateSize: indicateSize * t,
      direction: direction,
      anchor: Rect.fromPoints(
        anchor.topLeft * t,
        anchor.bottomRight * t,
      ),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is IndicateBorder) {
      return IndicateBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t),
        indicateSize: Size.lerp(a.indicateSize, indicateSize, t),
        anchor: Rect.lerp(a.anchor, anchor, t),
        direction: direction,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is IndicateBorder) {
      return IndicateBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t),
        indicateSize: Size.lerp(indicateSize, b.indicateSize, t),
        anchor: Rect.lerp(anchor, b.anchor, t),
        direction: direction,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  IndicateBorder copyWith({
    Size? indicateSize,
    BorderRadius? borderRadius,
    Rect? anchor,
    Axis? direction,
    BorderSide? side,
  }) {
    return IndicateBorder(
      indicateSize: indicateSize ?? this.indicateSize,
      borderRadius: borderRadius ?? this.borderRadius,
      side: side ?? this.side,
      direction: direction ?? this.direction,
      anchor: anchor ?? this.anchor,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect, textDirection: textDirection, delta: side.width);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect, textDirection: textDirection);
  }

  Path _getIndicatePath(double width, double height, [AxisDirection? direction, Offset? offset]) {
    var path = graphical.trianglePath(width, height, _cornerRadius);
    if (direction != null && direction.angle % 360 != 0) {
      path = path.transform(Matrix4.rotationZ(direction.radians).storage);
    }
    if (offset != null) {
      path = path.shift(offset);
    }
    return path;
  }

  Path _getPath(Rect rect, {TextDirection? textDirection, double delta = 0}) {
    assert(delta >= 0);
    final indicateWidth = indicateSize.width;
    final indicateHeight = indicateSize.height;

    double newIndicateWidth;
    double newIndicateHeight;
    double newDelta;
    if (indicateHeight == 0) {
      newIndicateWidth = indicateWidth;
      newIndicateHeight = indicateHeight;
      newDelta = 0;
    } else {
      final radians = math.atan(indicateWidth / 2 / indicateHeight);
      newDelta = delta / math.sin(radians);
      newIndicateHeight = indicateHeight - newDelta + delta;
      newIndicateWidth = newIndicateHeight * math.tan(radians) * 2;
    }

    final indicateOriginSize = indicateHeight;

    AxisDirection? axisDirection;
    Offset offset;
    if (direction == Axis.vertical) {
      final translation = (anchor.center - rect.centerLeft).dx;
      if (rect.center.dy < anchor.center.dy) {
        axisDirection = AxisDirection.down;
        offset = Offset(translation, rect.height - newDelta + indicateOriginSize);
      } else {
        axisDirection = AxisDirection.up;
        offset = Offset(translation, newDelta - indicateOriginSize);
      }
    } else {
      final translation = (anchor.center - rect.topCenter).dy;
      if (rect.center.dx < anchor.center.dx) {
        axisDirection = AxisDirection.right;
        offset = Offset(rect.width - newDelta + indicateOriginSize, translation);
      } else {
        axisDirection = AxisDirection.left;
        offset = Offset(newDelta - indicateOriginSize, translation);
      }
    }

    return Path.combine(
      PathOperation.union,
      _getIndicatePath(newIndicateWidth, newIndicateHeight, axisDirection, offset + rect.topLeft),
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(delta)),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        if (side.width == 0) {
          canvas.drawPath(_getPath(rect, textDirection: textDirection), side.toPaint());
          return;
        }
        final path = Path()
          ..addPath(getOuterPath(rect, textDirection: textDirection), Offset.zero)
          ..addPath(getInnerPath(rect, textDirection: textDirection), Offset.zero)
          ..fillType = PathFillType.evenOdd
          ..close();
        final paint = side.toPaint()..style = PaintingStyle.fill;
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IndicateBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.indicateSize == indicateSize &&
        other.anchor == anchor &&
        other.direction == direction;
  }

  @override
  int get hashCode => hashValues(side, borderRadius, indicateSize, anchor, direction);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'IndicateBorder')}($indicateSize, $borderRadius, $anchor, $direction, $side)';
  }
}

extension _AxisDirectionExtension on AxisDirection {
  /// 对应的角度
  double get angle {
    switch (this) {
      case AxisDirection.up:
        return 0;
      case AxisDirection.right:
        return 90;
      case AxisDirection.down:
        return 180;
      case AxisDirection.left:
        return 270;
    }
  }

  /// 弧度
  double get radians => angle * math.pi / 180;
}
