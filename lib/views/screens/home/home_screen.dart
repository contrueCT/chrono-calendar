import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/calendar_viewmodel.dart';
import '../calendar/month_view_screen.dart';
import '../calendar/week_view_screen.dart';
import '../calendar/day_view_screen.dart';

/// 首页 - 日历主页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(),
      child: const _HomeScreenContent(),
    );
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
        // 搜索按钮
        IconButton(
          onPressed: () {
            // TODO: 导航到搜索页面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('搜索功能将在后续版本实现'),
                duration: Duration(seconds: 1),
              ),
            );
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
    return FloatingActionButton(
      onPressed: () {
        // TODO: 导航到创建事件页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创建事件功能将在后续版本实现'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      child: const Icon(Icons.add),
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
                  // TODO: 导航到倒计时页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('倒计时功能将在后续版本实现'),
                      duration: Duration(seconds: 1),
                    ),
                  );
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
        // TODO: 导航到设置页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置页面将在后续版本实现'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 'calendars':
        // TODO: 导航到日历管理页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日历管理页面将在后续版本实现'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 'import':
        // TODO: 导入日历
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导入功能将在后续版本实现'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 'export':
        // TODO: 导出日历
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导出功能将在后续版本实现'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
    }
  }
}
