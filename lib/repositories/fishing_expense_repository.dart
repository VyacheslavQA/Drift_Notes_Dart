// Путь: lib/repositories/fishing_expense_repository.dart

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

/// Repository для управления поездками на рыбалку с расходами в subcollections
class FishingExpenseRepository {
  static final FishingExpenseRepository _instance = FishingExpenseRepository._internal();

  factory FishingExpenseRepository() {
    return _instance;
  }

  FishingExpenseRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  static const String _tripsCollection = 'fishing_trips';

  // Кэш для предотвращения повторных загрузок
  static List<FishingTripModel>? _cachedTrips;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// 🔥 ИСПРАВЛЕНО: Получить все поездки пользователя с кэшированием
  Future<List<FishingTripModel>> getUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📥 FishingExpenseRepository.getUserTrips() - userId: $userId');

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
        debugPrint('📥 Загружаем поездки из Firebase с расходами...');

        // 🔥 ИСПРАВЛЕНО: Получаем основные поездки
        final tripsSnapshot = await _firebaseService.getUserFishingTrips();
        debugPrint('📥 Получено ${tripsSnapshot.docs.length} поездок из Firebase');

        final onlineTrips = <FishingTripModel>[];

        // 🔥 ИСПРАВЛЕНО: Для каждой поездки загружаем расходы из subcollection
        for (var tripDoc in tripsSnapshot.docs) {
          try {
            final tripData = tripDoc.data() as Map<String, dynamic>;
            tripData['id'] = tripDoc.id;

            debugPrint('📥 Загружаем расходы для поездки: ${tripDoc.id}');

            // Получаем расходы поездки из subcollection
            final expensesSnapshot = await _firebaseService.getFishingTripExpenses(tripDoc.id);
            debugPrint('📥 Получено ${expensesSnapshot.docs.length} расходов для поездки ${tripDoc.id}');

            // Преобразуем расходы в список
            final expenses = expensesSnapshot.docs.map((expenseDoc) {
              final expenseData = expenseDoc.data() as Map<String, dynamic>;
              expenseData['id'] = expenseDoc.id;
              return expenseData;
            }).toList();

            // Добавляем расходы в данные поездки
            tripData['expenses'] = expenses;

            // Создаем модель поездки с расходами
            final trip = FishingTripModel.fromMapWithExpenses(tripData);
            onlineTrips.add(trip);

            debugPrint('✅ Поездка ${tripDoc.id} загружена с ${expenses.length} расходами');
          } catch (e) {
            debugPrint('❌ Ошибка парсинга поездки ${tripDoc.id}: $e');

            // Если ошибка загрузки расходов, создаем поездку без расходов
            try {
              final tripData = tripDoc.data() as Map<String, dynamic>;
              tripData['id'] = tripDoc.id;
              tripData['expenses'] = []; // Пустой список расходов

              final trip = FishingTripModel.fromMapWithExpenses(tripData);
              onlineTrips.add(trip);

              debugPrint('⚠️ Поездка ${tripDoc.id} загружена без расходов');
            } catch (e2) {
              debugPrint('❌ Критическая ошибка парсинга поездки ${tripDoc.id}: $e2');
            }
          }
        }

        // Получаем офлайн поездки, которые еще не были синхронизированы
        final offlineTrips = await _getOfflineTrips(userId);

        // Объединяем списки, избегая дубликатов
        final allTrips = [...onlineTrips];

