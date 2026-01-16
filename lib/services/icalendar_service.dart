import 'package:flutter/foundation.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import '../data/models/event_model.dart';
import '../data/models/reminder_model.dart';

/// iCalendar 导入结果
class ICalendarImportResult {
  /// 成功导入的事件列表
  final List<EventModel> events;

  /// 导入的提醒映射（事件 UID -> 提醒列表）
  final Map<String, List<ReminderModel>> reminders;

  /// 跳过的事件数量（如重复 UID）
  final int skippedCount;

  /// 错误信息列表
  final List<String> errors;

  const ICalendarImportResult({
    required this.events,
    required this.reminders,
    this.skippedCount = 0,
    this.errors = const [],
  });

  /// 是否全部成功
  bool get isFullySuccessful => errors.isEmpty && skippedCount == 0;

  /// 导入的事件数量
  int get importedCount => events.length;
}

/// iCalendar 服务 - 处理 iCalendar 格式的导入导出
class ICalendarService {
  // 单例模式
  static final ICalendarService _instance = ICalendarService._internal();
  factory ICalendarService() => _instance;
  ICalendarService._internal();

  /// 解析 iCalendar 内容
  ///
  /// [icsContent] - iCalendar 文件内容
  /// [targetCalendarId] - 目标日历 ID
  /// [existingUids] - 已存在的事件 UID 列表（用于跳过重复）
  Future<ICalendarImportResult> parseICalendar(
    String icsContent, {
    required String targetCalendarId,
    Set<String>? existingUids,
  }) async {
    final events = <EventModel>[];
    final reminders = <String, List<ReminderModel>>{};
    final errors = <String>[];
    int skippedCount = 0;

    try {
      final iCalendar = ICalendar.fromString(icsContent);

      for (final component in iCalendar.data) {
        if (component['type'] != 'VEVENT') continue;

        try {
          final uid = component['uid'] as String?;
          if (uid == null) {
            errors.add('事件缺少 UID，已跳过');
            skippedCount++;
            continue;
          }

          // 检查是否已存在
          if (existingUids != null && existingUids.contains(uid)) {
            skippedCount++;
            continue;
          }

          final event = _parseVEvent(component, targetCalendarId);
          if (event != null) {
            events.add(event);

            // 解析提醒
            final eventReminders = _parseAlarms(component, uid);
            if (eventReminders.isNotEmpty) {
              reminders[uid] = eventReminders;
            }
          }
        } catch (e) {
          final summary = component['summary'] ?? '未知事件';
          errors.add('解析事件 "$summary" 失败: $e');
        }
      }
    } catch (e) {
      errors.add('解析 iCalendar 文件失败: $e');
    }

    return ICalendarImportResult(
      events: events,
      reminders: reminders,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  /// 解析 VEVENT 组件
  EventModel? _parseVEvent(Map<String, dynamic> component, String calendarId) {
    final uid = component['uid'] as String;
    final summary = component['summary'] as String? ?? '无标题';

    // 解析开始时间
    final dtStart = _parseDateTime(component['dtstart']);
    if (dtStart == null) {
      throw Exception('缺少开始时间');
    }

    // 解析结束时间
    DateTime? dtEnd = _parseDateTime(component['dtend']);

    // 检查是否全天事件
    bool isAllDay = false;
    final dtStartData = component['dtstart'];
    if (dtStartData is IcsDateTime) {
      final startDateTime = dtStartData.toDateTime();
      if (startDateTime != null) {
        final dtEndData = component['dtend'];
        DateTime? endDateTime;
        if (dtEndData is IcsDateTime) {
          endDateTime = dtEndData.toDateTime();
        }
        isAllDay = startDateTime.hour == 0 &&
            startDateTime.minute == 0 &&
            (dtEndData == null || (endDateTime != null && endDateTime.hour == 0));
      }
    }

    // 解析重复规则
    String? rrule;
    if (component['rrule'] != null) {
      rrule = _formatRRule(component['rrule']);
    }

    // 解析排除日期
    List<DateTime>? exDates;
    if (component['exdate'] != null) {
      exDates = _parseExDates(component['exdate']);
    }

    // 解析状态
    EventStatus status = EventStatus.confirmed;
    final statusStr = component['status'] as String?;
    if (statusStr != null) {
      switch (statusStr.toUpperCase()) {
        case 'TENTATIVE':
          status = EventStatus.tentative;
          break;
        case 'CANCELLED':
          status = EventStatus.cancelled;
          break;
      }
    }

    // 解析优先级
    int priority = 0;
    if (component['priority'] != null) {
      priority = int.tryParse(component['priority'].toString()) ?? 0;
    }

    // 解析时间戳
    final now = DateTime.now();
    DateTime createdAt = now;
    DateTime updatedAt = now;

    if (component['created'] != null) {
      createdAt = _parseDateTime(component['created']) ?? now;
    }
    if (component['last-modified'] != null) {
      updatedAt = _parseDateTime(component['last-modified']) ?? now;
    } else if (component['dtstamp'] != null) {
      updatedAt = _parseDateTime(component['dtstamp']) ?? now;
    }

    // 解析序列号
    int sequence = 0;
    if (component['sequence'] != null) {
      sequence = int.tryParse(component['sequence'].toString()) ?? 0;
    }

    return EventModel(
      uid: uid,
      calendarId: calendarId,
      summary: summary,
      description: component['description'] as String?,
      location: component['location'] as String?,
      dtStart: dtStart,
      dtEnd: dtEnd,
      isAllDay: isAllDay,
      rrule: rrule,
      exDates: exDates,
      status: status,
      priority: priority,
      url: component['url'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sequence: sequence,
    );
  }

  /// 解析日期时间
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is IcsDateTime) {
      return value.toDateTime();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      // 尝试解析 ISO 8601 格式
      try {
        return DateTime.parse(value);
      } catch (_) {}

      // 尝试解析 iCalendar 格式 (例如: 20260115T140000Z)
      try {
        if (value.length >= 8) {
          final year = int.parse(value.substring(0, 4));
          final month = int.parse(value.substring(4, 6));
          final day = int.parse(value.substring(6, 8));

          if (value.length >= 15) {
            final hour = int.parse(value.substring(9, 11));
            final minute = int.parse(value.substring(11, 13));
            final second = int.parse(value.substring(13, 15));
            final isUtc = value.endsWith('Z');

            final dt = DateTime(year, month, day, hour, minute, second);
            return isUtc ? dt.toLocal() : dt;
          }

          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return null;
  }

  /// 格式化 RRULE
  String? _formatRRule(dynamic rrule) {
    if (rrule == null) return null;

    if (rrule is String) {
      // 移除 RRULE: 前缀（如果有）
      if (rrule.toUpperCase().startsWith('RRULE:')) {
        return rrule.substring(6);
      }
      return rrule;
    }

    if (rrule is Map) {
      // 从 Map 构建 RRULE 字符串
      final parts = <String>[];

      if (rrule['freq'] != null) {
        parts.add('FREQ=${rrule['freq']}');
      }
      if (rrule['interval'] != null) {
        parts.add('INTERVAL=${rrule['interval']}');
      }
      if (rrule['count'] != null) {
        parts.add('COUNT=${rrule['count']}');
      }
      if (rrule['until'] != null) {
        parts.add('UNTIL=${rrule['until']}');
      }
      if (rrule['byday'] != null) {
        parts.add('BYDAY=${rrule['byday']}');
      }
      if (rrule['bymonthday'] != null) {
        parts.add('BYMONTHDAY=${rrule['bymonthday']}');
      }
      if (rrule['bymonth'] != null) {
        parts.add('BYMONTH=${rrule['bymonth']}');
      }
      if (rrule['wkst'] != null) {
        parts.add('WKST=${rrule['wkst']}');
      }

      return parts.isNotEmpty ? parts.join(';') : null;
    }

    return rrule.toString();
  }

  /// 解析排除日期
  List<DateTime>? _parseExDates(dynamic exdate) {
    if (exdate == null) return null;

    final dates = <DateTime>[];

    if (exdate is List) {
      for (final item in exdate) {
        final dt = _parseDateTime(item);
        if (dt != null) {
          dates.add(dt);
        }
      }
    } else {
      final dt = _parseDateTime(exdate);
      if (dt != null) {
        dates.add(dt);
      }
    }

    return dates.isNotEmpty ? dates : null;
  }

  /// 解析 VALARM 组件
  List<ReminderModel> _parseAlarms(Map<String, dynamic> component, String eventUid) {
    final reminders = <ReminderModel>[];

    // icalendar_parser 可能将 alarms 放在不同的位置
    final alarms = component['valarm'] ?? component['alarms'];
    if (alarms == null) return reminders;

    int index = 0;
    if (alarms is List) {
      for (final alarm in alarms) {
        final reminder = _parseAlarm(alarm, eventUid, index);
        if (reminder != null) {
          reminders.add(reminder);
          index++;
        }
      }
    } else if (alarms is Map) {
      final reminder = _parseAlarm(alarms, eventUid, index);
      if (reminder != null) {
        reminders.add(reminder);
      }
    }

    return reminders;
  }

  /// 解析单个 VALARM
  ReminderModel? _parseAlarm(dynamic alarm, String eventUid, int index) {
    if (alarm is! Map) return null;

    // 解析 TRIGGER
    final trigger = alarm['trigger'];
    if (trigger == null) return null;

    int triggerMinutes = 15; // 默认 15 分钟

    if (trigger is String) {
      // 解析 ISO 8601 Duration 格式 (例如: -PT15M, -P1D)
      triggerMinutes = _parseDuration(trigger);
    } else if (trigger is Duration) {
      triggerMinutes = trigger.inMinutes.abs();
    }

    // 生成通知 ID
    final notificationId = (eventUid.hashCode + index).abs() % 2147483647;

    return ReminderModel(
      eventUid: eventUid,
      triggerMinutes: triggerMinutes,
      notificationId: notificationId,
    );
  }

  /// 解析 ISO 8601 Duration 格式
  int _parseDuration(String duration) {
    // 移除负号和 P 前缀
    String d = duration.toUpperCase().replaceAll('-', '').replaceAll('P', '');

    int minutes = 0;

    // 解析天数
    final dayMatch = RegExp(r'(\d+)D').firstMatch(d);
    if (dayMatch != null) {
      minutes += int.parse(dayMatch.group(1)!) * 24 * 60;
    }

    // 移除 T 前缀
    d = d.replaceAll('T', '');

    // 解析小时
    final hourMatch = RegExp(r'(\d+)H').firstMatch(d);
    if (hourMatch != null) {
      minutes += int.parse(hourMatch.group(1)!) * 60;
    }

    // 解析分钟
    final minMatch = RegExp(r'(\d+)M').firstMatch(d);
    if (minMatch != null) {
      minutes += int.parse(minMatch.group(1)!);
    }

    // 解析周
    final weekMatch = RegExp(r'(\d+)W').firstMatch(d);
    if (weekMatch != null) {
      minutes += int.parse(weekMatch.group(1)!) * 7 * 24 * 60;
    }

    return minutes > 0 ? minutes : 15; // 默认 15 分钟
  }

  // ==================== 导出功能 ====================

  /// 导出事件为 iCalendar 格式
  ///
  /// [events] - 要导出的事件列表
  /// [calendarName] - 日历名称
  /// [reminders] - 事件提醒映射（事件 UID -> 提醒列表）
  String exportToICalendar(
    List<EventModel> events, {
    String calendarName = 'Chrono Calendar',
    Map<String, List<ReminderModel>>? reminders,
  }) {
    final buffer = StringBuffer();

    // 写入 VCALENDAR 头部
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Chrono Calendar//CN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:${_escapeText(calendarName)}');
    buffer.writeln('X-WR-TIMEZONE:Asia/Shanghai');

    // 写入每个事件
    for (final event in events) {
      final eventReminders = reminders?[event.uid];
      buffer.write(_exportVEvent(event, eventReminders));
    }

    // 写入 VCALENDAR 尾部
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// 导出单个事件
  String _exportVEvent(EventModel event, List<ReminderModel>? reminders) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${event.uid}');
    buffer.writeln('DTSTAMP:${_formatDateTime(event.updatedAt)}');

    // 开始和结束时间
    if (event.isAllDay) {
      buffer.writeln('DTSTART;VALUE=DATE:${_formatDate(event.dtStart)}');
      if (event.dtEnd != null) {
        buffer.writeln('DTEND;VALUE=DATE:${_formatDate(event.dtEnd!)}');
      }
    } else {
      buffer.writeln('DTSTART:${_formatDateTime(event.dtStart)}');
      if (event.dtEnd != null) {
        buffer.writeln('DTEND:${_formatDateTime(event.dtEnd!)}');
      }
    }

    // 标题
    buffer.writeln('SUMMARY:${_escapeText(event.summary)}');

    // 可选字段
    if (event.description != null && event.description!.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escapeText(event.description!)}');
    }
    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeText(event.location!)}');
    }
    if (event.url != null && event.url!.isNotEmpty) {
      buffer.writeln('URL:${event.url}');
    }

    // 状态
    buffer.writeln('STATUS:${event.status.name.toUpperCase()}');

    // 序列号
    buffer.writeln('SEQUENCE:${event.sequence}');

    // 优先级
    if (event.priority > 0) {
      buffer.writeln('PRIORITY:${event.priority}');
    }

    // 重复规则
    if (event.rrule != null && event.rrule!.isNotEmpty) {
      buffer.writeln('RRULE:${event.rrule}');
    }

    // 排除日期
    if (event.exDates != null && event.exDates!.isNotEmpty) {
      final exdateStr = event.exDates!.map((d) => _formatDateTime(d)).join(',');
      buffer.writeln('EXDATE:$exdateStr');
    }

    // 创建时间
    buffer.writeln('CREATED:${_formatDateTime(event.createdAt)}');
    buffer.writeln('LAST-MODIFIED:${_formatDateTime(event.updatedAt)}');

    // 提醒
    if (reminders != null) {
      for (final reminder in reminders) {
        buffer.write(_exportVAlarm(reminder));
      }
    }

    buffer.writeln('END:VEVENT');

    return buffer.toString();
  }

  /// 导出 VALARM
  String _exportVAlarm(ReminderModel reminder) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VALARM');
    buffer.writeln('ACTION:DISPLAY');
    buffer.writeln('TRIGGER:-PT${reminder.triggerMinutes}M');
    buffer.writeln('DESCRIPTION:提醒');
    buffer.writeln('END:VALARM');

    return buffer.toString();
  }

