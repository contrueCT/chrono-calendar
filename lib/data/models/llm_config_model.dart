import '../../core/constants/db_constants.dart';

/// LLM 配置模型
/// 用于存储 AI 服务的配置信息，支持 OpenAI 协议兼容的各种服务
class LLMConfigModel {
  final int? id;
  final String name;
  final String baseUrl;
  final String model;
  final bool isActive;
  final DateTime createdAt;

  // API Key 不在模型中存储，使用 SecureStorage 单独管理

  const LLMConfigModel({
    this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.isActive = false,
    required this.createdAt,
  });

  /// 从数据库 Map 创建
  factory LLMConfigModel.fromMap(Map<String, dynamic> map) {
    return LLMConfigModel(
      id: map[DbConstants.columnLlmConfigId] as int?,
      name: map[DbConstants.columnLlmConfigName] as String,
      baseUrl: map[DbConstants.columnLlmConfigBaseUrl] as String,
      model: map[DbConstants.columnLlmConfigModel] as String,
      isActive: (map[DbConstants.columnLlmConfigIsActive] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnLlmConfigCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.columnLlmConfigId: id,
      DbConstants.columnLlmConfigName: name,
      DbConstants.columnLlmConfigBaseUrl: baseUrl,
      DbConstants.columnLlmConfigModel: model,
      DbConstants.columnLlmConfigIsActive: isActive ? 1 : 0,
      DbConstants.columnLlmConfigCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  LLMConfigModel copyWith({
    int? id,
    String? name,
    String? baseUrl,
    String? model,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LLMConfigModel(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'LLMConfigModel(id: $id, name: $name, baseUrl: $baseUrl, model: $model, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMConfigModel &&
        other.id == id &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.model == model &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, baseUrl, model, isActive);
  }
}

/// AI 解析后的事件草稿
/// 从自然语言解析得到的结构化事件信息
class ParsedEventDraft {
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final String? description;
  final int? reminderMinutes;

  const ParsedEventDraft({
    required this.title,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.description,
    this.reminderMinutes,
  });

  /// 从 LLM 返回的 JSON 创建
  factory ParsedEventDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return ParsedEventDraft(
      title: json['title'] as String? ?? '未命名事件',
      startTime: parseDateTime(json['start_time'] as String?),
      endTime: parseDateTime(json['end_time'] as String?),
      isAllDay: json['is_all_day'] as bool? ?? false,
      location: json['location'] as String?,
      description: json['description'] as String?,
      reminderMinutes: json['reminder_minutes'] as int?,
    );
  }

  /// 检查解析结果是否有效
  bool get isValid => title.isNotEmpty && startTime != null;

  @override
  String toString() {
    return 'ParsedEventDraft(title: $title, startTime: $startTime, endTime: $endTime, '
        'isAllDay: $isAllDay, location: $location, reminderMinutes: $reminderMinutes)';
  }
}

/// AI 解析后的倒计时草稿
class ParsedCountdownDraft {
  final String title;
  final DateTime targetDate;
  final String? category;
  final bool repeatYearly;
  final bool isLunar;
  final int? lunarMonth;
  final int? lunarDay;

  const ParsedCountdownDraft({
    required this.title,
    required this.targetDate,
    this.category,
    this.repeatYearly = false,
    this.isLunar = false,
    this.lunarMonth,
    this.lunarDay,
  });

  /// 从 LLM 返回的 JSON 创建
  factory ParsedCountdownDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    int? parseLunarPart(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        final match = RegExp(r'\d+').firstMatch(value);
        if (match != null) return int.tryParse(match.group(0)!);
      }
      return null;
    }

    // 解析农历日期字符串（如 "07-15"）
    int? lunarMonth;
    int? lunarDay;
    final lunarDateStr = json['lunar_date'] as String?;
    if (lunarDateStr != null) {
      final parts = lunarDateStr.split('-');
      if (parts.length == 2) {
        lunarMonth = int.tryParse(parts[0]);
        lunarDay = int.tryParse(parts[1]);
      }
    }

    return ParsedCountdownDraft(
      title: json['title'] as String? ?? '未命名倒计时',
      targetDate: parseDate(json['target_date'] as String?) ?? DateTime.now(),
      category: json['category'] as String?,
      repeatYearly: json['repeat_yearly'] as bool? ?? false,
      isLunar: json['is_lunar'] as bool? ?? false,
      lunarMonth: lunarMonth ?? parseLunarPart(json['lunar_month']),
      lunarDay: lunarDay ?? parseLunarPart(json['lunar_day']),
    );
  }

  @override
  String toString() {
    return 'ParsedCountdownDraft(title: $title, targetDate: $targetDate, '
        'category: $category, repeatYearly: $repeatYearly, isLunar: $isLunar)';
  }
}

/// AI 解析后的待办草稿
class ParsedTodoDraft {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final int priority;
  final String? description;

