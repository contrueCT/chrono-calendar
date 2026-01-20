import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/models/countdown_model.dart';
import '../data/models/todo_model.dart';
import '../data/models/calendar_display_item.dart';
import '../data/models/recurrence_rule.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../services/countdown_service.dart';
import '../services/todo_service.dart';
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
  final CountdownService _countdownService;
  final TodoService _todoService;

  /// 是否已销毁
  bool _isDisposed = false;

  /// 初始化错误信息
  String? _initError;
  String? get initError => _initError;

  CalendarViewModel({
    EventRepository? eventRepository,
    CalendarRepository? calendarRepository,
    CountdownService? countdownService,
    TodoService? todoService,
  })  : _eventRepository = eventRepository ?? EventRepository(),
        _calendarRepository = calendarRepository ?? CalendarRepository(),
        _countdownService = countdownService ?? CountdownService(),
        _todoService = todoService ?? TodoService() {
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

  /// 倒计时列表（按日期分组）
  Map<DateTime, List<CountdownDisplayItem>> _countdownsMap = {};

  /// 待办列表（按日期分组）
  Map<DateTime, List<TodoDisplayItem>> _todosMap = {};

  /// 可见日历 ID 列表
  List<String> _visibleCalendarIds = [];
  List<String> get visibleCalendarIds => _visibleCalendarIds;

  /// 当前日期范围（用于事件加载）
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // ==================== 初始化 ====================

  Future<void> _init() async {
    try {
      await _loadVisibleCalendars();
      if (_isDisposed) return;
      await _loadEventsForCurrentRange();
      if (_isDisposed) return;
    } catch (e) {
      _initError = '初始化日历失败: $e';
      debugPrint(_initError);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// 安全地通知监听器（检查是否已销毁）
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 加载可见日历列表
  Future<void> _loadVisibleCalendars() async {
    final calendars = await _calendarRepository.getVisibleCalendars();
    _visibleCalendarIds = calendars.map((c) => c.id).toList();
  }

  // ==================== 日期操作 ====================

  /// 选择日期
  void selectDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    if (_selectedDate == normalizedDate) return;
    _selectedDate = normalizedDate;
    _safeNotifyListeners();
  }

  /// 设置聚焦日期（切换月份时使用）
  void setFocusedDate(DateTime date) {
    // 检查月份是否真的改变（对于月视图最重要）
    if (_focusedDate.year == date.year && _focusedDate.month == date.month) {
      return;
    }
    _focusedDate = date;
    _updateDateRange();
    _safeNotifyListeners();
  }

  /// 跳转到今天
  void goToToday() {
    final today = DateTime.now();
    final normalizedToday = _normalizeDate(today);

    // 检查是否已经在今天
    final alreadyOnToday = _selectedDate == normalizedToday &&
        _focusedDate.year == today.year &&
        _focusedDate.month == today.month;

    if (alreadyOnToday) return;

    _selectedDate = normalizedToday;
    _focusedDate = today;
    _updateDateRange();
    _safeNotifyListeners();
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
    _safeNotifyListeners();
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
    _safeNotifyListeners();
  }

  /// 跳转到指定日期
  void jumpToDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    // 检查是否已经在该日期
    final alreadyOnDate = _selectedDate == normalizedDate &&
        _focusedDate.year == date.year &&
        _focusedDate.month == date.month;

    if (alreadyOnDate) return;

    _selectedDate = normalizedDate;
    _focusedDate = date;
    _updateDateRange();
    _safeNotifyListeners();
  }

  // ==================== 视图模式 ====================

  /// 切换视图模式
  void setViewMode(CalendarViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      _updateDateRange();
      _safeNotifyListeners();
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

  /// 加载当前范围内的事件、倒计时和待办
  ///
  /// [silent] 为 true 时不触发 notifyListeners（用于批量操作）
  Future<void> _loadEventsForCurrentRange({bool silent = false}) async {
    if (_rangeStart == null || _rangeEnd == null) {
      final range = _calculateDateRange();
      _rangeStart = range.$1;
      _rangeEnd = range.$2;
    }

    try {
      // 并行加载事件、倒计时和待办
      await Future.wait([
        _loadEvents(),
        _loadCountdowns(),
        _loadTodos(),
      ]);

      if (!silent) {
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('加载日历数据失败: $e');
    }
  }

  /// 加载事件
  Future<void> _loadEvents() async {
    try {
      // 获取范围内的事件
      final events = await _eventRepository.getEventsInRange(
        _rangeStart!,
        _rangeEnd!,
        calendarIds: _visibleCalendarIds.isNotEmpty ? _visibleCalendarIds : null,
      );

      // 展开重复事件并按日期分组
      _eventsMap = _expandAndGroupEvents(events, _rangeStart!, _rangeEnd!);
    } catch (e) {
      debugPrint('加载事件失败: $e');
    }
  }

  /// 加载倒计时
  Future<void> _loadCountdowns() async {
    try {
      final result = await _countdownService.getAllCountdowns();
      if (result.isFailure) {
        debugPrint('加载倒计时失败: ${result.errorOrNull}');
        return;
      }

      final countdowns = result.valueOrNull ?? [];
      _countdownsMap = _groupCountdownsByDate(countdowns, _rangeStart!, _rangeEnd!);
    } catch (e) {
      debugPrint('加载倒计时失败: $e');
    }
  }

  /// 加载待办
  Future<void> _loadTodos() async {
    try {
      // 获取有截止日期的待办
      final result = await _todoService.getAllTodos();
      if (result.isFailure) {
        debugPrint('加载待办失败: ${result.errorOrNull}');
        return;
      }

      final todos = result.valueOrNull ?? [];
      _todosMap = _groupTodosByDate(todos, _rangeStart!, _rangeEnd!);
    } catch (e) {
      debugPrint('加载待办失败: $e');
    }
  }

  /// 按日期分组倒计时
  Map<DateTime, List<CountdownDisplayItem>> _groupCountdownsByDate(
    List<CountdownModel> countdowns,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final Map<DateTime, List<CountdownDisplayItem>> result = {};

    for (final countdown in countdowns) {
      // 获取当前年份的目标日期
      final targetDate = countdown.getNextTargetDate();
      final dateKey = _normalizeDate(targetDate);

      // 检查是否在范围内
      if (dateKey.isBefore(rangeStart) || dateKey.isAfter(rangeEnd)) {
        continue;
      }

      final displayItem = CountdownDisplayItem(
        countdown: countdown,
        instanceDate: targetDate,
      );

      result.putIfAbsent(dateKey, () => []);
      result[dateKey]!.add(displayItem);
    }

    return result;
  }

  /// 按日期分组待办
  Map<DateTime, List<TodoDisplayItem>> _groupTodosByDate(
    List<TodoModel> todos,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final Map<DateTime, List<TodoDisplayItem>> result = {};

    for (final todo in todos) {
      // 只处理有截止日期的待办
      if (todo.dueDate == null) continue;

      final dateKey = _normalizeDate(todo.dueDate!);

      // 检查是否在范围内
      if (dateKey.isBefore(rangeStart) || dateKey.isAfter(rangeEnd)) {
        continue;
      }

      final displayItem = TodoDisplayItem(todo);

      result.putIfAbsent(dateKey, () => []);
      result[dateKey]!.add(displayItem);
    }

    // 按优先级和时间排序
    for (final items in result.values) {
      items.sort((a, b) {
        // 未完成的排在前面
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        // 高优先级排在前面
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        // 按时间排序
        return a.startTime.compareTo(b.startTime);
      });
    }

    return result;
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
    // 避免重复刷新
    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      await _loadVisibleCalendars();
      if (_isDisposed) return;
      // 使用 silent 模式避免重复通知
      await _loadEventsForCurrentRange(silent: true);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ==================== 事件查询 ====================

  /// 获取指定日期的事件
  List<EventInstance> getEventsForDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _eventsMap[dateKey] ?? [];
  }

  /// 获取指定日期的倒计时
  List<CountdownDisplayItem> getCountdownsForDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _countdownsMap[dateKey] ?? [];
  }

  /// 获取指定日期的待办
  List<TodoDisplayItem> getTodosForDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _todosMap[dateKey] ?? [];
  }

  /// 获取指定日期的所有日历项（事件 + 倒计时 + 待办）
  List<CalendarDisplayItem> getItemsForDate(DateTime date) {
    final dateKey = _normalizeDate(date);

    final List<CalendarDisplayItem> items = [];

    // 添加倒计时（排在最前面）
    final countdowns = _countdownsMap[dateKey] ?? [];
    items.addAll(countdowns);

    // 添加事件
    final events = _eventsMap[dateKey] ?? [];
    items.addAll(events.map((e) => EventDisplayItem(e)));

    // 添加待办
    final todos = _todosMap[dateKey] ?? [];
    items.addAll(todos);

    // 按类型和时间排序
    items.sort(CalendarDisplayItemComparator.compareByTypeAndTime);

    return items;
  }

  /// 获取选中日期的事件
  List<EventInstance> get selectedDateEvents => getEventsForDate(_selectedDate);

  /// 获取选中日期的所有日历项
  List<CalendarDisplayItem> get selectedDateItems => getItemsForDate(_selectedDate);

  /// 检查指定日期是否有事件
  bool hasEventsOnDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _eventsMap.containsKey(dateKey) && _eventsMap[dateKey]!.isNotEmpty;
  }

  /// 检查指定日期是否有倒计时
  bool hasCountdownsOnDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _countdownsMap.containsKey(dateKey) && _countdownsMap[dateKey]!.isNotEmpty;
  }

  /// 检查指定日期是否有待办
  bool hasTodosOnDate(DateTime date) {
    final dateKey = _normalizeDate(date);
    return _todosMap.containsKey(dateKey) && _todosMap[dateKey]!.isNotEmpty;
  }

  /// 检查指定日期是否有任何日历项（事件、倒计时或待办）
  bool hasItemsOnDate(DateTime date) {
    return hasEventsOnDate(date) || hasCountdownsOnDate(date) || hasTodosOnDate(date);
  }

  /// 获取指定日期的事件数量
  int getEventCountForDate(DateTime date) {
    return getEventsForDate(date).length;
  }

  /// 获取指定日期的所有日历项数量
  int getItemCountForDate(DateTime date) {
    return getItemsForDate(date).length;
  }

  // ==================== 日历可见性 ====================

  /// 更新可见日历
  Future<void> updateVisibleCalendars() async {
    await _loadVisibleCalendars();
    // 加载事件并触发通知
    await _loadEventsForCurrentRange(silent: false);
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
