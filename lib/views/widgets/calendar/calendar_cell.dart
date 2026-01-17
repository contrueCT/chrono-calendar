import 'package:flutter/material.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/calendar_display_item.dart';

/// 日历单元格组件 - 显示单个日期
class CalendarCell extends StatelessWidget {
  /// 日期
  final DateTime date;

  /// 是否选中
  final bool isSelected;

  /// 是否是今天
  final bool isToday;

  /// 是否在当前月份
  final bool isInCurrentMonth;

  /// 该日期的事件列表（保留兼容性）
  final List<EventInstance> events;

  /// 该日期的所有日历项（事件 + 倒计时 + 待办）
  final List<CalendarDisplayItem> items;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否显示农历
  final bool showLunar;

  const CalendarCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.isInCurrentMonth = true,
    this.events = const [],
    this.items = const [],
    this.onTap,
    this.onLongPress,
    this.showLunar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 获取农历信息
    final lunarText = showLunar ? LunarUtils.getDisplayText(date) : null;
    final lunarInfo = showLunar ? LunarUtils.getLunarInfo(date) : null;

    // 判断是否是特殊日期（节气或节日）
    final isSpecialDay = lunarInfo?.hasSpecialDay ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 公历日期
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: _getTextColor(colorScheme),
              ),
            ),

            // 农历日期
            if (showLunar && lunarText != null) ...[
              const SizedBox(height: 1),
              Text(
                lunarText,
                style: TextStyle(
                  fontSize: 9,
                  color: _getLunarTextColor(colorScheme, isSpecialDay),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // 事件标记（使用 items 如果提供，否则回退到 events）
            if (items.isNotEmpty) ...[
              const SizedBox(height: 2),
              _buildItemMarkers(colorScheme),
            ] else if (events.isNotEmpty) ...[
              const SizedBox(height: 2),
              _buildEventMarkers(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary;
    }
    if (isToday) {
      return colorScheme.primaryContainer.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  /// 获取文字颜色
  Color _getTextColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.onPrimary;
    }
    if (!isInCurrentMonth) {
      return colorScheme.onSurface.withOpacity(0.4);
    }
    if (isToday) {
      return colorScheme.primary;
    }
    // 周末颜色
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return colorScheme.error.withOpacity(0.8);
    }
    return colorScheme.onSurface;
  }

  /// 获取农历文字颜色
  Color _getLunarTextColor(ColorScheme colorScheme, bool isSpecialDay) {
    if (isSelected) {
      return colorScheme.onPrimary.withOpacity(0.8);
    }
    if (!isInCurrentMonth) {
      return colorScheme.onSurface.withOpacity(0.3);
    }
    if (isSpecialDay) {
      return colorScheme.primary;
    }
    return colorScheme.onSurfaceVariant;
  }

  /// 构建事件标记点
  Widget _buildEventMarkers(ColorScheme colorScheme) {
    // 最多显示 3 个标记点
    final displayEvents = events.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayEvents.map((event) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.onPrimary.withOpacity(0.8)
                : Color(event.event.color ?? colorScheme.primary.value),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  /// 构建日历项标记（支持倒计时/待办标签 + 事件小点）
  Widget _buildItemMarkers(ColorScheme colorScheme) {
    // 分离不同类型的项目
    final countdowns = items.whereType<CountdownDisplayItem>().toList();
    final todos = items.whereType<TodoDisplayItem>().where((t) => !t.isCompleted).toList();
    final eventItems = items.whereType<EventDisplayItem>().toList();

    // 优先显示倒计时和待办的标签（最多1个）
    final labelItems = [...countdowns, ...todos];
    final hasLabel = labelItems.isNotEmpty;

    // 如果有标签项目，显示第一个标签
    if (hasLabel) {
      final firstItem = labelItems.first;
      final itemColor = _getItemColor(firstItem, colorScheme);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.onPrimary.withOpacity(0.2)
                : itemColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            firstItem.title,
            style: TextStyle(
              fontSize: 8,
              color: isSelected ? colorScheme.onPrimary : itemColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 否则显示事件小点
    if (eventItems.isNotEmpty) {
      final displayEvents = eventItems.take(3).toList();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: displayEvents.map((item) {
          return Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.onPrimary.withOpacity(0.8)
                  : _getItemColor(item, colorScheme),
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  /// 获取日历项的显示颜色
  Color _getItemColor(CalendarDisplayItem item, ColorScheme colorScheme) {
    // 如果有自定义颜色，使用自定义颜色
    if (item.color != null) {
      return Color(item.color!);
    }

    // 根据类型返回默认颜色
    switch (item.itemType) {
      case CalendarItemType.countdown:
        return Colors.orange;
      case CalendarItemType.todo:
        final todoItem = item as TodoDisplayItem;
        // 根据优先级返回颜色
        switch (todoItem.priority) {
          case 3:
            return Colors.red;
          case 2:
            return Colors.orange;
          case 1:
            return Colors.blue;
          default:
            return Colors.teal;
        }
      case CalendarItemType.event:
        return colorScheme.primary;
    }
  }
}

/// 全天事件标签组件
class AllDayEventBadge extends StatelessWidget {
  final EventInstance event;
  final VoidCallback? onTap;

  const AllDayEventBadge({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(event.event.color ?? Theme.of(context).colorScheme.primary.value);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Text(
          event.event.summary,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
