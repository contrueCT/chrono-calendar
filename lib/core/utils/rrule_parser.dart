import '../../data/models/recurrence_rule.dart';

/// RRULE 解析器 - 根据重复规则生成事件实例日期
class RRuleParser {
  RRuleParser._();

  /// 获取指定范围内的所有实例日期
  static List<DateTime> getOccurrences(
    RecurrenceRule rule,
    DateTime eventStart,
    DateTime rangeStart,
    DateTime rangeEnd, {
    List<DateTime>? exDates,
    int maxCount = 1000,
  }) {
    final occurrences = <DateTime>[];
    final exDateSet = exDates?.map(_normalizeDate).toSet() ?? <DateTime>{};

    int count = 0;
    DateTime current = eventStart;

    // 迭代生成实例
    while (count < maxCount) {
      // 检查是否超过结束条件
      if (rule.until != null && current.isAfter(rule.until!)) {
        break;
      }
      if (rule.count != null && occurrences.length >= rule.count!) {
        break;
      }

      // 检查当前日期是否在范围内
      if (current.isAfter(rangeEnd) || current.isAtSameMomentAs(rangeEnd)) {
        // 如果已超出范围且没有 count/until 限制，可以停止
        if (rule.count == null && rule.until == null) {
          break;
        }
        // 否则继续迭代但不添加结果
      }

      // 生成当前周期的候选日期
      final candidates = _generateCandidates(rule, current, eventStart);

      for (final candidate in candidates) {
        // 检查是否超过限制
        if (rule.count != null && occurrences.length >= rule.count!) {
          break;
        }
        if (rule.until != null && candidate.isAfter(rule.until!)) {
          break;
        }

        // 检查是否在范围内
        if (candidate.isBefore(rangeStart)) continue;
        if (candidate.isAfter(rangeEnd) || candidate.isAtSameMomentAs(rangeEnd)) continue;

        // 检查是否被排除
        if (exDateSet.contains(_normalizeDate(candidate))) continue;

        // 检查是否早于事件开始时间
        if (candidate.isBefore(eventStart)) continue;

        occurrences.add(candidate);
        count++;
      }

      // 移动到下一个周期
      current = _nextInterval(rule, current);

      // 安全检查：防止无限循环
      if (current.isAfter(rangeEnd.add(const Duration(days: 365 * 10)))) {
        break;
      }
    }

    return occurrences;
  }

  /// 生成当前周期的候选日期
  static List<DateTime> _generateCandidates(
    RecurrenceRule rule,
    DateTime periodStart,
    DateTime eventStart,
  ) {
    List<DateTime> candidates = [];

    switch (rule.frequency) {
      case Frequency.daily:
        candidates = [periodStart];
        break;

      case Frequency.weekly:
        candidates = _generateWeeklyCandidates(rule, periodStart, eventStart);
        break;

      case Frequency.monthly:
        candidates = _generateMonthlyCandidates(rule, periodStart, eventStart);
        break;

      case Frequency.yearly:
        candidates = _generateYearlyCandidates(rule, periodStart, eventStart);
        break;
    }

    // 应用 BYSETPOS 筛选
    if (rule.bySetPos != null && rule.bySetPos!.isNotEmpty) {
      candidates = _applyBySetPos(candidates, rule.bySetPos!);
    }

    return candidates;
  }

  /// 生成周规则的候选日期
  static List<DateTime> _generateWeeklyCandidates(
    RecurrenceRule rule,
    DateTime periodStart,
    DateTime eventStart,
  ) {
    if (rule.byDay == null || rule.byDay!.isEmpty) {
      // 没有指定星期几，使用事件开始的星期几
      return [periodStart];
    }

    final candidates = <DateTime>[];
    final weekStart = _getWeekStart(periodStart, rule.weekStart);

    for (final weekDay in rule.byDay!) {
      final dayOffset = _weekDayToInt(weekDay) - _weekDayToInt(rule.weekStart);
      final adjustedOffset = dayOffset < 0 ? dayOffset + 7 : dayOffset;
      final candidate = weekStart.add(Duration(days: adjustedOffset));

      // 保留原始事件的时间
      final withTime = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        eventStart.hour,
        eventStart.minute,
        eventStart.second,
      );

      candidates.add(withTime);
    }

