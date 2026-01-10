import 'package:intl/intl.dart';

/// 重复频率枚举 (RFC 5545 FREQ)
enum Frequency {
  daily,    // 每天
  weekly,   // 每周
  monthly,  // 每月
  yearly,   // 每年
}

/// 星期枚举 (RFC 5545 weekday)
enum WeekDay {
  mo,  // 周一
  tu,  // 周二
  we,  // 周三
  th,  // 周四
  fr,  // 周五
  sa,  // 周六
  su,  // 周日
}

/// 带位置的星期规则（如 1MO = 第一个周一，-1FR = 最后一个周五）
class ByDayRule {
  /// 位置：null 表示所有，正数表示第 N 个，负数表示倒数第 N 个
  final int? position;

  /// 星期几
  final WeekDay weekDay;

  const ByDayRule({
    this.position,
    required this.weekDay,
  });

  /// 从 RRULE 值解析（如 "1MO", "-1FR", "TU"）
  factory ByDayRule.parse(String value) {
    final weekDayStr = value.replaceAll(RegExp(r'[^A-Z]'), '');
    final positionStr = value.replaceAll(RegExp(r'[A-Z]'), '');

    final weekDay = WeekDay.values.firstWhere(
      (e) => e.name.toUpperCase() == weekDayStr,
    );

    int? position;
    if (positionStr.isNotEmpty) {
      position = int.parse(positionStr);
    }

    return ByDayRule(position: position, weekDay: weekDay);
  }

  /// 转换为 RRULE 值
  String toRRuleValue() {
    if (position == null) {
      return weekDay.name.toUpperCase();
    }
    return '$position${weekDay.name.toUpperCase()}';
  }

  @override
  String toString() => toRRuleValue();
}

/// RFC 5545 重复规则模型
class RecurrenceRule {
  /// 频率（必需）
  final Frequency frequency;

  /// 间隔（默认 1）
  final int interval;

  /// 重复次数
  final int? count;

  /// 结束日期
  final DateTime? until;

  /// 按星期几（简单形式，如每周一三五）
  final List<WeekDay>? byDay;

  /// 按星期几（带位置，如每月第一个周一）
  final List<ByDayRule>? byDayRules;

  /// 按月中日期（1-31，-31 到 -1 表示倒数）
  final List<int>? byMonthDay;

  /// 按月份（1-12）
  final List<int>? byMonth;

  /// 按年中日期（1-366，-366 到 -1）
  final List<int>? byYearDay;

  /// 按周数（1-53，-53 到 -1）
  final List<int>? byWeekNo;

  /// 按位置选择
  final List<int>? bySetPos;

