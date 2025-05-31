// Путь: lib/widgets/weather/ai_bite_meter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../localization/app_localizations.dart';
import '../animated_border_widget.dart';

class AIBiteMeter extends StatefulWidget {
  final MultiFishingTypePrediction? aiPrediction;
  final VoidCallback? onCompareTypes;
  final Function(String)? onSelectType;

  const AIBiteMeter({
    super.key,
    this.aiPrediction,
    this.onCompareTypes,
    this.onSelectType,
  });

  @override
  State<AIBiteMeter> createState() => _AIBiteMeterState();
}

class _AIBiteMeterState extends State<AIBiteMeter>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _pulseController;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _gaugeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (widget.aiPrediction == null) {
      return _buildLoadingState(localizations);
    }

    return _buildAIPredictionContent(localizations);
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
                child: Text('🧠', style: const TextStyle(fontSize: 20)),
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

  Widget _buildAIPredictionContent(AppLocalizations localizations) {
    final prediction = widget.aiPrediction!;
    final bestType = prediction.bestPrediction;
    final score = bestType.overallScore;

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
        boxShadow: [
          BoxShadow(
            color: AppConstants.textColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с иконкой ИИ
          _buildHeader(localizations),

          const SizedBox(height: 20),

          // Главный блок со счетчиком
          _buildMainScoreSection(score, localizations),

          const SizedBox(height: 20),

          // Информация о лучшем типе рыбалки
          _buildBestTypeInfo(prediction, localizations),

          const SizedBox(height: 16),

          // Ключевые факторы
          _buildKeyFactors(bestType, localizations),

          const SizedBox(height: 16),

          // Кнопки действий
          _buildActionButtons(localizations),
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
                AppConstants.primaryColor.withValues(alpha: 0.8),
                AppConstants.primaryColor.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
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
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${localizations.translate('confidence')}: ${widget.aiPrediction!.bestPrediction.confidencePercent}%',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            localizations.translate('all_types'),
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainScoreSection(int score, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(score).withValues(alpha: 0.1),
            _getScoreColor(score).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getScoreColor(score).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Анимированный счетчик
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _gaugeAnimation,
              builder: (context, child) {
                final animatedScore = (_gaugeAnimation.value * score).round();
                return Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: score >= 80 ? _pulseAnimation.value : 1.0,
                          child: Text(
                            '$animatedScore',
                            style: TextStyle(
                              color: _getScoreColor(score),
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      localizations.translate('points'),
                      style: TextStyle(
                        color: _getScoreColor(score),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Вертикальный разделитель
          Container(
            height: 80,
            width: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getScoreColor(score).withValues(alpha: 0.3),
                  _getScoreColor(score).withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          // Описание уровня активности
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getScoreDescription(score, localizations),
                  style: TextStyle(
                    color: _getScoreColor(score),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreRecommendation(score, localizations),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestTypeInfo(MultiFishingTypePrediction prediction, AppLocalizations localizations) {
    final bestType = prediction.comparison.bestOverall;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bestType.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.translate('ai_recommendation')} ${bestType.typeName}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bestType.shortRecommendation,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bestType.scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${bestType.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFactors(AIBitePrediction prediction, AppLocalizations localizations) {
    final topFactors = prediction.topPositiveFactors.take(3).toList();

    if (topFactors.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('key_factors'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topFactors.map((factor) => _buildFactorChip(factor)).toList(),
        ),
      ],
    );
  }

  Widget _buildFactorChip(BiteFactorAnalysis factor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: factor.impactColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: factor.impactColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            factor.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            factor.name,
            style: TextStyle(
              color: factor.impactColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    final nextWindow = widget.aiPrediction!.bestPrediction.nextBestTimeWindow;

    return Row(
      children: [
        if (nextWindow != null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nextWindow.timeIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('best_time'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Кнопка "Подробнее"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onCompareTypes,
            icon: const Icon(Icons.compare_arrows, size: 18),
            label: Text(
              localizations.translate('more_details'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательные методы
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Зеленый
    if (score >= 60) return const Color(0xFF8BC34A); // Светло-зеленый
    if (score >= 40) return const Color(0xFFFFC107); // Желтый
    if (score >= 20) return const Color(0xFFFF9800); // Оранжевый
    return const Color(0xFFF44336); // Красный
  }

  String _getScoreDescription(int score, AppLocalizations localizations) {
    if (score >= 80) return localizations.translate('excellent');
    if (score >= 60) return localizations.translate('good');
    if (score >= 40) return localizations.translate('moderate');
    if (score >= 20) return localizations.translate('poor');
    return localizations.translate('very_poor_activity');
  }

  String _getScoreRecommendation(int score, AppLocalizations localizations) {
    if (score >= 80) return localizations.translate('excellent_conditions_recommendation');
    if (score >= 60) return localizations.translate('good_conditions_recommendation');
    if (score >= 40) return localizations.translate('moderate_conditions_recommendation');
    if (score >= 20) return localizations.translate('poor_conditions_recommendation');
    return localizations.translate('very_poor_conditions_recommendation');
  }
}