import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'database_service.dart';
import '../core/constants/db_constants.dart';

/// 天气数据模型
class WeatherData {
  final DateTime date;
  final double temperature;
  final double temperatureMax;
  final double temperatureMin;
  final int weatherCode;
  final String weatherDescription;
  final String weatherIcon;
  final int humidity;
  final double windSpeed;
  final DateTime? sunrise;
  final DateTime? sunset;

  const WeatherData({
    required this.date,
    required this.temperature,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.weatherCode,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.humidity,
    required this.windSpeed,
    this.sunrise,
    this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      date: DateTime.parse(json['date'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      temperatureMax: (json['temperatureMax'] as num).toDouble(),
      temperatureMin: (json['temperatureMin'] as num).toDouble(),
      weatherCode: json['weatherCode'] as int,
      weatherDescription: json['weatherDescription'] as String,
      weatherIcon: json['weatherIcon'] as String,
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      sunrise: json['sunrise'] != null ? DateTime.parse(json['sunrise'] as String) : null,
      sunset: json['sunset'] != null ? DateTime.parse(json['sunset'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'temperatureMax': temperatureMax,
      'temperatureMin': temperatureMin,
      'weatherCode': weatherCode,
      'weatherDescription': weatherDescription,
      'weatherIcon': weatherIcon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'sunrise': sunrise?.toIso8601String(),
      'sunset': sunset?.toIso8601String(),
    };
  }
}

/// 天气服务 - 使用 Open-Meteo API（免费，无需 API Key）
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final Dio _dio = Dio();
  final DatabaseService _db = DatabaseService();

  // Open-Meteo API 基础 URL
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // 缓存有效期（小时）
  static const int _cacheHours = 3;

  // 当前位置缓存
  Position? _cachedPosition;
  DateTime? _positionCacheTime;

  /// 获取当前位置的天气
  Future<List<WeatherData>?> getCurrentLocationWeather({int days = 7}) async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      return getWeather(position.latitude, position.longitude, days: days);
    } catch (e) {
      debugPrint('获取当前位置天气失败: $e');
      return null;
    }
  }

  /// 获取指定位置的天气
  Future<List<WeatherData>?> getWeather(
    double latitude,
    double longitude, {
    int days = 7,
  }) async {
    try {
      // 先检查缓存
      final cached = await _getCachedWeather(latitude, longitude);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      // 从 API 获取
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset',
          'timezone': 'auto',
          'forecast_days': days,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final weatherList = _parseWeatherData(data);

        // 缓存数据
        await _cacheWeather(latitude, longitude, weatherList);

        return weatherList;
      }

      return null;
    } catch (e) {
      debugPrint('获取天气数据失败: $e');
      return null;
    }
  }

  /// 获取今日天气
  Future<WeatherData?> getTodayWeather() async {
    final weatherList = await getCurrentLocationWeather(days: 1);
    return weatherList?.isNotEmpty == true ? weatherList!.first : null;
  }

  /// 解析天气数据
  List<WeatherData> _parseWeatherData(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;

    if (daily == null) return [];

    final dates = (daily['time'] as List).cast<String>();
    final weatherCodes = (daily['weather_code'] as List).cast<int>();
    final tempMax = (daily['temperature_2m_max'] as List).cast<num>();
    final tempMin = (daily['temperature_2m_min'] as List).cast<num>();
    final sunrises = (daily['sunrise'] as List?)?.cast<String?>() ?? [];
    final sunsets = (daily['sunset'] as List?)?.cast<String?>() ?? [];

    final currentTemp = current?['temperature_2m'] as num? ?? 0;
    final currentHumidity = current?['relative_humidity_2m'] as int? ?? 0;
    final currentWindSpeed = current?['wind_speed_10m'] as num? ?? 0;

    final weatherList = <WeatherData>[];

    for (var i = 0; i < dates.length; i++) {
      final code = weatherCodes[i];
      final weatherInfo = _getWeatherInfo(code);

      weatherList.add(WeatherData(
        date: DateTime.parse(dates[i]),
        temperature: i == 0 ? currentTemp.toDouble() : (tempMax[i] + tempMin[i]) / 2,
        temperatureMax: tempMax[i].toDouble(),
        temperatureMin: tempMin[i].toDouble(),
        weatherCode: code,
        weatherDescription: weatherInfo['description'] as String,
        weatherIcon: weatherInfo['icon'] as String,
        humidity: i == 0 ? currentHumidity : 0,
        windSpeed: i == 0 ? currentWindSpeed.toDouble() : 0,
        sunrise: i < sunrises.length && sunrises[i] != null
            ? DateTime.tryParse(sunrises[i]!)
            : null,
        sunset: i < sunsets.length && sunsets[i] != null
            ? DateTime.tryParse(sunsets[i]!)
            : null,
      ));
    }

    return weatherList;
  }

