import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/statistics_provider.dart';
import '../../models/statistics_models.dart';
import '../../utils/date_formatter.dart';
import '../../localization/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsProvider _statisticsProvider;

  @override
  void initState() {
    super.initState();
    _statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    await _statisticsProvider.loadData();
  }

  void _onPeriodSelected(StatisticsPeriod period) {
    if (period == StatisticsPeriod.custom) {
      _showDateRangePicker();
    } else {
      _statisticsProvider.changePeriod(period);
    }
  }

  // Показать диалог выбора пользовательского диапазона дат
  Future<void> _showDateRangePicker() async {
    final localizations = AppLocalizations.of(context);

    final initialDateRange = DateTimeRange(
      start: _statisticsProvider.customDateRange.startDate,
      end: _statisticsProvider.customDateRange.endDate,
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      saveText: localizations.translate('apply'),
      cancelText: localizations.translate('cancel'),
      confirmText: localizations.translate('select_custom'),
      helpText: localizations.translate('select_date_range'),
      errorFormatText: localizations.translate('enter_correct_date_format'),
      errorInvalidText: localizations.translate('enter_correct_date'),
      errorInvalidRangeText: localizations.translate('select_correct_range'),
      fieldStartHintText: localizations.translate('start_date'),
      fieldEndHintText: localizations.translate('end_date'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.backgroundColor,
              onSurface: AppConstants.textColor,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppConstants.backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null && mounted) {
      _statisticsProvider.updateCustomDateRange(
        pickedDateRange.start,
        pickedDateRange.end,
      );
      _statisticsProvider.changePeriod(StatisticsPeriod.custom);
    }
  }

  String _getPeriodTitle() {
    final localizations = AppLocalizations.of(context);

    switch (_statisticsProvider.selectedPeriod) {
      case StatisticsPeriod.week:
        return localizations.translate('week');
      case StatisticsPeriod.month:
        return localizations.translate('month');
      case StatisticsPeriod.year:
        return localizations.translate('year');
      case StatisticsPeriod.allTime:
        return localizations.translate('all_time');
      case StatisticsPeriod.custom:
        return _statisticsProvider.customDateRange.format();
    }
  }

  // Метод для сброса фильтра на "Всё время"
  void _resetToAllTime() {
    _statisticsProvider.changePeriod(StatisticsPeriod.allTime);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('statistics'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading;
          final errorMessage = provider.errorMessage;
          final stats = provider.statistics;

          return RefreshIndicator(
            onRefresh: _loadStatistics,
            color: AppConstants.primaryColor,
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadStatistics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    child: Text(localizations.translate('try_again')),
                  ),
                ],
              ),
            )
                : stats.hasNoData
                ? _buildEmptyState()
                : _buildStatisticsContent(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    final isFilterApplied = _statisticsProvider.selectedPeriod != StatisticsPeriod.allTime;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.query_stats,
                color: AppConstants.textColor.withValues(alpha: 0.3),
                size: 80,
              ),
              const SizedBox(height: 24),

              // Показываем разный текст в зависимости от того, применён ли фильтр
              Text(
                isFilterApplied
                    ? localizations.translate('no_data_for_selected_period')
                    : localizations.translate('no_data_to_display'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Если фильтр применён, показываем информацию о текущем периоде
              if (isFilterApplied) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${localizations.translate('selected_period')}: ${_getPeriodTitle()}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Подсказка
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isFilterApplied
                      ? localizations.translate('try_different_period')
                      : localizations.translate('create_fishing_notes_for_stats'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Кнопки действий
              if (isFilterApplied) ...[
                // Кнопка "Показать все данные"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetToAllTime,
                    icon: const Icon(Icons.clear_all),
                    label: Text(localizations.translate('show_all_data')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Селектор периодов (всегда показывать для быстрого переключения)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      localizations.translate('select_date_range'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPeriodSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),

            const SizedBox(height: 24),

            // Заголовок с выбранным периодом
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getPeriodTitle(),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Показываем индикатор активного фильтра
                if (_statisticsProvider.selectedPeriod != StatisticsPeriod.allTime)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt,
                          color: AppConstants.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).translate('filter_applied'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Основная статистика в новом порядке
            _buildMainStatistics(),

            const SizedBox(height: 100), // Доп. отступ внизу для скролла
          ],
        ),
      ),
    );
  }

  // Селектор периодов (недельный, месячный, годовой и т.д.)
  Widget _buildPeriodSelector() {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPeriodButton(
            localizations.translate('week'),
            _statisticsProvider.selectedPeriod == StatisticsPeriod.week,
                () => _onPeriodSelected(StatisticsPeriod.week),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            localizations.translate('month'),
            _statisticsProvider.selectedPeriod == StatisticsPeriod.month,
                () => _onPeriodSelected(StatisticsPeriod.month),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            localizations.translate('year'),
            _statisticsProvider.selectedPeriod == StatisticsPeriod.year,
                () => _onPeriodSelected(StatisticsPeriod.year),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            localizations.translate('all_time'),
            _statisticsProvider.selectedPeriod == StatisticsPeriod.allTime,
                () => _onPeriodSelected(StatisticsPeriod.allTime),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            localizations.translate('select_custom'),
            _statisticsProvider.selectedPeriod == StatisticsPeriod.custom,
                () => _onPeriodSelected(StatisticsPeriod.custom),
            Icons.date_range,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
      String text,
      bool isSelected,
      VoidCallback onTap, [
        IconData? icon,
      ]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(25),
          // Добавляем рамку для лучшего выделения активного фильтра
          border: isSelected
              ? Border.all(color: AppConstants.primaryColor, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppConstants.textColor,
                size: 18,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSelected ? 14 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Основные статистические показатели в обновленном порядке
  Widget _buildMainStatistics() {
    final stats = _statisticsProvider.statistics;
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Самая большая рыба
        if (stats.biggestFish != null)
          _buildStatCard(
            icon: Icons.emoji_events,
            title: localizations.translate('biggest_fish'),
            value: '${stats.biggestFish!.weight} ${localizations.translate('kg')}',
            subtitle: stats.biggestFish!.getFormattedText(context),
            valueColor: Colors.amber,
          ),

        const SizedBox(height: 16),

        // 2. Всего поймано рыб
        _buildStatCard(
          icon: Icons.set_meal,
          title: localizations.translate('total_fish_caught'),
          value: stats.totalFish.toString(),
          subtitle: DateFormatter.getFishText(stats.totalFish, context),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 3. Нереализованные поклевки
        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: localizations.translate('missed_bites'),
          value: stats.missedBites.toString(),
          subtitle: localizations.translate('bites_without_catch'),
          valueColor: Colors.red,
        ),

        const SizedBox(height: 16),

        // 4. Реализация поклевок
        _buildStatCard(
          icon: Icons.percent,
          title: localizations.translate('bite_realization'),
          value: '${stats.realizationRate.toStringAsFixed(1)}%',
          subtitle: localizations.translate('fishing_efficiency'),
          valueColor: _getRealizationColor(stats.realizationRate),
        ),

        const SizedBox(height: 16),

        // 5. Общий вес пойманных рыб
        _buildStatCard(
          icon: Icons.scale,
          title: localizations.translate('total_catch_weight'),
          value: '${stats.totalWeight.toStringAsFixed(1)} ${localizations.translate('kg')}',
          subtitle: localizations.translate('total_weight_caught_fish'),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 6. Всего рыбалок
        _buildStatCard(
          icon: Icons.format_list_bulleted,
          title: localizations.translate('total_fishing_trips'),
          value: stats.totalTrips.toString(),
          subtitle: DateFormatter.getFishingTripsText(stats.totalTrips, context),
        ),

        const SizedBox(height: 16),

        // 7. Самая долгая рыбалка
        _buildStatCard(
          icon: Icons.access_time,
          title: localizations.translate('longest_fishing_trip'),
          value: stats.longestTripDays.toString(),
          subtitle: DateFormatter.getDaysText(stats.longestTripDays, context),
        ),

        const SizedBox(height: 16),

        // 8. Всего дней на рыбалке
        _buildStatCard(
          icon: Icons.calendar_today,
          title: localizations.translate('total_fishing_days'),
          value: stats.totalDaysOnFishing.toString(),
          subtitle: localizations.translate('days_fishing'),
        ),

        const SizedBox(height: 16),

        // 9. Последний выезд
        if (stats.latestTrip != null)
          _buildStatCard(
            icon: Icons.directions_car,
            title: localizations.translate('last_fishing_trip'),
            value: stats.latestTrip!.tripName,
            subtitle: stats.latestTrip!.getFormattedText(context),
          ),

        const SizedBox(height: 16),

        // 10. Лучший месяц
        if (stats.bestMonth != null)
          _buildStatCard(
            icon: Icons.star,
            title: localizations.translate('best_month'),
            value: DateFormatter.getMonthInNominative(stats.bestMonth!.month, context),
            subtitle: stats.bestMonth!.getFormattedText(context),
            valueColor: Colors.amber,
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: valueColor ?? AppConstants.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
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

  Color _getRealizationColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}