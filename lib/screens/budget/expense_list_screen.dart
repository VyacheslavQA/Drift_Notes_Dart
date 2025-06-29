// Путь: lib/screens/budget/expense_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/responsive/responsive_button.dart';
import 'add_fishing_trip_expenses_screen.dart';

/// Экран списка суммированных расходов по категориям
class ExpenseListScreen extends StatefulWidget {
  /// Callback при обновлении расходов
  final VoidCallback? onExpenseUpdated;

  const ExpenseListScreen({
    super.key,
    this.onExpenseUpdated,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();
  final TextEditingController _searchController = TextEditingController();

  Map<FishingExpenseCategory, CategoryExpenseSummary> _categorySummaries = {};
  List<CategoryExpenseSummary> _filteredSummaries = [];
  String _sortBy = 'amount'; // amount, trips, category
  bool _sortAscending = false;
  String _selectedPeriod = 'all'; // month, year, all
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategorySummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorySummaries() async {
    try {
      setState(() => _isLoading = true);

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

      final summaries = await _expenseRepository.getCategorySummaries(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _categorySummaries = summaries;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    }
  }

  void _applyFilters() {
    _filteredSummaries = _categorySummaries.values.toList();

    // Поиск по названию категории
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      final localizations = AppLocalizations.of(context);
      _filteredSummaries = _filteredSummaries.where((summary) {
        final categoryName = _getCategoryName(summary.category, localizations).toLowerCase();
        return categoryName.contains(searchQuery);
      }).toList();
    }

    _sortSummaries();
  }

  void _sortSummaries() {
    switch (_sortBy) {
      case 'amount':
        _filteredSummaries.sort((a, b) =>
        _sortAscending ? a.totalAmount.compareTo(b.totalAmount) : b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'trips':
        _filteredSummaries.sort((a, b) =>
        _sortAscending ? a.tripCount.compareTo(b.tripCount) : b.tripCount.compareTo(a.tripCount));
        break;
      case 'category':
        _filteredSummaries.sort((a, b) {
          final categoryComparison = a.category.id.compareTo(b.category.id);
          return _sortAscending ? categoryComparison : -categoryComparison;
        });
        break;
    }
    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    _applyFilters();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadCategorySummaries();
  }

  void _showSortDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('sort_by') ?? 'Сортировать по',
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('amount', localizations.translate('amount') ?? 'Сумма', Icons.attach_money),
            _buildSortOption('trips', localizations.translate('trips_count') ?? 'Количество поездок', Icons.trip_origin),
            _buildSortOption('category', localizations.translate('category') ?? 'Категория', Icons.category),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText(
              localizations.translate('cancel') ?? 'Отмена',
              type: ResponsiveTextType.labelLarge,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String sortKey, String label, IconData icon) {
    final isSelected = _sortBy == sortKey;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppConstants.primaryColor : AppConstants.textColor),
      title: ResponsiveText(
        label,
        type: ResponsiveTextType.bodyLarge,
        color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      trailing: isSelected
          ? Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        color: AppConstants.primaryColor,
      )
          : null,
      onTap: () {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
            _sortAscending = false;
          }
        });
        _sortSummaries();
        Navigator.pop(context);
      },
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

  void _showCategoryDetails(CategoryExpenseSummary summary) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(summary.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(summary.category.icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(summary.category, localizations),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor,
                          ),
                        ),
                        Text(
                          _getCategoryDescription(summary.category, localizations),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstants.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Статистика
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCategoryColor(summary.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      localizations.translate('total_amount') ?? 'Общая сумма',
                      summary.formattedAmount,
                      _getCategoryColor(summary.category),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      localizations.translate('expense_count') ?? 'Количество расходов',
                      '${summary.expenseCount}',
                      AppConstants.textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      localizations.translate('trips_with_category') ?? 'Поездок с категорией',
                      summary.tripCountDescription,
                      AppConstants.textColor,
                    ),
                    if (summary.tripCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildStatRow(
                        localizations.translate('avg_per_trip') ?? 'Среднее за поездку',
                        '${summary.currencySymbol} ${(summary.totalAmount / summary.tripCount).toStringAsFixed(0)}',
                        AppConstants.textColor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Дополнительная информация
              Text(
                localizations.translate('category_info') ?? 'Информация о категории',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getCategoryDescription(summary.category, localizations),
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textColor.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textColor.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
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
          : Column(
        children: [
          _buildHeaderSection(localizations),
          const SizedBox(height: 16),
          _buildSearchAndFilters(localizations),
          const SizedBox(height: 16),
          Expanded(
            child: _categorySummaries.isEmpty
                ? _buildEmptyState(localizations)
                : _filteredSummaries.isEmpty
                ? _buildNoResultsState(localizations)
                : _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('expense_categories') ?? 'Категории расходов',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('categories_summary_desc') ?? 'Суммированные расходы по категориям со всех поездок',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          _buildPeriodSelector(localizations),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations localizations) {
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildSearchAndFilters(AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
            ),
            decoration: InputDecoration(
              hintText: localizations.translate('search_categories') ?? 'Поиск категорий',
              hintStyle: TextStyle(
                color: AppConstants.textColor.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppConstants.textColor.withOpacity(0.7),
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppConstants.textColor.withOpacity(0.7),
                ),
                onPressed: _clearSearch,
              )
                  : null,
              filled: true,
              fillColor: AppConstants.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            Icons.sort,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: _showSortDialog,
          style: IconButton.styleFrom(
            backgroundColor: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 80,
            color: AppConstants.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          ResponsiveText(
            localizations.translate('no_expenses_yet') ?? 'Пока нет расходов',
            type: ResponsiveTextType.titleLarge,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('add_first_expense') ?? 'Добавьте первую поездку с расходами',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: AppConstants.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            localizations.translate('no_results') ?? 'Нет результатов',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('try_different_search') ?? 'Попробуйте другой поиск',
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return RefreshIndicator(
      onRefresh: _loadCategorySummaries,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredSummaries.length,
        itemBuilder: (context, index) => _buildCategoryItem(_filteredSummaries[index]),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryExpenseSummary summary) {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCategoryDetails(summary),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showCategoryDetails(summary);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getCategoryColor(summary.category).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Иконка категории
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getCategoryColor(summary.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    summary.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Детали категории
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryName(summary.category, localizations),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.tripCountDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Сумма и стрелка
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.formattedAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(summary.category),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppConstants.textColor.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}