// Путь: lib/repositories/budget_notes_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_expense_model.dart';
import '../models/fishing_trip_model.dart';
import '../models/isar/budget_note_entity.dart';
import '../services/firebase/firebase_service.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../utils/network_utils.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

/// ✅ ИСПРАВЛЕННЫЙ Repository для управления заметками бюджета через Isar с правильной синхронизацией
class BudgetNotesRepository {
  static final BudgetNotesRepository _instance = BudgetNotesRepository._internal();

  factory BudgetNotesRepository() {
    return _instance;
  }

  BudgetNotesRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance; // ✅ ДОБАВЛЕНО: Используем SyncService
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingTripModel>? _cachedTrips;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// ✅ НОВОЕ: Инициализация репозитория
  Future<void> initialize() async {
    try {
      // ✅ УБРАНО: debugPrint с уведомлением об инициализации

      // IsarService должен быть уже инициализирован в main.dart
      if (!_isarService.isInitialized) {
        await _isarService.init();
      }

      // ✅ УБРАНО: debugPrint с подтверждением инициализации
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки инициализации
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получить все заметки бюджета пользователя через Isar
  Future<List<FishingTripModel>> getUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ УБРАНО: debugPrint('🏦 BudgetNotesRepository.getUserTrips() - userId: $userId');

      // Проверяем кэш
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          // ✅ УБРАНО: debugPrint с информацией о возврате данных из кэша
          return _cachedTrips!;
        } else {
          // ✅ УБРАНО: debugPrint об устаревшем кэше
          _cachedTrips = null;
          _cacheTimestamp = null;
        }
      }

      // ✅ ИСПРАВЛЕНО: Получаем данные из Isar и конвертируем правильно
      final budgetEntities = await _isarService.getAllBudgetNotes(userId);
      // ✅ УБРАНО: debugPrint('💾 Найдено ${budgetEntities.length} заметок бюджета в Isar');

      // Преобразуем в FishingTripModel для совместимости
      final trips = budgetEntities.map((entity) => entity.toTripModel()).toList();

      // Проверяем подключение к интернету для синхронизации
      final isOnline = await NetworkUtils.isNetworkAvailable();
      // ✅ УБРАНО: debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Используем SyncService вместо собственной логики
        final hasUnsyncedData = budgetEntities.any((entity) => !entity.isSynced);
        if (hasUnsyncedData) {
          // ✅ УБРАНО: debugPrint о найденных несинхронизированных данных
          _triggerSyncServiceInBackground();
        }

