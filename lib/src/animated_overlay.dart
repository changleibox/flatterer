/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/scheduler.dart';
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

  AnimationController _controller;
  OverlayEntry _overlay;
  Completer<void> _completer;
  Scheduler _scheduler;

  /// 是否正在显示
  bool get isShowing => _overlay != null;

  /// 显示完成，意思就是在remove了以后
  void whenCompleteOrCancel(VoidCallback callback) {
    void thunk(dynamic value) {
      callback();
    }

    _completer?.future?.then<void>(thunk, onError: thunk);
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
    final controller = AnimationController(
      vsync: _overlayState,
      value: _controller?.value,
      duration: transitionDuration,
    );

    void insertOverlay() {
      _overlay?.remove();
      // _controller == null说明已经removed，toolbarController已经释放，没必要再显示
      if (_controller == null) {
        return;
      }
      _overlay = OverlayEntry(
        builder: (BuildContext context) {
          final animation = controller.view;
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
        controller.value = controller.upperBound;
      } else {
        controller.animateTo(
          controller.upperBound,
          duration: transitionDuration,
          curve: curve,
        );
      }
    }

    if (_controller != null) {
      _completer = null;
      _dispose();
    }
    _controller = controller;
    _completer = Completer<void>();

    _onPostFrame(insertOverlay);
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
    void removeOverlay() {
      if (immediately || _controller == null) {
        _dispose();
        return;
      }
      final animateBack = _controller.animateBack(
        _controller.lowerBound,
        duration: transitionDuration,
        curve: curve,
      );
      animateBack.whenComplete(_dispose);
    }

    _onPostFrame(removeOverlay, false);
  }

  /// 销毁
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

  void _onPostFrame(VoidCallback callback, [bool cancel = true]) {
    assert(cancel != null);
    assert(callback != null);
    if (cancel) {
      _scheduler?.cancel();
    }
    _scheduler = Scheduler.postFrame(callback);
  }
}
