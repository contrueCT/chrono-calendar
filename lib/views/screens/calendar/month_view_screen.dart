import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../../../viewmodels/settings_viewmodel.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/calendar_display_item.dart';
import '../../widgets/calendar/calendar_cell.dart';
import '../../widgets/event/event_card.dart';

/// 月视图页面
class MonthViewScreen extends StatelessWidget {
  const MonthViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 月份导航栏
            _MonthNavigationBar(viewModel: viewModel),

            // 星期标题行
            Consumer<SettingsViewModel>(
              builder: (context, settings, _) => _WeekdayHeader(
                weekStartDay: settings.weekStartDay,
              ),
            ),

            // 日历网格
            Expanded(
              child: Consumer<SettingsViewModel>(
                builder: (context, settings, _) => _MonthGrid(
                  viewModel: viewModel,
                  showLunar: settings.showLunar,
                  weekStartDay: settings.weekStartDay,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 月份导航栏
class _MonthNavigationBar extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _MonthNavigationBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一月按钮
          IconButton(
            onPressed: viewModel.goToPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一月',
          ),

          // 月份标题（可点击跳转）
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewModel.currentMonthTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // 下一月按钮
          IconButton(
            onPressed: viewModel.goToNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一月',
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final initialDate = viewModel.focusedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      viewModel.jumpToDate(pickedDate);
    }
  }
}

/// 星期标题行
class _WeekdayHeader extends StatelessWidget {
  final int weekStartDay;

  const _WeekdayHeader({required this.weekStartDay});

  // 周一到周日的标签，索引对应 DateTime.weekday - 1
  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据起始日重新排列星期标签
    final orderedWeekdays = _getOrderedWeekdays();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: orderedWeekdays.map((entry) {
          final dayOfWeek = entry['dayOfWeek'] as int; // 1-7
          final label = entry['label'] as String;
          final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;

          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isWeekend
                      ? colorScheme.error.withOpacity(0.8)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 根据起始日获取排序后的星期列表
  List<Map<String, dynamic>> _getOrderedWeekdays() {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      // 计算当前位置对应的星期几 (1-7)
      int dayOfWeek = ((weekStartDay - 1 + i) % 7) + 1;
      result.add({
        'dayOfWeek': dayOfWeek,
        'label': _weekdayLabels[dayOfWeek - 1],
      });
    }
    return result;
  }
}

/// 月历网格
class _MonthGrid extends StatelessWidget {
  final CalendarViewModel viewModel;
  final bool showLunar;
  final int weekStartDay;

  const _MonthGrid({
    required this.viewModel,
    required this.showLunar,
    required this.weekStartDay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            // 向左滑动 → 下一月
            viewModel.goToNext();
          } else if (details.primaryVelocity! > 300) {
            // 向右滑动 → 上一月
            viewModel.goToPrevious();
          }
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // 日历网格
              Expanded(
                flex: 2,
                child: _buildCalendarGrid(context, constraints),
              ),

              // 选中日期的事件列表
              Expanded(
                flex: 1,
                child: _SelectedDateEvents(viewModel: viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, BoxConstraints constraints) {
    final dates = _generateMonthDates();
    final weeks = _groupIntoWeeks(dates);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: weeks.map((week) {
          return Expanded(
            child: Row(
              children: week.map((date) {
                return Expanded(
                  child: CalendarCell(
                    date: date,
                    isSelected: viewModel.isSelectedDate(date),
                    isToday: viewModel.isToday(date),
                    isInCurrentMonth: viewModel.isInCurrentMonth(date),
                    items: viewModel.getItemsForDate(date),
                    onTap: () => viewModel.selectDate(date),
                    showLunar: showLunar,
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 生成月视图的日期列表（包括前后月份的日期）
  List<DateTime> _generateMonthDates() {
    final year = viewModel.focusedDate.year;
    final month = viewModel.focusedDate.month;

    // 当月第一天
    final firstDayOfMonth = DateTime(year, month, 1);
    // 当月最后一天
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // 计算需要显示的第一天（上月的日期）
    // 根据设置的起始日计算偏移
    int daysBeforeFirst = (firstDayOfMonth.weekday - weekStartDay + 7) % 7;
    final firstVisibleDate = firstDayOfMonth.subtract(Duration(days: daysBeforeFirst));

    // 计算需要显示的最后一天（下月的日期）
    // 计算当月最后一天距离该周结束还有几天
    int daysAfterLast = (weekStartDay - 1 - lastDayOfMonth.weekday + 7) % 7;
    final lastVisibleDate = lastDayOfMonth.add(Duration(days: daysAfterLast));

    // 生成日期列表
    final dates = <DateTime>[];
    var currentDate = firstVisibleDate;
    while (!currentDate.isAfter(lastVisibleDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  /// 将日期列表分组为周
  List<List<DateTime>> _groupIntoWeeks(List<DateTime> dates) {
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < dates.length; i += 7) {
      weeks.add(dates.sublist(i, (i + 7).clamp(0, dates.length)));
    }
    return weeks;
  }
}

/// 选中日期的日程列表（包含事件、倒计时和待办）
class _SelectedDateEvents extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _SelectedDateEvents({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = viewModel.selectedDateItems;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  _formatSelectedDate(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _getItemCountText(items),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 日程列表
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(context, items[index], colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    final date = viewModel.selectedDate;
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];

    if (viewModel.isToday(date)) {
      return '今天 · $weekday';
    }

    return '${date.month}月${date.day}日 · $weekday';
  }

  String _getItemCountText(List<CalendarDisplayItem> items) {
    if (items.isEmpty) return '暂无日程';

    final eventCount = items.whereType<EventDisplayItem>().length;
    final countdownCount = items.whereType<CountdownDisplayItem>().length;
    final todoCount = items.whereType<TodoDisplayItem>().length;

    final parts = <String>[];
    if (eventCount > 0) parts.add('$eventCount 日程');
    if (countdownCount > 0) parts.add('$countdownCount 倒计时');
    if (todoCount > 0) parts.add('$todoCount 待办');

    return parts.join(' · ');
  }

  Widget _buildItemCard(BuildContext context, CalendarDisplayItem item, ColorScheme colorScheme) {
    switch (item.itemType) {
      case CalendarItemType.event:
        final eventItem = item as EventDisplayItem;
        return EventCard(
          event: eventItem.eventInstance,
          compact: true,
          onTap: () => _onEventTap(context, eventItem.eventInstance),
        );

      case CalendarItemType.countdown:
        final countdownItem = item as CountdownDisplayItem;
        return _CountdownCard(
          item: countdownItem,
          onTap: () => _onCountdownTap(context, countdownItem),
        );

      case CalendarItemType.todo:
        final todoItem = item as TodoDisplayItem;
        return _TodoCard(
          item: todoItem,
          onTap: () => _onTodoTap(context, todoItem),
        );
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 40,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无日程',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _onEventTap(BuildContext context, EventInstance event) {
    // 导航到事件详情页，传递实例日期用于重复事件
    final instanceDateParam = event.instanceStart.toIso8601String();
    context.push('/event/${event.event.uid}?instanceDate=$instanceDateParam');
  }

  void _onCountdownTap(BuildContext context, CountdownDisplayItem item) {
    // 导航到倒计时编辑页
    context.push('/countdown/${item.countdown.id}');
  }

  void _onTodoTap(BuildContext context, TodoDisplayItem item) {
    // TODO: 导航到待办编辑页（待实现）
    // context.push('/todo/${item.todoId}');
  }
}

/// 倒计时卡片组件
class _CountdownCard extends StatelessWidget {
  final CountdownDisplayItem item;
  final VoidCallback? onTap;

  const _CountdownCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemColor = item.color != null ? Color(item.color!) : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: itemColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.displayIcon,
                  color: itemColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.countdown.getCategoryName(),
                            style: TextStyle(
                              fontSize: 10,
                              color: itemColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 剩余天数
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.daysRemaining == 0 ? '今天' : '${item.daysRemaining}',
                    style: TextStyle(
                      fontSize: item.daysRemaining == 0 ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: itemColor,
                    ),
                  ),
                  if (item.daysRemaining != 0)
                    Text(
                      '天',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 待办卡片组件
class _TodoCard extends StatelessWidget {
  final TodoDisplayItem item;
  final VoidCallback? onTap;

  const _TodoCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据优先级和完成状态决定颜色
    Color itemColor;
    if (item.isCompleted) {
      itemColor = Colors.grey;
    } else if (item.isOverdue) {
      itemColor = Colors.red;
    } else {
      switch (item.priority) {
        case 3:
          itemColor = Colors.red;
          break;
        case 2:
          itemColor = Colors.orange;
          break;
        case 1:
          itemColor = Colors.blue;
          break;
        default:
          itemColor = Colors.teal;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: itemColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 完成状态图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: itemColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: item.isCompleted
                            ? colorScheme.onSurface.withOpacity(0.5)
                            : colorScheme.onSurface,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.getSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isOverdue
                            ? Colors.red
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 优先级标签
              if (item.priority > 0 && !item.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.priorityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: itemColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
