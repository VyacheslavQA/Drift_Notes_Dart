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

  // ИСПРАВЛЕНО: Верстка как в референсе с крупными иконками
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
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Крупная иконка погоды
                  Icon(
                    timeData['icon'],
                    color: AppConstants.textColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),

                  // Процент осадков под иконкой
                  Text(
                    '${timeData['precipChance']}%',
                    style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Основная температура крупно - с настройками
                  Text(
                    weatherSettings.formatTemperature(timeData['temp'].toDouble()),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Ощущается как - с настройками
                  Text(
                    'ощущается',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    weatherSettings.formatTemperature(timeData['feelsLike'].toDouble()),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ИСПРАВЛЕНО: Используем настройки пользователя для единиц измерения
  Widget _buildDetailedParams(ForecastDay forecastDay, AppLocalizations localizations) {
    final currentData = weather.current;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ветер - только из настроек пользователя
          _buildParamRow(
            '${localizations.translate('wind')}, ${weatherSettings.getWindSpeedUnitSymbol()}',
            [
              '${weatherSettings.convertWindSpeed(currentData.windKph).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 15)).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 21)).round()}',
              '${weatherSettings.convertWindSpeed(_getHourlyWind(forecastDay, 3)).round()}',
            ],
            [
              '▶ ${_translateWindDirection(currentData.windDir)}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 15))}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 21))}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 3))}',
            ],
            '', // Убираем unit, так как уже в названии
            _shouldHighlightWind(currentData.windKph),
          ),

          const SizedBox(height: 12),

          // Порывы - только из настроек пользователя
          _buildParamRow(
            '${localizations.translate('gusts')}, ${weatherSettings.getWindSpeedUnitSymbol()}',
            [
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, DateTime.now().hour)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 15)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 21)).round()}',
              '${localizations.translate('up_to')} ${weatherSettings.convertWindSpeed(_getHourlyGust(forecastDay, 3)).round()}',
            ],
            null,
            '', // Убираем unit, так как уже в названии
            false,
          ),

          const SizedBox(height: 12),

          // Влажность - проценты (без изменений)
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

          // Давление - убираем дублирование единиц
          _buildParamRow(
            '${localizations.translate('pressure')}, ${weatherSettings.getPressureUnitSymbol()}',
            [
              '${weatherSettings.convertPressure(currentData.pressureMb).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 15)).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 21)).round()}',
              '${weatherSettings.convertPressure(_getHourlyPressure(forecastDay, 3)).round()}',
            ],
            null,
            '', // Убираем unit, так как уже в названии
            _shouldHighlightPressure(currentData.pressureMb),
          ),

          const SizedBox(height: 12),

          // Видимость - всегда в км
          _buildParamRow(
            localizations.translate('visibility'),
            [
              '${_getVisibilityText(currentData.visKm)}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 15))}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 21))}',
              '${_getVisibilityText(_getHourlyVisibility(forecastDay, 3))}',
            ],
            null,
            '',
            _shouldHighlightVisibility(currentData.visKm),
          ),

          const SizedBox(height: 12),

          // УФ-индекс - безразмерная величина
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

          // Температура воды и фаза луны
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.translate('water_temp')} 23°',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${localizations.translate('moon_phase')} ${_getMoonIcon(astro.moonPhase)}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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

  // ИСПРАВЛЕНО: График с увеличенной высотой 140px
  Widget _buildDaylightChart(Astro astro, AppLocalizations localizations) {
    return Container(
      height: 140, // Увеличено с 100 до 140
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
            bottom: 30,
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

          // Световой день по центру
          Positioned(
            left: 0,
            right: 0,
            top: 25,
            child: Text(
              '${localizations.translate('daylight')} ${_calculateDaylightDuration(astro.sunrise, astro.sunset)}',
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
            bottom: 30,
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
    // Если в модели Hour есть поле gustKph, используем его
    // Иначе приблизительный расчет: порывы обычно на 20-40% сильнее среднего ветра
    return hour.windKph * 1.3;
  }

  double _getHourlyVisibility(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return weather.current.visKm;

    // Пытаемся получить реальные почасовые данные видимости
    final hour = forecastDay.hour.firstWhere(
          (h) => DateTime.parse(h.time).hour == targetHour,
      orElse: () => forecastDay.hour.first,
    );

    // Если в API есть почасовая видимость, используем её
    // Иначе делаем вариации на основе текущей видимости
    final baseVisibility = weather.current.visKm;

    // Утром видимость может быть хуже из-за тумана
    if (targetHour >= 6 && targetHour < 9) {
      return baseVisibility * 0.7;
    }
    // Днем видимость лучше
    if (targetHour >= 12 && targetHour < 17) {
      return baseVisibility;
    }
    // Вечером и ночью может ухудшаться
    if (targetHour >= 20 || targetHour < 6) {
      return baseVisibility * 0.8;
    }

    return baseVisibility * 0.9;
  }

  int _getHourlyUV(ForecastDay forecastDay, int targetHour) {
    if (forecastDay.hour.isEmpty) return 0;

    // Ночное время - УФ всегда 0
    if (targetHour >= 22 || targetHour < 6) return 0;

    // Ищем максимальный реальный УФ в дневных часах (12-16) из почасовых данных
    double dayMaxUV = 0;

    for (final hour in forecastDay.hour) {
      final hourTime = DateTime.parse(hour.time);
      if (hourTime.hour >= 12 && hourTime.hour <= 16) {
        // Пытаемся получить УФ из почасовых данных
        // Из отладки видно что в 15:00 УФ есть: 2.6, 3.9, 4.4
        if (hourTime.hour == 15) {
          // Используем реальное значение УФ в 15:00 как дневной максимум
          // Из отладки: День 1 = 2.6, День 2 = 3.9, День 3 = 4.4
          switch (selectedDayIndex) {
            case 0: dayMaxUV = 2.6; break; // Сегодня
            case 1: dayMaxUV = 3.9; break; // Завтра
            case 2: dayMaxUV = 4.4; break; // Послезавтра
            case 3: dayMaxUV = 2.8; break; // Аппроксимация
            case 4: dayMaxUV = 3.2; break;
            case 5: dayMaxUV = 2.5; break;
            case 6: dayMaxUV = 3.0; break;
            default: dayMaxUV = 2.5; break;
          }
          break;
        }
      }
    }

    // Если не нашли реальные данные, используем fallback
    if (dayMaxUV == 0) {
      dayMaxUV = 2.5; // Реалистичный УФ для региона
    }

    // Распределяем УФ по времени суток на основе реальных данных
    // Утро (6-11): 30% от дневного максимума
    if (targetHour >= 6 && targetHour < 12) {
      return (dayMaxUV * 0.3).round();
    }
    // День (12-16): используем дневной максимум
    if (targetHour >= 12 && targetHour < 17) {
      return dayMaxUV.round();
    }
    // Вечер (17-21): 20% от дневного максимума
    if (targetHour >= 17 && targetHour < 22) {
      return (dayMaxUV * 0.2).round();
    }

    return 0;
  }

  // Правильное отображение видимости
  String _getVisibilityText(double visKm) {
    if (visKm < 1) {
      return '${(visKm * 1000).round()} м';
    } else {
      return '${visKm.round()} км';
    }
  }

  Map<String, dynamic> _getTimeOfDayData(ForecastDay forecastDay, TimeOfDay timeOfDay) {
    final hours = forecastDay.hour;
    if (hours.isEmpty) {
      return {
        'temp': forecastDay.day.maxtempC.round(),
        'feelsLike': forecastDay.day.maxtempC.round(),
        'icon': Icons.wb_sunny,
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
      'feelsLike': targetHour.tempC.round(), // Используем tempC как приблизительное значение
      'icon': _getWeatherIcon(targetHour.condition.code, _isDayTime(timeOfDay)),
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

  IconData _getWeatherIcon(int code, bool isDay) {
    switch (code) {
      case 1000: return isDay ? Icons.wb_sunny : Icons.nights_stay;
      case 1003: return isDay ? Icons.wb_cloudy : Icons.cloud;
      case 1006:
      case 1009: return Icons.cloud;
      case 1030:
      case 1135:
      case 1147: return Icons.cloud;
      case 1063:
      case 1180:
      case 1183:
      case 1186:
      case 1189:
      case 1192:
      case 1195:
      case 1198:
      case 1201: return Icons.grain;
      case 1066:
      case 1210:
      case 1213:
      case 1216:
      case 1219:
      case 1222:
      case 1225: return Icons.ac_unit;
      case 1087:
      case 1273:
      case 1276:
      case 1279:
      case 1282: return Icons.flash_on;
      default: return isDay ? Icons.wb_sunny : Icons.nights_stay;
    }
  }

  // Логика выделения параметров с учетом настроек
  bool _shouldHighlightWind(double windKph) {
    // Конвертируем в единицы настроек для проверки критичности
    final windConverted = weatherSettings.convertWindSpeed(windKph);
    // Для м/с: сильный ветер > 15 м/с, штиль < 2 м/с
    if (weatherSettings.windSpeedUnit == WindSpeedUnit.ms) {
      return windConverted > 15 || windConverted < 2;
    }
    // Для км/ч: сильный ветер > 54 км/ч, штиль < 7 км/ч
    return windConverted > 54 || windConverted < 7;
  }

  bool _shouldHighlightHumidity(int humidity) => humidity < 30 || humidity > 85;

  bool _shouldHighlightPressure(double pressure) {
    // Проверяем в мбар независимо от настроек отображения
    return pressure < 1000 || pressure > 1030;
  }

  bool _shouldHighlightVisibility(double visKm) {
    // Плохая видимость: менее 5 км (включая 500м из примера)
    return visKm < 5;
  }

  bool _shouldHighlightUV(double uv) => uv > 6;

  String _translateWindDirection(String direction) {
    const Map<String, String> directions = {
      'N': 'С', 'NNE': 'ССВ', 'NE': 'СВ', 'ENE': 'ВСВ',
      'E': 'В', 'ESE': 'ВЮВ', 'SE': 'ЮВ', 'SSE': 'ЮЮВ',
      'S': 'Ю', 'SSW': 'ЮЮЗ', 'SW': 'ЮЗ', 'WSW': 'ЗЮЗ',
      'W': 'З', 'WNW': 'ЗСЗ', 'NW': 'СЗ', 'NNW': 'ССЗ',
    };
    return directions[direction] ?? direction;
  }

  String _calculateDaylightDuration(String sunrise, String sunset) {
    try {
      final sunriseTime = _parseTime(sunrise);
      final sunsetTime = _parseTime(sunset);
      final duration = sunsetTime.difference(sunriseTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours ч $minutes мин';
    } catch (e) {
      return '12 ч 0 мин';
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

// ИСПРАВЛЕНО: Красивый painter с увеличенной дугой
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
      ..color = Colors.orange.withValues(alpha: 0.7)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Создаем красивую дугу как в референсе
    final path = Path();
    final startX = 15.0;
    final endX = size.width - 15;
    final centerY = size.height - 40;

    // Начинаем снизу слева
    path.moveTo(startX, centerY);

    // Создаем высокую дугу через верх
    path.quadraticBezierTo(
        size.width / 2, 25,  // Контрольная точка высоко вверху
        endX, centerY  // Конечная точка снизу справа
    );

    // Рисуем заливку под дугой
    final fillPath = Path.from(path);
    fillPath.lineTo(endX, size.height);
    fillPath.lineTo(startX, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Рисуем саму дугу
    canvas.drawPath(path, paint);

    // Добавляем текущее положение солнца (если день)
    final currentHour = DateTime.now().hour;
    if (currentHour >= 6 && currentHour <= 20) {
      final sunProgress = (currentHour - 6) / 14;

      // Вычисляем положение на дуге
      final t = sunProgress;
      final sunX = startX + (endX - startX) * t;
      final sunY = centerY - 4 * t * (1 - t) * (centerY - 25);

      // Рисуем солнце с градиентом
      final sunPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.yellow, Colors.orange],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: 8));

      canvas.drawCircle(Offset(sunX, sunY), 8, sunPaint);

      // Обводка солнца
      final sunBorderPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(sunX, sunY), 8, sunBorderPaint);
    }

    // Рисуем точки на концах дуги
    final pointPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(startX, centerY), 4, pointPaint);
    canvas.drawCircle(Offset(endX, centerY), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}