/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/animated_overlay.dart';
import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/dismiss_window_scope.dart';
import 'package:flatterer/src/flatterer_route.dart';
import 'package:flatterer/src/geometry.dart';
import 'package:flatterer/src/hit_test_detector.dart';
import 'package:flatterer/src/track_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Created by changlei on 2020/8/5.
///
/// overlay浮层锚点控件
class OverlayWindowAnchor extends StatefulWidget {
  /// 浮动提示
  const OverlayWindowAnchor({
    Key? key,
    required this.child,
    required this.builder,
    this.offset = 0,
    this.indicateSize = defaultIndicateSize,
    this.direction = Axis.vertical,
    this.margin = defaultMargin,
    this.alignment = 0,
    this.link,
    this.onDismiss,
    this.backgroundColor = Colors.white,
    this.borderRadius = defaultBorderRadius,
    this.shadows = defaultShadows,
    this.side = defaultSide,
    this.barrierDismissible = true,
    this.barrierColor,
    this.preferBelow = true,
    this.useRootNavigator = true,
    this.below,
    this.above,
    this.onInserted,
    this.modalBarrier = false,
    this.showWhenUnlinked = false,
  }) : super(key: key);

  /// 需要对齐的child
  final Widget child;

  /// 构建弹窗内容
  final WidgetBuilder builder;

  /// 水平或垂直方向上的偏移量
  final double offset;

  /// 显示的方向，上下结构和左右结构
  final Axis direction;

  /// 三角指示器的大小
  final Size indicateSize;

  /// 距离屏幕或者[parentRegion]的距离
  final double margin;

  /// 对齐方式，[-1,1]，0为居中，-1为最左边，1为最右边
  final double alignment;

  /// 跟踪者
  final LayerLink? link;

  /// 隐藏回调
  final VoidCallback? onDismiss;

  /// 窗口背景颜色
  final Color backgroundColor;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 阴影
  final List<BoxShadow> shadows;

  /// The border outline's color and weight.
  ///
  /// If [side] is [BorderSide.none], which is the default, an outline is not drawn.
  /// Otherwise the outline is centered over the shape's boundary.
  final BorderSide side;

  /// 点击外部区域弹窗是否消失
  final bool barrierDismissible;

  /// 遮罩颜色
  final Color? barrierColor;

  /// 优先显示在末尾
  final bool preferBelow;

  /// 使用跟路由
  final bool useRootNavigator;

  /// 显示在below
  final OverlayEntry? below;

  /// 显示在above
  final OverlayEntry? above;

  /// 当窗口插入的时候
  final ValueChanged<OverlayEntry>? onInserted;

  /// 是否使用[ModalBarrier]
  final bool modalBarrier;

  /// [CompositedTransformFollower.showWhenUnlinked]
  final bool showWhenUnlinked;

  @override
  OverlayWindowAnchorState createState() => OverlayWindowAnchorState();
}

/// 浮动提示state
class OverlayWindowAnchorState extends State<OverlayWindowAnchor> with SingleTickerProviderStateMixin {
  final _hitTestDetector = HitTestDetector();

  late LayerLink _link;
  late AnimationController _controller;

  OverlayWindow? _overlayWindow;
  Rect? _anchor;
  VoidCallback? _listener;
  bool _isTapDownHit = false;

