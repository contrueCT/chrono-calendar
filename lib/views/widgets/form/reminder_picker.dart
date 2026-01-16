import 'package:flutter/material.dart';
import '../../../data/models/reminder_model.dart';

/// 提醒选择器组件
class ReminderPicker extends StatelessWidget {
  /// 当前选中的提醒时间列表（分钟）
  final List<int> selectedMinutes;

  /// 添加提醒回调
  final ValueChanged<int>? onAdd;

  /// 移除提醒回调
  final ValueChanged<int>? onRemove;

  const ReminderPicker({
    super.key,
    required this.selectedMinutes,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签行
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '提醒',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 已选择的提醒
        if (selectedMinutes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedMinutes.map((minutes) {
              return _ReminderChip(
                minutes: minutes,
                onRemove: onRemove != null ? () => onRemove!(minutes) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        // 添加提醒按钮
        OutlinedButton.icon(
          onPressed: () => _showAddReminderSheet(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加提醒'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    // 过滤掉已选择的选项
    final availableOptions = ReminderOptions.allOptions
        .where((m) => !selectedMinutes.contains(m))
        .toList();

    if (availableOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加所有可用的提醒时间')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReminderOptionsSheet(
        options: availableOptions,
        onSelect: (minutes) {
          Navigator.pop(context);
          onAdd?.call(minutes);
        },
      ),
    );
  }
}

/// 提醒标签
class _ReminderChip extends StatelessWidget {
  final int minutes;
  final VoidCallback? onRemove;

  const _ReminderChip({
    required this.minutes,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ReminderOptions.getDisplayText(minutes),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 提醒选项底部弹窗
class _ReminderOptionsSheet extends StatelessWidget {
  final List<int> options;
  final ValueChanged<int> onSelect;

  const _ReminderOptionsSheet({
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: EdgeInsets.only(top: 16, bottom: bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '选择提醒时间',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // 选项列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final minutes = options[index];
                return ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color: colorScheme.primary,
                  ),
                  title: Text(ReminderOptions.getDisplayText(minutes)),
                  onTap: () => onSelect(minutes),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 简化版提醒选择器（用于快速选择）
class SimpleReminderPicker extends StatelessWidget {
  /// 当前选中的提醒时间（分钟），null 表示无提醒
  final int? selectedMinutes;

  /// 选择变化回调
  final ValueChanged<int?>? onChanged;

  const SimpleReminderPicker({
    super.key,
    this.selectedMinutes,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayText = selectedMinutes != null
        ? ReminderOptions.getDisplayText(selectedMinutes!)
        : '无提醒';

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '提醒',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayText,
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

  void _showPicker(BuildContext context) {
    final allOptions = [null, ...ReminderOptions.allOptions];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SimpleReminderOptionsSheet(
        options: allOptions,
        selectedMinutes: selectedMinutes,
        onSelect: (minutes) {
          Navigator.pop(context);
          onChanged?.call(minutes);
        },
      ),
    );
  }
}

/// 简化版提醒选项底部弹窗
class _SimpleReminderOptionsSheet extends StatelessWidget {
  final List<int?> options;
  final int? selectedMinutes;
  final ValueChanged<int?> onSelect;

  const _SimpleReminderOptionsSheet({
    required this.options,
    this.selectedMinutes,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: EdgeInsets.only(top: 16, bottom: bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '选择提醒时间',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // 选项列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final minutes = options[index];
                final isSelected = minutes == selectedMinutes;
                final displayText = minutes != null
                    ? ReminderOptions.getDisplayText(minutes)
                    : '无提醒';

                return ListTile(
                  leading: Icon(
                    minutes != null ? Icons.access_time : Icons.notifications_off_outlined,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    displayText,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () => onSelect(minutes),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
