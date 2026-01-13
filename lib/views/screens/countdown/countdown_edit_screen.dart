import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../../../data/models/countdown_model.dart';
import '../../../services/countdown_service.dart';
import '../../../core/utils/lunar_utils.dart';

/// 倒计时编辑页面
class CountdownEditScreen extends StatefulWidget {
  final String? countdownId;

  const CountdownEditScreen({super.key, this.countdownId});

  @override
  State<CountdownEditScreen> createState() => _CountdownEditScreenState();
}

class _CountdownEditScreenState extends State<CountdownEditScreen> {
  final CountdownService _countdownService = CountdownService();
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditMode = false;
  CountdownModel? _existingCountdown;

  // 表单状态
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));
  bool _isLunar = false;
  int? _lunarMonth;
  int? _lunarDay;
  bool _isLeapMonth = false;
  CountdownCategory _category = CountdownCategory.other;
  int _selectedColor = 0xFF2563EB;
  bool _repeatYearly = false;
  bool _notifyEnabled = false;
  List<int> _notifyDays = [0, 1, 7];

  // 预设颜色
  static const List<int> _presetColors = [
    0xFF2563EB, // 蓝色
    0xFFDC2626, // 红色
    0xFF16A34A, // 绿色
    0xFFEA580C, // 橙色
    0xFF9333EA, // 紫色
    0xFFDB2777, // 粉色
    0xFF0891B2, // 青色
    0xFF854D0E, // 棕色
    0xFF4B5563, // 灰色
    0xFF0F172A, // 深色
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.countdownId != null;
    if (_isEditMode) {
      _loadCountdown();
    } else {
      // 初始化农历日期
      _updateLunarFromSolar(_targetDate);
    }
  }

  Future<void> _loadCountdown() async {
    setState(() => _isLoading = true);

    final countdown = await _countdownService.getCountdown(widget.countdownId!);
    if (countdown != null) {
      setState(() {
        _existingCountdown = countdown;
        _titleController.text = countdown.title;
        _targetDate = countdown.targetDate;
        _isLunar = countdown.isLunar;
        _lunarMonth = countdown.lunarMonth;
        _lunarDay = countdown.lunarDay;
        _isLeapMonth = countdown.isLeapMonth;
        _category = countdown.category ?? CountdownCategory.other;
        _selectedColor = countdown.color ?? 0xFF2563EB;
        _repeatYearly = countdown.repeatYearly;
        _notifyEnabled = countdown.notifyEnabled;
        _notifyDays = countdown.notifyDays ?? [0, 1, 7];
      });

      if (!_isLunar) {
        _updateLunarFromSolar(_targetDate);
      }
    }

    setState(() => _isLoading = false);
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
        _targetDate.year,
        _isLeapMonth ? -_lunarMonth! : _lunarMonth!,
        _lunarDay!,
      );
      final solar = lunar.getSolar();
      _targetDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      // 无效的农历日期，保持原日期
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑倒计时' : '新建倒计时'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 标题输入
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '例如：妈妈的生日',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入标题';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 分类选择
                  _buildSectionTitle('分类', colorScheme),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CountdownCategory.values.map((category) {
                      final isSelected = _category == category;
                      return ChoiceChip(
                        label: Text(_getCategoryName(category)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _category = category);
                          }
                        },
                        avatar: Icon(
                          _getCategoryIcon(category),
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

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
                        if (!_isLunar) {
                          _updateSolarFromLunar();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 日期选择
                  if (_isLunar) _buildLunarDatePicker(colorScheme) else _buildSolarDatePicker(colorScheme),
                  const SizedBox(height: 24),

                  // 颜色选择
                  _buildSectionTitle('颜色', colorScheme),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
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
                  ),
                  const SizedBox(height: 24),

                  // 选项
                  _buildSectionTitle('选项', colorScheme),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('每年重复'),
                    subtitle: const Text('适用于生日、纪念日等'),
                    value: _repeatYearly,
                    onChanged: (value) => setState(() => _repeatYearly = value),
                  ),
                  SwitchListTile(
                    title: const Text('启用提醒'),
                    subtitle: const Text('在指定天数前提醒'),
                    value: _notifyEnabled,
                    onChanged: (value) => setState(() => _notifyEnabled = value),
                  ),

                  // 提醒天数选择
                  if (_notifyEnabled) ...[
                    const SizedBox(height: 8),
                    _buildNotifyDaysSelector(colorScheme),
                  ],

                  const SizedBox(height: 32),

                  // 保存按钮
                  FilledButton.icon(
                    onPressed: _saveCountdown,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditMode ? '保存修改' : '创建倒计时'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

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
        DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(_targetDate),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '农历 ${LunarUtils.getFullLunarString(_targetDate)}',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _targetDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          locale: const Locale('zh', 'CN'),
        );
        if (picked != null) {
          setState(() {
            _targetDate = picked;
            _updateLunarFromSolar(picked);
          });
        }
      },
    );
  }

  Widget _buildLunarDatePicker(ColorScheme colorScheme) {
    return Column(
      children: [
        ListTile(
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
            '对应公历 ${DateFormat('yyyy年M月d日').format(_targetDate)}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLunarDatePicker(context),
        ),
      ],
    );
  }

  void _showLunarDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  Text('选择农历日期', style: theme.textTheme.titleMedium),
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
              // 月份选择
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
              // 日期选择
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

  Widget _buildNotifyDaysSelector(ColorScheme colorScheme) {
    final options = [
      {'value': 0, 'label': '当天'},
      {'value': 1, 'label': '1天前'},
      {'value': 3, 'label': '3天前'},
      {'value': 7, 'label': '1周前'},
      {'value': 14, 'label': '2周前'},
      {'value': 30, 'label': '1月前'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final value = option['value'] as int;
        final label = option['label'] as String;
        final isSelected = _notifyDays.contains(value);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _notifyDays.add(value);
                _notifyDays.sort();
              } else {
                _notifyDays.remove(value);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _saveCountdown() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final countdown = CountdownModel(
      id: _existingCountdown?.id ?? '',
      title: _titleController.text.trim(),
      targetDate: _targetDate,
      isLunar: _isLunar,
      lunarMonth: _isLunar ? _lunarMonth : null,
      lunarDay: _isLunar ? _lunarDay : null,
      isLeapMonth: _isLunar ? _isLeapMonth : false,
      category: _category,
      color: _selectedColor,
      repeatYearly: _repeatYearly,
      notifyEnabled: _notifyEnabled,
      notifyDays: _notifyEnabled ? _notifyDays : null,
      createdAt: _existingCountdown?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (_isEditMode) {
      success = await _countdownService.updateCountdown(countdown);
    } else {
      final newCountdown = CountdownModel.create(
        title: countdown.title,
        targetDate: countdown.targetDate,
        isLunar: countdown.isLunar,
        lunarMonth: countdown.lunarMonth,
        lunarDay: countdown.lunarDay,
        isLeapMonth: countdown.isLeapMonth,
        category: countdown.category,
        color: countdown.color,
        repeatYearly: countdown.repeatYearly,
        notifyEnabled: countdown.notifyEnabled,
        notifyDays: countdown.notifyDays,
      );
      success = await _countdownService.createCountdown(newCountdown);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除倒计时'),
        content: Text('确定要删除「${_titleController.text}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _countdownService.deleteCountdown(widget.countdownId!);
      if (success && mounted) {
        context.pop(true);
      }
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

  IconData _getCategoryIcon(CountdownCategory category) {
    switch (category) {
      case CountdownCategory.birthday:
        return Icons.cake;
      case CountdownCategory.anniversary:
        return Icons.favorite;
      case CountdownCategory.holiday:
        return Icons.celebration;
      case CountdownCategory.deadline:
        return Icons.schedule;
      case CountdownCategory.other:
        return Icons.event;
    }
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
}
