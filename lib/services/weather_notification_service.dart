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

class WeatherNotificationService {
  static final WeatherNotificationService _instance =
  WeatherNotificationService._internal();
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
  static const String _languageKey = 'app_language';

  // Текущий язык приложения
  String _currentLanguage = 'ru';

  // Глобальный ключ навигатора (для совместимости)
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Статичные переводы для работы без контекста
  static const Map<String, Map<String, String>> _translations = {
    'ru': {
      // Изменение давления
      'weather_pressure_change_title': 'Изменение атмосферного давления',
      'weather_pressure_rising': 'растет',
      'weather_pressure_falling': 'падает',
      'weather_pressure_bite_improve': 'улучшение клева',
      'weather_pressure_bite_worsen': 'ухудшение клева',

      // Изменение температуры
      'weather_temp_change_title': 'Резкое изменение температуры',
      'weather_temp_rising': 'повышается',
      'weather_temp_falling': 'понижается',

      // Изменение ветра
      'weather_wind_change_title': 'Изменение силы ветра',
      'weather_wind_increasing': 'усиливается',
      'weather_wind_decreasing': 'ослабевает',

      // Благоприятные условия
      'weather_favorable_title': 'Отличные условия для рыбалки!',

      // Предупреждения о шторме
      'weather_storm_title': 'Предупреждение о погоде',
      'weather_storm_thunder': 'Ожидается гроза! Рыбалка может быть опасной.',
      'weather_storm_rain': 'Ожидается сильный дождь. Рекомендуется отложить рыбалку.',

      // Ежедневный прогноз
      'weather_daily_title': 'Прогноз рыбалки на сегодня',
      'weather_conditions_excellent': 'Отличные условия',
      'weather_conditions_good': 'Хорошие условия',
      'weather_conditions_fair': 'Средние условия',
      'weather_conditions_poor': 'Слабые условия',

      // Общие
      'weather_best_time': 'Лучшее время',
      'weather_forecast_score': 'Прогноз клева',
      'weather_points_of': 'баллов из',
      'weather_temp_label': 'T',
      'weather_wind_label': 'Ветер',
      'weather_pressure_label': 'Давление',
      'weather_pressure_unit': 'мм рт.ст.',
      'weather_wind_unit': 'м/с',
      'weather_fish_behavior_change': 'Рыба может изменить поведение.',
      'weather_speed_changed_by': 'Скорость изменилась на',
      'weather_be_careful_on_water': 'Будьте осторожны на воде!',
      'weather_strong_wind': 'Сильный ветер',
    },
    'en': {
      // Pressure change
      'weather_pressure_change_title': 'Atmospheric Pressure Change',
      'weather_pressure_rising': 'rising',
      'weather_pressure_falling': 'falling',
      'weather_pressure_bite_improve': 'bite improvement',
      'weather_pressure_bite_worsen': 'bite worsening',

      // Temperature change
      'weather_temp_change_title': 'Sharp Temperature Change',
      'weather_temp_rising': 'rising',
      'weather_temp_falling': 'falling',

      // Wind change
      'weather_wind_change_title': 'Wind Speed Change',
      'weather_wind_increasing': 'increasing',
      'weather_wind_decreasing': 'decreasing',

      // Favorable conditions
      'weather_favorable_title': 'Great Fishing Conditions!',

      // Storm warnings
      'weather_storm_title': 'Weather Warning',
      'weather_storm_thunder': 'Thunderstorm expected! Fishing may be dangerous.',
      'weather_storm_rain': 'Heavy rain expected. Recommended to postpone fishing.',

      // Daily forecast
      'weather_daily_title': 'Today\'s Fishing Forecast',
      'weather_conditions_excellent': 'Excellent conditions',
      'weather_conditions_good': 'Good conditions',
      'weather_conditions_fair': 'Fair conditions',
      'weather_conditions_poor': 'Poor conditions',

      // Common
      'weather_best_time': 'Best time',
      'weather_forecast_score': 'Bite forecast',
      'weather_points_of': 'points out of',
      'weather_temp_label': 'T',
      'weather_wind_label': 'Wind',
      'weather_pressure_label': 'Pressure',
      'weather_pressure_unit': 'mmHg',
      'weather_wind_unit': 'm/s',
      'weather_fish_behavior_change': 'Fish behavior may change.',
      'weather_speed_changed_by': 'Speed changed by',
      'weather_be_careful_on_water': 'Be careful on water!',
      'weather_strong_wind': 'Strong wind',
    },
  };

