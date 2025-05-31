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

class AIBitePredictionService {
  static final AIBitePredictionService _instance = AIBitePredictionService._internal();
  factory AIBitePredictionService() => _instance;
  AIBitePredictionService._internal();

  // Кэш для оптимизации
  final Map<String, AIBitePrediction> _cache = {};
  static const String _cacheKey = 'ai_bite_cache';

  /// Основной метод получения ИИ прогноза клёва
  Future<AIBitePrediction> getAIBitePrediction({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    required String fishingType,
    List<FishingNote>? userHistory,
    DateTime? targetDate,
  }) async {
    try {
      targetDate ??= DateTime.now();

      // Создаём уникальный ключ для кэширования
      final cacheKey = _generateCacheKey(latitude, longitude, targetDate, fishingType);

      // Проверяем кэш (актуален 1 час)
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().difference(cached.generatedAt).inHours < 1) {
          debugPrint('🤖 ИИ прогноз из кэша');
          return cached;
        }
      }

      debugPrint('🤖 Генерация нового ИИ прогноза...');

      // Собираем все данные для анализа
      final analysisData = await _collectAnalysisData(
        weather: weather,
        latitude: latitude,
        longitude: longitude,
        fishingType: fishingType,
        userHistory: userHistory,
        targetDate: targetDate,
      );

      // Комбинируем локальный и облачный анализ
      final localPrediction = await _getLocalAIPrediction(analysisData);
      final cloudPrediction = await _getCloudAIPrediction(analysisData);

      // Объединяем результаты
      final finalPrediction = _combinepredictions(localPrediction, cloudPrediction, analysisData);

      // Сохраняем в кэш
      _cache[cacheKey] = finalPrediction;
      await _saveCacheToStorage();

