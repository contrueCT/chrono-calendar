import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../../../data/models/schedule_type.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/models/countdown_model.dart';
import '../../../data/models/todo_model.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/models/llm_config_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../services/countdown_service.dart';
import '../../../services/todo_service.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../widgets/form/schedule_type_selector.dart';
import '../../widgets/form/ai_input_field.dart';
import '../../widgets/form/date_time_picker.dart';
import '../../widgets/form/reminder_picker.dart';
import '../../widgets/form/recurrence_picker.dart';
import '../../widgets/form/color_picker_field.dart';

/// 统一的日程创建页面
/// 支持创建：默认日程、重要日（倒计时）、生日、待办
class ScheduleCreateScreen extends StatefulWidget {
  /// 初始日期
  final DateTime? initialDate;

  /// 初始类型
  final ScheduleType? initialType;

  const ScheduleCreateScreen({
    super.key,
    this.initialDate,
    this.initialType,
  });

  @override
  State<ScheduleCreateScreen> createState() => _ScheduleCreateScreenState();
}

class _ScheduleCreateScreenState extends State<ScheduleCreateScreen> {
  late ScheduleType _selectedType;
  bool _isLoading = false;

  // 通用字段
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 日历相关
  final CalendarRepository _calendarRepository = CalendarRepository();
  List<CalendarModel> _calendars = [];
  String? _selectedCalendarId;

  // 事件相关字段
  late DateTime _eventStartDate;
  late DateTime _eventEndDate;
  TimeOfDay _eventStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _eventEndTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isAllDay = false;
  int? _eventColor;
  List<int> _eventReminders = [15];

  // 倒计时相关字段
  late DateTime _countdownTargetDate;
  bool _isLunar = false;
  int? _lunarMonth;
  int? _lunarDay;
  bool _isLeapMonth = false;
  CountdownCategory _countdownCategory = CountdownCategory.other;
  int _countdownColor = 0xFF2563EB;
  bool _repeatYearly = false;
  bool _countdownNotifyEnabled = false;
  List<int> _countdownNotifyDays = [0, 1, 7];

  // 待办相关字段
  DateTime? _todoDueDate;
  TimeOfDay? _todoDueTime;
  int _todoPriority = 0;
  int? _todoColor;
  bool _todoNotifyEnabled = false;
  int _todoNotifyMinutes = 30;
  String? _todoDescription;

  // 预设颜色
  static const List<int> _presetColors = [
    0xFF2563EB, 0xFFDC2626, 0xFF16A34A, 0xFFEA580C,
    0xFF9333EA, 0xFFDB2777, 0xFF0891B2, 0xFF854D0E,
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? ScheduleType.event;
    final initialDate = widget.initialDate ?? DateTime.now();

    // 初始化事件日期
    _eventStartDate = initialDate;
    _eventEndDate = initialDate;

    // 初始化倒计时日期
    _countdownTargetDate = initialDate.add(const Duration(days: 7));
    _updateLunarFromSolar(_countdownTargetDate);

    // 初始化待办日期
    _todoDueDate = initialDate;

    // 根据初始类型设置默认值
    if (widget.initialType == ScheduleType.birthday) {
      _countdownCategory = CountdownCategory.birthday;
      _repeatYearly = true;
    } else if (widget.initialType == ScheduleType.important) {
      _countdownCategory = CountdownCategory.anniversary;
    }

    // 加载日历列表
    _loadCalendars();
  }

  /// 加载日历列表并设置默认日历
  Future<void> _loadCalendars() async {
    final calendars = await _calendarRepository.getAllCalendars();
    // 只显示本地日历（非订阅日历）
    final localCalendars = calendars.where((c) => !c.isSubscription).toList();

    if (mounted) {
      setState(() {
        _calendars = localCalendars;
        // 设置默认选中的日历
        if (_selectedCalendarId == null && localCalendars.isNotEmpty) {
          // 优先选择默认日历
          final defaultCalendar = localCalendars.firstWhere(
            (c) => c.isDefault,
            orElse: () => localCalendars.first,
          );
          _selectedCalendarId = defaultCalendar.id;
        }
      });
    }
  }

