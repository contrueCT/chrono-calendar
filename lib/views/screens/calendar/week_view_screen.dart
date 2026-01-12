import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../../../data/models/event_model.dart';
import '../../widgets/calendar/draggable_event.dart';

/// 周视图页面
class WeekViewScreen extends StatelessWidget {
  const WeekViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 周导航栏
            _WeekNavigationBar(viewModel: viewModel),

            // 日期选择条
            _WeekDaySelector(viewModel: viewModel),

            // 时间轴和事件区域
            Expanded(
              child: _WeekTimeGrid(viewModel: viewModel),
            ),
          ],
        );
      },
    );
  }
}

/// 周导航栏
class _WeekNavigationBar extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _WeekNavigationBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一周按钮
          IconButton(
            onPressed: viewModel.goToPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一周',
          ),

          // 周标题
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewModel.currentWeekTitle,
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

          // 下一周按钮
          IconButton(
            onPressed: viewModel.goToNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一周',
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

/// 周日期选择条
class _WeekDaySelector extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _WeekDaySelector({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weekDates = _getWeekDates();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧时间轴占位
          const SizedBox(width: 48),

          // 周日期
          ...weekDates.map((date) {
            final isSelected = viewModel.isSelectedDate(date);
            final isToday = viewModel.isToday(date);
            final isWeekend = date.weekday >= 6;

            return Expanded(
              child: GestureDetector(
                onTap: () => viewModel.selectDate(date),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isToday
                            ? colorScheme.primaryContainer.withOpacity(0.5)
                            : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // 星期
                      Text(
                        _getWeekdayName(date.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : isWeekend
                                  ? colorScheme.error.withOpacity(0.8)
                                  : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 日期
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : isToday
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DateTime> _getWeekDates() {
    final focusedDate = viewModel.focusedDate;
    // 周一为一周开始
    final weekStart = focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }
}

/// 周时间网格
class _WeekTimeGrid extends StatefulWidget {
  final CalendarViewModel viewModel;

  const _WeekTimeGrid({required this.viewModel});

  @override
  State<_WeekTimeGrid> createState() => _WeekTimeGridState();
}

class _WeekTimeGridState extends State<_WeekTimeGrid> {
  final ScrollController _scrollController = ScrollController();
  static const double hourHeight = 60.0;
  static const int startHour = 0;
  static const int endHour = 24;

  @override
  void initState() {
    super.initState();
    // 初始滚动到当前时间附近
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final targetOffset = (now.hour - 1) * hourHeight;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(targetOffset.clamp(0, _scrollController.position.maxScrollExtent));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weekDates = _getWeekDates();

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: (endHour - startHour) * hourHeight,
        child: Stack(
          children: [
            // 时间网格背景
            Row(
              children: [
                // 左侧时间轴
                _buildTimeAxis(colorScheme),

                // 日期列
                ...weekDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  return Expanded(
                    child: _buildDayColumn(context, date, index == 6, colorScheme),
                  );
                }),
              ],
            ),

            // 当前时间指示线
            _buildCurrentTimeIndicator(colorScheme),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getWeekDates() {
    final focusedDate = widget.viewModel.focusedDate;
    final weekStart = focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  Widget _buildTimeAxis(ColorScheme colorScheme) {
    return SizedBox(
      width: 48,
      child: Column(
        children: List.generate(endHour - startHour, (index) {
          final hour = startHour + index;
          return SizedBox(
            height: hourHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 0),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    DateTime date,
    bool isLast,
    ColorScheme colorScheme,
  ) {
    final events = widget.viewModel.getEventsForDate(date);
    final nonAllDayEvents = events.where((e) => !e.event.isAllDay).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5),
          right: isLast
              ? BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          // 小时分割线
          Column(
            children: List.generate(endHour - startHour, (index) {
              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),

          // 事件块
          ...nonAllDayEvents.map((event) => _buildEventBlock(context, event, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildEventBlock(
    BuildContext context,
    EventInstance event,
    ColorScheme colorScheme,
  ) {
    return CompactDraggableEvent(
      event: event,
      hourHeight: hourHeight,
      onTap: () => _onEventTap(context, event),
      onDragComplete: (newStart, newEnd) => _onEventDragComplete(
        context,
        event,
        newStart,
        newEnd,
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(ColorScheme colorScheme) {
    final now = DateTime.now();
    final weekDates = _getWeekDates();

    // 检查今天是否在本周内
    final todayIndex = weekDates.indexWhere(
      (date) => date.year == now.year && date.month == now.month && date.day == now.day,
    );

    if (todayIndex == -1) return const SizedBox.shrink();

    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final top = minutesSinceMidnight * hourHeight / 60;

    // 计算指示线的左偏移（时间轴宽度 + 前面日期列的宽度）
    return Positioned(
      left: 48,
      right: 0,
      top: top,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dayWidth = constraints.maxWidth / 7;
          final leftOffset = todayIndex * dayWidth;

          return Row(
            children: [
              SizedBox(width: leftOffset),
              // 红色圆点
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              // 红色线
              Expanded(
                child: Container(
                  height: 1.5,
                  color: colorScheme.error.withOpacity(0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onEventTap(BuildContext context, EventInstance event) {
    // 跳转到事件详情页
    final instanceDateStr = event.instanceStart.toIso8601String();
    context.push('/event/${event.event.uid}?instanceDate=$instanceDateStr');
  }

  Future<void> _onEventDragComplete(
    BuildContext context,
    EventInstance event,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final viewModel = widget.viewModel;
    final success = await viewModel.updateEventTime(event, newStart, newEnd);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已更新: ${event.event.summary}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                // 撤销：恢复原始时间
                await viewModel.updateEventTime(
                  EventInstance(
                    event: event.event.copyWith(
                      dtStart: newStart,
                      dtEnd: newEnd,
                    ),
                    instanceStart: newStart,
                    instanceEnd: newEnd,
                  ),
                  event.instanceStart,
                  event.instanceEnd,
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新失败，请重试'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// 全天事件区域
class AllDayEventsSection extends StatelessWidget {
  final CalendarViewModel viewModel;
  final List<DateTime> weekDates;

  const AllDayEventsSection({
    super.key,
    required this.viewModel,
    required this.weekDates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 收集本周的全天事件
    final allDayEvents = <DateTime, List<EventInstance>>{};
    for (final date in weekDates) {
      final events = viewModel.getEventsForDate(date).where((e) => e.event.isAllDay).toList();
      if (events.isNotEmpty) {
        allDayEvents[date] = events;
      }
    }

    if (allDayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧标签
          SizedBox(
            width: 48,
            child: Text(
              '全天',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // 每天的全天事件
          ...weekDates.map((date) {
            final events = allDayEvents[date] ?? [];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(2).map((event) {
                    final eventColor = Color(
                      event.event.color ?? colorScheme.primary.value,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.event.summary,
                        style: TextStyle(
                          fontSize: 10,
                          color: eventColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
