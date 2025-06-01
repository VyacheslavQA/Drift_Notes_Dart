// Путь: lib/services/weather/weather_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../models/weather_api_model.dart';
import '../../models/fishing_note_model.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const String _apiKey = 'your_api_key_here'; // Замените на реальный ключ

  /// Получение текущей погоды
  Future<WeatherApiResponse> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$latitude,$longitude&aqi=no'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherApiResponse.fromJson(data);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения текущей погоды: $e');
      rethrow;
    }
  }

  /// Получение прогноза погоды
  Future<WeatherApiResponse> getForecast({
    required double latitude,
    required double longitude,
    required int days,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$latitude,$longitude&days=$days&aqi=no&alerts=no'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherApiResponse.fromJson(data);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения прогноза погоды: $e');
      rethrow;
    }
  }

  /// Получение расширенных данных о давлении
  Future<Map<String, dynamic>> getExtendedPressureData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<WeatherApiResponse> allData = [];

      // Получаем данные за последние 3 дня + прогноз на 7 дней
      for (int i = -3; i <= 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        try {
          late http.Response response;

          if (i <= 0) {
            // Исторические данные
            response = await http.get(
              Uri.parse('$_baseUrl/history.json?key=$_apiKey&q=$latitude,$longitude&dt=$dateStr'),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            // Прогнозные данные
            response = await http.get(
              Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$latitude,$longitude&days=1&dt=$dateStr'),
              headers: {'Content-Type': 'application/json'},
            );
          }

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            allData.add(WeatherApiResponse.fromJson(data));
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка получения данных за $dateStr: $e');
          // Продолжаем с доступными данными
        }
      }

      return {'allData': allData};
    } catch (e) {
      debugPrint('❌ Ошибка получения расширенных данных: $e');
      rethrow;
    }
  }

  /// Конвертация в модель FishingWeather для совместимости
  static FishingWeather convertToFishingWeather(WeatherApiResponse weatherData) {
    try {
      final current = weatherData.current;
      final astro = weatherData.forecast.isNotEmpty
          ? weatherData.forecast.first.astro
          : null;

      return FishingWeather(
        temperature: current.tempC,
        feelsLike: current.feelslikeC,
        humidity: current.humidity,
        pressure: current.pressureMb,
        windSpeed: current.windKph,
        windDirection: _translateWindDirection(current.windDir),
        weatherDescription: _generateDescription(current),
        cloudCover: current.cloud,
        moonPhase: astro?.moonPhase ?? 'Unknown',
        observationTime: DateTime.now(),
        sunrise: astro?.sunrise ?? '',
        sunset: astro?.sunset ?? '',
        isDay: current.isDay == 1,
      );
    } catch (e) {
      debugPrint('❌ Ошибка конвертации погодных данных: $e');
      // Возвращаем данные по умолчанию
      return FishingWeather(
        temperature: 15.0,
        feelsLike: 15.0,
        humidity: 50,
        pressure: 1013.0,
        windSpeed: 5.0,
        windDirection: 'С',
        weatherDescription: 'Данные недоступны',
        cloudCover: 50,
        moonPhase: 'Unknown',
        observationTime: DateTime.now(),
        sunrise: '06:00',
        sunset: '18:00',
        isDay: true,
      );
    }
  }

  /// Перевод направления ветра
  static String _translateWindDirection(String direction) {
    const Map<String, String> directions = {
      'N': 'С',
      'NNE': 'ССВ',
      'NE': 'СВ',
      'ENE': 'ВСВ',
      'E': 'В',
      'ESE': 'ВЮВ',
      'SE': 'ЮВ',
      'SSE': 'ЮЮВ',
      'S': 'Ю',
      'SSW': 'ЮЮЗ',
      'SW': 'ЮЗ',
      'WSW': 'ЗЮЗ',
      'W': 'З',
      'WNW': 'ЗСЗ',
      'NW': 'СЗ',
      'NNW': 'ССЗ',
    };
    return directions[direction] ?? direction;
  }

  /// Генерация описания погоды
  static String _generateDescription(Current current) {
    final temp = current.tempC.round();
    final feelsLike = current.feelslikeC.round();
    final wind = (current.windKph / 3.6).round();
    final humidity = current.humidity;
    final pressure = (current.pressureMb / 1.333).round();

    return '${current.condition.text}, $temp°C, ощущается как $feelsLike°C\n'
        'Ветер: ${_translateWindDirection(current.windDir)}, $wind м/с\n'
        'Влажность: $humidity%, Давление: $pressure мм рт.ст.\n'
        'Облачность: ${current.cloud}%';
  }
}