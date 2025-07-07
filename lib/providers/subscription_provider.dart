// Путь: lib/providers/subscription_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_model.dart';
import '../models/usage_limits_model.dart';
import '../services/subscription/subscription_service.dart';
import '../services/subscription/usage_limits_service.dart';

/// Provider для управления состоянием подписки в приложении
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final UsageLimitsService _usageLimitsService = UsageLimitsService();

  // Состояние подписки
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

  // Стримы для прослушивания изменений
  StreamSubscription<SubscriptionModel>? _subscriptionSubscription;
  StreamSubscription<UsageLimitsModel>? _limitsSubscription;

  // Геттеры для состояния
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
  String get planDisplayName => _subscription?.planDisplayName ?? 'Free';

  /// Инициализация провайдера
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Инициализация SubscriptionProvider...');

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // Инициализируем сервисы
      await _subscriptionService.initialize();
      await _usageLimitsService.initialize();

      // Подписываемся на изменения
      _subscriptionSubscription = _subscriptionService.subscriptionStream.listen(
        _onSubscriptionChanged,
        onError: _onSubscriptionError,
      );

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

  /// Загрузка начальных данных
  Future<void> _loadInitialData() async {
    try {
      // Загружаем подписку и лимиты параллельно
      final results = await Future.wait([
        _subscriptionService.loadCurrentSubscription(),
        _usageLimitsService.loadCurrentLimits(),
      ]);

      _subscription = results[0] as SubscriptionModel;
      _usageLimits = results[1] as UsageLimitsModel;

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
        currentCount: _usageLimits?.getCountForType(contentType) ?? 0,
        limit: -1, // Безлимитно
        remaining: -1, // Безлимитно
      );
    }

    // Проверяем через сервис лимитов
    return await _usageLimitsService.checkContentCreation(contentType);
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

  /// Получение количества использования для типа контента
  int getUsageCount(ContentType contentType) {
    return _usageLimits?.getCountForType(contentType) ?? 0;
  }

  /// Получение лимита для типа контента
  int getUsageLimit(ContentType contentType) {
    return SubscriptionConstants.getContentLimit(contentType);
  }

  /// Получение оставшегося количества для типа контента
  int getRemainingCount(ContentType contentType) {
    if (isPremium) return -1; // Безлимитно
    return _usageLimits?.getRemainingCount(contentType) ?? 0;
  }

  /// Получение процента использования
  double getUsagePercentage(ContentType contentType) {
    if (isPremium) return 0.0; // Нет лимитов
    return _usageLimits?.getUsagePercentage(contentType) ?? 0.0;
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

  /// Обработчик изменений лимитов
  void _onLimitsChanged(UsageLimitsModel limits) {
    debugPrint('🔄 Лимиты изменены: ${limits.totalContentCount} элементов');
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

  @override
  void dispose() {
    _subscriptionSubscription?.cancel();
    _limitsSubscription?.cancel();
    _subscriptionService.dispose();
    _usageLimitsService.dispose();
    super.dispose();
  }
}