/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Created by changlei on 2020/8/7.
///
/// 有动画的overlay
class AnimatedOverlay {
  /// 有动画的overlay
  AnimatedOverlay(
    this.context, {
    this.rootOverlay = false,
  }) : assert(rootOverlay != null);

  /// context
  final BuildContext context;

  /// 是否是根overlay
  final bool rootOverlay;

  AnimationController _controller;
  OverlayEntry _overlay;
  Completer<void> _completer;

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
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
    bool immediately = false,
  }) {
    assert(builder != null);
    assert(transitionBuilder != null);
    assert(transitionDuration != null);
    assert(curve != null);
    assert(immediately != null);
    if (_controller != null) {
      _dispose();
    }

    final overlayState = Overlay.of(context, rootOverlay: rootOverlay);
    final toolbarController = AnimationController(
      vsync: overlayState,
      duration: transitionDuration,
    );

    final animation = toolbarController.view;

    final Widget child = AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) => transitionBuilder(context, animation, animation, child),
      child: builder(context, animation, animation),
    );

    void _insertOverlay() {
      _overlay = OverlayEntry(
        builder: (BuildContext context) => child,
      );
      overlayState.insert(_overlay);

      if (immediately) {
        toolbarController.value = toolbarController.upperBound;
      } else {
        toolbarController.animateTo(
          toolbarController.upperBound,
          duration: transitionDuration,
          curve: curve,
        );
      }
    }

    _controller = toolbarController;
    _completer = Completer<void>();

    _onPostFrame(_insertOverlay);
  }

  /// 隐藏
  void remove({
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
    bool immediately = false,
  }) {
    assert(transitionDuration != null);
    assert(curve != null);
    assert(immediately != null);
    if (_controller == null || immediately) {
      _dispose();
      return;
    }
    final animateBack = _controller.animateBack(
      _controller.lowerBound,
      duration: transitionDuration,
      curve: curve,
    );
    final oldOverlay = _overlay;
    animateBack.whenCompleteOrCancel(() {
      if (oldOverlay != _overlay) {
        return;
      }
      _dispose();
    });
  }

  /// 销毁
  void _dispose() {
    _onPostFrame(() {
      _controller?.dispose();
      _controller = null;
      _overlay?.remove();
      _overlay = null;
      _completer?.complete();
      _completer = null;
    });
  }

  void _onPostFrame(VoidCallback callback) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        callback?.call();
      });
    } else {
      callback?.call();
    }
  }
}
