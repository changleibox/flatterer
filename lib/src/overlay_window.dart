/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/animated_overlay.dart';
import 'package:flatterer/src/dismiss_window_scope.dart';
import 'package:flatterer/src/flatterer_window.dart';
import 'package:flatterer/src/geometry.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 三角形大小
const Size _indicateSize = Size(30, 16);

/// 四周的边距
const double _margin = 20;

/// 默认阴影
const _shadows = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    spreadRadius: 10,
    blurRadius: 30,
    offset: Offset(0, 0),
  ),
];

/// 默认圆角
const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(10));

/// Created by changlei on 2020/8/5.
///
/// overlay浮层锚点控件
class OverlayWindowAnchor extends StatefulWidget {
  /// 浮动提示
  const OverlayWindowAnchor({
    Key key,
    @required this.child,
    @required this.builder,
    this.offset = 0,
    this.indicateSize = _indicateSize,
    this.direction = Axis.vertical,
    this.margin = _margin,
    this.alignment = 0,
    this.onDismiss,
    this.backgroundColor = Colors.white,
    this.borderRadius = _borderRadius,
    this.shadows = _shadows,
    this.barrierDismissible = true,
    this.barrierColor,
    this.preferBelow = true,
  })  : assert(child != null),
        assert(builder != null),
        assert(offset != null),
        assert(direction != null),
        assert(indicateSize != null),
        assert(margin != null),
        assert(alignment != null),
        assert(backgroundColor != null),
        assert(borderRadius != null),
        assert(shadows != null),
        assert(barrierDismissible != null),
        assert(preferBelow != null),
        super(key: key);

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

  /// 隐藏回调
  final VoidCallback onDismiss;

  /// 窗口背景颜色
  final Color backgroundColor;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 阴影
  final List<BoxShadow> shadows;

  /// 点击外部区域弹窗是否消失
  final bool barrierDismissible;

  /// 遮罩颜色
  final Color barrierColor;

  /// 优先显示在末尾
  final bool preferBelow;

  @override
  OverlayWindowAnchorState createState() => OverlayWindowAnchorState();
}

/// 浮动提示state
class OverlayWindowAnchorState extends State<OverlayWindowAnchor> with SingleTickerProviderStateMixin {
  final _overlayLayerLink = LayerLink();

  OverlayWindow _overlayWindow;
  Rect _anchor;
  AnimationController _controller;
  GlobalKey _windowKey;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    super.initState();
  }

  @override
  void dispose() {
    _overlayWindow?.dismiss(immediately: true);
    _controller?.dispose();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event) {
    if ((event is PointerUpEvent || event is PointerCancelEvent) && localToGlobal(_windowKey?.currentContext)?.contains(event.localPosition) != true) {
      dismiss();
    }
  }

  /// 是否正在显示
  bool get isShowing => _overlayWindow != null && _overlayWindow.isShowing;

  /// 显示
  ///
  /// [anchor]-锚点，在屏幕中的位置
  /// [bounds]-边界，在屏幕中的位置
  /// [compositedTransformTarget]-compositedTransformTarget控件的坐标，默认为anchor的坐标
  void show({Rect anchor, Rect compositedTransformTarget, Rect bounds}) {
    final immediately = _anchor != null && anchor != _anchor;

    final rectTween = RectTween(begin: _anchor, end: anchor);
    final animation = rectTween.animate(_controller);
    void _listener() {
      if (animation.isCompleted) {
        animation.removeListener(_listener);
      }
      _showOrUpdate(animation.value, compositedTransformTarget, immediately, bounds: bounds);
    }

    animation.addListener(_listener);

    if (immediately) {
      _controller.forward(from: _controller.lowerBound);
    } else {
      _controller.value = _controller.upperBound;
    }

    _anchor = anchor;
  }

  void _showOrUpdate(Rect anchor, Rect compositedTransformTarget, bool immediately, {Rect bounds}) {
    _windowKey = GlobalKey();
    _overlayWindow?.dismiss(immediately: immediately);
    _overlayWindow = OverlayWindow(context);
    _overlayWindow.show(
      builder: (context) {
        return KeyedSubtree(
          key: _windowKey,
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
      toolbarLayerLink: _overlayLayerLink,
      bounds: bounds,
      immediately: immediately,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
    );
    if (!_controller.isCompleted) {
      return;
    }
    _overlayWindow.whenCompleteOrCancel((overlayWindow) {
      if (_overlayWindow != overlayWindow) {
        return;
      }
      widget.onDismiss?.call();
      dismiss();
    });
  }

  /// 隐藏
  void dismiss() {
    _overlayWindow?.dismiss();
    _overlayWindow = null;
    _anchor = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _overlayLayerLink,
      child: widget.child,
    );
  }
}

