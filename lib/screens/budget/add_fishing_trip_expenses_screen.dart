// Путь: lib/screens/budget/add_fishing_trip_expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../models/fishing_trip_model.dart';
import '../../services/firebase/firebase_service.dart'; // ИЗМЕНЕНО: Убран FishingExpenseRepository
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';

/// Экран добавления всех расходов на рыбалку за одну поездку
class AddExpenseScreen extends StatefulWidget {
  /// Поездка для редактирования (если редактируем существующую)
  final FishingTripModel? tripToEdit;

  /// Категория для фокуса при редактировании отдельного расхода
  final FishingExpenseCategory? focusCategory;

  const AddExpenseScreen({
    super.key,
    this.tripToEdit,
    this.focusCategory,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService(); // ИЗМЕНЕНО: Используем FirebaseService
  final SubscriptionService _subscriptionService = SubscriptionService();

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

    // Если редактируем поездку, загружаем ее данные
    if (widget.tripToEdit != null) {
      _loadTripForEditing(widget.tripToEdit!);
    } else {
      // Автоматически раскрываем первую категорию или категорию фокуса
      final categoryToExpand = widget.focusCategory ??
          (FishingExpenseCategory.allCategories.isNotEmpty
              ? FishingExpenseCategory.allCategories.first
              : null);

      if (categoryToExpand != null) {
        _expandedCategories[categoryToExpand] = true;
      }
    }
  }

  void _loadTripForEditing(FishingTripModel trip) {
    setState(() {
      _selectedDate = trip.date;
      _selectedCurrency = trip.currency;
      _locationController.text = trip.locationName ?? '';
      _tripNotesController.text = trip.notes ?? '';

      // Загружаем данные расходов по категориям
      for (final expense in trip.expenses) {
        _categoryAmounts[expense.category] = expense.amount;
        _categoryDescriptions[expense.category] = expense.description;
        _categoryNotes[expense.category] = expense.notes ?? '';
        _expandedCategories[expense.category] = true;
      }

      // Если указана категория фокуса, раскрываем ее
      if (widget.focusCategory != null) {
        _expandedCategories[widget.focusCategory!] = true;
      }

      _updateTotalAmount();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tripNotesController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getCurrencies(AppLocalizations localizations) {
    return [
      {'code': 'KZT', 'symbol': '₸', 'name': localizations.translate('currency_kzt') ?? 'Тенге'},
      {'code': 'USD', 'symbol': '\$', 'name': localizations.translate('currency_usd') ?? 'Доллар США'},
      {'code': 'EUR', 'symbol': '€', 'name': localizations.translate('currency_eur') ?? 'Евро'},
      {'code': 'RUB', 'symbol': '₽', 'name': localizations.translate('currency_rub') ?? 'Рубль'},
    ];
  }

  void _toggleCategory(FishingExpenseCategory category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
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

  String _getCategoryDescriptionHint(FishingExpenseCategory category, AppLocalizations localizations) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return localizations.translate('category_tackle_hint') ?? 'Например: Спиннинг, катушка';
      case FishingExpenseCategory.bait:
        return localizations.translate('category_bait_hint') ?? 'Например: Черви, прикормка';
      case FishingExpenseCategory.transport:
        return localizations.translate('category_transport_hint') ?? 'Например: Бензин, такси';
      case FishingExpenseCategory.accommodation:
        return localizations.translate('category_accommodation_hint') ?? 'Например: Отель, база отдыха';
      case FishingExpenseCategory.food:
        return localizations.translate('category_food_hint') ?? 'Например: Обед, напитки';
      case FishingExpenseCategory.license:
        return localizations.translate('category_license_hint') ?? 'Например: Путевка, лицензия';
    }
  }

  String _getCategoryNotesHint(FishingExpenseCategory category, AppLocalizations localizations) {
    switch (category) {
      case FishingExpenseCategory.tackle:
        return localizations.translate('category_tackle_notes_hint') ?? 'Дополнительные заметки о снастях';
      case FishingExpenseCategory.bait:
        return localizations.translate('category_bait_notes_hint') ?? 'Дополнительные заметки о наживке';
      case FishingExpenseCategory.transport:
        return localizations.translate('category_transport_notes_hint') ?? 'Дополнительные заметки о транспорте';
      case FishingExpenseCategory.accommodation:
        return localizations.translate('category_accommodation_notes_hint') ?? 'Дополнительные заметки о проживании';
      case FishingExpenseCategory.food:
        return localizations.translate('category_food_notes_hint') ?? 'Дополнительные заметки о питании';
      case FishingExpenseCategory.license:
        return localizations.translate('category_license_notes_hint') ?? 'Дополнительные заметки о лицензиях';
    }
  }

  Future<void> _selectDate() async {
    final localizations = AppLocalizations.of(context);
    final isRussian = localizations.languageCode == 'ru';

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030), // Разрешаем выбирать будущие даты до 2030 года
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
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localizations.translate('today') ?? 'Сегодня';
    } else if (dateOnly == yesterday) {
      return localizations.translate('yesterday') ?? 'Вчера';
    } else if (dateOnly == tomorrow) {
      return localizations.translate('tomorrow') ?? 'Завтра';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  // ИЗМЕНЕНО: Полностью переписан метод сохранения под новую структуру Firebase
  Future<void> _saveFishingTripExpenses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final localizations = AppLocalizations.of(context);
    final userId = _firebaseService.currentUserId;

    if (userId == null) {
      _showErrorSnackBar(localizations.translate('error_user_not_authorized') ?? 'Пользователь не авторизован');
      return;
    }

    // Проверяем, что хотя бы один расход указан
    final hasExpenses = _categoryAmounts.values.any((amount) => amount > 0);

    if (!hasExpenses) {
      _showErrorSnackBar(localizations.translate('error_no_expenses') ?? 'Добавьте хотя бы один расход');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.tripToEdit != null) {
        // Редактируем существующую поездку
        await _updateExistingTrip();
      } else {
        // Создаем новую поездку
        await _createNewTrip();
      }

      if (mounted) {
        final expenseCount = _categoryAmounts.values.where((amount) => amount > 0).length;
        final symbol = _currencySymbols[_selectedCurrency] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.tripToEdit != null
                    ? '${localizations.translate('trip_updated') ?? 'Поездка обновлена'} $expenseCount ${localizations.translate('expenses_count') ?? 'расходов'}. ${localizations.translate('total_amount') ?? 'Общая сумма'}: $symbol ${_totalAmount.toStringAsFixed(2)}'
                    : '${localizations.translate('fishing_trip_expenses_saved') ?? 'Расходы сохранены'} $expenseCount ${localizations.translate('expenses_count') ?? 'расходов'}. ${localizations.translate('total_amount') ?? 'Общая сумма'}: $symbol ${_totalAmount.toStringAsFixed(2)}'
            ),
            backgroundColor: AppConstants.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${localizations.translate('error_saving') ?? 'Ошибка сохранения'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ИЗМЕНЕНО: Новый метод создания поездки через Firebase subcollections
  Future<void> _createNewTrip() async {
    final localizations = AppLocalizations.of(context);

    try {
      // Создаем данные поездки
      final tripData = {
        'userId': _firebaseService.currentUserId,
        'date': _selectedDate,
        'locationName': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'notes': _tripNotesController.text.trim().isEmpty ? null : _tripNotesController.text.trim(),
        'currency': _selectedCurrency,
      };

      // Создаем поездку
      final tripRef = await _firebaseService.addFishingTrip(tripData);
      final tripId = tripRef.id;

      // Создаем список расходов для добавления
      final expensesToAdd = <Map<String, dynamic>>[];

      for (final category in FishingExpenseCategory.allCategories) {
        final amount = _categoryAmounts[category] ?? 0.0;
        if (amount > 0) {
          final description = _categoryDescriptions[category]?.trim() ?? '';
          final expenseNotes = _categoryNotes[category]?.trim() ?? '';

          final expenseData = {
            'userId': _firebaseService.currentUserId,
            'tripId': tripId,
            'amount': amount,
            'description': description.isNotEmpty ? description : (localizations.translate('expenses_default') ?? 'Расходы'),
            'category': category.id,
            'date': _selectedDate,
            'currency': _selectedCurrency,
            'notes': expenseNotes.isEmpty ? null : expenseNotes,
            'locationName': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          };

          expensesToAdd.add(expenseData);
        }
      }

      // Добавляем все расходы к поездке
      for (final expenseData in expensesToAdd) {
        await _firebaseService.addFishingExpense(tripId, expenseData);
      }

      // Увеличиваем счетчик использования после успешного создания
      try {
        await _subscriptionService.incrementUsage(ContentType.expenses);
        debugPrint('✅ Счетчик расходов/поездок увеличен');
      } catch (e) {
        debugPrint('❌ Ошибка увеличения счетчика расходов/поездок: $e');
      }

    } catch (e) {
      debugPrint('Ошибка создания поездки: $e');
      rethrow;
    }
  }

  // ИЗМЕНЕНО: Новый метод обновления поездки через Firebase subcollections
  Future<void> _updateExistingTrip() async {
    final localizations = AppLocalizations.of(context);
    final existingTrip = widget.tripToEdit!;

    try {
      // Обновляем данные поездки
      final tripData = {
        'date': _selectedDate,
        'locationName': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'notes': _tripNotesController.text.trim().isEmpty ? null : _tripNotesController.text.trim(),
        'currency': _selectedCurrency,
      };

      await _firebaseService.updateFishingTrip(existingTrip.id, tripData);

      // Получаем текущие расходы поездки
      final currentExpensesSnapshot = await _firebaseService.getFishingTripExpenses(existingTrip.id);
      final currentExpenses = <String, Map<String, dynamic>>{};

      for (var doc in currentExpensesSnapshot.docs) {
        final expenseData = doc.data() as Map<String, dynamic>;
        final category = expenseData['category'] as String;
        currentExpenses[category] = {
          'id': doc.id,
          ...expenseData,
        };
      }

      // Обновляем/добавляем/удаляем расходы по категориям
      for (final category in FishingExpenseCategory.allCategories) {
        final amount = _categoryAmounts[category] ?? 0.0;
        final categoryId = category.id;

        if (amount > 0) {
          // Есть расход в этой категории
          final description = _categoryDescriptions[category]?.trim() ?? '';
          final expenseNotes = _categoryNotes[category]?.trim() ?? '';

          final expenseData = {
            'userId': _firebaseService.currentUserId,
            'tripId': existingTrip.id,
            'amount': amount,
            'description': description.isNotEmpty ? description : (localizations.translate('expenses_default') ?? 'Расходы'),
            'category': categoryId,
            'date': _selectedDate,
            'currency': _selectedCurrency,
            'notes': expenseNotes.isEmpty ? null : expenseNotes,
            'locationName': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          };

          if (currentExpenses.containsKey(categoryId)) {
            // Обновляем существующий расход
            final existingExpenseId = currentExpenses[categoryId]!['id'];
            await _firebaseService.updateFishingExpense(existingTrip.id, existingExpenseId, expenseData);
          } else {
            // Добавляем новый расход
            await _firebaseService.addFishingExpense(existingTrip.id, expenseData);
          }
        } else {
          // Нет расхода в этой категории
          if (currentExpenses.containsKey(categoryId)) {
            // Удаляем существующий расход
            final existingExpenseId = currentExpenses[categoryId]!['id'];
            await _firebaseService.deleteFishingExpense(existingTrip.id, existingExpenseId);
          }
        }
      }

    } catch (e) {
      debugPrint('Ошибка обновления поездки: $e');
      rethrow;
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
        title: Text(
          widget.tripToEdit != null
              ? (localizations.translate('edit_expenses') ?? 'Редактировать расходы')
              : (localizations.translate('add_expenses') ?? 'Добавить расходы'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
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
                // Добавляем отступ снизу с учетом системной навигации
                SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
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
            localizations.translate('fishing_trip_info') ?? 'Информация о поездке',
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
          localizations.translate('date') ?? 'Дата',
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
          localizations.translate('currency') ?? 'Валюта',
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
          localizations.translate('fishing_location') ?? 'Место рыбалки',
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
            hintText: localizations.translate('fishing_location_hint') ?? 'Например: Озеро Балхаш',
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
          localizations.translate('trip_notes') ?? 'Заметки о поездке',
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
            hintText: localizations.translate('trip_notes_hint') ?? 'Дополнительные заметки о поездке',
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
          localizations.translate('expenses_by_category') ?? 'Расходы по категориям',
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
                              : localizations.translate('not_specified') ?? 'Не указано',
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
              hintText: _getCategoryDescriptionHint(category, localizations),
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
              hintText: _getCategoryNotesHint(category, localizations),
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
              localizations.translate('total_fishing_trip_expenses') ?? 'Общая сумма расходов',
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
          localizations.translate('save_fishing_trip_expenses') ?? 'Сохранить расходы',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}