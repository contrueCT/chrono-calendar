import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/todo_model.dart';
import '../../../services/todo_service.dart';

/// 待办筛选类型
enum TodoFilter {
  all('全部'),
  incomplete('未完成'),
  completed('已完成'),
  today('今天'),
  overdue('已逾期');

  final String label;
  const TodoFilter(this.label);
}

/// 待办列表页面
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoService _todoService = TodoService();
  List<TodoModel> _todos = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String? _errorMessage;
  TodoFilter _selectedFilter = TodoFilter.incomplete;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 并行加载待办和统计
    final results = await Future.wait([
      _loadTodos(),
      _loadStatistics(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTodos() async {
    final result = switch (_selectedFilter) {
      TodoFilter.all => await _todoService.getAllTodos(),
      TodoFilter.incomplete => await _todoService.getIncompleteTodos(),
      TodoFilter.completed => await _todoService.getCompletedTodos(),
      TodoFilter.today => await _todoService.getTodayTodos(),
      TodoFilter.overdue => await _todoService.getOverdueTodos(),
    };

    if (!mounted) return;

    result.when(
      success: (todos) {
        setState(() {
          _todos = todos;
        });
      },
      failure: (error) {
        setState(() {
          _errorMessage = error.userFriendlyMessage;
        });
      },
    );
  }

  Future<void> _loadStatistics() async {
    final result = await _todoService.getStatistics();
    if (!mounted) return;

    result.when(
      success: (stats) {
        setState(() {
          _statistics = stats;
        });
      },
      failure: (_) {
        // 统计加载失败不影响主列表显示
      },
    );
  }

  Future<void> _toggleComplete(TodoModel todo) async {
    final result = await _todoService.toggleComplete(todo.id);
    if (!mounted) return;

    result.when(
      success: (_) {
        _loadData();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyMessage)),
        );
      },
    );
  }

  Future<void> _deleteTodo(TodoModel todo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办'),
        content: Text('确定要删除"${todo.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _todoService.deleteTodo(todo.id);
    if (!mounted) return;

    result.when(
      success: (_) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('待办已删除')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyMessage)),
        );
      },
    );
  }

  Future<void> _clearCompleted() async {
    final completedCount = _statistics['completed'] ?? 0;
    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有已完成的待办')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除已完成'),
        content: Text('确定要删除所有 $completedCount 个已完成的待办吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _todoService.deleteCompletedTodos();
    if (!mounted) return;

    result.when(
      success: (count) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 $count 个待办')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyMessage)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_completed') {
                _clearCompleted();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 12),
                    Text('清除已完成'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(colorScheme)
              : Column(
                  children: [
                    // 统计卡片
                    _buildStatisticsCard(colorScheme),
                    // 筛选器
                    _buildFilterChips(colorScheme),
                    // 待办列表
                    Expanded(
                      child: _todos.isEmpty
                          ? _buildEmptyState(colorScheme)
                          : _buildTodoList(colorScheme),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/todo/create');
          if (result == true) {
            _loadData();
          }
        },
        tooltip: '添加待办',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsCard(ColorScheme colorScheme) {
    final total = _statistics['total'] ?? 0;
    final completed = _statistics['completed'] ?? 0;
    final incomplete = _statistics['incomplete'] ?? 0;
    final overdue = _statistics['overdue'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('待完成', incomplete, colorScheme.primary, colorScheme),
          _buildStatItem('已完成', completed, Colors.green, colorScheme),
          _buildStatItem('已逾期', overdue, colorScheme.error, colorScheme),
          _buildStatItem('总计', total, colorScheme.secondary, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                  _loadTodos();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final message = switch (_selectedFilter) {
      TodoFilter.all => '暂无待办',
      TodoFilter.incomplete => '所有待办都已完成',
      TodoFilter.completed => '暂无已完成的待办',
      TodoFilter.today => '今天没有待办',
      TodoFilter.overdue => '没有逾期的待办',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加新待办',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _todos.length + 1, // +1 for bottom padding
        itemBuilder: (context, index) {
          if (index == _todos.length) {
            return const SizedBox(height: 80); // FAB 空间
          }
          return _buildTodoCard(_todos[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildTodoCard(TodoModel todo, ColorScheme colorScheme) {
    final priorityColor = _getPriorityColor(todo.priority, colorScheme);
    final isCompleted = todo.isCompleted;
    final isOverdue = todo.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(todo.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete,
            color: colorScheme.onError,
          ),
        ),
        confirmDismiss: (_) async {
          await _deleteTodo(todo);
          return false; // 不自动移除，由 _loadData 刷新
        },
        child: InkWell(
          onTap: () async {
            final result = await context.push<bool>('/todo/${todo.id}');
            if (result == true) {
              _loadData();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 完成按钮
                GestureDetector(
                  onTap: () => _toggleComplete(todo),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 优先级标记
                          if (todo.priority > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                todo.priorityEnum.symbol,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // 标题
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isCompleted
                                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                                    : colorScheme.onSurface,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (todo.dueDate != null || todo.description != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (todo.dueDate != null) ...[
                              Icon(
                                isOverdue ? Icons.warning : Icons.schedule,
                                size: 14,
                                color: isOverdue
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDueDate(todo),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (todo.description != null && todo.dueDate != null)
                              const SizedBox(width: 12),
                            if (todo.description != null)
                              Expanded(
                                child: Text(
                                  todo.description!,
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
      ),
    );
  }

  Color _getPriorityColor(int priority, ColorScheme colorScheme) {
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

  String _formatDueDate(TodoModel todo) {
    if (todo.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
    final diff = due.difference(today).inDays;

    String dateStr;
    if (diff == 0) {
      dateStr = '今天';
    } else if (diff == 1) {
      dateStr = '明天';
    } else if (diff == -1) {
      dateStr = '昨天';
    } else if (diff > 0 && diff < 7) {
      dateStr = '$diff天后';
    } else if (diff < 0 && diff > -7) {
      dateStr = '${-diff}天前';
    } else {
      dateStr = DateFormat('M月d日').format(todo.dueDate!);
    }

    if (todo.dueTime != null) {
      dateStr += ' ${DateFormat('HH:mm').format(todo.dueTime!)}';
    }

    return dateStr;
  }
}
