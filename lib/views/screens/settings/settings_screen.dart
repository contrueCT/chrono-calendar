import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../viewmodels/settings_viewmodel.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // ========== 显示设置 ==========
              _buildSectionHeader(context, '显示'),
              _buildThemeModeTile(context, settings),
              _buildSwitchTile(
                context: context,
                icon: Icons.calendar_today,
                title: '显示农历',
                subtitle: '在日历中显示农历日期',
                value: settings.showLunar,
                onChanged: (value) => settings.setShowLunar(value),
              ),
              _buildDefaultViewTile(context, settings),
              _buildWeekStartTile(context, settings),
              const Divider(),

              // ========== AI 设置 ==========
              _buildSectionHeader(context, 'AI 智能'),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI 配置'),
                subtitle: const Text('配置 AI 模型和服务'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.llmSettings),
              ),
              const Divider(),

              // ========== 通知设置 ==========
              _buildSectionHeader(context, '通知'),
              _buildSwitchTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: '启用通知',
                subtitle: '接收事件提醒通知',
                value: settings.enableNotifications,
                onChanged: (value) => settings.setEnableNotifications(value),
              ),
              _buildDefaultReminderTile(context, settings),
              const Divider(),

              // ========== 关于 ==========
              _buildSectionHeader(context, '关于'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于 Chrono'),
                subtitle: const Text('版本 1.0.0'),
                onTap: () => _showAboutDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('重置设置'),
                subtitle: const Text('恢复默认设置'),
                onTap: () => _showResetDialog(context, settings),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  /// 构建主题模式设置
  Widget _buildThemeModeTile(BuildContext context, SettingsViewModel settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('主题模式'),
      subtitle: Text(settings.themeModeText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(context, settings),
    );
  }

  /// 构建默认视图设置
  Widget _buildDefaultViewTile(BuildContext context, SettingsViewModel settings) {
    return ListTile(
      leading: const Icon(Icons.view_agenda),
      title: const Text('默认视图'),
      subtitle: Text(settings.defaultViewText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDefaultViewDialog(context, settings),
    );
  }

  /// 构建周起始日设置
  Widget _buildWeekStartTile(BuildContext context, SettingsViewModel settings) {
    return ListTile(
      leading: const Icon(Icons.calendar_view_week),
      title: const Text('周起始日'),
      subtitle: Text(settings.weekStartDayText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showWeekStartDialog(context, settings),
    );
  }

  /// 构建默认提醒时间设置
  Widget _buildDefaultReminderTile(BuildContext context, SettingsViewModel settings) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: const Text('默认提醒时间'),
      subtitle: Text('提前 ${settings.defaultReminderMinutes} 分钟'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showReminderDialog(context, settings),
    );
  }

  /// 显示主题模式选择对话框
  void _showThemeModeDialog(BuildContext context, SettingsViewModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile(
              title: '跟随系统',
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile(
              title: '亮色模式',
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile(
              title: '深色模式',
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示默认视图选择对话框
  void _showDefaultViewDialog(BuildContext context, SettingsViewModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择默认视图'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile<String>(
              title: '月视图',
              value: 'month',
              groupValue: settings.defaultView,
              onChanged: (value) {
                settings.setDefaultView(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<String>(
              title: '周视图',
              value: 'week',
              groupValue: settings.defaultView,
              onChanged: (value) {
                settings.setDefaultView(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<String>(
              title: '日视图',
              value: 'day',
              groupValue: settings.defaultView,
              onChanged: (value) {
                settings.setDefaultView(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示周起始日选择对话框
  void _showWeekStartDialog(BuildContext context, SettingsViewModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择周起始日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile<int>(
              title: '周一',
              value: DateTime.monday,
              groupValue: settings.weekStartDay,
              onChanged: (value) {
                settings.setWeekStartDay(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<int>(
              title: '周六',
              value: DateTime.saturday,
              groupValue: settings.weekStartDay,
              onChanged: (value) {
                settings.setWeekStartDay(value!);
                Navigator.pop(context);
              },
            ),
            _buildRadioTile<int>(
              title: '周日',
              value: DateTime.sunday,
              groupValue: settings.weekStartDay,
              onChanged: (value) {
                settings.setWeekStartDay(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示默认提醒时间选择对话框
  void _showReminderDialog(BuildContext context, SettingsViewModel settings) {
    final options = [5, 10, 15, 30, 60, 120];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择默认提醒时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) {
            final text = minutes >= 60 ? '${minutes ~/ 60} 小时' : '$minutes 分钟';
            return _buildRadioTile<int>(
              title: '提前 $text',
              value: minutes,
              groupValue: settings.defaultReminderMinutes,
              onChanged: (value) {
                settings.setDefaultReminderMinutes(value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建单选按钮项
  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Chrono 日历',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.calendar_month,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      applicationLegalese: '一款现代化的 Flutter 日历应用，集成 AI 智能功能。',
      children: [
        const SizedBox(height: 16),
        const Text('功能特点：'),
        const SizedBox(height: 8),
        const Text('• 多视图日历（月/周/日）'),
        const Text('• 农历日期显示'),
        const Text('• AI 智能创建事件'),
        const Text('• iCalendar 导入导出'),
        const Text('• 事件提醒通知'),
      ],
    );
  }

  /// 显示重置确认对话框
  void _showResetDialog(BuildContext context, SettingsViewModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将所有设置恢复为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              settings.resetSettings();
              Navigator.pop(context);
              SnackBarHelper.show(context, '设置已重置');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
