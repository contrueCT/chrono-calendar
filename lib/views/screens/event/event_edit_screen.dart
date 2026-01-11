import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/calendar_model.dart';
import '../../../viewmodels/event_edit_viewmodel.dart';
import '../../widgets/form/date_time_picker.dart';
import '../../widgets/form/reminder_picker.dart';
import '../../widgets/form/recurrence_picker.dart';
import '../../widgets/form/color_picker_field.dart';

/// 事件编辑页面
class EventEditScreen extends StatelessWidget {
  /// 要编辑的事件（为 null 时为创建模式）
  final EventModel? event;

  /// 初始日期（创建模式下使用）
  final DateTime? initialDate;

  const EventEditScreen({
    super.key,
    this.event,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventEditViewModel(
        originalEvent: event,
        initialDate: initialDate,
      ),
      child: const _EventEditScreenContent(),
    );
  }
}

class _EventEditScreenContent extends StatefulWidget {
  const _EventEditScreenContent();

  @override
  State<_EventEditScreenContent> createState() => _EventEditScreenContentState();
}

class _EventEditScreenContentState extends State<_EventEditScreenContent> {
  late TextEditingController _summaryController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<EventEditViewModel>();
    _summaryController = TextEditingController(text: viewModel.summary);
    _descriptionController = TextEditingController(text: viewModel.description ?? '');
    _locationController = TextEditingController(text: viewModel.location ?? '');
    _urlController = TextEditingController(text: viewModel.url ?? '');
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<EventEditViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: _buildAppBar(context, viewModel, colorScheme),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, viewModel, theme, colorScheme),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EventEditViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _handleClose(context, viewModel),
        icon: const Icon(Icons.close),
      ),
      title: Text(viewModel.isEditMode ? '编辑日程' : '新建日程'),
      actions: [
        // 保存按钮
        TextButton(
          onPressed: viewModel.isSaving ? null : () => _handleSave(context, viewModel),
          child: viewModel.isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Text(
                  '保存',
                  style: TextStyle(
                    color: viewModel.isSummaryValid ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 错误提示
          if (viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 标题输入
          _buildTitleField(viewModel, theme, colorScheme),
          const SizedBox(height: 24),

          // 全天事件开关
          _buildAllDaySwitch(viewModel, theme, colorScheme),
          const SizedBox(height: 16),

          // 日期时间选择
          DateTimeRangePicker(
            startDateTime: viewModel.dtStart,
            endDateTime: viewModel.dtEnd,
            isAllDay: viewModel.isAllDay,
            onStartDateChanged: (date) => viewModel.setStartDate(date),
            onStartTimeChanged: (time) => viewModel.setStartTime(time.hour, time.minute),
            onEndDateChanged: (date) => viewModel.setEndDate(date),
            onEndTimeChanged: (time) => viewModel.setEndTime(time.hour, time.minute),
          ),
          const SizedBox(height: 24),

          // 重复规则
          RecurrencePicker(
            rule: viewModel.recurrenceRule,
            eventStartDate: viewModel.dtStart,
            onChanged: viewModel.setRecurrenceRule,
          ),
          const SizedBox(height: 16),

          // 提醒设置
          ReminderPicker(
            selectedMinutes: viewModel.reminderMinutes,
            onAdd: viewModel.addReminder,
            onRemove: viewModel.removeReminder,
          ),
          const SizedBox(height: 24),

          // 地点
          _buildLocationField(viewModel, theme, colorScheme),
          const SizedBox(height: 16),

          // 描述
          _buildDescriptionField(viewModel, theme, colorScheme),
          const SizedBox(height: 24),

          // 日历选择
          _buildCalendarPicker(viewModel, theme, colorScheme),
          const SizedBox(height: 16),

          // 颜色选择
          CompactColorPicker(
            selectedColor: viewModel.color,
            onColorChanged: viewModel.setColor,
          ),
          const SizedBox(height: 16),

          // URL
          _buildUrlField(viewModel, theme, colorScheme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTitleField(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return TextField(
      controller: _summaryController,
      onChanged: viewModel.setSummary,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: '添加标题',
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildAllDaySwitch(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '全天事件',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Switch(
            value: viewModel.isAllDay,
            onChanged: viewModel.setIsAllDay,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _locationController,
              onChanged: viewModel.setLocation,
              decoration: const InputDecoration(
                hintText: '添加地点',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notes_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              onChanged: viewModel.setDescription,
              decoration: const InputDecoration(
                hintText: '添加备注',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPicker(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final selectedCalendar = viewModel.selectedCalendar;

    return InkWell(
      onTap: () => _showCalendarPicker(context, viewModel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 日历颜色指示器
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selectedCalendar != null
                    ? Color(selectedCalendar.color)
                    : colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '日历',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedCalendar?.name ?? '选择日历',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlField(
    EventEditViewModel viewModel,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _urlController,
              onChanged: viewModel.setUrl,
              decoration: const InputDecoration(
                hintText: '添加链接',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.url,
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendarPicker(BuildContext context, EventEditViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '选择日历',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.calendars.length,
              itemBuilder: (context, index) {
                final calendar = viewModel.calendars[index];
                final isSelected = calendar.id == viewModel.selectedCalendarId;

                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(calendar.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    calendar.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  subtitle: calendar.isDefault ? const Text('默认日历') : null,
                  trailing: isSelected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    viewModel.setSelectedCalendar(calendar.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, EventEditViewModel viewModel) async {
    final success = await viewModel.save();
    if (success && context.mounted) {
      context.pop(true); // 返回 true 表示保存成功
    }
  }

  void _handleClose(BuildContext context, EventEditViewModel viewModel) {
    // 检查是否有未保存的更改
    // 简单实现：直接返回
    context.pop(false);
  }
}