  @override
  void initState() {
    _overlayWindow = OverlayWindow(context);
    _overlayWindow!.addListener(_onDismissed);
    _controller = AnimationController(
      vsync: this,
      duration: fadeDuration,
    );
    _link = widget.link ?? LayerLink();
    _hitTestDetector.setup(
      onPointerEvent: _handlePointerEvent,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OverlayWindowAnchor oldWidget) {
    if (widget.link != oldWidget.link) {
      _link = widget.link ?? LayerLink();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _overlayWindow?.removeListener(_onDismissed);
    _overlayWindow?.dismiss(immediately: true);
    _overlayWindow = null;
    _controller.dispose();
    _hitTestDetector.dispose();
    super.dispose();
  }

  /// 针对[PointerEvent]做命中测试
  ///
  /// 返回是否命中
  bool hitTest(PointerEvent event, [HitTestResultVisitor? other]) {
    bool visitor(HitTestTarget target, Object? data) {
      return other?.call(target, data) == true || this.visitor(target, data);
    }

    if (event is PointerDownEvent) {
      _isTapDownHit = event.result.any(visitor);
    } else if (event is PointerUpEvent && !_isTapDownHit && !event.result.any(visitor)) {
      _isTapDownHit = false;
      return true;
    }
    return false;
  }

  /// 测试是否需要dismiss
  bool visitor(HitTestTarget target, Object? data) {
    return data == this || data == widget.child || target == context.findRenderObject();
  }

  void _handlePointerEvent(PointerEvent event) {
    if (!isShowing || !widget.barrierDismissible || widget.modalBarrier) {
      return;
    }
    if (hitTest(event)) {
      dismiss();
    }
  }

  /// 是否正在显示
  bool get isShowing => _overlayWindow != null && _overlayWindow!.isShowing;

  /// 显示
  ///
  /// [anchor]-锚点，在屏幕中的位置
  /// [bounds]-边界，在屏幕中的位置
  /// [compositedTransformTarget]-compositedTransformTarget控件的坐标，默认为anchor的坐标
  void show({
    Rect? anchor,
    Rect? compositedTransformTarget,
    Rect? bounds,
    TrackBehavior behavior = TrackBehavior.lazy,
  }) {
    final rectTween = RectTween(begin: _anchor, end: anchor);
    final animation = rectTween.animate(_controller);
    void listener() {
      if (animation.isCompleted) {
        animation.removeListener(listener);
        _listener = null;
      }

      final value = animation.value;
      if (behavior == TrackBehavior.lazy) {
        _anchor = value;
      }
      _showOrUpdate(value, compositedTransformTarget, bounds: bounds);
    }

    if (_listener != null) {
      animation.removeListener(_listener!);
      _listener = null;
    }
    animation.addListener(_listener = listener);

    if (anchor != null && _anchor != null && anchor != _anchor && behavior != TrackBehavior.none) {
      _controller.forward(from: _controller.lowerBound);
    } else {
      _controller.value = _controller.upperBound;
    }
    if (behavior == TrackBehavior.sharp) {
      _anchor = anchor;
    }
  }

  void _showOrUpdate(Rect? anchor, Rect? compositedTransformTarget, {Rect? bounds}) {
    _overlayWindow!.show(
      builder: (context) {
        return MetaData(
          metaData: this,
          behavior: HitTestBehavior.translucent,
          child: widget.builder(context),
        );
      },
      anchor: anchor,
      compositedTransformTarget: compositedTransformTarget,
      offset: widget.offset,
      indicateSize: widget.indicateSize,
      direction: widget.direction,
      margin: widget.margin,
      alignment: widget.alignment,
      link: _link,
      bounds: bounds,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      side: widget.side,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
      useRootNavigator: widget.useRootNavigator,
      below: widget.below,
      above: widget.above,
      onInserted: widget.onInserted,
      modalBarrier: widget.modalBarrier,
      showWhenUnlinked: widget.showWhenUnlinked,
    );
  }

  /// 隐藏
  void dismiss() {
    if (_listener != null) {
      _controller.removeListener(_listener!);
      _listener = null;
      _controller.value = _controller.upperBound;
    }
    _overlayWindow?.dismiss();
  }

  void _onDismissed() {
    widget.onDismiss?.call();
    _anchor = null;
    dismiss();
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    if (widget.link == null) {
      child = CompositedTransformTarget(
        link: _link,
        child: child,
      );
    }
    return child;
  }
}

/// overlay浮层容器控件
class OverlayWindowContainer extends StatefulWidget {
  /// 浮动提示
  const OverlayWindowContainer({
    Key? key,
    required this.child,
    required this.builder,
    this.offset = 0,
    this.indicateSize = defaultIndicateSize,
    this.direction = Axis.vertical,
    this.margin = defaultMargin,
    this.alignment = 0,
    this.link,
    this.onDismiss,
    this.backgroundColor = Colors.white,
    this.borderRadius = defaultBorderRadius,
    this.shadows = defaultShadows,
    this.side = defaultSide,
    this.barrierDismissible = true,
    this.barrierColor,
    this.preferBelow = true,
    this.modalBarrier = false,
    this.showWhenUnlinked = false,
  }) : super(key: key);

  /// 需要对齐的child
  final Widget child;

  /// 构建弹窗内容
  final WidgetBuilder builder;

  /// 水平或垂直方向上的偏移量
  final double offset;

  /// 显示的方向，上下结构和左右结构
  final Axis direction;

  /// 三角指示器的大小
  final Size indicateSize;

  /// 距离屏幕或者[parentRegion]的距离
  final double margin;

  /// 对齐方式，[-1,1]，0为居中，-1为最左边，1为最右边
  final double alignment;

  /// 跟踪者
  final LayerLink? link;

  /// 隐藏回调
  final VoidCallback? onDismiss;

  /// 窗口背景颜色
  final Color backgroundColor;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 阴影
  final List<BoxShadow> shadows;

  /// The border outline's color and weight.
  ///
  /// If [side] is [BorderSide.none], which is the default, an outline is not drawn.
  /// Otherwise the outline is centered over the shape's boundary.
  final BorderSide side;

  /// 点击外部区域弹窗是否消失
  final bool barrierDismissible;

  /// 遮罩颜色
  final Color? barrierColor;

  /// 优先显示在末尾
  final bool preferBelow;

  /// 是否使用[ModalBarrier]
  final bool modalBarrier;

  /// [CompositedTransformFollower.showWhenUnlinked]
  final bool showWhenUnlinked;

  @override
  OverlayWindowContainerState createState() => OverlayWindowContainerState();
}

/// 浮动提示state
class OverlayWindowContainerState extends State<OverlayWindowContainer> {
  final _overlayAnchorKey = GlobalKey<OverlayWindowAnchorState>();

  /// 是否正在显示
  bool get isShowing => _overlayAnchorKey.currentState?.isShowing == true;

  /// 显示
  ///
  /// [anchor]-锚点，在父控件中的位置
  void show(Rect anchor, {TrackBehavior behavior = TrackBehavior.lazy}) {
    final bounds = localToGlobal(context);
    _overlayAnchorKey.currentState?.show(
      anchor: anchor.shift(bounds.topLeft),
      compositedTransformTarget: widget.link == null ? bounds : null,
      bounds: bounds,
      behavior: behavior,
    );
  }

  /// 隐藏
  void dismiss() {
    _overlayAnchorKey.currentState?.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayWindowAnchor(
      key: _overlayAnchorKey,
      builder: widget.builder,
      onDismiss: widget.onDismiss,
      margin: widget.margin,
      direction: widget.direction,
      offset: widget.offset,
      indicateSize: widget.indicateSize,
      alignment: widget.alignment,
      link: widget.link,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      side: widget.side,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
      modalBarrier: widget.modalBarrier,
      showWhenUnlinked: widget.showWhenUnlinked,
      child: widget.child,
    );
  }
}

/// 显示Overlay
class OverlayWindow {
  /// 显示Overlay
  OverlayWindow(
    this.context, {
    bool rootOverlay = true,
  }) : _overlay = AnimatedOverlay(
          context,
          rootOverlay: rootOverlay,
        );

  /// context
  final BuildContext context;
  final AnimatedOverlay _overlay;

  ModalRoute<dynamic>? _route;

  /// 是否正在显示
  bool get isShowing => _overlay.isShowing;

  /// 添加监听，在[dismiss]以后执行
  void addListener(VoidCallback callback) {
    _overlay.addListener(callback);
  }

  /// 删除监听
  void removeListener(VoidCallback callback) {
    _overlay.removeListener(callback);
  }

  /// 显示
  ///
  /// [anchor]-锚点，在屏幕中的位置
  /// [bounds]-边界，在屏幕中的位置
  /// [compositedTransformTarget]-compositedTransformTarget控件的坐标，默认为anchor的坐标
  void show({
    Rect? anchor,
    Rect? compositedTransformTarget,
    required WidgetBuilder builder,
    double offset = 0,
    Size indicateSize = Size.zero,
    Axis direction = Axis.vertical,
    double margin = 0,
    double alignment = 0,
    LayerLink? link,
    Rect? bounds,
    bool immediately = false,
    Color backgroundColor = Colors.white,
    BorderRadiusGeometry borderRadius = defaultBorderRadius,
    List<BoxShadow> shadows = defaultShadows,
    BorderSide side = defaultSide,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool preferBelow = true,
    OverlayEntry? below,
    OverlayEntry? above,
    ValueChanged<OverlayEntry>? onInserted,
    bool modalBarrier = false,
    bool showWhenUnlinked = false,
  }) {
    assert(margin >= 0);
    assert(alignment.abs() <= 1);
    final currentAnchor = anchor ?? localToGlobal(context);
    _route = FlattererRoute<dynamic>(
      builder,
      currentAnchor,
      offset: offset,
      direction: direction,
      indicateSize: indicateSize,
      margin: margin,
      alignment: alignment,
      bounds: bounds,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      shadows: shadows,
      side: side,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      preferBelow: preferBelow,
      capturedThemes: InheritedTheme.capture(from: context, to: null),
    );

    _overlay.insert(
      builder: (context, animation, secondaryAnimation) {
        Widget child = _OverlayWindowScope(
          overlayWindow: this,
          child: DismissWindowScope(
            dismiss: dismiss,
            child: _route!.buildPage(context, animation, secondaryAnimation),
          ),
        );
        if (link != null) {
          child = CompositedTransformFollower(
            link: link,
            showWhenUnlinked: showWhenUnlinked,
            offset: -(compositedTransformTarget ?? currentAnchor).topLeft,
            child: child,
          );
        }
        if (modalBarrier) {
          child = Stack(
            children: [
              _buildModalBarrier(context, animation),
              child,
            ],
          );
        } else if (barrierColor != null && barrierColor.alpha != 0) {
          final color = animation.drive(
            ColorTween(
              begin: barrierColor.withOpacity(0.0),
              end: barrierColor,
            ).chain(CurveTween(curve: _route!.barrierCurve)),
          );
          child = AnimatedBuilder(
            animation: color,
            builder: (context, child) {
              return ColoredBox(
                color: color.value!,
                child: child,
              );
            },
            child: child,
          );
        }
        return child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _route!.buildTransitions(context, animation, secondaryAnimation, child);
      },
      transitionDuration: _route!.transitionDuration,
      curve: _route!.barrierCurve,
      immediately: immediately,
      below: below,
      above: above,
      onInserted: onInserted,
    );
  }

  Widget _buildModalBarrier(BuildContext context, Animation<double> animation) {
    final modalRoute = _route!;
    final barrierColor = modalRoute.barrierColor;
    final barrierDismissible = _route!.barrierDismissible;
    final barrierLabel = _route!.barrierLabel;
    final semanticsDismissible = _route!.semanticsDismissible;
    Widget barrier;
    if (barrierColor != null && barrierColor.alpha != 0) {
      final color = animation.drive(
        ColorTween(
          begin: barrierColor.withOpacity(0.0),
          end: barrierColor, // changedInternalState is called if barrierColor updates
        ).chain(CurveTween(curve: modalRoute.barrierCurve)), // changedInternalState is called if barrierCurve updates
      );
      barrier = AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    } else {
      barrier = ModalBarrier(
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }
    barrier = IgnorePointer(
      ignoring: animation.status == AnimationStatus.reverse || animation.status == AnimationStatus.dismissed,
      child: barrier,
    );
    if (semanticsDismissible && barrierDismissible) {
      // To be sorted after the _modalScope.
      barrier = Semantics(
        sortKey: const OrdinalSortKey(1.0),
        child: barrier,
      );
    }
    return barrier;
  }

  /// 隐藏
  void dismiss({bool immediately = false}) {
    if (_route == null) {
      _overlay.remove(immediately: true);
    } else {
      _overlay.remove(
        transitionDuration: _route!.reverseTransitionDuration,
        curve: _route!.barrierCurve,
        immediately: immediately,
      );
    }
  }

  /// 获取锚点state
  static OverlayWindow? of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_OverlayWindowScope>();
    return widget?.overlayWindow;
  }
}

class _OverlayWindowScope extends InheritedWidget {
  const _OverlayWindowScope({
    Key? key,
    required this.overlayWindow,
    required Widget child,
  }) : super(key: key, child: child);

  final OverlayWindow overlayWindow;

  @override
  bool updateShouldNotify(_OverlayWindowScope old) => overlayWindow != old.overlayWindow;
}
