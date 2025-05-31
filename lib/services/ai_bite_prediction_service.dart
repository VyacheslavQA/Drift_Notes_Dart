// Путь: lib/services/ai_bite_prediction_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_api_model.dart';
import '../models/ai_bite_prediction_model.dart';
import '../models/fishing_note_model.dart';
import '../config/api_keys.dart';

class AIBitePredictionService {
  static final AIBitePredictionService _instance = AIBitePredictionService._internal();
  factory AIBitePredictionService() => _instance;
  AIBitePredictionService._internal();

  // Кэш для оптимизации
  final Map<String, MultiFishingTypePrediction> _cache = {};
  static const String _cacheKey = 'ai_bite_cache_multi';

  /// Основной метод получения ИИ прогноза
  Future<MultiFishingTypePrediction> getMultiFishingTypePrediction({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    List<FishingNoteModel>? userHistory,
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
          debugPrint('🤖 ИИ прогноз из кэша');
          return cached;
        }
      }

      debugPrint('🤖 Генерация нового ИИ прогноза...');

      // Собираем данные пользователя
      final userData = await _collectUserData(userHistory, latitude, longitude);

      // Анализируем погодные условия
      final weatherAnalysis = _analyzeWeatherConditions(weather);

      // Создаём прогнозы для всех типов рыбалки
      final predictions = _generatePredictionsForAllTypes(
        weather: weather,
        userData: userData,
        weatherAnalysis: weatherAnalysis,
        latitude: latitude,
        longitude: longitude,
        targetDate: targetDate,
      );

      // Если доступен OpenAI API - улучшаем прогноз с помощью ИИ
      if (ApiKeys.openAIKey.isNotEmpty && ApiKeys.openAIKey != 'YOUR_OPENAI_API_KEY_HERE') {
        await _enhanceWithOpenAI(predictions, weather, userData);
      }

      // Создаем мультитиповый прогноз
      final multiPrediction = _createMultiPrediction(
        predictions,
        preferredTypes,
        weather,
      );

      // Сохраняем в кэш
      _cache[cacheKey] = multiPrediction;