  /// 格式化日期时间为 iCalendar 格式 (UTC)
  String _formatDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${DateFormat('yyyyMMdd').format(utc)}T${DateFormat('HHmmss').format(utc)}Z';
  }

  /// 格式化日期为 iCalendar 格式 (仅日期)
  String _formatDate(DateTime dt) {
    return DateFormat('yyyyMMdd').format(dt);
  }

  /// 转义文本中的特殊字符
  String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }

  // ==================== 验证功能 ====================

  /// 验证 iCalendar 内容是否有效
  bool validateICalendar(String icsContent) {
    try {
      final iCalendar = ICalendar.fromString(icsContent);
      return iCalendar.data.isNotEmpty;
    } catch (e) {
      debugPrint('iCalendar 验证失败: $e');
      return false;
    }
  }

  /// 获取 iCalendar 内容的基本信息
  Map<String, dynamic> getICalendarInfo(String icsContent) {
    try {
      final iCalendar = ICalendar.fromString(icsContent);

      int eventCount = 0;
      for (final component in iCalendar.data) {
        if (component['type'] == 'VEVENT') {
          eventCount++;
        }
      }

      return {
        'isValid': true,
        'eventCount': eventCount,
        'calendarName': iCalendar.data.isNotEmpty
            ? iCalendar.data.first['x-wr-calname']
            : null,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
}
