/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Created by changlei on 2020/8/7.
///
/// 有动画的overlay
class AnimatedOverlay {
  /// 有动画的overlay
  AnimatedOverlay(
    BuildContext context, {
    bool rootOverlay = false,
  })  : assert(context != null),
        assert(rootOverlay != null),
        _overlayState = Overlay.of(
          context,
          rootOverlay: rootOverlay,
        );

  final OverlayState _overlayState;

  final _listeners = ObserverList<VoidCallback>();

  AnimationController _controller;
  OverlayEntry _overlay;
  Completer<void> _completer;
  Scheduler _scheduler;

  /// 是否正在显示
  bool get isShowing => _overlay != null;

  /// 添加监听，在[remove]以后执行
  void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  /// 删除监听
  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  /// 显示
  void insert({
    @required RoutePageBuilder builder,
    @required RouteTransitionsBuilder transitionBuilder,
    Duration transitionDuration = fadeDuration,
    Curve curve = Curves.linear,
    bool immediately = false,
  }) {
    assert(builder != null);
    assert(transitionBuilder != null);
    assert(transitionDuration != null);
    assert(curve != null);
    assert(immediately != null);
    if (_isAnimatingStatus(AnimationStatus.forward) && !immediately) {
      _overlay?.markNeedsBuild();
      return;
    }
    void insertOverlay() {
      if (_controller == null) {
        return;
      }
      final animation = _controller.view;
      _overlay?.remove();
      _overlay = OverlayEntry(
        builder: (BuildContext context) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget child) {
              return transitionBuilder(context, animation, animation, child);
            },
            child: builder(context, animation, animation),
          );
        },
      );
      _overlayState.insert(_overlay);

      if (immediately) {
        _controller.value = _controller.upperBound;
      } else {
        _controller.animateTo(
          _controller.upperBound,
          duration: transitionDuration,
          curve: curve,
        );
      }
    }

    _controller?.dispose();
    _controller = AnimationController(
      vsync: _overlayState,
      value: _controller?.value,
      duration: transitionDuration,
    );
    _completer = Completer<void>();
    _completer.future.then<void>(_notifyListeners);

    _onPostFrame(insertOverlay);
  }

  void _notifyListeners([dynamic _]) {
    final listeners = List.of(_listeners);
    for (var listener in listeners) {
      if (_listeners.contains(listener)) {
        listener();
      }
    }
  }

  /// 隐藏
  void remove({
    Duration transitionDuration = fadeDuration,
    Curve curve = Curves.linear,
    bool immediately = false,
  }) {
    assert(transitionDuration != null);
    assert(curve != null);
    assert(immediately != null);
    if (_isAnimatingStatus(AnimationStatus.reverse) && !immediately) {
      return;
    }
    void removeOverlay() {
      if (_controller == null) {
        return;
      }
      if (immediately) {
        _dispose();
      } else {
        final animateBack = _controller.animateBack(
          _controller.lowerBound,
          duration: transitionDuration,
          curve: curve,
        );
        animateBack.whenComplete(_dispose);
      }
    }

    _onPostFrame(removeOverlay, false);
  }

  // 销毁
  void _dispose() {
    _controller?.dispose();
    _controller = null;
    _completer?.complete();
    _completer = null;
    _scheduler?.cancel();
    _scheduler = null;
    _overlay?.remove();
    _overlay = null;
  }

  // 判断动画正在进行的状态
  bool _isAnimatingStatus(AnimationStatus status) {
    return _controller?.status == status && _controller?.isAnimating == true;
  }

  void _onPostFrame(VoidCallback callback, [bool cancel = true]) {
    assert(cancel != null);
    assert(callback != null);
    if (cancel) {
      _scheduler?.cancel();
    }
    _scheduler = Scheduler.postFrame(callback);
  }
}
