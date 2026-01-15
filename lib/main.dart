import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_manager.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/calendar_viewmodel.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // 尝试初始化应用
  String? initError;
  try {
    await _initializeApp();
  } catch (e, stackTrace) {
    debugPrint('初始化失败: $e');
    debugPrint('Stack trace: $stackTrace');
    initError = e.toString();
  }

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

  // 根据初始化结果决定启动哪个界面
  runApp(
    initError != null
        ? _InitializationErrorApp(error: initError, onRetry: main)
        : MultiProvider(
            providers: [
              // 设置 ViewModel
              ChangeNotifierProvider(create: (_) => SettingsViewModel()),
              // 日历 ViewModel - 全局共享，支持跨页面状态同步
              ChangeNotifierProvider(create: (_) => CalendarViewModel()),
            ],
            child: const ChronoApp(),
          ),
  );
}

/// 初始化应用核心服务
Future<void> _initializeApp() async {
  // 初始化日期格式化本地化数据
  await initializeDateFormatting('zh_CN', null);

  // 初始化数据库（如果失败会抛出异常）
  await DatabaseService().database;

  // 初始化通知服务
  await NotificationService().initialize(
    onNotificationTap: _onNotificationTap,
  );

  // 初始化提醒管理器（会刷新所有提醒）
  await ReminderManager().initialize();
}

/// 通知点击回调
void _onNotificationTap(String? payload) {
  // 解析 payload 并导航到事件详情
  // 由于此时可能没有 Navigator context，需要通过全局 key 处理
  // 实际导航逻辑将在 app.dart 中通过 navigatorKey 实现
  debugPrint('Notification tapped with payload: $payload');
}

/// 初始化错误界面
///
/// 当应用初始化失败时显示此界面，提供错误信息和重试选项。
class _InitializationErrorApp extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _InitializationErrorApp({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chrono Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 错误图标
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),

                // 标题
                const Text(
                  '初始化失败',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 错误描述
                const Text(
                  '应用启动时遇到问题，请尝试重新启动。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // 错误详情（可展开）
                ExpansionTile(
                  title: const Text('查看错误详情'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        error,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 重试按钮
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
