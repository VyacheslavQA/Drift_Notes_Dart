// Путь: lib/repositories/budget_notes_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_expense_model.dart';
import '../models/fishing_trip_model.dart';
import '../models/isar/budget_note_entity.dart';
import '../services/firebase/firebase_service.dart';
import '../services/isar_service.dart';
import '../utils/network_utils.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

/// ✅ ОБНОВЛЕННЫЙ Repository для управления заметками бюджета через Isar
class BudgetNotesRepository {
  static final BudgetNotesRepository _instance = BudgetNotesRepository._internal();

  factory BudgetNotesRepository() {
    return _instance;
  }

  BudgetNotesRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final IsarService _isarService = IsarService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingTripModel>? _cachedTrips;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// ✅ НОВОЕ: Инициализация репозитория
  Future<void> initialize() async {
    try {
      debugPrint('🏦 Инициализация BudgetNotesRepository...');

      // IsarService должен быть уже инициализирован в main.dart
      if (!_isarService.isInitialized) {
        await _isarService.init();
      }

      debugPrint('✅ BudgetNotesRepository инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации BudgetNotesRepository: $e');
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

      debugPrint('🏦 BudgetNotesRepository.getUserTrips() - userId: $userId');

      // Проверяем кэш
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Возвращаем данные из кэша (возраст: ${cacheAge.inSeconds}с)');
          return _cachedTrips!;
        } else {
          debugPrint('💾 Кэш устарел, очищаем');
          _cachedTrips = null;
          _cacheTimestamp = null;
        }
      }

      // ✅ ИСПРАВЛЕНО: Получаем данные из Isar и конвертируем правильно
      final budgetEntities = await _isarService.getAllBudgetNotes(userId);
      debugPrint('💾 Найдено ${budgetEntities.length} заметок бюджета в Isar');

      // Преобразуем в FishingTripModel для совместимости
      final trips = budgetEntities.map((entity) => entity.toTripModel()).toList();

      // Проверяем подключение к интернету для синхронизации
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Запускаем синхронизацию в фоне если есть несинхронизированные данные
        final hasUnsyncedData = budgetEntities.any((entity) => !entity.isSynced);
        if (hasUnsyncedData) {
          debugPrint('🔄 Найдены несинхронизированные данные, запускаем синхронизацию');
          _syncBudgetNotesInBackground();
        }

