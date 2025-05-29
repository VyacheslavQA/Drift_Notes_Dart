// Путь: lib/services/bite_forecast_service.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_api_model.dart';
import '../models/bite_forecast_model.dart';
import '../localization/app_localizations.dart';

class BiteForecastService {
  // Singleton pattern
  static final BiteForecastService _instance = BiteForecastService._internal();
  factory BiteForecastService() => _instance;
  BiteForecastService._internal();

  /// Основной метод для расчета прогноза клева
  Future<BiteForecastModel> calculateBiteForecast({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    debugPrint('🎣 Начинаем расчет прогноза клева...');

    try {
      // Анализируем все факторы
      final factors = await _analyzeAllFactors(weather, latitude, longitude, context);

      // Рассчитываем общую активность
      final overallActivity = _calculateOverallActivity(factors);

      // Определяем уровень и баллы
      final scorePoints = (overallActivity * 100).round();
      final level = _determineForecastLevel(scorePoints);

      // Генерируем рекомендации
      final recommendation = _generateRecommendation(factors, level, context);
      final tips = _generateTips(factors, weather, context);

      // Находим оптимальные временные окна
      final bestTimeWindows = _findOptimalTimeWindows(weather, factors, context);

      debugPrint('✅ Прогноз клева рассчитан: $scorePoints баллов, уровень: $level');

      return BiteForecastModel(
        overallActivity: overallActivity,
        scorePoints: scorePoints,
        level: level,
        recommendation: recommendation,
        tips: tips,
        factors: factors,
        bestTimeWindows: bestTimeWindows,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Ошибка при расчете прогноза клева: $e');

      // Возвращаем базовый прогноз в случае ошибки
      return BiteForecastModel(
        overallActivity: 0.5,
        scorePoints: 50,
        level: BiteForecastLevel.moderate,
        recommendation: context != null
            ? AppLocalizations.of(context).translate('moderate_conditions_recommendation')
            : 'Умеренные условия для рыбалки',
        tips: [],
        factors: {},
        bestTimeWindows: [],
        calculatedAt: DateTime.now(),
      );
    }
  }

  /// Анализ всех факторов, влияющих на клев
  Future<Map<String, BiteFactor>> _analyzeAllFactors(
      WeatherApiResponse weather,
      double latitude,
      double longitude,
      BuildContext? context,
      ) async {
    final factors = <String, BiteFactor>{};

    try {
      // 1. Анализ атмосферного давления
      factors['pressure'] = _analyzePressure(weather);

      // 2. Анализ ветра
      factors['wind'] = _analyzeWind(weather);

      // 3. Анализ фазы луны
      factors['moon'] = _analyzeMoonPhase(weather);

      // 4. Анализ температуры
      factors['temperature'] = _analyzeTemperature(weather);

      // 5. Анализ облачности и осадков
      factors['cloudiness'] = _analyzeCloudiness(weather);

      // 6. Анализ времени суток
      factors['timeOfDay'] = _analyzeTimeOfDay(weather);

      // 7. Анализ влажности
      factors['humidity'] = _analyzeHumidity(weather);

      debugPrint('🔍 Проанализировано факторов: ${factors.length}');

    } catch (e) {
      debugPrint('❌ Ошибка при анализе факторов: $e');
    }

    return factors;
  }

  /// Анализ атмосферного давления
  BiteFactor _analyzePressure(WeatherApiResponse weather) {
    final pressure = weather.current.pressureMb;
    double value = 0.5; // Базовое значение
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Нормальное давление';

    // Оптимальное давление для рыбалки: 1010-1025 гПа
    if (pressure >= 1010 && pressure <= 1025) {
      value = 0.8;
      impact = FactorImpact.positive;
      description = 'Стабильное давление, благоприятно для клева';
    } else if (pressure < 1000) {
      value = 0.3;
      impact = FactorImpact.negative;
      description = 'Низкое давление, рыба пассивна';
    } else if (pressure > 1030) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Высокое давление, клев слабый';
    } else {
      value = 0.6;
      impact = FactorImpact.neutral;
      description = 'Умеренное влияние на клев';
    }

    return BiteFactor(
      name: 'pressure',
      value: value,
      weight: 0.25, // Высокая важность
      impact: impact,
      description: description,
    );
  }

  /// Анализ ветра
  BiteFactor _analyzeWind(WeatherApiResponse weather) {
    final windKph = weather.current.windKph;
    final windDir = weather.current.windDir;

    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Умеренный ветер';

    // Оптимальная скорость ветра: 3-15 км/ч
    if (windKph >= 3 && windKph <= 15) {
      value = 0.8;
      impact = FactorImpact.positive;
      description = 'Оптимальный ветер для рыбалки';
    } else if (windKph < 3) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Штиль, рыба менее активна';
    } else if (windKph > 25) {
      value = 0.2;
      impact = FactorImpact.veryNegative;
      description = 'Сильный ветер, рыбалка затруднена';
    } else {
      value = 0.6;
      description = 'Свежий ветер, приемлемо для рыбалки';
    }

    // Бонус за благоприятное направление ветра
    if (['S', 'SW', 'SE'].contains(windDir)) {
      value = math.min(1.0, value + 0.1);
      description += ' (южное направление - плюс)';
    }

    return BiteFactor(
      name: 'wind',
      value: value,
      weight: 0.2,
      impact: impact,
      description: description,
    );
  }

