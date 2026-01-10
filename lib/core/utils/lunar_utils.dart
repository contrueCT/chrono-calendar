import 'package:lunar/lunar.dart';

/// 农历工具类 - 封装农历转换和节日查询功能
class LunarUtils {
  LunarUtils._();

  /// 获取农历日期信息
  static LunarDateInfo getLunarInfo(DateTime date) {
    final lunar = Lunar.fromDate(date);

    return LunarDateInfo(
      year: lunar.getYear(),
      month: lunar.getMonth(),
      day: lunar.getDay(),
      isLeapMonth: lunar.getMonth() < 0,
      monthName: lunar.getMonthInChinese(),
      dayName: lunar.getDayInChinese(),
      yearGanZhi: lunar.getYearInGanZhi(),
      monthGanZhi: lunar.getMonthInGanZhi(),
      dayGanZhi: lunar.getDayInGanZhi(),
      zodiac: lunar.getYearShengXiao(),
      solarTerm: lunar.getJieQi(),
      lunarFestival: _getLunarFestival(lunar),
      solarFestival: _getSolarFestival(date),
    );
  }

  /// 获取日历单元格显示文本（优先级：节气 > 农历节日 > 公历节日 > 农历日期）
  static String getDisplayText(DateTime date) {
    final info = getLunarInfo(date);

    // 优先显示节气
    if (info.solarTerm != null && info.solarTerm!.isNotEmpty) {
      return info.solarTerm!;
    }

    // 其次显示农历节日
    if (info.lunarFestival != null && info.lunarFestival!.isNotEmpty) {
      return info.lunarFestival!;
    }

    // 然后显示公历节日
    if (info.solarFestival != null && info.solarFestival!.isNotEmpty) {
      return info.solarFestival!;
    }

    // 初一显示月份，其他显示日
    if (info.day == 1) {
      return '${info.monthName}月';
    }

    return info.dayName;
  }

  /// 获取农历节日
  static String? _getLunarFestival(Lunar lunar) {
    final month = lunar.getMonth().abs();
    final day = lunar.getDay();

    // 主要农历节日
    const festivals = {
      '1-1': '春节',
      '1-15': '元宵',
      '2-2': '龙抬头',
      '5-5': '端午',
      '7-7': '七夕',
      '7-15': '中元',
      '8-15': '中秋',
      '9-9': '重阳',
      '12-8': '腊八',
      '12-23': '小年',
      '12-30': '除夕',
    };

    final key = '$month-$day';
    if (festivals.containsKey(key)) {
      return festivals[key];
    }

    // 除夕特殊处理：腊月最后一天
    if (month == 12 && day >= 29) {
      final nextDay = lunar.next(1);
      if (nextDay.getMonth() == 1 && nextDay.getDay() == 1) {
        return '除夕';
      }
    }

    return null;
  }

  /// 获取公历节日
  static String? _getSolarFestival(DateTime date) {
    final month = date.month;
    final day = date.day;

    // 主要公历节日
    const festivals = {
      '1-1': '元旦',
      '2-14': '情人节',
      '3-8': '妇女节',
      '3-12': '植树节',
      '4-1': '愚人节',
      '5-1': '劳动节',
      '5-4': '青年节',
      '6-1': '儿童节',
      '7-1': '建党节',
      '8-1': '建军节',
      '9-10': '教师节',
      '10-1': '国庆节',
      '12-25': '圣诞节',
    };

    final key = '$month-$day';
    return festivals[key];

    // 母亲节：5月第二个周日
    // 父亲节：6月第三个周日
    // 感恩节：11月第四个周四
    // 这些需要动态计算，暂不实现
  }

  /// 获取天干地支年份
  static String getGanZhiYear(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getYearInGanZhi();
  }

  /// 获取生肖
  static String getZodiac(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getYearShengXiao();
  }

  /// 获取节气
  static String? getSolarTerm(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final jieQi = lunar.getJieQi();
    return jieQi.isNotEmpty ? jieQi : null;
  }

