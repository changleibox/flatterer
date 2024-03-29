/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _maxInterval = kLongPressTimeout;
const _maxDistance = 100.0;

/// 遍历[HitTestResult]
typedef HitTestResultVisitor = bool Function(HitTestTarget target, Object? data);

/// Created by changlei on 2021/8/20.
///
/// 命中测试检测器
class HitTestDetector {
  bool _waitUpEvent = false;
  Offset? _tapDownPosition;
  Timer? _tapTimer;
  bool _isSetup = false;

  /// 命中测试
  ValueChanged<HitTestResult>? _onTapHitTest;

  /// 回调每个事件，最先执行
  ValueChanged<PointerEvent>? _onPointerEvent;

  /// 初始化
  void setup({ValueChanged<HitTestResult>? onTapHitTest, ValueChanged<PointerEvent>? onPointerEvent}) {
    assert(!_isSetup);
    _isSetup = true;
    _onTapHitTest = onTapHitTest;
    _onPointerEvent = onPointerEvent;
    GestureBinding.instance!.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  /// 释放
  void dispose() {
    assert(_isSetup);
    GestureBinding.instance!.pointerRouter.removeGlobalRoute(_handlePointerEvent);
  }

  void _handlePointerEvent(PointerEvent event) {
    _onPointerEvent?.call(event);
    if (event is PointerDownEvent) {
      _tapDownPosition = event.position;
      _waitUpEvent = true;
      _tapTimer?.cancel();
      _tapTimer = Timer(_maxInterval, () {
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
    _onTapHitTest?.call(event.result);
  }

  // 是否抽出点击范围
  bool _isOverflowClickDistance(Offset? a, Offset? b, [double distance = _maxDistance]) {
    if (a == null || b == null) {
      return true;
    }
    return (a.dx - b.dx).abs() > distance || (a.dy - b.dy).abs() > distance;
  }
}

/// 扩展[HitTestResult]
extension HitTestResultTarget on HitTestResult {
  /// 遍历访问target
  bool any(HitTestResultVisitor visitor) {
    return path.map((e) => e.target).any((element) {
      return visitor(element, element is RenderMetaData ? element.metaData : null);
    });
  }

  /// 遍历访问target
  bool every(HitTestResultVisitor visitor) {
    return path.map((e) => e.target).every((element) {
      return visitor(element, element is RenderMetaData ? element.metaData : null);
    });
  }
}

/// 扩展[PointerEvent]
extension PointerEventHitTestResult on PointerEvent {
  /// 返回[HitTestResult]
  HitTestResult get result {
    final result = HitTestResult();
    WidgetsBinding.instance!.hitTest(result, position);
    return result;
  }
}
