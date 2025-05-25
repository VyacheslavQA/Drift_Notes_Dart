// Путь: lib/services/fishing_forecast_service.dart

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/weather_api_model.dart';

class FishingForecastService {
  // Singleton pattern
  static final FishingForecastService _instance = FishingForecastService._internal();
  factory FishingForecastService() => _instance;
  FishingForecastService._internal();

  /// Получить прогноз для рыбалки на основе данных о погоде
  Future<Map<String, dynamic>> getFishingForecast({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final current = weather.current;
      final forecast = weather.forecast.isNotEmpty ? weather.forecast.first : null;

      // Анализируем различные факторы
      final pressureFactor = _analyzePressure(current.pressureMb);
      final windFactor = _analyzeWind(current.windKph);
      final temperatureFactor = _analyzeTemperature(current.tempC);
      final cloudFactor = _analyzeCloudCover(current.cloud);
      final moonFactor = forecast != null ? _analyzeMoonPhase(forecast.astro.moonPhase) : 0.5;
      final timeFactor = _analyzeTimeOfDay();

      // Рассчитываем общую активность клёва
      final overallActivity = _calculateOverallActivity([
        pressureFactor,
        windFactor,
        temperatureFactor,
        cloudFactor,
        moonFactor,
        timeFactor,
      ]);

      // Генерируем рекомендации
      final recommendation = _generateRecommendation(
        overallActivity,
        current,
        forecast?.astro,
      );

      return {
        'overallActivity': overallActivity,
        'pressureFactor': pressureFactor,
        'windFactor': windFactor,
        'temperatureFactor': temperatureFactor,
        'cloudFactor': cloudFactor,
        'moonFactor': moonFactor,
        'timeFactor': timeFactor,
        'recommendation': recommendation,
        'bestTimeToFish': _getBestTimeToFish(forecast),
        'weatherCondition': current.condition.text,
      };
    } catch (e) {
      debugPrint('Ошибка при создании прогноза рыбалки: $e');
      return {
        'overallActivity': 0.5,
        'pressureFactor': 0.5,
        'windFactor': 0.5,
        'temperatureFactor': 0.5,
        'cloudFactor': 0.5,
        'moonFactor': 0.5,
        'timeFactor': 0.5,
        'recommendation': 'Недостаточно данных для точного прогноза',
        'bestTimeToFish': 'Утренние и вечерние часы',
        'weatherCondition': 'Неизвестно',
      };
    }
  }

  /// Анализ атмосферного давления
  double _analyzePressure(double pressureMb) {
    // Оптимальное давление для рыбалки: 1013-1023 мб
    if (pressureMb >= 1013 && pressureMb <= 1023) {
      return 1.0; // Отличные условия
    } else if (pressureMb >= 1005 && pressureMb <= 1030) {
      return 0.7; // Хорошие условия
    } else if (pressureMb >= 995 && pressureMb <= 1035) {
      return 0.4; // Средние условия
    } else {
      return 0.2; // Плохие условия
    }
  }

  /// Анализ ветра
  double _analyzeWind(double windKph) {
    // Оптимальная скорость ветра: 5-15 км/ч
    if (windKph >= 5 && windKph <= 15) {
      return 1.0; // Отличные условия
    } else if (windKph >= 0 && windKph <= 25) {
      return 0.7; // Хорошие условия
    } else if (windKph <= 35) {
      return 0.4; // Средние условия
    } else {
      return 0.1; // Плохие условия (сильный ветер)
    }
  }

  /// Анализ температуры
  double _analyzeTemperature(double tempC) {
    // Оптимальная температура зависит от сезона
    final month = DateTime.now().month;

    if (month >= 4 && month <= 10) {
      // Весна-лето-осень
      if (tempC >= 15 && tempC <= 25) {
        return 1.0; // Отличные условия
      } else if (tempC >= 10 && tempC <= 30) {
        return 0.7; // Хорошие условия
      } else if (tempC >= 5 && tempC <= 35) {
        return 0.4; // Средние условия
      } else {
        return 0.2; // Плохие условия
      }
    } else {
      // Зима
      if (tempC >= -5 && tempC <= 5) {
        return 1.0; // Отличные условия для зимней рыбалки
      } else if (tempC >= -10 && tempC <= 10) {
        return 0.7; // Хорошие условия
      } else if (tempC >= -20 && tempC <= 15) {
        return 0.4; // Средние условия
      } else {
        return 0.2; // Плохие условия
      }
    }
  }

