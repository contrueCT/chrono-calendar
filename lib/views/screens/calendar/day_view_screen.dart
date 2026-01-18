import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../../../viewmodels/settings_viewmodel.dart';
import '../../../data/models/event_model.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../core/utils/event_layout_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../widgets/calendar/draggable_event.dart';

/// 日视图页面
class DayViewScreen extends StatelessWidget {
  const DayViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer<SettingsViewModel>(
          builder: (context, settings, _) {
            final showLunar = settings.showLunar;
            return Column(
              children: [
                // 日期导航栏
                _DayNavigationBar(viewModel: viewModel),

                // 日期详情头部
                _DayHeader(viewModel: viewModel, showLunar: showLunar),

                // 时间轴和事件区域
                Expanded(
                  child: _DayTimeGrid(viewModel: viewModel),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 日期导航栏
class _DayNavigationBar extends StatelessWidget {
  final CalendarViewModel viewModel;

  const _DayNavigationBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一天按钮
          IconButton(
            onPressed: viewModel.goToPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一天',
          ),

          // 日期标题
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewModel.currentDayTitle,
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

          // 下一天按钮
          IconButton(
            onPressed: viewModel.goToNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一天',
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

/// 日期详情头部（包含农历、天气等信息）
class _DayHeader extends StatelessWidget {
  final CalendarViewModel viewModel;
  final bool showLunar;

  const _DayHeader({
    required this.viewModel,
    required this.showLunar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = viewModel.selectedDate;
    final lunarInfo = showLunar ? LunarUtils.getLunarInfo(date) : null;
    final events = viewModel.selectedDateEvents;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
          // 日期大数字
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: viewModel.isToday(date)
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: viewModel.isToday(date)
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 日期详情
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 公历日期
                Text(
                  DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(date),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                // 农历日期（根据设置显示）
                if (showLunar && lunarInfo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        LunarUtils.getFullLunarString(date),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (lunarInfo.hasSpecialDay) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getSpecialDayName(lunarInfo),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 事件数量徽章
          if (events.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${events.length} 个日程',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 获取特殊日期名称（节气 > 农历节日 > 公历节日）
  String _getSpecialDayName(LunarDateInfo info) {
    if (info.solarTerm != null && info.solarTerm!.isNotEmpty) {
      return info.solarTerm!;
    }
    if (info.lunarFestival != null && info.lunarFestival!.isNotEmpty) {
      return info.lunarFestival!;
    }
    if (info.solarFestival != null && info.solarFestival!.isNotEmpty) {
      return info.solarFestival!;
    }
    return '';
  }
}

/// 日时间网格
class _DayTimeGrid extends StatefulWidget {
  final CalendarViewModel viewModel;

  const _DayTimeGrid({required this.viewModel});

  @override
  State<_DayTimeGrid> createState() => _DayTimeGridState();
}

class _DayTimeGridState extends State<_DayTimeGrid> {
  final ScrollController _scrollController = ScrollController();
  static const double hourHeight = 72.0;
  static const int startHour = 0;
  static const int endHour = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    if (!widget.viewModel.isToday(widget.viewModel.selectedDate)) {
      // 非今天，滚动到上午 8 点
      final targetOffset = 8 * hourHeight;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    } else {
      // 今天，滚动到当前时间
      final now = DateTime.now();
      final targetOffset = (now.hour - 1) * hourHeight;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
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
    final events = widget.viewModel.selectedDateEvents;
    final allDayEvents = events.where((e) => e.event.isAllDay).toList();
    final timedEvents = events.where((e) => !e.event.isAllDay).toList();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            // 向左滑动 → 下一天
            widget.viewModel.goToNext();
          } else if (details.primaryVelocity! > 300) {
            // 向右滑动 → 上一天
            widget.viewModel.goToPrevious();
          }
        }
      },
      child: Column(
        children: [
          // 全天事件区域
          if (allDayEvents.isNotEmpty) _buildAllDaySection(allDayEvents, colorScheme),

          // 时间轴
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: (endHour - startHour) * hourHeight,
                child: Stack(
                  children: [
                    // 时间网格背景
                    _buildTimeGrid(colorScheme),

                    // 事件块（使用布局辅助类处理重叠）
                    ..._buildEventBlocks(timedEvents, colorScheme),

                    // 当前时间指示线
                    if (widget.viewModel.isToday(widget.viewModel.selectedDate))
                      _buildCurrentTimeIndicator(colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDaySection(List<EventInstance> events, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全天',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final eventColor = Color(
                  event.event.color ?? colorScheme.primary.value,
                );
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: eventColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: eventColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.event.summary,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeGrid(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间轴
        SizedBox(
          width: 56,
          child: Column(
            children: List.generate(endHour - startHour, (index) {
              final hour = startHour + index;
              return SizedBox(
                height: hourHeight,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // 右侧事件区域背景
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  /// 构建所有事件块，处理重叠事件的布局
  List<Widget> _buildEventBlocks(
    List<EventInstance> events,
    ColorScheme colorScheme,
  ) {
    if (events.isEmpty) return [];

    // 使用布局辅助类计算重叠事件的位置
    final layoutInfos = EventLayoutHelper.calculateLayout(events);

    return layoutInfos.map((layoutInfo) {
      return DraggableEventWidget(
        event: layoutInfo.event,
        hourHeight: hourHeight,
        leftOffset: 60,
        rightOffset: 16,
        showDetails: true,
        widthFraction: layoutInfo.widthFraction,
        leftFraction: layoutInfo.leftFraction,
        onTap: () => _onEventTap(context, layoutInfo.event),
        onDragComplete: (newStart, newEnd) => _onEventDragComplete(
          context,
          layoutInfo.event,
          newStart,
          newEnd,
        ),
      );
    }).toList();
  }

  Widget _buildCurrentTimeIndicator(ColorScheme colorScheme) {
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final top = minutesSinceMidnight * hourHeight / 60;

    return Positioned(
      left: 48,
      right: 0,
      top: top,
      child: Row(
        children: [
          // 时间标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              DateFormat('HH:mm').format(now),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 红色线
          Expanded(
            child: Container(
              height: 2,
              color: colorScheme.error,
            ),
          ),
        ],
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
        SnackBarHelper.show(
          context,
          '已更新: ${event.event.summary}',
          actionLabel: '撤销',
          onAction: () async {
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
        );
      } else {
        SnackBarHelper.showError(context, '更新失败，请重试');
      }
    }
  }
}
