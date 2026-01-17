import 'package:flutter/material.dart';
import '../../../data/models/schedule_type.dart';

/// 日程类型选择器组件
/// 用于在新建日程时选择类型（默认/重要日/生日/待办）
class ScheduleTypeSelector extends StatelessWidget {
  /// 当前选中的类型
  final ScheduleType selected;

  /// 类型变更回调
  final ValueChanged<ScheduleType> onChanged;

  const ScheduleTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ScheduleType.values.map((type) {
          final isSelected = type == selected;
          return _TypeButton(
            type: type,
            isSelected: isSelected,
            colorScheme: colorScheme,
            onTap: () => onChanged(type),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final ScheduleType type;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TypeButton({
    required this.type,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圆形按钮
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              type.icon,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // 标签
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 紧凑型类型选择器（用于空间有限的情况）
class CompactScheduleTypeSelector extends StatelessWidget {
  final ScheduleType selected;
  final ValueChanged<ScheduleType> onChanged;

  const CompactScheduleTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ScheduleType.values.map((type) {
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 16,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(type.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
