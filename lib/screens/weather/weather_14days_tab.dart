// Путь: lib/screens/weather/weather_14days_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class Weather14DaysTab extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final Map<String, dynamic>? fishingForecast;
  final String locationName;
  final VoidCallback onRefresh;

  const Weather14DaysTab({
    super.key,
    required this.weatherData,
    this.fishingForecast,
    required this.locationName,
    required this.onRefresh,
  });

  @override
  State<Weather14DaysTab> createState() => _Weather14DaysTabState();
}

class _Weather14DaysTabState extends State<Weather14DaysTab> {
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  bool _isCalendarView = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppConstants.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.backgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.date_range,
                              color: AppConstants.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '14 ${localizations.translate('days_many')}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'РАСШИРЕННЫЙ',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Основной контент
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.construction,
                        size: 64,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Скоро будет готово!',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Работаем над расширенным 14-дневным прогнозом',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🔮 Что будет в 14-дневном прогнозе:',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            '📅 Календарная сетка на 2 недели',
                            '🎣 Лучшие дни для рыбалки',
                            '📊 Долгосрочные тренды погоды',
                            '⭐ Цветовая индикация качества дней',
                            '🔒 Премиум-функции',
                          ].map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  feature,
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}