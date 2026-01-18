import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/repositories/calendar_repository.dart';

/// 日历管理页面
class CalendarManageScreen extends StatefulWidget {
  const CalendarManageScreen({super.key});

  @override
  State<CalendarManageScreen> createState() => _CalendarManageScreenState();
}

class _CalendarManageScreenState extends State<CalendarManageScreen> {
  final CalendarRepository _repository = CalendarRepository();
  List<CalendarModel> _localCalendars = [];
  List<CalendarModel> _subscriptionCalendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);
    try {
      final calendars = await _repository.getAllCalendars();
      setState(() {
        _localCalendars = calendars.where((c) => !c.isSubscription).toList();
        _subscriptionCalendars = calendars.where((c) => c.isSubscription).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, '加载日历失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加日历',
            onPressed: () => _showCreateDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCalendars,
              child: ListView(
                children: [
                  // 本地日历
                  _buildSectionHeader('本地日历'),
                  if (_localCalendars.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无本地日历'),
                    )
                  else
                    ..._localCalendars.map(_buildCalendarTile),
                  const Divider(),

                  // 订阅日历
                  _buildSectionHeader('订阅日历'),
                  if (_subscriptionCalendars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('暂无订阅日历'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add_link),
                            label: const Text('添加订阅'),
                            onPressed: () => _showSubscribeDialog(),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ..._subscriptionCalendars.map(_buildCalendarTile),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_link),
                        label: const Text('添加订阅'),
                        onPressed: () => _showSubscribeDialog(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCalendarTile(CalendarModel calendar) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => _showColorPicker(calendar),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(calendar.color),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(calendar.name)),
          if (calendar.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '默认',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: calendar.isSubscription
          ? Text(
              calendar.subscriptionUrl ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 可见性开关
          IconButton(
            icon: Icon(
              calendar.isVisible ? Icons.visibility : Icons.visibility_off,
              color: calendar.isVisible ? null : Theme.of(context).disabledColor,
            ),
            tooltip: calendar.isVisible ? '隐藏' : '显示',
            onPressed: () => _toggleVisibility(calendar),
          ),
          // 更多选项
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, calendar),
            itemBuilder: (context) => [
              if (!calendar.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: ListTile(
                    leading: Icon(Icons.star),
                    title: Text('设为默认'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('编辑'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (calendar.isSubscription)
                const PopupMenuItem(
                  value: 'sync',
                  child: ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('立即同步'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              if (!calendar.isDefault)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, CalendarModel calendar) {
    switch (action) {
      case 'default':
        _setDefault(calendar);
        break;
      case 'edit':
        _showEditDialog(calendar);
        break;
      case 'sync':
        _syncCalendar(calendar);
        break;
      case 'delete':
        _showDeleteDialog(calendar);
        break;
    }
  }

  Future<void> _toggleVisibility(CalendarModel calendar) async {
    await _repository.toggleVisibility(calendar.id);
    _loadCalendars();
  }

  Future<void> _setDefault(CalendarModel calendar) async {
    await _repository.setDefaultCalendar(calendar.id);
    _loadCalendars();
    if (mounted) {
      SnackBarHelper.showSuccess(context, '已将「${calendar.name}」设为默认日历');
    }
  }

  Future<void> _syncCalendar(CalendarModel calendar) async {
    SnackBarHelper.show(context, '同步功能开发中...');
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    int selectedColor = ColorConstants.eventColors.first.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建日历'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '日历名称',
                  hintText: '输入日历名称',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('颜色: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final color = await _pickColor(Color(selectedColor));
                      if (color != null) {
                        setDialogState(() => selectedColor = color.value);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(selectedColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  SnackBarHelper.showWarning(context, '请输入日历名称');
                  return;
                }
                final exists = await _repository.isNameExists(name);
                if (exists) {
                  if (mounted) {
                    SnackBarHelper.showWarning(context, '日历名称已存在');
                  }
                  return;
                }
                final calendar = CalendarModel.create(
                  name: name,
                  color: selectedColor,
                );
                await _repository.insertCalendar(calendar);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCalendars();
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CalendarModel calendar) {
    final nameController = TextEditingController(text: calendar.name);
    int selectedColor = calendar.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑日历'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '日历名称',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('颜色: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final color = await _pickColor(Color(selectedColor));
                      if (color != null) {
                        setDialogState(() => selectedColor = color.value);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(selectedColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  SnackBarHelper.showWarning(context, '请输入日历名称');
                  return;
                }
                if (name != calendar.name) {
                  final exists = await _repository.isNameExists(name, excludeId: calendar.id);
                  if (exists) {
                    if (mounted) {
                      SnackBarHelper.showWarning(context, '日历名称已存在');
                    }
                    return;
                  }
                }
                final updated = calendar.copyWith(
                  name: name,
                  color: selectedColor,
                );
                await _repository.updateCalendar(updated);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCalendars();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(CalendarModel calendar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日历'),
        content: Text('确定要删除「${calendar.name}」吗？\n该日历中的所有事件也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _repository.deleteCalendar(calendar.id);
              if (mounted) {
                Navigator.pop(context);
                _loadCalendars();
                SnackBarHelper.showSuccess(context, '已删除「${calendar.name}」');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    int selectedColor = ColorConstants.eventColors.first.value;
    SyncInterval syncInterval = SyncInterval.daily;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('订阅日历'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '日历名称',
                    hintText: '输入日历名称',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: '订阅 URL',
                    hintText: 'https://example.com/calendar.ics',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('颜色: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final color = await _pickColor(Color(selectedColor));
                        if (color != null) {
                          setDialogState(() => selectedColor = color.value);
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(selectedColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SyncInterval>(
                  value: syncInterval,
                  decoration: const InputDecoration(
                    labelText: '同步间隔',
                  ),
                  items: const [
                    DropdownMenuItem(value: SyncInterval.manual, child: Text('手动')),
                    DropdownMenuItem(value: SyncInterval.hourly, child: Text('每小时')),
                    DropdownMenuItem(value: SyncInterval.daily, child: Text('每天')),
                    DropdownMenuItem(value: SyncInterval.weekly, child: Text('每周')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => syncInterval = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (name.isEmpty) {
                  SnackBarHelper.showWarning(context, '请输入日历名称');
                  return;
                }
                if (url.isEmpty) {
                  SnackBarHelper.showWarning(context, '请输入订阅 URL');
                  return;
                }
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  SnackBarHelper.showWarning(context, '请输入有效的 URL');
                  return;
                }
                final exists = await _repository.isNameExists(name);
                if (exists) {
                  if (mounted) {
                    SnackBarHelper.showWarning(context, '日历名称已存在');
                  }
                  return;
                }
                final calendar = CalendarModel.createSubscription(
                  name: name,
                  subscriptionUrl: url,
                  color: selectedColor,
                  syncInterval: syncInterval,
                );
                await _repository.insertCalendar(calendar);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCalendars();
                }
              },
              child: const Text('订阅'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(CalendarModel calendar) async {
    final color = await _pickColor(Color(calendar.color));
    if (color != null) {
      await _repository.updateColor(calendar.id, color.value);
      _loadCalendars();
    }
  }

  Future<Color?> _pickColor(Color initialColor) async {
    Color pickedColor = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: initialColor,
            availableColors: ColorConstants.eventColors,
            onColorChanged: (color) => pickedColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pickedColor),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
