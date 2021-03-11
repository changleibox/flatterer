/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/dismiss_window_scope.dart';
import 'package:flatterer/src/flatterer_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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

void _onPostFrame(VoidCallback callback) {
  if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      callback?.call();
    });
  } else {
    callback?.call();
  }
}

/// Created by changlei on 2020/8/14.
///
/// 堆叠在原控件上的window，其实也不能算是window，只是控件的堆叠
class StackWindowContainer extends StatefulWidget {
  /// 浮动提示
  const StackWindowContainer({
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
  StackWindowContainerState createState() => StackWindowContainerState();
}

/// 浮动提示state
class StackWindowContainerState extends State<StackWindowContainer> with SingleTickerProviderStateMixin {
  final _focusNode = FocusScopeNode();

  Rect _anchor;
  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onFocusChanged(bool hasFocus) {
    if (!hasFocus) {
      dismiss();
    }
  }

  /// 是否正在显示
  bool get isShowing => _anchor != null;

  /// 显示
  ///
  /// [anchor]-锚点，这里坐标是相对于父控件的坐标
  void show(Rect anchor) {
    final isAnimate = _anchor == null || anchor == _anchor;

    final rectTween = RectTween(begin: _anchor, end: anchor);
    final animation = rectTween.animate(_controller);
    void _listener() {
      if (animation.isCompleted) {
        animation.removeListener(_listener);
      }
      _showOrUpdate(animation.value);
    }

    animation.addListener(_listener);

    if (isAnimate) {
      _controller.value = _controller.upperBound;
    } else {
      _controller.forward(from: _controller.lowerBound);
    }

    _anchor = anchor;
    _focusNode.requestFocus();
  }

  void _showOrUpdate(Rect anchor) {
    _onPostFrame(() {
      setState(() {
        _anchor = anchor;
      });
    });
  }

  /// 隐藏
  void dismiss() {
    _focusNode.unfocus();
    _onPostFrame(() {
      setState(() {
        _anchor = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusNode,
      canRequestFocus: true,
      onFocusChange: _onFocusChanged,
      child: Stack(
        children: [
          widget.child,
          StackWindow(
            anchor: _anchor,
            builder: widget.builder,
            offset: widget.offset,
            indicateSize: widget.indicateSize,
            direction: widget.direction,
            margin: widget.margin,
            alignment: widget.alignment,
            backgroundColor: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            shadows: widget.shadows,
            barrierDismissible: widget.barrierDismissible,
            barrierColor: widget.barrierColor,
            onDismiss: () {
              widget.onDismiss?.call();
              dismiss();
            },
          ),
        ],
      ),
    );
  }
}

/// 浮动提示
class StackWindow extends StatefulWidget {
  /// 浮动提示
  const StackWindow({
    Key key,
    @required this.anchor,
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
  })  : assert(builder != null),
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

  /// 锚点，这里坐标是相对于父控件的坐标
  final Rect anchor;

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
  StackWindowState createState() => StackWindowState();
}

/// 堆叠在原控件上的window，其实也不能算是window，只是控件的堆叠
class StackWindowState extends State<StackWindow> {
  ModalRoute<dynamic> _route;

  @override
  void initState() {
    _initOverlayWindow();
    super.initState();
  }

  @override
  void didUpdateWidget(StackWindow oldWidget) {
    if (widget.anchor == null && _route != null) {
      widget.onDismiss?.call();
    }
    _initOverlayWindow();
    super.didUpdateWidget(oldWidget);
  }

  /// 销毁
  void dismiss() {
    if (_route == null) {
      return;
    }
    widget.onDismiss?.call();
    _route = null;
  }

  void _initOverlayWindow() {
    if (widget.anchor == null) {
      _route = null;
      return;
    }
    _route = FlattererWindowRoute<dynamic>(
      widget.builder,
      widget.anchor,
      offset: widget.offset,
      direction: widget.direction,
      indicateSize: widget.indicateSize,
      margin: widget.margin,
      alignment: widget.alignment,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      shadows: widget.shadows,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
      capturedThemes: InheritedTheme.capture(from: context, to: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DismissWindowScope(
        dismiss: dismiss,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _route?.buildPage(context, null, null),
        ),
      ),
    );
  }
}