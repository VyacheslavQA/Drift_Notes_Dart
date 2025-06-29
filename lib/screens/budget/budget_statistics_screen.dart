// Путь: lib/screens/budget/budget_statistics_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';

/// Экран аналитики и статистики бюджета рыбалки
class BudgetStatisticsScreen extends StatefulWidget {
  /// Статистика для отображения
  final FishingExpenseStatistics? statistics;

  /// Список расходов для анализа
  final List<FishingExpenseModel> expenses;

  const BudgetStatisticsScreen({
    super.key,
    this.statistics,
    required this.expenses,
  });

  @override
  State<BudgetStatisticsScreen> createState() => _BudgetStatisticsScreenState();
}

class _BudgetStatisticsScreenState extends State<BudgetStatisticsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String _selectedPeriod = 'month'; // month, year, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Фильтрация расходов по периоду
  List<FishingExpenseModel> _getFilteredExpenses() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        return widget.expenses;
    }

    return widget.expenses.where((expense) =>
    expense.date.isAfter(startDate) || expense.date.isAtSameMomentAs(startDate)
    ).toList();
  }

  // Получение статистики за выбранный период
  FishingExpenseStatistics _getStatistics() {
    final filteredExpenses = _getFilteredExpenses();
    return FishingExpenseStatistics.fromExpenses(filteredExpenses);
  }

  // Анализ трендов по месяцам
  Map<String, double> _getMonthlyTrends() {
    final monthlyData = <String, double>{};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.month.toString().padLeft(2, '0')}.${month.year}';
      monthlyData[monthKey] = 0.0;
    }

    for (var expense in widget.expenses) {
      final monthKey = '${expense.date.month.toString().padLeft(2, '0')}.${expense.date.year}';
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = monthlyData[monthKey]! + expense.amount;
      }
    }

    return monthlyData;
  }

  // Получение топ категорий
  List<MapEntry<FishingExpenseCategory, double>> _getTopCategories() {
    final filteredExpenses = _getFilteredExpenses();
    final categoryTotals = <FishingExpenseCategory, double>{};

    for (var expense in filteredExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // Анализ паттернов трат
  Map<String, dynamic> _getSpendingPatterns() {
    final filteredExpenses = _getFilteredExpenses();
    if (filteredExpenses.isEmpty) return {};

    // Анализ по дням недели
    final weekdaySpending = <int, double>{};
    for (int i = 1; i <= 7; i++) {
      weekdaySpending[i] = 0.0;
    }

    // Анализ по времени месяца
    final monthPeriodSpending = <String, double>{
      'начало': 0.0, // 1-10
      'середина': 0.0, // 11-20
      'конец': 0.0, // 21-31
    };

    double totalAmount = 0.0;
    double maxExpense = 0.0;
    double minExpense = double.infinity;

    for (var expense in filteredExpenses) {
      totalAmount += expense.amount;
      maxExpense = math.max(maxExpense, expense.amount);
      minExpense = math.min(minExpense, expense.amount);

      // По дням недели
      weekdaySpending[expense.date.weekday] =
          weekdaySpending[expense.date.weekday]! + expense.amount;

      // По периодам месяца
      final day = expense.date.day;
      if (day <= 10) {
        monthPeriodSpending['начало'] = monthPeriodSpending['начало']! + expense.amount;
      } else if (day <= 20) {
        monthPeriodSpending['середина'] = monthPeriodSpending['середина']! + expense.amount;
      } else {
        monthPeriodSpending['конец'] = monthPeriodSpending['конец']! + expense.amount;
      }
    }

    final averageExpense = totalAmount / filteredExpenses.length;

    return {
      'weekdaySpending': weekdaySpending,
      'monthPeriodSpending': monthPeriodSpending,
      'averageExpense': averageExpense,
      'maxExpense': maxExpense,
      'minExpense': minExpense == double.infinity ? 0.0 : minExpense,
      'totalExpenses': filteredExpenses.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (widget.expenses.isEmpty) {
      return _buildEmptyState(localizations);
    }

    return ResponsiveContainer(
      type: ResponsiveContainerType.page,
      useSafeArea: true,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildPeriodSelector(localizations),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(localizations),
                _buildCategoriesTab(localizations),
                _buildTrendsTab(localizations),
              ],
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
            localizations.translate('add_expenses_for_analytics') ?? 'Добавьте расходы для просмотра статистики',
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
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildOverviewTab(AppLocalizations localizations) {
    final statistics = _getStatistics();
    final patterns = _getSpendingPatterns();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(statistics, localizations),
          const SizedBox(height: 24),
          _buildSpendingPatternsCard(patterns, localizations),
          const SizedBox(height: 24),
          _buildTopExpensesCard(localizations),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(AppLocalizations localizations) {
    final topCategories = _getTopCategories();
    final statistics = _getStatistics();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBreakdownCard(topCategories, statistics, localizations),
          const SizedBox(height: 24),
          _buildCategoryComparisonCard(topCategories, localizations),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(AppLocalizations localizations) {
    final monthlyTrends = _getMonthlyTrends();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyTrendsCard(monthlyTrends, localizations),
          const SizedBox(height: 24),
          _buildForecastCard(monthlyTrends, localizations),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FishingExpenseStatistics statistics, AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            localizations.translate('total_spent') ?? 'Потрачено',
            statistics.formattedTotal,
            Icons.payments,
            AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            localizations.translate('average_expense') ?? 'Средний расход',
            statistics.formattedAverage,
            Icons.trending_up,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ResponsiveFishingCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          ResponsiveText(
            value,
            type: ResponsiveTextType.titleLarge,
            fontWeight: FontWeight.bold,
            color: color,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          ResponsiveText(
            title,
            type: ResponsiveTextType.labelMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPatternsCard(Map<String, dynamic> patterns, AppLocalizations localizations) {
    if (patterns.isEmpty) return const SizedBox.shrink();

    final weekdaySpending = patterns['weekdaySpending'] as Map<int, double>;
    final monthPeriodSpending = patterns['monthPeriodSpending'] as Map<String, double>;

    // Найдем самый дорогой день недели
    int mostExpensiveWeekday = 1;
    double maxWeekdaySpending = 0;
    weekdaySpending.forEach((day, amount) {
      if (amount > maxWeekdaySpending) {
        maxWeekdaySpending = amount;
        mostExpensiveWeekday = day;
      }
    });

    // Найдем самый дорогой период месяца
    String mostExpensivePeriod = 'начало';
    double maxPeriodSpending = 0;
    monthPeriodSpending.forEach((period, amount) {
      if (amount > maxPeriodSpending) {
        maxPeriodSpending = amount;
        mostExpensivePeriod = period;
      }
    });

    final weekdayNames = [
      'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'
    ];

    return ResponsiveFishingCard(
      title: localizations.translate('spending_patterns') ?? 'Паттерны трат',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatternItem(
            Icons.calendar_today,
            localizations.translate('most_expensive_weekday') ?? 'Самый дорогой день недели',
            weekdayNames[mostExpensiveWeekday - 1],
            '₸ ${maxWeekdaySpending.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 16),
          _buildPatternItem(
            Icons.date_range,
            localizations.translate('most_expensive_period') ?? 'Самый дорогой период месяца',
            '${mostExpensivePeriod} месяца',
            '₸ ${maxPeriodSpending.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 16),
          _buildPatternItem(
            Icons.calculate,
            localizations.translate('average_per_expense') ?? 'В среднем за расход',
            '',
            '₸ ${(patterns['averageExpense'] as double).toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(IconData icon, String title, String subtitle, String value) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                title,
                type: ResponsiveTextType.bodyMedium,
                fontWeight: FontWeight.w500,
              ),
              if (subtitle.isNotEmpty)
                ResponsiveText(
                  subtitle,
                  type: ResponsiveTextType.labelSmall,
                  color: AppConstants.textColor.withOpacity(0.7),
                ),
            ],
          ),
        ),
        ResponsiveText(
          value,
          type: ResponsiveTextType.bodyLarge,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTopExpensesCard(AppLocalizations localizations) {
    final filteredExpenses = _getFilteredExpenses();
    if (filteredExpenses.isEmpty) return const SizedBox.shrink();

    // Сортируем по убыванию суммы и берем топ-5
    final topExpenses = List<FishingExpenseModel>.from(filteredExpenses);
    topExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topExpenses.take(5).toList();

    return ResponsiveFishingCard(
      title: localizations.translate('top_expenses') ?? 'Самые крупные расходы',
      child: Column(
        children: top5.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          return _buildTopExpenseItem(expense, index + 1);
        }).toList(),
      ),
    );
  }

  Widget _buildTopExpenseItem(FishingExpenseModel expense, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: ResponsiveText(
                rank.toString(),
                type: ResponsiveTextType.labelLarge,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(expense.category.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  expense.shortDescription,
                  type: ResponsiveTextType.bodyMedium,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ResponsiveText(
                  _formatDate(expense.date),
                  type: ResponsiveTextType.labelSmall,
                  color: AppConstants.textColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
          ResponsiveText(
            expense.formattedAmount,
            type: ResponsiveTextType.bodyLarge,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(
      List<MapEntry<FishingExpenseCategory, double>> topCategories,
      FishingExpenseStatistics statistics,
      AppLocalizations localizations,
      ) {
    if (topCategories.isEmpty) return const SizedBox.shrink();

    return ResponsiveFishingCard(
      title: localizations.translate('expenses_by_category') ?? 'Расходы по категориям',
      child: Column(
        children: topCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = statistics.getCategoryPercentage(category);

          return _buildCategoryBreakdownItem(category, amount, percentage, localizations);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryBreakdownItem(
      FishingExpenseCategory category,
      double amount,
      double percentage,
      AppLocalizations localizations,
      ) {
    final categoryName = _getCategoryName(category, localizations);
    final color = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveText(
                  categoryName,
                  type: ResponsiveTextType.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ResponsiveText(
                    '₸ ${amount.toStringAsFixed(0)}',
                    type: ResponsiveTextType.bodyLarge,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  ResponsiveText(
                    '${percentage.toStringAsFixed(1)}%',
                    type: ResponsiveTextType.labelSmall,
                    color: AppConstants.textColor.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppConstants.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonCard(
      List<MapEntry<FishingExpenseCategory, double>> topCategories,
      AppLocalizations localizations,
      ) {
    if (topCategories.length < 2) return const SizedBox.shrink();

    final firstCategory = topCategories[0];
    final secondCategory = topCategories[1];
    final difference = firstCategory.value - secondCategory.value;
    final percentageDiff = (difference / secondCategory.value) * 100;

    return ResponsiveFishingCard(
      title: localizations.translate('category_comparison') ?? 'Сравнение категорий',
      child: Column(
        children: [
          ResponsiveText(
            localizations.translate('top_category_comparison') ??
                'Сравнение двух основных категорий расходов',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildComparisonItem(
            firstCategory.key,
            firstCategory.value,
            _getCategoryName(firstCategory.key, localizations),
            true,
            localizations,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ResponsiveText(
              '${localizations.translate('difference') ?? 'Разница'}: ₸ ${difference.toStringAsFixed(0)} (${percentageDiff.toStringAsFixed(1)}%)',
              type: ResponsiveTextType.labelMedium,
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          _buildComparisonItem(
            secondCategory.key,
            secondCategory.value,
            _getCategoryName(secondCategory.key, localizations),
            false,
            localizations,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
      FishingExpenseCategory category,
      double amount,
      String name,
      bool isTop,
      AppLocalizations localizations,
      ) {
    final color = _getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop ? color.withOpacity(0.1) : AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isTop ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  name,
                  type: ResponsiveTextType.bodyLarge,
                  fontWeight: FontWeight.w600,
                ),
                if (isTop)
                  ResponsiveText(
                    localizations.translate('top_category') ?? 'Основная категория',
                    type: ResponsiveTextType.labelSmall,
                    color: color,
                  ),
              ],
            ),
          ),
          ResponsiveText(
            '₸ ${amount.toStringAsFixed(0)}',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsCard(Map<String, double> monthlyTrends, AppLocalizations localizations) {
    final entries = monthlyTrends.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    // Находим максимальное значение для нормализации
    final maxValue = entries.map((e) => e.value).reduce(math.max);

    return ResponsiveFishingCard(
      title: localizations.translate('monthly_trends') ?? 'Тренды по месяцам',
      child: Column(
        children: [
          ResponsiveText(
            localizations.translate('spending_trend_last_6_months') ?? 'Динамика трат за последние 6 месяцев',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final height = maxValue > 0 ? (entry.value / maxValue) * 160 : 0.0;
                return _buildTrendBar(entry.key, entry.value, height);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(String month, double amount, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ResponsiveText(
          '₸${amount.toStringAsFixed(0)}',
          type: ResponsiveTextType.labelSmall,
          color: AppConstants.textColor.withOpacity(0.7),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: math.max(height, 4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        ResponsiveText(
          month,
          type: ResponsiveTextType.labelSmall,
          color: AppConstants.textColor.withOpacity(0.7),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForecastCard(Map<String, double> monthlyTrends, AppLocalizations localizations) {
    final entries = monthlyTrends.entries.toList();
    if (entries.length < 3) return const SizedBox.shrink();

    // Простой прогноз на основе среднего значения последних 3 месяцев
    final lastThreeMonths = entries.skip(entries.length - 3).map((e) => e.value).toList();
    final averageLastThree = lastThreeMonths.reduce((a, b) => a + b) / 3;

    // Тренд (растет/падает)
    final lastMonth = entries.last.value;
    final prevMonth = entries.length > 1 ? entries[entries.length - 2].value : 0;
    final trend = lastMonth > prevMonth ? 'растет' : lastMonth < prevMonth ? 'снижается' : 'стабилен';
    final trendIcon = lastMonth > prevMonth ? Icons.trending_up :
    lastMonth < prevMonth ? Icons.trending_down : Icons.trending_flat;
    final trendColor = lastMonth > prevMonth ? Colors.red :
    lastMonth < prevMonth ? Colors.green : Colors.grey;

    return ResponsiveFishingCard(
      title: localizations.translate('forecast') ?? 'Прогноз',
      child: Column(
        children: [
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      '${localizations.translate('trend') ?? 'Тренд'}: $trend',
                      type: ResponsiveTextType.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                    ResponsiveText(
                      localizations.translate('based_on_last_months') ?? 'На основе последних месяцев',
                      type: ResponsiveTextType.labelSmall,
                      color: AppConstants.textColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  localizations.translate('expected_next_month') ?? 'Ожидаемо в следующем месяце',
                  type: ResponsiveTextType.bodyMedium,
                ),
                ResponsiveText(
                  '₸ ${averageLastThree.toStringAsFixed(0)}',
                  type: ResponsiveTextType.titleMedium,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(FishingExpenseCategory category, AppLocalizations localizations) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return localizations.translate('category_tackle') ?? 'Снасти';
      case FishingExpenseCategory.bait:
        return localizations.translate('category_bait') ?? 'Наживка';
      case FishingExpenseCategory.transport:
        return localizations.translate('category_transport') ?? 'Транспорт';
      case FishingExpenseCategory.accommodation:
        return localizations.translate('category_accommodation') ?? 'Проживание';
      case FishingExpenseCategory.food:
        return localizations.translate('category_food') ?? 'Питание';
      case FishingExpenseCategory.license:
        return localizations.translate('category_license') ?? 'Лицензии';
    }
  }

  Color _getCategoryColor(FishingExpenseCategory category) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return const Color(0xFF2E7D32);
      case FishingExpenseCategory.bait:
        return const Color(0xFFFF8C00);
      case FishingExpenseCategory.transport:
        return const Color(0xFF1976D2);
      case FishingExpenseCategory.accommodation:
        return const Color(0xFF8E24AA);
      case FishingExpenseCategory.food:
        return const Color(0xFFD32F2F);
      case FishingExpenseCategory.license:
        return const Color(0xFF388E3C);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}