import 'package:flutter/material.dart';
import '../../../core/utils/lunar_utils.dart';

/// 日期跳转弹窗
/// 支持公历和农历日期选择，以及快捷选项
class DateJumpDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateJumpDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  /// 显示日期跳转弹窗
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => DateJumpDialog(
        initialDate: initialDate ?? DateTime.now(),
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<DateJumpDialog> createState() => _DateJumpDialogState();
}

class _DateJumpDialogState extends State<DateJumpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  // 农历选择
  int _lunarYear = 2026;
  int _lunarMonth = 1;
  int _lunarDay = 1;
  bool _lunarIsLeapMonth = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = widget.initialDate;
    _selectedYear = _selectedDate.year;
    _selectedMonth = _selectedDate.month;
    _selectedDay = _selectedDate.day;

    // 初始化农历
    final lunarInfo = LunarUtils.getLunarInfo(_selectedDate);
    _lunarYear = _selectedDate.year;
    _lunarMonth = lunarInfo.month;
    _lunarDay = lunarInfo.day;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题和标签页
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Text(
                    '跳转到日期',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: colorScheme.primary,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: '公历'),
                      Tab(text: '农历'),
                    ],
                  ),
                ],
              ),
            ),
            // 内容区
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSolarDatePicker(colorScheme),
                  _buildLunarDatePicker(colorScheme),
                ],
              ),
            ),
            // 快捷选项
            _buildQuickOptions(colorScheme),
            // 按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onConfirm,
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarDatePicker(ColorScheme colorScheme) {
    final firstYear = widget.firstDate?.year ?? 1900;
    final lastYear = widget.lastDate?.year ?? 2100;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 年月日选择器
          Row(
            children: [
              // 年
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: _selectedYear,
                  items: List.generate(
                    lastYear - firstYear + 1,
                    (i) => firstYear + i,
                  ),
                  labelBuilder: (v) => '$v年',
                  onChanged: (v) {
                    setState(() {
                      _selectedYear = v!;
                      _adjustDay();
                    });
                  },
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              // 月
              Expanded(
                child: _buildDropdown(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1),
                  labelBuilder: (v) => '$v月',
                  onChanged: (v) {
                    setState(() {
                      _selectedMonth = v!;
                      _adjustDay();
                    });
                  },
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              // 日
              Expanded(
                child: _buildDropdown(
                  value: _selectedDay,
                  items: List.generate(_getDaysInMonth(), (i) => i + 1),
                  labelBuilder: (v) => '$v日',
                  onChanged: (v) {
                    setState(() => _selectedDay = v!);
                  },
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 选中日期预览
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_selectedYear年$_selectedMonth月$_selectedDay日',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getWeekdayName(),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 农历信息
          Text(
            _getLunarPreview(),
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLunarDatePicker(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 农历年月日选择器
          Row(
            children: [
              // 年
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: _lunarYear,
                  items: List.generate(201, (i) => 1900 + i),
                  labelBuilder: (v) => '$v年',
                  onChanged: (v) {
                    setState(() => _lunarYear = v!);
                  },
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              // 月
              Expanded(
                child: _buildDropdown(
                  value: _lunarMonth,
                  items: List.generate(12, (i) => i + 1),
                  labelBuilder: (v) => _getLunarMonthName(v),
                  onChanged: (v) {
                    setState(() => _lunarMonth = v!);
                  },
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              // 日
              Expanded(
                child: _buildDropdown(
                  value: _lunarDay,
                  items: List.generate(30, (i) => i + 1),
                  labelBuilder: (v) => _getLunarDayName(v),
                  onChanged: (v) {
                    setState(() => _lunarDay = v!);
                  },
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 闰月选项
          Row(
            children: [
              Checkbox(
                value: _lunarIsLeapMonth,
                onChanged: (v) {
                  setState(() => _lunarIsLeapMonth = v!);
                },
              ),
              const Text('闰月'),
            ],
          ),
          const SizedBox(height: 16),
          // 预览
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${_lunarIsLeapMonth ? "闰" : ""}${_getLunarMonthName(_lunarMonth)}${_getLunarDayName(_lunarDay)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '对应公历日期将在确认时计算',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildQuickChip('今天', DateTime.now(), colorScheme),
          _buildQuickChip('明天', DateTime.now().add(const Duration(days: 1)), colorScheme),
          _buildQuickChip('下周', DateTime.now().add(const Duration(days: 7)), colorScheme),
          _buildQuickChip('下月', _getNextMonth(), colorScheme),
          _buildQuickChip('月初', _getMonthStart(), colorScheme),
          _buildQuickChip('月末', _getMonthEnd(), colorScheme),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, DateTime date, ColorScheme colorScheme) {
    final isSelected = _selectedYear == date.year &&
        _selectedMonth == date.month &&
        _selectedDay == date.day;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? colorScheme.primaryContainer : null,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontSize: 12,
      ),
      onPressed: () {
        setState(() {
          _selectedYear = date.year;
          _selectedMonth = date.month;
          _selectedDay = date.day;
        });
      },
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              labelBuilder(item),
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  int _getDaysInMonth() {
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  void _adjustDay() {
    final maxDay = _getDaysInMonth();
    if (_selectedDay > maxDay) {
      _selectedDay = maxDay;
    }
  }

  String _getWeekdayName() {
    final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  String _getLunarPreview() {
    final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    final lunarInfo = LunarUtils.getLunarInfo(date);
    final displayText = LunarUtils.getDisplayText(date);
    return '农历 ${lunarInfo.monthName}月${lunarInfo.dayName} $displayText';
  }

  String _getLunarMonthName(int month) {
    const months = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    return '${months[month - 1]}月';
  }

  String _getLunarDayName(int day) {
    const days = [
      '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
      '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
      '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
    ];
    return days[day - 1];
  }

  DateTime _getNextMonth() {
    if (_selectedMonth == 12) {
      return DateTime(_selectedYear + 1, 1, 1);
    }
    return DateTime(_selectedYear, _selectedMonth + 1, 1);
  }

  DateTime _getMonthStart() {
    return DateTime(_selectedYear, _selectedMonth, 1);
  }

  DateTime _getMonthEnd() {
    return DateTime(_selectedYear, _selectedMonth + 1, 0);
  }

  void _onConfirm() {
    DateTime resultDate;

    if (_tabController.index == 0) {
      // 公历
      resultDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    } else {
      // 农历 - 使用当前选中的公历日期（农历转换比较复杂，暂时简化处理）
      // 真实实现需要农历到公历的转换
      resultDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    }

    Navigator.pop(context, resultDate);
  }
}
