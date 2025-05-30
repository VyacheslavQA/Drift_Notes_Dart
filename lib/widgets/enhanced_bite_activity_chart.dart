// Путь: lib/widgets/enhanced_bite_activity_chart.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../models/weather_api_model.dart';
import '../localization/app_localizations.dart';

/// Улучшенный график активности клева в стиле временных зон
class EnhancedBiteActivityChart extends StatefulWidget {
  final Map<String, dynamic>? fishingForecast;
  final WeatherApiResponse? weatherData;
  final double height;
  final String? selectedFishingType;
  final Function(int hour, double activity)? onTimeSlotTapped;

  const EnhancedBiteActivityChart({
    super.key,
    this.fishingForecast,
    this.weatherData,
    this.height = 280,
    this.selectedFishingType,
    this.onTimeSlotTapped,
  });

  @override
  State<EnhancedBiteActivityChart> createState() => _EnhancedBiteActivityChartState();
}

class _EnhancedBiteActivityChartState extends State<EnhancedBiteActivityChart>
    with TickerProviderStateMixin {

  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _animationValue;
  late Animation<double> _glowAnimation;

  List<ActivityPoint> _activityPoints = [];
  double? _sunriseHour;
  double? _sunsetHour;
  int? _tappedHour;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateActivityData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedBiteActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherData != widget.weatherData ||
        oldWidget.fishingForecast != widget.fishingForecast) {
      _generateActivityData();
    }
  }

  void _generateActivityData() {
    _activityPoints.clear();

    // Получаем данные астрономии
    if (widget.weatherData?.forecast.isNotEmpty == true) {
      final astro = widget.weatherData!.forecast.first.astro;
      _sunriseHour = _parseTimeToHour(astro.sunrise);
      _sunsetHour = _parseTimeToHour(astro.sunset);
    }

    // Генерируем 24 точки активности (каждый час)
    for (int hour = 0; hour < 24; hour++) {
      final activity = _calculateHourlyActivity(hour);
      _activityPoints.add(ActivityPoint(
        hour: hour,
        activity: activity,
        zone: _getTimeZone(hour),
        quality: _getActivityQuality(activity),
      ));
    }

    if (mounted) setState(() {});
  }

  double _calculateHourlyActivity(int hour) {
    double baseActivity = 0.1;

    // Утренний пик (5-9 часов)
    if (hour >= 5 && hour <= 9) {
      final peak = 7.0;
      final distance = (hour - peak).abs();
      baseActivity = 0.9 - (distance * 0.15);
    }
    // Вечерний пик (17-21 час)
    else if (hour >= 17 && hour <= 21) {
      final peak = 19.0;
      final distance = (hour - peak).abs();
      baseActivity = 0.95 - (distance * 0.12);
    }
    // Дневная активность (10-16 часов)
    else if (hour >= 10 && hour <= 16) {
      baseActivity = 0.3 + math.sin((hour - 13) * 0.4) * 0.15;
    }
    // Ночная активность (22-4 часа)
    else if (hour >= 22 || hour <= 4) {
      baseActivity = 0.05 + math.sin(hour * 0.3) * 0.05;
    }

    // Корректировки по типу рыбалки
    baseActivity = _applyFishingTypeModifiers(baseActivity, hour);

    // Корректировки по погоде
    if (widget.fishingForecast != null) {
      baseActivity = _applyWeatherModifiers(baseActivity);
    }

    // Бонус за астрономические события
    if (_sunriseHour != null && (hour - _sunriseHour!).abs() <= 1) {
      baseActivity *= 1.2;
    }
    if (_sunsetHour != null && (hour - _sunsetHour!).abs() <= 1) {
      baseActivity *= 1.15;
    }

    return baseActivity.clamp(0.0, 1.0);
  }

  double _applyFishingTypeModifiers(double baseActivity, int hour) {
    final type = widget.selectedFishingType ?? 'spinning';

    switch (type) {
      case 'carp_fishing':
        if (hour >= 22 || hour <= 6) baseActivity *= 1.3;
        if (hour >= 12 && hour <= 16) baseActivity *= 0.7;
        break;
      case 'feeder':
        if (hour >= 5 && hour <= 10) baseActivity *= 1.2;
        if (hour >= 17 && hour <= 22) baseActivity *= 1.25;
        break;
      case 'ice_fishing':
        if (hour >= 8 && hour <= 14) baseActivity *= 1.2;
        if (hour >= 22 || hour <= 5) baseActivity *= 0.6;
        break;
      default: // spinning
        if (hour >= 5 && hour <= 9) baseActivity *= 1.15;
        if (hour >= 18 && hour <= 21) baseActivity *= 1.2;
    }

    return baseActivity;
  }

  double _applyWeatherModifiers(double baseActivity) {
    final factors = widget.fishingForecast!['factors'] as Map<String, dynamic>?;
    if (factors != null) {
      final pressure = factors['pressure']?['value'] as double?;
      if (pressure != null) {
        if (pressure > 0.7) baseActivity *= 1.15;
        else if (pressure < 0.4) baseActivity *= 0.8;
      }

      final wind = factors['wind']?['value'] as double?;
      if (wind != null) {
        if (wind > 0.4 && wind < 0.8) baseActivity *= 1.1;
        else if (wind < 0.3) baseActivity *= 0.85;
      }

      final moon = factors['moon']?['value'] as double?;
      if (moon != null) {
        baseActivity *= (0.9 + moon * 0.2);
      }
    }

    return baseActivity;
  }

  TimeZone _getTimeZone(int hour) {
    if (hour >= 5 && hour <= 11) return TimeZone.morning;
    if (hour >= 12 && hour <= 17) return TimeZone.day;
    if (hour >= 18 && hour <= 21) return TimeZone.evening;
    return TimeZone.night;
  }

  ActivityQuality _getActivityQuality(double activity) {
    if (activity > 0.8) return ActivityQuality.ideal;
    if (activity > 0.6) return ActivityQuality.good;
    if (activity > 0.3) return ActivityQuality.poor;
    return ActivityQuality.noActivity;
  }

  double? _parseTimeToHour(String timeStr) {
    try {
      final cleanTime = timeStr.trim().toLowerCase();
      final parts = cleanTime.split(':');

      if (parts.length >= 2) {
        final hourPart = parts[0];
        final minuteAndPeriod = parts[1].split(' ');

        var hour = int.tryParse(hourPart) ?? 0;
        final minute = int.tryParse(minuteAndPeriod[0]) ?? 0;

        if (minuteAndPeriod.length > 1) {
          final period = minuteAndPeriod[1];
          if (period == 'pm' && hour != 12) {
            hour += 12;
          } else if (period == 'am' && hour == 12) {
            hour = 0;
          }
        }

        return hour + (minute / 60.0);
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга времени "$timeStr": $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.translate('bite_activity'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '24${localizations.translate('hours')}',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // График
          Expanded(
            child: AnimatedBuilder(
              animation: _animationValue,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: BiteActivityPainter(
                    activityPoints: _activityPoints,
                    sunriseHour: _sunriseHour,
                    sunsetHour: _sunsetHour,
                    animationProgress: _animationValue.value,
                    glowAnimation: _glowAnimation.value,
                    tappedHour: _tappedHour,
                    textColor: AppConstants.textColor,
                  ),
                );
              },
            ),
          ),

          // Нижняя легенда
          _buildLegend(localizations),
        ],
      ),
    );
  }

  Widget _buildLegend(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Цветовая легенда
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                color: const Color(0xFF4CAF50),
                label: localizations.translate('excellent'),
                icon: Icons.thumb_up,
              ),
              _buildLegendItem(
                color: const Color(0xFF8BC34A),
                label: localizations.translate('good'),
                icon: Icons.thumb_up_outlined,
              ),
              _buildLegendItem(
                color: const Color(0xFFFF9800),
                label: localizations.translate('poor'),
                icon: Icons.thumb_down_outlined,
              ),
              _buildLegendItem(
                color: const Color(0xFF9E9E9E),
                label: localizations.translate('no'),
                icon: Icons.close,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Астрономические события
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAstroLegend(Icons.wb_twilight, 'Восход', Colors.orange),
              const SizedBox(width: 24),
              _buildAstroLegend(Icons.nights_stay, 'Закат', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAstroLegend(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
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
}

/// Кастомный painter для рисования графика активности
class BiteActivityPainter extends CustomPainter {
  final List<ActivityPoint> activityPoints;
  final double? sunriseHour;
  final double? sunsetHour;
  final double animationProgress;
  final double glowAnimation;
  final int? tappedHour;
  final Color textColor;

  BiteActivityPainter({
    required this.activityPoints,
    this.sunriseHour,
    this.sunsetHour,
    required this.animationProgress,
    required this.glowAnimation,
    this.tappedHour,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activityPoints.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Рисуем фоновый градиент временных зон
    _drawTimeZoneBackground(canvas, size);

    // Рисуем кривую активности
    _drawActivityCurve(canvas, size);

    // Рисуем временные метки
    _drawTimeLabels(canvas, size);

    // Рисуем астрономические события
    _drawAstronomicalEvents(canvas, size);

    // Рисуем зоны активности
    _drawActivityZones(canvas, size);
  }

  void _drawTimeZoneBackground(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF1A237E).withValues(alpha: 0.3), // Ночь
        const Color(0xFF3F51B5).withValues(alpha: 0.4), // Утро
        const Color(0xFF2196F3).withValues(alpha: 0.3), // День
        const Color(0xFFFF9800).withValues(alpha: 0.4), // Вечер
        const Color(0xFF1A237E).withValues(alpha: 0.3), // Ночь
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawActivityCurve(Canvas canvas, Size size) {
    if (activityPoints.length < 2) return;

    final path = Path();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Создаем путь кривой
    for (int i = 0; i < activityPoints.length; i++) {
      final point = activityPoints[i];
      final x = (i / (activityPoints.length - 1)) * size.width;
      final y = size.height - (point.activity * animationProgress * size.height * 0.7) - size.height * 0.15;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Используем плавные кривые
        final prevPoint = activityPoints[i - 1];
        final prevX = ((i - 1) / (activityPoints.length - 1)) * size.width;
        final prevY = size.height - (prevPoint.activity * animationProgress * size.height * 0.7) - size.height * 0.15;

        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    // Градиентная заливка под кривой
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF4CAF50).withValues(alpha: 0.6),
        const Color(0xFF4CAF50).withValues(alpha: 0.1),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Рисуем основную кривую
    final curveGradient = LinearGradient(
      colors: [
        const Color(0xFF4CAF50),
        const Color(0xFFFFC107),
        const Color(0xFFFF9800),
      ],
    );
    paint.shader = curveGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  void _drawTimeLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final times = ['00:00', '06:00', '12:00', '18:00', '00:00'];
    final zones = ['Night', 'Morning', 'Day', 'Evening', 'Night'];

    for (int i = 0; i < times.length; i++) {
      final x = (i / (times.length - 1)) * size.width;

      // Время
      textPainter.text = TextSpan(
        text: times[i],
        style: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - textPainter.height - 4),
      );

      // Зона времени (кроме последней)
      if (i < zones.length - 1) {
        textPainter.text = TextSpan(
          text: zones[i],
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();

        final zoneX = i == 0 ? x + 40 : (x + ((i + 1) / (times.length - 1)) * size.width) / 2;
        textPainter.paint(
          canvas,
          Offset(zoneX - textPainter.width / 2, 20),
        );
      }
    }
  }

  void _drawAstronomicalEvents(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Восход солнца
    if (sunriseHour != null) {
      final x = (sunriseHour! / 24) * size.width;
      final y = size.height - (_getActivityAtHour(sunriseHour!) * animationProgress * size.height * 0.7) - size.height * 0.15;

      // Анимированное свечение
      paint.color = Colors.orange.withValues(alpha: 0.3 * glowAnimation);
      canvas.drawCircle(Offset(x, y), 20 * glowAnimation, paint);

      // Иконка восхода
      _drawIcon(canvas, Offset(x, y), Icons.wb_twilight, Colors.orange, 16);
    }

    // Закат
    if (sunsetHour != null) {
      final x = (sunsetHour! / 24) * size.width;
      final y = size.height - (_getActivityAtHour(sunsetHour!) * animationProgress * size.height * 0.7) - size.height * 0.15;

      // Анимированное свечение
      paint.color = Colors.indigo.withValues(alpha: 0.3 * glowAnimation);
      canvas.drawCircle(Offset(x, y), 20 * glowAnimation, paint);

      // Иконка заката
      _drawIcon(canvas, Offset(x, y), Icons.nights_stay, Colors.indigo, 16);
    }
  }

  void _drawActivityZones(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < activityPoints.length; i++) {
      final point = activityPoints[i];
      if (point.quality == ActivityQuality.noActivity) continue;

      final x = (i / (activityPoints.length - 1)) * size.width;
      final y = size.height - (point.activity * animationProgress * size.height * 0.7) - size.height * 0.15;

      // Точка активности
      final paint = Paint()..style = PaintingStyle.fill;

      if (point.quality == ActivityQuality.ideal) {
        paint.color = const Color(0xFF4CAF50);
        canvas.drawCircle(Offset(x, y), 6, paint);

        // Надпись "Ideal"
        textPainter.text = TextSpan(
          text: 'Ideal',
          style: TextStyle(
            color: const Color(0xFF4CAF50),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        final labelX = x - textPainter.width / 2;
        final labelY = y - 25;

        // Фон для текста
        final bgPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;

        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(labelX - 8, labelY - 2, textPainter.width + 16, textPainter.height + 4),
          const Radius.circular(12),
        );
        canvas.drawRRect(bgRect, bgPaint);

        textPainter.paint(canvas, Offset(labelX, labelY));
      } else if (point.quality == ActivityQuality.good) {
        paint.color = const Color(0xFF8BC34A);
        canvas.drawCircle(Offset(x, y), 4, paint);
      } else if (point.quality == ActivityQuality.poor) {
        paint.color = const Color(0xFFFF9800);
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  void _drawIcon(Canvas canvas, Offset center, IconData iconData, Color color, double size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        color: color,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  double _getActivityAtHour(double hour) {
    final index = hour.round().clamp(0, activityPoints.length - 1);
    return activityPoints[index].activity;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Модели данных

class ActivityPoint {
  final int hour;
  final double activity;
  final TimeZone zone;
  final ActivityQuality quality;

  ActivityPoint({
    required this.hour,
    required this.activity,
    required this.zone,
    required this.quality,
  });
}

enum TimeZone { morning, day, evening, night }

enum ActivityQuality { ideal, good, poor, noActivity }