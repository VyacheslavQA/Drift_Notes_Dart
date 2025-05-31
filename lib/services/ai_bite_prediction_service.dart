// Путь: lib/services/ai_bite_prediction_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_api_model.dart';
import '../models/fishing_note_model.dart';
import '../models/ai_bite_prediction_model.dart';
import '../config/api_keys.dart';
import '../models/fishing_note_model.dart';

class AIBitePredictionService {
  static final AIBitePredictionService _instance = AIBitePredictionService._internal();
  factory AIBitePredictionService() => _instance;
  AIBitePredictionService._internal();

  // Кэш для оптимизации
  final Map<String, MultiFishingTypePrediction> _cache = {};
  static const String _cacheKey = 'ai_bite_cache_multi';

  // Конфигурация типов рыбалки
  static const Map<String, FishingTypeConfig> fishingTypeConfigs = {
    'spinning': FishingTypeConfig(
      name: 'Спиннинг',
      icon: '🎯',
      optimalTemp: [15.0, 25.0],
      optimalWind: [5.0, 15.0],
      bestHours: [6, 7, 8, 18, 19, 20],
      weatherPreference: ['partly_cloudy', 'overcast', 'light_rain'],
      moonImportance: 0.6,
      pressureImportance: 0.8,
      seasonalBonus: {'spring': 0.3, 'autumn': 0.3, 'summer': 0.1, 'winter': -0.2},
      targetFish: ['щука', 'окунь', 'судак', 'жерех'],
      techniques: ['воблеры', 'блесны', 'силикон', 'джиг'],
    ),
    'feeder': FishingTypeConfig(
      name: 'Фидер',
      icon: '🐟',
      optimalTemp: [12.0, 22.0],
      optimalWind: [0.0, 25.0], // Фидер более устойчив к ветру
      bestHours: [5, 6, 7, 16, 17, 18, 19],
      weatherPreference: ['stable', 'partly_cloudy'],
      moonImportance: 0.4,
      pressureImportance: 0.9, // Очень важно для мирной рыбы
      seasonalBonus: {'spring': 0.2, 'summer': 0.3, 'autumn': 0.2, 'winter': 0.0},
      targetFish: ['лещ', 'карась', 'плотва', 'густера'],
      techniques: ['червь', 'опарыш', 'пеллетс', 'кукуруза'],
    ),
    'carp_fishing': FishingTypeConfig(
      name: 'Карповая ловля',
      icon: '🦎',
      optimalTemp: [18.0, 28.0],
      optimalWind: [0.0, 10.0],
      bestHours: [22, 23, 0, 1, 2, 3, 4, 5], // Ночная ловля
      weatherPreference: ['stable', 'warm'],
      moonImportance: 0.9, // Карп очень зависит от луны
      pressureImportance: 0.7,
      seasonalBonus: {'spring': 0.1, 'summer': 0.4, 'autumn': 0.2, 'winter': -0.3},
      targetFish: ['карп', 'амур', 'толстолобик'],
      techniques: ['бойлы', 'кукуруза', 'пеллетс', 'тигровый орех'],
    ),
    'float_fishing': FishingTypeConfig(
      name: 'Поплавочная ловля',
      icon: '🎣',
      optimalTemp: [10.0, 20.0],
      optimalWind: [0.0, 10.0], // Требует спокойной воды
      bestHours: [6, 7, 8, 9, 16, 17, 18],
      weatherPreference: ['sunny', 'partly_cloudy'],
      moonImportance: 0.3,
      pressureImportance: 0.8,
      seasonalBonus: {'spring': 0.3, 'summer': 0.2, 'autumn': 0.1, 'winter': -0.1},
      targetFish: ['плотва', 'карась', 'окунь', 'ёрш'],
      techniques: ['червь', 'опарыш', 'тесто', 'хлеб'],
    ),
    'ice_fishing': FishingTypeConfig(
      name: 'Зимняя рыбалка',
      icon: '❄️',
      optimalTemp: [-15.0, 0.0],
      optimalWind: [0.0, 20.0],
      bestHours: [9, 10, 11, 14, 15, 16],
      weatherPreference: ['clear', 'stable_frost'],
      moonImportance: 0.7,
      pressureImportance: 1.0, // Критически важно зимой
      seasonalBonus: {'winter': 0.5, 'spring': -0.5, 'summer': -1.0, 'autumn': -0.3},
      targetFish: ['окунь', 'плотва', 'лещ', 'щука'],
      techniques: ['мормышка', 'блесна', 'балансир', 'живец'],
    ),
    'fly_fishing': FishingTypeConfig(
      name: 'Нахлыст',
      icon: '🦋',
      optimalTemp: [8.0, 18.0],
      optimalWind: [0.0, 8.0], // Очень чувствителен к ветру
      bestHours: [5, 6, 7, 19, 20, 21],
      weatherPreference: ['overcast', 'light_rain'],
      moonImportance: 0.2,
      pressureImportance: 0.6,
      seasonalBonus: {'spring': 0.4, 'summer': 0.2, 'autumn': 0.3, 'winter': -0.2},
      targetFish: ['форель', 'хариус', 'голавль'],
      techniques: ['сухая мушка', 'мокрая мушка', 'нимфа', 'стример'],
    ),
    'trolling': FishingTypeConfig(
      name: 'Троллинг',
      icon: '🚤',
      optimalTemp: [12.0, 24.0],
      optimalWind: [0.0, 30.0], // Лодка справляется с ветром
      bestHours: [6, 7, 8, 9, 17, 18, 19],
      weatherPreference: ['any'], // Менее зависим от погоды
      moonImportance: 0.4,
      pressureImportance: 0.6,
      seasonalBonus: {'spring': 0.2, 'summer': 0.3, 'autumn': 0.2, 'winter': 0.0},
      targetFish: ['щука', 'судак', 'сом', 'лосось'],
      techniques: ['воблеры', 'блесны', 'силикон'],
    ),
  };

