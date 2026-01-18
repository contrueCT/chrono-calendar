import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/screens/home/home_screen.dart';
import '../../views/screens/event/event_edit_screen.dart';
import '../../views/screens/event/event_detail_screen.dart';
import '../../views/screens/event/event_share_screen.dart';
import '../../views/screens/calendar_manage/import_export_screen.dart';
import '../../views/screens/calendar_manage/subscription_screen.dart';
import '../../views/screens/calendar_manage/calendar_manage_screen.dart';
import '../../views/screens/search/search_screen.dart';
import '../../views/screens/settings/settings_screen.dart';
import '../../views/screens/settings/llm_settings_screen.dart';
import '../../views/screens/countdown/countdown_list_screen.dart';
import '../../views/screens/countdown/countdown_edit_screen.dart';
import '../../views/screens/countdown/countdown_share_screen.dart';
import '../../data/models/countdown_model.dart';
import '../../views/screens/schedule/schedule_create_screen.dart';
import '../../views/screens/todo/todo_list_screen.dart';
import '../../views/screens/todo/todo_edit_screen.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/models/event_model.dart';
import '../../data/models/schedule_type.dart';

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
  static const String eventShare = '/event/share';
  static const String scheduleCreate = '/schedule/create';
  static const String search = '/search';
  static const String countdown = '/countdown';
  static const String countdownEdit = '/countdown/edit';
  static const String countdownShare = '/countdown/share';
  static const String todo = '/todo';
  static const String todoEdit = '/todo/edit';
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
  static const String eventShare = 'eventShare';
  static const String scheduleCreate = 'scheduleCreate';
  static const String search = 'search';
  static const String countdown = 'countdown';
  static const String countdownEdit = 'countdownEdit';
  static const String countdownShare = 'countdownShare';
  static const String todo = 'todo';
  static const String todoEdit = 'todoEdit';
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

  /// 获取根导航器 Key（用于通知点击导航等场景）
  static GlobalKey<NavigatorState> get navigatorKey => _rootNavigatorKey;

  /// 全局路由观察器（用于监听页面切换，实现返回时刷新等功能）
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  /// 路由配置
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    routes: _routes,
    errorBuilder: _errorBuilder,
    observers: [routeObserver],
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
              // 处理错误状态
              if (snapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('错误')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('加载事件失败: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('返回'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // 处理数据为空的情况
              if (snapshot.data == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('未找到')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('事件不存在或已删除'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('返回'),
                        ),
                      ],
                    ),
                  ),
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

    // 统一日程创建
    GoRoute(
      path: RoutePaths.scheduleCreate,
      name: RouteNames.scheduleCreate,
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        final typeStr = state.uri.queryParameters['type'];
        DateTime? initialDate;
        ScheduleType? initialType;
        if (dateStr != null) {
          initialDate = DateTime.tryParse(dateStr);
        }
        if (typeStr != null) {
          initialType = ScheduleType.fromString(typeStr);
        }
        return ScheduleCreateScreen(
          initialDate: initialDate,
          initialType: initialType,
        );
      },
    ),

    // 事件分享
    GoRoute(
      path: RoutePaths.eventShare,
      name: RouteNames.eventShare,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null || extra['event'] == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('错误')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('缺少事件数据'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          );
        }
        final event = extra['event'] as EventModel;
        final instanceDate = extra['instanceDate'] as DateTime?;
        return EventShareScreen(
          event: event,
          instanceDate: instanceDate,
        );
      },
    ),

    // 事件详情 (动态路由放在具体路由之后)
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

    // 搜索
    GoRoute(
      path: RoutePaths.search,
      name: RouteNames.search,
      builder: (context, state) => const SearchScreen(),
    ),

    // 倒计时列表
    GoRoute(
      path: RoutePaths.countdown,
      name: RouteNames.countdown,
      builder: (context, state) => const CountdownListScreen(),
    ),

    // 倒计时分享
    GoRoute(
      path: RoutePaths.countdownShare,
      name: RouteNames.countdownShare,
      builder: (context, state) {
        final countdown = state.extra as CountdownModel?;
        if (countdown == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('错误')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('缺少倒计时数据'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          );
        }
        return CountdownShareScreen(countdown: countdown);
      },
    ),

    // 倒计时创建
    GoRoute(
      path: '/countdown/create',
      builder: (context, state) => const CountdownEditScreen(),
    ),

    // 倒计时编辑/详情
    GoRoute(
      path: '/countdown/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return CountdownEditScreen(countdownId: id);
      },
    ),

    // 待办列表
    GoRoute(
      path: RoutePaths.todo,
      name: RouteNames.todo,
      builder: (context, state) => const TodoListScreen(),
    ),

    // 待办创建
    GoRoute(
      path: '/todo/create',
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        DateTime? initialDate;
        if (dateStr != null) {
          initialDate = DateTime.tryParse(dateStr);
        }
        return TodoEditScreen(initialDate: initialDate);
      },
    ),

    // 待办编辑/详情
    GoRoute(
      path: '/todo/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return TodoEditScreen(todoId: id);
      },
    ),

    // 日历管理
    GoRoute(
      path: RoutePaths.calendarManage,
      name: RouteNames.calendarManage,
      builder: (context, state) => const CalendarManageScreen(),
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
      builder: (context, state) => const SettingsScreen(),
    ),

    // LLM 设置
    GoRoute(
      path: RoutePaths.llmSettings,
      name: RouteNames.llmSettings,
      builder: (context, state) => const LLMSettingsScreen(),
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

  /// 跳转到统一日程创建
  void goScheduleCreate({DateTime? date, ScheduleType? type}) {
    final params = <String>[];
    if (date != null) {
      params.add('date=${date.toIso8601String()}');
    }
    if (type != null) {
      params.add('type=${type.name}');
    }
    if (params.isNotEmpty) {
      push('${RoutePaths.scheduleCreate}?${params.join('&')}');
    } else {
      push(RoutePaths.scheduleCreate);
    }
  }

  /// 跳转到统一日程创建（异步，可等待返回值）
  Future<T?> pushScheduleCreate<T>({DateTime? date, ScheduleType? type}) {
    final params = <String>[];
    if (date != null) {
      params.add('date=${date.toIso8601String()}');
    }
    if (type != null) {
      params.add('type=${type.name}');
    }
    final path = params.isNotEmpty
        ? '${RoutePaths.scheduleCreate}?${params.join('&')}'
        : RoutePaths.scheduleCreate;
    return push<T>(path);
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

  /// 跳转到待办列表
  void goTodo() => go(RoutePaths.todo);

  /// 跳转到待办编辑
  void goTodoEdit({String? id, DateTime? date}) {
    if (id != null) {
      go('/todo/$id');
    } else if (date != null) {
      go('/todo/create?date=${date.toIso8601String()}');
    } else {
      go('/todo/create');
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
