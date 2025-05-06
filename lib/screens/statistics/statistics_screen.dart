import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/statistics_provider.dart';
import '../../models/statistics_models.dart';
import '../../utils/date_formatter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
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
    final initialDateRange = DateTimeRange(
      start: _statisticsProvider.customDateRange.startDate,
      end: _statisticsProvider.customDateRange.endDate,
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      saveText: 'Применить',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      helpText: 'Выберите диапазон дат',
      errorFormatText: 'Введите дату в правильном формате',
      errorInvalidText: 'Введите правильную дату',
      errorInvalidRangeText: 'Выберите правильный диапазон',
      fieldStartHintText: 'Начальная дата',
      fieldEndHintText: 'Конечная дата',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.backgroundColor,
              onSurface: AppConstants.textColor,
            ),
            dialogBackgroundColor: AppConstants.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      _statisticsProvider.updateCustomDateRange(
        pickedDateRange.start,
        pickedDateRange.end,
      );
      _statisticsProvider.changePeriod(StatisticsPeriod.custom);
    }
  }

  String _getPeriodTitle() {
    switch (_statisticsProvider.selectedPeriod) {
      case StatisticsPeriod.week:
        return 'Последние 7 дней';
      case StatisticsPeriod.month:
        return 'Последние 30 дней';
      case StatisticsPeriod.year:
        return 'Текущий год';
      case StatisticsPeriod.allTime:
        return 'За всё время';
      case StatisticsPeriod.custom:
        return _statisticsProvider.customDateRange.format();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Статистика',
          style: TextStyle(
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
                  Icon(
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
                    child: const Text('Повторить'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats,
            color: AppConstants.textColor.withOpacity(0.3),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет данных для отображения',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Создайте заметки о рыбалке для отображения статистики',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
            Text(
              _getPeriodTitle(),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Основная статистика в новом порядке
            _buildMainStatistics(),

            const SizedBox(height: 24),

            // Дополнительные разделы статистики
            _buildEfficiencySection(),

            const SizedBox(height: 100), // Доп. отступ внизу для скролла
          ],
        ),
      ),
    );
  }

  // Селектор периодов (недельный, месячный, годовой и т.д.)
  Widget _buildPeriodSelector() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPeriodButton(
            'Неделя',
            _statisticsProvider.selectedPeriod == StatisticsPeriod.week,
                () => _onPeriodSelected(StatisticsPeriod.week),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            'Месяц',
            _statisticsProvider.selectedPeriod == StatisticsPeriod.month,
                () => _onPeriodSelected(StatisticsPeriod.month),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            'Год',
            _statisticsProvider.selectedPeriod == StatisticsPeriod.year,
                () => _onPeriodSelected(StatisticsPeriod.year),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            'Всё время',
            _statisticsProvider.selectedPeriod == StatisticsPeriod.allTime,
                () => _onPeriodSelected(StatisticsPeriod.allTime),
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            'Выбрать',
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
              : AppConstants.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Самая большая рыба
        if (stats.biggestFish != null)
          _buildStatCard(
            icon: Icons.emoji_events,
            title: 'Самая большая рыба',
            value: '${stats.biggestFish!.weight} кг',
            subtitle: stats.biggestFish!.formattedText,
            valueColor: Colors.amber,
          ),

        const SizedBox(height: 16),

        // 2. Всего поймано рыб
        _buildStatCard(
          icon: Icons.set_meal,
          title: 'Всего поймано рыб',
          value: stats.totalFish.toString(),
          subtitle: DateFormatter.getFishText(stats.totalFish),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 3. Нереализованные поклевки
        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: 'Нереализованные поклевки',
          value: stats.missedBites.toString(),
          subtitle: 'поклевок без поимки',
          valueColor: Colors.red,
        ),

        const SizedBox(height: 16),

        // 4. Реализация поклевок
        _buildStatCard(
          icon: Icons.percent,
          title: 'Реализация поклевок',
          value: '${stats.realizationRate.toStringAsFixed(1)}%',
          subtitle: 'эффективность ловли',
          valueColor: _getRealizationColor(stats.realizationRate),
        ),

        const SizedBox(height: 16),

        // 5. Всего рыбалок
        _buildStatCard(
          icon: Icons.format_list_bulleted,
          title: 'Всего рыбалок',
          value: stats.totalTrips.toString(),
          subtitle: DateFormatter.getFishingTripsText(stats.totalTrips),
        ),

        const SizedBox(height: 16),

        // 6. Самая долгая рыбалка
        _buildStatCard(
          icon: Icons.access_time,
          title: 'Самая долгая рыбалка',
          value: stats.longestTripDays.toString(),
          subtitle: DateFormatter.getDaysText(stats.longestTripDays),
        ),

        const SizedBox(height: 16),

        // 7. Всего дней на рыбалке
        _buildStatCard(
          icon: Icons.calendar_today,
          title: 'Всего дней на рыбалке',
          value: stats.totalDaysOnFishing.toString(),
          subtitle: 'дней на рыбалке',
        ),

        const SizedBox(height: 16),

        // 8. Последний выезд
        if (stats.latestTrip != null)
          _buildStatCard(
            icon: Icons.directions_car,
            title: 'Последний выезд',
            value: stats.latestTrip!.tripName,
            subtitle: stats.latestTrip!.formattedText,
          ),

        const SizedBox(height: 16),

        // 9. Лучший месяц
        if (stats.bestMonth != null)
          _buildStatCard(
            icon: Icons.star,
            title: 'Лучший месяц',
            value: DateFormatter.getMonthInNominative(stats.bestMonth!.month),
            subtitle: stats.bestMonth!.formattedText,
            valueColor: Colors.amber,
          ),
      ],
    );
  }

  // Секция с данными об эффективности по типам рыбалки
  Widget _buildEfficiencySection() {
    final efficiencyByType = _statisticsProvider.calculateEfficiencyByFishingType();

    if (efficiencyByType.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Эффективность по типам рыбалки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: efficiencyByType.entries.map((entry) {
              final efficiency = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: efficiency / 100,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getEfficiencyColor(efficiency),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$efficiency%',
                          style: TextStyle(
                            color: _getEfficiencyColor(efficiency),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  if (entry.key != efficiencyByType.keys.last)
                    const Divider(height: 24, color: Colors.white24),
                ],
              );
            }).toList(),
          ),
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
              color: AppConstants.primaryColor.withOpacity(0.2),
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
                    color: AppConstants.textColor.withOpacity(0.7),
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
                      color: AppConstants.textColor.withOpacity(0.7),
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

  Color _getEfficiencyColor(int efficiency) {
    if (efficiency >= 70) return Colors.green;
    if (efficiency >= 40) return Colors.orange;
    return Colors.red;
  }
}