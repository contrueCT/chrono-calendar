import 'package:flutter/material.dart';

/// 页面过渡类型
enum PageTransitionType {
  /// 淡入淡出
  fade,

  /// 从右侧滑入
  slideRight,

  /// 从底部滑入
  slideUp,

  /// 缩放
  scale,

  /// 缩放 + 淡入
  scaleFade,

  /// 滑入 + 淡入
  slideFade,

  /// 共享元素（Hero）过渡
  shared,

  /// iOS 风格滑动
  cupertino,
}

/// 自定义页面过渡路由
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageRoute({
    required this.page,
    this.transitionType = PageTransitionType.slideFade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              transitionType,
              curve,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType type,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.scaleFade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );

      case PageTransitionType.slideFade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case PageTransitionType.shared:
        // 使用 Hero 动画的页面不需要额外过渡效果
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case PageTransitionType.cupertino:
        // iOS 风格的滑动效果
        final slideIn = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        return SlideTransition(
          position: slideIn,
          child: SlideTransition(
            position: slideOut,
            child: child,
          ),
        );
    }
  }
}

/// 模态底部弹窗过渡
class ModalBottomSheetRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final bool isDismissible;
  final bool enableDrag;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  ModalBottomSheetRoute({
    required this.builder,
    this.isDismissible = true,
    this.enableDrag = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    super.settings,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }
}

/// 页面过渡扩展方法
extension PageTransitionExtension on BuildContext {
  /// 使用自定义过渡效果导航到新页面
  Future<T?> pushWithTransition<T>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideFade,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.push<T>(
      this,
      CustomPageRoute<T>(
        page: page,
        transitionType: type,
        duration: duration,
        curve: curve,
      ),
    );
  }

  /// 使用自定义过渡效果替换当前页面
  Future<T?> pushReplacementWithTransition<T, TO>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideFade,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    TO? result,
  }) {
    return Navigator.pushReplacement<T, TO>(
      this,
      CustomPageRoute<T>(
        page: page,
        transitionType: type,
        duration: duration,
        curve: curve,
      ),
      result: result,
    );
  }
}

/// Hero 动画辅助组件
class HeroImage extends StatelessWidget {
  final String tag;
  final Widget child;
  final BorderRadius? borderRadius;

  const HeroImage({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: borderRadius != null
            ? ClipRRect(
                borderRadius: borderRadius!,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// 共享元素过渡动画包装器
class SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}
