import 'package:uuid/uuid.dart';
import 'package:lunar/lunar.dart';
import '../../core/constants/db_constants.dart';

/// 倒计时分类枚举
enum CountdownCategory {
  birthday,    // 生日
  anniversary, // 纪念日
  holiday,     // 节假日
  deadline,    // 截止日期
  other,       // 其他
}

/// 倒计时模型 - 支持公历和农历日期
class CountdownModel {
  /// 唯一标识符
  final String id;

  /// 标题
  final String title;

  /// 目标日期（公历）
  final DateTime targetDate;

  /// 是否使用农历
  final bool isLunar;

  /// 农历月份（仅当 isLunar 为 true 时有效）
  final int? lunarMonth;

  /// 农历日期（仅当 isLunar 为 true 时有效）
  final int? lunarDay;

  /// 是否闰月（仅当 isLunar 为 true 时有效）
  final bool isLeapMonth;

  /// 分类
  final CountdownCategory? category;

  /// 颜色 (ARGB 整数值)
  final int? color;

  /// 图标名称
  final String? icon;

  /// 是否每年重复
  final bool repeatYearly;

  /// 是否启用提醒
  final bool notifyEnabled;

  /// 提前提醒天数列表（如 [0, 1, 7] 表示当天、提前1天、提前7天）
  final List<int>? notifyDays;

  /// 创建时间
  final DateTime createdAt;

  const CountdownModel({
    required this.id,
    required this.title,
    required this.targetDate,
    this.isLunar = false,
    this.lunarMonth,
    this.lunarDay,
    this.isLeapMonth = false,
    this.category,
    this.color,
    this.icon,
    this.repeatYearly = false,
    this.notifyEnabled = false,
    this.notifyDays,
    required this.createdAt,
  });

  /// 创建新倒计时的工厂方法
  factory CountdownModel.create({
    required String title,
    required DateTime targetDate,
    bool isLunar = false,
    int? lunarMonth,
    int? lunarDay,
    bool isLeapMonth = false,
    CountdownCategory? category,
    int? color,
    String? icon,
    bool repeatYearly = false,
    bool notifyEnabled = false,
    List<int>? notifyDays,
  }) {
    return CountdownModel(
      id: const Uuid().v4(),
      title: title,
      targetDate: targetDate,
      isLunar: isLunar,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      isLeapMonth: isLeapMonth,
      category: category,
      color: color,
      icon: icon,
      repeatYearly: repeatYearly,
      notifyEnabled: notifyEnabled,
      notifyDays: notifyDays,
      createdAt: DateTime.now(),
    );
  }

