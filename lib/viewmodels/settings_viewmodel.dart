import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置视图模型
class SettingsViewModel extends ChangeNotifier {
  // ========== 存储键 ==========
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyShowLunar = 'show_lunar';
  static const String _keyDefaultView = 'default_view';
  static const String _keyWeekStartDay = 'week_start_day';
  static const String _keyDefaultReminderMinutes = 'default_reminder_minutes';
  static const String _keyEnableNotifications = 'enable_notifications';

  // ========== 状态字段 ==========
  ThemeMode _themeMode = ThemeMode.system;
  bool _showLunar = true;
  String _defaultView = 'month';
  int _weekStartDay = DateTime.monday;
  int _defaultReminderMinutes = 15;
  bool _enableNotifications = true;
  bool _isLoading = true;

  // ========== Getters ==========
  ThemeMode get themeMode => _themeMode;
  bool get showLunar => _showLunar;
  String get defaultView => _defaultView;
  int get weekStartDay => _weekStartDay;
  int get defaultReminderMinutes => _defaultReminderMinutes;
  bool get enableNotifications => _enableNotifications;
  bool get isLoading => _isLoading;

  /// 构造函数 - 加载保存的设置
  SettingsViewModel() {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 主题模式
      final themeModeIndex = prefs.getInt(_keyThemeMode) ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];

      // 农历显示
      _showLunar = prefs.getBool(_keyShowLunar) ?? true;

      // 默认视图
      _defaultView = prefs.getString(_keyDefaultView) ?? 'month';

      // 周起始日
      _weekStartDay = prefs.getInt(_keyWeekStartDay) ?? DateTime.monday;

      // 默认提醒时间
      _defaultReminderMinutes = prefs.getInt(_keyDefaultReminderMinutes) ?? 15;

      // 通知开关
      _enableNotifications = prefs.getBool(_keyEnableNotifications) ?? true;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  /// 设置农历显示
  Future<void> setShowLunar(bool show) async {
    if (_showLunar == show) return;
    _showLunar = show;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowLunar, show);
  }

  /// 设置默认视图
  Future<void> setDefaultView(String view) async {
    if (_defaultView == view) return;
    _defaultView = view;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultView, view);
  }

  /// 设置周起始日
  Future<void> setWeekStartDay(int day) async {
    if (_weekStartDay == day) return;
    _weekStartDay = day;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWeekStartDay, day);
  }

  /// 设置默认提醒时间
  Future<void> setDefaultReminderMinutes(int minutes) async {
    if (_defaultReminderMinutes == minutes) return;
    _defaultReminderMinutes = minutes;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultReminderMinutes, minutes);
  }

  /// 设置通知开关
  Future<void> setEnableNotifications(bool enable) async {
    if (_enableNotifications == enable) return;
    _enableNotifications = enable;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableNotifications, enable);
  }

  /// 重置所有设置
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyThemeMode);
    await prefs.remove(_keyShowLunar);
    await prefs.remove(_keyDefaultView);
    await prefs.remove(_keyWeekStartDay);
    await prefs.remove(_keyDefaultReminderMinutes);
    await prefs.remove(_keyEnableNotifications);

    _themeMode = ThemeMode.system;
    _showLunar = true;
    _defaultView = 'month';
    _weekStartDay = DateTime.monday;
    _defaultReminderMinutes = 15;
    _enableNotifications = true;

    notifyListeners();
  }

  /// 获取主题模式显示文本
  String get themeModeText {
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '亮色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  /// 获取默认视图显示文本
  String get defaultViewText {
    switch (_defaultView) {
      case 'month':
        return '月视图';
      case 'week':
        return '周视图';
      case 'day':
        return '日视图';
      default:
        return '月视图';
    }
  }

  /// 获取周起始日显示文本
  String get weekStartDayText {
    switch (_weekStartDay) {
      case DateTime.monday:
        return '周一';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
      default:
        return '周一';
    }
  }
}
