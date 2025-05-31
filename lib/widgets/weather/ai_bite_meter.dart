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
  late AnimationController _fishAnimationController;
  late Animation<double> _meterAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fishAnimation;

  String _currentSelectedType = 'spinning';
  bool _showAllTypes = false;

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

    _fishAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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

    _fishAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fishAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _meterController.forward();
    _pulseController.repeat(reverse: true);
    _fishAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _meterController.dispose();
    _pulseController.dispose();
    _fishAnimationController.dispose();
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
            _buildMainMeter(),
            const SizedBox(height: 24),
            _buildFishingTypeSelector(),
            const SizedBox(height: 20),
            _buildSimpleRecommendation(),
            const SizedBox(height: 16),
            _buildKeyFactors(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
                  '🧠 ИИ анализирует клев...',
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
              'Анализируем все виды рыбалки...',
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
    final prediction = _getCurrentPrediction();
    final config = AIBitePredictionService.fishingTypeConfigs[_currentSelectedType];

    return Row(
      children: [
        // Иконка типа рыбалки
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: prediction.scoreColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            config?.icon ?? '🎣',
            style: const TextStyle(fontSize: 28),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 Прогноз клева ИИ',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config?.name ?? 'Спиннинг',
                style: TextStyle(
                  color: prediction.scoreColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Индикатор уверенности
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified,
                color: Colors.green,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${prediction.confidencePercent}%',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainMeter() {
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
              child: Container(
                width: 180,
                height: 180,
                child: Stack(
                  children: [
                    // Основной круговой индикатор
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: EnhancedBiteMeterPainter(
                        progress: (score / 100.0) * _meterAnimation.value,
                        color: prediction.scoreColor,
                        backgroundColor: AppConstants.textColor.withValues(alpha: 0.1),
                        strokeWidth: 16,
                      ),
                    ),

                    // Центральное содержимое
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Балл
                          AnimatedBuilder(
                            animation: _meterAnimation,
                            builder: (context, child) {
                              return Text(
                                '${(score * _meterAnimation.value).round()}',
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),

                          // Из 100
                          Text(
                            'из 100',
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Уровень активности
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: prediction.scoreColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSimpleActivityText(score),
                              style: TextStyle(
                                color: prediction.scoreColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Анимированная рыбка
                          AnimatedBuilder(
                            animation: _fishAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  math.sin(_fishAnimation.value * math.pi * 2) * 8,
                                  0,
                                ),
                                child: Text(
                                  score >= 70 ? '🐟💨' : score >= 40 ? '🐟' : '😴',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            },
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

  Widget _buildFishingTypeSelector() {
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
              'Выберите тип рыбалки:',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllTypes = !_showAllTypes;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllTypes ? 'Скрыть' : 'Все типы',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllTypes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppConstants.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTypeChips(),
      ],
    );
  }

  Widget _buildTypeChips() {
    final allTypes = AIBitePredictionService.fishingTypeConfigs.entries.toList();
    final displayTypes = _showAllTypes ? allTypes : allTypes.take(4).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayTypes.map((entry) {
        final type = entry.key;
        final config = entry.value;
        final prediction = widget.aiPrediction?.allPredictions[type];
        final score = prediction?.overallScore ?? 0;
        final isSelected = _currentSelectedType == type;
        final isBest = type == widget.aiPrediction?.bestFishingType;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentSelectedType = type;
            });
            widget.onSelectType?.call(type);
            _meterController.reset();
            _meterController.forward();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getScoreColor(score).withValues(alpha: 0.2)
                  : AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _getScoreColor(score)
                    : AppConstants.textColor.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          config.name,
                          style: TextStyle(
                            color: isSelected
                                ? _getScoreColor(score)
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
                      '$score б. • ${_getSimpleActivityText(score)}',
                      style: TextStyle(
                        color: isSelected
                            ? _getScoreColor(score)
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
      }).toList(),
    );
  }

  Widget _buildSimpleRecommendation() {
    final prediction = _getCurrentPrediction();
    final score = prediction.overallScore;

    String emoji;
    String title;
    String description;

    if (score >= 80) {
      emoji = '🔥';
      title = 'ОТЛИЧНЫЕ УСЛОВИЯ!';
      description = 'Идеальное время для рыбалки. Рыба очень активна!';
    } else if (score >= 60) {
      emoji = '👍';
      title = 'ХОРОШИЕ УСЛОВИЯ';
      description = 'Стоит попробовать! Клев должен быть неплохой.';
    } else if (score >= 40) {
      emoji = '🤔';
      title = 'СРЕДНИЕ УСЛОВИЯ';
      description = 'Можно рыбачить, но потребуется терпение.';
    } else if (score >= 20) {
      emoji = '😐';
      title = 'СЛАБЫЕ УСЛОВИЯ';
      description = 'Клев будет слабым, лучше подождать.';
    } else {
      emoji = '😴';
      title = 'ОЧЕНЬ СЛАБЫЕ УСЛОВИЯ';
      description = 'Рыба пассивна. Стоит отложить рыбалку.';
    }

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
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: prediction.scoreColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        height: 1.3,
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

  Widget _buildKeyFactors() {
    final prediction = _getCurrentPrediction();
    final topFactors = prediction.factors.take(3).toList();

    if (topFactors.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Ключевые факторы:',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topFactors.map((factor) => _buildSimpleFactorItem(factor)).toList(),
      ],
    );
  }

  Widget _buildSimpleFactorItem(BiteFactorAnalysis factor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            factor.icon,
            style: const TextStyle(fontSize: 20),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getSimpleFactorDescription(factor),
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
              color: factor.isPositive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              factor.isPositive ? 'ПЛЮС' : 'МИНУС',
              style: TextStyle(
                color: factor.isPositive ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
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
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Лучшее время',
                        style: TextStyle(
                          color: Colors.orange,
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
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Подробнее', style: TextStyle(fontSize: 12)),
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
      return AIBitePrediction(
        overallScore: 50,
        activityLevel: ActivityLevel.moderate,
        confidence: 0.5,
        recommendation: 'Базовая рекомендация',
        detailedAnalysis: 'Анализ недоступен',
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

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getSimpleActivityText(int score) {
    if (score >= 80) return 'Отлично';
    if (score >= 60) return 'Хорошо';
    if (score >= 40) return 'Средне';
    if (score >= 20) return 'Слабо';
    return 'Очень слабо';
  }

  String _getSimpleFactorDescription(BiteFactorAnalysis factor) {
    if (factor.isPositive) {
      return 'Способствует клеву';
    } else {
      return 'Ухудшает клев';
    }
  }

  void _showDetailedAnalysis() {
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
                '📊 Детальный анализ ИИ',
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
                      Text(
                        'Подробный анализ:',
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

                      if (prediction.tips.isNotEmpty) ...[
                        Text(
                          'Советы ИИ:',
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
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Улучшенный painter для клевометра
class EnhancedBiteMeterPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  EnhancedBiteMeterPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Фоновая окружность
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Прогресс окружность
    if (progress > 0) {
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Градиент для прогресса
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [
          color.withValues(alpha: 0.5),
          color,
          color.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      progressPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Точка в конце прогресса
      if (progress > 0.05) {
        final endAngle = startAngle + sweepAngle;
        final endX = center.dx + radius * math.cos(endAngle);
        final endY = center.dy + radius * math.sin(endAngle);

        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}