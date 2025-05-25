// Путь: lib/services/weather/weather_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/weather_api_model.dart';
import '../../config/api_keys.dart';
import '../../utils/network_utils.dart';
import '../../models/fishing_note_model.dart';

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
      'lang': 'ru', // Русский язык для описаний
    });

    try {
      debugPrint('🌤️ Запрос погоды: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🌤️ Статус ответа: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint('✅ Погода получена успешно');

        return WeatherApiResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
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

    // Бесплатный план поддерживает до 3 дней
    if (days > 3) {
      days = 3;
      debugPrint('⚠️ Ограничено до 3 дней для бесплатного плана');
    }

    final query = '$latitude,$longitude';

    final uri = Uri.parse('$_baseUrl/forecast.json').replace(queryParameters: {
      'key': ApiKeys.weatherApiKey,
      'q': query,
      'days': days.toString(),
      'aqi': includeAirQuality ? 'yes' : 'no',
      'alerts': includeAlerts ? 'yes' : 'no',
      'lang': 'ru',
    });

    try {
      debugPrint('🌤️ Запрос прогноза: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('🌤️ Статус ответа прогноза: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint('✅ Прогноз получен успешно');

        return WeatherApiResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Неизвестная ошибка';
        throw Exception('Ошибка API: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении прогноза: $e');
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

    return FishingWeather(
      temperature: current.tempC,
      feelsLike: current.feelslikeC,
      humidity: current.humidity,
      pressure: current.pressureMb,
      windSpeed: current.windKph / 3.6, // Конвертируем км/ч в м/с
      windDirection: current.windDir,
      weatherDescription: current.condition.text,
      cloudCover: current.cloud,
      moonPhase: weatherData.forecast.isNotEmpty
          ? weatherData.forecast.first.astro.moonPhase
          : 'Данные недоступны',
      observationTime: DateTime.now(),
      sunrise: sunrise,
      sunset: sunset,
      isDay: current.isDay == 1,
    );
  }
}