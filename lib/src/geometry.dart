// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Position a child box within a container box, either above or below a target
/// point.
///
/// The container's size is described by `size`.
///
/// The target point is specified by `target`, as an offset from the top left of
/// the container.
///
/// The child box's size is given by `childSize`.
///
/// The return value is the suggested distance from the top left of the
/// container box to the top left of the child box.
///
/// The suggested position will be above the target point if `preferBelow` is
/// false, and below the target point if it is true, unless it wouldn't fit on
/// the preferred side but would fit on the other side.
///
/// The suggested position will place the nearest side of the child to the
/// target point `verticalOffset` from the target point (even if it cannot fit
/// given that constraint).
///
/// The suggested position will be at least `margin` away from the edge of the
/// container. If possible, the child will be positioned so that its center is
/// aligned with the target point. If the child cannot fit horizontally within
/// the container given the margin, then the child will be centered in the
/// container.
///
/// Used by [Tooltip] to position a tooltip relative to its parent.
///
/// The arguments must not be null.
Offset positionDependentBoxPopupWindow({
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferBelow,
  double offset = 0.0,
  double margin = 10.0,
  Axis direction = Axis.vertical,
  double alignment = 0,
}) {
  if (direction == Axis.vertical) {
    return _positionDependentBoxVertical(
      size: size,
      childSize: childSize,
      target: target,
      preferBelow: preferBelow,
      verticalOffset: offset,
      margin: margin,
      alignment: alignment,
    );
  } else {
    return _positionDependentBoxHorizontal(
      size: size,
      childSize: childSize,
      target: target,
      preferBelow: preferBelow,
      horizontalOffset: offset,
      margin: margin,
      alignment: alignment,
    );
  }
}

/// 计算垂直位置上的坐标
Offset _positionDependentBoxVertical({
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferBelow,
  double verticalOffset = 0.0,
  double margin = 10.0,
  double alignment = 0,
}) {
  assert(alignment.abs() <= 1);
  // VERTICAL DIRECTION
  final fitsBelow = target.dy + verticalOffset + childSize.height <= size.height - margin;
  final fitsAbove = target.dy - verticalOffset - childSize.height >= margin;
  final tooltipBelow = preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
  double y;
  if (tooltipBelow) {
    y = math.min(target.dy + verticalOffset, size.height - margin);
  } else {
    y = math.max(target.dy - verticalOffset - childSize.height, margin);
  }
  // HORIZONTAL DIRECTION
  double x;
  if (size.width - margin * 2.0 < childSize.width) {
    x = (size.width - childSize.width) / 2.0;
  } else {
    final adjustOffset = _adjustOffset(childSize.width, alignment);
    final normalizedTargetX = (target.dx.clamp(margin, size.width - margin)) - adjustOffset;
    final edge = margin + childSize.width / 2.0;
    if (normalizedTargetX < edge) {
      x = margin;
    } else if (normalizedTargetX > size.width - edge) {
      x = size.width - margin - childSize.width;
    } else {
      x = normalizedTargetX - childSize.width / 2.0;
    }
  }
  return Offset(x, y);
}

/// 计算水平位置上的坐标
Offset _positionDependentBoxHorizontal({
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferBelow,
  double horizontalOffset = 0.0,
  double margin = 10.0,
  double alignment = 0,
}) {
  assert(alignment.abs() <= 1);
  // HORIZONTAL DIRECTION
  final fitsBelow = target.dx + horizontalOffset + childSize.width <= size.width - margin;
  final fitsAbove = target.dx - horizontalOffset - childSize.width >= margin;
  final tooltipBelow = preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
  double x;
  if (tooltipBelow) {
    x = math.min(target.dx + horizontalOffset, size.width - margin);
  } else {
    x = math.max(target.dx - horizontalOffset - childSize.width, margin);
  }
  // VERTICAL DIRECTION
  double y;
  if (size.height - margin * 2.0 < childSize.height) {
    y = (size.height - childSize.height) / 2.0;
  } else {
    final adjustOffset = _adjustOffset(childSize.height, alignment);
    final normalizedTargetY = (target.dy.clamp(margin, size.height - margin)) - adjustOffset;
    final edge = margin + childSize.height / 2.0;
    if (normalizedTargetY < edge) {
      y = margin;
    } else if (normalizedTargetY > size.height - edge) {
      y = size.height - margin - childSize.height;
    } else {
      y = normalizedTargetY - childSize.height / 2.0;
    }
  }
  return Offset(x, y);
}

double _adjustOffset(double offset, double alignment) => alignment * offset / 2.0;

/// Convert the given point from the local coordinate system for this box to
/// the global coordinate system in logical pixels.
///
/// If `ancestor` is non-null, this function converts the given point to the
/// coordinate system of `ancestor` (which must be an ancestor of this render
/// object) instead of to the global coordinate system.
///
/// This method is implemented in terms of [getTransformTo]. If the transform
/// matrix puts the given `point` on the line at infinity (for instance, when
/// the transform matrix is the zero matrix), this method returns (NaN, NaN).
Rect localToGlobal(BuildContext? context, {Offset? point, RenderObject? ancestor}) {
  if (context == null) {
    return Rect.zero;
  }
  point ??= Offset.zero;
  final renderObject = context.findRenderObject() as RenderBox;
  return Rect.fromPoints(
    renderObject.localToGlobal(point, ancestor: ancestor),
    renderObject.localToGlobal(renderObject.size.bottomRight(point), ancestor: ancestor),
  );
}

/// Convert the given point from the global coordinate system in logical pixels
/// to the local coordinate system for this box.
///
/// This method will un-project the point from the screen onto the widget,
/// which makes it different from [MatrixUtils.transformPoint].
///
/// If the transform from global coordinates to local coordinates is
/// degenerate, this function returns [Offset.zero].
///
/// If `ancestor` is non-null, this function converts the given point from the
/// coordinate system of `ancestor` (which must be an ancestor of this render
/// object) instead of from the global coordinate system.
///
/// This method is implemented in terms of [getTransformTo].
Rect globalToLocal(BuildContext? context, {Offset? point, RenderObject? ancestor}) {
  if (context == null) {
    return Rect.zero;
  }
  point ??= Offset.zero;
  final renderObject = context.findRenderObject() as RenderBox;
  return Rect.fromPoints(
    renderObject.globalToLocal(point, ancestor: ancestor),
    renderObject.globalToLocal(renderObject.size.bottomRight(point), ancestor: ancestor),
  );
}

/// 计算控件在离它最近的边界的位置
Rect localToRepaintBoundary(BuildContext? context, {Offset? point}) {
  if (context == null) {
    return Rect.zero;
  }
  point ??= Offset.zero;
  final renderObject = context.findRenderObject();
  final ancestor = context.findAncestorRenderObjectOfType<RenderRepaintBoundary>() ?? renderObject;
  return localToGlobal(context, point: point, ancestor: ancestor);
}
