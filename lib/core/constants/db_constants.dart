/// 数据库常量
class DbConstants {
  DbConstants._();

  // ========== 数据库配置 ==========
  static const String databaseName = 'chrono_calendar.db';
  static const int databaseVersion = 3;  // v3: 添加待办表

  // ========== 表名 ==========
  static const String tableCalendars = 'calendars';
  static const String tableEvents = 'events';
  static const String tableReminders = 'reminders';
  static const String tableEventCache = 'event_cache';
  static const String tableCountdowns = 'countdowns';
  static const String tableSearchHistory = 'search_history';
  static const String tableWeatherCache = 'weather_cache';
  static const String tableLlmConfig = 'llm_config';
  static const String tableTodos = 'todos';

  // ========== 日历表字段 ==========
  static const String columnCalendarId = 'id';
  static const String columnCalendarName = 'name';
  static const String columnCalendarColor = 'color';
  static const String columnCalendarIsVisible = 'is_visible';
  static const String columnCalendarIsDefault = 'is_default';
  static const String columnCalendarIsSubscription = 'is_subscription';
  static const String columnCalendarSubscriptionUrl = 'subscription_url';
  static const String columnCalendarSyncInterval = 'sync_interval';
  static const String columnCalendarLastSyncTime = 'last_sync_time';
  static const String columnCalendarCreatedAt = 'created_at';

  // ========== 事件表字段 ==========
  static const String columnEventUid = 'uid';
  static const String columnEventCalendarId = 'calendar_id';
  static const String columnEventSummary = 'summary';
  static const String columnEventDescription = 'description';
  static const String columnEventLocation = 'location';
  static const String columnEventDtstart = 'dtstart';
  static const String columnEventDtend = 'dtend';
  static const String columnEventIsAllDay = 'is_all_day';
  static const String columnEventRrule = 'rrule';
  static const String columnEventExdates = 'exdates';
  static const String columnEventColor = 'color';
  static const String columnEventStatus = 'status';
  static const String columnEventPriority = 'priority';
  static const String columnEventUrl = 'url';
  static const String columnEventCreatedAt = 'created_at';
  static const String columnEventUpdatedAt = 'updated_at';
  static const String columnEventSequence = 'sequence';

  // ========== 提醒表字段 ==========
  static const String columnReminderId = 'id';
  static const String columnReminderEventUid = 'event_uid';
  static const String columnReminderType = 'type';
  static const String columnReminderTriggerMinutes = 'trigger_minutes';
  static const String columnReminderNotificationId = 'notification_id';

  // ========== 事件缓存表字段 ==========
  static const String columnCacheId = 'id';
  static const String columnCacheEventUid = 'event_uid';
  static const String columnCacheOccurrenceDate = 'occurrence_date';
  static const String columnCacheIsException = 'is_exception';

  // ========== 倒计时表字段 ==========
  static const String columnCountdownId = 'id';
  static const String columnCountdownTitle = 'title';
  static const String columnCountdownTargetDate = 'target_date';
  static const String columnCountdownIsLunar = 'is_lunar';
  static const String columnCountdownLunarMonth = 'lunar_month';
  static const String columnCountdownLunarDay = 'lunar_day';
  static const String columnCountdownIsLeapMonth = 'is_leap_month';
  static const String columnCountdownCategory = 'category';
  static const String columnCountdownColor = 'color';
  static const String columnCountdownIcon = 'icon';
  static const String columnCountdownRepeatYearly = 'repeat_yearly';
  static const String columnCountdownNotifyEnabled = 'notify_enabled';
  static const String columnCountdownNotifyDays = 'notify_days';
  static const String columnCountdownCreatedAt = 'created_at';

  // ========== 待办表字段 ==========
  static const String columnTodoId = 'id';
  static const String columnTodoTitle = 'title';
  static const String columnTodoDescription = 'description';
  static const String columnTodoDueDate = 'due_date';
  static const String columnTodoDueTime = 'due_time';
  static const String columnTodoIsCompleted = 'is_completed';
  static const String columnTodoCompletedAt = 'completed_at';
  static const String columnTodoPriority = 'priority';
  static const String columnTodoColor = 'color';
  static const String columnTodoNotifyEnabled = 'notify_enabled';
  static const String columnTodoNotifyMinutes = 'notify_minutes';
  static const String columnTodoCreatedAt = 'created_at';
  static const String columnTodoUpdatedAt = 'updated_at';

  // ========== 建表 SQL ==========

