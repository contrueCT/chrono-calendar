import 'package:flutter/material.dart';

/// 应用颜色常量
class ColorConstants {
  ColorConstants._();

  // ========== 主色调 - 蓝色系 ==========
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF60A5FA);
  static const Color primaryContainerLight = Color(0xFFDBEAFE);
  static const Color primaryContainerDark = Color(0xFF1E3A5F);

  // ========== 辅助色 - 紫色系 ==========
  static const Color secondaryLight = Color(0xFF7C3AED);
  static const Color secondaryDark = Color(0xFFA78BFA);

  // ========== 强调色 - 绿色系 ==========
  static const Color tertiaryLight = Color(0xFF059669);
  static const Color tertiaryDark = Color(0xFF34D399);

  // ========== 背景色 ==========
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceVariantLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantDark = Color(0xFF1E293B);

  // ========== 文字色 ==========
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceDark = Color(0xFFF1F5F9);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // ========== 错误色 ==========
  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFF87171);

  // ========== 轮廓色 ==========
  static const Color outlineLight = Color(0xFFCBD5E1);
  static const Color outlineDark = Color(0xFF334155);
  static const Color outlineVariantLight = Color(0xFFE2E8F0);
  static const Color outlineVariantDark = Color(0xFF1E293B);

  // ========== 日历事件颜色 ==========
  static const List<Color> eventColors = [
    Color(0xFF3B82F6), // 蓝色
    Color(0xFF10B981), // 绿色
    Color(0xFFEF4444), // 红色
    Color(0xFFF59E0B), // 橙色
    Color(0xFF8B5CF6), // 紫色
    Color(0xFF06B6D4), // 青色
    Color(0xFFEC4899), // 粉色
    Color(0xFF78716C), // 棕色
    Color(0xFF6366F1), // 靛蓝
    Color(0xFF14B8A6), // 蓝绿
  ];

  /// 获取默认事件颜色
  static Color get defaultEventColor => eventColors[0];

  /// 根据索引获取事件颜色
  static Color getEventColor(int index) {
    return eventColors[index % eventColors.length];
  }

  // ========== 农历特殊日期颜色 ==========
  static const Color solarTermColor = Color(0xFF059669); // 节气 - 绿色
  static const Color lunarFestivalColor = Color(0xFFDC2626); // 农历节日 - 红色
  static const Color solarFestivalColor = Color(0xFF2563EB); // 公历节日 - 蓝色

  // ========== 毛玻璃效果颜色 ==========
  static Color glassBackgroundLight = Colors.white.withOpacity(0.15);
  static Color glassBackgroundDark = Colors.white.withOpacity(0.08);
  static Color glassBorderLight = Colors.white.withOpacity(0.2);
  static Color glassBorderDark = Colors.white.withOpacity(0.1);
}
