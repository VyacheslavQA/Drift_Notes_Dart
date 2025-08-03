// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ОБНОВЛЕНО: Упрощен график светового дня - убраны анимации, сложные тени и эффекты

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
      child: Column(
        children: [
          // Основная карточка времен дня с заголовком внутри
          _buildMainWeatherCard(forecastDay, localizations),

          const SizedBox(height: 16),

          // Упрощенная временная линия светового дня
          _buildSimpleDaylightCard(context, forecastDay, localizations),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard(ForecastDay forecastDay, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppConstants.cardGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: [
          // Динамический заголовок с датой
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _getWeatherTitle(localizations, selectedDayIndex),
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Заголовки времен дня
          Row(
            children: [
              Expanded(child: _buildTimeHeader(localizations.translate('morning'))),
              Expanded(child: _buildTimeHeader(localizations.translate('day'))),
              Expanded(child: _buildTimeHeader(localizations.translate('evening'))),
              Expanded(child: _buildTimeHeader(localizations.translate('night'))),
            ],
          ),

          const SizedBox(height: 16),

          // Иконки и проценты осадков
          Row(
            children: TimeOfDay.values.map((timeOfDay) {
              final timeData = _getTimeOfDayData(forecastDay, timeOfDay);
              return Expanded(
                child: Column(
                  children: [
                    Icon(
                      _getWeatherIcon(timeData['condition_code'], _isDayTime(timeOfDay)),
                      color: AppConstants.textColor,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeData['precipChance']}%',
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Температуры
          Row(
            children: TimeOfDay.values.map((timeOfDay) {
              final timeData = _getTimeOfDayData(forecastDay, timeOfDay);
              return Expanded(
                child: Text(
                  weatherSettings.formatTemperature(timeData['temp'].toDouble()),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Ощущается
          Row(
            children: TimeOfDay.values.map((timeOfDay) {
              final timeData = _getTimeOfDayData(forecastDay, timeOfDay);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      localizations.translate('feels_like'),
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      weatherSettings.formatTemperature(timeData['feelsLike'].toDouble()),
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Упрощенная карточка светового дня
  Widget _buildSimpleDaylightCard(BuildContext context, ForecastDay forecastDay, AppLocalizations localizations) {
    final astro = forecastDay.astro;
    final sunrise = _parseAstroTimeWithTimezone(astro.sunrise);
    final sunset = _parseAstroTimeWithTimezone(astro.sunset);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppConstants.cardGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Text('🌅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                localizations.translate('daylight_hours'),
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Упрощенная временная линия
          SimpleDaylightTimeline(
            sunrise: sunrise,
            sunset: sunset,
            currentTime: selectedDayIndex == 0 ? DateTime.now() : null,
            localizations: localizations,
          ),
        ],
      ),
    );
  }

  // Метод для получения динамического заголовка
  String _getWeatherTitle(AppLocalizations localizations, int dayIndex) {
    switch (dayIndex) {
      case 0:
        return localizations.translate('weather_today');
      case 1:
        return localizations.translate('tomorrow_forecast');
      default:
      // Для других дней показываем дату
        final selectedDay = weather.forecast[dayIndex];
        final date = DateTime.parse(selectedDay.date);
        final formattedDate = _formatDate(date, localizations);
        return '${localizations.translate('forecast_for')} $formattedDate';
    }
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date, AppLocalizations localizations) {
    // Используем ключи месяцев в родительном падеже (для дат)
    final monthsGenitive = [
      localizations.translate('january_genitive'),
      localizations.translate('february_genitive'),
      localizations.translate('march_genitive'),
      localizations.translate('april_genitive'),
      localizations.translate('may_genitive'),
      localizations.translate('june_genitive'),
      localizations.translate('july_genitive'),
      localizations.translate('august_genitive'),
      localizations.translate('september_genitive'),
      localizations.translate('october_genitive'),
      localizations.translate('november_genitive'),
      localizations.translate('december_genitive'),
    ];

    return '${date.day} ${monthsGenitive[date.month - 1]}';
  }

  Widget _buildTimeHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Парсинг времени с учетом единого часового пояса Казахстана UTC+5
  DateTime _parseAstroTimeWithTimezone(String timeString) {
    try {
      // Убираем лишние пробелы и очищаем строку
      final cleanTimeString = timeString.trim();

      // Проверяем формат времени (12-часовой с AM/PM)
      final isAM = cleanTimeString.toUpperCase().contains('AM');
      final isPM = cleanTimeString.toUpperCase().contains('PM');

      // Извлекаем время без AM/PM
      String timeOnly = cleanTimeString.replaceAll(RegExp(r'\s*(AM|PM)\s*', caseSensitive: false), '');

      final parts = timeOnly.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeString');
      }

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Конвертация в 24-часовой формат
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      // Получаем целевую дату с учетом выбранного дня
      final now = DateTime.now();
      DateTime targetDate = now;

      // Для будущих дней добавляем дни
      if (selectedDayIndex > 0) {
        targetDate = now.add(Duration(days: selectedDayIndex));
      }

      // Weather API возвращает время в UTC+6 (Asia/Almaty)
      // Но в Казахстане с 2024 года единый часовой пояс UTC+5
      // Поэтому вычитаем 1 час от времени API
      final apiDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      final correctedDateTime = apiDateTime.subtract(const Duration(hours: 1));

      return correctedDateTime;

    } catch (e) {
      // Fallback времена при ошибке парсинга (с учетом UTC+5)
      final now = DateTime.now();
      DateTime targetDate = now;

      if (selectedDayIndex > 0) {
        targetDate = now.add(Duration(days: selectedDayIndex));
      }

      // Возвращаем приблизительные времена с учетом UTC+5
      if (timeString.toLowerCase().contains('sunrise') || timeString.toLowerCase().contains('am')) {
        return DateTime(targetDate.year, targetDate.month, targetDate.day, 5, 30);
      } else {
        return DateTime(targetDate.year, targetDate.month, targetDate.day, 17, 30);
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

  bool _isDayTime(TimeOfDay timeOfDay) {
    return timeOfDay == TimeOfDay.morning || timeOfDay == TimeOfDay.day;
  }

  IconData _getWeatherIcon(int code, bool isDay) {
    switch (code) {
      case 1000: return isDay ? Icons.wb_sunny : Icons.brightness_2;
      case 1003: return isDay ? Icons.wb_cloudy : Icons.cloud_queue;
      case 1006: case 1009: return Icons.cloud;
      case 1030: case 1135: case 1147: return Icons.foggy;
      case 1063: case 1180: case 1183: return Icons.water_drop;
      case 1186: case 1189: case 1192: case 1195: return Icons.umbrella;
      case 1087: case 1273: case 1276: return Icons.thunderstorm;
      default: return isDay ? Icons.wb_sunny : Icons.brightness_2;
    }
  }
}

// Упрощенная временная линия светового дня (StatelessWidget)
class SimpleDaylightTimeline extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime? currentTime;
  final AppLocalizations localizations;

  const SimpleDaylightTimeline({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.localizations,
    this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Простая временная линия
        _buildSimpleTimeline(context),
        const SizedBox(height: 20),
        // Информация о времени
        _buildTimeInfo(context),
        const SizedBox(height: 16),
        // Простая дополнительная информация
        _buildSimpleInfo(context),
      ],
    );
  }

  Widget _buildSimpleTimeline(BuildContext context) {
    return SizedBox(
      height: 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timelineWidth = constraints.maxWidth;
          final currentPosition = _getCurrentPosition();

          return Stack(
            children: [
              // Простая линия без градиента
              Positioned(
                left: 0,
                right: 0,
                top: 25,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4a4a6a),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Простой маркер текущего времени (только эмодзи)
              if (currentTime != null)
                Positioned(
                  left: (timelineWidth * currentPosition) - 12,
                  top: 13,
                  child: const Text(
                    '☀️',
                    style: TextStyle(fontSize: 24),
                  ),
                ),

              // Простые метки времени - точно над позициями на линии
              Positioned(
                left: (timelineWidth * 0.2) - 25,
                top: 0,
                child: Text(
                  localizations.translate('sunrise'),
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Positioned(
                left: (timelineWidth * 0.8) - 25,
                top: 0,
                child: Text(
                  localizations.translate('sunset'),
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    final phaseInfo = _getCurrentPhaseInfo();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Восход
        _buildTimeCard(
          icon: '🌅',
          time: DateFormat('HH:mm').format(sunrise),
          label: localizations.translate('sunrise'),
        ),

        // Текущая фаза (только если показываем текущее время)
        if (currentTime != null)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${phaseInfo.icon} ${phaseInfo.phase}',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phaseInfo.timeLeft,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Закат
        _buildTimeCard(
          icon: '🌇',
          time: DateFormat('HH:mm').format(sunset),
          label: localizations.translate('sunset'),
        ),
      ],
    );
  }

  Widget _buildTimeCard({
    required String icon,
    required String time,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          '$icon $time',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: '⏱️',
            value: _getDaylightDuration(),
            label: localizations.translate('daylight_duration'),
          ),
          Container(
            width: 1,
            height: 30,
            color: AppConstants.textColor.withValues(alpha: 0.2),
          ),
          _buildStatCard(
            icon: '🕐',
            value: DateFormat('HH:mm').format(currentTime ?? DateTime.now()),
            label: localizations.translate('current_time'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Вычисление текущей позиции маркера на временной линии (0.0 - 1.0)
  double _getCurrentPosition() {
    final current = currentTime;
    if (current == null) return 0.5;

    // Если до восхода - позиция в начале
    if (current.isBefore(sunrise)) {
      return 0.2; // 20% от начала линии
    }

    // Если после заката - позиция в конце
    if (current.isAfter(sunset)) {
      return 0.8; // 80% от начала линии
    }

    // Во время светового дня - пропорциональная позиция
    final totalDaylight = sunset.difference(sunrise).inMinutes;
    final currentProgress = current.difference(sunrise).inMinutes;

    // Маппим от восхода (20%) до заката (80%)
    final position = 0.2 + (currentProgress / totalDaylight) * 0.6;
    return position.clamp(0.2, 0.8);
  }

  // Получение информации о текущей фазе дня
  ({String phase, String timeLeft, String icon}) _getCurrentPhaseInfo() {
    final current = currentTime;
    if (current == null) {
      return (
      phase: localizations.translate('day'),
      timeLeft: '',
      icon: '☀️'
      );
    }

    if (current.isBefore(sunrise)) {
      final timeUntilSunrise = sunrise.difference(current);
      return (
      phase: localizations.translate('night'),
      timeLeft: '${localizations.translate('until_sunrise')}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else if (current.isAfter(sunset)) {
      final timeUntilSunrise = sunrise.add(const Duration(days: 1)).difference(current);
      return (
      phase: localizations.translate('night'),
      timeLeft: '${localizations.translate('until_sunrise')}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else {
      final timeUntilSunset = sunset.difference(current);
      return (
      phase: localizations.translate('day'),
      timeLeft: '${localizations.translate('until_sunset')}: ${_formatDuration(timeUntilSunset)}',
      icon: '☀️'
      );
    }
  }

  // Форматирование длительности в читаемый вид с локализацией
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final locale = localizations.locale.languageCode;

    if (locale == 'ru') {
      if (hours > 0) {
        return '${hours}ч ${minutes}мин';
      } else {
        return '${minutes}мин';
      }
    } else if (locale == 'kk') {
      if (hours > 0) {
        return '${hours}с ${minutes}мин';
      } else {
        return '${minutes}мин';
      }
    } else {
      // Английский и другие языки
      if (hours > 0) {
        return '${hours}h ${minutes}min';
      } else {
        return '${minutes}min';
      }
    }
  }

  // Получение продолжительности светового дня
  String _getDaylightDuration() {
    final duration = sunset.difference(sunrise);
    return _formatDuration(duration);
  }
}