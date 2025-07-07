// Путь: lib/services/subscription/subscription_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/subscription_constants.dart';
import '../../models/subscription_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/subscription/usage_limits_service.dart';
import '../../utils/network_utils.dart';

/// Сервис для управления подписками и покупками
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsageLimitsService _usageLimitsService = UsageLimitsService();

  // Тестовые аккаунты для Google Play Review
  static const List<String> _testAccounts = [
    'googleplay.reviewer@gmail.com',
    'googleplayreviewer@gmail.com',
    'test.reviewer@gmail.com',
    'reviewer@googleplay.com',
    'driftnotes.test@gmail.com'
  ];

  // Кэш текущей подписки
  SubscriptionModel? _cachedSubscription;

  // Стрим для прослушивания изменений подписки
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final StreamController<SubscriptionModel> _subscriptionController = StreamController<SubscriptionModel>.broadcast();

  // Стрим для статуса подписки (для совместимости)
  final StreamController<SubscriptionStatus> _subscriptionStatusController = StreamController<SubscriptionStatus>.broadcast();

  // Стрим для UI
  Stream<SubscriptionModel> get subscriptionStream => _subscriptionController.stream;

  // Стрим статуса подписки для совместимости с виджетами
  Stream<SubscriptionStatus> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Проверка тестового аккаунта
  bool _isTestAccount() {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser?.email == null) return false;

      final email = currentUser!.email!.toLowerCase().trim();
      final isTest = _testAccounts.contains(email);

      if (kDebugMode && isTest) {
        debugPrint('🧪 Обнаружен тестовый аккаунт: $email');
      }

      return isTest;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки тестового аккаунта: $e');
      }
      return false;
    }
  }

  // Публичная проверка тестового аккаунта для отладки
  Future<bool> isTestReviewerAccount() async {
    return _isTestAccount();
  }

  /// Получение email текущего пользователя
  String? getCurrentUserEmail() {
    try {
      return _firebaseService.currentUser?.email?.toLowerCase().trim();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения email: $e');
      }
      return null;
    }
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Инициализация SubscriptionService...');
      }

      // Инициализируем UsageLimitsService
      await _usageLimitsService.initialize();

      // Устанавливаем связь между сервисами
      _usageLimitsService.setSubscriptionService(this);

      // Проверяем доступность покупок
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          debugPrint('❌ In-App Purchase недоступен на этом устройстве');
        }
        return;
      }

      // Подписываемся на изменения покупок
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {
          if (kDebugMode) {
            debugPrint('🔄 Purchase stream закрыт');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ Ошибка в purchase stream: $error');
          }
        },
      );

      // Загружаем текущую подписку
      await loadCurrentSubscription();

      // Восстанавливаем покупки при инициализации
      await restorePurchases();

      if (kDebugMode) {
        debugPrint('✅ SubscriptionService инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации SubscriptionService: $e');
      }
    }
  }

  /// Проверка возможности создания контента
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

      // Используем UsageLimitsService для проверки лимитов
      return await _usageLimitsService.canCreateContent(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      }
      return false;
    }
  }

  /// Проверка премиум доступа с учетом тестовых аккаунтов
  bool hasPremiumAccess() {
    // Проверяем тестовый аккаунт ПЕРВЫМ
    if (_isTestAccount()) {
      if (kDebugMode) {
        debugPrint('🧪 Тестовый аккаунт имеет полный премиум доступ');
      }
      return true;
    }

    // Обычная проверка премиум статуса
    return _cachedSubscription?.isPremium ?? false;
  }

  /// Получение текущего использования по типу контента (асинхронно)
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      final limits = await _usageLimitsService.getCurrentUsage();
      return limits.getCountForType(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования: $e');
      }
      return 0;
    }
  }

  /// Синхронная версия для совместимости с существующим кодом
  int getCurrentUsageSync(ContentType contentType) {
    try {
      final limits = _usageLimitsService.currentLimits;
      if (limits == null) return 0;

      return limits.getCountForType(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования (sync): $e');
      }
      return 0;
    }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения лимита: $e');
      }
      return SubscriptionConstants.getContentLimit(contentType);
    }
  }

  /// Увеличение счетчика использования
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Если премиум (включая тестовые аккаунты) - не увеличиваем счетчик
      if (hasPremiumAccess()) {
        return true;
      }

      // Проверяем возможность создания контента перед увеличением
      if (!await canCreateContent(contentType)) {
        return false;
      }

      // Используем UsageLimitsService для увеличения счетчика
      return await _usageLimitsService.incrementUsage(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика использования: $e');
      }
      return false;
    }
  }

  /// Уменьшение счетчика (при удалении контента)
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      // Используем UsageLimitsService для уменьшения счетчика
      return await _usageLimitsService.decrementUsage(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения счетчика использования: $e');
      }
      return false;
    }
  }

  /// Сброс использования по типу (для админских целей)
  Future<void> resetUsage(ContentType contentType) async {
    try {
      // Используем новый метод из UsageLimitsService
      await _usageLimitsService.resetUsageForType(contentType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса использования: $e');
      }
    }
  }

  /// Получение информации об использовании для UI (асинхронно)
  Future<Map<ContentType, Map<String, int>>> getUsageInfo() async {
    try {
      final result = <ContentType, Map<String, int>>{};

      for (final contentType in ContentType.values) {
        result[contentType] = {
          'current': await getCurrentUsage(contentType),
          'limit': getLimit(contentType),
        };
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения информации об использовании: $e');
      }
      return {};
    }
  }

  /// Синхронная версия getUsageInfo для совместимости
  Map<ContentType, Map<String, int>> getUsageInfoSync() {
    try {
      final result = <ContentType, Map<String, int>>{};

      for (final contentType in ContentType.values) {
        result[contentType] = {
          'current': getCurrentUsageSync(contentType),
          'limit': getLimit(contentType),
        };
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения информации об использовании (sync): $e');
      }
      return {};
    }
  }

  /// Получение статистики использования
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      return await _usageLimitsService.getUsageStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики: $e');
      }
      return {};
    }
  }

  /// Принудительное обновление данных лимитов
  Future<void> refreshUsageLimits() async {
    try {
      await _usageLimitsService.forceRefresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления лимитов: $e');
      }
    }
  }

  /// Загрузка текущей подписки пользователя
  Future<SubscriptionModel> loadCurrentSubscription() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        _cachedSubscription = SubscriptionModel.defaultSubscription('');
        _subscriptionStatusController.add(_cachedSubscription!.status);
        return _cachedSubscription!;
      }

      // Если тестовый аккаунт - создаем премиум подписку
      if (_isTestAccount()) {
        if (kDebugMode) {
          debugPrint('🧪 Создаем премиум подписку для тестового аккаунта');
        }
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

      // Пытаемся загрузить из Firebase
      if (await NetworkUtils.isNetworkAvailable()) {
        final doc = await _firestore
            .collection(SubscriptionConstants.subscriptionCollection)
            .doc(userId)
            .get();

        if (doc.exists && doc.data() != null) {
          _cachedSubscription = SubscriptionModel.fromMap(doc.data()!, userId);
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки подписки: $e');
      }
      final userId = _firebaseService.currentUserId ?? '';
      _cachedSubscription = SubscriptionModel.defaultSubscription(userId);
      _subscriptionStatusController.add(_cachedSubscription!.status);
      return _cachedSubscription!;
    }
  }

  /// Получение доступных продуктов подписки
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Загрузка доступных продуктов...');
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        SubscriptionConstants.subscriptionProductIds.toSet(),
      );

      if (response.error != null) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка загрузки продуктов: ${response.error}');
        }
        return [];
      }

      if (kDebugMode) {
        debugPrint('✅ Загружено продуктов: ${response.productDetails.length}');
        for (final product in response.productDetails) {
          debugPrint('📦 Продукт: ${product.id} - ${product.price} ${product.currencyCode}');
        }
      }

      return response.productDetails;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения продуктов: $e');
      }
      return [];
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription(String productId) async {
    try {
      if (kDebugMode) {
        debugPrint('🛒 Начинаем покупку: $productId');
      }

      // Получаем детали продукта
      final products = await getAvailableProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        if (kDebugMode) {
          debugPrint('❌ Продукт не найден: $productId');
        }
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

      if (kDebugMode) {
        debugPrint('🛒 Покупка запущена: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка покупки: $e');
      }
      return false;
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Восстановление покупок...');
      }
      await _inAppPurchase.restorePurchases();
      if (kDebugMode) {
        debugPrint('✅ Восстановление покупок запущено');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка восстановления покупок: $e');
      }
    }
  }

  /// Обработка обновлений покупок
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    if (kDebugMode) {
      debugPrint('🔄 Обработка обновлений покупок: ${purchaseDetailsList.length}');
    }

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        debugPrint('💳 Обработка покупки: ${purchaseDetails.productID} - ${purchaseDetails.status}');
      }

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
        if (kDebugMode) {
          debugPrint('✅ Покупка завершена: ${purchaseDetails.productID}');
        }
      }
    }
  }

  /// Обработка ожидающей покупки
  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      debugPrint('⏳ Покупка в ожидании: ${purchaseDetails.productID}');
    }

    // Обновляем статус в Firebase
    await _updateSubscriptionStatus(
      purchaseDetails,
      SubscriptionStatus.pending,
    );
  }

  /// Обработка успешной покупки
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      debugPrint('✅ Успешная покупка: ${purchaseDetails.productID}');
    }

    try {
      // Проверяем валидность покупки (опционально)
      if (await _validatePurchase(purchaseDetails)) {
        await _updateSubscriptionStatus(
          purchaseDetails,
          SubscriptionStatus.active,
        );

        if (kDebugMode) {
          debugPrint('🎉 Подписка активирована: ${purchaseDetails.productID}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Покупка не прошла валидацию: ${purchaseDetails.productID}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обработки успешной покупки: $e');
      }
    }
  }

  /// Обработка восстановленной покупки
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      debugPrint('🔄 Восстановлена покупка: ${purchaseDetails.productID}');
    }

    // Проверяем, не истекла ли подписка
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
    if (kDebugMode) {
      debugPrint('❌ Неудачная покупка: ${purchaseDetails.productID}');
      debugPrint('❌ Ошибка: ${purchaseDetails.error}');
    }

    // Можно показать пользователю сообщение об ошибке
  }

  /// Обработка отмененной покупки
  Future<void> _handleCanceledPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      debugPrint('🚫 Покупка отменена: ${purchaseDetails.productID}');
    }

    // Пользователь отменил покупку - ничего не делаем
  }

  /// Обновление статуса подписки в Firebase
  Future<void> _updateSubscriptionStatus(
      PurchaseDetails purchaseDetails,
      SubscriptionStatus status,
      ) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return;

      final subscriptionType = SubscriptionConstants.getSubscriptionType(purchaseDetails.productID);
      if (subscriptionType == null) return;

      // Вычисляем дату истечения
      DateTime? expirationDate;
      if (status == SubscriptionStatus.active) {
        expirationDate = _calculateExpirationDate(subscriptionType);
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

      // Сохраняем в Firebase
      if (await NetworkUtils.isNetworkAvailable()) {
        await _firestore
            .collection(SubscriptionConstants.subscriptionCollection)
            .doc(userId)
            .set(subscription.toMap(), SetOptions(merge: true));
      }

      // Сохраняем в кэш
      await _saveToCache(subscription);
      _cachedSubscription = subscription;

      // Отправляем в стримы
      _subscriptionController.add(subscription);
      _subscriptionStatusController.add(subscription.status);

      if (kDebugMode) {
        debugPrint('✅ Статус подписки обновлен: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления статуса подписки: $e');
      }
    }
  }

  /// Валидация покупки (базовая проверка)
  Future<bool> _validatePurchase(PurchaseDetails purchaseDetails) async {
    // Здесь можно добавить серверную валидацию покупки
    // Пока что просто проверяем, что есть ID продукта
    return purchaseDetails.productID.isNotEmpty;
  }

  /// Проверка валидности подписки
  Future<bool> _isSubscriptionStillValid(PurchaseDetails purchaseDetails) async {
    // Здесь можно добавить проверку с сервером магазина
    // Пока что считаем что подписка валидна
    return true;
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

  /// Сохранение подписки в локальный кэш
  Future<void> _saveToCache(SubscriptionModel subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SubscriptionConstants.cachedSubscriptionStatusKey,
        subscription.status.name,
      );
      await prefs.setString(
        SubscriptionConstants.cachedPlanTypeKey,
        subscription.type?.name ?? '',
      );
      if (subscription.expirationDate != null) {
        await prefs.setString(
          SubscriptionConstants.cachedExpirationDateKey,
          subscription.expirationDate!.toIso8601String(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения в кэш: $e');
      }
    }
  }

  /// Загрузка подписки из локального кэша
  Future<SubscriptionModel> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final statusString = prefs.getString(SubscriptionConstants.cachedSubscriptionStatusKey);
      final typeString = prefs.getString(SubscriptionConstants.cachedPlanTypeKey);
      final expirationString = prefs.getString(SubscriptionConstants.cachedExpirationDateKey);

      if (statusString == null) {
        return SubscriptionModel.defaultSubscription(userId);
      }

      final status = SubscriptionStatus.values
          .where((s) => s.name == statusString)
          .firstOrNull ?? SubscriptionStatus.none;

      final type = typeString != null && typeString.isNotEmpty
          ? SubscriptionType.values
          .where((t) => t.name == typeString)
          .firstOrNull
          : null;

      final expirationDate = expirationString != null
          ? DateTime.tryParse(expirationString)
          : null;

      final now = DateTime.now();
      final isActive = status == SubscriptionStatus.active &&
          expirationDate != null &&
          now.isBefore(expirationDate);

      return SubscriptionModel(
        userId: userId,
        status: isActive ? status : SubscriptionStatus.expired,
        type: type,
        expirationDate: expirationDate,
        purchaseToken: '',
        platform: Platform.isAndroid
            ? SubscriptionConstants.androidPlatform
            : SubscriptionConstants.iosPlatform,
        createdAt: now,
        updatedAt: now,
        isActive: isActive,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки из кэша: $e');
      }
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