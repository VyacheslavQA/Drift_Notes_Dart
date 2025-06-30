// Путь: lib/screens/budget/trip_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_trip_model.dart';
import '../../models/fishing_expense_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import 'add_fishing_trip_expenses_screen.dart';

/// Экран деталей поездки с расходами
class TripDetailsScreen extends StatefulWidget {
  /// Поездка для отображения
  final FishingTripModel trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();

  FishingTripModel? _currentTrip;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    setState(() => _isLoading = true);

    try {
      // Перезагружаем поездку с актуальными расходами
      final trip = await _expenseRepository.getTripById(widget.trip.id);

      if (mounted) {
        setState(() {
          _currentTrip = trip ?? widget.trip;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Ошибка загрузки деталей: $e');
      }
    }
  }

  Future<void> _deleteTrip() async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('delete_trip') ?? 'Удалить поездку',
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              localizations.translate('delete_trip_confirm') ??
                  'Вы уверены, что хотите удалить эту поездку?',
              type: ResponsiveTextType.bodyLarge,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              localizations.translate('delete_trip_warning') ??
                  'Это действие удалит поездку и все связанные расходы. Отменить будет невозможно.',
              type: ResponsiveTextType.bodyMedium,
              color: Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: ResponsiveText(
              localizations.translate('cancel') ?? 'Отмена',
              type: ResponsiveTextType.labelLarge,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: ResponsiveText(
              localizations.translate('delete') ?? 'Удалить',
              type: ResponsiveTextType.labelLarge,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);

      try {
        await _expenseRepository.deleteTrip(widget.trip.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('trip_deleted') ?? 'Поездка удалена'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          _showErrorSnackBar('${localizations.translate('delete_error') ?? 'Ошибка удаления'}: $e');
        }
      }
    }
  }

  Future<void> _editExpense(FishingExpenseModel expense) async {
    // Теперь редактируем всю поездку, передавая конкретный расход для фокуса
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          tripToEdit: _currentTrip,
          focusCategory: expense.category,
        ),
      ),
    );

    if (result == true) {
      _loadTripDetails();
    }
  }

  Future<void> _deleteExpense(FishingExpenseModel expense) async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: ResponsiveText(
          localizations.translate('delete_expense') ?? 'Удалить расход',
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              localizations.translate('delete_expense_confirm') ??
                  'Вы уверены, что хотите удалить этот расход?',
              type: ResponsiveTextType.bodyLarge,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              localizations.translate('delete_expense_warning') ??
                  'Расход будет удален из поездки.',
              type: ResponsiveTextType.bodyMedium,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: ResponsiveText(
              localizations.translate('cancel') ?? 'Отмена',
              type: ResponsiveTextType.labelLarge,
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: ResponsiveText(
              localizations.translate('delete') ?? 'Удалить',
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
        // Удаляем расход из текущей поездки
        final updatedExpenses = _currentTrip!.expenses
            .where((e) => e.id != expense.id)
            .toList();

        final updatedTrip = _currentTrip!.withExpenses(updatedExpenses);

        // Обновляем поездку в репозитории
        await _expenseRepository.updateTrip(updatedTrip);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('expense_deleted') ?? 'Расход удален'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTripDetails();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('${localizations.translate('delete_error') ?? 'Ошибка удаления'}: $e');
        }
      }
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
                if (expense.notes != null && expense.notes!.isNotEmpty)
                  _buildDetailRow(Icons.notes, localizations.translate('notes') ?? 'Заметки', expense.notes!),
                _buildDetailRow(Icons.access_time, localizations.translate('created') ?? 'Создано',
                    _formatDateTime(expense.createdAt, localizations)),
                if (expense.createdAt != expense.updatedAt)
                  _buildDetailRow(Icons.update, localizations.translate('updated') ?? 'Обновлено',
                      _formatDateTime(expense.updatedAt, localizations)),

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
                        label: Text(localizations.translate('edit') ?? 'Изменить'),
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
                        label: Text(localizations.translate('delete') ?? 'Удалить'),
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final trip = _currentTrip!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: ResponsiveText(
          localizations.translate('trip_details') ?? 'Детали поездки',
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
          if (!_isDeleting)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppConstants.textColor,
                size: ResponsiveUtils.getIconSize(context),
              ),
              color: AppConstants.cardColor,
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteTrip();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        localizations.translate('delete_trip') ?? 'Удалить поездку',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
        type: ResponsiveContainerType.page,
        useSafeArea: true,
        addHorizontalPadding: true,
        addVerticalPadding: true,
        child: RefreshIndicator(
          onRefresh: _loadTripDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTripHeader(trip, localizations),
                const SizedBox(height: 24),
                _buildTripSummary(trip, localizations),
                const SizedBox(height: 24),
                _buildExpensesList(trip, localizations),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripHeader(FishingTripModel trip, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.directions_boat, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.displayTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(trip.date, localizations),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('total_amount') ?? 'Общая сумма',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${trip.currencySymbol} ${trip.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    localizations.translate('expenses_count') ?? 'Расходов',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${trip.expenses?.length ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary(FishingTripModel trip, AppLocalizations localizations) {
    final expenses = trip.expenses ?? [];
    if (expenses.isEmpty) return const SizedBox.shrink();

    // Группируем расходы по категориям
    final categoryTotals = <FishingExpenseCategory, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

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
            localizations.translate('expenses_by_category') ?? 'Расходы по категориям',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          ...categoryTotals.entries.map((entry) =>
              _buildCategorySummaryItem(entry.key, entry.value, localizations)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySummaryItem(FishingExpenseCategory category, double amount, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: ResponsiveText(
              _getCategoryName(category, localizations),
              type: ResponsiveTextType.bodyMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          ResponsiveText(
            '${_currentTrip!.currencySymbol} ${amount.toStringAsFixed(0)}',
            type: ResponsiveTextType.bodyLarge,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(category),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(FishingTripModel trip, AppLocalizations localizations) {
    final expenses = trip.expenses ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                localizations.translate('all_expenses') ?? 'Все расходы',
                type: ResponsiveTextType.titleMedium,
                fontWeight: FontWeight.w600,
              ),
              if (expenses.isNotEmpty)
                ResponsiveText(
                  '${expenses.length}',
                  type: ResponsiveTextType.titleMedium,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (expenses.isEmpty)
            _buildEmptyExpensesList(localizations)
          else
            ...expenses.map((expense) => _buildExpenseItem(expense, localizations)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyExpensesList(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 60,
              color: AppConstants.textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            ResponsiveText(
              localizations.translate('no_expenses_in_trip') ?? 'Нет расходов в поездке',
              type: ResponsiveTextType.bodyLarge,
              color: AppConstants.textColor.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(FishingExpenseModel expense, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showExpenseDetails(expense);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getCategoryColor(expense.category).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Иконка категории
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense.category).withOpacity(0.2),
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

              // Детали расхода
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.shortDescription,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCategoryName(expense.category, localizations),
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
                    expense.formattedAmount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(expense.category),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
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

  String _formatDate(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localizations.translate('today') ?? 'Сегодня';
    } else if (dateOnly == yesterday) {
      return localizations.translate('yesterday') ?? 'Вчера';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime, AppLocalizations localizations) {
    return '${_formatDate(dateTime, localizations)} ${localizations.translate('at') ?? 'в'} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}