  /// Анализ фазы луны
  BiteFactor _analyzeMoonPhase(WeatherApiResponse weather) {
    if (weather.forecast.isEmpty) {
      return BiteFactor(
        name: 'moon',
        value: 0.5,
        weight: 0.15,
        impact: FactorImpact.neutral,
        description: 'Данные о луне недоступны',
      );
    }

    final moonPhase = weather.forecast.first.astro.moonPhase.toLowerCase();
    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Нейтральное влияние луны';

    if (moonPhase.contains('new') || moonPhase.contains('full')) {
      value = 0.8;
      impact = FactorImpact.positive;
      description = 'Активная фаза луны, клев усилен';
    } else if (moonPhase.contains('waxing') || moonPhase.contains('waning')) {
      value = 0.6;
      impact = FactorImpact.neutral;
      description = 'Переходная фаза луны';
    } else {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Пассивная фаза луны';
    }

    return BiteFactor(
      name: 'moon',
      value: value,
      weight: 0.15,
      impact: impact,
      description: description,
    );
  }

  /// Анализ температуры
  BiteFactor _analyzeTemperature(WeatherApiResponse weather) {
    final temp = weather.current.tempC;
    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Умеренная температура';

    // Оптимальная температура для рыбалки: 15-25°C
    if (temp >= 15 && temp <= 25) {
      value = 0.8;
      impact = FactorImpact.positive;
      description = 'Комфортная температура для рыбалки';
    } else if (temp < 5) {
      value = 0.3;
      impact = FactorImpact.negative;
      description = 'Холодно, рыба малоактивна';
    } else if (temp > 30) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Жарко, рыба уходит на глубину';
    } else {
      value = 0.6;
      description = 'Приемлемая температура';
    }

