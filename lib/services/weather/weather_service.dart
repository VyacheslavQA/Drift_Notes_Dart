// Путь: lib/services/weather/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/fishing_note_model.dart';
import 'package:intl/intl.dart';

class WeatherService {
  final String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Получает данные о погоде для указанных координат
  Future<FishingWeather?> getWeatherForLocation(double latitude,
      double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl?latitude=$latitude&longitude=$longitude'
              '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,'
              'precipitation,rain,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m'
              '&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
              '&timezone=auto'
      ));

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

  // Парсинг данных о погоде из ответа API
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
      print('Ошибка при обработке данных погоды: $e');
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
          current['wind_direction_10m'] ?? 0);
      final windSpeed = current['wind_speed_10m'] ?? 0.0;
      final humidity = current['relative_humidity_2m'] ?? 0;
      final pressure = current['pressure_msl'] != null
          ? (current['pressure_msl'] / 1.333).toInt()
          : 0;
      final cloudCover = current['cloud_cover'] ?? 0;

      return '$weatherDesc, $temperature°C, ощущается как $feelsLike°C\n'
          'Ветер: $windDirection, $windSpeed м/с\n'
          'Влажность: $humidity%, Давление: $pressure мм рт.ст.\n'
          'Облачность: $cloudCover%';
    } catch (e) {
      return 'Ошибка при формировании описания погоды';
    }
  }

  // Получает описание погоды по коду
  String _getWeatherDescription(int code) {
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