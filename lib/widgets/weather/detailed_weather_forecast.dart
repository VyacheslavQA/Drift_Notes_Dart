// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ИСПРАВЛЕНО: Заменены ResponsiveText и ResponsiveUtils на стандартный Flutter код

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

          // НОВАЯ временная линия светового дня
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

  // НОВЫЙ МЕТОД: Временная линия светового дня
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
          Text(
            '🌅 ${localizations.translate('daylight_hours') ?? 'Световой день'}',
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Временная линия
          DaylightTimelineWidget(
            sunrise: _parseAstroTime(astro.sunrise),
            sunset: _parseAstroTime(astro.sunset),
            currentTime: selectedDayIndex == 0 ? DateTime.now() : null,
            enableAnimation: true,
            showDetailedInfo: MediaQuery.of(context).size.width > 600,
          ),
        ],
      ),
    );
  }

  // Парсинг времени из API в DateTime
  DateTime _parseAstroTime(String timeString) {
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
      DateTime targetDate = now;

      // Для будущих дней добавляем дни
      if (selectedDayIndex > 0) {
        targetDate = now.add(Duration(days: selectedDayIndex));
      }

      return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
    } catch (e) {
      // Fallback времена
      final now = DateTime.now();
      return timeString.toLowerCase().contains('sunrise') || timeString.toLowerCase().contains('am')
          ? DateTime(now.year, now.month, now.day, 6, 30)
          : DateTime(now.year, now.month, now.day, 18, 30);
    }
  }

  // Вспомогательные методы (остаются без изменений)
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

// НОВЫЙ ВИДЖЕТ: Временная линия светового дня
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

  const DaylightTimelineWidget({
    super.key,
    required this.sunrise,
    required this.sunset,
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
  ({String phase, String timeLeft, String icon}) _getCurrentPhaseInfo(AppLocalizations localizations) {
    final currentTime = widget.currentTime ?? DateTime.now();
    final sunrise = widget.sunrise;
    final sunset = widget.sunset;

    if (currentTime.isBefore(sunrise)) {
      final timeUntilSunrise = sunrise.difference(currentTime);
      return (
      phase: localizations.translate('night') ?? 'Ночь',
      timeLeft: '${localizations.translate('until_sunrise') ?? 'До восхода'}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else if (currentTime.isAfter(sunset)) {
      final timeUntilSunrise = sunrise.add(const Duration(days: 1)).difference(currentTime);
      return (
      phase: localizations.translate('night') ?? 'Ночь',
      timeLeft: '${localizations.translate('until_sunrise') ?? 'До восхода'}: ${_formatDuration(timeUntilSunrise)}',
      icon: '🌙'
      );
    } else {
      final timeUntilSunset = sunset.difference(currentTime);
      return (
      phase: localizations.translate('day') ?? 'День',
      timeLeft: '${localizations.translate('until_sunset') ?? 'До заката'}: ${_formatDuration(timeUntilSunset)}',
      icon: '☀️'
      );
    }
  }

  /// Форматирование длительности в читаемый вид
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}ч ${minutes}мин';
    } else {
      return '${minutes}мин';
    }
  }

  /// Получение продолжительности светового дня
  String _getDaylightDuration() {
    final duration = widget.sunset.difference(widget.sunrise);
    return _formatDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final phaseInfo = _getCurrentPhaseInfo(localizations);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Временная линия
          _buildTimeline(context, localizations),

          const SizedBox(height: 24),

          // Информация о времени
          _buildTimeInfo(context, localizations, phaseInfo),

          if (widget.showDetailedInfo) ...[
            const SizedBox(height: 16),
            _buildDetailedInfo(context, localizations),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, AppLocalizations localizations) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timelineHeight = screenWidth > 600 ? 120.0 : 100.0;

    return SizedBox(
      height: timelineHeight,
      child: Stack(
        children: [
          // Фоновая линия с градиентом
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
                    Color(0xFFFF6B35), // Рассвет
                    Color(0xFFFFD93D), // День
                    Color(0xFFFFD93D), // День
                    Color(0xFFFF6B35), // Закат
                    Color(0xFF1a1a2e), // Ночь
                  ],
                  stops: [0.0, 0.2, 0.3, 0.7, 0.8, 1.0],
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
                return Positioned(
                  left: MediaQuery.of(context).size.width *
                      (_getCurrentPosition() - 0.05), // Центрируем маркер
                  top: timelineHeight / 2 - 15,
                  child: Container(
                    width: screenWidth > 600 ? 32.0 : 28.0,
                    height: screenWidth > 600 ? 32.0 : 28.0,
                    decoration: BoxDecoration(
                      // Градиент солнца от оранжевого к желтому
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
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '☀️',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Метки времени
          Positioned(
            left: MediaQuery.of(context).size.width * 0.2 - 30,
            top: timelineHeight / 2 - 35,
            child: Text(
              localizations.translate('sunrise') ?? 'Восход',
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Positioned(
            left: MediaQuery.of(context).size.width * 0.8 - 30,
            top: timelineHeight / 2 - 35,
            child: Text(
              localizations.translate('sunset') ?? 'Закат',
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
                return Positioned(
                  left: MediaQuery.of(context).size.width *
                      (_getCurrentPosition() - 0.05),
                  top: timelineHeight / 2 + 25,
                  child: Text(
                    localizations.translate('now') ?? 'Сейчас',
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
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, AppLocalizations localizations,
      ({String phase, String timeLeft, String icon}) phaseInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Восход
        _buildTimeCard(
          context,
          icon: '🌅',
          time: DateFormat('HH:mm').format(widget.sunrise),
          label: localizations.translate('sunrise') ?? 'Восход',
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
          icon: '🌅',
          time: DateFormat('HH:mm').format(widget.sunset),
          label: localizations.translate('sunset') ?? 'Закат',
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

  Widget _buildDetailedInfo(BuildContext context, AppLocalizations localizations) {
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
            label: localizations.translate('daylight_duration') ?? 'Продолжительность дня',
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
            label: localizations.translate('current_time') ?? 'Текущее время',
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