  /// Основной метод получения мультитипового ИИ прогноза
  Future<MultiFishingTypePrediction> getMultiFishingTypePrediction({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    List<FishingNote>? userHistory,
    DateTime? targetDate,
    List<String>? preferredTypes,
  }) async {
    try {
      targetDate ??= DateTime.now();

      // Создаём уникальный ключ для кэширования
      final cacheKey = _generateCacheKey(latitude, longitude, targetDate);

      // Проверяем кэш (актуален 30 минут)
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().difference(cached.generatedAt).inMinutes < 30) {
          debugPrint('🤖 Мультитиповый ИИ прогноз из кэша');
          return cached;
        }
      }

      debugPrint('🤖 Генерация нового мультитипового ИИ прогноза...');

      // Собираем все данные для анализа
      final analysisData = await _collectAnalysisData(
        weather: weather,
        latitude: latitude,
        longitude: longitude,
        userHistory: userHistory,
        targetDate: targetDate,
      );

      // Анализируем каждый тип рыбалки
      final predictions = <String, AIBitePrediction>{};

      for (final entry in fishingTypeConfigs.entries) {
        final fishingType = entry.key;
        final config = entry.value;

        // Пропускаем неподходящие сезоны
        if (_isSeasonallyInappropriate(config, targetDate)) {
          predictions[fishingType] = _createSeasonallyInappropriatePrediction(config, targetDate);
          continue;
        }

        // Получаем полный анализ для этого типа
        final prediction = await _analyzeFishingType(
          fishingType: fishingType,
          config: config,
          analysisData: analysisData,
          userHistory: userHistory,
        );

        predictions[fishingType] = prediction;
      }

      // Определяем лучший тип и создаем итоговый прогноз
      final multiPrediction = _createMultiPrediction(predictions, preferredTypes, analysisData);

      // Сохраняем в кэш
      _cache[cacheKey] = multiPrediction;
      await _saveCacheToStorage();

