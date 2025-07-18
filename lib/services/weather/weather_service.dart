// Путь: lib/services/weather/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/fishing_note_model.dart';
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';
import '../../services/weather/weather_api_service.dart';

class WeatherService {
  final String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  BuildContext? _context;

  // Новый сервис WeatherAPI
  final WeatherApiService _weatherApiService = WeatherApiService();

  WeatherService([this._context]);

  // Получает данные о погоде для указанных координат используя WeatherAPI
  Future<FishingWeather?> getWeatherForLocation(
      double latitude,
      double longitude, [
        BuildContext? context,
      ]) async {
    if (context != null) _context = context;

    try {
      // Сначала попробуем получить прогноз с астрономическими данными
      final weatherData = await _weatherApiService.getForecast(
        latitude: latitude,
        longitude: longitude,
        days: 1, // Нужен только сегодняшний день для астрономии
      );

      // Конвертируем в FishingWeather для совместимости
      return WeatherApiService.convertToFishingWeather(weatherData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ WeatherAPI прогноз недоступен, пробуем текущую погоду: $e');
      }

      try {
        // Если прогноз не работает, используем текущую погоду
        final weatherData = await _weatherApiService.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        );

        return WeatherApiService.convertToFishingWeather(weatherData);
      } catch (e2) {
        // Если новый API не работает совсем, используем старый Open-Meteo как fallback
        if (kDebugMode) {
          debugPrint('⚠️ WeatherAPI полностью недоступен, используем Open-Meteo: $e2');
        }
        return _getWeatherFromOpenMeteo(latitude, longitude);
      }
    }
  }

  // Fallback метод для Open-Meteo API (оригинальный код)
  Future<FishingWeather?> _getWeatherFromOpenMeteo(
      double latitude,
      double longitude,
      ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?latitude=$latitude&longitude=$longitude'
              '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,'
              'precipitation,rain,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m'
              '&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
              '&timezone=auto',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        throw Exception('Ошибка запроса: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Парсинг данных о погоде из ответа API (оригинальный код)
  FishingWeather? _parseWeatherData(Map<String, dynamic> data) {
    try {
      final current = data['current'];
      final daily = data['daily'];

      // Получаем время восхода и заката из первого дня массива
      final sunrise = daily['sunrise'][0] as String? ?? '';
      final sunset = daily['sunset'][0] as String? ?? '';

      return FishingWeather(
        temperature: current['temperature_2m'] ?? 0.0,
        feelsLike: current['apparent_temperature'] ?? 0.0,
        humidity: current['relative_humidity_2m'] ?? 0,
        pressure: current['pressure_msl'] ?? 0.0,
        windSpeed: current['wind_speed_10m'] ?? 0.0,
        windDirection: _getWindDirection(current['wind_direction_10m'] ?? 0),
        weatherDescription: _generateWeatherDescription(current),
        cloudCover: current['cloud_cover'] ?? 0,
        moonPhase: 'Данные недоступны',
        observationTime: DateTime.now(),
        sunrise: _formatTimeFromIso(sunrise),
        sunset: _formatTimeFromIso(sunset),
        isDay: current['is_day'] == 1,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обработке данных погоды: $e');
      }
      return null;
    }
  }

  // Генерирует описание погоды на основе данных
  String _generateWeatherDescription(Map<String, dynamic> current) {
    try {
      final weatherCode = current['weather_code'] ?? 0;
      final weatherDesc = _getWeatherDescription(weatherCode);
      final temperature = (current['temperature_2m'] ?? 0.0).toInt();
      final feelsLike = (current['apparent_temperature'] ?? 0.0).toInt();
      final windDirection = _getWindDirection(
        current['wind_direction_10m'] ?? 0,
      );
      final windSpeed = current['wind_speed_10m'] ?? 0.0;
      final humidity = current['relative_humidity_2m'] ?? 0;
      final pressure =
      current['pressure_msl'] != null
          ? (current['pressure_msl'] / 1.333).toInt()
          : 0;
      final cloudCover = current['cloud_cover'] ?? 0;

      // Формируем описание в зависимости от языка
      if (_context != null &&
          AppLocalizations.of(_context!).locale.languageCode == 'en') {
        return '$weatherDesc, $temperature°C, feels like $feelsLike°C\n'
            'Wind: $windDirection, $windSpeed m/s\n'
            'Humidity: $humidity%, Pressure: $pressure mmHg\n'
            'Cloud cover: $cloudCover%';
      }

      return '$weatherDesc, $temperature°C, ощущается как $feelsLike°C\n'
          'Ветер: $windDirection, $windSpeed м/с\n'
          'Влажность: $humidity%, Давление: $pressure мм рт.ст.\n'
          'Облачность: $cloudCover%';
    } catch (e) {
      return _context != null &&
          AppLocalizations.of(_context!).locale.languageCode == 'en'
          ? 'Error generating weather description'
          : 'Ошибка при формировании описания погоды';
    }
  }

  // Получает описание погоды по коду
  String _getWeatherDescription(int code) {
    if (_context != null) {
      final localizations = AppLocalizations.of(_context!);
      switch (code) {
        case 0:
          return localizations.translate('weather_clear');
        case 1:
        case 2:
        case 3:
          return localizations.translate('weather_partly_cloudy');
        case 45:
        case 48:
          return localizations.translate('weather_mist');
        case 51:
        case 53:
        case 55:
          return localizations.translate('weather_light_drizzle');
        case 56:
        case 57:
          return localizations.translate('weather_freezing_drizzle');
        case 61:
        case 63:
        case 65:
          return localizations.translate('weather_light_rain');
        case 66:
        case 67:
          return localizations.translate('weather_light_freezing_rain');
        case 71:
        case 73:
        case 75:
          return localizations.translate('weather_light_snow');
        case 77:
          return localizations.translate('weather_ice_pellets');
        case 80:
        case 81:
        case 82:
          return localizations.translate('weather_light_rain_shower');
        case 85:
        case 86:
          return localizations.translate('weather_light_snow_showers');
        case 95:
          return localizations.translate('weather_thundery_outbreaks_possible');
        case 96:
        case 99:
          return localizations.translate('weather_thundery_outbreaks_possible');
        default:
          return localizations.translate('unknown_weather');
      }
    }

    // Fallback для русского
    switch (code) {
      case 0:
        return 'Ясно';
      case 1:
      case 2:
      case 3:
        return 'Переменная облачность';
      case 45:
      case 48:
        return 'Туман';
      case 51:
      case 53:
      case 55:
        return 'Морось';
      case 56:
      case 57:
        return 'Морось со снегом';
      case 61:
      case 63:
      case 65:
        return 'Дождь';
      case 66:
      case 67:
        return 'Ледяной дождь';
      case 71:
      case 73:
      case 75:
        return 'Снег';
      case 77:
        return 'Снежные зерна';
      case 80:
      case 81:
      case 82:
        return 'Ливень';
      case 85:
      case 86:
        return 'Снежный шквал';
      case 95:
        return 'Гроза';
      case 96:
      case 99:
        return 'Гроза с градом';
      default:
        return 'Неизвестно';
    }
  }

  // Получает направление ветра по градусам
  String _getWindDirection(int degrees) {
    if (_context != null) {
      final localizations = AppLocalizations.of(_context!);
      if (degrees >= 337.5 || degrees < 22.5)
        return localizations.translate('wind_n');
      if (degrees >= 22.5 && degrees < 67.5)
        return localizations.translate('wind_ne');
      if (degrees >= 67.5 && degrees < 112.5)
        return localizations.translate('wind_e');
      if (degrees >= 112.5 && degrees < 157.5)
        return localizations.translate('wind_se');
      if (degrees >= 157.5 && degrees < 202.5)
        return localizations.translate('wind_s');
      if (degrees >= 202.5 && degrees < 247.5)
        return localizations.translate('wind_sw');
      if (degrees >= 247.5 && degrees < 292.5)
        return localizations.translate('wind_w');
      if (degrees >= 292.5 && degrees < 337.5)
        return localizations.translate('wind_nw');
      return localizations.translate('unknown_direction');
    }

    // Fallback для русского
    if (degrees >= 337.5 || degrees < 22.5) return 'С';
    if (degrees >= 22.5 && degrees < 67.5) return 'СВ';
    if (degrees >= 67.5 && degrees < 112.5) return 'В';
    if (degrees >= 112.5 && degrees < 157.5) return 'ЮВ';
    if (degrees >= 157.5 && degrees < 202.5) return 'Ю';
    if (degrees >= 202.5 && degrees < 247.5) return 'ЮЗ';
    if (degrees >= 247.5 && degrees < 292.5) return 'З';
    if (degrees >= 292.5 && degrees < 337.5) return 'СЗ';
    return 'Неизвестно';
  }

  // форматирует время из ISO формата
  String _formatTimeFromIso(String isoTime) {
    try {
      if (isoTime.isEmpty) {
        return '';
      }

      final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm");
      final time = dateFormat.parse(isoTime);
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return '';
    }
  }
}