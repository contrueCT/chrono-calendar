import 'package:flutter/material.dart';
import '../../../services/weather_service.dart';

/// 天气小组件 - 显示当前天气信息
class WeatherWidget extends StatefulWidget {
  final bool compact;
  final VoidCallback? onTap;

  const WeatherWidget({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _todayWeather;
  List<WeatherData>? _forecast;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getCurrentLocationWeather(days: 7);
      if (weather != null && weather.isNotEmpty) {
        setState(() {
          _todayWeather = weather.first;
          _forecast = weather;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '无法获取天气数据';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '获取天气失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactWidget(context);
    }
    return _buildFullWidget(context);
  }

  /// 紧凑模式（用于 AppBar 或小空间）
  Widget _buildCompactWidget(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const SizedBox(
        width: 60,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _todayWeather == null) {
      return const SizedBox.shrink();
    }

    final weather = _todayWeather!;
    final now = DateTime.now();
    final isNight = weather.sunset != null && now.isAfter(weather.sunset!);

    return GestureDetector(
      onTap: widget.onTap ?? () => _showWeatherDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              WeatherService.getWeatherIcon(weather.weatherIcon, isNight: isNight),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              '${weather.temperature.round()}°',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 完整模式（用于首页卡片）
  Widget _buildFullWidget(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Card(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _todayWeather == null) {
      return Card(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '无法获取天气',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: _loadWeather,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final weather = _todayWeather!;
    final now = DateTime.now();
    final isNight = weather.sunset != null && now.isAfter(weather.sunset!);

    return Card(
      child: InkWell(
        onTap: () => _showWeatherDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日天气
              Row(
                children: [
                  Text(
                    WeatherService.getWeatherIcon(weather.weatherIcon, isNight: isNight),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}°C',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          weather.weatherDescription,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 14, color: colorScheme.error),
                          Text(
                            '${weather.temperatureMax.round()}°',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 14, color: colorScheme.primary),
                          Text(
                            '${weather.temperatureMin.round()}°',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              if (_forecast != null && _forecast!.length > 1) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 未来几天预报
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecast!.length > 5 ? 5 : _forecast!.length,
                    itemBuilder: (context, index) {
                      if (index == 0) return const SizedBox.shrink(); // 跳过今天
                      final day = _forecast![index];
                      return _buildForecastDay(day, colorScheme);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastDay(WeatherData day, ColorScheme colorScheme) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[day.date.weekday % 7];

    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            WeatherService.getWeatherIcon(day.weatherIcon),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.temperatureMax.round()}°/${day.temperatureMin.round()}°',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeatherDetail(BuildContext context) {
    if (_forecast == null || _forecast!.isEmpty) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '7日天气预报',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _forecast!.length,
                  itemBuilder: (context, index) {
                    final day = _forecast![index];
                    return _buildDetailDay(day, colorScheme, isToday: index == 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailDay(WeatherData day, ColorScheme colorScheme, {bool isToday = false}) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = isToday ? '今天' : weekdays[day.date.weekday % 7];
    final dateStr = '${day.date.month}/${day.date.day}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            WeatherService.getWeatherIcon(day.weatherIcon),
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              day.weatherDescription,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${day.temperatureMax.round()}°',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${day.temperatureMin.round()}°',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
