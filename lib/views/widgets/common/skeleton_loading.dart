import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 骨架屏基础组件
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 骨架屏圆形组件
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    this.size = 48,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 骨架屏文本行
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin,
    );
  }
}

/// 骨架屏段落（多行文本）
class SkeletonParagraph extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double lineSpacing;
  final double? lastLineWidth;

  const SkeletonParagraph({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.lineSpacing = 8,
    this.lastLineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return SkeletonLine(
          height: lineHeight,
          width: isLast ? lastLineWidth : null,
          margin: isLast ? null : EdgeInsets.only(bottom: lineSpacing),
        );
      }),
    );
  }
}

/// Shimmer 效果包装器
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlight =
        highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}

/// 事件卡片骨架屏
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 时间指示器
            const SkeletonBox(
              width: 4,
              height: 50,
              borderRadius: 2,
            ),
            const SizedBox(width: 12),
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 150, height: 18),
                  const SizedBox(height: 8),
                  SkeletonLine(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 14,
                  ),
                ],
              ),
            ),
            // 时间标签
            const SkeletonBox(width: 50, height: 20),
          ],
        ),
      ),
    );
  }
}

/// 事件列表骨架屏
class EventListSkeleton extends StatelessWidget {
  final int itemCount;

  const EventListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const EventCardSkeleton(),
    );
  }
}

/// 日历网格骨架屏
class CalendarGridSkeleton extends StatelessWidget {
  const CalendarGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 月份标题
            const SkeletonBox(width: 120, height: 24),
            const SizedBox(height: 16),
            // 星期标题行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                7,
                (_) => const SkeletonBox(width: 30, height: 16),
              ),
            ),
            const SizedBox(height: 12),
            // 日期网格
            ...List.generate(
              5,
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    7,
                    (_) => const SkeletonBox(width: 36, height: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 倒计时卡片骨架屏
class CountdownCardSkeleton extends StatelessWidget {
  const CountdownCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 图标
            const SkeletonCircle(size: 48),
            const SizedBox(width: 16),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 120, height: 18),
                  SizedBox(height: 6),
                  SkeletonLine(width: 80, height: 14),
                ],
              ),
            ),
            // 天数
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SkeletonBox(width: 50, height: 28),
                SizedBox(height: 4),
                SkeletonLine(width: 30, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 天气卡片骨架屏
class WeatherCardSkeleton extends StatelessWidget {
  const WeatherCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 温度和天气图标
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 80, height: 40),
                SizedBox(height: 8),
                SkeletonLine(width: 60, height: 16),
              ],
            ),
            const Spacer(),
            // 天气图标
            const SkeletonCircle(size: 64),
          ],
        ),
      ),
    );
  }
}

/// 详情页骨架屏
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            const SkeletonBox(width: double.infinity, height: 120),
            const SizedBox(height: 24),
            // 信息行
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: const [
                    SkeletonBox(width: 40, height: 40, borderRadius: 10),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 100, height: 16),
                          SizedBox(height: 6),
                          SkeletonLine(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 描述区域
            const SkeletonParagraph(lines: 4),
          ],
        ),
      ),
    );
  }
}

/// 搜索结果骨架屏
class SearchResultSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchResultSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 16,
                    ),
                    const SizedBox(height: 6),
                    SkeletonLine(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 通用内容加载状态组件
class ContentLoader<T> extends StatelessWidget {
  final Future<T>? future;
  final T? data;
  final bool isLoading;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object? error)? errorBuilder;
  final Widget? emptyWidget;
  final bool Function(T? data)? isEmpty;

  const ContentLoader({
    super.key,
    this.future,
    this.data,
    this.isLoading = false,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    // 使用直接数据
    if (data != null && !isLoading) {
      if (isEmpty?.call(data) ?? false) {
        return emptyWidget ?? _buildEmptyState(context);
      }
      return builder(data as T);
    }

    if (isLoading) {
      return loadingWidget ?? _buildLoadingState();
    }

    // 使用 Future
    if (future != null) {
      return FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingWidget ?? _buildLoadingState();
          }

          if (snapshot.hasError) {
            return errorBuilder?.call(snapshot.error) ??
                _buildErrorState(context, snapshot.error);
          }

          if (snapshot.data == null ||
              (isEmpty?.call(snapshot.data) ?? false)) {
            return emptyWidget ?? _buildEmptyState(context);
          }

          return builder(snapshot.data as T);
        },
      );
    }

    return emptyWidget ?? _buildEmptyState(context);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? '未知错误',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无内容',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
