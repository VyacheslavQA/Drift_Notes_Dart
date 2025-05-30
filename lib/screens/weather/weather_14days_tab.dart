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

class _Weather14DaysTabState extends State<Weather14DaysTab>
    with SingleTickerProviderStateMixin {
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isCalendarView = true;
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
                  _buildTwoWeeksSummary(),
                  const SizedBox(height: 24),
                  _buildViewToggle(),
                  const SizedBox(height: 16),
                  _isCalendarView ? _buildCalendarView() : _buildListView(),
                  const SizedBox(height: 24),
                  _buildBestWeeksAnalysis(),
                  const SizedBox(height: 24),
                  _buildLongTermTrends(),
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
                    ? Colors.purple[400]!.withValues(alpha: 0.3)
                    : Colors.indigo[900]!.withValues(alpha: 0.3),
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
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.date_range,
                          color: Colors.purple,
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
                          color: Colors.purple.withValues(alpha: 0.2),
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

                  const SizedBox(height: 8),

                  // Период и локация
                  Row(
                    children: [
                      Text(
                        '${_getDateRange()}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoWeeksSummary() {
    final localizations = AppLocalizations.of(context);
    final twoWeeksActivity = _calculateTwoWeeksActivity();
    final bestDaysCount = _getBestDaysCountInTwoWeeks();
    final premiumDaysCount = _getPremiumDaysCount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBiteActivityColor(twoWeeksActivity).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: AppConstants.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('bite_forecast')} (2 ${localizations.translate('week').toLowerCase()})',
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
                // Двухнедельный клёвометр
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.textColor.withValues(alpha: 0.1),
                            width: 8,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(100, 100),
                        painter: BiteMeterPainter14Days(
                          progress: twoWeeksActivity,
                          color: _getBiteActivityColor(twoWeeksActivity),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(twoWeeksActivity * 100).round()}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 22,
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
                          color: _getBiteActivityColor(twoWeeksActivity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getBiteActivityText(twoWeeksActivity),
                          style: TextStyle(
                            color: _getBiteActivityColor(twoWeeksActivity),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Статистика по дням
                      _buildSummaryRow(
                        '⭐ Отличных дней:',
                        '$bestDaysCount',
                        Colors.green,
                      ),
                      const SizedBox(height: 4),
                      _buildSummaryRow(
                        '🔒 Премиум дней:',
                        '$premiumDaysCount',
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _getTwoWeeksRecommendation(),
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

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarView = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isCalendarView
                        ? AppConstants.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: _isCalendarView
                            ? Colors.white
                            : AppConstants.textColor.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Календарь',
                        style: TextStyle(
                          color: _isCalendarView
                              ? Colors.white
                              : AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarView = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isCalendarView
                        ? AppConstants.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list,
                        color: !_isCalendarView
                            ? Colors.white
                            : AppConstants.textColor.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Список',
                        style: TextStyle(
                          color: !_isCalendarView
                              ? Colors.white
                              : AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final forecast14Days = _generate14DaysForecast();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Заголовки дней недели
            _buildWeekDaysHeader(),
            const SizedBox(height: 8),

            // Календарная сетка (2 недели)
            _buildCalendarGrid(forecast14Days),

            const SizedBox(height: 16),

            // Легенда цветов
            _buildColorLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Row(
      children: weekDays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(List<Map<String, dynamic>> forecast14Days) {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);

    // Находим понедельник текущей недели
    final mondayOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));

    return Column(
      children: [
        // Первая неделя
        _buildWeekRow(forecast14Days, mondayOfWeek, 0),
        const SizedBox(height: 4),
        // Вторая неделя
        _buildWeekRow(forecast14Days, mondayOfWeek.add(const Duration(days: 7)), 1),
      ],
    );
  }

  Widget _buildWeekRow(List<Map<String, dynamic>> forecast14Days, DateTime weekStart, int weekIndex) {
    return Row(
      children: List.generate(7, (dayIndex) {
        final date = weekStart.add(Duration(days: dayIndex));
        final dayData = _findDayData(forecast14Days, date);
        final isToday = _isSameDay(date, DateTime.now());
        final isCurrentMonth = date.month == DateTime.now().month;

        return Expanded(
          child: GestureDetector(
            onTap: () => _showDayDetails(dayData, date),
            child: Container(
              height: 60,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getDayBackgroundColor(dayData, isToday),
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(
                  color: AppConstants.primaryColor,
                  width: 2,
                ) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isCurrentMonth
                          ? (isToday ? AppConstants.primaryColor : AppConstants.textColor)
                          : AppConstants.textColor.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (dayData != null) ...[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getBiteActivityColor(dayData['activity']),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${(dayData['activity'] * 10).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (dayData['isPremium'] == true) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.lock,
                        color: Colors.purple,
                        size: 8,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildListView() {
    final forecast14Days = _generate14DaysForecast();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: forecast14Days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final date = day['date'] as DateTime;
          final isToday = index == 0;
          final isPremium = day['isPremium'] as bool;
          final isBestDay = (day['activity'] as double) >= 0.7;

          return _buildListDayCard(day, isToday, isPremium, isBestDay, index);
        }).toList(),
      ),
    );
  }

  Widget _buildListDayCard(Map<String, dynamic> day, bool isToday, bool isPremium, bool isBestDay, int dayIndex) {
    final localizations = AppLocalizations.of(context);
    final date = day['date'] as DateTime;
    final dayActivity = day['activity'] as double;
    final isExpanded = _selectedDayIndex == dayIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBestDay
              ? Colors.green.withValues(alpha: 0.4)
              : isToday
              ? AppConstants.primaryColor.withValues(alpha: 0.4)
              : AppConstants.textColor.withValues(alpha: 0.1),
          width: isBestDay || isToday ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isPremium ? _showPremiumDialog : () {
          setState(() {
            _selectedDayIndex = isExpanded ? null : dayIndex;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Дата
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

                  // Погода
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Icon(
                          _getWeatherIcon(day['condition']),
                          size: 24,
                          color: isPremium
                              ? AppConstants.textColor.withValues(alpha: 0.3)
                              : AppConstants.textColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium
                              ? '***'
                              : '${_weatherSettings.formatTemperature(day['minTemp'], showUnit: false)}°/${_weatherSettings.formatTemperature(day['maxTemp'], showUnit: false)}°',
                          style: TextStyle(
                            color: isPremium
                                ? AppConstants.textColor.withValues(alpha: 0.3)
                                : AppConstants.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                          if (isBestDay && !isPremium) ...[
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
                          if (isPremium) ...[
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.purple,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPremium
                              ? Colors.grey
                              : _getBiteActivityColor(dayActivity),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isPremium
                              ? const Icon(Icons.lock, color: Colors.white, size: 16)
                              : Text(
                            '${(dayActivity * 100).round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Расширенная информация (только для бесплатных дней)
              if (isExpanded && !isPremium) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayRecommendation(dayActivity),
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${localizations.translate('bite_activity')}: ${_getBiteActivityText(dayActivity)}',
                        style: TextStyle(
                          color: _getBiteActivityColor(dayActivity),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Widget _buildColorLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎨 Цветовая индикация качества дней:',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Отлично', Colors.green, '8-10'),
              _buildLegendItem('Хорошо', Colors.orange, '6-7'),
              _buildLegendItem('Средне', Colors.red, '4-5'),
              _buildLegendItem('Слабо', Colors.grey, '0-3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              range.split('-')[1],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBestWeeksAnalysis() {
    final localizations = AppLocalizations.of(context);
    final week1Activity = _calculateWeekActivity(0, 7);
    final week2Activity = _calculateWeekActivity(7, 14);

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
                    Icons.compare,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Сравнение недель',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildWeekComparison(
                    'Первая неделя',
                    week1Activity,
                    _getWeekDatesRange(0, 7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWeekComparison(
                    'Вторая неделя',
                    week2Activity,
                    _getWeekDatesRange(7, 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBetterWeekColor(week1Activity, week2Activity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: _getBetterWeekColor(week1Activity, week2Activity),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getBetterWeekText(week1Activity, week2Activity),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
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

  Widget _buildWeekComparison(String title, double activity, String dateRange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBiteActivityColor(activity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBiteActivityColor(activity).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getBiteActivityColor(activity),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(activity * 100).round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getBiteActivityText(activity),
            style: TextStyle(
              color: _getBiteActivityColor(activity),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLongTermTrends() {
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
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Долгосрочные тренды',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildTrendItem(
              '📈 Температурный тренд:',
              _getTemperatureTrend(),
              _getTemperatureTrendColor(),
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              '🎣 Тренд активности:',
              _getActivityTrend(),
              _getActivityTrendColor(),
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              '🌙 Лунные фазы:',
              _getMoonTrend(),
              Colors.blue,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Планируйте дальние поездки заранее, учитывая долгосрочные прогнозы! 🎯',
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

  Widget _buildTrendItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательные методы

  List<Map<String, dynamic>> _generate14DaysForecast() {
    final forecast = <Map<String, dynamic>>[];
    final baseDate = DateTime.now();
    final availableForecast = widget.weatherData.forecast;

    for (int i = 0; i < 14; i++) {
      final date = baseDate.add(Duration(days: i));
      final isPremium = i >= 10; // Дни 11-14 премиум

      if (i < availableForecast.length && !isPremium) {
        // Используем реальные данные
        final day = availableForecast[i];
        final activity = _calculateDayActivity(day);

        forecast.add({
          'date': date,
          'minTemp': day.day.mintempC,
          'maxTemp': day.day.maxtempC,
          'condition': day.day.condition.text,
          'activity': activity,
          'isPremium': false,
        });
      } else {
        // Генерируем данные или блокируем премиум дни
        forecast.add({
          'date': date,
          'minTemp': isPremium ? 0.0 : _generateTemp(true),
          'maxTemp': isPremium ? 0.0 : _generateTemp(false),
          'condition': isPremium ? 'Locked' : _generateCondition(),
          'activity': isPremium ? 0.0 : _generateActivity(),
          'isPremium': isPremium,
        });
      }
    }

    return forecast;
  }

  double _calculateDayActivity(dynamic day) {
    double activity = 0.5;

    if (day.runtimeType.toString().contains('ForecastDay')) {
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
    }

    return activity.clamp(0.0, 1.0);
  }

  double _generateTemp(bool isMin) {
    final base = isMin ? 10.0 : 20.0;
    return base + (math.Random().nextDouble() - 0.5) * 15;
  }

  String _generateCondition() {
    final conditions = ['Sunny', 'Partly cloudy', 'Cloudy', 'Light rain'];
    return conditions[math.Random().nextInt(conditions.length)];
  }

  double _generateActivity() => 0.3 + math.Random().nextDouble() * 0.5;

  double _calculateTwoWeeksActivity() {
    final forecast = _generate14DaysForecast();
    final freeActivities = forecast
        .where((day) => !(day['isPremium'] as bool))
        .map((day) => day['activity'] as double);

    if (freeActivities.isEmpty) return 0.5;

    return freeActivities.reduce((a, b) => a + b) / freeActivities.length;
  }

  int _getBestDaysCountInTwoWeeks() {
    final forecast = _generate14DaysForecast();
    return forecast
        .where((day) => !(day['isPremium'] as bool) && (day['activity'] as double) >= 0.7)
        .length;
  }

  int _getPremiumDaysCount() {
    return 4; // Дни 11-14
  }

  String _getTwoWeeksRecommendation() {
    final bestDaysCount = _getBestDaysCountInTwoWeeks();
    if (bestDaysCount >= 5) return 'Отличные 2 недели для рыбалки!';
    if (bestDaysCount >= 3) return 'Хорошие перспективы на ближайшие недели';
    if (bestDaysCount >= 1) return 'Есть несколько хороших дней';
    return 'Период будет сложным, но возможности есть';
  }

  String _getDateRange() {
    final start = DateTime.now();
    final end = start.add(const Duration(days: 13));
    return '${DateFormat('dd.MM').format(start)} - ${DateFormat('dd.MM').format(end)}';
  }

  Map<String, dynamic>? _findDayData(List<Map<String, dynamic>> forecast, DateTime date) {
    try {
      return forecast.firstWhere(
            (day) => _isSameDay(day['date'] as DateTime, date),
      );
    } catch (e) {
      return null;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getDayBackgroundColor(Map<String, dynamic>? dayData, bool isToday) {
    if (dayData == null) {
      return AppConstants.backgroundColor.withValues(alpha: 0.3);
    }

    if (dayData['isPremium'] == true) {
      return Colors.purple.withValues(alpha: 0.1);
    }

    final activity = dayData['activity'] as double;
    return _getBiteActivityColor(activity).withValues(alpha: 0.1);
  }

  void _showDayDetails(Map<String, dynamic>? dayData, DateTime date) {
    if (dayData == null) return;

    if (dayData['isPremium'] == true) {
      _showPremiumDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          DateFormat('dd MMMM, EEEE').format(date),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getBiteActivityColor(dayData['activity']),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${(dayData['activity'] * 100).round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getBiteActivityText(dayData['activity']),
              style: TextStyle(
                color: _getBiteActivityColor(dayData['activity']),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getDayRecommendation(dayData['activity']),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Закрыть',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Премиум функция',
              style: TextStyle(color: AppConstants.textColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Colors.purple,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Расширенный 14-дневный прогноз',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Получите доступ к детальному прогнозу на 14 дней вперед с анализом лучших дней для рыбалки',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Позже',
              style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Переход к покупке премиума
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Перейти к Premium'),
          ),
        ],
      ),
    );
  }

  double _calculateWeekActivity(int startDay, int endDay) {
    final forecast = _generate14DaysForecast();
    final weekDays = forecast.skip(startDay).take(endDay - startDay);
    final freeActivities = weekDays
        .where((day) => !(day['isPremium'] as bool))
        .map((day) => day['activity'] as double);

    if (freeActivities.isEmpty) return 0.5;

    return freeActivities.reduce((a, b) => a + b) / freeActivities.length;
  }

  String _getWeekDatesRange(int startDay, int endDay) {
    final start = DateTime.now().add(Duration(days: startDay));
    final end = DateTime.now().add(Duration(days: endDay - 1));
    return '${DateFormat('dd.MM').format(start)} - ${DateFormat('dd.MM').format(end)}';
  }

  Color _getBetterWeekColor(double week1, double week2) {
    if (week1 > week2) return Colors.green;
    if (week2 > week1) return Colors.blue;
    return Colors.orange;
  }

  String _getBetterWeekText(double week1, double week2) {
    if (week1 > week2) {
      return 'Первая неделя будет лучше для рыбалки';
    } else if (week2 > week1) {
      return 'Вторая неделя обещает быть более успешной';
    } else {
      return 'Обе недели примерно одинаковы по условиям';
    }
  }

  String _getTemperatureTrend() {
    // Упрощенная логика тренда
    final random = math.Random().nextDouble();
    if (random > 0.6) return 'Потепление (+2-4°C)';
    if (random < 0.4) return 'Похолодание (-2-4°C)';
    return 'Стабильная (±1°C)';
  }

  Color _getTemperatureTrendColor() {
    final trend = _getTemperatureTrend();
    if (trend.contains('Потепление')) return Colors.orange;
    if (trend.contains('Похолодание')) return Colors.blue;
    return Colors.green;
  }

  String _getActivityTrend() {
    final week1 = _calculateWeekActivity(0, 7);
    final week2 = _calculateWeekActivity(7, 14);

    if (week2 > week1 + 0.1) return 'Улучшается к концу периода';
    if (week2 < week1 - 0.1) return 'Снижается к концу периода';
    return 'Остается стабильной';
  }

  Color _getActivityTrendColor() {
    final trend = _getActivityTrend();
    if (trend.contains('Улучшается')) return Colors.green;
    if (trend.contains('Снижается')) return Colors.red;
    return Colors.blue;
  }

  String _getMoonTrend() {
    // Упрощенная логика лунных фаз
    final phases = ['Новолуние (7-е)', 'Полнолуние (14-е)', 'Растущая луна'];
    return phases[math.Random().nextInt(phases.length)];
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

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) return Icons.wb_sunny;
    if (lowerCondition.contains('cloud')) return Icons.cloud;
    if (lowerCondition.contains('rain')) return Icons.grain;
    if (lowerCondition.contains('snow')) return Icons.ac_unit;
    if (lowerCondition.contains('storm')) return Icons.flash_on;
    if (lowerCondition.contains('locked')) return Icons.lock;
    return Icons.wb_sunny;
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
    return localizations.translate('very_poor_activity');
  }

  String _getDayRecommendation(double activity) {
    if (activity > 0.8) {
      return 'Отличный день! Планируйте дальние поездки и используйте разнообразные приманки 🏆';
    } else if (activity > 0.6) {
      return 'Хороший день для рыбалки. Стоит попробовать любимые места 👍';
    } else if (activity > 0.4) {
      return 'Средние условия. Используйте проверенные методы и терпение';
    } else {
      return 'Сложный день. Рекомендуется ловля в укрытых местах на глубине';
    }
  }
}

// Кастомный painter для клёвометра
class BiteMeterPainter14Days extends CustomPainter {
  final double progress;
  final Color color;

  BiteMeterPainter14Days({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 4;

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