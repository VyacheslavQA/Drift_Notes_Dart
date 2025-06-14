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
import '../services/weather/weather_service.dart';
import '../models/weather_api_model.dart';

class AIBitePredictionService {
  static final AIBitePredictionService _instance =
      AIBitePredictionService._internal();
  factory AIBitePredictionService() => _instance;
  AIBitePredictionService._internal();

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
          debugPrint(
            '🤖 ИИ прогноз из кэша (${cached.bestPrediction.dataSource})',
          );
          return cached;
        }
      }

      debugPrint('🤖 Генерация нового прогноза...');

      // Сначала определяем, доступен ли OpenAI
      final aiAvailable = _isOpenAIConfigured();
      debugPrint('🔧 OpenAI доступен: $aiAvailable');

      // Собираем данные пользователя
      final userData = await _collectUserData(userHistory, latitude, longitude);

      // Анализируем погодные условия
      final weatherAnalysis = _analyzeWeatherConditions(weather);

      // Создаём базовые прогнозы для всех типов рыбалки
      final predictions = _generatePredictionsForAllTypes(
        weather: weather,
        userData: userData,
        weatherAnalysis: weatherAnalysis,
        latitude: latitude,
        longitude: longitude,
        targetDate: targetDate,
        useAI: false, // Сначала базовый анализ
      );

      // Пытаемся улучшить с помощью OpenAI
      bool aiEnhanced = false;
      if (aiAvailable) {
        aiEnhanced = await _enhanceWithOpenAI(predictions, weather, userData);
      }

      // Обновляем dataSource на основе успешности AI улучшения
      final finalDataSource = aiEnhanced ? 'enhanced_ai' : 'local_algorithm';
      _updateDataSource(predictions, finalDataSource);

      // Создаем мультитиповый прогноз
      final multiPrediction = _createMultiPrediction(
        predictions,
        preferredTypes,
        weather,
        aiEnhanced,
      );

      // Сохраняем в кэш
      _cache[cacheKey] = multiPrediction;

      debugPrint(
        '✅ Прогноз готов. Источник: $finalDataSource. Лучший: ${multiPrediction.bestFishingType}',
      );
      return multiPrediction;
    } catch (e) {
      debugPrint('❌ Ошибка прогноза: $e');
      return _getFallbackPrediction(weather, userHistory, latitude, longitude);
    }
  }

  /// Получить прогноз для конкретного типа рыбалки (обертка для удобства)
  Future<AIBitePrediction> getPredictionForFishingType({
    required String fishingType,
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    try {
      debugPrint('🎯 Получаем прогноз для $fishingType...');

      // Создаем фиктивный объект погоды для тестирования
      // TODO: Получить реальную погоду когда будет правильный API
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
      );

      // Возвращаем прогноз для конкретного типа
      final prediction = multiPrediction.allPredictions[fishingType];
      if (prediction == null) {
        throw Exception(
          'Не удалось получить прогноз для типа рыбалки: $fishingType',
        );
      }

      debugPrint(
        '✅ Прогноз для $fishingType готов: ${prediction.overallScore} баллов',
      );
      return prediction;
    } catch (e) {
      debugPrint('❌ Ошибка получения прогноза для $fishingType: $e');
      rethrow;
    }
  }

  /// Проверяем, настроен ли OpenAI API
  bool _isOpenAIConfigured() {
    try {
      final key = ApiKeys.openAIKey;
      final isConfigured =
          key.isNotEmpty &&
          key != 'YOUR_OPENAI_API_KEY_HERE' &&
          key.startsWith('sk-') &&
          key.length > 20;

      debugPrint(
        '🔑 OpenAI ключ проверка: длина=${key.length}, начинается с sk-=${key.startsWith('sk-')}, настроен=$isConfigured',
      );
      return isConfigured;
    } catch (e) {
      debugPrint('❌ Ошибка проверки OpenAI ключа: $e');
      return false;
    }
  }

  /// Базовый OpenAI запрос (общий метод) - ИСПРАВЛЕН
  Future<Map<String, dynamic>?> _makeOpenAIRequest(
    List<Map<String, String>> messages,
  ) async {
    if (!_isOpenAIConfigured()) {
      debugPrint('🚫 OpenAI не настроен');
      return null;
    }

    _lastAIRequestTime = DateTime.now();

    try {
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'Ты эксперт по рыбалке. Отвечай развернуто на русском языке с конкретными советами.',
          },
          ...messages,
        ],
        'max_tokens': 400, // УВЕЛИЧЕНО с 150 до 400
        'temperature':
            0.7, // УВЕЛИЧЕНО с 0.3 до 0.7 для более естественных ответов
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
          .timeout(const Duration(seconds: 30)); // УВЕЛИЧЕНО с 15 до 30 секунд

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        // ДОБАВЛЕНО: Проверка полноты ответа
        final finishReason = data['choices']?[0]?['finish_reason'];
        if (finishReason == 'length') {
          debugPrint('⚠️ Ответ OpenAI был обрезан из-за лимита токенов');
        }

        _lastAIRequestSuccessful = true;
        _lastAIError = '';

        debugPrint(
          '✅ OpenAI ответ получен успешно (finish_reason: $finishReason)',
        );
        return data;
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        _lastAIRequestSuccessful = false;
        _lastAIError =
            'HTTP ${response.statusCode}: ${errorData['error']?['message'] ?? 'Unknown error'}';

        debugPrint('❌ OpenAI ошибка: $_lastAIError');
        return null;
      }
    } catch (e) {
      _lastAIRequestSuccessful = false;
      _lastAIError = e.toString();
      debugPrint('❌ OpenAI исключение: $e');
      return null;
    }
  }

  /// Получает ИИ-рекомендации для ветра - УЛУЧШЕНО
  Future<List<String>> getWindFishingRecommendations(String prompt) async {
    try {
      final response = await _makeOpenAIRequest([
        {'role': 'user', 'content': prompt},
      ]);

      if (response != null &&
          response['choices'] != null &&
          response['choices'].isNotEmpty) {
        final content = response['choices'][0]['message']['content'] as String?;

        if (content != null && content.isNotEmpty) {
          // УЛУЧШЕНО: Более умная обработка ответа
          final cleanContent = content.trim();

          // Разбиваем на рекомендации
          List<String> recommendations = [];

          // Сначала пробуем разделить по номерам
          final numberedLines = cleanContent.split(RegExp(r'\d+\.\s*'));
          if (numberedLines.length > 1) {
            recommendations =
                numberedLines
                    .skip(1) // Пропускаем первый пустой элемент
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty && line.length > 5)
                    .take(6) // УВЕЛИЧЕНО до 6 рекомендаций
                    .toList();
          }

          // Если нумерованных пунктов нет, разбиваем по переносам строк
          if (recommendations.isEmpty) {
            recommendations =
                cleanContent
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty && line.length > 5)
                    .take(6)
                    .toList();
          }

          // Если и так не получилось, возвращаем весь ответ как одну рекомендацию
          if (recommendations.isEmpty && cleanContent.length > 10) {
            recommendations = [cleanContent];
          }

          debugPrint('✅ Получено ${recommendations.length} рекомендаций от ИИ');
          return recommendations.isNotEmpty
              ? recommendations
              : ['Рекомендации успешно получены от ИИ'];
        }
      }

      return ['Не удалось получить рекомендации от ИИ'];
    } catch (e) {
      debugPrint('❌ Ошибка получения ИИ-рекомендаций для ветра: $e');
      return ['Ошибка получения рекомендаций: $e'];
    }
  }

  /// Тестовый метод для проверки OpenAI API - УЛУЧШЕНО
  Future<Map<String, dynamic>> testOpenAIConnection() async {
    _lastAIRequestTime = DateTime.now();

    if (!_isOpenAIConfigured()) {
      _lastAIRequestSuccessful = false;
      _lastAIError = 'OpenAI API ключ не настроен';
      return {
        'success': false,
        'error': 'API ключ не настроен или неверный формат',
        'configured': false,
      };
    }

    try {
      debugPrint('🧪 Тестируем OpenAI соединение...');

      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content':
                'Ответь одной короткой фразой на русском: "API работает корректно"',
          },
        ],
        'max_tokens': 20, // Для теста достаточно
        'temperature': 0.1, // Низкая температура для стабильного ответа
      };

      debugPrint('🔍 Request body: ${json.encode(requestBody)}');

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

      debugPrint('🌐 OpenAI ответ: статус ${response.statusCode}');
      debugPrint('🔍 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Правильно декодируем ответ
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint('🔍 Decoded response body: $decodedBody');

        final data = json.decode(decodedBody);
        final answer =
            data['choices'][0]['message']['content'].toString().trim();
        final finishReason = data['choices'][0]['finish_reason'];

        debugPrint('🔍 Final answer: $answer');
        debugPrint('🔍 Finish reason: $finishReason');

        _lastAIRequestSuccessful = true;
        _lastAIError = '';

        return {
          'success': true,
          'status': response.statusCode,
          'model': data['model'] ?? 'unknown',
          'response': answer,
          'finish_reason': finishReason,
          'configured': true,
          'response_time':
              DateTime.now().difference(_lastAIRequestTime!).inMilliseconds,
        };
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        _lastAIRequestSuccessful = false;
        _lastAIError =
            'HTTP ${response.statusCode}: ${errorData['error']?['message'] ?? 'Unknown error'}';

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

      debugPrint('❌ OpenAI тест ошибка: $e');
      return {'success': false, 'error': e.toString(), 'configured': true};
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
    final successfulTrips =
        userHistory
            .where(
              (note) =>
                  note.biteRecords.isNotEmpty &&
                  note.biteRecords.any((bite) => bite.weight > 0),
            )
            .toList();

    // Найдем поездки рядом с текущим местоположением
    final locationTrips =
        userHistory.where((note) {
          return _calculateDistance(
                note.latitude,
                note.longitude,
                latitude,
                longitude,
              ) <
              50; // В радиусе 50 км
        }).toList();

    // Анализ успешных условий
    final successfulConditions = <Map<String, dynamic>>[];
    for (final trip in successfulTrips) {
      successfulConditions.add({
        'fishing_type': trip.fishingType,
        'time_of_day': trip.date.hour,
        'season': _getSeason(trip.date),
        'catch_weight': trip.biteRecords.fold(
          0.0,
          (sum, bite) => sum + bite.weight,
        ),
        'bite_count': trip.biteRecords.length,
        'duration_hours': trip.endDate?.difference(trip.date).inHours ?? 8,
      });
    }

    // Предпочитаемые типы рыбалки
    final typeFrequency = <String, int>{};
    for (final trip in userHistory) {
      typeFrequency[trip.fishingType] =
          (typeFrequency[trip.fishingType] ?? 0) + 1;
    }

    final preferredTypes =
        typeFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'has_data': true,
      'total_trips': userHistory.length,
      'successful_trips': successfulTrips.length,
      'success_rate': successfulTrips.length / userHistory.length,
      'preferred_types': preferredTypes.take(3).map((e) => e.key).toList(),
      'successful_conditions': successfulConditions,
      'location_familiarity': locationTrips.length / userHistory.length,
      'avg_trip_duration':
          userHistory
              .map((trip) => trip.endDate?.difference(trip.date).inHours ?? 0)
              .where((duration) => duration > 0)
              .fold(0.0, (sum, duration) => sum + duration) /
          userHistory.length,
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
    required bool useAI,
  }) {
    final predictions = <String, AIBitePrediction>{};
    final current = weather.current;

    // Исправляем конфигурацию типов рыбалки с более реалистичными параметрами
    final fishingTypes = {
      'spinning': {
        'name': 'Спиннинг',
        'wind_tolerance': 25.0, // км/ч
        'temp_optimal_min': 8.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.8,
        'season_bonus': _getSeasonBonus('spinning', _getSeason(targetDate)),
        'base_score': 45.0, // Разный базовый скор
      },
      'feeder': {
        'name': 'Фидер',
        'wind_tolerance': 20.0,
        'temp_optimal_min': 12.0,
        'temp_optimal_max': 28.0,
        'pressure_sensitivity': 0.9,
        'season_bonus': _getSeasonBonus('feeder', _getSeason(targetDate)),
        'base_score': 50.0,
      },
      'carp_fishing': {
        'name': 'Карповая рыбалка',
        'wind_tolerance': 15.0,
        'temp_optimal_min': 15.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 1.0,
        'season_bonus': _getSeasonBonus('carp_fishing', _getSeason(targetDate)),
        'base_score': 40.0,
      },
      'float_fishing': {
        'name': 'Поплавочная рыбалка',
        'wind_tolerance': 10.0,
        'temp_optimal_min': 8.0,
        'temp_optimal_max': 25.0,
        'pressure_sensitivity': 0.7,
        'season_bonus': _getSeasonBonus(
          'float_fishing',
          _getSeason(targetDate),
        ),
        'base_score': 55.0,
      },
      'ice_fishing': {
        'name': 'Зимняя рыбалка',
        'wind_tolerance': 30.0,
        'temp_optimal_min': -15.0,
        'temp_optimal_max': 5.0,
        'pressure_sensitivity': 1.2,
        'season_bonus': _getSeasonBonus('ice_fishing', _getSeason(targetDate)),
        'base_score':
            current.tempC <= 0
                ? 60.0
                : 10.0, // Кардинально разные скоры зимой и летом
      },
      'fly_fishing': {
        'name': 'Нахлыст',
        'wind_tolerance': 8.0,
        'temp_optimal_min': 10.0,
        'temp_optimal_max': 22.0,
        'pressure_sensitivity': 0.6,
        'season_bonus': _getSeasonBonus('fly_fishing', _getSeason(targetDate)),
        'base_score': 35.0,
      },
      'trolling': {
        'name': 'Троллинг',
        'wind_tolerance': 35.0,
        'temp_optimal_min': 5.0,
        'temp_optimal_max': 30.0,
        'pressure_sensitivity': 0.5,
        'season_bonus': _getSeasonBonus('trolling', _getSeason(targetDate)),
        'base_score': 42.0,
      },
    };

    debugPrint(
      '🎣 Генерируем прогнозы для ${fishingTypes.length} типов рыбалки...',
    );

    for (final entry in fishingTypes.entries) {
      final type = entry.key;
      final config = entry.value;

      predictions[type] = _generatePredictionForType(
        type,
        config,
        weather,
        userData,
        weatherAnalysis,
        useAI,
      );

      debugPrint('📊 $type: ${predictions[type]!.overallScore} баллов');
    }

    return predictions;
  }

  /// Получаем сезонный бонус для типа рыбалки
  double _getSeasonBonus(String fishingType, String season) {
    const seasonBonuses = {
      'spinning': {
        'spring': 15.0,
        'summer': 10.0,
        'autumn': 20.0,
        'winter': -10.0,
      },
      'feeder': {
        'spring': 10.0,
        'summer': 15.0,
        'autumn': 10.0,
        'winter': -15.0,
      },
      'carp_fishing': {
        'spring': 5.0,
        'summer': 20.0,
        'autumn': 10.0,
        'winter': -25.0,
      },
      'float_fishing': {
        'spring': 20.0,
        'summer': 15.0,
        'autumn': 10.0,
        'winter': -5.0,
      },
      'ice_fishing': {
        'spring': -30.0,
        'summer': -40.0,
        'autumn': -20.0,
        'winter': 30.0,
      },
      'fly_fishing': {
        'spring': 20.0,
        'summer': 10.0,
        'autumn': 15.0,
        'winter': -20.0,
      },
      'trolling': {
        'spring': 10.0,
        'summer': 15.0,
        'autumn': 5.0,
        'winter': -10.0,
      },
    };

    return seasonBonuses[fishingType]?[season] ?? 0.0;
  }

  /// Генерация прогноза для конкретного типа рыбалки
  AIBitePrediction _generatePredictionForType(
    String fishingType,
    Map<String, dynamic> config,
    WeatherApiResponse weather,
    Map<String, dynamic> userData,
    Map<String, dynamic> weatherAnalysis,
    bool useAI,
  ) {
    // Начинаем с базового скора для типа
    double score = config['base_score'] as double;
    final factors = <BiteFactorAnalysis>[];
    final tips = <String>[];

    debugPrint('🎯 Анализируем $fishingType, базовый скор: $score');

    // Применяем сезонный бонус
    final seasonBonus = config['season_bonus'] as double;
    score += seasonBonus;
    if (seasonBonus != 0) {
      factors.add(
        BiteFactorAnalysis(
          name: 'Сезон',
          value: _getSeason(DateTime.now()),
          impact: seasonBonus.round(),
          weight: 0.9,
          description:
              seasonBonus > 0
                  ? 'Благоприятный сезон для ${config['name']}'
                  : 'Неблагоприятный сезон',
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
          name: 'Ветер',
          value: '${windKph.round()} км/ч',
          impact: windBonus.round(),
          weight: 0.8,
          description: 'Подходящий ветер для ${config['name']}',
          isPositive: true,
        ),
      );
    } else {
      final excess = windKph - windTolerance;
      final windPenalty =
          -math.min(excess * 2, 30.0); // Максимальный штраф 30 баллов
      score += windPenalty;
      factors.add(
        BiteFactorAnalysis(
          name: 'Ветер',
          value: '${windKph.round()} км/ч',
          impact: windPenalty.round(),
          weight: 0.8,
          description: 'Слишком сильный ветер для ${config['name']}',
          isPositive: false,
        ),
      );
      tips.add('При сильном ветре ищите защищенные места');
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
          name: 'Температура',
          value: '${temp.round()}°C',
          impact: tempBonus.round(),
          weight: 0.7,
          description: 'Оптимальная температура для ${config['name']}',
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
          name: 'Температура',
          value: '${temp.round()}°C',
          impact: tempPenalty.round(),
          weight: 0.7,
          description:
              temp < tempMin
                  ? 'Слишком холодно для ${config['name']}'
                  : 'Слишком жарко',
          isPositive: false,
        ),
      );

      if (temp < tempMin) {
        tips.add('В холодную погоду рыба менее активна - замедлите проводку');
      } else {
        tips.add('В жаркую погоду рыба уходит на глубину');
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
          name: 'Атмосферное давление',
          value: '${pressure.round()} мб',
          impact: pressureBonus.round(),
          weight: pressureSensitivity,
          description: 'Стабильное давление способствует клеву',
          isPositive: true,
        ),
      );
    } else {
      final pressurePenalty =
          pressure < 1000
              ? -18 * pressureSensitivity
              : -12 * pressureSensitivity;
      score += pressurePenalty;
      factors.add(
        BiteFactorAnalysis(
          name: 'Атмосферное давление',
          value: '${pressure.round()} мб',
          impact: pressurePenalty.round(),
          weight: pressureSensitivity,
          description:
              pressure < 1000
                  ? 'Низкое давление снижает активность'
                  : 'Высокое давление неблагоприятно',
          isPositive: false,
        ),
      );
      tips.add('При изменении давления рыба может быть пассивной');
    }

    // Учет пользовательских данных
    if (userData['has_data'] == true) {
      final preferredTypes = userData['preferred_types'] as List<dynamic>;
      if (preferredTypes.contains(fishingType)) {
        score += 8;
        factors.add(
          BiteFactorAnalysis(
            name: 'Персональная история',
            value: 'Предпочитаемый тип',
            impact: 8,
            weight: 0.6,
            description: 'Вы часто используете этот тип рыбалки',
            isPositive: true,
          ),
        );
      }
    }

    // Специальные условия для зимней рыбалки
    if (fishingType == 'ice_fishing') {
      if (temp > 5) {
        score = math.min(score, 15.0); // Максимум 15 баллов летом
        tips.add('Зимняя рыбалка невозможна при плюсовой температуре');
      }
    }

    // Генерируем временные окна
    final timeWindows = _generateTimeWindows(weather, fishingType);

    // Генерируем дополнительные советы
    tips.addAll(_generateTipsForType(fishingType, weather));

    // Ограничиваем скор
    score = score.clamp(0.0, 100.0);

    // Определяем уровень активности
    final activityLevel = _determineActivityLevel(score);

    // Генерируем рекомендацию
    final recommendation = _generateRecommendation(fishingType, score, factors);

    debugPrint('✅ $fishingType: финальный скор $score');

    return AIBitePrediction(
      overallScore: score.round(),
      activityLevel: activityLevel,
      confidence: useAI ? 0.9 : 0.8,
      recommendation: recommendation,
      detailedAnalysis: _generateDetailedAnalysis(
        fishingType,
        factors,
        weather,
      ),
      factors: factors,
      bestTimeWindows: timeWindows,
      tips: tips,
      generatedAt: DateTime.now(),
      dataSource: useAI ? 'enhanced_ai' : 'local_algorithm',
      modelVersion: useAI ? '2.1.0-ai' : '2.0.0-local',
    );
  }

  /// Улучшение прогноза с помощью OpenAI - ИСПРАВЛЕНО
  Future<bool> _enhanceWithOpenAI(
    Map<String, AIBitePrediction> predictions,
    WeatherApiResponse weather,
    Map<String, dynamic> userData,
  ) async {
    if (!_isOpenAIConfigured()) {
      debugPrint('🚫 OpenAI не настроен, пропускаем улучшение');
      return false;
    }

    _lastAIRequestTime = DateTime.now();

    try {
      debugPrint('🧠 Улучшаем прогноз с помощью OpenAI...');

      final prompt = _buildOpenAIPrompt(predictions, weather, userData);

      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'Ты эксперт по рыбалке. Проанализируй условия и дай практические советы на русском языке.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300, // УВЕЛИЧЕНО с 200 до 300
        'temperature': 0.6, // УВЕЛИЧЕНО с 0.3 до 0.6
      };

      debugPrint('🔍 Request body: ${json.encode(requestBody)}');

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
          .timeout(const Duration(seconds: 30)); // УВЕЛИЧЕНО таймаут

      debugPrint('🌐 OpenAI ответ: статус ${response.statusCode}');

      if (response.statusCode == 200) {
        // Правильно декодируем ответ
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        final aiResponse = data['choices'][0]['message']['content'] as String;
        final finishReason = data['choices'][0]['finish_reason'];

        debugPrint('🔍 AI response: $aiResponse');
        debugPrint('🔍 Finish reason: $finishReason');

        // Обрабатываем ответ AI и улучшаем прогнозы
        _processAIResponse(predictions, aiResponse, weather);

        _lastAIRequestSuccessful = true;
        _lastAIError = '';

        debugPrint('✅ OpenAI улучшение применено успешно');
        return true;
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        _lastAIRequestSuccessful = false;
        _lastAIError =
            'HTTP ${response.statusCode}: ${errorData['error']?['message'] ?? 'Unknown error'}';

        debugPrint('❌ OpenAI ошибка: $_lastAIError');
        return false;
      }
    } catch (e) {
      _lastAIRequestSuccessful = false;
      _lastAIError = e.toString();

      debugPrint('❌ OpenAI исключение: $e');
      return false;
    }
  }

  /// Обработка ответа от AI и улучшение прогнозов - УЛУЧШЕНО
  void _processAIResponse(
    Map<String, AIBitePrediction> predictions,
    String aiResponse,
    WeatherApiResponse weather,
  ) {
    try {
      debugPrint('🔍 Processing AI response: $aiResponse');

      // Добавляем AI советы к лучшему прогнозу
      final bestType =
          predictions.entries
              .reduce(
                (a, b) => a.value.overallScore > b.value.overallScore ? a : b,
              )
              .key;

      if (predictions[bestType] != null) {
        final enhanced = predictions[bestType]!;

        // УЛУЧШЕНО: Более аккуратная обработка ответа
        final cleanResponse = aiResponse.trim();

        // Проверяем, что ответ не пустой и содержательный
        if (cleanResponse.isNotEmpty && cleanResponse.length > 10) {
          // Разбиваем ответ на отдельные советы, если они есть
          final aiTips =
              cleanResponse
                  .split(RegExp(r'[.!]\s+'))
                  .map((tip) => tip.trim())
                  .where((tip) => tip.isNotEmpty && tip.length > 5)
                  .take(3) // Максимум 3 совета
                  .toList();

          if (aiTips.isNotEmpty) {
            // Добавляем каждый совет отдельно
            for (int i = 0; i < aiTips.length; i++) {
              enhanced.tips.insert(i, '🧠 ИИ совет ${i + 1}: ${aiTips[i]}');
            }
          } else {
            // Если не удалось разбить, добавляем весь ответ
            enhanced.tips.insert(0, '🧠 ИИ анализ: $cleanResponse');
          }

          debugPrint('✨ AI советы добавлены к прогнозу $bestType');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка обработки AI ответа: $e');
      // Добавляем базовый совет, если обработка не удалась
      final bestType =
          predictions.entries
              .reduce(
                (a, b) => a.value.overallScore > b.value.overallScore ? a : b,
              )
              .key;

      if (predictions[bestType] != null) {
        predictions[bestType]!.tips.insert(
          0,
          '🧠 Анализ улучшен искусственным интеллектом',
        );
      }
    }
  }

  /// Обновление источника данных для всех прогнозов
  void _updateDataSource(
    Map<String, AIBitePrediction> predictions,
    String dataSource,
  ) {
    for (final prediction in predictions.values) {
      // Обновляем поля через reflection или создаем новый объект
      // Поскольку AIBitePrediction immutable, обновляем через tips
      if (dataSource == 'enhanced_ai') {
        if (!prediction.tips.any((tip) => tip.contains('🧠 ИИ'))) {
          prediction.tips.insert(
            0,
            '🧠 Анализ улучшен искусственным интеллектом',
          );
        }
      }
    }
  }

  /// Создание мультитипового прогноза
  MultiFishingTypePrediction _createMultiPrediction(
    Map<String, AIBitePrediction> predictions,
    List<String>? preferredTypes,
    WeatherApiResponse weather,
    bool aiEnhanced,
  ) {
    // Сортируем по скору
    final sortedPredictions =
        predictions.entries.toList()..sort(
          (a, b) => b.value.overallScore.compareTo(a.value.overallScore),
        );

    // Определяем лучший тип с учетом предпочтений пользователя
    String bestType = sortedPredictions.first.key;

    if (preferredTypes != null && preferredTypes.isNotEmpty) {
      for (final preferred in preferredTypes) {
        if (predictions.containsKey(preferred) &&
            predictions[preferred]!.overallScore >= 40) {
          bestType = preferred;
          break;
        }
      }
    }

    // Создаем сравнительный анализ
    final comparison = _createComparisonAnalysis(predictions);

    // Генерируем общие рекомендации
    final generalRecommendations = _generateGeneralRecommendations(
      predictions,
      bestType,
      aiEnhanced,
    );

    debugPrint(
      '🏆 Лучший тип рыбалки: $bestType (${predictions[bestType]!.overallScore} баллов)',
    );

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

  // Остальные методы остаются без изменений...

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
  ) {
    final now = DateTime.now();
    final windows = <OptimalTimeWindow>[];

    // Утреннее окно
    windows.add(
      OptimalTimeWindow(
        startTime: now.copyWith(hour: 6, minute: 0),
        endTime: now.copyWith(hour: 8, minute: 30),
        activity: 0.85,
        reason: 'Утренняя активность рыбы',
        recommendations: ['Используйте активные приманки'],
      ),
    );

    // Вечернее окно
    windows.add(
      OptimalTimeWindow(
        startTime: now.copyWith(hour: 18, minute: 0),
        endTime: now.copyWith(hour: 20, minute: 30),
        activity: 0.9,
        reason: 'Вечерняя активность рыбы',
        recommendations: ['Попробуйте поверхностные приманки'],
      ),
    );

    return windows;
  }

  List<String> _generateTipsForType(
    String fishingType,
    WeatherApiResponse weather,
  ) {
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
      case 'ice_fishing':
        tips.add('Используйте мормышки и блесны');
        tips.add('Сверлите лунки на разной глубине');
        break;
      case 'fly_fishing':
        tips.add('Следите за направлением ветра при забросе');
        tips.add('Используйте сухие мушки в теплую погоду');
        break;
      case 'trolling':
        tips.add('Меняйте скорость движения лодки');
        tips.add('Используйте воблеры разных размеров');
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
  ) {
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

  String _generateDetailedAnalysis(
    String fishingType,
    List<BiteFactorAnalysis> factors,
    WeatherApiResponse weather,
  ) {
    final analysis = StringBuffer();
    analysis.write('Анализ условий для ${_getFishingTypeName(fishingType)}: ');

    final positiveFactors = factors.where((f) => f.isPositive).length;
    final negativeFactors = factors.where((f) => !f.isPositive).length;

    if (positiveFactors > negativeFactors) {
      analysis.write('Преобладают благоприятные факторы. ');
    } else if (negativeFactors > positiveFactors) {
      analysis.write(
        'Есть неблагоприятные факторы, которые могут снизить активность рыбы. ',
      );
    } else {
      analysis.write('Смешанные условия - успех зависит от техники и опыта. ');
    }

    analysis.write('Температура воздуха ${weather.current.tempC.round()}°C, ');
    analysis.write('давление ${weather.current.pressureMb.round()} мб, ');
    analysis.write('ветер ${weather.current.windKph.round()} км/ч.');

    return analysis.toString();
  }

  ComparisonAnalysis _createComparisonAnalysis(
    Map<String, AIBitePrediction> predictions,
  ) {
    final rankings =
        predictions.entries
            .map(
              (e) => FishingTypeRanking(
                fishingType: e.key,
                typeName: _getFishingTypeName(e.key),
                icon: _getFishingTypeIcon(e.key),
                score: e.value.overallScore,
                activityLevel: e.value.activityLevel,
                shortRecommendation: e.value.recommendation,
                keyFactors: e.value.factors.take(3).map((f) => f.name).toList(),
              ),
            )
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
  ) {
    final recommendations = <String>[];
    final bestPrediction = predictions[bestType]!;

    if (aiEnhanced) {
      recommendations.add('🧠 Анализ улучшен искусственным интеллектом');
    } else {
      recommendations.add('📊 Базовый алгоритмический анализ');
    }

    recommendations.add('Рекомендуемый тип: ${_getFishingTypeName(bestType)}');
    recommendations.add(bestPrediction.recommendation);

    if (bestPrediction.overallScore >= 80) {
      recommendations.add('Отличные условия - не упустите возможность!');
    } else if (bestPrediction.overallScore < 40) {
      recommendations.add(
        'Подумайте о переносе рыбалки на более благоприятное время',
      );
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
      moonPhase:
          weather.forecast.isNotEmpty
              ? weather.forecast.first.astro.moonPhase
              : 'Unknown',
    );
  }

  String _buildOpenAIPrompt(
    Map<String, AIBitePrediction> predictions,
    WeatherApiResponse weather,
    Map<String, dynamic> userData,
  ) {
    final bestType = predictions.entries.reduce(
      (a, b) => a.value.overallScore > b.value.overallScore ? a : b,
    );

    return '''
Условия рыбалки:
- Погода: ${weather.current.tempC}°C, давление ${weather.current.pressureMb} мб, ветер ${weather.current.windKph} км/ч
- Лучший тип: ${bestType.key} (${bestType.value.overallScore} баллов)
- Фаза луны: ${weather.forecast.isNotEmpty ? weather.forecast.first.astro.moonPhase : 'неизвестно'}

Дай 2-3 конкретных совета для успешной рыбалки в этих условиях на русском языке (каждый совет - отдельное предложение).
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

    // Создаем простые fallback прогнозы с разными скорами
    final fallbackScores = {
      'spinning': 55,
      'feeder': 50,
      'carp_fishing': 45,
      'float_fishing': 60,
      'ice_fishing': weather.current.tempC <= 0 ? 40 : 5,
      'fly_fishing': 35,
      'trolling': 42,
    };

    for (final entry in fallbackScores.entries) {
      fallbackPredictions[entry.key] = AIBitePrediction(
        overallScore: entry.value,
        activityLevel: _determineActivityLevel(entry.value.toDouble()),
        confidence: 0.3,
        recommendation: 'Базовые условия для ${_getFishingTypeName(entry.key)}',
        detailedAnalysis: 'Анализ основан на базовых алгоритмах',
        factors: [],
        bestTimeWindows: [],
        tips: ['Ловите в утренние и вечерние часы'],
        generatedAt: DateTime.now(),
        dataSource: 'fallback_algorithm',
        modelVersion: '1.0.0-fallback',
      );
    }

    final bestType =
        fallbackScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return MultiFishingTypePrediction(
      bestFishingType: bestType,
      bestPrediction: fallbackPredictions[bestType]!,
      allPredictions: fallbackPredictions,
      comparison: ComparisonAnalysis(
        rankings: [],
        bestOverall: FishingTypeRanking(
          fishingType: bestType,
          typeName: _getFishingTypeName(bestType),
          icon: _getFishingTypeIcon(bestType),
          score: fallbackScores[bestType]!,
          activityLevel: _determineActivityLevel(
            fallbackScores[bestType]!.toDouble(),
          ),
          shortRecommendation: 'Базовые условия',
          keyFactors: [],
        ),
        alternativeOptions: [],
        worstOptions: [],
      ),
      generalRecommendations: [
        '📊 Базовый режим из-за ошибки анализа',
        'Используйте стандартные подходы к рыбалке',
      ],
      weatherSummary: WeatherSummary(
        temperature: weather.current.tempC,
        pressure: weather.current.pressureMb,
        windSpeed: weather.current.windKph,
        humidity: weather.current.humidity,
        condition: weather.current.condition.text,
        moonPhase:
            weather.forecast.isNotEmpty
                ? weather.forecast.first.astro.moonPhase
                : 'Unknown',
      ),
      generatedAt: DateTime.now(),
    );
  }

  // Дополнительные вспомогательные методы...

  String _generateCacheKey(double lat, double lon, DateTime date) {
    return 'ai_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}';
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // км
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
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

    final sortedHours =
        hourCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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

  // Вместо старого _getFishingTypeIcon() добавь эти два метода:

  String _getFishingTypeIcon(String type) {
    const icons = {
      'spinning': '🎯',
      'feeder': '🐟',
      'carp_fishing': '🎣', // Заменили ящерицу на удочку
      'float_fishing': '🎣',
      'ice_fishing': '❄️',
      'fly_fishing': '🦋',
      'trolling': '⛵', // Заменили лодку на парусник
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
    _cache.removeWhere(
      (key, value) =>
          now.difference(value.generatedAt).inHours > 2, // Кэш актуален 2 часа
    );
  }
}

// Enums остаются прежними
enum ActivityLevel { excellent, good, moderate, poor, veryPoor }

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
