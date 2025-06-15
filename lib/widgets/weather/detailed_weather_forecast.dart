// Путь: lib/widgets/weather/detailed_weather_forecast.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
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

          // 2 маленькие карточки
          _buildBottomCards(forecastDay, localizations),

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

  Widget _buildBottomCards(ForecastDay forecastDay, AppLocalizations localizations) {
    // Берем данные полудня для выбранного дня (или первый доступный час)
    final middayHour = forecastDay.hour.length > 12 ? forecastDay.hour[12] : forecastDay.hour.first;

    return Row(
      children: [
        // Видимость - с описанием качества
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: AppConstants.textColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.translate('visibility') ?? 'Видимость',
                        style: TextStyle(
                          color: AppConstants.secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getVisibilityText(_getVisibilityFromHour(middayHour), localizations),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getVisibilityDescription(_getVisibilityFromHour(middayHour), localizations),
                    style: TextStyle(
                      color: AppConstants.secondaryTextColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // УФ индекс - с цветной шкалой и описанием
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '☀️',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.translate('uv_index') ?? 'УФ индекс',
                        style: TextStyle(
                          color: AppConstants.secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_getUVFromDay(forecastDay).round()}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildUVColorBar(_getUVFromDay(forecastDay)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getUVDescription(_getUVFromDay(forecastDay), localizations),
                    style: TextStyle(
                      color: _getUVDescriptionColor(_getUVFromDay(forecastDay)),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUVColorBar(double uvIndex) {
    return Container(
      width: 60, // Увеличено с 30 до 60
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50), // Зеленый (низкий)
            const Color(0xFFFFEB3B), // Желтый (умеренный)
            const Color(0xFFFF9800), // Оранжевый (высокий)
            const Color(0xFFE53935), // Красный (очень высокий)
            const Color(0xFF9C27B0), // Фиолетовый (экстремальный)
          ],
        ),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (uvIndex / 11).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  String _getVisibilityDescription(double visKm, AppLocalizations localizations) {
    final locale = localizations.locale.languageCode;

    if (locale == 'ru') {
      if (visKm >= 10) return 'Отличная';
      if (visKm >= 5) return 'Хорошая';
      if (visKm >= 2) return 'Умеренная';
      if (visKm >= 1) return 'Плохая';
      return 'Туман';
    }

    if (visKm >= 10) return 'Excellent';
    if (visKm >= 5) return 'Good';
    if (visKm >= 2) return 'Moderate';
    if (visKm >= 1) return 'Poor';
    return 'Fog';
  }

  String _getUVDescription(double uvIndex, AppLocalizations localizations) {
    final locale = localizations.locale.languageCode;

    if (locale == 'ru') {
      if (uvIndex <= 2) return 'Низкий';
      if (uvIndex <= 5) return 'Умеренный';
      if (uvIndex <= 7) return 'Высокий';
      if (uvIndex <= 10) return 'Очень высокий';
      return 'Экстремальный';
    }

    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  Color _getUVDescriptionColor(double uvIndex) {
    if (uvIndex <= 2) return const Color(0xFF4CAF50); // Зеленый
    if (uvIndex <= 5) return const Color(0xFFFFEB3B); // Желтый
    if (uvIndex <= 7) return const Color(0xFFFF9800); // Оранжевый
    if (uvIndex <= 10) return const Color(0xFFE53935); // Красный
    return const Color(0xFF9C27B0); // Фиолетовый
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
          // Супер-реалистичный 3D виджет дня/ночи
          SizedBox(
            height: 140,
            child: Ultra3DDayCycleWidget(
              sunrise: astro.sunrise,
              sunset: astro.sunset,
              localizations: localizations,
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
      'feelsLike': targetHour.tempC.round(), // В Hour нет feelslikeC, используем tempC
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

  String _getVisibilityText(double visKm, AppLocalizations localizations) {
    if (visKm < 1) {
      final metersUnit = localizations.translate('meters') ?? 'м';
      return '${(visKm * 1000).round()} $metersUnit';
    } else {
      final kmUnit = localizations.translate('kilometers') ?? 'км';
      return '${visKm.round()} $kmUnit';
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

  // Вспомогательные методы для получения данных выбранного дня
  double _getVisibilityFromHour(Hour hour) {
    if (hour.humidity > 90) return 2.0; // Высокая влажность = плохая видимость
    if (hour.humidity > 80) return 5.0;
    if (hour.humidity > 70) return 8.0;
    return 10.0; // Хорошая видимость при низкой влажности
  }

  double _getUVFromDay(ForecastDay forecastDay) {
    if (forecastDay.hour.isEmpty) return 0.0;

    double maxUV = 0.0;
    for (final hour in forecastDay.hour) {
      final time = DateTime.parse('${forecastDay.date} ${hour.time.split(' ').last}');
      final hourOfDay = time.hour;

      if (hourOfDay >= 10 && hourOfDay <= 16) {
        double uvEstimate = 8.0; // Базовый УФ для полудня

        final conditionCode = hour.condition.code;
        if (conditionCode == 1000) uvEstimate *= 1.0; // Ясно
        else if (conditionCode <= 1003) uvEstimate *= 0.8; // Частично облачно
        else if (conditionCode <= 1009) uvEstimate *= 0.6; // Облачно
        else uvEstimate *= 0.3; // Дождь/снег

        if (uvEstimate > maxUV) maxUV = uvEstimate;
      }
    }

    return maxUV;
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

// 🌟 СУПЕР-РЕАЛИСТИЧНЫЙ 3D ВИДЖЕТ ЦИКЛА ДНЯ
class Ultra3DDayCycleWidget extends StatefulWidget {
  final String sunrise;
  final String sunset;
  final AppLocalizations localizations;

  const Ultra3DDayCycleWidget({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.localizations,
  });

  @override
  State<Ultra3DDayCycleWidget> createState() => _Ultra3DDayCycleWidgetState();
}

class _Ultra3DDayCycleWidgetState extends State<Ultra3DDayCycleWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _cloudController;
  late AnimationController _celestialController;
  late AnimationController _atmosphereController;

  late Animation<double> _mainAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _cloudAnimation;
  late Animation<double> _celestialAnimation;
  late Animation<double> _atmosphereAnimation;

  int _currentPhase = 0;
  List<Ultra3DParticle> _particles = [];
  List<Cloud3D> _clouds = [];

  @override
  void initState() {
    super.initState();

    // Основная анимация фазы
    _mainController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _mainAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    // Анимация частиц
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);

    // Анимация облаков
    _cloudController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    _cloudAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_cloudController);

    // Анимация небесных тел
    _celestialController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _celestialAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_celestialController);

    // Атмосферные эффекты
    _atmosphereController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _atmosphereAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_atmosphereController);

    _currentPhase = _getCurrentPhaseByTime();
    _generateParticles();
    _generateClouds();

    _mainController.forward();
  }

  void _generateParticles() {
    _particles.clear();
    final random = math.Random();

    int particleCount;
    ParticleType3D type;

    switch (_currentPhase) {
      case 0: // Утро
        particleCount = 25;
        type = ParticleType3D.morningMist;
        break;
      case 1: // День
        particleCount = 15;
        type = ParticleType3D.pollen;
        break;
      case 2: // Вечер
        particleCount = 20;
        type = ParticleType3D.fireflies;
        break;
      case 3: // Ночь
        particleCount = 30;
        type = ParticleType3D.starDust;
        break;
      default:
        particleCount = 20;
        type = ParticleType3D.pollen;
    }

    for (int i = 0; i < particleCount; i++) {
      _particles.add(Ultra3DParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        z: 0.2 + random.nextDouble() * 0.8,
        speedX: (random.nextDouble() - 0.5) * 0.02,
        speedY: 0.3 + random.nextDouble() * 0.7,
        speedZ: (random.nextDouble() - 0.5) * 0.01,
        size: 1.0 + random.nextDouble() * 4.0,
        opacity: 0.3 + random.nextDouble() * 0.7,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.1,
        type: type,
        color: _getParticleColor(type),
      ));
    }
  }

  void _generateClouds() {
    _clouds.clear();
    final random = math.Random();

    for (int layer = 0; layer < 3; layer++) {
      for (int i = 0; i < 4; i++) {
        _clouds.add(Cloud3D(
          x: random.nextDouble() * 1.2 - 0.1,
          y: 0.1 + random.nextDouble() * 0.4,
          z: 0.3 + layer * 0.2,
          size: 0.8 + random.nextDouble() * 1.5,
          opacity: 0.4 + random.nextDouble() * 0.4,
          speed: 0.1 + layer * 0.05,
          type: CloudType.values[random.nextInt(CloudType.values.length)],
        ));
      }
    }
  }

  Color _getParticleColor(ParticleType3D type) {
    switch (type) {
      case ParticleType3D.morningMist:
        return Colors.orange.withOpacity(0.6);
      case ParticleType3D.pollen:
        return Colors.yellow.withOpacity(0.8);
      case ParticleType3D.fireflies:
        return Colors.greenAccent.withOpacity(0.9);
      case ParticleType3D.starDust:
        return Colors.white.withOpacity(0.7);
    }
  }

  int _getCurrentPhaseByTime() {
    final now = DateTime.now();
    final currentHour = now.hour;

    try {
      final sunriseTime = _parseTime(widget.sunrise);
      final sunsetTime = _parseTime(widget.sunset);

      final sunriseHour = sunriseTime.hour;
      final sunsetHour = sunsetTime.hour;

      if (currentHour >= 5 && currentHour < sunriseHour + 2) {
        return 0; // Утро
      } else if (currentHour >= sunriseHour + 2 && currentHour < sunsetHour - 2) {
        return 1; // День
      } else if (currentHour >= sunsetHour - 2 && currentHour < sunsetHour + 2) {
        return 2; // Вечер
      } else {
        return 3; // Ночь
      }
    } catch (e) {
      if (currentHour >= 6 && currentHour < 10) return 0;
      if (currentHour >= 10 && currentHour < 17) return 1;
      if (currentHour >= 17 && currentHour < 21) return 2;
      return 3;
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

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _cloudController.dispose();
    _celestialController.dispose();
    _atmosphereController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainAnimation,
        _particleAnimation,
        _cloudAnimation,
        _celestialAnimation,
        _atmosphereAnimation,
      ]),
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(0.05)
            ..rotateY(math.sin(_atmosphereAnimation.value * 2 * math.pi) * 0.02),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _getRealtimeSkyGradient(),
              boxShadow: [
                BoxShadow(
                  color: _getCurrentSkyColor().withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Звезды только ночью
                  if (_isNightTime()) _buildRealtimeStars(),

                  // Облака с реалистичным движением
                  _buildRealtimeClouds(),

                  // Солнце/луна с реальной траекторией
                  _buildRealtimeCelestialBody(),

                  // Атмосферные эффекты
                  _buildAtmosphericEffects(),

                  // Метка времени
                  _buildRealtimeLabel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getRealtimeSkyGradient() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final timeProgress = (currentHour * 60 + currentMinute) / (24 * 60); // 0.0 - 1.0 за день

    try {
      final sunrise = _parseTime(widget.sunrise);
      final sunset = _parseTime(widget.sunset);
      final sunriseProgress = (sunrise.hour * 60 + sunrise.minute) / (24 * 60);
      final sunsetProgress = (sunset.hour * 60 + sunset.minute) / (24 * 60);

      // Плавные переходы в зависимости от времени
      if (timeProgress < sunriseProgress - 0.04) {
        // Глубокая ночь
        return _getNightGradient(1.0);
      } else if (timeProgress < sunriseProgress + 0.04) {
        // Рассвет (1 час до и после восхода)
        final progress = (timeProgress - (sunriseProgress - 0.04)) / 0.08;
        return _getDawnGradient(progress);
      } else if (timeProgress < sunsetProgress - 0.04) {
        // День
        return _getDayGradient(1.0);
      } else if (timeProgress < sunsetProgress + 0.04) {
        // Закат (1 час до и после заката)
        final progress = (timeProgress - (sunsetProgress - 0.04)) / 0.08;
        return _getDuskGradient(progress);
      } else {
        // Ночь
        return _getNightGradient(1.0);
      }
    } catch (e) {
      // Fallback на основе часов
      if (currentHour >= 6 && currentHour < 8) {
        return _getDawnGradient(_mainAnimation.value);
      } else if (currentHour >= 8 && currentHour < 18) {
        return _getDayGradient(_mainAnimation.value);
      } else if (currentHour >= 18 && currentHour < 20) {
        return _getDuskGradient(_mainAnimation.value);
      } else {
        return _getNightGradient(_mainAnimation.value);
      }
    }
  }

  LinearGradient _getDawnGradient(double progress) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF415A77), progress)!,
        Color.lerp(const Color(0xFF415A77), const Color(0xFF778DA9), progress)!,
        Color.lerp(const Color(0xFF778DA9), const Color(0xFFE0E1DD), progress)!,
        Color.lerp(const Color(0xFFE0E1DD), const Color(0xFFFFC300), progress)!,
      ],
    );
  }

  LinearGradient _getDayGradient(double progress) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF87CEEB), const Color(0xFF4A90E2), progress)!,
        Color.lerp(const Color(0xFF87CEEB), const Color(0xFF7EC8E3), progress)!,
        Color.lerp(const Color(0xFFB8E6B8), const Color(0xFFE3F2FD), progress)!,
        Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFF0F8FF), progress)!,
      ],
    );
  }

  LinearGradient _getDuskGradient(double progress) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF4A90E2), const Color(0xFF2C1810), progress)!,
        Color.lerp(const Color(0xFF7EC8E3), const Color(0xFFFF6B35), progress)!,
        Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFFF8E53), progress)!,
        Color.lerp(const Color(0xFFF0F8FF), const Color(0xFFFFA726), progress)!,
      ],
    );
  }

  LinearGradient _getNightGradient(double progress) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF1A1A2E), progress)!,
        Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF16213E), progress)!,
        Color.lerp(const Color(0xFF16213E), const Color(0xFF0F3460), progress)!,
        Color.lerp(const Color(0xFF0F3460), const Color(0xFF533483), progress)!,
      ],
    );
  }

  bool _isNightTime() {
    final now = DateTime.now();
    final currentHour = now.hour;

    try {
      final sunset = _parseTime(widget.sunset);
      final sunrise = _parseTime(widget.sunrise);
      return currentHour >= sunset.hour || currentHour < sunrise.hour;
    } catch (e) {
      return currentHour >= 20 || currentHour < 6;
    }
  }

  Color _getCurrentSkyColor() {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (currentHour >= 5 && currentHour < 10) {
      return Colors.orange; // Утро
    } else if (currentHour >= 10 && currentHour < 17) {
      return Colors.blue; // День
    } else if (currentHour >= 17 && currentHour < 21) {
      return Colors.pink; // Вечер
    } else {
      return Colors.indigo; // Ночь
    }
  }

  Widget _buildRealtimeStars() {
    return Positioned.fill(
      child: CustomPaint(
        painter: RealtimeStarsPainter(_atmosphereAnimation.value),
      ),
    );
  }

  Widget _buildRealtimeClouds() {
    return Stack(
      children: [
        // Дальние облака
        Positioned(
          top: 15 + math.sin(_cloudAnimation.value * math.pi) * 8,
          left: -40 + (_cloudAnimation.value * 150) % 200,
          child: Opacity(
            opacity: 0.4 + _atmosphereAnimation.value * 0.3,
            child: Text('☁️', style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
        // Ближние облака
        Positioned(
          top: 35 + math.cos(_cloudAnimation.value * 1.5 * math.pi) * 12,
          right: -60 + (_cloudAnimation.value * 180) % 240,
          child: Opacity(
            opacity: 0.6 + _atmosphereAnimation.value * 0.4,
            child: Text('☁️', style: TextStyle(fontSize: 26, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeCelestialBody() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    try {
      final sunrise = _parseTime(widget.sunrise);
      final sunset = _parseTime(widget.sunset);
      final sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
      final sunsetMinutes = sunset.hour * 60 + sunset.minute;

      final isDay = currentMinutes >= sunriseMinutes && currentMinutes <= sunsetMinutes;

      if (isDay) {
        // Солнце движется по дуге от восхода до заката
        final dayProgress = (currentMinutes - sunriseMinutes) / (sunsetMinutes - sunriseMinutes);
        return _buildMovingSun(dayProgress);
      } else {
        // Луна движется по ночной дуге
        final nightDuration = (24 * 60) - (sunsetMinutes - sunriseMinutes);
        final nightMinutes = currentMinutes > sunsetMinutes
            ? currentMinutes - sunsetMinutes
            : currentMinutes + (24 * 60 - sunsetMinutes);
        final nightProgress = nightMinutes / nightDuration;
        return _buildMovingMoon(nightProgress);
      }
    } catch (e) {
      // Fallback
      final isDay = now.hour >= 6 && now.hour < 18;
      final progress = isDay
          ? (now.hour - 6) / 12.0
          : ((now.hour >= 18 ? now.hour - 18 : now.hour + 6) / 12.0);
      return isDay ? _buildMovingSun(progress) : _buildMovingMoon(progress);
    }
  }

  Widget _buildMovingSun(double progress) {
    // Солнце движется по параболической дуге
    final x = progress;
    final y = 4 * progress * (1 - progress); // Парабола для дуги

    return Positioned(
      left: 20 + x * 100,
      top: 80 - y * 60,
      child: Transform.scale(
        scale: 1.0 + math.sin(_celestialAnimation.value * 2 * math.pi) * 0.1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white,
                Colors.yellow,
                Colors.orange.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            '☀️',
            style: TextStyle(
              fontSize: 32,
              shadows: [
                Shadow(
                  color: Colors.yellow.withOpacity(0.8),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovingMoon(double progress) {
    // Луна движется по ночной дуге
    final x = progress;
    final y = 4 * progress * (1 - progress);

    return Positioned(
      left: 20 + x * 100,
      top: 80 - y * 40,
      child: Transform.scale(
        scale: 1.0 + math.sin(_celestialAnimation.value * math.pi) * 0.05,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlue.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Text(
            '🌙',
            style: TextStyle(
              fontSize: 28,
              shadows: [
                Shadow(
                  color: Colors.lightBlue.withOpacity(0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAtmosphericEffects() {
    final now = DateTime.now();
    final isDawn = now.hour >= 5 && now.hour <= 7;
    final isDusk = now.hour >= 17 && now.hour <= 19;

    if (!isDawn && !isDusk) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              (isDawn ? Colors.orange : Colors.pink).withOpacity(0.2 * _atmosphereAnimation.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealtimeLabel() {
    final now = DateTime.now();
    String phaseText;
    Color labelColor;

    if (now.hour >= 5 && now.hour < 10) {
      phaseText = widget.localizations.translate('morning') ?? 'Утро';
      labelColor = Colors.orange;
    } else if (now.hour >= 10 && now.hour < 17) {
      phaseText = widget.localizations.translate('day') ?? 'День';
      labelColor = Colors.blue;
    } else if (now.hour >= 17 && now.hour < 21) {
      phaseText = widget.localizations.translate('evening') ?? 'Вечер';
      labelColor = Colors.pink;
    } else {
      phaseText = widget.localizations.translate('night') ?? 'Ночь';
      labelColor = Colors.indigo;
    }

    return Positioned(
      bottom: 15,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: labelColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: labelColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            phaseText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Painter для реалистичных звезд
class RealtimeStarsPainter extends CustomPainter {
  final double twinkleValue;

  RealtimeStarsPainter(this.twinkleValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final stars = [
      {'x': 0.2, 'y': 0.2, 'size': 2.0, 'brightness': 0.9},
      {'x': 0.7, 'y': 0.15, 'size': 1.5, 'brightness': 0.7},
      {'x': 0.9, 'y': 0.3, 'size': 2.5, 'brightness': 1.0},
      {'x': 0.3, 'y': 0.5, 'size': 1.8, 'brightness': 0.8},
      {'x': 0.8, 'y': 0.6, 'size': 1.2, 'brightness': 0.6},
      {'x': 0.1, 'y': 0.7, 'size': 2.2, 'brightness': 0.9},
      {'x': 0.6, 'y': 0.8, 'size': 1.6, 'brightness': 0.75},
    ];

    for (final star in stars) {
      final x = (star['x'] as double) * size.width;
      final y = (star['y'] as double) * size.height;
      final starSize = star['size'] as double;
      final brightness = star['brightness'] as double;

      // Мерцание с разными фазами
      final twinkle = 0.4 + 0.6 * math.sin(twinkleValue * 2 * math.pi + x * 0.01);
      final opacity = (brightness * twinkle).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(opacity);

      // Основная звезда
      canvas.drawCircle(Offset(x, y), starSize, paint);

      // Лучи для ярких звезд
      if (starSize > 1.8) {
        final rayPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(x - starSize * 2.5, y),
          Offset(x + starSize * 2.5, y),
          rayPaint,
        );
        canvas.drawLine(
          Offset(x, y - starSize * 2.5),
          Offset(x, y + starSize * 2.5),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}