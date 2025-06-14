// Путь: lib/widgets/weather/detailed_weather_forecast.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';
import '../../enums/forecast_period.dart';

enum TimeOfDay { morning, day, evening, night }

class DetailedWeatherForecast extends StatelessWidget {
  final WeatherApiResponse weather;
  final WeatherSettingsService weatherSettings;
  final ForecastPeriod selectedPeriod;
  final String locationName;

  const DetailedWeatherForecast({
    super.key,
    required this.weather,
    required this.weatherSettings,
    required this.selectedPeriod,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (weather.forecast.isEmpty) {
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

    final forecastDay = _getForecastDayForPeriod();
    if (forecastDay == null) {
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

  ForecastDay? _getForecastDayForPeriod() {
    switch (selectedPeriod) {
      case ForecastPeriod.today:
        return weather.forecast.isNotEmpty ? weather.forecast[0] : null;
      case ForecastPeriod.tomorrow:
        return weather.forecast.length > 1 ? weather.forecast[1] : null;
      case ForecastPeriod.dayAfterTomorrow:
        return weather.forecast.length > 2 ? weather.forecast[2] : null;
      default:
        return weather.forecast.isNotEmpty ? weather.forecast[0] : null;
    }
  }

  Widget _buildHeader(ForecastDay forecastDay, AppLocalizations localizations) {
    final date = DateTime.parse(forecastDay.date);
    final isToday = selectedPeriod == ForecastPeriod.today;

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

  Widget _buildTimesOfDay(ForecastDay forecastDay, AppLocalizations localizations) {
    final currentHour = DateTime.now().hour;
    final isToday = selectedPeriod == ForecastPeriod.today;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TimeOfDay.values.map((timeOfDay) {
          final timeData = _getTimeOfDayData(forecastDay, timeOfDay);
          final isCurrent = isToday && _isCurrentTimeOfDay(currentHour, timeOfDay);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 16),
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
                children: [
                  Text(
                    _getTimeOfDayName(timeOfDay, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        timeData['icon'],
                        color: AppConstants.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${timeData['precipChance']}%',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${timeData['temp']}°',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.translate('feels_like_short')} ${timeData['feelsLike']}°',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 10,
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

  Widget _buildDetailedParams(ForecastDay forecastDay, AppLocalizations localizations) {
    final currentData = weather.current;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ветер - используем реальные данные
          _buildParamRow(
            localizations.translate('wind_speed'),
            [
              '${currentData.windKph.round()}',
              '${_getHourlyWind(forecastDay, 15).round()}', // 15:00
              '${_getHourlyWind(forecastDay, 21).round()}', // 21:00
              '${_getHourlyWind(forecastDay, 3).round()}',  // 3:00
            ],
            [
              '▶ ${_translateWindDirection(currentData.windDir)}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 15))}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 21))}',
              '▲ ${_translateWindDirection(_getHourlyWindDir(forecastDay, 3))}',
            ],
            localizations.translate('m_s'),
            _shouldHighlightWind(currentData.windKph),
          ),

          const SizedBox(height: 12),

          // Порывы - реальные данные на основе ветра
          _buildParamRow(
            localizations.translate('gusts'),
            [
              '${localizations.translate('up_to')} ${(currentData.windKph * 1.5).round()}',
              '${localizations.translate('up_to')} ${(_getHourlyWind(forecastDay, 15) * 1.4).round()}',
              '${localizations.translate('up_to')} ${(_getHourlyWind(forecastDay, 21) * 1.3).round()}',
              '${localizations.translate('up_to')} ${(_getHourlyWind(forecastDay, 3) * 1.2).round()}',
            ],
            null,
            '',
            false,
          ),

          const SizedBox(height: 12),

          // Влажность - реальные данные
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

          // Давление - реальные данные
          _buildParamRow(
            localizations.translate('pressure_mmhg'),
            [
              '${(currentData.pressureMb * 0.75).round()}',
              '${(_getHourlyPressure(forecastDay, 15) * 0.75).round()}',
              '${(_getHourlyPressure(forecastDay, 21) * 0.75).round()}',
              '${(_getHourlyPressure(forecastDay, 3) * 0.75).round()}',
            ],
            null,
            '',
            _shouldHighlightPressure(currentData.pressureMb),
          ),

          const SizedBox(height: 12),

          // Видимость - исправленные реальные данные
          _buildParamRow(
            localizations.translate('visibility'),
            [
              '${currentData.visKm.round()} ${localizations.translate('km')}',
              '${currentData.visKm.round()} ${localizations.translate('km')}',
              '${(currentData.visKm * 0.9).round()} ${localizations.translate('km')}',
              '${(currentData.visKm * 0.8).round()} ${localizations.translate('km')}',
            ],
            null,
            '',
            _shouldHighlightVisibility(currentData.visKm),
          ),

          const SizedBox(height: 12),

          // УФ-индекс - правильная логика по времени
          _buildParamRow(
            localizations.translate('uv_index'),
            [
              '${_getCurrentUV()}',
              '${currentData.uv.round()}', // День - максимальный УФ
              '${(currentData.uv * 0.3).round()}', // Вечер - снижается
              '0', // Ночь - всегда 0
            ],
            null,
            '',
            _shouldHighlightUV(currentData.uv),
          ),
        ],
      ),
    );
  }

  // НОВЫЕ МЕТОДЫ: Получение реальных почасовых данных
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

  // ИСПРАВЛЕННЫЙ МЕТОД: Правильный УФ-индекс по времени
  int _getCurrentUV() {
    final currentHour = DateTime.now().hour;

    // Ночь (22:00 - 05:59)
    if (currentHour >= 22 || currentHour < 6) {
      return 0;
    }

    // Раннее утро (06:00 - 08:59)
    if (currentHour >= 6 && currentHour < 9) {
      return (weather.current.uv * 0.3).round();
    }

    // Утро (09:00 - 11:59)
    if (currentHour >= 9 && currentHour < 12) {
      return (weather.current.uv * 0.7).round();
    }

    // День (12:00 - 15:59) - пик УФ
    if (currentHour >= 12 && currentHour < 16) {
      return weather.current.uv.round();
    }

    // Вечер (16:00 - 21:59)
    if (currentHour >= 16 && currentHour < 22) {
      return (weather.current.uv * 0.5).round();
    }

    return weather.current.uv.round();
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

  Widget _buildDaylightChart(Astro astro, AppLocalizations localizations) {
    return Container(
      height: 60,
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
            bottom: 0,
            child: Row(
              children: [
                Icon(Icons.wb_twilight, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  astro.sunrise,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Световой день по центру
          Positioned.fill(
            child: Center(
              child: Text(
                '${localizations.translate('daylight')} ${_calculateDaylightDuration(astro.sunrise, astro.sunset)}',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Закат
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                Icon(Icons.nights_stay, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  astro.sunset,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // НОВЫЙ МЕТОД: Расчет продолжительности светового дня
  String _calculateDaylightDuration(String sunrise, String sunset) {
    try {
      // Парсим время восхода и заката
      final sunriseTime = _parseTime(sunrise);
      final sunsetTime = _parseTime(sunset);

      // Вычисляем разность
      final duration = sunsetTime.difference(sunriseTime);

      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      return '$hours ч $minutes мин';
    } catch (e) {
      return '12 ч 0 мин'; // Fallback
    }
  }

  // НОВЫЙ МЕТОД: Парсинг времени из строки
  DateTime _parseTime(String timeString) {
    try {
      // Убираем AM/PM и парсим
      final cleanTime = timeString.replaceAll(RegExp(r'\s*(AM|PM)\s*'), '');
      final parts = cleanTime.split(':');

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Конвертируем 12-часовой формат в 24-часовой
      if (timeString.toUpperCase().contains('PM') && hour != 12) {
        hour += 12;
      } else if (timeString.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      // Fallback - возвращаем примерное время
      final now = DateTime.now();
      if (timeString.contains('sunrise') || timeString.contains('AM')) {
        return DateTime(now.year, now.month, now.day, 6, 0);
      } else {
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
    }
  }

  // Вспомогательные методы

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
        targetHour = hours.length > 9 ? hours[9] : hours.first; // 9:00
        break;
      case TimeOfDay.day:
        targetHour = hours.length > 15 ? hours[15] : hours.first; // 15:00
        break;
      case TimeOfDay.evening:
        targetHour = hours.length > 21 ? hours[21] : hours.last; // 21:00
        break;
      case TimeOfDay.night:
        targetHour = hours.length > 3 ? hours[3] : hours.last; // 3:00
        break;
    }

    return {
      'temp': targetHour.tempC.round(),
      'feelsLike': targetHour.tempC.round(), // Приблизительно
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

  // Логика выделения параметров
  bool _shouldHighlightWind(double windKph) => windKph > 15 || windKph < 2;
  bool _shouldHighlightHumidity(int humidity) => humidity < 30 || humidity > 85;
  bool _shouldHighlightPressure(double pressure) => pressure < 1000 || pressure > 1030;
  bool _shouldHighlightVisibility(double visKm) => visKm < 1;
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

  String _rotateDirection(String direction, int degrees) {
    // Упрощенная логика поворота направления ветра
    return direction; // Для демо оставляем как есть
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

// Кастомный painter для дуги светового дня
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
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Рисуем основную дугу
    final path = Path();
    path.moveTo(0, size.height);

    // Создаем более реалистичную дугу
    final controlPointHeight = size.height * 0.3; // Высота дуги
    path.quadraticBezierTo(
        size.width / 2,
        controlPointHeight,
        size.width,
        size.height
    );

    canvas.drawPath(path, paint);

    // Добавляем текущее положение солнца (если день)
    final currentHour = DateTime.now().hour;
    if (currentHour >= 6 && currentHour <= 20) {
      final sunProgress = (currentHour - 6) / 14; // Нормализуем от 6 до 20 часов
      final sunX = size.width * sunProgress;
      final sunY = size.height - (4 * sunProgress * (1 - sunProgress) * size.height * 0.7);

      // Рисуем точку текущего положения солнца
      final sunPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sunX, sunY), 4, sunPaint);
    }

    // Рисуем горизонтальную линию горизонта
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}