import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/models/calendar_model.dart';
import '../data/models/event_model.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/event_repository.dart';
import 'icalendar_service.dart';
import 'reminder_manager.dart';

/// 订阅同步结果
class SubscriptionSyncResult {
  /// 是否成功
  final bool success;

  /// 新增事件数
  final int addedCount;

  /// 更新事件数
  final int updatedCount;

  /// 删除事件数
  final int deletedCount;

  /// 错误信息
  final String? error;

  const SubscriptionSyncResult({
    required this.success,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.error,
  });

  /// 创建成功结果
  factory SubscriptionSyncResult.success({
    int addedCount = 0,
    int updatedCount = 0,
    int deletedCount = 0,
  }) {
    return SubscriptionSyncResult(
      success: true,
      addedCount: addedCount,
      updatedCount: updatedCount,
      deletedCount: deletedCount,
    );
  }

  /// 创建失败结果
  factory SubscriptionSyncResult.failure(String error) {
    return SubscriptionSyncResult(
      success: false,
      error: error,
    );
  }

  /// 总变更数
  int get totalChanges => addedCount + updatedCount + deletedCount;
}

/// 订阅服务 - 处理网络日历订阅
class SubscriptionService {
  // 单例模式
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Accept': 'text/calendar, application/calendar+json, */*',
      'User-Agent': 'Chrono Calendar/1.0',
    },
  ));

  final CalendarRepository _calendarRepository = CalendarRepository();
  final EventRepository _eventRepository = EventRepository();
  final ICalendarService _icalendarService = ICalendarService();
  final ReminderManager _reminderManager = ReminderManager();

  /// 验证订阅 URL
  ///
  /// 返回验证结果，包含日历名称和事件数量
  Future<Map<String, dynamic>> validateSubscriptionUrl(String url) async {
    try {
      // 验证 URL 格式
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        return {
          'valid': false,
          'error': '无效的 URL 格式',
        };
      }

      // 尝试获取内容
      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        return {
          'valid': false,
          'error': 'HTTP 错误: ${response.statusCode}',
        };
      }

      final content = response.data.toString();

      // 验证 iCalendar 格式
      if (!_icalendarService.validateICalendar(content)) {
        return {
          'valid': false,
          'error': '无效的 iCalendar 格式',
        };
      }

      // 获取日历信息
      final info = _icalendarService.getICalendarInfo(content);

      return {
        'valid': true,
        'calendarName': info['calendarName'] ?? '订阅日历',
        'eventCount': info['eventCount'] ?? 0,
      };
    } on DioException catch (e) {
      return {
        'valid': false,
        'error': _getDioErrorMessage(e),
      };
    } catch (e) {
      return {
        'valid': false,
        'error': '验证失败: $e',
      };
    }
  }

  /// 添加订阅
  ///
  /// [url] - 订阅 URL
  /// [name] - 日历名称
  /// [color] - 日历颜色
  /// [syncInterval] - 同步间隔
  Future<CalendarModel?> addSubscription({
    required String url,
    required String name,
    int? color,
    SyncInterval syncInterval = SyncInterval.daily,
  }) async {
    try {
      // 创建订阅日历
      final calendar = CalendarModel.createSubscription(
        name: name,
        subscriptionUrl: url,
        color: color,
        syncInterval: syncInterval,
      );

      // 保存到数据库
      await _calendarRepository.insertCalendar(calendar);

      // 立即执行首次同步
      await syncSubscription(calendar.id);

      return calendar;
    } catch (e) {
      debugPrint('添加订阅失败: $e');
      return null;
    }
  }

  /// 同步单个订阅
  Future<SubscriptionSyncResult> syncSubscription(String calendarId) async {
    try {
      // 获取日历信息
      final calendar = await _calendarRepository.getCalendarById(calendarId);
      if (calendar == null) {
        return SubscriptionSyncResult.failure('日历不存在');
      }

      if (!calendar.isSubscription || calendar.subscriptionUrl == null) {
        return SubscriptionSyncResult.failure('不是订阅日历');
      }

      // 获取远程内容
      final response = await _dio.get(calendar.subscriptionUrl!);

      if (response.statusCode != 200) {
        return SubscriptionSyncResult.failure('HTTP 错误: ${response.statusCode}');
      }

      final content = response.data.toString();

      // 解析远程事件
      final parseResult = await _icalendarService.parseICalendar(
        content,
        targetCalendarId: calendarId,
      );

      if (parseResult.errors.isNotEmpty && parseResult.events.isEmpty) {
        return SubscriptionSyncResult.failure(parseResult.errors.first);
      }

      // 获取本地事件
      final localEvents =
          await _eventRepository.getEventsByCalendarId(calendarId);
      final localEventMap = {for (var e in localEvents) e.uid: e};

      // 计算差异
      int addedCount = 0;
      int updatedCount = 0;
      int deletedCount = 0;

      final remoteUids = <String>{};

      for (final remoteEvent in parseResult.events) {
        remoteUids.add(remoteEvent.uid);

        final localEvent = localEventMap[remoteEvent.uid];

        if (localEvent == null) {
          // 新事件
          await _eventRepository.insertEvent(remoteEvent);
          addedCount++;

          // 处理提醒
          final reminders = parseResult.reminders[remoteEvent.uid];
          if (reminders != null && reminders.isNotEmpty) {
            await _eventRepository.updateReminders(remoteEvent.uid, reminders);
            await _reminderManager.updateRemindersForEvent(
                remoteEvent, reminders);
          }
        } else if (_hasEventChanged(localEvent, remoteEvent)) {
          // 事件已更新
          await _eventRepository.updateEvent(remoteEvent);
          updatedCount++;

          // 更新提醒
          final reminders = parseResult.reminders[remoteEvent.uid];
          if (reminders != null) {
            await _eventRepository.updateReminders(remoteEvent.uid, reminders);
            await _reminderManager.updateRemindersForEvent(
                remoteEvent, reminders);
          }
        }
      }

      // 删除远程不存在的事件
      for (final localEvent in localEvents) {
        if (!remoteUids.contains(localEvent.uid)) {
          await _reminderManager.cancelRemindersForEvent(localEvent.uid);
          await _eventRepository.deleteEvent(localEvent.uid);
          deletedCount++;
        }
      }

      // 更新最后同步时间
      await _calendarRepository.updateLastSyncTime(calendarId);

      return SubscriptionSyncResult.success(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
      );
    } on DioException catch (e) {
      return SubscriptionSyncResult.failure(_getDioErrorMessage(e));
    } catch (e) {
      return SubscriptionSyncResult.failure('同步失败: $e');
    }
  }

  /// 同步所有需要同步的订阅
  Future<Map<String, SubscriptionSyncResult>> syncAllSubscriptions() async {
    final results = <String, SubscriptionSyncResult>{};

    try {
      final calendars = await _calendarRepository.getCalendarsNeedingSync();

      for (final calendar in calendars) {
        results[calendar.id] = await syncSubscription(calendar.id);
      }
    } catch (e) {
      debugPrint('同步所有订阅失败: $e');
    }

    return results;
  }

  /// 删除订阅
  ///
  /// 会同时删除日历和所有关联的事件
  Future<bool> deleteSubscription(String calendarId) async {
    try {
      // 取消所有相关通知
      final events =
          await _eventRepository.getEventsByCalendarId(calendarId);
      for (final event in events) {
        await _reminderManager.cancelRemindersForEvent(event.uid);
      }

      // 删除日历（事件会通过外键级联删除）
      await _calendarRepository.deleteCalendar(calendarId);

      return true;
    } catch (e) {
      debugPrint('删除订阅失败: $e');
      return false;
    }
  }

  /// 更新订阅设置
  Future<bool> updateSubscription(
    String calendarId, {
    String? name,
    int? color,
    SyncInterval? syncInterval,
  }) async {
    try {
      final calendar = await _calendarRepository.getCalendarById(calendarId);
      if (calendar == null || !calendar.isSubscription) {
        return false;
      }

      final updated = calendar.copyWith(
        name: name,
        color: color,
        syncInterval: syncInterval,
      );

      await _calendarRepository.updateCalendar(updated);
      return true;
    } catch (e) {
      debugPrint('更新订阅失败: $e');
      return false;
    }
  }

  /// 检查事件是否有变化
  bool _hasEventChanged(EventModel local, EventModel remote) {
    // 比较关键字段
    if (local.summary != remote.summary) return true;
    if (local.description != remote.description) return true;
    if (local.location != remote.location) return true;
    if (local.dtStart != remote.dtStart) return true;
    if (local.dtEnd != remote.dtEnd) return true;
    if (local.isAllDay != remote.isAllDay) return true;
    if (local.rrule != remote.rrule) return true;
    if (local.status != remote.status) return true;

    // 比较序列号（如果远程序列号更高，说明有更新）
    if (remote.sequence > local.sequence) return true;

    return false;
  }

  /// 获取 Dio 错误消息
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      case DioExceptionType.badResponse:
        return 'HTTP 错误: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return '网络错误: ${e.message}';
    }
  }
}
