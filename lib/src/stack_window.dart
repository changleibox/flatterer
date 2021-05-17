/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/dismiss_window_scope.dart';
import 'package:flatterer/src/flatterer_route.dart';
import 'package:flatterer/src/scheduler.dart';
import 'package:flatterer/src/track_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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
        assert(side != null),
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

  /// 跟踪者
  final LayerLink link;

  /// 隐藏回调
  final VoidCallback onDismiss;

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
  final Color barrierColor;

  /// 优先显示在末尾
  final bool preferBelow;

  @override
  StackWindowContainerState createState() => StackWindowContainerState();
}

/// 浮动提示state
class StackWindowContainerState extends State<StackWindowContainer> with SingleTickerProviderStateMixin {
  Rect _anchor;
  AnimationController _controller;
  VoidCallback _listener;
  Scheduler _scheduler;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: fadeDuration,
    );
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    _scheduler?.cancel();
    _scheduler = null;
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event) {
    if (!isShowing || !widget.barrierDismissible) {
      return;
    }
    final result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, event.position);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (result.path.map((e) => e.target).any((element) {
        final dynamic metaDate = element is RenderMetaData ? element.metaData : null;
        return metaDate != null && (metaDate == this || metaDate == widget.child);
      })) {
        return;
      }
      dismiss();
    }
  }

  /// 是否正在显示
  bool get isShowing => _anchor != null;

  /// 显示
  ///
  /// [anchor]-锚点，这里坐标是相对于父控件的坐标
  void show(Rect anchor, {TrackBehavior behavior = TrackBehavior.lazy}) {
    assert(anchor != null);
    assert(behavior != null);
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
      _showOrUpdate(value);
    }

    if (_listener != null) {
      animation.removeListener(_listener);
      _listener = null;
    }
    animation.addListener(_listener = listener);

    if (_anchor != null && anchor != _anchor && behavior != TrackBehavior.none) {
      _controller.forward(from: _controller.lowerBound);
    } else {
      _controller.value = _controller.upperBound;
    }
    if (behavior == TrackBehavior.sharp) {
      _anchor = anchor;
    }
  }

  void _showOrUpdate(Rect anchor) {
    _onPostFrame(() {
      if (!mounted || _anchor == anchor) {
        return;
      }
      setState(() {
        _anchor = anchor;
      });
    });
  }

  /// 隐藏
  void dismiss() {
    if (_listener != null) {
      _controller.removeListener(_listener);
      _listener = null;
      _controller.value = _controller.upperBound;
    }
    _onPostFrame(() {
      if (!mounted || _anchor == null) {
        return;
      }
      setState(() {
        _anchor = null;
      });
    });
  }

  void _onPostFrame(VoidCallback callback) {
    _scheduler?.cancel();
    _scheduler = Scheduler.postFrame(callback);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        StackWindow(
          anchor: _anchor,
          builder: (context) {
            return MetaData(
              metaData: this,
              behavior: HitTestBehavior.translucent,
              child: widget.builder(context),
            );
          },
          offset: widget.offset,
          indicateSize: widget.indicateSize,
          direction: widget.direction,
          margin: widget.margin,
          alignment: widget.alignment,
          link: widget.link,
          backgroundColor: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          shadows: widget.shadows,
          side: widget.side,
          barrierDismissible: widget.barrierDismissible,
          barrierColor: widget.barrierColor,
          preferBelow: widget.preferBelow,
          onDismiss: () {
            widget.onDismiss?.call();
            dismiss();
          },
        ),
      ],
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
  })  : assert(builder != null),
        assert(offset != null),
        assert(direction != null),
        assert(indicateSize != null),
        assert(margin != null),
        assert(alignment != null),
        assert(backgroundColor != null),
        assert(borderRadius != null),
        assert(shadows != null),
        assert(side != null),
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

  /// 跟踪者
  final LayerLink link;

  /// 隐藏回调
  final VoidCallback onDismiss;

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
    _route = FlattererRoute<dynamic>(
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
      side: widget.side,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      preferBelow: widget.preferBelow,
      capturedThemes: InheritedTheme.capture(from: context, to: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    var child = _route?.buildPage(context, null, null);
    if (child != null && widget.link != null) {
      child = CompositedTransformFollower(
        link: widget.link,
        showWhenUnlinked: false,
        offset: -widget.anchor.topLeft,
        child: child,
      );
    }
    return RepaintBoundary(
      child: DismissWindowScope(
        dismiss: dismiss,
        child: AnimatedSwitcher(
          duration: fadeDuration,
          transitionBuilder: (child, animation) {
            if (widget.barrierColor != null && widget.barrierColor.alpha != 0) {
              final color = animation.drive(
                ColorTween(
                  begin: widget.barrierColor.withOpacity(0.0),
                  end: widget.barrierColor,
                ).chain(CurveTween(curve: Curves.ease)),
              );
              child = AnimatedBuilder(
                animation: color,
                builder: (context, child) {
                  return ColoredBox(
                    color: color.value,
                    child: child,
                  );
                },
                child: child,
              );
            }
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }
}
