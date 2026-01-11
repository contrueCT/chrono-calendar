import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../services/icalendar_service.dart';
import '../../../services/reminder_manager.dart';

/// 导入导出页面
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final CalendarRepository _calendarRepository = CalendarRepository();
  final EventRepository _eventRepository = EventRepository();
  final ICalendarService _icalendarService = ICalendarService();

  List<CalendarModel> _calendars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final calendars = await _calendarRepository.getAllCalendars();
    setState(() {
      _calendars = calendars.where((c) => !c.isSubscription).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入导出'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 导入部分
                _buildSectionHeader(context, '导入', Icons.file_download),
                const SizedBox(height: 12),
                _buildImportCard(context),

                const SizedBox(height: 32),

                // 导出部分
                _buildSectionHeader(context, '导出', Icons.file_upload),
                const SizedBox(height: 12),
                _buildExportCard(context),

                const SizedBox(height: 32),

                // 提示信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '关于 iCalendar 格式',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'iCalendar (.ics) 是一种通用的日历数据格式，被 Google Calendar、'
                        'Apple Calendar、Outlook 等主流日历应用广泛支持。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImportCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '从文件导入',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择 .ics 文件导入日程到指定日历',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _importFromFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择文件'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导出到文件',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '将日历中的日程导出为 .ics 文件',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calendars.isEmpty ? null : _showExportDialog,
                icon: const Icon(Icons.ios_share),
                label: const Text('选择日历导出'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 导入功能 ====================

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content;

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        _showError('无法读取文件');
        return;
      }

      // 验证文件内容
      if (!_icalendarService.validateICalendar(content)) {
        _showError('无效的 iCalendar 文件');
        return;
      }

      // 获取文件信息
      final info = _icalendarService.getICalendarInfo(content);
      final eventCount = info['eventCount'] as int? ?? 0;

      if (eventCount == 0) {
        _showError('文件中没有日程');
        return;
      }

      // 显示导入预览对话框
      if (!mounted) return;
      await _showImportPreviewDialog(content, file.name, eventCount);
    } catch (e) {
      _showError('导入失败: $e');
    }
  }

  Future<void> _showImportPreviewDialog(
    String content,
    String fileName,
    int eventCount,
  ) async {
    CalendarModel? selectedCalendar =
        _calendars.isNotEmpty ? _calendars.first : null;
    bool skipDuplicates = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('导入预览'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: theme.textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$eventCount 个日程',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 目标日历选择
                  Text(
                    '导入到日历',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CalendarModel>(
                    value: selectedCalendar,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _calendars.map((calendar) {
                      return DropdownMenuItem(
                        value: calendar,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(calendar.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(calendar.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCalendar = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 跳过重复选项
                  CheckboxListTile(
                    value: skipDuplicates,
                    onChanged: (value) {
                      setState(() {
                        skipDuplicates = value ?? true;
                      });
                    },
                    title: const Text('跳过重复的日程'),
                    subtitle: const Text('根据 UID 判断是否重复'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: selectedCalendar == null
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('导入'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedCalendar != null) {
      await _performImport(content, selectedCalendar!, skipDuplicates);
    }
  }

  Future<void> _performImport(
    String content,
    CalendarModel calendar,
    bool skipDuplicates,
  ) async {
    setState(() => _isLoading = true);

    try {
      // 获取已存在的事件 UID（如果需要跳过重复）
      Set<String>? existingUids;
      if (skipDuplicates) {
        final existingEvents = await _eventRepository.getAllEvents();
        existingUids = existingEvents.map((e) => e.uid).toSet();
      }

      // 解析并导入
      final result = await _icalendarService.parseICalendar(
        content,
        targetCalendarId: calendar.id,
        existingUids: existingUids,
      );

      // 批量插入事件
      if (result.events.isNotEmpty) {
        await _eventRepository.insertEvents(result.events);

        // 保存提醒并调度通知
        final reminderManager = ReminderManager();
        for (final event in result.events) {
          final eventReminders = result.reminders[event.uid];
          if (eventReminders != null && eventReminders.isNotEmpty) {
            await _eventRepository.updateReminders(event.uid, eventReminders);
            await reminderManager.updateRemindersForEvent(event, eventReminders);
          }
        }
      }

      // 显示结果
      if (!mounted) return;
      _showImportResult(result);
    } catch (e) {
      _showError('导入失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImportResult(ICalendarImportResult result) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.errors.isEmpty ? Icons.check_circle : Icons.warning,
              color: result.errors.isEmpty
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('导入完成'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('成功导入 ${result.importedCount} 个日程'),
            if (result.skippedCount > 0)
              Text('跳过 ${result.skippedCount} 个重复日程'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '错误信息：',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              ...result.errors.take(3).map((e) => Text(
                    '• $e',
                    style: theme.textTheme.bodySmall,
                  )),
              if (result.errors.length > 3)
                Text(
                  '...还有 ${result.errors.length - 3} 个错误',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // ==================== 导出功能 ====================

  Future<void> _showExportDialog() async {
    // 选择要导出的日历
    final selectedCalendars = <CalendarModel>{};
    DateTime? startDate;
    DateTime? endDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('选择导出内容'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择日历',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...(_calendars.map((calendar) {
                    final isSelected = selectedCalendars.contains(calendar);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedCalendars.add(calendar);
                          } else {
                            selectedCalendars.remove(calendar);
                          }
                        });
                      },
                      title: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(calendar.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(calendar.name),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  })),
                  const Divider(height: 24),
                  Text(
                    '日期范围（可选）',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => startDate = date);
                            }
                          },
                          child: Text(
                            startDate != null
                                ? DateFormat('yyyy-MM-dd').format(startDate!)
                                : '开始日期',
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('至'),
                      ),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => endDate = date);
                            }
                          },
                          child: Text(
                            endDate != null
                                ? DateFormat('yyyy-MM-dd').format(endDate!)
                                : '结束日期',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (startDate != null || endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                          });
                        },
                        child: const Text('清除日期范围'),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: selectedCalendars.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('导出'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedCalendars.isNotEmpty) {
      await _performExport(
        selectedCalendars.toList(),
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  Future<void> _performExport(
    List<CalendarModel> calendars, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setState(() => _isLoading = true);

    try {
      // 收集要导出的事件
      final allEvents = <EventModel>[];
      final allReminders = <String, List<ReminderModel>>{};

      for (final calendar in calendars) {
        List<EventModel> events;

        if (startDate != null && endDate != null) {
          events = await _eventRepository.getEventsInRange(
            startDate,
            endDate.add(const Duration(days: 1)),
            calendarIds: [calendar.id],
          );
        } else {
          events = await _eventRepository.getEventsByCalendarId(calendar.id);
        }

        allEvents.addAll(events);

        // 收集提醒
        for (final event in events) {
          final reminders =
              await _eventRepository.getRemindersForEvent(event.uid);
          if (reminders.isNotEmpty) {
            allReminders[event.uid] = reminders;
          }
        }
      }

      if (allEvents.isEmpty) {
        _showError('没有可导出的日程');
        return;
      }

      // 生成日历名称
      final calendarName = calendars.length == 1
          ? calendars.first.name
          : 'Chrono Calendar';

      // 生成 iCalendar 内容
      final icsContent = _icalendarService.exportToICalendar(
        allEvents,
        calendarName: calendarName,
        reminders: allReminders,
      );

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'chrono_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.ics';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(icsContent);

      // 分享文件
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '导出的日历数据',
      );

      _showSuccess('已导出 ${allEvents.length} 个日程');
    } catch (e) {
      _showError('导出失败: $e');
    } finally {
      setState(() => _isLoading = false);
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
