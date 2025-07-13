// Путь: lib/providers/subscription_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_model.dart';
import '../models/usage_limits_model.dart';
import '../services/subscription/subscription_service.dart';
import '../services/subscription/usage_limits_service.dart';
import '../services/firebase/firebase_service.dart'; // ДОБАВЛЕНО

/// Provider для управления состоянием подписки в приложении
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final UsageLimitsService _usageLimitsService = UsageLimitsService();

  // Состояние подписки
  SubscriptionModel? _subscription;
  // 🔥 ИСПРАВЛЕНО: Изменили тип с UsageLimitsModel на Map
  Map<String, dynamic>? _usageLimits;

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

  // Стримы для прослушивания изменений
  StreamSubscription<SubscriptionModel>? _subscriptionSubscription;
  // 🔥 ИСПРАВЛЕНО: Изменили тип стрима
  StreamSubscription<Map<String, dynamic>>? _limitsSubscription;

  // Геттеры для состояния
  SubscriptionModel? get subscription => _subscription;
  // 🔥 ИСПРАВЛЕНО: Адаптер для совместимости
  UsageLimitsModel? get usageLimits => _convertMapToUsageLimits(_usageLimits);
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
  String get planDisplayName => _subscription?.planDisplayName ?? 'Free';

  /// 🔥 НОВЫЙ МЕТОД: Конвертация Map в UsageLimitsModel для совместимости
  UsageLimitsModel? _convertMapToUsageLimits(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('notesCount')) return null;

    // Создаем UsageLimitsModel из данных новой Firebase системы
    return UsageLimitsModel(
      userId: _subscription?.userId ?? '',
      notesCount: data['notesCount'] ?? 0,
      markerMapsCount: data['markerMapsCount'] ?? 0,
      expensesCount: data['expensesCount'] ?? 0,
      lastResetDate: DateTime.now(), // Приблизительно
      updatedAt: DateTime.now(),
    );
  }

  /// Инициализация провайдера
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Инициализация SubscriptionProvider...');

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // ИСПРАВЛЕНО: Создаем и устанавливаем FirebaseService в SubscriptionService
      try {
        final firebaseService = FirebaseService();
        _subscriptionService.setFirebaseService(firebaseService);
        debugPrint('✅ FirebaseService установлен в SubscriptionService');
      } catch (e) {
        debugPrint('⚠️ Не удалось установить FirebaseService: $e');
        // Продолжаем инициализацию без FirebaseService для избежания полного краха
      }

      // Инициализируем сервисы
      await _subscriptionService.initialize();
      await _usageLimitsService.initialize();

      // Подписываемся на изменения
      _subscriptionSubscription = _subscriptionService.subscriptionStream.listen(
        _onSubscriptionChanged,
        onError: _onSubscriptionError,
      );

      // 🔥 ИСПРАВЛЕНО: Обновленный обработчик для нового типа стрима
      _limitsSubscription = _usageLimitsService.limitsStream.listen(
        _onLimitsChanged,
        onError: _onLimitsError,
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

  /// 🔥 ИСПРАВЛЕНО: Загрузка начальных данных через новую систему
  Future<void> _loadInitialData() async {
    try {
      // Загружаем подписку и лимиты параллельно
      final results = await Future.wait([
        _subscriptionService.loadCurrentSubscription(),
        _usageLimitsService.loadCurrentLimits(),
      ]);

      _subscription = results[0] as SubscriptionModel;
      // 🔥 ИСПРАВЛЕНО: Теперь получаем Map вместо UsageLimitsModel
      _usageLimits = results[1] as Map<String, dynamic>;

      // Загружаем локализованные цены
      await _loadLocalizedPrices();

      // Загружаем доступные продукты
      await loadAvailableProducts();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки начальных данных: $e');
      rethrow;
    }
  }

  /// Загрузка локализованных цен
  Future<void> _loadLocalizedPrices() async {
    try {
      _localizedPrices = await SubscriptionConstants.getLocalizedPrices();
      debugPrint('💰 Загружены локализованные цены: $_localizedPrices');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки локализованных цен: $e');
      // Используем фоллбэк
      _localizedPrices = const {
        SubscriptionConstants.monthlyPremiumId: '\$4.99',
        SubscriptionConstants.yearlyPremiumId: '\$39.99',
      };
    }
  }

  /// Загрузка доступных продуктов из магазинов
  Future<void> loadAvailableProducts() async {
    try {
      _isLoadingProducts = true;
      _lastError = null;
      notifyListeners();

      final products = await _subscriptionService.getAvailableProducts();

      // Сортируем продукты: сначала месячный, потом годовой
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

      debugPrint('✅ Загружено продуктов: ${products.length}');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки продуктов: $e');
      _lastError = 'Failed to load products: $e';
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription(String productId) async {
    try {
      debugPrint('🛒 Покупка подписки: $productId');

      _isPurchasing = true;
      _purchasingProductId = productId;
      _lastError = null;
      notifyListeners();

      final success = await _subscriptionService.purchaseSubscription(productId);

      if (!success) {
        _lastError = 'Failed to initiate purchase';
      }

      _isPurchasing = false;
      _purchasingProductId = null;
      notifyListeners();

      return success;
    } catch (e) {
      debugPrint('❌ Ошибка покупки: $e');
      _lastError = 'Purchase failed: $e';
      _isPurchasing = false;
      _purchasingProductId = null;
      notifyListeners();
      return false;
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      debugPrint('🔄 Восстановление покупок...');

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _subscriptionService.restorePurchases();

      // Обновляем данные после восстановления
      await refreshData();

      debugPrint('✅ Восстановление покупок завершено');
    } catch (e) {
      debugPrint('❌ Ошибка восстановления покупок: $e');
      _lastError = 'Restore failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Проверка возможности создания контента
  Future<bool> canCreateContent(ContentType contentType) async {
    // Если есть премиум подписка, разрешаем все
    if (isPremium) {
      return true;
    }

    // Для графика глубин требуется премиум
    if (contentType == ContentType.depthChart) {
      return false;
    }

    // Проверяем лимиты через сервис
    return await _usageLimitsService.canCreateContent(contentType);
  }

  /// Детальная проверка возможности создания контента
  Future<ContentCreationResult> checkContentCreation(
      ContentType contentType,
      ) async {
    // Если есть премиум подписка
    if (isPremium) {
      return ContentCreationResult(
        canCreate: true,
        reason: null,
        currentCount: _getUsageCountFromMap(contentType),
        limit: -1, // Безлимитно
        remaining: -1, // Безлимитно
      );
    }

    // Проверяем через сервис лимитов
    return await _usageLimitsService.checkContentCreation(contentType);
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение счетчика из Map данных
  int _getUsageCountFromMap(ContentType contentType) {
    if (_usageLimits == null) return 0;

    switch (contentType) {
      case ContentType.fishingNotes:
        return _usageLimits!['notesCount'] ?? 0;
      case ContentType.markerMaps:
        return _usageLimits!['markerMapsCount'] ?? 0;
      case ContentType.expenses:
        return _usageLimits!['expensesCount'] ?? 0;
      case ContentType.depthChart:
        return 0; // Только премиум
    }
  }

  /// Увеличение счетчика использования
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Если есть премиум подписка, счетчики не увеличиваем
      if (isPremium) {
        return true;
      }

      final success = await _usageLimitsService.incrementUsage(contentType);

      if (success) {
        // Лимиты автоматически обновятся через стрим
        debugPrint('✅ Счетчик увеличен для $contentType');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счетчика: $e');
      return false;
    }
  }

  /// Уменьшение счетчика использования
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      // Если есть премиум подписка, счетчики не уменьшаем
      if (isPremium) {
        return true;
      }

      final success = await _usageLimitsService.decrementUsage(contentType);

      if (success) {
        debugPrint('✅ Счетчик уменьшен для $contentType');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Ошибка уменьшения счетчика: $e');
      return false;
    }
  }

  /// Получение статистики использования
  Future<Map<String, dynamic>> getUsageStatistics() async {
    return await _usageLimitsService.getUsageStatistics();
  }

  /// Проверка предупреждений о лимитах
  Future<List<ContentTypeWarning>> checkForWarnings() async {
    // Если есть премиум, предупреждений нет
    if (isPremium) {
      return [];
    }

    return await _usageLimitsService.checkForWarnings();
  }

  /// Пересчет лимитов на основе фактических данных
  Future<void> recalculateLimits() async {
    try {
      await _usageLimitsService.recalculateLimits();
      debugPrint('✅ Лимиты пересчитаны');
    } catch (e) {
      debugPrint('❌ Ошибка пересчета лимитов: $e');
    }
  }

  /// Обновление всех данных
  Future<void> refreshData() async {
    try {
      debugPrint('🔄 Обновление данных подписки...');

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _loadInitialData();

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Данные подписки обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления данных: $e');
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Получение информации о продукте по ID
  ProductDetails? getProductById(String productId) {
    return _availableProducts.where((p) => p.id == productId).firstOrNull;
  }

  /// Получение цены продукта (ИСПРАВЛЕНО)
  String getProductPrice(String productId) {
    final product = getProductById(productId);

    // Если есть реальная цена из магазина
    if (product != null && product.price.isNotEmpty) {
      return product.price;
    }

    // Используем локализованную цену
    if (_localizedPrices != null && _localizedPrices!.containsKey(productId)) {
      return _localizedPrices![productId]!;
    }

    // Фоллбэк на дефолтные цены
    const fallbackPrices = {
      SubscriptionConstants.monthlyPremiumId: '\$4.99',
      SubscriptionConstants.yearlyPremiumId: '\$39.99',
    };

    return fallbackPrices[productId] ?? '\$4.99';
  }

  /// Получение локализованной цены асинхронно
  Future<String> getLocalizedPrice(String productId) async {
    try {
      return await SubscriptionConstants.getLocalizedPrice(productId);
    } catch (e) {
      return getProductPrice(productId);
    }
  }

  /// Получение годовой экономии (в процентах) - УЛУЧШЕНО
  double getYearlyDiscount() {
    try {
      // Сначала пытаемся получить скидку из констант
      if (_localizedPrices != null) {
        // Получаем текущую валюту и рассчитываем скидку
        return SubscriptionConstants.getUserYearlyDiscount() as double? ?? 0.0;
      }

      // Если нет локализованных цен, считаем по продуктам из магазина
      final monthlyProduct = getProductById(SubscriptionConstants.monthlyPremiumId);
      final yearlyProduct = getProductById(SubscriptionConstants.yearlyPremiumId);

      if (monthlyProduct == null || yearlyProduct == null) {
        return 33.0; // Дефолтная скидка
      }

      // Извлекаем числовые значения из цен
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

  /// Получение годовой скидки асинхронно
  Future<double> getYearlyDiscountAsync() async {
    try {
      return await SubscriptionConstants.getUserYearlyDiscount();
    } catch (e) {
      return getYearlyDiscount();
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получение количества использования для типа контента
  int getUsageCount(ContentType contentType) {
    return _getUsageCountFromMap(contentType);
  }

  /// Получение лимита для типа контента
  int getUsageLimit(ContentType contentType) {
    return SubscriptionConstants.getContentLimit(contentType);
  }

  /// 🔥 ИСПРАВЛЕНО: Получение оставшегося количества для типа контента
  int getRemainingCount(ContentType contentType) {
    if (isPremium) return -1; // Безлимитно

    final current = _getUsageCountFromMap(contentType);
    final limit = getUsageLimit(contentType);

    return (limit - current).clamp(0, limit);
  }

  /// 🔥 ИСПРАВЛЕНО: Получение процента использования
  double getUsagePercentage(ContentType contentType) {
    if (isPremium) return 0.0; // Нет лимитов

    final current = _getUsageCountFromMap(contentType);
    final limit = getUsageLimit(contentType);

    if (limit <= 0) return 0.0;
    return (current / limit).clamp(0.0, 1.0);
  }

  /// Получение информации о валюте пользователя
  Future<SupportedCurrency> getUserCurrency() async {
    return await SubscriptionConstants.getUserCurrency();
  }

  /// Получение символа валюты
  Future<String> getCurrencySymbol() async {
    final currency = await getUserCurrency();
    return SubscriptionConstants.getCurrencySymbol(currency);
  }

  /// Обработчик изменений подписки
  void _onSubscriptionChanged(SubscriptionModel subscription) {
    debugPrint('🔄 Подписка изменена: ${subscription.status}');
    _subscription = subscription;
    notifyListeners();
  }

  /// Обработчик ошибок подписки
  void _onSubscriptionError(dynamic error) {
    debugPrint('❌ Ошибка в стриме подписки: $error');
    _lastError = error.toString();
    notifyListeners();
  }

  /// 🔥 ИСПРАВЛЕНО: Обработчик изменений лимитов (теперь принимает Map)
  void _onLimitsChanged(Map<String, dynamic> limits) {
    debugPrint('🔄 Лимиты изменены через новую Firebase систему');
    debugPrint('🔄 Данные: $limits');
    _usageLimits = limits;
    notifyListeners();
  }

  /// Обработчик ошибок лимитов
  void _onLimitsError(dynamic error) {
    debugPrint('❌ Ошибка в стриме лимитов: $error');
    _lastError = error.toString();
    notifyListeners();
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

  /// Очистка ошибки
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // 🔥 НОВЫЕ МЕТОДЫ для исправления реактивности счетчиков

  /// Принудительное обновление данных с уведомлением слушателей
  Future<void> refreshUsageData() async {
    try {
      debugPrint('🔄 SubscriptionProvider: Принудительное обновление данных...');

      // Загружаем актуальную подписку
      await _subscriptionService.loadCurrentSubscription();

      // Загружаем актуальные лимиты
      await _usageLimitsService.loadCurrentLimits();

      // 🚨 КРИТИЧЕСКИ ВАЖНО: Уведомляем всех слушателей об изменениях
      notifyListeners();

      debugPrint('✅ SubscriptionProvider: Данные обновлены и слушатели уведомлены');
    } catch (e) {
      debugPrint('❌ SubscriptionProvider: Ошибка обновления данных: $e');
      _lastError = e.toString();
      notifyListeners(); // Уведомляем даже при ошибке
    }
  }

  /// Синхронная проверка премиум доступа
  bool get hasPremiumAccess => _subscription?.isPremium ?? false;

  /// Синхронное получение использования для типа контента
  int? getUsage(ContentType contentType) {
    if (_usageLimits == null) return null;

    switch (contentType) {
      case ContentType.fishingNotes:
        return _usageLimits!['notesCount'] ?? 0;
      case ContentType.markerMaps:
        return _usageLimits!['markerMapsCount'] ?? 0;
      case ContentType.expenses:
        return _usageLimits!['expensesCount'] ?? 0;
      case ContentType.depthChart:
        return 0; // Только премиум
    }
  }

  /// Синхронное получение лимита для типа контента
  int? getLimit(ContentType contentType) {
    if (hasPremiumAccess) {
      return SubscriptionConstants.unlimitedValue; // Безлимитно для премиум
    }

    return SubscriptionConstants.getContentLimit(contentType);
  }

  /// Синхронная проверка возможности создания контента
  bool canCreateContentSync(ContentType contentType) {
    // Если премиум - разрешаем все
    if (hasPremiumAccess) {
      return true;
    }

    // Для графика глубин - только премиум
    if (contentType == ContentType.depthChart) {
      return false;
    }

    final currentUsage = getUsage(contentType) ?? 0;
    final limit = getLimit(contentType) ?? 0;

    return currentUsage < limit;
  }

  /// Получение цвета индикатора по проценту использования
  Color getUsageIndicatorColor(ContentType contentType) {
    final currentUsage = getUsage(contentType) ?? 0;
    final limit = getLimit(contentType) ?? 0;

    if (limit <= 0) return const Color(0xFF2E7D32);

    final percentage = currentUsage / limit;

    if (percentage >= 0.9) {
      return const Color(0xFFFF4444); // Красный - лимит
    } else if (percentage >= 0.7) {
      return const Color(0xFFFFA500); // Оранжевый - предупреждение
    } else {
      return const Color(0xFF2E7D32); // Зеленый - норма
    }
  }

  /// Получение текста использования
  String getUsageText(ContentType contentType) {
    if (hasPremiumAccess) {
      return '∞'; // Безлимитно
    }

    final currentUsage = getUsage(contentType) ?? 0;
    final limit = getLimit(contentType) ?? 0;

    return '$currentUsage/$limit';
  }

  @override
  void dispose() {
    _subscriptionSubscription?.cancel();
    _limitsSubscription?.cancel();
    _subscriptionService.dispose();
    _usageLimitsService.dispose();
    super.dispose();
  }
}