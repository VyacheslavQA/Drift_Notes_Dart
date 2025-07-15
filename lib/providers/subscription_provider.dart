// Путь: lib/providers/subscription_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_model.dart';
import '../models/usage_limits_model.dart';
import '../services/subscription/subscription_service.dart';
import '../services/firebase/firebase_service.dart';

/// ✅ ИСПРАВЛЕННЫЙ Provider для управления состоянием подписки
/// Убран UsageLimitsService, исправлено expenses → budgetNotes
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  // ✅ УПРОЩЕННОЕ состояние - только SubscriptionService
  SubscriptionModel? _subscription;
  UsageLimitsModel? _usageLimits;

  // Состояние продуктов
  List<ProductDetails> _availableProducts = [];
  bool _isLoadingProducts = false;

  // Состояние покупки
  bool _isPurchasing = false;
  String? _purchasingProductId;

  // Состояние загрузки
  bool _isLoading = true;
  String? _lastError;

  // Кэш локализованных цен
  Map<String, String>? _localizedPrices;

  // ✅ УПРОЩЕННЫЕ стримы - только SubscriptionService
  StreamSubscription<SubscriptionModel>? _subscriptionSubscription;

  // ========================================
  // ✅ ИСПРАВЛЕННЫЕ ГЕТТЕРЫ
  // ========================================

  SubscriptionModel? get subscription => _subscription;
  UsageLimitsModel? get usageLimits => _usageLimits;
  List<ProductDetails> get availableProducts => _availableProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  String? get purchasingProductId => _purchasingProductId;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Удобные геттеры для проверки статуса
  bool get isPremium => _subscription?.isPremium ?? false;
  bool get hasActiveSubscription => _subscription?.isActive ?? false;
  bool get isExpiringSoon => _subscription?.isExpiringSoon ?? false;
  int? get daysUntilExpiration => _subscription?.daysUntilExpiration;
  String get planDisplayName => _subscription?.planDisplayName ?? 'Бесплатный план';

  // Геттер для совместимости с HomeScreen
  bool get hasPremiumAccess => isPremium;

  // ========================================
  // ✅ УПРОЩЕННАЯ ИНИЦИАЛИЗАЦИЯ
  // ========================================

  Future<void> initialize() async {
    try {
      debugPrint('🔄 Инициализация SubscriptionProvider...');

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // ✅ УПРОЩЕНО: Инициализируем только SubscriptionService
      await _subscriptionService.initialize();

      // ✅ УПРОЩЕНО: Подписываемся только на изменения подписки
      _subscriptionSubscription = _subscriptionService.subscriptionStream.listen(
        _onSubscriptionChanged,
        onError: _onSubscriptionError,
      );

      // Загружаем начальные данные
      await _loadInitialData();

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ SubscriptionProvider инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации SubscriptionProvider: $e');
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ УПРОЩЕННАЯ загрузка данных через SubscriptionService
  Future<void> _loadInitialData() async {
    try {
      // Загружаем подписку
      _subscription = await _subscriptionService.loadCurrentSubscription();

      // ✅ ИСПРАВЛЕНО: Загружаем лимиты через Firebase
      await _loadUsageLimits();

      await _loadLocalizedPrices();
      await loadAvailableProducts();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки начальных данных: $e');
      // Устанавливаем дефолтные значения
      _subscription ??= SubscriptionModel.defaultSubscription('unknown');
      _usageLimits ??= UsageLimitsModel.defaultLimits(_subscription?.userId ?? 'unknown');
    }
  }

  /// ✅ ИСПРАВЛЕНО: Загрузка лимитов использования через Firebase с правильными методами
  Future<void> _loadUsageLimits() async {
    try {
      if (!_firebaseService.isUserLoggedIn) {
        // Для неавторизованных пользователей - дефолтные лимиты
        _usageLimits = UsageLimitsModel.defaultLimits('offline');
        return;
      }

      final userId = _firebaseService.currentUserId!;

      // ✅ ИСПРАВЛЕНО: Используем существующий метод getUsageStatistics
      final statsData = await _firebaseService.getUsageStatistics();

      if (statsData['exists'] == true) {
        // Создаем UsageLimitsModel из статистики
        _usageLimits = UsageLimitsModel(
          userId: userId,
          notesCount: statsData[SubscriptionConstants.notesCountField] ?? 0,
          markerMapsCount: statsData[SubscriptionConstants.markerMapsCountField] ?? 0,
          budgetNotesCount: statsData[SubscriptionConstants.budgetNotesCountField] ?? 0,
          lastResetDate: statsData[SubscriptionConstants.lastResetDateField] != null
              ? DateTime.parse(statsData[SubscriptionConstants.lastResetDateField])
              : DateTime.now(),
          updatedAt: statsData['updatedAt'] != null
              ? DateTime.parse(statsData['updatedAt'])
              : DateTime.now(),
        );
      } else {
        // Создаем новые лимиты если их нет
        _usageLimits = UsageLimitsModel.defaultLimits(userId);
        // ✅ ИСПРАВЛЕНО: Сохраняем через существующий метод resetUserUsageLimits
        await _firebaseService.resetUserUsageLimits(resetReason: 'initial_creation');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки лимитов: $e');
      _usageLimits = UsageLimitsModel.defaultLimits(_subscription?.userId ?? 'unknown');
    }
  }

  // ========================================
  // ✅ ИСПРАВЛЕННЫЕ МЕТОДЫ ПРОВЕРКИ ЛИМИТОВ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Проверка возможности создания контента
  Future<bool> canCreateContent(ContentType contentType) async {
    // Если есть премиум подписка, разрешаем все
    if (isPremium) {
      return true;
    }

    // Для графика глубин требуется премиум
    if (contentType == ContentType.depthChart) {
      return false;
    }

    // ✅ ИСПРАВЛЕНО: Проверка лимитов через UsageLimitsModel
    if (_usageLimits == null) {
      await _loadUsageLimits();
    }

    return _usageLimits?.canCreateNew(contentType) ?? false;
  }

  /// ✅ ИСПРАВЛЕНО: Синхронная проверка
  bool canCreateContentSync(ContentType contentType) {
    // Если премиум - разрешаем все
    if (isPremium) {
      return true;
    }

    // Для графика глубин - только премиум
    if (contentType == ContentType.depthChart) {
      return false;
    }

    return _usageLimits?.canCreateNew(contentType) ?? false;
  }

  /// ✅ ИСПРАВЛЕНО: Получение использования для типа контента
  int? getUsage(ContentType contentType) {
    return _usageLimits?.getCountForType(contentType);
  }

  /// ✅ ИСПРАВЛЕНО: Получение лимита для типа контента
  int getLimit(ContentType contentType) {
    if (isPremium) {
      return SubscriptionConstants.unlimitedValue; // ✅ ИСПРАВЛЕНО: Используем константу
    }

    return SubscriptionConstants.getContentLimit(contentType);
  }

  /// ✅ ИСПРАВЛЕНО: Получение оставшегося количества
  int getRemainingCount(ContentType contentType) {
    if (isPremium) return SubscriptionConstants.unlimitedValue; // Безлимитно

    return _usageLimits?.getRemainingCount(contentType) ?? 0;
  }

  /// ✅ ИСПРАВЛЕНО: Получение процента использования
  double getUsagePercentage(ContentType contentType) {
    if (isPremium) return 0.0;

    return _usageLimits?.getUsagePercentage(contentType) ?? 0.0;
  }

  /// ✅ ИСПРАВЛЕНО: Увеличение счетчика использования через Firebase методы
  Future<void> incrementUsage(ContentType contentType) async {
    try {
      if (_usageLimits == null) return;

      // Обновляем локальную модель
      _usageLimits = _usageLimits!.incrementCounter(contentType);
      notifyListeners();

      // ✅ ИСПРАВЛЕНО: Сохраняем через правильный Firebase метод
      if (_firebaseService.isUserLoggedIn) {
        final firebaseFieldName = _getFirebaseFieldName(contentType);
        await _firebaseService.incrementUsageCount(firebaseFieldName);
      }

      debugPrint('✅ Счетчик ${contentType.name} увеличен: ${getUsage(contentType)}');
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счетчика: $e');
    }
  }

  /// ✅ ИСПРАВЛЕНО: Уменьшение счетчика через SubscriptionService
  Future<void> decrementUsage(ContentType contentType) async {
    try {
      if (_usageLimits == null) return;

      // Обновляем локальную модель
      _usageLimits = _usageLimits!.decrementCounter(contentType);
      notifyListeners();

      // ✅ ИСПРАВЛЕНО: Используем SubscriptionService для уменьшения
      await _subscriptionService.decrementUsage(contentType);

      debugPrint('✅ Счетчик ${contentType.name} уменьшен: ${getUsage(contentType)}');
    } catch (e) {
      debugPrint('❌ Ошибка уменьшения счетчика: $e');
    }
  }

  /// ✅ НОВЫЙ: Преобразование ContentType в название поля Firebase
  String _getFirebaseFieldName(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return SubscriptionConstants.notesCountField;
      case ContentType.markerMaps:
        return SubscriptionConstants.markerMapsCountField;
      case ContentType.budgetNotes:
        return SubscriptionConstants.budgetNotesCountField;
      case ContentType.depthChart:
        return 'depthChartCount'; // На случай если будет добавлен
    }
  }

  // ========================================
  // МЕТОДЫ РАБОТЫ С ПРОДУКТАМИ И ПОКУПКАМИ
  // ========================================

  /// Загрузка локализованных цен
  Future<void> _loadLocalizedPrices() async {
    try {
      _localizedPrices = await SubscriptionConstants.getLocalizedPrices();
    } catch (e) {
      _localizedPrices = SubscriptionConstants.defaultPrices;
    }
  }

  /// Загрузка доступных продуктов из магазинов
  Future<void> loadAvailableProducts() async {
    try {
      _isLoadingProducts = true;
      _lastError = null;
      notifyListeners();

      final products = await _subscriptionService.getAvailableProducts();

      // Сортируем продукты в нужном порядке
      products.sort((a, b) {
        const order = [
          SubscriptionConstants.monthlyPremiumId,
          SubscriptionConstants.yearlyPremiumId,
        ];
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      });

      _availableProducts = products;
      _isLoadingProducts = false;
      notifyListeners();
    } catch (e) {
      _lastError = 'Не удалось загрузить продукты: $e';
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription(String productId) async {
    try {
      _isPurchasing = true;
      _purchasingProductId = productId;
      _lastError = null;
      notifyListeners();

      final success = await _subscriptionService.purchaseSubscription(productId);

      if (!success) {
        _lastError = 'Не удалось инициировать покупку';
      }

      _isPurchasing = false;
      _purchasingProductId = null;
      notifyListeners();

      return success;
    } catch (e) {
      _lastError = 'Ошибка покупки: $e';
      _isPurchasing = false;
      _purchasingProductId = null;
      notifyListeners();
      return false;
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _subscriptionService.restorePurchases();
      await refreshData();
    } catch (e) {
      _lastError = 'Ошибка восстановления: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Получение информации о продукте по ID
  ProductDetails? getProductById(String productId) {
    try {
      return _availableProducts.where((p) => p.id == productId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Получение цены продукта
  String getProductPrice(String productId) {
    final product = getProductById(productId);

    if (product != null && product.price.isNotEmpty) {
      return product.price;
    }

    if (_localizedPrices != null && _localizedPrices!.containsKey(productId)) {
      return _localizedPrices![productId]!;
    }

    return SubscriptionConstants.getDefaultPrice(productId);
  }

  // ========================================
  // ✅ УПРОЩЕННЫЕ МЕТОДЫ ОБНОВЛЕНИЯ
  // ========================================

  /// ✅ КРИТИЧЕСКИ ВАЖНО: Принудительное обновление данных
  Future<void> refreshUsageData() async {
    try {
      debugPrint('🔄 SubscriptionProvider: Обновление данных...');

      // Загружаем актуальные данные
      _subscription = await _subscriptionService.loadCurrentSubscription();
      await _loadUsageLimits();

      // 🚨 КРИТИЧЕСКИ ВАЖНО: Уведомляем всех слушателей
      notifyListeners();

      debugPrint('✅ SubscriptionProvider: Данные обновлены');
    } catch (e) {
      debugPrint('❌ SubscriptionProvider: Ошибка обновления: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Обновление всех данных
  Future<void> refreshData() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _loadInitialData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // UI HELPER МЕТОДЫ
  // ========================================

  /// Получение текста использования
  String getUsageText(ContentType contentType) {
    if (isPremium) {
      return '∞';
    }

    final currentUsage = getUsage(contentType) ?? 0;
    final limit = getLimit(contentType);

    return '$currentUsage/$limit';
  }

  /// Получение цвета индикатора использования
  Color getUsageIndicatorColor(ContentType contentType) {
    return SubscriptionConstants.getLimitIndicatorColor(
      getUsage(contentType) ?? 0,
      getLimit(contentType),
    );
  }

  /// ✅ ИСПРАВЛЕНО: Получение годовой скидки
  double getYearlyDiscount() {
    try {
      final monthlyProduct = getProductById(SubscriptionConstants.monthlyPremiumId);
      final yearlyProduct = getProductById(SubscriptionConstants.yearlyPremiumId);

      if (monthlyProduct == null || yearlyProduct == null) {
        return 33.0; // Дефолтная скидка
      }

      final monthlyPrice = _extractPrice(monthlyProduct.price);
      final yearlyPrice = _extractPrice(yearlyProduct.price);

      if (monthlyPrice > 0 && yearlyPrice > 0) {
        final annualMonthlyPrice = monthlyPrice * 12;
        final discount = ((annualMonthlyPrice - yearlyPrice) / annualMonthlyPrice) * 100;
        return discount.clamp(0.0, 100.0);
      }
    } catch (e) {
      debugPrint('❌ Ошибка расчета скидки: $e');
    }

    return 33.0; // Дефолтная скидка
  }

  /// Извлечение числового значения из строки цены
  double _extractPrice(String priceString) {
    try {
      // Удаляем все символы кроме цифр, точек и запятых
      String numericString = priceString.replaceAll(RegExp(r'[^\d.,]'), '');
      // Заменяем запятую на точку для десятичных дробей
      numericString = numericString.replaceAll(',', '.');
      return double.tryParse(numericString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// ✅ НОВЫЙ: Получение статистики использования
  Map<String, dynamic> getUsageStats() {
    return _usageLimits?.getUsageStats() ?? {
      'notes': {'current': 0, 'limit': 3, 'remaining': 3, 'percentage': 0.0},
      'maps': {'current': 0, 'limit': 3, 'remaining': 3, 'percentage': 0.0},
      'budgetNotes': {'current': 0, 'limit': 3, 'remaining': 3, 'percentage': 0.0},
      'total': 0,
    };
  }

  /// ✅ НОВЫЙ: Проверка нужно ли показать предупреждение о лимите
  bool shouldShowLimitWarning(ContentType contentType) {
    return _usageLimits?.shouldShowWarning(contentType) ?? false;
  }

  // ========================================
  // ОБРАБОТЧИКИ СОБЫТИЙ
  // ========================================

  /// Обработчик изменений подписки
  void _onSubscriptionChanged(SubscriptionModel subscription) {
    _subscription = subscription;
    notifyListeners();
  }

  /// Обработчик ошибок подписки
  void _onSubscriptionError(dynamic error) {
    _lastError = error.toString();
    notifyListeners();
  }

  /// Очистка ошибки
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscriptionSubscription?.cancel();
    _subscriptionService.dispose();
    super.dispose();
  }
}