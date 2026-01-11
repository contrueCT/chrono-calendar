import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_manager.dart';
import 'viewmodels/settings_viewmodel.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化本地化数据
  await initializeDateFormatting('zh_CN', null);

  // 初始化数据库
  await DatabaseService().database;

  // 初始化通知服务
  await NotificationService().initialize(
    onNotificationTap: _onNotificationTap,
  );

  // 初始化提醒管理器（会刷新所有提醒）
  await ReminderManager().initialize();

  // 设置系统 UI 样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 设置屏幕方向（支持竖屏和横屏）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        // 设置 ViewModel
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        // 后续添加更多 ViewModel...
      ],
      child: const ChronoApp(),
    ),
  );
}

/// 通知点击回调
void _onNotificationTap(String? payload) {
  // 解析 payload 并导航到事件详情
  // 由于此时可能没有 Navigator context，需要通过全局 key 处理
  // 实际导航逻辑将在 app.dart 中通过 navigatorKey 实现
  debugPrint('Notification tapped with payload: $payload');
}