  /// 日历表
  static const String createCalendarsTable = '''
    CREATE TABLE $tableCalendars (
      $columnCalendarId TEXT PRIMARY KEY,
      $columnCalendarName TEXT NOT NULL,
      $columnCalendarColor INTEGER NOT NULL DEFAULT 0xFF2563EB,
      $columnCalendarIsVisible INTEGER NOT NULL DEFAULT 1,
      $columnCalendarIsDefault INTEGER NOT NULL DEFAULT 0,
      $columnCalendarIsSubscription INTEGER NOT NULL DEFAULT 0,
      $columnCalendarSubscriptionUrl TEXT,
      $columnCalendarSyncInterval TEXT DEFAULT 'manual',
      $columnCalendarLastSyncTime INTEGER,
      $columnCalendarCreatedAt INTEGER NOT NULL
    )
  ''';

  /// 事件表
  static const String createEventsTable = '''
    CREATE TABLE $tableEvents (
      $columnEventUid TEXT PRIMARY KEY,
      $columnEventCalendarId TEXT NOT NULL,
      $columnEventSummary TEXT NOT NULL,
      $columnEventDescription TEXT,
      $columnEventLocation TEXT,
      $columnEventDtstart INTEGER NOT NULL,
      $columnEventDtend INTEGER,
      $columnEventIsAllDay INTEGER NOT NULL DEFAULT 0,
      $columnEventRrule TEXT,
      $columnEventExdates TEXT,
      $columnEventColor INTEGER,
      $columnEventStatus TEXT NOT NULL DEFAULT 'confirmed',
      $columnEventPriority INTEGER NOT NULL DEFAULT 0,
      $columnEventUrl TEXT,
      $columnEventCreatedAt INTEGER NOT NULL,
      $columnEventUpdatedAt INTEGER NOT NULL,
      $columnEventSequence INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($columnEventCalendarId) REFERENCES $tableCalendars($columnCalendarId) ON DELETE CASCADE
    )
  ''';

  /// 事件索引
  static const String createEventsCalendarIdIndex = '''
    CREATE INDEX idx_events_calendar_id ON $tableEvents($columnEventCalendarId)
  ''';

  static const String createEventsDtstartIndex = '''
    CREATE INDEX idx_events_dtstart ON $tableEvents($columnEventDtstart)
  ''';

  static const String createEventsDtendIndex = '''
    CREATE INDEX idx_events_dtend ON $tableEvents($columnEventDtend)
  ''';

  /// 联合索引：calendar_id + dtstart（优化按日历和日期范围查询）
  static const String createEventsCalendarDtstartIndex = '''
    CREATE INDEX idx_events_calendar_dtstart ON $tableEvents($columnEventCalendarId, $columnEventDtstart)
  ''';

  /// 联合索引：dtstart + dtend（优化日期范围重叠查询）
  static const String createEventsDtstartDtendIndex = '''
    CREATE INDEX idx_events_dtstart_dtend ON $tableEvents($columnEventDtstart, $columnEventDtend)
  ''';

  /// 提醒表
  static const String createRemindersTable = '''
    CREATE TABLE $tableReminders (
      $columnReminderId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnReminderEventUid TEXT NOT NULL,
      $columnReminderType TEXT NOT NULL DEFAULT 'notification',
      $columnReminderTriggerMinutes INTEGER NOT NULL,
      $columnReminderNotificationId INTEGER NOT NULL,
      FOREIGN KEY ($columnReminderEventUid) REFERENCES $tableEvents($columnEventUid) ON DELETE CASCADE
    )
  ''';

  static const String createRemindersEventUidIndex = '''
    CREATE INDEX idx_reminders_event_uid ON $tableReminders($columnReminderEventUid)
  ''';

  /// 事件缓存表
  static const String createEventCacheTable = '''
    CREATE TABLE $tableEventCache (
      $columnCacheId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnCacheEventUid TEXT NOT NULL,
      $columnCacheOccurrenceDate INTEGER NOT NULL,
      $columnCacheIsException INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($columnCacheEventUid) REFERENCES $tableEvents($columnEventUid) ON DELETE CASCADE
    )
  ''';

  static const String createEventCacheDateIndex = '''
    CREATE INDEX idx_event_cache_date ON $tableEventCache($columnCacheOccurrenceDate)
  ''';

  static const String createEventCacheEventUidIndex = '''
    CREATE INDEX idx_event_cache_event_uid ON $tableEventCache($columnCacheEventUid)
  ''';

  /// 倒计时表
  static const String createCountdownsTable = '''
    CREATE TABLE $tableCountdowns (
      $columnCountdownId TEXT PRIMARY KEY,
      $columnCountdownTitle TEXT NOT NULL,
      $columnCountdownTargetDate INTEGER NOT NULL,
      $columnCountdownIsLunar INTEGER NOT NULL DEFAULT 0,
      $columnCountdownLunarMonth INTEGER,
      $columnCountdownLunarDay INTEGER,
      $columnCountdownIsLeapMonth INTEGER NOT NULL DEFAULT 0,
      $columnCountdownCategory TEXT,
      $columnCountdownColor INTEGER,
      $columnCountdownIcon TEXT,
      $columnCountdownRepeatYearly INTEGER NOT NULL DEFAULT 0,
      $columnCountdownNotifyEnabled INTEGER NOT NULL DEFAULT 0,
      $columnCountdownNotifyDays TEXT,
      $columnCountdownCreatedAt INTEGER NOT NULL
    )
  ''';

