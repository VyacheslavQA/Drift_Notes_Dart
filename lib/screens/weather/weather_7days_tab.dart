// Путь: lib/screens/weather/weather_7days_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class Weather7DaysTab extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final Map<String, dynamic>? fishingForecast;
  final String locationName;
  final VoidCallback onRefresh;

  const Weather7DaysTab({
    super.key,
    required this.weatherData,
    this.fishingForecast,
    required this.locationName,
    required this.onRefresh,
  });

  @override
  State<Weather7DaysTab> createState() => _Weather7DaysTabState();
}

class _Weather7DaysTabState extends State<Weather7DaysTab>
    with SingleTickerProviderStateMixin {
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppConstants.primaryColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildCompactHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildWeekSummary(),
                  const SizedBox(height: 24),
                  _buildSevenDaysCards(),
                  const SizedBox(height: 24),
                  _buildWeeklyTrends(),
                  const SizedBox(height: 24),
                  _buildBestDaysOfWeek(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final localizations = AppLocalizations.of(context);
    final current = widget.weatherData.current;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                current.isDay == 1
                    ? Colors.blue[400]!.withValues(alpha: 0.3)
                    : Colors.indigo[800]!.withValues(alpha: 0.3),
                AppConstants.backgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Заголовок периода
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.view_week,
                          color: AppConstants.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '7 ${localizations.translate('days_many')}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.locationName,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Диапазон температур на неделю
                  Row(
                    children: [
                      Text(
                        '${localizations.translate('week')}: ',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _getWeekTempRange(),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getWeekQualityColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getWeekQualityText(),
                          style: TextStyle(
                            color: _getWeekQualityColor(),
                            fontSize: 12,
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
    );
  }

  Widget _buildWeekSummary() {
    final localizations = AppLocalizations.of(context);
    final weekActivity = _calculateWeekActivity();
    final bestDaysCount = _getBestDaysCount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBiteActivityColor(weekActivity).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppConstants.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('bite_forecast')} (${localizations.translate('week')})',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Недельный клёвометр
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.textColor.withValues(alpha: 0.1),
                            width: 6,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(90, 90),
                        painter: BiteMeterPainter(
                          progress: weekActivity,
                          color: _getBiteActivityColor(weekActivity),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(weekActivity * 100).round()}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              localizations.translate('points'),
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getBiteActivityColor(weekActivity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getBiteActivityText(weekActivity),
                          style: TextStyle(
                            color: _getBiteActivityColor(weekActivity),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.green,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$bestDaysCount ${_getDaysText(bestDaysCount)} ${localizations.translate('good_for_fishing').toLowerCase()}',
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _getWeekRecommendation(),
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSevenDaysCards() {
    final localizations = AppLocalizations.of(context);

    // Расширяем прогноз до 7 дней (генерируем недостающие дни)
    final sevenDaysForecast = _generateSevenDaysForecast();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: AppConstants.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${localizations.translate('tap_for_details')}',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Карточки дней
          ...sevenDaysForecast.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = index == 0;
            final isBestDay = day['isBestDay'] as bool;
            final isExpanded = _selectedDayIndex == index;

            return _buildDayCard(day, isToday, isBestDay, isExpanded, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, bool isToday, bool isBestDay, bool isExpanded, int dayIndex) {
    final localizations = AppLocalizations.of(context);
    final date = day['date'] as DateTime;
    final dayActivity = day['activity'] as double;
    final minTemp = day['minTemp'] as double;
    final maxTemp = day['maxTemp'] as double;
    final condition = day['condition'] as String;
    final windKph = day['windKph'] as double;
    final humidity = day['humidity'] as int;
    final pressure = day['pressure'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestDay
              ? Colors.green.withValues(alpha: 0.4)
              : isToday
              ? AppConstants.primaryColor.withValues(alpha: 0.4)
              : AppConstants.textColor.withValues(alpha: 0.1),
          width: isBestDay ? 2 : 1,
        ),
        boxShadow: isBestDay ? [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDayIndex = isExpanded ? null : dayIndex;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Основная информация дня
              Row(
                children: [
                  // Дата и день недели
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? localizations.translate('today')
                              : _formatDayName(date),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM').format(date),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Иконка и описание погоды
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Icon(
                          _getWeatherIcon(condition),
                          size: 32,
                          color: AppConstants.textColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _translateWeatherDescription(condition),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Температуры
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weatherSettings.formatTemperature(minTemp, showUnit: false),
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '°/${_weatherSettings.formatTemperature(maxTemp, showUnit: false)}°',
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
                          _weatherSettings.formatWindSpeed(windKph),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Клёвометр и значки
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBestDay) ...[
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (isToday) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'СЕГОДНЯ',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getBiteActivityColor(dayActivity),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${(dayActivity * 100).round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Расширенная информация (если выбран день)
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              localizations.translate('humidity'),
                              '$humidity%',
                              Icons.water_drop,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              localizations.translate('pressure'),
                              _weatherSettings.formatPressure(pressure),
                              Icons.speed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              localizations.translate('bite_activity'),
                              _getBiteActivityText(dayActivity),
                              Icons.set_meal,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              localizations.translate('fishing_conditions'),
                              _getFishingCondition(dayActivity),
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getBiteActivityColor(dayActivity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: _getBiteActivityColor(dayActivity),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDayRecommendation(dayActivity, condition),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeeklyTrends() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${localizations.translate('trends')} ${localizations.translate('week').toLowerCase()}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Мини-график температуры
            Container(
              height: 60,
              child: CustomPaint(
                size: Size(double.infinity, 60),
                painter: WeeklyTrendsPainter(
                  temps: _getWeeklyTemps(),
                  activities: _getWeeklyActivities(),
                  textColor: AppConstants.textColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Сводка трендов
            Row(
              children: [
                Expanded(
                  child: _buildTrendItem(
                    '📈 ${localizations.translate('temperature')}',
                    _getTemperatureTrend(),
                    _getTemperatureTrendColor(),
                  ),
                ),
                Expanded(
                  child: _buildTrendItem(
                    '🎣 ${localizations.translate('bite_activity')}',
                    _getActivityTrend(),
                    _getActivityTrendColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBestDaysOfWeek() {
    final localizations = AppLocalizations.of(context);
    final bestDays = _getBestDaysOfWeek();

    if (bestDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.sentiment_neutral,
                size: 48,
                color: AppConstants.textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Неделя будет непростой для рыбалки',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Но не расстраивайтесь - рыба клюет всегда! 🎣',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '🌟 ${localizations.translate('best')} ${localizations.translate('days_many')} ${localizations.translate('week').toLowerCase()}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...bestDays.map((day) => _buildBestDayItem(day)).toList(),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Планируйте рыбалку на эти дни для максимального результата! 🎯',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 13,
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
  }

  Widget _buildBestDayItem(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final activity = day['activity'] as double;
    final dayIndex = day['dayIndex'] as int;
    final isToday = dayIndex == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Сегодня' : _formatDayName(date),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd.MM').format(date),
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
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(activity * 100).round()}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы

  List<Map<String, dynamic>> _generateSevenDaysForecast() {
    final forecast = <Map<String, dynamic>>[];
    final baseDate = DateTime.now();

    // Берем реальные данные или генерируем
    final availableForecast = widget.weatherData.forecast;

    for (int i = 0; i < 7; i++) {
      final date = baseDate.add(Duration(days: i));

      if (i < availableForecast.length) {
        // Используем реальные данные
        final day = availableForecast[i];
        final activity = _calculateDayActivity(day);

        forecast.add({
          'date': date,
          'minTemp': day.day.mintempC,
          'maxTemp': day.day.maxtempC,
          'condition': day.day.condition.text,
          'windKph': _getAverageWindForDay(day),
          'humidity': _getAverageHumidityForDay(day),
          'pressure': widget.weatherData.current.pressureMb, // Примерно
          'activity': activity,
          'isBestDay': activity >= 0.7,
        });
      } else {
        // Генерируем примерные данные
        forecast.add({
          'date': date,
          'minTemp': _generateTemp(true),
          'maxTemp': _generateTemp(false),
          'condition': _generateCondition(),
          'windKph': _generateWind(),
          'humidity': _generateHumidity(),
          'pressure': _generatePressure(),
          'activity': _generateActivity(),
          'isBestDay': false,
        });
      }
    }

    return forecast;
  }

  double _calculateDayActivity(ForecastDay day) {
    double activity = 0.5;

    final avgTemp = (day.day.mintempC + day.day.maxtempC) / 2;
    if (avgTemp >= 15 && avgTemp <= 25) {
      activity += 0.2;
    } else if (avgTemp < 5 || avgTemp > 35) {
      activity -= 0.2;
    }

    final moonPhase = day.astro.moonPhase.toLowerCase();
    if (moonPhase.contains('full') || moonPhase.contains('new')) {
      activity += 0.1;
    }

    final condition = day.day.condition.text.toLowerCase();
    if (condition.contains('sunny') || condition.contains('clear')) {
      activity += 0.1;
    } else if (condition.contains('storm') || condition.contains('heavy')) {
      activity -= 0.2;
    }

    return activity.clamp(0.0, 1.0);
  }

  double _getAverageWindForDay(ForecastDay day) {
    if (day.hour.isEmpty) return 0.0;
    return day.hour.map((h) => h.windKph).reduce((a, b) => a + b) / day.hour.length;
  }

  int _getAverageHumidityForDay(ForecastDay day) {
    if (day.hour.isEmpty) return 60;
    return (day.hour.map((h) => h.humidity).reduce((a, b) => a + b) / day.hour.length).round();
  }

  // Методы генерации данных для недостающих дней
  double _generateTemp(bool isMin) {
    final base = isMin ? 10.0 : 20.0;
    return base + (math.Random().nextDouble() - 0.5) * 15;
  }

  String _generateCondition() {
    final conditions = ['Sunny', 'Partly cloudy', 'Cloudy', 'Light rain'];
    return conditions[math.Random().nextInt(conditions.length)];
  }

  double _generateWind() => 5.0 + math.Random().nextDouble() * 15;
  int _generateHumidity() => 40 + math.Random().nextInt(40);
  double _generatePressure() => 1000.0 + math.Random().nextDouble() * 30;
  double _generateActivity() => 0.3 + math.Random().nextDouble() * 0.5;

  double _calculateWeekActivity() {
    final forecast = _generateSevenDaysForecast();
    final totalActivity = forecast.map((day) => day['activity'] as double).reduce((a, b) => a + b);
    return totalActivity / 7;
  }

  int _getBestDaysCount() {
    final forecast = _generateSevenDaysForecast();
    return forecast.where((day) => (day['activity'] as double) >= 0.7).length;
  }

  String _getDaysText(int count) {
    if (count == 1) return 'день';
    if (count >= 2 && count <= 4) return 'дня';
    return 'дней';
  }

  String _getWeekRecommendation() {
    final bestDaysCount = _getBestDaysCount();
    if (bestDaysCount >= 3) return 'Отличная неделя для рыбалки!';
    if (bestDaysCount >= 1) return 'Есть хорошие дни для выезда';
    return 'Неделя будет сложной, но попробовать стоит';
  }

  String _getWeekTempRange() {
    final forecast = _generateSevenDaysForecast();
    final minTemp = forecast.map((day) => day['minTemp'] as double).reduce(math.min);
    final maxTemp = forecast.map((day) => day['maxTemp'] as double).reduce(math.max);

    return '${_weatherSettings.formatTemperature(minTemp, showUnit: false)}°..${_weatherSettings.formatTemperature(maxTemp, showUnit: false)}°';
  }

  Color _getWeekQualityColor() {
    final weekActivity = _calculateWeekActivity();
    return _getBiteActivityColor(weekActivity);
  }

  String _getWeekQualityText() {
    final weekActivity = _calculateWeekActivity();
    return _getBiteActivityText(weekActivity);
  }

  List<Map<String, dynamic>> _getBestDaysOfWeek() {
    final forecast = _generateSevenDaysForecast();
    final bestDays = <Map<String, dynamic>>[];

    for (int i = 0; i < forecast.length; i++) {
      final day = forecast[i];
      final activity = day['activity'] as double;

      if (activity >= 0.7) {
        bestDays.add({
          'date': day['date'],
          'activity': activity,
          'dayIndex': i,
        });
      }
    }

    bestDays.sort((a, b) => (b['activity'] as double).compareTo(a['activity'] as double));
    return bestDays;
  }

  String _formatDayName(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations.locale.languageCode;

    try {
      return DateFormat('EEEE', locale).format(date);
    } catch (e) {
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return weekdays[date.weekday - 1];
    }
  }

  List<double> _getWeeklyTemps() {
    final forecast = _generateSevenDaysForecast();
    return forecast.map((day) => (day['minTemp'] as double + day['maxTemp'] as double) / 2).toList();
  }

  List<double> _getWeeklyActivities() {
    final forecast = _generateSevenDaysForecast();
    return forecast.map((day) => day['activity'] as double).toList();
  }

  String _getTemperatureTrend() {
    final temps = _getWeeklyTemps();
    final firstHalf = temps.take(3).reduce((a, b) => a + b) / 3;
    final secondHalf = temps.skip(4).reduce((a, b) => a + b) / 3;

    if (secondHalf > firstHalf + 2) return 'Потепление';
    if (secondHalf < firstHalf - 2) return 'Похолодание';
    return 'Стабильно';
  }

  Color _getTemperatureTrendColor() {
    final trend = _getTemperatureTrend();
    switch (trend) {
      case 'Потепление': return Colors.orange;
      case 'Похолодание': return Colors.blue;
      default: return Colors.green;
    }
  }

  String _getActivityTrend() {
    final activities = _getWeeklyActivities();
    final firstHalf = activities.take(3).reduce((a, b) => a + b) / 3;
    final secondHalf = activities.skip(4).reduce((a, b) => a + b) / 3;

    if (secondHalf > firstHalf + 0.1) return 'Улучшается';
    if (secondHalf < firstHalf - 0.1) return 'Ухудшается';
    return 'Стабильно';
  }

  Color _getActivityTrendColor() {
    final trend = _getActivityTrend();
    switch (trend) {
      case 'Улучшается': return Colors.green;
      case 'Ухудшается': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) return Icons.wb_sunny;
    if (lowerCondition.contains('cloud')) return Icons.cloud;
    if (lowerCondition.contains('rain')) return Icons.grain;
    if (lowerCondition.contains('snow')) return Icons.ac_unit;
    if (lowerCondition.contains('storm')) return Icons.flash_on;
    return Icons.wb_sunny;
  }

  String _translateWeatherDescription(String description) {
    final localizations = AppLocalizations.of(context);
    final cleanDescription = description.trim().toLowerCase();

    final Map<String, String> descriptionToKey = {
      'sunny': 'weather_sunny',
      'clear': 'weather_clear',
      'partly cloudy': 'weather_partly_cloudy',
      'cloudy': 'weather_cloudy',
      'overcast': 'weather_overcast',
      'mist': 'weather_mist',
      'light rain': 'weather_light_rain',
      'moderate rain': 'weather_moderate_rain',
      'heavy rain': 'weather_heavy_rain',
      'light snow': 'weather_light_snow',
      'thunderstorm': 'weather_thundery_outbreaks_possible',
    };

    final localizationKey = descriptionToKey[cleanDescription];
    if (localizationKey != null) {
      return localizations.translate(localizationKey);
    }

    return description;
  }

  Color _getBiteActivityColor(double activity) {
    if (activity > 0.8) return const Color(0xFF4CAF50);
    if (activity > 0.6) return const Color(0xFFFFC107);
    if (activity > 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getBiteActivityText(double activity) {
    final localizations = AppLocalizations.of(context);
    if (activity > 0.8) return localizations.translate('excellent_activity');
    if (activity > 0.6) return localizations.translate('good_activity');
    if (activity > 0.4) return localizations.translate('moderate_activity');
    if (activity > 0.2) return localizations.translate('weak_activity');
    return localizations.translate('very_weak_activity');
  }

  String _getFishingCondition(double activity) {
    final localizations = AppLocalizations.of(context);
    if (activity > 0.8) return localizations.translate('excellent_for_fishing');
    if (activity > 0.6) return localizations.translate('good_for_fishing');
    if (activity > 0.4) return localizations.translate('moderate_for_fishing');
    return localizations.translate('difficult_for_fishing');
  }

  String _getDayRecommendation(double activity, String condition) {
    if (activity > 0.8) {
      return 'Отличный день! Берите активные приманки и ловите трофеи 🏆';
    } else if (activity > 0.6) {
      return 'Хороший день для рыбалки. Стоит попробовать 👍';
    } else if (activity > 0.4) {
      return 'Средние условия. Используйте проверенные места и приманки';
    } else {
      return 'Сложный день. Попробуйте ловить на глубине или в укрытиях';
    }
  }
}

// Кастомный painter для недельных трендов
class WeeklyTrendsPainter extends CustomPainter {
  final List<double> temps;
  final List<double> activities;
  final Color textColor;

  WeeklyTrendsPainter({
    required this.temps,
    required this.activities,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.isEmpty || activities.isEmpty) return;

    final Paint tempPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint activityPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill;

    // Нормализуем данные
    final normalizedTemps = _normalizeData(temps);
    final normalizedActivities = _normalizeData(activities);

    final stepX = size.width / (temps.length - 1);

    // Рисуем линию температур
    final tempPath = Path();
    for (int i = 0; i < normalizedTemps.length; i++) {
      final x = i * stepX;
      final y = size.height - (normalizedTemps[i] * size.height * 0.4) - size.height * 0.1;

      if (i == 0) {
        tempPath.moveTo(x, y);
      } else {
        tempPath.lineTo(x, y);
      }
    }
    canvas.drawPath(tempPath, tempPaint);

    // Рисуем линию активности
    final activityPath = Path();
    for (int i = 0; i < normalizedActivities.length; i++) {
      final x = i * stepX;
      final y = size.height - (normalizedActivities[i] * size.height * 0.4) - size.height * 0.5;

      if (i == 0) {
        activityPath.moveTo(x, y);
      } else {
        activityPath.lineTo(x, y);
      }
    }
    canvas.drawPath(activityPath, activityPaint);

    // Рисуем точки
    for (int i = 0; i < temps.length; i++) {
      final x = i * stepX;

      // Точка температуры
      final tempY = size.height - (normalizedTemps[i] * size.height * 0.4) - size.height * 0.1;
      dotPaint.color = Colors.orange;
      canvas.drawCircle(Offset(x, tempY), 3, dotPaint);

      // Точка активности
      final activityY = size.height - (normalizedActivities[i] * size.height * 0.4) - size.height * 0.5;
      dotPaint.color = Colors.green;
      canvas.drawCircle(Offset(x, activityY), 3, dotPaint);
    }
  }

  List<double> _normalizeData(List<double> data) {
    if (data.isEmpty) return [];

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = maxVal - minVal;

    if (range == 0) return data.map((e) => 0.5).toList();

    return data.map((val) => (val - minVal) / range).toList();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Кастомный painter для мини клёвометра (повторно используем)
class BiteMeterPainter extends CustomPainter {
  final double progress;
  final Color color;

  BiteMeterPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 3;

    const double startAngle = -math.pi / 2;
    const double maxSweepAngle = 2 * math.pi;
    final double sweepAngle = maxSweepAngle * progress;

    // Рисуем фоновую окружность
    canvas.drawCircle(center, radius, backgroundPaint);

    // Рисуем прогресс
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}