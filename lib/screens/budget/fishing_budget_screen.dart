// Путь: lib/screens/budget/fishing_budget_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/responsive/responsive_button.dart';
import 'add_fishing_trip_expenses_screen.dart';
import 'expense_list_screen.dart';
import 'budget_statistics_screen.dart';

/// Главный экран управления бюджетом рыбалки
class FishingBudgetScreen extends StatefulWidget {
  const FishingBudgetScreen({super.key});

  @override
  State<FishingBudgetScreen> createState() => _FishingBudgetScreenState();
}

class _FishingBudgetScreenState extends State<FishingBudgetScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();

  List<FishingExpenseModel> _expenses = [];
  FishingExpenseStatistics? _statistics;
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // month, year, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      setState(() => _isLoading = true);

      final expenses = await _expenseRepository.getUserExpenses();
      final filteredExpenses = _filterExpensesByPeriod(expenses, _selectedPeriod);
      final statistics = FishingExpenseStatistics.fromExpenses(filteredExpenses);

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    }
  }

  List<FishingExpenseModel> _filterExpensesByPeriod(
      List<FishingExpenseModel> expenses,
      String period
      ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        return expenses;
    }

    return expenses.where((expense) =>
    expense.date.isAfter(startDate) || expense.date.isAtSameMomentAs(startDate)
    ).toList();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadExpenses();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (result == true) {
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: ResponsiveText(
          localizations.translate('fishing_budget') ?? 'Бюджет рыбалки',
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _loadExpenses,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.textColor,
          unselectedLabelColor: AppConstants.textColor.withOpacity(0.6),
          indicatorColor: AppConstants.primaryColor,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('overview') ?? 'Обзор',
            ),
            Tab(
              icon: Icon(Icons.list, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('expenses') ?? 'Расходы',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('analytics') ?? 'Аналитика',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить расходы на рыбалку',
      ),
    );
  }

  Widget _buildOverviewTab() {
    final localizations = AppLocalizations.of(context);

    return ResponsiveContainer(
      type: ResponsiveContainerType.page,
      useSafeArea: true,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildCategoriesOverview(),
              const SizedBox(height: 24),
              _buildRecentExpenses(),
              const SizedBox(height: 100), // Отступ для FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    final filteredExpenses = _filterExpensesByPeriod(_expenses, _selectedPeriod);
    return ExpenseListScreen(
      expenses: filteredExpenses,
      onExpenseUpdated: _loadExpenses,
    );
  }

  Widget _buildAnalyticsTab() {
    return BudgetStatisticsScreen(
      statistics: _statistics,
      expenses: _filterExpensesByPeriod(_expenses, _selectedPeriod),
    );
  }

  Widget _buildSummaryCard() {
    final localizations = AppLocalizations.of(context);
    final statistics = _statistics;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('total_expenses') ?? 'Общие расходы',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            statistics?.formattedTotal ?? '₸ 0',
            type: ResponsiveTextType.displayMedium,
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 16),
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPeriodButton('month', localizations.translate('month') ?? 'Месяц'),
        _buildPeriodButton('year', localizations.translate('year') ?? 'Год'),
        _buildPeriodButton('all', localizations.translate('all_time') ?? 'Всё время'),
      ],
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () => _onPeriodChanged(period),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildSummaryStats() {
    final localizations = AppLocalizations.of(context);
    final statistics = _statistics;

    if (statistics == null) return const SizedBox.shrink();

    // Рассчитываем количество уникальных поездок
    final uniqueDates = _filterExpensesByPeriod(_expenses, _selectedPeriod)
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .length;

    final avgPerTrip = uniqueDates > 0 ? statistics.totalAmount / uniqueDates : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            localizations.translate('avg_per_trip') ?? 'Средние за поездку',
            '₸ ${avgPerTrip.toStringAsFixed(0)}',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            localizations.translate('trips_count') ?? 'Поездок',
            uniqueDates.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        ResponsiveText(
          value,
          type: ResponsiveTextType.titleLarge,
          color: AppConstants.textColor,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveText(
          label,
          type: ResponsiveTextType.labelSmall,
          color: AppConstants.textColor.withOpacity(0.7),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add_card),
              label: Text(localizations.translate('add_expense') ?? 'Добавить расход'),
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
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement budget planning
                _showErrorSnackBar('Функция в разработке');
              },
              icon: const Icon(Icons.trending_up),
              label: Text(localizations.translate('planning') ?? 'Планирование'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: BorderSide(color: AppConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesOverview() {
    final localizations = AppLocalizations.of(context);
    final statistics = _statistics;

    if (statistics == null || statistics.categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              localizations.translate('expense_categories') ?? 'Категории расходов',
              type: ResponsiveTextType.titleMedium,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 16),
            Center(
              child: ResponsiveText(
                localizations.translate('no_expenses_yet') ?? 'Пока нет расходов',
                type: ResponsiveTextType.caption,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('expense_categories') ?? 'Категории расходов',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          ...FishingExpenseCategory.allCategories.map((category) {
            final amount = statistics.categoryTotals[category] ?? 0;
            return _buildCategoryItem(category, amount);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(FishingExpenseCategory category, double amount) {
    final localizations = AppLocalizations.of(context);

    // Получаем локализованное название категории
    String categoryName;
    switch (category) {
      case FishingExpenseCategory.tackle:
        categoryName = localizations.translate('category_tackle') ?? 'Снасти и оборудование';
        break;
      case FishingExpenseCategory.bait:
        categoryName = localizations.translate('category_bait') ?? 'Наживка и прикормка';
        break;
      case FishingExpenseCategory.transport:
        categoryName = localizations.translate('category_transport') ?? 'Транспорт';
        break;
      case FishingExpenseCategory.accommodation:
        categoryName = localizations.translate('category_accommodation') ?? 'Проживание';
        break;
      case FishingExpenseCategory.food:
        categoryName = localizations.translate('category_food') ?? 'Питание';
        break;
      case FishingExpenseCategory.license:
        categoryName = localizations.translate('category_license') ?? 'Лицензии';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  categoryName,
                  type: ResponsiveTextType.bodyLarge,
                  fontWeight: FontWeight.w500,
                ),
                ResponsiveText(
                  _getCategoryDescription(category, localizations),
                  type: ResponsiveTextType.labelSmall,
                  color: AppConstants.textColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
          ResponsiveText(
            '₸ ${amount.toStringAsFixed(0)}',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(category),
          ),
        ],
      ),
    );
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

  String _getCategoryDescription(FishingExpenseCategory category, AppLocalizations localizations) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return localizations.translate('category_tackle_desc') ?? 'Удочки, катушки, приманки';
      case FishingExpenseCategory.bait:
        return localizations.translate('category_bait_desc') ?? 'Черви, опарыш, прикормка';
      case FishingExpenseCategory.transport:
        return localizations.translate('category_transport_desc') ?? 'Бензин, такси, аренда';
      case FishingExpenseCategory.accommodation:
        return localizations.translate('category_accommodation_desc') ?? 'Отель, база отдыха';
      case FishingExpenseCategory.food:
        return localizations.translate('category_food_desc') ?? 'Еда и напитки';
      case FishingExpenseCategory.license:
        return localizations.translate('category_license_desc') ?? 'Путевки, лицензии';
    }
  }

  Widget _buildRecentExpenses() {
    final localizations = AppLocalizations.of(context);
    final recentExpenses = _filterExpensesByPeriod(_expenses, _selectedPeriod)
        .take(5)
        .toList();

    if (recentExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              localizations.translate('recent_expenses') ?? 'Последние расходы',
              type: ResponsiveTextType.titleMedium,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  ResponsiveText(
                    localizations.translate('no_expenses_yet') ?? 'Пока нет расходов',
                    type: ResponsiveTextType.caption,
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    localizations.translate('add_first_expense') ?? 'Нажмите "+" чтобы добавить первый расход',
                    type: ResponsiveTextType.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('recent_expenses') ?? 'Последние расходы',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          ...recentExpenses.map((expense) => _buildExpenseItem(expense)).toList(),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(FishingExpenseModel expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                expense.category.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  expense.shortDescription,
                  type: ResponsiveTextType.bodyMedium,
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
            '-${expense.formattedAmount}',
            type: ResponsiveTextType.bodyLarge,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Сегодня';
    } else if (dateOnly == yesterday) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}';
    }
  }
}