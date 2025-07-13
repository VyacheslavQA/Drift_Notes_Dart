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

  // 🔥 ИСПРАВЛЕНО: Убираем старый кэш - теперь используем новую систему Firebase
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

      // 🔥 ИСПРАВЛЕНО: Инициализируем систему лимитов в новой Firebase структуре
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

  // 🔥 НОВЫЙ МЕТОД: Инициализация системы лимитов через новую Firebase структуру
  Future<void> _initializeUsageLimits() async {
    try {
      debugPrint('🔄 Инициализация системы лимитов через новую Firebase структуру...');

      // Проверяем существует ли документ usage_limits для пользователя
      final usageLimitsDoc = await firebaseService.getUserUsageLimits();

      if (!usageLimitsDoc.exists) {
        debugPrint('📊 Создаем начальные лимиты для нового пользователя');
        // Автоматически создастся через getUserUsageLimits()
      } else {
        debugPrint('📊 Лимиты пользователя уже существуют');
        final data = usageLimitsDoc.data() as Map<String, dynamic>;
        debugPrint('📊 Текущие лимиты: $data');
      }

      debugPrint('✅ Система лимитов инициализирована через новую Firebase структуру');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации системы лимитов: $e');
    }
  }

  // 🔥 ИСПРАВЛЕННЫЕ МЕТОДЫ для работы с новой системой Firebase

  /// ✅ ИСПРАВЛЕНО: Основной метод проверки возможности создания контента с использованием новой Firebase системы
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

      // 3. 🔥 ИСПРАВЛЕНО: Используем новую систему Firebase для проверки лимитов
      final canCreate = await firebaseService.canCreateItem(_getFirebaseItemType(contentType));

      if (kDebugMode) {
        debugPrint('🔥 Проверка через новую Firebase систему: $contentType -> ${canCreate['canProceed']}');
        debugPrint('🔥 Детали: ${canCreate['currentCount']}/${canCreate['maxLimit']} (осталось: ${canCreate['remaining']})');
      }

      return canCreate['canProceed'] ?? false;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки офлайн создания контента: $e');
      }
      // При ошибке разрешаем создание (принцип "fail open")
      return true;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение детальной информации о статусе использования через новую Firebase систему
  Future<OfflineUsageResult> checkOfflineUsage(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую систему Firebase
      final limitCheck = await firebaseService.canCreateItem(_getFirebaseItemType(contentType));

      final canCreate = limitCheck['canProceed'] ?? false;
      final currentUsage = limitCheck['currentCount'] ?? 0;
      final maxLimit = limitCheck['maxLimit'] ?? 0;
      final remaining = limitCheck['remaining'] ?? 0;

      // Определяем тип предупреждения
      OfflineLimitWarningType warningType;
      String message;

      if (!canCreate) {
        warningType = OfflineLimitWarningType.blocked;
        message = 'Достигнут лимит ${_getContentTypeName(contentType)} ($maxLimit)';
      } else if (remaining <= 2) {
        warningType = OfflineLimitWarningType.approaching;
        message = 'Осталось $remaining ${_getContentTypeName(contentType)}';
      } else {
        warningType = OfflineLimitWarningType.normal;
        message = 'Доступно $remaining ${_getContentTypeName(contentType)}';
      }

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

  /// 🔥 НОВЫЙ МЕТОД: Преобразование ContentType в строку для новой Firebase системы
  String _getFirebaseItemType(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.expenses:
        return 'expensesCount';
      case ContentType.depthChart:
        return 'depthChartCount';
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение читаемого названия типа контента
  String _getContentTypeName(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'заметок';
      case ContentType.markerMaps:
        return 'карт';
      case ContentType.expenses:
        return 'поездок';
      case ContentType.depthChart:
        return 'графиков глубин';
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение текущего использования через новую Firebase систему
  Future<int> getCurrentOfflineUsage(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую систему Firebase для получения статистики
      final stats = await firebaseService.getUsageStatistics();

      final String firebaseKey = _getFirebaseItemType(contentType);
      final currentUsage = stats[firebaseKey] ?? 0;

      if (kDebugMode) {
        debugPrint('📊 Использование $contentType через новую Firebase систему: $currentUsage');
      }

      return currentUsage;
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

      // 🔥 ИСПРАВЛЕНО: Кэшируем лимиты через новую систему Firebase
      try {
        final usageLimits = await _loadUsageLimitsFromNewSystem();
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

      // 🔥 ИСПРАВЛЕНО: Обновляем через новую систему Firebase
      await _refreshUsageCacheFromNewSystem();

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

  /// ✅ ИСПРАВЛЕНО: Увеличение счетчика использования через новую Firebase систему
  Future<void> incrementOfflineUsage(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую систему Firebase для увеличения счетчика
      final success = await firebaseService.incrementUsageCount(_getFirebaseItemType(contentType));

      if (kDebugMode) {
        if (success) {
          debugPrint('📈 Увеличен счетчик $contentType через новую Firebase систему');
        } else {
          debugPrint('❌ Не удалось увеличить счетчик $contentType');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика: $e');
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Уменьшение счетчика использования через новую Firebase систему
  Future<void> decrementOfflineUsage(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую систему Firebase для уменьшения счетчика
      // Пока что новая система не имеет метода уменьшения, нужно будет добавить
      // Временно используем старый механизм офлайн стоража
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

  /// 🔥 ИСПРАВЛЕНО: Получение UsageLimitsModel из новой системы Firebase
  Future<UsageLimitsModel?> _loadUsageLimitsFromNewSystem() async {
    try {
      final userId = firebaseService.currentUserId;
      if (userId == null) return null;

      // 🔥 ИСПРАВЛЕНО: Получаем статистику из новой системы Firebase
      final stats = await firebaseService.getUsageStatistics();

      return UsageLimitsModel(
        userId: userId,
        notesCount: stats['notesCount'] ?? 0,
        markerMapsCount: stats['markerMapsCount'] ?? 0,
        expensesCount: stats['expensesCount'] ?? 0,
        lastResetDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки лимитов из новой системы: $e');
      }
      return null;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получение статистики использования через новую Firebase систему
  Future<Map<String, dynamic>> getOfflineUsageStatistics() async {
    try {
      // Получаем статистику из новой системы Firebase
      final stats = await firebaseService.getUsageStatistics();

      return {
        'newSystem': stats,
        'exists': stats['exists'] ?? false,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики через новую систему: $e');
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

      // Проверяем только базовый лимит
      return serverUsage < limit;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка синхронной проверки: $e');
      }
      return true; // При ошибке разрешаем
    }
  }

  // ✅ ИСПРАВЛЕНО: Обновление кэша использования из новой структуры Firebase
  Future<void> _refreshUsageCacheFromNewSystem() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Обновление кэша использования из новой Firebase системы...');
      }

      // Просто обновляем время кэша, так как новая система работает напрямую с Firebase
      _lastUsageCacheUpdate = DateTime.now();

      if (kDebugMode) {
        // Логируем текущую статистику для отладки
        final stats = await firebaseService.getUsageStatistics();
        debugPrint('✅ Статистика использования из новой системы: $stats');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обновления кэша из новой системы: $e');
      }
    }
  }

  /// НОВЫЙ МЕТОД: Проверка актуальности кэша
  bool _isUsageCacheValid() {
    if (_lastUsageCacheUpdate == null) return false;
    return DateTime.now().difference(_lastUsageCacheUpdate!) < _cacheValidDuration;
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка возможности создания контента с использованием новой Firebase системы
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

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем новую Firebase систему
      return await canCreateContentOffline(contentType);
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

  /// ✅ ИСПРАВЛЕНО: Получение текущего использования через новую Firebase систему
  Future<int> getCurrentUsage(ContentType contentType) async {
    try {
      return await getCurrentOfflineUsage(contentType);
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
      // Для синхронной версии возвращаем приблизительные данные
      // В будущем можно добавить кэширование
      return 0; // Временно, так как новая система асинхронная
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

  /// 🔥 ИСПРАВЛЕНО: Увеличение счетчика использования через новую Firebase систему
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Тестовые аккаунты Google Play - безлимитный доступ БЕЗ счетчиков
      if (_isTestAccount()) {
        if (kDebugMode) {
          debugPrint('🧪 Тестовый аккаунт Google Play - пропускаем увеличение счетчика для $contentType');
        }
        return true;
      }

      // 🔥 ИСПРАВЛЕНО: Для ВСЕХ остальных пользователей (включая обычных премиум) - ВСЕГДА увеличиваем счетчики
      await incrementOfflineUsage(contentType);

      if (kDebugMode) {
        debugPrint('📈 Счетчик увеличен для $contentType');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика использования: $e');
      }
      return false;
    }
  }

  /// ОБНОВЛЕН: Уменьшение счетчика (при удалении контента)
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      await decrementOfflineUsage(contentType);
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
      // 🔥 ИСПРАВЛЕНО: Используем новую Firebase систему для сброса
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

  /// 🔥 ИСПРАВЛЕНО: Получение информации об использовании через новую Firebase систему
  Future<Map<ContentType, Map<String, int>>> getUsageInfo() async {
    try {
      final result = <ContentType, Map<String, int>>{};

      for (final contentType in ContentType.values) {
        final totalUsage = await getCurrentOfflineUsage(contentType);
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

  /// ✅ ИСПРАВЛЕНО: Получение статистики использования через новую Firebase систему
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      return await firebaseService.getUsageStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики: $e');
      }
      return {};
    }
  }

  /// ✅ ИСПРАВЛЕНО: Принудительное обновление данных лимитов через новую Firebase систему
  Future<void> refreshUsageLimits() async {
    try {
      await _refreshUsageCacheFromNewSystem();
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

  // === ОСТАЛЬНЫЕ МЕТОДЫ ОСТАЮТСЯ БЕЗ ИЗМЕНЕНИЙ ===
  // (методы покупок, обработки платежей и т.д.)

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
  }
}