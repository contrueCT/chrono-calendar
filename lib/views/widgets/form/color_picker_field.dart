import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

/// 颜色选择器字段组件
class ColorPickerField extends StatelessWidget {
  /// 当前选中的颜色值
  final int selectedColor;

  /// 颜色变化回调
  final ValueChanged<int>? onColorChanged;

  /// 标签文本
  final String label;

  const ColorPickerField({
    super.key,
    required this.selectedColor,
    this.onColorChanged,
    this.label = '颜色',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 颜色选择网格
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ColorConstants.eventColors.map((color) {
            final isSelected = color.value == selectedColor;
            return _ColorOption(
              color: color,
              isSelected: isSelected,
              onTap: () => onColorChanged?.call(color.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 颜色选项
class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}

/// 紧凑版颜色选择器（用于表单行内显示）
class CompactColorPicker extends StatelessWidget {
  /// 当前选中的颜色值
  final int selectedColor;

  /// 颜色变化回调
  final ValueChanged<int>? onColorChanged;

  const CompactColorPicker({
    super.key,
    required this.selectedColor,
    this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 当前颜色预览
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(selectedColor),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '颜色',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getColorName(selectedColor),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _getColorName(int colorValue) {
    final index = ColorConstants.eventColors.indexWhere((c) => c.value == colorValue);
    const names = ['蓝色', '绿色', '红色', '橙色', '紫色', '青色', '粉色', '棕色', '靛蓝', '蓝绿'];
    if (index >= 0 && index < names.length) {
      return names[index];
    }
    return '自定义';
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ColorPickerSheet(
        selectedColor: selectedColor,
        onSelect: (color) {
          Navigator.pop(context);
          onColorChanged?.call(color);
        },
      ),
    );
  }
}

/// 颜色选择底部弹窗
class _ColorPickerSheet extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onSelect;

  const _ColorPickerSheet({
    required this.selectedColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '选择颜色',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // 颜色网格
          ColorPickerField(
            selectedColor: selectedColor,
            onColorChanged: onSelect,
            label: '',
          ),
        ],
      ),
    );
  }
}

/// 日历颜色指示器（用于日历选择列表）
class CalendarColorIndicator extends StatelessWidget {
  /// 颜色值
  final int color;

  /// 尺寸
  final double size;

  const CalendarColorIndicator({
    super.key,
    required this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
      ),
    );
  }
}
