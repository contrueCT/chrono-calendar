import 'package:flutter/foundation.dart';
import '../data/models/countdown_model.dart';
import '../core/constants/db_constants.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// 倒计时服务 - 管理倒计时的 CRUD 操作和提醒
class CountdownService {
  static final CountdownService _instance = CountdownService._internal();
  factory CountdownService() => _instance;
  CountdownService._internal();

  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  /// 获取所有倒计时
  Future<List<CountdownModel>> getAllCountdowns() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableCountdowns,
        orderBy: '${DbConstants.columnCountdownTargetDate} ASC',
      );
      return maps.map((map) => CountdownModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取倒计时列表失败: $e');
      return [];
    }
  }

  /// 获取单个倒计时
  Future<CountdownModel?> getCountdown(String id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableCountdowns,
        where: '${DbConstants.columnCountdownId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return CountdownModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('获取倒计时失败: $e');
      return null;
    }
  }

  /// 获取即将到来的倒计时（未来30天内）
  Future<List<CountdownModel>> getUpcomingCountdowns({int days = 30}) async {
    final allCountdowns = await getAllCountdowns();
    return allCountdowns.where((countdown) {
      final remaining = countdown.getDaysRemaining();
      return remaining >= 0 && remaining <= days;
    }).toList()
      ..sort((a, b) => a.getDaysRemaining().compareTo(b.getDaysRemaining()));
  }

  /// 按分类获取倒计时
  Future<List<CountdownModel>> getCountdownsByCategory(CountdownCategory category) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        DbConstants.tableCountdowns,
        where: '${DbConstants.columnCountdownCategory} = ?',
        whereArgs: [category.name],
        orderBy: '${DbConstants.columnCountdownTargetDate} ASC',
      );
      return maps.map((map) => CountdownModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('按分类获取倒计时失败: $e');
      return [];
    }
  }

  /// 创建倒计时
  Future<bool> createCountdown(CountdownModel countdown) async {
    try {
      final db = await _db.database;
      await db.insert(DbConstants.tableCountdowns, countdown.toMap());

      // 调度提醒
      if (countdown.notifyEnabled) {
        await _scheduleNotifications(countdown);
      }

      return true;
    } catch (e) {
      debugPrint('创建倒计时失败: $e');
      return false;
    }
  }

  /// 更新倒计时
  Future<bool> updateCountdown(CountdownModel countdown) async {
    try {
      final db = await _db.database;
      await db.update(
        DbConstants.tableCountdowns,
        countdown.toMap(),
        where: '${DbConstants.columnCountdownId} = ?',
        whereArgs: [countdown.id],
      );

      // 取消旧提醒并重新调度
      await _cancelNotifications(countdown.id);
      if (countdown.notifyEnabled) {
        await _scheduleNotifications(countdown);
      }

      return true;
    } catch (e) {
      debugPrint('更新倒计时失败: $e');
      return false;
    }
  }

  /// 删除倒计时
  Future<bool> deleteCountdown(String id) async {
    try {
      final db = await _db.database;
      await db.delete(
        DbConstants.tableCountdowns,
        where: '${DbConstants.columnCountdownId} = ?',
        whereArgs: [id],
      );

      // 取消提醒
      await _cancelNotifications(id);

      return true;
    } catch (e) {
      debugPrint('删除倒计时失败: $e');
      return false;
    }
  }

  /// 调度倒计时提醒
  Future<void> _scheduleNotifications(CountdownModel countdown) async {
    if (!countdown.notifyEnabled || countdown.notifyDays == null) return;

    final targetDate = countdown.getNextTargetDate();
    final now = DateTime.now();

    for (final daysBefore in countdown.notifyDays!) {
      final notifyDate = targetDate.subtract(Duration(days: daysBefore));

      // 跳过已过期的通知
      if (notifyDate.isBefore(now)) continue;

      // 设置通知时间为当天上午 9:00
      final scheduledTime = DateTime(
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        9,
        0,
      );

      // 如果时间已过，跳过
      if (scheduledTime.isBefore(now)) continue;

      final notificationId = _generateNotificationId(countdown.id, daysBefore);
      final title = daysBefore == 0
          ? '${countdown.title} 就是今天!'
          : '${countdown.title} 还有 $daysBefore 天';
      final body = daysBefore == 0
          ? '祝您有美好的一天!'
          : '距离 ${countdown.title} 还有 $daysBefore 天';

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: 'countdown:${countdown.id}',
      );
    }
  }

  /// 取消倒计时的所有提醒
  Future<void> _cancelNotifications(String countdownId) async {
    // 取消所有可能的提醒（假设最多提前 30 天提醒）
    for (var i = 0; i <= 30; i++) {
      final notificationId = _generateNotificationId(countdownId, i);
      await _notificationService.cancelNotification(notificationId);
    }
  }

  /// 生成通知 ID（使用 FNV-1a 风格哈希减少碰撞）
  ///
  /// 基于倒计时 ID 和提前天数生成唯一 ID。
  /// 使用 FNV-1a 32-bit 哈希算法，比 Dart 内置 hashCode 有更好的分布性。
  int _generateNotificationId(String countdownId, int daysBefore) {
    final input = 'countdown|$countdownId|$daysBefore';

    // FNV-1a 32-bit 哈希算法
    int hash = 0x811c9dc5; // FNV offset basis
    const int prime = 0x01000193; // FNV prime

    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * prime) & 0xFFFFFFFF;
    }

    return hash & 0x7FFFFFFF;
  }

  /// 刷新所有倒计时的提醒（用于每年重复的倒计时）
  Future<void> refreshAllNotifications() async {
    final countdowns = await getAllCountdowns();
    for (final countdown in countdowns) {
      if (countdown.notifyEnabled && countdown.repeatYearly) {
        await _cancelNotifications(countdown.id);
        await _scheduleNotifications(countdown);
      }
    }
  }

  /// 获取今日倒计时
  Future<List<CountdownModel>> getTodayCountdowns() async {
    final allCountdowns = await getAllCountdowns();
    return allCountdowns.where((countdown) {
      return countdown.getDaysRemaining() == 0;
    }).toList();
  }

  /// 获取统计信息
  Future<Map<String, int>> getStatistics() async {
    final allCountdowns = await getAllCountdowns();
    final today = allCountdowns.where((c) => c.getDaysRemaining() == 0).length;
    final upcoming = allCountdowns.where((c) {
      final days = c.getDaysRemaining();
      return days > 0 && days <= 7;
    }).length;
    final total = allCountdowns.length;

    return {
      'today': today,
      'upcoming': upcoming,
      'total': total,
    };
  }
}
