/// 应用常量
class AppConstants {
  AppConstants._();

  // ========== 应用信息 ==========
  static const String appName = 'Chrono';
  static const String appVersion = '1.0.0';

  // ========== 缓存配置 ==========
  /// 重复事件缓存天数
  static const int eventCacheDays = 90;

  /// 内存缓存最大条目数
  static const int memoryCacheMaxEntries = 100;

  /// 天气缓存有效期（小时）
  static const int weatherCacheHours = 1;

  // ========== 提醒选项（分钟） ==========
  static const List<int> reminderOptions = [
    0,      // 事件发生时
    5,      // 提前 5 分钟
    15,     // 提前 15 分钟
    30,     // 提前 30 分钟
    60,     // 提前 1 小时
    120,    // 提前 2 小时
    1440,   // 提前 1 天
    2880,   // 提前 2 天
    10080,  // 提前 1 周
  ];

  /// 获取提醒选项显示文本
  static String getReminderText(int minutes) {
    if (minutes == 0) return '事件发生时';
    if (minutes < 60) return '提前 $minutes 分钟';
    if (minutes < 1440) return '提前 ${minutes ~/ 60} 小时';
    if (minutes < 10080) return '提前 ${minutes ~/ 1440} 天';
    return '提前 ${minutes ~/ 10080} 周';
  }

  // ========== 时间格式 ==========
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'M月d日 EEEE';
  static const String displayDateTimeFormat = 'M月d日 HH:mm';

  // ========== 周起始日选项 ==========
  static const Map<int, String> weekStartOptions = {
    DateTime.monday: '周一',
    DateTime.saturday: '周六',
    DateTime.sunday: '周日',
  };

  // ========== 视图模式 ==========
  static const Map<String, String> viewModeOptions = {
    'month': '月视图',
    'week': '周视图',
    'day': '日视图',
  };

  // ========== 同步间隔选项 ==========
  static const Map<String, String> syncIntervalOptions = {
    'manual': '手动',
    'hourly': '每小时',
    'daily': '每天',
    'weekly': '每周',
  };

  // ========== 搜索历史 ==========
  static const int maxSearchHistory = 10;

  // ========== 拖拽配置 ==========
  /// 时间吸附粒度（分钟）
  static const int dragSnapMinutes = 15;

  /// 每小时高度（像素）
  static const double hourHeight = 60.0;

  // ========== 动画时长 ==========
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ========== UI 尺寸 ==========
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // ========== 毛玻璃效果 ==========
  static const double glassBlurSigma = 10.0;
  static const double glassBorderWidth = 1.5;
}
