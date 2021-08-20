/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _maxIntervalForClick = kLongPressTimeout;
const _maxDistanceForClick = 100.0;

/// Created by changlei on 2021/8/20.
///
/// 命中测试检测器
class HitTestDetector {
  bool _waitUpEvent = false;
  Offset _tapDownPosition;
  Timer _tapTimer;

  /// 命中测试
  ValueChanged<HitTestResult> _hitTest;

  /// 初始化
  void setup(ValueChanged<HitTestResult> hitTest) {
    _hitTest = hitTest;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  /// 释放
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _tapDownPosition = event.position;
      _waitUpEvent = true;
      _tapTimer?.cancel();
      _tapTimer = Timer(_maxIntervalForClick, () {
        _waitUpEvent = false;
      });
      return;
    } else if (event is PointerUpEvent) {
      final waitUpEvent = _waitUpEvent;
      _waitUpEvent = false;
      _tapTimer?.cancel();
      if (_isOverflowClickDistance(event.position, _tapDownPosition)) {
        return;
      }
      if (!waitUpEvent) {
        return;
      }
    } else if (event is PointerMoveEvent) {
      if (_isOverflowClickDistance(event.position, _tapDownPosition)) {
        _waitUpEvent = false;
        _tapTimer?.cancel();
      }
      return;
    } else {
      return;
    }
    final result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, event.position);
    _hitTest?.call(result);
  }

  // 是否抽出点击范围
  bool _isOverflowClickDistance(Offset a, Offset b, [double distance = _maxDistanceForClick]) {
    return (a.dx - b.dx).abs() > distance || (a.dy - b.dy).abs() > distance;
  }
}

/// hitTest扩展
extension HitTestResultTarget on HitTestResult {
  /// 遍历访问target
  bool any(bool Function(HitTestTarget target, Object data) visitor) {
    return path.map((e) => e.target).any((element) {
      return visitor(element, element is RenderMetaData ? element.metaData : null);
    });
  }

  /// 遍历访问target
  bool every(bool Function(HitTestTarget target, Object data) visitor) {
    return path.map((e) => e.target).every((element) {
      return visitor(element, element is RenderMetaData ? element.metaData : null);
    });
  }
}
