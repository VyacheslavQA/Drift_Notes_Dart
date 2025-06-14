// Путь: lib/services/weather/weather_api_service.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../models/weather_api_model.dart';
import '../../models/fishing_note_model.dart';
import '../../config/api_keys.dart';
import '../../localization/app_localizations.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  // Используем API ключ из конфигурационного файла
  static String get _apiKey => ApiKeys.weatherApiKey;

  /// Проверка валидности API ключа
  bool get hasValidApiKey => ApiKeys.hasWeatherKey;

  /// Получение текущей погоды
  Future<WeatherApiResponse> getCurrentWeather({
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    if (!hasValidApiKey) {
      debugPrint(
        '❌ ${_getDebugText(context, 'weather_api_key_not_configured_debug')}',
      );
      debugPrint(
        '📝 ${_getDebugText(context, 'current_key')}: ${ApiKeys.getMaskedKey(_apiKey)}',
      );
      throw Exception(_getErrorText(context, 'weather_api_key_not_configured'));
    }

    try {
      final url =
          '$_baseUrl/current.json?key=$_apiKey&q=$latitude,$longitude&aqi=no';
      debugPrint(
        '🌤️ ${_getDebugText(context, 'current_weather_request')}: $latitude, $longitude',
      );

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '🌤️ ${_getDebugText(context, 'weather_api_response')}: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          '✅ ${_getDebugText(context, 'weather_received_successfully')}: ${data['location']['name']}',
        );
        return WeatherApiResponse.fromJson(data);
      } else {
        final errorBody = response.body;
        debugPrint(
          '❌ ${_getDebugText(context, 'weather_api_error')}: ${response.statusCode}',
        );
        debugPrint('❌ ${_getDebugText(context, 'error_body')}: $errorBody');

        if (response.statusCode == 401) {
          throw Exception(_getErrorText(context, 'weather_api_invalid_key'));
        } else if (response.statusCode == 403) {
          throw Exception(_getErrorText(context, 'weather_api_access_denied'));
        } else {
          throw Exception(
            'Weather API error: ${response.statusCode} - $errorBody',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '❌ ${_getDebugText(context, 'error_getting_current_weather')}: $e',
      );
      rethrow;
    }
  }

  /// Получение прогноза погоды
  Future<WeatherApiResponse> getForecast({
    required double latitude,
    required double longitude,
    required int days,
    BuildContext? context,
  }) async {
    if (!hasValidApiKey) {
      debugPrint(
        '❌ ${_getDebugText(context, 'weather_api_key_not_configured_debug')}',
      );
      debugPrint(
        '📝 ${_getDebugText(context, 'current_key')}: ${ApiKeys.getMaskedKey(_apiKey)}',
      );
      throw Exception(_getErrorText(context, 'weather_api_key_not_configured'));
    }

    try {
      // Ограничиваем количество дней для вашего плана (до 7 дней)
      final limitedDays = days > 7 ? 7 : days;

      final url =
          '$_baseUrl/forecast.json?key=$_apiKey&q=$latitude,$longitude&days=$limitedDays&aqi=no&alerts=no';
      debugPrint(
        '🌤️ ${_getDebugText(context, 'forecast_request')} $limitedDays ${_getDebugText(context, 'days_for_coordinates')}: $latitude, $longitude',
      );

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '🌤️ ${_getDebugText(context, 'weather_api_response')}: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          '✅ ${_getDebugText(context, 'forecast_received_successfully')}: ${data['forecast']['forecastday'].length} ${_getDebugText(context, 'days_received')}',
        );

        // ОТЛАДКА РЕАЛЬНЫХ ДАННЫХ ОТ API
        _debugApiData(data);

        return WeatherApiResponse.fromJson(data);
      } else {
        final errorBody = response.body;
        debugPrint(
          '❌ ${_getDebugText(context, 'weather_api_error')}: ${response.statusCode}',
        );
        debugPrint('❌ ${_getDebugText(context, 'error_body')}: $errorBody');

        if (response.statusCode == 401) {
          throw Exception(_getErrorText(context, 'weather_api_invalid_key'));
        } else if (response.statusCode == 403) {
          throw Exception(_getErrorText(context, 'weather_api_access_denied'));
        } else {
          throw Exception(
            'Weather API error: ${response.statusCode} - $errorBody',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ ${_getDebugText(context, 'error_getting_forecast')}: $e');
      rethrow;
    }
  }

  /// НОВЫЙ МЕТОД: Отладка данных от API
  void _debugApiData(Map<String, dynamic> data) {
    try {
      debugPrint('🔍 ===== ОТЛАДКА ДАННЫХ ОТ API =====');

      final current = data['current'];
      final forecast = data['forecast']['forecastday'];

      debugPrint('📍 Локация: ${data['location']['name']}, ${data['location']['region']}');
      debugPrint('🕐 Время: ${current['last_updated']}');

      debugPrint('🌡️ ТЕКУЩАЯ ТЕМПЕРАТУРА: ${current['temp_c']}°C');
      debugPrint('🌡️ ОЩУЩАЕТСЯ КАК: ${current['feelslike_c']}°C');
      debugPrint('💨 ВЕТЕР: ${current['wind_kph']} км/ч, направление: ${current['wind_dir']}');
      debugPrint('💧 ВЛАЖНОСТЬ: ${current['humidity']}%');
      debugPrint('📊 ДАВЛЕНИЕ: ${current['pressure_mb']} мб (${(current['pressure_mb'] * 0.75).round()} мм рт.ст.)');
      debugPrint('👁️ ВИДИМОСТЬ: ${current['vis_km']} км');
      debugPrint('☀️ УФ-ИНДЕКС: ${current['uv']}');
      debugPrint('☁️ ОБЛАЧНОСТЬ: ${current['cloud']}%');
      debugPrint('🌤️ УСЛОВИЯ: ${current['condition']['text']}');

      debugPrint('📅 ПРОГНОЗ НА ${forecast.length} ДНЕЙ:');
      for (int i = 0; i < forecast.length && i < 3; i++) {
        final day = forecast[i];
        final dayData = day['day'];
        final astro = day['astro'];

        debugPrint('📅 День ${i + 1} (${day['date']}):');
        debugPrint('   🌡️ Мин: ${dayData['mintemp_c']}°C, Макс: ${dayData['maxtemp_c']}°C');
        debugPrint('   💨 Макс ветер: ${dayData['maxwind_kph']} км/ч');
        debugPrint('   💧 Средняя влажность: ${dayData['avghumidity']}%');
        debugPrint('   ☀️ ДНЕВНОЙ УФ: ${dayData['uv'] ?? 'N/A'}');
        debugPrint('   🌅 Восход: ${astro['sunrise']}');
        debugPrint('   🌇 Закат: ${astro['sunset']}');
        debugPrint('   🌙 Фаза луны: ${astro['moon_phase']}');

        // Проверяем почасовые данные
        final hours = day['hour'] as List;
        if (hours.length >= 16) {
          final hour15 = hours[15]; // 15:00
          debugPrint('   🕒 В 15:00:');
          debugPrint('      🌡️ Температура: ${hour15['temp_c']}°C');
          debugPrint('      💨 Ветер: ${hour15['wind_kph']} км/ч, ${hour15['wind_dir']}');
          debugPrint('      💧 Влажность: ${hour15['humidity']}%');
          debugPrint('      📊 Давление: ${hour15['pressure_mb']} мб');
          debugPrint('      🌧️ Шанс дождя: ${hour15['chance_of_rain']}%');
          debugPrint('      ☀️ УФ в 15:00: ${hour15['uv'] ?? 'N/A'}');
        }
      }

      debugPrint('🔍 ===== КОНЕЦ ОТЛАДКИ =====');
    } catch (e) {
      debugPrint('❌ Ошибка отладки данных: $e');
    }
  }

  /// Получение исторических данных о погоде
  Future<WeatherApiResponse> getHistoricalWeather({
    required double latitude,
    required double longitude,
    required DateTime date,
    BuildContext? context,
  }) async {
    if (!hasValidApiKey) {
      debugPrint(
        '❌ ${_getDebugText(context, 'weather_api_key_not_configured_debug')}',
      );
      throw Exception(_getErrorText(context, 'weather_api_key_not_configured'));
    }

    try {
      // Форматируем дату в формате YYYY-MM-DD
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final url =
          '$_baseUrl/history.json?key=$_apiKey&q=$latitude,$longitude&dt=$dateString';
      debugPrint(
        '📅 Запрос исторических данных за $dateString для координат: $latitude, $longitude',
      );

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('📅 История погоды ответ: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Исторические данные получены за $dateString');
        return WeatherApiResponse.fromJson(data);
      } else {
        final errorBody = response.body;
        debugPrint('❌ Ошибка получения истории: ${response.statusCode}');
        debugPrint('❌ Тело ошибки: $errorBody');

        if (response.statusCode == 401) {
          throw Exception(_getErrorText(context, 'weather_api_invalid_key'));
        } else if (response.statusCode == 403) {
          throw Exception(_getErrorText(context, 'weather_api_access_denied'));
        } else {
          throw Exception(
            'Weather API History error: ${response.statusCode} - $errorBody',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения исторических данных: $e');
      rethrow;
    }
  }

  /// Получение расширенных данных о давлении (история + прогноз)
  Future<Map<String, dynamic>> getExtendedPressureData({
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    if (!hasValidApiKey) {
      throw Exception(_getErrorText(context, 'weather_api_key_not_set'));
    }

    try {
      debugPrint(
        '🔄 ${_getDebugText(context, 'getting_extended_pressure_data')}',
      );

      List<WeatherApiResponse> allData = [];
      final now = DateTime.now();

      // Получаем исторические данные за последние 7 дней
      debugPrint('📅 Загрузка исторических данных за 7 дней...');
      for (int i = 7; i >= 1; i--) {
        try {
          final historyDate = now.subtract(Duration(days: i));
          final historicalData = await getHistoricalWeather(
            latitude: latitude,
            longitude: longitude,
            date: historyDate,
            context: context,
          );
          allData.add(historicalData);

          // Небольшая задержка между запросами, чтобы не превышать лимиты API
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('⚠️ Не удалось получить данные за день -$i: $e');
          // Продолжаем даже если один из дней не загрузился
        }
      }

      // Получаем прогноз на 7 дней вперед
      debugPrint('🔮 Загрузка прогноза на 7 дней...');
      try {
        final forecast = await getForecast(
          latitude: latitude,
          longitude: longitude,
          days: 7,
          context: context,
        );
        allData.add(forecast);
      } catch (e) {
        debugPrint('⚠️ Не удалось получить прогноз: $e');
      }

      debugPrint(
        '✅ ${_getDebugText(context, 'extended_data_received')}: ${allData.length} источников данных',
      );

      return {
        'allData': allData,
        'historicalDays': allData.length - 1, // Количество исторических дней
        'hasForecast': allData.isNotEmpty,
      };
    } catch (e) {
      debugPrint(
        '❌ ${_getDebugText(context, 'error_getting_extended_data')}: $e',
      );
      rethrow;
    }
  }

  /// Конвертация в модель FishingWeather для совместимости
  static FishingWeather convertToFishingWeather(
      WeatherApiResponse weatherData, [
        BuildContext? context,
      ]) {
    try {
      final current = weatherData.current;
      final astro =
      weatherData.forecast.isNotEmpty
          ? weatherData.forecast.first.astro
          : null;

      return FishingWeather(
        temperature: current.tempC,
        feelsLike: current.feelslikeC,
        humidity: current.humidity,
        pressure: current.pressureMb,
        windSpeed: current.windKph,
        windDirection: _translateWindDirection(current.windDir),
        weatherDescription: _generateDescription(current, context),
        cloudCover: current.cloud,
        moonPhase: astro?.moonPhase ?? 'Unknown',
        observationTime: DateTime.now(),
        sunrise: astro?.sunrise ?? '',
        sunset: astro?.sunset ?? '',
        isDay: current.isDay == 1,
      );
    } catch (e) {
      debugPrint(
        '❌ ${_getDebugText(context, 'error_converting_weather_data')}: $e',
      );
      // Возвращаем данные по умолчанию
      return FishingWeather(
        temperature: 15.0,
        feelsLike: 15.0,
        humidity: 50,
        pressure: 1013.0,
        windSpeed: 5.0,
        windDirection: 'С',
        weatherDescription: _getErrorText(context, 'data_unavailable'),
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

  /// Генерация описания погоды с локализацией
  static String _generateDescription(Current current, [BuildContext? context]) {
    final temp = current.tempC.round();
    final feelsLike = current.feelslikeC.round();
    final wind = (current.windKph / 3.6).round();
    final humidity = current.humidity;
    final pressure = (current.pressureMb / 1.333).round();

    if (context != null) {
      final localizations = AppLocalizations.of(context);
      return '${current.condition.text}, $temp°C, ${localizations.translate('feels_like_short')} $feelsLike°C\n'
          '${localizations.translate('wind_short')}: ${_translateWindDirection(current.windDir)}, $wind м/с\n'
          '${localizations.translate('humidity_short')}: $humidity%, ${localizations.translate('pressure_short')}: $pressure мм рт.ст.\n'
          '${localizations.translate('cloudiness_short')}: ${current.cloud}%';
    } else {
      // Fallback для случаев без контекста
      return '${current.condition.text}, $temp°C, ощущается как $feelsLike°C\n'
          'Ветер: ${_translateWindDirection(current.windDir)}, $wind м/с\n'
          'Влажность: $humidity%, Давление: $pressure мм рт.ст.\n'
          'Облачность: ${current.cloud}%';
    }
  }

  /// Получение локализованного текста для ошибок
  static String _getErrorText(BuildContext? context, String key) {
    if (context != null) {
      return AppLocalizations.of(context).translate(key);
    }
    // Fallback на русский для случаев без контекста
    return _getRussianFallback(key);
  }

  /// Получение локализованного текста для debug сообщений
  static String _getDebugText(BuildContext? context, String key) {
    if (context != null) {
      return AppLocalizations.of(context).translate(key);
    }
    // Fallback на русский для случаев без контекста
    return _getRussianFallback(key);
  }

  /// Fallback переводы на русский язык
  static String _getRussianFallback(String key) {
    const Map<String, String> fallbacks = {
      'weather_api_key_not_configured':
      'WeatherAPI ключ не настроен. Замените "тут мой ключ" на реальный ключ в config/api_keys.dart',
      'weather_api_invalid_key':
      'Неверный API ключ WeatherAPI. Проверьте ключ в config/api_keys.dart',
      'weather_api_access_denied':
      'Доступ к WeatherAPI запрещен. Проверьте ваш план подписки',
      'weather_api_key_not_set': 'WeatherAPI ключ не настроен',
      'current_weather_request': 'Запрос текущей погоды для координат',
      'forecast_request': 'Запрос прогноза погоды на',
      'days_for_coordinates': 'дней для координат',
      'weather_api_response': 'Ответ Weather API',
      'weather_received_successfully': 'Погода успешно получена',
      'forecast_received_successfully': 'Прогноз погоды успешно получен',
      'days_received': 'дней',
      'getting_extended_pressure_data':
      'Получение расширенных данных о давлении...',
      'extended_data_received': 'Расширенные данные получены',
      'feels_like_short': 'ощущается как',
      'wind_short': 'Ветер',
      'humidity_short': 'Влажность',
      'pressure_short': 'Давление',
      'cloudiness_short': 'Облачность',
      'data_unavailable': 'Данные недоступны',
      'weather_api_key_not_configured_debug':
      'WeatherAPI ключ не настроен в config/api_keys.dart',
      'current_key': 'Текущий ключ',
      'weather_api_error': 'Ошибка Weather API',
      'error_body': 'Тело ошибки',
      'error_getting_current_weather': 'Ошибка получения текущей погоды',
      'error_getting_forecast': 'Ошибка получения прогноза погоды',
      'error_getting_extended_data': 'Ошибка получения расширенных данных',
      'error_converting_weather_data': 'Ошибка конвертации погодных данных',
    };
    return fallbacks[key] ?? key;
  }
}