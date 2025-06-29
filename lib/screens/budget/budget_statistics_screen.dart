// Путь: lib/screens/budget/budget_statistics_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_trip_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';

/// Упрощенный экран аналитики и статистики бюджета рыбалки
class BudgetStatisticsScreen extends StatefulWidget {
  /// Статистика поездок для отображения
  final FishingTripStatistics? statistics;

  const BudgetStatisticsScreen({
    super.key,
    this.statistics,
  });

  @override
  State<BudgetStatisticsScreen> createState() => _BudgetStatisticsScreenState();
}

class _BudgetStatisticsScreenState extends State<BudgetStatisticsScreen> {
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();

  String _selectedPeriod = 'all'; // month, year, all
  FishingTripStatistics? _currentStatistics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatistics = widget.statistics;
    if (_currentStatistics == null) {
      _loadStatistics();
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      DateTime? startDate;
      DateTime? endDate;

      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        case 'all':
        default:
          startDate = null;
          endDate = null;
          break;
      }

      final statistics = await _expenseRepository.getTripStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _currentStatistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Ошибка загрузки статистики: $e');
      }
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadStatistics();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ResponsiveContainer(
      type: ResponsiveContainerType.page,
      useSafeArea: true,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentStatistics == null || _currentStatistics!.tripCount == 0
          ? _buildEmptyState(localizations)
          : Column(
        children: [
          const SizedBox(height: 16),
          _buildPeriodSelector(localizations),
          const SizedBox(height: 24),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainStatistics(localizations),
                    const SizedBox(height: 24),
                    _buildAdditionalInfo(localizations),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: AppConstants.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          ResponsiveText(
            localizations.translate('no_data_for_analytics') ?? 'Нет данных для аналитики',
            type: ResponsiveTextType.titleLarge,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('add_trips_for_analytics') ?? 'Добавьте поездки для просмотра статистики',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('month', localizations.translate('month') ?? 'Месяц'),
          _buildPeriodButton('year', localizations.translate('year') ?? 'Год'),
          _buildPeriodButton('all', localizations.translate('all_time') ?? 'Всё время'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () => _onPeriodChanged(period),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ResponsiveText(
            label,
            type: ResponsiveTextType.labelLarge,
            color: isSelected ? Colors.white : AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatistics(AppLocalizations localizations) {
    final statistics = _currentStatistics!;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            localizations.translate('total_spent') ?? 'Потрачено',
            statistics.formattedTotal,
            Icons.payments,
            AppConstants.primaryColor,
            localizations.translate('total_spent_desc') ?? 'Общая сумма всех расходов',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            localizations.translate('avg_per_trip') ?? 'Среднее за поездку',
            statistics.formattedAveragePerTrip,
            Icons.trending_up,
            Colors.green,
            localizations.translate('avg_per_trip_desc') ?? 'Средние расходы на одну поездку',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            value,
            type: ResponsiveTextType.headlineMedium,
            fontWeight: FontWeight.bold,
            color: color,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            title,
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            description,
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(AppLocalizations localizations) {
    final statistics = _currentStatistics!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('detailed_statistics') ?? 'Детальная статистика',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 20),

          // Количество поездок
          _buildDetailRow(
            Icons.trip_origin,
            localizations.translate('trips_count') ?? 'Количество поездок',
            '${statistics.tripCount}',
            _getTripCountDescription(statistics.tripCount),
          ),

          const SizedBox(height: 16),

          // Период
          _buildDetailRow(
            Icons.date_range,
            localizations.translate('period') ?? 'Период',
            _getPeriodText(localizations),
            _getPeriodDescription(localizations),
          ),

          if (statistics.tripCount > 1) ...[
            const SizedBox(height: 16),

            // Диапазон расходов
            _buildDetailRow(
              Icons.show_chart,
              localizations.translate('expense_range') ?? 'Диапазон расходов',
              '${statistics.formattedMinTrip} - ${statistics.formattedMaxTrip}',
              localizations.translate('min_max_trip_expenses') ?? 'Минимальные и максимальные расходы за поездку',
            ),
          ],

          if (statistics.tripCount >= 3) ...[
            const SizedBox(height: 20),
            _buildTrendInfo(statistics, localizations),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                title,
                type: ResponsiveTextType.bodyLarge,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                value,
                type: ResponsiveTextType.titleMedium,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                description,
                type: ResponsiveTextType.bodyMedium,
                color: AppConstants.textColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendInfo(FishingTripStatistics statistics, AppLocalizations localizations) {
    // Простой анализ тренда: сравниваем среднее первой половины поездок со второй
    final isGrowingSpending = statistics.averagePerTrip > (statistics.totalAmount / statistics.tripCount * 0.8);

    final trendIcon = isGrowingSpending ? Icons.trending_up : Icons.trending_down;
    final trendColor = isGrowingSpending ? Colors.orange : Colors.green;
    final trendText = isGrowingSpending
        ? (localizations.translate('spending_trend_up') ?? 'Расходы растут')
        : (localizations.translate('spending_trend_down') ?? 'Расходы снижаются');
    final trendDescription = isGrowingSpending
        ? (localizations.translate('spending_trend_up_desc') ?? 'Последние поездки обходятся дороже')
        : (localizations.translate('spending_trend_down_desc') ?? 'Вы стали тратить меньше');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  trendText,
                  type: ResponsiveTextType.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
                const SizedBox(height: 4),
                ResponsiveText(
                  trendDescription,
                  type: ResponsiveTextType.bodyMedium,
                  color: AppConstants.textColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTripCountDescription(int count) {
    if (count == 1) {
      return 'Одна поездка';
    } else if (count >= 2 && count <= 4) {
      return '$count поездки';
    } else {
      return '$count поездок';
    }
  }

  String _getPeriodText(AppLocalizations localizations) {
    switch (_selectedPeriod) {
      case 'month':
        final now = DateTime.now();
        final months = [
          'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
          'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
        ];
        return '${months[now.month - 1]} ${now.year}';
      case 'year':
        return DateTime.now().year.toString();
      case 'all':
      default:
        return localizations.translate('all_time') ?? 'Всё время';
    }
  }

  String _getPeriodDescription(AppLocalizations localizations) {
    switch (_selectedPeriod) {
      case 'month':
        return localizations.translate('current_month_data') ?? 'Данные за текущий месяц';
      case 'year':
        return localizations.translate('current_year_data') ?? 'Данные за текущий год';
      case 'all':
      default:
        return localizations.translate('all_time_data') ?? 'Данные за всё время';
    }
  }
}