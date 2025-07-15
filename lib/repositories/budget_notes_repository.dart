// Путь: lib/repositories/budget_notes_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_expense_model.dart';
import '../models/fishing_trip_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
import '../services/offline/offline_storage_service.dart';
import '../services/offline/sync_service.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

/// ✅ ИСПРАВЛЕННЫЙ Repository для управления заметками бюджета (поездками на рыбалку)
/// ContentType.expenses → ContentType.budgetNotes везде
/// Используем существующие методы Firebase: addBudgetNote(), getUserBudgetNotes() и т.д.
class BudgetNotesRepository {
  static final BudgetNotesRepository _instance = BudgetNotesRepository._internal();

  factory BudgetNotesRepository() {
    return _instance;
  }

  BudgetNotesRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingTripModel>? _cachedTrips;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// ✅ ИСПРАВЛЕНО: Получить все заметки бюджета пользователя с кэшированием
  Future<List<FishingTripModel>> getUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📥 BudgetNotesRepository.getUserTrips() - userId: $userId');

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

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        debugPrint('📥 Загружаем заметки бюджета из Firebase...');

        // ✅ ИСПРАВЛЕНО: Используем существующий метод getUserBudgetNotes()
        final notesSnapshot = await _firebaseService.getUserBudgetNotes();
        debugPrint('📥 Получено ${notesSnapshot.docs.length} заметок бюджета из Firebase');

        final onlineTrips = <FishingTripModel>[];

        // Парсим каждую заметку бюджета как поездку с расходами
        for (var noteDoc in notesSnapshot.docs) {
          try {
            final noteData = noteDoc.data() as Map<String, dynamic>;
            noteData['id'] = noteDoc.id;

            // Создаем модель поездки с расходами из данных заметки бюджета
            final trip = FishingTripModel.fromMapWithExpenses(noteData);
            onlineTrips.add(trip);

            debugPrint('✅ Заметка бюджета ${noteDoc.id} загружена с ${trip.expenses.length} расходами');
          } catch (e) {
            debugPrint('❌ Ошибка парсинга заметки бюджета ${noteDoc.id}: $e');

            // Если ошибка парсинга, создаем заметку без расходов
            try {
              final noteData = noteDoc.data() as Map<String, dynamic>;
              noteData['id'] = noteDoc.id;
              noteData['expenses'] = []; // Пустой список расходов

              final trip = FishingTripModel.fromMapWithExpenses(noteData);
              onlineTrips.add(trip);

              debugPrint('⚠️ Заметка бюджета ${noteDoc.id} загружена без расходов');
            } catch (e2) {
              debugPrint('❌ Критическая ошибка парсинга заметки бюджета ${noteDoc.id}: $e2');
            }
          }
        }

        // ✅ ИСПРАВЛЕНО: Получаем офлайн заметки через правильный метод
        final offlineTrips = await _getOfflineTrips(userId);

        // Объединяем списки, избегая дубликатов
        final allTrips = [...onlineTrips];

        for (var offlineTrip in offlineTrips) {
          // Проверяем, что такой заметки еще нет в списке
          if (!allTrips.any((trip) => trip.id == offlineTrip.id)) {
            allTrips.add(offlineTrip);
          }
        }

        // Удаляем дубликаты на основе ID
        final Map<String, FishingTripModel> uniqueTrips = {};
        for (var trip in allTrips) {
          uniqueTrips[trip.id] = trip;
        }

        // Сортируем локально по дате (от новых к старым)
        final result = uniqueTrips.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        debugPrint('✅ Получено ${result.length} уникальных заметок бюджета');

        // Кэшируем результат
        _cachedTrips = result;
        _cacheTimestamp = DateTime.now();

        // Запускаем синхронизацию в фоне ТОЛЬКО если есть офлайн данные
        if (offlineTrips.isNotEmpty) {
          debugPrint('🔄 Запуск фоновой синхронизации (есть офлайн данные)');
          // НЕ БЛОКИРУЕМ выполнение
          Future.microtask(() => _syncService.syncAll());
        }

