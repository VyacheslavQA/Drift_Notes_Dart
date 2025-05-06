// Путь: lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late StatisticsProvider _statisticsProvider;

  @override
  void initState() {
    super.initState();
    _statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    await _statisticsProvider.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Статистика',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
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
                    provider.errorMessage!,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.statistics.hasNoData) {
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
                    'Нет данных для отображения статистики',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте заметки о рыбалке, чтобы увидеть статистику',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppConstants.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(provider),
                  const SizedBox(height: 24),
                  _buildGeneralStatistics(provider),
                  const SizedBox(height: 24),
                  _buildFishingEfficiencySection(provider),
                  const SizedBox(height: 24),
                  _buildBiteStatistics(provider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(StatisticsProvider provider) {
    return Column(
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPeriodChip(
                label: 'Неделя',
                selected: provider.selectedPeriod == StatisticsPeriod.week,
                onTap: () => provider.changePeriod(StatisticsPeriod.week),
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                label: 'Месяц',
                selected: provider.selectedPeriod == StatisticsPeriod.month,
                onTap: () => provider.changePeriod(StatisticsPeriod.month),
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                label: 'Год',
                selected: provider.selectedPeriod == StatisticsPeriod.year,
                onTap: () => provider.changePeriod(StatisticsPeriod.year),
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                label: 'Всё время',
                selected: provider.selectedPeriod == StatisticsPeriod.allTime,
                onTap: () => provider.changePeriod(StatisticsPeriod.allTime),
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                label: 'Произвольно',
                selected: provider.selectedPeriod == StatisticsPeriod.custom,
                onTap: () => _selectCustomDateRange(provider),
              ),
            ],
          ),
        ),
        if (provider.selectedPeriod == StatisticsPeriod.custom)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              provider.customDateRange.format(),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppConstants.primaryColor : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppConstants.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange(StatisticsProvider provider) async {
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
      provider.changePeriod(StatisticsPeriod.custom);
    }
  }

  Widget _buildGeneralStatistics(StatisticsProvider provider) {
    final stats = provider.statistics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Общая статистика',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          icon: Icons.directions_car,
          title: 'Всего рыбалок',
          value: '${stats.totalTrips}',
          subtitle: DateFormatter.getFishingTripsText(stats.totalTrips),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.calendar_today,
          title: 'Всего дней на рыбалке',
          value: '${stats.totalDaysOnFishing}',
          subtitle: DateFormatter.getDaysText(stats.totalDaysOnFishing),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.access_time,
          title: 'Самая долгая рыбалка',
          value: '${stats.longestTripDays}',
          subtitle: DateFormatter.getDaysText(stats.longestTripDays),
        ),
        if (stats.biggestFish != null) ...[
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.emoji_events,
            title: 'Самая большая рыба',
            value: stats.biggestFish!.formattedText,
            valueColor: Colors.amber,
          ),
        ],
        if (stats.latestTrip != null) ...[
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.update,
            title: 'Последний выезд',
            value: stats.latestTrip!.formattedText,
          ),
        ],
      ],
    );
  }

  Widget _buildFishingEfficiencySection(StatisticsProvider provider) {
    final efficiencyByType = provider.calculateEfficiencyByFishingType();

    if (efficiencyByType.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Результативность по типам рыбалки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...efficiencyByType.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildEfficiencyCard(
              type: entry.key,
              efficiency: entry.value,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEfficiencyCard({
    required String type,
    required int efficiency,
  }) {
    final color = _getEfficiencyColor(efficiency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: efficiency / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$efficiency%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(int efficiency) {
    if (efficiency >= 70) return Colors.green;
    if (efficiency >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBiteStatistics(StatisticsProvider provider) {
    final stats = provider.statistics;
    final totalCaughtFish = provider.totalCaughtFish;
    final totalMissedBites = provider.totalMissedBites;
    final totalBites = totalCaughtFish + totalMissedBites;
    final realizationRate = totalBites > 0 ? (totalCaughtFish / totalBites * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика поклевок',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.set_meal,
                title: 'Пойманные рыбы',
                value: '$totalCaughtFish',
                subtitle: DateFormatter.getFishText(totalCaughtFish),
                valueColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.hourglass_empty,
                title: 'Нереализованные',
                value: '$totalMissedBites',
                subtitle: 'поклевок без поимки',
                valueColor: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalBites > 0) ...[
          _buildStatCard(
            icon: Icons.percent,
            title: 'Процент реализации поклевок',
            value: '${realizationRate.toStringAsFixed(1)}%',
            subtitle: 'эффективность ловли',
            valueColor: _getEfficiencyColor(realizationRate.round()),
          ),
          const SizedBox(height: 16),
          _buildBiteDistributionChart(totalCaughtFish, totalMissedBites),
        ],
      ],
    );
  }

  Widget _buildBiteDistributionChart(int caught, int missed) {
    final total = caught + missed;
    final caughtPercentage = caught / total;
    final missedPercentage = missed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Распределение поклевок',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Expanded(
                    flex: (caughtPercentage * 100).round(),
                    child: Container(
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: (missedPercentage * 100).round(),
                    child: Container(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                color: Colors.green,
                label: 'Пойманная рыба',
                percentage: caughtPercentage * 100,
              ),
              _buildLegendItem(
                color: Colors.red,
                label: 'Нереализованные',
                percentage: missedPercentage * 100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String subtitle = '',
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}