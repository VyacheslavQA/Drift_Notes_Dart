// Путь: lib/services/fishing_forecast_service.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_api_model.dart';
import '../models/bite_forecast_model.dart';
import '../services/bite_forecast_service.dart';
import '../localization/app_localizations.dart';

class FishingForecastService {
  // Singleton pattern
  static final FishingForecastService _instance =
      FishingForecastService._internal();
  factory FishingForecastService() => _instance;
  FishingForecastService._internal();

  final BiteForecastService _biteForecastService = BiteForecastService();

  /// Главный метод получения прогноза рыбалки
  Future<Map<String, dynamic>> getFishingForecast({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    debugPrint('🎣 Получаем полный прогноз рыбалки...');

    try {
      // Получаем детальный прогноз клева
      final biteForecast = await _biteForecastService.calculateBiteForecast(
        weather: weather,
        latitude: latitude,
        longitude: longitude,
        context: context,
      );

      // Анализируем почасовые данные
      final hourlyForecast = _generateHourlyForecast(weather, biteForecast);

      // Определяем лучшие временные окна
      final bestTimeWindows = _enhanceBestTimeWindows(
        weather,
        biteForecast,
        context,
      );

      // Генерируем практические рекомендации
      final practicalTips = _generatePracticalTips(
        weather,
        biteForecast,
        context,
      );

      // Создаем итоговый прогноз
      final forecast = {
        'overallActivity': biteForecast.overallActivity,
        'scorePoints': biteForecast.scorePoints,
        'level': biteForecast.level.displayName,
        'recommendation': biteForecast.recommendation,
        'tips': biteForecast.tips,
        'factors': _formatFactors(biteForecast.factors, context),
        'bestTimeWindows': bestTimeWindows,
        'hourlyForecast': hourlyForecast,
        'practicalTips': practicalTips,
        'pressureTrend': _analyzePressureTrend(weather),
        'windAnalysis': _analyzeWindForFishing(weather, context),
        'moonAnalysis': _analyzeMoonForFishing(weather, context),
        'optimalDepth': _recommendOptimalDepth(weather, biteForecast),
        'recommendedBaits': _recommendBaits(weather, biteForecast, context),
        'fishingTechnique': _recommendTechnique(weather, biteForecast, context),
        'calculatedAt': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '✅ Полный прогноз рыбалки готов: ${biteForecast.scorePoints} баллов',
      );
      return forecast;
    } catch (e) {
      debugPrint('❌ Ошибка при получении прогноза рыбалки: $e');

      // Возвращаем базовый прогноз
      return {
        'overallActivity': 0.5,
        'scorePoints': 50,
        'level': 'moderate_activity',
        'recommendation':
            context != null
                ? AppLocalizations.of(
                  context,
                ).translate('moderate_conditions_recommendation')
                : 'Умеренные условия для рыбалки',
        'tips': <String>[],
        'factors': <String, dynamic>{},
        'bestTimeWindows': <Map<String, dynamic>>[],
        'hourlyForecast': <Map<String, dynamic>>[],
        'practicalTips': <String>[],
        'calculatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Генерация почасового прогноза клева
  List<Map<String, dynamic>> _generateHourlyForecast(
    WeatherApiResponse weather,
    BiteForecastModel biteForecast,
  ) {
    final hourlyForecast = <Map<String, dynamic>>[];

    try {
      if (weather.forecast.isNotEmpty &&
          weather.forecast.first.hour.isNotEmpty) {
        final hours = weather.forecast.first.hour;
        final now = DateTime.now();

        // Берем следующие 12 часов
        for (int i = 0; i < math.min(12, hours.length); i++) {
          final hour = hours[i];
          final hourTime = DateTime.parse(hour.time);

          if (hourTime.isAfter(now)) {
            final hourlyActivity = _calculateHourlyActivity(hour, biteForecast);

            hourlyForecast.add({
              'time': hourTime.toIso8601String(),
              'hour': hourTime.hour,
              'temperature': hour.tempC,
              'windKph': hour.windKph,
              'windDir': hour.windDir,
              'humidity': hour.humidity,
              'chanceOfRain': hour.chanceOfRain,
              'condition': hour.condition.text,
              'conditionCode': hour.condition.code,
              'biteActivity': hourlyActivity,
              'biteLevel': _getBiteLevel(hourlyActivity),
              'recommendation': _getHourlyRecommendation(hourlyActivity),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при генерации почасового прогноза: $e');
    }

    return hourlyForecast;
  }

  /// Расчет активности клева для конкретного часа
  double _calculateHourlyActivity(Hour hour, BiteForecastModel baseForecast) {
    double activity = baseForecast.overallActivity;

    try {
      final hourTime = DateTime.parse(hour.time);
      final hourOfDay = hourTime.hour;

      // Корректировка по времени суток
      if ((hourOfDay >= 5 && hourOfDay <= 8) ||
          (hourOfDay >= 18 && hourOfDay <= 21)) {
        activity *= 1.2; // Золотые часы
      } else if (hourOfDay >= 22 || hourOfDay <= 4) {
        activity *= 0.7; // Ночное время
      }

      // Корректировка по температуре
      if (hour.tempC >= 15 && hour.tempC <= 25) {
        activity *= 1.1;
      } else if (hour.tempC < 5 || hour.tempC > 30) {
        activity *= 0.8;
      }

      // Корректировка по ветру
      if (hour.windKph >= 3 && hour.windKph <= 15) {
        activity *= 1.1;
      } else if (hour.windKph > 25) {
        activity *= 0.6;
      }

      // Корректировка по осадкам
      if (hour.chanceOfRain > 50) {
        activity *= 0.8;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при расчете активности для часа: $e');
    }

    return math.max(0.0, math.min(1.0, activity));
  }

  /// Определение уровня клева для часа
  String _getBiteLevel(double activity) {
    if (activity >= 0.8) return 'excellent_activity';
    if (activity >= 0.6) return 'good_activity';
    if (activity >= 0.4) return 'moderate_activity';
    if (activity >= 0.2) return 'poor_activity';
    return 'very_poor_activity';
  }

  /// Рекомендация для конкретного часа
  String _getHourlyRecommendation(double activity) {
    if (activity >= 0.8) return 'excellent_conditions_recommendation';
    if (activity >= 0.6) return 'good_conditions_recommendation';
    if (activity >= 0.4) return 'moderate_conditions_recommendation';
    if (activity >= 0.2) return 'poor_conditions_recommendation';
    return 'very_poor_conditions_recommendation';
  }

  /// Улучшение временных окон с дополнительной информацией
  List<Map<String, dynamic>> _enhanceBestTimeWindows(
    WeatherApiResponse weather,
    BiteForecastModel biteForecast,
    BuildContext? context,
  ) {
    final enhancedWindows = <Map<String, dynamic>>[];

    try {
      for (final window in biteForecast.bestTimeWindows) {
        enhancedWindows.add({
          'startTime': window.startTime.toIso8601String(),
          'endTime': window.endTime.toIso8601String(),
          'timeRange': window.timeRange,
          'activity': window.activity,
          'activityLevel': _getBiteLevel(window.activity),
          'reason': window.reason,
          'recommendations': window.recommendations,
          'optimalFor': _getOptimalFor(window.activity),
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка при улучшении временных окон: $e');
    }

    return enhancedWindows;
  }

  /// Определение оптимальности временного окна
  List<String> _getOptimalFor(double activity) {
    final optimal = <String>[];

    if (activity >= 0.8) {
      optimal.addAll(['spinning', 'feeder', 'float_fishing', 'carp_fishing']);
    } else if (activity >= 0.6) {
      optimal.addAll(['spinning', 'feeder']);
    } else if (activity >= 0.4) {
      optimal.add('feeder');
    }

    return optimal;
  }

  /// Форматирование факторов для UI
  Map<String, dynamic> _formatFactors(
    Map<String, BiteFactor> factors,
    BuildContext? context,
  ) {
    final formatted = <String, dynamic>{};

    try {
      for (final entry in factors.entries) {
        final factor = entry.value;
        formatted[entry.key] = {
          'name': factor.name,
          'value': factor.value,
          'weight': factor.weight,
          'impact': factor.impact.toString().split('.').last,
          'description': factor.description,
          'score': (factor.value * 100).round(),
          'level': _getFactorLevel(factor.value),
          'recommendation': _getFactorRecommendation(
            entry.key,
            factor.value,
            context,
          ),
        };
      }
    } catch (e) {
      debugPrint('❌ Ошибка при форматировании факторов: $e');
    }

    return formatted;
  }

  /// Определение уровня фактора
  String _getFactorLevel(double value) {
    if (value >= 0.8) return 'excellent';
    if (value >= 0.6) return 'good';
    if (value >= 0.4) return 'moderate';
    if (value >= 0.2) return 'poor';
    return 'very_poor';
  }

  /// Рекомендация для конкретного фактора
  String _getFactorRecommendation(
    String factorName,
    double value,
    BuildContext? context,
  ) {
    switch (factorName) {
      case 'pressure':
        if (value >= 0.7)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('pressure_stable_good'),
              ) ??
              'Стабильное давление благоприятно';
        if (value < 0.4)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('pressure_low_bad'),
              ) ??
              'Низкое давление - рыба пассивна';
        return context?.let(
              (c) => AppLocalizations.of(c).translate('pressure_high_bad'),
            ) ??
            'Высокое давление - клев слабый';

      case 'wind':
        if (value >= 0.7)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('wind_optimal'),
              ) ??
              'Оптимальный ветер';
        if (value < 0.4)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('wind_calm'),
              ) ??
              'Штиль - используйте легкие приманки';
        return context?.let(
              (c) => AppLocalizations.of(c).translate('wind_strong'),
            ) ??
            'Сильный ветер затрудняет рыбалку';

      case 'moon':
        if (value >= 0.7)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('moon_active_phase'),
              ) ??
              'Активная фаза луны';
        return context?.let(
              (c) => AppLocalizations.of(c).translate('moon_passive_phase'),
            ) ??
            'Пассивная фаза луны';

      case 'temperature':
        if (value >= 0.7)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('temperature_optimal'),
              ) ??
              'Комфортная температура';
        if (value < 0.4)
          return context?.let(
                (c) => AppLocalizations.of(c).translate('temperature_cold'),
              ) ??
              'Холодная погода';
        return context?.let(
              (c) => AppLocalizations.of(c).translate('temperature_hot'),
            ) ??
            'Жаркая погода';

      default:
        return 'Нормальные условия';
    }
  }

  /// Анализ тренда давления
  Map<String, dynamic> _analyzePressureTrend(WeatherApiResponse weather) {
    // Упрощенный анализ - в реальном приложении нужны исторические данные
    final currentPressure = weather.current.pressureMb;

    return {
      'current': currentPressure,
      'trend':
          'stable', // stable, rising, falling, rapidly_rising, rapidly_falling
      'change24h': 0.0, // Изменение за 24 часа
      'recommendation':
          currentPressure >= 1010 && currentPressure <= 1025
              ? 'pressure_stable_good'
              : 'pressure_unstable',
    };
  }

  /// Анализ ветра для рыбалки
  Map<String, dynamic> _analyzeWindForFishing(
    WeatherApiResponse weather,
    BuildContext? context,
  ) {
    final wind = weather.current;
    final windKph = wind.windKph;
    final windDir = wind.windDir;

    String impact;
    if (windKph >= 3 && windKph <= 15) {
      impact = 'wind_impact_excellent';
    } else if (windKph <= 20) {
      impact = 'wind_impact_good';
    } else if (windKph <= 30) {
      impact = 'wind_impact_moderate';
    } else {
      impact = 'wind_impact_poor';
    }

    return {
      'speed': windKph,
      'direction': windDir,
      'impact': impact,
      'fishingAdvice': _getWindFishingAdvice(windKph, windDir),
      'optimalSide': _getOptimalFishingSide(windDir),
    };
  }

  /// Советы по ветру для рыбалки
  String _getWindFishingAdvice(double windKph, String windDir) {
    if (windKph < 3) return 'wind_calm';
    if (windKph <= 15) return 'wind_optimal';
    return 'wind_strong';
  }

  /// Оптимальная сторона для рыбалки по ветру
  String _getOptimalFishingSide(String windDir) {
    // Упрощенная логика - обычно лучше ловить с наветренной стороны
    switch (windDir.toUpperCase()) {
      case 'N':
        return 'south_side';
      case 'S':
        return 'north_side';
      case 'E':
        return 'west_side';
      case 'W':
        return 'east_side';
      default:
        return 'windward_side';
    }
  }

  /// Анализ луны для рыбалки
  Map<String, dynamic> _analyzeMoonForFishing(
    WeatherApiResponse weather,
    BuildContext? context,
  ) {
    if (weather.forecast.isEmpty) {
      return {
        'phase': 'unknown',
        'impact': 'moon_impact_moderate',
        'recommendation': 'Данные о луне недоступны',
      };
    }

    final moonPhase = weather.forecast.first.astro.moonPhase;
    final phaseLower = moonPhase.toLowerCase();

    String impact;
    if (phaseLower.contains('new') || phaseLower.contains('full')) {
      impact = 'moon_impact_excellent';
    } else if (phaseLower.contains('waxing') || phaseLower.contains('waning')) {
      impact = 'moon_impact_good';
    } else {
      impact = 'moon_impact_moderate';
    }

    return {
      'phase': moonPhase,
      'impact': impact,
      'recommendation':
          impact == 'moon_impact_excellent'
              ? 'moon_active_phase'
              : 'moon_passive_phase',
    };
  }

  /// Рекомендация оптимальной глубины
  Map<String, dynamic> _recommendOptimalDepth(
    WeatherApiResponse weather,
    BiteForecastModel forecast,
  ) {
    final pressure = weather.current.pressureMb;
    final temp = weather.current.tempC;

    String depth;
    String reason;

    if (pressure < 1005) {
      depth = 'deep';
      reason = 'Низкое давление - рыба уходит на глубину';
    } else if (temp > 25) {
      depth = 'deep';
      reason = 'Жаркая погода - рыба ищет прохладу на глубине';
    } else if (temp < 10) {
      depth = 'shallow';
      reason = 'Холодная погода - рыба ближе к поверхности';
    } else {
      depth = 'medium';
      reason = 'Оптимальные условия - средняя глубина';
    }

    return {
      'recommended': depth, // shallow, medium, deep
      'reason': reason,
      'metersRange': _getDepthRange(depth),
    };
  }

  /// Диапазон глубин в метрах
  String _getDepthRange(String depth) {
    switch (depth) {
      case 'shallow':
        return '0.5-2м';
      case 'medium':
        return '2-5м';
      case 'deep':
        return '5-15м';
      default:
        return '2-5м';
    }
  }

  /// Рекомендация приманок
  List<Map<String, dynamic>> _recommendBaits(
    WeatherApiResponse weather,
    BiteForecastModel forecast,
    BuildContext? context,
  ) {
    final baits = <Map<String, dynamic>>[];

    final temp = weather.current.tempC;
    final windKph = weather.current.windKph;
    final isDay = weather.current.isDay == 1;
    final activity = forecast.overallActivity;

    try {
      // Активные приманки для высокой активности рыбы
      if (activity >= 0.7) {
        baits.add({
          'type': 'active',
          'name': 'Воблеры, блесны',
          'reason': 'Высокая активность рыбы',
          'colors': isDay ? ['bright', 'natural'] : ['dark', 'contrast'],
        });
      }

      // В холодную погоду
      if (temp < 15) {
        baits.add({
          'type': 'slow',
          'name': 'Джиг, мягкие приманки',
          'reason': 'Холодная вода - медленная проводка',
          'colors': ['natural', 'dark'],
        });
      }

      // При сильном ветре
      if (windKph > 20) {
        baits.add({
          'type': 'heavy',
          'name': 'Тяжелые приманки',
          'reason': 'Сильный ветер - нужен вес',
          'colors': ['bright', 'contrast'],
        });
      }

      // Универсальные приманки
      if (baits.isEmpty) {
        baits.add({
          'type': 'universal',
          'name': 'Силиконовые приманки',
          'reason': 'Универсальный выбор',
          'colors': ['natural'],
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка при рекомендации приманок: $e');
    }

    return baits;
  }

  /// Рекомендация техники ловли
  Map<String, dynamic> _recommendTechnique(
    WeatherApiResponse weather,
    BiteForecastModel forecast,
    BuildContext? context,
  ) {
    final temp = weather.current.tempC;
    final activity = forecast.overallActivity;

    String technique;
    String description;
    List<String> tips = [];

    if (activity >= 0.7) {
      technique = 'aggressive';
      description = 'Агрессивная проводка';
      tips = ['Быстрая проводка', 'Активные движения', 'Частые рывки'];
    } else if (temp < 15 || activity < 0.4) {
      technique = 'slow';
      description = 'Медленная проводка';
      tips = ['Медленные движения', 'Длинные паузы', 'Плавная проводка'];
    } else {
      technique = 'medium';
      description = 'Умеренная проводка';
      tips = ['Средний темп', 'Периодические паузы', 'Смена ритма'];
    }

    return {'type': technique, 'description': description, 'tips': tips};
  }

  /// Генерация практических советов
  List<String> _generatePracticalTips(
    WeatherApiResponse weather,
    BiteForecastModel forecast,
    BuildContext? context,
  ) {
    final tips = <String>[];

    try {
      // Добавляем советы из базового прогноза
      tips.addAll(forecast.tips);

      // Дополнительные советы по погоде
      final pressure = weather.current.pressureMb;
      final windKph = weather.current.windKph;
      final temp = weather.current.tempC;
      final cloudCover = weather.current.cloud;

      if (pressure < 1005) {
        tips.add('low_pressure_tip');
      }

      if (windKph >= 3 && windKph <= 15) {
        tips.add('good_wind_tip');
      } else if (windKph < 3) {
        tips.add('calm_weather_tip');
      }

      if (temp < 15) {
        tips.add('cold_weather_tip');
      }

      if (cloudCover >= 20 && cloudCover <= 70) {
        tips.add('Легкая облачность благоприятна для рыбалки');
      }

      // Удаляем дубликаты
      return tips.toSet().toList();
    } catch (e) {
      debugPrint('❌ Ошибка при генерации практических советов: $e');
      return forecast.tips;
    }
  }
}

// Расширение для удобства работы с контекстом
extension ContextExtension on BuildContext? {
  T? let<T>(T Function(BuildContext) action) {
    if (this != null) {
      return action(this!);
    }
    return null;
  }
}
