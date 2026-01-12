import '../core/constants/db_constants.dart';
import '../data/models/event_model.dart';
import '../data/repositories/event_repository.dart';
import 'database_service.dart';

/// 搜索历史记录模型
class SearchHistoryItem {
  final int id;
  final String query;
  final DateTime searchedAt;
  final int resultCount;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.searchedAt,
    required this.resultCount,
  });

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] as int,
      query: map['query'] as String,
      searchedAt: DateTime.fromMillisecondsSinceEpoch(map['searched_at'] as int),
      resultCount: map['result_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'searched_at': searchedAt.millisecondsSinceEpoch,
      'result_count': resultCount,
    };
  }
}

/// 搜索结果模型 - 包含事件和匹配信息
class SearchResult {
  final EventModel event;
  final String matchField; // 'summary', 'description', 'location'
  final String matchedText;

  SearchResult({
    required this.event,
    required this.matchField,
    required this.matchedText,
  });
}

/// 搜索服务 - 负责事件搜索和搜索历史管理
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final EventRepository _eventRepository = EventRepository();

  /// 最大搜索历史记录数
  static const int maxHistoryCount = 20;

  // ==================== 事件搜索 ====================

  /// 搜索事件
  /// [query] 搜索关键词
  /// [startDate] 开始日期（可选）
  /// [endDate] 结束日期（可选）
  /// [calendarIds] 日历ID列表（可选，为空则搜索所有日历）
  /// [saveHistory] 是否保存到搜索历史
  Future<List<SearchResult>> searchEvents({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? calendarIds,
    bool saveHistory = true,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final trimmedQuery = query.trim().toLowerCase();

    // 执行搜索
    final events = await _eventRepository.searchEvents(
      trimmedQuery,
      startDate: startDate,
      endDate: endDate,
    );

    // 过滤日历
    List<EventModel> filteredEvents = events;
    if (calendarIds != null && calendarIds.isNotEmpty) {
      filteredEvents = events.where((e) => calendarIds.contains(e.calendarId)).toList();
    }

    // 构建搜索结果（包含匹配信息）
    final results = <SearchResult>[];
    for (final event in filteredEvents) {
      final matchInfo = _getMatchInfo(event, trimmedQuery);
      if (matchInfo != null) {
        results.add(SearchResult(
          event: event,
          matchField: matchInfo['field']!,
          matchedText: matchInfo['text']!,
        ));
      }
    }

    // 保存搜索历史
    if (saveHistory && results.isNotEmpty) {
      await _saveSearchHistory(query.trim(), results.length);
    }

    return results;
  }

  /// 获取匹配信息
  Map<String, String>? _getMatchInfo(EventModel event, String query) {
    // 优先匹配标题
    if (event.summary.toLowerCase().contains(query)) {
      return {'field': 'summary', 'text': event.summary};
    }
    // 然后匹配描述
    if (event.description?.toLowerCase().contains(query) == true) {
      return {'field': 'description', 'text': event.description!};
    }
    // 最后匹配地点
    if (event.location?.toLowerCase().contains(query) == true) {
      return {'field': 'location', 'text': event.location!};
    }
    return null;
  }

  /// 高亮搜索关键词
  /// 返回带有标记的文本片段列表
  List<TextSpanInfo> highlightQuery(String text, String query) {
    if (query.isEmpty || text.isEmpty) {
      return [TextSpanInfo(text: text, isHighlight: false)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpanInfo>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index != -1) {
      // 添加匹配前的普通文本
      if (index > start) {
        spans.add(TextSpanInfo(
          text: text.substring(start, index),
          isHighlight: false,
        ));
      }

      // 添加高亮文本
      spans.add(TextSpanInfo(
        text: text.substring(index, index + query.length),
        isHighlight: true,
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // 添加剩余的普通文本
    if (start < text.length) {
      spans.add(TextSpanInfo(
        text: text.substring(start),
        isHighlight: false,
      ));
    }

    return spans.isEmpty ? [TextSpanInfo(text: text, isHighlight: false)] : spans;
  }

  // ==================== 搜索历史 ====================

  /// 获取搜索历史
  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 10}) async {
    final maps = await _databaseService.query(
      DbConstants.tableSearchHistory,
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return maps.map((map) => SearchHistoryItem.fromMap(map)).toList();
  }

  /// 保存搜索历史
  Future<void> _saveSearchHistory(String query, int resultCount) async {
    // 检查是否已存在相同的搜索词
    final existing = await _databaseService.query(
      DbConstants.tableSearchHistory,
      where: 'query = ?',
      whereArgs: [query],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 更新已存在的记录
      await _databaseService.update(
        DbConstants.tableSearchHistory,
        {
          'searched_at': DateTime.now().millisecondsSinceEpoch,
          'result_count': resultCount,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // 插入新记录
      await _databaseService.insert(DbConstants.tableSearchHistory, {
        'query': query,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
        'result_count': resultCount,
      });

      // 清理超出限制的历史记录
      await _cleanupHistory();
    }
  }

  /// 清理超出限制的历史记录
  Future<void> _cleanupHistory() async {
    final count = await _databaseService.count(DbConstants.tableSearchHistory);
    if (count > maxHistoryCount) {
      // 获取需要删除的记录
      final toDelete = await _databaseService.query(
        DbConstants.tableSearchHistory,
        orderBy: 'searched_at ASC',
        limit: count - maxHistoryCount,
      );

      for (final item in toDelete) {
        await _databaseService.delete(
          DbConstants.tableSearchHistory,
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }

  /// 删除单条搜索历史
  Future<void> deleteHistoryItem(int id) async {
    await _databaseService.delete(
      DbConstants.tableSearchHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有搜索历史
  Future<void> clearAllHistory() async {
    await _databaseService.delete(DbConstants.tableSearchHistory);
  }

  // ==================== 搜索建议 ====================

  /// 获取搜索建议（基于历史记录和当前输入）
  Future<List<String>> getSearchSuggestions(String input) async {
    if (input.trim().isEmpty) {
      // 返回最近的搜索历史
      final history = await getSearchHistory(limit: 5);
      return history.map((h) => h.query).toList();
    }

    final pattern = '%${input.trim()}%';

    // 从历史记录中匹配
    final historyMatches = await _databaseService.query(
      DbConstants.tableSearchHistory,
      where: 'query LIKE ?',
      whereArgs: [pattern],
      orderBy: 'searched_at DESC',
      limit: 5,
    );

    final suggestions = historyMatches
        .map((m) => m['query'] as String)
        .toList();

    // 从事件标题中匹配更多建议
    if (suggestions.length < 5) {
      final eventMatches = await _databaseService.query(
        DbConstants.tableEvents,
        columns: [DbConstants.columnEventSummary],
        where: '${DbConstants.columnEventSummary} LIKE ?',
        whereArgs: [pattern],
        limit: 5 - suggestions.length,
      );

      for (final event in eventMatches) {
        final summary = event[DbConstants.columnEventSummary] as String;
        if (!suggestions.contains(summary)) {
          suggestions.add(summary);
        }
      }
    }

    return suggestions;
  }
}

/// 文本片段信息（用于高亮显示）
class TextSpanInfo {
  final String text;
  final bool isHighlight;

  TextSpanInfo({required this.text, required this.isHighlight});
}