    return BiteFactor(
      name: 'temperature',
      value: value,
      weight: 0.15,
      impact: impact,
      description: description,
    );
  }

  /// Анализ облачности и осадков
  BiteFactor _analyzeCloudiness(WeatherApiResponse weather) {
    final cloudCover = weather.current.cloud;
    final condition = weather.current.condition.text.toLowerCase();

    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Переменная облачность';

    // Легкая облачность лучше для рыбалки
    if (cloudCover >= 20 && cloudCover <= 70) {
      value = 0.7;
      impact = FactorImpact.positive;
      description = 'Оптимальная облачность';
    } else if (cloudCover < 20) {
      value = 0.5;
      description = 'Ясная погода';
    } else {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Сильная облачность';
    }

    // Штраф за осадки
    if (condition.contains('rain') || condition.contains('drizzle')) {
      value *= 0.7;
      impact = FactorImpact.negative;
      description = 'Дождь ухудшает клев';
    } else if (condition.contains('thunderstorm')) {
      value *= 0.3;
      impact = FactorImpact.veryNegative;
      description = 'Гроза - рыбалка опасна';
    }

    return BiteFactor(
      name: 'cloudiness',
      value: value,
      weight: 0.1,
      impact: impact,
      description: description,
    );
  }

  /// Анализ времени суток
  BiteFactor _analyzeTimeOfDay(WeatherApiResponse weather) {
    final hour = DateTime.now().hour;
    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Дневное время';

    // Лучшее время: рассвет (5-8) и закат (18-21)
    if ((hour >= 5 && hour <= 8) || (hour >= 18 && hour <= 21)) {
      value = 0.9;
      impact = FactorImpact.veryPositive;
      description = 'Золотое время для рыбалки';
    } else if ((hour >= 9 && hour <= 11) || (hour >= 15 && hour <= 17)) {
      value = 0.7;
      impact = FactorImpact.positive;
      description = 'Хорошее время для клева';
    } else if (hour >= 22 || hour <= 4) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Ночное время, низкая активность';
    } else {
      value = 0.5;
      description = 'Среднее время для рыбалки';
    }

    return BiteFactor(
      name: 'timeOfDay',
      value: value,
      weight: 0.1,
      impact: impact,
      description: description,
    );
  }

  /// Анализ влажности
  BiteFactor _analyzeHumidity(WeatherApiResponse weather) {
    final humidity = weather.current.humidity;
    double value = 0.5;
    FactorImpact impact = FactorImpact.neutral;
    String description = 'Нормальная влажность';

    // Оптимальная влажность: 60-80%
    if (humidity >= 60 && humidity <= 80) {
      value = 0.7;
      impact = FactorImpact.positive;
      description = 'Хорошая влажность для клева';
    } else if (humidity < 40) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Низкая влажность';
    } else if (humidity > 90) {
      value = 0.4;
      impact = FactorImpact.negative;
      description = 'Очень высокая влажность';
    }

    return BiteFactor(
      name: 'humidity',
      value: value,
      weight: 0.05,
      impact: impact,
      description: description,
    );
  }

  /// Расчет общей активности на основе всех факторов
  double _calculateOverallActivity(Map<String, BiteFactor> factors) {
    if (factors.isEmpty) return 0.5;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final factor in factors.values) {
      final adjustedValue = factor.value * factor.impact.multiplier;
      weightedSum += adjustedValue * factor.weight;
      totalWeight += factor.weight;
    }

    final activity = totalWeight > 0 ? weightedSum / totalWeight : 0.5;
    return math.max(0.0, math.min(1.0, activity));
  }

  /// Определение уровня прогноза по баллам
  BiteForecastLevel _determineForecastLevel(int scorePoints) {
    if (scorePoints >= 80) return BiteForecastLevel.excellent;
    if (scorePoints >= 60) return BiteForecastLevel.good;
    if (scorePoints >= 40) return BiteForecastLevel.moderate;
    if (scorePoints >= 20) return BiteForecastLevel.poor;
    return BiteForecastLevel.veryPoor;
  }

  /// Генерация основной рекомендации
  String _generateRecommendation(
      Map<String, BiteFactor> factors,
      BiteForecastLevel level,
      BuildContext? context,
      ) {
    if (context == null) {
      switch (level) {
        case BiteForecastLevel.excellent:
          return 'Отличные условия! Самое время для рыбалки.';
        case BiteForecastLevel.good:
          return 'Хорошие условия для клева.';
        case BiteForecastLevel.moderate:
          return 'Умеренные условия, стоит попробовать.';
        case BiteForecastLevel.poor:
          return 'Условия не очень, но шанс есть.';
        case BiteForecastLevel.veryPoor:
          return 'Плохие условия для рыбалки.';
      }
    }

    final localizations = AppLocalizations.of(context);

    switch (level) {
      case BiteForecastLevel.excellent:
        return localizations.translate('excellent_conditions_recommendation');
      case BiteForecastLevel.good:
        return localizations.translate('good_conditions_recommendation');
      case BiteForecastLevel.moderate:
        return localizations.translate('moderate_conditions_recommendation');
      case BiteForecastLevel.poor:
        return localizations.translate('poor_conditions_recommendation');
      case BiteForecastLevel.veryPoor:
        return localizations.translate('very_poor_conditions_recommendation');
    }
  }

  /// Генерация практических советов
  List<String> _generateTips(
      Map<String, BiteFactor> factors,
      WeatherApiResponse weather,
      BuildContext? context,
      ) {
    final tips = <String>[];

    try {
      // Советы по давлению
      final pressure = factors['pressure'];
      if (pressure != null && pressure.value < 0.5) {
        tips.add(context != null
            ? AppLocalizations.of(context).translate('low_pressure_tip')
            : 'При низком давлении ловите на глубине');
      }

      // Советы по ветру
      final wind = factors['wind'];
      if (wind != null) {
        if (wind.value > 0.7) {
          tips.add(context != null
              ? AppLocalizations.of(context).translate('good_wind_tip')
              : 'Хороший ветер - ловите с наветренной стороны');
        } else if (wind.value < 0.4) {
          tips.add(context != null
              ? AppLocalizations.of(context).translate('calm_weather_tip')
              : 'В штиль используйте легкие приманки');
        }
      }

      // Советы по времени
      final timeOfDay = factors['timeOfDay'];
      if (timeOfDay != null && timeOfDay.value > 0.8) {
        tips.add(context != null
            ? AppLocalizations.of(context).translate('golden_hour_tip')
            : 'Золотое время - используйте активные приманки');
      }

      // Советы по температуре
      final temp = factors['temperature'];
      if (temp != null && temp.value < 0.5) {
        tips.add(context != null
            ? AppLocalizations.of(context).translate('cold_weather_tip')
            : 'В холодную погоду рыба менее активна - замедлите проводку');
      }

    } catch (e) {
      debugPrint('❌ Ошибка при генерации советов: $e');
    }

    return tips;
  }

  /// Поиск оптимальных временных окон
  List<OptimalTimeWindow> _findOptimalTimeWindows(
      WeatherApiResponse weather,
      Map<String, BiteFactor> factors,
      BuildContext? context,
      ) {
    final windows = <OptimalTimeWindow>[];
    final now = DateTime.now();

    try {
      // Утреннее окно (рассвет)
      if (weather.forecast.isNotEmpty) {
        final astro = weather.forecast.first.astro;
        final sunriseTime = _parseTime(astro.sunrise, now);

        if (sunriseTime != null) {
          windows.add(OptimalTimeWindow(
            startTime: sunriseTime.subtract(const Duration(hours: 1)),
            endTime: sunriseTime.add(const Duration(hours: 2)),
            activity: 0.85,
            reason: context != null
                ? AppLocalizations.of(context).translate('sunrise_activity_reason')
                : 'Утренняя активность рыбы',
            recommendations: [
              context != null
                  ? AppLocalizations.of(context).translate('morning_bait_recommendation')
                  : 'Используйте яркие приманки'
            ],
          ));
        }

        // Вечернее окно (закат)
        final sunsetTime = _parseTime(astro.sunset, now);

        if (sunsetTime != null) {
          windows.add(OptimalTimeWindow(
            startTime: sunsetTime.subtract(const Duration(hours: 2)),
            endTime: sunsetTime.add(const Duration(hours: 1)),
            activity: 0.9,
            reason: context != null
                ? AppLocalizations.of(context).translate('sunset_activity_reason')
                : 'Вечерняя активность рыбы',
            recommendations: [
              context != null
                  ? AppLocalizations.of(context).translate('evening_bait_recommendation')
                  : 'Попробуйте поверхностные приманки'
            ],
          ));
        }
      }

    } catch (e) {
      debugPrint('❌ Ошибка при поиске оптимальных окон: $e');
    }

    return windows;
  }

  /// Парсинг времени из строки формата "6:30 AM"
  DateTime? _parseTime(String timeStr, DateTime baseDate) {
    try {
      final cleanTime = timeStr.trim().toLowerCase();
      final parts = cleanTime.split(':');

      if (parts.length >= 2) {
        final hourPart = parts[0];
        final minuteAndPeriod = parts[1].split(' ');

        var hour = int.tryParse(hourPart) ?? 0;
        final minute = int.tryParse(minuteAndPeriod[0]) ?? 0;

        if (minuteAndPeriod.length > 1) {
          final period = minuteAndPeriod[1];
          if (period == 'pm' && hour != 12) {
            hour += 12;
          } else if (period == 'am' && hour == 12) {
            hour = 0;
          }
        }

        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга времени "$timeStr": $e');
    }

    return null;
  }
}