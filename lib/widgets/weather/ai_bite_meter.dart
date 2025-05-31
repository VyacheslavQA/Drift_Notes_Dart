// Путь: lib/widgets/weather/ai_bite_meter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../localization/app_localizations.dart';
import '../animated_border_widget.dart';
import '../../screens/weather/fishing_type_detail_screen.dart';

class AIBiteMeter extends StatefulWidget {
  final MultiFishingTypePrediction? aiPrediction;
  final VoidCallback? onCompareTypes;
  final Function(String)? onSelectType;
  final List<String>? preferredTypes;

  const AIBiteMeter({
    super.key,
    this.aiPrediction,
    this.onCompareTypes,
    this.onSelectType,
    this.preferredTypes,
  });

  @override
  State<AIBiteMeter> createState() => _AIBiteMeterState();
}

class _AIBiteMeterState extends State<AIBiteMeter>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _pulseController;
  late AnimationController _needleController;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _needleAnimation;

  // Конфигурация типов рыбалки с иконками
  static const Map<String, Map<String, String>> fishingTypes = {
    'carp_fishing': {
      'name': 'Карповая рыбалка',
      'icon': 'assets/images/fishing_types/carp_fishing.png',
      'nameKey': 'carp_fishing',
    },
    'feeder': {
      'name': 'Фидер',
      'icon': 'assets/images/fishing_types/feeder.png',
      'nameKey': 'feeder',
    },
    'float_fishing': {
      'name': 'Поплавочная',
      'icon': 'assets/images/fishing_types/float_fishing.png',
      'nameKey': 'float_fishing',
    },
    'fly_fishing': {
      'name': 'Нахлыст',
      'icon': 'assets/images/fishing_types/fly_fishing.png',
      'nameKey': 'fly_fishing',
    },
    'ice_fishing': {
      'name': 'Зимняя рыбалка',
      'icon': 'assets/images/fishing_types/ice_fishing.png',
      'nameKey': 'ice_fishing',
    },
    'spinning': {
      'name': 'Спиннинг',
      'icon': 'assets/images/fishing_types/spinning.png',
      'nameKey': 'spinning',
    },
    'trolling': {
      'name': 'Троллинг',
      'icon': 'assets/images/fishing_types/trolling.png',
      'nameKey': 'trolling',
    },
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _needleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _gaugeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gaugeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _needleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _needleController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _gaugeController.forward();
    _needleController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _needleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<String> _getFilteredTypes() {
    if (widget.preferredTypes != null && widget.preferredTypes!.isNotEmpty) {
      return widget.preferredTypes!;
    }
    return fishingTypes.keys.toList();
  }

  String _getBestFilteredType() {
    if (widget.aiPrediction == null) return 'spinning';

    final filteredTypes = _getFilteredTypes();
    final rankings = widget.aiPrediction!.comparison.rankings;

    for (final ranking in rankings) {
      if (filteredTypes.contains(ranking.fishingType)) {
        return ranking.fishingType;
      }
    }

    return filteredTypes.isNotEmpty ? filteredTypes.first : 'spinning';
  }

  int _getBestFilteredScore() {
    if (widget.aiPrediction == null) return 50;

    final bestType = _getBestFilteredType();
    final prediction = widget.aiPrediction!.allPredictions[bestType];
    return prediction?.overallScore ?? 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (widget.aiPrediction == null) {
      return _buildLoadingState(localizations);
    }

    return _buildSpeedometerContent(localizations);
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧠', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('ai_bite_forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('ai_analyzing_fishing'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerContent(AppLocalizations localizations) {
    final score = _getBestFilteredScore();
    final bestType = _getBestFilteredType();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1B3A36),
            const Color(0xFF0F2A26),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок
          _buildHeader(localizations),

          const SizedBox(height: 20),

          // Главный спидометр
          _buildSpeedometer(score, localizations),

          const SizedBox(height: 24),

          // Горизонтальный скролл типов рыбалки
          _buildFishingTypesScroll(localizations, bestType),

          const SizedBox(height: 24),

          // Информация о погоде - СТОЛБИК
          _buildWeatherInfo(localizations),

          const SizedBox(height: 20),

          // Кнопка подробнее
          _buildDetailsButton(localizations),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.3),
                Colors.cyan.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('🧠', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('ai_bite_forecast'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${localizations.translate('confidence')}: ${widget.aiPrediction!.bestPrediction.confidencePercent}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedometer(int score, AppLocalizations localizations) {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _gaugeAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: SpeedometerPainter(
              progress: _gaugeAnimation.value,
              score: score,
              needleProgress: _needleAnimation.value,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Размещаем цифры в верхней части круга
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: score >= 80 ? _pulseAnimation.value : 1.0,
                        child: Text(
                          '${(_gaugeAnimation.value * score).round()}',
                          style: TextStyle(
                            color: _getScoreTextColor(score),
                            fontSize: 42,
                            fontWeight: FontWeight.w200,
                            height: 1.0,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'КЛЁВ: ${_getScoreText(score, localizations).toUpperCase()}',
                    style: TextStyle(
                      color: _getScoreTextColor(score),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFishingTypesScroll(AppLocalizations localizations, String bestType) {
    final allTypes = fishingTypes.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Типы рыбалки',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: allTypes.length,
            itemBuilder: (context, index) {
              final type = allTypes[index];
              final typeInfo = fishingTypes[type]!;
              final isBest = type == bestType;
              final prediction = widget.aiPrediction!.allPredictions[type];
              final score = prediction?.overallScore ?? 0;

              return GestureDetector(
                onTap: () => _openFishingTypeDetail(type, localizations),
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isBest
                        ? Colors.green.withValues(alpha: 0.3)
                        : _getScoreColor(score).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBest
                          ? Colors.green.withValues(alpha: 0.6)
                          : _getScoreColor(score).withValues(alpha: 0.4),
                      width: isBest ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Увеличенная иконка
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            typeInfo['icon']!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            color: isBest ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports,
                                size: 36,
                                color: isBest ? Colors.white : Colors.white.withValues(alpha: 0.8),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Название на 2 строки
                        Text(
                          localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfo(AppLocalizations localizations) {
    final weatherSummary = widget.aiPrediction!.weatherSummary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Основная рекомендация - 2 строки максимум
          Text(
            widget.aiPrediction!.bestPrediction.recommendation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Параметры в столбик с описаниями
          _buildWeatherMetricRow('🌡️', '${(weatherSummary.pressure / 1.333).round()} мм', 'Атмосферное давление'),
          const SizedBox(height: 8),
          _buildWeatherMetricRow('💨', '${(weatherSummary.windSpeed / 3.6).round()} м/с', 'Скорость ветра'),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
              '🌙',
              weatherSummary.moonPhase.length > 12
                  ? '${weatherSummary.moonPhase.substring(0, 12)}...'
                  : weatherSummary.moonPhase,
              'Фаза луны'
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow('💧', '${weatherSummary.humidity}%', 'Влажность воздуха'),
          const SizedBox(height: 8),
          _buildWeatherMetricRow('🕐', '05:00-06:30', 'Лучшее время'),
          const SizedBox(height: 8),
          _buildWeatherMetricRow('⭐', '${_getBestFilteredScore()}/100', 'Общий балл клёва'),
        ],
      ),
    );
  }

  Widget _buildWeatherMetricRow(String icon, String value, String description) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onCompareTypes,
        icon: const Icon(Icons.analytics, size: 18),
        label: Text(
          localizations.translate('more_details'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _openFishingTypeDetail(String type, AppLocalizations localizations) {
    final prediction = widget.aiPrediction!.allPredictions[type];
    if (prediction == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingTypeDetailScreen(
          fishingType: type,
          prediction: prediction,
          typeInfo: fishingTypes[type]!,
        ),
      ),
    );
  }

  // Вспомогательные методы
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getScoreTextColor(int score) {
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 60) return const Color(0xFF9CCC65);
    if (score >= 40) return const Color(0xFFFFCA28);
    if (score >= 20) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  String _getScoreText(int score, AppLocalizations localizations) {
    if (score >= 80) return 'отличный';
    if (score >= 60) return 'хороший';
    if (score >= 40) return 'средний';
    if (score >= 20) return 'слабый';
    return 'очень слабый';
  }
}

// Кастомный painter для спидометра с треугольником ОСТРИЕМ НАРУЖУ
class SpeedometerPainter extends CustomPainter {
  final double progress;
  final int score;
  final double needleProgress;

  SpeedometerPainter({
    required this.progress,
    required this.score,
    required this.needleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final radius = size.width * 0.32;

    // Рисуем фоновую дугу
    _drawBackgroundArc(canvas, center, radius);

    // Рисуем цветную дугу (градиент)
    _drawColoredArc(canvas, center, radius);

    // Рисуем треугольник НА ДУГЕ (острием НАРУЖУ)
    _drawTriangleOnArc(canvas, center, radius);
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi + 0.4;
    const sweepAngle = math.pi - 0.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawColoredArc(Canvas canvas, Offset center, double radius) {
    const startAngle = math.pi + 0.4;
    const totalSweepAngle = math.pi - 0.8;
    final currentSweepAngle = totalSweepAngle * progress;

    // Создаем градиент
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalSweepAngle,
      colors: const [
        Color(0xFFEF5350), // Красный
        Color(0xFFFF9800), // Оранжевый
        Color(0xFFFFC107), // Желтый
        Color(0xFF8BC34A), // Светло-зеленый
        Color(0xFF4CAF50), // Зеленый
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweepAngle,
      false,
      paint,
    );
  }

  void _drawTriangleOnArc(Canvas canvas, Offset center, double radius) {
    if (needleProgress == 0) return;

    const startAngle = math.pi + 0.4;
    const totalSweepAngle = math.pi - 0.8;
    final scoreProgress = score / 100.0;
    final triangleAngle = startAngle + (totalSweepAngle * scoreProgress * needleProgress);

    // Позиция треугольника НА ВНУТРЕННЕЙ СТОРОНЕ ДУГИ (ближе к центру)
    final innerRadius = radius - 8; // Сдвигаем треугольник ближе к центру
    final trianglePosition = Offset(
      center.dx + innerRadius * math.cos(triangleAngle),
      center.dy + innerRadius * math.sin(triangleAngle),
    );

    const triangleSize = 12.0;

    // Треугольник острием НАРУЖУ (к дуге)
    final path = Path();

    // Острие треугольника направлено К ДУГЕ (наружу от центра)
    final tip = Offset(
      trianglePosition.dx + 12 * math.cos(triangleAngle), // Острие к дуге
      trianglePosition.dy + 12 * math.sin(triangleAngle),
    );

    // Два угла основания треугольника (перпендикулярно к радиусу)
    final perpAngle1 = triangleAngle + math.pi / 2;
    final perpAngle2 = triangleAngle - math.pi / 2;

    final leftBase = Offset(
      trianglePosition.dx + triangleSize * 0.5 * math.cos(perpAngle1),
      trianglePosition.dy + triangleSize * 0.5 * math.sin(perpAngle1),
    );

    final rightBase = Offset(
      trianglePosition.dx + triangleSize * 0.5 * math.cos(perpAngle2),
      trianglePosition.dy + triangleSize * 0.5 * math.sin(perpAngle2),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(leftBase.dx, leftBase.dy);
    path.lineTo(rightBase.dx, rightBase.dy);
    path.close();

    // Тень треугольника
    final shadowPath = Path();
    final shadowOffset = const Offset(1.5, 1.5);

    shadowPath.moveTo(tip.dx + shadowOffset.dx, tip.dy + shadowOffset.dy);
    shadowPath.lineTo(leftBase.dx + shadowOffset.dx, leftBase.dy + shadowOffset.dy);
    shadowPath.lineTo(rightBase.dx + shadowOffset.dx, rightBase.dy + shadowOffset.dy);
    shadowPath.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    canvas.drawPath(shadowPath, shadowPaint);

    // Основной треугольник - белый цвет
    final trianglePaint = Paint()
      ..color = Colors.white // Белый цвет
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, trianglePaint);

    // Обводка треугольника
    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}