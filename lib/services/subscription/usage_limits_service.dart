// Путь: lib/services/subscription/usage_limits_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/subscription_constants.dart';
import '../../models/usage_limits_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../utils/network_utils.dart';

/// Сервис для отслеживания и управления лимитами использования
class UsageLimitsService {
  static final UsageLimitsService _instance = UsageLimitsService._internal();
  factory UsageLimitsService() => _instance;
  UsageLimitsService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 НОВОЕ: Интеграция с офлайн сторажем
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Ссылка на SubscriptionService для проверки премиум статуса
  SubscriptionService? _subscriptionService;

  // Кэш текущих лимитов
  UsageLimitsModel? _cachedLimits;

  // Флаг инициализации для предотвращения повторной инициализации
  bool _isInitialized = false;

  // Стрим для прослушивания изменений лимитов
  final StreamController<UsageLimitsModel> _limitsController = StreamController<UsageLimitsModel>.broadcast();

  // Стрим для UI
  Stream<UsageLimitsModel> get limitsStream => _limitsController.stream;

  /// Установка ссылки на SubscriptionService
  void setSubscriptionService(SubscriptionService subscriptionService) {
    _subscriptionService = subscriptionService;
  }

  /// Проверка премиум статуса
  bool _hasPremiumAccess() {
    try {
      return _subscriptionService?.hasPremiumAccess() ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки премиум статуса: $e');
      }
      return false;
    }
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('🔄 UsageLimitsService уже инициализирован');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 Инициализация UsageLimitsService...');
      }

      // 🔥 НОВОЕ: Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

      // Загружаем текущие лимиты
      await loadCurrentLimits();

      // КРИТИЧЕСКИ ВАЖНО: Пересчитываем лимиты из реальных данных Firebase + офлайн
      await recalculateLimitsWithOffline();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ UsageLimitsService инициализирован с реальными данными + офлайн');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации UsageLimitsService: $e');
      }
    }
  }

  /// Загрузка текущих лимитов пользователя
  Future<UsageLimitsModel> loadCurrentLimits() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        _cachedLimits = UsageLimitsModel.defaultLimits('');
        return _cachedLimits!;
      }

      // Проверяем кэш только если данные актуальные
      if (_cachedLimits != null &&
          _cachedLimits!.userId == userId &&
          _isDataRecent(_cachedLimits!.updatedAt)) {
        return _cachedLimits!;
      }

      // Пытаемся загрузить из Firebase
      if (await NetworkUtils.isNetworkAvailable()) {
        final doc = await _firestore
            .collection(SubscriptionConstants.usageLimitsCollection)
            .doc(userId)
            .get();

        if (doc.exists && doc.data() != null) {
          _cachedLimits = UsageLimitsModel.fromMap(doc.data()!, userId);
        } else {
          // Создаем новый документ лимитов
          _cachedLimits = UsageLimitsModel.defaultLimits(userId);
          await _saveLimitsToFirebase(_cachedLimits!);
        }
      } else {
        // Загружаем из локального кэша
        _cachedLimits = await _loadFromCache(userId);
      }

      // Отправляем в стрим
      _limitsController.add(_cachedLimits!);

      return _cachedLimits!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки лимитов: $e');
      }
      final userId = _firebaseService.currentUserId ?? '';
      _cachedLimits = UsageLimitsModel.defaultLimits(userId);
      return _cachedLimits!;
    }
  }

  /// Проверка актуальности данных (данные считаются актуальными в течение 5 минут)
  bool _isDataRecent(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inMinutes < 5;
  }

  /// 🔥 ИСПРАВЛЕНО: Получение текущего использования с учетом офлайн данных
  Future<UsageLimitsModel> getCurrentUsage() async {
    try {
      // Если кэш пустой или устаревший - загружаем и пересчитываем
      if (_cachedLimits == null || !_isDataRecent(_cachedLimits!.updatedAt)) {
        await loadCurrentLimits();
        await recalculateLimitsWithOffline();
      }

      return _cachedLimits ?? UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования: $e');
      }
      return UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение общего использования (серверное + офлайн)
  Future<int> _getTotalUsageForType(ContentType contentType) async {
    try {
      // Получаем серверное использование
      final limits = _cachedLimits ?? UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
      final serverUsage = limits.getCountForType(contentType);

      // Получаем офлайн использование
      final offlineUsage = await _offlineStorage.getLocalUsageCount(contentType);

      final totalUsage = serverUsage + offlineUsage;

      if (kDebugMode) {
        debugPrint('📊 Общее использование $contentType: сервер=$serverUsage, офлайн=$offlineUsage, всего=$totalUsage');
      }

      return totalUsage;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения общего использования для $contentType: $e');
      }
      return 0;
    }
  }

  /// 🔥 КРИТИЧЕСКИ ИСПРАВЛЕНО: Проверка возможности создания нового контента с учетом офлайн лимитов
  Future<bool> canCreateContent(ContentType contentType) async {
    try {
      // Проверяем премиум статус ПЕРВЫМ
      if (_hasPremiumAccess()) {
        if (kDebugMode) {
          debugPrint('🧪 Премиум пользователь - разрешен доступ к $contentType');
        }
        return true;
      }

      // Для графика глубин проверяем только премиум статус
      if (contentType == ContentType.depthChart) {
        if (kDebugMode) {
          debugPrint('⚠️ График глубин требует премиум подписку');
        }
        return false;
      }

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем SubscriptionService для проверки офлайн лимитов
      if (_subscriptionService != null) {
        final canCreate = await _subscriptionService!.canCreateContentOffline(contentType);
        if (kDebugMode) {
          debugPrint('🔒 Проверка офлайн лимитов через SubscriptionService: $canCreate');
        }
        return canCreate;
      }

      // Fallback: проверка только серверных лимитов (не рекомендуется)
      final limits = await getCurrentUsage();
      final canCreateServer = limits.canCreateNew(contentType);

      if (kDebugMode) {
        debugPrint('⚠️ Fallback: проверка только серверных лимитов: $canCreateServer');
      }

      return canCreateServer;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      }
      return false;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка возможности создания с детализацией и учетом офлайн данных
  Future<ContentCreationResult> checkContentCreation(ContentType contentType) async {
    try {
      // Проверяем премиум статус ПЕРВЫМ
      if (_hasPremiumAccess()) {
        if (kDebugMode) {
          debugPrint('🧪 Премиум пользователь - полный доступ к $contentType');
        }
        return ContentCreationResult(
          canCreate: true,
          reason: null,
          currentCount: 0,
          limit: SubscriptionConstants.unlimitedValue,
          remaining: SubscriptionConstants.unlimitedValue,
        );
      }

      // Для графика глубин
      if (contentType == ContentType.depthChart) {
        return ContentCreationResult(
          canCreate: false,
          reason: ContentCreationBlockReason.premiumRequired,
          currentCount: 0,
          limit: 0,
          remaining: 0,
        );
      }

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем общее использование (серверное + офлайн)
      final totalUsage = await _getTotalUsageForType(contentType);
      final limit = SubscriptionConstants.getContentLimit(contentType);
      final maxAllowed = limit + SubscriptionConstants.offlineGraceLimit;

      final canCreate = totalUsage < maxAllowed;
      final remaining = maxAllowed - totalUsage;

      ContentCreationBlockReason? reason;
      if (!canCreate) {
        reason = ContentCreationBlockReason.limitReached;
      }

      if (kDebugMode) {
        debugPrint('🔒 Детальная проверка $contentType: $totalUsage < $maxAllowed = $canCreate (remaining: $remaining)');
      }

      return ContentCreationResult(
        canCreate: canCreate,
        reason: reason,
        currentCount: totalUsage,
        limit: maxAllowed,
        remaining: remaining > 0 ? remaining : 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки создания контента: $e');
      }
      return ContentCreationResult(
        canCreate: false,
        reason: ContentCreationBlockReason.error,
        currentCount: 0,
        limit: 0,
        remaining: 0,
      );
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Увеличение счетчика использования с проверкой офлайн лимитов
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Если премиум - не увеличиваем счетчик
      if (_hasPremiumAccess()) {
        if (kDebugMode) {
          debugPrint('🧪 Премиум пользователь - счетчик не увеличивается для $contentType');
        }
        return true;
      }

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Проверяем офлайн лимиты через SubscriptionService
      if (_subscriptionService != null) {
        final canCreate = await _subscriptionService!.canCreateContentOffline(contentType);
        if (!canCreate) {
          if (kDebugMode) {
            debugPrint('⚠️ Достигнут офлайн лимит для типа: $contentType');
          }
          return false;
        }
      } else {
        // Fallback: проверка только серверных лимитов
        final limits = await getCurrentUsage();
        if (!limits.canCreateNew(contentType)) {
          if (kDebugMode) {
            debugPrint('⚠️ Достигнут серверный лимит для типа: $contentType');
          }
          return false;
        }
      }

      // Увеличиваем серверный счетчик
      final limits = await getCurrentUsage();
      final updatedLimits = limits.incrementCounter(contentType);

      // Сохраняем обновленные лимиты
      await _saveLimits(updatedLimits);

      if (kDebugMode) {
        debugPrint('✅ Серверный счетчик увеличен для $contentType: ${updatedLimits.getCountForType(contentType)}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика: $e');
      }
      return false;
    }
  }

  /// ОБНОВЛЕН: Уменьшение счетчика использования (при удалении контента)
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      final limits = await getCurrentUsage();

      // Уменьшаем счетчик
      final updatedLimits = limits.decrementCounter(contentType);

      // Сохраняем обновленные лимиты
      await _saveLimits(updatedLimits);

      if (kDebugMode) {
        debugPrint('✅ Счетчик уменьшен для $contentType: ${updatedLimits.getCountForType(contentType)}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения счетчика: $e');
      }
      return false;
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Пересчет лимитов с учетом офлайн данных
  Future<void> recalculateLimitsWithOffline() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Пересчет лимитов с учетом офлайн данных...');
      }

      // Сначала пересчитываем серверные данные
      await recalculateLimits();

      // Затем логируем информацию об офлайн счетчиках
      final userId = _firebaseService.currentUserId;
      if (userId != null) {
        final offlineCounters = await _offlineStorage.getAllLocalUsageCounters();

        if (kDebugMode) {
          debugPrint('📊 Офлайн счетчики:');
          for (final entry in offlineCounters.entries) {
            debugPrint('   ${entry.key.name}: ${entry.value}');
          }

          // Показываем общую статистику
          debugPrint('📊 Общее использование (серверное + офлайн):');
          for (final contentType in ContentType.values) {
            if (contentType != ContentType.depthChart) {
              final totalUsage = await _getTotalUsageForType(contentType);
              final limit = SubscriptionConstants.getContentLimit(contentType);
              final graceLimit = limit + SubscriptionConstants.offlineGraceLimit;
              debugPrint('   ${contentType.name}: $totalUsage/$graceLimit (лимит: $limit + grace: ${SubscriptionConstants.offlineGraceLimit})');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка пересчета лимитов с офлайн данными: $e');
      }
    }
  }

  /// ИСПРАВЛЕНО: Пересчет лимитов на основе фактических данных из НОВОЙ структуры
  Future<void> recalculateLimits() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Пересчет серверных лимитов из НОВОЙ структуры...');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Пользователь не авторизован, пропускаем пересчет');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('👤 Пересчитываем лимиты для пользователя: $userId');
      }

      // Подсчитываем фактическое количество контента из НОВОЙ структуры subcollections
      int actualNotesCount = 0;
      int actualMapsCount = 0;
      int actualExpensesCount = 0;

      if (await NetworkUtils.isNetworkAvailable()) {
        try {
          // ИСПРАВЛЕНО: Считаем заметки из НОВОЙ структуры
          if (kDebugMode) {
            debugPrint('📝 Подсчет заметок из НОВОЙ структуры: users/$userId/fishing_notes');
          }

          final notesSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')    // ← НОВАЯ СТРУКТУРА
              .get();

          actualNotesCount = notesSnapshot.docs.length;
          if (kDebugMode) {
            debugPrint('📝 Найдено заметок в НОВОЙ структуре: $actualNotesCount');
          }

          // ИСПРАВЛЕНО: Считаем маркерные карты из НОВОЙ структуры
          if (kDebugMode) {
            debugPrint('🗺️ Подсчет карт из НОВОЙ структуры: users/$userId/marker_maps');
          }

          final mapsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('marker_maps')      // ← НОВАЯ СТРУКТУРА
              .get();

          actualMapsCount = mapsSnapshot.docs.length;
          if (kDebugMode) {
            debugPrint('🗺️ Найдено карт в НОВОЙ структуре: $actualMapsCount');
          }

          // ИСПРАВЛЕНО: Считаем поездки из НОВОЙ структуры
          if (kDebugMode) {
            debugPrint('💰 Подсчет поездок из НОВОЙ структуры: users/$userId/fishing_trips');
          }

          final tripsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_trips')    // ← НОВАЯ СТРУКТУРА
              .get();

          // Считаем количество поездок (каждая поездка = один элемент расходов)
          actualExpensesCount = tripsSnapshot.docs.length;
          if (kDebugMode) {
            debugPrint('💰 Найдено поездок в НОВОЙ структуре: $actualExpensesCount');
            // Показываем ID всех поездок для диагностики
            final tripIds = tripsSnapshot.docs.map((doc) => doc.id).toList();
            debugPrint('💰 ID поездок: $tripIds');
          }

          // ДОПОЛНИТЕЛЬНО: Проверяем старую структуру для сравнения
          if (kDebugMode) {
            debugPrint('🔍 === СРАВНЕНИЕ СО СТАРОЙ СТРУКТУРОЙ ===');

            try {
              // Старая структура заметок
              final oldNotesSnapshot = await _firestore
                  .collection('fishing_notes')
                  .where('userId', isEqualTo: userId)
                  .get();
              debugPrint('📝 Старая структура заметок: ${oldNotesSnapshot.docs.length}');

              // Старая структура карт
              final oldMapsSnapshot = await _firestore
                  .collection('marker_maps')
                  .where('userId', isEqualTo: userId)
                  .get();
              debugPrint('🗺️ Старая структура карт: ${oldMapsSnapshot.docs.length}');

              // Старая структура поездок
              final oldTripsSnapshot = await _firestore
                  .collection('fishing_trips')
                  .where('userId', isEqualTo: userId)
                  .get();
              debugPrint('💰 Старая структура поездок: ${oldTripsSnapshot.docs.length}');
            } catch (e) {
              debugPrint('❌ Ошибка проверки старой структуры: $e');
            }
          }

        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Ошибка подсчета данных из НОВОЙ структуры Firebase: $e');
          }
          // В случае ошибки используем данные из кэша
          final currentLimits = _cachedLimits ?? UsageLimitsModel.defaultLimits(userId);
          actualNotesCount = currentLimits.notesCount;
          actualMapsCount = currentLimits.markerMapsCount;
          actualExpensesCount = currentLimits.expensesCount;
          if (kDebugMode) {
            debugPrint('💾 Используем кэшированные данные: $actualNotesCount/$actualMapsCount/$actualExpensesCount');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('🔌 Нет интернета, используем кэшированные данные');
        }
        final currentLimits = _cachedLimits ?? UsageLimitsModel.defaultLimits(userId);
        actualNotesCount = currentLimits.notesCount;
        actualMapsCount = currentLimits.markerMapsCount;
        actualExpensesCount = currentLimits.expensesCount;
      }

      // Создаем обновленную модель лимитов
      final currentLimits = _cachedLimits ?? UsageLimitsModel.defaultLimits(userId);
      final updatedLimits = currentLimits.copyWith(
        notesCount: actualNotesCount,
        markerMapsCount: actualMapsCount,
        expensesCount: actualExpensesCount,
        updatedAt: DateTime.now(),
      );

      // Сохраняем обновленные лимиты
      await _saveLimits(updatedLimits);

      if (kDebugMode) {
        debugPrint('✅ Серверные лимиты пересчитаны из НОВОЙ структуры и сохранены:');
        debugPrint('   📝 Заметки: $actualNotesCount/${SubscriptionConstants.freeNotesLimit}');
        debugPrint('   🗺️ Карты: $actualMapsCount/${SubscriptionConstants.freeMarkerMapsLimit}');
        debugPrint('   💰 Поездки: $actualExpensesCount/${SubscriptionConstants.freeExpensesLimit}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Критическая ошибка пересчета лимитов: $e');
      }
    }
  }

  /// Принудительное обновление данных (для использования в UI)
  Future<void> forceRefresh() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Принудительное обновление лимитов...');
      }
      _cachedLimits = null; // Очищаем кэш
      await loadCurrentLimits();
      await recalculateLimitsWithOffline();
      if (kDebugMode) {
        debugPrint('✅ Принудительное обновление завершено');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка принудительного обновления: $e');
      }
    }
  }

  /// Методы для сброса конкретных типов контента (для тестирования)
  Future<void> resetUsageForType(ContentType contentType) async {
    try {
      final limits = await getCurrentUsage();
      UsageLimitsModel updatedLimits;

      switch (contentType) {
        case ContentType.fishingNotes:
          updatedLimits = limits.copyWith(notesCount: 0, updatedAt: DateTime.now());
          break;
        case ContentType.markerMaps:
          updatedLimits = limits.copyWith(markerMapsCount: 0, updatedAt: DateTime.now());
          break;
        case ContentType.expenses:
          updatedLimits = limits.copyWith(expensesCount: 0, updatedAt: DateTime.now());
          break;
        case ContentType.depthChart:
        // График глубин не имеет счетчика
          return;
      }

      await _saveLimits(updatedLimits);
      if (kDebugMode) {
        debugPrint('✅ Сброшен счетчик для типа: $contentType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса счетчика для типа $contentType: $e');
      }
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получение статистики использования с учетом офлайн данных
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final limits = await getCurrentUsage();
      final baseStats = limits.getUsageStats();

      // Добавляем офлайн статистику
      final offlineCounters = await _offlineStorage.getAllLocalUsageCounters();

      // Добавляем общую статистику
      final totalStats = <String, dynamic>{};
      for (final contentType in ContentType.values) {
        if (contentType != ContentType.depthChart) {
          final totalUsage = await _getTotalUsageForType(contentType);
          totalStats['total_${contentType.name}'] = totalUsage;
        }
      }

      return {
        ...baseStats,
        'offline_counters': {
          for (final entry in offlineCounters.entries)
            entry.key.name: entry.value
        },
        ...totalStats,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики: $e');
      }
      return {};
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка нужно ли показать предупреждение о лимитах с учетом офлайн данных
  Future<List<ContentTypeWarning>> checkForWarnings() async {
    try {
      final warnings = <ContentTypeWarning>[];

      for (final contentType in [
        ContentType.fishingNotes,
        ContentType.markerMaps,
        ContentType.expenses,
      ]) {
        // Получаем общее использование (серверное + офлайн)
        final totalUsage = await _getTotalUsageForType(contentType);
        final limit = SubscriptionConstants.getContentLimit(contentType);
        final maxAllowed = limit + SubscriptionConstants.offlineGraceLimit;

        // Проверяем нужно ли показывать предупреждение
        final warningThreshold = (limit * 0.8).round(); // 80% от лимита

        if (totalUsage >= warningThreshold) {
          final remaining = maxAllowed - totalUsage;
          final percentage = totalUsage / maxAllowed;

          warnings.add(ContentTypeWarning(
            contentType: contentType,
            currentCount: totalUsage,
            limit: maxAllowed,
            remaining: remaining > 0 ? remaining : 0,
            percentage: percentage,
          ));
        }
      }

      return warnings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки предупреждений: $e');
      }
      return [];
    }
  }

  /// Сброс всех лимитов (для админских целей)
  Future<void> resetAllLimits() async {
    try {
      final limits = await getCurrentUsage();
      final resetLimits = limits.resetAllCounters();
      await _saveLimits(resetLimits);

      // 🔥 НОВОЕ: Также сбрасываем офлайн счетчики
      await _offlineStorage.resetLocalUsageCounters();

      if (kDebugMode) {
        debugPrint('✅ Все лимиты сброшены (серверные + офлайн)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса лимитов: $e');
      }
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение общей статистики использования
  Future<Map<String, dynamic>> getComprehensiveUsageStats() async {
    try {
      final Map<String, dynamic> stats = {};

      for (final contentType in ContentType.values) {
        if (contentType != ContentType.depthChart) {
          final limits = _cachedLimits ?? UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
          final serverUsage = limits.getCountForType(contentType);
          final offlineUsage = await _offlineStorage.getLocalUsageCount(contentType);
          final totalUsage = serverUsage + offlineUsage;
          final limit = SubscriptionConstants.getContentLimit(contentType);
          final maxAllowed = limit + SubscriptionConstants.offlineGraceLimit;

          stats[contentType.name] = {
            'server': serverUsage,
            'offline': offlineUsage,
            'total': totalUsage,
            'limit': limit,
            'maxAllowed': maxAllowed,
            'remaining': maxAllowed - totalUsage,
            'percentage': totalUsage / maxAllowed,
          };
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения комплексной статистики: $e');
      }
      return {};
    }
  }

  /// Сохранение лимитов
  Future<void> _saveLimits(UsageLimitsModel limits) async {
    try {
      // Сохраняем в Firebase
      await _saveLimitsToFirebase(limits);

      // Сохраняем в локальный кэш
      await _saveToCache(limits);

      // Обновляем кэш в памяти
      _cachedLimits = limits;

      // Отправляем в стрим
      _limitsController.add(limits);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения лимитов: $e');
      }
      rethrow;
    }
  }

  /// Сохранение лимитов в Firebase
  Future<void> _saveLimitsToFirebase(UsageLimitsModel limits) async {
    try {
      if (await NetworkUtils.isNetworkAvailable()) {
        await _firestore
            .collection(SubscriptionConstants.usageLimitsCollection)
            .doc(limits.userId)
            .set(limits.toMap(), SetOptions(merge: true));
        if (kDebugMode) {
          debugPrint('💾 Лимиты сохранены в Firebase');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🔌 Нет интернета, сохранение в Firebase пропущено');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения в Firebase: $e');
      }
    }
  }

  /// Сохранение лимитов в локальный кэш
  Future<void> _saveToCache(UsageLimitsModel limits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_notes_count', limits.notesCount);
      await prefs.setInt('cached_maps_count', limits.markerMapsCount);
      await prefs.setInt('cached_expenses_count', limits.expensesCount);
      await prefs.setString('cached_limits_updated', limits.updatedAt.toIso8601String());
      await prefs.setString('cached_user_id', limits.userId);
      if (kDebugMode) {
        debugPrint('💾 Лимиты сохранены в локальный кэш');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сохранения лимитов в кэш: $e');
      }
    }
  }

  /// Загрузка лимитов из локального кэша
  Future<UsageLimitsModel> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Проверяем соответствие пользователя
      final cachedUserId = prefs.getString('cached_user_id');
      if (cachedUserId != userId) {
        if (kDebugMode) {
          debugPrint('👤 Смена пользователя, создаем новые лимиты');
        }
        return UsageLimitsModel.defaultLimits(userId);
      }

      final notesCount = prefs.getInt('cached_notes_count') ?? 0;
      final mapsCount = prefs.getInt('cached_maps_count') ?? 0;
      final expensesCount = prefs.getInt('cached_expenses_count') ?? 0;
      final updatedString = prefs.getString('cached_limits_updated');

      final updatedAt = updatedString != null
          ? DateTime.tryParse(updatedString) ?? DateTime.now()
          : DateTime.now();

      if (kDebugMode) {
        debugPrint('💾 Лимиты загружены из кэша: $notesCount/$mapsCount/$expensesCount');
      }

      return UsageLimitsModel(
        userId: userId,
        notesCount: notesCount,
        markerMapsCount: mapsCount,
        expensesCount: expensesCount,
        lastResetDate: updatedAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки лимитов из кэша: $e');
      }
      return UsageLimitsModel.defaultLimits(userId);
    }
  }

  /// Получение текущих лимитов (синхронно из кэша)
  UsageLimitsModel? get currentLimits => _cachedLimits;

  /// Проверка инициализации
  bool get isInitialized => _isInitialized;

  /// Очистка ресурсов
  void dispose() {
    _limitsController.close();
    _isInitialized = false;
  }
}

/// Результат проверки возможности создания контента
class ContentCreationResult {
  final bool canCreate;
  final ContentCreationBlockReason? reason;
  final int currentCount;
  final int limit;
  final int remaining;

  const ContentCreationResult({
    required this.canCreate,
    this.reason,
    required this.currentCount,
    required this.limit,
    required this.remaining,
  });

  @override
  String toString() {
    return 'ContentCreationResult(canCreate: $canCreate, current: $currentCount/$limit, remaining: $remaining)';
  }
}

/// Причины блокировки создания контента
enum ContentCreationBlockReason {
  limitReached,      // Достигнут лимит
  premiumRequired,   // Требуется премиум подписка
  error,            // Ошибка при проверке
}

/// Предупреждение о достижении лимита
class ContentTypeWarning {
  final ContentType contentType;
  final int currentCount;
  final int limit;
  final int remaining;
  final double percentage;

  const ContentTypeWarning({
    required this.contentType,
    required this.currentCount,
    required this.limit,
    required this.remaining,
    required this.percentage,
  });

  @override
  String toString() {
    return 'ContentTypeWarning($contentType: ${(percentage * 100).toInt()}% used, $remaining remaining)';
  }
}