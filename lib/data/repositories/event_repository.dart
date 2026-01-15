import '../../core/constants/db_constants.dart';
import '../../services/database_service.dart';
import '../models/event_model.dart';
import '../models/reminder_model.dart';

/// 事件仓库 - 处理事件数据的 CRUD 操作
class EventRepository {
  final DatabaseService _databaseService;

  EventRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  // ==================== 事件 CRUD ====================

  /// 获取所有事件
  Future<List<EventModel>> getAllEvents() async {
    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      orderBy: '${DbConstants.columnEventDtstart} ASC',
    );
    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  /// 根据 UID 获取事件
  Future<EventModel?> getEventByUid(String uid) async {
    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      where: '${DbConstants.columnEventUid} = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first);
  }

  /// 获取指定日历的事件
  Future<List<EventModel>> getEventsByCalendarId(String calendarId) async {
    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      where: '${DbConstants.columnEventCalendarId} = ?',
      whereArgs: [calendarId],
      orderBy: '${DbConstants.columnEventDtstart} ASC',
    );
    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  /// 获取指定日期范围内的事件（不包括重复事件的展开）
  ///
  /// 对于单次事件：检查事件是否与查询范围有重叠
  /// 对于重复事件：只加载 dtStart 早于查询范围结束的事件，在应用层展开实例
  Future<List<EventModel>> getEventsInRange(
    DateTime start,
    DateTime end, {
    List<String>? calendarIds,
  }) async {
    final startTimestamp = start.toUtc().millisecondsSinceEpoch;
    final endTimestamp = end.toUtc().millisecondsSinceEpoch;

    // 查询条件说明：
    // 1. 单次事件：事件开始时间在范围内，或事件结束时间在范围内，或事件跨越整个范围
    // 2. 重复事件：dtStart 必须早于查询范围的结束时间（实例展开在应用层处理）
    //    这样可以避免加载已经完全结束的历史重复事件
    String where = '('
        // 单次事件的条件
        '(${DbConstants.columnEventRrule} IS NULL AND ('
        '(${DbConstants.columnEventDtstart} >= ? AND ${DbConstants.columnEventDtstart} < ?) '
        'OR (${DbConstants.columnEventDtend} > ? AND ${DbConstants.columnEventDtend} <= ?) '
        'OR (${DbConstants.columnEventDtstart} <= ? AND ${DbConstants.columnEventDtend} >= ?)'
        '))'
        ' OR '
        // 重复事件的条件：dtStart 早于查询范围结束，且 rrule 不为空
        '(${DbConstants.columnEventRrule} IS NOT NULL AND ${DbConstants.columnEventDtstart} < ?)'
        ')';
    List<Object?> whereArgs = [
      // 单次事件的参数
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      // 重复事件的参数
      endTimestamp,
    ];

    if (calendarIds != null && calendarIds.isNotEmpty) {
      final placeholders = calendarIds.map((_) => '?').join(',');
      where += ' AND ${DbConstants.columnEventCalendarId} IN ($placeholders)';
      whereArgs.addAll(calendarIds);
    }

    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.columnEventDtstart} ASC',
    );

    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  /// 获取指定日期的事件（精确匹配单天）
  Future<List<EventModel>> getEventsForDate(
    DateTime date, {
    List<String>? calendarIds,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getEventsInRange(dayStart, dayEnd, calendarIds: calendarIds);
  }

  /// 搜索事件
  Future<List<EventModel>> searchEvents(
    String query, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final searchPattern = '%$query%';

    String where = '(${DbConstants.columnEventSummary} LIKE ? '
        'OR ${DbConstants.columnEventDescription} LIKE ? '
        'OR ${DbConstants.columnEventLocation} LIKE ?)';
    List<Object?> whereArgs = [searchPattern, searchPattern, searchPattern];

    if (startDate != null) {
      where += ' AND ${DbConstants.columnEventDtstart} >= ?';
      whereArgs.add(startDate.toUtc().millisecondsSinceEpoch);
    }

    if (endDate != null) {
      where += ' AND ${DbConstants.columnEventDtstart} <= ?';
      whereArgs.add(endDate.toUtc().millisecondsSinceEpoch);
    }

    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.columnEventDtstart} DESC',
      limit: limit,
    );

    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  /// 获取重复事件列表
  Future<List<EventModel>> getRecurringEvents() async {
    final maps = await _databaseService.query(
      DbConstants.tableEvents,
      where: '${DbConstants.columnEventRrule} IS NOT NULL AND ${DbConstants.columnEventRrule} != ?',
      whereArgs: [''],
    );
    return maps.map((map) => EventModel.fromMap(map)).toList();
  }

  /// 插入事件
  Future<void> insertEvent(EventModel event) async {
    await _databaseService.insert(DbConstants.tableEvents, event.toMap());
  }

  /// 批量插入事件（事务安全）
  ///
  /// 使用事务确保原子性：要么全部成功，要么全部回滚。
  /// 如果需要导入大量事件，建议分批处理以避免内存问题。
  Future<void> insertEvents(List<EventModel> events) async {
    if (events.isEmpty) return;

    await _databaseService.insertBatch(
      DbConstants.tableEvents,
      events.map((e) => e.toMap()).toList(),
    );
  }

  /// 更新事件
  Future<void> updateEvent(EventModel event) async {
    // 更新时自动增加 sequence 和更新时间
    final updatedEvent = event.copyWith(
      sequence: event.sequence + 1,
      updatedAt: DateTime.now(),
    );

    await _databaseService.update(
      DbConstants.tableEvents,
      updatedEvent.toMap(),
      where: '${DbConstants.columnEventUid} = ?',
      whereArgs: [event.uid],
    );
  }

  /// 删除事件
  Future<void> deleteEvent(String uid) async {
    await _databaseService.delete(
      DbConstants.tableEvents,
      where: '${DbConstants.columnEventUid} = ?',
      whereArgs: [uid],
    );
  }

  /// 删除指定日历的所有事件
  Future<void> deleteEventsByCalendarId(String calendarId) async {
    await _databaseService.delete(
      DbConstants.tableEvents,
      where: '${DbConstants.columnEventCalendarId} = ?',
      whereArgs: [calendarId],
    );
  }

  /// 为重复事件添加排除日期（删除单个实例）
  Future<void> addExcludeDate(String uid, DateTime excludeDate) async {
    final event = await getEventByUid(uid);
    if (event == null || event.rrule == null) return;

    final exDates = List<DateTime>.from(event.exDates ?? []);
    exDates.add(excludeDate);

    final updatedEvent = event.copyWith(
      exDates: exDates,
      sequence: event.sequence + 1,
      updatedAt: DateTime.now(),
    );

    await _databaseService.update(
      DbConstants.tableEvents,
      updatedEvent.toMap(),
      where: '${DbConstants.columnEventUid} = ?',
      whereArgs: [uid],
    );
  }

  /// 获取事件数量
  Future<int> getEventCount({String? calendarId}) async {
    if (calendarId != null) {
      return await _databaseService.count(
        DbConstants.tableEvents,
        where: '${DbConstants.columnEventCalendarId} = ?',
        whereArgs: [calendarId],
      );
    }
    return await _databaseService.count(DbConstants.tableEvents);
  }

  // ==================== 提醒相关 ====================

  /// 获取事件的所有提醒
  Future<List<ReminderModel>> getRemindersForEvent(String eventUid) async {
    final maps = await _databaseService.query(
      DbConstants.tableReminders,
      where: '${DbConstants.columnReminderEventUid} = ?',
      whereArgs: [eventUid],
    );
    return maps.map((map) => ReminderModel.fromMap(map)).toList();
  }

  /// 添加提醒
  Future<int> addReminder(ReminderModel reminder) async {
    return await _databaseService.insert(
      DbConstants.tableReminders,
      reminder.toMap(),
    );
  }

  /// 删除提醒
  Future<void> deleteReminder(int id) async {
    await _databaseService.delete(
      DbConstants.tableReminders,
      where: '${DbConstants.columnReminderId} = ?',
      whereArgs: [id],
    );
  }

  /// 删除事件的所有提醒
  Future<void> deleteRemindersForEvent(String eventUid) async {
    await _databaseService.delete(
      DbConstants.tableReminders,
      where: '${DbConstants.columnReminderEventUid} = ?',
      whereArgs: [eventUid],
    );
  }

  /// 更新事件的提醒（替换所有）
  Future<void> updateReminders(
    String eventUid,
    List<ReminderModel> reminders,
  ) async {
    await _databaseService.transaction((txn) async {
      // 删除旧的提醒
      await txn.delete(
        DbConstants.tableReminders,
        where: '${DbConstants.columnReminderEventUid} = ?',
        whereArgs: [eventUid],
      );

      // 添加新的提醒
      for (final reminder in reminders) {
        await txn.insert(DbConstants.tableReminders, reminder.toMap());
      }
    });
  }

  // ==================== 事件缓存相关 ====================

  /// 获取缓存的事件实例
  Future<List<Map<String, dynamic>>> getCachedInstances(
    DateTime start,
    DateTime end,
  ) async {
    final startTimestamp = start.toUtc().millisecondsSinceEpoch;
    final endTimestamp = end.toUtc().millisecondsSinceEpoch;

    return await _databaseService.query(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.columnCacheOccurrenceDate} >= ? AND ${DbConstants.columnCacheOccurrenceDate} < ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: '${DbConstants.columnCacheOccurrenceDate} ASC',
    );
  }

  /// 添加缓存实例
  Future<void> addCachedInstance(
    String eventUid,
    DateTime occurrenceDate, {
    bool isException = false,
  }) async {
    await _databaseService.insert(DbConstants.tableEventCache, {
      DbConstants.columnCacheEventUid: eventUid,
      DbConstants.columnCacheOccurrenceDate:
          occurrenceDate.toUtc().millisecondsSinceEpoch,
      DbConstants.columnCacheIsException: isException ? 1 : 0,
    });
  }

  /// 批量添加缓存实例
  Future<void> addCachedInstances(
    List<Map<String, dynamic>> instances,
  ) async {
    await _databaseService.insertBatch(DbConstants.tableEventCache, instances);
  }

  /// 删除事件的所有缓存实例
  Future<void> deleteCachedInstancesForEvent(String eventUid) async {
    await _databaseService.delete(
      DbConstants.tableEventCache,
      where: '${DbConstants.columnCacheEventUid} = ?',
      whereArgs: [eventUid],
    );
  }

  /// 删除指定日期之前的缓存
  Future<void> deleteExpiredCache(DateTime before) async {
    await _databaseService.delete(
      DbConstants.tableEventCache,
      where: '${DbConstants.columnCacheOccurrenceDate} < ?',
      whereArgs: [before.toUtc().millisecondsSinceEpoch],
    );
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    await _databaseService.delete(DbConstants.tableEventCache);
  }
}
