import 'package:flutter/material.dart';

/// 动画常量
class AnimationConstants {
  AnimationConstants._();

  /// 快速动画时长
  static const Duration fast = Duration(milliseconds: 150);

  /// 标准动画时长
  static const Duration standard = Duration(milliseconds: 250);

  /// 中等动画时长
  static const Duration medium = Duration(milliseconds: 350);

  /// 慢速动画时长
  static const Duration slow = Duration(milliseconds: 500);

  /// 页面过渡时长
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// 标准缓动曲线
  static const Curve standardCurve = Curves.easeInOut;

  /// 弹性缓动曲线
  static const Curve bouncyCurve = Curves.elasticOut;

  /// 快速缓动曲线
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// 减速缓动曲线
  static const Curve decelerate = Curves.decelerate;
}

/// 列表项交错动画控制器
class StaggeredAnimationController {
  final int itemCount;
  final Duration itemDelay;
  final Duration itemDuration;

  StaggeredAnimationController({
    required this.itemCount,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
  });

  /// 获取指定索引项的动画延迟
  Duration getDelay(int index) {
    return Duration(milliseconds: itemDelay.inMilliseconds * index);
  }

  /// 获取总动画时长
  Duration get totalDuration {
    return Duration(
      milliseconds:
          itemDelay.inMilliseconds * (itemCount - 1) + itemDuration.inMilliseconds,
    );
  }
}

/// 动画 Widget 扩展
extension AnimatedWidgetExtension on Widget {
  /// 添加淡入动画
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeIn,
  }) {
    return _FadeInWidget(
      duration: duration,
      delay: delay,
      curve: curve,
      child: this,
    );
  }

  /// 添加滑入动画
  Widget slideIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutCubic,
    Offset begin = const Offset(0, 0.1),
  }) {
    return _SlideInWidget(
      duration: duration,
      delay: delay,
      curve: curve,
      begin: begin,
      child: this,
    );
  }

  /// 添加缩放动画
  Widget scaleIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutBack,
    double begin = 0.8,
  }) {
    return _ScaleInWidget(
      duration: duration,
      delay: delay,
      curve: curve,
      begin: begin,
      child: this,
    );
  }

  /// 组合动画：淡入 + 滑入
  Widget fadeSlideIn({
    Duration duration = const Duration(milliseconds: 350),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutCubic,
    Offset slideBegin = const Offset(0, 0.05),
  }) {
    return _FadeSlideInWidget(
      duration: duration,
      delay: delay,
      curve: curve,
      slideBegin: slideBegin,
      child: this,
    );
  }
}

/// 淡入动画 Widget
class _FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const _FadeInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
  });

  @override
  State<_FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<_FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// 滑入动画 Widget
class _SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset begin;

  const _SlideInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.begin,
  });

  @override
  State<_SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<_SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

/// 缩放动画 Widget
class _ScaleInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double begin;

  const _ScaleInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.begin,
  });

  @override
  State<_ScaleInWidget> createState() => _ScaleInWidgetState();
}

class _ScaleInWidgetState extends State<_ScaleInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.begin,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// 组合动画：淡入 + 滑入
class _FadeSlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideBegin;

  const _FadeSlideInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.slideBegin,
  });

  @override
  State<_FadeSlideInWidget> createState() => _FadeSlideInWidgetState();
}

class _FadeSlideInWidgetState extends State<_FadeSlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: widget.slideBegin,
      end: Offset.zero,
    ).animate(curvedAnimation);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 交错列表动画构建器
class StaggeredListBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration itemDelay;
  final Duration itemDuration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const StaggeredListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemBuilder: (context, index) {
        return itemBuilder(context, index).fadeSlideIn(
          delay: Duration(milliseconds: itemDelay.inMilliseconds * index),
          duration: itemDuration,
        );
      },
    );
  }
}

/// 按压缩放效果
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}
