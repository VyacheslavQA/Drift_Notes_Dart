// Путь: lib/services/ai_bite_prediction_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_api_model.dart';
import '../models/ai_bite_prediction_model.dart';
import '../models/fishing_note_model.dart';
import '../config/api_keys.dart';
import '../services/weather/weather_service.dart';
import '../models/weather_api_model.dart';
import '../repositories/user_repository.dart';
import '../localization/app_localizations.dart';
import '../services/localization/ai_localization_service.dart';

class AIBitePredictionService {
  static final AIBitePredictionService _instance = AIBitePredictionService._internal();
  factory AIBitePredictionService() => _instance;
  AIBitePredictionService._internal();

  // Зависимости
  final _userRepository = UserRepository();
  final _localizationService = AILocalizationService();

  // Кэш для оптимизации
  final Map<String, MultiFishingTypePrediction> _cache = {};
  static const String _cacheKey = 'ai_bite_cache_multi';

  // Статус последнего AI запроса
  bool _lastAIRequestSuccessful = false;
  String _lastAIError = '';
  DateTime? _lastAIRequestTime;

  /// Геттеры для проверки статуса AI
  bool get isAIAvailable => _isOpenAIConfigured();
  bool get lastAIRequestSuccessful => _lastAIRequestSuccessful;
  String get lastAIError => _lastAIError;
  DateTime? get lastAIRequestTime => _lastAIRequestTime;

  /// Основной метод получения ИИ прогноза - ОБНОВЛЕН С ЛОКАЛИЗАЦИЕЙ
  Future<MultiFishingTypePrediction> getMultiFishingTypePrediction({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    List<FishingNoteModel>? userHistory,
    DateTime? targetDate,
    List<String>? preferredTypes,
    required AppLocalizations l10n,
  }) async {
    try {
      targetDate ??= DateTime.now();

      // Загружаем предпочтения пользователя из профиля
      final effectivePreferredTypes = await _getEffectivePreferredTypes(preferredTypes);

      if (kDebugMode) {
        debugPrint('🎯 ${l10n.translate("ai_analyzing_selected_types")}: $effectivePreferredTypes');
      }

      // Создаём уникальный ключ для кэширования с учетом предпочтений и языка
      final cacheKey = _generateCacheKey(latitude, longitude, targetDate, effectivePreferredTypes, l10n.languageCode);

      // Проверяем кэш (актуален 30 минут)
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().difference(cached.generatedAt).inMinutes < 30) {
          if (kDebugMode) {
            debugPrint('🤖 ${l10n.translate("ai_prediction_from_cache")} (${cached.bestPrediction.dataSource})');
          }
          return cached;
        }
      }

      if (kDebugMode) {
        debugPrint('🤖 ${l10n.translate("ai_generating_new_prediction")} ${effectivePreferredTypes.length} ${l10n.translate("ai_types")}...');
      }

      // Сначала определяем, доступен ли OpenAI
      final aiAvailable = _isOpenAIConfigured();
      if (kDebugMode) {
        debugPrint('🔧 OpenAI ${l10n.translate("ai_available")}: $aiAvailable');
      }

      // Собираем данные пользователя
      final userData = await _collectUserData(userHistory, latitude, longitude);

      // Анализируем погодные условия
      final weatherAnalysis = _analyzeWeatherConditions(weather, l10n);

      // Создаём базовые прогнозы ТОЛЬКО для выбранных типов рыбалки
      final predictions = _generatePredictionsForSelectedTypes(
        selectedTypes: effectivePreferredTypes,
        weather: weather,
        userData: userData,
        weatherAnalysis: weatherAnalysis,
        latitude: latitude,
        longitude: longitude,
        targetDate: targetDate,
        useAI: false,
        l10n: l10n,
      );

      // Пытаемся улучшить с помощью OpenAI
      bool aiEnhanced = false;
      if (aiAvailable) {
        aiEnhanced = await _enhanceWithOpenAI(predictions, weather, userData, effectivePreferredTypes, l10n);
      }

      // Обновляем dataSource на основе успешности AI улучшения
      final finalDataSource = aiEnhanced ? 'enhanced_ai' : 'local_algorithm';
      _updateDataSource(predictions, finalDataSource, l10n);

      // Создаем мультитиповый прогноз
      final multiPrediction = _createMultiPrediction(
        predictions,
        effectivePreferredTypes,
        weather,
        aiEnhanced,
        l10n,
      );

      // Сохраняем в кэш
      _cache[cacheKey] = multiPrediction;