  /// Установка ключа навигатора из main.dart (для совместимости)
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    debugPrint('🔑 NavigatorKey установлен для WeatherNotificationService');
  }

  /// Статичная локализация без контекста
  String _t(String key) {
    return _translations[_currentLanguage]?[key] ??
        _translations['ru']?[key] ??
        key;
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('🌤️ Инициализация сервиса погодных уведомлений...');

    await _loadLanguage();
    await _loadSettings();
    await _loadLastWeatherData();

    if (_settings.enabled) {
      _startPeriodicChecks();
      _scheduleDailyForecast();
    }

    debugPrint('✅ Сервис погодных уведомлений инициализирован (язык: $_currentLanguage)');
  }

  /// Загрузка текущего языка приложения
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? 'ru';
      debugPrint('🌍 Загружен язык для уведомлений: $_currentLanguage');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки языка: $e');
      _currentLanguage = 'ru'; // Fallback
    }
  }

  /// Обновление языка (вызывается при смене языка в приложении)
  Future<void> updateLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    debugPrint('🌍 Язык уведомлений обновлен: $languageCode');
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

  /// Планирование ежедневного прогноза через обычный таймер
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
    final nextScheduledTime =
    scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    final delay = nextScheduledTime.difference(now);

    debugPrint(
      '📅 Ежедневный прогноз запланирован на: ${nextScheduledTime.toString()}',
    );

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
  Future<void> _checkPressureChange(
      Current oldCurrent,
      Current newCurrent,
      ) async {
    final oldPressureMmHg = oldCurrent.pressureMb / 1.333;
    final newPressureMmHg = newCurrent.pressureMb / 1.333;
    final pressureChange = (newPressureMmHg - oldPressureMmHg).abs();

    if (pressureChange >= _settings.pressureThreshold) {
      final isRising = newPressureMmHg > oldPressureMmHg;
      final trend = isRising ? _t('weather_pressure_rising') : _t('weather_pressure_falling');
      final impact = isRising ? _t('weather_pressure_bite_improve') : _t('weather_pressure_bite_worsen');
      final pressureUnit = _t('weather_pressure_unit');

      final title = _t('weather_pressure_change_title');
      final message = '${_t('weather_pressure_label')} $trend ${_t('weather_pressure_label').toLowerCase()} ${pressureChange.toStringAsFixed(1)} $pressureUnit. ${_t('weather_forecast_score')}: $impact.';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.pressureChange,
        title: title,
        message: message,
        priority: pressureChange > 10
            ? WeatherAlertPriority.high
            : WeatherAlertPriority.medium,
        createdAt: DateTime.now(),
        data: {
          'Изменение давления': '${pressureChange.toStringAsFixed(1)} $pressureUnit',
          'Направление': isRising ? 'Повышение' : 'Понижение',
          'Влияние на клев': isRising ? 'Положительное' : 'Отрицательное',
        },
      );

      await _sendWeatherAlert(alert);
    }
  }

  /// Проверка изменения температуры
  Future<void> _checkTemperatureChange(
      Current oldCurrent,
      Current newCurrent,
      ) async {
    final tempChange = (newCurrent.tempC - oldCurrent.tempC).abs();

    if (tempChange >= _settings.temperatureThreshold) {
      final isRising = newCurrent.tempC > oldCurrent.tempC;
      final trend = isRising ? _t('weather_temp_rising') : _t('weather_temp_falling');

      final title = _t('weather_temp_change_title');
      final message = '${_t('weather_temp_label')}температура $trend на ${tempChange.toStringAsFixed(1)}°C. ${_t('weather_fish_behavior_change')}';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.temperatureChange,
        title: title,
        message: message,
        priority: WeatherAlertPriority.medium,
        createdAt: DateTime.now(),
        data: {
          'Изменение температуры': '${tempChange.toStringAsFixed(1)}°C',
          'Направление': isRising ? 'Повышение' : 'Понижение',
          'Новая температура': '${newCurrent.tempC.round()}°C',
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
      final trend = isIncreasing ? _t('weather_wind_increasing') : _t('weather_wind_decreasing');
      final windUnit = _t('weather_wind_unit');

      final title = _t('weather_wind_change_title');
      final message = '${_t('weather_wind_label')} $trend. ${_t('weather_speed_changed_by')} ${(windSpeedChange / 3.6).toStringAsFixed(1)} $windUnit.';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.windChange,
        title: title,
        message: message,
        priority: WeatherAlertPriority.low,
        createdAt: DateTime.now(),
        data: {
          'Изменение скорости ветра': '${(windSpeedChange / 3.6).toStringAsFixed(1)} $windUnit',
          'Направление изменения': isIncreasing ? 'Усиление' : 'Ослабление',
          'Текущая скорость': '${(newCurrent.windKph / 3.6).toStringAsFixed(1)} $windUnit',
        },
      );

      await _sendWeatherAlert(alert);
    }
  }

  /// Проверка благоприятных условий для рыбалки
  Future<void> _checkFavorableConditions(
      WeatherApiResponse weather,
      Position position,
      ) async {
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
          timeInfo = ' ${_t('weather_best_time')}: ${_formatTime(startTime)} - ${_formatTime(endTime)}';
        }

        final title = _t('weather_favorable_title');
        final message = '${_t('weather_forecast_score')}: $scorePoints ${_t('weather_points_of')} 100.$timeInfo';

        final alert = WeatherAlertModel(
          id: _uuid.v4(),
          type: WeatherAlertType.favorableConditions,
          title: title,
          message: message,
          priority: WeatherAlertPriority.medium,
          createdAt: DateTime.now(),
          data: {
            // ✅ ИСПРАВЛЕНО: Убираем технические поля и добавляем полезные для пользователя
            'Рейтинг рыбалки': '$scorePoints баллов из 100',
            'Качество условий': activity >= 0.9 ? 'Превосходные' : 'Отличные',
            'Рекомендуемая активность': 'Активная рыбалка',
            // Убираем: activity, bestWindows (сложная структура)
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
      warningMessage = _t('weather_storm_thunder');
      priority = WeatherAlertPriority.high;
    } else if (current.windKph > 50) {
      hasStormConditions = true;
      final windSpeed = (current.windKph / 3.6).toStringAsFixed(1);
      final windUnit = _t('weather_wind_unit');
      warningMessage = '${_t('weather_strong_wind')} $windSpeed $windUnit. ${_t('weather_be_careful_on_water')}';
      priority = WeatherAlertPriority.high;
    } else if (condition.contains('heavy rain') ||
        condition.contains('torrential')) {
      hasStormConditions = true;
      warningMessage = _t('weather_storm_rain');
      priority = WeatherAlertPriority.medium;
    }

    if (hasStormConditions) {
      // Проверяем, не отправляли ли уже предупреждение в последние 3 часа
      if (await _wasNotificationSentRecently(
        WeatherAlertType.stormWarning,
        3,
      )) {
        return;
      }

      final title = _t('weather_storm_title');

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.stormWarning,
        title: title,
        message: warningMessage,
        priority: priority,
        createdAt: DateTime.now(),
        data: {
          'Скорость ветра': '${(current.windKph / 3.6).toStringAsFixed(1)} м/с',
          'Тип погодных условий': current.condition.text,
          'Уровень опасности': priority == WeatherAlertPriority.high ? 'Высокий' : 'Средний',
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

      String activityText = '';
      if (activity >= 0.8) {
        activityText = _t('weather_conditions_excellent');
      } else if (activity >= 0.6) {
        activityText = _t('weather_conditions_good');
      } else if (activity >= 0.4) {
        activityText = _t('weather_conditions_fair');
      } else {
        activityText = _t('weather_conditions_poor');
      }

      final temperature = weather.current.tempC.round();
      final windSpeed = (weather.current.windKph / 3.6).round();
      final pressure = (weather.current.pressureMb / 1.333).round();

      final tempLabel = _t('weather_temp_label');
      final windLabel = _t('weather_wind_label');
      final pressureLabel = _t('weather_pressure_label');
      final windUnit = _t('weather_wind_unit');
      final pressureUnit = _t('weather_pressure_unit');

      final title = _t('weather_daily_title');
      final message = '$activityText ($scorePoints/100)\n$tempLabel: $temperature°C, $windLabel: $windSpeed $windUnit, $pressureLabel: $pressure $pressureUnit';

      final alert = WeatherAlertModel(
        id: _uuid.v4(),
        type: WeatherAlertType.dailyForecast,
        title: title,
        message: message,
        priority: WeatherAlertPriority.low,
        createdAt: DateTime.now(),
        data: {
          // ✅ ИСПРАВЛЕНО: Заменяем технические поля на понятные пользователю
          'Баллы рыбалки': '$scorePoints баллов',
          'Качество условий': activityText,
          'Температура воздуха': '$temperature°C',
          'Скорость ветра': '$windSpeed $windUnit',
          'Атмосферное давление': '$pressure $pressureUnit',
          // Убираем: activity, temperature, windSpeed, pressure (сырые числа)
        },
      );

      await _sendWeatherAlert(alert);
    } catch (e) {
      debugPrint('❌ Ошибка при отправке ежедневного прогноза: $e');
    }
  }

  /// Отправка погодного уведомления через основной сервис уведомлений
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
      await _notificationService.addNotification(notification);

      debugPrint('✅ Погодное уведомление отправлено: ${weatherAlert.title}');
    } catch (e) {
      debugPrint('❌ Ошибка при отправке погодного уведомления: $e');
    }
  }

  /// Мапинг типов погодных уведомлений в общие типы
  NotificationType _mapWeatherAlertTypeToNotificationType(
      WeatherAlertType weatherType,
      ) {
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

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
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

      final lastSentDate = DateTime.fromMillisecondsSinceEpoch(
        lastSentTimestamp,
      );
      final today = DateTime.now();

      return lastSentDate.day == today.day &&
          lastSentDate.month == today.month &&
          lastSentDate.year == today.year;
    } catch (e) {
      return false;
    }
  }

  /// Проверка, отправлялось ли уведомление недавно (в указанные часы)
  Future<bool> _wasNotificationSentRecently(
      WeatherAlertType type,
      int hours,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastNotificationTimeKey}${type.toString()}_recent';
      final lastSentTimestamp = prefs.getInt(key);

      if (lastSentTimestamp == null) return false;

      final lastSentTime = DateTime.fromMillisecondsSinceEpoch(
        lastSentTimestamp,
      );
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
      _scheduleDailyForecast();
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