import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/models/recurrence_rule.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../core/utils/rrule_parser.dart';

/// 日历视图模式
enum CalendarViewMode {
  month,  // 月视图
  week,   // 周视图
  day,    // 日视图
}

/// 日历视图模型 - 管理日历视图状态
class CalendarViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  final CalendarRepository _calendarRepository;

  CalendarViewModel({
    EventRepository? eventRepository,
    CalendarRepository? calendarRepository,
  })  : _eventRepository = eventRepository ?? EventRepository(),
        _calendarRepository = calendarRepository ?? CalendarRepository() {
    _init();
  }

  // ==================== 状态字段 ====================

  /// 当前选中日期
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  /// 当前聚焦日期（用于月视图的月份导航）
  DateTime _focusedDate = DateTime.now();
  DateTime get focusedDate => _focusedDate;

  /// 当前视图模式
  CalendarViewMode _viewMode = CalendarViewMode.month;
  CalendarViewMode get viewMode => _viewMode;

  /// 是否正在加载
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// 事件列表（按日期分组）
  Map<DateTime, List<EventInstance>> _eventsMap = {};
  Map<DateTime, List<EventInstance>> get eventsMap => _eventsMap;

  /// 可见日历 ID 列表
  List<String> _visibleCalendarIds = [];
  List<String> get visibleCalendarIds => _visibleCalendarIds;

  /// 当前日期范围（用于事件加载）
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // ==================== 初始化 ====================

  Future<void> _init() async {
    await _loadVisibleCalendars();
    await _loadEventsForCurrentRange();
    _isLoading = false;
    notifyListeners();
  }

  /// 加载可见日历列表
  Future<void> _loadVisibleCalendars() async {
    final calendars = await _calendarRepository.getVisibleCalendars();
    _visibleCalendarIds = calendars.map((c) => c.id).toList();
  }

  // ==================== 日期操作 ====================

  /// 选择日期
  void selectDate(DateTime date) {
    _selectedDate = _normalizeDate(date);
    notifyListeners();
  }

  /// 设置聚焦日期（切换月份时使用）
  void setFocusedDate(DateTime date) {
    _focusedDate = date;
    _updateDateRange();
    notifyListeners();
  }

  /// 跳转到今天
  void goToToday() {
    final today = DateTime.now();
    _selectedDate = _normalizeDate(today);
    _focusedDate = today;
    _updateDateRange();
    notifyListeners();
  }

  /// 切换到上一个周期（月/周/日）
  void goToPrevious() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
        break;
      case CalendarViewMode.week:
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
        break;
      case CalendarViewMode.day:
        _focusedDate = _focusedDate.subtract(const Duration(days: 1));
        _selectedDate = _normalizeDate(_focusedDate);
        break;
    }
    _updateDateRange();
    notifyListeners();
  }

  /// 切换到下一个周期（月/周/日）
  void goToNext() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
        break;
      case CalendarViewMode.week:
        _focusedDate = _focusedDate.add(const Duration(days: 7));
        break;
      case CalendarViewMode.day:
        _focusedDate = _focusedDate.add(const Duration(days: 1));
        _selectedDate = _normalizeDate(_focusedDate);
        break;
    }
    _updateDateRange();
    notifyListeners();
  }

  /// 跳转到指定日期
  void jumpToDate(DateTime date) {
    _selectedDate = _normalizeDate(date);
    _focusedDate = date;
    _updateDateRange();
    notifyListeners();
  }

  // ==================== 视图模式 ====================

  /// 切换视图模式
  void setViewMode(CalendarViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      _updateDateRange();
      notifyListeners();
    }
  }

  // ==================== 事件加载 ====================

  /// 更新日期范围并加载事件
  Future<void> _updateDateRange() async {
    final range = _calculateDateRange();
    if (range.$1 != _rangeStart || range.$2 != _rangeEnd) {
      _rangeStart = range.$1;
      _rangeEnd = range.$2;
      await _loadEventsForCurrentRange();
    }
  }

  /// 计算当前视图的日期范围
  (DateTime, DateTime) _calculateDateRange() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        // 月视图：包含当月前后各一周的日期
        final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
        final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
        final start = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
        final end = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday % 7));
        return (start, end);

      case CalendarViewMode.week:
        // 周视图：当前周
        final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return (_normalizeDate(weekStart), _normalizeDate(weekEnd));

      case CalendarViewMode.day:
        // 日视图：当天
        final dayStart = _normalizeDate(_focusedDate);
        final dayEnd = dayStart.add(const Duration(days: 1));
        return (dayStart, dayEnd);
    }
  }

  /// 加载当前范围内的事件
  Future<void> _loadEventsForCurrentRange() async {
    if (_rangeStart == null || _rangeEnd == null) {
      final range = _calculateDateRange();
      _rangeStart = range.$1;
      _rangeEnd = range.$2;
    }

    try {
      // 获取范围内的事件
      final events = await _eventRepository.getEventsInRange(
        _rangeStart!,
        _rangeEnd!,
        calendarIds: _visibleCalendarIds.isNotEmpty ? _visibleCalendarIds : null,
      );

      // 展开重复事件并按日期分组
      _eventsMap = _expandAndGroupEvents(events, _rangeStart!, _rangeEnd!);
      notifyListeners();
    } catch (e) {
      debugPrint('加载事件失败: $e');
    }
  }

  /// 展开重复事件并按日期分组
  Map<DateTime, List<EventInstance>> _expandAndGroupEvents(
    List<EventModel> events,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final Map<DateTime, List<EventInstance>> result = {};

    for (final event in events) {
      if (event.isRecurring) {
        // 重复事件：生成实例
        final rule = RecurrenceRule.fromRRuleString(event.rrule!);
        final occurrences = RRuleParser.getOccurrences(
          rule,
          event.dtStart,
          rangeStart,
          rangeEnd,
          exDates: event.exDates,
        );

        for (final occurrence in occurrences) {
          final dateKey = _normalizeDate(occurrence);
          final instance = EventInstance(
            event: event,
            instanceStart: occurrence,
            instanceEnd: event.dtEnd != null
                ? occurrence.add(event.duration)
                : occurrence.add(const Duration(hours: 1)),
            isException: false,
          );

          result.putIfAbsent(dateKey, () => []);
          result[dateKey]!.add(instance);
        }
      } else {
        // 非重复事件
        final dateKey = _normalizeDate(event.dtStart);
        final instance = EventInstance.fromEvent(event);

        result.putIfAbsent(dateKey, () => []);
        result[dateKey]!.add(instance);
      }
    }

    // 按开始时间排序
    for (final instances in result.values) {
      instances.sort((a, b) => a.instanceStart.compareTo(b.instanceStart));
    }

    return result;
  }

  /// 刷新事件数据
  Future<void> refreshEvents() async {
    _isLoading = true;
    notifyListeners();

    await _loadVisibleCalendars();
    await _loadEventsForCurrentRange();

    _isLoading = false;
    notifyListeners();
  }

  // ==================== 事件查询 ====================

  /// 获取指定日期的事件
  List<EventInstance> getEventsForDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _eventsMap[dateKey] ?? [];
  }

  /// 获取选中日期的事件
  List<EventInstance> get selectedDateEvents => getEventsForDate(_selectedDate);

  /// 检查指定日期是否有事件
  bool hasEventsOnDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _eventsMap.containsKey(dateKey) && _eventsMap[dateKey]!.isNotEmpty;
  }

  /// 获取指定日期的事件数量
  int getEventCountForDate(DateTime date) {
    return getEventsForDate(date).length;
  }

  // ==================== 日历可见性 ====================

  /// 更新可见日历
  Future<void> updateVisibleCalendars() async {
    await _loadVisibleCalendars();
    await _loadEventsForCurrentRange();
  }

  // ==================== 事件拖拽更新 ====================

  /// 更新事件时间（拖拽后）
  /// [eventInstance] 要更新的事件实例
  /// [newStart] 新的开始时间
  /// [newEnd] 新的结束时间
  /// 返回是否成功
  Future<bool> updateEventTime(
    EventInstance eventInstance,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    try {
      final event = eventInstance.event;

      // 如果是重复事件的实例，需要特殊处理
      if (event.isRecurring) {
        // 对于重复事件，可以选择：
        // 1. 只修改此实例（添加 EXDATE 并创建新的独立事件）
        // 2. 修改整个系列
        // 目前采用方案1：只修改此实例
        await _updateRecurringEventInstance(
          event,
          eventInstance.instanceStart,
          newStart,
          newEnd,
        );
      } else {
        // 非重复事件：直接更新
        final updatedEvent = event.copyWith(
          dtStart: newStart,
          dtEnd: newEnd,
          updatedAt: DateTime.now(),
        );
        await _eventRepository.updateEvent(updatedEvent);
      }

      // 刷新事件数据
      await _loadEventsForCurrentRange();
      return true;
    } catch (e) {
      debugPrint('更新事件时间失败: $e');
      return false;
    }
  }

  /// 更新重复事件的单个实例
  Future<void> _updateRecurringEventInstance(
    EventModel event,
    DateTime originalInstanceStart,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    // 将原实例添加到排除日期
    await _eventRepository.addExcludeDate(event.uid, originalInstanceStart);

    // 创建新的独立事件（不重复）
    final newEvent = EventModel.create(
      calendarId: event.calendarId,
      summary: event.summary,
      description: event.description,
      location: event.location,
      dtStart: newStart,
      dtEnd: newEnd,
      isAllDay: event.isAllDay,
      // 不复制重复规则
      color: event.color,
      priority: event.priority,
      url: event.url,
    );

    await _eventRepository.insertEvent(newEvent);
  }

  // ==================== 工具方法 ====================

  /// 标准化日期（去除时间部分）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 检查是否是今天
  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// 检查是否是选中日期
  bool isSelectedDate(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  /// 检查日期是否在当前月份
  bool isInCurrentMonth(DateTime date) {
    return date.month == _focusedDate.month && date.year == _focusedDate.year;
  }

  /// 获取当前月份标题
  String get currentMonthTitle {
    return '${_focusedDate.year}年${_focusedDate.month}月';
  }

  /// 获取当前周标题
  String get currentWeekTitle {
    final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month == weekEnd.month) {
      return '${weekStart.year}年${weekStart.month}月 第${_getWeekOfMonth(weekStart)}周';
    } else {
      return '${weekStart.month}月${weekStart.day}日 - ${weekEnd.month}月${weekEnd.day}日';
    }
  }

  /// 获取当前日期标题
  String get currentDayTitle {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[_focusedDate.weekday - 1];
    return '${_focusedDate.month}月${_focusedDate.day}日 $weekday';
  }

  /// 获取日期在月份中的周数
  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysDiff = date.difference(firstDayOfMonth).inDays;
    return (daysDiff / 7).floor() + 1;
  }
}
