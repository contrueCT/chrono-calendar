import 'package:flutter/material.dart';
import 'event_model.dart';
import 'countdown_model.dart';
import 'todo_model.dart';

/// 日历项类型枚举
enum CalendarItemType {
  /// 普通事件
  event,

  /// 倒计时/纪念日
  countdown,

  /// 待办事项
  todo,
}

/// 日历显示项 - 统一包装事件、倒计时和待办用于日历显示
abstract class CalendarDisplayItem {
  /// 唯一标识符
  String get id;

  /// 显示标题
  String get title;

  /// 显示日期
  DateTime get displayDate;

  /// 显示颜色 (ARGB)
  int? get color;

  /// 项目类型
  CalendarItemType get itemType;

  /// 是否为全天项目
  bool get isAllDay;

  /// 开始时间（用于排序）
  DateTime get startTime;

  /// 结束时间
  DateTime? get endTime;

  /// 获取显示用的图标
  IconData get displayIcon;

  /// 获取副标题（时间或剩余天数等）
  String getSubtitle();
}

/// 事件显示项 - 包装 EventInstance
class EventDisplayItem implements CalendarDisplayItem {
  /// 原始事件实例
  final EventInstance eventInstance;

  const EventDisplayItem(this.eventInstance);

  @override
  String get id => eventInstance.event.uid;

  @override
  String get title => eventInstance.event.summary;

  @override
  DateTime get displayDate => eventInstance.instanceStart;

  @override
  int? get color => eventInstance.event.color;

  @override
  CalendarItemType get itemType => CalendarItemType.event;

  @override
  bool get isAllDay => eventInstance.event.isAllDay;

  @override
  DateTime get startTime => eventInstance.instanceStart;

  @override
  DateTime? get endTime => eventInstance.instanceEnd;

  @override
  IconData get displayIcon => isAllDay
      ? Icons.calendar_today
      : Icons.access_time;

