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
  static const String _userDataCacheKey = 'ai_user_data_cache';
  static const String _internetDataCacheKey = 'ai_internet_data_cache';

  // Настройки ИИ
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';
  static const String _fishingApiBaseUrl = 'https://api.fishingapi.com/v1'; // Пример API рыболовных данных
  static const String _weatherInfluenceApiUrl = 'https://api.weatherinfluence.com/v1'; // Пример API влияния погоды

  /// Основной метод получения ИИ прогноза с использованием реальных данных
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

      // Проверяем кэш (актуален 15 минут для реального ИИ)
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().difference(cached.generatedAt).inMinutes < 15) {
          debugPrint('🤖 ИИ прогноз из кэша');
          return cached;
        }
      }

      debugPrint('🤖 Генерация нового ИИ прогноза с интернет-данными...');

      // Шаг 1: Собираем данные пользователя
      final userData = await _collectUserData(userHistory, latitude, longitude);

      // Шаг 2: Получаем данные из интернета
      final internetData = await _fetchInternetFishingData(latitude, longitude, targetDate);

      // Шаг 3: Анализируем погодные условия с помощью внешних API
      final weatherAnalysis = await _analyzeWeatherWithAI(weather, latitude, longitude);

      // Шаг 4: Объединяем все данные для ИИ-анализа
      final aiInput = _prepareAIInput(
        weather: weather,
        userData: userData,
        internetData: internetData,
        weatherAnalysis: weatherAnalysis,
        latitude: latitude,
        longitude: longitude,
        targetDate: targetDate,
      );

      // Шаг 5: Получаем прогноз от ИИ
      final aiPredictions = await _getAIPredictions(aiInput);

      // Шаг 6: Создаем мультитиповый прогноз
      final multiPrediction = _createMultiPredictionFromAI(
        aiPredictions,
        preferredTypes,
        weather,
        internetData,
      );

      // Сохраняем в кэш
      _cache[cacheKey] = multiPrediction;
      await _saveCacheToStorage();

      // Обучаем модель на основе результата (если есть фидбек пользователя)
      _scheduleModelTraining(aiInput, multiPrediction);

      debugPrint('✅ ИИ прогноз готов. Лучший: ${multiPrediction.bestFishingType}');
      return multiPrediction;

    } catch (e) {
      debugPrint('❌ Ошибка ИИ прогноза: $e');
      // Fallback на локальный анализ
      return _getFallbackPrediction(weather, userHistory, latitude, longitude);
    }
  }

  /// Сбор данных пользователя для ИИ-анализа
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

    final locationTrips = userHistory.where((note) =>
    _calculateDistance(
      note.coordinates?['latitude'] ?? 0,
      note.coordinates?['longitude'] ?? 0,
      latitude,
      longitude,
    ) < 50 // В радиусе 50 км
    ).toList();

    // Анализ успешных условий
    final successfulConditions = <Map<String, dynamic>>[];
    for (final trip in successfulTrips) {
      if (trip.weatherData != null) {
        successfulConditions.add({
          'temperature': trip.weatherData!.temperature,
          'pressure': trip.weatherData!.pressure,
          'wind_speed': trip.weatherData!.windSpeed,
          'weather_description': trip.weatherData!.weatherDescription,
          'moon_phase': trip.weatherData!.moonPhase,
          'fishing_type': trip.fishingType,
          'time_of_day': trip.startDate.hour,
          'season': _getSeason(trip.startDate),
          'catch_weight': trip.biteRecords.fold(0.0, (sum, bite) => sum + bite.weight),
          'bite_count': trip.biteRecords.length,
        });
      }
    }

    // Предпочитаемые типы рыбалки
    final typeFrequency = <String, int>{};
    for (final trip in userHistory) {
      typeFrequency[trip.fishingType] = (typeFrequency[trip.fishingType] ?? 0) + 1;
    }

    final preferredTypes = typeFrequency.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..map((e) => e.key)
          .take(3)
          .toList();

    return {
      'has_data': true,
      'total_trips': userHistory.length,
      'successful_trips': successfulTrips.length,
      'success_rate': successfulTrips.length / userHistory.length,
      'preferred_types': preferredTypes,
      'successful_conditions': successfulConditions,
      'location_familiarity': locationTrips.length / userHistory.length,
      'avg_trip_duration': userHistory
          .map((trip) => trip.endDate?.difference(trip.startDate).inHours ?? 0)
          .where((duration) => duration > 0)
          .fold(0.0, (sum, duration) => sum + duration) / userHistory.length,
      'favorite_seasons': _analyzeFavoriteSeasons(userHistory),
      'best_times': _analyzeBestTimes(successfulTrips),
    };
  }

  /// Получение данных о рыбалке из интернета
  Future<Map<String, dynamic>> _fetchInternetFishingData(
      double latitude,
      double longitude,
      DateTime targetDate,
      ) async {
    debugPrint('🌐 Получаем данные о рыбалке из интернета...');

    try {
      // Кэшируем интернет-данные на 1 час
      final cacheKey = 'internet_data_${latitude}_${longitude}_${targetDate.day}';
      final cachedData = await _getCachedInternetData(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final futures = <Future<Map<String, dynamic>>>[];

      // 1. Данные о рыболовных условиях из специализированных API
      futures.add(_fetchFishingConditionsData(latitude, longitude));

      // 2. Исторические данные клева для региона
      futures.add(_fetchHistoricalBiteData(latitude, longitude, targetDate));

      // 3. Сообщения рыболовных форумов и социальных сетей
      futures.add(_fetchSocialFishingReports(latitude, longitude));

      // 4. Научные данные о поведении рыб
      futures.add(_fetchFishBehaviorData(latitude, longitude, targetDate));

      // 5. Локальные рыболовные отчеты
      futures.add(_fetchLocalFishingReports(latitude, longitude));

      final results = await Future.wait(futures);

      final combinedData = <String, dynamic>{
        'fishing_conditions': results[0],
        'historical_bite': results[1],
        'social_reports': results[2],
        'fish_behavior': results[3],
        'local_reports': results[4],
        'data_quality_score': _calculateDataQuality(results),
        'last_updated': DateTime.now().toIso8601String(),
      };

      await _cacheInternetData(cacheKey, combinedData);
      return combinedData;

    } catch (e) {
      debugPrint('❌ Ошибка получения интернет-данных: $e');
      return {
        'error': e.toString(),
        'fallback_data': await _getFallbackInternetData(latitude, longitude),
      };
    }
  }

  /// Получение данных о рыболовных условиях
  Future<Map<String, dynamic>> _fetchFishingConditionsData(
      double latitude,
      double longitude,
      ) async {
    try {
      // Пример запроса к API рыболовных условий
      final response = await http.get(
        Uri.parse('$_fishingApiBaseUrl/conditions?lat=$latitude&lon=$longitude'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.fishingApiKey}', // Добавить в api_keys.dart
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'water_temperature': data['water_temp'] ?? 15.0,
          'water_clarity': data['clarity'] ?? 'moderate',
          'fish_activity_index': data['activity_index'] ?? 0.5,
          'optimal_depths': data['optimal_depths'] ?? [2.0, 5.0, 8.0],
          'recommended_baits': data['recommended_baits'] ?? ['worm', 'spinner'],
          'local_species': data['local_species'] ?? ['carp', 'pike', 'perch'],
          'seasonal_patterns': data['seasonal_patterns'] ?? {},
          'source': 'fishing_api',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Fishing API недоступен: $e');
    }

    // Fallback данные
    return {
      'water_temperature': 15.0,
      'water_clarity': 'moderate',
      'fish_activity_index': 0.5,
      'optimal_depths': [2.0, 5.0, 8.0],
      'recommended_baits': ['worm', 'spinner'],
      'local_species': ['carp', 'pike', 'perch'],
      'source': 'fallback',
    };
  }

  /// Получение исторических данных клева
  Future<Map<String, dynamic>> _fetchHistoricalBiteData(
      double latitude,
      double longitude,
      DateTime targetDate,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$_fishingApiBaseUrl/historical-bite?lat=$latitude&lon=$longitude&month=${targetDate.month}&day=${targetDate.day}'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.fishingApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'historical_activity': data['historical_activity'] ?? 0.6,
          'best_historical_times': data['best_times'] ?? ['06:00', '18:00'],
          'seasonal_trends': data['seasonal_trends'] ?? {},
          'weather_correlations': data['weather_correlations'] ?? {},
          'success_rate_by_type': data['success_by_type'] ?? {},
          'source': 'historical_api',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Historical API недоступен: $e');
    }

    return {
      'historical_activity': 0.6,
      'best_historical_times': ['06:00', '18:00'],
      'source': 'fallback',
    };
  }

  /// Получение отчетов из соцсетей и форумов
  Future<Map<String, dynamic>> _fetchSocialFishingReports(
      double latitude,
      double longitude,
      ) async {
    try {
      // Анализируем недавние посты в соцсетях и на форумах
      final response = await http.get(
        Uri.parse('$_fishingApiBaseUrl/social-reports?lat=$latitude&lon=$longitude&radius=50'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.fishingApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'recent_reports': data['reports'] ?? [],
          'sentiment_score': data['sentiment'] ?? 0.5, // Позитивность отзывов
          'activity_mentions': data['activity_mentions'] ?? 0,
          'popular_locations': data['popular_spots'] ?? [],
          'trending_baits': data['trending_baits'] ?? [],
          'source': 'social_api',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Social API недоступен: $e');
    }

    return {
      'recent_reports': [],
      'sentiment_score': 0.5,
      'activity_mentions': 0,
      'source': 'fallback',
    };
  }

  /// Получение данных о поведении рыб
  Future<Map<String, dynamic>> _fetchFishBehaviorData(
      double latitude,
      double longitude,
      DateTime targetDate,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$_fishingApiBaseUrl/fish-behavior?lat=$latitude&lon=$longitude&date=${targetDate.toIso8601String()}'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.fishingApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'spawning_season': data['spawning_season'] ?? false,
          'migration_patterns': data['migration'] ?? {},
          'feeding_times': data['feeding_times'] ?? [],
          'species_activity': data['species_activity'] ?? {},
          'environmental_stress': data['stress_factors'] ?? [],
          'source': 'behavior_api',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Behavior API недоступен: $e');
    }

    return {
      'spawning_season': false,
      'migration_patterns': {},
      'feeding_times': ['06:00-08:00', '18:00-20:00'],
      'source': 'fallback',
    };
  }

  /// Получение локальных рыболовных отчетов
  Future<Map<String, dynamic>> _fetchLocalFishingReports(
      double latitude,
      double longitude,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$_fishingApiBaseUrl/local-reports?lat=$latitude&lon=$longitude'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.fishingApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'local_guides_reports': data['guides'] ?? [],
          'fishing_store_reports': data['stores'] ?? [],
          'ranger_reports': data['rangers'] ?? [],
          'local_conditions': data['conditions'] ?? {},
          'source': 'local_api',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Local API недоступен: $e');
    }

    return {
      'local_guides_reports': [],
      'fishing_store_reports': [],
      'ranger_reports': [],
      'source': 'fallback',
    };
  }

  /// Анализ погоды с помощью ИИ
  Future<Map<String, dynamic>> _analyzeWeatherWithAI(
      WeatherApiResponse weather,
      double latitude,
      double longitude,
      ) async {
    debugPrint('🧠 ИИ-анализ погодных условий...');

    try {
      final prompt = _buildWeatherAnalysisPrompt(weather, latitude, longitude);

      final response = await http.post(
        Uri.parse('$_openAIBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert fishing guide with 30 years of experience. Analyze weather conditions and provide fishing recommendations in JSON format.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        try {
          final analysisResult = json.decode(aiResponse);
          return {
            'ai_analysis': analysisResult,
            'confidence': 0.9,
            'model_used': 'gpt-4',
            'source': 'openai',
          };
        } catch (e) {
          return _parseUnstructuredAIResponse(aiResponse);
        }
      }
    } catch (e) {
      debugPrint('❌ OpenAI API ошибка: $e');
    }

    // Fallback анализ
    return _getFallbackWeatherAnalysis(weather);
  }

  /// Подготовка входных данных для ИИ
  Map<String, dynamic> _prepareAIInput({
    required WeatherApiResponse weather,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> internetData,
    required Map<String, dynamic> weatherAnalysis,
    required double latitude,
    required double longitude,
    required DateTime targetDate,
  }) {
    return {
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'region': weather.location.region,
        'country': weather.location.country,
      },
      'datetime': {
        'target_date': targetDate.toIso8601String(),
        'hour': targetDate.hour,
        'day_of_week': targetDate.weekday,
        'month': targetDate.month,
        'season': _getSeason(targetDate),
      },
      'weather': {
        'temperature': weather.current.tempC,
        'feels_like': weather.current.feelslikeC,
        'humidity': weather.current.humidity,
        'pressure': weather.current.pressureMb,
        'wind_speed': weather.current.windKph,
        'wind_direction': weather.current.windDir,
        'cloud_cover': weather.current.cloud,
        'visibility': weather.current.visKm,
        'uv_index': weather.current.uv,
        'condition': weather.current.condition.text,
        'is_day': weather.current.isDay == 1,
        'moon_phase': weather.forecast.isNotEmpty ? weather.forecast.first.astro.moonPhase : '',
        'sunrise': weather.forecast.isNotEmpty ? weather.forecast.first.astro.sunrise : '',
        'sunset': weather.forecast.isNotEmpty ? weather.forecast.first.astro.sunset : '',
      },
      'user_data': userData,
      'internet_data': internetData,
      'weather_analysis': weatherAnalysis,
      'available_fishing_types': [
        'spinning', 'feeder', 'carp_fishing', 'float_fishing',
        'ice_fishing', 'fly_fishing', 'trolling'
      ],
    };
  }

  /// Получение прогнозов от ИИ для всех типов рыбалки
  Future<Map<String, AIBitePrediction>> _getAIPredictions(Map<String, dynamic> input) async {
    debugPrint('🤖 Получаем ИИ-прогнозы для всех типов рыбалки...');

    try {
      final prompt = _buildFishingPredictionPrompt(input);

      final response = await http.post(
        Uri.parse('$_openAIBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a world-class fishing expert with deep knowledge of fish behavior, weather patterns, and fishing techniques. 
              Analyze the provided data and give detailed predictions for each fishing type. 
              Response must be a valid JSON object with predictions for each fishing type.''',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 2000,
          'temperature': 0.4,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        try {
          final predictionsJson = json.decode(aiResponse);
          return _parseAIPredictions(predictionsJson, input);
        } catch (e) {
          debugPrint('❌ Ошибка парсинга ИИ ответа: $e');
          return _getFallbackPredictions(input);
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка ИИ API: $e');
    }

    return _getFallbackPredictions(input);
  }

  /// Парсинг ответа ИИ в структурированные прогнозы
  Map<String, AIBitePrediction> _parseAIPredictions(
      Map<String, dynamic> aiResponse,
      Map<String, dynamic> input,
      ) {
    final predictions = <String, AIBitePrediction>{};

    for (final fishingType in input['available_fishing_types'] as List<String>) {
      final typeData = aiResponse[fishingType] as Map<String, dynamic>?;

      if (typeData != null) {
        predictions[fishingType] = AIBitePrediction(
          overallScore: (typeData['score'] ?? 50).round(),
          activityLevel: _parseActivityLevel(typeData['activity_level'] ?? 'moderate'),
          confidence: (typeData['confidence'] ?? 0.7).toDouble(),
          recommendation: typeData['recommendation'] ?? 'Стандартные условия для рыбалки',
          detailedAnalysis: typeData['detailed_analysis'] ?? 'ИИ-анализ недоступен',
          factors: _parseFactors(typeData['factors'] ?? []),
          bestTimeWindows: _parseTimeWindows(typeData['best_times'] ?? []),
          tips: List<String>.from(typeData['tips'] ?? ['Удачной рыбалки!']),
          generatedAt: DateTime.now(),
          dataSource: 'openai_gpt4',
          modelVersion: '4.0.0',
        );
      }
    }

    return predictions;
  }

  /// Создание мультитипового прогноза из ИИ данных
  MultiFishingTypePrediction _createMultiPredictionFromAI(
      Map<String, AIBitePrediction> predictions,
      List<String>? preferredTypes,
      WeatherApiResponse weather,
      Map<String, dynamic> internetData,
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
    final comparison = _createAIComparisonAnalysis(predictions);

    // ИИ-генерированные рекомендации
    final generalRecommendations = _generateAIRecommendations(predictions, bestType, internetData);

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

  /// Построение промпта для анализа погоды
  String _buildWeatherAnalysisPrompt(WeatherApiResponse weather, double lat, double lon) {
    return '''
Analyze the following weather conditions for fishing at coordinates $lat, $lon:

Current Weather:
- Temperature: ${weather.current.tempC}°C (feels like ${weather.current.feelslikeC}°C)
- Pressure: ${weather.current.pressureMb} mb
- Humidity: ${weather.current.humidity}%
- Wind: ${weather.current.windKph} km/h ${weather.current.windDir}
- Cloud cover: ${weather.current.cloud}%
- Visibility: ${weather.current.visKm} km
- UV Index: ${weather.current.uv}
- Condition: ${weather.current.condition.text}
- Time of day: ${weather.current.isDay == 1 ? 'Day' : 'Night'}

Please provide analysis in JSON format with these fields:
{
  "overall_fishing_suitability": 0-100,
  "pressure_impact": "positive/negative/neutral",
  "temperature_impact": "positive/negative/neutral", 
  "wind_impact": "positive/negative/neutral",
  "cloud_impact": "positive/negative/neutral",
  "key_recommendations": ["tip1", "tip2", "tip3"],
  "best_fishing_hours": ["HH:MM-HH:MM"],
  "weather_stability": "stable/changing/unstable"
}
''';
  }

  /// Построение промпта для прогноза рыбалки
  String _buildFishingPredictionPrompt(Map<String, dynamic> input) {
    final weather = input['weather'];
    final userData = input['user_data'];
    final internetData = input['internet_data'];

    return '''
Analyze fishing conditions and provide predictions for each fishing type:

LOCATION: ${input['location']['latitude']}, ${input['location']['longitude']} (${input['location']['region']})
DATE: ${input['datetime']['target_date']} (${input['datetime']['season']})

WEATHER CONDITIONS:
- Temperature: ${weather['temperature']}°C (feels like ${weather['feels_like']}°C)
- Pressure: ${weather['pressure']} mb
- Wind: ${weather['wind_speed']} km/h ${weather['wind_direction']}
- Humidity: ${weather['humidity']}%
- Visibility: ${weather['visibility']} km
- Cloud cover: ${weather['cloud_cover']}%
- Moon phase: ${weather['moon_phase']}
- Condition: ${weather['condition']}

USER DATA:
- Total trips: ${userData['total_trips']}
- Success rate: ${userData['success_rate']}
- Preferred types: ${userData['preferred_types']}
- Location familiarity: ${userData['location_familiarity']}

INTERNET DATA:
- Fish activity index: ${internetData['fishing_conditions']?['fish_activity_index'] ?? 0.5}
- Water temperature: ${internetData['fishing_conditions']?['water_temperature'] ?? 15}°C
- Recent reports sentiment: ${internetData['social_reports']?['sentiment_score'] ?? 0.5}
- Historical activity: ${internetData['historical_bite']?['historical_activity'] ?? 0.6}

Provide detailed predictions for each fishing type in JSON format:
{
  "spinning": {
    "score": 0-100,
    "activity_level": "excellent/good/moderate/poor/very_poor", 
    "confidence": 0.0-1.0,
    "recommendation": "brief recommendation",
    "detailed_analysis": "detailed analysis paragraph",
    "factors": [
      {
        "name": "factor name",
        "impact": -100 to +100,
        "description": "factor description"
      }
    ],
    "best_times": [
      {
        "start": "HH:MM",
        "end": "HH:MM", 
        "activity": 0.0-1.0,
        "reason": "why this time is good"
      }
    ],
    "tips": ["tip1", "tip2", "tip3"]
  },
  "feeder": { ... },
  "carp_fishing": { ... },
  "float_fishing": { ... },
  "ice_fishing": { ... },
  "fly_fishing": { ... },
  "trolling": { ... }
}

Consider:
1. Weather impact on each fishing type
2. User's experience and preferences  
3. Seasonal patterns and fish behavior
4. Internet data about local conditions
5. Time of day and lunar influence
6. Water conditions and fish activity
''';
  }

  // Вспомогательные методы...

  ActivityLevel _parseActivityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'excellent': return ActivityLevel.excellent;
      case 'good': return ActivityLevel.good;
      case 'moderate': return ActivityLevel.moderate;
      case 'poor': return ActivityLevel.poor;
      case 'very_poor': return ActivityLevel.veryPoor;
      default: return ActivityLevel.moderate;
    }
  }

  List<BiteFactorAnalysis> _parseFactors(List<dynamic> factors) {
    return factors.map((factor) => BiteFactorAnalysis(
      name: factor['name'] ?? 'Unknown Factor',
      value: '',
      impact: (factor['impact'] ?? 0).round(),
      weight: 1.0,
      description: factor['description'] ?? '',
      isPositive: (factor['impact'] ?? 0) > 0,
    )).toList();
  }

  List<OptimalTimeWindow> _parseTimeWindows(List<dynamic> times) {
    return times.map((time) {
      final start = DateTime.now().copyWith(
        hour: int.parse(time['start'].split(':')[0]),
        minute: int.parse(time['start'].split(':')[1]),
      );
      final end = DateTime.now().copyWith(
        hour: int.parse(time['end'].split(':')[0]),
        minute: int.parse(time['end'].split(':')[1]),
      );

      return OptimalTimeWindow(
        startTime: start,
        endTime: end,
        activity: (time['activity'] ?? 0.5).toDouble(),
        reason: time['reason'] ?? 'Оптимальное время',
        recommendations: ['Используйте активные приманки'],
      );
    }).toList();
  }

  // Методы кэширования...

  Future<Map<String, dynamic>?> _getCachedInternetData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_internetDataCacheKey}_$key');
      if (cached != null) {
        final data = json.decode(cached);
        final lastUpdated = DateTime.parse(data['last_updated']);
        if (DateTime.now().difference(lastUpdated).inHours < 1) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка чтения кэша: $e');
    }
    return null;
  }

  Future<void> _cacheInternetData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_internetDataCacheKey}_$key', json.encode(data));
    } catch (e) {
      debugPrint('❌ Ошибка сохранения кэша: $e');
    }
  }

  // Fallback методы...

  MultiFishingTypePrediction _getFallbackPrediction(
      WeatherApiResponse weather,
      List<FishingNoteModel>? userHistory,
      double latitude,
      double longitude,
      ) {
    // Возвращаем базовый прогноз при недоступности ИИ
    final fallbackPredictions = <String, AIBitePrediction>{};

    for (final type in ['spinning', 'feeder', 'carp_fishing', 'float_fishing']) {
      fallbackPredictions[type] = AIBitePrediction(
        overallScore: 50,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.3,
        recommendation: 'Базовые условия для рыбалки',
        detailedAnalysis: 'ИИ-анализ недоступен, используются базовые алгоритмы',
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
      generalRecommendations: ['ИИ-анализ недоступен'],
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
    return 'ai_real_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}';
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

  /// Обучение модели на основе фидбека
  void _scheduleModelTraining(Map<String, dynamic> input, MultiFishingTypePrediction prediction) {
    // TODO: Реализовать отправку данных для обучения модели
    // Отправляем данные о прогнозе для дальнейшего обучения
    debugPrint('📚 Планируем обучение модели на основе результата');
  }

  /// Очистка старого кэша
  void clearOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) =>
    now.difference(value.generatedAt).inHours > 6 // Кэш ИИ актуален 6 часов
    );
  }

  Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = _cache.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('❌ Ошибка сохранения кэша ИИ: $e');
    }
  }

  // Методы, которые нужно реализовать для полной функциональности...

  Map<String, dynamic> _getFallbackInternetData(double lat, double lon) {
    return {
      'fishing_conditions': {
        'water_temperature': 15.0,
        'fish_activity_index': 0.5,
        'source': 'fallback',
      },
      'historical_bite': {
        'historical_activity': 0.6,
        'source': 'fallback',
      },
      'social_reports': {
        'sentiment_score': 0.5,
        'source': 'fallback',
      },
    };
  }

  double _calculateDataQuality(List<Map<String, dynamic>> results) {
    double quality = 0.0;
    int validSources = 0;

    for (final result in results) {
      if (result['source'] != 'fallback') {
        validSources++;
        quality += 0.2;
      }
    }

    return quality.clamp(0.0, 1.0);
  }

  Map<String, dynamic> _getFallbackWeatherAnalysis(WeatherApiResponse weather) {
    return {
      'overall_fishing_suitability': 60,
      'pressure_impact': 'neutral',
      'temperature_impact': 'neutral',
      'wind_impact': 'neutral',
      'confidence': 0.3,
      'source': 'fallback',
    };
  }

  Map<String, dynamic> _parseUnstructuredAIResponse(String response) {
    return {
      'unstructured_response': response,
      'confidence': 0.5,
      'source': 'unstructured_ai',
    };
  }

  Map<String, AIBitePrediction> _getFallbackPredictions(Map<String, dynamic> input) {
    // Возвращаем базовые прогнозы
    final predictions = <String, AIBitePrediction>{};

    for (final type in input['available_fishing_types'] as List<String>) {
      predictions[type] = AIBitePrediction(
        overallScore: 50,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.3,
        recommendation: 'Стандартные условия',
        detailedAnalysis: 'Базовый анализ',
        factors: [],
        bestTimeWindows: [],
        tips: ['Удачной рыбалки!'],
        generatedAt: DateTime.now(),
        dataSource: 'fallback',
        modelVersion: '1.0.0',
      );
    }

    return predictions;
  }

  ComparisonAnalysis _createAIComparisonAnalysis(Map<String, AIBitePrediction> predictions) {
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

  List<String> _generateAIRecommendations(
      Map<String, AIBitePrediction> predictions,
      String bestType,
      Map<String, dynamic> internetData,
      ) {
    final recommendations = <String>[];
    final bestPrediction = predictions[bestType]!;

    recommendations.add('ИИ рекомендует: ${_getFishingTypeName(bestType)}');
    recommendations.add(bestPrediction.recommendation);

    // Добавляем рекомендации на основе интернет-данных
    final socialScore = internetData['social_reports']?['sentiment_score'] ?? 0.5;
    if (socialScore > 0.7) {
      recommendations.add('Недавние отчеты рыболовов очень позитивные!');
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

  Map<String, double> _analyzeFavoriteSeasons(List<FishingNoteModel> history) {
    final seasonCounts = <String, int>{};
    for (final trip in history) {
      final season = _getSeason(trip.startDate);
      seasonCounts[season] = (seasonCounts[season] ?? 0) + 1;
    }

    final total = history.length;
    return seasonCounts.map((season, count) => MapEntry(season, count / total));
  }

  List<int> _analyzeBestTimes(List<FishingNoteModel> successfulTrips) {
    final hourCounts = <int, int>{};
    for (final trip in successfulTrips) {
      hourCounts[trip.startDate.hour] = (hourCounts[trip.startDate.hour] ?? 0) + 1;
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