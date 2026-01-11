import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/models/reminder_model.dart';
import '../data/models/recurrence_rule.dart';
import '../data/repositories/event_repository.dart';
import '../core/utils/rrule_parser.dart';
import 'notification_service.dart';

/// 提醒管理器 - 负责调度和维护事件提醒
class ReminderManager {
  // 单例模式
  static final ReminderManager _instance = ReminderManager._internal();
  factory ReminderManager() => _instance;
  ReminderManager._internal();

  final NotificationService _notificationService = NotificationService();
  final EventRepository _eventRepository = EventRepository();

  /// 提醒预生成天数（针对重复事件）
  static const int _preGenerateDays = 90;

  /// 初始化提醒管理器
  Future<void> initialize() async {
    debugPrint('ReminderManager initializing...');

    // 启动时刷新所有提醒
    await refreshAllReminders();

    debugPrint('ReminderManager initialized');
  }

  /// 生成通知 ID
  /// 基于事件 UID、触发时间和实例日期生成唯一 ID
  int _generateNotificationId(
    String eventUid,
    int triggerMinutes,
    DateTime instanceDate,
  ) {
    // 使用事件 UID、触发分钟数和实例日期的组合生成哈希
    final combined = '$eventUid-$triggerMinutes-${instanceDate.millisecondsSinceEpoch}';
    return combined.hashCode.abs() % 2147483647; // 确保是正整数且在 int32 范围内
  }

