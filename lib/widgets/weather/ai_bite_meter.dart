// Путь: lib/widgets/weather/ai_bite_meter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../localization/app_localizations.dart';

class AIBiteMeter extends StatefulWidget {
  final MultiFishingTypePrediction? aiPrediction;
  final VoidCallback? onCompareTypes;
  final Function(String)? onSelectType;
  final String? selectedFishingType;

  const AIBiteMeter({
    super.key,
    this.aiPrediction,
    this.onCompareTypes,
    this.onSelectType,
    this.selectedFishingType,
  });

  @override
  State<AIBiteMeter> createState() => _AIBiteMeterState();
}

class _AIBiteMeterState extends State<AIBiteMeter>
    with TickerProviderStateMixin {
  late AnimationController _meterController;
  late AnimationController _pulseController;
  late AnimationController _factorsController;
  late Animation<double> _meterAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _factorsAnimation;

  String _currentSelectedType = 'spinning';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _currentSelectedType = widget.selectedFishingType ??
        widget.aiPrediction?.bestFishingType ?? 'spinning';
  }

  void _initAnimations() {
    _meterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _factorsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _meterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _meterController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _factorsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _factorsController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Запускаем анимации
    _meterController.forward();
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _factorsController.forward();
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _pulseController.dispose();
    _factorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiPrediction == null) {
      return _buildLoadingState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getCurrentPrediction().scoreColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCurrentPrediction().scoreColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAIMeter(),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildRecommendation(),
            const SizedBox(height: 16),
            _buildTopFactors(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '🧠 ${localizations.translate('ai_analyzing_fishing')}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                strokeWidth: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('ai_analyzing_fishing'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context);
    final prediction = _getCurrentPrediction();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.psychology,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 ${localizations.translate('ai_bite_forecast')}',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${localizations.translate('confidence')}: ${prediction.confidencePercent}%',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'AI v${widget.aiPrediction!.bestPrediction.modelVersion}',
            style: const TextStyle(
              color: Colors.purple,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIMeter() {
    final prediction = _getCurrentPrediction();
    final score = prediction.overallScore;

    return AnimatedBuilder(
      animation: _meterAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: score >= 80 ? _pulseAnimation.value : 1.0,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  children: [
                    // Фоновая окружность
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.textColor.withValues(alpha: 0.1),
                          width: 12,
                        ),
                      ),
                    ),
                    // ИИ прогресс
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: FixedAIBiteMeterPainter(
                        progress: (score / 100.0) * _meterAnimation.value.clamp(0.0, 1.0),
                        color: prediction.scoreColor,
                        showSpark: score >= 80,
                        animationValue: _meterAnimation.value.clamp(0.0, 1.0),
                      ),
                    ),
                    // Центральный контент
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(score * _meterAnimation.value.clamp(0.0, 1.0)).round()}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).translate('points'),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: prediction.scoreColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prediction.activityLevel.displayName,
                              style: TextStyle(
                                color: prediction.scoreColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    final localizations = AppLocalizations.of(context);

    if (widget.aiPrediction == null) return const SizedBox();

    final rankings = widget.aiPrediction!.comparison.rankings.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              localizations.translate('select_fishing_type'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (widget.onCompareTypes != null)
              GestureDetector(
                onTap: widget.onCompareTypes,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localizations.translate('all_types'),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: rankings.map((ranking) => _buildTypeChip(ranking)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(FishingTypeRanking ranking) {
    final isSelected = _currentSelectedType == ranking.fishingType;
    final isBest = ranking.fishingType == widget.aiPrediction!.bestFishingType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSelectedType = ranking.fishingType;
        });
        widget.onSelectType?.call(ranking.fishingType);

        // Перезапускаем анимацию при смене типа
        _meterController.reset();
        _meterController.forward();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ranking.scoreColor.withValues(alpha: 0.2)
              : AppConstants.backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ranking.scoreColor
                : AppConstants.textColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ranking.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ranking.typeName,
                      style: TextStyle(
                        color: isSelected
                            ? ranking.scoreColor
                            : AppConstants.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 12,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${ranking.score} ${AppLocalizations.of(context).translate('points')}',
                  style: TextStyle(
                    color: isSelected
                        ? ranking.scoreColor
                        : AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation() {
    final localizations = AppLocalizations.of(context);
    final prediction = _getCurrentPrediction();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: prediction.scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: prediction.scoreColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: prediction.scoreColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('ai_recommendation'),
                style: TextStyle(
                  color: prediction.scoreColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prediction.recommendation,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFactors() {
    final localizations = AppLocalizations.of(context);
    final prediction = _getCurrentPrediction();
    final topFactors = prediction.factors.take(3).toList();

    if (topFactors.isEmpty) return const SizedBox();

    return AnimatedBuilder(
      animation: _factorsAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('key_factors'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...topFactors.asMap().entries.map((entry) {
              final index = entry.key;
              final factor = entry.value;
              final delay = index * 0.2;
              final animationValue = _factorsAnimation.value.clamp(0.0, 1.0);
              final delayedValue = (animationValue - delay).clamp(0.0, 1.0);

              return FadeTransition(
                opacity: AlwaysStoppedAnimation(delayedValue),
                child: _buildFactorItem(factor),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFactorItem(BiteFactorAnalysis factor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: factor.impactColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            factor.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.name,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  factor.description,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: factor.impactColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${factor.impact > 0 ? '+' : ''}${factor.impact}',
              style: TextStyle(
                color: factor.impactColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final localizations = AppLocalizations.of(context);
    final prediction = _getCurrentPrediction();
    final nextWindow = prediction.nextBestTimeWindow;

    return Row(
      children: [
        // Следующее лучшее время
        if (nextWindow != null)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.translate('best_time'),
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextWindow.timeRange,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextWindow.timeUntilStartText != null)
                    Text(
                      nextWindow.timeUntilStartText!,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),

        if (nextWindow != null) const SizedBox(width: 12),

        // Кнопка подробнее
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDetailedAnalysis(),
            icon: const Icon(Icons.analytics, size: 16),
            label: Text(
              localizations.translate('more_details'),
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательные методы
  AIBitePrediction _getCurrentPrediction() {
    if (widget.aiPrediction == null) {
      // Fallback
      return AIBitePrediction(
        overallScore: 50,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.5,
        recommendation: AppLocalizations.of(context).translate('basic_recommendation'),
        detailedAnalysis: AppLocalizations.of(context).translate('analysis_unavailable'),
        factors: [],
        bestTimeWindows: [],
        tips: [],
        generatedAt: DateTime.now(),
        dataSource: 'fallback',
        modelVersion: '1.0.0',
      );
    }

    return widget.aiPrediction!.allPredictions[_currentSelectedType] ??
        widget.aiPrediction!.bestPrediction;
  }

  void _showDetailedAnalysis() {
    final localizations = AppLocalizations.of(context);
    final prediction = _getCurrentPrediction();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.translate('detailed_ai_analysis'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Анализ
                      Text(
                        localizations.translate('detailed_analysis'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prediction.detailedAnalysis,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Советы
                      if (prediction.tips.isNotEmpty) ...[
                        Text(
                          localizations.translate('ai_tips'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...prediction.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: AppConstants.textColor.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(localizations.translate('close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ПОЛНОСТЬЮ ИСПРАВЛЕННЫЙ Кастомный painter для ИИ клевометра
class FixedAIBiteMeterPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool showSpark;
  final double animationValue;

  FixedAIBiteMeterPainter({
    required this.progress,
    required this.color,
    required this.showSpark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // ИСПРАВЛЕНИЕ: Безопасное создание градиента
    final safeProgress = progress.clamp(0.0, 1.0);

    // Создаем линейный градиент вместо SweepGradient
    final progressGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.5),
        color,
        color.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    progressPaint.shader = progressGradient.createShader(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 6,
      ),
    );

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 6;

    const double startAngle = -math.pi / 2;
    const double maxSweepAngle = 2 * math.pi * 0.9; // Не полный круг, чтобы избежать проблем
    final double sweepAngle = maxSweepAngle * safeProgress;

    // Рисуем фоновую окружность
    canvas.drawCircle(center, radius, backgroundPaint);

    // Рисуем прогресс
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Добавляем искры для отличных условий
    if (showSpark && safeProgress > 0.8) {
      _drawSparks(canvas, center, radius, sweepAngle, color);
    }

    // Добавляем ИИ эффект
    _drawAIEffect(canvas, center, radius, animationValue.clamp(0.0, 1.0), color);
  }

  void _drawSparks(Canvas canvas, Offset center, double radius, double sweepAngle, Color color) {
    final Paint sparkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Рисуем несколько искр вдоль прогресса
    for (int i = 0; i < 3; i++) {
      final angle = (-math.pi / 2) + (sweepAngle * (0.3 + i * 0.2));
      final sparkRadius = radius + 8 + (math.sin(animationValue.clamp(0.0, 1.0) * math.pi * 4) * 3);

      final sparkX = center.dx + sparkRadius * math.cos(angle);
      final sparkY = center.dy + sparkRadius * math.sin(angle);

      canvas.drawCircle(
        Offset(sparkX, sparkY),
        2 + math.sin(animationValue.clamp(0.0, 1.0) * math.pi * 6) * 1,
        sparkPaint,
      );
    }
  }

  void _drawAIEffect(Canvas canvas, Offset center, double radius, double animation, Color color) {
    final Paint aiPaint = Paint()
      ..color = color.withValues(alpha: (0.3 * (1 - animation) + 0.1).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Рисуем пульсирующие круги
    for (int i = 0; i < 3; i++) {
      final aiRadius = radius + 15 + (i * 10) + (animation * 20);
      canvas.drawCircle(center, aiRadius, aiPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}