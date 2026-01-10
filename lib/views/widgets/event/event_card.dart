import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';

/// 事件卡片组件 - 显示事件详情
class EventCard extends StatelessWidget {
  /// 事件实例
  final EventInstance event;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否紧凑模式
  final bool compact;

  /// 是否显示日期
  final bool showDate;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventColor = Color(event.event.color ?? colorScheme.primary.value);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 16,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左侧颜色条
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 10 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.event.summary,
                              style: TextStyle(
                                fontSize: compact ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.event.isRecurring)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.repeat,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: compact ? 4 : 8),

                      // 时间信息
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeRange(),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (showDate) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('M月d日').format(event.instanceStart),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // 地点信息（非紧凑模式）
                      if (!compact && event.event.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.event.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化时间范围
  String _formatTimeRange() {
    if (event.event.isAllDay) {
      return '全天';
    }

    final startTime = DateFormat('HH:mm').format(event.instanceStart);
    final endTime = DateFormat('HH:mm').format(event.instanceEnd);
    return '$startTime - $endTime';
  }
}

/// 渐变事件卡片 - 用于周视图/日视图的时间轴
class GradientEventCard extends StatelessWidget {
  /// 事件实例
  final EventInstance event;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 卡片高度
  final double? height;

  const GradientEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(
      event.event.color ?? Theme.of(context).colorScheme.primary.value,
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              eventColor.withOpacity(0.9),
              eventColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: eventColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              event.event.summary,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // 时间（如果高度足够）
            if (height == null || height! > 40) ...[
              const SizedBox(height: 2),
              Text(
                _formatTimeRange(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],

            // 地点（如果高度足够）
            if ((height == null || height! > 60) && event.event.location != null) ...[
              const SizedBox(height: 2),
              Text(
                event.event.location!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeRange() {
    if (event.event.isAllDay) {
      return '全天';
    }
    final startTime = DateFormat('HH:mm').format(event.instanceStart);
    return startTime;
  }
}

/// 事件列表项组件 - 用于事件列表
class EventListTile extends StatelessWidget {
  final EventInstance event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventColor = Color(event.event.color ?? colorScheme.primary.value);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: eventColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        event.event.summary,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        _formatSubtitle(),
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: event.event.isRecurring
          ? Icon(
              Icons.repeat,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }

  String _formatSubtitle() {
    if (event.event.isAllDay) {
      return '全天';
    }

    final startTime = DateFormat('HH:mm').format(event.instanceStart);
    final endTime = DateFormat('HH:mm').format(event.instanceEnd);

    if (event.event.location != null) {
      return '$startTime - $endTime · ${event.event.location}';
    }

    return '$startTime - $endTime';
  }
}
