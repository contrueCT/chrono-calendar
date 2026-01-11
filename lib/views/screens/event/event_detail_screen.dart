import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/recurrence_rule.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/models/calendar_model.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../services/reminder_manager.dart';

/// 事件详情页面
class EventDetailScreen extends StatefulWidget {
  /// 事件 UID
  final String eventUid;

  /// 事件实例的开始时间（用于重复事件）
  final DateTime? instanceDate;

  const EventDetailScreen({
    super.key,
    required this.eventUid,
    this.instanceDate,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventRepository _eventRepository = EventRepository();
  final CalendarRepository _calendarRepository = CalendarRepository();

  EventModel? _event;
  CalendarModel? _calendar;
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final event = await _eventRepository.getEventByUid(widget.eventUid);
      if (event == null) {
        setState(() {
          _errorMessage = '事件不存在';
          _isLoading = false;
        });
        return;
      }

      final calendar = await _calendarRepository.getCalendarById(event.calendarId);
      final reminders = await _eventRepository.getRemindersForEvent(event.uid);

      setState(() {
        _event = event;
        _calendar = calendar;
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载事件失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(context)
              : _buildContent(context, theme, colorScheme),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final event = _event!;
    final eventColor = Color(event.color ?? colorScheme.primary.value);

    return CustomScrollView(
      slivers: [
        // 顶部标题区域
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: eventColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            // 编辑按钮
            IconButton(
              onPressed: () => _handleEdit(context),
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
            ),
            // 更多菜单
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                if (event.isRecurring) ...[
                  const PopupMenuItem(
                    value: 'delete_instance',
                    child: Row(
                      children: [
                        Icon(Icons.event_busy_outlined),
                        SizedBox(width: 12),
                        Text('仅删除此次'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_future',
                    child: Row(
                      children: [
                        Icon(Icons.event_busy_outlined),
                        SizedBox(width: 12),
                        Text('删除此次及之后'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    eventColor,
                    eventColor.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 标题
                  Text(
                    event.summary,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 日历名称
                  if (_calendar != null)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(_calendar!.color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _calendar!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        // 详情内容
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间信息
                _buildTimeSection(event, theme, colorScheme),
                const SizedBox(height: 24),

                // 重复规则
                if (event.isRecurring) ...[
                  _buildRecurrenceSection(event, theme, colorScheme),
                  const SizedBox(height: 24),
                ],

                // 提醒
                if (_reminders.isNotEmpty) ...[
                  _buildRemindersSection(theme, colorScheme),
                  const SizedBox(height: 24),
                ],

                // 地点
                if (event.location != null && event.location!.isNotEmpty) ...[
                  _buildLocationSection(event, theme, colorScheme),
                  const SizedBox(height: 24),
                ],

                // 描述
                if (event.description != null && event.description!.isNotEmpty) ...[
                  _buildDescriptionSection(event, theme, colorScheme),
                  const SizedBox(height: 24),
                ],

                // URL
                if (event.url != null && event.url!.isNotEmpty) ...[
                  _buildUrlSection(event, theme, colorScheme),
                  const SizedBox(height: 24),
                ],

                // 创建/更新时间
                _buildMetaSection(event, theme, colorScheme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final displayDate = widget.instanceDate ?? event.dtStart;
    final lunarInfo = LunarUtils.getLunarInfo(displayDate);

    return _DetailSection(
      icon: Icons.access_time,
      iconColor: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期
          Text(
            DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(displayDate),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // 农历
          Text(
            LunarUtils.getFullLunarString(displayDate),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // 时间
          if (event.isAllDay)
            Text(
              '全天',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              '${DateFormat('HH:mm').format(displayDate)} - '
              '${DateFormat('HH:mm').format(event.dtEnd ?? displayDate.add(const Duration(hours: 1)))}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final rule = RecurrenceRule.fromRRuleString(event.rrule!);

    return _DetailSection(
      icon: Icons.repeat,
      iconColor: colorScheme.primary,
      child: Text(
        rule.description,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildRemindersSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _DetailSection(
      icon: Icons.notifications_outlined,
      iconColor: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _reminders.map((reminder) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              reminder.displayText,
              style: theme.textTheme.bodyLarge,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _DetailSection(
      icon: Icons.location_on_outlined,
      iconColor: colorScheme.primary,
      child: Text(
        event.location!,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildDescriptionSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _DetailSection(
      icon: Icons.notes_outlined,
      iconColor: colorScheme.primary,
      child: Text(
        event.description!,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildUrlSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _DetailSection(
      icon: Icons.link,
      iconColor: colorScheme.primary,
      child: InkWell(
        onTap: () {
          // TODO: 打开链接
        },
        child: Text(
          event.url!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaSection(
    EventModel event,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text(
          '创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(event.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '更新时间: ${DateFormat('yyyy-MM-dd HH:mm').format(event.updatedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _handleEdit(BuildContext context) {
    context.push('/event/edit?uid=${_event!.uid}');
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation(context, _DeleteType.all);
        break;
      case 'delete_instance':
        _showDeleteConfirmation(context, _DeleteType.instance);
        break;
      case 'delete_future':
        _showDeleteConfirmation(context, _DeleteType.future);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, _DeleteType type) {
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    String content;

    switch (type) {
      case _DeleteType.all:
        title = '删除日程';
        content = _event!.isRecurring
            ? '确定要删除此重复日程的所有实例吗？'
            : '确定要删除此日程吗？';
        break;
      case _DeleteType.instance:
        title = '删除此次日程';
        content = '确定要删除此次日程吗？其他重复实例不受影响。';
        break;
      case _DeleteType.future:
        title = '删除此次及之后';
        content = '确定要删除此次及之后的所有日程吗？';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(context, type);
            },
            child: Text(
              '删除',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, _DeleteType type) async {
    try {
      final reminderManager = ReminderManager();

      switch (type) {
        case _DeleteType.all:
          // 取消所有提醒通知
          await reminderManager.cancelRemindersForEvent(_event!.uid);
          // 删除事件
          await _eventRepository.deleteEvent(_event!.uid);
          break;
        case _DeleteType.instance:
          if (widget.instanceDate != null) {
            await _eventRepository.addExcludeDate(_event!.uid, widget.instanceDate!);
            // 重新调度提醒（会排除被删除的实例）
            final reminders = await _eventRepository.getRemindersForEvent(_event!.uid);
            if (reminders.isNotEmpty) {
              await reminderManager.updateRemindersForEvent(_event!, reminders);
            }
          }
          break;
        case _DeleteType.future:
          // 需要修改重复规则的 UNTIL
          // 简化实现：将 UNTIL 设置为当前实例的前一天
          final rule = RecurrenceRule.fromRRuleString(_event!.rrule!);
          final newRule = rule.copyWith(
            until: widget.instanceDate?.subtract(const Duration(days: 1)),
            count: null,
          );
          final updatedEvent = _event!.copyWith(
            rrule: newRule.toRRuleString(),
            updatedAt: DateTime.now(),
          );
          await _eventRepository.updateEvent(updatedEvent);
          // 重新调度提醒（根据新的 UNTIL 范围）
          final reminders = await _eventRepository.getRemindersForEvent(_event!.uid);
          if (reminders.isNotEmpty) {
            await reminderManager.updateRemindersForEvent(updatedEvent, reminders);
          }
          break;
      }

      if (context.mounted) {
        context.pop(true); // 返回 true 表示删除成功
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    }
  }
}

/// 详情项区块
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}

enum _DeleteType {
  all,      // 删除所有实例
  instance, // 仅删除此次
  future,   // 删除此次及之后
}
