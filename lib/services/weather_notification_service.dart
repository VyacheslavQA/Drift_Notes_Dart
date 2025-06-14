// Путь: lib/services/weather_notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_alert_model.dart';
import '../models/weather_api_model.dart';
import '../models/notification_model.dart';
import 'weather/weather_api_service.dart';
import '../services/fishing_forecast_service.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';

class WeatherNotificationService {
  static final WeatherNotificationService _instance = WeatherNotificationService._internal();
  factory WeatherNotificationService() => _instance;
  WeatherNotificationService._internal();

  final WeatherApiService _weatherService = WeatherApiService();
  final FishingForecastService _forecastService = FishingForecastService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Таймеры для периодических проверок
  Timer? _periodicCheckTimer;
  Timer? _dailyForecastTimer;

  // Кэш последних данных для сравнения
  WeatherApiResponse? _lastWeatherData;
  WeatherNotificationSettings _settings = const WeatherNotificationSettings();

  // Ключи для SharedPreferences
  static const String _settingsKey = 'weather_notification_settings';
  static const String _lastWeatherKey = 'last_weather_data';
  static const String _lastNotificationTimeKey = 'last_notification_time_';

  // Глобальный ключ навигатора (будет установлен из main.dart)
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Установка ключа навигатора из main.dart
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('🌤️ Инициализация сервиса погодных уведомлений...');

    await _loadSettings();
    await _loadLastWeatherData();

    if (_settings.enabled) {
      _startPeriodicChecks();
      _scheduleDailyForecast(); // ИСПРАВЛЕНО: используем только таймер, без дублирующих локальных уведомлений
    }

