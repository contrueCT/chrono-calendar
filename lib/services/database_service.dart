import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/db_constants.dart';

/// 数据库服务 - 单例模式
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DbConstants.databaseName);

    debugPrint('数据库路径: $path');

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// 配置数据库（启用外键约束）
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('创建数据库表...');

    for (final sql in DbConstants.createTableStatements) {
      await db.execute(sql);
    }

    // 创建默认日历
    await _createDefaultCalendar(db);

    debugPrint('数据库表创建完成');
  }

  /// 创建默认日历
  Future<void> _createDefaultCalendar(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(DbConstants.tableCalendars, {
      DbConstants.columnCalendarId: 'default',
      DbConstants.columnCalendarName: '我的日历',
      DbConstants.columnCalendarColor: 0xFF2563EB,
      DbConstants.columnCalendarIsVisible: 1,
      DbConstants.columnCalendarIsDefault: 1,
      DbConstants.columnCalendarIsSubscription: 0,
      DbConstants.columnCalendarCreatedAt: now,
    });
    debugPrint('默认日历已创建');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('数据库升级: $oldVersion -> $newVersion');

    // 预留升级逻辑
    // if (oldVersion < 2) {
    //   // 执行 v1 -> v2 的迁移
    // }
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('数据库已关闭');
    }
  }

  /// 删除数据库（用于调试）
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DbConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    debugPrint('数据库已删除');
  }

  // ==================== 通用查询方法 ====================

  /// 插入数据
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// 批量插入数据
  Future<void> insertBatch(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final data in dataList) {
      batch.insert(table, data);
    }
    await batch.commit(noResult: true);
  }

  /// 更新数据
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// 删除数据
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 查询数据
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 执行原始 SQL 查询
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 执行原始 SQL 语句
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// 开始事务
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// 获取表中记录数量
  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
