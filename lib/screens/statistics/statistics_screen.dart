// Путь: lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late StatisticsPeriod _selectedPeriod;
  CustomDateRange? _customDateRange;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final provider = Provider.of<StatisticsProvider>(context, listen: false);
    _selectedPeriod = provider.selectedPeriod;

    setState(() {
      _isLoading = true;
    });

    await provider.loadData();

    setState(() {
      _isLoading = false;
    });
  }

  void _changePeriod(StatisticsPeriod period) {
    final provider = Provider.of<StatisticsProvider>(context, listen: false);
    provider.changePeriod(period);

    setState(() {
      _selectedPeriod = period;
    });
  }

  // Выбор пользовательского диапазона дат
  Future<void> _selectCustomDateRange() async {
    final provider = Provider.of<StatisticsProvider>(context, listen: false);
    final initialDateRange = DateTimeRange(
      start: provider.customDateRange.startDate,
      end: provider.customDateRange.endDate,
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.textColor,
            ),
            dialogBackgroundColor: AppConstants.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      provider.updateCustomDateRange(
        pickedDateRange.start,
        pickedDateRange.end,
      );

      // Переключаемся на пользовательский период
      provider.changePeriod(StatisticsPeriod.custom);

      setState(() {
        _selectedPeriod = StatisticsPeriod.custom;
      });
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
        ),
      )
          : Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          final statistics = provider.statistics;

          if (statistics.hasNoData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: AppConstants.textColor.withOpacity(0.5),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных для статистики',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте заметки о рыбалке, чтобы увидеть статистику',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadStatistics,
            color: AppConstants.primaryColor,
            backgroundColor: AppConstants.surfaceColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Фильтр периодов
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Период',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Кнопки выбора периода
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPeriodButton(
                              title: 'Неделя',
                              period: StatisticsPeriod.week,
                              isSelected: _selectedPeriod == StatisticsPeriod.week,
                            ),
                            _buildPeriodButton(
                              title: 'Месяц',
                              period: StatisticsPeriod.month,
                              isSelected: _selectedPeriod == StatisticsPeriod.month,
                            ),
                            _buildPeriodButton(
                              title: 'Год',
                              period: StatisticsPeriod.year,
                              isSelected: _selectedPeriod == StatisticsPeriod.year,
                            ),
                            _buildPeriodButton(
                              title: 'Всё время',
                              period: StatisticsPeriod.allTime,
                              isSelected: _selectedPeriod == StatisticsPeriod.allTime,
                            ),
                          ],
                        ),

                        // Кнопка выбора произвольного периода
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton(
                            onPressed: _selectCustomDateRange,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPeriod == StatisticsPeriod.custom
                                  ? AppConstants.primaryColor
                                  : AppConstants.surfaceColor,
                              foregroundColor: AppConstants.textColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.date_range),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedPeriod == StatisticsPeriod.custom
                                      ? provider.customDateRange.format()
                                      : 'Выбрать произвольный период',
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 14,
                                    fontWeight: _selectedPeriod == StatisticsPeriod.custom
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Карточки статистики
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatCard(
                          icon: Icons.directions_boat,
                          title: 'Всего рыбалок',
                          value: statistics.totalTrips.toString(),
                          subtitle: DateFormatter.getFishingTripsText(statistics.totalTrips),
                        ),

                        const SizedBox(height: 16),

                        _buildStatCard(
                          icon: Icons.calendar_today,
                          title: 'Самая долгая рыбалка',
                          value: statistics.longestTripDays.toString(),
                          subtitle: DateFormatter.getDaysText(statistics.longestTripDays),
                        ),

                        const SizedBox(height: 16),

                        _buildStatCard(
                          icon: Icons.watch_later,
                          title: 'Всего дней на рыбалке',
                          value: statistics.totalDaysOnFishing.toString(),
                          subtitle: 'дней',
                        ),

                        const SizedBox(height: 16),

                        _buildStatCard(
                          icon: Icons.set_meal,
                          title: 'Всего поймано рыб',
                          value: statistics.totalFish.toString(),
                          subtitle: DateFormatter.getFishText(statistics.totalFish),
                          valueColor: Colors.green,
                        ),

                        const SizedBox(height: 16),

                        _buildStatCard(
                          icon: Icons.hourglass_empty,
                          title: 'Нереализованные поклевки',
                          value: statistics.missedBites.toString(),
                          subtitle: 'поклевок без поимки',
                          valueColor: Colors.red,
                        ),

                        if (statistics.biggestFish != null) ...[
                          const SizedBox(height: 16),

                          _buildStatCard(
                            icon: Icons.emoji_events,
                            title: 'Самая крупная рыба',
                            value: statistics.biggestFish!.formattedText,
                            subtitle: '',
                            valueColor: Colors.amber,
                          ),
                        ],

                        if (statistics.bestMonth != null) ...[
                          const SizedBox(height: 16),

                          _buildStatCard(
                            icon: Icons.star,
                            title: 'Лучший месяц',
                            value: statistics.bestMonth!.formattedText,
                            subtitle: '',
                            valueColor: Colors.amber,
                          ),
                        ],

                        const SizedBox(height: 16),

                        _buildStatCard(
                          icon: Icons.percent,
                          title: 'Процент реализации поклевок',
                          value: '${provider.biteRealizationRate.toStringAsFixed(1)}%',
                          subtitle: 'эффективность ловли',
                          valueColor: _getRealizationColor(provider.biteRealizationRate),
                        ),
                      ],
                    ),
                  ),

                  // Дополнительный отступ внизу для скролла
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton({
    required String title,
    required StatisticsPeriod period,
    required bool isSelected,
  }) {
    return ElevatedButton(
      onPressed: () => _changePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor:
        isSelected ? AppConstants.primaryColor : AppConstants.surfaceColor,
        foregroundColor: AppConstants.textColor,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
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
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  // Метод для определения цвета в зависимости от процента реализации
  Color _getRealizationColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}