        // Также синхронизируем данные из Firebase если нужно
        _triggerSyncFromFirebaseInBackground();
      }

      // ✅ УБРАНО: Все логи с деталями заметок бюджета:
      // - debugPrint('📊 Итого заметок бюджета: ${trips.length}');
      // - debugPrint('  📍 Поездка: ${trip.locationName}');
      // - debugPrint('     Дата: ${trip.date}');
      // - debugPrint('     Расходов: ${trip.expenses.length}');
      // - debugPrint('     Общая сумма: ${trip.expenses.fold<double>(0, (sum, expense) => sum + expense.amount)}');

      // Кэшируем результат
      _cachedTrips = trips;
      _cacheTimestamp = DateTime.now();

      return trips;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки в getUserTrips

      // В случае ошибки, пытаемся вернуть хотя бы данные из Isar
      try {
        final userId = _firebaseService.currentUserId;
        if (userId != null) {
          final budgetEntities = await _isarService.getAllBudgetNotes(userId);
          return budgetEntities.map((entity) => entity.toTripModel()).toList();
        }
      } catch (_) {
        // В крайнем случае возвращаем пустой список
      }
      return [];
    }
  }

  /// ✅ ИСПРАВЛЕНО: Создать новую заметку бюджета с расходами через Isar
  Future<FishingTripModel> createTripWithExpenses({
    required DateTime date,
    String? locationName,
    String? notes,
    String currency = 'KZT',
    required Map<FishingExpenseCategory, double> categoryAmounts,
    required Map<FishingExpenseCategory, String> categoryDescriptions,
    required Map<FishingExpenseCategory, String> categoryNotes,
  }) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ УБРАНО: debugPrint о создании заметки бюджета с расходами

      // ✅ Проверяем лимиты для budgetNotes
      final canCreate = await _subscriptionService.canCreateContentOffline(
        ContentType.budgetNotes,
      );

      if (!canCreate) {
        throw Exception('Достигнут лимит создания заметок бюджета');
      }

      // Создаем расходы для категорий с указанными суммами
      final List<FishingExpenseModel> expenses = [];
      int expenseIndex = 0;

      for (final category in FishingExpenseCategory.allCategories) {
        final amount = categoryAmounts[category] ?? 0.0;
        if (amount > 0) {
          final description = categoryDescriptions[category]?.trim() ?? '';
          final expenseNotes = categoryNotes[category]?.trim() ?? '';

          // Создаем уникальный ID для каждого расхода
          final now = DateTime.now();
          final expenseId = 'expense_${now.millisecondsSinceEpoch}_$expenseIndex';

          final expense = FishingExpenseModel(
            id: expenseId,
            userId: userId,
            tripId: '', // Будет установлен после создания заметки
            amount: amount,
            description: description.isNotEmpty ? description : 'Расходы',
            category: category,
            date: date,
            currency: currency,
            notes: expenseNotes.isEmpty ? null : expenseNotes,
            locationName: locationName,
            createdAt: now,
            updatedAt: now,
            isSynced: false,
          );

          expenses.add(expense);
          expenseIndex++;
        }
      }

      // ✅ УБРАНО: debugPrint('🏦 Создано ${expenses.length} расходов');

      // Генерируем уникальный ID
      final tripId = const Uuid().v4();

      // Обновляем tripId в расходах
      final updatedExpenses = expenses.map((expense) =>
          expense.copyWith(tripId: tripId)
      ).toList();

      // ✅ ИСПРАВЛЕНО: Создаем BudgetNoteEntity для Isar
      final budgetEntity = BudgetNoteEntity.create(
        customId: tripId,
        userId: userId,
        date: date,
        locationName: locationName,
        notes: notes,
        currency: currency,
        expenses: updatedExpenses,
      );

      // ✅ НОВОЕ: Сохраняем в Isar
      await _isarService.insertBudgetNote(budgetEntity);
      // ✅ УБРАНО: debugPrint('💾 Заметка бюджета сохранена в Isar: $tripId');

      // Увеличиваем счетчик
      try {
        await _subscriptionService.incrementUsage(ContentType.budgetNotes);
        // ✅ УБРАНО: debugPrint с подтверждением увеличения счетчика
      } catch (e) {
        // ✅ УБРАНО: debugPrint с деталями ошибки увеличения счетчика
      }

      // Очищаем кэш после создания новой заметки
      clearCache();

      // ✅ ИСПРАВЛЕНО: Запускаем синхронизацию через SyncService
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _triggerSyncServiceInBackground();
      }

      // Возвращаем FishingTripModel для совместимости
      return budgetEntity.toTripModel();
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки создания заметки бюджета
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Обновить заметку бюджета через Isar
  Future<FishingTripModel> updateTrip(FishingTripModel trip) async {
    try {
      if (trip.id.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ УБРАНО: debugPrint('🏦 Обновление заметки бюджета: ${trip.id}');

      // ✅ ИСПРАВЛЕНО: Находим существующую запись в Isar
      final existingEntity = await _isarService.getBudgetNoteByFirebaseId(trip.id);

      if (existingEntity != null) {
        // Обновляем существующую запись
        final updatedEntity = BudgetNoteEntity.fromTripModel(trip);
        updatedEntity.id = existingEntity.id; // Сохраняем Isar ID
        updatedEntity.markAsModified(); // Помечаем как измененную

        await _isarService.updateBudgetNote(updatedEntity);
        // ✅ УБРАНО: debugPrint с подтверждением обновления в Isar
      } else {
        // Создаем новую запись если не найдена
        final newEntity = BudgetNoteEntity.fromTripModel(trip);
        newEntity.markAsModified();

        await _isarService.insertBudgetNote(newEntity);
        // ✅ УБРАНО: debugPrint о создании заметки в Isar (не найдена для обновления)
      }

      // Очищаем кэш после обновления заметки
      clearCache();

      // ✅ ИСПРАВЛЕНО: Запускаем синхронизацию через SyncService
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _triggerSyncServiceInBackground();
      }

      return trip;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при обновлении заметки бюджета
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение заметки бюджета по ID через Isar
  Future<FishingTripModel?> getTripById(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ УБРАНО: debugPrint('🏦 Получение заметки бюджета по ID: $tripId');

      // ✅ ИСПРАВЛЕНО: Ищем в Isar
      final budgetEntity = await _isarService.getBudgetNoteByFirebaseId(tripId);

      if (budgetEntity != null) {
        // ✅ УБРАНО: debugPrint с подтверждением нахождения заметки бюджета в Isar
        return budgetEntity.toTripModel();
      }

      // ✅ УБРАНО: debugPrint('⚠️ Заметка бюджета не найдена: $tripId');
      return null;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении заметки бюджета
      return null;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Удалить заметку бюджета с двухэтапной логикой (онлайн/офлайн)
  Future<void> deleteTrip(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🗑️ BudgetNotesRepository: Начинаем удаление заметки бюджета $tripId');

      // 🔥 НОВОЕ: Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 BudgetNotesRepository: Статус сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // 🔥 ОНЛАЙН: Сразу удаляем из Firebase + Isar
        debugPrint('📱 BudgetNotesRepository: Режим ОНЛАЙН - сразу удаляем из Firebase и Isar');
        final result = await _syncService.deleteBudgetNoteByFirebaseId(tripId);

        if (result) {
          debugPrint('✅ BudgetNotesRepository: Онлайн удаление прошло успешно');
        } else {
          debugPrint('⚠️ BudgetNotesRepository: Онлайн удаление завершилось с предупреждениями');
        }
      } else {
        // 🔥 ОФЛАЙН: Помечаем для удаления, НЕ удаляем физически
        debugPrint('📴 BudgetNotesRepository: Режим ОФЛАЙН - помечаем для удаления');

        try {
          await _isarService.markBudgetNoteForDeletion(tripId);
          debugPrint('✅ BudgetNotesRepository: Заметка бюджета помечена для офлайн удаления');
        } catch (e) {
          debugPrint('❌ BudgetNotesRepository: Ошибка при маркировке заметки для удаления: $e');
          rethrow;
        }
      }

      // 🔥 ВСЕГДА: Уменьшаем счетчик независимо от режима
      try {
        await _subscriptionService.decrementUsage(ContentType.budgetNotes);
        debugPrint('✅ BudgetNotesRepository: Счетчик лимитов уменьшен');
      } catch (e) {
        debugPrint('❌ BudgetNotesRepository: Ошибка уменьшения счетчика: $e');
        // Не прерываем выполнение, заметка уже удалена/помечена
      }

      // Очищаем кэш после удаления заметки
      clearCache();

      // 🔥 ЗАПУСКАЕМ СИНХРОНИЗАЦИЮ: Если онлайн или при включении интернета
      if (isOnline) {
        _triggerSyncServiceInBackground();
      }

      debugPrint('🎯 BudgetNotesRepository: Удаление заметки бюджета завершено успешно');
    } catch (e) {
      debugPrint('❌ BudgetNotesRepository: Критическая ошибка при удалении заметки бюджета $tripId: $e');
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Фоновая синхронизация через SyncService
  void _triggerSyncServiceInBackground() async {
    try {
      // ✅ УБРАНО: debugPrint о запуске фоновой синхронизации

      // ✅ ИСПОЛЬЗУЕМ ИСПРАВЛЕННЫЙ SyncService с поддержкой удаления
      final result = await _syncService.syncBudgetNotesToFirebaseWithDeletion();

      if (result) {
        // ✅ УБРАНО: debugPrint с подтверждением успешной фоновой синхронизации
      } else {
        // ✅ УБРАНО: debugPrint с предупреждением о синхронизации с ошибками
      }

      // Очищаем кэш после синхронизации
      clearCache();
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки фоновой синхронизации
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация данных из Firebase через SyncService
  void _triggerSyncFromFirebaseInBackground() async {
    try {
      // ✅ УБРАНО: debugPrint о запуске синхронизации из Firebase

      // ✅ ИСПОЛЬЗУЕМ ИСПРАВЛЕННЫЙ SyncService
      final result = await _syncService.syncBudgetNotesFromFirebase();

      if (result) {
        // ✅ УБРАНО: debugPrint с подтверждением успешной синхронизации из Firebase
      } else {
        // ✅ УБРАНО: debugPrint с предупреждением о синхронизации из Firebase с ошибками
      }

      // Очищаем кэш после синхронизации
      clearCache();
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки синхронизации из Firebase
    }
  }

  // ========================================
  // ОСТАЛЬНЫЕ МЕТОДЫ (сохраняем совместимость)
  // ========================================

  /// Получить суммированные расходы по категориям
  Future<Map<FishingExpenseCategory, CategoryExpenseSummary>> getCategorySummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ✅ УБРАНО: debugPrint о получении сводки по категориям

      // Используем кэшированные данные если доступны
      List<FishingTripModel> trips;
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          // ✅ УБРАНО: debugPrint о использовании кэшированных заметок для анализа
          trips = _cachedTrips!;
        } else {
          // ✅ УБРАНО: debugPrint об устаревшем кэше
          trips = await getUserTrips();
        }
      } else {
        // ✅ УБРАНО: debugPrint об отсутствии кэша
        trips = await getUserTrips();
      }

      // ✅ УБРАНО: debugPrint('🏦 Получено ${trips.length} заметок для анализа');

      // Фильтруем заметки по периоду
      final filteredTrips = trips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      // ✅ УБРАНО: debugPrint('🏦 После фильтрации осталось ${filteredTrips.length} заметок');

      final Map<FishingExpenseCategory, CategoryExpenseSummary> summaries = {};

      for (final category in FishingExpenseCategory.allCategories) {
        double totalAmount = 0;
        int expenseCount = 0;
        int tripCount = 0;
        String currency = 'KZT';

        for (final trip in filteredTrips) {
          bool hasCategoryInTrip = false;

          for (final expense in trip.expenses) {
            if (expense.category == category) {
              totalAmount += expense.amount;
              expenseCount++;
              currency = expense.currency;
              hasCategoryInTrip = true;
            }
          }

          if (hasCategoryInTrip) {
            tripCount++;
          }
        }

        if (totalAmount > 0) {
          summaries[category] = CategoryExpenseSummary(
            category: category,
            totalAmount: totalAmount,
            expenseCount: expenseCount,
            tripCount: tripCount,
            currency: currency,
          );

          // ✅ УБРАНО: debugPrint с деталями категории и суммой
        }
      }

      // ✅ УБРАНО: debugPrint('✅ Получено ${summaries.length} категорий с расходами');
      return summaries;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения сводки по категориям
      return {};
    }
  }

  /// Получить статистику заметок бюджета
  Future<FishingTripStatistics> getTripStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Используем кэшированные данные если доступны
      List<FishingTripModel> allTrips;
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          // ✅ УБРАНО: debugPrint о использовании кэшированных заметок для статистики
          allTrips = _cachedTrips!;
        } else {
          // ✅ УБРАНО: debugPrint об устаревшем кэше для статистики
          allTrips = await getUserTrips();
        }
      } else {
        // ✅ УБРАНО: debugPrint об отсутствии кэша для статистики
        allTrips = await getUserTrips();
      }

      // Фильтруем заметки по периоду
      final filteredTrips = allTrips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      return FishingTripStatistics.fromTrips(
        filteredTrips,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения статистики заметок бюджета
      return FishingTripStatistics.fromTrips([]);
    }
  }

  /// Поиск заметок бюджета
  Future<List<FishingTripModel>> searchTrips(String query) async {
    try {
      if (query.trim().isEmpty) return getUserTrips();

      final allTrips = await getUserTrips();
      final lowercaseQuery = query.toLowerCase();

      return allTrips.where((trip) {
        return trip.locationName?.toLowerCase().contains(lowercaseQuery) == true ||
            trip.notes?.toLowerCase().contains(lowercaseQuery) == true ||
            trip.expenses.any((expense) =>
            expense.description.toLowerCase().contains(lowercaseQuery) ||
                expense.notes?.toLowerCase().contains(lowercaseQuery) == true
            );
      }).toList();
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки поиска заметок бюджета
      return [];
    }
  }

  /// Проверка возможности создания новой заметки бюджета
  Future<bool> canCreateTrip() async {
    try {
      return await _subscriptionService.canCreateContentOffline(
        ContentType.budgetNotes,
      );
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при проверке возможности создания заметки бюджета
      return false;
    }
  }

  /// Получение текущего использования заметок бюджета
  Future<int> getCurrentUsage() async {
    try {
      return await _subscriptionService.getCurrentUsage(
        ContentType.budgetNotes,
      );
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении текущего использования заметок бюджета
      return 0;
    }
  }

  /// Получение лимита заметок бюджета
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.budgetNotes);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении лимита заметок бюджета
      return 0;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удалить все заметки бюджета пользователя
  Future<void> deleteAllUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ УБРАНО: debugPrint('🏦 Удаление всех заметок бюджета пользователя: $userId');

      // ✅ ИСПРАВЛЕНО: Удаляем все из Isar
      await _isarService.deleteAllBudgetNotes(userId);

      // Очищаем кэш
      clearCache();

      // ✅ УБРАНО: debugPrint с подтверждением удаления всех заметок бюджета
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при удалении всех заметок бюджета
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Принудительная синхронизация данных через SyncService
  Future<bool> forceSyncData() async {
    try {
      // ✅ УБРАНО: debugPrint о принудительной синхронизации через SyncService

      // ✅ ИСПОЛЬЗУЕМ ПОЛНУЮ СИНХРОНИЗАЦИЮ SyncService
      final result = await _syncService.fullSync();

      if (result) {
        // ✅ УБРАНО: debugPrint с подтверждением успешной принудительной синхронизации
      } else {
        // ✅ УБРАНО: debugPrint с предупреждением о синхронизации с ошибками
      }

      // Очищаем кэш
      clearCache();

      return result;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при принудительной синхронизации через SyncService
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получить статус синхронизации через SyncService
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final syncStatus = await _syncService.getSyncStatus();
      final budgetStatus = syncStatus['budgetNotes'] as Map<String, dynamic>? ?? {};

      return {
        'total': budgetStatus['total'] ?? 0,
        'unsynced': budgetStatus['unsynced'] ?? 0,
        'synced': budgetStatus['synced'] ?? 0,
        'hasInternet': await NetworkUtils.isNetworkAvailable(),
      };
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки получения статуса синхронизации через SyncService
      return {
        'total': 0,
        'unsynced': 0,
        'synced': 0,
        'hasInternet': false,
        'error': e.toString(),
      };
    }
  }

  /// Очистить кеш данных
  static void clearCache() {
    _cachedTrips = null;
    _cacheTimestamp = null;
    // ✅ УБРАНО: debugPrint с уведомлением об очистке кэша заметок бюджета
  }

  // ========================================
  // МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ СО СТАРЫМ КОДОМ
  // ========================================

  /// Устаревший метод - теперь не используется
  @Deprecated('Используйте getUserTrips() и работайте с расходами внутри заметок')
  Future<List<FishingExpenseModel>> getUserExpenses() async {
    final trips = await getUserTrips();
    final allExpenses = <FishingExpenseModel>[];

    for (final trip in trips) {
      allExpenses.addAll(trip.expenses);
    }

    return allExpenses;
  }

  /// Устаревший метод - теперь не используется
  @Deprecated('Используйте updateTrip()')
  Future<FishingExpenseModel> addExpense(FishingExpenseModel expense) async {
    throw UnimplementedError('Метод больше не поддерживается. Используйте createTripWithExpenses()');
  }

  /// Устаревший метод - теперь не используется
  @Deprecated('Используйте updateTrip()')
  Future<void> deleteExpense(String expenseId) async {
    throw UnimplementedError('Метод больше не поддерживается. Редактируйте заметку бюджета целиком');
  }
}

/// Сводка расходов по категории (сохраняем для совместимости)
class CategoryExpenseSummary {
  final FishingExpenseCategory category;
  final double totalAmount;
  final int expenseCount;
  final int tripCount;
  final String currency;

  const CategoryExpenseSummary({
    required this.category,
    required this.totalAmount,
    required this.expenseCount,
    required this.tripCount,
    required this.currency,
  });

  String get currencySymbol {
    switch (currency) {
      case 'KZT':
        return '₸';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'RUB':
        return '₽';
      default:
        return currency;
    }
  }

  String get formattedAmount {
    return '$currencySymbol ${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';
  }

  String get tripCountDescription {
    if (tripCount == 1) {
      return 'из 1 заметки';
    } else if (tripCount >= 2 && tripCount <= 4) {
      return 'из $tripCount заметок';
    } else {
      return 'из $tripCount заметок';
    }
  }
}