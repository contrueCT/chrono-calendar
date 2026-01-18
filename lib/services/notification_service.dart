import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 通知回调函数类型
typedef NotificationCallback = void Function(String? payload);

/// 通知服务 - 管理本地通知的调度和显示
class NotificationService {
  // 单例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Flutter 本地通知插件实例
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 通知点击回调
  NotificationCallback? _onNotificationTap;

  /// Android 通知渠道 ID
  static const String _channelId = 'chrono_reminders';
  static const String _channelName = '日程提醒';
  static const String _channelDescription = 'Chrono 日历应用的日程提醒通知';

  /// 初始化通知服务
  Future<void> initialize({NotificationCallback? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;

    // 初始化时区数据
    tz_data.initializeTimeZones();

    // 设置本地时区
    try {
      final String timeZoneName = await _getLocalTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // 如果获取时区失败，使用 UTC
      debugPrint('Failed to get local timezone: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // 创建 Android 通知渠道
    await _createNotificationChannel();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// 获取本地时区名称
  ///
  /// 根据系统时区偏移量推断时区名称。
  /// 由于多个时区可能共享相同的偏移量，这里选择该偏移量中最常用的时区。
  ///
  /// 注意：如需更精确的时区支持，可考虑使用 flutter_native_timezone 包。
  Future<String> _getLocalTimeZone() async {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetMinutes = offset.inMinutes;

    // 常见时区映射（偏移量分钟数 -> 时区名称）
    // 选择每个偏移量中人口最多或最常用的时区
    const timezoneMap = <int, String>{
      -720: 'Etc/GMT+12',        // UTC-12:00
      -660: 'Pacific/Midway',    // UTC-11:00
      -600: 'Pacific/Honolulu',  // UTC-10:00 (夏威夷)
      -570: 'Pacific/Marquesas', // UTC-09:30
      -540: 'America/Anchorage', // UTC-09:00 (阿拉斯加)
      -480: 'America/Los_Angeles', // UTC-08:00 (美国太平洋)
      -420: 'America/Denver',    // UTC-07:00 (美国山地)
      -360: 'America/Chicago',   // UTC-06:00 (美国中部)
      -300: 'America/New_York',  // UTC-05:00 (美国东部)
      -240: 'America/Halifax',   // UTC-04:00 (大西洋)
      -210: 'America/St_Johns',  // UTC-03:30 (纽芬兰)
      -180: 'America/Sao_Paulo', // UTC-03:00 (巴西)
      -120: 'Atlantic/South_Georgia', // UTC-02:00
      -60: 'Atlantic/Azores',    // UTC-01:00
      0: 'Europe/London',        // UTC+00:00 (英国)
      60: 'Europe/Paris',        // UTC+01:00 (中欧)
      120: 'Europe/Helsinki',    // UTC+02:00 (东欧)
      180: 'Europe/Moscow',      // UTC+03:00 (莫斯科)
      210: 'Asia/Tehran',        // UTC+03:30 (伊朗)
      240: 'Asia/Dubai',         // UTC+04:00 (海湾)
      270: 'Asia/Kabul',         // UTC+04:30 (阿富汗)
      300: 'Asia/Karachi',       // UTC+05:00 (巴基斯坦)
      330: 'Asia/Kolkata',       // UTC+05:30 (印度)
      345: 'Asia/Kathmandu',     // UTC+05:45 (尼泊尔)
      360: 'Asia/Dhaka',         // UTC+06:00 (孟加拉)
      390: 'Asia/Yangon',        // UTC+06:30 (缅甸)
      420: 'Asia/Bangkok',       // UTC+07:00 (东南亚)
      480: 'Asia/Shanghai',      // UTC+08:00 (中国)
      525: 'Australia/Eucla',    // UTC+08:45
      540: 'Asia/Tokyo',         // UTC+09:00 (日本/韩国)
      570: 'Australia/Darwin',   // UTC+09:30 (澳大利亚中部)
      600: 'Australia/Sydney',   // UTC+10:00 (澳大利亚东部)
      630: 'Australia/Lord_Howe', // UTC+10:30
      660: 'Pacific/Guadalcanal', // UTC+11:00
      720: 'Pacific/Auckland',   // UTC+12:00 (新西兰)
      765: 'Pacific/Chatham',    // UTC+12:45
      780: 'Pacific/Apia',       // UTC+13:00
      840: 'Pacific/Kiritimati', // UTC+14:00
    };

    // 查找匹配的时区
    if (timezoneMap.containsKey(offsetMinutes)) {
      return timezoneMap[offsetMinutes]!;
    }

    // 如果没有精确匹配，尝试找最接近的时区
    int closestOffset = 0;
    int minDiff = 999999;
    for (final key in timezoneMap.keys) {
      final diff = (key - offsetMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestOffset = key;
      }
    }

    if (minDiff <= 30) {
      debugPrint('Using closest timezone for offset $offsetMinutes minutes: ${timezoneMap[closestOffset]}');
      return timezoneMap[closestOffset]!;
    }

    // 实在找不到，返回 UTC
    debugPrint('Could not determine timezone for offset $offsetMinutes minutes, using UTC');
    return 'UTC';
  }

  /// 创建 Android 通知渠道
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 通知响应回调（点击通知时）
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _onNotificationTap?.call(response.payload);
  }

  /// 后台通知响应回调
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
  }

  /// 请求通知权限
  /// 返回是否获得权限
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Android 13+ 需要请求通知权限
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    }
    return false;
  }

  /// 检查是否有通知权限
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
      return false;
    } else if (Platform.isIOS) {
      // 检查 iOS 通知权限状态
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final settings = await iosPlugin.checkPermissions();
        // 检查是否至少有一种通知方式被允许
        return settings?.isEnabled ?? false;
      }
      return false;
    }
    return false;
  }

  /// 请求精确闹钟权限（Android 12+）
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// 检查是否有精确闹钟权限
  Future<bool> hasExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final canSchedule = await androidPlugin.canScheduleExactNotifications();
        return canSchedule ?? false;
      }
    }
    return true;
  }

  /// 调度通知
  ///
  /// [id] - 通知 ID，用于后续取消
  /// [title] - 通知标题
  /// [body] - 通知内容
  /// [scheduledTime] - 预定显示时间
  /// [payload] - 附加数据（点击通知时传递）
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    // 如果时间已过，不调度
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('Scheduled time is in the past, skipping notification $id');
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      when: scheduledTime.millisecondsSinceEpoch,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('Scheduled notification $id for $scheduledTime');
  }

  /// 立即显示通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Cancelled notification $id');
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// 获取待处理的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 获取已显示的活动通知列表（Android）
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.getActiveNotifications();
    }
    return [];
  }
}
