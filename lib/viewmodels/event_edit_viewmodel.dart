import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/models/calendar_model.dart';
import '../data/models/reminder_model.dart';
import '../data/models/recurrence_rule.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../core/constants/color_constants.dart';

/// 事件编辑 ViewModel
class EventEditViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  final CalendarRepository _calendarRepository;

  /// 是否为编辑模式（否则为创建模式）
  final bool isEditMode;

  /// 原始事件（编辑模式下）
  final EventModel? originalEvent;

  // ==================== 表单状态 ====================

  /// 标题
  String _summary = '';
  String get summary => _summary;

  /// 描述
  String? _description;
  String? get description => _description;

  /// 地点
  String? _location;
  String? get location => _location;

  /// 是否全天事件
  bool _isAllDay = false;
  bool get isAllDay => _isAllDay;

  /// 开始时间
  DateTime _dtStart = DateTime.now();
  DateTime get dtStart => _dtStart;

  /// 结束时间
  DateTime _dtEnd = DateTime.now().add(const Duration(hours: 1));
  DateTime get dtEnd => _dtEnd;

  /// 重复规则
  RecurrenceRule? _recurrenceRule;
  RecurrenceRule? get recurrenceRule => _recurrenceRule;

  /// 提醒列表（存储提前分钟数）
  List<int> _reminderMinutes = [15]; // 默认提前15分钟
  List<int> get reminderMinutes => List.unmodifiable(_reminderMinutes);

  /// 事件颜色
  int _color = ColorConstants.defaultEventColor.value;
  int get color => _color;

  /// 关联 URL
  String? _url;
  String? get url => _url;

  /// 选中的日历 ID
  String? _selectedCalendarId;
  String? get selectedCalendarId => _selectedCalendarId;

  // ==================== 日历列表 ====================

  List<CalendarModel> _calendars = [];
  List<CalendarModel> get calendars => List.unmodifiable(_calendars);

  CalendarModel? get selectedCalendar {
    if (_selectedCalendarId == null) return null;
    try {
      return _calendars.firstWhere((c) => c.id == _selectedCalendarId);
    } catch (_) {
      return null;
    }
  }

  // ==================== 加载状态 ====================

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================== 构造函数 ====================

  EventEditViewModel({
    EventRepository? eventRepository,
    CalendarRepository? calendarRepository,
    this.originalEvent,
    DateTime? initialDate,
  })  : _eventRepository = eventRepository ?? EventRepository(),
        _calendarRepository = calendarRepository ?? CalendarRepository(),
        isEditMode = originalEvent != null {
    // 初始化表单状态
    if (originalEvent != null) {
      _initFromEvent(originalEvent!);
    } else if (initialDate != null) {
      _initFromDate(initialDate);
    }
    // 加载日历列表
    _loadCalendars();
  }

  /// 从现有事件初始化
  void _initFromEvent(EventModel event) {
    _summary = event.summary;
    _description = event.description;
    _location = event.location;
    _isAllDay = event.isAllDay;
    _dtStart = event.dtStart;
    _dtEnd = event.dtEnd ?? event.dtStart.add(const Duration(hours: 1));
    _color = event.color ?? ColorConstants.defaultEventColor.value;
    _url = event.url;
    _selectedCalendarId = event.calendarId;

    // 解析重复规则
    if (event.rrule != null && event.rrule!.isNotEmpty) {
      try {
        _recurrenceRule = RecurrenceRule.fromRRuleString(event.rrule!);
      } catch (e) {
        debugPrint('解析重复规则失败: $e');
      }
    }

    // 加载提醒（异步）
    _loadReminders(event.uid);
  }

  /// 从日期初始化（创建新事件）
  void _initFromDate(DateTime date) {
    // 如果是今天，从下一个整点开始
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      _dtStart = DateTime(now.year, now.month, now.day, now.hour + 1);
    } else {
      _dtStart = DateTime(date.year, date.month, date.day, 9); // 默认9点
    }
    _dtEnd = _dtStart.add(const Duration(hours: 1));
  }

  /// 加载日历列表
  Future<void> _loadCalendars() async {
    _isLoading = true;
    notifyListeners();

    try {
      _calendars = await _calendarRepository.getAllCalendars();

      // 如果没有选中的日历，选择默认日历
      if (_selectedCalendarId == null && _calendars.isNotEmpty) {
        final defaultCalendar = _calendars.firstWhere(
          (c) => c.isDefault,
          orElse: () => _calendars.first,
        );
        _selectedCalendarId = defaultCalendar.id;
      }
    } catch (e) {
      _errorMessage = '加载日历列表失败';
      debugPrint('加载日历列表失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载事件提醒
  Future<void> _loadReminders(String eventUid) async {
    try {
      final reminders = await _eventRepository.getRemindersForEvent(eventUid);
      _reminderMinutes = reminders.map((r) => r.triggerMinutes).toList();
      if (_reminderMinutes.isEmpty) {
        _reminderMinutes = [15]; // 默认
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载提醒失败: $e');
    }
  }

  // ==================== 表单操作 ====================

  /// 设置标题
  void setSummary(String value) {
    _summary = value;
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置描述
  void setDescription(String? value) {
    _description = value?.isEmpty == true ? null : value;
    notifyListeners();
  }

  /// 设置地点
  void setLocation(String? value) {
    _location = value?.isEmpty == true ? null : value;
    notifyListeners();
  }

  /// 设置是否全天事件
  void setIsAllDay(bool value) {
    _isAllDay = value;
    if (value) {
      // 全天事件：时间设置为当天开始
      _dtStart = DateTime(_dtStart.year, _dtStart.month, _dtStart.day);
      _dtEnd = DateTime(_dtEnd.year, _dtEnd.month, _dtEnd.day).add(const Duration(days: 1));
    }
    notifyListeners();
  }

  /// 设置开始时间
  void setDtStart(DateTime value) {
    _dtStart = value;
    // 确保结束时间不早于开始时间
    if (_dtEnd.isBefore(_dtStart)) {
      _dtEnd = _dtStart.add(const Duration(hours: 1));
    }
    notifyListeners();
  }

  /// 设置结束时间
  void setDtEnd(DateTime value) {
    if (value.isAfter(_dtStart)) {
      _dtEnd = value;
      notifyListeners();
    }
  }

  /// 设置开始日期（保持时间不变）
  void setStartDate(DateTime date) {
    _dtStart = DateTime(
      date.year,
      date.month,
      date.day,
      _dtStart.hour,
      _dtStart.minute,
    );
    // 如果结束日期早于开始日期，同步调整
    if (_dtEnd.isBefore(_dtStart)) {
      _dtEnd = DateTime(
        date.year,
        date.month,
        date.day,
        _dtEnd.hour,
        _dtEnd.minute,
      );
      if (_dtEnd.isBefore(_dtStart)) {
        _dtEnd = _dtStart.add(const Duration(hours: 1));
      }
    }
    notifyListeners();
  }

  /// 设置开始时间（保持日期不变）
  void setStartTime(int hour, int minute) {
    _dtStart = DateTime(
      _dtStart.year,
      _dtStart.month,
      _dtStart.day,
      hour,
      minute,
    );
    // 如果结束时间早于开始时间，调整结束时间
    if (_dtEnd.isBefore(_dtStart) || _dtEnd.isAtSameMomentAs(_dtStart)) {
      _dtEnd = _dtStart.add(const Duration(hours: 1));
    }
    notifyListeners();
  }

  /// 设置结束日期（保持时间不变）
  void setEndDate(DateTime date) {
    final newEnd = DateTime(
      date.year,
      date.month,
      date.day,
      _dtEnd.hour,
      _dtEnd.minute,
    );
    if (newEnd.isAfter(_dtStart)) {
      _dtEnd = newEnd;
      notifyListeners();
    }
  }

  /// 设置结束时间（保持日期不变）
  void setEndTime(int hour, int minute) {
    final newEnd = DateTime(
      _dtEnd.year,
      _dtEnd.month,
      _dtEnd.day,
      hour,
      minute,
    );
    if (newEnd.isAfter(_dtStart)) {
      _dtEnd = newEnd;
      notifyListeners();
    }
  }

  /// 设置重复规则
  void setRecurrenceRule(RecurrenceRule? rule) {
    _recurrenceRule = rule;
    notifyListeners();
  }

  /// 添加提醒
  void addReminder(int minutes) {
    if (!_reminderMinutes.contains(minutes)) {
      _reminderMinutes.add(minutes);
      _reminderMinutes.sort();
      notifyListeners();
    }
  }

  /// 移除提醒
  void removeReminder(int minutes) {
    _reminderMinutes.remove(minutes);
    notifyListeners();
  }

  /// 清空所有提醒
  void clearReminders() {
    _reminderMinutes.clear();
    notifyListeners();
  }

  /// 设置颜色
  void setColor(int value) {
    _color = value;
    notifyListeners();
  }

  /// 设置 URL
  void setUrl(String? value) {
    _url = value?.isEmpty == true ? null : value;
    notifyListeners();
  }

  /// 设置选中的日历
  void setSelectedCalendar(String calendarId) {
    _selectedCalendarId = calendarId;
    notifyListeners();
  }

  // ==================== 验证 ====================

  /// 验证表单
  bool validate() {
    if (_summary.trim().isEmpty) {
      _errorMessage = '请输入事件标题';
      notifyListeners();
      return false;
    }

    if (_selectedCalendarId == null) {
      _errorMessage = '请选择日历';
      notifyListeners();
      return false;
    }

    if (!_isAllDay && _dtEnd.isBefore(_dtStart)) {
      _errorMessage = '结束时间不能早于开始时间';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    return true;
  }

  /// 标题是否有效
  bool get isSummaryValid => _summary.trim().isNotEmpty;

  // ==================== 保存 ====================

  /// 保存事件
  Future<bool> save() async {
    if (!validate()) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final event = _buildEvent();

      if (isEditMode) {
        await _eventRepository.updateEvent(event);
      } else {
        await _eventRepository.insertEvent(event);
      }

      // 更新提醒
      await _saveReminders(event.uid);

      return true;
    } catch (e) {
      _errorMessage = isEditMode ? '更新事件失败' : '创建事件失败';
      debugPrint('保存事件失败: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 构建事件模型
  EventModel _buildEvent() {
    final now = DateTime.now();

    if (isEditMode && originalEvent != null) {
      return originalEvent!.copyWith(
        calendarId: _selectedCalendarId,
        summary: _summary.trim(),
        description: _description,
        location: _location,
        dtStart: _dtStart,
        dtEnd: _isAllDay ? null : _dtEnd,
        isAllDay: _isAllDay,
        rrule: _recurrenceRule?.toRRuleString(),
        color: _color,
        url: _url,
        updatedAt: now,
      );
    } else {
      return EventModel.create(
        calendarId: _selectedCalendarId!,
        summary: _summary.trim(),
        description: _description,
        location: _location,
        dtStart: _dtStart,
        dtEnd: _isAllDay ? null : _dtEnd,
        isAllDay: _isAllDay,
        rrule: _recurrenceRule?.toRRuleString(),
        color: _color,
        url: _url,
      );
    }
  }

  /// 保存提醒
  Future<void> _saveReminders(String eventUid) async {
    // 生成通知 ID（使用事件 UID 的 hashCode 作为基础）
    final baseNotificationId = eventUid.hashCode.abs();

    final reminders = _reminderMinutes.asMap().entries.map((entry) {
      return ReminderModel(
        eventUid: eventUid,
        triggerMinutes: entry.value,
        notificationId: baseNotificationId + entry.key,
      );
    }).toList();

    await _eventRepository.updateReminders(eventUid, reminders);
  }

  // ==================== 重复规则便捷方法 ====================

  /// 获取重复规则显示文本
  String get recurrenceRuleText {
    if (_recurrenceRule == null) return '不重复';
    return _recurrenceRule!.description;
  }

  /// 是否设置了重复
  bool get hasRecurrence => _recurrenceRule != null;

  /// 清除重复规则
  void clearRecurrenceRule() {
    _recurrenceRule = null;
    notifyListeners();
  }
}
