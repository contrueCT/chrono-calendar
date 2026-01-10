import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../../../data/models/event_model.dart';
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
            const _WeekdayHeader(),

            // 日历网格
            Expanded(
              child: _MonthGrid(viewModel: viewModel),
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
  const _WeekdayHeader();

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: _weekdays.asMap().entries.map((entry) {
          final index = entry.key;
          final weekday = entry.value;
          final isWeekend = index >= 5;

          return Expanded(
            child: Center(
              child: Text(
                weekday,
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
}

/// 月历网格
class _MonthGrid extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _MonthGrid({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                    events: viewModel.getEventsForDate(date),
                    onTap: () => viewModel.selectDate(date),
                    showLunar: true,
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
    // 周一为一周开始
    int daysBeforeFirst = firstDayOfMonth.weekday - 1;
    final firstVisibleDate = firstDayOfMonth.subtract(Duration(days: daysBeforeFirst));

    // 计算需要显示的最后一天（下月的日期）
    int daysAfterLast = 7 - lastDayOfMonth.weekday;
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

/// 选中日期的事件列表
class _SelectedDateEvents extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _SelectedDateEvents({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final events = viewModel.selectedDateEvents;

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
                  '${events.length} 个事件',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 事件列表
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return EventCard(
                        event: events[index],
                        compact: true,
                        onTap: () => _onEventTap(context, events[index]),
                      );
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
    // TODO: 导航到事件详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了事件: ${event.event.summary}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