        return result;
      } else {
        debugPrint('📱 Получение заметок бюджета из офлайн хранилища');

        // Если нет подключения, получаем заметки из офлайн хранилища
        final result = await _getOfflineTrips(userId);

        // Кэшируем офлайн результат
        _cachedTrips = result;
        _cacheTimestamp = DateTime.now();

        return result;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметок бюджета: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн заметки
      try {
        return await _getOfflineTrips(_firebaseService.currentUserId ?? '');
      } catch (_) {
        rethrow;
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение заметок из офлайн хранилища
  Future<List<FishingTripModel>> _getOfflineTrips(String userId) async {
    try {
      // ✅ ИСПРАВЛЕНО: Используем правильный метод для бюджетных заметок
      final offlineTrips = await _offlineStorage.getOfflineBudgetNotes(userId);

      // Фильтруем и преобразуем данные в модели
      final offlineTripModels = offlineTrips
          .where((trip) => trip['userId'] == userId) // Фильтруем по userId
          .map((trip) => FishingTripModel.fromMapWithExpenses(trip))
          .toList();

      // Сортируем по дате (от новых к старым)
      offlineTripModels.sort((a, b) => b.date.compareTo(a.date));

      return offlineTripModels;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн заметок бюджета: $e');
      return [];
    }
  }

  /// ✅ ИСПРАВЛЕНО: Создать новую заметку бюджета с расходами
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

      debugPrint('🔥 Создание заметки бюджета с расходами...');

      // ✅ ИСПРАВЛЕНО: Проверяем лимиты для budgetNotes
      final canCreate = await _subscriptionService.canCreateContentOffline(
        ContentType.budgetNotes,  // ✅ ИСПРАВЛЕНО! Было expenses
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

      debugPrint('🔥 Создано ${expenses.length} расходов');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Создаем заметку бюджета через существующий метод

        // 1. Создаем данные для заметки бюджета (включая расходы в одном документе)
        final budgetData = {
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'locationName': locationName,
          'notes': notes,
          'currency': currency,
          'totalAmount': expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
          'expenseCount': expenses.length,
          'expenses': expenses.map((expense) => expense.toMap()).toList(), // Расходы внутри документа
        };

        // ✅ ИСПРАВЛЕНО: Используем существующий метод addBudgetNote()
        final noteRef = await _firebaseService.addBudgetNote(budgetData);
        final noteId = noteRef.id;

        debugPrint('✅ Заметка бюджета создана: $noteId');

        // 2. Создаем финальную модель заметки
        final syncedExpenses = expenses.map((e) =>
            e.copyWith(tripId: noteId).markAsSynced()
        ).toList();

        final syncedTrip = FishingTripModel.create(
          userId: userId,
          date: date,
          locationName: locationName,
          notes: notes,
          currency: currency,
        ).copyWith(id: noteId).markAsSynced().withExpenses(syncedExpenses);

        // ✅ ИСПРАВЛЕНО: Увеличиваем счетчик budgetNotes через Firebase
        try {
          final success = await _firebaseService.incrementUsageCount('budgetNotesCount');  // ✅ ИСПРАВЛЕНО!
          if (success) {
            debugPrint('✅ Счетчик заметок бюджета увеличен через Firebase');
          } else {
            debugPrint('❌ Не удалось увеличить счетчик заметок бюджета через Firebase');
          }
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика заметок бюджета: $e');
        }

        // Очищаем кэш после создания новой заметки
        clearCache();

        return syncedTrip;
      } else {
        // Если нет интернета, сохраняем заметку локально
        final trip = FishingTripModel.create(
          userId: userId,
          date: date,
          locationName: locationName,
          notes: notes,
          currency: currency,
        ).withExpenses(expenses);

        await _saveTripOffline(trip);

        // ✅ ИСПРАВЛЕНО: Увеличиваем счетчик budgetNotes офлайн
        try {
          await _subscriptionService.incrementUsage(ContentType.budgetNotes);  // ✅ ИСПРАВЛЕНО!
          debugPrint('✅ Счетчик заметок бюджета увеличен офлайн');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика заметок бюджета: $e');
        }

        // Очищаем кэш после создания новой заметки
        clearCache();

        return trip;
      }
    } catch (e) {
      debugPrint('❌ Ошибка создания заметки бюджета: $e');
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Сохранение заметки в офлайн режиме
  Future<void> _saveTripOffline(FishingTripModel trip) async {
    try {
      // ✅ ИСПРАВЛЕНО: Используем правильный метод для бюджетных заметок
      await _offlineStorage.saveOfflineBudgetNote(trip.toMapWithExpenses());
      debugPrint('Заметка бюджета ${trip.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('Ошибка при сохранении заметки бюджета офлайн: $e');
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Обновить заметку бюджета
  Future<FishingTripModel> updateTrip(FishingTripModel trip) async {
    try {
      if (trip.id.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🔥 Обновление заметки бюджета: ${trip.id}');

      // Создаем копию заметки с установленным UserID
      final tripToUpdate = trip.copyWith(userId: userId).touch();

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Обновляем заметку бюджета через существующий метод

        // 1. Обновляем заметку бюджета (включая расходы в одном документе)
        final budgetData = {
          'userId': userId,
          'date': Timestamp.fromDate(tripToUpdate.date),
          'locationName': tripToUpdate.locationName,
          'notes': tripToUpdate.notes,
          'currency': tripToUpdate.currency,
          'totalAmount': tripToUpdate.totalAmount,
          'expenseCount': tripToUpdate.expenses.length,
          'expenses': tripToUpdate.expenses.map((expense) => expense.toMap()).toList(),
        };

        // ✅ ИСПРАВЛЕНО: Используем существующий метод updateBudgetNote()
        await _firebaseService.updateBudgetNote(trip.id, budgetData);

        debugPrint('✅ Заметка бюджета обновлена онлайн: ${trip.id}');

        // Очищаем кэш после обновления заметки
        clearCache();

        return tripToUpdate.markAsSynced();
      } else {
        // ✅ ИСПРАВЛЕНО: Если нет интернета, сохраняем обновление локально
        await _offlineStorage.saveOfflineBudgetNote(tripToUpdate.toMapWithExpenses());

        debugPrint('✅ Заметка бюджета обновлена офлайн: ${trip.id}');

        // Очищаем кэш после обновления заметки
        clearCache();

        return tripToUpdate;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки бюджета: $e');

      // ✅ ИСПРАВЛЕНО: В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveOfflineBudgetNote(trip.toMapWithExpenses());
        return trip;
      } catch (_) {
        rethrow;
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удалить заметку бюджета
  Future<void> deleteTrip(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      debugPrint('🔥 Удаление заметки бюджета: $tripId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Удаляем заметку бюджета через существующий метод
        await _firebaseService.deleteBudgetNote(tripId);

        // ✅ ИСПРАВЛЕНО: Удаляем локальную копию, если она есть
        try {
          await _offlineStorage.removeOfflineBudgetNote(tripId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии заметки бюджета: $e');
        }

        debugPrint('✅ Заметка бюджета удалена онлайн: $tripId');
      } else {
        // Если нет интернета, отмечаем заметку для удаления
        await _offlineStorage.markForDeletion(tripId, false); // false для budget notes

        // ✅ ИСПРАВЛЕНО: Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineBudgetNote(tripId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии заметки бюджета: $e');
        }

        debugPrint('✅ Заметка бюджета отмечена для удаления: $tripId');
      }

      // ✅ ИСПРАВЛЕНО: Уменьшаем счетчик использования budgetNotes
      try {
        await _subscriptionService.decrementUsage(ContentType.budgetNotes);  // ✅ ИСПРАВЛЕНО!
        debugPrint('✅ Счетчик заметок бюджета уменьшен');
      } catch (e) {
        debugPrint('❌ Ошибка уменьшения счетчика заметок бюджета: $e');
        // Не прерываем выполнение, заметка уже удалена
      }

      // Очищаем кэш после удаления заметки
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки бюджета: $e');

      // В случае ошибки, отмечаем заметку для удаления
      try {
        await _offlineStorage.markForDeletion(tripId, false);
      } catch (_) {
        rethrow;
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получить заметку бюджета по ID
  Future<FishingTripModel?> getTripById(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID заметки бюджета не может быть пустым');
      }

      debugPrint('🔥 Получение заметки бюджета по ID: $tripId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Получаем заметки бюджета через существующий метод
        final budgetNotesSnapshot = await _firebaseService.getUserBudgetNotes();

        // Ищем нужную заметку по ID
        final noteDoc = budgetNotesSnapshot.docs.where((doc) => doc.id == tripId).firstOrNull;

        if (noteDoc != null) {
          final noteData = noteDoc.data() as Map<String, dynamic>;
          noteData['id'] = noteDoc.id;

          debugPrint('✅ Заметка бюджета найдена в Firebase: $tripId');
          return FishingTripModel.fromMapWithExpenses(noteData);
        } else {
          // Если заметка не найдена в Firebase, пробуем найти в офлайн хранилище
          debugPrint('⚠️ Заметка бюджета не найдена в Firebase, ищем в офлайн хранилище: $tripId');
          return await _getOfflineTripById(tripId);
        }
      } else {
        // Если нет интернета, ищем заметку в офлайн хранилище
        debugPrint('📱 Получение заметки бюджета из офлайн хранилища: $tripId');
        return await _getOfflineTripById(tripId);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки бюджета по ID: $e');

      // В случае ошибки, пытаемся получить заметку из офлайн хранилища
      try {
        return await _getOfflineTripById(tripId);
      } catch (_) {
        return null;
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение заметки из офлайн хранилища по ID
  Future<FishingTripModel?> _getOfflineTripById(String tripId) async {
    try {
      // ✅ ИСПРАВЛЕНО: Используем правильный метод для бюджетных заметок
      final allOfflineTrips = await _offlineStorage.getAllOfflineBudgetNotes();

      // Ищем заметку по ID
      final tripData = allOfflineTrips.firstWhere(
            (trip) => trip['id'] == tripId,
        orElse: () => throw Exception('Заметка бюджета не найдена в офлайн хранилище'),
      );

      return FishingTripModel.fromMapWithExpenses(tripData);
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки бюджета из офлайн хранилища: $e');
      return null;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удалить все заметки бюджета пользователя
  Future<void> deleteAllUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Если есть интернет, получаем все заметки бюджета пользователя и удаляем их
        final snapshot = await _firebaseService.getUserBudgetNotes();

        // Удаляем каждую заметку бюджета
        for (var doc in snapshot.docs) {
          await _firebaseService.deleteBudgetNote(doc.id);
        }

        debugPrint('✅ Удалено ${snapshot.docs.length} заметок бюджета пользователя');
      } else {
        // Если нет интернета, отмечаем все заметки для удаления
        await _offlineStorage.markAllNotesForDeletion(); // используем тот же метод
      }

      // ✅ ИСПРАВЛЕНО: Очищаем локальное хранилище заметок бюджета
      try {
        final offlineTrips = await _offlineStorage.getAllOfflineBudgetNotes();
        for (var trip in offlineTrips) {
          final tripId = trip['id'];
          if (tripId != null) {
            await _offlineStorage.removeOfflineBudgetNote(tripId);
          }
        }
      } catch (e) {
        debugPrint('Ошибка при очистке локального хранилища заметок бюджета: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении всех заметок бюджета: $e');

      // В случае ошибки, отмечаем все заметки для удаления
      try {
        await _offlineStorage.markAllNotesForDeletion();
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Получить суммированные расходы по категориям
  Future<Map<FishingExpenseCategory, CategoryExpenseSummary>> getCategorySummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔥 Получение сводки по категориям...');

      // ВАЖНО: Используем кэшированные данные если доступны
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

      debugPrint('🔥 Получено ${trips.length} заметок для анализа');

      // Фильтруем заметки по периоду
      final filteredTrips = trips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      debugPrint('🔥 После фильтрации осталось ${filteredTrips.length} заметок');

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

  /// ✅ ИСПРАВЛЕНО: Проверка возможности создания новой заметки бюджета
  Future<bool> canCreateTrip() async {
    try {
      return await _subscriptionService.canCreateContentOffline(
        ContentType.budgetNotes,  // ✅ ИСПРАВЛЕНО! Было expenses
      );
    } catch (e) {
      debugPrint('❌ Ошибка при проверке возможности создания заметки бюджета: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение текущего использования заметок бюджета
  Future<int> getCurrentUsage() async {
    try {
      return await _subscriptionService.getCurrentUsage(
        ContentType.budgetNotes,  // ✅ ИСПРАВЛЕНО! Было expenses
      );
    } catch (e) {
      debugPrint('❌ Ошибка при получении текущего использования заметок бюджета: $e');
      return 0;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Получение лимита заметок бюджета
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.budgetNotes);  // ✅ ИСПРАВЛЕНО! Было expenses
    } catch (e) {
      debugPrint('❌ Ошибка при получении лимита заметок бюджета: $e');
      return 0;
    }
  }

  /// Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await _syncService.syncAll();
  }

  /// Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      return await _syncService.forceSyncAll();
    } catch (e) {
      debugPrint('❌ Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  /// Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
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

/// Сводка расходов по категории
class CategoryExpenseSummary {
  /// Категория расходов
  final FishingExpenseCategory category;

  /// Общая сумма по категории
  final double totalAmount;

  /// Количество расходов
  final int expenseCount;

  /// Количество заметок с этой категорией
  final int tripCount;

  /// Валюта
  final String currency;

  const CategoryExpenseSummary({
    required this.category,
    required this.totalAmount,
    required this.expenseCount,
    required this.tripCount,
    required this.currency,
  });

  /// Получить символ валюты
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

  /// Отформатированная сумма
  String get formattedAmount {
    return '$currencySymbol ${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';
  }

  /// Описание количества заметок
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