      debugPrint('✅ ИИ прогноз готов. Лучший: ${multiPrediction.bestFishingType}');
      return multiPrediction;

    } catch (e) {
      debugPrint('❌ Ошибка ИИ прогноза: $e');
      return _getFallbackPrediction(weather, userHistory, latitude, longitude);
    }
  }

  /// Сбор данных пользователя для анализа
  Future<Map<String, dynamic>> _collectUserData(
      List<FishingNoteModel>? userHistory,
      double latitude,
      double longitude,
      ) async {
    debugPrint('📊 Собираем данные пользователя...');

    if (userHistory == null || userHistory.isEmpty) {
      return {
        'has_data': false,
        'total_trips': 0,
        'success_rate': 0.0,
        'preferred_types': <String>[],
        'successful_conditions': <Map<String, dynamic>>[],
        'location_familiarity': 0.0,
      };
    }

    // Анализируем историю пользователя
    final successfulTrips = userHistory.where((note) =>
    note.biteRecords.isNotEmpty &&
        note.biteRecords.any((bite) => bite.weight > 0)
    ).toList();

    // Найдем поездки рядом с текущим местоположением (используем отдельные поля latitude/longitude)
    final locationTrips = userHistory.where((note) {
      return _calculateDistance(
        note.latitude,
        note.longitude,
        latitude,
        longitude,
      ) < 50; // В радиусе 50 км
    }).toList();

    // Анализ успешных условий
    final successfulConditions = <Map<String, dynamic>>[];
    for (final trip in successfulTrips) {
      // Используем правильные поля из FishingNoteModel
      successfulConditions.add({
        'fishing_type': trip.fishingType,
        'time_of_day': trip.date.hour,
        'season': _getSeason(trip.date),
        'catch_weight': trip.biteRecords.fold(0.0, (sum, bite) => sum + bite.weight),
        'bite_count': trip.biteRecords.length,
        'duration_hours': trip.endDate?.difference(trip.date).inHours ?? 8,
      });
    }

    // Предпочитаемые типы рыбалки
    final typeFrequency = <String, int>{};
    for (final trip in userHistory) {
      typeFrequency[trip.fishingType] = (typeFrequency[trip.fishingType] ?? 0) + 1;
    }

    final preferredTypes = typeFrequency.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'has_data': true,
      'total_trips': userHistory.length,
      'successful_trips': successfulTrips.length,
      'success_rate': successfulTrips.length / userHistory.length,
      'preferred_types': preferredTypes.take(3).map((e) => e.key).toList(),
      'successful_conditions': successfulConditions,
      'location_familiarity': locationTrips.length / userHistory.length,
      'avg_trip_duration': userHistory
          .map((trip) => trip.endDate?.difference(trip.date).inHours ?? 0)
          .where((duration) => duration > 0)
          .fold(0.0, (sum, duration) => sum + duration) / userHistory.length,
      'favorite_seasons': _analyzeFavoriteSeasons(userHistory),
      'best_times': _analyzeBestTimes(successfulTrips),
    };
  }

  /// Анализ погодных условий (локальный алгоритм)
  Map<String, dynamic> _analyzeWeatherConditions(WeatherApiResponse weather) {
    final current = weather.current;
    double suitability = 50.0; // Базовый скор

    // Анализ давления
    final pressure = current.pressureMb;
    if (pressure >= 1010 && pressure <= 1025) {
      suitability += 20; // Идеальное давление
    } else if (pressure < 1000 || pressure > 1030) {
      suitability -= 15; // Плохое давление
    }

    // Анализ ветра
    final windKph = current.windKph;
    if (windKph <= 15) {
      suitability += 15; // Отличный ветер
    } else if (windKph <= 25) {
      suitability += 5; // Хороший ветер
    } else if (windKph > 35) {
      suitability -= 20; // Сильный ветер
    }

    // Анализ температуры
    final temp = current.tempC;
    if (temp >= 15 && temp <= 25) {
      suitability += 10; // Комфортная температура
    } else if (temp < 5 || temp > 35) {
      suitability -= 10; // Экстремальная температура
    }

    // Анализ облачности
    final clouds = current.cloud;
    if (clouds >= 30 && clouds <= 70) {
      suitability += 5; // Хорошая облачность
    } else if (clouds == 0) {
      suitability -= 5; // Слишком ярко
    }

    // Анализ фазы луны
    String moonImpact = 'neutral';
    if (weather.forecast.isNotEmpty) {
      final moonPhase = weather.forecast.first.astro.moonPhase.toLowerCase();
      if (moonPhase.contains('new') || moonPhase.contains('full')) {
        suitability += 10;
        moonImpact = 'positive';
      }
    }

    return {
      'overall_suitability': suitability.clamp(0.0, 100.0),
      'pressure_impact': _getPressureImpact(pressure),
      'wind_impact': _getWindImpact(windKph),
      'temperature_impact': _getTemperatureImpact(temp),
      'moon_impact': moonImpact,
      'best_hours': _calculateBestHours(current.isDay == 1),
      'confidence': 0.8,
    };
  }

  /// Генерация прогнозов для всех типов рыбалки
  Map<String, AIBitePrediction> _generatePredictionsForAllTypes({
    required WeatherApiResponse weather,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> weatherAnalysis,
    required double latitude,
    required double longitude,
    required DateTime targetDate,
  }) {
    final predictions = <String, AIBitePrediction>{};
    final baseSuitability = weatherAnalysis['overall_suitability'] as double;

    // Типы рыбалки с их характеристиками
    final fishingTypes = {
      'spinning': {
        'name': 'Спиннинг',
        'wind_tolerance': 25.0, // км/ч
        'temp_optimal_min': 10.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.8,
        'base_score_modifier': 0.0,
      },
      'feeder': {
        'name': 'Фидер',
        'wind_tolerance': 20.0,
        'temp_optimal_min': 12.0,
        'temp_optimal_max': 28.0,
        'pressure_sensitivity': 0.9,
        'base_score_modifier': 5.0,
      },
      'carp_fishing': {
        'name': 'Карповая рыбалка',
        'wind_tolerance': 15.0,
        'temp_optimal_min': 15.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 1.0,
        'base_score_modifier': 0.0,
      },
      'float_fishing': {
        'name': 'Поплавочная рыбалка',
        'wind_tolerance': 10.0,
        'temp_optimal_min': 8.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.7,
        'base_score_modifier': 10.0,
      },
      'ice_fishing': {
        'name': 'Зимняя рыбалка',
        'wind_tolerance': 30.0,
        'temp_optimal_min': -15.0,
        'temp_optimal_max': 5.0,
        'pressure_sensitivity': 1.2,
        'base_score_modifier': weather.current.tempC < 5 ? 20.0 : -30.0,
      },
      'fly_fishing': {
        'name': 'Нахлыст',
        'wind_tolerance': 8.0,
        'temp_optimal_min': 10.0,
        'temp_optimal_max': 22.0,
        'pressure_sensitivity': 0.6,
        'base_score_modifier': 0.0,
      },
      'trolling': {
        'name': 'Троллинг',
        'wind_tolerance': 35.0,
        'temp_optimal_min': 5.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 0.5,
        'base_score_modifier': 5.0,
      },
    };

    for (final entry in fishingTypes.entries) {
      final type = entry.key;
      final config = entry.value;

      predictions[type] = _generatePredictionForType(
        type,
        config,
        weather,
        userData,
        weatherAnalysis,
        baseSuitability,
      );
    }

    return predictions;
  }

  /// Генерация прогноза для конкретного типа рыбалки
  AIBitePrediction _generatePredictionForType(
      String fishingType,
      Map<String, dynamic> config,
      WeatherApiResponse weather,
      Map<String, dynamic> userData,
      Map<String, dynamic> weatherAnalysis,
      double baseSuitability,
      ) {
    double score = baseSuitability;
    final factors = <BiteFactorAnalysis>[];
    final tips = <String>[];

    // Применяем модификатор базового скора
    score += config['base_score_modifier'] as double;

    // Анализ ветра
    final windKph = weather.current.windKph;
    final windTolerance = config['wind_tolerance'] as double;
    if (windKph <= windTolerance) {
      score += 15;
      factors.add(BiteFactorAnalysis(
        name: 'Ветер',
        value: '${windKph.round()} км/ч',
        impact: 15,
        weight: 0.8,
        description: 'Благоприятный ветер для ${config['name']}',
        isPositive: true,
      ));
    } else {
      final penalty = ((windKph - windTolerance) / 5) * -10;
      score += penalty;
      factors.add(BiteFactorAnalysis(
        name: 'Ветер',
        value: '${windKph.round()} км/ч',
        impact: penalty.round(),
        weight: 0.8,
        description: 'Слишком сильный ветер для ${config['name']}',
        isPositive: false,
      ));
      tips.add('При сильном ветре ищите защищенные места');
    }

    // Анализ температуры
    final temp = weather.current.tempC;
    final tempMin = config['temp_optimal_min'] as double;
    final tempMax = config['temp_optimal_max'] as double;
    if (temp >= tempMin && temp <= tempMax) {
      score += 10;
      factors.add(BiteFactorAnalysis(
        name: 'Температура',
        value: '${temp.round()}°C',
        impact: 10,
        weight: 0.7,
        description: 'Оптимальная температура для ${config['name']}',
        isPositive: true,
      ));
    } else {
      final tempPenalty = (temp < tempMin) ? (tempMin - temp) * -2 : (temp - tempMax) * -1.5;
      score += tempPenalty;
      factors.add(BiteFactorAnalysis(
        name: 'Температура',
        value: '${temp.round()}°C',
        impact: tempPenalty.round(),
        weight: 0.7,
        description: temp < tempMin ? 'Слишком холодно' : 'Слишком жарко',
        isPositive: false,
      ));
    }

    // Анализ давления
    final pressure = weather.current.pressureMb;
    final pressureSensitivity = config['pressure_sensitivity'] as double;
    if (pressure >= 1010 && pressure <= 1025) {
      final bonus = 10 * pressureSensitivity;
      score += bonus;
      factors.add(BiteFactorAnalysis(
        name: 'Атмосферное давление',
        value: '${pressure.round()} мб',
        impact: bonus.round(),
        weight: pressureSensitivity,
        description: 'Стабильное давление способствует клеву',
        isPositive: true,
      ));
    } else {
      final penalty = pressure < 1000 ? -15 * pressureSensitivity : -10 * pressureSensitivity;
      score += penalty;
      factors.add(BiteFactorAnalysis(
        name: 'Атмосферное давление',
        value: '${pressure.round()} мб',
        impact: penalty.round(),
        weight: pressureSensitivity,
        description: pressure < 1000 ? 'Низкое давление снижает активность' : 'Высокое давление',
        isPositive: false,
      ));
      tips.add('При изменении давления рыба может быть пассивной');
    }

    // Учет пользовательских данных
    if (userData['has_data'] == true) {
      final preferredTypes = userData['preferred_types'] as List<dynamic>;
      if (preferredTypes.contains(fishingType)) {
        score += 5;
        factors.add(BiteFactorAnalysis(
          name: 'Персональная история',
          value: 'Предпочитаемый тип',
          impact: 5,
          weight: 0.6,
          description: 'Вы часто используете этот тип рыбалки',
          isPositive: true,
        ));
      }
    }

    // Генерируем временные окна
    final timeWindows = _generateTimeWindows(weather, fishingType);

    // Генерируем дополнительные советы
    tips.addAll(_generateTipsForType(fishingType, weather));

    // Определяем уровень активности
    final activityLevel = _determineActivityLevel(score);

    // Генерируем рекомендацию
    final recommendation = _generateRecommendation(fishingType, score, factors);

    return AIBitePrediction(
      overallScore: score.round().clamp(0, 100),
      activityLevel: activityLevel,
      confidence: 0.8,
      recommendation: recommendation,
      detailedAnalysis: _generateDetailedAnalysis(fishingType, factors, weather),
      factors: factors,
      bestTimeWindows: timeWindows,
      tips: tips,
      generatedAt: DateTime.now(),
      dataSource: 'local_ai',
      modelVersion: '2.0.0',
    );
  }

  /// Улучшение прогноза с помощью OpenAI (если доступен)
  Future<void> _enhanceWithOpenAI(
      Map<String, AIBitePrediction> predictions,
      WeatherApiResponse weather,
      Map<String, dynamic> userData,
      ) async {
    if (ApiKeys.openAIKey.isEmpty || ApiKeys.openAIKey == 'YOUR_OPENAI_API_KEY_HERE') {
      return;
    }

    try {
      debugPrint('🧠 Улучшаем прогноз с помощью OpenAI...');

      final prompt = _buildOpenAIPrompt(predictions, weather, userData);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты эксперт по рыбалке. Проанализируй условия и дай краткие советы.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiTips = data['choices'][0]['message']['content'] as String;

        // Добавляем советы от ИИ к лучшему прогнозу
        final bestType = predictions.entries
            .reduce((a, b) => a.value.overallScore > b.value.overallScore ? a : b)
            .key;

        if (predictions[bestType] != null) {
          final enhanced = predictions[bestType]!;
          enhanced.tips.add('💡 Совет ИИ: $aiTips');
        }

        debugPrint('✅ OpenAI улучшение применено');
      }
    } catch (e) {
      debugPrint('❌ Ошибка OpenAI: $e');
    }
  }

  /// Создание мультитипового прогноза
  MultiFishingTypePrediction _createMultiPrediction(
      Map<String, AIBitePrediction> predictions,
      List<String>? preferredTypes,
      WeatherApiResponse weather,
      ) {
    // Сортируем по скору
    final sortedPredictions = predictions.entries.toList()
      ..sort((a, b) => b.value.overallScore.compareTo(a.value.overallScore));

    // Определяем лучший тип с учетом предпочтений пользователя
    String bestType = sortedPredictions.first.key;

    if (preferredTypes != null && preferredTypes.isNotEmpty) {
      for (final preferred in preferredTypes) {
        if (predictions.containsKey(preferred) && predictions[preferred]!.overallScore >= 40) {
          bestType = preferred;
          break;
        }
      }
    }

    // Создаем сравнительный анализ
    final comparison = _createComparisonAnalysis(predictions);

    // Генерируем общие рекомендации
    final generalRecommendations = _generateGeneralRecommendations(predictions, bestType);

    return MultiFishingTypePrediction(
      bestFishingType: bestType,
      bestPrediction: predictions[bestType]!,
      allPredictions: predictions,
      comparison: comparison,
      generalRecommendations: generalRecommendations,
      weatherSummary: _createWeatherSummary(weather),
      generatedAt: DateTime.now(),
    );
  }

  // Вспомогательные методы...

  String _getPressureImpact(double pressure) {
    if (pressure >= 1010 && pressure <= 1025) return 'positive';
    if (pressure < 1000 || pressure > 1030) return 'negative';
    return 'neutral';
  }

  String _getWindImpact(double windKph) {
    if (windKph <= 15) return 'positive';
    if (windKph <= 25) return 'neutral';
    return 'negative';
  }

  String _getTemperatureImpact(double temp) {
    if (temp >= 15 && temp <= 25) return 'positive';
    if (temp < 5 || temp > 35) return 'negative';
    return 'neutral';
  }

  List<String> _calculateBestHours(bool isDay) {
    if (isDay) {
      return ['06:00-08:00', '18:00-20:00'];
    } else {
      return ['20:00-22:00', '05:00-07:00'];
    }
  }

  List<OptimalTimeWindow> _generateTimeWindows(WeatherApiResponse weather, String fishingType) {
    final now = DateTime.now();
    final windows = <OptimalTimeWindow>[];

    // Утреннее окно
    windows.add(OptimalTimeWindow(
      startTime: now.copyWith(hour: 6, minute: 0),
      endTime: now.copyWith(hour: 8, minute: 30),
      activity: 0.85,
      reason: 'Утренняя активность рыбы',
      recommendations: ['Используйте активные приманки'],
    ));

    // Вечернее окно
    windows.add(OptimalTimeWindow(
      startTime: now.copyWith(hour: 18, minute: 0),
      endTime: now.copyWith(hour: 20, minute: 30),
      activity: 0.9,
      reason: 'Вечерняя активность рыбы',
      recommendations: ['Попробуйте поверхностные приманки'],
    ));

    return windows;
  }

  List<String> _generateTipsForType(String fishingType, WeatherApiResponse weather) {
    final tips = <String>[];

    switch (fishingType) {
      case 'spinning':
        tips.add('Используйте яркие приманки в пасмурную погоду');
        if (weather.current.windKph > 20) {
          tips.add('При сильном ветре используйте более тяжелые приманки');
        }
        break;
      case 'feeder':
        tips.add('Проверяйте кормушку каждые 15-20 минут');
        tips.add('Используйте ароматизированную прикормку');
        break;
      case 'carp_fishing':
        tips.add('Используйте бойлы и PVA-пакеты');
        tips.add('Ловите в тихих местах с медленным течением');
        break;
      case 'float_fishing':
        tips.add('Следите за поплавком и делайте быструю подсечку');
        if (weather.current.windKph < 10) {
          tips.add('Отличные условия для точной проводки');
        }
        break;
    }

    return tips;
  }

  ActivityLevel _determineActivityLevel(double score) {
    if (score >= 80) return ActivityLevel.excellent;
    if (score >= 60) return ActivityLevel.good;
    if (score >= 40) return ActivityLevel.moderate;
    if (score >= 20) return ActivityLevel.poor;
    return ActivityLevel.veryPoor;
  }

  String _generateRecommendation(String fishingType, double score, List<BiteFactorAnalysis> factors) {
    if (score >= 80) {
      return 'Отличные условия для ${_getFishingTypeName(fishingType)}! Самое время отправляться на рыбалку.';
    } else if (score >= 60) {
      return 'Хорошие условия для ${_getFishingTypeName(fishingType)}. Стоит попробовать!';
    } else if (score >= 40) {
      return 'Средние условия. ${_getFishingTypeName(fishingType)} может принести результат.';
    } else {
      return 'Сложные условия для рыбалки. Рекомендуется подождать улучшения погоды.';
    }
  }

  String _generateDetailedAnalysis(String fishingType, List<BiteFactorAnalysis> factors, WeatherApiResponse weather) {
    final analysis = StringBuffer();
    analysis.write('Анализ условий для ${_getFishingTypeName(fishingType)}: ');

    final positiveFactors = factors.where((f) => f.isPositive).length;
    final negativeFactors = factors.where((f) => !f.isPositive).length;

    if (positiveFactors > negativeFactors) {
      analysis.write('Преобладают благоприятные факторы. ');
    } else if (negativeFactors > positiveFactors) {
      analysis.write('Есть неблагоприятные факторы, которые могут снизить активность рыбы. ');
    } else {
      analysis.write('Смешанные условия - успех зависит от техники и опыта. ');
    }

    analysis.write('Температура воздуха ${weather.current.tempC.round()}°C, ');
    analysis.write('давление ${weather.current.pressureMb.round()} мб, ');
    analysis.write('ветер ${weather.current.windKph.round()} км/ч.');

    return analysis.toString();
  }

  ComparisonAnalysis _createComparisonAnalysis(Map<String, AIBitePrediction> predictions) {
    final rankings = predictions.entries.map((e) => FishingTypeRanking(
      fishingType: e.key,
      typeName: _getFishingTypeName(e.key),
      icon: _getFishingTypeIcon(e.key),
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

    recommendations.add('Рекомендуемый тип: ${_getFishingTypeName(bestType)}');
    recommendations.add(bestPrediction.recommendation);

    if (bestPrediction.overallScore >= 80) {
      recommendations.add('Отличные условия - не упустите возможность!');
    } else if (bestPrediction.overallScore < 40) {
      recommendations.add('Подумайте о переносе рыбалки на более благоприятное время');
    }

    return recommendations;
  }

  WeatherSummary _createWeatherSummary(WeatherApiResponse weather) {
    return WeatherSummary(
      temperature: weather.current.tempC,
      pressure: weather.current.pressureMb,
      windSpeed: weather.current.windKph,
      humidity: weather.current.humidity,
      condition: weather.current.condition.text,
      moonPhase: weather.forecast.isNotEmpty ? weather.forecast.first.astro.moonPhase : 'Unknown',
    );
  }

  String _buildOpenAIPrompt(Map<String, AIBitePrediction> predictions, WeatherApiResponse weather, Map<String, dynamic> userData) {
    return '''
Погодные условия: температура ${weather.current.tempC}°C, давление ${weather.current.pressureMb} мб, ветер ${weather.current.windKph} км/ч.
Лучший тип рыбалки по алгоритму: ${predictions.entries.reduce((a, b) => a.value.overallScore > b.value.overallScore ? a : b).key}.
Дай 1-2 кратких совета для успешной рыбалки в этих условиях.
''';
  }

  /// Fallback прогноз при ошибках
  MultiFishingTypePrediction _getFallbackPrediction(
      WeatherApiResponse weather,
      List<FishingNoteModel>? userHistory,
      double latitude,
      double longitude,
      ) {
    final fallbackPredictions = <String, AIBitePrediction>{};

    for (final type in ['spinning', 'feeder', 'carp_fishing', 'float_fishing']) {
      fallbackPredictions[type] = AIBitePrediction(
        overallScore: 50,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.3,
        recommendation: 'Базовые условия для рыбалки',
        detailedAnalysis: 'Анализ основан на базовых алгоритмах',
        factors: [],
        bestTimeWindows: [],
        tips: ['Ловите в утренние и вечерние часы'],
        generatedAt: DateTime.now(),
        dataSource: 'fallback',
        modelVersion: '1.0.0',
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
          score: 50,
          activityLevel: ActivityLevel.moderate,
          shortRecommendation: 'Базовые условия',
          keyFactors: [],
        ),
        alternativeOptions: [],
        worstOptions: [],
      ),
      generalRecommendations: ['Используйте стандартные подходы к рыбалке'],
      weatherSummary: WeatherSummary(
        temperature: weather.current.tempC,
        pressure: weather.current.pressureMb,
        windSpeed: weather.current.windKph,
        humidity: weather.current.humidity,
        condition: weather.current.condition.text,
        moonPhase: weather.forecast.isNotEmpty ? weather.forecast.first.astro.moonPhase : 'Unknown',
      ),
      generatedAt: DateTime.now(),
    );
  }

  // Дополнительные вспомогательные методы...

  String _generateCacheKey(double lat, double lon, DateTime date) {
    return 'ai_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // км
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  Map<String, double> _analyzeFavoriteSeasons(List<FishingNoteModel> history) {
    final seasonCounts = <String, int>{};
    for (final trip in history) {
      final season = _getSeason(trip.date);
      seasonCounts[season] = (seasonCounts[season] ?? 0) + 1;
    }

    final total = history.length;
    return seasonCounts.map((season, count) => MapEntry(season, count / total));
  }

  List<int> _analyzeBestTimes(List<FishingNoteModel> successfulTrips) {
    final hourCounts = <int, int>{};
    for (final trip in successfulTrips) {
      hourCounts[trip.date.hour] = (hourCounts[trip.date.hour] ?? 0) + 1;
    }

    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHours.take(5).map((e) => e.key).toList();
  }

  String _getFishingTypeName(String type) {
    const names = {
      'spinning': 'Спиннинг',
      'feeder': 'Фидер',
      'carp_fishing': 'Карповая ловля',
      'float_fishing': 'Поплавочная ловля',
      'ice_fishing': 'Зимняя рыбалка',
      'fly_fishing': 'Нахлыст',
      'trolling': 'Троллинг',
    };
    return names[type] ?? type;
  }

  String _getFishingTypeIcon(String type) {
    const icons = {
      'spinning': '🎯',
      'feeder': '🐟',
      'carp_fishing': '🦎',
      'float_fishing': '🎣',
      'ice_fishing': '❄️',
      'fly_fishing': '🦋',
      'trolling': '🚤',
    };
    return icons[type] ?? '🎣';
  }

  /// Очистка старого кэша
  void clearOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) =>
    now.difference(value.generatedAt).inHours > 2 // Кэш актуален 2 часа
    );
  }
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