// Путь: lib/services/weather/weather_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/weather_api_model.dart';
import '../../config/api_keys.dart';
import '../../utils/network_utils.dart';
import '../../models/fishing_note_model.dart';
import 'package:intl/intl.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  // Singleton pattern
  static final WeatherApiService _instance = WeatherApiService._internal();
  factory WeatherApiService() => _instance;
  WeatherApiService._internal();

  /// Получить текущую погоду по координатам
  Future<WeatherApiResponse> getCurrentWeather({
    required double latitude,
    required double longitude,
    bool includeAirQuality = false,
  }) async {
    // Проверяем подключение к интернету
    final isConnected = await NetworkUtils.isNetworkAvailable();
    if (!isConnected) {
      throw Exception('Нет подключения к интернету');
    }

    final query = '$latitude,$longitude';

    final uri = Uri.parse('$_baseUrl/current.json').replace(queryParameters: {
      'key': ApiKeys.weatherApiKey,
      'q': query,
      'aqi': includeAirQuality ? 'yes' : 'no',
      'lang': 'en', // Изменено с 'ru' на 'en'
    });

    try {
      debugPrint('🌤️ Запрос погоды: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8', // Добавлена кодировка
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🌤️ Статус ответа: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes)); // Исправлено декодирование
        debugPrint('✅ Погода получена успешно');

        return WeatherApiResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes)); // Исправлено декодирование
        final errorMessage = errorData['error']?['message'] ?? 'Неизвестная ошибка';
        throw Exception('Ошибка API: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении погоды: $e');
      rethrow;
    }
  }

  /// Получить прогноз погоды на несколько дней
  Future<WeatherApiResponse> getForecast({
    required double latitude,
    required double longitude,
    int days = 3,
    bool includeAirQuality = false,
    bool includeAlerts = false,
  }) async {
    // Проверяем подключение к интернету
    final isConnected = await NetworkUtils.isNetworkAvailable();
    if (!isConnected) {
      throw Exception('Нет подключения к интернету');
    }

    // Платный план поддерживает до 7 дней
    if (days > 7) {
      days = 7;
      debugPrint('⚠️ Ограничено до 7 дней для платного плана');
    }

    final query = '$latitude,$longitude';

    final uri = Uri.parse('$_baseUrl/forecast.json').replace(queryParameters: {
      'key': ApiKeys.weatherApiKey,
      'q': query,
      'days': days.toString(),
      'aqi': includeAirQuality ? 'yes' : 'no',
      'alerts': includeAlerts ? 'yes' : 'no',
      'lang': 'en', // Изменено с 'ru' на 'en'
    });

    try {
      debugPrint('🌤️ Запрос прогноза: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8', // Добавлена кодировка
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('🌤️ Статус ответа прогноза: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes)); // Исправлено декодирование
        debugPrint('✅ Прогноз получен успешно');

        return WeatherApiResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes)); // Исправлено декодирование
        final errorMessage = errorData['error']?['message'] ?? 'Неизвестная ошибка';
        throw Exception('Ошибка API: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении прогноза: $e');
      rethrow;
    }
  }

  /// Получить исторические данные о погоде
  Future<WeatherApiResponse> getHistoricalWeather({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    // Проверяем подключение к интернету
    final isConnected = await NetworkUtils.isNetworkAvailable();
    if (!isConnected) {
      throw Exception('Нет подключения к интернету');
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final query = '$latitude,$longitude';

    final uri = Uri.parse('$_baseUrl/history.json').replace(queryParameters: {
      'key': ApiKeys.weatherApiKey,
      'q': query,
      'dt': formattedDate,
      'lang': 'en',
    });

    try {
      debugPrint('🌤️ Запрос исторических данных: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('🌤️ Статус ответа исторических данных: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('✅ Исторические данные получены успешно');

        return WeatherApiResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['error']?['message'] ?? 'Неизвестная ошибка';
        throw Exception('Ошибка API: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении исторических данных: $e');
      rethrow;
    }
  }

  /// Получить расширенные данные: история + прогноз для анализа давления
  Future<Map<String, dynamic>> getExtendedPressureData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final List<WeatherApiResponse> allData = [];

      // Получаем данные за последние 2 дня
      for (int i = 2; i >= 1; i--) {
        try {
          final date = now.subtract(Duration(days: i));
          final historicalData = await getHistoricalWeather(
            latitude: latitude,
            longitude: longitude,
            date: date,
          );
          allData.add(historicalData);
        } catch (e) {
          debugPrint('⚠️ Не удалось получить данные за $i дней назад: $e');
        }
      }

      // Получаем прогноз на 7 дней
      final forecastData = await getForecast(
        latitude: latitude,
        longitude: longitude,
        days: 7,
      );
      allData.add(forecastData);

      return {
        'allData': allData,
        'currentWeather': forecastData,
      };
    } catch (e) {
      debugPrint('❌ Ошибка при получении расширенных данных о давлении: $e');
      rethrow;
    }
  }

  /// Конвертация данных WeatherAPI в модель FishingWeather для совместимости
  static FishingWeather convertToFishingWeather(WeatherApiResponse weatherData) {
    final current = weatherData.current;
    final location = weatherData.location;

    // Получаем астрономические данные из прогноза, если есть
    String sunrise = '';
    String sunset = '';

    if (weatherData.forecast.isNotEmpty) {
      final today = weatherData.forecast.first;
      sunrise = today.astro.sunrise;
      sunset = today.astro.sunset;
    }

    // Используем английские данные без перевода - переводом займутся UI компоненты
    return FishingWeather(
      temperature: current.tempC,
      feelsLike: current.feelslikeC,
      humidity: current.humidity,
      pressure: current.pressureMb,
      windSpeed: current.windKph / 3.6, // Конвертируем км/ч в м/с
      windDirection: current.windDir, // Оставляем английское обозначение (N, NE, E и т.д.)
      weatherDescription: current.condition.text, // Английское описание
      cloudCover: current.cloud,
      moonPhase: weatherData.forecast.isNotEmpty
          ? weatherData.forecast.first.astro.moonPhase // Английская фаза луны
          : 'No data available',
      observationTime: DateTime.now(),
      sunrise: sunrise,
      sunset: sunset,
      isDay: current.isDay == 1,
    );
  }
}