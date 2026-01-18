import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/llm_config_model.dart';
import '../core/constants/db_constants.dart';
import 'database_service.dart';

/// LLM 服务 - 处理 AI 自然语言解析
/// 支持 OpenAI 协议兼容的各种服务（OpenAI、DeepSeek、通义千问、Ollama 等）
class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  final DatabaseService _db = DatabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  /// 自然语言解析的系统提示词
  static const String _systemPrompt = '''
你是一个日程解析助手。请从用户输入的自然语言中提取日程信息。

当前时间：{{current_time}}

请判断用户意图并返回 JSON（三种类型之一）：

**类型1 - 普通日程**（会议、约会、活动、考试等有具体时间段的事项）：
{
  "type": "event",
  "title": "事件标题",
  "start_time": "ISO8601",
  "end_time": "ISO8601（可选）",
  "is_all_day": false,
  "location": "地点（可选）",
  "description": "描述（可选）",
  "reminder_minutes": 15
}

**类型2 - 倒计时/纪念日**（生日、纪念日、重要日期、截止日期等）：
{
  "type": "countdown",
  "title": "标题",
  "target_date": "YYYY-MM-DD",
  "category": "birthday|anniversary|holiday|deadline|other",
  "repeat_yearly": true,
  "is_lunar": false,
  "lunar_date": "MM-DD（仅农历时）"
}

**类型3 - 待办事项**（需要完成的任务、购物清单等）：
{
  "type": "todo",
  "title": "待办标题",
  "due_date": "YYYY-MM-DD（可选）",
  "due_time": "HH:mm（可选）",
  "priority": 0,
  "description": "详细描述（可选）"
}

优先级说明：0=无 1=低 2=中 3=高

判断规则：
- "生日"、"纪念日"、"周年"、"还有X天" → countdown
- "会议"、"约会"、"开会"、"几点" → event
- "买"、"购买"、"提醒我"、"记得"、"要做"、"完成" → todo
- 如果是任务性质且没有明确时间段 → todo
- 如果是活动性质且有明确时间段 → event

规则：
1. 如果没有明确时间，使用合理推断
2. "明天"指下一个自然日
3. "下周一"指下一个周一
4. 只返回 JSON，不要其他文字
5. 如果无法解析，返回 {"error": "原因"}
''';

  // ==================== 配置管理 ====================

  /// 获取所有 LLM 配置
  Future<List<LLMConfigModel>> getAllConfigs() async {
    final maps = await _db.query(
      DbConstants.tableLlmConfig,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => LLMConfigModel.fromMap(m)).toList();
  }

  /// 获取当前激活的配置
  Future<LLMConfigModel?> getActiveConfig() async {
    final maps = await _db.query(
      DbConstants.tableLlmConfig,
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LLMConfigModel.fromMap(maps.first);
  }

  /// 根据 ID 获取配置
  Future<LLMConfigModel?> getConfigById(int id) async {
    final maps = await _db.query(
      DbConstants.tableLlmConfig,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LLMConfigModel.fromMap(maps.first);
  }

  /// 保存配置（新增或更新）
  Future<int> saveConfig(LLMConfigModel config, String apiKey) async {
    final map = config.toMap();

    int configId;
    if (config.id == null) {
      // 新增
      configId = await _db.insert(DbConstants.tableLlmConfig, map);
    } else {
      // 更新
      await _db.update(
        DbConstants.tableLlmConfig,
        map,
        where: 'id = ?',
        whereArgs: [config.id],
      );
      configId = config.id!;
    }

    // 安全存储 API Key
    await _secureStorage.write(
      key: _getApiKeyStorageKey(configId),
      value: apiKey,
    );

    debugPrint('LLM 配置已保存: $configId');
    return configId;
  }

  /// 删除配置
  Future<void> deleteConfig(int id) async {
    await _db.delete(
      DbConstants.tableLlmConfig,
      where: 'id = ?',
      whereArgs: [id],
    );

    // 删除对应的 API Key
    await _secureStorage.delete(key: _getApiKeyStorageKey(id));

    debugPrint('LLM 配置已删除: $id');
  }

  /// 设置激活配置
  Future<void> setActiveConfig(int id) async {
    // 先取消所有激活状态
    await _db.update(
      DbConstants.tableLlmConfig,
      {'is_active': 0},
    );

    // 设置指定配置为激活
    await _db.update(
      DbConstants.tableLlmConfig,
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    debugPrint('LLM 配置已激活: $id');
  }

  /// 获取配置的 API Key
  Future<String?> getApiKey(int configId) async {
    return await _secureStorage.read(key: _getApiKeyStorageKey(configId));
  }

  /// 生成 API Key 存储键名
  String _getApiKeyStorageKey(int configId) => 'llm_api_key_$configId';

  // ==================== AI 解析功能 ====================

  /// 使用 AI 解析自然语言输入为事件信息
  Future<LLMParseResult> parseNaturalLanguage(String input) async {
    if (input.trim().isEmpty) {
      return LLMParseResult.error('输入不能为空');
    }

    final config = await getActiveConfig();
    if (config == null) {
      return LLMParseResult.error('请先配置 AI 服务');
    }

    final apiKey = await getApiKey(config.id!);
    if (apiKey == null || apiKey.isEmpty) {
      return LLMParseResult.error('API Key 未配置');
    }

    try {
      final systemPrompt = _systemPrompt.replaceAll(
        '{{current_time}}',
        DateTime.now().toIso8601String(),
      );

      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': input},
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        },
      );

      if (response.statusCode != 200) {
        return LLMParseResult.error('API 请求失败: ${response.statusCode}');
      }

      final data = response.data;
      final content = data['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.isEmpty) {
        return LLMParseResult.error('AI 返回内容为空');
      }

      debugPrint('LLM 原始响应: $content');

      // 尝试解析 JSON
      final jsonContent = _extractJson(content);
      if (jsonContent == null) {
        return LLMParseResult.error('无法解析 AI 返回的 JSON');
      }

      final json = jsonDecode(jsonContent) as Map<String, dynamic>;

      // 检查是否有错误
      if (json.containsKey('error')) {
        return LLMParseResult.error(json['error'] as String);
      }

      final draft = ParsedEventDraft.fromJson(json);
      return LLMParseResult.success(draft);
    } on DioException catch (e) {
      debugPrint('LLM 请求异常: $e');
      return LLMParseResult.error(_getDioErrorMessage(e));
    } catch (e) {
      debugPrint('LLM 解析异常: $e');
      return LLMParseResult.error('解析失败: $e');
    }
  }

  /// 使用 AI 解析自然语言输入为统一的日程结果（支持事件/倒计时/待办）
  Future<LLMScheduleParseResult> parseSchedule(String input) async {
    if (input.trim().isEmpty) {
      return LLMScheduleParseResult.error('输入不能为空');
    }

    final config = await getActiveConfig();
    if (config == null) {
      return LLMScheduleParseResult.error('请先配置 AI 服务');
    }

    final apiKey = await getApiKey(config.id!);
    if (apiKey == null || apiKey.isEmpty) {
      return LLMScheduleParseResult.error('API Key 未配置');
    }

    try {
      final systemPrompt = _systemPrompt.replaceAll(
        '{{current_time}}',
        DateTime.now().toIso8601String(),
      );

      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': input},
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        },
      );

      if (response.statusCode != 200) {
        return LLMScheduleParseResult.error('API 请求失败: ${response.statusCode}');
      }

      final data = response.data;
      final content = data['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.isEmpty) {
        return LLMScheduleParseResult.error('AI 返回内容为空');
      }

      debugPrint('LLM 原始响应: $content');

      // 尝试解析 JSON
      final jsonContent = _extractJson(content);
      if (jsonContent == null) {
        return LLMScheduleParseResult.error('无法解析 AI 返回的 JSON');
      }

      final json = jsonDecode(jsonContent) as Map<String, dynamic>;

      // 检查是否有错误
      if (json.containsKey('error')) {
        return LLMScheduleParseResult.error(json['error'] as String);
      }

      final result = ParsedScheduleResult.fromJson(json);
      return LLMScheduleParseResult.success(result);
    } on DioException catch (e) {
      debugPrint('LLM 请求异常: $e');
      return LLMScheduleParseResult.error(_getDioErrorMessage(e));
    } catch (e) {
      debugPrint('LLM 解析异常: $e');
      return LLMScheduleParseResult.error('解析失败: $e');
    }
  }

  /// 从响应中提取 JSON（处理可能的 markdown 代码块）
  String? _extractJson(String content) {
    // 尝试直接解析
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    // 尝试从 markdown 代码块中提取
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = jsonBlockRegex.firstMatch(content);
    if (match != null) {
      final extracted = match.group(1)?.trim();
      if (extracted != null &&
          extracted.startsWith('{') &&
          extracted.endsWith('}')) {
        return extracted;
      }
    }

    // 尝试找到第一个 JSON 对象
    final jsonRegex = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonRegex.firstMatch(content);
    if (jsonMatch != null) {
      return jsonMatch.group(0);
    }

    return null;
  }

  /// 获取 Dio 错误的友好提示
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '响应超时，AI 服务可能繁忙';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'API Key 无效或已过期';
        } else if (statusCode == 429) {
          return '请求过于频繁，请稍后再试';
        } else if (statusCode == 500) {
          return 'AI 服务器错误';
        }
        return 'API 错误: $statusCode';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '无法连接到 AI 服务，请检查网络或服务地址';
      default:
        return '网络错误: ${e.message}';
    }
  }

  // ==================== 连接测试 ====================

  /// 测试 LLM 服务连接
  Future<LLMTestResult> testConnection(
      LLMConfigModel config, String apiKey) async {
    try {
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': '你好'},
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        final content =
            response.data['choices']?[0]?['message']?['content'] as String?;
        return LLMTestResult.success(content ?? '连接成功');
      } else {
        return LLMTestResult.failure('HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      return LLMTestResult.failure(_getDioErrorMessage(e));
    } catch (e) {
      return LLMTestResult.failure('测试失败: $e');
    }
  }

  /// 检查是否有可用的 AI 配置
  Future<bool> hasActiveConfig() async {
    final config = await getActiveConfig();
    if (config == null) return false;
    final apiKey = await getApiKey(config.id!);
    return apiKey != null && apiKey.isNotEmpty;
  }
}

