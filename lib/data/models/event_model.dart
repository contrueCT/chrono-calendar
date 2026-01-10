import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/db_constants.dart';

/// 事件状态枚举 (RFC 5545 STATUS)
enum EventStatus {
  tentative,  // 暂定
  confirmed,  // 已确认
  cancelled,  // 已取消
}

/// 事件模型 - 遵循 RFC 5545 iCalendar 标准
class EventModel {
  /// 全局唯一标识符 (RFC 5545 UID)
  final String uid;

  /// 所属日历 ID
  final String calendarId;

  /// 事件标题 (RFC 5545 SUMMARY)
  final String summary;

  /// 事件描述 (RFC 5545 DESCRIPTION)
  final String? description;

  /// 地点 (RFC 5545 LOCATION)
  final String? location;

  /// 开始时间 (RFC 5545 DTSTART)
  final DateTime dtStart;

  /// 结束时间 (RFC 5545 DTEND)
  final DateTime? dtEnd;

  /// 是否全天事件
  final bool isAllDay;

  /// 重复规则字符串 (RFC 5545 RRULE)
  final String? rrule;

  /// 排除日期列表 (RFC 5545 EXDATE)
  final List<DateTime>? exDates;

  /// 事件颜色 (ARGB 整数值)
  final int? color;

  /// 事件状态 (RFC 5545 STATUS)
  final EventStatus status;

  /// 优先级 0-9，0=未定义，1=最高 (RFC 5545 PRIORITY)
  final int priority;

  /// 关联 URL (RFC 5545 URL)
  final String? url;

  /// 创建时间 (RFC 5545 CREATED)
  final DateTime createdAt;

  /// 更新时间 (RFC 5545 LAST-MODIFIED / DTSTAMP)
  final DateTime updatedAt;

  /// 修订序号 (RFC 5545 SEQUENCE)
  final int sequence;

  const EventModel({
    required this.uid,
    required this.calendarId,
    required this.summary,
    this.description,
    this.location,
    required this.dtStart,
    this.dtEnd,
    this.isAllDay = false,
    this.rrule,
    this.exDates,
    this.color,
    this.status = EventStatus.confirmed,
    this.priority = 0,
    this.url,
    required this.createdAt,
    required this.updatedAt,
    this.sequence = 0,
  });

