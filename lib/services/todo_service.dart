import 'package:flutter/foundation.dart';
import '../data/models/todo_model.dart';
import '../core/constants/db_constants.dart';
import '../core/errors/result.dart';
import '../core/errors/app_exception.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// 待办服务 - 管理待办事项的 CRUD 操作和提醒
class TodoService {
  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  TodoService._internal();

  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  // ==================== 查询操作 ====================

  /// 获取所有待办
  Future<Result<List<TodoModel>>> getAllTodos() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableTodos,
        orderBy: '${DbConstants.columnTodoIsCompleted} ASC, '
            '${DbConstants.columnTodoPriority} DESC, '
            '${DbConstants.columnTodoDueDate} ASC',
      );
      final todos = maps.map((map) => TodoModel.fromMap(map)).toList();
      return Result.success(todos);
    } catch (e, s) {
      debugPrint('获取待办列表失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取单个待办
  Future<Result<TodoModel?>> getTodo(String id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return Result.success(null);
      return Result.success(TodoModel.fromMap(maps.first));
    } catch (e, s) {
      debugPrint('获取待办失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取未完成的待办
  Future<Result<List<TodoModel>>> getIncompleteTodos() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoIsCompleted} = ?',
        whereArgs: [0],
        orderBy: '${DbConstants.columnTodoPriority} DESC, '
            '${DbConstants.columnTodoDueDate} ASC',
      );
      final todos = maps.map((map) => TodoModel.fromMap(map)).toList();
      return Result.success(todos);
    } catch (e, s) {
      debugPrint('获取未完成待办失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取已完成的待办
  Future<Result<List<TodoModel>>> getCompletedTodos() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoIsCompleted} = ?',
        whereArgs: [1],
        orderBy: '${DbConstants.columnTodoCompletedAt} DESC',
      );
      final todos = maps.map((map) => TodoModel.fromMap(map)).toList();
      return Result.success(todos);
    } catch (e, s) {
      debugPrint('获取已完成待办失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取指定日期的待办
  Future<Result<List<TodoModel>>> getTodosForDate(DateTime date) async {
    try {
      final db = await _db.database;
      // 计算当天的时间范围（UTC）
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final maps = await db.query(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoDueDate} >= ? AND ${DbConstants.columnTodoDueDate} < ?',
        whereArgs: [
          dayStart.toUtc().millisecondsSinceEpoch,
          dayEnd.toUtc().millisecondsSinceEpoch,
        ],
        orderBy: '${DbConstants.columnTodoIsCompleted} ASC, '
            '${DbConstants.columnTodoPriority} DESC, '
            '${DbConstants.columnTodoDueTime} ASC',
      );
      final todos = maps.map((map) => TodoModel.fromMap(map)).toList();
      return Result.success(todos);
    } catch (e, s) {
      debugPrint('获取指定日期待办失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取今天的待办
  Future<Result<List<TodoModel>>> getTodayTodos() async {
    return getTodosForDate(DateTime.now());
  }

  /// 获取已逾期的待办（未完成且截止日期已过）
  Future<Result<List<TodoModel>>> getOverdueTodos() async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final maps = await db.query(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoIsCompleted} = ? AND '
            '${DbConstants.columnTodoDueDate} IS NOT NULL AND '
            '${DbConstants.columnTodoDueDate} < ?',
        whereArgs: [0, today.toUtc().millisecondsSinceEpoch],
        orderBy: '${DbConstants.columnTodoDueDate} ASC',
      );
      final todos = maps.map((map) => TodoModel.fromMap(map)).toList();
      return Result.success(todos);
    } catch (e, s) {
      debugPrint('获取已逾期待办失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 获取日期范围内有待办的日期列表
  Future<Result<Set<DateTime>>> getTodoDatesInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableTodos,
        columns: [DbConstants.columnTodoDueDate],
        where: '${DbConstants.columnTodoDueDate} IS NOT NULL AND '
            '${DbConstants.columnTodoDueDate} >= ? AND '
            '${DbConstants.columnTodoDueDate} < ?',
        whereArgs: [
          start.toUtc().millisecondsSinceEpoch,
          end.toUtc().millisecondsSinceEpoch,
        ],
      );

      final dates = <DateTime>{};
      for (final map in maps) {
        final timestamp = map[DbConstants.columnTodoDueDate] as int?;
        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
          dates.add(DateTime(date.year, date.month, date.day));
        }
      }
      return Result.success(dates);
    } catch (e, s) {
      debugPrint('获取待办日期范围失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  // ==================== CRUD 操作 ====================

  /// 创建待办
  Future<Result<void>> createTodo(TodoModel todo) async {
    try {
      final db = await _db.database;
      await db.insert(DbConstants.tableTodos, todo.toMap());

      // 调度提醒
      if (todo.notifyEnabled) {
        await _scheduleNotification(todo);
      }

      return Result.success(null);
    } catch (e, s) {
      debugPrint('创建待办失败: $e');
      return Result.failure(
        DatabaseException.insertFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 更新待办
  Future<Result<void>> updateTodo(TodoModel todo) async {
    try {
      final db = await _db.database;
      await db.update(
        DbConstants.tableTodos,
        todo.toMap(),
        where: '${DbConstants.columnTodoId} = ?',
        whereArgs: [todo.id],
      );

      // 重新调度提醒
      await _cancelNotification(todo.id);
      if (todo.notifyEnabled && !todo.isCompleted) {
        await _scheduleNotification(todo);
      }

      return Result.success(null);
    } catch (e, s) {
      debugPrint('更新待办失败: $e');
      return Result.failure(
        DatabaseException.updateFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 删除待办
  Future<Result<void>> deleteTodo(String id) async {
    try {
      final db = await _db.database;
      await db.delete(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoId} = ?',
        whereArgs: [id],
      );

      // 取消提醒
      await _cancelNotification(id);

      return Result.success(null);
    } catch (e, s) {
      debugPrint('删除待办失败: $e');
      return Result.failure(
        DatabaseException.deleteFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 批量删除已完成的待办
  Future<Result<int>> deleteCompletedTodos() async {
    try {
      final db = await _db.database;
      final count = await db.delete(
        DbConstants.tableTodos,
        where: '${DbConstants.columnTodoIsCompleted} = ?',
        whereArgs: [1],
      );
      return Result.success(count);
    } catch (e, s) {
      debugPrint('批量删除已完成待办失败: $e');
      return Result.failure(
        DatabaseException.deleteFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  // ==================== 完成状态操作 ====================

  /// 切换待办完成状态
  Future<Result<TodoModel>> toggleComplete(String id) async {
    final result = await getTodo(id);
    if (result.isFailure) return Result.failure(result.errorOrNull!);

    final todo = result.valueOrNull;
    if (todo == null) {
      return Result.failure(
        BusinessException.notFound('待办'),
      );
    }

    final updatedTodo = todo.toggleComplete();
    final updateResult = await updateTodo(updatedTodo);
    if (updateResult.isFailure) return Result.failure(updateResult.errorOrNull!);

    return Result.success(updatedTodo);
  }

  /// 标记待办为完成
  Future<Result<void>> markComplete(String id) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      await db.update(
        DbConstants.tableTodos,
        {
          DbConstants.columnTodoIsCompleted: 1,
          DbConstants.columnTodoCompletedAt: now.toUtc().millisecondsSinceEpoch,
          DbConstants.columnTodoUpdatedAt: now.toUtc().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnTodoId} = ?',
        whereArgs: [id],
      );

      // 取消提醒
      await _cancelNotification(id);

      return Result.success(null);
    } catch (e, s) {
      debugPrint('标记待办完成失败: $e');
      return Result.failure(
        DatabaseException.updateFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  /// 标记待办为未完成
  Future<Result<void>> markIncomplete(String id) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      await db.update(
        DbConstants.tableTodos,
        {
          DbConstants.columnTodoIsCompleted: 0,
          DbConstants.columnTodoCompletedAt: null,
          DbConstants.columnTodoUpdatedAt: now.toUtc().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnTodoId} = ?',
        whereArgs: [id],
      );

      // 重新获取待办以调度提醒
      final todoResult = await getTodo(id);
      if (todoResult.isSuccess && todoResult.valueOrNull != null) {
        final todo = todoResult.valueOrNull!;
        if (todo.notifyEnabled) {
          await _scheduleNotification(todo);
        }
      }

      return Result.success(null);
    } catch (e, s) {
      debugPrint('标记待办未完成失败: $e');
      return Result.failure(
        DatabaseException.updateFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  // ==================== 统计功能 ====================

  /// 获取统计信息
  Future<Result<Map<String, int>>> getStatistics() async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // 总数
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableTodos}',
      );
      final total = totalResult.first['count'] as int? ?? 0;

      // 未完成
      final incompleteResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableTodos} '
        'WHERE ${DbConstants.columnTodoIsCompleted} = 0',
      );
      final incomplete = incompleteResult.first['count'] as int? ?? 0;

      // 已完成
      final completed = total - incomplete;

      // 今日待办
      final todayResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableTodos} '
        'WHERE ${DbConstants.columnTodoDueDate} >= ? AND ${DbConstants.columnTodoDueDate} < ?',
        [today.toUtc().millisecondsSinceEpoch, tomorrow.toUtc().millisecondsSinceEpoch],
      );
      final todayCount = todayResult.first['count'] as int? ?? 0;

      // 已逾期（未完成且截止日期已过）
      final overdueResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableTodos} '
        'WHERE ${DbConstants.columnTodoIsCompleted} = 0 '
        'AND ${DbConstants.columnTodoDueDate} IS NOT NULL '
        'AND ${DbConstants.columnTodoDueDate} < ?',
        [today.toUtc().millisecondsSinceEpoch],
      );
      final overdue = overdueResult.first['count'] as int? ?? 0;

      return Result.success({
        'total': total,
        'completed': completed,
        'incomplete': incomplete,
        'today': todayCount,
        'overdue': overdue,
      });
    } catch (e, s) {
      debugPrint('获取统计信息失败: $e');
      return Result.failure(
        DatabaseException.queryFailed(DbConstants.tableTodos, e, s),
      );
    }
  }

  // ==================== 提醒功能 ====================

  /// 调度待办提醒
  Future<void> _scheduleNotification(TodoModel todo) async {
    final notifyTime = todo.getNotificationTime();
    if (notifyTime == null) return;

    // 跳过已过期的通知
    if (notifyTime.isBefore(DateTime.now())) return;

    final notificationId = _generateNotificationId(todo.id);
    final title = '待办提醒: ${todo.title}';
    String body;

    if (todo.dueTime != null) {
      body = '截止时间: ${_formatTime(todo.dueTime!)}';
    } else if (todo.dueDate != null) {
      body = '今天截止';
    } else {
      body = '请及时完成';
    }

    if (todo.priority > 0) {
      body += ' [${todo.priorityEnum.label}优先级]';
    }

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledTime: notifyTime,
      payload: 'todo:${todo.id}',
    );
  }

  /// 取消待办提醒
  Future<void> _cancelNotification(String todoId) async {
    final notificationId = _generateNotificationId(todoId);
    await _notificationService.cancelNotification(notificationId);
  }

  /// 生成通知 ID（使用 FNV-1a 风格哈希）
  int _generateNotificationId(String todoId) {
    final input = 'todo|$todoId';

    // FNV-1a 32-bit 哈希算法
    int hash = 0x811c9dc5;
    const int prime = 0x01000193;

    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * prime) & 0xFFFFFFFF;
    }

    return hash & 0x7FFFFFFF;
  }

  /// 刷新所有待办的提醒
  Future<void> refreshAllNotifications() async {
    final result = await getIncompleteTodos();
    if (result.isFailure) return;

    for (final todo in result.valueOrNull!) {
      if (todo.notifyEnabled) {
        await _cancelNotification(todo.id);
        await _scheduleNotification(todo);
      }
    }
  }

  // ==================== 工具方法 ====================

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
