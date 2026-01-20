import 'package:flutter/material.dart';

/// 日程类型枚举
/// 用于新建日程时的类型选择
enum ScheduleType {
  /// 默认日程（普通事件）
  event(
    label: '默认',
    icon: Icons.calendar_today,
    description: '普通日程，支持时间段和重复',
  ),

  /// 重要日（倒计时-纪念日）
  important(
    label: '重要日',
    icon: Icons.star_outline,
    description: '纪念日、重要日期，支持农历',
  ),

  /// 生日（倒计时-生日）
  birthday(
    label: '生日',
    icon: Icons.cake_outlined,
    description: '生日提醒，每年重复',
  ),

  /// 待办事项
  todo(
    label: '待办',
    icon: Icons.check_circle_outline,
    description: '待完成的任务，可标记完成状态',
  );

  /// 显示标签
  final String label;

  /// 图标
  final IconData icon;

  /// 描述
  final String description;

  const ScheduleType({
    required this.label,
    required this.icon,
    required this.description,
  });

  /// 从字符串解析
  static ScheduleType? fromString(String? value) {
    if (value == null) return null;
    return ScheduleType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ScheduleType.event,
    );
  }

  /// 是否为倒计时类型
  bool get isCountdown => this == important || this == birthday;

  /// 是否为待办类型
  bool get isTodo => this == todo;

  /// 是否为普通事件类型
  bool get isEvent => this == event;
}
