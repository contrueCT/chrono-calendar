import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'notification_service.dart';

/// 权限状态
enum PermissionStatus {
  granted,    // 已授权
  denied,     // 已拒绝
  unknown,    // 未知
}

/// 权限服务 - 处理应用权限请求
class PermissionService {
  // 单例模式
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final NotificationService _notificationService = NotificationService();

  /// 检查通知权限状态
  Future<PermissionStatus> checkNotificationPermission() async {
    final hasPermission = await _notificationService.hasPermission();
    return hasPermission ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// 检查精确闹钟权限状态（仅 Android）
  Future<PermissionStatus> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }

    final hasPermission = await _notificationService.hasExactAlarmPermission();
    return hasPermission ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// 请求通知权限
  /// 返回是否获得权限
  Future<bool> requestNotificationPermission() async {
    return await _notificationService.requestPermission();
  }

  /// 请求精确闹钟权限（仅 Android）
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return await _notificationService.requestExactAlarmPermission();
  }

  /// 打开应用通知设置
  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  /// 打开应用设置（用于精确闹钟权限）
  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  /// 显示通知权限请求对话框
  /// 返回用户是否同意请求权限
  Future<bool> showNotificationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.blue),
            SizedBox(width: 12),
            Text('开启通知权限'),
          ],
        ),
        content: const Text(
          'Chrono 需要通知权限来提醒您的日程安排。\n\n'
          '开启通知后，您将在日程开始前收到提醒，不错过任何重要事项。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开启通知'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示通知权限被拒绝的提示
  Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('通知权限未开启'),
          ],
        ),
        content: const Text(
          '您尚未开启通知权限，日程提醒功能将无法正常工作。\n\n'
          '您可以在系统设置中手动开启通知权限。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openNotificationSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 显示精确闹钟权限请求对话框（仅 Android 12+）
  Future<bool> showExactAlarmPermissionDialog(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.blue),
            SizedBox(width: 12),
            Text('精确提醒权限'),
          ],
        ),
        content: const Text(
          '为了确保日程提醒能够准时送达，Chrono 需要精确闹钟权限。\n\n'
          '开启此权限后，您的日程提醒将更加准确可靠。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开启权限'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 完整的权限请求流程
  /// 包括通知权限和精确闹钟权限
  Future<bool> requestAllPermissions(BuildContext context) async {
    // 1. 检查并请求通知权限
    final notificationStatus = await checkNotificationPermission();

    if (notificationStatus != PermissionStatus.granted) {
      // 显示说明对话框
      final userAgreed = await showNotificationPermissionDialog(context);

      if (userAgreed) {
        final granted = await requestNotificationPermission();
        if (!granted && context.mounted) {
          await showPermissionDeniedDialog(context);
          return false;
        }
      } else {
        return false;
      }
    }

    // 2. 检查并请求精确闹钟权限（仅 Android）
    if (Platform.isAndroid) {
      final alarmStatus = await checkExactAlarmPermission();

      if (alarmStatus != PermissionStatus.granted) {
        if (context.mounted) {
          final userAgreed = await showExactAlarmPermissionDialog(context);

          if (userAgreed) {
            await requestExactAlarmPermission();
          }
        }
      }
    }

    return true;
  }

  /// 检查是否所有必要权限都已授权
  Future<bool> hasAllPermissions() async {
    final notificationGranted = await _notificationService.hasPermission();
    if (!notificationGranted) return false;

    if (Platform.isAndroid) {
      final alarmGranted = await _notificationService.hasExactAlarmPermission();
      if (!alarmGranted) return false;
    }

    return true;
  }
}
