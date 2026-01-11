import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/screens/home/home_screen.dart';
import '../../views/screens/event/event_edit_screen.dart';
import '../../views/screens/event/event_detail_screen.dart';
import '../../views/screens/calendar_manage/import_export_screen.dart';
import '../../views/screens/calendar_manage/subscription_screen.dart';
import '../../data/repositories/event_repository.dart';

/// 路由路径常量
class RoutePaths {
  RoutePaths._();

  static const String home = '/';
  static const String monthView = '/month';
  static const String weekView = '/week';
  static const String dayView = '/day';
  static const String eventDetail = '/event/:uid';
  static const String eventEdit = '/event/edit';
  static const String eventCreate = '/event/create';
  static const String search = '/search';
  static const String countdown = '/countdown';
  static const String countdownEdit = '/countdown/edit';
  static const String calendarManage = '/calendar-manage';
  static const String subscription = '/subscription';
  static const String importExport = '/import-export';
  static const String settings = '/settings';
  static const String llmSettings = '/settings/llm';
  static const String weatherSettings = '/settings/weather';
}

/// 路由名称常量
class RouteNames {
  RouteNames._();

  static const String home = 'home';
  static const String monthView = 'monthView';
  static const String weekView = 'weekView';
  static const String dayView = 'dayView';
  static const String eventDetail = 'eventDetail';
  static const String eventEdit = 'eventEdit';
  static const String eventCreate = 'eventCreate';
  static const String search = 'search';
  static const String countdown = 'countdown';
  static const String countdownEdit = 'countdownEdit';
  static const String calendarManage = 'calendarManage';
  static const String subscription = 'subscription';
  static const String importExport = 'importExport';
  static const String settings = 'settings';
  static const String llmSettings = 'llmSettings';
  static const String weatherSettings = 'weatherSettings';
}

/// 应用路由配置
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// 路由配置
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    routes: _routes,
    errorBuilder: _errorBuilder,
  );

  /// 路由列表
  static final List<RouteBase> _routes = [
    // 首页（包含月/周/日视图切换）
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),

    // 独立月视图（从其他页面跳转时使用）
    GoRoute(
      path: RoutePaths.monthView,
      name: RouteNames.monthView,
      builder: (context, state) => const HomeScreen(),
    ),

    // 独立周视图（从其他页面跳转时使用）
    GoRoute(
      path: RoutePaths.weekView,
      name: RouteNames.weekView,
      builder: (context, state) => const HomeScreen(),
    ),

    // 独立日视图（从其他页面跳转时使用）
    GoRoute(
      path: RoutePaths.dayView,
      name: RouteNames.dayView,
      builder: (context, state) => const HomeScreen(),
    ),

    // 事件详情
    GoRoute(
      path: RoutePaths.eventDetail,
      name: RouteNames.eventDetail,
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        final instanceDateStr = state.uri.queryParameters['instanceDate'];
        DateTime? instanceDate;
        if (instanceDateStr != null) {
          instanceDate = DateTime.tryParse(instanceDateStr);
        }
        return EventDetailScreen(
          eventUid: uid,
          instanceDate: instanceDate,
        );
      },
    ),

    // 事件编辑
    GoRoute(
      path: RoutePaths.eventEdit,
      name: RouteNames.eventEdit,
      builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        final dateStr = state.uri.queryParameters['date'];
        DateTime? initialDate;
        if (dateStr != null) {
          initialDate = DateTime.tryParse(dateStr);
        }
        // 如果有 uid，加载事件进行编辑
        if (uid != null) {
          return FutureBuilder(
            future: EventRepository().getEventByUid(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return EventEditScreen(
                event: snapshot.data,
                initialDate: initialDate,
              );
            },
          );
        }
        // 创建新事件
        return EventEditScreen(initialDate: initialDate);
      },
    ),

    // 事件创建
    GoRoute(
      path: RoutePaths.eventCreate,
      name: RouteNames.eventCreate,
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        DateTime? initialDate;
        if (dateStr != null) {
          initialDate = DateTime.tryParse(dateStr);
        }
        return EventEditScreen(initialDate: initialDate);
      },
    ),

    // 搜索
    GoRoute(
      path: RoutePaths.search,
      name: RouteNames.search,
      builder: (context, state) => const _PlaceholderScreen(title: '搜索'),
    ),

    // 倒计时
    GoRoute(
      path: RoutePaths.countdown,
      name: RouteNames.countdown,
      builder: (context, state) => const _PlaceholderScreen(title: '倒计时'),
    ),

    // 倒计时编辑
    GoRoute(
      path: RoutePaths.countdownEdit,
      name: RouteNames.countdownEdit,
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        return _PlaceholderScreen(title: '编辑倒计时: ${id ?? "新建"}');
      },
    ),

    // 日历管理
    GoRoute(
      path: RoutePaths.calendarManage,
      name: RouteNames.calendarManage,
      builder: (context, state) => const _PlaceholderScreen(title: '日历管理'),
    ),

    // 订阅管理
    GoRoute(
      path: RoutePaths.subscription,
      name: RouteNames.subscription,
      builder: (context, state) => const SubscriptionScreen(),
    ),

    // 导入导出
    GoRoute(
      path: RoutePaths.importExport,
      name: RouteNames.importExport,
      builder: (context, state) => const ImportExportScreen(),
    ),

    // 设置
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (context, state) => const _PlaceholderScreen(title: '设置'),
    ),

    // LLM 设置
    GoRoute(
      path: RoutePaths.llmSettings,
      name: RouteNames.llmSettings,
      builder: (context, state) => const _PlaceholderScreen(title: 'AI 设置'),
    ),

    // 天气设置
    GoRoute(
      path: RoutePaths.weatherSettings,
      name: RouteNames.weatherSettings,
      builder: (context, state) => const _PlaceholderScreen(title: '天气设置'),
    ),
  ];

  /// 错误页面构建器
  static Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '找不到页面: ${state.uri.path}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面（开发阶段使用）
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '开发中...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BuildContext 扩展 - 路由导航便捷方法
extension RouterExtension on BuildContext {
  /// 跳转到首页
  void goHome() => go(RoutePaths.home);

