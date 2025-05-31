// Путь: lib/widgets/weather/weather_metrics_grid.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

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

class _WeatherMetricsGridState extends State<WeatherMetricsGrid>
    with TickerProviderStateMixin {
  late AnimationController _pressureAnimationController;
  late AnimationController _windAnimationController;
  late Animation<double> _pressureAnimation;
  late Animation<double> _windAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Анимация для давления (зеленое свечение)
    _pressureAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Анимация для ветра (голубое свечение)
    _windAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pressureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pressureAnimationController,
      curve: Curves.easeInOut,
    ));

    _windAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _windAnimationController,
      curve: Curves.easeInOut,
    ));

    // Запускаем анимации с небольшой задержкой
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pressureAnimationController.repeat();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _windAnimationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _pressureAnimationController.dispose();
    _windAnimationController.dispose();
    super.dispose();
  }

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
        childAspectRatio: 1.1,
        children: [
          _buildPressureCard(),
          _buildWindCard(),
          _buildMoonPhaseCard(),
          _buildVisibilityCard(),
        ],
      ),
    );
  }

  Widget _buildPressureCard() {
    final localizations = AppLocalizations.of(context);
    final pressure = widget.weather.current.pressureMb;
    final formattedPressure = widget.weatherSettings.formatPressure(pressure);
    final pressureTrend = _getPressureTrend();
    final pressureStatus = _getPressureStatus(pressure);

    return AnimatedBuilder(
      animation: _pressureAnimation,
      builder: (context, child) {
        return GestureDetector(
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
            child: CustomPaint(
              painter: GlowingBorderPainter(
                animation: _pressureAnimation,
                color: Colors.green,
                borderRadius: 16,
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
                    const SizedBox(height: 4),
                    Text(
                      formattedPressure,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pressureStatus['description'],
                      style: TextStyle(
                        color: pressureStatus['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWindCard() {
    final localizations = AppLocalizations.of(context);
    final windSpeed = widget.weather.current.windKph;
    final windDirection = widget.weather.current.windDir;
    final formattedWind = widget.weatherSettings.formatWindSpeed(windSpeed);
    final windStatus = _getWindStatus(windSpeed);

    return AnimatedBuilder(
      animation: _windAnimation,
      builder: (context, child) {
        return GestureDetector(
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
            child: CustomPaint(
              painter: GlowingBorderPainter(
                animation: _windAnimation,
                color: Colors.blue,
                borderRadius: 16,
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
                    const SizedBox(height: 4),
                    Text(
                      formattedWind,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      windStatus['description'],
                      style: TextStyle(
                        color: windStatus['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoonPhaseCard() {
    final localizations = AppLocalizations.of(context);
    final moonPhase = widget.weather.forecast.isNotEmpty
        ? widget.weather.forecast.first.astro.moonPhase
        : 'Unknown';

    final moonInfo = _getMoonPhaseInfo(moonPhase);

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
          const SizedBox(height: 4),
          Text(
            _translateMoonPhase(moonPhase),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildVisibilityCard() {
    final localizations = AppLocalizations.of(context);
    final visibility = widget.weather.current.visKm;
    final visibilityStatus = _getVisibilityStatus(visibility);

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
                  color: visibilityStatus['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility,
                  color: visibilityStatus['color'],
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                visibilityStatus['icon'],
                color: visibilityStatus['color'],
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('visibility'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${visibility.toStringAsFixed(1)} ${localizations.translate('km')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            visibilityStatus['description'],
            style: TextStyle(
              color: visibilityStatus['color'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для анализа данных

  String _getPressureTrend() {
    // Упрощенная логика определения тренда
    // В реальном приложении можно сравнивать с предыдущими значениями
    final pressure = widget.weather.current.pressureMb;
    if (pressure > 1020) return 'stable';
    if (pressure > 1010) return 'rising';
    return 'falling';
  }

  Map<String, dynamic> _getPressureStatus(double pressure) {
    final localizations = AppLocalizations.of(context);

    if (pressure >= 1010 && pressure <= 1025) {
      return {
        'color': Colors.green,
        'description': localizations.translate('excellent_for_fishing'),
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

  Map<String, dynamic> _getWindStatus(double windKph) {
    final localizations = AppLocalizations.of(context);

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

  Map<String, dynamic> _getMoonPhaseInfo(String moonPhase) {
    final localizations = AppLocalizations.of(context);
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new')) {
      return {
        'icon': '🌑',
        'color': Colors.purple,
        'impact': 'АКТИВ',
        'description': localizations.translate('active_bite'),
      };
    } else if (phase.contains('full')) {
      return {
        'icon': '🌕',
        'color': Colors.orange,
        'impact': 'АКТИВ',
        'description': localizations.translate('active_bite'),
      };
    } else if (phase.contains('first quarter')) {
      return {
        'icon': '🌓',
        'color': Colors.blue,
        'impact': 'НОРМА',
        'description': localizations.translate('moderate_bite'),
      };
    } else if (phase.contains('third quarter') || phase.contains('last quarter')) {
      return {
        'icon': '🌗',
        'color': Colors.blue,
        'impact': 'НОРМА',
        'description': localizations.translate('moderate_bite'),
      };
    } else if (phase.contains('waxing crescent')) {
      return {
        'icon': '🌒',
        'color': Colors.grey,
        'impact': 'СЛАБО',
        'description': localizations.translate('weak_bite'),
      };
    } else if (phase.contains('waning crescent')) {
      return {
        'icon': '🌘',
        'color': Colors.grey,
        'impact': 'СЛАБО',
        'description': localizations.translate('weak_bite'),
      };
    } else if (phase.contains('waxing gibbous')) {
      return {
        'icon': '🌔',
        'color': Colors.green,
        'impact': 'ХОРОШО',
        'description': localizations.translate('good_bite'),
      };
    } else if (phase.contains('waning gibbous')) {
      return {
        'icon': '🌖',
        'color': Colors.green,
        'impact': 'ХОРОШО',
        'description': localizations.translate('good_bite'),
      };
    } else {
      return {
        'icon': '🌙',
        'color': Colors.grey,
        'impact': 'Н/Д',
        'description': localizations.translate('no_data'),
      };
    }
  }

  String _translateMoonPhase(String moonPhase) {
    final localizations = AppLocalizations.of(context);
    final phase = moonPhase.toLowerCase();

    final Map<String, String> phaseTranslations = {
      'new moon': localizations.translate('moon_new_moon'),
      'waxing crescent': localizations.translate('moon_waxing_crescent'),
      'first quarter': localizations.translate('moon_first_quarter'),
      'waxing gibbous': localizations.translate('moon_waxing_gibbous'),
      'full moon': localizations.translate('moon_full_moon'),
      'waning gibbous': localizations.translate('moon_waning_gibbous'),
      'last quarter': localizations.translate('moon_last_quarter'),
      'third quarter': localizations.translate('moon_third_quarter'),
      'waning crescent': localizations.translate('moon_waning_crescent'),
    };

    for (final entry in phaseTranslations.entries) {
      if (phase.contains(entry.key)) {
        return entry.value;
      }
    }

    return moonPhase;
  }

  Map<String, dynamic> _getVisibilityStatus(double visibility) {
    final localizations = AppLocalizations.of(context);

    if (visibility >= 10) {
      return {
        'color': Colors.green,
        'description': localizations.translate('excellent_visibility'),
        'icon': Icons.wb_sunny,
      };
    } else if (visibility >= 5) {
      return {
        'color': Colors.lightGreen,
        'description': localizations.translate('good_visibility'),
        'icon': Icons.wb_cloudy,
      };
    } else if (visibility >= 1) {
      return {
        'color': Colors.orange,
        'description': localizations.translate('moderate_visibility'),
        'icon': Icons.cloud,
      };
    } else {
      return {
        'color': Colors.red,
        'description': localizations.translate('poor_visibility'),
        'icon': Icons.foggy,
      };
    }
  }
}

/// Кастомный painter для создания бегающего свечения по краям карточки
class GlowingBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double borderRadius;

  GlowingBorderPainter({
    required this.animation,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Создаем путь по периметру закругленного прямоугольника
    final path = Path()..addRRect(rrect);

    // Вычисляем позицию светящейся точки
    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;
    final distance = pathLength * animation.value;

    final tangent = pathMetrics.getTangentForOffset(distance);
    if (tangent == null) return;

    final position = tangent.position;

    // Создаем градиент для свечения
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: 20));

    // Рисуем свечение
    canvas.drawCircle(position, 20, glowPaint);

    // Рисуем яркую точку
    final brightPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 3, brightPaint);
  }

  @override
  bool shouldRepaint(GlowingBorderPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}