  /// 从数据库 Map 创建
  factory CountdownModel.fromMap(Map<String, dynamic> map) {
    return CountdownModel(
      id: map[DbConstants.columnCountdownId] as String,
      title: map[DbConstants.columnCountdownTitle] as String,
      targetDate: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnCountdownTargetDate] as int,
      ),
      isLunar: (map[DbConstants.columnCountdownIsLunar] as int) == 1,
      lunarMonth: map[DbConstants.columnCountdownLunarMonth] as int?,
      lunarDay: map[DbConstants.columnCountdownLunarDay] as int?,
      isLeapMonth: (map[DbConstants.columnCountdownIsLeapMonth] as int?) == 1,
      category: _categoryFromString(map[DbConstants.columnCountdownCategory] as String?),
      color: map[DbConstants.columnCountdownColor] as int?,
      icon: map[DbConstants.columnCountdownIcon] as String?,
      repeatYearly: (map[DbConstants.columnCountdownRepeatYearly] as int) == 1,
      notifyEnabled: (map[DbConstants.columnCountdownNotifyEnabled] as int) == 1,
      notifyDays: _parseNotifyDays(map[DbConstants.columnCountdownNotifyDays] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnCountdownCreatedAt] as int,
      ),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnCountdownId: id,
      DbConstants.columnCountdownTitle: title,
      DbConstants.columnCountdownTargetDate: targetDate.millisecondsSinceEpoch,
      DbConstants.columnCountdownIsLunar: isLunar ? 1 : 0,
      DbConstants.columnCountdownLunarMonth: lunarMonth,
      DbConstants.columnCountdownLunarDay: lunarDay,
      DbConstants.columnCountdownIsLeapMonth: isLeapMonth ? 1 : 0,
      DbConstants.columnCountdownCategory: category?.name,
      DbConstants.columnCountdownColor: color,
      DbConstants.columnCountdownIcon: icon,
      DbConstants.columnCountdownRepeatYearly: repeatYearly ? 1 : 0,
      DbConstants.columnCountdownNotifyEnabled: notifyEnabled ? 1 : 0,
      DbConstants.columnCountdownNotifyDays: notifyDays?.join(','),
      DbConstants.columnCountdownCreatedAt: createdAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  CountdownModel copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    bool? isLunar,
    int? lunarMonth,
    int? lunarDay,
    bool? isLeapMonth,
    CountdownCategory? category,
    int? color,
    String? icon,
    bool? repeatYearly,
    bool? notifyEnabled,
    List<int>? notifyDays,
    DateTime? createdAt,
  }) {
    return CountdownModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      isLunar: isLunar ?? this.isLunar,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarDay: lunarDay ?? this.lunarDay,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyDays: notifyDays ?? this.notifyDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取下一个目标日期（考虑每年重复）
  DateTime getNextTargetDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isLunar && lunarMonth != null && lunarDay != null) {
      // 农历日期处理
      return _getNextLunarDate(today);
    } else {
      // 公历日期处理
      return _getNextSolarDate(today);
    }
  }

  /// 获取下一个公历目标日期
  DateTime _getNextSolarDate(DateTime today) {
    if (!repeatYearly) {
      return targetDate;
    }

    // 计算今年的目标日期
    var nextDate = DateTime(today.year, targetDate.month, targetDate.day);

    // 如果今年的日期已过，使用明年的日期
    if (nextDate.isBefore(today)) {
      nextDate = DateTime(today.year + 1, targetDate.month, targetDate.day);
    }

    return nextDate;
  }

  /// 获取下一个农历目标日期
  DateTime _getNextLunarDate(DateTime today) {
    if (!repeatYearly || lunarMonth == null || lunarDay == null) {
      return targetDate;
    }

    // 尝试今年的农历日期
    var year = today.year;
    var solarDate = _lunarToSolar(year, lunarMonth!, lunarDay!, isLeapMonth);

    // 如果今年的日期已过，使用明年的日期
    if (solarDate != null && solarDate.isBefore(today)) {
      solarDate = _lunarToSolar(year + 1, lunarMonth!, lunarDay!, isLeapMonth);
    }

    return solarDate ?? targetDate;
  }

  /// 农历转公历
  static DateTime? _lunarToSolar(int year, int month, int day, bool isLeapMonth) {
    try {
      final lunar = Lunar.fromYmd(year, isLeapMonth ? -month : month, day);
      final solar = lunar.getSolar();
      return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      return null;
    }
  }

  /// 计算剩余天数（负数表示已过去）
  int getDaysRemaining() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = getNextTargetDate();
    final targetDay = DateTime(target.year, target.month, target.day);

    return targetDay.difference(today).inDays;
  }

  /// 获取分类对应的图标
  String getCategoryIcon() {
    if (icon != null) return icon!;

    switch (category) {
      case CountdownCategory.birthday:
        return 'cake';
      case CountdownCategory.anniversary:
        return 'favorite';
      case CountdownCategory.holiday:
        return 'celebration';
      case CountdownCategory.deadline:
        return 'schedule';
      case CountdownCategory.other:
      default:
        return 'event';
    }
  }

  /// 获取分类名称
  String getCategoryName() {
    switch (category) {
      case CountdownCategory.birthday:
        return '生日';
      case CountdownCategory.anniversary:
        return '纪念日';
      case CountdownCategory.holiday:
        return '节假日';
      case CountdownCategory.deadline:
        return '截止日期';
      case CountdownCategory.other:
      default:
        return '其他';
    }
  }

  /// 解析分类字符串
  static CountdownCategory? _categoryFromString(String? value) {
    if (value == null) return null;
    return CountdownCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CountdownCategory.other,
    );
  }

  /// 解析提醒天数字符串
  static List<int>? _parseNotifyDays(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  }

  @override
  String toString() {
    return 'CountdownModel(id: $id, title: $title, targetDate: $targetDate, '
        'isLunar: $isLunar, repeatYearly: $repeatYearly)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountdownModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