      if (kDebugMode) {
        debugPrint('✅ ${l10n.translate("ai_prediction_ready")}. ${l10n.translate("ai_source")}: $finalDataSource. ${l10n.translate("ai_best")}: ${multiPrediction.bestFishingType}');
      }
      return multiPrediction;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${l10n.translate("ai_prediction_error")}: $e');
      }
      return _getFallbackPrediction(weather, userHistory, latitude, longitude, l10n);
    }
  }

  /// Получение эффективных предпочтений пользователя
  Future<List<String>> _getEffectivePreferredTypes(List<String>? providedTypes) async {
    // Если типы переданы напрямую - используем их
    if (providedTypes != null && providedTypes.isNotEmpty) {
      return providedTypes;
    }

    try {
      // Загружаем предпочтения из профиля пользователя
      final userData = await _userRepository.getCurrentUserData();
      if (userData?.fishingTypes?.isNotEmpty == true) {
        if (kDebugMode) {
          debugPrint('📋 Загружены предпочтения из профиля: ${userData!.fishingTypes}');
        }
        return userData!.fishingTypes!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка загрузки предпочтений пользователя: $e');
      }
    }

    // Fallback - базовые популярные типы
    final fallbackTypes = ['spinning', 'feeder', 'float_fishing'];
    if (kDebugMode) {
      debugPrint('🔄 Используем fallback типы: $fallbackTypes');
    }
    return fallbackTypes;
  }

  /// Получить прогноз для конкретного типа рыбалки (обертка для удобства)
  Future<AIBitePrediction> getPredictionForFishingType({
    required String fishingType,
    required double latitude,
    required double longitude,
    required AppLocalizations l10n,
    DateTime? date,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 ${l10n.translate("ai_getting_prediction_for")} $fishingType...');
      }

      // Создаем фиктивный объект погоды для тестирования
      final fakeWeather = WeatherApiResponse(
        location: Location(
          name: 'Test Location',
          region: '',
          country: '',
          lat: latitude,
          lon: longitude,
          tzId: '',
        ),
        current: Current(
          tempC: 15.0,
          feelslikeC: 15.0,
          humidity: 65,
          pressureMb: 1013.0,
          windKph: 10.0,
          windDir: 'N',
          condition: Condition(text: 'Clear', icon: '', code: 1000),
          cloud: 20,
          isDay: 1,
          visKm: 10.0,
          uv: 5.0,
        ),
        forecast: [],
      );

      // Используем существующий метод для получения мульти-прогноза
      final multiPrediction = await getMultiFishingTypePrediction(
        weather: fakeWeather,
        latitude: latitude,
        longitude: longitude,
        targetDate: date,
        preferredTypes: [fishingType],
        l10n: l10n,
      );

      // Возвращаем прогноз для конкретного типа
      final prediction = multiPrediction.allPredictions[fishingType];
      if (prediction == null) {
        throw Exception('${l10n.translate("ai_failed_to_get_prediction")}: $fishingType');
      }

      if (kDebugMode) {
        debugPrint('✅ Прогноз для $fishingType ${l10n.translate("ai_ready")}: ${prediction.overallScore} ${l10n.translate("ai_points")}');
      }
      return prediction;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${l10n.translate("ai_error_getting_prediction")} $fishingType: $e');
      }
      rethrow;
    }
  }

  /// Проверяем, настроен ли OpenAI API
  bool _isOpenAIConfigured() {
    try {
      final key = ApiKeys.openAIKey;
      final isConfigured = key.isNotEmpty &&
          key != 'YOUR_OPENAI_API_KEY_HERE' &&
          key.startsWith('sk-') &&
          key.length > 20;

      if (kDebugMode) {
        debugPrint('🔑 OpenAI ключ проверка: длина=${key.length}, начинается с sk-=${key.startsWith('sk-')}, настроен=$isConfigured');
      }
      return isConfigured;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки OpenAI ключа: $e');
      }
      return false;
    }
  }

  /// Базовый OpenAI запрос с поддержкой локализации - ПОЛНОСТЬЮ ПЕРЕРАБОТАН
  Future<Map<String, dynamic>?> _makeOpenAIRequest(
      List<Map<String, String>> messages,
      AppLocalizations l10n,
      ) async {
    if (!_isOpenAIConfigured()) {
      if (kDebugMode) {
        debugPrint('🚫 OpenAI ${l10n.translate("ai_not_configured")}');
      }
      return null;
    }

    _lastAIRequestTime = DateTime.now();

    try {
      // Получаем системное сообщение на нужном языке
      final systemMessage = _localizationService.getSystemMessage(l10n);

      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemMessage,
          },
          ...messages,
        ],
        'max_tokens': 400,
        'temperature': 0.7,
      };

      final response = await http
          .post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        final finishReason = data['choices']?[0]?['finish_reason'];
        if (kDebugMode && finishReason == 'length') {
          debugPrint('⚠️ ${l10n.translate("ai_response_truncated")}');
        }

        // Валидация языка ответа
        final aiResponse = data['choices']?[0]?['message']?['content'] as String?;
        if (kDebugMode && aiResponse != null && !_localizationService.validateResponseLanguage(aiResponse, l10n)) {
          debugPrint('⚠️ ${l10n.translate("ai_response_wrong_language")}');
        }

        _lastAIRequestSuccessful = true;
        _lastAIError = '';

        if (kDebugMode) {
          debugPrint('✅ OpenAI ${l10n.translate("ai_response_received")} (finish_reason: $finishReason)');
        }
        return data;
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        _lastAIRequestSuccessful = false;
        _lastAIError = 'HTTP ${response.statusCode}: ${errorData['error']?['message'] ?? l10n.translate("ai_unknown_error")}';

        if (kDebugMode) {
          debugPrint('❌ OpenAI ${l10n.translate("ai_error")}: $_lastAIError');
        }
        return null;
      }
    } catch (e) {
      _lastAIRequestSuccessful = false;
      _lastAIError = e.toString();
      if (kDebugMode) {
        debugPrint('❌ OpenAI ${l10n.translate("ai_exception")}: $e');
      }
      return null;
    }
  }

  /// Получает ИИ-рекомендации для ветра с локализацией
  Future<List<String>> getWindFishingRecommendations(String prompt, AppLocalizations l10n) async {
    try {
      // Создаем локализованный промпт
      final localizedPrompt = _localizationService.createWindRecommendationPrompt(prompt, l10n);

      final response = await _makeOpenAIRequest([
        {'role': 'user', 'content': localizedPrompt},
      ], l10n);

      if (response != null &&
          response['choices'] != null &&
          response['choices'].isNotEmpty) {
        final content = response['choices'][0]['message']['content'] as String?;

        if (content != null && content.isNotEmpty) {
          final recommendations = _localizationService.parseAIRecommendations(content);

          if (kDebugMode) {
            debugPrint('✅ ${l10n.translate("ai_received_recommendations")}: ${recommendations.length}');
          }
          return recommendations.isNotEmpty
              ? recommendations
              : [l10n.translate("ai_recommendations_received")];
        }
      }

      return [l10n.translate("ai_failed_recommendations")];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ${l10n.translate("ai_wind_recommendations_error")}: $e');
      }
      return ['${l10n.translate("ai_wind_recommendations_error")}: $e'];
    }
  }

  /// Тестовый метод для проверки OpenAI API с локализацией
  Future<Map<String, dynamic>> testOpenAIConnection(AppLocalizations l10n) async {
    _lastAIRequestTime = DateTime.now();

    if (!_isOpenAIConfigured()) {
      _lastAIRequestSuccessful = false;
      _lastAIError = l10n.translate("ai_openai_not_configured");
      return {
        'success': false,
        'error': l10n.translate("ai_api_key_wrong_format"),
        'configured': false,
      };
    }

    try {
      if (kDebugMode) {
        debugPrint('🧪 ${l10n.translate("ai_testing_connection")}...');
      }

      final testPrompt = _localizationService.createTestPrompt(l10n);

      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': testPrompt,
          },
        ],
        'max_tokens': 20,
        'temperature': 0.1,
      };

      if (kDebugMode) {
        debugPrint('🔍 Request body: ${json.encode(requestBody)}');
      }

      final response = await http
          .post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('🌐 ${l10n.translate("ai_openai_response")}: ${l10n.translate("ai_status")} ${response.statusCode}');
        debugPrint('🔍 Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        if (kDebugMode) {
          debugPrint('🔍 Decoded response body: $decodedBody');
        }

        final data = json.decode(decodedBody);
        final answer = data['choices'][0]['message']['content'].toString().trim();
        final finishReason = data['choices'][0]['finish_reason'];

        if (kDebugMode) {
          debugPrint('🔍 Final answer: $answer');
          debugPrint('🔍 Finish reason: $finishReason');
        }

        _lastAIRequestSuccessful = true;
        _lastAIError = '';

        return {
          'success': true,
          'status': response.statusCode,
          'model': data['model'] ?? 'unknown',
          'response': answer,
          'finish_reason': finishReason,
          'configured': true,
          'response_time': DateTime.now().difference(_lastAIRequestTime!).inMilliseconds,
        };
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        _lastAIRequestSuccessful = false;
        _lastAIError = 'HTTP ${response.statusCode}: ${errorData['error']?['message'] ?? l10n.translate("ai_unknown_error")}';

        return {
          'success': false,
          'status': response.statusCode,
          'error': _lastAIError,
          'configured': true,
        };
      }
    } catch (e) {
      _lastAIRequestSuccessful = false;
      _lastAIError = e.toString();

      if (kDebugMode) {
        debugPrint('❌ OpenAI ${l10n.translate("ai_test_error")}: $e');
      }
      return {'success': false, 'error': e.toString(), 'configured': true};
    }
  }

  /// Сбор данных пользователя для анализа
  Future<Map<String, dynamic>> _collectUserData(
      List<FishingNoteModel>? userHistory,
      double latitude,
      double longitude,
      ) async {
    if (kDebugMode) {
      debugPrint('📊 Собираем данные пользователя...');
    }

    try {
      // Загружаем профиль пользователя
      final userData = await _userRepository.getCurrentUserData();

      if (userHistory == null || userHistory.isEmpty) {
        // Возвращаем данные из профиля даже если нет истории рыбалок
        return {
          'has_data': userData != null,
          'total_trips': 0,
          'success_rate': 0.0,
          'preferred_types': userData?.fishingTypes ?? <String>[],
          'experience_level': userData?.experience ?? 'beginner',
          'user_location': {
            'country': userData?.country ?? '',
            'city': userData?.city ?? '',
          },
          'successful_conditions': <Map<String, dynamic>>[],
          'location_familiarity': 0.0,
        };
      }

      // Анализируем историю пользователя
      final successfulTrips = userHistory
          .where((note) => note.biteRecords.isNotEmpty && note.biteRecords.any((bite) => bite.weight > 0))
          .toList();

      // Найдем поездки рядом с текущим местоположением
      final locationTrips = userHistory.where((note) {
        return _calculateDistance(note.latitude, note.longitude, latitude, longitude) < 50; // В радиусе 50 км
      }).toList();

      // Анализ успешных условий
      final successfulConditions = <Map<String, dynamic>>[];
      for (final trip in successfulTrips) {
        successfulConditions.add({
          'fishing_type': trip.fishingType,
          'time_of_day': trip.date.hour,
          'season': _getSeason(trip.date),
          'catch_weight': trip.biteRecords.fold(0.0, (sum, bite) => sum + bite.weight),
          'bite_count': trip.biteRecords.length,
          'duration_hours': trip.endDate?.difference(trip.date).inHours ?? 8,
        });
      }

      // Предпочитаемые типы рыбалки из истории
      final typeFrequency = <String, int>{};
      for (final trip in userHistory) {
        typeFrequency[trip.fishingType] = (typeFrequency[trip.fishingType] ?? 0) + 1;
      }

      final preferredTypesFromHistory = typeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Объединяем предпочтения из профиля и истории
      final combinedPreferredTypes = <String>[];
      if (userData?.fishingTypes?.isNotEmpty == true) {
        combinedPreferredTypes.addAll(userData!.fishingTypes!);
      }
      // Добавляем из истории, если их нет в профиле
      for (final historyType in preferredTypesFromHistory.take(3).map((e) => e.key)) {
        if (!combinedPreferredTypes.contains(historyType)) {
          combinedPreferredTypes.add(historyType);
        }
      }

      return {
        'has_data': true,
        'total_trips': userHistory.length,
        'successful_trips': successfulTrips.length,
        'success_rate': successfulTrips.length / userHistory.length,
        'preferred_types': combinedPreferredTypes,
        'experience_level': userData?.experience ?? 'beginner',
        'user_location': {
          'country': userData?.country ?? '',
          'city': userData?.city ?? '',
        },
        'successful_conditions': successfulConditions,
        'location_familiarity': locationTrips.length / userHistory.length,
        'avg_trip_duration': userHistory
            .map((trip) => trip.endDate?.difference(trip.date).inHours ?? 0)
            .where((duration) => duration > 0)
            .fold(0.0, (sum, duration) => sum + duration) / userHistory.length,
        'favorite_seasons': _analyzeFavoriteSeasons(userHistory),
        'best_times': _analyzeBestTimes(successfulTrips),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сбора данных пользователя: $e');
      }
      return {
        'has_data': false,
        'total_trips': 0,
        'success_rate': 0.0,
        'preferred_types': <String>[],
        'experience_level': 'beginner',
        'successful_conditions': <Map<String, dynamic>>[],
        'location_familiarity': 0.0,
      };
    }
  }

  /// Анализ погодных условий с локализацией
  Map<String, dynamic> _analyzeWeatherConditions(WeatherApiResponse weather, AppLocalizations l10n) {
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

  /// Генерация прогнозов только для выбранных типов с локализацией
  Map<String, AIBitePrediction> _generatePredictionsForSelectedTypes({
    required List<String> selectedTypes,
    required WeatherApiResponse weather,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> weatherAnalysis,
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    required bool useAI,
    required AppLocalizations l10n,
  }) {
    final predictions = <String, AIBitePrediction>{};
    final current = weather.current;

    // Конфигурация типов рыбалки
    final fishingTypes = {
      'spinning': {
        'name': l10n.translate('ai_spinning'),
        'wind_tolerance': 25.0,
        'temp_optimal_min': 8.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.8,
        'season_bonus': _getSeasonBonus('spinning', _getSeason(targetDate)),
        'base_score': 45.0,
      },
      'feeder': {
        'name': l10n.translate('ai_feeder'),
        'wind_tolerance': 20.0,
        'temp_optimal_min': 12.0,
        'temp_optimal_max': 28.0,
        'pressure_sensitivity': 0.9,
        'season_bonus': _getSeasonBonus('feeder', _getSeason(targetDate)),
        'base_score': 50.0,
      },
      'carp_fishing': {
        'name': l10n.translate('ai_carp_fishing'),
        'wind_tolerance': 15.0,
        'temp_optimal_min': 15.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 1.0,
        'season_bonus': _getSeasonBonus('carp_fishing', _getSeason(targetDate)),
        'base_score': 40.0,
      },
      'float_fishing': {
        'name': l10n.translate('ai_float_fishing'),
        'wind_tolerance': 10.0,
        'temp_optimal_min': 8.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.7,
        'season_bonus': _getSeasonBonus('float_fishing', _getSeason(targetDate)),
        'base_score': 55.0,
      },
      'ice_fishing': {
        'name': l10n.translate('ai_ice_fishing'),
        'wind_tolerance': 30.0,
        'temp_optimal_min': -15.0,
        'temp_optimal_max': 5.0,
        'pressure_sensitivity': 1.2,
        'season_bonus': _getSeasonBonus('ice_fishing', _getSeason(targetDate)),
        'base_score': current.tempC <= 0 ? 60.0 : 10.0,
      },
      'fly_fishing': {
        'name': l10n.translate('ai_fly_fishing'),
        'wind_tolerance': 8.0,
        'temp_optimal_min': 10.0,
        'temp_optimal_max': 22.0,
        'pressure_sensitivity': 0.6,
        'season_bonus': _getSeasonBonus('fly_fishing', _getSeason(targetDate)),
        'base_score': 35.0,
      },
      'trolling': {
        'name': l10n.translate('ai_trolling'),
        'wind_tolerance': 35.0,
        'temp_optimal_min': 5.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 0.5,
        'season_bonus': _getSeasonBonus('trolling', _getSeason(targetDate)),
        'base_score': 42.0,
      },
    };

    if (kDebugMode) {
      debugPrint('🎣 ${l10n.translate("ai_generating_predictions")} ${selectedTypes.length} ${l10n.translate("ai_selected_types")}: $selectedTypes');
    }

    // Генерируем прогнозы ТОЛЬКО для выбранных типов
    for (final type in selectedTypes) {
      final config = fishingTypes[type];
      if (config != null) {
        predictions[type] = _generatePredictionForType(
          type,
          config,
          weather,
          userData,
          weatherAnalysis,
          useAI,
          l10n,
        );

        if (kDebugMode) {
          debugPrint('📊 $type: ${predictions[type]!.overallScore} ${l10n.translate("ai_points")}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ ${l10n.translate("ai_unknown_fishing_type")}: $type');
        }
      }
    }

    return predictions;
  }

  /// Получаем сезонный бонус для типа рыбалки
  double _getSeasonBonus(String fishingType, String season) {
    const seasonBonuses = {
      'spinning': {'spring': 15.0, 'summer': 10.0, 'autumn': 20.0, 'winter': -10.0},
      'feeder': {'spring': 10.0, 'summer': 15.0, 'autumn': 10.0, 'winter': -15.0},
      'carp_fishing': {'spring': 5.0, 'summer': 20.0, 'autumn': 10.0, 'winter': -25.0},
      'float_fishing': {'spring': 20.0, 'summer': 15.0, 'autumn': 10.0, 'winter': -5.0},
      'ice_fishing': {'spring': -30.0, 'summer': -40.0, 'autumn': -20.0, 'winter': 30.0},
      'fly_fishing': {'spring': 20.0, 'summer': 10.0, 'autumn': 15.0, 'winter': -20.0},
      'trolling': {'spring': 10.0, 'summer': 15.0, 'autumn': 5.0, 'winter': -10.0},
    };

    return seasonBonuses[fishingType]?[season] ?? 0.0;
  }

  /// Генерация прогноза для конкретного типа рыбалки с локализацией
  AIBitePrediction _generatePredictionForType(
      String fishingType,
      Map<String, dynamic> config,
      WeatherApiResponse weather,
      Map<String, dynamic> userData,
      Map<String, dynamic> weatherAnalysis,
      bool useAI,
      AppLocalizations l10n,
      ) {
    // Начинаем с базового скора для типа
    double score = config['base_score'] as double;
    final factors = <BiteFactorAnalysis>[];
    final tips = <String>[];

    if (kDebugMode) {
      debugPrint('🎯 ${l10n.translate("ai_analyzing")} $fishingType, ${l10n.translate("ai_base_score")}: $score');
    }

    // Учитываем уровень опыта пользователя
    final experienceLevel = userData['experience_level'] as String?;
    if (experienceLevel != null) {
      double experienceBonus = 0.0;
      String experienceTip = '';

      switch (experienceLevel) {
        case 'expert':
          experienceBonus = 8.0;
          experienceTip = l10n.translate('ai_expert_tip');
          break;
        case 'intermediate':
          experienceBonus = 4.0;
          experienceTip = l10n.translate('ai_intermediate_tip');
          break;
        case 'beginner':
          experienceBonus = -2.0;
          experienceTip = l10n.translate('ai_beginner_tip');
          break;
      }

      if (experienceBonus != 0) {
        score += experienceBonus;
        factors.add(
          BiteFactorAnalysis(
            name: l10n.translate('ai_experience_level'),
            value: _localizationService.getExperienceLevelName(experienceLevel, l10n),
            impact: experienceBonus.round(),
            weight: 0.6,
            description: l10n.translate('ai_personal_experience'),
            isPositive: experienceBonus > 0,
          ),
        );
        tips.add(experienceTip);
      }
    }

    // Применяем сезонный бонус
    final seasonBonus = config['season_bonus'] as double;
    score += seasonBonus;
    if (seasonBonus != 0) {
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_season'),
          value: _localizationService.getSeasonName(_getSeason(DateTime.now()), l10n),
          impact: seasonBonus.round(),
          weight: 0.9,
          description: seasonBonus > 0
              ? '${l10n.translate("ai_favorable_season")} ${config['name']}'
              : l10n.translate('ai_unfavorable_season'),
          isPositive: seasonBonus > 0,
        ),
      );
    }

    // Анализ ветра с конкретными штрафами
    final windKph = weather.current.windKph;
    final windTolerance = config['wind_tolerance'] as double;
    if (windKph <= windTolerance) {
      final windBonus = windKph <= windTolerance * 0.5 ? 15.0 : 10.0;
      score += windBonus;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_wind'),
          value: '${windKph.round()} ${l10n.translate("kilometers")}/ч',
          impact: windBonus.round(),
          weight: 0.8,
          description: '${l10n.translate("ai_suitable_wind")} ${config['name']}',
          isPositive: true,
        ),
      );
    } else {
      final excess = windKph - windTolerance;
      final windPenalty = -math.min(excess * 2, 30.0);
      score += windPenalty;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_wind'),
          value: '${windKph.round()} ${l10n.translate("kilometers")}/ч',
          impact: windPenalty.round(),
          weight: 0.8,
          description: '${l10n.translate("ai_strong_wind")} ${config['name']}',
          isPositive: false,
        ),
      );
      tips.add(l10n.translate('ai_strong_wind_tip'));
    }

    // Анализ температуры с четкими границами
    final temp = weather.current.tempC;
    final tempMin = config['temp_optimal_min'] as double;
    final tempMax = config['temp_optimal_max'] as double;

    if (temp >= tempMin && temp <= tempMax) {
      final tempBonus = 15.0;
      score += tempBonus;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_temperature'),
          value: '${temp.round()}°C',
          impact: tempBonus.round(),
          weight: 0.7,
          description: '${l10n.translate("ai_optimal_temperature")} ${config['name']}',
          isPositive: true,
        ),
      );
    } else {
      double tempPenalty;
      if (temp < tempMin) {
        tempPenalty = -math.min((tempMin - temp) * 3, 25.0);
      } else {
        tempPenalty = -math.min((temp - tempMax) * 2, 20.0);
      }
      score += tempPenalty;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_temperature'),
          value: '${temp.round()}°C',
          impact: tempPenalty.round(),
          weight: 0.7,
          description: temp < tempMin
              ? '${l10n.translate("ai_too_cold")} ${config['name']}'
              : l10n.translate('ai_too_hot'),
          isPositive: false,
        ),
      );

      if (temp < tempMin) {
        tips.add(l10n.translate('ai_cold_tip'));
      } else {
        tips.add(l10n.translate('ai_hot_tip'));
      }
    }

    // Анализ давления
    final pressure = weather.current.pressureMb;
    final pressureSensitivity = config['pressure_sensitivity'] as double;
    if (pressure >= 1010 && pressure <= 1025) {
      final pressureBonus = 12 * pressureSensitivity;
      score += pressureBonus;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_pressure'),
          value: '${pressure.round()} мб',
          impact: pressureBonus.round(),
          weight: pressureSensitivity,
          description: l10n.translate('ai_stable_pressure'),
          isPositive: true,
        ),
      );
    } else {
      final pressurePenalty = pressure < 1000 ? -18 * pressureSensitivity : -12 * pressureSensitivity;
      score += pressurePenalty;
      factors.add(
        BiteFactorAnalysis(
          name: l10n.translate('ai_pressure'),
          value: '${pressure.round()} мб',
          impact: pressurePenalty.round(),
          weight: pressureSensitivity,
          description: pressure < 1000
              ? l10n.translate('ai_low_pressure')
              : l10n.translate('ai_high_pressure'),
          isPositive: false,
        ),
      );
      tips.add(l10n.translate('ai_pressure_tip'));
    }

    // Учет пользовательских данных
    if (userData['has_data'] == true) {
      final preferredTypes = userData['preferred_types'] as List<dynamic>;
      if (preferredTypes.contains(fishingType)) {
        score += 8;
        factors.add(
          BiteFactorAnalysis(
            name: l10n.translate('ai_personal_history'),
            value: l10n.translate('ai_preferred_type'),
            impact: 8,
            weight: 0.6,
            description: l10n.translate('ai_often_use_type'),
            isPositive: true,
          ),
        );
      }
    }

    // Специальные условия для зимней рыбалки
    if (fishingType == 'ice_fishing') {
      if (temp > 5) {
        score = math.min(score, 15.0);
        tips.add(l10n.translate('ai_ice_impossible_warm'));
      }
    }

    // Генерируем временные окна
    final timeWindows = _generateTimeWindows(weather, fishingType, l10n);

    // Генерируем дополнительные советы
    tips.addAll(_generateTipsForType(fishingType, weather, l10n));

    // Ограничиваем скор
    score = score.clamp(0.0, 100.0);

    // Определяем уровень активности
    final activityLevel = _determineActivityLevel(score);

    // Генерируем рекомендацию
    final recommendation = _generateRecommendation(fishingType, score, factors, l10n);

    if (kDebugMode) {
      debugPrint('✅ $fishingType: ${l10n.translate("ai_final_score")} $score');
    }

    return AIBitePrediction(
      overallScore: score.round(),
      activityLevel: activityLevel,
      confidence: useAI ? 0.9 : 0.8,
      recommendation: recommendation,
      detailedAnalysis: _generateDetailedAnalysis(fishingType, factors, weather, l10n),
      factors: factors,
      bestTimeWindows: timeWindows,
      tips: tips,
      generatedAt: DateTime.now(),
      dataSource: useAI ? 'enhanced_ai' : 'local_algorithm',
      modelVersion: useAI ? '2.1.0-ai' : '2.0.0-local',
    );
  }

  /// Улучшение прогноза с помощью OpenAI с локализацией
  Future<bool> _enhanceWithOpenAI(
      Map<String, AIBitePrediction> predictions,
      WeatherApiResponse weather,
      Map<String, dynamic> userData,
      List<String> selectedTypes,
      AppLocalizations l10n,
      ) async {
    if (!_isOpenAIConfigured()) {
      if (kDebugMode) {
        debugPrint('🚫 OpenAI ${l10n.translate("ai_not_configured")}, ${l10n.translate("ai_skipping_enhancement")}');
      }
      return false;
    }

    _lastAIRequestTime = DateTime.now();

    try {
      if (kDebugMode) {
        debugPrint('🧠 ${l10n.translate("ai_enhancing_prediction")} ${l10n.translate("ai_for_types")}: $selectedTypes');
      }

      // Создаем специализированные промпты для каждого выбранного типа
      bool anySuccess = false;

      for (final fishingType in selectedTypes) {
        final prediction = predictions[fishingType];
        if (prediction == null) continue;

        final prompt = _buildSpecializedPrompt(fishingType, prediction, weather, userData, l10n);

        final response = await _makeOpenAIRequest([
          {'role': 'user', 'content': prompt},
        ], l10n);

        if (response != null &&
            response['choices'] != null &&
            response['choices'].isNotEmpty) {
          final aiResponse = response['choices'][0]['message']['content'] as String;

          // Обрабатываем ответ AI для конкретного типа
          _processSpecializedAIResponse(prediction, aiResponse, fishingType, l10n);
          anySuccess = true;
        }
      }

      if (anySuccess) {
        _lastAIRequestSuccessful = true;
        _lastAIError = '';
        if (kDebugMode) {
          debugPrint('✅ OpenAI ${l10n.translate("ai_enhancement_applied")} ${selectedTypes.length} ${l10n.translate("ai_types")}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ OpenAI ${l10n.translate("ai_could_not_enhance")}');
        }
        return false;
      }
    } catch (e) {
      _lastAIRequestSuccessful = false;
      _lastAIError = e.toString();
      if (kDebugMode) {
        debugPrint('❌ OpenAI ${l10n.translate("ai_exception")}: $e');
      }
      return false;
    }
  }

  /// Создание специализированного промпта для типа рыбалки с локализацией
  String _buildSpecializedPrompt(
      String fishingType,
      AIBitePrediction prediction,
      WeatherApiResponse weather,
      Map<String, dynamic> userData,
      AppLocalizations l10n,
      ) {
    final typeName = _localizationService.getFishingTypeName(fishingType, l10n);
    final experienceLevel = userData['experience_level'] as String? ?? 'beginner';
    final hasHistory = userData['has_data'] as bool? ?? false;

    return _localizationService.createSpecializedPrompt(
      typeName: typeName,
      temperature: weather.current.tempC,
      pressure: weather.current.pressureMb,
      windSpeed: weather.current.windKph,
      currentScore: prediction.overallScore,
      experienceLevel: experienceLevel,
      hasHistory: hasHistory,
      currentHour: DateTime.now().hour,
      l10n: l10n,
    );
  }

  /// Обработка специализированного ответа ИИ с локализацией
  void _processSpecializedAIResponse(
      AIBitePrediction prediction,
      String aiResponse,
      String fishingType,
      AppLocalizations l10n,
      ) {
    try {
      if (kDebugMode) {
        debugPrint('🔍 ${l10n.translate("ai_processing_response")} $fishingType: $aiResponse');
      }

      final cleanResponse = aiResponse.trim();

      if (cleanResponse.isNotEmpty && cleanResponse.length > 10) {
        final tips = _localizationService.parseSpecializedAIResponse(cleanResponse, l10n);

        // Добавляем каждый совет с соответствующими иконками
        for (int i = 0; i < tips.length; i++) {
          prediction.tips.insert(i, tips[i]);
        }

        if (kDebugMode) {
          debugPrint('✨ ${l10n.translate("ai_added_tips")} $fishingType: ${tips.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ${l10n.translate("ai_processing_error")} $fishingType: $e');
      }
      // Добавляем базовый совет при ошибке
      prediction.tips.insert(0, l10n.translate('ai_enhanced_by_ai'));
    }
  }

  /// Обновление источника данных для всех прогнозов с локализацией
  void _updateDataSource(
      Map<String, AIBitePrediction> predictions,
      String dataSource,
      AppLocalizations l10n,
      ) {
    for (final prediction in predictions.values) {
      if (dataSource == 'enhanced_ai') {
        // Проверяем, есть ли уже ИИ-советы
        final hasAITips = prediction.tips.any((tip) =>
        tip.contains('🧠') || tip.contains('🎯') ||
            tip.contains('⚡') || tip.contains('📍'));

        if (!hasAITips) {
          prediction.tips.insert(0, l10n.translate('ai_enhanced_by_ai'));
        }
      }
    }
  }

  /// Создание мультитипового прогноза с локализацией
  MultiFishingTypePrediction _createMultiPrediction(
      Map<String, AIBitePrediction> predictions,
      List<String> preferredTypes,
      WeatherApiResponse weather,
      bool aiEnhanced,
      AppLocalizations l10n,
      ) {
    // Сортируем только выбранные типы по скору
    final sortedPredictions = predictions.entries.toList()
      ..sort((a, b) => b.value.overallScore.compareTo(a.value.overallScore));

    // Лучший тип из выбранных
    String bestType = sortedPredictions.first.key;

    if (kDebugMode) {
      debugPrint('🎯 ${l10n.translate("ai_selected_types")}: $preferredTypes');
      debugPrint('🏆 ${l10n.translate("ai_best_from_selected")}: $bestType');
    }

    // Создаем сравнительный анализ только для выбранных типов
    final comparison = _createComparisonAnalysis(predictions, l10n);

    // Генерируем общие рекомендации
    final generalRecommendations = _generateGeneralRecommendations(
      predictions,
      bestType,
      aiEnhanced,
      l10n,
    );

    if (kDebugMode) {
      debugPrint('🏆 ${l10n.translate("ai_best_fishing_type")}: $bestType (${predictions[bestType]!.overallScore} ${l10n.translate("ai_points")})');
    }

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

  // Остальные методы с локализацией...

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

  List<OptimalTimeWindow> _generateTimeWindows(
      WeatherApiResponse weather,
      String fishingType,
      AppLocalizations l10n,
      ) {
    final now = DateTime.now();
    final windows = <OptimalTimeWindow>[];

    // Утреннее окно
    windows.add(
      OptimalTimeWindow(
        startTime: now.copyWith(hour: 6, minute: 0),
        endTime: now.copyWith(hour: 8, minute: 30),
        activity: 0.85,
        reason: l10n.translate('ai_morning_activity'),
        recommendations: [l10n.translate('ai_use_active_lures')],
      ),
    );

    // Вечернее окно
    windows.add(
      OptimalTimeWindow(
        startTime: now.copyWith(hour: 18, minute: 0),
        endTime: now.copyWith(hour: 20, minute: 30),
        activity: 0.9,
        reason: l10n.translate('ai_evening_activity'),
        recommendations: [l10n.translate('ai_try_surface_lures')],
      ),
    );

    return windows;
  }

  List<String> _generateTipsForType(
      String fishingType,
      WeatherApiResponse weather,
      AppLocalizations l10n,
      ) {
    final tips = <String>[];

    switch (fishingType) {
      case 'spinning':
        tips.add(l10n.translate('ai_bright_lures_cloudy'));
        if (weather.current.windKph > 20) {
          tips.add(l10n.translate('ai_heavier_lures_wind'));
        }
        break;
      case 'feeder':
        tips.add(l10n.translate('ai_check_feeder'));
        tips.add(l10n.translate('ai_aromatized_bait'));
        break;
      case 'carp_fishing':
        tips.add(l10n.translate('ai_boilies_pva'));
        tips.add(l10n.translate('ai_quiet_places'));
        break;
      case 'float_fishing':
        tips.add(l10n.translate('ai_watch_float'));
        if (weather.current.windKph < 10) {
          tips.add(l10n.translate('ai_accurate_retrieve'));
        }
        break;
      case 'ice_fishing':
        tips.add(l10n.translate('ai_mormyshka_spoons'));
        tips.add(l10n.translate('ai_drill_holes'));
        break;
      case 'fly_fishing':
        tips.add(l10n.translate('ai_wind_direction'));
        tips.add(l10n.translate('ai_dry_flies'));
        break;
      case 'trolling':
        tips.add(l10n.translate('ai_boat_speed'));
        tips.add(l10n.translate('ai_wobblers_sizes'));
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

  String _generateRecommendation(
      String fishingType,
      double score,
      List<BiteFactorAnalysis> factors,
      AppLocalizations l10n,
      ) {
    final typeName = _localizationService.getFishingTypeName(fishingType, l10n);

    if (score >= 80) {
      return l10n.translate('ai_excellent_conditions').replaceAll('{type}', typeName);
    } else if (score >= 60) {
      return l10n.translate('ai_good_conditions').replaceAll('{type}', typeName);
    } else if (score >= 40) {
      return l10n.translate('ai_average_conditions').replaceAll('{type}', typeName);
    } else {
      return l10n.translate('ai_difficult_conditions');
    }
  }

  String _generateDetailedAnalysis(
      String fishingType,
      List<BiteFactorAnalysis> factors,
      WeatherApiResponse weather,
      AppLocalizations l10n,
      ) {
    final analysis = StringBuffer();
    final typeName = _localizationService.getFishingTypeName(fishingType, l10n);
    analysis.write(l10n.translate('ai_conditions_analysis').replaceAll('{type}', typeName));

    final positiveFactors = factors.where((f) => f.isPositive).length;
    final negativeFactors = factors.where((f) => !f.isPositive).length;

    if (positiveFactors > negativeFactors) {
      analysis.write(l10n.translate('ai_favorable_factors'));
    } else if (negativeFactors > positiveFactors) {
      analysis.write(l10n.translate('ai_unfavorable_factors'));
    } else {
      analysis.write(l10n.translate('ai_mixed_conditions'));
    }

    final weatherDetails = l10n.translate('ai_weather_details')
        .replaceAll('{temp}', weather.current.tempC.round().toString())
        .replaceAll('{pressure}', weather.current.pressureMb.round().toString())
        .replaceAll('{wind}', weather.current.windKph.round().toString());

    analysis.write(weatherDetails);

    return analysis.toString();
  }

  ComparisonAnalysis _createComparisonAnalysis(
      Map<String, AIBitePrediction> predictions,
      AppLocalizations l10n,
      ) {
    final rankings = predictions.entries
        .map((e) => FishingTypeRanking(
      fishingType: e.key,
      typeName: _localizationService.getFishingTypeName(e.key, l10n),
      icon: _getFishingTypeIcon(e.key),
      score: e.value.overallScore,
      activityLevel: e.value.activityLevel,
      shortRecommendation: e.value.recommendation,
      keyFactors: e.value.factors.take(3).map((f) => f.name).toList(),
    ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return ComparisonAnalysis(
      rankings: rankings,
      bestOverall: rankings.first,
      alternativeOptions: rankings.skip(1).take(2).toList(),
      worstOptions: rankings.where((r) => r.score < 30).toList(),
    );
  }

  List<String> _generateGeneralRecommendations(
      Map<String, AIBitePrediction> predictions,
      String bestType,
      bool aiEnhanced,
      AppLocalizations l10n,
      ) {
    final recommendations = <String>[];
    final bestPrediction = predictions[bestType]!;

    if (aiEnhanced) {
      recommendations.add(l10n.translate('ai_enhanced_by_ai'));
    } else {
      recommendations.add(l10n.translate('ai_basic_analysis'));
    }

    final typeName = _localizationService.getFishingTypeName(bestType, l10n);
    recommendations.add(l10n.translate('ai_recommended_type').replaceAll('{type}', typeName));
    recommendations.add(bestPrediction.recommendation);

    if (bestPrediction.overallScore >= 80) {
      recommendations.add(l10n.translate('ai_dont_miss'));
    } else if (bestPrediction.overallScore < 40) {
      recommendations.add(l10n.translate('ai_consider_postponing'));
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

  /// Fallback прогноз при ошибках с локализацией
  Future<MultiFishingTypePrediction> _getFallbackPrediction(
      WeatherApiResponse weather,
      List<FishingNoteModel>? userHistory,
      double latitude,
      double longitude,
      AppLocalizations l10n,
      ) async {
    // Получаем предпочтения для fallback
    final preferredTypes = await _getEffectivePreferredTypes(null);
    final fallbackPredictions = <String, AIBitePrediction>{};

    final fallbackScores = {
      'spinning': 55,
      'feeder': 50,
      'carp_fishing': 45,
      'float_fishing': 60,
      'ice_fishing': weather.current.tempC <= 0 ? 40 : 5,
      'fly_fishing': 35,
      'trolling': 42,
    };

    // Создаем fallback только для предпочитаемых типов
    for (final type in preferredTypes) {
      final score = fallbackScores[type] ?? 40;
      final typeName = _localizationService.getFishingTypeName(type, l10n);

      fallbackPredictions[type] = AIBitePrediction(
        overallScore: score,
        activityLevel: _determineActivityLevel(score.toDouble()),
        confidence: 0.3,
        recommendation: l10n.translate('ai_basic_conditions').replaceAll('{type}', typeName),
        detailedAnalysis: l10n.translate('ai_basic_algorithms'),
        factors: [],
        bestTimeWindows: [],
        tips: [l10n.translate('ai_morning_evening')],
        generatedAt: DateTime.now(),
        dataSource: 'fallback_algorithm',
        modelVersion: '1.0.0-fallback',
      );
    }

    final bestType = preferredTypes.isNotEmpty ? preferredTypes.first : 'spinning';

    return MultiFishingTypePrediction(
      bestFishingType: bestType,
      bestPrediction: fallbackPredictions[bestType]!,
      allPredictions: fallbackPredictions,
      comparison: ComparisonAnalysis(
        rankings: [],
        bestOverall: FishingTypeRanking(
          fishingType: bestType,
          typeName: _localizationService.getFishingTypeName(bestType, l10n),
          icon: _getFishingTypeIcon(bestType),
          score: fallbackScores[bestType] ?? 40,
          activityLevel: _determineActivityLevel((fallbackScores[bestType] ?? 40).toDouble()),
          shortRecommendation: l10n.translate('ai_basic_conditions').replaceAll('{type}', _localizationService.getFishingTypeName(bestType, l10n)),
          keyFactors: [],
        ),
        alternativeOptions: [],
        worstOptions: [],
      ),
      generalRecommendations: [
        l10n.translate('ai_basic_mode'),
        l10n.translate('ai_standard_approaches'),
      ],
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

  String _generateCacheKey(double lat, double lon, DateTime date, List<String> types, String locale) {
    final typesKey = types.join('_');
    return 'ai_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}_${typesKey}_$locale';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // км
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
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

  String _getFishingTypeIcon(String type) {
    const icons = {
      'spinning': '🎯',
      'feeder': '🐟',
      'carp_fishing': '🎣',
      'float_fishing': '🎣',
      'ice_fishing': '❄️',
      'fly_fishing': '🦋',
      'trolling': '⛵',
    };
    return icons[type] ?? '🎣';
  }

  String _getFishingTypeImagePath(String type) {
    const imagePaths = {
      'spinning': 'assets/images/fishing_types/spinning.png',
      'feeder': 'assets/images/fishing_types/feeder.png',
      'carp_fishing': 'assets/images/fishing_types/carp_fishing.png',
      'float_fishing': 'assets/images/fishing_types/float_fishing.png',
      'ice_fishing': 'assets/images/fishing_types/ice_fishing.png',
      'fly_fishing': 'assets/images/fishing_types/fly_fishing.png',
      'trolling': 'assets/images/fishing_types/trolling.png',
    };
    return imagePaths[type] ?? 'assets/images/fishing_types/spinning.png';
  }

  /// Очистка старого кэша
  void clearOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => now.difference(value.generatedAt).inHours > 2); // Кэш актуален 2 часа
  }
}

// Enums остаются прежними
enum ActivityLevel { excellent, good, moderate, poor, veryPoor }

extension ActivityLevelExtension on ActivityLevel {
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case ActivityLevel.excellent:
        return l10n.translate('ai_activity_excellent');
      case ActivityLevel.good:
        return l10n.translate('ai_activity_good');
      case ActivityLevel.moderate:
        return l10n.translate('ai_activity_moderate');
      case ActivityLevel.poor:
        return l10n.translate('ai_activity_poor');
      case ActivityLevel.veryPoor:
        return l10n.translate('ai_activity_very_poor');
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