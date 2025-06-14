// Путь: lib/widgets/weather/weather_metrics_grid.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';
import '../animated_border_widget.dart';

class WeatherMetricsGrid extends StatefulWidget {
  final WeatherApiResponse weather;
  final WeatherSettingsService weatherSettings;
  final VoidCallback? onPressureCardTap;
  final VoidCallback? onWindCardTap;

  const WeatherMetricsGrid({
    super.key,
    required this.weather,
    required this.weatherSettings,
    this.onPressureCardTap,
    this.onWindCardTap,
  });

  @override
  State<WeatherMetricsGrid> createState() => _WeatherMetricsGridState();
}

class _WeatherMetricsGridState extends State<WeatherMetricsGrid> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildPressureCard(),
          _buildWindCard(),
          _buildMoonPhaseCard(),
          _buildHumidityCard(),
        ],
      ),
    );
  }

  Widget _buildPressureCard() {
    final localizations = AppLocalizations.of(context);
    final pressure = widget.weather.current.pressureMb;
    final formattedPressure = widget.weatherSettings.formatPressure(pressure);
    final pressureTrend = _getPressureTrend(pressure);
    final pressureStatus = _getPressureStatus(pressure, localizations);

    return AnimatedBorderWidget(
      borderRadius: 16.0,
      glowColor: Colors.green,
      baseColor: Colors.green.withValues(alpha: 0.3),
      animationDuration: const Duration(seconds: 6),
      glowSize: 25.0,
      glowIntensity: 0.9,
      onTap: widget.onPressureCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.textColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pressureStatus['color'].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.speed,
                      color: pressureStatus['color'],
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getPressureTrendIcon(pressureTrend),
                    color: _getPressureTrendColor(pressureTrend),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizations.translate('pressure'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formattedPressure,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                pressureStatus['description'],
                style: TextStyle(
                  color: pressureStatus['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindCard() {
    final localizations = AppLocalizations.of(context);
    final windSpeed = widget.weather.current.windKph;
    final windDirection = widget.weather.current.windDir;
    final formattedWind = widget.weatherSettings.formatWindSpeed(windSpeed);
    final windStatus = _getWindStatus(windSpeed, localizations);

    return AnimatedBorderWidget(
      borderRadius: 16.0,
      glowColor: Colors.blue,
      baseColor: Colors.blue.withValues(alpha: 0.3),
      animationDuration: const Duration(seconds: 6),
      glowSize: 30.0,
      glowIntensity: 0.8,
      onTap: widget.onWindCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.textColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: windStatus['color'].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.air,
                      color: windStatus['color'],
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _translateWindDirection(windDirection),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizations.translate('wind'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formattedWind,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                windStatus['description'],
                style: TextStyle(
                  color: windStatus['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoonPhaseCard() {
    final localizations = AppLocalizations.of(context);
    final moonPhase =
    widget.weather.forecast.isNotEmpty
        ? widget.weather.forecast.first.astro.moonPhase
        : 'Unknown';

    final moonInfo = _getMoonPhaseInfo(moonPhase, localizations);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: moonInfo['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  moonInfo['icon'],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: moonInfo['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  moonInfo['impact'],
                  style: TextStyle(
                    color: moonInfo['color'],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('moon_phase'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _translateMoonPhase(moonPhase, localizations),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            moonInfo['description'],
            style: TextStyle(
              color: moonInfo['color'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard() {
    final localizations = AppLocalizations.of(context);
    final humidity = widget.weather.current.humidity;
    final dewPoint = _calculateDewPoint(widget.weather.current.tempC, humidity);
    final humidityStatus = _getHumidityStatus(humidity, localizations);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: humidityStatus['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: humidityStatus['color'],
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: humidityStatus['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  humidityStatus['badge'],
                  style: TextStyle(
                    color: humidityStatus['color'],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('humidity'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$humidity%',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                humidityStatus['description'],
                style: TextStyle(
                  color: humidityStatus['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.translate('dew_point')}: ${dewPoint.round()}°',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для анализа данных

  String _getPressureTrend(double pressure) {
    if (pressure > 1020) return 'stable';
    if (pressure > 1010) return 'rising';
    return 'falling';
  }

  Map<String, dynamic> _getPressureStatus(
      double pressure,
      AppLocalizations localizations,
      ) {
    if (pressure >= 1010 && pressure <= 1025) {
      return {
        'color': Colors.green,
        'description': localizations.translate('normal_pressure'),
      };
    } else if (pressure < 1000) {
      return {
        'color': Colors.red,
        'description': localizations.translate('low_pressure'),
      };
    } else if (pressure > 1030) {
      return {
        'color': Colors.orange,
        'description': localizations.translate('high_pressure'),
      };
    } else {
      return {
        'color': Colors.orange,
        'description': localizations.translate('moderate_pressure'),
      };
    }
  }

  IconData _getPressureTrendIcon(String trend) {
    switch (trend) {
      case 'rising':
        return Icons.trending_up;
      case 'falling':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getPressureTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return Colors.green;
      case 'falling':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Map<String, dynamic> _getWindStatus(
      double windKph,
      AppLocalizations localizations,
      ) {
    if (windKph < 10) {
      return {
        'color': Colors.green,
        'description': localizations.translate('excellent_for_fishing'),
      };
    } else if (windKph < 20) {
      return {
        'color': Colors.lightGreen,
        'description': localizations.translate('good_for_fishing'),
      };
    } else if (windKph < 30) {
      return {
        'color': Colors.orange,
        'description': localizations.translate('moderate_for_fishing'),
      };
    } else {
      return {
        'color': Colors.red,
        'description': localizations.translate('difficult_for_fishing'),
      };
    }
  }

  String _translateWindDirection(String direction) {
    final localizations = AppLocalizations.of(context);
    final Map<String, String> translations = {
      'N': localizations.translate('wind_n'),
      'NNE': localizations.translate('wind_nne'),
      'NE': localizations.translate('wind_ne'),
      'ENE': localizations.translate('wind_ene'),
      'E': localizations.translate('wind_e'),
      'ESE': localizations.translate('wind_ese'),
      'SE': localizations.translate('wind_se'),
      'SSE': localizations.translate('wind_sse'),
      'S': localizations.translate('wind_s'),
      'SSW': localizations.translate('wind_ssw'),
      'SW': localizations.translate('wind_sw'),
      'WSW': localizations.translate('wind_wsw'),
      'W': localizations.translate('wind_w'),
      'WNW': localizations.translate('wind_wnw'),
      'NW': localizations.translate('wind_nw'),
      'NNW': localizations.translate('wind_nnw'),
    };
    return translations[direction] ?? direction;
  }

  Map<String, dynamic> _getMoonPhaseInfo(
      String moonPhase,
      AppLocalizations localizations,
      ) {
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new')) {
      return {
        'icon': '🌑',
        'color': Colors.purple,
        'impact': localizations.translate('excellent').toUpperCase(),
        'description': localizations.translate('excellent_activity'),
      };
    } else if (phase.contains('full')) {
      return {
        'icon': '🌕',
        'color': Colors.orange,
        'impact': localizations.translate('excellent').toUpperCase(),
        'description': localizations.translate('excellent_activity'),
      };
    } else if (phase.contains('first quarter')) {
      return {
        'icon': '🌓',
        'color': Colors.blue,
        'impact': localizations.translate('normal').toUpperCase(),
        'description': localizations.translate('moderate_activity'),
      };
    } else if (phase.contains('third quarter') ||
        phase.contains('last quarter')) {
      return {
        'icon': '🌗',
        'color': Colors.blue,
        'impact': localizations.translate('normal').toUpperCase(),
        'description': localizations.translate('moderate_activity'),
      };
    } else if (phase.contains('waxing crescent')) {
      return {
        'icon': '🌒',
        'color': Colors.grey,
        'impact': localizations.translate('poor').toUpperCase(),
        'description': localizations.translate('poor_activity'),
      };
    } else if (phase.contains('waning crescent')) {
      return {
        'icon': '🌘',
        'color': Colors.orange,
        'impact': localizations.translate('moderate').toUpperCase(),
        'description': localizations.translate('moderate_activity'),
      };
    } else if (phase.contains('waxing gibbous')) {
      return {
        'icon': '🌔',
        'color': Colors.green,
        'impact': localizations.translate('good').toUpperCase(),
        'description': localizations.translate('good_activity'),
      };
    } else if (phase.contains('waning gibbous')) {
      return {
        'icon': '🌖',
        'color': Colors.green,
        'impact': localizations.translate('good').toUpperCase(),
        'description': localizations.translate('good_activity'),
      };
    } else {
      return {
        'icon': '🌙',
        'color': Colors.grey,
        'impact': 'Н/Д',
        'description': localizations.translate('no_data_to_display'),
      };
    }
  }

  String _translateMoonPhase(String moonPhase, AppLocalizations localizations) {
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new')) return localizations.translate('moon_new_moon');
    if (phase.contains('full'))
      return localizations.translate('moon_full_moon');
    if (phase.contains('first quarter'))
      return localizations.translate('moon_first_quarter');
    if (phase.contains('third quarter') || phase.contains('last quarter'))
      return localizations.translate('moon_last_quarter');
    if (phase.contains('waxing crescent'))
      return localizations.translate('moon_waxing_crescent');
    if (phase.contains('waning crescent'))
      return localizations.translate('moon_waning_crescent');
    if (phase.contains('waxing gibbous'))
      return localizations.translate('moon_waxing_gibbous');
    if (phase.contains('waning gibbous'))
      return localizations.translate('moon_waning_gibbous');

    return localizations.translate('unknown_weather');
  }

  Map<String, dynamic> _getHumidityStatus(
      int humidity,
      AppLocalizations localizations,
      ) {
    if (humidity >= 40 && humidity <= 60) {
      return {
        'color': Colors.green,
        'description': localizations.translate('comfortable'),
        'badge': localizations.translate('normal').toUpperCase(),
      };
    } else if (humidity < 30) {
      return {
        'color': Colors.orange,
        'description': localizations.translate('dry'),
        'badge': localizations.translate('dry').toUpperCase(),
      };
    } else if (humidity > 80) {
      return {
        'color': Colors.blue,
        'description': localizations.translate('humid'),
        'badge': localizations.translate('humid').toUpperCase(),
      };
    } else {
      return {
        'color': Colors.lightGreen,
        'description': localizations.translate('moderate'),
        'badge': 'OK',
      };
    }
  }

  double _calculateDewPoint(double tempC, int humidity) {
    final a = 17.27;
    final b = 237.7;
    final alpha = ((a * tempC) / (b + tempC)) + math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
  }
}