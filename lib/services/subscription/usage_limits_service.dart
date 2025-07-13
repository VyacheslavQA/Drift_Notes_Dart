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

/// 🔥 ПОЛНОСТЬЮ ОБНОВЛЕННЫЙ Сервис для отслеживания и управления лимитами использования
/// Теперь использует новую систему Firebase usage_limits subcollections
class UsageLimitsService {
  static final UsageLimitsService _instance = UsageLimitsService._internal();
  factory UsageLimitsService() => _instance;
  UsageLimitsService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // 🔥 НОВОЕ: Интеграция с офлайн сторажем
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Ссылка на SubscriptionService для проверки премиум статуса
  SubscriptionService? _subscriptionService;

  // 🔥 ИСПРАВЛЕНО: Убираем старый кэш UsageLimitsModel, используем новую систему Firebase
  DateTime? _lastLimitsUpdate;

  // Флаг инициализации для предотвращения повторной инициализации
  bool _isInitialized = false;

  // 🔥 ИСПРАВЛЕНО: Стрим теперь работает с Map вместо UsageLimitsModel
  final StreamController<Map<String, dynamic>> _limitsController = StreamController<Map<String, dynamic>>.broadcast();

  // Стрим для UI
  Stream<Map<String, dynamic>> get limitsStream => _limitsController.stream;

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
        debugPrint('🔄 Инициализация UsageLimitsService с новой Firebase системой...');
      }

      // 🔥 НОВОЕ: Инициализируем офлайн сторадж
      await _offlineStorage.initialize();

      // 🔥 ИСПРАВЛЕНО: Инициализируем новую систему Firebase лимитов
      await _initializeNewFirebaseSystem();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ UsageLimitsService инициализирован с новой Firebase системой');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации UsageLimitsService: $e');
      }
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Инициализация новой системы Firebase
  Future<void> _initializeNewFirebaseSystem() async {
    try {
      debugPrint('🔄 Инициализация новой Firebase системы лимитов...');

      // Просто вызываем getUserUsageLimits чтобы инициализировать документ если его нет
      final limitsDoc = await _firebaseService.getUserUsageLimits();

      if (limitsDoc.exists) {
        final data = limitsDoc.data() as Map<String, dynamic>;
        debugPrint('📊 Текущие лимиты из новой системы: $data');

        // Отправляем в стрим
        _limitsController.add(data);
      } else {
        debugPrint('📊 Лимиты созданы автоматически');
      }

      _lastLimitsUpdate = DateTime.now();
      debugPrint('✅ Новая Firebase система лимитов готова');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации новой Firebase системы: $e');
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Загрузка текущих лимитов через новую Firebase систему
  Future<Map<String, dynamic>> loadCurrentLimits() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        return _getDefaultLimitsMap();
      }

      // Проверяем актуальность кэша
      if (_lastLimitsUpdate != null && _isDataRecent(_lastLimitsUpdate!)) {
        // Возвращаем последние известные данные
        return await _getCurrentLimitsFromNewSystem();
      }

      // 🔥 ИСПРАВЛЕНО: Загружаем через новую Firebase систему
      final limitsDoc = await _firebaseService.getUserUsageLimits();

      if (limitsDoc.exists) {
        final data = limitsDoc.data() as Map<String, dynamic>;
        _limitsController.add(data);
        _lastLimitsUpdate = DateTime.now();
        return data;
      } else {
        // Лимиты создадутся автоматически
        return _getDefaultLimitsMap();
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка загрузки лимитов: $e');
      }
      return _getDefaultLimitsMap();
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение текущих лимитов из новой Firebase системы
  Future<Map<String, dynamic>> _getCurrentLimitsFromNewSystem() async {
    try {
      final stats = await _firebaseService.getUsageStatistics();
      return stats;
    } catch (e) {
      debugPrint('❌ Ошибка получения лимитов из новой системы: $e');
      return _getDefaultLimitsMap();
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение лимитов по умолчанию
  Map<String, dynamic> _getDefaultLimitsMap() {
    return {
      'notesCount': 0,
      'markerMapsCount': 0,
      'expensesCount': 0,
      'tripsCount': 0,
      'budgetNotesCount': 0,
      'exists': false,
    };
  }

  /// Проверка актуальности данных (данные считаются актуальными в течение 5 минут)
  bool _isDataRecent(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inMinutes < 5;
  }

  /// 🔥 ИСПРАВЛЕНО: Получение текущего использования через новую Firebase систему
  Future<Map<String, dynamic>> getCurrentUsage() async {
    try {
      // Если данные недавние - возвращаем их
      if (_lastLimitsUpdate != null && _isDataRecent(_lastLimitsUpdate!)) {
        return await _getCurrentLimitsFromNewSystem();
      }

      // Иначе загружаем заново
      return await loadCurrentLimits();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения текущего использования: $e');
      }
      return _getDefaultLimitsMap();
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка возможности создания нового контента через новую Firebase систему
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

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем новую Firebase систему
      final itemType = _getFirebaseItemType(contentType);
      final canCreateResult = await _firebaseService.canCreateItem(itemType);

      final canCreate = canCreateResult['canProceed'] ?? false;

      if (kDebugMode) {
        debugPrint('🔒 Проверка через новую Firebase систему: $contentType -> $canCreate');
        debugPrint('🔒 Детали: ${canCreateResult['currentCount']}/${canCreateResult['maxLimit']}');
      }

      return canCreate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      }
      return false;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка возможности создания с детализацией через новую Firebase систему
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

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем новую Firebase систему
      final itemType = _getFirebaseItemType(contentType);
      final result = await _firebaseService.canCreateItem(itemType);

      final canCreate = result['canProceed'] ?? false;
      final currentCount = result['currentCount'] ?? 0;
      final maxLimit = result['maxLimit'] ?? 0;
      final remaining = result['remaining'] ?? 0;

      ContentCreationBlockReason? reason;
      if (!canCreate) {
        reason = ContentCreationBlockReason.limitReached;
      }

      if (kDebugMode) {
        debugPrint('🔒 Детальная проверка $contentType: $currentCount/$maxLimit, можно: $canCreate, осталось: $remaining');
      }

      return ContentCreationResult(
        canCreate: canCreate,
        reason: reason,
        currentCount: currentCount,
        limit: maxLimit,
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

  /// 🔥 ИСПРАВЛЕНО: Увеличение счетчика использования через новую Firebase систему
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      // Если премиум - не увеличиваем счетчик
      if (_hasPremiumAccess()) {
        if (kDebugMode) {
          debugPrint('🧪 Премиум пользователь - счетчик не увеличивается для $contentType');
        }
        return true;
      }

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем новую Firebase систему
      final itemType = _getFirebaseItemType(contentType);

      // Сначала проверяем можно ли создать
      final canCreateResult = await _firebaseService.canCreateItem(itemType);
      if (!(canCreateResult['canProceed'] ?? false)) {
        if (kDebugMode) {
          debugPrint('⚠️ Достигнут лимит для типа: $contentType');
        }
        return false;
      }

      // Увеличиваем счетчик
      final success = await _firebaseService.incrementUsageCount(itemType);

      if (kDebugMode) {
        if (success) {
          debugPrint('✅ Счетчик увеличен для $contentType через новую Firebase систему');
        } else {
          debugPrint('❌ Не удалось увеличить счетчик для $contentType');
        }
      }

      // Обновляем время последнего обновления
      _lastLimitsUpdate = DateTime.now();

      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка увеличения счетчика: $e');
      }
      return false;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Уменьшение счетчика использования через новую Firebase систему
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую Firebase систему
      final itemType = _getFirebaseItemType(contentType);

      // Пока что в новой системе нет метода уменьшения, используем офлайн
      await _offlineStorage.decrementLocalUsage(contentType);

      if (kDebugMode) {
        debugPrint('✅ Счетчик уменьшен для $contentType (офлайн)');
      }

      // Обновляем время последнего обновления
      _lastLimitsUpdate = DateTime.now();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка уменьшения счетчика: $e');
      }
      return false;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Пересчет лимитов через новую Firebase систему
  Future<void> recalculateLimitsWithOffline() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Пересчет лимитов через новую Firebase систему...');
      }

      // Получаем актуальную статистику из новой системы
      final stats = await _firebaseService.getUsageStatistics();

      if (kDebugMode) {
        debugPrint('📊 Статистика из новой Firebase системы:');
        debugPrint('   notesCount: ${stats['notesCount']}');
        debugPrint('   markerMapsCount: ${stats['markerMapsCount']}');
        debugPrint('   expensesCount: ${stats['expensesCount']}');
        debugPrint('   tripsCount: ${stats['tripsCount']}');
        debugPrint('   budgetNotesCount: ${stats['budgetNotesCount']}');
      }

      // Отправляем в стрим
      _limitsController.add(stats);
      _lastLimitsUpdate = DateTime.now();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка пересчета лимитов: $e');
      }
    }
  }

  /// ОБНОВЛЕН: Пересчет лимитов (для совместимости)
  Future<void> recalculateLimits() async {
    await recalculateLimitsWithOffline();
  }

  /// Принудительное обновление данных (для использования в UI)
  Future<void> forceRefresh() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Принудительное обновление лимитов через новую систему...');
      }
      _lastLimitsUpdate = null; // Сбрасываем кэш
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

  /// 🔥 ИСПРАВЛЕНО: Сброс использования по типу через новую Firebase систему
  Future<void> resetUsageForType(ContentType contentType) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую Firebase систему для сброса
      final resetReason = 'reset_${contentType.name}_${DateTime.now().millisecondsSinceEpoch}';
      await _firebaseService.resetUserUsageLimits(resetReason: resetReason);

      if (kDebugMode) {
        debugPrint('✅ Сброшен счетчик для типа: $contentType через новую Firebase систему');
      }

      // Обновляем время последнего обновления
      _lastLimitsUpdate = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса счетчика для типа $contentType: $e');
      }
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получение статистики использования через новую Firebase систему
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      return await _firebaseService.getUsageStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения статистики: $e');
      }
      return {};
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка нужно ли показать предупреждение о лимитах через новую Firebase систему
  Future<List<ContentTypeWarning>> checkForWarnings() async {
    try {
      final warnings = <ContentTypeWarning>[];

      for (final contentType in [
        ContentType.fishingNotes,
        ContentType.markerMaps,
        ContentType.expenses,
      ]) {
        // Получаем информацию о лимитах через новую систему
        final itemType = _getFirebaseItemType(contentType);
        final result = await _firebaseService.canCreateItem(itemType);

        final currentCount = result['currentCount'] ?? 0;
        final maxLimit = result['maxLimit'] ?? 0;
        final remaining = result['remaining'] ?? 0;

        if (maxLimit > 0) {
          // Проверяем нужно ли показывать предупреждение
          final warningThreshold = (maxLimit * 0.8).round(); // 80% от лимита

          if (currentCount >= warningThreshold) {
            final percentage = currentCount / maxLimit;

            warnings.add(ContentTypeWarning(
              contentType: contentType,
              currentCount: currentCount,
              limit: maxLimit,
              remaining: remaining > 0 ? remaining : 0,
              percentage: percentage,
            ));
          }
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

  /// 🔥 ИСПРАВЛЕНО: Сброс всех лимитов через новую Firebase систему
  Future<void> resetAllLimits() async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем новую Firebase систему
      await _firebaseService.resetUserUsageLimits(resetReason: 'admin_reset_all');

      // Также сбрасываем офлайн счетчики
      await _offlineStorage.resetLocalUsageCounters();

      if (kDebugMode) {
        debugPrint('✅ Все лимиты сброшены через новую Firebase систему');
      }

      // Обновляем время последнего обновления
      _lastLimitsUpdate = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка сброса лимитов: $e');
      }
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Получение общей статистики использования через новую Firebase систему
  Future<Map<String, dynamic>> getComprehensiveUsageStats() async {
    try {
      // Получаем статистику из новой Firebase системы
      final stats = await _firebaseService.getUsageStatistics();

      // Добавляем информацию о лимитах
      final Map<String, dynamic> comprehensiveStats = {};

      for (final contentType in ContentType.values) {
        if (contentType != ContentType.depthChart) {
          final itemType = _getFirebaseItemType(contentType);
          final result = await _firebaseService.canCreateItem(itemType);

          final currentCount = result['currentCount'] ?? 0;
          final maxLimit = result['maxLimit'] ?? 0;
          final remaining = result['remaining'] ?? 0;

          comprehensiveStats[contentType.name] = {
            'current': currentCount,
            'limit': maxLimit,
            'remaining': remaining,
            'percentage': maxLimit > 0 ? currentCount / maxLimit : 0.0,
            'canCreate': result['canProceed'] ?? false,
          };
        }
      }

      return {
        'rawStats': stats,
        'contentTypes': comprehensiveStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения комплексной статистики: $e');
      }
      return {};
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

  /// 🔥 УСТАРЕВШИЕ МЕТОДЫ (оставлены для совместимости, но используют новую систему)

  /// Получение текущих лимитов в старом формате (для совместимости)
  UsageLimitsModel? get currentLimits {
    // Возвращаем null, так как теперь используем Map вместо UsageLimitsModel
    return null;
  }

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