  /// 创建新事件的工厂方法
  factory EventModel.create({
    required String calendarId,
    required String summary,
    String? description,
    String? location,
    required DateTime dtStart,
    DateTime? dtEnd,
    bool isAllDay = false,
    String? rrule,
    int? color,
    int priority = 0,
    String? url,
  }) {
    final now = DateTime.now();
    return EventModel(
      uid: const Uuid().v4(),
      calendarId: calendarId,
      summary: summary,
      description: description,
      location: location,
      dtStart: dtStart,
      dtEnd: dtEnd,
      isAllDay: isAllDay,
      rrule: rrule,
      color: color,
      priority: priority,
      url: url,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 是否为重复事件
  bool get isRecurring => rrule != null && rrule!.isNotEmpty;

  /// 事件时长
  Duration get duration {
    if (dtEnd == null) {
      return isAllDay ? const Duration(days: 1) : const Duration(hours: 1);
    }
    return dtEnd!.difference(dtStart);
  }

  /// 从数据库 Map 创建
  factory EventModel.fromMap(Map<String, dynamic> map) {
    // 解析排除日期
    List<DateTime>? exDates;
    if (map[DbConstants.columnEventExdates] != null) {
      final exdatesJson = map[DbConstants.columnEventExdates] as String;
      if (exdatesJson.isNotEmpty) {
        final List<dynamic> exdatesList = jsonDecode(exdatesJson);
        exDates = exdatesList
            .map((e) => DateTime.fromMillisecondsSinceEpoch(e as int, isUtc: true).toLocal())
            .toList();
      }
    }

    // 解析状态
    EventStatus status = EventStatus.confirmed;
    final statusStr = map[DbConstants.columnEventStatus] as String?;
    if (statusStr != null) {
      status = EventStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => EventStatus.confirmed,
      );
    }

    return EventModel(
      uid: map[DbConstants.columnEventUid] as String,
      calendarId: map[DbConstants.columnEventCalendarId] as String,
      summary: map[DbConstants.columnEventSummary] as String,
      description: map[DbConstants.columnEventDescription] as String?,
      location: map[DbConstants.columnEventLocation] as String?,
      dtStart: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnEventDtstart] as int,
        isUtc: true,
      ).toLocal(),
      dtEnd: map[DbConstants.columnEventDtend] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.columnEventDtend] as int,
              isUtc: true,
            ).toLocal()
          : null,
      isAllDay: (map[DbConstants.columnEventIsAllDay] as int) == 1,
      rrule: map[DbConstants.columnEventRrule] as String?,
      exDates: exDates,
      color: map[DbConstants.columnEventColor] as int?,
      status: status,
      priority: map[DbConstants.columnEventPriority] as int? ?? 0,
      url: map[DbConstants.columnEventUrl] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnEventCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnEventUpdatedAt] as int,
        isUtc: true,
      ).toLocal(),
      sequence: map[DbConstants.columnEventSequence] as int? ?? 0,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    // 序列化排除日期
    String? exdatesJson;
    if (exDates != null && exDates!.isNotEmpty) {
      exdatesJson = jsonEncode(
        exDates!.map((d) => d.toUtc().millisecondsSinceEpoch).toList(),
      );
    }

    return {
      DbConstants.columnEventUid: uid,
      DbConstants.columnEventCalendarId: calendarId,
      DbConstants.columnEventSummary: summary,
      DbConstants.columnEventDescription: description,
      DbConstants.columnEventLocation: location,
      DbConstants.columnEventDtstart: dtStart.toUtc().millisecondsSinceEpoch,
      DbConstants.columnEventDtend: dtEnd?.toUtc().millisecondsSinceEpoch,
      DbConstants.columnEventIsAllDay: isAllDay ? 1 : 0,
      DbConstants.columnEventRrule: rrule,
      DbConstants.columnEventExdates: exdatesJson,
      DbConstants.columnEventColor: color,
      DbConstants.columnEventStatus: status.name,
      DbConstants.columnEventPriority: priority,
      DbConstants.columnEventUrl: url,
      DbConstants.columnEventCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
      DbConstants.columnEventUpdatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
      DbConstants.columnEventSequence: sequence,
    };
  }

  /// 复制并修改
  EventModel copyWith({
    String? uid,
    String? calendarId,
    String? summary,
    String? description,
    String? location,
    DateTime? dtStart,
    DateTime? dtEnd,
    bool? isAllDay,
    String? rrule,
    List<DateTime>? exDates,
    int? color,
    EventStatus? status,
    int? priority,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sequence,
  }) {
    return EventModel(
      uid: uid ?? this.uid,
      calendarId: calendarId ?? this.calendarId,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      dtStart: dtStart ?? this.dtStart,
      dtEnd: dtEnd ?? this.dtEnd,
      isAllDay: isAllDay ?? this.isAllDay,
      rrule: rrule ?? this.rrule,
      exDates: exDates ?? this.exDates,
      color: color ?? this.color,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'EventModel(uid: $uid, summary: $summary, dtStart: $dtStart)';
  }
}

/// 事件实例 - 用于表示重复事件的单个实例
class EventInstance {
  /// 原始事件
  final EventModel event;

  /// 实例的开始时间
  final DateTime instanceStart;

  /// 实例的结束时间
  final DateTime instanceEnd;

  /// 是否为异常实例
  final bool isException;

  const EventInstance({
    required this.event,
    required this.instanceStart,
    required this.instanceEnd,
    this.isException = false,
  });

  /// 从非重复事件创建实例
  factory EventInstance.fromEvent(EventModel event) {
    return EventInstance(
      event: event,
      instanceStart: event.dtStart,
      instanceEnd: event.dtEnd ?? event.dtStart.add(event.duration),
    );
  }

  @override
  String toString() {
    return 'EventInstance(summary: ${event.summary}, start: $instanceStart)';
  }
}
