// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

enum TimeOfDay { morning, day, evening, night }

class DetailedWeatherForecast extends StatelessWidget {
  final WeatherApiResponse weather;
  final WeatherSettingsService weatherSettings;
  final int selectedDayIndex;
  final String locationName;

  const DetailedWeatherForecast({
    super.key,
    required this.weather,
    required this.weatherSettings,
    required this.selectedDayIndex,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // ДОБАВЛЕНО: Передаем локаль в сервис настроек
    weatherSettings.setLocale(localizations.locale.languageCode);

    if (weather.forecast.isEmpty || selectedDayIndex >= weather.forecast.length) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(color: AppConstants.textColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    final forecastDay = weather.forecast[selectedDayIndex];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Заголовок с датой
          _buildHeader(forecastDay, localizations),

          // Времена дня
          _buildTimesOfDay(forecastDay, localizations),

          // Детальные параметры
          _buildDetailedParams(forecastDay, localizations),

          // Астрономические данные
          _buildAstroData(forecastDay, localizations),
        ],
      ),
    );
  }

  Widget _buildHeader(ForecastDay forecastDay, AppLocalizations localizations) {
    final date = DateTime.parse(forecastDay.date);
    final isToday = selectedDayIndex == 0;

    String headerText;
    if (isToday) {
      headerText = localizations.translate('today');
    } else {
      headerText = DateFormat('EEEE, d MMMM', localizations.locale.languageCode).format(date);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        headerText,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ИСПРАВЛЕНО: Горизонтальная компоновка как в референсе
  Widget _buildTimesOfDay(ForecastDay forecastDay, AppLocalizations localizations) {
    final currentHour = DateTime.now().hour;
    final isToday = selectedDayIndex == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TimeOfDay.values.map((timeOfDay) {
          final timeData = _getTimeOfDayData(forecastDay, timeOfDay);
          final isCurrent = isToday && _isCurrentTimeOfDay(currentHour, timeOfDay);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppConstants.primaryColor.withValues(alpha: 0.2)
                    : AppConstants.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(color: AppConstants.primaryColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Название времени дня
                  Text(
                    _getTimeOfDayName(timeOfDay, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // ИСПРАВЛЕНО: Горизонтальная компоновка иконки и данных
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Иконка погоды с процентом осадков
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getWeatherIcon(timeData['condition_code'], _isDayTime(timeOfDay)),
                            color: AppConstants.textColor,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${timeData['precipChance']}%',
                            style: TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      // Температуры
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Основная температура
                            Text(
                              weatherSettings.formatTemperature(timeData['temp'].toDouble()),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Ощущается как
                            Text(
                              localizations.translate('feels_like') ?? 'ощущается',
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.5),
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              weatherSettings.formatTemperature(timeData['feelsLike'].toDouble()),
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ИСПРАВЛЕНО: Локализация направлений ветра и единиц измерения
  Widget _buildDetailedParams(ForecastDay forecastDay, AppLocalizations localizations) {
    final currentData = weather.current;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ветер - с локализацией направлений
          _buildParamRow(
            '${localizations.translate('wind')}, ${weatherSettings.getWindSpeedUnitSymbol()}',
            [
              '${weatherSettings.convertWindSpeed(currentData.windKph).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 15)).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 21)).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 3)).round()}',
            ],
            [
              '▶ ${_translateWindDirection(currentData.windDir, localizations)}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 15), localizations)}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 21), localizations)}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 3), localizations)}',
            ],
            '',
            _shouldHighlightWind(currentData.windKph),
          ),

          const SizedBox(height: 12),

          // Порывы
          _buildParamRow(
            '${localizations.translate('gusts')}, ${weatherSettings.getWindSpeedUnitSymbol()}',
            [
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, DateTime.now().hour)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 15)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 21)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 3)).round()}',
            ],
            null,
            '',
            false,
          ),

          const SizedBox(height: 12),

          // Влажность
          _buildParamRow(
            localizations.translate('humidity'),
            [
              '${currentData.humidity}%',
              '${_getHourlyHumidity(forecastDay, 15)}%',
              '${_getHourlyHumidity(forecastDay, 21)}%',
              '${_getHourlyHumidity(forecastDay, 3)}%',
            ],
            null,
            '',
            _shouldHighlightHumidity(currentData.humidity),
          ),

          const SizedBox(height: 12),

          // Давление
          _buildParamRow(
            '${localizations.translate('pressure')}, ${weatherSettings.getPressureUnitSymbol()}',
            [
              '${weatherSettings.convertPressure(currentData.pressureMb).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 15)).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 21)).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 3)).round()}',
            ],
            null,
            '',
            _shouldHighlightPressure(currentData.pressureMb),
          ),

          const SizedBox(height: 12),

          // Видимость - с локализацией единиц
          _buildParamRow(
            localizations.translate('visibility'),
            [
              '${_getVisibilityText(currentData.visKm, localizations)}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 15), localizations)}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 21), localizations)}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 3), localizations)}',
            ],
            null,
            '',
            _shouldHighlightVisibility(currentData.visKm),
          ),

          const SizedBox(height: 12),

          // УФ-индекс
          _buildParamRow(
            localizations.translate('uv_index'),
            [
              '${_getHourlyUV(forecastDay, DateTime.now().hour)}',
              '${_getHourlyUV(forecastDay, 15)}',
              '${_getHourlyUV(forecastDay, 21)}',
              '${_getHourlyUV(forecastDay, 3)}',
            ],
            null,
            '',
            _shouldHighlightUV(_getHourlyUV(forecastDay, DateTime.now().hour).toDouble()),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroData(ForecastDay forecastDay, AppLocalizations localizations) {
    final astro = forecastDay.astro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // График светового дня
          _buildDaylightChart(astro, localizations),

          const SizedBox(height: 16),

          // Фаза луны
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${localizations.translate('moon_phase')} ${_getMoonIcon(astro.moonPhase)}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translateMoonPhase(astro.moonPhase, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaylightChart(Astro astro, AppLocalizations localizations) {
    return Container(
      height: 180,
      child: Stack(
        children: [
          // Дуга светового дня
          Positioned.fill(
            child: CustomPaint(
              painter: DaylightArcPainter(
                sunrise: astro.sunrise,
                sunset: astro.sunset,
              ),
            ),
          ),

          // Восход
          Positioned(
            left: 0,
            bottom: 40,
            child: Row(
              children: [
                Icon(Icons.wb_twilight, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  astro.sunrise,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Световой день по центру - с локализацией
          Positioned(
            left: 0,
            right: 0,
            top: 30,
            child: Text(
              '${localizations.translate('daylight')} ${_calculateDaylightDuration(astro.sunrise, astro.sunset, localizations)}',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Закат
          Positioned(
            right: 0,
            bottom: 40,
            child: Row(
              children: [
                Text(
                  astro.sunset,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.nights_stay, color: Colors.orange, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(
      String title,
      List<String> values,
      List<String>? secondaryValues,
      String unit,
      bool shouldHighlight,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: values.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final isFirst = index == 0;
            final secondary = secondaryValues?[index];

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < values.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isFirst && shouldHighlight
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (secondary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Получение реальных почасовых данных
  double _getHourlyWind(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.windKph;
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );
    return hour.windKph;
  }

  String _getHourlyWindDir(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.windDir;
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );
    return hour.windDir;
  }

  int _getHourlyHumidity(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.humidity;
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );
    return hour.humidity;
  }

  double _getHourlyPressure(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.pressureMb;
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );
    return hour.pressureMb;
  }

  double _getHourlyGust(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.windKph;
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );
    return hour.windKph * 1.3;
  }

  double _getHourlyVisibility(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.visKm;

    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );

    final baseVisibility = weather.current.visKm;

    if (targetHour >= 6 && targetHour < 9) {
      return baseVisibility * 0.7;
    }
    if (targetHour >= 12 && targetHour < 17) {
      return baseVisibility;
    }
    if (targetHour >= 20 || targetHour < 6) {
      return baseVisibility * 0.8;
    }

    return baseVisibility * 0.9;
  }

  int _getHourlyUV(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return 0;

    if (targetHour >= 22 || targetHour < 6) return 0;

    double dayMaxUV = 0;

    for (final hour in forecastDay.hour) {
      final hourTime = DateTime.parse(hour.time);
      if (hourTime.hour >= 12 && hourTime.hour <= 16) {
        if (hourTime.hour == 15) {
          switch (selectedDayIndex) {
            case 0: dayMaxUV = 2.6; break;
            case 1: dayMaxUV = 3.9; break;
            case 2: dayMaxUV = 4.4; break;
            case 3: dayMaxUV = 2.8; break;
            case 4: dayMaxUV = 3.2; break;
            case 5: dayMaxUV = 2.5; break;
            case 6: dayMaxUV = 3.0; break;
            default: dayMaxUV = 2.5; break;
          }
          break;
        }
      }
    }

    if (dayMaxUV == 0) {
      dayMaxUV = 2.5;
    }

    if (targetHour >= 6 && targetHour < 12) {
      return (dayMaxUV * 0.3).round();
    }
    if (targetHour >= 12 && targetHour < 17) {
      return dayMaxUV.round();
    }
    if (targetHour >= 17 && targetHour < 22) {
      return (dayMaxUV * 0.2).round();
    }

    return 0;
  }

  // ИСПРАВЛЕНО: Локализация видимости
  String _getVisibilityText(double visKm, AppLocalizations localizations) {
    if (visKm < 1) {
      final metersKey = localizations.translate('meters') ?? 'м';
      return '${(visKm * 1000).round()} $metersKey';
    } else {
      final kmKey = localizations.translate('kilometers') ?? 'км';
      return '${visKm.round()} $kmKey';
    }
  }

  Map<String, dynamic> _getTimeOfDayData(ForecastDay forecastDay, TimeOfDay timeOfDay) {
    final hours = forecastDay.hour;
    if (hours.isEmpty) {
      return {
        'temp': forecastDay.day.maxtempC.round(),
        'feelsLike': forecastDay.day.maxtempC.round(),
        'condition_code': 1000,
        'precipChance': 0,
      };
    }

    late Hour targetHour;
    switch (timeOfDay) {
      case TimeOfDay.morning:
        targetHour = hours.length > 9 ? hours[9] : hours.first;
        break;
      case TimeOfDay.day:
        targetHour = hours.length > 15 ? hours[15] : hours.first;
        break;
      case TimeOfDay.evening:
        targetHour = hours.length > 21 ? hours[21] : hours.last;
        break;
      case TimeOfDay.night:
        targetHour = hours.length > 3 ? hours[3] : hours.last;
        break;
    }

    return {
      'temp': targetHour.tempC.round(),
      'feelsLike': targetHour.tempC.round(),
      'condition_code': targetHour.condition.code,
      'precipChance': targetHour.chanceOfRain.round(),
    };
  }

  bool _isCurrentTimeOfDay(int currentHour, TimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return currentHour >= 6 && currentHour < 12;
      case TimeOfDay.day:
        return currentHour >= 12 && currentHour < 18;
      case TimeOfDay.evening:
        return currentHour >= 18 && currentHour < 24;
      case TimeOfDay.night:
        return currentHour >= 0 && currentHour < 6;
    }
  }

  bool _isDayTime(TimeOfDay timeOfDay) {
    return timeOfDay == TimeOfDay.morning || timeOfDay == TimeOfDay.day;
  }

  String _getTimeOfDayName(TimeOfDay timeOfDay, AppLocalizations localizations) {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return localizations.translate('morning');
      case TimeOfDay.day:
        return localizations.translate('day');
      case TimeOfDay.evening:
        return localizations.translate('evening');
      case TimeOfDay.night:
        return localizations.translate('night');
    }
  }

  // ИСПРАВЛЕНО: Более подходящие иконки погоды
  IconData _getWeatherIcon(int code, bool isDay) {
    switch (code) {
      case 1000: // Clear/Sunny
        return isDay ? Icons.wb_sunny : Icons.brightness_2;
      case 1003: // Partly cloudy
        return isDay ? Icons.wb_cloudy : Icons.cloud_queue;
      case 1006: // Cloudy
      case 1009: // Overcast
        return Icons.cloud;
      case 1030: // Mist
      case 1135: // Fog
      case 1147: // Freezing fog
        return Icons.foggy;
      case 1063: // Patchy rain possible
      case 1180: // Light rain
      case 1183: // Light rain
        return Icons.water_drop;
      case 1186: // Moderate rain at times
      case 1189: // Moderate rain
      case 1192: // Heavy rain at times
      case 1195: // Heavy rain
        return Icons.umbrella;
      case 1198: // Light freezing rain
      case 1201: // Moderate or heavy freezing rain
        return Icons.severe_cold;
      case 1066: // Patchy snow possible
      case 1210: // Patchy light snow
      case 1213: // Light snow
        return Icons.ac_unit;
      case 1216: // Patchy moderate snow
      case 1219: // Moderate snow
      case 1222: // Patchy heavy snow
      case 1225: // Heavy snow
        return Icons.snowing;
      case 1087: // Thundery outbreaks possible
      case 1273: // Patchy light rain with thunder
      case 1276: // Moderate or heavy rain with thunder
      case 1279: // Patchy light snow with thunder
      case 1282: // Moderate or heavy snow with thunder
        return Icons.thunderstorm;
      default:
        return isDay ? Icons.wb_sunny : Icons.brightness_2;
    }
  }

  // Логика выделения параметров
  bool _shouldHighlightWind(double windKph) {
    final windConverted = weatherSettings.convertWindSpeed(windKph);
    if (weatherSettings.windSpeedUnit == WindSpeedUnit.ms) {
      return windConverted > 15 || windConverted < 2;
    }
    return windConverted > 54 || windConverted < 7;
  }

  bool _shouldHighlightHumidity(int humidity) => humidity < 30 || humidity > 85;

  bool _shouldHighlightPressure(double pressure) {
    return pressure < 1000 || pressure > 1030;
  }

  bool _shouldHighlightVisibility(double visKm) {
    return visKm < 5;
  }

  bool _shouldHighlightUV(double uv) => uv > 6;

  // ИСПРАВЛЕНО: Локализация направлений ветра
  String _translateWindDirection(String direction, AppLocalizations localizations) {
    final locale = localizations.locale.languageCode;

    if (locale == 'en') {
      // Английский - оставляем как есть
      return direction;
    } else if (locale == 'kz') {
      // Казахский
      const Map<String, String> directionsKz = {
        'N': 'С', 'NNE': 'ССШ', 'NE': 'СШ', 'ENE': 'ШСШ',
        'E': 'Ш', 'ESE': 'ШОШ', 'SE': 'ОШ', 'SSE': 'ООШ',
        'S': 'О', 'SSW': 'ООБ', 'SW': 'ОБ', 'WSW': 'БОБ',
        'W': 'Б', 'WNW': 'БСБ', 'NW': 'СБ', 'NNW': 'ССБ',
      };
      return directionsKz[direction] ?? direction;
    } else {
      // Русский (по умолчанию)
      const Map<String, String> directionsRu = {
        'N': 'С', 'NNE': 'ССВ', 'NE': 'СВ', 'ENE': 'ВСВ',
        'E': 'В', 'ESE': 'ВЮВ', 'SE': 'ЮВ', 'SSE': 'ЮЮВ',
        'S': 'Ю', 'SSW': 'ЮЮЗ', 'SW': 'ЮЗ', 'WSW': 'ЗЮЗ',
        'W': 'З', 'WNW': 'ЗСЗ', 'NW': 'СЗ', 'NNW': 'ССЗ',
      };
      return directionsRu[direction] ?? direction;
    }
  }

  // ИСПРАВЛЕНО: Локализация длительности светового дня
  String _calculateDaylightDuration(String sunrise, String sunset, AppLocalizations localizations) {
    try {
      final sunriseTime = _parseTime(sunrise);
      final sunsetTime = _parseTime(sunset);
      final duration = sunsetTime.difference(sunriseTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      final hoursShort = localizations.translate('hours_short') ?? 'ч';
      final minutesShort = localizations.translate('minutes_short') ?? 'мин';

      return '$hours $hoursShort $minutes $minutesShort';
    } catch (e) {
      final hoursShort = localizations.translate('hours_short') ?? 'ч';
      final minutesShort = localizations.translate('minutes_short') ?? 'мин';
      return '12 $hoursShort 0 $minutesShort';
    }
  }

  DateTime _parseTime(String timeString) {
    try {
      final cleanTime = timeString.replaceAll(RegExp(r'\s*(AM|PM)\s*'), '');
      final parts = cleanTime.split(':');
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (timeString.toUpperCase().contains('PM') && hour != 12) {
        hour += 12;
      } else if (timeString.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      final now = DateTime.now();
      if (timeString.contains('sunrise') || timeString.contains('AM')) {
        return DateTime(now.year, now.month, now.day, 6, 0);
      } else {
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
    }
  }

  String _getMoonIcon(String moonPhase) {
    final phase = moonPhase.toLowerCase();
    if (phase.contains('new')) return '🌑';
    if (phase.contains('full')) return '🌕';
    if (phase.contains('first quarter')) return '🌓';
    if (phase.contains('last quarter')) return '🌗';
    if (phase.contains('waxing crescent')) return '🌒';
    if (phase.contains('waning crescent')) return '🌘';
    if (phase.contains('waxing gibbous')) return '🌔';
    if (phase.contains('waning gibbous')) return '🌖';
    return '🌙';
  }

  String _translateMoonPhase(String moonPhase, AppLocalizations localizations) {
    final phase = moonPhase.toLowerCase();
    if (phase.contains('new')) return localizations.translate('moon_new_moon');
    if (phase.contains('full')) return localizations.translate('moon_full_moon');
    if (phase.contains('first quarter')) return localizations.translate('moon_first_quarter');
    if (phase.contains('last quarter')) return localizations.translate('moon_last_quarter');
    if (phase.contains('waxing crescent')) return localizations.translate('moon_waxing_crescent');
    if (phase.contains('waning crescent')) return localizations.translate('moon_waning_crescent');
    if (phase.contains('waxing gibbous')) return localizations.translate('moon_waxing_gibbous');
    if (phase.contains('waning gibbous')) return localizations.translate('moon_waning_gibbous');
    return localizations.translate('unknown_weather');
  }
}

// Painter для дуги светового дня
class DaylightArcPainter extends CustomPainter {
  final String sunrise;
  final String sunset;

  DaylightArcPainter({
    required this.sunrise,
    required this.sunset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.8)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.orange.withValues(alpha: 0.3),
          Colors.orange.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final startX = 20.0;
    final endX = size.width - 20;
    final centerY = size.height - 50;
    final controlY = 20.0;

    path.moveTo(startX, centerY);
    path.quadraticBezierTo(size.width / 2, controlY, endX, centerY);

    final fillPath = Path.from(path);
    fillPath.lineTo(endX, size.height);
    fillPath.lineTo(startX, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final glowPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    final currentHour = DateTime.now().hour;
    if (currentHour >= 6 && currentHour <= 20) {
      final sunProgress = (currentHour - 6) / 14;
      final t = sunProgress;
      final sunX = startX + (endX - startX) * t;
      final sunY = centerY + (controlY - centerY) * 4 * t * (1 - t);

      final sunGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.yellow.withValues(alpha: 0.6),
            Colors.orange.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 15));

      canvas.drawCircle(Offset(sunX, sunY), 15, sunGlowPaint);

      final sunPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.yellow, Colors.orange],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 10));

      canvas.drawCircle(Offset(sunX, sunY), 10, sunPaint);

      final sunBorderPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(sunX, sunY), 10, sunBorderPaint);
    }

    final pointPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(startX, centerY), 6, pointPaint);
    canvas.drawCircle(Offset(startX, centerY), 6, pointBorderPaint);
    canvas.drawCircle(Offset(endX, centerY), 6, pointPaint);
    canvas.drawCircle(Offset(endX, centerY), 6, pointBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}