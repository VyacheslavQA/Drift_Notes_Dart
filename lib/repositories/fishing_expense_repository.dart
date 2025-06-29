// Путь: lib/repositories/fishing_expense_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/fishing_expense_model.dart';
import '../models/fishing_trip_model.dart';
import '../services/firebase/firebase_service.dart';
import '../services/offline/offline_storage_service.dart';
import '../utils/network_utils.dart';

/// Repository для управления расходами на рыбалку
class FishingExpenseRepository {
  static final FishingExpenseRepository _instance = FishingExpenseRepository._internal();

  factory FishingExpenseRepository() {
    return _instance;
  }

  FishingExpenseRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  static const String _collectionName = 'fishing_expenses';
  static const String _offlineKey = 'offline_fishing_expenses';

  /// Получить все расходы пользователя
  Future<List<FishingExpenseModel>> getUserExpenses() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Загружаем из Firestore
        final onlineExpenses = await _getExpensesFromFirestore(userId);

        // Сохраняем в офлайн кеш
        await _cacheExpensesOffline(onlineExpenses);

        return onlineExpenses;
      } else {
        // Загружаем из офлайн кеша
        final offlineExpenses = await _getExpensesFromOfflineCache();
        return offlineExpenses;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расходов: $e');

      // При ошибке пытаемся загрузить из офлайн кеша
      try {
        final offlineExpenses = await _getExpensesFromOfflineCache();
        return offlineExpenses;
      } catch (offlineError) {
        debugPrint('Ошибка загрузки из офлайн кеша: $offlineError');
        return [];
      }
    }
  }

  /// Получить расходы из Firestore
  Future<List<FishingExpenseModel>> _getExpensesFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final expenses = <FishingExpenseModel>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final expense = FishingExpenseModel.fromMap(data);
          expenses.add(expense);
        } catch (e) {
          debugPrint('Ошибка парсинга документа ${doc.id}: $e');
        }
      }

      // Сортируем в коде вместо Firestore
      expenses.sort((a, b) => b.date.compareTo(a.date));

      return expenses;
    } catch (e) {
      debugPrint('Ошибка запроса к Firestore: $e');
      rethrow;
    }
  }

  /// Получить расходы из офлайн кеша
  Future<List<FishingExpenseModel>> _getExpensesFromOfflineCache() async {
    try {
      final prefs = await _offlineStorage.preferences;
      final expensesJsonList = prefs.getStringList(_offlineKey) ?? [];

      final List<FishingExpenseModel> expenses = [];
      for (var expenseJsonString in expensesJsonList) {
        try {
          final expenseJson = jsonDecode(expenseJsonString) as Map<String, dynamic>;
          final expense = FishingExpenseModel.fromJson(expenseJson);
          expenses.add(expense);
        } catch (e) {
          debugPrint('Ошибка парсинга офлайн расхода: $e');
        }
      }

      // Сортируем по дате (новые сначала)
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } catch (e) {
      debugPrint('Ошибка загрузки из офлайн кеша: $e');
      return [];
    }
  }

  /// Кешировать расходы офлайн
  Future<void> _cacheExpensesOffline(List<FishingExpenseModel> expenses) async {
    try {
      final prefs = await _offlineStorage.preferences;
      final expensesJsonList = expenses
          .map((expense) => jsonEncode(expense.toJson()))
          .toList();

      await prefs.setStringList(_offlineKey, expensesJsonList);
    } catch (e) {
      debugPrint('Ошибка кеширования расходов: $e');
    }
  }

  /// Добавить новый расход
  Future<FishingExpenseModel> addExpense(FishingExpenseModel expense) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Убеждаемся, что userId правильный
      final expenseWithUserId = expense.copyWith(userId: userId);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Сохраняем в Firestore
        final docData = expenseWithUserId.toMap();

        await _firestore
            .collection(_collectionName)
            .doc(expenseWithUserId.id)
            .set(docData);

        final syncedExpense = expenseWithUserId.markAsSynced();
        await _addExpenseToOfflineCache(syncedExpense);

        return syncedExpense;
      } else {
        // Сохраняем офлайн для последующей синхронизации
        await _offlineStorage.saveOfflineNote(expenseWithUserId.toJson());
        await _addExpenseToOfflineCache(expenseWithUserId);

        return expenseWithUserId;
      }
    } catch (e) {
      debugPrint('Ошибка добавления расхода: $e');
      rethrow;
    }
  }

  /// Добавить расход в офлайн кеш
  Future<void> _addExpenseToOfflineCache(FishingExpenseModel expense) async {
    try {
      final currentExpenses = await _getExpensesFromOfflineCache();

      // Проверяем, есть ли уже такой расход
      final existingIndex = currentExpenses.indexWhere((e) => e.id == expense.id);

      if (existingIndex >= 0) {
        // Обновляем существующий
        currentExpenses[existingIndex] = expense;
      } else {
        // Добавляем новый
        currentExpenses.insert(0, expense);
      }

      await _cacheExpensesOffline(currentExpenses);
    } catch (e) {
      debugPrint('Ошибка добавления в офлайн кеш: $e');
    }
  }

  /// Обновить расход
  Future<FishingExpenseModel> updateExpense(FishingExpenseModel expense) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Обновляем timestamp
      final updatedExpense = expense.touch();

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Обновляем в Firestore
        await _firestore
            .collection(_collectionName)
            .doc(updatedExpense.id)
            .set(updatedExpense.toMap());

        final syncedExpense = updatedExpense.markAsSynced();
        await _updateExpenseInOfflineCache(syncedExpense);

        return syncedExpense;
      } else {
        // Сохраняем обновление для последующей синхронизации
        await _offlineStorage.saveNoteUpdate(updatedExpense.id, updatedExpense.toJson());
        await _updateExpenseInOfflineCache(updatedExpense);

        return updatedExpense;
      }
    } catch (e) {
      debugPrint('Ошибка обновления расхода: $e');
      rethrow;
    }
  }

  /// Обновить расход в офлайн кеше
  Future<void> _updateExpenseInOfflineCache(FishingExpenseModel expense) async {
    try {
      final currentExpenses = await _getExpensesFromOfflineCache();
      final index = currentExpenses.indexWhere((e) => e.id == expense.id);

      if (index >= 0) {
        currentExpenses[index] = expense;
        await _cacheExpensesOffline(currentExpenses);
      }
    } catch (e) {
      debugPrint('Ошибка обновления в офлайн кеше: $e');
    }
  }

  /// Удалить расход
  Future<void> deleteExpense(String expenseId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Удаляем из Firestore
        await _firestore.collection(_collectionName).doc(expenseId).delete();
      } else {
        // Отмечаем для удаления при следующей синхронизации
        await _offlineStorage.markForDeletion(expenseId, false);
      }

      // Удаляем из офлайн кеша
      await _removeExpenseFromOfflineCache(expenseId);
    } catch (e) {
      debugPrint('Ошибка удаления расхода: $e');
      rethrow;
    }
  }

  /// Удалить расход из офлайн кеша
  Future<void> _removeExpenseFromOfflineCache(String expenseId) async {
    try {
      final currentExpenses = await _getExpensesFromOfflineCache();
      final updatedExpenses = currentExpenses.where((e) => e.id != expenseId).toList();
      await _cacheExpensesOffline(updatedExpenses);
    } catch (e) {
      debugPrint('Ошибка удаления из офлайн кеша: $e');
    }
  }

  /// Получить расходы за определенный период
  Future<List<FishingExpenseModel>> getExpensesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allExpenses = await getUserExpenses();
      return allExpenses.where((expense) {
        return expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения расходов за период: $e');
      return [];
    }
  }

  /// Получить расходы по ID поездки
  Future<List<FishingExpenseModel>> getExpensesByTrip(String tripId) async {
    try {
      final allExpenses = await getUserExpenses();
      return allExpenses.where((expense) => expense.tripId == tripId).toList();
    } catch (e) {
      debugPrint('Ошибка получения расходов по поездке: $e');
      return [];
    }
  }

  /// Удалить все расходы поездки
  Future<void> deleteExpensesByTrip(String tripId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Удаляем из Firestore
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('tripId', isEqualTo: tripId)
            .get();

        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } else {
        // Отмечаем все расходы поездки для удаления
        final tripExpenses = await getExpensesByTrip(tripId);
        for (var expense in tripExpenses) {
          await _offlineStorage.markForDeletion(expense.id, false);
        }
      }

      // Удаляем из офлайн кеша
      await _removeExpensesFromOfflineCacheByTrip(tripId);
    } catch (e) {
      debugPrint('Ошибка удаления расходов поездки: $e');
      rethrow;
    }
  }

  /// Удалить расходы поездки из офлайн кеша
  Future<void> _removeExpensesFromOfflineCacheByTrip(String tripId) async {
    try {
      final currentExpenses = await _getExpensesFromOfflineCache();
      final updatedExpenses = currentExpenses.where((e) => e.tripId != tripId).toList();
      await _cacheExpensesOffline(updatedExpenses);
    } catch (e) {
      debugPrint('Ошибка удаления расходов поездки из кеша: $e');
    }
  }

  /// Получить расходы по категории
  Future<List<FishingExpenseModel>> getExpensesByCategory(
      FishingExpenseCategory category
      ) async {
    try {
      final allExpenses = await getUserExpenses();
      return allExpenses.where((expense) => expense.category == category).toList();
    } catch (e) {
      debugPrint('Ошибка получения расходов по категории: $e');
      return [];
    }
  }

  /// Получить статистику расходов
  Future<FishingExpenseStatistics> getExpenseStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<FishingExpenseModel> expenses;

      if (startDate != null || endDate != null) {
        expenses = await getExpensesByPeriod(
          startDate: startDate ?? DateTime(2020),
          endDate: endDate ?? DateTime.now(),
        );
      } else {
        expenses = await getUserExpenses();
      }

      return FishingExpenseStatistics.fromExpenses(
        expenses,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики: $e');
      return FishingExpenseStatistics.fromExpenses([]);
    }
  }

  /// Получить суммированные расходы по категориям (для экрана расходов)
  Future<Map<FishingExpenseCategory, CategoryExpenseSummary>> getCategorySummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<FishingExpenseModel> expenses;

      if (startDate != null || endDate != null) {
        expenses = await getExpensesByPeriod(
          startDate: startDate ?? DateTime(2020),
          endDate: endDate ?? DateTime.now(),
        );
      } else {
        expenses = await getUserExpenses();
      }

      final Map<FishingExpenseCategory, CategoryExpenseSummary> summaries = {};

      for (final category in FishingExpenseCategory.allCategories) {
        final categoryExpenses = expenses.where((e) => e.category == category).toList();

        if (categoryExpenses.isNotEmpty) {
          final totalAmount = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
          final uniqueTrips = categoryExpenses.map((e) => e.tripId).toSet().length;

          summaries[category] = CategoryExpenseSummary(
            category: category,
            totalAmount: totalAmount,
            expenseCount: categoryExpenses.length,
            tripCount: uniqueTrips,
            currency: categoryExpenses.first.currency,
          );
        }
      }

      return summaries;
    } catch (e) {
      debugPrint('Ошибка получения сводки по категориям: $e');
      return {};
    }
  }

  /// Создать новую поездку с расходами
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

      // Создаем поездку
      final trip = FishingTripModel.create(
        userId: userId,
        date: date,
        locationName: locationName,
        notes: notes,
        currency: currency,
      );

      // Создаем расходы для категорий с указанными суммами
      final List<FishingExpenseModel> expenses = [];
      for (final category in FishingExpenseCategory.allCategories) {
        final amount = categoryAmounts[category] ?? 0.0;
        if (amount > 0) {
          final description = categoryDescriptions[category]?.trim() ?? '';
          final expenseNotes = categoryNotes[category]?.trim() ?? '';

          final expense = FishingExpenseModel.create(
            userId: userId,
            tripId: trip.id,
            amount: amount,
            description: description.isNotEmpty ? description : 'Расходы',
            category: category,
            date: date,
            currency: currency,
            notes: expenseNotes.isEmpty ? null : expenseNotes,
            locationName: locationName,
          );

          expenses.add(expense);
        }
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Сохраняем поездку в Firestore
        await _firestore
            .collection('fishing_trips')
            .doc(trip.id)
            .set(trip.toMap());

        // Сохраняем расходы
        for (final expense in expenses) {
          await _firestore
              .collection(_collectionName)
              .doc(expense.id)
              .set(expense.toMap());
        }

        final syncedTrip = trip.markAsSynced().withExpenses(expenses.map((e) => e.markAsSynced()).toList());
        return syncedTrip;
      } else {
        // Сохраняем офлайн для последующей синхронизации
        final tripWithExpenses = trip.withExpenses(expenses);
        return tripWithExpenses;
      }
    } catch (e) {
      debugPrint('Ошибка создания поездки: $e');
      rethrow;
    }
  }

  /// Получить все поездки пользователя с расходами
  Future<List<FishingTripModel>> getUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Загружаем поездки из Firestore
        final tripsSnapshot = await _firestore
            .collection('fishing_trips')
            .where('userId', isEqualTo: userId)
            .get();

        final trips = <FishingTripModel>[];

        for (var doc in tripsSnapshot.docs) {
          try {
            final tripData = doc.data();
            final trip = FishingTripModel.fromMap(tripData);

            // Загружаем расходы для этой поездки
            final expenses = await getExpensesByTrip(trip.id);
            final tripWithExpenses = trip.withExpenses(expenses);

            trips.add(tripWithExpenses);
          } catch (e) {
            debugPrint('Ошибка парсинга поездки ${doc.id}: $e');
          }
        }

        // Сортируем по дате (новые сначала)
        trips.sort((a, b) => b.date.compareTo(a.date));

        return trips;
      } else {
        // Возвращаем группированные расходы как поездки
        return await _getTripsFromExpenses();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки поездок: $e');
      return await _getTripsFromExpenses();
    }
  }

  /// Создать поездки из расходов (группировка по tripId)
  Future<List<FishingTripModel>> _getTripsFromExpenses() async {
    try {
      final expenses = await getUserExpenses();
      final tripsMap = <String, List<FishingExpenseModel>>{};

      // Группируем расходы по tripId
      for (final expense in expenses) {
        if (!tripsMap.containsKey(expense.tripId)) {
          tripsMap[expense.tripId] = [];
        }
        tripsMap[expense.tripId]!.add(expense);
      }

      final trips = <FishingTripModel>[];

      // Создаем поездки из групп расходов
      for (final entry in tripsMap.entries) {
        final tripExpenses = entry.value;
        if (tripExpenses.isNotEmpty) {
          final firstExpense = tripExpenses.first;

          final trip = FishingTripModel(
            id: entry.key,
            userId: firstExpense.userId,
            date: firstExpense.date,
            locationName: firstExpense.locationName,
            currency: firstExpense.currency,
            createdAt: tripExpenses.map((e) => e.createdAt).reduce((a, b) => a.isBefore(b) ? a : b),
            updatedAt: tripExpenses.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b),
            isSynced: tripExpenses.every((e) => e.isSynced),
            expenses: tripExpenses,
          );

          trips.add(trip);
        }
      }

      // Сортируем по дате (новые сначала)
      trips.sort((a, b) => b.date.compareTo(a.date));

      return trips;
    } catch (e) {
      debugPrint('Ошибка создания поездок из расходов: $e');
      return [];
    }
  }

  /// Получить поездку по ID с расходами
  Future<FishingTripModel?> getTripById(String tripId) async {
    try {
      final trips = await getUserTrips();
      try {
        return trips.firstWhere((trip) => trip.id == tripId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка получения поездки: $e');
      return null;
    }
  }

  /// Удалить поездку и все связанные расходы
  Future<void> deleteTrip(String tripId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Удаляем поездку из Firestore
        await _firestore.collection('fishing_trips').doc(tripId).delete();

        // Удаляем все связанные расходы
        await deleteExpensesByTrip(tripId);
      } else {
        // Отмечаем для удаления при следующей синхронизации
        await _offlineStorage.markForDeletion(tripId, true);
        await deleteExpensesByTrip(tripId);
      }
    } catch (e) {
      debugPrint('Ошибка удаления поездки: $e');
      rethrow;
    }
  }

  /// Получить статистику поездок
  Future<FishingTripStatistics> getTripStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<FishingTripModel> trips;

      if (startDate != null || endDate != null) {
        final allTrips = await getUserTrips();
        trips = allTrips.where((trip) {
          return trip.date.isAfter((startDate ?? DateTime(2020)).subtract(const Duration(days: 1))) &&
              trip.date.isBefore((endDate ?? DateTime.now()).add(const Duration(days: 1)));
        }).toList();
      } else {
        trips = await getUserTrips();
      }

      return FishingTripStatistics.fromTrips(
        trips,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики поездок: $e');
      return FishingTripStatistics.fromTrips([]);
    }
  }

  /// Синхронизировать офлайн данные с сервером
  Future<void> syncOfflineDataOnStartup() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (!isOnline) {
        return;
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        return;
      }

      // Здесь можно добавить логику синхронизации офлайн изменений
      // Пока просто обновляем кеш актуальными данными
      await getUserExpenses();
    } catch (e) {
      debugPrint('Ошибка синхронизации расходов: $e');
    }
  }

  /// Удалить все расходы пользователя (для отладки)
  Future<void> deleteAllUserExpenses() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Удаляем из Firestore
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .get();

        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } else {
        // Отмечаем все для удаления
        await _offlineStorage.markAllNotesForDeletion();
      }

      // Очищаем офлайн кеш
      await clearOfflineCache();
    } catch (e) {
      debugPrint('Ошибка удаления всех расходов: $e');
      rethrow;
    }
  }

  /// Очистить офлайн кеш (публичный метод)
  Future<void> clearOfflineCache() async {
    try {
      final prefs = await _offlineStorage.preferences;
      await prefs.remove(_offlineKey);
    } catch (e) {
      debugPrint('Ошибка очистки офлайн кеша: $e');
    }
  }

  /// Получить количество несинхронизированных расходов
  Future<int> getUnsyncedExpensesCount() async {
    try {
      final expenses = await _getExpensesFromOfflineCache();
      return expenses.where((expense) => !expense.isSynced).length;
    } catch (e) {
      debugPrint('Ошибка подсчета несинхронизированных расходов: $e');
      return 0;
    }
  }

  /// Получить информацию о состоянии репозитория
  Future<Map<String, dynamic>> getRepositoryStatus() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();
      final unsyncedCount = await getUnsyncedExpensesCount();
      final totalCount = (await _getExpensesFromOfflineCache()).length;

      return {
        'isOnline': isOnline,
        'totalExpenses': totalCount,
        'unsyncedExpenses': unsyncedCount,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Ошибка получения статуса репозитория: $e');
      return {
        'isOnline': false,
        'totalExpenses': 0,
        'unsyncedExpenses': 0,
        'error': e.toString(),
      };
    }
  }

  /// Поиск расходов по описанию
  Future<List<FishingExpenseModel>> searchExpenses(String query) async {
    try {
      if (query.trim().isEmpty) return getUserExpenses();

      final allExpenses = await getUserExpenses();
      final lowercaseQuery = query.toLowerCase();

      return allExpenses.where((expense) {
        return expense.description.toLowerCase().contains(lowercaseQuery) ||
            expense.notes?.toLowerCase().contains(lowercaseQuery) == true ||
            expense.locationName?.toLowerCase().contains(lowercaseQuery) == true;
      }).toList();
    } catch (e) {
      debugPrint('Ошибка поиска расходов: $e');
      return [];
    }
  }

  /// Stream расходов в реальном времени (только для онлайн режима)
  Stream<List<FishingExpenseModel>> getUserExpensesStream() {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => FishingExpenseModel.fromMap(doc.data()))
          .toList();

      // Сортируем в коде вместо Firestore
      expenses.sort((a, b) => b.date.compareTo(a.date));

      return expenses;
    });
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

  /// Количество поездок с этой категорией
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

  /// Описание количества поездок
  String get tripCountDescription {
    if (tripCount == 1) {
      return 'из 1 поездки';
    } else if (tripCount >= 2 && tripCount <= 4) {
      return 'из $tripCount поездок';
    } else {
      return 'из $tripCount поездок';
    }
  }
}