  /// 为单个事件调度提醒
  ///
  /// [event] - 事件
  /// [reminders] - 提醒列表
  /// [instanceDate] - 事件实例日期（用于重复事件）
  Future<void> scheduleRemindersForEvent(
    EventModel event,
    List<ReminderModel> reminders, {
    DateTime? instanceDate,
  }) async {
    final eventStart = instanceDate ?? event.dtStart;

    for (final reminder in reminders) {
      final triggerTime = reminder.calculateTriggerTime(eventStart);

      // 跳过已过期的提醒
      if (triggerTime.isBefore(DateTime.now())) {
        continue;
      }

      final notificationId = _generateNotificationId(
        event.uid,
        reminder.triggerMinutes,
        eventStart,
      );

      // 构建通知内容
      final title = '日程提醒';
      final body = _buildNotificationBody(event, reminder, eventStart);
      final payload = _buildPayload(event.uid, eventStart);

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: triggerTime,
        payload: payload,
      );
    }
  }

  /// 构建通知内容
  String _buildNotificationBody(
    EventModel event,
    ReminderModel reminder,
    DateTime eventStart,
  ) {
    final buffer = StringBuffer();
    buffer.write(event.summary);

    // 添加时间信息
    if (event.isAllDay) {
      buffer.write(' - 全天');
    } else {
      final hour = eventStart.hour.toString().padLeft(2, '0');
      final minute = eventStart.minute.toString().padLeft(2, '0');
      buffer.write(' - $hour:$minute');
    }

    // 添加地点信息
    if (event.location != null && event.location!.isNotEmpty) {
      buffer.write(' @ ${event.location}');
    }

    return buffer.toString();
  }

  /// 构建通知 payload
  String _buildPayload(String eventUid, DateTime instanceDate) {
    return jsonEncode({
      'eventUid': eventUid,
      'instanceDate': instanceDate.toIso8601String(),
    });
  }

  /// 取消事件的所有提醒
  Future<void> cancelRemindersForEvent(String eventUid) async {
    // 获取事件信息
    final event = await _eventRepository.getEventByUid(eventUid);
    if (event == null) return;

    final reminders = await _eventRepository.getRemindersForEvent(eventUid);

    if (event.isRecurring) {
      // 重复事件：取消所有预生成的实例提醒
      final now = DateTime.now();
      final end = now.add(Duration(days: _preGenerateDays));
      final rule = RecurrenceRule.fromRRuleString(event.rrule!);
      final occurrences = RRuleParser.getOccurrences(
        rule,
        event.dtStart,
        now.subtract(const Duration(days: 1)),
        end,
        exDates: event.exDates,
      );

      for (final occurrence in occurrences) {
        for (final reminder in reminders) {
          final notificationId = _generateNotificationId(
            eventUid,
            reminder.triggerMinutes,
            occurrence,
          );
          await _notificationService.cancelNotification(notificationId);
        }
      }
    } else {
      // 单次事件：取消基于事件开始时间的提醒
      for (final reminder in reminders) {
        final notificationId = _generateNotificationId(
          eventUid,
          reminder.triggerMinutes,
          event.dtStart,
        );
        await _notificationService.cancelNotification(notificationId);
      }
    }
  }

  /// 更新事件的提醒
  ///
  /// 这会取消旧的提醒并调度新的提醒
  Future<void> updateRemindersForEvent(
    EventModel event,
    List<ReminderModel> newReminders,
  ) async {
    // 取消旧提醒
    await cancelRemindersForEvent(event.uid);

    // 调度新提醒
    if (newReminders.isEmpty) return;

    if (event.isRecurring) {
      // 重复事件：为未来 90 天的实例调度提醒
      await _scheduleRecurringEventReminders(event, newReminders);
    } else {
      // 单次事件
      await scheduleRemindersForEvent(event, newReminders);
    }
  }

  /// 为重复事件预生成提醒
  Future<void> _scheduleRecurringEventReminders(
    EventModel event,
    List<ReminderModel> reminders,
  ) async {
    if (event.rrule == null) return;

    final now = DateTime.now();
    final end = now.add(Duration(days: _preGenerateDays));
    final rule = RecurrenceRule.fromRRuleString(event.rrule!);

    // 获取未来 90 天内的所有实例
    final occurrences = RRuleParser.getOccurrences(
      rule,
      event.dtStart,
      now.subtract(const Duration(days: 1)),
      end,
      exDates: event.exDates,
    );

    debugPrint('Scheduling reminders for ${occurrences.length} occurrences of event ${event.uid}');

    // 为每个实例调度提醒
    for (final occurrence in occurrences) {
      await scheduleRemindersForEvent(
        event,
        reminders,
        instanceDate: occurrence,
      );
    }
  }

  /// 刷新所有提醒
  ///
  /// 这会清除所有现有提醒并重新调度
  /// 通常在应用启动或设置更改时调用
  Future<void> refreshAllReminders() async {
    debugPrint('Refreshing all reminders...');

    // 取消所有现有通知
    await _notificationService.cancelAllNotifications();

    // 获取所有事件
    final events = await _eventRepository.getAllEvents();

    int scheduledCount = 0;

    for (final event in events) {
      final reminders = await _eventRepository.getRemindersForEvent(event.uid);

      if (reminders.isEmpty) continue;

      if (event.isRecurring) {
        await _scheduleRecurringEventReminders(event, reminders);
      } else {
        // 检查事件是否还未过期
        if (event.dtStart.isAfter(DateTime.now())) {
          await scheduleRemindersForEvent(event, reminders);
        }
      }

      scheduledCount++;
    }

    debugPrint('Refreshed reminders for $scheduledCount events');
  }

  /// 维护提醒（定期调用）
  ///
  /// 这会为重复事件补充新的提醒（扩展预生成范围）
  /// 并清理过期的提醒记录
  Future<void> maintainReminders() async {
    debugPrint('Maintaining reminders...');

    // 获取所有重复事件
    final recurringEvents = await _eventRepository.getRecurringEvents();

    for (final event in recurringEvents) {
      final reminders = await _eventRepository.getRemindersForEvent(event.uid);

      if (reminders.isEmpty) continue;

      // 只为新的时间范围添加提醒
      // 这里简单实现为重新调度所有（实际项目可以优化）
      await _scheduleRecurringEventReminders(event, reminders);
    }

    debugPrint('Maintenance completed for ${recurringEvents.length} recurring events');
  }

  /// 获取待处理的通知数量
  Future<int> getPendingNotificationCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }

  /// 调试：打印所有待处理的通知
  Future<void> debugPrintPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    debugPrint('=== Pending Notifications (${pending.length}) ===');
    for (final notification in pending) {
      debugPrint('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
    }
    debugPrint('=== End ===');
  }
}
