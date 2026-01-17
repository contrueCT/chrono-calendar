import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../../../core/router/app_router.dart';
import '../calendar/month_view_screen.dart';
import '../calendar/week_view_screen.dart';
import '../calendar/day_view_screen.dart';
import '../../widgets/common/date_jump_dialog.dart';

/// 首页 - 日历主页面
///
/// 使用根级 MultiProvider 中的 CalendarViewModel，
/// 不再创建局部实例，确保跨页面状态共享。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接使用根级的 CalendarViewModel
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: _buildAppBar(context, viewModel, colorScheme),
          body: _buildBody(viewModel),
          floatingActionButton: _buildFAB(context, colorScheme),
          bottomNavigationBar: _buildBottomNavBar(context, viewModel, colorScheme),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CalendarViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          // 应用图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Chrono',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // 今天按钮
        TextButton.icon(
          onPressed: viewModel.goToToday,
          icon: Icon(
            Icons.today,
            size: 18,
            color: colorScheme.primary,
          ),
          label: Text(
            '今天',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // 日期跳转按钮
        IconButton(
          onPressed: () async {
            final date = await DateJumpDialog.show(
              context,
              initialDate: viewModel.selectedDate,
            );
            if (date != null) {
              viewModel.jumpToDate(date);
            }
          },
          icon: Icon(
            Icons.date_range,
            color: colorScheme.onSurfaceVariant,
          ),
          tooltip: '跳转到日期',
        ),
        // 搜索按钮
        IconButton(
          onPressed: () {
            context.push(RoutePaths.search);
          },
          icon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          tooltip: '搜索',
        ),
        // 更多菜单
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('设置'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'calendars',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_month_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('日历管理'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('导入日历'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_upload_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('导出日历'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(CalendarViewModel viewModel) {
    switch (viewModel.viewMode) {
      case CalendarViewMode.month:
        return const MonthViewScreen();
      case CalendarViewMode.week:
        return const WeekViewScreen();
      case CalendarViewMode.day:
        return const DayViewScreen();
    }
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) {
    final viewModel = context.read<CalendarViewModel>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 使用选中的日期作为初始日期，跳转到统一的新建页面
            final date = viewModel.selectedDate;
            context.goScheduleCreate(date: date);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  '新建日程',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    CalendarViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.calendar_view_month,
                label: '月',
                isSelected: viewModel.viewMode == CalendarViewMode.month,
                onTap: () => viewModel.setViewMode(CalendarViewMode.month),
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_view_week,
                label: '周',
                isSelected: viewModel.viewMode == CalendarViewMode.week,
                onTap: () => viewModel.setViewMode(CalendarViewMode.week),
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_view_day,
                label: '日',
                isSelected: viewModel.viewMode == CalendarViewMode.day,
                onTap: () => viewModel.setViewMode(CalendarViewMode.day),
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.timer_outlined,
                label: '倒计时',
                isSelected: false,
                onTap: () {
                  context.push(RoutePaths.countdown);
                },
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.checklist,
                label: '待办',
                isSelected: false,
                onTap: () {
                  context.push(RoutePaths.todo);
                },
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        context.push(RoutePaths.settings);
        break;
      case 'calendars':
        context.push(RoutePaths.calendarManage);
        break;
      case 'import':
        context.push(RoutePaths.importExport);
        break;
      case 'export':
        context.push(RoutePaths.importExport);
        break;
    }
  }
}