  /// 根据天气代码获取描述和图标
  Map<String, dynamic> _getWeatherInfo(int code) {
    // WMO 天气代码映射
    switch (code) {
      case 0:
        return {'description': '晴', 'icon': 'sunny'};
      case 1:
      case 2:
      case 3:
        return {'description': '多云', 'icon': 'partly_cloudy'};
      case 45:
      case 48:
        return {'description': '雾', 'icon': 'foggy'};
      case 51:
      case 53:
      case 55:
        return {'description': '小雨', 'icon': 'rainy'};
      case 56:
      case 57:
        return {'description': '冻雨', 'icon': 'rainy'};
      case 61:
      case 63:
      case 65:
        return {'description': '雨', 'icon': 'rainy'};
      case 66:
      case 67:
        return {'description': '冻雨', 'icon': 'rainy'};
      case 71:
      case 73:
      case 75:
        return {'description': '雪', 'icon': 'snowy'};
      case 77:
        return {'description': '雪粒', 'icon': 'snowy'};
      case 80:
      case 81:
      case 82:
        return {'description': '阵雨', 'icon': 'rainy'};
      case 85:
      case 86:
        return {'description': '阵雪', 'icon': 'snowy'};
      case 95:
        return {'description': '雷暴', 'icon': 'thunderstorm'};
      case 96:
      case 99:
        return {'description': '雷暴冰雹', 'icon': 'thunderstorm'};
      default:
        return {'description': '未知', 'icon': 'cloudy'};
    }
  }

  /// 获取天气图标
  static String getWeatherIcon(String iconName, {bool isNight = false}) {
    switch (iconName) {
      case 'sunny':
        return isNight ? '🌙' : '☀️';
      case 'partly_cloudy':
        return isNight ? '☁️' : '⛅';
      case 'cloudy':
        return '☁️';
      case 'foggy':
        return '🌫️';
      case 'rainy':
        return '🌧️';
      case 'snowy':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  /// 获取当前位置
  Future<Position?> _getCurrentPosition() async {
    // 检查缓存
    if (_cachedPosition != null && _positionCacheTime != null) {
      final age = DateTime.now().difference(_positionCacheTime!);
      if (age.inMinutes < 30) {
        return _cachedPosition;
      }
    }

    try {
      // 检查权限
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('位置服务未启用');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('位置权限被拒绝');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('位置权限被永久拒绝');
        return null;
      }

      // 获取位置
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _cachedPosition = position;
      _positionCacheTime = DateTime.now();

      return position;
    } catch (e) {
      debugPrint('获取位置失败: $e');
      return null;
    }
  }

  /// 从缓存获取天气数据
  Future<List<WeatherData>?> _getCachedWeather(double latitude, double longitude) async {
    try {
      final db = await _db.database;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final maps = await db.query(
        DbConstants.tableWeatherCache,
        where: 'latitude = ? AND longitude = ? AND date >= ? AND cached_at >= ?',
        whereArgs: [
          latitude.toStringAsFixed(2),
          longitude.toStringAsFixed(2),
          todayStart.millisecondsSinceEpoch,
          DateTime.now().subtract(Duration(hours: _cacheHours)).millisecondsSinceEpoch,
        ],
        orderBy: 'date ASC',
      );

      if (maps.isEmpty) return null;

      return maps.map((map) {
        final weatherData = jsonDecode(map['weather_data'] as String) as Map<String, dynamic>;
        return WeatherData.fromJson(weatherData);
      }).toList();
    } catch (e) {
      debugPrint('获取缓存天气失败: $e');
      return null;
    }
  }

  /// 缓存天气数据
  Future<void> _cacheWeather(
    double latitude,
    double longitude,
    List<WeatherData> weatherList,
  ) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 删除旧缓存
      await db.delete(
        DbConstants.tableWeatherCache,
        where: 'latitude = ? AND longitude = ?',
        whereArgs: [
          latitude.toStringAsFixed(2),
          longitude.toStringAsFixed(2),
        ],
      );

      // 插入新缓存
      for (final weather in weatherList) {
        await db.insert(
          DbConstants.tableWeatherCache,
          {
            'latitude': double.parse(latitude.toStringAsFixed(2)),
            'longitude': double.parse(longitude.toStringAsFixed(2)),
            'date': weather.date.millisecondsSinceEpoch,
            'weather_data': jsonEncode(weather.toJson()),
            'cached_at': now,
          },
        );
      }
    } catch (e) {
      debugPrint('缓存天气数据失败: $e');
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    try {
      final db = await _db.database;
      await db.delete(DbConstants.tableWeatherCache);
    } catch (e) {
      debugPrint('清除天气缓存失败: $e');
    }
  }
}
