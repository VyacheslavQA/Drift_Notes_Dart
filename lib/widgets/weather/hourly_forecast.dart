// Путь: lib/widgets/weather/hourly_forecast.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class HourlyForecast extends StatelessWidget {
  final WeatherApiResponse weather;
  final WeatherSettingsService weatherSettings;
  final Function(int hour, double activity)? onHourTapped;

  const HourlyForecast({
    super.key,
    required this.weather,
    required this.weatherSettings,
    this.onHourTapped,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (weather.forecast.isEmpty) {
      return const SizedBox();
    }

    final todayForecast = weather.forecast.first;
    final hours = todayForecast.hour;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('hourly_forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              itemBuilder: (context, index) {
                final hour = hours[index];
                final time = DateTime.parse(hour.time);
                final activity = _calculateHourActivity(hour);
                final isCurrentHour = DateTime.now().hour == time.hour;

                return GestureDetector(
                  onTap: () => onHourTapped?.call(time.hour, activity),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentHour
                          ? AppConstants.primaryColor.withValues(alpha: 0.2)
                          : AppConstants.backgroundColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentHour
                          ? Border.all(color: AppConstants.primaryColor, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(time),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          _getWeatherIcon(hour.condition.code),
                          color: AppConstants.textColor,
                          size: 20,
                        ),
                        Text(
                          weatherSettings.formatTemperature(hour.tempC, showUnit: false),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getActivityColor(activity),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${(activity * 10).round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateHourActivity(Hour hour) {
    // Простой алгоритм расчета активности по часам
    double activity = 0.5;

    // Лучшие часы для рыбалки
    final hourOfDay = DateTime.parse(hour.time).hour;
    if ([6, 7, 8, 18, 19, 20].contains(hourOfDay)) {
      activity += 0.3;
    }

    // Температура
    if (hour.tempC >= 15 && hour.tempC <= 25) {
      activity += 0.1;
    }

    // Ветер
    if (hour.windKph < 15) {
      activity += 0.1;
    } else if (hour.windKph > 30) {
      activity -= 0.2;
    }

    return activity.clamp(0.0, 1.0);
  }

  IconData _getWeatherIcon(int code) {
    switch (code) {
      case 1000: return Icons.wb_sunny;
      case 1003: case 1006: case 1009: return Icons.cloud;
      case 1030: case 1135: case 1147: return Icons.cloud;
      case 1063: case 1180: case 1183: case 1186: case 1189: case 1192: case 1195: case 1198: case 1201: return Icons.grain;
      case 1066: case 1210: case 1213: case 1216: case 1219: case 1222: case 1225: return Icons.ac_unit;
      case 1087: case 1273: case 1276: case 1279: case 1282: return Icons.flash_on;
      default: return Icons.wb_sunny;
    }
  }

  Color _getActivityColor(double activity) {
    if (activity >= 0.8) return const Color(0xFF4CAF50);
    if (activity >= 0.6) return const Color(0xFFFFC107);
    if (activity >= 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}