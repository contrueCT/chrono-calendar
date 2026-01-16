import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/countdown_model.dart';
import '../../../services/countdown_service.dart';
import '../../../core/utils/lunar_utils.dart';

/// 倒计时列表页面
class CountdownListScreen extends StatefulWidget {
  const CountdownListScreen({super.key});

  @override
  State<CountdownListScreen> createState() => _CountdownListScreenState();
}

class _CountdownListScreenState extends State<CountdownListScreen> {
  final CountdownService _countdownService = CountdownService();
  List<CountdownModel> _countdowns = [];
  bool _isLoading = true;
  String? _errorMessage;
  CountdownCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCountdowns();
  }

  Future<void> _loadCountdowns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _selectedCategory != null
        ? await _countdownService.getCountdownsByCategory(_selectedCategory!)
        : await _countdownService.getAllCountdowns();

    if (!mounted) return;

    result.when(
      success: (countdowns) {
        // 按剩余天数排序
        countdowns.sort((a, b) => a.getDaysRemaining().compareTo(b.getDaysRemaining()));
        setState(() {
          _countdowns = countdowns;
          _isLoading = false;
        });
      },
      failure: (error) {
        setState(() {
          _errorMessage = error.userFriendlyMessage;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('倒计时'),
        actions: [
          PopupMenuButton<CountdownCategory?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选分类',
            onSelected: (category) {
              setState(() => _selectedCategory = category);
              _loadCountdowns();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<CountdownCategory?>(
                value: null,
                child: Text('全部'),
              ),
              ...CountdownCategory.values.map((category) => PopupMenuItem(
                value: category,
                child: Text(_getCategoryName(category)),
              )),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(colorScheme)
              : _countdowns.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildCountdownList(colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/countdown/create');
          if (result == true) {
            _loadCountdowns();
          }
        },
        tooltip: '添加倒计时',
        child: const Icon(Icons.add),
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
            onPressed: _loadCountdowns,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无倒计时',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownList(ColorScheme colorScheme) {
    // 分组：今天、即将到来、已过期
    final todayCountdowns = <CountdownModel>[];
    final upcomingCountdowns = <CountdownModel>[];
    final pastCountdowns = <CountdownModel>[];

    for (final countdown in _countdowns) {
      final days = countdown.getDaysRemaining();
      if (days == 0) {
        todayCountdowns.add(countdown);
      } else if (days > 0) {
        upcomingCountdowns.add(countdown);
      } else {
        pastCountdowns.add(countdown);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadCountdowns,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (todayCountdowns.isNotEmpty) ...[
            _buildSectionHeader('今天', colorScheme, isHighlight: true),
            ...todayCountdowns.map((c) => _buildCountdownCard(c, colorScheme)),
            const SizedBox(height: 16),
          ],
          if (upcomingCountdowns.isNotEmpty) ...[
            _buildSectionHeader('即将到来', colorScheme),
            ...upcomingCountdowns.map((c) => _buildCountdownCard(c, colorScheme)),
            const SizedBox(height: 16),
          ],
          if (pastCountdowns.isNotEmpty) ...[
            _buildSectionHeader('已过去', colorScheme),
            ...pastCountdowns.map((c) => _buildCountdownCard(c, colorScheme, isPast: true)),
          ],
          const SizedBox(height: 80), // FAB 空间
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isHighlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCountdownCard(CountdownModel countdown, ColorScheme colorScheme, {bool isPast = false}) {
    final days = countdown.getDaysRemaining();
    final eventColor = Color(countdown.color ?? colorScheme.primary.toARGB32());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final result = await context.push<bool>('/countdown/${countdown.id}');
          if (result == true) {
            _loadCountdowns();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左侧图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(countdown.category),
                  color: eventColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 中间内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countdown.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPast
                            ? colorScheme.onSurface.withValues(alpha: 0.5)
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTargetDate(countdown),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (countdown.repeatYearly)
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '每年重复',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // 右侧天数
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPast
                      ? colorScheme.surfaceContainerHighest
                      : days == 0
                          ? colorScheme.primary
                          : eventColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      days == 0
                          ? '今天'
                          : days > 0
                              ? '$days'
                              : '${-days}',
                      style: TextStyle(
                        fontSize: days == 0 ? 14 : 20,
                        fontWeight: FontWeight.bold,
                        color: isPast
                            ? colorScheme.onSurfaceVariant
                            : days == 0
                                ? colorScheme.onPrimary
                                : eventColor,
                      ),
                    ),
                    if (days != 0)
                      Text(
                        days > 0 ? '天后' : '天前',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast
                              ? colorScheme.onSurfaceVariant
                              : eventColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTargetDate(CountdownModel countdown) {
    final targetDate = countdown.getNextTargetDate();
    final dateStr = DateFormat('yyyy年M月d日').format(targetDate);

    if (countdown.isLunar) {
      final lunarInfo = LunarUtils.getLunarInfo(targetDate);
      return '$dateStr (农历${lunarInfo.monthName}月${lunarInfo.dayName})';
    }

    return dateStr;
  }

  IconData _getCategoryIcon(CountdownCategory? category) {
    switch (category) {
      case CountdownCategory.birthday:
        return Icons.cake;
      case CountdownCategory.anniversary:
        return Icons.favorite;
      case CountdownCategory.holiday:
        return Icons.celebration;
      case CountdownCategory.deadline:
        return Icons.schedule;
      case CountdownCategory.other:
      default:
        return Icons.event;
    }
  }

  String _getCategoryName(CountdownCategory category) {
    switch (category) {
      case CountdownCategory.birthday:
        return '生日';
      case CountdownCategory.anniversary:
        return '纪念日';
      case CountdownCategory.holiday:
        return '节假日';
      case CountdownCategory.deadline:
        return '截止日期';
      case CountdownCategory.other:
        return '其他';
    }
  }
}
