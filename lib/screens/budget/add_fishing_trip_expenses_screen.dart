// Путь: lib/screens/budget/add_fishing_trip_expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../services/firebase/firebase_service.dart';

/// Экран добавления всех расходов на рыбалку за одну поездку
class AddExpenseScreen extends StatefulWidget {
  final FishingExpenseModel? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();
  final FirebaseService _firebaseService = FirebaseService();

  // Общая информация о рыбалке
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'KZT';
  final _locationController = TextEditingController();
  final _tripNotesController = TextEditingController();

  // Расходы по категориям
  final Map<FishingExpenseCategory, double> _categoryAmounts = {};
  final Map<FishingExpenseCategory, String> _categoryDescriptions = {};
  final Map<FishingExpenseCategory, String> _categoryNotes = {};
  final Map<FishingExpenseCategory, bool> _expandedCategories = {};

  bool _isLoading = false;
  double _totalAmount = 0.0;

  // Список поддерживаемых валют
  final Map<String, String> _currencySymbols = {
    'KZT': '₸',
    'USD': '\$',
    'EUR': '€',
    'RUB': '₽',
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Инициализируем данные для всех категорий
    for (final category in FishingExpenseCategory.allCategories) {
      _categoryAmounts[category] = 0.0;
      _categoryDescriptions[category] = '';
      _categoryNotes[category] = '';
      _expandedCategories[category] = false;
    }
    // Автоматически раскрываем первую категорию
    _expandedCategories[FishingExpenseCategory.tackle] = true;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tripNotesController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getCurrencies(AppLocalizations localizations) {
    return [
      {'code': 'KZT', 'symbol': '₸', 'name': localizations.translate('currency_kzt')},
      {'code': 'USD', 'symbol': '\$', 'name': localizations.translate('currency_usd')},
      {'code': 'EUR', 'symbol': '€', 'name': localizations.translate('currency_eur')},
      {'code': 'RUB', 'symbol': '₽', 'name': localizations.translate('currency_rub')},
    ];
  }

  void _toggleCategory(FishingExpenseCategory category) {
    setState(() {
      _expandedCategories[category] = !_expandedCategories[category]!;
    });
  }

  void _updateCategoryAmount(FishingExpenseCategory category, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _categoryAmounts[category] = amount;
      _updateTotalAmount();
    });
  }

  void _updateTotalAmount() {
    _totalAmount = _categoryAmounts.values.fold(0.0, (sum, amount) => sum + amount);
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

  Future<void> _selectDate() async {
    final localizations = AppLocalizations.of(context);
    final isRussian = localizations.languageCode == 'ru';

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: isRussian ? const Locale('ru', 'RU') : const Locale('en', 'US'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
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

  Future<void> _saveFishingTripExpenses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final localizations = AppLocalizations.of(context);
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      _showErrorSnackBar(localizations.translate('error_user_not_authorized'));
      return;
    }

    // Проверяем, что хотя бы один расход указан
    final hasExpenses = _categoryAmounts.values.any((amount) => amount > 0);
    if (!hasExpenses) {
      _showErrorSnackBar(localizations.translate('error_no_expenses'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<FishingExpenseModel> expenses = [];

      // Создаем расходы только для категорий с указанной суммой
      for (final category in FishingExpenseCategory.allCategories) {
        final amount = _categoryAmounts[category] ?? 0.0;
        if (amount > 0) {
          final description = _categoryDescriptions[category]?.trim() ?? '';
          final notes = _categoryNotes[category]?.trim() ?? '';

          // Если описание пустое, используем название категории
          final finalDescription = description.isNotEmpty
              ? description
              : _getCategoryName(category, localizations);

          final expense = FishingExpenseModel.create(
            userId: userId,
            amount: amount,
            description: finalDescription,
            category: category,
            date: _selectedDate,
            currency: _selectedCurrency,
            notes: notes.isEmpty ? null : notes,
            locationName: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );

          expenses.add(expense);
        }
      }

      // Сохраняем все расходы
      for (final expense in expenses) {
        await _expenseRepository.addExpense(expense);
      }

      if (mounted) {
        final symbol = _currencySymbols[_selectedCurrency] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${localizations.translate('fishing_trip_expenses_saved')} ${expenses.length} ${localizations.translate('expenses_count')}. ${localizations.translate('total_amount')}: $symbol ${_totalAmount.toStringAsFixed(2)}'
            ),
            backgroundColor: AppConstants.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${localizations.translate('error_saving')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: ResponsiveText(
          localizations.translate('add_fishing_trip_expenses'),
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildTripInfoSection(),
                const SizedBox(height: 24),
                _buildExpensesSection(),
                const SizedBox(height: 24),
                _buildTotalSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfoSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('fishing_trip_info'),
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),

          // Дата и валюта
          Row(
            children: [
              Expanded(child: _buildDateField()),
              const SizedBox(width: 16),
              Expanded(child: _buildCurrencyField()),
            ],
          ),
          const SizedBox(height: 16),

          // Место рыбалки
          _buildLocationField(),
          const SizedBox(height: 16),

          // Общие заметки
          _buildTripNotesField(),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          localizations.translate('date'),
          type: ResponsiveTextType.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Text(
              _formatDate(_selectedDate, localizations),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyField() {
    final localizations = AppLocalizations.of(context);
    final currencies = _getCurrencies(localizations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          localizations.translate('currency'),
          type: ResponsiveTextType.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppConstants.textColor.withOpacity(0.7),
              ),
              dropdownColor: AppConstants.cardColor,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
              ),
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(
                        currency['symbol']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(currency['name']!)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          localizations.translate('fishing_location'),
          type: ResponsiveTextType.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: localizations.translate('fishing_location_hint'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppConstants.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTripNotesField() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          localizations.translate('trip_notes'),
          type: ResponsiveTextType.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tripNotesController,
          maxLines: 3,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: localizations.translate('trip_notes_hint'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppConstants.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesSection() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          localizations.translate('expenses_by_category'),
          type: ResponsiveTextType.titleMedium,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 16),

        ...FishingExpenseCategory.allCategories.map((category) =>
            _buildCategoryExpenseCard(category)
        ),
      ],
    );
  }

  Widget _buildCategoryExpenseCard(FishingExpenseCategory category) {
    final localizations = AppLocalizations.of(context);
    final isExpanded = _expandedCategories[category] ?? false;
    final amount = _categoryAmounts[category] ?? 0.0;
    final hasAmount = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasAmount
            ? AppConstants.primaryColor.withOpacity(0.15)
            : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: hasAmount
            ? Border.all(color: AppConstants.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          // Заголовок категории
          InkWell(
            onTap: () => _toggleCategory(category),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          _getCategoryName(category, localizations),
                          type: ResponsiveTextType.bodyLarge,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasAmount
                              ? '${_currencySymbols[_selectedCurrency]} ${amount.toStringAsFixed(2)}'
                              : localizations.translate('not_specified'),
                          style: TextStyle(
                            color: hasAmount
                                ? AppConstants.primaryColor
                                : AppConstants.secondaryTextColor,
                            fontSize: 14,
                            fontWeight: hasAmount ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppConstants.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),

          // Детали категории
          if (isExpanded) _buildCategoryDetails(category),
        ],
      ),
    );
  }

  Widget _buildCategoryDetails(FishingExpenseCategory category) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Поле суммы
          Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadiusMedium),
                      bottomLeft: Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                  child: Text(
                    _currencySymbols[_selectedCurrency] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _categoryAmounts[category] == 0
                        ? ''
                        : _categoryAmounts[category]!.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) => _updateCategoryAmount(category, value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Поле описания
          TextFormField(
            initialValue: _categoryDescriptions[category],
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: localizations.translate('category_description_hint'),
              hintStyle: TextStyle(
                color: AppConstants.textColor.withOpacity(0.5),
              ),
              filled: true,
              fillColor: AppConstants.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              _categoryDescriptions[category] = value;
            },
          ),
          const SizedBox(height: 12),

          // Поле заметок
          TextFormField(
            initialValue: _categoryNotes[category],
            maxLines: 3,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: localizations.translate('category_notes_hint'),
              hintStyle: TextStyle(
                color: AppConstants.textColor.withOpacity(0.5),
              ),
              filled: true,
              fillColor: AppConstants.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              _categoryNotes[category] = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              localizations.translate('total_fishing_trip_expenses'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currencySymbols[_selectedCurrency]} ${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveFishingTripExpenses,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(
          localizations.translate('save_fishing_trip_expenses'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}