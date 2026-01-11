import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/recurrence_rule.dart';

/// 重复规则选择器组件
class RecurrencePicker extends StatelessWidget {
  /// 当前重复规则
  final RecurrenceRule? rule;

  /// 事件开始日期（用于确定默认值）
  final DateTime eventStartDate;

  /// 规则变化回调
  final ValueChanged<RecurrenceRule?>? onChanged;

  const RecurrencePicker({
    super.key,
    this.rule,
    required this.eventStartDate,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayText = rule?.description ?? '不重复';

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
              Icons.repeat,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '重复',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecurrencePickerSheet(
        currentRule: rule,
        eventStartDate: eventStartDate,
        onSelect: (newRule) {
          Navigator.pop(context);
          onChanged?.call(newRule);
        },
      ),
    );
  }
}

/// 重复规则选择底部弹窗
class _RecurrencePickerSheet extends StatefulWidget {
  final RecurrenceRule? currentRule;
  final DateTime eventStartDate;
  final ValueChanged<RecurrenceRule?> onSelect;

  const _RecurrencePickerSheet({
    this.currentRule,
    required this.eventStartDate,
    required this.onSelect,
  });

  @override
  State<_RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<_RecurrencePickerSheet> {
  late Frequency? _frequency;
  late int _interval;
  late List<WeekDay> _selectedWeekDays;
  late int? _monthDay;
  late ByDayRule? _monthWeekDay;
  late _EndType _endType;
  late int _count;
  late DateTime _until;
  late bool _useMonthWeekDay; // 每月按星期几还是按日期

  @override
  void initState() {
    super.initState();
    _initFromRule(widget.currentRule);
  }

  void _initFromRule(RecurrenceRule? rule) {
    if (rule == null) {
      _frequency = null;
      _interval = 1;
      _selectedWeekDays = [];
      _monthDay = widget.eventStartDate.day;
      _monthWeekDay = null;
      _endType = _EndType.never;
      _count = 10;
      _until = widget.eventStartDate.add(const Duration(days: 365));
      _useMonthWeekDay = false;
    } else {
      _frequency = rule.frequency;
      _interval = rule.interval;
      _selectedWeekDays = rule.byDay ?? [];
      _monthDay = rule.byMonthDay?.firstOrNull ?? widget.eventStartDate.day;
      _monthWeekDay = rule.byDayRules?.firstOrNull;
      _useMonthWeekDay = rule.byDayRules != null && rule.byDayRules!.isNotEmpty;

      if (rule.count != null) {
        _endType = _EndType.count;
        _count = rule.count!;
      } else if (rule.until != null) {
        _endType = _EndType.until;
        _until = rule.until!;
      } else {
        _endType = _EndType.never;
      }
      _count = rule.count ?? 10;
      _until = rule.until ?? widget.eventStartDate.add(const Duration(days: 365));
    }
  }

  RecurrenceRule? _buildRule() {
    if (_frequency == null) return null;

    return RecurrenceRule(
      frequency: _frequency!,
      interval: _interval,
      byDay: _frequency == Frequency.weekly && _selectedWeekDays.isNotEmpty
          ? _selectedWeekDays
          : null,
      byMonthDay: _frequency == Frequency.monthly && !_useMonthWeekDay
          ? [_monthDay ?? 1]
          : null,
      byDayRules: _frequency == Frequency.monthly && _useMonthWeekDay && _monthWeekDay != null
          ? [_monthWeekDay!]
          : null,
      count: _endType == _EndType.count ? _count : null,
      until: _endType == _EndType.until ? _until : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '重复设置',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => widget.onSelect(_buildRule()),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 频率选择
                  _buildFrequencySection(theme, colorScheme),
                  if (_frequency != null) ...[
                    const Divider(height: 1),
                    // 间隔设置
                    _buildIntervalSection(theme, colorScheme),
                    // 周重复：选择星期几
                    if (_frequency == Frequency.weekly) ...[
                      const Divider(height: 1),
                      _buildWeekDaysSection(theme, colorScheme),
                    ],
                    // 月重复：选择日期或星期几
                    if (_frequency == Frequency.monthly) ...[
                      const Divider(height: 1),
                      _buildMonthlySection(theme, colorScheme),
                    ],
                    const Divider(height: 1),
                    // 结束条件
                    _buildEndSection(theme, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(ThemeData theme, ColorScheme colorScheme) {
    final options = [
      (null, '不重复'),
      (Frequency.daily, '每天'),
      (Frequency.weekly, '每周'),
      (Frequency.monthly, '每月'),
      (Frequency.yearly, '每年'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = _frequency == option.$1;
          return ChoiceChip(
            label: Text(option.$2),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _frequency = option.$1;
                // 如果选择了每周，默认选中当前日期对应的星期
                if (_frequency == Frequency.weekly && _selectedWeekDays.isEmpty) {
                  _selectedWeekDays = [_getWeekDayFromDate(widget.eventStartDate)];
                }
                // 如果选择了每月，初始化月份规则
                if (_frequency == Frequency.monthly && _monthWeekDay == null) {
                  _initMonthlyDefaults();
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntervalSection(ThemeData theme, ColorScheme colorScheme) {
    final frequencyText = switch (_frequency) {
      Frequency.daily => '天',
      Frequency.weekly => '周',
      Frequency.monthly => '月',
      Frequency.yearly => '年',
      null => '',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('每', style: theme.textTheme.bodyLarge),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: DropdownButtonFormField<int>(
              value: _interval,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(30, (i) => i + 1).map((i) {
                return DropdownMenuItem(value: i, child: Text('$i'));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _interval = value);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(frequencyText, style: theme.textTheme.bodyLarge),
          Text(' 重复一次', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildWeekDaysSection(ThemeData theme, ColorScheme colorScheme) {
    const weekDays = [
      (WeekDay.mo, '一'),
      (WeekDay.tu, '二'),
      (WeekDay.we, '三'),
      (WeekDay.th, '四'),
      (WeekDay.fr, '五'),
      (WeekDay.sa, '六'),
      (WeekDay.su, '日'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '重复日',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isSelected = _selectedWeekDays.contains(day.$1);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWeekDays.remove(day.$1);
                    } else {
                      _selectedWeekDays.add(day.$1);
                    }
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.$2,
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '重复方式',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // 按日期
          RadioListTile<bool>(
            title: Text('每月 ${_monthDay ?? 1} 号'),
            value: false,
            groupValue: _useMonthWeekDay,
            onChanged: (value) {
              if (value != null) {
                setState(() => _useMonthWeekDay = value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          // 按星期几
          RadioListTile<bool>(
            title: Text(_getMonthWeekDayText()),
            value: true,
            groupValue: _useMonthWeekDay,
            onChanged: (value) {
              if (value != null) {
                setState(() => _useMonthWeekDay = value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildEndSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '结束条件',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // 永不结束
          RadioListTile<_EndType>(
            title: const Text('永不结束'),
            value: _EndType.never,
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() => _endType = value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          // 重复次数
          RadioListTile<_EndType>(
            title: Row(
              children: [
                const Text('重复 '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: TextEditingController(text: _count.toString()),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count > 0) {
                        _count = count;
                      }
                    },
                    enabled: _endType == _EndType.count,
                  ),
                ),
                const Text(' 次'),
              ],
            ),
            value: _EndType.count,
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() => _endType = value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          // 结束日期
          RadioListTile<_EndType>(
            title: Row(
              children: [
                const Text('结束于 '),
                TextButton(
                  onPressed: _endType == _EndType.until ? () => _selectEndDate(context) : null,
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_until),
                    style: TextStyle(
                      color: _endType == _EndType.until ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            value: _EndType.until,
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() => _endType = value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until,
      firstDate: widget.eventStartDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _until = picked);
    }
  }

  WeekDay _getWeekDayFromDate(DateTime date) {
    return WeekDay.values[(date.weekday - 1) % 7];
  }

  void _initMonthlyDefaults() {
    final date = widget.eventStartDate;
    _monthDay = date.day;

    // 计算是第几个星期几
    final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
    final weekDay = _getWeekDayFromDate(date);
    _monthWeekDay = ByDayRule(position: weekOfMonth, weekDay: weekDay);
  }

  String _getMonthWeekDayText() {
    if (_monthWeekDay == null) {
      _initMonthlyDefaults();
    }

    final positionText = switch (_monthWeekDay!.position) {
      1 => '第一个',
      2 => '第二个',
      3 => '第三个',
      4 => '第四个',
      5 => '第五个',
      -1 => '最后一个',
      _ => '第${_monthWeekDay!.position}个',
    };

    final dayText = switch (_monthWeekDay!.weekDay) {
      WeekDay.mo => '周一',
      WeekDay.tu => '周二',
      WeekDay.we => '周三',
      WeekDay.th => '周四',
      WeekDay.fr => '周五',
      WeekDay.sa => '周六',
      WeekDay.su => '周日',
    };

    return '每月$positionText$dayText';
  }
}

enum _EndType { never, count, until }
