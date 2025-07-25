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
      if (kDebugMode) {
        debugPrint('🔄 Инициализация SubscriptionService...');
      }

      // Проверяем что FirebaseService установлен
      if (_firebaseService == null) {
        if (kDebugMode) {
          debugPrint('⚠️ FirebaseService не установлен, пропускаем инициализацию SubscriptionService');
        }
        return;
      }

      // Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

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

      // 🆕 ИСПРАВЛЕНО: Инициализируем систему лимитов через Repository
      await _initializeUsageLimitsRepository();


      if (kDebugMode) {
        debugPrint('✅ SubscriptionService инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации SubscriptionService: $e');
      }
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Инициализация системы лимитов через Repository
  Future<void> _initializeUsageLimitsRepository() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Инициализация системы лимитов через Repository...');
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для инициализации лимитов');
        }
        return;
      }

      // Загружаем текущие лимиты через Repository
      final limits = await _usageLimitsRepository.getUserLimits(userId);

      if (limits != null) {
        if (kDebugMode) {
          debugPrint('📊 Лимиты пользователя загружены через Repository: $limits');
        }
      } else {
        if (kDebugMode) {
          debugPrint('📊 Создаем начальные лимиты для нового пользователя через Repository');
        }

        // Создаем лимиты по умолчанию и сохраняем через Repository
        final defaultLimits = UsageLimitsModel.defaultLimits(userId);
        await _usageLimitsRepository.saveUserLimits(defaultLimits);
      }

      if (kDebugMode) {
        debugPrint('✅ Система лимитов инициализирована через Repository');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации системы лимитов через Repository: $e');
      }
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
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для проверки лимитов');
        }
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Используем Repository для проверки лимитов
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      if (kDebugMode) {
        debugPrint('🔍 canCreateContent: $contentType, canCreate=${result.canCreate}, current=${result.currentCount}, limit=${result.limit}');
      }

      return result.canCreate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      }
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Офлайн проверка создания контента через Repository
  Future<bool> canCreateContentOffline(ContentType contentType) async {
    try {
      // 1. Проверка тестового аккаунта - безлимитный доступ
      if (_isTestAccount()) {
        if (kDebugMode) {
          debugPrint('🧪 Тестовый аккаунт - безлимитный доступ к $contentType');
        }
        return true;
      }

      // 2. Проверка кэшированного премиум статуса
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      if (cachedSubscription?.isPremium == true) {
        if (await _offlineStorage.isSubscriptionCacheValid()) {
          if (kDebugMode) {
            debugPrint('🔥 Кэшированный премиум статус действителен - разрешаем $contentType');
          }
          return true;
        }
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для офлайн проверки лимитов');
        }
        return false;
      }

      // 3. 🆕 ИСПРАВЛЕНО: Используем Repository для офлайн проверки
      final result = await _usageLimitsRepository.canCreateContent(userId, contentType);

      if (kDebugMode) {
        debugPrint('🔍 canCreateContentOffline: $contentType, canCreate=${result.canCreate}, current=${result.currentCount}, limit=${result.limit}');
      }

      return result.canCreate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн создания контента: $e');
      }
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

      if (kDebugMode) {
        debugPrint('🔍 checkOfflineUsage: $contentType, current=${result.currentCount}, limit=${result.limit}, remaining=${result.remaining}, canCreate=${result.canCreate}');
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн использования: $e');
      }
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
        if (kDebugMode) {
          debugPrint('🧪 Тестовый аккаунт - пропускаем увеличение счетчика для $contentType');
        }
        return true;
      }

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для увеличения счетчика');
        }
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Увеличиваем счетчик через Repository
      await _usageLimitsRepository.incrementCounter(userId, contentType);

      if (kDebugMode) {
        debugPrint('✅ incrementUsage: счетчик $contentType увеличен через Repository');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика использования: $e');
      }
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Уменьшение счетчика использования через Repository
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для уменьшения счетчика');
        }
        return false;
      }

      // 🆕 ИСПРАВЛЕНО: Уменьшаем счетчик через Repository
      await _usageLimitsRepository.decrementCounter(userId, contentType);

      if (kDebugMode) {
        debugPrint('✅ decrementUsage: счетчик $contentType уменьшен через Repository');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения счетчика использования: $e');
      }
      return false;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Сброс использования по типу через Repository
  Future<void> resetUsage(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для сброса счетчика');
        }
        return;
      }

      // Сбрасываем все счетчики через Repository
      await _usageLimitsRepository.resetAllCounters(userId);

      if (kDebugMode) {
        debugPrint('✅ Сброшены все счетчики через Repository');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса использования: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения информации об использовании: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики использования: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования: $e');
      }
      return 0;
    }
  }

  /// 🆕 ИСПРАВЛЕНО: Полный пересчет лимитов через Repository с правильной фильтрацией по пользователю
  Future<void> recalculateUsageLimits() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован для пересчета лимитов');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Пересчет лимитов для пользователя: $userId');
      }

      // 🔥 ИСПРАВЛЕНО: Получаем реальное количество заметок с фильтрацией по пользователю
      final fishingNotesCount = await _isarService.getFishingNotesCountByUser(userId);
      final markerMapsCount = await _isarService.getMarkerMapsCountByUser(userId);
      final budgetNotesCount = await _isarService.getBudgetNotesCountByUser(userId);

      if (kDebugMode) {
        debugPrint('📊 Реальные подсчеты: fishing=$fishingNotesCount, maps=$markerMapsCount, budget=$budgetNotesCount');
      }

      // Пересчитываем через Repository
      await _usageLimitsRepository.recalculateCounters(
        userId,
        notesCount: fishingNotesCount,
        markerMapsCount: markerMapsCount,
        budgetNotesCount: budgetNotesCount,
        recalculationType: 'subscription_service_recalculate',
      );

      if (kDebugMode) {
        debugPrint('✅ Лимиты пересчитаны: fishing=$fishingNotesCount, maps=$markerMapsCount, budget=$budgetNotesCount');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка пересчета лимитов: $e');
      }
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
      if (kDebugMode) {
        debugPrint('🧪 Тестовый аккаунт имеет полный премиум доступ');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения лимита: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки необходимости предупреждения: $e');
      }
      return false;
    }
  }

  /// Проверка необходимости показа диалога премиум
  Future<bool> shouldShowPremiumDialog(ContentType contentType) async {
    try {
      final result = await checkOfflineUsage(contentType);
      return result.shouldShowPremiumDialog;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки необходимости диалога премиум: $e');
      }
      return false;
    }
  }

  // ========================================
  // 🆕 ИСПРАВЛЕННОЕ КЭШИРОВАНИЕ И ОФЛАЙН МЕТОДЫ (ЧЕРЕЗ REPOSITORY)
  // ========================================

  /// 🆕 ИСПРАВЛЕНО: Кэширование данных подписки через Repository
  Future<void> cacheSubscriptionDataOnline() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Кэширование данных подписки онлайн через Repository...');
      }

      // Проверяем доступность сети
      if (!await NetworkUtils.isNetworkAvailable()) {
        if (kDebugMode) {
          debugPrint('⚠️ Нет сети - пропускаем кэширование');
        }
        return;
      }

      // Загружаем актуальную подписку
      final subscription = await loadCurrentSubscription();

      // Кэшируем подписку
      await _offlineStorage.cacheSubscriptionStatus(subscription);
      if (kDebugMode) {
        debugPrint('✅ Статус подписки кэширован');
      }

      // 🆕 ИСПРАВЛЕНО: Кэшируем лимиты через Repository
      try {
        final userId = firebaseService.currentUserId;
        if (userId != null) {
          final limits = await _usageLimitsRepository.getUserLimits(userId);
          if (limits != null) {
            await _offlineStorage.cacheUsageLimits(limits);
            if (kDebugMode) {
              debugPrint('✅ Лимиты пользователя кэшированы через Repository: $limits');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка кэширования лимитов через Repository: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Данные подписки успешно кэшированы через Repository');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка кэширования данных подписки: $e');
      }
    }
  }

  /// Принудительное обновление кэша подписки
  Future<void> refreshSubscriptionCache() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Обновление кэша подписки...');
      }

      await cacheSubscriptionDataOnline();

      if (kDebugMode) {
        debugPrint('✅ Кэш подписки обновлен');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления кэша подписки: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения информации о кэше подписки: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения отладочной информации о лимитах: $e');
      }
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

      if (kDebugMode) {
        debugPrint('✅ Локальные счетчики очищены через Repository');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка очистки локальных счетчиков: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения локальных счетчиков: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки подписки: $e');
      }
      final userId = firebaseService.currentUserId ?? '';
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
  }

  /// Обработка отмененной покупки
  Future<void> _handleCanceledPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      debugPrint('🚫 Покупка отменена: ${purchaseDetails.productID}');
    }
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

      if (kDebugMode) {
        debugPrint('✅ Статус подписки обновлен: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления статуса подписки: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения в кэш: $e');
      }
    }
  }

  /// Загрузка подписки из кэша только через OfflineStorageService
  Future<SubscriptionModel> _loadFromCache(String userId) async {
    try {
      final cachedSubscription = await _offlineStorage.getCachedSubscriptionStatus();
      return cachedSubscription ?? SubscriptionModel.defaultSubscription(userId);
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