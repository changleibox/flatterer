/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Created by box on 2020/7/28.
///
/// 带有指示器的自定义border
class IndicateBorder extends OutlinedBorder {
  /// 带有指示器的自定义border
  const IndicateBorder({
    this.indicateSize = Size.zero,
    this.borderRadius = BorderRadius.zero,
    this.anchor = Rect.zero,
    this.direction = Axis.vertical,
    BorderSide side = BorderSide.none,
  })  : assert(indicateSize != null),
        assert(borderRadius != null),
        assert(anchor != null),
        assert(direction != null),
        assert(side != null),
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
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
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
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
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
    Size indicateSize,
    BorderRadius borderRadius,
    Rect anchor,
    Axis direction,
    BorderSide side,
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
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return _getPath(rect, textDirection: textDirection, delta: side.width);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return _getPath(rect, textDirection: textDirection);
  }

  Path _getVerticalIndicatePath(Rect rect, double offset, double width, double height) {
    final indicateOriginSize = indicateSize.height;
    final translation = (anchor.center - rect.centerLeft).dx;
    Path indicatePath;
    if (rect.center.dy < anchor.center.dy) {
      indicatePath = Path()
        ..moveTo(translation, rect.height - offset + indicateOriginSize)
        ..relativeLineTo(-width / 2, -height)
        ..relativeLineTo(width, 0)
        ..close();
    } else {
      indicatePath = Path()
        ..moveTo(translation, offset - indicateOriginSize)
        ..relativeLineTo(-width / 2, height)
        ..relativeLineTo(width, 0)
        ..close();
    }
    return indicatePath;
  }

  Path _getHorizontalIndicatePath(
    Rect rect,
    double offset,
    double width,
    double height, {
    TextDirection textDirection,
  }) {
    final indicateOriginSize = indicateSize.height;
    final translation = (anchor.center - rect.topCenter).dy;
    final isArrowPointingEnd = rect.center.dx < anchor.center.dx && textDirection == TextDirection.ltr;
    Path indicatePath;
    if (isArrowPointingEnd) {
      indicatePath = Path()
        ..moveTo(rect.width - offset + indicateOriginSize, translation)
        ..relativeLineTo(-width, height / 2)
        ..relativeLineTo(0, -height)
        ..close();
    } else {
      indicatePath = Path()
        ..moveTo(offset - indicateOriginSize, translation)
        ..relativeLineTo(width, height / 2)
        ..relativeLineTo(0, -height)
        ..close();
    }
    return indicatePath;
  }

  Path _getPath(Rect rect, {TextDirection textDirection, double delta = 0}) {
    assert(delta != null && delta >= 0);
    final path = Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(delta));
    if (indicateSize.isEmpty) {
      return path;
    }

    final indicateWidth = indicateSize.width;
    final indicateHeight = indicateSize.height;

    double newIndicateWidth;
    double newIndicateHeight;
    double offset;
    if (indicateHeight == 0) {
      newIndicateWidth = indicateWidth;
      newIndicateHeight = indicateHeight;
      offset = 0;
    } else {
      final radians = math.atan(indicateWidth / 2 / indicateHeight);
      offset = delta / math.sin(radians);
      newIndicateHeight = indicateHeight - offset + delta;
      newIndicateWidth = newIndicateHeight * math.tan(radians) * 2;
    }

    Path indicatePath;
    if (direction == Axis.vertical) {
      indicatePath = _getVerticalIndicatePath(
        rect,
        offset,
        newIndicateWidth,
        newIndicateHeight,
      );
    } else {
      indicatePath = _getHorizontalIndicatePath(
        rect,
        offset,
        newIndicateHeight,
        newIndicateWidth,
        textDirection: textDirection,
      );
    }

    return Path.combine(
      PathOperation.union,
      indicatePath.shift(rect.topLeft),
      path,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
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
