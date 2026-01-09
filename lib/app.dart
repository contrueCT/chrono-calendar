import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/settings_viewmodel.dart';

/// Chrono 日历应用
class ChronoApp extends StatelessWidget {
  const ChronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, child) {
        return MaterialApp.router(
          // 应用名称
          title: AppConstants.appName,

          // 路由配置
          routerConfig: AppRouter.router,

          // 主题配置
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,

          // 调试配置
          debugShowCheckedModeBanner: false,

          // 本地化配置
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}
