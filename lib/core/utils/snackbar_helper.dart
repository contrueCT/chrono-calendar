import 'dart:async';
import 'package:flutter/material.dart';

/// SnackBar 辅助类
/// 统一管理应用中的 SnackBar 显示，提供一致的样式和行为
class SnackBarHelper {
  /// 显示普通提示
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );

    // 当有 action 时，Flutter 会忽略 duration 参数
    // 使用 Timer 强制在指定时间后关闭 SnackBar
    if (actionLabel != null) {
      Timer(duration, () {
        controller.close();
      });
    }
  }

  /// 显示成功提示
  static void showSuccess(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.green);
  }

  /// 显示错误提示
  static void showError(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.red);
  }

  /// 显示警告提示
  static void showWarning(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.orange);
  }
}
