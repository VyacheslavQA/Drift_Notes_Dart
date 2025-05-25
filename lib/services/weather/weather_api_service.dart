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

    // Переводим описание погоды
    final translatedDescription = _translateWeatherDescription(current.condition.text);

    return FishingWeather(
      temperature: current.tempC,
      feelsLike: current.feelslikeC,
      humidity: current.humidity,
      pressure: current.pressureMb,
      windSpeed: current.windKph / 3.6, // Конвертируем км/ч в м/с
      windDirection: _translateWindDirection(current.windDir),
      weatherDescription: translatedDescription,
      cloudCover: current.cloud,
      moonPhase: weatherData.forecast.isNotEmpty
          ? _translateMoonPhase(weatherData.forecast.first.astro.moonPhase)
          : 'Данные недоступны',
      observationTime: DateTime.now(),
      sunrise: sunrise,
      sunset: sunset,
      isDay: current.isDay == 1,
    );
  }

  /// Перевод описания погоды с английского на русский
  static String _translateWeatherDescription(String englishDescription) {
    final translations = {
      // Ясная погода
      'Sunny': 'Солнечно',
      'Clear': 'Ясно',

      // Облачность (все варианты регистра)
      'Partly cloudy': 'Переменная облачность',
      'Partly Cloudy': 'Переменная облачность',
      'PARTLY CLOUDY': 'Переменная облачность',
      'Cloudy': 'Облачно',
      'cloudy': 'Облачно',
      'CLOUDY': 'Облачно',
      'Overcast': 'Пасмурно',
      'overcast': 'Пасмурно',
      'OVERCAST': 'Пасмурно',

      // Туман
      'Mist': 'Дымка',
      'mist': 'Дымка',
      'Fog': 'Туман',
      'fog': 'Туман',
      'Freezing fog': 'Ледяной туман',
      'freezing fog': 'Ледяной туман',

      // Дождь - все варианты
      'Patchy rain possible': 'Местами дождь',
      'patchy rain possible': 'Местами дождь',
      'Patchy rain nearby': 'Местами дождь поблизости',
      'patchy rain nearby': 'Местами дождь поблизости',
      'Patchy light drizzle': 'Местами легкая морось',
      'patchy light drizzle': 'Местами легкая морось',
      'Light drizzle': 'Легкая морось',
      'light drizzle': 'Легкая морось',
      'Freezing drizzle': 'Ледяная морось',
      'freezing drizzle': 'Ледяная морось',
      'Heavy freezing drizzle': 'Сильная ледяная морось',
      'heavy freezing drizzle': 'Сильная ледяная морось',
      'Patchy light rain': 'Местами легкий дождь',
      'patchy light rain': 'Местами легкий дождь',
      'Light rain': 'Легкий дождь',
      'light rain': 'Легкий дождь',
      'Moderate rain at times': 'Временами умеренный дождь',
      'moderate rain at times': 'Временами умеренный дождь',
      'Moderate rain': 'Умеренный дождь',
      'moderate rain': 'Умеренный дождь',
      'Heavy rain at times': 'Временами сильный дождь',
      'heavy rain at times': 'Временами сильный дождь',
      'Heavy rain': 'Сильный дождь',
      'heavy rain': 'Сильный дождь',
      'Light freezing rain': 'Легкий ледяной дождь',
      'light freezing rain': 'Легкий ледяной дождь',
      'Moderate or heavy freezing rain': 'Умеренный или сильный ледяной дождь',
      'moderate or heavy freezing rain': 'Умеренный или сильный ледяной дождь',
      'Light showers of ice pellets': 'Легкий ледяной дождь',
      'light showers of ice pellets': 'Легкий ледяной дождь',
      'Moderate or heavy showers of ice pellets': 'Умеренный или сильный ледяной дождь',
      'moderate or heavy showers of ice pellets': 'Умеренный или сильный ледяной дождь',

      // Снег - все варианты
      'Patchy snow possible': 'Местами снег',
      'patchy snow possible': 'Местами снег',
      'Patchy snow nearby': 'Местами снег поблизости',
      'patchy snow nearby': 'Местами снег поблизости',
      'Patchy light snow': 'Местами легкий снег',
      'patchy light snow': 'Местами легкий снег',
      'Light snow': 'Легкий снег',
      'light snow': 'Легкий снег',
      'Patchy moderate snow': 'Местами умеренный снег',
      'patchy moderate snow': 'Местами умеренный снег',
      'Moderate snow': 'Умеренный снег',
      'moderate snow': 'Умеренный снег',
      'Patchy heavy snow': 'Местами сильный снег',
      'patchy heavy snow': 'Местами сильный снег',
      'Heavy snow': 'Сильный снег',
      'heavy snow': 'Сильный снег',
      'Ice pellets': 'Ледяная крупа',
      'ice pellets': 'Ледяная крупа',
      'Light snow showers': 'Легкие снежные ливни',
      'light snow showers': 'Легкие снежные ливни',
      'Moderate or heavy snow showers': 'Умеренные или сильные снежные ливни',
      'moderate or heavy snow showers': 'Умеренные или сильные снежные ливни',
      'Patchy light snow with thunder': 'Местами легкий снег с грозой',
      'patchy light snow with thunder': 'Местами легкий снег с грозой',
      'Moderate or heavy snow with thunder': 'Умеренный или сильный снег с грозой',
      'moderate or heavy snow with thunder': 'Умеренный или сильный снег с грозой',

      // Дождь с ливнями
      'Light rain shower': 'Легкий ливень',
      'light rain shower': 'Легкий ливень',
      'Moderate or heavy rain shower': 'Умеренный или сильный ливень',
      'moderate or heavy rain shower': 'Умеренный или сильный ливень',
      'Torrential rain shower': 'Проливной ливень',
      'torrential rain shower': 'Проливной ливень',

      // Гроза
      'Thundery outbreaks possible': 'Возможны грозы',
      'thundery outbreaks possible': 'Возможны грозы',
      'Patchy light rain with thunder': 'Местами легкий дождь с грозой',
      'patchy light rain with thunder': 'Местами легкий дождь с грозой',
      'Moderate or heavy rain with thunder': 'Умеренный или сильный дождь с грозой',
      'moderate or heavy rain with thunder': 'Умеренный или сильный дождь с грозой',

      // Град и мокрый снег
      'Patchy sleet possible': 'Местами мокрый снег',
      'patchy sleet possible': 'Местами мокрый снег',
      'Patchy sleet nearby': 'Местами мокрый снег поблизости',
      'patchy sleet nearby': 'Местами мокрый снег поблизости',
      'Light sleet': 'Легкий мокрый снег',
      'light sleet': 'Легкий мокрый снег',
      'Moderate or heavy sleet': 'Умеренный или сильный мокрый снег',
      'moderate or heavy sleet': 'Умеренный или сильный мокрый снег',
      'Light sleet showers': 'Легкие ливни с мокрым снегом',
      'light sleet showers': 'Легкие ливни с мокрым снегом',
      'Moderate or heavy sleet showers': 'Умеренные или сильные ливни с мокрым снегом',
      'moderate or heavy sleet showers': 'Умеренные или сильные ливни с мокрым снегом',

      // Другие условия
      'Blowing snow': 'Метель',
      'blowing snow': 'Метель',
      'Blizzard': 'Буран',
      'blizzard': 'Буран',

      // Дополнительные варианты
      'Fair': 'Ясно',
      'fair': 'ясно',
      'Hot': 'Жарко',
      'hot': 'жарко',
      'Cold': 'Холодно',
      'cold': 'холодно',
      'Windy': 'Ветрено',
      'windy': 'ветрено',
    };

    return translations[englishDescription] ?? englishDescription;
  }

  /// Перевод направления ветра
  static String _translateWindDirection(String windDir) {
    final translations = {
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

    return translations[windDir] ?? windDir;
  }

  /// Перевод фазы луны
  static String _translateMoonPhase(String moonPhase) {
    final translations = {
      'New Moon': 'Новолуние',
      'new moon': 'Новолуние',
      'Waxing Crescent': 'Растущая луна',
      'waxing crescent': 'Растущая луна',
      'First Quarter': 'Первая четверть',
      'first quarter': 'Первая четверть',
      'Waxing Gibbous': 'Растущая луна',
      'waxing gibbous': 'Растущая луна',
      'Full Moon': 'Полнолуние',
      'full moon': 'Полнолуние',
      'Waning Gibbous': 'Убывающая луна',
      'waning gibbous': 'Убывающая луна',
      'Last Quarter': 'Последняя четверть',
      'last quarter': 'Последняя четверть',
      'Third Quarter': 'Третья четверть',
      'third quarter': 'Третья четверть',
      'Waning Crescent': 'Убывающая луна',
      'waning crescent': 'Убывающая луна',
    };

    return translations[moonPhase] ?? moonPhase;
  }
}