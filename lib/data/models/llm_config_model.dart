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
      id: map['id'] as int?,
      name: map['name'] as String,
      baseUrl: map['base_url'] as String,
      model: map['model'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'base_url': baseUrl,
      'model': model,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
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
