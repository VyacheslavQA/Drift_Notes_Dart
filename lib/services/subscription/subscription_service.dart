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
import '../../models/usage_limits_models.dart'; // 🆕 ДОБАВЛЕНО
import '../../models/offline_usage_result.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/isar_service.dart';
import '../../repositories/user_usage_limits_repository.dart'; // 🆕 ДОБАВЛЕНО
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

  // 🆕 ДОБАВЛЕНО: Repository для работы с лимитами пользователя
  final UserUsageLimitsRepository _usageLimitsRepository = UserUsageLimitsRepository.instance;

  // Офлайн сторадж для кэширования (только для подписок, не для заметок)
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Кэш текущей подписки
  SubscriptionModel? _cachedSubscription;

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
  // ИНИЦИАЛИЗАЦИЯ
  // ========================================

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением об инициализации

      // Проверяем что FirebaseService установлен
      if (_firebaseService == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неустановленном FirebaseService
        return;
      }

      // Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

      // Проверяем доступность покупок
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        // ✅ УБРАНО: debugPrint с сообщением о недоступности In-App Purchase
        return;
      }

      // Подписываемся на изменения покупок
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {
          // ✅ УБРАНО: debugPrint о закрытии purchase stream
        },
        onError: (error) {
          // ✅ УБРАНО: debugPrint с деталями ошибки в purchase stream
        },
      );

      // Загружаем текущую подписку
      await loadCurrentSubscription();

      // Восстанавливаем покупки при инициализации
      await restorePurchases();

      // 🆕 ИСПРАВЛЕНО: Инициализируем систему лимитов через Repository
      await _initializeUsageLimitsRepository();


      // ✅ УБРАНО: debugPrint с подтверждением инициализации
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки инициализации
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Инициализация системы лимитов через Repository
  Future<void> _initializeUsageLimitsRepository() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением об инициализации системы лимитов

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе
        return;
      }

      // Загружаем текущие лимиты через Repository
      final limits = await _usageLimitsRepository.getUserLimits(userId);

      if (limits != null) {
        // ✅ УБРАНО: debugPrint с информацией о загруженных лимитах пользователя
      } else {
        // ✅ УБРАНО: debugPrint о создании начальных лимитов для нового пользователя

        // Создаем лимиты по умолчанию и сохраняем через Repository
        final defaultLimits = UsageLimitsModel.defaultLimits(userId);
        await _usageLimitsRepository.saveUserLimits(defaultLimits);
      }

      // ✅ УБРАНО: debugPrint с подтверждением инициализации системы лимитов
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки инициализации системы лимитов
    }
  }

  // ========================================
  // 🆕 ИСПРАВЛЕННЫЕ МЕТОДЫ ПРОВЕРКИ ЛИМИТОВ (ТЕПЕРЬ ИСПОЛЬЗУЮТ REPOSITORY)
  // ========================================

  /// 🆕 ИСПРАВЛЕНО: Основной метод проверки возможности создания контента через Repository
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
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Используем Repository для проверки лимитов
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      // ✅ УБРАНО: debugPrint с деталями проверки (contentType, canCreate, currentCount, limit)

      return result.canCreate;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки проверки возможности создания контента
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Офлайн проверка создания контента через Repository
  Future<bool> canCreateContentOffline(ContentType contentType) async {
    try {
      // 1. Проверка тестового аккаунта - безлимитный доступ
      if (_isTestAccount()) {
        // ✅ УБРАНО: debugPrint с информацией о тестовом аккаунте
        return true;
      }

      // 2. Проверка кэшированного премиум статуса
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      if (cachedSubscription?.isPremium == true) {
        if (await _offlineStorage.isSubscriptionCacheValid()) {
          // ✅ УБРАНО: debugPrint с информацией о кэшированном премиум статусе
          return true;
        }
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе для офлайн проверки
        return false;
      }

      // 3. 🆕 ИСПРАВЛЕНО: Используем Repository для офлайн проверки
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      // ✅ УБРАНО: debugPrint с деталями офлайн проверки (contentType, canCreate, currentCount, limit)

      return result.canCreate;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки проверки офлайн создания контента
      // При ошибке разрешаем создание (принцип "fail open")
      return true;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Получение детальной информации о статусе использования через Repository
  Future<OfflineUsageResult> checkOfflineUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        return _getErrorUsageResult(contentType);
      }

      // 🆕 ИСПРАВЛЕНО: Получаем результат через Repository
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

      // ✅ УБРАНО: debugPrint с деталями проверки офлайн использования

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
      // ✅ УБРАНО: debugPrint с деталями ошибки проверки офлайн использования
      return _getErrorUsageResult(contentType);
    }
  }

  /// 🆕 ВСПОМОГАТЕЛЬНЫЙ: Создание результата при ошибке
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
  // 🆕 ИСПРАВЛЕННЫЕ МЕТОДЫ РАБОТЫ СО СЧЕТЧИКАМИ (ЧЕРЕЗ REPOSITORY)
  // ========================================

  /// 🆕 ИСПРАВЛЕНО: Увеличение счетчика использования через Repository
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Тестовые аккаунты Google Play - безлимитный доступ БЕЗ счетчиков
      if (_isTestAccount()) {
        // ✅ УБРАНО: debugPrint с информацией о пропуске увеличения счетчика для тестового аккаунта
        return true;
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе для увеличения счетчика
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Увеличиваем счетчик через Repository
      await _usageLimitsRepository.incrementCounter(userId, contentType);

      // ✅ УБРАНО: debugPrint с подтверждением увеличения счетчика через Repository
      return true;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки увеличения счетчика использования
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Уменьшение счетчика использования через Repository
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе для уменьшения счетчика
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Уменьшаем счетчик через Repository
      await _usageLimitsRepository.decrementCounter(userId, contentType);

      // ✅ УБРАНО: debugPrint с подтверждением уменьшения счетчика через Repository
      return true;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки уменьшения счетчика использования
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Сброс использования по типу через Repository
  Future<void> resetUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе для сброса счетчика
        return;
      }

      // Сбрасываем все счетчики через Repository
      await _usageLimitsRepository.resetAllCounters(userId);

      // ✅ УБРАНО: debugPrint с подтверждением сброса всех счетчиков через Repository
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки сброса использования
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Получение информации об использовании через Repository
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
      // ✅ УБРАНО: debugPrint с деталями ошибки получения информации об использовании
      return {};
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Получение статистики использования через Repository
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {'exists': false, 'error': 'User not authenticated'};

      // 🆕 ИСПРАВЛЕНО: Получаем статистику через Repository
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
      // ✅ УБРАНО: debugPrint с деталями ошибки получения статистики использования
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// 🆕 НОВОЕ: Получение текущего использования через Repository
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return 0;

      final stats = await _usageLimitsRepository.getStatsForType(userId, contentType);
      return stats['current'] ?? 0;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения текущего использования
      return 0;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Полный пересчет лимитов через Repository с правильной фильтрацией по пользователю
  Future<void> recalculateUsageLimits() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        // ✅ УБРАНО: debugPrint с предупреждением о неавторизованном пользователе для пересчета лимитов
        return;
      }

      // ✅ УБРАНО: debugPrint с информацией о пересчете лимитов для пользователя

      // 🔥 ИСПРАВЛЕНО: Получаем реальное количество заметок с фильтрацией по пользователю
      final fishingNotesCount = await _isarService.getFishingNotesCountByUser(userId);
      final markerMapsCount = await _isarService.getMarkerMapsCountByUser(userId);
      final budgetNotesCount = await _isarService.getBudgetNotesCountByUser(userId);

      // ✅ УБРАНО: debugPrint с реальными подсчетами по типам

      // Пересчитываем через Repository
      await _usageLimitsRepository.recalculateCounters(
        userId,
        notesCount: fishingNotesCount,
        markerMapsCount: markerMapsCount,
        budgetNotesCount: budgetNotesCount,
        recalculationType: 'subscription_service_recalculate',
      );

      // ✅ УБРАНО: debugPrint с результатами пересчета лимитов
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки пересчета лимитов
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
    }
  }

  /// Проверка премиум доступа с учетом тестовых аккаунтов
  bool hasPremiumAccess() {
    // Проверяем тестовый аккаунт ПЕРВЫМ
    if (_isTestAccount()) {
      // ✅ УБРАНО: debugPrint с информацией о полном премиум доступе тестового аккаунта
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
      // ✅ УБРАНО: debugPrint с деталями ошибки получения лимита
      return SubscriptionConstants.getContentLimit(contentType);
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Проверка необходимости показа предупреждения о лимите через Repository
  Future<bool> shouldShowLimitWarning(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return false;

      final warnings = await _usageLimitsRepository.getContentWarnings(userId);
      return warnings.any((warning) => warning.contentType == contentType);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки проверки необходимости предупреждения
      return false;
    }
  }

  /// Проверка необходимости показа диалога премиум
  Future<bool> shouldShowPremiumDialog(ContentType contentType) async {
    try {
      final result = await checkOfflineUsage(contentType);
      return result.shouldShowPremiumDialog;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки проверки необходимости диалога премиум
      return false;
    }
  }

  // ========================================
  // 🆕 ИСПРАВЛЕННОЕ КЭШИРОВАНИЕ И ОФЛАЙН МЕТОДЫ (ЧЕРЕЗ REPOSITORY)
  // ========================================

  /// 🆕 ИСПРАВЛЕНО: Кэширование данных подписки через Repository
  Future<void> cacheSubscriptionDataOnline() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением о кэшировании данных подписки

      // Проверяем доступность сети
      if (!await NetworkUtils.isNetworkAvailable()) {
        // ✅ УБРАНО: debugPrint с предупреждением об отсутствии сети
        return;
      }

      // Загружаем актуальную подписку
      final subscription = await loadCurrentSubscription();

      // Кэшируем подписку
      await _offlineStorage.cacheSubscriptionStatus(subscription);
      // ✅ УБРАНО: debugPrint с подтверждением кэширования статуса подписки

      // 🆕 ИСПРАВЛЕНО: Кэшируем лимиты через Repository
      try {
        final userId = firebaseService.currentUserId;
        if (userId != null) {
          final limits = await _usageLimitsRepository.getUserLimits(userId);
          if (limits != null) {
            await _offlineStorage.cacheUsageLimits(limits);
            // ✅ УБРАНО: debugPrint с подтверждением кэширования лимитов пользователя через Repository
          }
        }
      } catch (e) {
        // ✅ УБРАНО: debugPrint с деталями ошибки кэширования лимитов через Repository
      }

      // ✅ УБРАНО: debugPrint с подтверждением успешного кэширования данных подписки
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки кэширования данных подписки
    }
  }

  /// Принудительное обновление кэша подписки
  Future<void> refreshSubscriptionCache() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением об обновлении кэша подписки

      await cacheSubscriptionDataOnline();

      // ✅ УБРАНО: debugPrint с подтверждением обновления кэша подписки
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки обновления кэша подписки
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
      // ✅ УБРАНО: debugPrint с деталями ошибки получения информации о кэше подписки
      return {
        'hasCachedSubscription': false,
        'isPremium': false,
        'isCacheValid': false,
      };
    }
  }

  /// 🆕 НОВОЕ: Получение отладочной информации о лимитах через Repository
  Future<Map<String, dynamic>> getUsageLimitsDebugInfo() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return {'error': 'User not authenticated'};

      return await _usageLimitsRepository.getDebugInfo(userId);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения отладочной информации о лимитах
      return {'error': e.toString()};
    }
  }

  /// Очистка локальных счетчиков (теперь через Repository)
  Future<void> clearLocalCounters() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return;

      // 🆕 ИСПРАВЛЕНО: Очищаем через Repository
      await _usageLimitsRepository.resetAllCounters(userId);

      // ✅ УБРАНО: debugPrint с подтверждением очистки локальных счетчиков через Repository
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки очистки локальных счетчиков
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Получение всех локальных счетчиков через Repository
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
      // ✅ УБРАНО: debugPrint с деталями ошибки получения локальных счетчиков
      return {};
    }
  }

  // ========================================
  // УПРАВЛЕНИЕ ПОДПИСКАМИ (Остальные методы без изменений)
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
        // ✅ УБРАНО: debugPrint о создании премиум подписки для тестового аккаунта
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
      // ✅ УБРАНО: debugPrint с деталями ошибки загрузки подписки
      final userId = firebaseService.currentUserId ?? '';
      _cachedSubscription = SubscriptionModel.defaultSubscription(userId);
      _subscriptionStatusController.add(_cachedSubscription!.status);
      return _cachedSubscription!;
    }
  }

  /// Получение доступных продуктов подписки
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением о загрузке доступных продуктов

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        SubscriptionConstants.subscriptionProductIds.toSet(),
      );

      if (response.error != null) {
        // ✅ УБРАНО: debugPrint с деталями ошибки загрузки продуктов
        return [];
      }

      // ✅ УБРАНО: debugPrint с количеством загруженных продуктов

      return response.productDetails;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения продуктов
      return [];
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription(String productId) async {
    try {
      // ✅ УБРАНО: debugPrint с информацией о начале покупки

      // Получаем детали продукта
      final products = await getAvailableProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        // ✅ УБРАНО: debugPrint с сообщением о ненайденном продукте
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

      // ✅ УБРАНО: debugPrint с результатом запуска покупки
      return success;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки покупки
      return false;
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением о восстановлении покупок
      await _inAppPurchase.restorePurchases();
      // ✅ УБРАНО: debugPrint с подтверждением запуска восстановления покупок
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки восстановления покупок
    }
  }

  /// Обработка обновлений покупок
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    // ✅ УБРАНО: debugPrint с количеством обновлений покупок

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      // ✅ УБРАНО: debugPrint с деталями обработки покупки (productID, status)

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
        // ✅ УБРАНО: debugPrint с подтверждением завершения покупки
      }
    }
  }

  /// Обработка ожидающей покупки
  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    // ✅ УБРАНО: debugPrint с информацией о покупке в ожидании

    await _updateSubscriptionStatus(
      purchaseDetails,
      SubscriptionStatus.pending,
    );
  }

  /// Обработка успешной покупки
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // ✅ УБРАНО: debugPrint с информацией об успешной покупке

    try {
      if (await _validatePurchase(purchaseDetails)) {
        await _updateSubscriptionStatus(
          purchaseDetails,
          SubscriptionStatus.active,
        );

        // ✅ УБРАНО: debugPrint с подтверждением активации подписки
      } else {
        // ✅ УБРАНО: debugPrint с сообщением о непрошедшей валидации покупки
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки обработки успешной покупки
    }
  }

  /// Обработка восстановленной покупки
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    // ✅ УБРАНО: debugPrint с информацией о восстановленной покупке

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
    // ✅ УБРАНО: debugPrint с информацией о неудачной покупке и деталями ошибки
  }

  /// Обработка отмененной покупки
  Future<void> _handleCanceledPurchase(PurchaseDetails purchaseDetails) async {
    // ✅ УБРАНО: debugPrint с информацией об отмененной покупке
  }

  /// Обновление статуса подписки в Firebase
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
        'platform': Platform.isAndroid
            ? SubscriptionConstants.androidPlatform
            : SubscriptionConstants.iosPlatform,
        'createdAt': _cachedSubscription?.createdAt != null
            ? Timestamp.fromDate(_cachedSubscription!.createdAt)
            : FieldValue.serverTimestamp(),
        'isActive': status == SubscriptionStatus.active &&
            expirationDate != null &&
            DateTime.now().isBefore(expirationDate),
      };

      // Сохраняем через FirebaseService
      if (await NetworkUtils.isNetworkAvailable()) {
        await firebaseService.updateUserSubscription(subscriptionData);
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

      // ✅ УБРАНО: debugPrint с подтверждением обновления статуса подписки
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки обновления статуса подписки
    }
  }

  /// Валидация покупки
  Future<bool> _validatePurchase(PurchaseDetails purchaseDetails) async {
    return purchaseDetails.productID.isNotEmpty;
  }

  /// Проверка валидности подписки
  Future<bool> _isSubscriptionStillValid(PurchaseDetails purchaseDetails) async {
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

  /// Сохранение подписки в кэш только через OfflineStorageService
  Future<void> _saveToCache(SubscriptionModel subscription) async {
    try {
      await _offlineStorage.cacheSubscriptionStatus(subscription);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки сохранения в кэш
    }
  }

  /// Загрузка подписки из кэша только через OfflineStorageService
  Future<SubscriptionModel> _loadFromCache(String userId) async {
    try {
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      return cachedSubscription ?? SubscriptionModel.defaultSubscription(userId);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки загрузки из кэша
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