/// overlay浮层容器控件
class OverlayWindowContainer extends StatefulWidget {
  /// 浮动提示
  const OverlayWindowContainer({
    Key key,
    @required this.child,
    @required this.builder,
    this.offset = 0,
    this.indicateSize = _indicateSize,
    this.direction = Axis.vertical,
    this.margin = _margin,
    this.alignment = 0,
    this.onDismiss,
    this.backgroundColor = Colors.white,
    this.borderRadius = _borderRadius,
    this.shadows = _shadows,
    this.barrierDismissible = true,
    this.barrierColor,
  })  : assert(child != null),
        assert(builder != null),
        assert(offset != null),
        assert(direction != null),
        assert(indicateSize != null),
        assert(margin != null),
        assert(alignment != null),
        assert(backgroundColor != null),
        assert(borderRadius != null),
        assert(shadows != null),
        assert(barrierDismissible != null),
        super(key: key);

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

  /// 隐藏回调
  final VoidCallback onDismiss;

  /// 窗口背景颜色
  final Color backgroundColor;

  /// 矩形框的圆角
  final BorderRadiusGeometry borderRadius;

  /// 阴影
  final List<BoxShadow> shadows;

  /// 点击外部区域弹窗是否消失
  final bool barrierDismissible;

  /// 遮罩颜色
  final Color barrierColor;

  @override
  OverlayWindowContainerState createState() => OverlayWindowContainerState();
}

/// 浮动提示state
class OverlayWindowContainerState extends State<OverlayWindowContainer> {
  final _overlayAnchorKey = GlobalKey<OverlayWindowAnchorState>();

  /// 是否正在显示
  bool get isShowing => _overlayAnchorKey.currentState.isShowing;

  /// 显示
  ///
  /// [anchor]-锚点，在父控件中的位置
  void show(Rect anchor) {
    final bounds = localToGlobal(context);
    _overlayAnchorKey.currentState.show(
      anchor: anchor.shift(bounds.topLeft),
      compositedTransformTarget: bounds,
      bounds: bounds,
    );
  }

  /// 隐藏
  void dismiss() {
    _overlayAnchorKey.currentState.dismiss();
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
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      child: widget.child,
    );
  }
}

/// 显示Overlay
class OverlayWindow {
  /// 显示Overlay
  OverlayWindow(this.context) : _overlay = AnimatedOverlay(context, rootOverlay: true);

  /// context
  final BuildContext context;
  final AnimatedOverlay _overlay;

  ModalRoute<dynamic> _route;

  /// 是否正在显示
  bool get isShowing => _overlay.isShowing;

  /// 显示完成，意思就是在remove了以后
  void whenCompleteOrCancel(ValueChanged<OverlayWindow> callback) {
    _overlay.whenCompleteOrCancel(() => callback(this));
  }

  /// 显示
  ///
  /// [anchor]-锚点，在屏幕中的位置
  /// [bounds]-边界，在屏幕中的位置
  /// [compositedTransformTarget]-compositedTransformTarget控件的坐标，默认为anchor的坐标
  void show({
    Rect anchor,
    Rect compositedTransformTarget,
    @required WidgetBuilder builder,
    double offset = 0,
    Size indicateSize = Size.zero,
    Axis direction = Axis.vertical,
    double margin = 0,
    double alignment = 0,
    LayerLink toolbarLayerLink,
    Rect bounds,
    bool immediately = false,
    Color backgroundColor = Colors.white,
    BorderRadiusGeometry borderRadius = _borderRadius,
    List<BoxShadow> shadows = _shadows,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    Color barrierColor,
    bool preferBelow = true,
  }) {
    assert(immediately != null);
    final currentAnchor = anchor ?? localToGlobal(context);
    _route = FlattererWindowRoute<dynamic>(
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
            child: _route.buildPage(context, animation, secondaryAnimation),
          ),
        );
        if (toolbarLayerLink != null) {
          child = CompositedTransformFollower(
            link: toolbarLayerLink,
            showWhenUnlinked: false,
            offset: -(compositedTransformTarget ?? currentAnchor).topLeft,
            child: child,
          );
        }
        return child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _route.buildTransitions(context, animation, secondaryAnimation, child);
      },
      transitionDuration: _route.transitionDuration,
      curve: _route.barrierCurve,
      immediately: immediately,
    );
  }

  /// 隐藏
  void dismiss({bool immediately = false}) {
    assert(immediately != null);
    if (_route == null) {
      _overlay.remove(immediately: true);
    } else {
      _overlay.remove(
        transitionDuration: _route.reverseTransitionDuration,
        curve: _route.barrierCurve,
        immediately: immediately,
      );
    }
  }

  /// 获取锚点state
  static OverlayWindow of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_OverlayWindowScope>();
    return widget?.overlayWindow;
  }
}

class _OverlayWindowScope extends InheritedWidget {
  const _OverlayWindowScope({
    Key key,
    @required this.overlayWindow,
    @required Widget child,
  })  : assert(overlayWindow != null),
        assert(child != null),
        super(key: key, child: child);

  final OverlayWindow overlayWindow;

  @override
  bool updateShouldNotify(_OverlayWindowScope old) => overlayWindow != old.overlayWindow;
}
