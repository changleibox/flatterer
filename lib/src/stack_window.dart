/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'package:flatterer/src/dimens.dart';
import 'package:flatterer/src/dismiss_window_scope.dart';
import 'package:flatterer/src/flatterer_route.dart';
import 'package:flatterer/src/hit_test_detector.dart';
import 'package:flatterer/src/scheduler.dart';
import 'package:flatterer/src/track_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Created by changlei on 2020/8/14.
///
/// 堆叠在原控件上的window，其实也不能算是window，只是控件的堆叠
class StackWindowContainer extends StatefulWidget {
  /// 浮动提示
  const StackWindowContainer({
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
  StackWindowContainerState createState() => StackWindowContainerState();
}

/// 浮动提示state
class StackWindowContainerState extends State<StackWindowContainer> with SingleTickerProviderStateMixin {
  final _hitTestDetector = HitTestDetector();

  late AnimationController _controller;
  Rect? _anchor;
  VoidCallback? _listener;
  Scheduler? _scheduler;
  bool _isTapDownHit = false;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: fadeDuration,
    );
    _hitTestDetector.setup(
      onPointerEvent: _handlePointerEvent,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scheduler?.cancel();
    _scheduler = null;
    _hitTestDetector.dispose();
    super.dispose();
  }

  bool _visitAny(HitTestTarget target, Object? data) {
    return data != null && (data == this || data == widget.child);
  }

  void _handlePointerEvent(PointerEvent event) {
    if (!isShowing || !widget.barrierDismissible || widget.modalBarrier) {
      return;
    }
    if (event is PointerDownEvent) {
      _isTapDownHit = event.result.any(_visitAny);
    } else if (event is PointerUpEvent && !_isTapDownHit && !event.result.any(_visitAny)) {
      _isTapDownHit = false;
      dismiss();
    }
  }

  /// 是否正在显示
  bool get isShowing => _anchor != null;

  /// 显示
  ///
  /// [anchor]-锚点，这里坐标是相对于父控件的坐标
  void show(Rect anchor, {TrackBehavior behavior = TrackBehavior.lazy}) {
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
      animation.removeListener(_listener!);
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

  void _showOrUpdate(Rect? anchor) {
    _onPostFrame(() {
      if (!mounted) {
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
      _controller.removeListener(_listener!);
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
          modalBarrier: widget.modalBarrier,
          showWhenUnlinked: widget.showWhenUnlinked,
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
    Key? key,
    required this.anchor,
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

  /// 锚点，这里坐标是相对于父控件的坐标
  final Rect? anchor;

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
  StackWindowState createState() => StackWindowState();
}

/// 堆叠在原控件上的window，其实也不能算是window，只是控件的堆叠
class StackWindowState extends State<StackWindow> with TickerProviderStateMixin {
  ModalRoute<dynamic>? _route;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      widget.anchor!,
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
    var child = _route?.buildPage(context, _controller, _controller);
    if (child != null && widget.link != null) {
      child = CompositedTransformFollower(
        link: widget.link!,
        showWhenUnlinked: widget.showWhenUnlinked,
        offset: -widget.anchor!.topLeft,
        child: child,
      );
    }
    return RepaintBoundary(
      child: DismissWindowScope(
        dismiss: dismiss,
        child: AnimatedSwitcher(
          duration: fadeDuration,
          transitionBuilder: (child, animation) {
            if (widget.modalBarrier) {
              child = Stack(
                children: [
                  _buildModalBarrier(context, animation),
                  child,
                ],
              );
            } else if (widget.barrierColor != null && widget.barrierColor!.alpha != 0) {
              final color = animation.drive(
                ColorTween(
                  begin: widget.barrierColor!.withOpacity(0.0),
                  end: widget.barrierColor,
                ).chain(CurveTween(curve: Curves.ease)),
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

  Widget _buildModalBarrier(BuildContext context, Animation<double> animation) {
    final barrierColor = widget.barrierColor;
    final barrierDismissible = widget.barrierDismissible;
    final barrierLabel = _route?.barrierLabel;
    final semanticsDismissible = _route?.semanticsDismissible == true;
    Widget barrier;
    if (barrierColor != null && barrierColor.alpha != 0) {
      final color = animation.drive(
        ColorTween(
          begin: barrierColor.withOpacity(0.0),
          end: barrierColor, // changedInternalState is called if barrierColor updates
        ).chain(CurveTween(curve: Curves.ease)), // changedInternalState is called if barrierCurve updates
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
}
