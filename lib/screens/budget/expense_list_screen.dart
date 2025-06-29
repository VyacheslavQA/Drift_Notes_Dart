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

/// Экран списка расходов на рыбалку
class ExpenseListScreen extends StatefulWidget {
  /// Список расходов для отображения
  final List<FishingExpenseModel> expenses;

  /// Callback при обновлении расходов
  final VoidCallback? onExpenseUpdated;

  const ExpenseListScreen({
    super.key,
    required this.expenses,
    this.onExpenseUpdated,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<FishingExpenseModel> _filteredExpenses = [];
  FishingExpenseCategory? _selectedCategoryFilter;
  String _sortBy = 'date'; // date, amount, category
  bool _sortAscending = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredExpenses = List.from(widget.expenses);
    _sortExpenses();
  }

  @override
  void didUpdateWidget(ExpenseListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _filteredExpenses = List.from(widget.expenses);
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _filteredExpenses = List.from(widget.expenses);

    // Поиск по тексту
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      _filteredExpenses = _filteredExpenses.where((expense) {
        return expense.description.toLowerCase().contains(searchQuery) ||
            expense.notes?.toLowerCase().contains(searchQuery) == true ||
            expense.locationName?.toLowerCase().contains(searchQuery) == true;
      }).toList();
    }

    // Фильтр по категории
    if (_selectedCategoryFilter != null) {
      _filteredExpenses = _filteredExpenses
          .where((expense) => expense.category == _selectedCategoryFilter)
          .toList();
    }

    _sortExpenses();
  }