  void _updateLunarFromSolar(DateTime date) {
    final lunar = Lunar.fromDate(date);
    _lunarMonth = lunar.getMonth().abs();
    _lunarDay = lunar.getDay();
    _isLeapMonth = lunar.getMonth() < 0;
  }

  void _updateSolarFromLunar() {
    if (_lunarMonth == null || _lunarDay == null) return;
    try {
      final lunar = Lunar.fromYmd(
        _countdownTargetDate.year,
        _isLeapMonth ? -_lunarMonth! : _lunarMonth!,
        _lunarDay!,
      );
      final solar = lunar.getSolar();
      _countdownTargetDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      // 无效的农历日期
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(false),
          icon: const Icon(Icons.close),
        ),
        title: const Text('新建日程'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '保存',
                    style: TextStyle(
                      color: _titleController.text.trim().isNotEmpty
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型选择器
                ScheduleTypeSelector(
                  selected: _selectedType,
                  onChanged: (type) {
                    setState(() {
                      _selectedType = type;
                      // 根据类型设置默认值
                      if (type == ScheduleType.birthday) {
                        _countdownCategory = CountdownCategory.birthday;
                        _repeatYearly = true;
                      } else if (type == ScheduleType.important) {
                        _countdownCategory = CountdownCategory.anniversary;
                      }
                    });
                  },
                ),

                const Divider(height: 1),

                // AI 智能输入
                AIInputField(
                  onParsed: _onScheduleParsed,
                ),

                // 表单内容
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题输入
                      _buildTitleField(theme, colorScheme),
                      const SizedBox(height: 24),

                      // 根据类型显示不同的表单
                      if (_selectedType.isEvent)
                        _buildEventForm(theme, colorScheme)
                      else if (_selectedType.isCountdown)
                        _buildCountdownForm(theme, colorScheme)
                      else if (_selectedType.isTodo)
                        _buildTodoForm(theme, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _titleController,
      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: _getHintText(),
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入标题';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case ScheduleType.event:
        return '添加日程标题';
      case ScheduleType.important:
        return '添加重要日标题';
      case ScheduleType.birthday:
        return '谁的生日？';
      case ScheduleType.todo:
        return '添加待办事项';
    }
  }

  // ==================== 事件表单 ====================

  Widget _buildEventForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日历选择
        if (_calendars.isNotEmpty) ...[
          _buildCalendarPicker(colorScheme),
          const SizedBox(height: 16),
        ],

        // 全天事件开关
        _buildAllDaySwitch(colorScheme),
        const SizedBox(height: 16),

        // 日期时间选择
        DateTimeRangePicker(
          startDateTime: DateTime(
            _eventStartDate.year,
            _eventStartDate.month,
            _eventStartDate.day,
            _eventStartTime.hour,
            _eventStartTime.minute,
          ),
          endDateTime: DateTime(
            _eventEndDate.year,
            _eventEndDate.month,
            _eventEndDate.day,
            _eventEndTime.hour,
            _eventEndTime.minute,
          ),
          isAllDay: _isAllDay,
          onStartDateChanged: (date) => setState(() => _eventStartDate = date),
          onStartTimeChanged: (time) => setState(() => _eventStartTime = time),
          onEndDateChanged: (date) => setState(() => _eventEndDate = date),
          onEndTimeChanged: (time) => setState(() => _eventEndTime = time),
        ),
        const SizedBox(height: 24),

        // 提醒设置
        ReminderPicker(
          selectedMinutes: _eventReminders,
          onAdd: (minutes) {
            setState(() {
              if (!_eventReminders.contains(minutes)) {
                _eventReminders.add(minutes);
                _eventReminders.sort();
              }
            });
          },
          onRemove: (minutes) {
            setState(() => _eventReminders.remove(minutes));
          },
        ),
        const SizedBox(height: 24),

        // 地点输入
        _buildLocationField(colorScheme),
        const SizedBox(height: 16),

        // 备注输入
        _buildDescriptionField(colorScheme),
        const SizedBox(height: 24),

        // 颜色选择
        CompactColorPicker(
          selectedColor: _eventColor ?? 0xFF2563EB,
          onColorChanged: (color) => setState(() => _eventColor = color),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLocationField(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: '添加地点',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(Icons.notes_outlined, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '添加备注',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDaySwitch(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('全天事件')),
          Switch(
            value: _isAllDay,
            onChanged: (value) => setState(() => _isAllDay = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPicker(ColorScheme colorScheme) {
    // 获取当前选中的日历
    final selectedCalendar = _calendars.firstWhere(
      (c) => c.id == _selectedCalendarId,
      orElse: () => _calendars.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 日历颜色标识
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(selectedCalendar.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedCalendar.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // 下拉选择按钮
          PopupMenuButton<String>(
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant,
            ),
            onSelected: (calendarId) {
              setState(() => _selectedCalendarId = calendarId);
            },
            itemBuilder: (context) => _calendars.map((calendar) {
              final isSelected = calendar.id == _selectedCalendarId;
              return PopupMenuItem<String>(
                value: calendar.id,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(calendar.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(calendar.name)),
                    if (isSelected)
                      Icon(Icons.check, size: 18, color: colorScheme.primary),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 倒计时表单 ====================

  Widget _buildCountdownForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类选择（仅重要日显示）
        if (_selectedType == ScheduleType.important) ...[
          _buildSectionTitle('分类', colorScheme),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CountdownCategory.anniversary,
              CountdownCategory.holiday,
              CountdownCategory.deadline,
              CountdownCategory.other,
            ].map((category) {
              final isSelected = _countdownCategory == category;
              return ChoiceChip(
                label: Text(_getCategoryName(category)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _countdownCategory = category);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // 日期类型切换
        _buildSectionTitle('日期类型', colorScheme),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('公历')),
            ButtonSegment(value: true, label: Text('农历')),
          ],
          selected: {_isLunar},
          onSelectionChanged: (selected) {
            setState(() {
              _isLunar = selected.first;
              if (!_isLunar) _updateSolarFromLunar();
            });
          },
        ),
        const SizedBox(height: 16),

        // 日期选择
        _isLunar
            ? _buildLunarDatePicker(colorScheme)
            : _buildSolarDatePicker(colorScheme),
        const SizedBox(height: 24),

        // 颜色选择
        _buildSectionTitle('颜色', colorScheme),
        const SizedBox(height: 8),
        _buildColorPicker(),
        const SizedBox(height: 24),

        // 选项
        _buildSectionTitle('选项', colorScheme),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('每年重复'),
          subtitle: const Text('适用于生日、纪念日等'),
          value: _repeatYearly,
          onChanged: (value) => setState(() => _repeatYearly = value),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('启用提醒'),
          subtitle: const Text('在指定天数前提醒'),
          value: _countdownNotifyEnabled,
          onChanged: (value) => setState(() => _countdownNotifyEnabled = value),
          contentPadding: EdgeInsets.zero,
        ),

        if (_countdownNotifyEnabled) ...[
          const SizedBox(height: 8),
          _buildNotifyDaysSelector(),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSolarDatePicker(ColorScheme colorScheme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.calendar_today, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(_countdownTargetDate),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '农历 ${LunarUtils.getFullLunarString(_countdownTargetDate)}',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _countdownTargetDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          locale: const Locale('zh', 'CN'),
        );
        if (picked != null) {
          setState(() {
            _countdownTargetDate = picked;
            _updateLunarFromSolar(picked);
          });
        }
      },
    );
  }

  Widget _buildLunarDatePicker(ColorScheme colorScheme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.calendar_month, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        _lunarMonth != null && _lunarDay != null
            ? '${_isLeapMonth ? '闰' : ''}${_getLunarMonthName(_lunarMonth!)}月${_getLunarDayName(_lunarDay!)}'
            : '选择农历日期',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '对应公历 ${DateFormat('yyyy年M月d日').format(_countdownTargetDate)}',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLunarDatePicker(),
    );
  }

  void _showLunarDatePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    int tempMonth = _lunarMonth ?? 1;
    int tempDay = _lunarDay ?? 1;
    bool tempIsLeap = _isLeapMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('选择农历日期', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _lunarMonth = tempMonth;
                        _lunarDay = tempDay;
                        _isLeapMonth = tempIsLeap;
                        _updateSolarFromLunar();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('月份', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final isSelected = tempMonth == month && !tempIsLeap;
                  return ChoiceChip(
                    label: Text('${_getLunarMonthName(month)}月'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setSheetState(() {
                          tempMonth = month;
                          tempIsLeap = false;
                        });
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text('日期', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = tempDay == day;
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempDay = day),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getLunarDayName(day),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetColors.map((color) {
        final isSelected = _countdownColor == color;
        return GestureDetector(
          onTap: () => setState(() => _countdownColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: colorScheme.outline, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotifyDaysSelector() {
    final options = [
      {'value': 0, 'label': '当天'},
      {'value': 1, 'label': '1天前'},
      {'value': 3, 'label': '3天前'},
      {'value': 7, 'label': '1周前'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final value = option['value'] as int;
        final label = option['label'] as String;
        final isSelected = _countdownNotifyDays.contains(value);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _countdownNotifyDays.add(value);
                _countdownNotifyDays.sort();
              } else {
                _countdownNotifyDays.remove(value);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ==================== 待办表单 ====================

  Widget _buildTodoForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 截止日期
        _buildSectionTitle('截止日期（可选）', colorScheme),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: colorScheme.onPrimaryContainer),
          ),
          title: Text(
            _todoDueDate != null
                ? DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(_todoDueDate!)
                : '选择截止日期',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: _todoDueTime != null
              ? Text('${_todoDueTime!.hour.toString().padLeft(2, '0')}:${_todoDueTime!.minute.toString().padLeft(2, '0')}')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_todoDueDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _todoDueDate = null;
                    _todoDueTime = null;
                  }),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _todoDueDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              locale: const Locale('zh', 'CN'),
            );
            if (picked != null) {
              setState(() => _todoDueDate = picked);

              // 询问是否设置时间
              if (mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _todoDueTime ?? const TimeOfDay(hour: 18, minute: 0),
                );
                if (time != null) {
                  setState(() => _todoDueTime = time);
                }
              }
            }
          },
        ),
        const SizedBox(height: 24),

        // 优先级
        _buildSectionTitle('优先级', colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            {'value': 0, 'label': '无', 'color': Colors.grey},
            {'value': 1, 'label': '低', 'color': Colors.blue},
            {'value': 2, 'label': '中', 'color': Colors.orange},
            {'value': 3, 'label': '高', 'color': Colors.red},
          ].map((option) {
            final value = option['value'] as int;
            final label = option['label'] as String;
            final color = option['color'] as Color;
            final isSelected = _todoPriority == value;

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: color.withOpacity(0.2),
              onSelected: (selected) {
                if (selected) setState(() => _todoPriority = value);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 提醒
        SwitchListTile(
          title: const Text('启用提醒'),
          subtitle: Text(_todoNotifyEnabled ? '截止前 $_todoNotifyMinutes 分钟提醒' : '不提醒'),
          value: _todoNotifyEnabled,
          onChanged: _todoDueDate != null
              ? (value) => setState(() => _todoNotifyEnabled = value)
              : null,
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== 辅助方法 ====================

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _getCategoryName(CountdownCategory category) {
    switch (category) {
      case CountdownCategory.birthday:
        return '生日';
      case CountdownCategory.anniversary:
        return '纪念日';
      case CountdownCategory.holiday:
        return '节假日';
      case CountdownCategory.deadline:
        return '截止日期';
      case CountdownCategory.other:
        return '其他';
    }
  }

  String _getLunarMonthName(int month) {
    const months = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    return months[(month - 1) % 12];
  }

  String _getLunarDayName(int day) {
    const days = [
      '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
      '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
      '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
    ];
    return days[(day - 1) % 30];
  }

  // ==================== AI 解析处理 ====================

  /// AI 解析处理（支持事件/倒计时/待办）
  void _onScheduleParsed(ParsedScheduleResult result) {
    setState(() {
      switch (result.type) {
        case 'event':
          if (result.eventDraft != null) {
            _handleEventDraft(result.eventDraft!);
          }
          break;
        case 'countdown':
          if (result.countdownDraft != null) {
            _handleCountdownDraft(result.countdownDraft!);
          }
          break;
        case 'todo':
          if (result.todoDraft != null) {
            _handleTodoDraft(result.todoDraft!);
          }
          break;
      }
    });
  }

  /// 处理事件类型解析结果
  void _handleEventDraft(ParsedEventDraft draft) {
    _selectedType = ScheduleType.event;
    _titleController.text = draft.title;

    if (draft.startTime != null) {
      _eventStartDate = draft.startTime!;
      _eventStartTime = TimeOfDay.fromDateTime(draft.startTime!);
    }
    if (draft.endTime != null) {
      _eventEndDate = draft.endTime!;
      _eventEndTime = TimeOfDay.fromDateTime(draft.endTime!);
    }
    _isAllDay = draft.isAllDay;
    _locationController.text = draft.location ?? '';
    _descriptionController.text = draft.description ?? '';
    if (draft.reminderMinutes != null) {
      _eventReminders = [draft.reminderMinutes!];
    }
  }

  /// 处理倒计时类型解析结果
  void _handleCountdownDraft(ParsedCountdownDraft draft) {
    // 根据 category 决定类型
    if (draft.category == 'birthday') {
      _selectedType = ScheduleType.birthday;
      _countdownCategory = CountdownCategory.birthday;
      _repeatYearly = true;
    } else {
      _selectedType = ScheduleType.important;
      _countdownCategory = _mapCategoryFromString(draft.category);
    }

    _titleController.text = draft.title;
    _countdownTargetDate = draft.targetDate;
    _repeatYearly = draft.repeatYearly;
    _isLunar = draft.isLunar;

    if (draft.isLunar && draft.lunarMonth != null && draft.lunarDay != null) {
      _lunarMonth = draft.lunarMonth;
      _lunarDay = draft.lunarDay;
    } else {
      _updateLunarFromSolar(draft.targetDate);
    }
  }

  /// 处理待办类型解析结果
  void _handleTodoDraft(ParsedTodoDraft draft) {
    _selectedType = ScheduleType.todo;
    _titleController.text = draft.title;
    _todoDueDate = draft.dueDate;

    if (draft.dueTime != null) {
      _todoDueTime = TimeOfDay.fromDateTime(draft.dueTime!);
    }
    _todoPriority = draft.priority;
    _todoDescription = draft.description;

    // 如果有截止日期，默认启用提醒
    if (_todoDueDate != null) {
      _todoNotifyEnabled = true;
    }
  }

  /// 从字符串映射 CountdownCategory
  CountdownCategory _mapCategoryFromString(String? category) {
    switch (category) {
      case 'birthday':
        return CountdownCategory.birthday;
      case 'anniversary':
        return CountdownCategory.anniversary;
      case 'holiday':
        return CountdownCategory.holiday;
      case 'deadline':
        return CountdownCategory.deadline;
      default:
        return CountdownCategory.other;
    }
  }

  // ==================== 保存处理 ====================

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = false;

      switch (_selectedType) {
        case ScheduleType.event:
          success = await _saveEvent();
          break;
        case ScheduleType.important:
        case ScheduleType.birthday:
          success = await _saveCountdown();
          break;
        case ScheduleType.todo:
          success = await _saveTodo();
          break;
      }

      if (success && mounted) {
        context.pop(true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _saveEvent() async {
    // 确保有选中的日历
    String calendarId = _selectedCalendarId ?? '';
    if (calendarId.isEmpty) {
      // 尝试获取默认日历
      final defaultCalendar = await _calendarRepository.getDefaultCalendar();
      if (defaultCalendar != null) {
        calendarId = defaultCalendar.id;
      } else {
        // 没有可用日历，显示错误
        if (mounted) {
          SnackBarHelper.showError(context, '请先创建一个日历');
        }
        return false;
      }
    }

    final event = EventModel.create(
      calendarId: calendarId,
      summary: _titleController.text.trim(),
      dtStart: _isAllDay
          ? DateTime(_eventStartDate.year, _eventStartDate.month, _eventStartDate.day)
          : DateTime(
              _eventStartDate.year,
              _eventStartDate.month,
              _eventStartDate.day,
              _eventStartTime.hour,
              _eventStartTime.minute,
            ),
      dtEnd: _isAllDay
          ? DateTime(_eventEndDate.year, _eventEndDate.month, _eventEndDate.day, 23, 59)
          : DateTime(
              _eventEndDate.year,
              _eventEndDate.month,
              _eventEndDate.day,
              _eventEndTime.hour,
              _eventEndTime.minute,
            ),
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      color: _eventColor,
    );

    // 使用 EventRepository 保存
    final repository = EventRepository();
    await repository.insertEvent(event);

    // 添加提醒
    for (int i = 0; i < _eventReminders.length; i++) {
      final minutes = _eventReminders[i];
      final notificationId = (event.uid.hashCode + i).abs() % 2147483647;
      final reminder = ReminderModel(
        eventUid: event.uid,
        triggerMinutes: minutes,
        notificationId: notificationId,
      );
      await repository.addReminder(reminder);
    }

    return true;
  }

  Future<bool> _saveCountdown() async {
    final countdownService = CountdownService();

    final countdown = CountdownModel.create(
      title: _titleController.text.trim(),
      targetDate: _countdownTargetDate,
      isLunar: _isLunar,
      lunarMonth: _isLunar ? _lunarMonth : null,
      lunarDay: _isLunar ? _lunarDay : null,
      isLeapMonth: _isLunar ? _isLeapMonth : false,
      category: _selectedType == ScheduleType.birthday
          ? CountdownCategory.birthday
          : _countdownCategory,
      color: _countdownColor,
      repeatYearly: _repeatYearly,
      notifyEnabled: _countdownNotifyEnabled,
      notifyDays: _countdownNotifyEnabled ? _countdownNotifyDays : null,
    );

    final result = await countdownService.createCountdown(countdown);

    if (result.isFailure && mounted) {
      SnackBarHelper.showError(context, result.errorOrNull!.userFriendlyMessage);
      return false;
    }

    return true;
  }

  Future<bool> _saveTodo() async {
    final todoService = TodoService();

    final todo = TodoModel.create(
      title: _titleController.text.trim(),
      description: _todoDescription,
      dueDate: _todoDueDate,
      dueTime: _todoDueTime != null && _todoDueDate != null
          ? DateTime(
              _todoDueDate!.year,
              _todoDueDate!.month,
              _todoDueDate!.day,
              _todoDueTime!.hour,
              _todoDueTime!.minute,
            )
          : null,
      priority: _todoPriority,
      color: _todoColor,
      notifyEnabled: _todoNotifyEnabled,
      notifyMinutes: _todoNotifyEnabled ? _todoNotifyMinutes : null,
    );

    final result = await todoService.createTodo(todo);

    if (result.isFailure && mounted) {
      SnackBarHelper.showError(context, result.errorOrNull!.userFriendlyMessage);
      return false;
    }

    return true;
  }
}
