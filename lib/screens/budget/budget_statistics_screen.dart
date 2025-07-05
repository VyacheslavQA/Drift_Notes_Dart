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

  String _selectedPeriod = 'all'; // month, year, all, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
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
        case 'custom':
          startDate = _customStartDate;
          endDate = _customEndDate;
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
        final localizations = AppLocalizations.of(context);
        _showErrorSnackBar('${localizations.translate('statistics_loading_error')}: $e');
      }
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      if (period != 'custom') {
        _customStartDate = null;
        _customEndDate = null;
      }
    });

    if (period == 'custom') {
      _showCustomDatePicker();
    } else {
      _loadStatistics();
    }
  }

  Future<void> _showCustomDatePicker() async {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('select_date_range') ?? 'Выберите период',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Дата начала
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _customStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppConstants.primaryColor,
                              surface: AppConstants.cardColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setDialogState(() {
                        _customStartDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.textColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('start_date') ?? 'Дата начала',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                _customStartDate != null
                                    ? _formatDate(_customStartDate!)
                                    : localizations.translate('select_date') ?? 'Выберите дату',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Дата окончания
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _customEndDate ?? DateTime.now(),
                      firstDate: _customStartDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppConstants.primaryColor,
                              surface: AppConstants.cardColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setDialogState(() {
                        _customEndDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.textColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('end_date') ?? 'Дата окончания',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                _customEndDate != null
                                    ? _formatDate(_customEndDate!)
                                    : localizations.translate('select_date') ?? 'Выберите дату',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPeriod = 'all';
                _customStartDate = null;
                _customEndDate = null;
              });
              Navigator.pop(context);
              _loadStatistics();
            },
            child: Text(
              localizations.translate('cancel') ?? 'Отмена',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: _customStartDate != null && _customEndDate != null
                ? () {
              Navigator.pop(context);
              _loadStatistics();
            }
                : null,
            child: Text(
              localizations.translate('apply') ?? 'Применить',
              style: TextStyle(
                color: _customStartDate != null && _customEndDate != null
                    ? AppConstants.primaryColor
                    : AppConstants.textColor.withOpacity(0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getDateRangeDescription() {
    final localizations = AppLocalizations.of(context);

    switch (_selectedPeriod) {
      case 'month':
        final now = DateTime.now();
        return '${_getMonthName(now.month, localizations)} ${now.year}';
      case 'year':
        return DateTime.now().year.toString();
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}';
        }
        return localizations.translate('custom_period') ?? 'Произвольный период';
      case 'all':
      default:
        return localizations.translate('all_time') ?? 'Всё время';
    }
  }

  String _getMonthName(int month, AppLocalizations localizations) {
    final monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return localizations.translate(monthKeys[month - 1]) ?? 'Месяц';
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
          _buildDateFilter(localizations),
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
          Expanded(child: _buildPeriodButton('month', localizations.translate('month') ?? 'Месяц')),
          Expanded(child: _buildPeriodButton('year', localizations.translate('year') ?? 'Год')),
          Expanded(child: _buildPeriodButton('all', localizations.translate('all_time') ?? 'Всё время')),
        ],
      ),
    );
  }

  Widget _buildDateFilter(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('filter_by_period') ?? 'Фильтр по периоду',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getDateRangeDescription(),
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Первая строка: основные периоды
          Row(
            children: [
              Expanded(child: _buildPeriodButton('month', localizations.translate('month') ?? 'Месяц')),
              const SizedBox(width: 8),
              Expanded(child: _buildPeriodButton('year', localizations.translate('year') ?? 'Год')),
              const SizedBox(width: 8),
              Expanded(child: _buildPeriodButton('all', localizations.translate('all_time') ?? 'Всё время')),
            ],
          ),
          const SizedBox(height: 8),
          // Вторая строка: кастомный период
          SizedBox(
            width: double.infinity,
            child: _buildPeriodButton('custom', localizations.translate('custom_period') ?? 'Произвольный период'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => _onPeriodChanged(period),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCustomPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => _onPeriodChanged(period),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMainStatistics(AppLocalizations localizations) {
    final statistics = _currentStatistics!;

    return Column(
      children: [
        _buildStatCard(
          localizations.translate('total_spent') ?? 'Потрачено',
          statistics.formattedTotal,
          Icons.payments,
          AppConstants.primaryColor,
          localizations.translate('total_spent_desc') ?? 'Общая сумма всех расходов',
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          localizations.translate('avg_per_trip') ?? 'Среднее за поездку',
          statistics.formattedAveragePerTrip,
          Icons.trending_up,
          Colors.green,
          localizations.translate('avg_per_trip_desc') ?? 'Средние расходы на одну поездку',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
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
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textColor.withOpacity(0.7),
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
            _getTripCountDescription(statistics.tripCount, localizations),
          ),

          const SizedBox(height: 16),

          // Период
          _buildDetailRow(
            Icons.date_range,
            localizations.translate('period') ?? 'Период',
            _getDateRangeDescription(),
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

  String _getTripCountDescription(int count, AppLocalizations localizations) {
    if (count == 1) {
      return localizations.translate('one_trip') ?? 'Одна поездка';
    } else if (count >= 2 && count <= 4) {
      return localizations.translate('few_trips')?.replaceFirst('%count%', count.toString()) ?? '$count поездки';
    } else {
      return localizations.translate('many_trips')?.replaceFirst('%count%', count.toString()) ?? '$count поездок';
    }
  }

  String _getPeriodDescription(AppLocalizations localizations) {
    switch (_selectedPeriod) {
      case 'month':
        return localizations.translate('current_month_data') ?? 'Данные за текущий месяц';
      case 'year':
        return localizations.translate('current_year_data') ?? 'Данные за текущий год';
      case 'custom':
        return localizations.translate('custom_period_data') ?? 'Данные за выбранный период';
      case 'all':
      default:
        return localizations.translate('all_time_data') ?? 'Данные за всё время';
    }
  }
}