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
        childAspectRatio: 1.35, // Увеличил с 1.2 до 1.35 для большей высоты
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
                padding: const EdgeInsets.all(18), // Увеличил с 16 до 18
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
                    const SizedBox(height: 14), // Увеличил с 12 до 14
                    Text(
                      localizations.translate('pressure'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6), // Увеличил с 4 до 6
                    Text(
                      formattedPressure,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6), // Увеличил с 4 до 6
                    Expanded(
                      child: Text(
                        pressureStatus['description'],
                        style: TextStyle(
                          color: pressureStatus['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.all(18),
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
                    const SizedBox(height: 14),
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        windStatus['description'],
                        style: TextStyle(
                          color: windStatus['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          Text(
            localizations.translate('moon_phase'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              _translateMoonPhase(moonPhase),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
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
    final dewPoint = _calculateDewPoint(
      widget.weather.current.tempC,
      humidity,
    );
    final humidityStatus = _getHumidityStatus(humidity);

    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          Text(
            'Влажность',
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
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
                  'Точка росы: ${dewPoint.round()}°',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для анализа данных

  String _getPressureTrend() {
    final pressure = widget.weather.current.pressureMb;
    if (pressure > 1020) return 'stable';
    if (pressure > 1010) return 'rising';
    return 'falling';
  }

  Map<String, dynamic> _getPressureStatus(double pressure) {
    if (pressure >= 1010 && pressure <= 1025) {
      return {
        'color': Colors.green,
        'description': 'Нормальное',
      };
    } else if (pressure < 1000) {
      return {
        'color': Colors.red,
        'description': 'Низкое давление',
      };
    } else if (pressure > 1030) {
      return {
        'color': Colors.orange,
        'description': 'Высокое давление',
      };
    } else {
      return {
        'color': Colors.orange,
        'description': 'Умеренное',
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
    if (windKph < 10) {
      return {
        'color': Colors.green,
        'description': 'Отлично для рыбалки',
      };
    } else if (windKph < 20) {
      return {
        'color': Colors.lightGreen,
        'description': 'Хорошо для рыбалки',
      };
    } else if (windKph < 30) {
      return {
        'color': Colors.orange,
        'description': 'Умеренно для рыбалки',
      };
    } else {
      return {
        'color': Colors.red,
        'description': 'Сложно для рыбалки',
      };
    }
  }

  String _translateWindDirection(String direction) {
    final Map<String, String> translations = {
      'N': 'С', 'NNE': 'ССВ', 'NE': 'СВ', 'ENE': 'ВСВ',
      'E': 'В', 'ESE': 'ВЮВ', 'SE': 'ЮВ', 'SSE': 'ЮЮВ',
      'S': 'Ю', 'SSW': 'ЮЮЗ', 'SW': 'ЮЗ', 'WSW': 'ЗЮЗ',
      'W': 'З', 'WNW': 'ЗСЗ', 'NW': 'СЗ', 'NNW': 'ССЗ',
    };
    return translations[direction] ?? direction;
  }

  Map<String, dynamic> _getMoonPhaseInfo(String moonPhase) {
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new')) {
      return {
        'icon': '🌑',
        'color': Colors.purple,
        'impact': 'АКТИВ',
        'description': 'Активная фаза',
      };
    } else if (phase.contains('full')) {
      return {
        'icon': '🌕',
        'color': Colors.orange,
        'impact': 'АКТИВ',
        'description': 'Активная фаза',
      };
    } else if (phase.contains('first quarter')) {
      return {
        'icon': '🌓',
        'color': Colors.blue,
        'impact': 'НОРМА',
        'description': 'Умеренная активность',
      };
    } else if (phase.contains('third quarter') || phase.contains('last quarter')) {
      return {
        'icon': '🌗',
        'color': Colors.blue,
        'impact': 'НОРМА',
        'description': 'Умеренная активность',
      };
    } else if (phase.contains('waxing crescent')) {
      return {
        'icon': '🌒',
        'color': Colors.grey,
        'impact': 'СЛАБО',
        'description': 'Слабая активность',
      };
    } else if (phase.contains('waning crescent')) {
      return {
        'icon': '🌘',
        'color': Colors.orange,
        'impact': 'СРЕДНЕ',
        'description': 'Умеренная активность',
      };
    } else if (phase.contains('waxing gibbous')) {
      return {
        'icon': '🌔',
        'color': Colors.green,
        'impact': 'ХОРОШО',
        'description': 'Хорошая активность',
      };
    } else if (phase.contains('waning gibbous')) {
      return {
        'icon': '🌖',
        'color': Colors.green,
        'impact': 'ХОРОШО',
        'description': 'Хорошая активность',
      };
    } else {
      return {
        'icon': '🌙',
        'color': Colors.grey,
        'impact': 'Н/Д',
        'description': 'Нет данных',
      };
    }
  }

  String _translateMoonPhase(String moonPhase) {
    final phase = moonPhase.toLowerCase();

    if (phase.contains('new')) return 'Новолуние';
    if (phase.contains('full')) return 'Полнолуние';
    if (phase.contains('first quarter')) return 'Первая четверть';
    if (phase.contains('third quarter') || phase.contains('last quarter')) return 'Последняя четверть';
    if (phase.contains('waxing crescent')) return 'Растущий серп';
    if (phase.contains('waning crescent')) return 'Растущая луна';
    if (phase.contains('waxing gibbous')) return 'Растущая луна';
    if (phase.contains('waning gibbous')) return 'Убывающая луна';

    return 'Неизвестно';
  }

  Map<String, dynamic> _getHumidityStatus(int humidity) {
    if (humidity >= 40 && humidity <= 60) {
      return {
        'color': Colors.green,
        'description': 'Комфортно',
        'badge': 'НОРМА',
      };
    } else if (humidity < 30) {
      return {
        'color': Colors.orange,
        'description': 'Сухо',
        'badge': 'СУХО',
      };
    } else if (humidity > 80) {
      return {
        'color': Colors.blue,
        'description': 'Влажно',
        'badge': 'ВЛАЖНО',
      };
    } else {
      return {
        'color': Colors.lightGreen,
        'description': 'Приемлемо',
        'badge': 'ОК',
      };
    }
  }

  double _calculateDewPoint(double tempC, int humidity) {
    // Упрощенная формула расчета точки росы
    final a = 17.27;
    final b = 237.7;
    final alpha = ((a * tempC) / (b + tempC)) + math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
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

    // Создаем более яркое свечение
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: 25));

    // Рисуем свечение
    canvas.drawCircle(position, 25, glowPaint);

    // Рисуем более яркую точку
    final brightPaint = Paint()
      ..color = color.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4, brightPaint);

    // Добавляем дополнительное внешнее свечение
    final outerGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 15, outerGlowPaint);
  }

  @override
  bool shouldRepaint(GlowingBorderPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}