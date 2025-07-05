// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ИСПРАВЛЕНО: График светового дня, расчет длительности и локализация

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
          localizations.translate('no_data_to_display') ?? 'Нет данных для отображения',
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
          // Основная карточка времен дня
          _buildMainWeatherCard(forecastDay, localizations),

          const SizedBox(height: 16),

          // Карточка ветра и метрик
          _buildWindMetricsCard(forecastDay, localizations),

          const SizedBox(height: 16),

          // ИСПРАВЛЕННАЯ временная линия светового дня
          _buildDaylightTimelineCard(context, forecastDay, localizations),
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
          // Заголовки времен дня
          Row(
            children: [
              Expanded(child: _buildTimeHeader(localizations.translate('morning') ?? 'Утро')),
              Expanded(child: _buildTimeHeader(localizations.translate('day') ?? 'День')),
              Expanded(child: _buildTimeHeader(localizations.translate('evening') ?? 'Вечер')),
              Expanded(child: _buildTimeHeader(localizations.translate('night') ?? 'Ночь')),
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
                      localizations.translate('feels_like') ?? 'Ощущается',
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

  Widget _buildWindMetricsCard(ForecastDay forecastDay, AppLocalizations localizations) {
    // Берем данные полудня для выбранного дня (или первый доступный час)
    final middayHour = forecastDay.hour.length > 12 ? forecastDay.hour[12] : forecastDay.hour.first;

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Строка ветра, влажности и давления (3 колонки)
          Row(
            children: [
              // Ветер
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, color: AppConstants.secondaryTextColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${weatherSettings.convertWindSpeed(middayHour.windKph).round()} ${weatherSettings.getWindSpeedUnitSymbol()}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_translateWindDirection(middayHour.windDir, localizations)}',
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Влажность
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop, color: AppConstants.secondaryTextColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${middayHour.humidity}%',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.translate('humidity') ?? 'Влажность',
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Давление
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speed, color: AppConstants.secondaryTextColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${weatherSettings.convertPressure(middayHour.pressureMb).round()}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weatherSettings.getPressureUnitSymbol(),
                      style: TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Временная линия светового дня
  Widget _buildDaylightTimelineCard(BuildContext context, ForecastDay forecastDay, AppLocalizations localizations) {
    final astro = forecastDay.astro;

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
              Text(
                '🌅',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('daylight_hours') ?? 'Daylight Hours',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ИСПРАВЛЕННАЯ временная линия
          DaylightTimelineWidget(
            sunrise: _parseAstroTime(astro.sunrise),
            sunset: _parseAstroTime(astro.sunset),
            currentTime: selectedDayIndex == 0 ? DateTime.now() : null,
            enableAnimation: true,
            showDetailedInfo: MediaQuery.of(context).size.width > 600,
            localizations: localizations, // Передаем локализацию
          ),
        ],
      ),
    );
  }

  // ИСПРАВЛЕННЫЙ парсинг времени из API в DateTime
  DateTime _parseAstroTime(String timeString) {
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

      final now = DateTime.now();
      DateTime targetDate = now;

      // Для будущих дней добавляем дни
      if (selectedDayIndex > 0) {
        targetDate = now.add(Duration(days: selectedDayIndex));
      }

      return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
    } catch (e) {
      // Fallback времена при ошибке парсинга
      final now = DateTime.now();
      DateTime targetDate = now;

      if (selectedDayIndex > 0) {
        targetDate = now.add(Duration(days: selectedDayIndex));
      }

      // Возвращаем приблизительные времена
      if (timeString.toLowerCase().contains('sunrise') || timeString.toLowerCase().contains('am')) {
        return DateTime(targetDate.year, targetDate.month, targetDate.day, 6, 30);
      } else {
        return DateTime(targetDate.year, targetDate.month, targetDate.day, 18, 30);
      }
    }
  }

  // Вспомогательные методы (ВОССТАНОВЛЕНЫ все методы)
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

  String _translateWindDirection(String direction, AppLocalizations localizations) {
    final locale = localizations.locale.languageCode;

    if (locale == 'ru') {
      const Map<String, String> directionsRu = {
        'N': 'С', 'NNE': 'ССВ', 'NE': 'СВ', 'ENE': 'ВСВ',
        'E': 'В', 'ESE': 'ВЮВ', 'SE': 'ЮВ', 'SSE': 'ЮЮВ',
        'S': 'Ю', 'SSW': 'ЮЮЗ', 'SW': 'ЮЗ', 'WSW': 'ЗЮЗ',
        'W': 'З', 'WNW': 'ЗСЗ', 'NW': 'СЗ', 'NNW': 'ССЗ',
      };
      return directionsRu[direction] ?? direction;
    }

    return direction; // Для английского и казахского возвращаем как есть
  }
}

