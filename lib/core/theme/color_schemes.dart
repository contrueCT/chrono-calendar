import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

/// 应用配色方案
class AppColorSchemes {
  AppColorSchemes._();

  /// 亮色主题配色方案
  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        // 主色调
        primary: ColorConstants.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: ColorConstants.primaryContainerLight,
        onPrimaryContainer: Color(0xFF0F172A),
        // 辅助色
        secondary: ColorConstants.secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF3E8FF),
        onSecondaryContainer: Color(0xFF2E1065),
        // 强调色
        tertiary: ColorConstants.tertiaryLight,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFD1FAE5),
        onTertiaryContainer: Color(0xFF064E3B),
        // 错误色
        error: ColorConstants.errorLight,
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF7F1D1D),
        // 背景
        surface: ColorConstants.surfaceLight,
        onSurface: ColorConstants.onSurfaceLight,
        surfaceContainerHighest: ColorConstants.surfaceVariantLight,
        onSurfaceVariant: ColorConstants.onSurfaceVariantLight,
        // 轮廓
        outline: ColorConstants.outlineLight,
        outlineVariant: ColorConstants.outlineVariantLight,
        // 阴影
        shadow: Colors.black,
        scrim: Colors.black,
        // 反色
        inverseSurface: Color(0xFF1E293B),
        onInverseSurface: Color(0xFFF1F5F9),
        inversePrimary: ColorConstants.primaryDark,
      );

  /// 深色主题配色方案
  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        // 主色调
        primary: ColorConstants.primaryDark,
        onPrimary: Color(0xFF0F172A),
        primaryContainer: ColorConstants.primaryContainerDark,
        onPrimaryContainer: Color(0xFFDBEAFE),
        // 辅助色
        secondary: ColorConstants.secondaryDark,
        onSecondary: Color(0xFF0F172A),
        secondaryContainer: Color(0xFF4C1D95),
        onSecondaryContainer: Color(0xFFF3E8FF),
        // 强调色
        tertiary: ColorConstants.tertiaryDark,
        onTertiary: Color(0xFF0F172A),
        tertiaryContainer: Color(0xFF065F46),
        onTertiaryContainer: Color(0xFFD1FAE5),
        // 错误色
        error: ColorConstants.errorDark,
        onError: Color(0xFF0F172A),
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEE2E2),
        // 背景
        surface: ColorConstants.surfaceDark,
        onSurface: ColorConstants.onSurfaceDark,
        surfaceContainerHighest: ColorConstants.surfaceVariantDark,
        onSurfaceVariant: ColorConstants.onSurfaceVariantDark,
        // 轮廓
        outline: ColorConstants.outlineDark,
        outlineVariant: ColorConstants.outlineVariantDark,
        // 阴影
        shadow: Colors.black,
        scrim: Colors.black,
        // 反色
        inverseSurface: Color(0xFFF1F5F9),
        onInverseSurface: Color(0xFF1E293B),
        inversePrimary: ColorConstants.primaryLight,
      );
}
