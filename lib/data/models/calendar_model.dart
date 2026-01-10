import 'package:uuid/uuid.dart';
import '../../core/constants/db_constants.dart';
import '../../core/constants/color_constants.dart';

/// 同步间隔枚举
enum SyncInterval {
  manual,   // 手动
  hourly,   // 每小时
  daily,    // 每天
  weekly,   // 每周
}

/// 日历模型
class CalendarModel {
  /// 日历 ID
  final String id;

  /// 日历名称
  final String name;

  /// 日历颜色 (ARGB 整数值)
  final int color;

  /// 是否可见
  final bool isVisible;

  /// 是否为默认日历
  final bool isDefault;

  /// 是否为订阅日历
  final bool isSubscription;

  /// 订阅 URL（仅订阅日历有值）
  final String? subscriptionUrl;

  /// 同步间隔
  final SyncInterval syncInterval;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 创建时间
  final DateTime createdAt;

  const CalendarModel({
    required this.id,
    required this.name,
    required this.color,
    this.isVisible = true,
    this.isDefault = false,
    this.isSubscription = false,
    this.subscriptionUrl,
    this.syncInterval = SyncInterval.manual,
    this.lastSyncTime,
    required this.createdAt,
  });

  /// 创建新日历的工厂方法
  factory CalendarModel.create({
    required String name,
    int? color,
    bool isDefault = false,
  }) {
    return CalendarModel(
      id: const Uuid().v4(),
      name: name,
      color: color ?? ColorConstants.eventColors.first.value,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }

  /// 创建订阅日历的工厂方法
  factory CalendarModel.createSubscription({
    required String name,
    required String subscriptionUrl,
    int? color,
    SyncInterval syncInterval = SyncInterval.daily,
  }) {
    return CalendarModel(
      id: const Uuid().v4(),
      name: name,
      color: color ?? ColorConstants.eventColors.first.value,
      isSubscription: true,
      subscriptionUrl: subscriptionUrl,
      syncInterval: syncInterval,
      createdAt: DateTime.now(),
    );
  }

  /// 从数据库 Map 创建
  factory CalendarModel.fromMap(Map<String, dynamic> map) {
    // 解析同步间隔
    SyncInterval syncInterval = SyncInterval.manual;
    final syncIntervalStr = map[DbConstants.columnCalendarSyncInterval] as String?;
    if (syncIntervalStr != null) {
      syncInterval = SyncInterval.values.firstWhere(
        (e) => e.name == syncIntervalStr,
        orElse: () => SyncInterval.manual,
      );
    }

    return CalendarModel(
      id: map[DbConstants.columnCalendarId] as String,
      name: map[DbConstants.columnCalendarName] as String,
      color: map[DbConstants.columnCalendarColor] as int,
      isVisible: (map[DbConstants.columnCalendarIsVisible] as int) == 1,
      isDefault: (map[DbConstants.columnCalendarIsDefault] as int) == 1,
      isSubscription: (map[DbConstants.columnCalendarIsSubscription] as int) == 1,
      subscriptionUrl: map[DbConstants.columnCalendarSubscriptionUrl] as String?,
      syncInterval: syncInterval,
      lastSyncTime: map[DbConstants.columnCalendarLastSyncTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.columnCalendarLastSyncTime] as int,
              isUtc: true,
            ).toLocal()
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnCalendarCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnCalendarId: id,
      DbConstants.columnCalendarName: name,
      DbConstants.columnCalendarColor: color,
      DbConstants.columnCalendarIsVisible: isVisible ? 1 : 0,
      DbConstants.columnCalendarIsDefault: isDefault ? 1 : 0,
      DbConstants.columnCalendarIsSubscription: isSubscription ? 1 : 0,
      DbConstants.columnCalendarSubscriptionUrl: subscriptionUrl,
      DbConstants.columnCalendarSyncInterval: syncInterval.name,
      DbConstants.columnCalendarLastSyncTime: lastSyncTime?.toUtc().millisecondsSinceEpoch,
      DbConstants.columnCalendarCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  CalendarModel copyWith({
    String? id,
    String? name,
    int? color,
    bool? isVisible,
    bool? isDefault,
    bool? isSubscription,
    String? subscriptionUrl,
    SyncInterval? syncInterval,
    DateTime? lastSyncTime,
    DateTime? createdAt,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      isDefault: isDefault ?? this.isDefault,
      isSubscription: isSubscription ?? this.isSubscription,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      syncInterval: syncInterval ?? this.syncInterval,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取同步间隔的显示文本
  String get syncIntervalText {
    switch (syncInterval) {
      case SyncInterval.manual:
        return '手动';
      case SyncInterval.hourly:
        return '每小时';
      case SyncInterval.daily:
        return '每天';
      case SyncInterval.weekly:
        return '每周';
    }
  }

  /// 是否需要同步（仅订阅日历）
  bool get needsSync {
    if (!isSubscription) return false;
    if (syncInterval == SyncInterval.manual) return false;
    if (lastSyncTime == null) return true;

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    switch (syncInterval) {
      case SyncInterval.hourly:
        return diff.inHours >= 1;
      case SyncInterval.daily:
        return diff.inDays >= 1;
      case SyncInterval.weekly:
        return diff.inDays >= 7;
      case SyncInterval.manual:
        return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CalendarModel(id: $id, name: $name, isDefault: $isDefault)';
  }
}
