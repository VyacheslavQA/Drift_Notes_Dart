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
import '../../models/offline_usage_result.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/isar_service.dart'; // ✅ ДОБАВЛЕНО: Импорт IsarService
import '../../utils/network_utils.dart';

/// Сервис для управления подписками и покупками
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // FirebaseService инжектируется извне
  FirebaseService? _firebaseService;

  // ✅ ДОБАВЛЕНО: IsarService для работы с локальными данными
  final IsarService _isarService = IsarService.instance;

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

      // Инициализируем систему лимитов в новой Firebase структуре
      await _initializeUsageLimits();

      if (kDebugMode) {
        debugPrint('✅ SubscriptionService инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации SubscriptionService: $e');
      }
    }
  }

  /// Инициализация системы лимитов через новую Firebase структуре
  Future<void> _initializeUsageLimits() async {
    try {
      debugPrint('🔄 Инициализация системы лимитов через Firebase...');

      // Проверяем существует ли документ usage_limits для пользователя
      final usageLimitsDoc = await firebaseService.getUserUsageLimits();

      if (!usageLimitsDoc.exists) {
        debugPrint('📊 Создаем начальные лимиты для нового пользователя');
        // Автоматически создастся через getUserUsageLimits()
      } else {
        debugPrint('📊 Лимиты пользователя уже существуют');
      }

      debugPrint('✅ Система лимитов инициализирована');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации системы лимитов: $e');
    }
  }

  // ========================================
  // ✅ ИСПРАВЛЕННЫЕ МЕТОДЫ ПРОВЕРКИ ЛИМИТОВ (ТЕПЕРЬ ИСПОЛЬЗУЮТ ISAR)
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Основной метод проверки возможности создания контента
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

      // ✅ ИСПРАВЛЕНО: Используем новый метод с Isar
      final currentUsage = await getCurrentUsage(contentType);
      final limit = getLimit(contentType);

      final canCreate = currentUsage < limit;

      debugPrint('🔍 canCreateContentSync: $contentType, usage=$currentUsage, limit=$limit, canCreate=$canCreate');
      return canCreate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      }
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Офлайн проверка создания контента
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

      // 3. ✅ ИСПРАВЛЕНО: Используем новый метод правильного подсчета через Isar
      final currentUsage = await getCurrentUsage(contentType);
      final limit = getLimit(contentType);

      final canCreate = currentUsage < limit;

      debugPrint('🔍 canCreateContentOffline: $contentType, usage=$currentUsage, limit=$limit, canCreate=$canCreate');
      return canCreate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн создания контента: $e');
      }
      // При ошибке разрешаем создание (принцип "fail open")
      return true;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение детальной информации о статусе использования
  Future<OfflineUsageResult> checkOfflineUsage(ContentType contentType) async {
    try {
      // ✅ ИСПРАВЛЕНО: Используем правильный подсчет через Isar
      final currentUsage = await getCurrentUsage(contentType);
      final maxLimit = getLimit(contentType);
      final remaining = maxLimit - currentUsage;
      final canCreate = currentUsage < maxLimit;

      // Определяем тип предупреждения
      OfflineLimitWarningType warningType;
      String message;

      if (!canCreate) {
        warningType = OfflineLimitWarningType.blocked;
        message = 'Достигнут лимит ${_getContentTypeName(contentType)} ($maxLimit)';
      } else if (remaining <= 2) {
        warningType = OfflineLimitWarningType.warning;
        message = 'Осталось $remaining ${_getContentTypeName(contentType)}';
      } else {
        warningType = OfflineLimitWarningType.normal;
        message = 'Доступно $remaining ${_getContentTypeName(contentType)}';
      }

      debugPrint('🔍 checkOfflineUsage: $contentType, current=$currentUsage, limit=$maxLimit, remaining=$remaining, canCreate=$canCreate');

      return OfflineUsageResult(
        canCreate: canCreate,
        warningType: warningType,
        message: message,
        currentUsage: currentUsage,
        limit: maxLimit,
        remaining: remaining,
        contentType: contentType,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн использования: $e');
      }

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
  }

  // ========================================
  // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: ПРАВИЛЬНЫЙ ПОДСЧЕТ ЗАМЕТОК ЧЕРЕЗ ISAR
  // ========================================

  /// ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Получение текущего использования ЧЕРЕЗ ISAR
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      debugPrint('🔍 getCurrentUsage: начинаем подсчет для $contentType');

      final userId = firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('❌ getCurrentUsage: пользователь не авторизован');
        return 0;
      }

      final hasNetwork = await NetworkUtils.isNetworkAvailable();

      // ✅ ИСПРАВЛЕНО: В офлайн режиме используем ПРЯМОЙ подсчет из Isar
      if (!hasNetwork) {
        debugPrint('📱 getCurrentUsage: офлайн режим, считаем ПРЯМО из локальных данных...');
        return await _countDirectFromIsar(contentType, userId);
      }

      int totalCount = 0;

      // 1. ✅ ИСПРАВЛЕНО: Считаем РЕАЛЬНЫЕ заметки из Firebase subcollections
      try {
        int onlineCount = 0;

        switch (contentType) {
          case ContentType.fishingNotes:
            final snapshot = await firebaseService.getUserFishingNotesNew();
            onlineCount = snapshot.docs.length;
            break;
          case ContentType.markerMaps:
            final snapshot = await firebaseService.getUserMarkerMaps();
            onlineCount = snapshot.docs.length;
            break;
          case ContentType.budgetNotes:
            final snapshot = await firebaseService.getUserBudgetNotes();
            onlineCount = snapshot.docs.length;
            break;
          case ContentType.depthChart:
            onlineCount = 0; // Пока не реализовано
            break;
        }

        totalCount += onlineCount;
        debugPrint('📊 getCurrentUsage: онлайн $contentType = $onlineCount');
      } catch (e) {
        debugPrint('❌ getCurrentUsage: ошибка подсчета онлайн заметок: $e');
      }

      // 2. ✅ ИСПРАВЛЕНО: Считаем ТОЛЬКО не синхронизированные заметки из Isar
      try {
        int offlineCount = 0;

        switch (contentType) {
          case ContentType.fishingNotes:
            final unsyncedNotes = await _isarService.getUnsyncedNotes();
            offlineCount = unsyncedNotes.length;
            break;
          case ContentType.markerMaps:
            final unsyncedMaps = await _isarService.getUnsyncedMarkerMaps(userId);
            offlineCount = unsyncedMaps.length;
            break;
          case ContentType.budgetNotes:
            final unsyncedBudgetNotes = await _isarService.getUnsyncedBudgetNotes(userId);
            offlineCount = unsyncedBudgetNotes.length;
            break;
          case ContentType.depthChart:
            offlineCount = 0; // Пока не реализовано
            break;
        }

        totalCount += offlineCount;
        debugPrint('📊 getCurrentUsage: офлайн $contentType = $offlineCount');
      } catch (e) {
        debugPrint('❌ getCurrentUsage: ошибка подсчета офлайн заметок из Isar: $e');
      }

      debugPrint('✅ getCurrentUsage: итого $contentType = $totalCount');
      return totalCount;
    } catch (e) {
      debugPrint('❌ getCurrentUsage: критическая ошибка подсчета: $e');
      return 0;
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Прямой подсчет из Isar для офлайн режима
  Future<int> _countDirectFromIsar(ContentType contentType, String userId) async {
    try {
      debugPrint('📱 _countDirectFromLocalStorage: $contentType = подсчет начался');

      int totalCount = 0;

      // ✅ ИСПРАВЛЕНО: Считаем ВСЕ заметки из Isar (синхронизированные + не синхронизированные)
      switch (contentType) {
        case ContentType.fishingNotes:
          final allNotes = await _isarService.getAllFishingNotes();
          totalCount = allNotes.length;
          break;
        case ContentType.markerMaps:
          final allMaps = await _isarService.getAllMarkerMaps(userId);
          totalCount = allMaps.length;
          break;
        case ContentType.budgetNotes:
          final allBudgetNotes = await _isarService.getAllBudgetNotes(userId);
          totalCount = allBudgetNotes.length;
          break;
        case ContentType.depthChart:
          totalCount = 0; // Пока не реализовано
          break;
      }

      debugPrint('📱 _countDirectFromLocalStorage: $contentType = $totalCount');
      return totalCount;
    } catch (e) {
      debugPrint('❌ _countDirectFromLocalStorage: ошибка: $e');
      return 0;
    }
  }

  // ========================================
  // МЕТОДЫ РАБОТЫ СО СЧЕТЧИКАМИ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Увеличение счетчика использования (теперь не нужно, так как считаем реальные заметки)
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Тестовые аккаунты Google Play - безлимитный доступ БЕЗ счетчиков
      if (_isTestAccount()) {
        if (kDebugMode) {
          debugPrint('🧪 Тестовый аккаунт - пропускаем увеличение счетчика для $contentType');
        }
        return true;
      }

      // ✅ ИСПРАВЛЕНО: Теперь мы считаем реальные заметки из Isar, а не ведем счетчики
      debugPrint('✅ incrementUsage: счетчик $contentType (теперь считаем реальные заметки)');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика использования: $e');
      }
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Уменьшение счетчика использования (теперь не нужно)
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      // ✅ ИСПРАВЛЕНО: Теперь мы считаем реальные заметки, а не ведем счетчики
      debugPrint('✅ decrementUsage: счетчик $contentType (теперь считаем реальные заметки)');
      return true;
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
      await firebaseService.resetUserUsageLimits(resetReason: 'admin_reset_${contentType.name}');
      if (kDebugMode) {
        debugPrint('✅ Сброшен счетчик для типа: $contentType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса использования: $e');
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение информации об использовании через Isar
  Future<Map<ContentType, Map<String, int>>> getUsageInfo() async {
    try {
      final result = <ContentType, Map<String, int>>{};

      for (final contentType in ContentType.values) {
        final totalUsage = await getCurrentUsage(contentType);
        result[contentType] = {
          'current': totalUsage,
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

  /// ✅ ИСПРАВЛЕНО: Получение статистики использования через Isar
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      // ✅ ИСПРАВЛЕНО: Возвращаем реальные подсчеты через Isar вместо счетчиков Firebase
      final fishingNotesCount = await getCurrentUsage(ContentType.fishingNotes);
      final markerMapsCount = await getCurrentUsage(ContentType.markerMaps);
      final budgetNotesCount = await getCurrentUsage(ContentType.budgetNotes);

      return {
        SubscriptionConstants.notesCountField: fishingNotesCount,
        SubscriptionConstants.markerMapsCountField: markerMapsCount,
        SubscriptionConstants.budgetNotesCountField: budgetNotesCount,
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

  // ========================================
  // УТИЛИТЫ И ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Преобразование ContentType в строку для Firebase
  String _getFirebaseItemType(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.budgetNotes:
        return 'budgetNotesCount';
      case ContentType.depthChart:
        return 'depthChartCount';
    }
  }

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

  /// Проверка необходимости показа предупреждения о лимите
  Future<bool> shouldShowLimitWarning(ContentType contentType) async {
    try {
      final result = await checkOfflineUsage(contentType);
      return result.shouldShowWarning;
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
  // ✅ ИСПРАВЛЕННОЕ КЭШИРОВАНИЕ И ОФЛАЙН МЕТОДЫ
  // ========================================

  /// ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Кэширование данных подписки с правильным подсчетом через Isar
  Future<void> cacheSubscriptionDataOnline() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Кэширование данных подписки онлайн...');
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
      debugPrint('Статус подписки кэширован');

      // ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Создаем лимиты через прямой подсчет из Firebase
      try {
        final usageLimits = await _loadUsageLimitsDirectFromFirebase();
        if (usageLimits != null) {
          await _offlineStorage.cacheUsageLimits(usageLimits);
          debugPrint('Лимиты использования кэшированы');
          debugPrint('✅ Реальные счетчики заметок кэшированы');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка кэширования лимитов: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Данные подписки успешно кэшированы');
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

  /// 🔥 ИСПРАВЛЕНО: Прямая загрузка лимитов из Firebase БЕЗ рекурсии
  Future<UsageLimitsModel?> _loadUsageLimitsDirectFromFirebase() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return null;

      // ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Считаем НАПРЯМУЮ из Firebase БЕЗ вызова getCurrentUsage()
      int fishingNotesCount = 0;
      int markerMapsCount = 0;
      int budgetNotesCount = 0;

      try {
        // Прямые запросы к Firebase
        final fishingSnapshot = await firebaseService.getUserFishingNotesNew();
        fishingNotesCount = fishingSnapshot.docs.length;

        final mapsSnapshot = await firebaseService.getUserMarkerMaps();
        markerMapsCount = mapsSnapshot.docs.length;

        final budgetSnapshot = await firebaseService.getUserBudgetNotes();
        budgetNotesCount = budgetSnapshot.docs.length;
      } catch (e) {
        debugPrint('⚠️ Ошибка прямого подсчета из Firebase: $e');
      }

      debugPrint('📊 Прямой подсчет из Firebase: fishing=$fishingNotesCount, maps=$markerMapsCount, budget=$budgetNotesCount');

      return UsageLimitsModel(
        userId: userId,
        notesCount: fishingNotesCount,
        markerMapsCount: markerMapsCount,
        budgetNotesCount: budgetNotesCount,
        lastResetDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка прямой загрузки лимитов из Firebase: $e');
      }
      return null;
    }
  }

  /// Очистка локальных счетчиков (теперь не нужно, так как считаем из Isar)
  Future<void> clearLocalCounters() async {
    try {
      // ✅ ИСПРАВЛЕНО: Теперь не используем старые счетчики
      debugPrint('✅ Локальные счетчики не используются (считаем из Isar)');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка очистки локальных счетчиков: $e');
      }
    }
  }

  /// Получение всех локальных счетчиков (теперь из Isar)
  Future<Map<ContentType, int>> getAllLocalCounters() async {
    try {
      final result = <ContentType, int>{};

      for (final contentType in ContentType.values) {
        final count = await getCurrentUsage(contentType);
        result[contentType] = count;
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

  /// ✅ УПРОЩЕНО: Сохранение подписки в кэш только через OfflineStorageService
  Future<void> _saveToCache(SubscriptionModel subscription) async {
    try {
      await _offlineStorage.cacheSubscriptionStatus(subscription);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения в кэш: $e');
      }
    }
  }

  /// ✅ УПРОЩЕНО: Загрузка подписки из кэша только через OfflineStorageService
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