  /// 周起始日（默认周一）
  final WeekDay weekStart;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay,
    this.byDayRules,
    this.byMonthDay,
    this.byMonth,
    this.byYearDay,
    this.byWeekNo,
    this.bySetPos,
    this.weekStart = WeekDay.mo,
  });

  /// 从 RRULE 字符串解析
  factory RecurrenceRule.fromRRuleString(String rrule) {
    // 移除可能的 "RRULE:" 前缀
    final ruleString = rrule.replaceFirst(RegExp(r'^RRULE:', caseSensitive: false), '');

    final parts = ruleString.split(';');
    final Map<String, String> params = {};

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        params[keyValue[0].toUpperCase()] = keyValue[1];
      }
    }

    // 解析频率
    final freqStr = params['FREQ']?.toUpperCase();
    final frequency = Frequency.values.firstWhere(
      (f) => f.name.toUpperCase() == freqStr,
      orElse: () => Frequency.daily,
    );

    // 解析间隔
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

    // 解析次数
    int? count;
    if (params['COUNT'] != null) {
      count = int.tryParse(params['COUNT']!);
    }

    // 解析结束日期
    DateTime? until;
    if (params['UNTIL'] != null) {
      until = _parseDateTime(params['UNTIL']!);
    }

    // 解析 BYDAY
    List<WeekDay>? byDay;
    List<ByDayRule>? byDayRules;
    if (params['BYDAY'] != null) {
      final byDayParts = params['BYDAY']!.split(',');
      final hasPosition = byDayParts.any((p) => RegExp(r'\d').hasMatch(p));

      if (hasPosition) {
        byDayRules = byDayParts.map((p) => ByDayRule.parse(p)).toList();
      } else {
        byDay = byDayParts.map((p) {
          return WeekDay.values.firstWhere(
            (w) => w.name.toUpperCase() == p.toUpperCase(),
          );
        }).toList();
      }
    }

    // 解析 BYMONTHDAY
    List<int>? byMonthDay;
    if (params['BYMONTHDAY'] != null) {
      byMonthDay = params['BYMONTHDAY']!
          .split(',')
          .map((s) => int.parse(s))
          .toList();
    }

    // 解析 BYMONTH
    List<int>? byMonth;
    if (params['BYMONTH'] != null) {
      byMonth = params['BYMONTH']!
          .split(',')
          .map((s) => int.parse(s))
          .toList();
    }

    // 解析 BYYEARDAY
    List<int>? byYearDay;
    if (params['BYYEARDAY'] != null) {
      byYearDay = params['BYYEARDAY']!
          .split(',')
          .map((s) => int.parse(s))
          .toList();
    }

    // 解析 BYWEEKNO
    List<int>? byWeekNo;
    if (params['BYWEEKNO'] != null) {
      byWeekNo = params['BYWEEKNO']!
          .split(',')
          .map((s) => int.parse(s))
          .toList();
    }

    // 解析 BYSETPOS
    List<int>? bySetPos;
    if (params['BYSETPOS'] != null) {
      bySetPos = params['BYSETPOS']!
          .split(',')
          .map((s) => int.parse(s))
          .toList();
    }

    // 解析 WKST
    WeekDay weekStart = WeekDay.mo;
    if (params['WKST'] != null) {
      weekStart = WeekDay.values.firstWhere(
        (w) => w.name.toUpperCase() == params['WKST']!.toUpperCase(),
        orElse: () => WeekDay.mo,
      );
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay,
      byDayRules: byDayRules,
      byMonthDay: byMonthDay,
      byMonth: byMonth,
      byYearDay: byYearDay,
      byWeekNo: byWeekNo,
      bySetPos: bySetPos,
      weekStart: weekStart,
    );
  }

  /// 转换为 RRULE 字符串
  String toRRuleString() {
    final parts = <String>[];

    parts.add('FREQ=${frequency.name.toUpperCase()}');

    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }

    if (count != null) {
      parts.add('COUNT=$count');
    }

    if (until != null) {
      parts.add('UNTIL=${_formatDateTime(until!)}');
    }

    if (byDay != null && byDay!.isNotEmpty) {
      parts.add('BYDAY=${byDay!.map((d) => d.name.toUpperCase()).join(',')}');
    }

    if (byDayRules != null && byDayRules!.isNotEmpty) {
      parts.add('BYDAY=${byDayRules!.map((r) => r.toRRuleValue()).join(',')}');
    }

    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      parts.add('BYMONTHDAY=${byMonthDay!.join(',')}');
    }

    if (byMonth != null && byMonth!.isNotEmpty) {
      parts.add('BYMONTH=${byMonth!.join(',')}');
    }

    if (byYearDay != null && byYearDay!.isNotEmpty) {
      parts.add('BYYEARDAY=${byYearDay!.join(',')}');
    }

    if (byWeekNo != null && byWeekNo!.isNotEmpty) {
      parts.add('BYWEEKNO=${byWeekNo!.join(',')}');
    }

    if (bySetPos != null && bySetPos!.isNotEmpty) {
      parts.add('BYSETPOS=${bySetPos!.join(',')}');
    }

    if (weekStart != WeekDay.mo) {
      parts.add('WKST=${weekStart.name.toUpperCase()}');
    }

    return parts.join(';');
  }

  /// 复制并修改
  RecurrenceRule copyWith({
    Frequency? frequency,
    int? interval,
    int? count,
    DateTime? until,
    List<WeekDay>? byDay,
    List<ByDayRule>? byDayRules,
    List<int>? byMonthDay,
    List<int>? byMonth,
    List<int>? byYearDay,
    List<int>? byWeekNo,
    List<int>? bySetPos,
    WeekDay? weekStart,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      count: count ?? this.count,
      until: until ?? this.until,
      byDay: byDay ?? this.byDay,
      byDayRules: byDayRules ?? this.byDayRules,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      byMonth: byMonth ?? this.byMonth,
      byYearDay: byYearDay ?? this.byYearDay,
      byWeekNo: byWeekNo ?? this.byWeekNo,
      bySetPos: bySetPos ?? this.bySetPos,
      weekStart: weekStart ?? this.weekStart,
    );
  }

  /// 获取人类可读的描述
  String get description {
    final buffer = StringBuffer();

    // 频率描述
    final intervalText = interval > 1 ? '每 $interval ' : '每';
    switch (frequency) {
      case Frequency.daily:
        buffer.write('$intervalText天');
        break;
      case Frequency.weekly:
        buffer.write('$intervalText周');
        if (byDay != null && byDay!.isNotEmpty) {
          buffer.write('的${_weekDaysText(byDay!)}');
        }
        break;
      case Frequency.monthly:
        buffer.write('$intervalText月');
        if (byDayRules != null && byDayRules!.isNotEmpty) {
          buffer.write('的${_byDayRulesText(byDayRules!)}');
        } else if (byMonthDay != null && byMonthDay!.isNotEmpty) {
          buffer.write('的${byMonthDay!.join(', ')}号');
        }
        break;
      case Frequency.yearly:
        buffer.write('$intervalText年');
        if (byMonth != null && byMonth!.isNotEmpty) {
          buffer.write('的${byMonth!.join(', ')}月');
        }
        break;
    }

    // 结束条件
    if (count != null) {
      buffer.write('，共 $count 次');
    } else if (until != null) {
      buffer.write('，至 ${DateFormat('yyyy-MM-dd').format(until!)}');
    }

    return buffer.toString();
  }

  String _weekDaysText(List<WeekDay> days) {
    const names = {
      WeekDay.mo: '周一',
      WeekDay.tu: '周二',
      WeekDay.we: '周三',
      WeekDay.th: '周四',
      WeekDay.fr: '周五',
      WeekDay.sa: '周六',
      WeekDay.su: '周日',
    };
    return days.map((d) => names[d]).join('、');
  }

  String _byDayRulesText(List<ByDayRule> rules) {
    const dayNames = {
      WeekDay.mo: '周一',
      WeekDay.tu: '周二',
      WeekDay.we: '周三',
      WeekDay.th: '周四',
      WeekDay.fr: '周五',
      WeekDay.sa: '周六',
      WeekDay.su: '周日',
    };
    const posNames = {
      1: '第一个',
      2: '第二个',
      3: '第三个',
      4: '第四个',
      5: '第五个',
      -1: '最后一个',
      -2: '倒数第二个',
    };

    return rules.map((r) {
      final posText = r.position != null ? (posNames[r.position] ?? '第${r.position}个') : '';
      return '$posText${dayNames[r.weekDay]}';
    }).join('、');
  }

  /// 解析 iCalendar 日期时间格式
  static DateTime? _parseDateTime(String value) {
    try {
      // 格式：20261231T235959Z 或 20261231
      if (value.endsWith('Z')) {
        // UTC 时间
        final str = value.substring(0, value.length - 1);
        if (str.length == 15) {
          return DateTime.utc(
            int.parse(str.substring(0, 4)),
            int.parse(str.substring(4, 6)),
            int.parse(str.substring(6, 8)),
            int.parse(str.substring(9, 11)),
            int.parse(str.substring(11, 13)),
            int.parse(str.substring(13, 15)),
          ).toLocal();
        }
      } else if (value.length == 8) {
        // 仅日期
        return DateTime(
          int.parse(value.substring(0, 4)),
          int.parse(value.substring(4, 6)),
          int.parse(value.substring(6, 8)),
        );
      } else if (value.length == 15) {
        // 本地时间
        return DateTime(
          int.parse(value.substring(0, 4)),
          int.parse(value.substring(4, 6)),
          int.parse(value.substring(6, 8)),
          int.parse(value.substring(9, 11)),
          int.parse(value.substring(11, 13)),
          int.parse(value.substring(13, 15)),
        );
      }
    } catch (e) {
      // 解析失败
    }
    return null;
  }

  /// 格式化为 iCalendar 日期时间格式
  static String _formatDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  @override
  String toString() => 'RecurrenceRule($toRRuleString())';
}