    debugPrint('✅ Сервис погодных уведомлений инициализирован');
  }

  /// Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson);
        _settings = WeatherNotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки настроек погодных уведомлений: $e');
    }
  }

  /// Сохранение настроек
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настроек погодных уведомлений: $e');
    }
  }

  /// Загрузка последних данных о погоде
  Future<void> _loadLastWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWeatherJson = prefs.getString(_lastWeatherKey);

      if (lastWeatherJson != null) {
        final lastWeatherMap = json.decode(lastWeatherJson);
        _lastWeatherData = WeatherApiResponse.fromJson(lastWeatherMap);
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки последних данных о погоде: $e');
    }
  }

  /// Сохранение последних данных о погоде
  Future<void> _saveLastWeatherData(WeatherApiResponse weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = json.encode(weatherData.toJson());
      await prefs.setString(_lastWeatherKey, weatherJson);
      _lastWeatherData = weatherData;
    } catch (e) {
      debugPrint('❌ Ошибка сохранения данных о погоде: $e');
    }
  }

  /// Запуск периодических проверок погоды
  void _startPeriodicChecks() {
    _periodicCheckTimer?.cancel();

    // Проверяем каждые 30 минут
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkWeatherChanges();
    });

    // Первая проверка через 1 минуту после запуска
    Timer(const Duration(minutes: 1), () {
      _checkWeatherChanges();
    });
  }

  /// ИСПРАВЛЕНО: Планирование ежедневного прогноза через обычный таймер
  void _scheduleDailyForecast() {
    _dailyForecastTimer?.cancel();

    if (!_settings.dailyForecastEnabled) return;

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      _settings.dailyForecastHour,
      _settings.dailyForecastMinute,
    );

    // Если время уже прошло, планируем на завтра
    final nextScheduledTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    final delay = nextScheduledTime.difference(now);

    debugPrint('📅 Ежедневный прогноз запланирован на: ${nextScheduledTime.toString()}');

    _dailyForecastTimer = Timer(delay, () {
      _sendDailyForecast();
      _scheduleDailyForecast(); // Планируем следующий день
    });
  }

  /// Основная функция проверки изменений погоды
  Future<void> _checkWeatherChanges() async {
    if (!_settings.enabled) return;

    try {
      debugPrint('🔍 Проверка изменений погоды...');

      final position = await _getCurrentPosition();
      if (position == null) return;

      final currentWeather = await _weatherService.getForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        days: 1,
      );

      if (_lastWeatherData != null) {
        await _analyzeWeatherChanges(_lastWeatherData!, currentWeather);
      }

      await _checkFavorableConditions(currentWeather, position);
      await _checkStormWarning(currentWeather);

      await _saveLastWeatherData(currentWeather);

    } catch (e) {
      debugPrint('❌ Ошибка при проверке изменений погоды: $e');
    }
  }

  /// Анализ изменений погоды
  Future<void> _analyzeWeatherChanges(
      WeatherApiResponse oldWeather,
      WeatherApiResponse newWeather,
      ) async {
    // Проверка изменения давления
    if (_settings.pressureChangeEnabled) {
      await _checkPressureChange(oldWeather.current, newWeather.current);
    }

    // Проверка изменения температуры
    if (_settings.temperatureChangeEnabled) {
      await _checkTemperatureChange(oldWeather.current, newWeather.current);
    }

    // Проверка изменения ветра
    if (_settings.windChangeEnabled) {
      await _checkWindChange(oldWeather.current, newWeather.current);
    }
  }

  /// Проверка изменения давления
  Future<void> _checkPressureChange(Current oldCurrent, Current newCurrent) async {
    final oldPressureMmHg = oldCurrent.pressureMb / 1.333;
    final newPressureMmHg = newCurrent.pressureMb / 1.333;
    final pressureChange = (newPressureMmHg - oldPressureMmHg).abs();

    if (pressureChange >= _settings.pressureThreshold) {
      final isRising = newPressureMmHg > oldPressureMmHg;
      final trend = isRising ? 'растет' : 'падает';
      final impact = isRising ? 'улучшение клева' : 'ухудшение клева';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.pressureChange,
        title: 'Изменение атмосферного давления',
        message: 'Давление $trend на ${pressureChange.toStringAsFixed(1)} мм рт.ст. Ожидается $impact.',
        priority: pressureChange > 10 ? WeatherAlertPriority.high : WeatherAlertPriority.medium,
        createdAt: DateTime.now(),
        data: {
          'oldPressure': oldPressureMmHg,
          'newPressure': newPressureMmHg,
          'change': pressureChange,
          'isRising': isRising,
        },
      );

      await _sendWeatherAlert(alert);
    }
  }

  /// Проверка изменения температуры
  Future<void> _checkTemperatureChange(Current oldCurrent, Current newCurrent) async {
    final tempChange = (newCurrent.tempC - oldCurrent.tempC).abs();

    if (tempChange >= _settings.temperatureThreshold) {
      final isRising = newCurrent.tempC > oldCurrent.tempC;
      final trend = isRising ? 'повышается' : 'понижается';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.temperatureChange,
        title: 'Резкое изменение температуры',
        message: 'Температура $trend на ${tempChange.toStringAsFixed(1)}°C. Рыба может изменить поведение.',
        priority: WeatherAlertPriority.medium,
        createdAt: DateTime.now(),
        data: {
          'oldTemp': oldCurrent.tempC,
          'newTemp': newCurrent.tempC,
          'change': tempChange,
          'isRising': isRising,
        },
      );

      await _sendWeatherAlert(alert);
    }
  }

  /// Проверка изменения ветра
  Future<void> _checkWindChange(Current oldCurrent, Current newCurrent) async {
    final windSpeedChange = (newCurrent.windKph - oldCurrent.windKph).abs();

    if (windSpeedChange >= _settings.windSpeedThreshold) {
      final isIncreasing = newCurrent.windKph > oldCurrent.windKph;
      final trend = isIncreasing ? 'усиливается' : 'ослабевает';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.windChange,
        title: 'Изменение силы ветра',
        message: 'Ветер $trend. Скорость изменилась на ${(windSpeedChange / 3.6).toStringAsFixed(1)} м/с.',
        priority: WeatherAlertPriority.low,
        createdAt: DateTime.now(),
        data: {
          'oldWindKph': oldCurrent.windKph,
          'newWindKph': newCurrent.windKph,
          'change': windSpeedChange,
          'isIncreasing': isIncreasing,
        },
      );

      await _sendWeatherAlert(alert);
    }
  }

  /// Проверка благоприятных условий для рыбалки
  Future<void> _checkFavorableConditions(WeatherApiResponse weather, Position position) async {
    if (!_settings.favorableConditionsEnabled) return;

    // Проверяем, не отправляли ли мы уже уведомление о хороших условиях сегодня
    if (await _wasNotificationSentToday(WeatherAlertType.favorableConditions)) {
      return;
    }

    try {
      final forecast = await _forecastService.getFishingForecast(
        weather: weather,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final activity = forecast['overallActivity'] as double;
      final scorePoints = forecast['scorePoints'] as int;

      // Отправляем уведомление только при отличных условиях (80+ баллов)
      if (activity >= 0.8) {
        final bestWindows = forecast['bestTimeWindows'] as List<dynamic>;
        final nextWindow = bestWindows.isNotEmpty ? bestWindows.first : null;

        String timeInfo = '';
        if (nextWindow != null) {
          final startTime = DateTime.parse(nextWindow['startTime']);
          final endTime = DateTime.parse(nextWindow['endTime']);
          timeInfo = ' Лучшее время: ${_formatTime(startTime)} - ${_formatTime(endTime)}';
        }

        final alert = WeatherAlertModel(
          id: _uuid.v4(),
          type: WeatherAlertType.favorableConditions,
          title: 'Отличные условия для рыбалки!',
          message: 'Прогноз клева: $scorePoints баллов из 100.$timeInfo',
          priority: WeatherAlertPriority.medium,
          createdAt: DateTime.now(),
          data: {
            'activity': activity,
            'scorePoints': scorePoints,
            'bestWindows': bestWindows,
          },
        );

        await _sendWeatherAlert(alert);
        await _markNotificationSentToday(WeatherAlertType.favorableConditions);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке благоприятных условий: $e');
    }
  }

  /// Проверка предупреждений о шторме
  Future<void> _checkStormWarning(WeatherApiResponse weather) async {
    if (!_settings.stormWarningEnabled) return;

    final current = weather.current;
    final condition = current.condition.text.toLowerCase();

    bool hasStormConditions = false;
    String warningMessage = '';
    WeatherAlertPriority priority = WeatherAlertPriority.medium;

    // Проверяем различные опасные условия
    if (condition.contains('thunderstorm') || condition.contains('thunder')) {
      hasStormConditions = true;
      warningMessage = 'Ожидается гроза! Рыбалка может быть опасной.';
      priority = WeatherAlertPriority.high;
    } else if (current.windKph > 50) {
      hasStormConditions = true;
      warningMessage = 'Сильный ветер ${(current.windKph / 3.6).toStringAsFixed(1)} м/с. Будьте осторожны на воде!';
      priority = WeatherAlertPriority.high;
    } else if (condition.contains('heavy rain') || condition.contains('torrential')) {
      hasStormConditions = true;
      warningMessage = 'Ожидается сильный дождь. Рекомендуется отложить рыбалку.';
      priority = WeatherAlertPriority.medium;
    }

    if (hasStormConditions) {
      // Проверяем, не отправляли ли уже предупреждение в последние 3 часа
      if (await _wasNotificationSentRecently(WeatherAlertType.stormWarning, 3)) {
        return;
      }

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.stormWarning,
        title: 'Предупреждение о погоде',
        message: warningMessage,
        priority: priority,
        createdAt: DateTime.now(),
        data: {
          'windKph': current.windKph,
          'condition': current.condition.text,
          'conditionCode': current.condition.code,
        },
      );

      await _sendWeatherAlert(alert);
      await _markNotificationSentRecently(WeatherAlertType.stormWarning);
    }
  }

  /// Отправка ежедневного прогноза
  Future<void> _sendDailyForecast() async {
    if (!_settings.dailyForecastEnabled) return;

    try {
      debugPrint('📅 Отправка ежедневного прогноза...');

      final position = await _getCurrentPosition();
      if (position == null) return;

      final weather = await _weatherService.getForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        days: 3,
      );

      final forecast = await _forecastService.getFishingForecast(
        weather: weather,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final activity = forecast['overallActivity'] as double;
      final scorePoints = forecast['scorePoints'] as int;
      final recommendation = forecast['recommendation'] as String;

      String activityText = '';
      if (activity >= 0.8) {
        activityText = 'Отличные условия';
      } else if (activity >= 0.6) {
        activityText = 'Хорошие условия';
      } else if (activity >= 0.4) {
        activityText = 'Средние условия';
      } else {
        activityText = 'Слабые условия';
      }

      final temperature = weather.current.tempC.round();
      final windSpeed = (weather.current.windKph / 3.6).round();
      final pressure = (weather.current.pressureMb / 1.333).round();

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.dailyForecast,
        title: 'Прогноз рыбалки на сегодня',
        message: '$activityText ($scorePoints/100)\nT: $temperature°C, Ветер: $windSpeed м/с, Давление: $pressure мм',
        priority: WeatherAlertPriority.low,
        createdAt: DateTime.now(),
        data: {
          'activity': activity,
          'scorePoints': scorePoints,
          'recommendation': recommendation,
          'temperature': temperature,
          'windSpeed': windSpeed,
          'pressure': pressure,
        },
      );

      await _sendWeatherAlert(alert);

    } catch (e) {
      debugPrint('❌ Ошибка при отправке ежедневного прогноза: $e');
    }
  }

  /// ИСПРАВЛЕНО: Отправка погодного уведомления только через основной сервис уведомлений
  Future<void> _sendWeatherAlert(WeatherAlertModel weatherAlert) async {
    try {
      // Конвертируем погодное уведомление в общую модель уведомления
      final notification = NotificationModel(
        id: weatherAlert.id,
        title: weatherAlert.title,
        message: weatherAlert.message,
        type: _mapWeatherAlertTypeToNotificationType(weatherAlert.type),
        isRead: false,
        timestamp: weatherAlert.createdAt,
        data: weatherAlert.data,
      );

      // Отправляем ТОЛЬКО через основной сервис уведомлений
      // (он сам отправит push-уведомление через LocalPushNotificationService)
      await _notificationService.addNotification(notification);

      debugPrint('✅ Погодное уведомление отправлено: ${weatherAlert.title}');

    } catch (e) {
      debugPrint('❌ Ошибка при отправке погодного уведомления: $e');
    }
  }

  /// Мапинг типов погодных уведомлений в общие типы
  NotificationType _mapWeatherAlertTypeToNotificationType(WeatherAlertType weatherType) {
    switch (weatherType) {
      case WeatherAlertType.pressureChange:
      case WeatherAlertType.windChange:
      case WeatherAlertType.temperatureChange:
        return NotificationType.weatherUpdate;
      case WeatherAlertType.favorableConditions:
      case WeatherAlertType.biteActivity:
        return NotificationType.biteForecast;
      case WeatherAlertType.stormWarning:
        return NotificationType.weatherUpdate;
      case WeatherAlertType.dailyForecast:
        return NotificationType.biteForecast;
    }
  }

  /// Получение текущей позиции
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('❌ Ошибка получения геопозиции: $e');
      // Возвращаем Павлодар как fallback
      return Position(
        longitude: 76.9574,
        latitude: 52.2962,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  /// Проверка, отправлялось ли уведомление сегодня
  Future<bool> _wasNotificationSentToday(WeatherAlertType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastNotificationTimeKey}${type.toString()}';
      final lastSentTimestamp = prefs.getInt(key);

      if (lastSentTimestamp == null) return false;

      final lastSentDate = DateTime.fromMillisecondsSinceEpoch(lastSentTimestamp);
      final today = DateTime.now();

      return lastSentDate.day == today.day &&
          lastSentDate.month == today.month &&
          lastSentDate.year == today.year;
    } catch (e) {
      return false;
    }
  }

  /// Проверка, отправлялось ли уведомление недавно (в указанные часы)
  Future<bool> _wasNotificationSentRecently(WeatherAlertType type, int hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastNotificationTimeKey}${type.toString()}_recent';
      final lastSentTimestamp = prefs.getInt(key);

      if (lastSentTimestamp == null) return false;

      final lastSentTime = DateTime.fromMillisecondsSinceEpoch(lastSentTimestamp);
      final now = DateTime.now();

      return now.difference(lastSentTime).inHours < hours;
    } catch (e) {
      return false;
    }
  }

  /// Отметка об отправке уведомления сегодня
  Future<void> _markNotificationSentToday(WeatherAlertType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastNotificationTimeKey}${type.toString()}';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Ошибка отметки уведомления: $e');
    }
  }

  /// Отметка об отправке недавнего уведомления
  Future<void> _markNotificationSentRecently(WeatherAlertType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastNotificationTimeKey}${type.toString()}_recent';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Ошибка отметки недавнего уведомления: $e');
    }
  }

  /// Форматирование времени
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Публичные методы для управления настройками

  /// Получение текущих настроек
  WeatherNotificationSettings get settings => _settings;

  /// Обновление настроек
  Future<void> updateSettings(WeatherNotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();

    // Перезапускаем службы с новыми настройками
    if (_settings.enabled) {
      _startPeriodicChecks();
      _scheduleDailyForecast(); // ИСПРАВЛЕНО: используем обычный метод
    } else {
      _stopServices();
    }
  }

  /// Остановка всех служб
  void _stopServices() {
    _periodicCheckTimer?.cancel();
    _dailyForecastTimer?.cancel();
  }

  /// Принудительная проверка погоды прямо сейчас
  Future<void> forceWeatherCheck() async {
    debugPrint('🔄 Принудительная проверка погоды...');
    await _checkWeatherChanges();
  }

  /// Принудительная отправка ежедневного прогноза
  Future<void> forceDailyForecast() async {
    debugPrint('📅 Принудительная отправка ежедневного прогноза...');
    await _sendDailyForecast();
  }

  /// Очистка сервиса при выходе из приложения
  void dispose() {
    _stopServices();
  }
}