        for (var offlineTrip in offlineTrips) {
          // Проверяем, что такой поездки еще нет в списке
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

        debugPrint('✅ Получено ${result.length} уникальных поездок');

        // 🔥 ИСПРАВЛЕНО: Кэшируем результат
        _cachedTrips = result;
        _cacheTimestamp = DateTime.now();

        // Запускаем синхронизацию в фоне ТОЛЬКО если есть офлайн данные
        if (offlineTrips.isNotEmpty) {
          debugPrint('🔄 Запуск фоновой синхронизации (есть офлайн данные)');
          // НЕ БЛОКИРУЕМ выполнение
          Future.microtask(() => _syncService.syncAll());
        }

        // Обновляем лимиты после загрузки поездок (БЕЗ БЛОКИРОВКИ)
        Future.microtask(() async {
          try {
            await _subscriptionService.refreshUsageLimits();
          } catch (e) {
            debugPrint('Ошибка обновления лимитов после загрузки поездок: $e');
          }
        });

        return result;
      } else {
        debugPrint('📱 Получение поездок из офлайн хранилища');

        // Если нет подключения, получаем поездки из офлайн хранилища
        final result = await _getOfflineTrips(userId);

        // Кэшируем офлайн результат
        _cachedTrips = result;
        _cacheTimestamp = DateTime.now();

        return result;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении поездок: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн поездки
      try {
        return await _getOfflineTrips(_firebaseService.currentUserId ?? '');
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Получение поездок из офлайн хранилища
  Future<List<FishingTripModel>> _getOfflineTrips(String userId) async {
    try {
      final offlineTrips = await _offlineStorage.getOfflineExpenses(userId);

      // Фильтруем и преобразуем данные в модели
      final offlineTripModels = offlineTrips
          .where((trip) => trip['userId'] == userId) // Фильтруем по userId
          .map((trip) => FishingTripModel.fromMapWithExpenses(trip))
          .toList();

      // Сортируем по дате (от новых к старым)
      offlineTripModels.sort((a, b) => b.date.compareTo(a.date));

      return offlineTripModels;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн поездок: $e');
      return [];
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Создать новую поездку с расходами в subcollections
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

      debugPrint('🔥 Создание поездки с расходами...');

      // ✅ КРИТИЧНО: Проверяем лимиты ДО создания поездки
      final canCreate = await _subscriptionService.canCreateContentOffline(
        ContentType.expenses,
      );

      if (!canCreate) {
        throw Exception('Достигнут лимит создания поездок');
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
            tripId: '', // Будет установлен после создания поездки
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
        // 🔥 ИСПРАВЛЕНО: Создаем поездку и расходы через Firebase subcollections

        // 1. Создаем основную поездку (БЕЗ расходов)
        final tripData = {
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'locationName': locationName,
          'notes': notes,
          'currency': currency,
          'totalAmount': expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
          'expenseCount': expenses.length,
        };

        final tripRef = await _firebaseService.addFishingTrip(tripData);
        final tripId = tripRef.id;

        debugPrint('✅ Поездка создана: $tripId');

        // 2. Создаем расходы в subcollection
        for (final expense in expenses) {
          final expenseData = expense.copyWith(tripId: tripId).toMap();
          await _firebaseService.addFishingExpense(tripId, expenseData);
        }

        debugPrint('✅ Добавлено ${expenses.length} расходов в subcollection');

        // 3. Создаем финальную модель поездки
        final syncedExpenses = expenses.map((e) =>
            e.copyWith(tripId: tripId).markAsSynced()
        ).toList();

        final syncedTrip = FishingTripModel.create(
          userId: userId,
          date: date,
          locationName: locationName,
          notes: notes,
          currency: currency,
        ).copyWith(id: tripId).markAsSynced().withExpenses(syncedExpenses);

        // ✅ Увеличиваем счетчик использования после успешного сохранения
        try {
          await _subscriptionService.incrementUsage(ContentType.expenses);
          await _subscriptionService.incrementOfflineUsage(ContentType.expenses);
          debugPrint('✅ Счетчик поездок увеличен');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика поездок: $e');
        }

        // Очищаем кэш после создания новой поездки
        clearCache();

        return syncedTrip;
      } else {
        // Если нет интернета, сохраняем поездку локально (старая логика)
        final trip = FishingTripModel.create(
          userId: userId,
          date: date,
          locationName: locationName,
          notes: notes,
          currency: currency,
        ).withExpenses(expenses);

        await _saveTripOffline(trip);

        // ✅ Увеличиваем счетчик использования после успешного сохранения
        try {
          await _subscriptionService.incrementUsage(ContentType.expenses);
          await _subscriptionService.incrementOfflineUsage(ContentType.expenses);
          debugPrint('✅ Счетчик поездок увеличен');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика поездок: $e');
        }

        // Очищаем кэш после создания новой поездки
        clearCache();

        return trip;
      }
    } catch (e) {
      debugPrint('❌ Ошибка создания поездки: $e');
      rethrow;
    }
  }

  /// Сохранение поездки в офлайн режиме
  Future<void> _saveTripOffline(FishingTripModel trip) async {
    try {
      await _offlineStorage.saveOfflineExpenseWithSync(trip.toMapWithExpenses());
      debugPrint('Поездка ${trip.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('Ошибка при сохранении поездки офлайн: $e');
      rethrow;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Обновить поездку с расходами в subcollections
  Future<FishingTripModel> updateTrip(FishingTripModel trip) async {
    try {
      if (trip.id.isEmpty) {
        throw Exception('ID поездки не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🔥 Обновление поездки: ${trip.id}');

      // Создаем копию поездки с установленным UserID
      final tripToUpdate = trip.copyWith(userId: userId).touch();

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Обновляем поездку и расходы через Firebase subcollections

        // 1. Обновляем основную поездку
        final tripData = {
          'userId': userId,
          'date': Timestamp.fromDate(tripToUpdate.date),
          'locationName': tripToUpdate.locationName,
          'notes': tripToUpdate.notes,
          'currency': tripToUpdate.currency,
          'totalAmount': tripToUpdate.totalAmount,
          'expenseCount': tripToUpdate.expenses.length,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firebaseService.updateFishingTrip(trip.id, tripData);

        // 2. Получаем существующие расходы из subcollection
        final existingExpensesSnapshot = await _firebaseService.getFishingTripExpenses(trip.id);

        // 3. Удаляем все существующие расходы
        final batch = _firestore.batch();
        for (var expenseDoc in existingExpensesSnapshot.docs) {
          batch.delete(expenseDoc.reference);
        }
        await batch.commit();

        // 4. Добавляем новые расходы
        for (final expense in tripToUpdate.expenses) {
          final expenseData = expense.copyWith(tripId: trip.id).toMap();
          await _firebaseService.addFishingExpense(trip.id, expenseData);
        }

        debugPrint('✅ Поездка обновлена онлайн с subcollections: ${trip.id}');

        // Очищаем кэш после обновления поездки
        clearCache();

        return tripToUpdate.markAsSynced();
      } else {
        // Если нет интернета, сохраняем обновление локально
        await _offlineStorage.saveOfflineExpenseWithSync(tripToUpdate.toMapWithExpenses());

        debugPrint('✅ Поездка обновлена офлайн: ${trip.id}');

        // Очищаем кэш после обновления поездки
        clearCache();

        return tripToUpdate;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении поездки: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveOfflineExpenseWithSync(trip.toMapWithExpenses());
        return trip;
      } catch (_) {
        rethrow;
      }
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Удалить поездку с расходами из subcollections
  Future<void> deleteTrip(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID поездки не может быть пустым');
      }

      debugPrint('🔥 Удаление поездки: $tripId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Удаляем поездку со всеми расходами через Firebase
        await _firebaseService.deleteFishingTripWithExpenses(tripId);

        // Удаляем локальную копию, если она есть
        try {
          await _offlineStorage.removeOfflineExpense(tripId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии поездки: $e');
        }

        debugPrint('✅ Поездка удалена онлайн со всеми расходами: $tripId');
      } else {
        // Если нет интернета, отмечаем поездку для удаления
        await _offlineStorage.markForDeletion(tripId, false); // false для expenses

        // Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineExpense(tripId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии поездки: $e');
        }

        debugPrint('✅ Поездка отмечена для удаления: $tripId');
      }

      // ✅ Уменьшаем счетчик использования после успешного удаления
      try {
        await _subscriptionService.decrementUsage(ContentType.expenses);
        await _subscriptionService.decrementOfflineUsage(ContentType.expenses);
        debugPrint('✅ Счетчик поездок уменьшен');
      } catch (e) {
        debugPrint('❌ Ошибка уменьшения счетчика поездок: $e');
        // Не прерываем выполнение, поездка уже удалена
      }

      // Очищаем кэш после удаления поездки
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при удалении поездки: $e');

      // В случае ошибки, отмечаем поездку для удаления
      try {
        await _offlineStorage.markForDeletion(tripId, false);
      } catch (_) {
        rethrow;
      }
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получить поездку по ID с расходами из subcollections
  Future<FishingTripModel?> getTripById(String tripId) async {
    try {
      if (tripId.isEmpty) {
        throw Exception('ID поездки не может быть пустым');
      }

      debugPrint('🔥 Получение поездки по ID: $tripId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Получаем поездку с расходами из Firebase subcollections
        final tripWithExpenses = await _firebaseService.getFishingTripWithExpenses(tripId);

        if (tripWithExpenses != null) {
          debugPrint('✅ Поездка найдена в Firebase: $tripId');
          return FishingTripModel.fromMapWithExpenses(tripWithExpenses);
        } else {
          // Если поездка не найдена в Firestore, пробуем найти в офлайн хранилище
          debugPrint('⚠️ Поездка не найдена в Firebase, ищем в офлайн хранилище: $tripId');
          return await _getOfflineTripById(tripId);
        }
      } else {
        // Если нет интернета, ищем поездку в офлайн хранилище
        debugPrint('📱 Получение поездки из офлайн хранилища: $tripId');
        return await _getOfflineTripById(tripId);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении поездки по ID: $e');

      // В случае ошибки, пытаемся получить поездку из офлайн хранилища
      try {
        return await _getOfflineTripById(tripId);
      } catch (_) {
        return null;
      }
    }
  }

  /// Получение поездки из офлайн хранилища по ID
  Future<FishingTripModel?> _getOfflineTripById(String tripId) async {
    try {
      final allOfflineTrips = await _offlineStorage.getAllOfflineExpenses();

      // Ищем поездку по ID
      final tripData = allOfflineTrips.firstWhere(
            (trip) => trip['id'] == tripId,
        orElse: () => throw Exception('Поездка не найдена в офлайн хранилище'),
      );

      return FishingTripModel.fromMapWithExpenses(tripData);
    } catch (e) {
      debugPrint('❌ Ошибка при получении поездки из офлайн хранилища: $e');
      return null;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получить суммированные расходы по категориям (БЕЗ ЛИШНИХ ВЫЗОВОВ)
  Future<Map<FishingExpenseCategory, CategoryExpenseSummary>> getCategorySummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔥 Получение сводки по категориям...');

      // 🔥 ВАЖНО: Используем кэшированные данные если доступны
      List<FishingTripModel> trips;
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Используем кэшированные поездки для анализа');
          trips = _cachedTrips!;
        } else {
          debugPrint('💾 Кэш устарел, загружаем заново');
          trips = await getUserTrips();
        }
      } else {
        debugPrint('💾 Кэша нет, загружаем поездки');
        trips = await getUserTrips();
      }

      debugPrint('🔥 Получено ${trips.length} поездок для анализа');

      // Фильтруем поездки по периоду
      final filteredTrips = trips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      debugPrint('🔥 После фильтрации осталось ${filteredTrips.length} поездок');

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

  /// Внутренний метод получения поездок БЕЗ синхронизации (для анализа)
  Future<List<FishingTripModel>> _getUserTripsForAnalysis() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Загружаем БЕЗ вызова синхронизации
        final tripsSnapshot = await _firebaseService.getUserFishingTrips();

        final onlineTrips = <FishingTripModel>[];
        for (var doc in tripsSnapshot.docs) {
          try {
            final tripData = doc.data() as Map<String, dynamic>;
            tripData['id'] = doc.id;

            // Получаем расходы поездки из subcollection
            final expensesSnapshot = await _firebaseService.getFishingTripExpenses(doc.id);

            // Преобразуем расходы в список
            final expenses = expensesSnapshot.docs.map((expenseDoc) {
              final expenseData = expenseDoc.data() as Map<String, dynamic>;
              expenseData['id'] = expenseDoc.id;
              return expenseData;
            }).toList();

            // Добавляем расходы в данные поездки
            tripData['expenses'] = expenses;

            // Создаем модель поездки с расходами
            final trip = FishingTripModel.fromMapWithExpenses(tripData);
            onlineTrips.add(trip);
          } catch (e) {
            debugPrint('❌ Ошибка парсинга поездки ${doc.id}: $e');
          }
        }

        // Получаем офлайн поездки
        final offlineTrips = await _getOfflineTrips(userId);

        // Объединяем без дубликатов
        final allTrips = [...onlineTrips];
        for (var offlineTrip in offlineTrips) {
          if (!allTrips.any((trip) => trip.id == offlineTrip.id)) {
            allTrips.add(offlineTrip);
          }
        }

        // Сортируем по дате
        allTrips.sort((a, b) => b.date.compareTo(a.date));

        return allTrips;
      } else {
        // Если нет интернета, получаем поездки из офлайн хранилища
        return await _getOfflineTrips(userId);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении поездок для анализа: $e');
      return [];
    }
  }

  /// Получить статистику поездок
  Future<FishingTripStatistics> getTripStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 🔥 ИСПРАВЛЕНО: Используем кэшированные данные если доступны
      List<FishingTripModel> allTrips;
      if (_cachedTrips != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Используем кэшированные поездки для статистики');
          allTrips = _cachedTrips!;
        } else {
          debugPrint('💾 Кэш устарел, загружаем заново для статистики');
          allTrips = await getUserTrips();
        }
      } else {
        debugPrint('💾 Кэша нет, загружаем поездки для статистики');
        allTrips = await getUserTrips();
      }

      // Фильтруем поездки по периоду
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
      debugPrint('❌ Ошибка получения статистики поездок: $e');
      return FishingTripStatistics.fromTrips([]);
    }
  }

  /// Удалить все поездки пользователя
  Future<void> deleteAllUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем все поездки пользователя и удаляем их
        final snapshot = await _firebaseService.getUserFishingTrips();

        // Удаляем каждую поездку со всеми расходами
        for (var doc in snapshot.docs) {
          await _firebaseService.deleteFishingTripWithExpenses(doc.id);
        }

        debugPrint('✅ Удалено ${snapshot.docs.length} поездок пользователя');
      } else {
        // Если нет интернета, отмечаем все поездки для удаления
        await _offlineStorage.markAllNotesForDeletion(); // используем тот же метод
      }

      // В любом случае, очищаем локальное хранилище поездок
      try {
        final offlineTrips = await _offlineStorage.getAllOfflineExpenses();
        for (var trip in offlineTrips) {
          final tripId = trip['id'];
          if (tripId != null) {
            await _offlineStorage.removeOfflineExpense(tripId);
          }
        }
      } catch (e) {
        debugPrint('Ошибка при очистке локального хранилища поездок: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении всех поездок: $e');

      // В случае ошибки, отмечаем все поездки для удаления
      try {
        await _offlineStorage.markAllNotesForDeletion();
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Поиск поездок
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
      debugPrint('❌ Ошибка поиска поездок: $e');
      return [];
    }
  }

  /// Проверка возможности создания новой поездки
  Future<bool> canCreateTrip() async {
    try {
      return await _subscriptionService.canCreateContentOffline(
        ContentType.expenses,
      );
    } catch (e) {
      debugPrint('❌ Ошибка при проверке возможности создания поездки: $e');
      return false;
    }
  }

  /// Получение текущего использования поездок
  Future<int> getCurrentUsage() async {
    try {
      return await _subscriptionService.getCurrentOfflineUsage(
        ContentType.expenses,
      );
    } catch (e) {
      debugPrint('❌ Ошибка при получении текущего использования поездок: $e');
      return 0;
    }
  }

  /// Получение лимита поездок
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.expenses);
    } catch (e) {
      debugPrint('❌ Ошибка при получении лимита поездок: $e');
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
    debugPrint('💾 Кэш поездок очищен');
  }

  // Методы для совместимости со старым кодом (будут удалены позже)

  /// Устаревший метод - теперь не используется
  @Deprecated('Используйте getUserTrips() и работайте с расходами внутри поездок')
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
    throw UnimplementedError('Метод больше не поддерживается. Редактируйте поездку целиком');
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