import '../../core/constants/db_constants.dart';

/// 提醒类型枚举 (RFC 5545 ACTION)
enum ReminderType {
  notification,  // DISPLAY - 显示通知
  audio,         // AUDIO - 播放声音
}

/// 提醒模型 - 对应 RFC 5545 VALARM 组件
class ReminderModel {
  /// 提醒 ID（数据库自增）
  final int? id;

  /// 关联事件 UID
  final String eventUid;

  /// 提醒类型
  final ReminderType type;

  /// 提前触发时间（分钟）
  /// 正数表示提前多少分钟提醒
  final int triggerMinutes;

  /// 本地通知 ID（用于取消通知）
  final int notificationId;

  const ReminderModel({
    this.id,
    required this.eventUid,
    this.type = ReminderType.notification,
    required this.triggerMinutes,
    required this.notificationId,
  });

  /// 从数据库 Map 创建
  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    // 解析提醒类型
    ReminderType type = ReminderType.notification;
    final typeStr = map[DbConstants.columnReminderType] as String?;
    if (typeStr != null) {
      type = ReminderType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ReminderType.notification,
      );
    }

    return ReminderModel(
      id: map[DbConstants.columnReminderId] as int?,
      eventUid: map[DbConstants.columnReminderEventUid] as String,
      type: type,
      triggerMinutes: map[DbConstants.columnReminderTriggerMinutes] as int,
      notificationId: map[DbConstants.columnReminderNotificationId] as int,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.columnReminderEventUid: eventUid,
      DbConstants.columnReminderType: type.name,
      DbConstants.columnReminderTriggerMinutes: triggerMinutes,
      DbConstants.columnReminderNotificationId: notificationId,
    };

    if (id != null) {
      map[DbConstants.columnReminderId] = id;
    }

    return map;
  }

  /// 复制并修改
  ReminderModel copyWith({
    int? id,
    String? eventUid,
    ReminderType? type,
    int? triggerMinutes,
    int? notificationId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      eventUid: eventUid ?? this.eventUid,
      type: type ?? this.type,
      triggerMinutes: triggerMinutes ?? this.triggerMinutes,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// 获取提醒时间显示文本
  String get displayText {
    if (triggerMinutes == 0) {
      return '事件发生时';
    } else if (triggerMinutes < 60) {
      return '提前 $triggerMinutes 分钟';
    } else if (triggerMinutes < 1440) {
      final hours = triggerMinutes ~/ 60;
      return '提前 $hours 小时';
    } else if (triggerMinutes < 10080) {
      final days = triggerMinutes ~/ 1440;
      return '提前 $days 天';
    } else {
      final weeks = triggerMinutes ~/ 10080;
      return '提前 $weeks 周';
    }
  }

  /// 转换为 RFC 5545 VALARM 组件字符串
  String toVAlarm() {
    final action = type == ReminderType.notification ? 'DISPLAY' : 'AUDIO';
    return '''BEGIN:VALARM
ACTION:$action
TRIGGER:-PT${triggerMinutes}M
DESCRIPTION:提醒
END:VALARM''';
  }

  /// 计算实际提醒时间
  DateTime calculateTriggerTime(DateTime eventStartTime) {
    return eventStartTime.subtract(Duration(minutes: triggerMinutes));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel &&
        other.eventUid == eventUid &&
        other.triggerMinutes == triggerMinutes;
  }

  @override
  int get hashCode => Object.hash(eventUid, triggerMinutes);

  @override
  String toString() {
    return 'ReminderModel(eventUid: $eventUid, triggerMinutes: $triggerMinutes)';
  }
}

/// 预定义的提醒选项
class ReminderOptions {
  ReminderOptions._();

  /// 所有可选的提醒时间（分钟）
  static const List<int> allOptions = [
    0,      // 事件发生时
    5,      // 提前 5 分钟
    15,     // 提前 15 分钟
    30,     // 提前 30 分钟
    60,     // 提前 1 小时
    120,    // 提前 2 小时
    1440,   // 提前 1 天
    2880,   // 提前 2 天
    10080,  // 提前 1 周
  ];

  /// 获取显示文本
  static String getDisplayText(int minutes) {
    switch (minutes) {
      case 0:
        return '事件发生时';
      case 5:
        return '提前 5 分钟';
      case 15:
        return '提前 15 分钟';
      case 30:
        return '提前 30 分钟';
      case 60:
        return '提前 1 小时';
      case 120:
        return '提前 2 小时';
      case 1440:
        return '提前 1 天';
      case 2880:
        return '提前 2 天';
      case 10080:
        return '提前 1 周';
      default:
        if (minutes < 60) {
          return '提前 $minutes 分钟';
        } else if (minutes < 1440) {
          return '提前 ${minutes ~/ 60} 小时';
        } else {
          return '提前 ${minutes ~/ 1440} 天';
        }
    }
  }
}