  const ParsedTodoDraft({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.priority = 0,
    this.description,
  });

  /// 从 LLM 返回的 JSON 创建
  factory ParsedTodoDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    DateTime? parseTime(String? value, DateTime? date) {
      if (value == null || value.isEmpty || date == null) return null;
      final parts = value.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return DateTime(date.year, date.month, date.day, hour, minute);
        }
      }
      return null;
    }

    final dueDate = parseDate(json['due_date'] as String?);
    final dueTime = parseTime(json['due_time'] as String?, dueDate);

    return ParsedTodoDraft(
      title: json['title'] as String? ?? '未命名待办',
      dueDate: dueDate,
      dueTime: dueTime,
      priority: json['priority'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }

  @override
  String toString() {
    return 'ParsedTodoDraft(title: $title, dueDate: $dueDate, priority: $priority)';
  }
}

/// 统一的 AI 解析结果
class ParsedScheduleResult {
  /// 解析结果类型
  final String type;

  /// 事件草稿（type=event 时有值）
  final ParsedEventDraft? eventDraft;

  /// 倒计时草稿（type=countdown 时有值）
  final ParsedCountdownDraft? countdownDraft;

  /// 待办草稿（type=todo 时有值）
  final ParsedTodoDraft? todoDraft;

  const ParsedScheduleResult({
    required this.type,
    this.eventDraft,
    this.countdownDraft,
    this.todoDraft,
  });

  /// 从 LLM 返回的 JSON 创建
  factory ParsedScheduleResult.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'event';

    switch (typeStr) {
      case 'countdown':
        return ParsedScheduleResult(
          type: 'countdown',
          countdownDraft: ParsedCountdownDraft.fromJson(json),
        );
      case 'todo':
        return ParsedScheduleResult(
          type: 'todo',
          todoDraft: ParsedTodoDraft.fromJson(json),
        );
      default:
        return ParsedScheduleResult(
          type: 'event',
          eventDraft: ParsedEventDraft.fromJson(json),
        );
    }
  }

  /// 是否是事件类型
  bool get isEvent => type == 'event';

  /// 是否是倒计时类型
  bool get isCountdown => type == 'countdown';

  /// 是否是待办类型
  bool get isTodo => type == 'todo';
}

/// 预设的 LLM 服务提供商
class LLMProvider {
  final String name;
  final String baseUrl;
  final List<String> models;
  final String description;

  const LLMProvider({
    required this.name,
    required this.baseUrl,
    required this.models,
    required this.description,
  });

  /// 预设的服务提供商列表
  static const List<LLMProvider> presets = [
    LLMProvider(
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'],
      description: 'OpenAI 官方 API',
    ),
    LLMProvider(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      models: ['deepseek-chat', 'deepseek-coder'],
      description: 'DeepSeek 深度求索',
    ),
    LLMProvider(
      name: '通义千问',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      models: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
      description: '阿里云通义千问',
    ),
    LLMProvider(
      name: 'Ollama (本地)',
      baseUrl: 'http://localhost:11434/v1',
      models: ['llama3', 'qwen2', 'mistral', 'gemma'],
      description: '本地 Ollama 服务',
    ),
    LLMProvider(
      name: '自定义',
      baseUrl: '',
      models: [],
      description: '自定义 OpenAI 兼容 API',
    ),
  ];
}
