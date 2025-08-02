// Путь: lib/screens/budget/expense_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../repositories/budget_notes_repository.dart'; // ИСПРАВЛЕНО: Используем новый репозиторий
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';



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
  final BudgetNotesRepository _expenseRepository = BudgetNotesRepository(); // ИСПРАВЛЕНО: Используем репозиторий

  Map<FishingExpenseCategory, CategoryExpenseSummary> _categorySummaries = {};
  List<CategoryExpenseSummary> _filteredSummaries = [];
  String _selectedPeriod = 'all'; // month, year, all, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategorySummaries();
  }

  // ИСПРАВЛЕНО: Загрузка сводок через новый репозиторий
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

      // ИСПРАВЛЕНО: Используем метод репозитория
      final summaries = await _expenseRepository.getCategorySummaries(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _categorySummaries = summaries;
          _filteredSummaries = summaries.values.toList();
          _isLoading = false;
        });

        // Вызываем callback для обновления родительского экрана
        widget.onExpenseUpdated?.call();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки сводок категорий: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        final localizations = AppLocalizations.of(context);
        _showErrorSnackBar('${localizations.translate('data_loading_error') ?? 'Ошибка загрузки данных'}: $e');
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
      _loadCategorySummaries();
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
              _loadCategorySummaries();
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
              _loadCategorySummaries();
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

  String _getTripCountDescription(int tripCount, AppLocalizations localizations) {
    if (tripCount == 1) {
      return localizations.translate('from_one_trip') ?? 'из 1 поездки';
    } else if (tripCount >= 2 && tripCount <= 4) {
      return localizations.translate('from_few_trips')?.replaceFirst('%count%', tripCount.toString()) ?? 'из $tripCount поездок';
    } else {
      return localizations.translate('from_many_trips')?.replaceFirst('%count%', tripCount.toString()) ?? 'из $tripCount поездок';
    }
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
                      _getTripCountDescription(summary.tripCount, localizations),
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

              // Период
              _buildStatRow(
                localizations.translate('period') ?? 'Период',
                _getDateRangeDescription(),
                AppConstants.textColor,
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
          _buildDateFilter(localizations),
          const SizedBox(height: 16),
          Expanded(
            child: _categorySummaries.isEmpty
                ? _buildEmptyState(localizations)
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
          Text(
            localizations.translate('expense_categories') ?? 'Категории расходов',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('categories_summary_desc') ?? 'Суммированные расходы по категориям со всех поездок',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
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
                      _getTripCountDescription(summary.tripCount, localizations),
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

// ИСПРАВЛЕНО: Убрали дублирующий класс CategoryExpenseSummary
// Теперь используется класс из репозитория