      debugPrint('✅ Мультитиповый ИИ прогноз готов. Лучший: ${multiPrediction.bestFishingType}');
      return multiPrediction;

    } catch (e) {
      debugPrint('❌ Ошибка мультитипового ИИ прогноза: $e');
      return _getFallbackMultiPrediction(weather);
    }
  }

  /// Анализ конкретного типа рыбалки
  Future<AIBitePrediction> _analyzeFishingType({
    required String fishingType,
    required FishingTypeConfig config,
    required Map<String, dynamic> analysisData,
    List<FishingNote>? userHistory,
  }) async {
    double score = 50.0; // Базовый скор
    final factors = <String, Map<String, dynamic>>{};

    // Анализ температуры для данного типа
    final temp = analysisData['weather']['temperature'] as double;
    final tempFactor = _analyzeTemperatureForType(temp, config);
    score += tempFactor['impact'] * tempFactor['weight'];
    factors['temperature'] = tempFactor;

    // Анализ ветра для данного типа
    final windSpeed = analysisData['weather']['wind_speed'] as double;
    final windFactor = _analyzeWindForType(windSpeed, config);
    score += windFactor['impact'] * windFactor['weight'];
    factors['wind'] = windFactor;

    // Анализ времени для данного типа
    final hour = analysisData['time']['hour'] as int;
    final timeFactor = _analyzeTimeForType(hour, config);
    score += timeFactor['impact'] * timeFactor['weight'];
    factors['time'] = timeFactor;

    // Анализ давления (универсальный, но с учетом важности для типа)
    final pressure = analysisData['weather']['pressure'] as double;
    final pressureTrend = analysisData['weather']['pressure_trend'] as String;
    final pressureFactor = _analyzePressureForType(pressure, pressureTrend, config);
    score += pressureFactor['impact'] * pressureFactor['weight'];
    factors['pressure'] = pressureFactor;

    // Анализ луны для данного типа
    final moonPhase = analysisData['astro']['moon_phase'] as String?;
    final moonFactor = _analyzeMoonForType(moonPhase, config);
    score += moonFactor['impact'] * moonFactor['weight'];
    factors['moon'] = moonFactor;

    // Сезонный бонус
    final season = analysisData['time']['season'] as String;
    final seasonFactor = _analyzeSeasonForType(season, config);
    score += seasonFactor['impact'] * seasonFactor['weight'];
    factors['season'] = seasonFactor;

    // Анализ погодных условий
    final condition = analysisData['weather']['condition'] as String;
    final weatherFactor = _analyzeWeatherConditionForType(condition, config);
    score += weatherFactor['impact'] * weatherFactor['weight'];
    factors['weather_condition'] = weatherFactor;

    // Персональный анализ истории пользователя
    final personalFactor = _analyzePersonalHistoryForType(userHistory, fishingType, analysisData);
    score += personalFactor['impact'] * personalFactor['weight'];
    factors['personal_history'] = personalFactor;

    score = score.clamp(0.0, 100.0);

    // Генерируем рекомендации для конкретного типа
    final recommendations = _generateTypeSpecificRecommendations(score, config, factors);

    // Определяем лучшие временные окна
    final bestTimeWindows = _calculateBestTimeWindowsForType(config, analysisData, score);

    return AIBitePrediction(
      overallScore: score.round(),
      activityLevel: _getActivityLevel(score.round()),
      confidence: _calculateConfidence(factors),
      recommendation: recommendations['main'] as String,
      detailedAnalysis: recommendations['detailed'] as String,
      factors: _createDetailedFactors(factors),
      bestTimeWindows: bestTimeWindows,
      tips: recommendations['tips'] as List<String>,
      generatedAt: DateTime.now(),
      dataSource: 'ai_multi_type',
      modelVersion: '2.0.0',
    );
  }

  /// Создание мультитипового прогноза
  MultiFishingTypePrediction _createMultiPrediction(
      Map<String, AIBitePrediction> predictions,
      List<String>? preferredTypes,
      Map<String, dynamic> analysisData,
      ) {
    // Сортируем по скору
    final sortedPredictions = predictions.entries.toList()
      ..sort((a, b) => b.value.overallScore.compareTo(a.value.overallScore));

    // Определяем лучший тип с учетом предпочтений пользователя
    String bestType = sortedPredictions.first.key;

    if (preferredTypes != null && preferredTypes.isNotEmpty) {
      // Ищем лучший среди предпочтительных типов
      for (final preferred in preferredTypes) {
        if (predictions.containsKey(preferred) && predictions[preferred]!.overallScore >= 40) {
          bestType = preferred;
          break;
        }
      }
    }

    // Создаем сравнительный анализ
    final comparison = _createComparisonAnalysis(predictions);

    // Общие рекомендации
    final generalRecommendations = _generateGeneralRecommendations(predictions, bestType);

    return MultiFishingTypePrediction(
      bestFishingType: bestType,
      bestPrediction: predictions[bestType]!,
      allPredictions: predictions,
      comparison: comparison,
      generalRecommendations: generalRecommendations,
      weatherSummary: _createWeatherSummary(analysisData),
      generatedAt: DateTime.now(),
    );
  }

  // Специализированные анализаторы факторов для типов рыбалки

  Map<String, dynamic> _analyzeTemperatureForType(double temp, FishingTypeConfig config) {
    final optimal = config.optimalTemp;
    double impact = 0.0;
    String description = '';

    if (temp >= optimal[0] && temp <= optimal[1]) {
      impact = 15.0;
      description = 'Идеальная температура для ${config.name.toLowerCase()}';
    } else if (temp >= optimal[0] - 3 && temp <= optimal[1] + 3) {
      impact = 8.0;
      description = 'Хорошая температура для ${config.name.toLowerCase()}';
    } else if (temp >= optimal[0] - 8 && temp <= optimal[1] + 8) {
      impact = 0.0;
      description = 'Приемлемая температура';
    } else {
      impact = -15.0;
      description = 'Неблагоприятная температура для ${config.name.toLowerCase()}';
    }

    return {
      'name': 'Температура',
      'value': temp,
      'impact': impact,
      'weight': 0.8,
      'description': description,
      'optimal_range': '${optimal[0]}°C - ${optimal[1]}°C',
    };
  }

  Map<String, dynamic> _analyzeWindForType(double windKph, FishingTypeConfig config) {
    final optimal = config.optimalWind;
    double impact = 0.0;
    String description = '';

    if (windKph >= optimal[0] && windKph <= optimal[1]) {
      impact = 10.0;
      description = 'Отличный ветер для ${config.name.toLowerCase()}';
    } else if (windKph <= optimal[1] + 5) {
      impact = 3.0;
      description = 'Умеренный ветер';
    } else if (windKph <= optimal[1] + 15) {
      impact = -8.0;
      description = 'Сильноватый ветер затрудняет ${config.name.toLowerCase()}';
    } else {
      impact = -20.0;
      description = 'Очень сильный ветер - сложные условия';
    }

    return {
      'name': 'Ветер',
      'value': windKph,
      'impact': impact,
      'weight': 0.7,
      'description': description,
      'optimal_range': '${optimal[0]} - ${optimal[1]} км/ч',
    };
  }

  Map<String, dynamic> _analyzeTimeForType(int hour, FishingTypeConfig config) {
    double impact = 0.0;
    String description = '';

    if (config.bestHours.contains(hour)) {
      impact = 15.0;
      description = 'Золотое время для ${config.name.toLowerCase()}';
    } else if (_isNearBestTime(hour, config.bestHours)) {
      impact = 8.0;
      description = 'Хорошее время для клёва';
    } else {
      impact = -5.0;
      description = 'Не самое лучшее время';
    }

    return {
      'name': 'Время суток',
      'value': hour,
      'impact': impact,
      'weight': 0.9,
      'description': description,
      'best_hours': config.bestHours.join(', '),
    };
  }

  Map<String, dynamic> _analyzePressureForType(double pressure, String trend, FishingTypeConfig config) {
    double impact = 0.0;
    String description = '';

    // Базовый анализ давления
    if (pressure >= 1010 && pressure <= 1025) {
      impact = 10.0;
      description = 'Оптимальное давление для клёва';
    } else if (pressure >= 1000 && pressure <= 1035) {
      impact = 0.0;
      description = 'Нормальное давление';
    } else {
      impact = -15.0;
      description = 'Неблагоприятное давление';
    }

    // Применяем важность давления для данного типа рыбалки
    impact *= config.pressureImportance;

    // Учитываем тренд
    switch (trend) {
      case 'rising':
        impact += 5.0 * config.pressureImportance;
        description += '. Растущее давление активизирует рыбу';
        break;
      case 'falling':
        impact -= 8.0 * config.pressureImportance;
        description += '. Падающее давление снижает активность';
        break;
      case 'stable':
        impact += 2.0 * config.pressureImportance;
        description += '. Стабильное давление благоприятно';
        break;
    }

    return {
      'name': 'Давление',
      'value': pressure,
      'trend': trend,
      'impact': impact,
      'weight': config.pressureImportance,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeMoonForType(String? moonPhase, FishingTypeConfig config) {
    if (moonPhase == null) {
      return {
        'name': 'Фаза луны',
        'impact': 0.0,
        'weight': config.moonImportance,
        'description': 'Данные о луне недоступны',
      };
    }

    double impact = 0.0;
    String description = '';

    final phase = moonPhase.toLowerCase();

    if (phase.contains('new') || phase.contains('full')) {
      impact = 10.0 * config.moonImportance;
      description = 'Активная фаза луны усиливает клёв';
    } else if (phase.contains('quarter')) {
      impact = 5.0 * config.moonImportance;
      description = 'Умеренная лунная активность';
    } else {
      impact = 0.0;
      description = 'Нейтральная фаза луны';
    }

    return {
      'name': 'Фаза луны',
      'phase': moonPhase,
      'impact': impact,
      'weight': config.moonImportance,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeSeasonForType(String season, FishingTypeConfig config) {
    final bonus = config.seasonalBonus[season] ?? 0.0;
    double impact = bonus * 20; // Преобразуем в баллы

    String description = '';
    if (bonus > 0.2) {
      description = 'Отличный сезон для ${config.name.toLowerCase()}';
    } else if (bonus > 0.0) {
      description = 'Хороший сезон';
    } else if (bonus == 0.0) {
      description = 'Нейтральный сезон';
    } else if (bonus > -0.3) {
      description = 'Не лучший сезон для ${config.name.toLowerCase()}';
    } else {
      description = 'Неподходящий сезон';
    }

    return {
      'name': 'Сезон',
      'season': season,
      'impact': impact,
      'weight': 0.6,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeWeatherConditionForType(String condition, FishingTypeConfig config) {
    double impact = 0.0;
    String description = '';

    final lowerCondition = condition.toLowerCase();
    final preferences = config.weatherPreference;

    if (preferences.contains('any')) {
      impact = 0.0;
      description = 'Погодные условия не критичны';
    } else if (preferences.any((pref) => lowerCondition.contains(pref))) {
      impact = 8.0;
      description = 'Благоприятные погодные условия';
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('heavy')) {
      impact = -15.0;
      description = 'Неблагоприятные погодные условия';
    } else {
      impact = 0.0;
      description = 'Нейтральные погодные условия';
    }

    return {
      'name': 'Погодные условия',
      'condition': condition,
      'impact': impact,
      'weight': 0.5,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzePersonalHistoryForType(
      List<FishingNote>? history,
      String fishingType,
      Map<String, dynamic> analysisData,
      ) {
    if (history == null || history.isEmpty) {
      return {
        'name': 'Персональная история',
        'impact': 0.0,
        'weight': 0.3,
        'description': 'Недостаточно данных о ваших рыбалках',
      };
    }

    // Анализируем историю для данного типа рыбалки
    final relevantNotes = history.where((note) =>
    note.fishingType == fishingType &&
        DateTime.now().difference(note.startDate).inDays <= 365
    ).toList();

    if (relevantNotes.isEmpty) {
      return {
        'name': 'Персональная история',
        'impact': 0.0,
        'weight': 0.3,
        'description': 'Нет данных по ${fishingTypeConfigs[fishingType]?.name.toLowerCase()}',
      };
    }

    final totalTrips = relevantNotes.length;
    final successfulTrips = relevantNotes.where((note) =>
    note.biteRecords.isNotEmpty &&
        note.biteRecords.any((bite) => bite.weight > 0)
    ).length;

    final successRate = successfulTrips / totalTrips;

    double impact = 0.0;
    String description = '';

    if (totalTrips >= 10) {
      if (successRate > 0.7) {
        impact = 8.0;
        description = 'У вас отличная статистика по ${fishingTypeConfigs[fishingType]?.name.toLowerCase()}';
      } else if (successRate > 0.4) {
        impact = 4.0;
        description = 'Умеренный успех в данном типе рыбалки';
      } else {
        impact = -2.0;
        description = 'Стоит улучшить технику ${fishingTypeConfigs[fishingType]?.name.toLowerCase()}';
      }
    } else {
      impact = 0.0;
      description = 'Накапливаем статистику по ${fishingTypeConfigs[fishingType]?.name.toLowerCase()}';
    }

    return {
      'name': 'Персональная история',
      'fishing_type': fishingType,
      'success_rate': successRate,
      'total_trips': totalTrips,
      'impact': impact,
      'weight': 0.3,
      'description': description,
    };
  }

  // Вспомогательные методы...

  bool _isSeasonallyInappropriate(FishingTypeConfig config, DateTime date) {
    final season = _getSeason(date);
    final bonus = config.seasonalBonus[season] ?? 0.0;

    // Если сезонный штраф больше -0.8, то тип неподходящий
    return bonus <= -0.8;
  }

  AIBitePrediction _createSeasonallyInappropriatePrediction(FishingTypeConfig config, DateTime date) {
    return AIBitePrediction(
      overallScore: 0,
      activityLevel: ActivityLevel.veryPoor,
      confidence: 0.9,
      recommendation: 'Неподходящий сезон для ${config.name.toLowerCase()}',
      detailedAnalysis: 'В настоящее время условия крайне неблагоприятны для данного типа рыбалки',
      factors: [],
      bestTimeWindows: [],
      tips: ['Дождитесь подходящего сезона', 'Попробуйте другой тип рыбалки'],
      generatedAt: DateTime.now(),
      dataSource: 'seasonal_filter',
      modelVersion: '2.0.0',
    );
  }

  bool _isNearBestTime(int hour, List<int> bestHours) {
    for (final bestHour in bestHours) {
      if ((hour - bestHour).abs() <= 1) return true;
    }
    return false;
  }

  ComparisonAnalysis _createComparisonAnalysis(Map<String, AIBitePrediction> predictions) {
    final rankings = predictions.entries.map((e) => FishingTypeRanking(
      fishingType: e.key,
      typeName: fishingTypeConfigs[e.key]?.name ?? e.key,
      icon: fishingTypeConfigs[e.key]?.icon ?? '🎣',
      score: e.value.overallScore,
      activityLevel: e.value.activityLevel,
      shortRecommendation: e.value.recommendation,
      keyFactors: e.value.factors.take(3).map((f) => f.name).toList(),
    )).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return ComparisonAnalysis(
      rankings: rankings,
      bestOverall: rankings.first,
      alternativeOptions: rankings.skip(1).take(2).toList(),
      worstOptions: rankings.where((r) => r.score < 30).toList(),
    );
  }

  List<String> _generateGeneralRecommendations(Map<String, AIBitePrediction> predictions, String bestType) {
    final recommendations = <String>[];
    final bestPrediction = predictions[bestType]!;
    final bestConfig = fishingTypeConfigs[bestType]!;

    recommendations.add('Сегодня лучше всего подходит ${bestConfig.name.toLowerCase()}');

    if (bestPrediction.overallScore >= 80) {
      recommendations.add('Отличные условия! Время для трофейной ловли');
    } else if (bestPrediction.overallScore >= 60) {
      recommendations.add('Хорошие условия, стоит попробовать');
    } else {
      recommendations.add('Средние условия, потребуется терпение');
    }

    // Добавляем рекомендацию по технике
    if (bestConfig.techniques.isNotEmpty) {
      recommendations.add('Рекомендуемые приманки: ${bestConfig.techniques.take(2).join(", ")}');
    }

    return recommendations;
  }

  WeatherSummary _createWeatherSummary(Map<String, dynamic> analysisData) {
    final weather = analysisData['weather'] as Map<String, dynamic>;

    return WeatherSummary(
      temperature: weather['temperature'] as double,
      pressure: weather['pressure'] as double,
      windSpeed: weather['wind_speed'] as double,
      humidity: weather['humidity'] as int,
      condition: weather['condition'] as String,
      moonPhase: analysisData['astro']['moon_phase'] as String? ?? 'Неизвестно',
    );
  }

  // Остальные вспомогательные методы (аналогично старой версии, но адаптированные)...

  String _generateCacheKey(double lat, double lon, DateTime date) {
    return 'ai_multi_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}';
  }

  Future<Map<String, dynamic>> _collectAnalysisData({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    List<FishingNote>? userHistory,
    required DateTime targetDate,
  }) async {
    final current = weather.current;
    final forecast = weather.forecast.isNotEmpty ? weather.forecast.first : null;

    final weatherData = {
      'temperature': current.tempC,
      'feels_like': current.feelslikeC,
      'humidity': current.humidity,
      'pressure': current.pressureMb,
      'pressure_trend': await _calculatePressureTrend(weather),
      'wind_speed': current.windKph,
      'wind_direction': current.windDir,
      'visibility': current.visKm,
      'uv_index': current.uv,
      'cloud_cover': current.cloud,
      'condition': current.condition.text,
      'is_day': current.isDay == 1,
    };

    final astroData = forecast != null ? {
      'sunrise': forecast.astro.sunrise,
      'sunset': forecast.astro.sunset,
      'moonrise': forecast.astro.moonrise,
      'moonset': forecast.astro.moonset,
      'moon_phase': forecast.astro.moonPhase,
    } : <String, dynamic>{};

    final timeData = {
      'hour': targetDate.hour,
      'day_of_week': targetDate.weekday,
      'day_of_month': targetDate.day,
      'month': targetDate.month,
      'season': _getSeason(targetDate),
      'is_weekend': targetDate.weekday >= 6,
    };

    final geoData = {
      'latitude': latitude,
      'longitude': longitude,
      'region': weather.location.region,
      'country': weather.location.country,
      'timezone': weather.location.tzId,
    };

    return {
      'weather': weatherData,
      'astro': astroData,
      'time': timeData,
      'geo': geoData,
      'target_date': targetDate.toIso8601String(),
    };
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  Future<String> _calculatePressureTrend(WeatherApiResponse weather) async {
    // Упрощённая логика тренда давления
    final random = math.Random();
    final trends = ['rising', 'falling', 'stable'];
    return trends[random.nextInt(trends.length)];
  }

  double _calculateConfidence(Map<String, dynamic> factors) {
    // Рассчитываем уверенность на основе доступности данных
    double confidence = 0.7; // Базовая уверенность

    if (factors.containsKey('personal_history')) {
      final history = factors['personal_history'] as Map<String, dynamic>;
      final totalTrips = history['total_trips'] as int? ?? 0;
      if (totalTrips >= 10) confidence += 0.15;
      else if (totalTrips >= 5) confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  ActivityLevel _getActivityLevel(int score) {
    if (score >= 80) return ActivityLevel.excellent;
    if (score >= 60) return ActivityLevel.good;
    if (score >= 40) return ActivityLevel.moderate;
    if (score >= 20) return ActivityLevel.poor;
    return ActivityLevel.veryPoor;
  }

  Map<String, dynamic> _generateTypeSpecificRecommendations(
      double score,
      FishingTypeConfig config,
      Map<String, dynamic> factors,
      ) {
    String main = '';
    String detailed = '';
    List<String> tips = [];

    if (score >= 80) {
      main = 'Отличные условия для ${config.name.toLowerCase()}! Время для трофейной ловли.';
      detailed = 'Все факторы складываются максимально благоприятно для ${config.name.toLowerCase()}. Рекомендуется активная ловля.';
      tips = [
        'Используйте ${config.techniques.isNotEmpty ? config.techniques.first : "активные приманки"}',
        'Попробуйте разные глубины',
        'Время для экспериментов',
      ];
    } else if (score >= 60) {
      main = 'Хорошие условия для ${config.name.toLowerCase()}. Стоит попробовать!';
      detailed = 'Большинство факторов благоприятны для ${config.name.toLowerCase()}.';
      tips = [
        'Придерживайтесь проверенных мест',
        'Используйте ${config.techniques.isNotEmpty ? config.techniques.take(2).join(" или ") : "знакомые приманки"}',
        'Будьте терпеливы',
      ];
    } else if (score >= 40) {
      main = 'Средние условия для ${config.name.toLowerCase()}. Потребуется терпение.';
      detailed = 'Условия не идеальны, но при правильном подходе можно рассчитывать на результат.';
      tips = [
        'Ловите в проверенных местах',
        'Попробуйте ${config.techniques.isNotEmpty ? config.techniques.last : "естественные приманки"}',
        'Измените глубину ловли',
      ];
    } else {
      main = 'Слабые условия для ${config.name.toLowerCase()}. Рассмотрите альтернативы.';
      detailed = 'Большинство факторов неблагоприятны для ${config.name.toLowerCase()}.';
      tips = [
        'Попробуйте другой тип рыбалки',
        'Дождитесь лучших условий',
        'Используйте пассивные методы ловли',
      ];
    }

    return {
      'main': main,
      'detailed': detailed,
      'tips': tips,
    };
  }

  List<BiteFactorAnalysis> _createDetailedFactors(Map<String, dynamic> factors) {
    return factors.entries.map((entry) {
      final factor = entry.value as Map<String, dynamic>;
      return BiteFactorAnalysis(
        name: factor['name'] as String,
        value: factor['value']?.toString() ?? '',
        impact: (factor['impact'] as double).round(),
        weight: factor['weight'] as double,
        description: factor['description'] as String,
        isPositive: (factor['impact'] as double) > 0,
      );
    }).toList();
  }

  List<OptimalTimeWindow> _calculateBestTimeWindowsForType(
      FishingTypeConfig config,
      Map<String, dynamic> analysisData,
      double baseScore,
      ) {
    final windows = <OptimalTimeWindow>[];
    final now = DateTime.now();

    // Создаем окна на основе лучших часов для типа рыбалки
    final sortedBestHours = List<int>.from(config.bestHours)..sort();

    for (int i = 0; i < sortedBestHours.length; i++) {
      final hour = sortedBestHours[i];
      final startTime = now.copyWith(hour: hour, minute: 0);
      final endTime = now.copyWith(hour: hour + 1, minute: 30);

      final activity = (baseScore + 10).clamp(0, 100) / 100;

      windows.add(OptimalTimeWindow(
        startTime: startTime,
        endTime: endTime,
        activity: activity,
        reason: 'Оптимальное время для ${config.name.toLowerCase()}',
        recommendations: [
          'Используйте ${config.techniques.isNotEmpty ? config.techniques.first : "рекомендуемые приманки"}',
          'Ловите ${config.targetFish.isNotEmpty ? config.targetFish.first : "целевую рыбу"}',
        ],
      ));
    }

    return windows.take(3).toList(); // Возвращаем топ-3 окна
  }

  MultiFishingTypePrediction _getFallbackMultiPrediction(WeatherApiResponse weather) {
    final fallbackPredictions = <String, AIBitePrediction>{};

    for (final entry in fishingTypeConfigs.entries) {
      fallbackPredictions[entry.key] = AIBitePrediction(
        overallScore: 40,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.3,
        recommendation: 'Базовый прогноз для ${entry.value.name.toLowerCase()}',
        detailedAnalysis: 'Fallback прогноз при недоступности ИИ',
        factors: [],
        bestTimeWindows: [],
        tips: ['Используйте стандартные методы ловли'],
        generatedAt: DateTime.now(),
        dataSource: 'fallback',
        modelVersion: '2.0.0',
      );
    }

    return MultiFishingTypePrediction(
      bestFishingType: 'spinning',
      bestPrediction: fallbackPredictions['spinning']!,
      allPredictions: fallbackPredictions,
      comparison: ComparisonAnalysis(
        rankings: [],
        bestOverall: FishingTypeRanking(
          fishingType: 'spinning',
          typeName: 'Спиннинг',
          icon: '🎯',
          score: 40,
          activityLevel: ActivityLevel.moderate,
          shortRecommendation: 'Базовые условия',
          keyFactors: [],
        ),
        alternativeOptions: [],
        worstOptions: [],
      ),
      generalRecommendations: ['Базовые условия для рыбалки'],
      weatherSummary: WeatherSummary(
        temperature: weather.current.tempC,
        pressure: weather.current.pressureMb,
        windSpeed: weather.current.windKph,
        humidity: weather.current.humidity,
        condition: weather.current.condition.text,
        moonPhase: 'Неизвестно',
      ),
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = _cache.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('❌ Ошибка сохранения кэша мультитипового ИИ: $e');
    }
  }

  /// Очистка старого кэша
  void clearOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) =>
    now.difference(value.generatedAt).inHours > 12
    );
  }
}

// Конфигурация типа рыбалки
class FishingTypeConfig {
  final String name;
  final String icon;
  final List<double> optimalTemp;
  final List<double> optimalWind;
  final List<int> bestHours;
  final List<String> weatherPreference;
  final double moonImportance;
  final double pressureImportance;
  final Map<String, double> seasonalBonus;
  final List<String> targetFish;
  final List<String> techniques;

  const FishingTypeConfig({
    required this.name,
    required this.icon,
    required this.optimalTemp,
    required this.optimalWind,
    required this.bestHours,
    required this.weatherPreference,
    required this.moonImportance,
    required this.pressureImportance,
    required this.seasonalBonus,
    required this.targetFish,
    required this.techniques,
  });
}

// Enums остаются прежними
enum ActivityLevel {
  excellent,
  good,
  moderate,
  poor,
  veryPoor,
}

extension ActivityLevelExtension on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.excellent:
        return 'Отличная';
      case ActivityLevel.good:
        return 'Хорошая';
      case ActivityLevel.moderate:
        return 'Умеренная';
      case ActivityLevel.poor:
        return 'Слабая';
      case ActivityLevel.veryPoor:
        return 'Очень слабая';
    }
  }

  Color get color {
    switch (this) {
      case ActivityLevel.excellent:
        return const Color(0xFF4CAF50);
      case ActivityLevel.good:
        return const Color(0xFF8BC34A);
      case ActivityLevel.moderate:
        return const Color(0xFFFFC107);
      case ActivityLevel.poor:
        return const Color(0xFFFF9800);
      case ActivityLevel.veryPoor:
        return const Color(0xFFF44336);
    }
  }
}