/// 常用重复规则预设
class RecurrencePresets {
  RecurrencePresets._();

  /// 每天
  static RecurrenceRule daily({int interval = 1}) {
    return RecurrenceRule(
      frequency: Frequency.daily,
      interval: interval,
    );
  }

  /// 每周工作日（周一至周五）
  static RecurrenceRule weekdays() {
    return const RecurrenceRule(
      frequency: Frequency.weekly,
      byDay: [WeekDay.mo, WeekDay.tu, WeekDay.we, WeekDay.th, WeekDay.fr],
    );
  }

  /// 每周指定几天
  static RecurrenceRule weekly({
    int interval = 1,
    List<WeekDay>? days,
  }) {
    return RecurrenceRule(
      frequency: Frequency.weekly,
      interval: interval,
      byDay: days,
    );
  }

  /// 每月指定日期
  static RecurrenceRule monthlyByDay({
    int interval = 1,
    required int day,
  }) {
    return RecurrenceRule(
      frequency: Frequency.monthly,
      interval: interval,
      byMonthDay: [day],
    );
  }

  /// 每月第 N 个星期几
  static RecurrenceRule monthlyByWeekDay({
    int interval = 1,
    required int position,
    required WeekDay weekDay,
  }) {
    return RecurrenceRule(
      frequency: Frequency.monthly,
      interval: interval,
      byDayRules: [ByDayRule(position: position, weekDay: weekDay)],
    );
  }

  /// 每年
  static RecurrenceRule yearly({int interval = 1}) {
    return RecurrenceRule(
      frequency: Frequency.yearly,
      interval: interval,
    );
  }
}
