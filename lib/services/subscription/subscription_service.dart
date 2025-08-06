// Путь: lib/services/subscription/subscription_service.dart

import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/subscription_constants.dart';
import '../../models/subscription_model.dart';
import '../../models/usage_limits_model.dart';
import '../../models/usage_limits_models.dart';
import '../../models/offline_usage_result.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/isar_service.dart';
import '../../repositories/user_usage_limits_repository.dart';
import '../../utils/network_utils.dart';

/// Сервис для управления подписками и покупками
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // FirebaseService инжектируется извне
  FirebaseService? _firebaseService;

  // IsarService для работы с локальными данными
  final IsarService _isarService = IsarService.instance;

  // Repository для работы с лимитами пользователя
  final UserUsageLimitsRepository _usageLimitsRepository = UserUsageLimitsRepository.instance;

  // Офлайн сторадж для кэширования (только для подписок, не для заметок)
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Кэш текущей подписки
  SubscriptionModel? _cachedSubscription;

  // 🆕 ДОБАВЛЕНО: Кэш доступных продуктов для загрузки цен
  List<ProductDetails> _availableProducts = [];

  // 🆕 ДОБАВЛЕНО: Кэш для управления обновлением цен
  DateTime? _lastProductsLoadTime;
  static const Duration _productsValidityDuration = Duration(hours: 1);

  // Стрим для прослушивания изменений подписки
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final StreamController<SubscriptionModel> _subscriptionController = StreamController<SubscriptionModel>.broadcast();
  final StreamController<SubscriptionStatus> _subscriptionStatusController = StreamController<SubscriptionStatus>.broadcast();

  // Стримы для UI
  Stream<SubscriptionModel> get subscriptionStream => _subscriptionController.stream;
  Stream<SubscriptionStatus> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Установка FirebaseService (вызывается ServiceManager'ом)
  void setFirebaseService(FirebaseService firebaseService) {
    _firebaseService = firebaseService;
  }

  /// Получение FirebaseService (с проверкой инициализации)
  FirebaseService get firebaseService {
    if (_firebaseService == null) {
      throw Exception('SubscriptionService не инициализирован! FirebaseService не установлен.');
    }
    return _firebaseService!;
  }

  // ========================================
  // УПРОЩЕННАЯ ЛОГИКА ТЕСТОВЫХ АККАУНТОВ
  // ========================================

  // Тестовые аккаунты для Google Play Review
  static const List<String> _testAccounts = [
    'googleplay.reviewer@gmail.com',
    'googleplayreviewer@gmail.com',
    'test.reviewer@gmail.com',
    'reviewer@googleplay.com',
    'driftnotes.test@gmail.com'
  ];

  /// Проверка тестового аккаунта
  bool _isTestAccount() {
    try {
      final currentUser = firebaseService.currentUser;
      if (currentUser?.email == null) return false;

      final email = currentUser!.email!.toLowerCase().trim();
      return _testAccounts.contains(email);
    } catch (e) {
      return false;
    }
  }

  /// Публичная проверка тестового аккаунта для отладки
  Future<bool> isTestReviewerAccount() async {
    return _isTestAccount();
  }

  /// Получение email текущего пользователя
  String? getCurrentUserEmail() {
    try {
      return firebaseService.currentUser?.email?.toLowerCase().trim();
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // 🆕 МЕТОДЫ ДЛЯ РАБОТЫ С РЕАЛЬНЫМИ ЦЕНАМИ
  // ========================================

  /// 🆕 НОВОЕ: Получение реальной локализованной цены продукта из Google Play
  Future<String?> getLocalizedPriceAsync(String productId) async {
    try {
      // Проверяем кэш продуктов
      if (_isProductsCacheValid() && _cachedProducts.containsKey(productId)) {
        final product = _cachedProducts[productId]!;
        return product.price;
      }

      // Обновляем кэш если нужно
      await _refreshProductsCache();

      // Возвращаем цену из обновленного кэша
      if (_cachedProducts.containsKey(productId)) {
        return _cachedProducts[productId]!.price;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🆕 НОВОЕ: Получение деталей продукта из Google Play
  Future<ProductDetails?> getProductDetailsAsync(String productId) async {
    try {
      // Проверяем кэш
      if (_isProductsCacheValid() && _cachedProducts.containsKey(productId)) {
        return _cachedProducts[productId];
      }

      // Обновляем кэш
      await _refreshProductsCache();

      return _cachedProducts[productId];
    } catch (e) {
      return null;
    }
  }

  /// 🆕 НОВОЕ: Принудительное обновление кэша продуктов и цен
  Future<void> refreshProductPrices() async {
    try {
      await _refreshProductsCache(force: true);
    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// 🆕 НОВОЕ: Получение всех локализованных цен
  Future<Map<String, String>> getAllLocalizedPrices() async {
    try {
      final prices = <String, String>{};

      // Обновляем кэш если нужно
      if (!_isProductsCacheValid()) {
        await _refreshProductsCache();
      }

      // Собираем цены из кэша
      for (final productId in SubscriptionConstants.subscriptionProductIds) {
        if (_cachedProducts.containsKey(productId)) {
          prices[productId] = _cachedProducts[productId]!.price;
        } else {
          // Фоллбэк к дефолтным ценам
          prices[productId] = SubscriptionConstants.getDefaultPrice(productId);
        }
      }

      return prices;
    } catch (e) {
      // Возвращаем дефолтные цены при ошибке
      return SubscriptionConstants.defaultPrices;
    }
  }

  /// 🆕 НОВОЕ: Получение лучшей доступной цены (реальная или фоллбэк)
  Future<String> getBestAvailablePrice(String productId) async {
    try {
      // Сначала пытаемся получить реальную цену
      final realPrice = await getLocalizedPriceAsync(productId);
      if (realPrice != null && realPrice.isNotEmpty) {
        return realPrice;
      }

      // Региональный фоллбэк
      final regionalPrices = await SubscriptionConstants.getLocalizedPrices();
      if (regionalPrices.containsKey(productId)) {
        return regionalPrices[productId]!;
      }

      // Финальный фоллбэк
      return SubscriptionConstants.getDefaultPrice(productId);
    } catch (e) {
      return SubscriptionConstants.getDefaultPrice(productId);
    }
  }

  /// 🆕 НОВОЕ: Получение цен с учетом региона пользователя
  Future<Map<String, String>> getRegionalizedPrices() async {
    try {
      // Сначала пытаемся получить реальные цены из Google Play
      final realPrices = await getAllLocalizedPrices();

      // Если есть реальные цены - используем их
      if (realPrices.isNotEmpty &&
          realPrices.values.every((price) => price.isNotEmpty && !price.contains('N/A'))) {
        return realPrices;
      }

      // Фоллбэк к региональным ценам из констант
      return await SubscriptionConstants.getLocalizedPrices();
    } catch (e) {
      return SubscriptionConstants.defaultPrices;
    }
  }

  // 🆕 НОВОЕ: Вспомогательный кэш продуктов для быстрого доступа
  Map<String, ProductDetails> _cachedProducts = {};

  /// 🆕 НОВОЕ: Проверка валидности кэша продуктов
  bool _isProductsCacheValid() {
    if (_lastProductsLoadTime == null || _cachedProducts.isEmpty) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_lastProductsLoadTime!);
    return cacheAge < _productsValidityDuration;
  }

  /// 🆕 НОВОЕ: Обновление кэша продуктов
  Future<void> _refreshProductsCache({bool force = false}) async {
    try {
      // Проверяем нужно ли обновлять
      if (!force && _isProductsCacheValid()) {
        return;
      }

      // Проверяем доступность InAppPurchase
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return;
      }

      // Загружаем продукты из Google Play
      final response = await _inAppPurchase.queryProductDetails(
          SubscriptionConstants.subscriptionProductIds.toSet()
      );

      if (response.error != null) {
        return;
      }

      // Обновляем кэш
      _cachedProducts.clear();
      for (final product in response.productDetails) {
        _cachedProducts[product.id] = product;
      }

      // Также обновляем старый кэш для совместимости
      _availableProducts = response.productDetails;
      _lastProductsLoadTime = DateTime.now();

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  // ========================================
  // СИНХРОННЫЕ МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ
  // ========================================

  /// Получение локализованной цены продукта (синхронно из кэша)
  String getLocalizedPrice(String productId) {
    try {
      final product = _availableProducts.where((p) => p.id == productId).firstOrNull;
      return product?.price ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Получение деталей продукта (синхронно из кэша)
  ProductDetails? getProductDetails(String productId) {
    try {
      return _availableProducts.where((p) => p.id == productId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Проверка загруженности продуктов
  bool get areProductsLoaded => _availableProducts.isNotEmpty;

  // ========================================
  // ИНИЦИАЛИЗАЦИЯ
  // ========================================

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      // Проверяем что FirebaseService установлен
      if (_firebaseService == null) {
        return;
      }

      // Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

      // Проверяем доступность покупок
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return;
      }

      // Подписываемся на изменения покупок
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {},
        onError: (error) {},
      );

      // 🆕 УЛУЧШЕНО: Загружаем продукты для кэширования цен
      await _loadProducts();

      // Загружаем текущую подписку
      await loadCurrentSubscription();

      // Восстанавливаем покупки при инициализации
      await restorePurchases();

      // Инициализируем систему лимитов через Repository
      await _initializeUsageLimitsRepository();

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// 🆕 УЛУЧШЕНО: Загрузка продуктов с кэшированием (теперь использует новый кэш)
  Future<void> _loadProducts() async {
    try {
      await _refreshProductsCache();
    } catch (e) {
      _availableProducts = [];
    }
  }

  /// Инициализация системы лимитов через Repository
  Future<void> _initializeUsageLimitsRepository() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return;
      }

      // Загружаем текущие лимиты через Repository
      final limits = await _usageLimitsRepository.getUserLimits(userId);

      if (limits == null) {
        // Создаем лимиты по умолчанию и сохраняем через Repository
        final defaultLimits = UsageLimitsModel.defaultLimits(userId);
        await _usageLimitsRepository.saveUserLimits(defaultLimits);
      }

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  // ========================================
  // ИСПРАВЛЕННЫЕ МЕТОДЫ ПРОВЕРКИ ЛИМИТОВ (ТЕПЕРЬ ИСПОЛЬЗУЮТ REPOSITORY)
  // ========================================

  /// Основной метод проверки возможности создания контента через Repository
  Future<bool> canCreateContent(ContentType contentType) async {
    try {
      // Если пользователь имеет премиум - разрешаем всё
      if (hasPremiumAccess()) {
        return true;
      }

      // Для графика глубин - только премиум
      if (contentType == ContentType.depthChart) {
        return false;
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return false;
      }

      // Используем Repository для проверки лимитов
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      return result.canCreate;
    } catch (e) {
      return false;
    }
  }

  /// Офлайн проверка создания контента через Repository
  Future<bool> canCreateContentOffline(ContentType contentType) async {
    try {
      // 1. Проверка тестового аккаунта - безлимитный доступ
      if (_isTestAccount()) {
        return true;
      }

      // 2. Проверка кэшированного премиум статуса
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      if (cachedSubscription?.isPremium == true) {
        if (await _offlineStorage.isSubscriptionCacheValid()) {
          return true;
        }
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return false;
      }

      // 3. Используем Repository для офлайн проверки
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      return result.canCreate;
    } catch (e) {
      // При ошибке разрешаем создание (принцип "fail open")
      return true;
    }
  }

  /// Получение детальной информации о статусе использования через Repository
  Future<OfflineUsageResult> checkOfflineUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return _getErrorUsageResult(contentType);
      }

      // Получаем результат через Repository
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      // Определяем тип предупреждения
      OfflineLimitWarningType warningType;
      String message;

      if (!result.canCreate) {
        if (result.reason == ContentCreationBlockReason.premiumRequired) {
          warningType = OfflineLimitWarningType.blocked;
          message = 'Требуется премиум подписка для ${_getContentTypeName(contentType)}';
        } else {
          warningType = OfflineLimitWarningType.blocked;
          message = 'Достигнут лимит ${_getContentTypeName(contentType)} (${result.limit})';
        }
      } else if (result.remaining <= 2) {
        warningType = OfflineLimitWarningType.warning;
        message = 'Осталось ${result.remaining} ${_getContentTypeName(contentType)}';
      } else {
        warningType = OfflineLimitWarningType.normal;
        message = 'Доступно ${result.remaining} ${_getContentTypeName(contentType)}';
      }

      return OfflineUsageResult(
        canCreate: result.canCreate,
        warningType: warningType,
        message: message,
        currentUsage: result.currentCount,
        limit: result.limit,
        remaining: result.remaining,
        contentType: contentType,
      );
    } catch (e) {
      return _getErrorUsageResult(contentType);
    }
  }

  /// Вспомогательный: Создание результата при ошибке
  OfflineUsageResult _getErrorUsageResult(ContentType contentType) {
    return OfflineUsageResult(
      canCreate: true,
      warningType: OfflineLimitWarningType.normal,
      message: 'Ошибка проверки лимитов',
      currentUsage: 0,
      limit: getLimit(contentType),
      remaining: getLimit(contentType),
      contentType: contentType,
    );
  }

  // ========================================
  // ИСПРАВЛЕННЫЕ МЕТОДЫ РАБОТЫ СО СЧЕТЧИКАМИ (ЧЕРЕЗ REPOSITORY)
  // ========================================

  /// Увеличение счетчика использования через Repository
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Тестовые аккаунты Google Play - безлимитный доступ БЕЗ счетчиков
      if (_isTestAccount()) {
        return true;
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return false;
      }

      // Увеличиваем счетчик через Repository
      await _usageLimitsRepository.incrementCounter(userId, contentType);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Уменьшение счетчика использования через Repository
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return false;
      }

      // Уменьшаем счетчик через Repository
      await _usageLimitsRepository.decrementCounter(userId, contentType);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Сброс использования по типу через Repository
  Future<void> resetUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return;
      }

      // Сбрасываем все счетчики через Repository
      await _usageLimitsRepository.resetAllCounters(userId);

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Получение информации об использовании через Repository
  Future<Map<ContentType, Map<String, int>>> getUsageInfo() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {};

      final result = <ContentType, Map<String, int>>{};

      for (final contentType in ContentType.values) {
        final stats = await _usageLimitsRepository.getStatsForType(userId, contentType);
        result[contentType] = {
          'current': stats['current'] ?? 0,
          'limit': stats['limit'] ?? 0,
        };
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  /// Получение статистики использования через Repository
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {'exists': false, 'error': 'User not authenticated'};

      // Получаем статистику через Repository
      final stats = await _usageLimitsRepository.getUsageStats(userId);

      // Преобразуем в формат совместимый со старой структурой
      return {
        SubscriptionConstants.notesCountField: stats['notes']?['current'] ?? 0,
        SubscriptionConstants.markerMapsCountField: stats['maps']?['current'] ?? 0,
        SubscriptionConstants.budgetNotesCountField: stats['budgetNotes']?['current'] ?? 0,
        SubscriptionConstants.lastResetDateField: DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'exists': true,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Получение текущего использования через Repository
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return 0;

      final stats = await _usageLimitsRepository.getStatsForType(userId, contentType);
      return stats['current'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Полный пересчет лимитов через Repository с правильной фильтрацией по пользователю
  Future<void> recalculateUsageLimits() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return;
      }

      // Получаем реальное количество заметок с фильтрацией по пользователю
      final fishingNotesCount = await _isarService.getFishingNotesCountByUser(userId);
      final markerMapsCount = await _isarService.getMarkerMapsCountByUser(userId);
      final budgetNotesCount = await _isarService.getBudgetNotesCountByUser(userId);

      // Пересчитываем через Repository
      await _usageLimitsRepository.recalculateCounters(
        userId,
        notesCount: fishingNotesCount,
        markerMapsCount: markerMapsCount,
        budgetNotesCount: budgetNotesCount,
        recalculationType: 'subscription_service_recalculate',
      );

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  // ========================================
  // УТИЛИТЫ И ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Получение читаемого названия типа контента
  String _getContentTypeName(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'заметок';
      case ContentType.markerMaps:
        return 'карт';
      case ContentType.budgetNotes:
        return 'заметок бюджета';
      case ContentType.depthChart:
        return 'графиков глубин';
      case ContentType.markerMapSharing: // 🚀 ДОБАВИТЬ ЭТУ СТРОКУ
        return 'обмена картами';           // 🚀 И ЭТУ СТРОКУ
    }
  }

  /// Проверка премиум доступа с учетом тестовых аккаунтов
  bool hasPremiumAccess() {
    // Проверяем тестовый аккаунт ПЕРВЫМ
    if (_isTestAccount()) {
      return true;
    }

    // Обычная проверка премиум статуса
    return _cachedSubscription?.isPremium ?? false;
  }

  /// Получение лимита по типу контента с учетом тестовых аккаунтов
  int getLimit(ContentType contentType) {
    try {
      // Если премиум (включая тестовые аккаунты) - возвращаем безлимитный доступ
      if (hasPremiumAccess()) {
        return SubscriptionConstants.unlimitedValue;
      }

      // Для бесплатных пользователей возвращаем лимиты из констант
      return SubscriptionConstants.getContentLimit(contentType);
    } catch (e) {
      return SubscriptionConstants.getContentLimit(contentType);
    }
  }

  /// Проверка необходимости показа предупреждения о лимите через Repository
  Future<bool> shouldShowLimitWarning(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return false;

      final warnings = await _usageLimitsRepository.getContentWarnings(userId);
      return warnings.any((warning) => warning.contentType == contentType);
    } catch (e) {
      return false;
    }
  }

  /// Проверка необходимости показа диалога премиум
  Future<bool> shouldShowPremiumDialog(ContentType contentType) async {
    try {
      final result = await checkOfflineUsage(contentType);
      return result.shouldShowPremiumDialog;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // ИСПРАВЛЕННОЕ КЭШИРОВАНИЕ И ОФЛАЙН МЕТОДЫ (ЧЕРЕЗ REPOSITORY)
  // ========================================

  /// Кэширование данных подписки через Repository
  Future<void> cacheSubscriptionDataOnline() async {
    try {
      // Проверяем доступность сети
      if (!await NetworkUtils.isNetworkAvailable()) {
        return;
      }

      // Загружаем актуальную подписку
      final subscription = await loadCurrentSubscription();

      // Кэшируем подписку
      await _offlineStorage.cacheSubscriptionStatus(subscription);

      // Кэшируем лимиты через Repository
      try {
        final userId = firebaseService.currentUserId;
        if (userId != null) {
          final limits = await _usageLimitsRepository.getUserLimits(userId);
          if (limits != null) {
            await _offlineStorage.cacheUsageLimits(limits);
          }
        }
      } catch (e) {
        // Ошибки кэширования лимитов не критичны
      }

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Принудительное обновление кэша подписки
  Future<void> refreshSubscriptionCache() async {
    try {
      await cacheSubscriptionDataOnline();
    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Получение информации о кэше подписки
  Future<Map<String, dynamic>> getSubscriptionCacheInfo() async {
    try {
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      final isValid = await _offlineStorage.isSubscriptionCacheValid();

      return {
        'hasCachedSubscription': cachedSubscription != null,
        'isPremium': cachedSubscription?.isPremium ?? false,
        'isCacheValid': isValid,
        'status': cachedSubscription?.status.name,
        'expirationDate': cachedSubscription?.expirationDate?.toIso8601String(),
      };
    } catch (e) {
      return {
        'hasCachedSubscription': false,
        'isPremium': false,
        'isCacheValid': false,
      };
    }
  }

  /// Получение отладочной информации о лимитах через Repository
  Future<Map<String, dynamic>> getUsageLimitsDebugInfo() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {'error': 'User not authenticated'};

      return await _usageLimitsRepository.getDebugInfo(userId);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Очистка локальных счетчиков (теперь через Repository)
  Future<void> clearLocalCounters() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return;

      // Очищаем через Repository
      await _usageLimitsRepository.resetAllCounters(userId);

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Получение всех локальных счетчиков через Repository
  Future<Map<ContentType, int>> getAllLocalCounters() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {};

      final result = <ContentType, int>{};

      for (final contentType in ContentType.values) {
        final stats = await _usageLimitsRepository.getStatsForType(userId, contentType);
        result[contentType] = stats['current'] ?? 0;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  // ========================================
  // УПРАВЛЕНИЕ ПОДПИСКАМИ
  // ========================================

  /// Загрузка текущей подписки пользователя
  Future<SubscriptionModel> loadCurrentSubscription() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        _cachedSubscription = SubscriptionModel.defaultSubscription('');
        _subscriptionStatusController.add(_cachedSubscription!.status);
        return _cachedSubscription!;
      }

      // Если тестовый аккаунт - создаем премиум подписку
      if (_isTestAccount()) {
        _cachedSubscription = SubscriptionModel(
          userId: userId,
          status: SubscriptionStatus.active,
          type: SubscriptionType.yearly,
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          purchaseToken: 'test_account_token',
          platform: Platform.isAndroid ? 'android' : 'ios',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        _subscriptionController.add(_cachedSubscription!);
        _subscriptionStatusController.add(_cachedSubscription!.status);
        return _cachedSubscription!;
      }

      // Проверяем кэш
      if (_cachedSubscription != null && _cachedSubscription!.userId == userId) {
        return _cachedSubscription!;
      }

      // Загружаем из Firebase
      if (await NetworkUtils.isNetworkAvailable()) {
        final doc = await firebaseService.getUserSubscription();

        if (doc.exists && doc.data() != null) {
          _cachedSubscription = SubscriptionModel.fromMap(doc.data()! as Map<String, dynamic>, userId);
        } else {
          _cachedSubscription = SubscriptionModel.defaultSubscription(userId);
        }
      } else {
        // Загружаем из локального кэша
        _cachedSubscription = await _loadFromCache(userId);
      }

      // Отправляем в стримы
      _subscriptionController.add(_cachedSubscription!);
      _subscriptionStatusController.add(_cachedSubscription!.status);

      return _cachedSubscription!;
    } catch (e) {
      final userId = firebaseService.currentUserId ?? '';
      _cachedSubscription = SubscriptionModel.defaultSubscription(userId);
      _subscriptionStatusController.add(_cachedSubscription!.status);
      return _cachedSubscription!;
    }
  }

  /// 🆕 ОБНОВЛЕНО: Получение доступных продуктов подписки (теперь использует новый кэш)
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      // Если кэш актуален, возвращаем из него
      if (_isProductsCacheValid()) {
        return _cachedProducts.values.toList();
      }

      // Обновляем кэш
      await _refreshProductsCache();

      // Возвращаем обновленные продукты
      return _cachedProducts.values.toList();
    } catch (e) {
      return _availableProducts; // Фоллбэк к старому кэшу
    }
  }

  /// 🆕 УЛУЧШЕНО: Покупка подписки с обработкой тестовых аккаунтов
  Future<bool> purchaseSubscription(String productId) async {
    try {
      // 🆕 ДОБАВЛЕНО: Проверка тестового аккаунта - пропускаем реальную покупку
      if (_isTestAccount()) {
        // Для тестовых аккаунтов имитируем успешную покупку
        await Future.delayed(const Duration(seconds: 1));
        await _handleTestAccountPurchase(productId);
        return true;
      }

      // Получаем детали продукта
      final products = await getAvailableProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        return false;
      }

      // Создаем параметры покупки
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Запускаем покупку
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 ДОБАВЛЕНО: Обработка покупки для тестовых аккаунтов
  Future<void> _handleTestAccountPurchase(String productId) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return;

      final subscriptionType = SubscriptionConstants.getSubscriptionType(productId);
      if (subscriptionType == null) return;

      // Создаем подписку для тестового аккаунта
      final subscription = SubscriptionModel(
        userId: userId,
        status: SubscriptionStatus.active,
        type: subscriptionType,
        expirationDate: DateTime.now().add(const Duration(days: 365)),
        purchaseToken: 'test_account_$productId',
        platform: Platform.isAndroid ? 'android' : 'ios',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Сохраняем в кэш
      await _saveToCache(subscription);
      _cachedSubscription = subscription;

      // Отправляем в стримы
      _subscriptionController.add(subscription);
      _subscriptionStatusController.add(subscription.status);

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// 🆕 УЛУЧШЕНО: Обработка обновлений покупок с полной логикой
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          await _handlePendingPurchase(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          await _handleRestoredPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          await _handleFailedPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          await _handleCanceledPurchase(purchaseDetails);
          break;
      }

      // Завершаем покупку на платформе
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Обработка ожидающей покупки
  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    await _updateSubscriptionStatus(
      purchaseDetails,
      SubscriptionStatus.pending,
    );
  }

  /// 🆕 УЛУЧШЕНО: Обработка успешной покупки с валидацией
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (await _validatePurchase(purchaseDetails)) {
        await _updateSubscriptionStatus(
          purchaseDetails,
          SubscriptionStatus.active,
        );
      }
    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// 🆕 УЛУЧШЕНО: Обработка восстановленной покупки с проверкой валидности
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    if (await _isSubscriptionStillValid(purchaseDetails)) {
      await _updateSubscriptionStatus(
        purchaseDetails,
        SubscriptionStatus.active,
      );
    } else {
      await _updateSubscriptionStatus(
        purchaseDetails,
        SubscriptionStatus.expired,
      );
    }
  }

  /// Обработка неудачной покупки
  Future<void> _handleFailedPurchase(PurchaseDetails purchaseDetails) async {
    // Логируем неудачу, но не предпринимаем дополнительных действий
  }

  /// Обработка отмененной покупки
  Future<void> _handleCanceledPurchase(PurchaseDetails purchaseDetails) async {
    // Покупка отменена пользователем, дополнительных действий не требуется
  }

  /// 🆕 УЛУЧШЕНО: Обновление статуса подписки в Firebase с retry и офлайн кэшированием
  Future<void> _updateSubscriptionStatus(
      PurchaseDetails purchaseDetails,
      SubscriptionStatus status,
      ) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return;

      final subscriptionType = SubscriptionConstants.getSubscriptionType(purchaseDetails.productID);
      if (subscriptionType == null) return;

      // Вычисляем дату истечения
      DateTime? expirationDate;
      if (status == SubscriptionStatus.active) {
        expirationDate = _calculateExpirationDate(subscriptionType);
      }

      // Создаем данные подписки
      final subscriptionData = {
        'userId': userId,
        'status': status.name,
        'type': subscriptionType.name,
        'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null,
        'purchaseToken': purchaseDetails.purchaseID ?? '',
        'productId': purchaseDetails.productID, // 🆕 ДОБАВЛЕНО
        'originalTransactionId': purchaseDetails.purchaseID ?? '', // 🆕 ДОБАВЛЕНО
        'platform': Platform.isAndroid
            ? SubscriptionConstants.androidPlatform
            : SubscriptionConstants.iosPlatform,
        'createdAt': _cachedSubscription?.createdAt != null
            ? Timestamp.fromDate(_cachedSubscription!.createdAt)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), // 🆕 УЛУЧШЕНО
        'isActive': status == SubscriptionStatus.active &&
            expirationDate != null &&
            DateTime.now().isBefore(expirationDate),
      };

      // 🆕 УЛУЧШЕНО: Сохраняем с retry логикой
      if (await NetworkUtils.isNetworkAvailable()) {
        await _saveSubscriptionWithRetry(subscriptionData);
      }

      // Создаем обновленную модель подписки
      final subscription = SubscriptionModel(
        userId: userId,
        status: status,
        type: subscriptionType,
        expirationDate: expirationDate,
        purchaseToken: purchaseDetails.purchaseID ?? '',
        platform: Platform.isAndroid
            ? SubscriptionConstants.androidPlatform
            : SubscriptionConstants.iosPlatform,
        createdAt: _cachedSubscription?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: status == SubscriptionStatus.active &&
            expirationDate != null &&
            DateTime.now().isBefore(expirationDate),
      );

      // Сохраняем в кэш
      await _saveToCache(subscription);
      _cachedSubscription = subscription;

      // Отправляем в стримы
      _subscriptionController.add(subscription);
      _subscriptionStatusController.add(subscription.status);

    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Сохранение подписки с retry логикой
  Future<void> _saveSubscriptionWithRetry(Map<String, dynamic> subscriptionData) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        await firebaseService.updateUserSubscription(subscriptionData);
        return; // Успешно сохранено
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          // После всех попыток просто логируем ошибку
          // Данные уже кэшированы локально через _saveToCache()
          return;
        }
        // Ждем перед следующей попыткой
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }

  /// 🆕 УЛУЧШЕНО: Валидация покупки с дополнительными проверками
  Future<bool> _validatePurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Базовые проверки
      if (purchaseDetails.productID.isEmpty) return false;

      // Проверяем что productID в списке наших продуктов
      if (!SubscriptionConstants.subscriptionProductIds.contains(purchaseDetails.productID)) {
        return false;
      }

      // Проверяем наличие purchaseToken
      if (purchaseDetails.purchaseID == null || purchaseDetails.purchaseID!.isEmpty) {
        return false;
      }

      // 🆕 ДОБАВЛЕНО: Проверяем что покупка не дублируется
      if (_cachedSubscription != null &&
          _cachedSubscription!.purchaseToken == purchaseDetails.purchaseID) {
        return false; // Дубликат покупки
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 УЛУЧШЕНО: Проверка валидности подписки с проверкой даты истечения
  Future<bool> _isSubscriptionStillValid(PurchaseDetails purchaseDetails) async {
    try {
      // Базовая проверка продукта
      if (!SubscriptionConstants.subscriptionProductIds.contains(purchaseDetails.productID)) {
        return false;
      }

      // Проверяем кэшированную подписку
      if (_cachedSubscription != null) {
        final now = DateTime.now();
        if (_cachedSubscription!.expirationDate != null &&
            now.isAfter(_cachedSubscription!.expirationDate!)) {
          return false; // Подписка истекла
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Вычисление даты истечения подписки
  DateTime _calculateExpirationDate(SubscriptionType type) {
    final now = DateTime.now();

    switch (type) {
      case SubscriptionType.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case SubscriptionType.yearly:
        return DateTime(now.year + 1, now.month, now.day);
    }
  }

  /// Сохранение подписки в кэш только через OfflineStorageService
  Future<void> _saveToCache(SubscriptionModel subscription) async {
    try {
      await _offlineStorage.cacheSubscriptionStatus(subscription);
    } catch (e) {
      // Ошибки обрабатываем молча
    }
  }

  /// Загрузка подписки из кэша только через OfflineStorageService
  Future<SubscriptionModel> _loadFromCache(String userId) async {
    try {
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      return cachedSubscription ?? SubscriptionModel.defaultSubscription(userId);
    } catch (e) {
      return SubscriptionModel.defaultSubscription(userId);
    }
  }

  /// Получение текущей подписки (синхронно из кэша)
  SubscriptionModel? get currentSubscription => _cachedSubscription;

  /// Проверка премиум статуса с учетом тестовых аккаунтов
  bool get isPremium {
    // Проверяем тестовый аккаунт ПЕРВЫМ
    if (_isTestAccount()) {
      return true;
    }

    // Обычная проверка премиум статуса
    return _cachedSubscription?.isPremium ?? false;
  }

  /// Очистка ресурсов
  void dispose() {
    _purchaseSubscription?.cancel();
    _subscriptionController.close();
    _subscriptionStatusController.close();
  }
}