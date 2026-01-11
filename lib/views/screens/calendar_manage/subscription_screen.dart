import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../services/subscription_service.dart';
import '../../../core/constants/color_constants.dart';

/// 订阅管理页面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final CalendarRepository _calendarRepository = CalendarRepository();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<CalendarModel> _subscriptions = [];
  bool _isLoading = false;
  final Map<String, bool> _syncingMap = {};

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);

    try {
      final subscriptions = await _calendarRepository.getSubscriptionCalendars();
      setState(() {
        _subscriptions = subscriptions;
      });
    } catch (e) {
      _showError('加载订阅失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
        actions: [
          if (_subscriptions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncAllSubscriptions,
              tooltip: '同步全部',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubscriptionDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      return _buildSubscriptionCard(
                          context, _subscriptions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '还没有订阅日历',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '添加网络日历订阅，自动同步日程安排',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddSubscriptionDialog,
              icon: const Icon(Icons.add),
              label: const Text('添加订阅'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, CalendarModel subscription) {
    final theme = Theme.of(context);
    final isSyncing = _syncingMap[subscription.id] ?? false;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showSubscriptionDetails(subscription),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(subscription.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subscription.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 同步按钮
                  IconButton(
                    icon: isSyncing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.sync),
                    onPressed: isSyncing
                        ? null
                        : () => _syncSubscription(subscription),
                    tooltip: '立即同步',
                  ),
                  // 更多操作
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, subscription),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 12),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // URL
              Text(
                subscription.subscriptionUrl ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 同步信息
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '同步间隔: ${subscription.syncIntervalText}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (subscription.lastSyncTime != null) ...[
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '上次同步: ${_formatLastSync(subscription.lastSyncTime!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(lastSync);
    }
  }

  // ==================== 添加订阅 ====================

  Future<void> _showAddSubscriptionDialog() async {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    Color selectedColor = ColorConstants.eventColors.first;
    SyncInterval syncInterval = SyncInterval.daily;
    bool isValidating = false;
    String? urlError;
    int? eventCount;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('添加订阅'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // URL 输入
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: '订阅 URL',
                        hintText: 'https://...',
                        errorText: urlError,
                        border: const OutlineInputBorder(),
                        suffixIcon: isValidating
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  if (urlController.text.isEmpty) return;

                                  setState(() {
                                    isValidating = true;
                                    urlError = null;
                                  });

                                  final result = await _subscriptionService
                                      .validateSubscriptionUrl(urlController.text);

                                  setState(() {
                                    isValidating = false;
                                    if (result['valid'] == true) {
                                      if (nameController.text.isEmpty) {
                                        nameController.text =
                                            result['calendarName'] ?? '订阅日历';
                                      }
                                      eventCount = result['eventCount'];
                                      urlError = null;
                                    } else {
                                      urlError = result['error'];
                                      eventCount = null;
                                    }
                                  });
                                },
                                tooltip: '验证 URL',
                              ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    if (eventCount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '验证成功，包含 $eventCount 个日程',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 名称输入
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '日历名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 颜色选择
                    Text('颜色', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ColorConstants.eventColors.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 同步间隔
                    Text('同步间隔', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SyncInterval>(
                      value: syncInterval,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: SyncInterval.values.map((interval) {
                        return DropdownMenuItem(
                          value: interval,
                          child: Text(_getSyncIntervalText(interval)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => syncInterval = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: isValidating ||
                        urlController.text.isEmpty ||
                        nameController.text.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _addSubscription(
                          url: urlController.text,
                          name: nameController.text,
                          color: selectedColor.value,
                          syncInterval: syncInterval,
                        );
                      },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getSyncIntervalText(SyncInterval interval) {
    switch (interval) {
      case SyncInterval.manual:
        return '手动同步';
      case SyncInterval.hourly:
        return '每小时';
      case SyncInterval.daily:
        return '每天';
      case SyncInterval.weekly:
        return '每周';
    }
  }

  Future<void> _addSubscription({
    required String url,
    required String name,
    required int color,
    required SyncInterval syncInterval,
  }) async {
    setState(() => _isLoading = true);

    try {
      final calendar = await _subscriptionService.addSubscription(
        url: url,
        name: name,
        color: color,
        syncInterval: syncInterval,
      );

      if (calendar != null) {
        _showSuccess('订阅添加成功');
        await _loadSubscriptions();
      } else {
        _showError('添加订阅失败');
      }
    } catch (e) {
      _showError('添加订阅失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== 同步 ====================

  Future<void> _syncSubscription(CalendarModel subscription) async {
    setState(() => _syncingMap[subscription.id] = true);

    try {
      final result =
          await _subscriptionService.syncSubscription(subscription.id);

      if (result.success) {
        _showSuccess(
          '同步完成: 新增 ${result.addedCount}，更新 ${result.updatedCount}，删除 ${result.deletedCount}',
        );
        await _loadSubscriptions();
      } else {
        _showError('同步失败: ${result.error}');
      }
    } catch (e) {
      _showError('同步失败: $e');
    } finally {
      setState(() => _syncingMap[subscription.id] = false);
    }
  }

  Future<void> _syncAllSubscriptions() async {
    if (_subscriptions.isEmpty) return;

    for (final subscription in _subscriptions) {
      await _syncSubscription(subscription);
    }
  }

  // ==================== 其他操作 ====================

  void _handleMenuAction(String action, CalendarModel subscription) {
    switch (action) {
      case 'edit':
        _showEditDialog(subscription);
        break;
      case 'delete':
        _confirmDelete(subscription);
        break;
    }
  }

  Future<void> _showSubscriptionDetails(CalendarModel subscription) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(subscription.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subscription.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // URL
            _buildDetailRow(
              theme,
              Icons.link,
              '订阅地址',
              subscription.subscriptionUrl ?? '',
            ),
            const SizedBox(height: 12),

            // 同步间隔
            _buildDetailRow(
              theme,
              Icons.schedule,
              '同步间隔',
              subscription.syncIntervalText,
            ),
            const SizedBox(height: 12),

            // 上次同步
            _buildDetailRow(
              theme,
              Icons.update,
              '上次同步',
              subscription.lastSyncTime != null
                  ? DateFormat('yyyy-MM-dd HH:mm')
                      .format(subscription.lastSyncTime!)
                  : '从未同步',
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(subscription);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _syncSubscription(subscription);
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('立即同步'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(CalendarModel subscription) async {
    final nameController = TextEditingController(text: subscription.name);
    Color selectedColor = Color(subscription.color);
    SyncInterval syncInterval = subscription.syncInterval;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('编辑订阅'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '日历名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('颜色', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColorConstants.eventColors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('同步间隔', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<SyncInterval>(
                  value: syncInterval,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: SyncInterval.values.map((interval) {
                    return DropdownMenuItem(
                      value: interval,
                      child: Text(_getSyncIntervalText(interval)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => syncInterval = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final success = await _subscriptionService.updateSubscription(
        subscription.id,
        name: nameController.text,
        color: selectedColor.value,
        syncInterval: syncInterval,
      );

      if (success) {
        _showSuccess('更新成功');
        await _loadSubscriptions();
      } else {
        _showError('更新失败');
      }
    }
  }

  Future<void> _confirmDelete(CalendarModel subscription) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅'),
        content: Text('确定要删除订阅 "${subscription.name}" 吗？\n\n'
            '删除后，该订阅中的所有日程也将被删除。'),
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

    if (result == true) {
      final success =
          await _subscriptionService.deleteSubscription(subscription.id);

      if (success) {
        _showSuccess('删除成功');
        await _loadSubscriptions();
      } else {
        _showError('删除失败');
      }
    }
  }

  // ==================== 工具方法 ====================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