  @override
  String getSubtitle() {
    if (isAllDay) {
      return '全天';
    }
    final start = eventInstance.instanceStart;
    final end = eventInstance.instanceEnd;
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  /// 获取原始事件
  EventModel get event => eventInstance.event;

  /// 是否为重复事件
  bool get isRecurring => eventInstance.event.isRecurring;

  /// 地点
  String? get location => eventInstance.event.location;

  /// 描述
  String? get description => eventInstance.event.description;

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 倒计时显示项 - 包装 CountdownModel
class CountdownDisplayItem implements CalendarDisplayItem {
  /// 原始倒计时
  final CountdownModel countdown;

  /// 实例日期（当年的目标日期）
  final DateTime instanceDate;

  const CountdownDisplayItem({
    required this.countdown,
    required this.instanceDate,
  });

  /// 从倒计时创建显示项
  factory CountdownDisplayItem.fromCountdown(CountdownModel countdown) {
    return CountdownDisplayItem(
      countdown: countdown,
      instanceDate: countdown.getNextTargetDate(),
    );
  }

  @override
  String get id => countdown.id;

  @override
  String get title => countdown.title;

  @override
  DateTime get displayDate => instanceDate;

  @override
  int? get color => countdown.color;

  @override
  CalendarItemType get itemType => CalendarItemType.countdown;

  @override
  bool get isAllDay => true;

  @override
  DateTime get startTime => DateTime(
        instanceDate.year,
        instanceDate.month,
        instanceDate.day,
      );

  @override
  DateTime? get endTime => null;

  @override
  IconData get displayIcon {
    switch (countdown.category) {
      case CountdownCategory.birthday:
        return Icons.cake_outlined;
      case CountdownCategory.anniversary:
        return Icons.favorite_outline;
      case CountdownCategory.holiday:
        return Icons.celebration_outlined;
      case CountdownCategory.deadline:
        return Icons.schedule;
      case CountdownCategory.other:
      default:
        return Icons.star_outline;
    }
  }

  @override
  String getSubtitle() {
    final days = countdown.getDaysRemaining();
    if (days == 0) {
      return '今天';
    } else if (days > 0) {
      return '还有 $days 天';
    } else {
      return '已过 ${-days} 天';
    }
  }

  /// 分类
  CountdownCategory? get category => countdown.category;

  /// 是否农历
  bool get isLunar => countdown.isLunar;

  /// 是否每年重复
  bool get repeatYearly => countdown.repeatYearly;

  /// 剩余天数
  int get daysRemaining => countdown.getDaysRemaining();
}

/// 待办显示项 - 包装 TodoModel
class TodoDisplayItem implements CalendarDisplayItem {
  /// 原始待办数据
  final TodoModel todo;

  const TodoDisplayItem(this.todo);

  /// 从 TodoModel 创建显示项
  factory TodoDisplayItem.fromTodo(TodoModel todo) {
    return TodoDisplayItem(todo);
  }

  /// 待办 ID
  String get todoId => todo.id;

  /// 待办标题
  String get todoTitle => todo.title;

  /// 截止日期
  DateTime? get dueDate => todo.dueDate;

  /// 截止时间
  DateTime? get dueTime => todo.dueTime;

  /// 是否完成
  bool get isCompleted => todo.isCompleted;

  /// 优先级 (0-3)
  int get priority => todo.priority;

  /// 颜色
  int? get todoColor => todo.color;

  @override
  String get id => todoId;

  @override
  String get title => todoTitle;

  @override
  DateTime get displayDate => dueDate ?? DateTime.now();

  @override
  int? get color => todoColor;

  @override
  CalendarItemType get itemType => CalendarItemType.todo;

  @override
  bool get isAllDay => dueTime == null;

  @override
  DateTime get startTime {
    if (dueDate == null) return DateTime.now();
    if (dueTime != null) {
      return DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
    }
    return DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
  }

  @override
  DateTime? get endTime => null;

  @override
  IconData get displayIcon {
    if (isCompleted) {
      return Icons.check_circle;
    }
    switch (priority) {
      case 3:
        return Icons.priority_high;
      case 2:
        return Icons.error_outline;
      case 1:
        return Icons.low_priority;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  String getSubtitle() {
    if (isCompleted) {
      return '已完成';
    }
    if (dueDate == null) {
      return '无截止日期';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) {
      return '已逾期 ${-diff} 天';
    } else if (diff == 0) {
      if (dueTime != null) {
        return '今天 ${_formatTime(dueTime!)} 到期';
      }
      return '今天到期';
    } else if (diff == 1) {
      return '明天到期';
    } else {
      return '$diff 天后到期';
    }
  }

  /// 是否已逾期
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  /// 获取优先级标签
  String get priorityLabel {
    switch (priority) {
      case 3:
        return '高';
      case 2:
        return '中';
      case 1:
        return '低';
      default:
        return '';
    }
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 日历显示项排序比较器
class CalendarDisplayItemComparator {
  /// 按开始时间排序
  static int compareByStartTime(CalendarDisplayItem a, CalendarDisplayItem b) {
    // 全天事件排在前面
    if (a.isAllDay && !b.isAllDay) return -1;
    if (!a.isAllDay && b.isAllDay) return 1;

    // 按开始时间排序
    return a.startTime.compareTo(b.startTime);
  }

  /// 按类型和开始时间排序
  /// 排序优先级：倒计时 > 事件 > 待办
  static int compareByTypeAndTime(CalendarDisplayItem a, CalendarDisplayItem b) {
    // 先按类型排序
    final typeOrder = {
      CalendarItemType.countdown: 0,
      CalendarItemType.event: 1,
      CalendarItemType.todo: 2,
    };
    final typeCompare = typeOrder[a.itemType]!.compareTo(typeOrder[b.itemType]!);
    if (typeCompare != 0) return typeCompare;

    // 再按开始时间排序
    return compareByStartTime(a, b);
  }
}
