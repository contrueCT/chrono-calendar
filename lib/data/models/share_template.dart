import 'package:flutter/material.dart';

/// 分享模板类型枚举
enum ShareTemplateType {
  light,     // 简约白
  gradient,  // 渐变彩
  dark,      // 深色
  festival,  // 节日主题
}

/// 分享模板数据模型
class ShareTemplate {
  /// 模板名称
  final String name;

  /// 模板类型
  final ShareTemplateType type;

  /// 渐变背景
  final LinearGradient gradient;

  /// 主要文字颜色
  final Color textColor;

  /// 次要文字颜色
  final Color secondaryTextColor;

  /// 图标颜色
  final Color iconColor;

  /// 模板图标（用于选择界面）
  final IconData? icon;

  const ShareTemplate({
    required this.name,
    required this.type,
    required this.gradient,
    required this.textColor,
    required this.secondaryTextColor,
    required this.iconColor,
    this.icon,
  });

  /// 简约白模板
  static const light = ShareTemplate(
    name: '简约白',
    type: ShareTemplateType.light,
    gradient: LinearGradient(
      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Color(0xFF0F172A),
    secondaryTextColor: Color(0xFF64748B),
    iconColor: Color(0xFF475569),
    icon: Icons.wb_sunny_outlined,
  );

  /// 渐变彩模板
  static const colorful = ShareTemplate(
    name: '渐变彩',
    type: ShareTemplateType.gradient,
    gradient: LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
    secondaryTextColor: Color(0xCCFFFFFF),
    iconColor: Colors.white,
    icon: Icons.gradient,
  );

  /// 深色模板
  static const dark = ShareTemplate(
    name: '深色',
    type: ShareTemplateType.dark,
    gradient: LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Color(0xFFF1F5F9),
    secondaryTextColor: Color(0xFF94A3B8),
    iconColor: Color(0xFFCBD5E1),
    icon: Icons.dark_mode_outlined,
  );

  /// 节日主题模板（春节）
  static const festival = ShareTemplate(
    name: '节日红',
    type: ShareTemplateType.festival,
    gradient: LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Color(0xFFFEF2F2),
    secondaryTextColor: Color(0xFFFCA5A5),
    iconColor: Color(0xFFFEE2E2),
    icon: Icons.celebration_outlined,
  );

  /// 所有预设模板列表
  static const List<ShareTemplate> presets = [
    light,
    colorful,
    dark,
    festival,
  ];

  /// 根据事件颜色创建自定义模板
  static ShareTemplate fromEventColor(Color eventColor) {
    // 计算亮度来决定文字颜色
    final luminance = eventColor.computeLuminance();
    final isLight = luminance > 0.5;

    return ShareTemplate(
      name: '事件颜色',
      type: ShareTemplateType.gradient,
      gradient: LinearGradient(
        colors: [
          eventColor,
          eventColor.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: isLight ? const Color(0xFF0F172A) : Colors.white,
      secondaryTextColor: isLight
          ? const Color(0xFF64748B)
          : Colors.white.withOpacity(0.8),
      iconColor: isLight ? const Color(0xFF475569) : Colors.white,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareTemplate && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}
