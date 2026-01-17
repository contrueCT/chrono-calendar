import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/todo_model.dart';
import '../../../services/todo_service.dart';

/// 待办编辑页面
class TodoEditScreen extends StatefulWidget {
  /// 待办 ID（编辑模式）
  final String? todoId;

  /// 初始日期（创建模式）
  final DateTime? initialDate;

  const TodoEditScreen({
    super.key,
    this.todoId,
    this.initialDate,
  });

  @override
  State<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends State<TodoEditScreen> {
  final TodoService _todoService = TodoService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  TodoModel? _existingTodo;

  // 表单状态
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  int _priority = 0;
  bool _notifyEnabled = false;
  int _notifyMinutes = 30;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.todoId != null;
    if (_isEditing) {
      _loadTodo();
    } else {
      _dueDate = widget.initialDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTodo() async {
    setState(() => _isLoading = true);

    final result = await _todoService.getTodo(widget.todoId!);

    if (!mounted) return;

    result.when(
      success: (todo) {
        if (todo != null) {
          setState(() {
            _existingTodo = todo;
            _titleController.text = todo.title;
            _descriptionController.text = todo.description ?? '';
            _dueDate = todo.dueDate;
            _dueTime = todo.dueTime != null
                ? TimeOfDay.fromDateTime(todo.dueTime!)
                : null;
            _priority = todo.priority;
            _notifyEnabled = todo.notifyEnabled;
            _notifyMinutes = todo.notifyMinutes ?? 30;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('待办不存在')),
          );
          context.pop();
        }
      },
      failure: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyMessage)),
        );
        context.pop();
      },
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    DateTime? dueTime;
    if (_dueTime != null && _dueDate != null) {
      dueTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }

    final result = _isEditing
        ? await _updateTodo(dueTime)
        : await _createTodo(dueTime);

    if (!mounted) return;

    result.when(
      success: (_) {
        context.pop(true);
      },
      failure: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userFriendlyMessage)),
        );
      },
    );
  }

  Future<dynamic> _createTodo(DateTime? dueTime) async {
    final todo = TodoModel.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      dueDate: _dueDate,
      dueTime: dueTime,
      priority: _priority,
      notifyEnabled: _notifyEnabled,
      notifyMinutes: _notifyEnabled ? _notifyMinutes : null,
    );
    return _todoService.createTodo(todo);
  }

  Future<dynamic> _updateTodo(DateTime? dueTime) async {
    final todo = _existingTodo!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      clearDescription: _descriptionController.text.trim().isEmpty,
      dueDate: _dueDate,
      clearDueDate: _dueDate == null,
      dueTime: dueTime,
      clearDueTime: dueTime == null,
      priority: _priority,
      notifyEnabled: _notifyEnabled,
      notifyMinutes: _notifyEnabled ? _notifyMinutes : null,
      clearNotifyMinutes: !_notifyEnabled,
    );
    return _todoService.updateTodo(todo);
  }

  Future<void> _deleteTodo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办'),
        content: const Text('确定要删除这个待办吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await _todoService.deleteTodo(widget.todoId!);

    if (!mounted) return;

    result.when(
      success: (_) {
        context.pop(true);
      },
      failure: (error) {
        setState(() => _isLoading = false);
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
        title: Text(_isEditing ? '编辑待办' : '新建待办'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isLoading ? null : _deleteTodo,
              icon: Icon(Icons.delete, color: colorScheme.error),
              tooltip: '删除',
            ),
        ],
      ),
      body: _isLoading && _isEditing && _existingTodo == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 标题
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '请输入待办标题',
                      prefixIcon: Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入标题';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 描述
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '描述（可选）',
                      hintText: '添加备注或详细信息',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // 截止日期
                  _buildSectionTitle('截止时间', colorScheme),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(colorScheme),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeButton(colorScheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 优先级
                  _buildSectionTitle('优先级', colorScheme),
                  const SizedBox(height: 8),
                  _buildPrioritySelector(colorScheme),
                  const SizedBox(height: 24),

                  // 提醒
                  _buildSectionTitle('提醒', colorScheme),
                  const SizedBox(height: 8),
                  _buildReminderSection(colorScheme),
                  const SizedBox(height: 32),

                  // 保存按钮
                  FilledButton(
                    onPressed: _isLoading ? null : _saveTodo,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? '保存' : '创建'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDateButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: _selectDate,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        _dueDate != null
            ? DateFormat('yyyy-MM-dd').format(_dueDate!)
            : '选择日期',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTimeButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: _dueDate != null ? _selectTime : null,
      icon: const Icon(Icons.access_time, size: 18),
      label: Text(
        _dueTime != null
            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
            : '选择时间',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPrioritySelector(ColorScheme colorScheme) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('无'),
          icon: Icon(Icons.remove, size: 16),
        ),
        ButtonSegment(
          value: 1,
          label: Text('低'),
          icon: Icon(Icons.arrow_downward, size: 16),
        ),
        ButtonSegment(
          value: 2,
          label: Text('中'),
          icon: Icon(Icons.remove, size: 16),
        ),
        ButtonSegment(
          value: 3,
          label: Text('高'),
          icon: Icon(Icons.arrow_upward, size: 16),
        ),
      ],
      selected: {_priority},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _priority = newSelection.first;
        });
      },
      showSelectedIcon: false,
    );
  }

  Widget _buildReminderSection(ColorScheme colorScheme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('启用提醒'),
          subtitle: _notifyEnabled && _dueDate != null
              ? Text('提前 $_notifyMinutes 分钟提醒')
              : _dueDate == null
                  ? const Text('请先选择截止日期')
                  : null,
          value: _notifyEnabled && _dueDate != null,
          onChanged: _dueDate != null
              ? (value) {
                  setState(() => _notifyEnabled = value);
                }
              : null,
          contentPadding: EdgeInsets.zero,
        ),
        if (_notifyEnabled && _dueDate != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 30, 60, 120, 1440].map((minutes) {
              final isSelected = _notifyMinutes == minutes;
              String label;
              if (minutes < 60) {
                label = '$minutes分钟';
              } else if (minutes < 1440) {
                label = '${minutes ~/ 60}小时';
              } else {
                label = '${minutes ~/ 1440}天';
              }
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _notifyMinutes = minutes);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