  /// Анализ облачности
  double _analyzeCloudCover(int cloudCover) {
    // Легкая облачность часто лучше для рыбалки
    if (cloudCover >= 20 && cloudCover <= 70) {
      return 1.0; // Отличные условия
    } else if (cloudCover >= 10 && cloudCover <= 80) {
      return 0.7; // Хорошие условия
    } else {
      return 0.5; // Средние условия
    }
  }

  /// Анализ фазы луны
  double _analyzeMoonPhase(String moonPhase) {
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new') || phase.contains('full')) {
      return 1.0; // Новолуние и полнолуние - лучшее время
    } else if (phase.contains('quarter')) {
      return 0.7; // Четверти луны - хорошее время
    } else if (phase.contains('crescent') || phase.contains('gibbous')) {
      return 0.6; // Промежуточные фазы
    } else {
      return 0.5; // Средние условия
    }
  }

  /// Анализ времени суток
  double _analyzeTimeOfDay() {
    final hour = DateTime.now().hour;

    if ((hour >= 5 && hour <= 9) || (hour >= 17 && hour <= 21)) {
      return 1.0; // Утренние и вечерние часы - лучшее время
    } else if ((hour >= 4 && hour <= 11) || (hour >= 16 && hour <= 22)) {
      return 0.7; // Расширенные утренние и вечерние часы
    } else if (hour >= 22 || hour <= 3) {
      return 0.8; // Ночное время может быть хорошим
    } else {
      return 0.4; // Дневное время менее благоприятно
    }
  }

  /// Расчёт общей активности клёва
  double _calculateOverallActivity(List<double> factors) {
    if (factors.isEmpty) return 0.5;

    // Взвешенное среднее с учётом важности факторов
    final weights = [0.25, 0.20, 0.15, 0.10, 0.15, 0.15]; // Сумма = 1.0

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < factors.length && i < weights.length; i++) {
      weightedSum += factors[i] * weights[i];
      totalWeight += weights[i];
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// Генерация рекомендаций
  String _generateRecommendation(
      double overallActivity,
      Current current,
      Astro? astro,
      ) {
    if (overallActivity > 0.8) {
      return 'Отличные условия для рыбалки! Рыба должна быть очень активной.';
    } else if (overallActivity > 0.6) {
      return 'Хорошие условия для рыбалки. Стоит попробовать!';
    } else if (overallActivity > 0.4) {
      return 'Средние условия. Рыба может клевать, но не очень активно.';
    } else if (overallActivity > 0.2) {
      return 'Слабые условия для рыбалки. Лучше подождать более благоприятной погоды.';
    } else {
      return 'Неблагоприятные условия для рыбалки. Рекомендуется отложить выезд.';
    }
  }

  /// Определение лучшего времени для рыбалки
  String _getBestTimeToFish(ForecastDay? forecast) {
    if (forecast == null) {
      return 'Утренние часы (05:00-09:00) и вечерние часы (17:00-21:00)';
    }

    final astro = forecast.astro;
    final sunrise = astro.sunrise;
    final sunset = astro.sunset;

    return 'Лучшее время: час до восхода ($sunrise) и час после заката ($sunset)';
  }

  /// Получить детальный анализ условий
  Map<String, String> getDetailedAnalysis(Map<String, dynamic> forecast) {
    final analysis = <String, String>{};

    // Анализ давления
    final pressureFactor = forecast['pressureFactor'] as double;
    if (pressureFactor > 0.8) {
      analysis['pressure'] = 'Давление стабильное - отлично для рыбалки';
    } else if (pressureFactor > 0.5) {
      analysis['pressure'] = 'Давление в норме - хорошо для рыбалки';
    } else {
      analysis['pressure'] = 'Давление нестабильное - может влиять на клёв';
    }

    // Анализ ветра
    final windFactor = forecast['windFactor'] as double;
    if (windFactor > 0.8) {
      analysis['wind'] = 'Ветер слабый - идеально для рыбалки';
    } else if (windFactor > 0.5) {
      analysis['wind'] = 'Ветер умеренный - неплохо для рыбалки';
    } else {
      analysis['wind'] = 'Сильный ветер - может затруднить рыбалку';
    }

    // Анализ луны
    final moonFactor = forecast['moonFactor'] as double;
    if (moonFactor > 0.8) {
      analysis['moon'] = 'Фаза луны благоприятна для активного клёва';
    } else if (moonFactor > 0.5) {
      analysis['moon'] = 'Фаза луны нейтральна';
    } else {
      analysis['moon'] = 'Фаза луны не очень благоприятна';
    }

    return analysis;
  }
}