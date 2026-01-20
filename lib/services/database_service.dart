import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../core/constants/db_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';

/// 数据库服务 - 单例模式
///
/// 使用 Completer 确保线程安全的单例初始化。
/// 多个并发调用 database getter 时，只会创建一个数据库连接。
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// 获取数据库实例（线程安全）
  ///
  /// 使用 Completer 确保并发调用时只进行一次初始化。
  /// 如果初始化失败，会重置状态允许重试。
  Future<Database> get database async {
    // 如果已初始化完成，直接返回
    if (_database != null) return _database!;

    // 如果正在初始化中，等待完成
    if (_initCompleter != null) {
      return await _initCompleter!.future;
    }

    // 开始初始化（只有第一个调用者会执行到这里）
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      // 初始化失败，完成错误并重置状态
      _initCompleter!.completeError(e);
      _initCompleter = null;  // 重置，允许下次重试
      rethrow;
    }
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

    // v1 -> v2: 添加联合索引以优化查询性能
    if (oldVersion < 2) {
      debugPrint('执行 v1 -> v2 迁移：添加联合索引');
      try {
        // 添加 calendar_id + dtstart 联合索引
        await db.execute(DbConstants.createEventsCalendarDtstartIndex);
        // 添加 dtstart + dtend 联合索引
        await db.execute(DbConstants.createEventsDtstartDtendIndex);
        debugPrint('联合索引创建完成');
      } catch (e) {
        // 索引可能已存在，忽略错误
        debugPrint('创建索引时出错（可能已存在）: $e');
      }
    }

    // v2 -> v3: 添加待办表
    if (oldVersion < 3) {
      debugPrint('执行 v2 -> v3 迁移：添加待办表');
      try {
        for (final sql in DbConstants.upgradeToV3Statements) {
          await db.execute(sql);
        }
        debugPrint('待办表创建完成');
      } catch (e) {
        // 表可能已存在，忽略错误
        debugPrint('创建待办表时出错（可能已存在）: $e');
      }
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initCompleter = null;  // 重置初始化状态
      debugPrint('数据库已关闭');
    }
  }

  /// 删除数据库（用于调试）
  Future<void> deleteDatabase() async {
    // 先关闭数据库
    await close();

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DbConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    debugPrint('数据库已删除');
  }

  // ==================== 通用查询方法 ====================

  /// 插入数据
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// 批量插入数据（事务安全）
  ///
  /// 使用事务确保原子性：要么全部成功，要么全部回滚。
  /// 如果任何一条插入失败，整个操作将回滚。
  Future<void> insertBatch(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    if (dataList.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final data in dataList) {
        batch.insert(table, data);
      }
      // continueOnError: false 确保任何错误都会导致回滚
      await batch.commit(noResult: true, continueOnError: false);
    });
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

  // ==================== 安全操作方法（返回 Result）====================

  /// 安全插入数据，返回 Result
  Future<Result<int>> insertSafe(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      final id = await db.insert(table, data);
      return Result.success(id);
    } catch (e, s) {
      debugPrint('插入数据失败: $e');
      return Result.failure(DatabaseException.insertFailed(table, e, s));
    }
  }

  /// 安全更新数据，返回 Result
  Future<Result<int>> updateSafe(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      final count = await db.update(table, data, where: where, whereArgs: whereArgs);
      return Result.success(count);
    } catch (e, s) {
      debugPrint('更新数据失败: $e');
      return Result.failure(DatabaseException.updateFailed(table, e, s));
    }
  }

  /// 安全删除数据，返回 Result
  Future<Result<int>> deleteSafe(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      final count = await db.delete(table, where: where, whereArgs: whereArgs);
      return Result.success(count);
    } catch (e, s) {
      debugPrint('删除数据失败: $e');
      return Result.failure(DatabaseException.deleteFailed(table, e, s));
    }
  }

  /// 安全查询数据，返回 Result
  Future<Result<List<Map<String, dynamic>>>> querySafe(
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
    try {
      final db = await database;
      final results = await db.query(
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
      return Result.success(results);
    } catch (e, s) {
      debugPrint('查询数据失败: $e');
      return Result.failure(DatabaseException.queryFailed(table, e, s));
    }
  }

  /// 安全批量插入数据，返回 Result
  Future<Result<void>> insertBatchSafe(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    if (dataList.isEmpty) return Result.success(null);

    try {
      final db = await database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final data in dataList) {
          batch.insert(table, data);
        }
        await batch.commit(noResult: true, continueOnError: false);
      });
      return Result.success(null);
    } catch (e, s) {
      debugPrint('批量插入数据失败: $e');
      return Result.failure(DatabaseException.insertFailed(table, e, s));
    }
  }
}
