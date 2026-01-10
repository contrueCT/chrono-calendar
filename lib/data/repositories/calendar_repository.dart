import '../../core/constants/db_constants.dart';
import '../../services/database_service.dart';
import '../models/calendar_model.dart';

/// 日历仓库 - 处理日历数据的 CRUD 操作
class CalendarRepository {
  final DatabaseService _databaseService;

  CalendarRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  /// 获取所有日历
  Future<List<CalendarModel>> getAllCalendars() async {
    final maps = await _databaseService.query(
      DbConstants.tableCalendars,
      orderBy: '${DbConstants.columnCalendarIsDefault} DESC, ${DbConstants.columnCalendarCreatedAt} ASC',
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 获取可见日历
  Future<List<CalendarModel>> getVisibleCalendars() async {
    final maps = await _databaseService.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnCalendarIsVisible} = ?',
      whereArgs: [1],
      orderBy: '${DbConstants.columnCalendarIsDefault} DESC, ${DbConstants.columnCalendarCreatedAt} ASC',
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 根据 ID 获取日历
  Future<CalendarModel?> getCalendarById(String id) async {
    final maps = await _databaseService.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first);
  }

  /// 获取默认日历
  Future<CalendarModel?> getDefaultCalendar() async {
    final maps = await _databaseService.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnCalendarIsDefault} = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first);
  }

  /// 获取订阅日历
  Future<List<CalendarModel>> getSubscriptionCalendars() async {
    final maps = await _databaseService.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnCalendarIsSubscription} = ?',
      whereArgs: [1],
      orderBy: '${DbConstants.columnCalendarCreatedAt} ASC',
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 获取需要同步的日历
  Future<List<CalendarModel>> getCalendarsNeedingSync() async {
    final calendars = await getSubscriptionCalendars();
    return calendars.where((c) => c.needsSync).toList();
  }

  /// 插入日历
  Future<void> insertCalendar(CalendarModel calendar) async {
    await _databaseService.insert(DbConstants.tableCalendars, calendar.toMap());
  }

  /// 更新日历
  Future<void> updateCalendar(CalendarModel calendar) async {
    await _databaseService.update(
      DbConstants.tableCalendars,
      calendar.toMap(),
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [calendar.id],
    );
  }

  /// 删除日历（关联事件会通过外键级联删除）
  Future<void> deleteCalendar(String id) async {
    await _databaseService.delete(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 设置默认日历
  Future<void> setDefaultCalendar(String id) async {
    await _databaseService.transaction((txn) async {
      // 先取消所有日历的默认状态
      await txn.update(
        DbConstants.tableCalendars,
        {DbConstants.columnCalendarIsDefault: 0},
      );
      // 设置新的默认日历
      await txn.update(
        DbConstants.tableCalendars,
        {DbConstants.columnCalendarIsDefault: 1},
        where: '${DbConstants.columnCalendarId} = ?',
        whereArgs: [id],
      );
    });
  }

  /// 切换日历可见性
  Future<void> toggleVisibility(String id) async {
    final calendar = await getCalendarById(id);
    if (calendar == null) return;

    await _databaseService.update(
      DbConstants.tableCalendars,
      {DbConstants.columnCalendarIsVisible: calendar.isVisible ? 0 : 1},
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 更新日历颜色
  Future<void> updateColor(String id, int color) async {
    await _databaseService.update(
      DbConstants.tableCalendars,
      {DbConstants.columnCalendarColor: color},
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 更新最后同步时间
  Future<void> updateLastSyncTime(String id) async {
    await _databaseService.update(
      DbConstants.tableCalendars,
      {
        DbConstants.columnCalendarLastSyncTime:
            DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnCalendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 获取日历数量
  Future<int> getCalendarCount() async {
    return await _databaseService.count(DbConstants.tableCalendars);
  }

  /// 检查日历名称是否存在
  Future<bool> isNameExists(String name, {String? excludeId}) async {
    String where = '${DbConstants.columnCalendarName} = ?';
    List<Object?> whereArgs = [name];

    if (excludeId != null) {
      where += ' AND ${DbConstants.columnCalendarId} != ?';
      whereArgs.add(excludeId);
    }

    final count = await _databaseService.count(
      DbConstants.tableCalendars,
      where: where,
      whereArgs: whereArgs,
    );
    return count > 0;
  }
}