  /// 检查是否是节假日（农历或公历）
  static bool isFestival(DateTime date) {
    final info = getLunarInfo(date);
    return (info.lunarFestival != null && info.lunarFestival!.isNotEmpty) ||
        (info.solarFestival != null && info.solarFestival!.isNotEmpty);
  }

  /// 检查是否是节气
  static bool isSolarTerm(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getJieQi().isNotEmpty;
  }

  /// 农历转公历
  static DateTime? lunarToSolar(int year, int month, int day, {bool isLeapMonth = false}) {
    try {
      final lunar = Lunar.fromYmd(year, isLeapMonth ? -month : month, day);
      final solar = lunar.getSolar();
      return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      return null;
    }
  }

  /// 获取当年某农历日期对应的公历日期（用于倒计时/纪念日）
  static DateTime? getLunarDateInYear(int solarYear, int lunarMonth, int lunarDay, {bool isLeapMonth = false}) {
    // 尝试在给定年份找到对应的农历日期
    try {
      // 首先尝试当年
      var lunar = Lunar.fromYmd(solarYear, isLeapMonth ? -lunarMonth : lunarMonth, lunarDay);
      var solar = lunar.getSolar();

      // 如果转换后的公历年份不是目标年份，尝试调整
      if (solar.getYear() != solarYear) {
        // 尝试前一年
        lunar = Lunar.fromYmd(solarYear - 1, isLeapMonth ? -lunarMonth : lunarMonth, lunarDay);
        solar = lunar.getSolar();
        if (solar.getYear() == solarYear) {
          return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
        }

        // 尝试后一年
        lunar = Lunar.fromYmd(solarYear + 1, isLeapMonth ? -lunarMonth : lunarMonth, lunarDay);
        solar = lunar.getSolar();
        if (solar.getYear() == solarYear) {
          return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
        }
      }

      return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      return null;
    }
  }

  /// 获取完整的农历日期字符串
  static String getFullLunarString(DateTime date) {
    final info = getLunarInfo(date);
    final monthPrefix = info.isLeapMonth ? '闰' : '';
    return '${info.yearGanZhi}年 $monthPrefix${info.monthName}月${info.dayName}';
  }

  /// 获取简短的农历日期字符串
  static String getShortLunarString(DateTime date) {
    final info = getLunarInfo(date);
    final monthPrefix = info.isLeapMonth ? '闰' : '';
    return '$monthPrefix${info.monthName}月${info.dayName}';
  }
}

/// 农历日期信息
class LunarDateInfo {
  /// 农历年
  final int year;

  /// 农历月（负数表示闰月）
  final int month;

  /// 农历日
  final int day;

  /// 是否闰月
  final bool isLeapMonth;

  /// 月份中文名（如"正"、"二"）
  final String monthName;

  /// 日期中文名（如"初一"、"十五"）
  final String dayName;

  /// 年干支（如"甲辰"）
  final String yearGanZhi;

  /// 月干支
  final String monthGanZhi;

  /// 日干支
  final String dayGanZhi;

  /// 生肖
  final String zodiac;

  /// 节气
  final String? solarTerm;

  /// 农历节日
  final String? lunarFestival;

  /// 公历节日
  final String? solarFestival;

  const LunarDateInfo({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthName,
    required this.dayName,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.zodiac,
    this.solarTerm,
    this.lunarFestival,
    this.solarFestival,
  });

  /// 获取农历月份绝对值
  int get absoluteMonth => month.abs();

  /// 是否有特殊日期（节气或节日）
  bool get hasSpecialDay =>
      (solarTerm != null && solarTerm!.isNotEmpty) ||
      (lunarFestival != null && lunarFestival!.isNotEmpty) ||
      (solarFestival != null && solarFestival!.isNotEmpty);

  @override
  String toString() {
    return 'LunarDateInfo(year: $year, month: $month, day: $day, '
        'monthName: $monthName, dayName: $dayName)';
  }
}
