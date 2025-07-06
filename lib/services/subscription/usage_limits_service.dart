// Путь: lib/services/subscription/usage_limits_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/subscription_constants.dart';
import '../../models/usage_limits_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/network_utils.dart';

/// Сервис для отслеживания и управления лимитами использования
class UsageLimitsService {
  static final UsageLimitsService _instance = UsageLimitsService._internal();
  factory UsageLimitsService() => _instance;
  UsageLimitsService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш текущих лимитов
  UsageLimitsModel? _cachedLimits;

  // Флаг инициализации для предотвращения повторной инициализации
  bool _isInitialized = false;

  // Стрим для прослушивания изменений лимитов
  final StreamController<UsageLimitsModel> _limitsController =
  StreamController<UsageLimitsModel>.broadcast();

  // Стрим для UI
  Stream<UsageLimitsModel> get limitsStream => _limitsController.stream;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 UsageLimitsService уже инициализирован');
      return;
    }

    try {
      debugPrint('🔄 Инициализация UsageLimitsService...');

      // Загружаем текущие лимиты
      await loadCurrentLimits();

      // КРИТИЧЕСКИ ВАЖНО: Пересчитываем лимиты из реальных данных Firebase
      await recalculateLimits();

      _isInitialized = true;
      debugPrint('✅ UsageLimitsService инициализирован с реальными данными');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации UsageLimitsService: $e');
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
      debugPrint('❌ Ошибка загрузки лимитов: $e');
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

  /// Получение текущего использования (основной метод для SubscriptionService)
  Future<UsageLimitsModel> getCurrentUsage() async {
    try {
      // Если кэш пустой или устаревший - загружаем и пересчитываем
      if (_cachedLimits == null || !_isDataRecent(_cachedLimits!.updatedAt)) {
        await loadCurrentLimits();
        await recalculateLimits();
      }

      return _cachedLimits ?? UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
    } catch (e) {
      debugPrint('❌ Ошибка получения текущего использования: $e');
      return UsageLimitsModel.defaultLimits(_firebaseService.currentUserId ?? '');
    }
  }

  /// Проверка возможности создания нового контента
  Future<bool> canCreateContent(ContentType contentType) async {
    try {
      final limits = await getCurrentUsage();

      // Для графика глубин проверяем только премиум статус
      if (contentType == ContentType.depthChart) {
        // График глубин доступен только с премиум подпиской
        // Здесь нужно будет добавить проверку премиум статуса
        // Пока возвращаем false
        return false;
      }

      return limits.canCreateNew(contentType);
    } catch (e) {
      debugPrint('❌ Ошибка проверки возможности создания контента: $e');
      return false;
    }
  }

  /// Проверка возможности создания с детализацией
  Future<ContentCreationResult> checkContentCreation(
      ContentType contentType,
      ) async {
    try {
      final limits = await getCurrentUsage();

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

      final canCreate = limits.canCreateNew(contentType);
      final currentCount = limits.getCountForType(contentType);
      final limit = SubscriptionConstants.getContentLimit(contentType);
      final remaining = limits.getRemainingCount(contentType);

      ContentCreationBlockReason? reason;
      if (!canCreate) {
        reason = ContentCreationBlockReason.limitReached;
      }

      return ContentCreationResult(
        canCreate: canCreate,
        reason: reason,
        currentCount: currentCount,
        limit: limit,
        remaining: remaining,
      );
    } catch (e) {
      debugPrint('❌ Ошибка проверки создания контента: $e');
      return ContentCreationResult(
        canCreate: false,
        reason: ContentCreationBlockReason.error,
        currentCount: 0,
        limit: 0,
        remaining: 0,
      );
    }
  }

  /// Увеличение счетчика использования
  Future<bool> incrementUsage(ContentType contentType) async {
    try {
      final limits = await getCurrentUsage();

      // Проверяем можно ли увеличить счетчик
      if (!limits.canCreateNew(contentType)) {
        debugPrint('⚠️ Достигнут лимит для типа: $contentType');
        return false;
      }

      // Увеличиваем счетчик
      final updatedLimits = limits.incrementCounter(contentType);

      // Сохраняем обновленные лимиты
      await _saveLimits(updatedLimits);

      debugPrint('✅ Счетчик увеличен для $contentType: ${updatedLimits.getCountForType(contentType)}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счетчика: $e');
      return false;
    }
  }

  /// Уменьшение счетчика использования (при удалении контента)
  Future<bool> decrementUsage(ContentType contentType) async {
    try {
      final limits = await getCurrentUsage();

      // Уменьшаем счетчик
      final updatedLimits = limits.decrementCounter(contentType);

      // Сохраняем обновленные лимиты
      await _saveLimits(updatedLimits);

      debugPrint('✅ Счетчик уменьшен для $contentType: ${updatedLimits.getCountForType(contentType)}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка уменьшения счетчика: $e');
      return false;
    }
  }

  /// Пересчет лимитов на основе фактических данных
  Future<void> recalculateLimits() async {
    try {
      debugPrint('🔄 Пересчет лимитов использования...');

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ Пользователь не авторизован, пропускаем пересчет');
        return;
      }

      debugPrint('👤 Пересчитываем лимиты для пользователя: $userId');

      // Подсчитываем фактическое количество контента из каждой коллекции
      int actualNotesCount = 0;
      int actualMapsCount = 0;
      int actualExpensesCount = 0;

      if (await NetworkUtils.isNetworkAvailable()) {
        try {
          // Считаем заметки
          debugPrint('📝 Подсчет заметок из коллекции: fishing_notes...');
          final notesQuery = _firestore
              .collection('fishing_notes')
              .where('userId', isEqualTo: userId);

          debugPrint('📝 Выполняем запрос заметок...');
          final notesSnapshot = await notesQuery.get();
          actualNotesCount = notesSnapshot.docs.length;
          debugPrint('📝 Найдено заметок: $actualNotesCount');

          // Считаем маркерные карты
          debugPrint('🗺️ Подсчет карт из коллекции: marker_maps...');
          final mapsQuery = _firestore
              .collection('marker_maps')
              .where('userId', isEqualTo: userId);

          debugPrint('🗺️ Выполняем запрос карт...');
          final mapsSnapshot = await mapsQuery.get();
          actualMapsCount = mapsSnapshot.docs.length;
          debugPrint('🗺️ Найдено карт: $actualMapsCount');

          // Считаем расходы (по уникальным tripId)
          debugPrint('💰 Подсчет расходов из коллекции: fishing_trips...');
          final expensesQuery = _firestore
              .collection('fishing_trips')
              .where('userId', isEqualTo: userId);

          debugPrint('💰 Выполняем запрос расходов...');
          final expensesSnapshot = await expensesQuery.get();

          // Считаем количество поездок (каждая поездка = один элемент расходов)
          actualExpensesCount = expensesSnapshot.docs.length;
          debugPrint('💰 Найдено поездок: $actualExpensesCount');

          // Показываем ID всех поездок для диагностики
          final tripIds = expensesSnapshot.docs.map((doc) => doc.id).toList();
          debugPrint('💰 ID поездок: $tripIds');

        } catch (e) {
          debugPrint('❌ Ошибка подсчета данных из Firebase: $e');
          // В случае ошибки используем данные из кэша
          final currentLimits = _cachedLimits ?? UsageLimitsModel.defaultLimits(userId);
          actualNotesCount = currentLimits.notesCount;
          actualMapsCount = currentLimits.markerMapsCount;
          actualExpensesCount = currentLimits.expensesCount;
          debugPrint('💾 Используем кэшированные данные: $actualNotesCount/$actualMapsCount/$actualExpensesCount');
        }
      } else {
        debugPrint('🔌 Нет интернета, используем кэшированные данные');
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

      debugPrint('✅ Лимиты пересчитаны и сохранены:');
      debugPrint('   📝 Заметки: $actualNotesCount/${SubscriptionConstants.freeNotesLimit}');
      debugPrint('   🗺️ Карты: $actualMapsCount/${SubscriptionConstants.freeMarkerMapsLimit}');
      debugPrint('   💰 Расходы: $actualExpensesCount/${SubscriptionConstants.freeExpensesLimit}');
    } catch (e) {
      debugPrint('❌ Критическая ошибка пересчета лимитов: $e');
    }
  }

  /// Принудительное обновление данных (для использования в UI)
  Future<void> forceRefresh() async {
    try {
      debugPrint('🔄 Принудительное обновление лимитов...');
      _cachedLimits = null; // Очищаем кэш
      await loadCurrentLimits();
      await recalculateLimits();
      debugPrint('✅ Принудительное обновление завершено');
    } catch (e) {
      debugPrint('❌ Ошибка принудительного обновления: $e');
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
      debugPrint('✅ Сброшен счетчик для типа: $contentType');
    } catch (e) {
      debugPrint('❌ Ошибка сброса счетчика для типа $contentType: $e');
    }
  }

  /// Получение статистики использования
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final limits = await getCurrentUsage();
      return limits.getUsageStats();
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Проверка нужно ли показать предупреждение о лимитах
  Future<List<ContentTypeWarning>> checkForWarnings() async {
    try {
      final limits = await getCurrentUsage();
      final warnings = <ContentTypeWarning>[];

      for (final contentType in [
        ContentType.fishingNotes,
        ContentType.markerMaps,
        ContentType.expenses,
      ]) {
        if (limits.shouldShowWarning(contentType)) {
          warnings.add(ContentTypeWarning(
            contentType: contentType,
            currentCount: limits.getCountForType(contentType),
            limit: SubscriptionConstants.getContentLimit(contentType),
            remaining: limits.getRemainingCount(contentType),
            percentage: limits.getUsagePercentage(contentType),
          ));
        }
      }

      return warnings;
    } catch (e) {
      debugPrint('❌ Ошибка проверки предупреждений: $e');
      return [];
    }
  }

  /// Сброс всех лимитов (для админских целей)
  Future<void> resetAllLimits() async {
    try {
      final limits = await getCurrentUsage();
      final resetLimits = limits.resetAllCounters();
      await _saveLimits(resetLimits);
      debugPrint('✅ Все лимиты сброшены');
    } catch (e) {
      debugPrint('❌ Ошибка сброса лимитов: $e');
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
      debugPrint('❌ Ошибка сохранения лимитов: $e');
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
        debugPrint('💾 Лимиты сохранены в Firebase');
      } else {
        debugPrint('🔌 Нет интернета, сохранение в Firebase пропущено');
      }
    } catch (e) {
      debugPrint('❌ Ошибка сохранения в Firebase: $e');
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
      debugPrint('💾 Лимиты сохранены в локальный кэш');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения лимитов в кэш: $e');
    }
  }

  /// Загрузка лимитов из локального кэша
  Future<UsageLimitsModel> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Проверяем соответствие пользователя
      final cachedUserId = prefs.getString('cached_user_id');
      if (cachedUserId != userId) {
        debugPrint('👤 Смена пользователя, создаем новые лимиты');
        return UsageLimitsModel.defaultLimits(userId);
      }

      final notesCount = prefs.getInt('cached_notes_count') ?? 0;
      final mapsCount = prefs.getInt('cached_maps_count') ?? 0;
      final expensesCount = prefs.getInt('cached_expenses_count') ?? 0;
      final updatedString = prefs.getString('cached_limits_updated');

      final updatedAt = updatedString != null
          ? DateTime.tryParse(updatedString) ?? DateTime.now()
          : DateTime.now();

      debugPrint('💾 Лимиты загружены из кэша: $notesCount/$mapsCount/$expensesCount');

      return UsageLimitsModel(
        userId: userId,
        notesCount: notesCount,
        markerMapsCount: mapsCount,
        expensesCount: expensesCount,
        lastResetDate: updatedAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки лимитов из кэша: $e');
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