  /// 跳转到月视图
  void goMonthView() => go(RoutePaths.monthView);

  /// 跳转到周视图
  void goWeekView() => go(RoutePaths.weekView);

  /// 跳转到日视图
  void goDayView() => go(RoutePaths.dayView);

  /// 跳转到事件详情
  void goEventDetail(String uid) => go('/event/$uid');

  /// 跳转到事件编辑
  void goEventEdit({String? uid}) {
    if (uid != null) {
      go('${RoutePaths.eventEdit}?uid=$uid');
    } else {
      go(RoutePaths.eventEdit);
    }
  }

  /// 跳转到事件创建
  void goEventCreate({DateTime? date}) {
    if (date != null) {
      go('${RoutePaths.eventCreate}?date=${date.toIso8601String()}');
    } else {
      go(RoutePaths.eventCreate);
    }
  }

  /// 跳转到搜索
  void goSearch() => go(RoutePaths.search);

  /// 跳转到倒计时
  void goCountdown() => go(RoutePaths.countdown);

  /// 跳转到倒计时编辑
  void goCountdownEdit({String? id}) {
    if (id != null) {
      go('${RoutePaths.countdownEdit}?id=$id');
    } else {
      go(RoutePaths.countdownEdit);
    }
  }

  /// 跳转到日历管理
  void goCalendarManage() => go(RoutePaths.calendarManage);

  /// 跳转到订阅管理
  void goSubscription() => go(RoutePaths.subscription);

  /// 跳转到导入导出
  void goImportExport() => go(RoutePaths.importExport);

  /// 跳转到设置
  void goSettings() => go(RoutePaths.settings);

  /// 跳转到 AI 设置
  void goLlmSettings() => go(RoutePaths.llmSettings);

  /// 跳转到天气设置
  void goWeatherSettings() => go(RoutePaths.weatherSettings);
}
