import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/search_service.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/countdown_model.dart';
import '../../../data/models/todo_model.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<UnifiedSearchResult> _searchResults = [];
  List<SearchHistoryItem> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showHistory = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory(limit: 10);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _suggestions = [];
        _showHistory = true;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showHistory = false;
      _suggestions = [];  // 清空建议列表，确保显示搜索结果
      _currentQuery = query.trim();
    });

    try {
      final results = await _searchService.searchAll(query: query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // 刷新搜索历史
      await _loadSearchHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarHelper.showError(context, '搜索出错: $e');
      }
    }
  }

  Future<void> _updateSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _showHistory = true;
      });
      return;
    }

    final suggestions = await _searchService.getSearchSuggestions(input);
    setState(() {
      _suggestions = suggestions;
      _showHistory = false;
    });
  }

  Future<void> _deleteHistoryItem(int id) async {
    await _searchService.deleteHistoryItem(id);
    await _loadSearchHistory();
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空搜索历史'),
        content: const Text('确定要清空所有搜索历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _searchService.clearAllHistory();
      await _loadSearchHistory();
    }
  }

  void _onEventTap(EventModel event) {
    context.push('/event/${event.uid}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          // 搜索建议或历史
          if (_showHistory || _suggestions.isNotEmpty) _buildSuggestionsOrHistory(colorScheme),
          // 搜索结果
          if (!_showHistory && _suggestions.isEmpty) Expanded(child: _buildSearchResults(colorScheme)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: '搜索事件、倒计时、待办...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        textInputAction: TextInputAction.search,
        onChanged: _updateSuggestions,
        onSubmitted: _search,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults = [];
                _suggestions = [];
                _showHistory = true;
                _currentQuery = '';
              });
              _searchFocusNode.requestFocus();
            },
          ),
      ],
    );
  }

  Widget _buildSuggestionsOrHistory(ColorScheme colorScheme) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 显示建议
          if (_suggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '搜索建议',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ..._suggestions.map((suggestion) => ListTile(
                  leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  title: Text(suggestion),
                  onTap: () {
                    _searchController.text = suggestion;
                    _search(suggestion);
                  },
                )),
          ],
          // 显示历史
          if (_showHistory && _searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '搜索历史',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllHistory,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '清空',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._searchHistory.map((item) => ListTile(
                  leading: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
                  title: Text(item.query),
                  subtitle: Text(
                    '${item.resultCount} 个结果',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
                    onPressed: () => _deleteHistoryItem(item.id),
                  ),
                  onTap: () {
                    _searchController.text = item.query;
                    _search(item.query);
                  },
                )),
          ],
          // 空状态
          if (_showHistory && _searchHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '搜索事件、倒计时或待办',
                    style: TextStyle(
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

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关内容',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用不同的关键词搜索',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 分组结果
    final eventResults = _searchResults.whereType<EventSearchResult>().toList();
    final countdownResults = _searchResults.whereType<CountdownSearchResult>().toList();
    final todoResults = _searchResults.whereType<TodoSearchResult>().toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 总结
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '找到 ${_searchResults.length} 个结果',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 事件结果
        if (eventResults.isNotEmpty) ...[
          _buildSectionHeader('事件', eventResults.length, Icons.event, colorScheme),
          ...eventResults.map((r) => _EventResultCard(
                result: r,
                query: _currentQuery,
                colorScheme: colorScheme,
                onTap: () => context.push('/event/${r.event.uid}'),
              )),
        ],

        // 倒计时结果
        if (countdownResults.isNotEmpty) ...[
          _buildSectionHeader('倒计时', countdownResults.length, Icons.timer, colorScheme),
          ...countdownResults.map((r) => _CountdownResultCard(
                result: r,
                query: _currentQuery,
                colorScheme: colorScheme,
                onTap: () => context.push('/countdown/${r.countdown.id}'),
              )),
        ],

        // 待办结果
        if (todoResults.isNotEmpty) ...[
          _buildSectionHeader('待办', todoResults.length, Icons.check_circle_outline, colorScheme),
          ...todoResults.map((r) => _TodoResultCard(
                result: r,
                query: _currentQuery,
                colorScheme: colorScheme,
                onTap: () => context.push('/todo/${r.todo.id}'),
              )),
        ],

        // 底部间距
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 事件搜索结果卡片
class _EventResultCard extends StatelessWidget {
  final EventSearchResult result;
  final String query;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _EventResultCard({
    required this.result,
    required this.query,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final event = result.event;
    final dateFormat = DateFormat('MM月dd日 HH:mm');
    final eventColor = Color(event.color ?? 0xFF2563EB);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 颜色指示条
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题（高亮搜索词）
                    _buildHighlightedText(
                      event.summary,
                      query,
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    // 时间
                    Row(
                      children: [
                        Icon(
                          event.isAllDay ? Icons.calendar_today : Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isAllDay
                              ? DateFormat('yyyy年MM月dd日').format(event.dtStart)
                              : dateFormat.format(event.dtStart),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // 农历
                        const SizedBox(width: 8),
                        Text(
                          LunarUtils.getDisplayText(event.dtStart),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    // 匹配的字段
                    if (result.matchField != 'summary') ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            result.matchField == 'location'
                                ? Icons.location_on
                                : Icons.description,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildHighlightedText(
                              _truncateText(result.matchedText, 50),
                              query,
                              TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              colorScheme,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 地点（如果匹配的不是地点）
                    if (result.matchField != 'location' && event.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 重复标记
                    if (event.rrule != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '重复事件',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    ColorScheme colorScheme,
  ) {
    final searchService = SearchService();
    final spans = searchService.highlightQuery(text, query);

    return RichText(
      text: TextSpan(
        children: spans.map((span) {
          return TextSpan(
            text: span.text,
            style: span.isHighlight
                ? baseStyle.copyWith(
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : baseStyle,
          );
        }).toList(),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// 倒计时搜索结果卡片
class _CountdownResultCard extends StatelessWidget {
  final CountdownSearchResult result;
  final String query;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _CountdownResultCard({
    required this.result,
    required this.query,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countdown = result.countdown;
    final daysRemaining = countdown.getDaysRemaining();
    final countdownColor = Color(countdown.color ?? 0xFF2563EB);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 颜色指示条
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: countdownColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题（高亮）
                    _buildHighlightedText(
                      countdown.title,
                      query,
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    // 目标日期
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining == 0
                              ? '就是今天'
                              : daysRemaining > 0
                                  ? '还有 $daysRemaining 天'
                                  : '已过 ${-daysRemaining} 天',
                          style: TextStyle(
                            fontSize: 13,
                            color: daysRemaining == 0
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: daysRemaining == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    // 分类
                    const SizedBox(height: 4),
                    Text(
                      countdown.getCategoryName(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    ColorScheme colorScheme,
  ) {
    final searchService = SearchService();
    final spans = searchService.highlightQuery(text, query);

    return RichText(
      text: TextSpan(
        children: spans.map((span) {
          return TextSpan(
            text: span.text,
            style: span.isHighlight
                ? baseStyle.copyWith(
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : baseStyle,
          );
        }).toList(),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 待办搜索结果卡片
class _TodoResultCard extends StatelessWidget {
  final TodoSearchResult result;
  final String query;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TodoResultCard({
    required this.result,
    required this.query,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final todo = result.todo;
    final todoColor = Color(todo.color ?? 0xFF2563EB);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 完成状态指示
              Icon(
                todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: todo.isCompleted ? colorScheme.primary : todoColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题（高亮，完成则划线）
                    _buildHighlightedText(
                      todo.title,
                      query,
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: todo.isCompleted
                            ? colorScheme.onSurface.withOpacity(0.5)
                            : colorScheme.onSurface,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      colorScheme,
                    ),
                    // 匹配描述
                    if (result.matchField == 'description' && todo.description != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.description, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildHighlightedText(
                              _truncateText(todo.description!, 50),
                              query,
                              TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              colorScheme,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 截止日期和优先级
                    if (todo.dueDate != null || todo.priority > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (todo.dueDate != null) ...[
                            Icon(
                              todo.isOverdue ? Icons.warning : Icons.schedule,
                              size: 14,
                              color: todo.isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MM月dd日').format(todo.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: todo.isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (todo.isOverdue) ...[
                              const SizedBox(width: 4),
                              Text(
                                '已逾期',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                          if (todo.priority > 0) ...[
                            if (todo.dueDate != null) const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(todo.priority).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                todo.priorityEnum.symbol,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getPriorityColor(todo.priority),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    ColorScheme colorScheme,
  ) {
    final searchService = SearchService();
    final spans = searchService.highlightQuery(text, query);

    return RichText(
      text: TextSpan(
        children: spans.map((span) {
          return TextSpan(
            text: span.text,
            style: span.isHighlight
                ? baseStyle.copyWith(
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : baseStyle,
          );
        }).toList(),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