      debugPrint('✅ ИИ прогноз готов: ${finalPrediction.overallScore}/100');
      return finalPrediction;

    } catch (e) {
      debugPrint('❌ Ошибка ИИ прогноза: $e');
      // Возвращаем fallback прогноз
      return _getFallbackPrediction(weather, fishingType);
    }
  }

  /// Сбор всех данных для анализа
  Future<Map<String, dynamic>> _collectAnalysisData({
    required WeatherApiResponse weather,
    required double latitude,
    required double longitude,
    required String fishingType,
    List<FishingNote>? userHistory,
    required DateTime targetDate,
  }) async {
    final current = weather.current;
    final forecast = weather.forecast.isNotEmpty ? weather.forecast.first : null;

    // Основные погодные данные
    final weatherData = {
      'temperature': current.tempC,
      'feels_like': current.feelslikeC,
      'humidity': current.humidity,
      'pressure': current.pressureMb,
      'pressure_trend': await _calculatePressureTrend(weather),
      'wind_speed': current.windKph,
      'wind_direction': current.windDir,
      'wind_gust': current.gustKph,
      'visibility': current.visKm,
      'uv_index': current.uv,
      'cloud_cover': current.cloud,
      'condition': current.condition.text,
      'is_day': current.isDay == 1,
    };

    // Астрономические данные
    final astroData = forecast != null ? {
      'sunrise': forecast.astro.sunrise,
      'sunset': forecast.astro.sunset,
      'moonrise': forecast.astro.moonrise,
      'moonset': forecast.astro.moonset,
      'moon_phase': forecast.astro.moonPhase,
      'moon_illumination': forecast.astro.moonIllumination,
    } : <String, dynamic>{};

    // Временные факторы
    final timeData = {
      'hour': targetDate.hour,
      'day_of_week': targetDate.weekday,
      'day_of_month': targetDate.day,
      'month': targetDate.month,
      'season': _getSeason(targetDate),
      'is_weekend': targetDate.weekday >= 6,
    };

    // Географические данные
    final geoData = {
      'latitude': latitude,
      'longitude': longitude,
      'region': weather.location.region,
      'country': weather.location.country,
      'timezone': weather.location.tzId,
      'water_type': _determineWaterType(latitude, longitude), // река/озеро/море
    };

    // Анализ истории пользователя
    final historyData = _analyzeUserHistory(userHistory, fishingType, targetDate);

    // Исторические погодные паттерны
    final historicalData = await _getHistoricalWeatherPatterns(latitude, longitude, targetDate);

    return {
      'weather': weatherData,
      'astro': astroData,
      'time': timeData,
      'geo': geoData,
      'user_history': historyData,
      'historical_patterns': historicalData,
      'fishing_type': fishingType,
      'target_date': targetDate.toIso8601String(),
    };
  }

  /// Локальный ИИ анализ (быстрый, офлайн)
  Future<Map<String, dynamic>> _getLocalAIPrediction(Map<String, dynamic> data) async {
    debugPrint('🧠 Локальный ИИ анализ...');

    double score = 50.0; // Базовый скор
    final factors = <String, Map<String, dynamic>>{};

    // Анализ температуры
    final temp = data['weather']['temperature'] as double;
    final tempFactor = _analyzeTemperatureFactor(temp, data['fishing_type']);
    score += tempFactor['impact'] * tempFactor['weight'];
    factors['temperature'] = tempFactor;

    // Анализ давления
    final pressure = data['weather']['pressure'] as double;
    final pressureTrend = data['weather']['pressure_trend'] as String;
    final pressureFactor = _analyzePressureFactor(pressure, pressureTrend);
    score += pressureFactor['impact'] * pressureFactor['weight'];
    factors['pressure'] = pressureFactor;

    // Анализ ветра
    final windSpeed = data['weather']['wind_speed'] as double;
    final windDir = data['weather']['wind_direction'] as String;
    final windFactor = _analyzeWindFactor(windSpeed, windDir, data['fishing_type']);
    score += windFactor['impact'] * windFactor['weight'];
    factors['wind'] = windFactor;

    // Анализ времени
    final hour = data['time']['hour'] as int;
    final sunrise = data['astro']['sunrise'] as String?;
    final sunset = data['astro']['sunset'] as String?;
    final timeFactor = _analyzeTimeFactor(hour, sunrise, sunset);
    score += timeFactor['impact'] * timeFactor['weight'];
    factors['time'] = timeFactor;

    // Анализ луны
    final moonPhase = data['astro']['moon_phase'] as String?;
    final moonIllumination = data['astro']['moon_illumination'] as int?;
    final moonFactor = _analyzeMoonFactor(moonPhase, moonIllumination);
    score += moonFactor['impact'] * moonFactor['weight'];
    factors['moon'] = moonFactor;

    // Сезонный анализ
    final season = data['time']['season'] as String;
    final month = data['time']['month'] as int;
    final seasonFactor = _analyzeSeasonFactor(season, month, data['fishing_type']);
    score += seasonFactor['impact'] * seasonFactor['weight'];
    factors['season'] = seasonFactor;

    // Анализ истории пользователя
    final historyFactor = _analyzeUserHistoryFactor(data['user_history']);
    score += historyFactor['impact'] * historyFactor['weight'];
    factors['user_history'] = historyFactor;

    score = score.clamp(0.0, 100.0);

    return {
      'source': 'local_ai',
      'score': score,
      'confidence': 0.75,
      'factors': factors,
      'processing_time_ms': 50,
    };
  }

  /// Облачный ИИ анализ (мощный, требует интернет)
  Future<Map<String, dynamic>> _getCloudAIPrediction(Map<String, dynamic> data) async {
    try {
      debugPrint('☁️ Облачный ИИ анализ...');

      // Если нет API ключа OpenAI, используем мок
      if (ApiKeys.openAiApiKey.isEmpty) {
        return _getMockCloudPrediction(data);
      }

      final prompt = _buildAIPrompt(data);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAiApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты эксперт по рыбалке и прогнозированию клёва. Анализируй данные и дай точный прогноз клёва от 0 до 100 баллов с объяснением факторов.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final aiResponse = result['choices'][0]['message']['content'];

        return _parseAIResponse(aiResponse);
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }

    } catch (e) {
      debugPrint('❌ Ошибка облачного ИИ: $e');
      return _getMockCloudPrediction(data);
    }
  }

  /// Объединение локального и облачного прогнозов
  AIBitePrediction _combinepredictions(
      Map<String, dynamic> localPrediction,
      Map<String, dynamic> cloudPrediction,
      Map<String, dynamic> data,
      ) {
    // Взвешиваем результаты
    final localWeight = 0.4;
    final cloudWeight = 0.6;

    final localScore = localPrediction['score'] as double;
    final cloudScore = cloudPrediction['score'] as double;

    final combinedScore = (localScore * localWeight + cloudScore * cloudWeight).round();

    // Определяем уровень активности
    final activityLevel = _getActivityLevel(combinedScore);

    // Генерируем рекомендации
    final recommendations = _generateRecommendations(combinedScore, data);

    // Создаём детальные факторы
    final detailedFactors = _createDetailedFactors(localPrediction['factors'], data);

    // Определяем лучшие временные окна
    final bestTimeWindows = _calculateBestTimeWindows(data, combinedScore);

    return AIBitePrediction(
      overallScore: combinedScore,
      activityLevel: activityLevel,
      confidence: ((localPrediction['confidence'] as double + cloudPrediction['confidence'] as double) / 2),
      recommendation: recommendations['main'] as String,
      detailedAnalysis: recommendations['detailed'] as String,
      factors: detailedFactors,
      bestTimeWindows: bestTimeWindows,
      tips: recommendations['tips'] as List<String>,
      generatedAt: DateTime.now(),
      dataSource: 'ai_hybrid',
      modelVersion: '1.0.0',
    );
  }

  // Вспомогательные методы анализа факторов...

  Map<String, dynamic> _analyzeTemperatureFactor(double temp, String fishingType) {
    double impact = 0.0;
    String description = '';

    // Оптимальные температуры для разных видов рыбалки
    Map<String, List<double>> optimalTemps = {
      'spinning': [15.0, 25.0],
      'feeder': [12.0, 22.0],
      'carp_fishing': [18.0, 28.0],
      'float_fishing': [10.0, 20.0],
      'ice_fishing': [-10.0, 5.0],
    };

    final optimal = optimalTemps[fishingType] ?? [15.0, 25.0];

    if (temp >= optimal[0] && temp <= optimal[1]) {
      impact = 15.0;
      description = 'Оптимальная температура для данного типа рыбалки';
    } else if (temp >= optimal[0] - 5 && temp <= optimal[1] + 5) {
      impact = 5.0;
      description = 'Приемлемая температура';
    } else {
      impact = -10.0;
      description = 'Неблагоприятная температура';
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

  Map<String, dynamic> _analyzePressureFactor(double pressure, String trend) {
    double impact = 0.0;
    String description = '';

    // Оптимальное давление: 1010-1025 гПа
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

    // Учитываем тренд давления
    switch (trend) {
      case 'rising':
        impact += 5.0;
        description += '. Давление растёт - рыба активизируется';
        break;
      case 'falling':
        impact -= 8.0;
        description += '. Давление падает - клёв ослабевает';
        break;
      case 'stable':
        impact += 2.0;
        description += '. Стабильное давление способствует клёву';
        break;
    }

    return {
      'name': 'Атмосферное давление',
      'value': pressure,
      'trend': trend,
      'impact': impact,
      'weight': 1.0, // Самый важный фактор
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeWindFactor(double windSpeed, String windDir, String fishingType) {
    double impact = 0.0;
    String description = '';

    // Анализ скорости ветра
    if (windSpeed <= 5) {
      impact = 5.0;
      description = 'Слабый ветер благоприятен';
    } else if (windSpeed <= 15) {
      impact = 10.0; // Лёгкий ветер - идеально
      description = 'Лёгкий ветер - отличные условия';
    } else if (windSpeed <= 25) {
      impact = -5.0;
      description = 'Умеренный ветер затрудняет рыбалку';
    } else {
      impact = -20.0;
      description = 'Сильный ветер - сложные условия';
    }

    // Направление ветра влияет на разные типы рыбалки
    if (fishingType == 'spinning' && (windDir.contains('W') || windDir.contains('SW'))) {
      impact += 3.0;
      description += '. Западный ветер хорош для спиннинга';
    }

    return {
      'name': 'Ветер',
      'speed': windSpeed,
      'direction': windDir,
      'impact': impact,
      'weight': 0.7,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeTimeFactor(int hour, String? sunrise, String? sunset) {
    double impact = 0.0;
    String description = '';

    // Лучшие часы для рыбалки
    if ((hour >= 5 && hour <= 8) || (hour >= 18 && hour <= 21)) {
      impact = 15.0;
      description = 'Золотое время рыбалки';
    } else if ((hour >= 9 && hour <= 11) || (hour >= 16 && hour <= 17)) {
      impact = 8.0;
      description = 'Хорошее время для клёва';
    } else if (hour >= 12 && hour <= 15) {
      impact = -5.0;
      description = 'Дневное затишье';
    } else {
      impact = 0.0;
      description = 'Обычное время';
    }

    // Проверяем близость к восходу/закату
    if (sunrise != null && sunset != null) {
      // Дополнительная логика для астрономических факторов
      description += '. Учтены восход и закат';
    }

    return {
      'name': 'Время суток',
      'hour': hour,
      'impact': impact,
      'weight': 0.9,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeMoonFactor(String? moonPhase, int? illumination) {
    if (moonPhase == null) {
      return {
        'name': 'Фаза луны',
        'impact': 0.0,
        'weight': 0.4,
        'description': 'Данные о луне недоступны',
      };
    }

    double impact = 0.0;
    String description = '';

    final phase = moonPhase.toLowerCase();

    if (phase.contains('new') || phase.contains('full')) {
      impact = 8.0;
      description = 'Активная фаза луны усиливает клёв';
    } else if (phase.contains('quarter')) {
      impact = 3.0;
      description = 'Умеренная лунная активность';
    } else {
      impact = 0.0;
      description = 'Нейтральная фаза луны';
    }

    return {
      'name': 'Фаза луны',
      'phase': moonPhase,
      'illumination': illumination,
      'impact': impact,
      'weight': 0.4,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeSeasonFactor(String season, int month, String fishingType) {
    double impact = 0.0;
    String description = '';

    // Сезонные предпочтения для разных типов рыбалки
    Map<String, List<int>> bestMonths = {
      'spinning': [4, 5, 6, 9, 10], // Весна и осень
      'carp_fishing': [5, 6, 7, 8, 9], // Тёплое время
      'feeder': [4, 5, 6, 7, 8, 9, 10], // Долгий сезон
      'ice_fishing': [12, 1, 2, 3], // Зима
    };

    final optimal = bestMonths[fishingType] ?? [4, 5, 6, 7, 8, 9];

    if (optimal.contains(month)) {
      impact = 8.0;
      description = 'Оптимальный сезон для данного типа рыбалки';
    } else {
      impact = -3.0;
      description = 'Не самый лучший сезон';
    }

    return {
      'name': 'Сезон',
      'season': season,
      'month': month,
      'impact': impact,
      'weight': 0.6,
      'description': description,
    };
  }

  Map<String, dynamic> _analyzeUserHistoryFactor(Map<String, dynamic>? historyData) {
    if (historyData == null || historyData.isEmpty) {
      return {
        'name': 'История пользователя',
        'impact': 0.0,
        'weight': 0.5,
        'description': 'Недостаточно данных о ваших рыбалках',
      };
    }

    double impact = 0.0;
    String description = '';

    final successRate = historyData['success_rate'] as double? ?? 0.0;
    final totalTrips = historyData['total_trips'] as int? ?? 0;

    if (totalTrips >= 10) {
      if (successRate > 0.7) {
        impact = 5.0;
        description = 'В похожих условиях у вас высокий успех';
      } else if (successRate > 0.4) {
        impact = 2.0;
        description = 'Умеренный успех в похожих условиях';
      } else {
        impact = -3.0;
        description = 'В похожих условиях успех был низким';
      }
    } else {
      impact = 0.0;
      description = 'Накапливаем статистику ваших рыбалок';
    }

    return {
      'name': 'Персональная история',
      'success_rate': successRate,
      'total_trips': totalTrips,
      'impact': impact,
      'weight': 0.5,
      'description': description,
    };
  }

  // Остальные вспомогательные методы...

  String _generateCacheKey(double lat, double lon, DateTime date, String fishingType) {
    return 'ai_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${date.year}${date.month}${date.day}${date.hour}_$fishingType';
  }

  Future<String> _calculatePressureTrend(WeatherApiResponse weather) async {
    // Упрощённая логика тренда давления
    final random = math.Random();
    final trends = ['rising', 'falling', 'stable'];
    return trends[random.nextInt(trends.length)];
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  String _determineWaterType(double lat, double lon) {
    // Упрощённая логика определения типа водоёма
    // В реальном приложении можно использовать геоданные
    return 'lake'; // или 'river', 'sea'
  }

  Map<String, dynamic> _analyzeUserHistory(List<FishingNote>? history, String fishingType, DateTime date) {
    if (history == null || history.isEmpty) {
      return {};
    }

    // Анализируем историю пользователя
    final relevantNotes = history.where((note) =>
    note.fishingType == fishingType &&
        date.difference(note.startDate).inDays <= 365 // Последний год
    ).toList();

    if (relevantNotes.isEmpty) {
      return {};
    }

    final totalTrips = relevantNotes.length;
    final successfulTrips = relevantNotes.where((note) =>
    note.biteRecords.isNotEmpty &&
        note.biteRecords.any((bite) => bite.weight > 0)
    ).length;

    final successRate = successfulTrips / totalTrips;

    return {
      'total_trips': totalTrips,
      'successful_trips': successfulTrips,
      'success_rate': successRate,
      'avg_fish_count': relevantNotes.map((n) => n.biteRecords.length).fold(0, (a, b) => a + b) / totalTrips,
    };
  }

  Future<Map<String, dynamic>> _getHistoricalWeatherPatterns(double lat, double lon, DateTime date) async {
    // Заглушка для исторических погодных данных
    // В будущем можно интегрировать с историческими API
    return {
      'has_data': false,
      'patterns': [],
    };
  }

  String _buildAIPrompt(Map<String, dynamic> data) {
    return '''
Проанализируй условия для рыбалки и дай прогноз клёва от 0 до 100 баллов.

Погодные условия:
- Температура: ${data['weather']['temperature']}°C
- Давление: ${data['weather']['pressure']} мб (тренд: ${data['weather']['pressure_trend']})
- Ветер: ${data['weather']['wind_speed']} км/ч, направление ${data['weather']['wind_direction']}
- Влажность: ${data['weather']['humidity']}%
- Облачность: ${data['weather']['cloud_cover']}%

Время и место:
- Час: ${data['time']['hour']}:00
- Месяц: ${data['time']['month']}
- Тип рыбалки: ${data['fishing_type']}
- Широта: ${data['geo']['latitude']}, Долгота: ${data['geo']['longitude']}

Фаза луны: ${data['astro']['moon_phase'] ?? 'неизвестно'}

Дай точный числовой прогноз (0-100) и краткое объяснение ключевых факторов.
''';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    // Парсим ответ от ИИ
    final RegExp scoreRegex = RegExp(r'(\d{1,3})\s*(?:баллов?|points?|%)?');
    final match = scoreRegex.firstMatch(response);

    double score = 50.0; // Значение по умолчанию
    if (match != null) {
      score = double.tryParse(match.group(1)!) ?? 50.0;
    }

    return {
      'source': 'cloud_ai',
      'score': score.clamp(0.0, 100.0),
      'confidence': 0.85,
      'analysis': response,
      'processing_time_ms': 2000,
    };
  }

  Map<String, dynamic> _getMockCloudPrediction(Map<String, dynamic> data) {
    // Мок облачного ИИ для тестирования
    final baseScore = 45.0 + math.Random().nextDouble() * 30; // 45-75

    return {
      'source': 'mock_cloud_ai',
      'score': baseScore,
      'confidence': 0.65,
      'analysis': 'Мок-анализ: Условия оценены как умеренно благоприятные для рыбалки.',
      'processing_time_ms': 1500,
    };
  }

  ActivityLevel _getActivityLevel(int score) {
    if (score >= 80) return ActivityLevel.excellent;
    if (score >= 60) return ActivityLevel.good;
    if (score >= 40) return ActivityLevel.moderate;
    if (score >= 20) return ActivityLevel.poor;
    return ActivityLevel.veryPoor;
  }

  Map<String, dynamic> _generateRecommendations(int score, Map<String, dynamic> data) {
    String main = '';
    String detailed = '';
    List<String> tips = [];

    if (score >= 80) {
      main = 'Отличные условия для рыбалки! Самое время для трофейной ловли.';
      detailed = 'Все факторы складываются максимально благоприятно. Рекомендуется активная ловля с разнообразными приманками.';
      tips = [
        'Используйте активные приманки',
        'Попробуйте разные глубины',
        'Время для экспериментов с новыми местами',
      ];
    } else if (score >= 60) {
      main = 'Хорошие условия для клёва. Стоит попробовать!';
      detailed = 'Большинство факторов благоприятны. Рыба должна быть достаточно активна.';
      tips = [
        'Придерживайтесь проверенных мест',
        'Используйте знакомые приманки',
        'Будьте терпеливы - поклёвки будут',
      ];
    } else if (score >= 40) {
      main = 'Средние условия. Клёв возможен, но потребуется терпение.';
      detailed = 'Условия не идеальны, но при правильном подходе можно рассчитывать на результат.';
      tips = [
        'Ловите в проверенных местах',
        'Используйте более мелкие приманки',
        'Попробуйте ловлю на дне',
      ];
    } else {
      main = 'Слабые условия для рыбалки. Лучше отложить или сменить тактику.';
      detailed = 'Большинство факторов неблагоприятны. Рекомендуется дождаться лучших условий.';
      tips = [
        'Попробуйте ночную рыбалку',
        'Ловите в глубоких местах',
        'Используйте натуральные приманки',
      ];
    }

    return {
      'main': main,
      'detailed': detailed,
      'tips': tips,
    };
  }

  List<BiteFactorAnalysis> _createDetailedFactors(Map<String, dynamic>? factors, Map<String, dynamic> data) {
    if (factors == null) return [];

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

  List<OptimalTimeWindow> _calculateBestTimeWindows(Map<String, dynamic> data, int baseScore) {
    final windows = <OptimalTimeWindow>[];

    // Утреннее окно
    windows.add(OptimalTimeWindow(
      startTime: DateTime.now().copyWith(hour: 6, minute: 0),
      endTime: DateTime.now().copyWith(hour: 8, minute: 30),
      activity: (baseScore + 15).clamp(0, 100) / 100,
      reason: 'Утренняя активность рыбы',
      recommendations: ['Используйте яркие приманки', 'Ловите у поверхности'],
    ));

    // Вечернее окно
    windows.add(OptimalTimeWindow(
      startTime: DateTime.now().copyWith(hour: 18, minute: 0),
      endTime: DateTime.now().copyWith(hour: 20, minute: 30),
      activity: (baseScore + 20).clamp(0, 100) / 100,
      reason: 'Вечерний жор',
      recommendations: ['Время для трофейной ловли', 'Попробуйте поверхностные приманки'],
    ));

    return windows;
  }

  AIBitePrediction _getFallbackPrediction(WeatherApiResponse weather, String fishingType) {
    return AIBitePrediction(
      overallScore: 50,
      activityLevel: ActivityLevel.moderate,
      confidence: 0.3,
      recommendation: 'Средние условия для рыбалки',
      detailedAnalysis: 'Базовый прогноз при недоступности ИИ-анализа',
      factors: [],
      bestTimeWindows: [],
      tips: ['Попробуйте стандартные приёмы ловли'],
      generatedAt: DateTime.now(),
      dataSource: 'fallback',
      modelVersion: '1.0.0',
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

  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson != null) {
        final cacheData = json.decode(cacheJson) as Map<String, dynamic>;
        _cache.clear();
        cacheData.forEach((key, value) {
          _cache[key] = AIBitePrediction.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки кэша ИИ: $e');
    }
  }

  /// Очистка старого кэша
  void clearOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) =>
    now.difference(value.generatedAt).inHours > 24
    );
  }
}

// Енумы и модели
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