// ИСПРАВЛЕННЫЙ ВИДЖЕТ: Временная линия светового дня
class DaylightTimelineWidget extends StatefulWidget {
  /// Время восхода солнца
  final DateTime sunrise;

  /// Время заката солнца
  final DateTime sunset;

  /// Текущее время (по умолчанию - сейчас)
  final DateTime? currentTime;

  /// Показывать ли анимацию
  final bool enableAnimation;

  /// Кастомная высота виджета
  final double? height;

  /// Показывать ли подробную информацию
  final bool showDetailedInfo;

  /// Локализация для правильного форматирования
  final AppLocalizations localizations;

  const DaylightTimelineWidget({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.localizations,
    this.currentTime,
    this.enableAnimation = true,
    this.height,
    this.showDetailedInfo = true,
  });

  @override
  State<DaylightTimelineWidget> createState() => _DaylightTimelineWidgetState();
}

class _DaylightTimelineWidgetState extends State<DaylightTimelineWidget>
    with TickerProviderStateMixin {
  late AnimationController _markerController;
  late AnimationController _fadeController;
  late Animation<double> _markerAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _markerController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _markerAnimation = Tween<double>(
      begin: _getCurrentPosition(),
      end: _getCurrentPosition() + 0.05, // Небольшое движение для анимации
    ).animate(CurvedAnimation(
      parent: _markerController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    if (widget.enableAnimation) {
      _fadeController.forward();
      _markerController.repeat(reverse: true);
    } else {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _markerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Вычисление текущей позиции маркера на временной линии (0.0 - 1.0)
  double _getCurrentPosition() {
    final currentTime = widget.currentTime ?? DateTime.now();
    final sunrise = widget.sunrise;
    final sunset = widget.sunset;

    // Если до восхода - позиция в начале
    if (currentTime.isBefore(sunrise)) {
      return 0.2; // 20% от начала линии
    }

    // Если после заката - позиция в конце
    if (currentTime.isAfter(sunset)) {
      return 0.8; // 80% от начала линии
    }

    // Во время светового дня - пропорциональная позиция
    final totalDaylight = sunset.difference(sunrise).inMinutes;
    final currentProgress = currentTime.difference(sunrise).inMinutes;

    // Маппим от восхода (20%) до заката (80%)
    final position = 0.2 + (currentProgress / totalDaylight) * 0.6;
    return position.clamp(0.2, 0.8);
  }

  /// Получение информации о текущей фазе дня
  ({String phase, String timeLeft, String icon}) _getCurrentPhaseInfo() {
    final currentTime = widget.currentTime ?? DateTime.now();
    final sunrise = widget.sunrise;
    final sunset = widget.sunset;

    if (currentTime.isBefore(sunrise)) {
      final timeUntilSunrise = sunrise.difference(currentTime);
      return (
      phase: widget.localizations.translate('night') ?? 'Night',
      timeLeft: '${widget.localizations.translate('until_sunrise') ?? 'Until sunrise'}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else if (currentTime.isAfter(sunset)) {
      final timeUntilSunrise = sunrise.add(const Duration(days: 1)).difference(currentTime);
      return (
      phase: widget.localizations.translate('night') ?? 'Night',
      timeLeft: '${widget.localizations.translate('until_sunrise') ?? 'Until sunrise'}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else {
      final timeUntilSunset = sunset.difference(currentTime);
      return (
      phase: widget.localizations.translate('day') ?? 'Day',
      timeLeft: '${widget.localizations.translate('until_sunset') ?? 'Until sunset'}: ${_formatDuration(timeUntilSunset)}',
      icon: '☀️'
      );
    }
  }

  /// ИСПРАВЛЕНО: Форматирование длительности в читаемый вид с локализацией
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final locale = widget.localizations.locale.languageCode;

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

  /// ИСПРАВЛЕНО: Получение продолжительности светового дня
  String _getDaylightDuration() {
    final duration = widget.sunset.difference(widget.sunrise);
    return _formatDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final phaseInfo = _getCurrentPhaseInfo();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ИСПРАВЛЕННАЯ временная линия с правильным расчетом ширины
          _buildTimeline(context),

          const SizedBox(height: 24),

          // Информация о времени
          _buildTimeInfo(context, phaseInfo),

          if (widget.showDetailedInfo) ...[
            const SizedBox(height: 16),
            _buildDetailedInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timelineHeight = screenWidth > 600 ? 120.0 : 100.0;

    // ИСПРАВЛЕНО: Правильный расчет доступной ширины с учетом отступов
    final containerPadding = 40.0; // 20 слева + 20 справа от контейнера
    final availableWidth = screenWidth - containerPadding;

    return SizedBox(
      height: timelineHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timelineWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Фоновая линия с градиентом - ИСПРАВЛЕНО: точная ширина
              Positioned(
                left: 0,
                right: 0,
                top: timelineHeight / 2 - 5,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1a1a2e), // Ночь
                        Color(0xFF4a4a6a), // Предрассветный
                        Color(0xFFFF6B35), // Рассвет
                        Color(0xFFFFD93D), // Утро
                        Color(0xFFFFE55C), // День
                        Color(0xFFFFD93D), // Полдень
                        Color(0xFFFF6B35), // Закат
                        Color(0xFF4a4a6a), // Сумерки
                        Color(0xFF1a1a2e), // Ночь
                      ],
                      stops: [0.0, 0.15, 0.2, 0.25, 0.5, 0.75, 0.8, 0.85, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Анимированный маркер текущего времени - красивое солнышко
              if (widget.currentTime != null)
                AnimatedBuilder(
                  animation: _markerAnimation,
                  builder: (context, child) {
                    final position = _getCurrentPosition();
                    return Positioned(
                      left: (timelineWidth * position) - 16, // Центрируем маркер
                      top: timelineHeight / 2 - 16,
                      child: Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFD93D), // Желтый центр
                              const Color(0xFFFF8C00), // Оранжевый край
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD93D).withValues(alpha: 0.8),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '☀️',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Метки времени - ИСПРАВЛЕНО: правильное позиционирование
              Positioned(
                left: (timelineWidth * 0.2) - 30,
                top: timelineHeight / 2 - 40,
                child: Text(
                  widget.localizations.translate('sunrise') ?? 'Sunrise',
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Positioned(
                left: (timelineWidth * 0.8) - 30,
                top: timelineHeight / 2 - 40,
                child: Text(
                  widget.localizations.translate('sunset') ?? 'Sunset',
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Метка "Сейчас" (только если показываем текущее время)
              if (widget.currentTime != null)
                AnimatedBuilder(
                  animation: _markerAnimation,
                  builder: (context, child) {
                    final position = _getCurrentPosition();
                    return Positioned(
                      left: (timelineWidth * position) - 20,
                      top: timelineHeight / 2 + 25,
                      child: Text(
                        widget.localizations.translate('now') ?? 'Now',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, ({String phase, String timeLeft, String icon}) phaseInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Восход
        _buildTimeCard(
          context,
          icon: '🌅',
          time: DateFormat('HH:mm').format(widget.sunrise),
          label: widget.localizations.translate('sunrise') ?? 'Sunrise',
        ),

        // Текущая фаза (только если показываем текущее время)
        if (widget.currentTime != null)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phaseInfo.timeLeft,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Закат
        _buildTimeCard(
          context,
          icon: '🌇',
          time: DateFormat('HH:mm').format(widget.sunset),
          label: widget.localizations.translate('sunset') ?? 'Sunset',
        ),
      ],
    );
  }

  Widget _buildTimeCard(BuildContext context, {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            context,
            icon: '⏱️',
            value: _getDaylightDuration(),
            label: widget.localizations.translate('daylight_duration') ?? 'Daylight Duration',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppConstants.textColor.withValues(alpha: 0.2),
          ),
          _buildStatCard(
            context,
            icon: '🕐',
            value: DateFormat('HH:mm').format(widget.currentTime ?? DateTime.now()),
            label: widget.localizations.translate('current_time') ?? 'Current Time',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 16,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}