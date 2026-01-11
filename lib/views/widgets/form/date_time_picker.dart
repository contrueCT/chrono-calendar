import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 日期时间选择器组件
class DateTimePicker extends StatelessWidget {
  /// 当前日期时间
  final DateTime dateTime;

  /// 是否只显示日期（全天事件）
  final bool dateOnly;

  /// 标签文本
  final String label;

  /// 日期变化回调
  final ValueChanged<DateTime>? onDateChanged;

  /// 时间变化回调
  final ValueChanged<TimeOfDay>? onTimeChanged;

  /// 最早可选日期
  final DateTime? firstDate;

  /// 最晚可选日期
  final DateTime? lastDate;

  const DateTimePicker({
    super.key,
    required this.dateTime,
    this.dateOnly = false,
    required this.label,
    this.onDateChanged,
    this.onTimeChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // 选择器行
        Row(
          children: [
            // 日期选择
            Expanded(
              flex: 3,
              child: _DatePickerButton(
                dateTime: dateTime,
                onDateChanged: onDateChanged,
                firstDate: firstDate,
                lastDate: lastDate,
              ),
            ),
            // 时间选择（非全天事件显示）
            if (!dateOnly) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _TimePickerButton(
                  time: TimeOfDay.fromDateTime(dateTime),
                  onTimeChanged: onTimeChanged,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 日期选择按钮
class _DatePickerButton extends StatelessWidget {
  final DateTime dateTime;
  final ValueChanged<DateTime>? onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _DatePickerButton({
    required this.dateTime,
    this.onDateChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 判断是否为今天、明天、后天
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = selectedDate.difference(today).inDays;

    String displayText;
    if (diff == 0) {
      displayText = '今天';
    } else if (diff == 1) {
      displayText = '明天';
    } else if (diff == 2) {
      displayText = '后天';
    } else if (diff == -1) {
      displayText = '昨天';
    } else {
      displayText = DateFormat('M月d日 E', 'zh_CN').format(dateTime);
    }

    return InkWell(
      onTap: () => _showDatePicker(context),
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
              Icons.calendar_today,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (diff.abs() > 2)
                    Text(
                      DateFormat('yyyy年').format(dateTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null && onDateChanged != null) {
      onDateChanged!(picked);
    }
  }
}

/// 时间选择按钮
class _TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  const _TimePickerButton({
    required this.time,
    this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayText = _formatTime(time);

    return InkWell(
      onTap: () => _showTimePicker(context),
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
              Icons.access_time,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && onTimeChanged != null) {
      onTimeChanged!(picked);
    }
  }
}

/// 日期范围选择器（用于开始-结束时间选择）
class DateTimeRangePicker extends StatelessWidget {
  /// 开始时间
  final DateTime startDateTime;

  /// 结束时间
  final DateTime endDateTime;

  /// 是否全天事件
  final bool isAllDay;

  /// 开始日期变化回调
  final ValueChanged<DateTime>? onStartDateChanged;

  /// 开始时间变化回调
  final ValueChanged<TimeOfDay>? onStartTimeChanged;

  /// 结束日期变化回调
  final ValueChanged<DateTime>? onEndDateChanged;

  /// 结束时间变化回调
  final ValueChanged<TimeOfDay>? onEndTimeChanged;

  const DateTimeRangePicker({
    super.key,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    this.onStartDateChanged,
    this.onStartTimeChanged,
    this.onEndDateChanged,
    this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 开始时间
        DateTimePicker(
          dateTime: startDateTime,
          dateOnly: isAllDay,
          label: '开始时间',
          onDateChanged: onStartDateChanged,
          onTimeChanged: onStartTimeChanged,
        ),
        const SizedBox(height: 16),
        // 结束时间
        DateTimePicker(
          dateTime: endDateTime,
          dateOnly: isAllDay,
          label: '结束时间',
          onDateChanged: onEndDateChanged,
          onTimeChanged: onEndTimeChanged,
          firstDate: startDateTime,
        ),
      ],
    );
  }
}