/// LLM 解析结果
class LLMParseResult {
  final bool isSuccess;
  final ParsedEventDraft? draft;
  final String? errorMessage;

  const LLMParseResult._({
    required this.isSuccess,
    this.draft,
    this.errorMessage,
  });

  factory LLMParseResult.success(ParsedEventDraft draft) {
    return LLMParseResult._(isSuccess: true, draft: draft);
  }

  factory LLMParseResult.error(String message) {
    return LLMParseResult._(isSuccess: false, errorMessage: message);
  }
}

/// LLM 统一日程解析结果
class LLMScheduleParseResult {
  final bool isSuccess;
  final ParsedScheduleResult? result;
  final String? errorMessage;

  const LLMScheduleParseResult._({
    required this.isSuccess,
    this.result,
    this.errorMessage,
  });

  factory LLMScheduleParseResult.success(ParsedScheduleResult result) {
    return LLMScheduleParseResult._(isSuccess: true, result: result);
  }

  factory LLMScheduleParseResult.error(String message) {
    return LLMScheduleParseResult._(isSuccess: false, errorMessage: message);
  }
}

/// LLM 连接测试结果
class LLMTestResult {
  final bool isSuccess;
  final String message;

  const LLMTestResult._({required this.isSuccess, required this.message});

  factory LLMTestResult.success(String message) {
    return LLMTestResult._(isSuccess: true, message: message);
  }

  factory LLMTestResult.failure(String message) {
    return LLMTestResult._(isSuccess: false, message: message);
  }
}
