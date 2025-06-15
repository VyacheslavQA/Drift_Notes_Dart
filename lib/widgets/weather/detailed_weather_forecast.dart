// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ИСПРАВЛЕНО: Убраны карточки видимости и УФ индекса

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

enum TimeOfDay { morning, day, evening, night }

// 🎨 МОДЕЛИ ДАННЫХ ДЛЯ 3D ЭЛЕМЕНТОВ
enum ParticleType3D { morningMist, pollen, fireflies, starDust }
enum CloudType { cumulus, stratus, cirrus, nimbus }

class Ultra3DParticle {
  double x, y, z;
  final double speedX, speedY, speedZ;
  final double size;
  final double opacity;
  double rotation;
  final double rotationSpeed;
  final ParticleType3D type;
  final Color color;

  Ultra3DParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.speedX,
    required this.speedY,
    required this.speedZ,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
    required this.color,
  });
}

class Cloud3D {
  double x, y, z;
  final double size;
  final double opacity;
  final double speed;
  final CloudType type;

  Cloud3D({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.type,
  });
}

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

          // График светового дня
          _buildDaylightCard(forecastDay, localizations),
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

  Widget _buildDaylightCard(ForecastDay forecastDay, AppLocalizations localizations) {
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
        children: [
          // Круговая диаграмма дня/ночи
          SizedBox(
            height: 200,
            child: DaylightCircularChart(
              sunrise: astro.sunrise,
              sunset: astro.sunset,
              localizations: localizations,
              selectedDayIndex: selectedDayIndex,
              allForecastDays: weather.forecast,
            ),
          ),

          const SizedBox(height: 16),

          // Времена и длительность
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    localizations.translate('sunrise') ?? 'Восход',
                    style: TextStyle(
                      color: AppConstants.secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    astro.sunrise,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    localizations.translate('daylight') ?? 'Световой день',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _calculateDaylightDuration(astro.sunrise, astro.sunset, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    localizations.translate('sunset') ?? 'Закат',
                    style: TextStyle(
                      color: AppConstants.secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    astro.sunset,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
      // Используем tempC поскольку feelslikeC недоступно в модели
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
      return DateTime(now.year, now.month, now.day, 12, 0);
    }
  }
}

// 🌅 КРУГОВАЯ ДИАГРАММА СВЕТОВОГО ДНЯ С ОТСЛЕЖИВАНИЕМ ИЗМЕНЕНИЙ
class DaylightCircularChart extends StatefulWidget {
  final String sunrise;
  final String sunset;
  final AppLocalizations localizations;
  final int selectedDayIndex;
  final List<ForecastDay> allForecastDays;

  const DaylightCircularChart({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.localizations,
    required this.selectedDayIndex,
    required this.allForecastDays,
  });

  @override
  State<DaylightCircularChart> createState() => _DaylightCircularChartState();
}

class _DaylightCircularChartState extends State<DaylightCircularChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Основная круговая диаграмма
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: DaylightCircularPainter(
                    sunrise: widget.sunrise,
                    sunset: widget.sunset,
                    animation: _rotationAnimation.value,
                  ),
                ),
              ),
            ),

            // Центральная информация
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Иконка времени суток
                  Text(
                    _getCurrentTimeIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),

                  // Текущее время или выбранный день
                  Text(
                    _getCurrentTimeText(),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Индикатор изменения длительности дня
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: _buildDayChangeIndicator(),
            ),
          ],
        );
      },
    );
  }

  String _getCurrentTimeIcon() {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (currentHour >= 5 && currentHour < 10) {
      return '🌅'; // Рассвет
    } else if (currentHour >= 10 && currentHour < 17) {
      return '☀️'; // День
    } else if (currentHour >= 17 && currentHour < 21) {
      return '🌇'; // Закат
    } else {
      return '🌙'; // Ночь
    }
  }

  String _getCurrentTimeText() {
    if (widget.selectedDayIndex == 0) {
      return DateFormat('HH:mm').format(DateTime.now());
    } else {
      final locale = widget.localizations.locale.languageCode;
      if (locale == 'ru') {
        const days = ['Сегодня', 'Завтра', 'Послезавтра'];
        return widget.selectedDayIndex < days.length ? days[widget.selectedDayIndex] : '+${widget.selectedDayIndex}д';
      } else {
        const days = ['Today', 'Tomorrow', 'Day after'];
        return widget.selectedDayIndex < days.length ? days[widget.selectedDayIndex] : '+${widget.selectedDayIndex}d';
      }
    }
  }

  Widget _buildDayChangeIndicator() {
    if (widget.selectedDayIndex >= widget.allForecastDays.length - 1) {
      return const SizedBox.shrink();
    }

    try {
      final currentDay = widget.allForecastDays[widget.selectedDayIndex];
      final previousDay = widget.selectedDayIndex > 0
          ? widget.allForecastDays[widget.selectedDayIndex - 1]
          : null;

      if (previousDay == null) return const SizedBox.shrink();

      final currentDuration = _calculateDaylightMinutes(currentDay.astro.sunrise, currentDay.astro.sunset);
      final previousDuration = _calculateDaylightMinutes(previousDay.astro.sunrise, previousDay.astro.sunset);

      final difference = currentDuration - previousDuration;

      if (difference == 0) return const SizedBox.shrink();

      final isIncreasing = difference > 0;
      final diffHours = difference.abs() ~/ 60;
      final diffMinutes = difference.abs() % 60;

      String changeText;
      final locale = widget.localizations.locale.languageCode;

      if (locale == 'ru') {
        if (diffHours > 0) {
          changeText = '${isIncreasing ? '+' : '-'}$diffHours ч $diffMinutes мин';
        } else {
          changeText = '${isIncreasing ? '+' : '-'}$diffMinutes мин';
        }
      } else {
        if (diffHours > 0) {
          changeText = '${isIncreasing ? '+' : '-'}${diffHours}h ${diffMinutes}m';
        } else {
          changeText = '${isIncreasing ? '+' : '-'}${diffMinutes}m';
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: (isIncreasing ? Colors.green : Colors.orange).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncreasing ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              changeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  int _calculateDaylightMinutes(String sunrise, String sunset) {
    try {
      final sunriseTime = _parseTime(sunrise);
      final sunsetTime = _parseTime(sunset);
      return sunsetTime.difference(sunriseTime).inMinutes;
    } catch (e) {
      return 12 * 60; // 12 часов по умолчанию
    }
  }

  DateTime _parseTime(String timeString) {
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
  }
}

// Painter для круговой диаграммы
class DaylightCircularPainter extends CustomPainter {
  final String sunrise;
  final String sunset;
  final double animation;

  DaylightCircularPainter({
    required this.sunrise,
    required this.sunset,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    try {
      final sunriseTime = _parseTime(sunrise);
      final sunsetTime = _parseTime(sunset);

      // Конвертируем в минуты от начала дня
      final sunriseMinutes = sunriseTime.hour * 60 + sunriseTime.minute;
      final sunsetMinutes = sunsetTime.hour * 60 + sunsetTime.minute;

      // Углы для дуги (0° = 12 часов наверху, по часовой стрелке)
      // Формула: (час / 12) * 2π - π/2 для правильного циферблата
      final sunriseAngle = ((sunriseMinutes / 60) / 12) * 2 * math.pi - math.pi / 2;
      final sunsetAngle = ((sunsetMinutes / 60) / 12) * 2 * math.pi - math.pi / 2;
      final daylightSweepAngle = sunsetAngle - sunriseAngle;

      // Фоновый круг (ночь)
      final nightPaint = Paint()
        ..color = const Color(0xFF1A1A2E).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;

      canvas.drawCircle(center, radius, nightPaint);

      // Дуга светового дня с анимацией
      final dayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      // Градиент от рассвета к закату
      final gradient = SweepGradient(
        startAngle: sunriseAngle,
        endAngle: sunsetAngle,
        colors: [
          Colors.orange.withOpacity(0.8),  // Рассвет
          Colors.yellow.withOpacity(0.9),  // Утро
          Colors.blue.withOpacity(0.8),    // День
          Colors.orange.withOpacity(0.8),  // Вечер
          Colors.red.withOpacity(0.7),     // Закат
        ],
      );

      dayPaint.shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));

      // Рисуем дугу дня с анимацией
      final animatedSweepAngle = daylightSweepAngle * animation;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sunriseAngle,
        animatedSweepAngle,
        false,
        dayPaint,
      );

      // Маркеры времени (12, 6, 18, 24)
      _drawTimeMarkers(canvas, center, radius);

      // Маркеры восхода и заката
      if (animation > 0.7) {
        _drawSunMarkers(canvas, center, radius, sunriseAngle, sunsetAngle);
      }

      // Текущее время (если сегодня)
      _drawCurrentTimeMarker(canvas, center, radius);

    } catch (e) {
      // Fallback круг при ошибке парсинга
      final fallbackPaint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawCircle(center, radius, fallbackPaint);
    }
  }

  void _drawTimeMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Маркеры для 12, 3, 6, 9 часов (как на обычном циферблате)
    final hours = [12, 3, 6, 9];
    for (final hour in hours) {
      // Правильные углы для циферблата: 12 часов = верх (0°), далее по часовой стрелке
      final angle = (hour / 12) * 2 * math.pi - math.pi / 2;
      final markerRadius = radius + 15;
      final x = center.dx + markerRadius * math.cos(angle);
      final y = center.dy + markerRadius * math.sin(angle);

      // Маленькая точка
      canvas.drawCircle(Offset(x, y), 2, markerPaint);

      // Текст времени
      textPainter.text = TextSpan(
        text: hour.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();

      // Правильное позиционирование текста относительно маркера
      final textX = x - textPainter.width / 2;
      final textY = y - textPainter.height / 2 + (hour == 12 ? -15 : hour == 6 ? 10 : 0);
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  void _drawSunMarkers(Canvas canvas, Offset center, double radius, double sunriseAngle, double sunsetAngle) {
    final sunPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Маркер восхода
    final sunriseX = center.dx + radius * math.cos(sunriseAngle);
    final sunriseY = center.dy + radius * math.sin(sunriseAngle);
    canvas.drawCircle(Offset(sunriseX, sunriseY), 4, sunPaint);

    // Маркер заката
    final sunsetX = center.dx + radius * math.cos(sunsetAngle);
    final sunsetY = center.dy + radius * math.sin(sunsetAngle);
    canvas.drawCircle(Offset(sunsetX, sunsetY), 4, sunPaint);
  }

  void _drawCurrentTimeMarker(Canvas canvas, Offset center, double radius) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    // Правильный расчет угла для 12-часового циферблата
    final currentAngle = ((currentMinutes / 60) / 12) * 2 * math.pi - math.pi / 2;

    final currentTimePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final currentX = center.dx + (radius - 6) * math.cos(currentAngle);
    final currentY = center.dy + (radius - 6) * math.sin(currentAngle);

    // Внешний белый круг
    canvas.drawCircle(Offset(currentX, currentY), 6, currentTimePaint);

    // Внутренний цветной круг
    final innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX, currentY), 4, innerPaint);
  }

  DateTime _parseTime(String timeString) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}