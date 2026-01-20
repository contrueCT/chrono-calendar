import 'package:uuid/uuid.dart';
import '../../core/constants/db_constants.dart';

/// 待办优先级枚举
enum TodoPriority {
  /// 无优先级
  none(0, '无', ''),

  /// 低优先级
  low(1, '低', '!'),

  /// 中优先级
  medium(2, '中', '!!'),

  /// 高优先级
  high(3, '高', '!!!');

  /// 数值
  final int value;

  /// 标签
  final String label;

  /// 符号
  final String symbol;

  const TodoPriority(this.value, this.label, this.symbol);

  /// 从数值获取优先级
  static TodoPriority fromValue(int value) {
    return TodoPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TodoPriority.none,
    );
  }
}

/// 待办事项模型
class TodoModel {
  /// 唯一标识符
  final String id;

  /// 标题
  final String title;

  /// 描述
  final String? description;

  /// 截止日期（可选）
  final DateTime? dueDate;

  /// 截止时间（可选，仅时间部分）
  final DateTime? dueTime;

  /// 是否完成
  final bool isCompleted;

  /// 完成时间
  final DateTime? completedAt;

  /// 优先级 (0-3: 无/低/中/高)
  final int priority;

  /// 颜色 (ARGB 整数值)
  final int? color;

  /// 是否启用提醒
  final bool notifyEnabled;

  /// 提前提醒分钟数
  final int? notifyMinutes;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  const TodoModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.completedAt,
    this.priority = 0,
    this.color,
    this.notifyEnabled = false,
    this.notifyMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建新待办的工厂方法
  factory TodoModel.create({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? dueTime,
    int priority = 0,
    int? color,
    bool notifyEnabled = false,
    int? notifyMinutes,
  }) {
    final now = DateTime.now();
    return TodoModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      color: color,
      notifyEnabled: notifyEnabled,
      notifyMinutes: notifyMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从数据库 Map 创建
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map[DbConstants.columnTodoId] as String,
      title: map[DbConstants.columnTodoTitle] as String,
      description: map[DbConstants.columnTodoDescription] as String?,
      dueDate: map[DbConstants.columnTodoDueDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.columnTodoDueDate] as int,
              isUtc: true,
            ).toLocal()
          : null,
      dueTime: map[DbConstants.columnTodoDueTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.columnTodoDueTime] as int,
              isUtc: true,
            ).toLocal()
          : null,
      isCompleted: (map[DbConstants.columnTodoIsCompleted] as int) == 1,
      completedAt: map[DbConstants.columnTodoCompletedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.columnTodoCompletedAt] as int,
              isUtc: true,
            ).toLocal()
          : null,
      priority: map[DbConstants.columnTodoPriority] as int? ?? 0,
      color: map[DbConstants.columnTodoColor] as int?,
      notifyEnabled: (map[DbConstants.columnTodoNotifyEnabled] as int?) == 1,
      notifyMinutes: map[DbConstants.columnTodoNotifyMinutes] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnTodoCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnTodoUpdatedAt] as int,
        isUtc: true,
      ).toLocal(),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnTodoId: id,
      DbConstants.columnTodoTitle: title,
      DbConstants.columnTodoDescription: description,
      DbConstants.columnTodoDueDate: dueDate?.toUtc().millisecondsSinceEpoch,
      DbConstants.columnTodoDueTime: dueTime?.toUtc().millisecondsSinceEpoch,
      DbConstants.columnTodoIsCompleted: isCompleted ? 1 : 0,
      DbConstants.columnTodoCompletedAt: completedAt?.toUtc().millisecondsSinceEpoch,
      DbConstants.columnTodoPriority: priority,
      DbConstants.columnTodoColor: color,
      DbConstants.columnTodoNotifyEnabled: notifyEnabled ? 1 : 0,
      DbConstants.columnTodoNotifyMinutes: notifyMinutes,
      DbConstants.columnTodoCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
      DbConstants.columnTodoUpdatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? dueTime,
    bool clearDueTime = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? priority,
    int? color,
    bool clearColor = false,
    bool? notifyEnabled,
    int? notifyMinutes,
    bool clearNotifyMinutes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      priority: priority ?? this.priority,
      color: clearColor ? null : (color ?? this.color),
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyMinutes: clearNotifyMinutes ? null : (notifyMinutes ?? this.notifyMinutes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 标记为完成
  TodoModel markCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// 标记为未完成
  TodoModel markIncomplete() {
    return copyWith(
      isCompleted: false,
      clearCompletedAt: true,
    );
  }

  /// 切换完成状态
  TodoModel toggleComplete() {
    return isCompleted ? markIncomplete() : markCompleted();
  }

  /// 获取优先级枚举
  TodoPriority get priorityEnum => TodoPriority.fromValue(priority);

  /// 是否有截止日期
  bool get hasDueDate => dueDate != null;

  /// 是否已逾期
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (dueTime != null) {
      final dueDateTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
      return now.isAfter(dueDateTime);
    }

    return today.isAfter(due);
  }

  /// 是否今天到期
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAtSameMomentAs(due);
  }

  /// 获取剩余天数（负数表示已逾期）
  int? getDaysRemaining() {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  /// 获取提醒时间
  DateTime? getNotificationTime() {
    if (!notifyEnabled || dueDate == null || notifyMinutes == null) {
      return null;
    }

    DateTime notifyTime;
    if (dueTime != null) {
      notifyTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
    } else {
      // 如果没有具体时间，默认上午9点提醒
      notifyTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        9,
        0,
      );
    }

    return notifyTime.subtract(Duration(minutes: notifyMinutes!));
  }

  @override
  String toString() {
    return 'TodoModel(id: $id, title: $title, isCompleted: $isCompleted, '
        'priority: $priority, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
