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
import '../../services/subscription/usage_limits_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../utils/network_utils.dart';

/// Сервис для управления подписками и покупками
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // ИСПРАВЛЕНО: FirebaseService теперь инжектируется извне
  FirebaseService? _firebaseService;
  final UsageLimitsService _usageLimitsService = UsageLimitsService();

  // 🔥 НОВОЕ: Офлайн сторадж для кэширования
  final OfflineStorageService _offlineStorage = OfflineStorageService();

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

  // Кэш для подсчета использования (чтобы не обращаться к Firebase каждый раз)
  Map<ContentType, int> _usageCache = {};
  DateTime? _lastUsageCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Стрим для прослушивания изменений подписки
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final StreamController<SubscriptionModel> _subscriptionController = StreamController<SubscriptionModel>.broadcast();

  // Стрим для статуса подписки (для совместимости)
  final StreamController<SubscriptionStatus> _subscriptionStatusController = StreamController<SubscriptionStatus>.broadcast();

  // Стрим для UI
  Stream<SubscriptionModel> get subscriptionStream => _subscriptionController.stream;

  // Стрим статуса подписки для совместимости с виджетами
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

  /// Проверка тестового аккаунта
  bool _isTestAccount() {
    try {
      final currentUser = firebaseService.currentUser;
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
      return firebaseService.currentUser?.email?.toLowerCase().trim();
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

      // Проверяем что FirebaseService установлен
      if (_firebaseService == null) {
        if (kDebugMode) {
          debugPrint('⚠️ FirebaseService не установлен, пропускаем инициализацию SubscriptionService');
        }
        return;
      }

      // 🔥 НОВОЕ: Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

      // Инициализируем UsageLimitsService (для совместимости, но не используем для подсчета)
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

      // Загружаем данные использования
      await _refreshUsageCache();

      if (kDebugMode) {
        debugPrint('✅ SubscriptionService инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации SubscriptionService: $e');
      }
    }
  }

  // 🔥 НОВЫЕ МЕТОДЫ для офлайн режима

  /// Основной метод проверки возможности создания контента офлайн
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
        // Проверяем актуальность кэша
        if (await _offlineStorage.isSubscriptionCacheValid()) {
          if (kDebugMode) {
            debugPrint('🔥 Кэшированный премиум статус действителен - разрешаем $contentType');
          }
          return true;
        }
      }

      // 3. Получаем текущее использование с учетом локальных счетчиков
      final currentUsage = await _getCurrentOfflineUsage(contentType);
      final limit = getLimit(contentType);

      // 4. ЖЕСТКАЯ ПРОВЕРКА: лимит + grace period
      if (currentUsage >= limit + SubscriptionConstants.offlineGraceLimit) {
        if (kDebugMode) {
          debugPrint('❌ Превышен лимит + grace period для $contentType: $currentUsage >= ${limit + SubscriptionConstants.offlineGraceLimit}');
        }
        return false; // Блокировка
      }

      if (kDebugMode) {
        debugPrint('✅ Разрешено создание $contentType: $currentUsage < ${limit + SubscriptionConstants.offlineGraceLimit}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн создания контента: $e');
      }
      // При ошибке разрешаем создание (принцип "fail open")
      return true;
    }
  }

  /// Получение детальной информации о статусе офлайн использования
  Future<OfflineUsageResult> checkOfflineUsage(ContentType contentType) async {
    try {
      final currentUsage = await _getCurrentOfflineUsage(contentType);
      final limit = getLimit(contentType);
      final canCreate = await canCreateContentOffline(contentType);

      final warningType = SubscriptionConstants.getWarningType(currentUsage, limit);
      final message = SubscriptionConstants.getLimitStatusMessage(currentUsage, limit, contentType);
      final remaining = SubscriptionConstants.getRemainingGraceElements(currentUsage, limit);

      return OfflineUsageResult(
        canCreate: canCreate,
        warningType: warningType,
        message: message,
        currentUsage: currentUsage,
        limit: limit,
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
        remaining: SubscriptionConstants.offlineGraceLimit,
        contentType: contentType,
      );
    }
  }

  /// Получение текущего использования с учетом локальных счетчиков
  Future<int> _getCurrentOfflineUsage(ContentType contentType) async {
    try {
      // Получаем серверное использование (из кэша)
      final serverUsage = await getCurrentUsage(contentType);

      // Получаем локальные счетчики
      final localUsage = await _offlineStorage.getLocalUsageCount(contentType);

      final totalUsage = serverUsage + localUsage;

      if (kDebugMode) {
        debugPrint('📊 Использование $contentType: сервер=$serverUsage, локально=$localUsage, всего=$totalUsage');
      }

      return totalUsage;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения офлайн использования: $e');
      }
      return 0;
    }
  }

  /// Кэширование данных подписки при онлайн режиме
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

      // Кэшируем лимиты (если есть UsageLimitsModel)
      try {
        final usageLimits = await _loadUsageLimits();
        if (usageLimits != null) {
          await _offlineStorage.cacheUsageLimits(usageLimits);
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

  /// Принудительное обновление офлайн кэша
  Future<void> refreshOfflineCache() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Принудительное обновление офлайн кэша...');
      }

      // Обновляем кэш использования
      await _refreshUsageCache();

      // Кэшируем данные подписки если есть сеть
      await cacheSubscriptionDataOnline();

      if (kDebugMode) {
        debugPrint('✅ Офлайн кэш обновлен');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления офлайн кэша: $e');
      }
    }
  }

  /// Увеличение офлайн счетчика использования
  Future<void> incrementOfflineUsage(ContentType contentType) async {
    try {
      // Увеличиваем локальный счетчик
      await _offlineStorage.incrementLocalUsage(contentType);

      if (kDebugMode) {
        final localCount = await _offlineStorage.getLocalUsageCount(contentType);
        debugPrint('📈 Увеличен офлайн счетчик $contentType: локально=$localCount');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения офлайн счетчика: $e');
      }
    }
  }

  /// Уменьшение офлайн счетчика использования
  Future<void> decrementOfflineUsage(ContentType contentType) async {
    try {
      // Уменьшаем локальный счетчик
      await _offlineStorage.decrementLocalUsage(contentType);

      if (kDebugMode) {
        final localCount = await _offlineStorage.getLocalUsageCount(contentType);
        debugPrint('📉 Уменьшен офлайн счетчик $contentType: локально=$localCount');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения офлайн счетчика: $e');
      }
    }
  }

  /// Получение UsageLimitsModel для кэширования
  Future<UsageLimitsModel?> _loadUsageLimits() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return null;

      // Создаем UsageLimitsModel из текущих данных
      final fishingNotes = await getCurrentUsage(ContentType.fishingNotes);
      final markerMaps = await getCurrentUsage(ContentType.markerMaps);
      final expenses = await getCurrentUsage(ContentType.expenses);

      return UsageLimitsModel(
        userId: userId,
        notesCount: fishingNotes,
        markerMapsCount: markerMaps,
        expensesCount: expenses,
        lastResetDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки лимитов использования: $e');
      }
      return null;
    }
  }

  /// Получение статистики офлайн использования
  Future<Map<String, dynamic>> getOfflineUsageStatistics() async {
    try {
      final allLocalCounters = await _offlineStorage.getAllLocalUsageCounters();
      final resetTime = await _offlineStorage.getLocalCountersResetTime();

      Map<String, dynamic> stats = {
        'localCounters': {},
        'totalUsage': {},
        'lastReset': resetTime?.toIso8601String(),
      };

      // Локальные счетчики
      for (final entry in allLocalCounters.entries) {
        stats['localCounters'][entry.key.name] = entry.value;
      }

      // Общее использование
      for (final contentType in ContentType.values) {
        final total = await _getCurrentOfflineUsage(contentType);
        stats['totalUsage'][contentType.name] = total;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики офлайн использования: $e');
      }
      return {};
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

  /// Очистка локальных счетчиков (для синхронизации)
  Future<void> clearLocalCounters() async {
    try {
      await _offlineStorage.resetLocalUsageCounters();
      if (kDebugMode) {
        debugPrint('✅ Локальные счетчики очищены');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка очистки локальных счетчиков: $e');
      }
    }
  }

  /// Получение всех локальных счетчиков
  Future<Map<ContentType, int>> getAllLocalCounters() async {
    try {
      return await _offlineStorage.getAllLocalUsageCounters();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения локальных счетчиков: $e');
      }
      return {};
    }
  }

  /// Проверка возможности создания контента для UI (синхронная)
  bool canCreateContentSync(ContentType contentType) {
    try {
      // Для тестовых аккаунтов - всегда разрешаем
      if (_isTestAccount()) {
        return true;
      }

      // Для обычных проверок используем асинхронный метод
      // Этот метод только для случаев, когда нужна синхронная проверка
      final serverUsage = getCurrentUsageSync(contentType);
      final limit = getLimit(contentType);

      // Проверяем только базовый лимит (без учета локальных счетчиков)
      return serverUsage < limit;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка синхронной проверки: $e');
      }
      return true; // При ошибке разрешаем
    }
  }

  // ОБНОВЛЕН: Обновление кэша использования из новой структуры Firebase
  Future<void> _refreshUsageCache() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) {
        _usageCache.clear();
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Обновление кэша использования для userId: $userId');
      }

      final Map<ContentType, int> newCache = {};

      // ИСПРАВЛЕНО: Подсчитываем из новой структуры subcollections
      try {
        final fishingNotesSnapshot = await firebaseService.getUserFishingNotesNew();
        newCache[ContentType.fishingNotes] = fishingNotesSnapshot.docs.length;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка подсчета fishing_notes: $e');
        }
        newCache[ContentType.fishingNotes] = 0;
      }

      // ИСПРАВЛЕНО: Подсчитываем маркерные карты из новой структуры
      try {
        final markerMapsSnapshot = await firebaseService.getUserMarkerMaps();
        newCache[ContentType.markerMaps] = markerMapsSnapshot.docs.length;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка подсчета marker_maps: $e');
        }
        newCache[ContentType.markerMaps] = 0;
      }

      // ИСПРАВЛЕНО: Подсчитываем поездки из новой структуры
      try {
        final fishingTripsSnapshot = await firebaseService.getUserFishingTrips();
        newCache[ContentType.expenses] = fishingTripsSnapshot.docs.length;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка подсчета fishing_trips: $e');
        }
        newCache[ContentType.expenses] = 0;
      }

      // depth_chart - пока только премиум, считаем 0 для бесплатных
      newCache[ContentType.depthChart] = 0;

      _usageCache = newCache;
      _lastUsageCacheUpdate = DateTime.now();

      if (kDebugMode) {
        debugPrint('✅ Кэш использования обновлен из новой структуры:');
        for (final entry in _usageCache.entries) {
          debugPrint('   ${entry.key.name}: ${entry.value}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления кэша использования: $e');
      }
    }
  }

  /// НОВЫЙ МЕТОД: Проверка актуальности кэша
  bool _isUsageCacheValid() {
    if (_lastUsageCacheUpdate == null) return false;
    return DateTime.now().difference(_lastUsageCacheUpdate!) < _cacheValidDuration;
  }

  /// ОБНОВЛЕН: Прямой подсчет использования из новой структуры Firebase
  Future<int> _getDirectUsageCount(ContentType contentType) async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return 0;

      QuerySnapshot snapshot;

      switch (contentType) {
        case ContentType.fishingNotes:
          snapshot = await firebaseService.getUserFishingNotesNew();
          break;

        case ContentType.markerMaps:
          snapshot = await firebaseService.getUserMarkerMaps();
          break;

        case ContentType.expenses:
          snapshot = await firebaseService.getUserFishingTrips();
          break;

        case ContentType.depthChart:
        // Пока depth_chart только премиум, возвращаем 0
          return 0;
      }

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка прямого подсчета $contentType: $e');
      }
      return 0;
    }
  }

  /// ОБНОВЛЕН: Проверка возможности создания контента с новой структурой
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

      // Получаем текущее использование
      final currentUsage = await getCurrentUsage(contentType);
      final limit = getLimit(contentType);

      // Проверяем лимит
      return currentUsage < limit;
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

  /// ОБНОВЛЕН: Получение текущего использования по типу контента (асинхронно)
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      // Если кэш актуален - используем его
      if (_isUsageCacheValid() && _usageCache.containsKey(contentType)) {
        return _usageCache[contentType] ?? 0;
      }

      // Иначе обновляем кэш
      await _refreshUsageCache();
      return _usageCache[contentType] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования: $e');
      }
      return 0;
    }
  }

  /// ОБНОВЛЕН: Синхронная версия для совместимости с существующим кодом
  int getCurrentUsageSync(ContentType contentType) {
    try {
      // Если кэш актуален - используем его
      if (_isUsageCacheValid() && _usageCache.containsKey(contentType)) {
        return _usageCache[contentType] ?? 0;
      }

      // Если кэш не актуален, возвращаем последнее известное значение
      // и запускаем обновление в фоне
      if (_usageCache.containsKey(contentType)) {
        // Обновляем кэш асинхронно
        _refreshUsageCache().catchError((e) {
          if (kDebugMode) {
            debugPrint('❌ Ошибка фонового обновления кэша: $e');
          }
        });
        return _usageCache[contentType] ?? 0;
      }

      return 0;
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

  /// ОБНОВЛЕН: Увеличение счетчика использования с проверкой офлайн лимитов
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Если премиум (включая тестовые аккаунты) - не увеличиваем счетчик
      if (hasPremiumAccess()) {
        return true;
      }

      // 🔥 НОВОЕ: Проверяем возможность создания контента с учетом офлайн лимитов
      if (!await canCreateContentOffline(contentType)) {
        return false;
      }

      // Увеличиваем счетчик в кэше
      final currentCount = _usageCache[contentType] ?? 0;
      _usageCache[contentType] = currentCount + 1;

      if (kDebugMode) {
        debugPrint('✅ Увеличен серверный счетчик $contentType: ${currentCount + 1}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика использования: $e');
      }
      return false;
    }
  }

  /// ОБНОВЛЕН: Уменьшение счетчика (при удалении контента) с обновлением кэша
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      // Уменьшаем счетчик в кэше
      final currentCount = _usageCache[contentType] ?? 0;
      if (currentCount > 0) {
        _usageCache[contentType] = currentCount - 1;

        if (kDebugMode) {
          debugPrint('✅ Уменьшен счетчик $contentType: ${currentCount - 1}');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения счетчика использования: $e');
      }
      return false;
    }
  }

  /// ОБНОВЛЕН: Сброс использования по типу (для админских целей)
  Future<void> resetUsage(ContentType contentType) async {
    try {
      _usageCache[contentType] = 0;
      if (kDebugMode) {
        debugPrint('✅ Сброшен счетчик $contentType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса использования: $e');
      }
    }
  }

  /// ОБНОВЛЕН: Получение информации об использовании для UI (асинхронно)
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

  /// ОБНОВЛЕН: Синхронная версия getUsageInfo для совместимости
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

  /// ОБНОВЛЕН: Получение статистики использования
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      await _refreshUsageCache();

      return {
        'fishingNotes': _usageCache[ContentType.fishingNotes] ?? 0,
        'markerMaps': _usageCache[ContentType.markerMaps] ?? 0,
        'expenses': _usageCache[ContentType.expenses] ?? 0,
        'depthChart': _usageCache[ContentType.depthChart] ?? 0,
        'lastUpdated': _lastUsageCacheUpdate?.toIso8601String(),
        'cacheValid': _isUsageCacheValid(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики: $e');
      }
      return {};
    }
  }

  /// ОБНОВЛЕН: Принудительное обновление данных лимитов
  Future<void> refreshUsageLimits() async {
    try {
      await _refreshUsageCache();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления лимитов: $e');
      }
    }
  }

  /// ОБНОВЛЕН: Загрузка текущей подписки пользователя из новой структуры
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

      // ИСПРАВЛЕНО: Загружаем из новой структуры Firebase через FirebaseService
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

  /// ИСПРАВЛЕНО: Обновление статуса подписки в новой структуре Firebase
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

      // ИСПРАВЛЕНО: Сохраняем через FirebaseService в новую структуру
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
        debugPrint('✅ Статус подписки обновлен в новой структуре: $status');
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
    _usageCache.clear();
  }
}