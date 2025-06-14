// Путь: lib/widgets/weather/best_time_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../localization/app_localizations.dart';

class BestTimeSection extends StatelessWidget {
  final WeatherApiResponse weather;
  final MultiFishingTypePrediction? aiPrediction;

  const BestTimeSection({super.key, required this.weather, this.aiPrediction});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
                Icons.access_time,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('best_time_for_fishing'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (aiPrediction != null &&
              aiPrediction!.bestPrediction.bestTimeWindows.isNotEmpty)
            _buildAITimeWindows(context)
          else
            _buildDefaultTimeWindows(context),
        ],
      ),
    );
  }

  Widget _buildAITimeWindows(BuildContext context) {
    final windows =
        aiPrediction!.bestPrediction.bestTimeWindows.take(3).toList();

    return Column(
      children:
          windows.map((window) => _buildTimeWindow(context, window)).toList(),
    );
  }

  Widget _buildDefaultTimeWindows(BuildContext context) {
    // Стандартные "золотые часы" рыбалки
    final now = DateTime.now();
    final windows = [
      {
        'start': now.copyWith(hour: 6, minute: 0),
        'end': now.copyWith(hour: 8, minute: 30),
        'activity': 0.8,
        'reason': 'Утренний клев',
      },
      {
        'start': now.copyWith(hour: 18, minute: 0),
        'end': now.copyWith(hour: 20, minute: 30),
        'activity': 0.9,
        'reason': 'Вечерний клев',
      },
    ];

    return Column(
      children:
          windows.map((window) {
            return _buildSimpleTimeWindow(
              context,
              window['start'] as DateTime,
              window['end'] as DateTime,
              window['activity'] as double,
              window['reason'] as String,
            );
          }).toList(),
    );
  }

  Widget _buildTimeWindow(BuildContext context, OptimalTimeWindow window) {
    final isActive = window.isActiveNow;
    final timeUntil = window.timeUntilStartText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppConstants.primaryColor.withValues(alpha: 0.1)
                : AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            isActive
                ? Border.all(color: AppConstants.primaryColor, width: 2)
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: window.activityColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${window.activityPercent}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(window.timeIcon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      window.timeRange,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (timeUntil != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeUntil,
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  window.reason,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (window.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    window.recommendations.first,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTimeWindow(
    BuildContext context,
    DateTime start,
    DateTime end,
    double activity,
    String reason,
  ) {
    final isActive =
        DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
    final activityColor = _getActivityColor(activity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppConstants.primaryColor.withValues(alpha: 0.1)
                : AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            isActive
                ? Border.all(color: AppConstants.primaryColor, width: 2)
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: activityColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(activity * 100).round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTimeIcon(start.hour),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(double activity) {
    if (activity >= 0.8) return const Color(0xFF4CAF50);
    if (activity >= 0.6) return const Color(0xFFFFC107);
    if (activity >= 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getTimeIcon(int hour) {
    if (hour >= 5 && hour < 12) return '🌅'; // Утро
    if (hour >= 12 && hour < 17) return '☀️'; // День
    if (hour >= 17 && hour < 21) return '🌇'; // Вечер
    return '🌙'; // Ночь
  }
}
