// Путь: lib/screens/budget/add_fishing_trip_expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ✅ ДОБАВЛЕНО: Импорты для обновления SubscriptionProvider
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../models/fishing_trip_model.dart';
import '../../repositories/budget_notes_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../constants/subscription_constants.dart';
import '../../screens/subscription/paywall_screen.dart';

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
  final BudgetNotesRepository _expenseRepository = BudgetNotesRepository();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  // Общая информация о рыбалке
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'KZT';
  final _locationController = TextEditingController();
  final _tripNotesController = TextEditingController();

  // ИСПРАВЛЕНО: Добавили контроллеры для каждого поля ввода
  final Map<FishingExpenseCategory, TextEditingController> _amountControllers = {};
  final Map<FishingExpenseCategory, TextEditingController> _descriptionControllers = {};
  final Map<FishingExpenseCategory, TextEditingController> _notesControllers = {};

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
    // ИСПРАВЛЕНО: Инициализируем контроллеры для всех категорий
    for (final category in FishingExpenseCategory.allCategories) {
      _categoryAmounts[category] = 0.0;
      _categoryDescriptions[category] = '';
      _categoryNotes[category] = '';
      _expandedCategories[category] = false;

      // Создаем контроллеры для каждой категории
      _amountControllers[category] = TextEditingController();
      _descriptionControllers[category] = TextEditingController();
      _notesControllers[category] = TextEditingController();

      // Добавляем слушатели для автоматического обновления данных
      _amountControllers[category]!.addListener(() {
        final text = _amountControllers[category]!.text;
        final amount = double.tryParse(text) ?? 0.0;
        if (_categoryAmounts[category] != amount) {
          _categoryAmounts[category] = amount;
          _updateTotalAmount();
          debugPrint('Сумма для ${category.name} обновлена: $amount');
        }
      });

      _descriptionControllers[category]!.addListener(() {
        _categoryDescriptions[category] = _descriptionControllers[category]!.text;
      });

      _notesControllers[category]!.addListener(() {
        _categoryNotes[category] = _notesControllers[category]!.text;
      });
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

      // ОТЛАДКА: Выводим информацию о загружаемой поездке
      debugPrint('=== ЗАГРУЗКА ПОЕЗДКИ ДЛЯ РЕДАКТИРОВАНИЯ ===');
      debugPrint('ID поездки: ${trip.id}');
      debugPrint('Дата: ${trip.date}');
      debugPrint('Место: ${trip.locationName}');
      debugPrint('Заметки: ${trip.notes}');
      debugPrint('Валюта: ${trip.currency}');
      debugPrint('Количество расходов: ${trip.expenses.length}');

      // ИСПРАВЛЕНО: Загружаем данные расходов в контроллеры
      for (final expense in trip.expenses) {
        debugPrint('Загружаем расход: ${expense.category.name} - ${expense.amount}');
        debugPrint('  Описание: ${expense.description}');
        debugPrint('  Заметки: ${expense.notes}');

        _categoryAmounts[expense.category] = expense.amount;
        _categoryDescriptions[expense.category] = expense.description;
        _categoryNotes[expense.category] = expense.notes ?? '';
        _expandedCategories[expense.category] = true;

        // Устанавливаем значения в контроллеры
        _amountControllers[expense.category]!.text = expense.amount == 0
            ? ''
            : expense.amount.toStringAsFixed(2).replaceAll('.00', '');
        _descriptionControllers[expense.category]!.text = expense.description;
        _notesControllers[expense.category]!.text = expense.notes ?? '';
      }

      // Если указана категория фокуса, раскрываем ее
      if (widget.focusCategory != null) {
        _expandedCategories[widget.focusCategory!] = true;
        debugPrint('Фокус на категории: ${widget.focusCategory!.name}');
      }

      _updateTotalAmount();

      debugPrint('Общая сумма после загрузки: $_totalAmount');
      debugPrint('========================================');
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tripNotesController.dispose();

    // ИСПРАВЛЕНО: Освобождаем все контроллеры
    for (final category in FishingExpenseCategory.allCategories) {
      _amountControllers[category]?.dispose();
      _descriptionControllers[category]?.dispose();
      _notesControllers[category]?.dispose();
    }

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

  // ИСПРАВЛЕНО: Упрощенный метод обновления общей суммы
  void _updateTotalAmount() {
    setState(() {
      _totalAmount = _categoryAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    });
    debugPrint('Общая сумма обновлена: $_totalAmount');
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
      lastDate: DateTime(2030),
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

  /// ✅ ИСПРАВЛЕНО: Убрано предупреждающее окно - только проверка жесткого лимита
  Future<bool> _checkLimitsBeforeCreating() async {
    final localizations = AppLocalizations.of(context);

    try {
      debugPrint('🔍 Проверка лимитов для заметок бюджета...');

      // ✅ ИСПРАВЛЕНО: Используем новую систему через SubscriptionService
      final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.budgetNotes);

      debugPrint('✅ Результат проверки лимитов: canCreate=$canCreate');

      if (!canCreate) {
        debugPrint('❌ Превышен лимит создания заметок бюджета');

        // ✅ ИСПРАВЛЕНО: Показываем Paywall для правильного типа контента
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaywallScreen(
              contentType: 'budgetNotes',
              blockedFeature: localizations.translate('fishing_expenses') ?? 'Расходы на рыбалку',
            ),
          ),
        );

        return false;
      }

      // ✅ УБРАНО: Предупреждающее окно "Осталось X заметок из Y"
      // Теперь пользователь может создавать заметки без раздражающих предупреждений
      // Жесткий лимит все еще работает - при превышении покажется PaywallScreen

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка проверки лимитов: $e');

      // В случае ошибки разрешаем создание (fallback)
      return true;
    }
  }

  Future<void> _saveFishingTripExpenses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final localizations = AppLocalizations.of(context);

    // Проверяем, что хотя бы один расход указан
    final hasExpenses = _categoryAmounts.values.any((amount) => amount > 0);

    if (!hasExpenses) {
      _showErrorSnackBar(localizations.translate('error_no_expenses') ?? 'Добавьте хотя бы один расход');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.tripToEdit != null) {
        // Редактируем существующую поездку - проверка лимитов не нужна
        await _updateExistingTrip();
      } else {
        // ✅ ИСПРАВЛЕНО: Проверяем лимиты через правильную систему ПЕРЕД созданием новой поездки
        final canCreate = await _checkLimitsBeforeCreating();
        if (!canCreate) {
          return; // Пользователь отменил создание или превышен лимит
        }

        // Создаем новую поездку
        await _createNewTrip();

        // ✅ КРИТИЧЕСКИ ВАЖНО: Обновляем SubscriptionProvider после создания поездки
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после создания поездки с расходами');
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
        }
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
      debugPrint('❌ Ошибка сохранения поездки: $e');

      if (mounted) {
        // ✅ ИСПРАВЛЕНО: Улучшенная обработка ошибок лимитов
        if (e.toString().contains('subscription_limit_exceeded') ||
            e.toString().contains('Превышен лимит') ||
            e.toString().contains('limit_exceeded')) {
          debugPrint('🚫 Обнаружена ошибка превышения лимита');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaywallScreen(
                contentType: 'budgetNotes',
                blockedFeature: localizations.translate('fishing_expenses') ?? 'Расходы на рыбалку',
              ),
            ),
          );
        } else {
          _showErrorSnackBar('${localizations.translate('error_saving') ?? 'Ошибка сохранения'}: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNewTrip() async {
    try {
      debugPrint('=== СОЗДАНИЕ НОВОЙ ПОЕЗДКИ ===');
      debugPrint('Дата: $_selectedDate');
      debugPrint('Место: ${_locationController.text}');
      debugPrint('Заметки: ${_tripNotesController.text}');
      debugPrint('Валюта: $_selectedCurrency');
      debugPrint('Суммы по категориям:');
      _categoryAmounts.forEach((category, amount) {
        if (amount > 0) {
          debugPrint('  ${category.name}: $amount');
          debugPrint('    Описание: ${_categoryDescriptions[category]}');
          debugPrint('    Заметки: ${_categoryNotes[category]}');
        }
      });

      await _expenseRepository.createTripWithExpenses(
        date: _selectedDate,
        locationName: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        notes: _tripNotesController.text.trim().isEmpty ? null : _tripNotesController.text.trim(),
        currency: _selectedCurrency,
        categoryAmounts: _categoryAmounts,
        categoryDescriptions: _categoryDescriptions,
        categoryNotes: _categoryNotes,
      );

      debugPrint('✅ Поездка успешно создана');

    } catch (e) {
      debugPrint('❌ Ошибка создания поездки: $e');
      rethrow;
    }
  }

  Future<void> _updateExistingTrip() async {
    final localizations = AppLocalizations.of(context);
    final existingTrip = widget.tripToEdit!;

    try {
      debugPrint('=== ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕЙ ПОЕЗДКИ ===');
      debugPrint('ID поездки: ${existingTrip.id}');

      // Создаем обновленный список расходов
      final expenses = <FishingExpenseModel>[];

      for (final category in FishingExpenseCategory.allCategories) {
        final amount = _categoryAmounts[category] ?? 0.0;
        if (amount > 0) {
          final description = _categoryDescriptions[category]?.trim() ?? '';
          final expenseNotes = _categoryNotes[category]?.trim() ?? '';

          // Ищем существующий расход этой категории
          final existingExpense = existingTrip.expenses.where((e) => e.category == category).firstOrNull;

          final expense = FishingExpenseModel(
            id: existingExpense?.id ?? '',
            userId: existingTrip.userId,
            tripId: existingTrip.id,
            amount: amount,
            description: description.isNotEmpty ? description : (localizations.translate('expenses_default') ?? 'Расходы'),
            category: category,
            date: _selectedDate,
            currency: _selectedCurrency,
            notes: expenseNotes.isEmpty ? null : expenseNotes,
            locationName: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            createdAt: existingExpense?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: existingExpense?.isSynced ?? false,
          );

          expenses.add(expense);
        }
      }

      // Создаем обновленную поездку
      final updatedTrip = FishingTripModel(
        id: existingTrip.id,
        userId: existingTrip.userId,
        date: _selectedDate,
        locationName: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        notes: _tripNotesController.text.trim().isEmpty ? null : _tripNotesController.text.trim(),
        currency: _selectedCurrency,
        expenses: expenses,
        createdAt: existingTrip.createdAt,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _expenseRepository.updateTrip(updatedTrip);

      debugPrint('✅ Поездка успешно обновлена');

    } catch (e) {
      debugPrint('❌ Ошибка обновления поездки: $e');
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
          // ИСПРАВЛЕНО: Поле суммы с контроллером
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
                    controller: _amountControllers[category], // ИСПРАВЛЕНО: Используем контроллер
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
                    onChanged: (value) {
                      // Обновляем общую сумму при изменении
                      _updateTotalAmount();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ИСПРАВЛЕНО: Поле описания с контроллером
          TextFormField(
            controller: _descriptionControllers[category], // ИСПРАВЛЕНО: Используем контроллер
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
          ),
          const SizedBox(height: 12),

          // ИСПРАВЛЕНО: Поле заметок с контроллером
          TextFormField(
            controller: _notesControllers[category], // ИСПРАВЛЕНО: Используем контроллер
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