  void _sortExpenses() {
    switch (_sortBy) {
      case 'date':
        _filteredExpenses.sort((a, b) =>
        _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
        break;
      case 'amount':
        _filteredExpenses.sort((a, b) =>
        _sortAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
        break;
      case 'category':
        _filteredExpenses.sort((a, b) {
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

  void _showSortDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('sort_by'),
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('date', localizations.translate('date'), Icons.calendar_today),
            _buildSortOption('amount', localizations.translate('amount'), Icons.attach_money),
            _buildSortOption('category', localizations.translate('category'), Icons.category),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText(
              localizations.translate('cancel'),
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
        _sortExpenses();
        Navigator.pop(context);
      },
    );
  }

  void _showCategoryFilter() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('filter_by_category'),
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryFilterOption(null, localizations.translate('all_categories')),
              ...FishingExpenseCategory.allCategories.map(
                    (category) => _buildCategoryFilterOption(category, _getCategoryName(category, localizations)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText(
              localizations.translate('cancel'),
              type: ResponsiveTextType.labelLarge,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterOption(FishingExpenseCategory? category, String label) {
    final isSelected = _selectedCategoryFilter == category;

    return ListTile(
      leading: category != null
          ? Text(category.icon, style: const TextStyle(fontSize: 20))
          : Icon(Icons.all_inclusive, color: AppConstants.textColor),
      title: ResponsiveText(
        label,
        type: ResponsiveTextType.bodyLarge,
        color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppConstants.primaryColor)
          : null,
      onTap: () {
        setState(() {
          _selectedCategoryFilter = category;
        });
        _applyFilters();
        Navigator.pop(context);
      },
    );
  }

  String _getCategoryName(FishingExpenseCategory category, AppLocalizations localizations) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return localizations.translate('category_tackle');
      case FishingExpenseCategory.bait:
        return localizations.translate('category_bait');
      case FishingExpenseCategory.transport:
        return localizations.translate('category_transport');
      case FishingExpenseCategory.accommodation:
        return localizations.translate('category_accommodation');
      case FishingExpenseCategory.food:
        return localizations.translate('category_food');
      case FishingExpenseCategory.license:
        return localizations.translate('category_license');
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

  Future<void> _deleteExpense(FishingExpenseModel expense) async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('delete_expense'),
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: ResponsiveText(
          localizations.translate('delete_expense_confirm'),
          type: ResponsiveTextType.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: ResponsiveText(
              localizations.translate('cancel'),
              type: ResponsiveTextType.labelLarge,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: ResponsiveText(
              localizations.translate('delete'),
              type: ResponsiveTextType.labelLarge,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _expenseRepository.deleteExpense(expense.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('expense_deleted')),
              backgroundColor: Colors.green,
            ),
          );
          widget.onExpenseUpdated?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('delete_error')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editExpense(FishingExpenseModel expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expenseToEdit: expense),
      ),
    );

    if (result == true) {
      widget.onExpenseUpdated?.call();
    }
  }

  void _showExpenseDetails(FishingExpenseModel expense) {
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
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
                        color: _getCategoryColor(expense.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(expense.category.icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textColor,
                            ),
                            maxLines: 2,
                          ),
                          Text(
                            _getCategoryName(expense.category, localizations),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppConstants.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      expense.formattedAmount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(expense.category),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Детали
                _buildDetailRow(Icons.calendar_today, localizations.translate('date'), _formatDate(expense.date, localizations)),
                if (expense.locationName != null)
                  _buildDetailRow(Icons.location_on, localizations.translate('location'), expense.locationName!),
                if (expense.notes != null && expense.notes!.isNotEmpty)
                  _buildDetailRow(Icons.notes, localizations.translate('notes'), expense.notes!),
                _buildDetailRow(Icons.access_time, localizations.translate('created'), _formatDateTime(expense.createdAt, localizations)),
                if (expense.createdAt != expense.updatedAt)
                  _buildDetailRow(Icons.update, localizations.translate('updated'), _formatDateTime(expense.updatedAt, localizations)),

                const SizedBox(height: 24),

                // Действия
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editExpense(expense);
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(localizations.translate('edit')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteExpense(expense);
                        },
                        icon: const Icon(Icons.delete),
                        label: Text(localizations.translate('delete')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localizations.translate('today');
    } else if (dateOnly == yesterday) {
      return localizations.translate('yesterday');
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime, AppLocalizations localizations) {
    return '${_formatDate(dateTime, localizations)} ${localizations.translate('at')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
          _buildSearchAndFilters(localizations),
          const SizedBox(height: 16),
          _buildFilterChips(localizations),
          Expanded(
            child: _filteredExpenses.isEmpty
                ? _buildNoResultsState(localizations)
                : _buildExpensesList(),
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
            Icons.receipt_long,
            size: 80,
            color: AppConstants.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          ResponsiveText(
            localizations.translate('no_expenses_yet'),
            type: ResponsiveTextType.titleLarge,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('add_first_expense'),
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
            localizations.translate('no_results'),
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            localizations.translate('try_different_search'),
            type: ResponsiveTextType.bodyMedium,
            color: AppConstants.textColor.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
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
              hintText: localizations.translate('search_expenses'),
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
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: _selectedCategoryFilter != null ? AppConstants.primaryColor : AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: _showCategoryFilter,
          style: IconButton.styleFrom(
            backgroundColor: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AppLocalizations localizations) {
    final chips = <Widget>[];

    if (_selectedCategoryFilter != null) {
      chips.add(
        Chip(
          label: ResponsiveText(
            _getCategoryName(_selectedCategoryFilter!, localizations),
            type: ResponsiveTextType.labelMedium,
            color: AppConstants.textColor,
          ),
          avatar: Text(_selectedCategoryFilter!.icon),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedCategoryFilter = null;
            });
            _applyFilters();
          },
          backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => chips[index],
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) => _buildExpenseItem(_filteredExpenses[index]),
    );
  }

  Widget _buildExpenseItem(FishingExpenseModel expense) {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showExpenseDetails(expense);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.textColor.withOpacity(0.1),
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
                  color: _getCategoryColor(expense.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    expense.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Детали расхода
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.shortDescription,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(expense.date, localizations),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textColor.withOpacity(0.7),
                          ),
                        ),
                        if (expense.locationName != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textColor.withOpacity(0.7),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              expense.locationName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textColor.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Сумма и статус синхронизации
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.formattedAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(expense.category),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!expense.isSynced)
                        const Icon(
                          Icons.sync_disabled,
                          size: 16,
                          color: Colors.orange,
                        ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppConstants.textColor.withOpacity(0.3),
                      ),
                    ],
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