  static const String createCountdownsTargetDateIndex = '''
    CREATE INDEX idx_countdowns_target_date ON $tableCountdowns($columnCountdownTargetDate)
  ''';

  /// 待办表
  static const String createTodosTable = '''
    CREATE TABLE $tableTodos (
      $columnTodoId TEXT PRIMARY KEY,
      $columnTodoTitle TEXT NOT NULL,
      $columnTodoDescription TEXT,
      $columnTodoDueDate INTEGER,
      $columnTodoDueTime INTEGER,
      $columnTodoIsCompleted INTEGER NOT NULL DEFAULT 0,
      $columnTodoCompletedAt INTEGER,
      $columnTodoPriority INTEGER NOT NULL DEFAULT 0,
      $columnTodoColor INTEGER,
      $columnTodoNotifyEnabled INTEGER NOT NULL DEFAULT 0,
      $columnTodoNotifyMinutes INTEGER,
      $columnTodoCreatedAt INTEGER NOT NULL,
      $columnTodoUpdatedAt INTEGER NOT NULL
    )
  ''';

  static const String createTodosDueDateIndex = '''
    CREATE INDEX idx_todos_due_date ON $tableTodos($columnTodoDueDate)
  ''';

  static const String createTodosIsCompletedIndex = '''
    CREATE INDEX idx_todos_is_completed ON $tableTodos($columnTodoIsCompleted)
  ''';

  static const String createTodosPriorityIndex = '''
    CREATE INDEX idx_todos_priority ON $tableTodos($columnTodoPriority)
  ''';

  // ========== LLM 配置表字段 ==========
  static const String columnLlmConfigId = 'id';
  static const String columnLlmConfigName = 'name';
  static const String columnLlmConfigBaseUrl = 'base_url';
  static const String columnLlmConfigModel = 'model';
  static const String columnLlmConfigIsActive = 'is_active';
  static const String columnLlmConfigCreatedAt = 'created_at';

  /// 搜索历史表
  static const String createSearchHistoryTable = '''
    CREATE TABLE $tableSearchHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      query TEXT NOT NULL,
      searched_at INTEGER NOT NULL,
      result_count INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createSearchHistorySearchedAtIndex = '''
    CREATE INDEX idx_search_history_searched_at ON $tableSearchHistory(searched_at)
  ''';

  /// 天气缓存表
  static const String createWeatherCacheTable = '''
    CREATE TABLE $tableWeatherCache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      date INTEGER NOT NULL,
      weather_data TEXT NOT NULL,
      cached_at INTEGER NOT NULL,
      UNIQUE(latitude, longitude, date)
    )
  ''';

  static const String createWeatherCacheDateIndex = '''
    CREATE INDEX idx_weather_cache_date ON $tableWeatherCache(date)
  ''';

  /// LLM 配置表
  /// 注意：API Key 使用 flutter_secure_storage 单独存储，不在数据库中
  static const String createLlmConfigTable = '''
    CREATE TABLE $tableLlmConfig (
      $columnLlmConfigId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnLlmConfigName TEXT NOT NULL,
      $columnLlmConfigBaseUrl TEXT NOT NULL,
      $columnLlmConfigModel TEXT NOT NULL,
      $columnLlmConfigIsActive INTEGER NOT NULL DEFAULT 0,
      $columnLlmConfigCreatedAt INTEGER NOT NULL
    )
  ''';

  /// 获取所有建表语句
  static List<String> get createTableStatements => [
    createCalendarsTable,
    createEventsTable,
    createEventsCalendarIdIndex,
    createEventsDtstartIndex,
    createEventsDtendIndex,
    createEventsCalendarDtstartIndex,  // 联合索引：优化按日历+日期查询
    createEventsDtstartDtendIndex,      // 联合索引：优化日期范围查询
    createRemindersTable,
    createRemindersEventUidIndex,
    createEventCacheTable,
    createEventCacheDateIndex,
    createEventCacheEventUidIndex,
    createCountdownsTable,
    createCountdownsTargetDateIndex,
    createTodosTable,
    createTodosDueDateIndex,
    createTodosIsCompletedIndex,
    createTodosPriorityIndex,
    createSearchHistoryTable,
    createSearchHistorySearchedAtIndex,
    createWeatherCacheTable,
    createWeatherCacheDateIndex,
    createLlmConfigTable,
  ];

  /// 获取数据库升级到 v3 的 SQL 语句（添加待办表）
  static List<String> get upgradeToV3Statements => [
    createTodosTable,
    createTodosDueDateIndex,
    createTodosIsCompletedIndex,
    createTodosPriorityIndex,
  ];
}
