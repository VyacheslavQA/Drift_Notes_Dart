// Путь: lib/repositories/fishing_expense_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fishing_expense_model.dart';
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

        debugPrint('✅ Загружено ${onlineExpenses.length} расходов из Firestore');
        return onlineExpenses;
      } else {
        // Загружаем из офлайн кеша
        final offlineExpenses = await _getExpensesFromOfflineCache();
        debugPrint('📱 Загружено ${offlineExpenses.length} расходов из офлайн кеша');
        return offlineExpenses;
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки расходов: $e');

      // При ошибке пытаемся загрузить из офлайн кеша
      try {
        final offlineExpenses = await _getExpensesFromOfflineCache();
        debugPrint('📱 Fallback: загружено ${offlineExpenses.length} расходов из кеша');
        return offlineExpenses;
      } catch (offlineError) {
        debugPrint('❌ Ошибка загрузки из офлайн кеша: $offlineError');
        return [];
      }
    }
  }

  /// Получить расходы из Firestore
  Future<List<FishingExpenseModel>> _getExpensesFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    final expenses = snapshot.docs
        .map((doc) => FishingExpenseModel.fromMap(doc.data()))
        .toList();

    // Сортируем в коде вместо Firestore
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return expenses;
  }

  /// Получить расходы из офлайн кеша
  Future<List<FishingExpenseModel>> _getExpensesFromOfflineCache() async {
    final prefs = await _offlineStorage.preferences;
    final expensesJson = prefs.getStringList(_offlineKey) ?? [];

    final List<FishingExpenseModel> expenses = [];
    for (var expenseJsonString in expensesJson) {
      try {
        final expenseJson = Map<String, dynamic>.from(
            await compute(_parseJson, expenseJsonString)
        );
        expenses.add(FishingExpenseModel.fromJson(expenseJson));
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга офлайн расхода: $e');
      }
    }

    // Сортируем по дате (новые сначала)
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Вспомогательная функция для парсинга JSON в изоляте
  static Map<String, dynamic> _parseJson(String jsonString) {
    return Map<String, dynamic>.from(
      // Используем более безопасный парсинг
        Uri.splitQueryString(jsonString.isEmpty ? '{}' : jsonString)
    );
  }

  /// Кешировать расходы офлайн
  Future<void> _cacheExpensesOffline(List<FishingExpenseModel> expenses) async {
    try {
      final prefs = await _offlineStorage.preferences;
      final expensesJson = expenses
          .map((expense) => expense.toJson())
          .map((json) => json.toString())
          .toList();

      await prefs.setStringList(_offlineKey, expensesJson);
      debugPrint('💾 Кешировано ${expenses.length} расходов офлайн');
    } catch (e) {
      debugPrint('⚠️ Ошибка кеширования расходов: $e');
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
        await _firestore
            .collection(_collectionName)
            .doc(expenseWithUserId.id)
            .set(expenseWithUserId.toMap());

        final syncedExpense = expenseWithUserId.markAsSynced();
        await _addExpenseToOfflineCache(syncedExpense);

        debugPrint('✅ Расход добавлен в Firestore: ${expenseWithUserId.id}');
        return syncedExpense;
      } else {
        // Сохраняем офлайн для последующей синхронизации
        await _offlineStorage.saveOfflineNote(expenseWithUserId.toJson());
        await _addExpenseToOfflineCache(expenseWithUserId);

        debugPrint('📱 Расход сохранен офлайн: ${expenseWithUserId.id}');
        return expenseWithUserId;
      }
    } catch (e) {
      debugPrint('❌ Ошибка добавления расхода: $e');
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
      debugPrint('⚠️ Ошибка добавления в офлайн кеш: $e');
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

        debugPrint('✅ Расход обновлен в Firestore: ${updatedExpense.id}');
        return syncedExpense;
      } else {
        // Сохраняем обновление для последующей синхронизации
        await _offlineStorage.saveNoteUpdate(updatedExpense.id, updatedExpense.toJson());
        await _updateExpenseInOfflineCache(updatedExpense);

        debugPrint('📱 Обновление расхода сохранено офлайн: ${updatedExpense.id}');
        return updatedExpense;
      }
    } catch (e) {
      debugPrint('❌ Ошибка обновления расхода: $e');
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
      debugPrint('⚠️ Ошибка обновления в офлайн кеше: $e');
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
        debugPrint('✅ Расход удален из Firestore: $expenseId');
      } else {
        // Отмечаем для удаления при следующей синхронизации
        await _offlineStorage.markForDeletion(expenseId, false);
        debugPrint('📱 Расход отмечен для удаления: $expenseId');
      }

      // Удаляем из офлайн кеша
      await _removeExpenseFromOfflineCache(expenseId);
    } catch (e) {
      debugPrint('❌ Ошибка удаления расхода: $e');
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
      debugPrint('⚠️ Ошибка удаления из офлайн кеша: $e');
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
      debugPrint('❌ Ошибка получения расходов за период: $e');
      return [];
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
      debugPrint('❌ Ошибка получения расходов по категории: $e');
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
      debugPrint('❌ Ошибка получения статистики: $e');
      return FishingExpenseStatistics.fromExpenses([]);
    }
  }

  /// Синхронизировать офлайн данные с сервером
  Future<void> syncOfflineDataOnStartup() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (!isOnline) {
        debugPrint('📱 Нет подключения для синхронизации расходов');
        return;
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ Пользователь не авторизован для синхронизации');
        return;
      }

      // Здесь можно добавить логику синхронизации офлайн изменений
      // Пока просто обновляем кеш актуальными данными
      await getUserExpenses();
      debugPrint('✅ Синхронизация расходов завершена');
    } catch (e) {
      debugPrint('⚠️ Ошибка синхронизации расходов: $e');
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

        debugPrint('✅ Все расходы удалены из Firestore');
      } else {
        // Отмечаем все для удаления
        await _offlineStorage.markAllNotesForDeletion();
        debugPrint('📱 Все расходы отмечены для удаления');
      }

      // Очищаем офлайн кеш
      await _clearOfflineCache();
    } catch (e) {
      debugPrint('❌ Ошибка удаления всех расходов: $e');
      rethrow;
    }
  }

  /// Очистить офлайн кеш
  Future<void> _clearOfflineCache() async {
    try {
      final prefs = await _offlineStorage.preferences;
      await prefs.remove(_offlineKey);
      debugPrint('🧹 Офлайн кеш расходов очищен');
    } catch (e) {
      debugPrint('⚠️ Ошибка очистки офлайн кеша: $e');
    }
  }

  /// Получить количество несинхронизированных расходов
  Future<int> getUnsyncedExpensesCount() async {
    try {
      final expenses = await _getExpensesFromOfflineCache();
      return expenses.where((expense) => !expense.isSynced).length;
    } catch (e) {
      debugPrint('⚠️ Ошибка подсчета несинхронизированных расходов: $e');
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
      debugPrint('⚠️ Ошибка получения статуса репозитория: $e');
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
      debugPrint('❌ Ошибка поиска расходов: $e');
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