    candidates.sort();
    return candidates;
  }

  /// 生成月规则的候选日期
  static List<DateTime> _generateMonthlyCandidates(
    RecurrenceRule rule,
    DateTime periodStart,
    DateTime eventStart,
  ) {
    final candidates = <DateTime>[];

    if (rule.byDayRules != null && rule.byDayRules!.isNotEmpty) {
      // 按"第 N 个星期几"
      for (final dayRule in rule.byDayRules!) {
        final candidate = _getNthWeekdayOfMonth(
          periodStart.year,
          periodStart.month,
          dayRule.weekDay,
          dayRule.position ?? 1,
          eventStart,
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
    } else if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
      // 按月中日期
      for (final day in rule.byMonthDay!) {
        final candidate = _getDayOfMonth(
          periodStart.year,
          periodStart.month,
          day,
          eventStart,
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
    } else {
      // 默认使用事件开始的日期
      final candidate = _getDayOfMonth(
        periodStart.year,
        periodStart.month,
        eventStart.day,
        eventStart,
      );
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    candidates.sort();
    return candidates;
  }

  /// 生成年规则的候选日期
  static List<DateTime> _generateYearlyCandidates(
    RecurrenceRule rule,
    DateTime periodStart,
    DateTime eventStart,
  ) {
    final candidates = <DateTime>[];

    if (rule.byMonth != null && rule.byMonth!.isNotEmpty) {
      for (final month in rule.byMonth!) {
        if (rule.byDayRules != null && rule.byDayRules!.isNotEmpty) {
          // 按月份 + 第 N 个星期几
          for (final dayRule in rule.byDayRules!) {
            final candidate = _getNthWeekdayOfMonth(
              periodStart.year,
              month,
              dayRule.weekDay,
              dayRule.position ?? 1,
              eventStart,
            );
            if (candidate != null) {
              candidates.add(candidate);
            }
          }
        } else if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
          // 按月份 + 日期
          for (final day in rule.byMonthDay!) {
            final candidate = _getDayOfMonth(
              periodStart.year,
              month,
              day,
              eventStart,
            );
            if (candidate != null) {
              candidates.add(candidate);
            }
          }
        } else {
          // 按月份 + 事件原始日期
          final candidate = _getDayOfMonth(
            periodStart.year,
            month,
            eventStart.day,
            eventStart,
          );
          if (candidate != null) {
            candidates.add(candidate);
          }
        }
      }
    } else {
      // 每年的同一天
      final candidate = _getDayOfMonth(
        periodStart.year,
        eventStart.month,
        eventStart.day,
        eventStart,
      );
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    candidates.sort();
    return candidates;
  }

  /// 获取下一个间隔的开始日期
  static DateTime _nextInterval(RecurrenceRule rule, DateTime current) {
    switch (rule.frequency) {
      case Frequency.daily:
        return current.add(Duration(days: rule.interval));

      case Frequency.weekly:
        return current.add(Duration(days: 7 * rule.interval));

      case Frequency.monthly:
        return DateTime(
          current.year,
          current.month + rule.interval,
          1,
          current.hour,
          current.minute,
          current.second,
        );

      case Frequency.yearly:
        return DateTime(
          current.year + rule.interval,
          1,
          1,
          current.hour,
          current.minute,
          current.second,
        );
    }
  }

  /// 获取月中第 N 个星期几的日期
  static DateTime? _getNthWeekdayOfMonth(
    int year,
    int month,
    WeekDay weekDay,
    int position,
    DateTime eventStart,
  ) {
    if (position == 0) return null;

    final targetWeekday = _weekDayToInt(weekDay);

    if (position > 0) {
      // 正数：从月初开始数
      final firstDay = DateTime(year, month, 1);
      final firstWeekday = firstDay.weekday;
      var daysToAdd = targetWeekday - firstWeekday;
      if (daysToAdd < 0) daysToAdd += 7;
      daysToAdd += (position - 1) * 7;

      final result = DateTime(
        year,
        month,
        1 + daysToAdd,
        eventStart.hour,
        eventStart.minute,
        eventStart.second,
      );

      // 检查是否还在当月
      if (result.month != month) return null;
      return result;
    } else {
      // 负数：从月末开始数
      final lastDay = DateTime(year, month + 1, 0);
      final lastWeekday = lastDay.weekday;
      var daysToSubtract = lastWeekday - targetWeekday;
      if (daysToSubtract < 0) daysToSubtract += 7;
      daysToSubtract += (-position - 1) * 7;

      final result = DateTime(
        year,
        month,
        lastDay.day - daysToSubtract,
        eventStart.hour,
        eventStart.minute,
        eventStart.second,
      );

      // 检查是否还在当月
      if (result.month != month || result.day < 1) return null;
      return result;
    }
  }

  /// 获取月中指定日期
  static DateTime? _getDayOfMonth(
    int year,
    int month,
    int day,
    DateTime eventStart,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    int actualDay;
    if (day > 0) {
      actualDay = day;
      if (actualDay > daysInMonth) return null;
    } else {
      // 负数表示从月末倒数
      actualDay = daysInMonth + day + 1;
      if (actualDay < 1) return null;
    }

    return DateTime(
      year,
      month,
      actualDay,
      eventStart.hour,
      eventStart.minute,
      eventStart.second,
    );
  }

  /// 获取周的开始日期
  static DateTime _getWeekStart(DateTime date, WeekDay weekStart) {
    final weekStartInt = _weekDayToInt(weekStart);
    var daysToSubtract = date.weekday - weekStartInt;
    if (daysToSubtract < 0) daysToSubtract += 7;
    return DateTime(
      date.year,
      date.month,
      date.day - daysToSubtract,
      date.hour,
      date.minute,
      date.second,
    );
  }

  /// 应用 BYSETPOS 筛选
  static List<DateTime> _applyBySetPos(
    List<DateTime> candidates,
    List<int> bySetPos,
  ) {
    if (candidates.isEmpty) return [];

    final result = <DateTime>[];
    for (final pos in bySetPos) {
      int index;
      if (pos > 0) {
        index = pos - 1;
      } else {
        index = candidates.length + pos;
      }
      if (index >= 0 && index < candidates.length) {
        result.add(candidates[index]);
      }
    }
    return result;
  }

  /// WeekDay 转换为 Dart 的 weekday (1-7，周一为 1)
  static int _weekDayToInt(WeekDay weekDay) {
    switch (weekDay) {
      case WeekDay.mo:
        return DateTime.monday;
      case WeekDay.tu:
        return DateTime.tuesday;
      case WeekDay.we:
        return DateTime.wednesday;
      case WeekDay.th:
        return DateTime.thursday;
      case WeekDay.fr:
        return DateTime.friday;
      case WeekDay.sa:
        return DateTime.saturday;
      case WeekDay.su:
        return DateTime.sunday;
    }
  }

  /// 标准化日期（去除时间部分，用于排除日期比较）
  static DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