        // Также синхронизируем данные из Firebase если нужно
        _syncFromFirebaseInBackground(userId);
      }

      debugPrint('📊 Итого заметок бюджета: ${trips.length}');

      // Кэшируем результат
      _cachedTrips = trips;
      _cacheTimestamp = DateTime.now();

      return trips;
    } catch (e) {
      debugPrint('❌ Ошибка в getUserTrips: $e');

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

      debugPrint('🏦 Создание заметки бюджета с расходами...');

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

      debugPrint('🏦 Создано ${expenses.length} расходов');

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
      debugPrint('💾 Заметка бюджета сохранена в Isar: $tripId');

      // Увеличиваем счетчик
      try {
        await _subscriptionService.incrementUsage(ContentType.budgetNotes);
        debugPrint('✅ Счетчик заметок бюджета увеличен');
      } catch (e) {
        debugPrint('❌ Ошибка увеличения счетчика заметок бюджета: $e');
      }

      // Очищаем кэш после создания новой заметки
      clearCache();

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncBudgetNotesInBackground();
      }

      // Возвращаем FishingTripModel для совместимости
      return budgetEntity.toTripModel();
    } catch (e) {
      debugPrint('❌ Ошибка создания заметки бюджета: $e');
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

      debugPrint('🏦 Обновление заметки бюджета: ${trip.id}');

      // ✅ ИСПРАВЛЕНО: Находим существующую запись в Isar
      final existingEntity = await _isarService.getBudgetNoteByFirebaseId(trip.id);

      if (existingEntity != null) {
        // Обновляем существующую запись
        final updatedEntity = BudgetNoteEntity.fromTripModel(trip);
        updatedEntity.id = existingEntity.id; // Сохраняем Isar ID
        updatedEntity.markAsModified(); // Помечаем как измененную

        await _isarService.updateBudgetNote(updatedEntity);
        debugPrint('💾 Заметка бюджета обновлена в Isar');
      } else {
        // Создаем новую запись если не найдена
        final newEntity = BudgetNoteEntity.fromTripModel(trip);
        newEntity.markAsModified();

        await _isarService.insertBudgetNote(newEntity);
        debugPrint('💾 Заметка бюджета создана в Isar (не найдена для обновления)');
      }

      // Очищаем кэш после обновления заметки
      clearCache();

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncBudgetNotesInBackground();
      }

      return trip;
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки бюджета: $e');
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

      debugPrint('🏦 Получение заметки бюджета по ID: $tripId');

      // ✅ ИСПРАВЛЕНО: Ищем в Isar
      final budgetEntity = await _isarService.getBudgetNoteByFirebaseId(tripId);

      if (budgetEntity != null) {
        debugPrint('✅ Заметка бюджета найдена в Isar');
        return budgetEntity.toTripModel();
      }

      debugPrint('⚠️ Заметка бюджета не найдена: $tripId');
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки бюджета: $e');
      return null;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удалить заметку бюджета через Isar
  Future<void> deleteTrip(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🏦 Удаление заметки бюджета: $tripId');

      // ✅ ИСПРАВЛЕНО: Находим и помечаем для удаления в Isar
      final budgetEntity = await _isarService.getBudgetNoteByFirebaseId(tripId);

      if (budgetEntity != null) {
        if (budgetEntity.isSynced) {
          // Если синхронизирована, помечаем для удаления
          await _isarService.markBudgetNoteForDeletion(tripId);
          debugPrint('💾 Заметка бюджета помечена для удаления');
        } else {
          // Если не синхронизирована, удаляем сразу
          await _isarService.deleteBudgetNote(budgetEntity.id);
          debugPrint('💾 Несинхронизированная заметка бюджета удалена');
        }
      }

      // Уменьшаем счетчик
      try {
        await _subscriptionService.decrementUsage(ContentType.budgetNotes);
        debugPrint('✅ Счетчик заметок бюджета уменьшен');
      } catch (e) {
        debugPrint('⚠️ Ошибка уменьшения счетчика: $e');
      }

      // Очищаем кэш после удаления заметки
      clearCache();

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncBudgetNotesInBackground();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки бюджета: $e');
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Фоновая синхронизация заметок бюджета с Firebase
  void _syncBudgetNotesInBackground() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return;

      debugPrint('🔄 Запуск фоновой синхронизации заметок бюджета...');

      // Получаем несинхронизированные заметки
      final unsyncedNotes = await _isarService.getUnsyncedBudgetNotes(userId);

      for (final entity in unsyncedNotes) {
        try {
          if (entity.firebaseId != null) {
            // Обновляем существующую заметку в Firebase
            final budgetData = entity.toMapWithExpenses();
            await _firebaseService.updateBudgetNote(entity.firebaseId!, budgetData);

            // Помечаем как синхронизированную
            await _isarService.markBudgetNoteAsSynced(entity.id, entity.firebaseId!);

            debugPrint('✅ Заметка бюджета обновлена в Firebase: ${entity.firebaseId}');
          } else {
            // Создаем новую заметку в Firebase
            final budgetData = entity.toMapWithExpenses();
            final noteRef = await _firebaseService.addBudgetNote(budgetData);

            // Помечаем как синхронизированную с новым Firebase ID
            await _isarService.markBudgetNoteAsSynced(entity.id, noteRef.id);

            debugPrint('✅ Заметка бюджета создана в Firebase: ${noteRef.id}');
          }
        } catch (e) {
          debugPrint('❌ Ошибка синхронизации заметки бюджета ${entity.firebaseId}: $e');
        }
      }

      debugPrint('✅ Фоновая синхронизация заметок бюджета завершена');
    } catch (e) {
      debugPrint('❌ Ошибка фоновой синхронизации заметок бюджета: $e');
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация данных из Firebase в Isar
  void _syncFromFirebaseInBackground(String userId) async {
    try {
      debugPrint('🔄 Синхронизация заметок бюджета из Firebase...');

      final snapshot = await _firebaseService.getUserBudgetNotes();

      for (var doc in snapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = firebaseId;

          // Проверяем, есть ли уже такая заметка в Isar
          final existingEntity = await _isarService.getBudgetNoteByFirebaseId(firebaseId);

          if (existingEntity == null) {
            // Создаем новую запись в Isar
            final entity = BudgetNoteEntity.fromMapWithExpenses(data);
            entity.markAsSynced();

            await _isarService.insertBudgetNote(entity);
            debugPrint('✅ Новая заметка бюджета добавлена в Isar: $firebaseId');
          } else {
            // Проверяем, нужно ли обновить существующую запись
            final firebaseUpdatedAt = DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int);

            if (firebaseUpdatedAt.isAfter(existingEntity.updatedAt)) {
              // Обновляем данными из Firebase
              final updatedEntity = BudgetNoteEntity.fromMapWithExpenses(data);
              updatedEntity.id = existingEntity.id; // Сохраняем Isar ID
              updatedEntity.markAsSynced();

              await _isarService.updateBudgetNote(updatedEntity);
              debugPrint('✅ Заметка бюджета обновлена из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          debugPrint('❌ Ошибка обработки заметки бюджета ${doc.id}: $e');
        }
      }

      // Очищаем кэш после синхронизации
      clearCache();

      debugPrint('✅ Синхронизация из Firebase завершена');
    } catch (e) {
      debugPrint('❌ Ошибка синхронизации из Firebase: $e');
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
      debugPrint('🏦 Получение сводки по категориям...');

      // Используем кэшированные данные если доступны
      List<FishingTripModel> trips;
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Используем кэшированные заметки для анализа');
          trips = _cachedTrips!;
        } else {
          debugPrint('💾 Кэш устарел, загружаем заново');
          trips = await getUserTrips();
        }
      } else {
        debugPrint('💾 Кэша нет, загружаем заметки');
        trips = await getUserTrips();
      }

      debugPrint('🏦 Получено ${trips.length} заметок для анализа');

      // Фильтруем заметки по периоду
      final filteredTrips = trips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      debugPrint('🏦 После фильтрации осталось ${filteredTrips.length} заметок');

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

          debugPrint('✅ Категория ${category.toString()}: ${totalAmount.toStringAsFixed(2)} $currency');
        }
      }

      debugPrint('✅ Получено ${summaries.length} категорий с расходами');
      return summaries;
    } catch (e) {
      debugPrint('❌ Ошибка получения сводки по категориям: $e');
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
          debugPrint('💾 Используем кэшированные заметки для статистики');
          allTrips = _cachedTrips!;
        } else {
          debugPrint('💾 Кэш устарел, загружаем заново для статистики');
          allTrips = await getUserTrips();
        }
      } else {
        debugPrint('💾 Кэша нет, загружаем заметки для статистики');
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
      debugPrint('❌ Ошибка получения статистики заметок бюджета: $e');
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
      debugPrint('❌ Ошибка поиска заметок бюджета: $e');
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
      debugPrint('❌ Ошибка при проверке возможности создания заметки бюджета: $e');
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
      debugPrint('❌ Ошибка при получении текущего использования заметок бюджета: $e');
      return 0;
    }
  }

  /// Получение лимита заметок бюджета
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.budgetNotes);
    } catch (e) {
      debugPrint('❌ Ошибка при получении лимита заметок бюджета: $e');
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

      debugPrint('🏦 Удаление всех заметок бюджета пользователя: $userId');

      // ✅ ИСПРАВЛЕНО: Удаляем все из Isar
      await _isarService.deleteAllBudgetNotes(userId);

      // Очищаем кэш
      clearCache();

      debugPrint('✅ Все заметки бюджета удалены');
    } catch (e) {
      debugPrint('❌ Ошибка при удалении всех заметок бюджета: $e');
      rethrow;
    }
  }

  /// Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return false;

      debugPrint('🔄 Принудительная синхронизация заметок бюджета...');

      // Синхронизируем в обе стороны
      _syncBudgetNotesInBackground();
      _syncFromFirebaseInBackground(userId);

      // Очищаем кэш
      clearCache();

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  /// Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return {};

      final total = await _isarService.getBudgetNotesCount(userId);
      final unsynced = await _isarService.getUnsyncedBudgetNotesCount(userId);

      return {
        'total': total,
        'unsynced': unsynced,
        'synced': total - unsynced,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения статуса синхронизации: $e');
      return {};
    }
  }

  /// Очистить кеш данных
  static void clearCache() {
    _cachedTrips = null;
    _cacheTimestamp = null;
    debugPrint('💾 Кэш заметок бюджета очищен');
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