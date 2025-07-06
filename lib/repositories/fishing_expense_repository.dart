// Путь: lib/repositories/fishing_expense_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fishing_expense_model.dart';
import '../models/fishing_trip_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
// ДОБАВЛЕНО: Импорты для работы с лимитами
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

/// Repository для управления поездками на рыбалку (расходы хранятся внутри поездок)
class FishingExpenseRepository {
  static final FishingExpenseRepository _instance = FishingExpenseRepository._internal();

  factory FishingExpenseRepository() {
    return _instance;
  }

  FishingExpenseRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  static const String _tripsCollection = 'fishing_trips';

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
            tripId: '', // Не используется при хранении внутри поездки
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

      // Создаем поездку с расходами
      final trip = FishingTripModel.create(
        userId: userId,
        date: date,
        locationName: locationName,
        notes: notes,
        currency: currency,
      ).withExpenses(expenses);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Сохраняем поездку со всеми расходами в одном документе
        final tripData = trip.toMapWithExpenses();

        await _firestore
            .collection(_tripsCollection)
            .doc(trip.id)
            .set(tripData);

        final syncedTrip = trip.markAsSynced().withExpenses(
            expenses.map((e) => e.markAsSynced()).toList()
        );

        // ДОБАВЛЕНО: Увеличиваем счетчик использования после успешного сохранения
        try {
          await SubscriptionService().incrementUsage(ContentType.expenses);
          debugPrint('✅ Счетчик расходов/поездок увеличен');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика расходов/поездок: $e');
        }

        return syncedTrip;
      } else {
        // TODO: Добавить офлайн хранение

        // ДОБАВЛЕНО: Увеличиваем счетчик использования и в офлайн режиме
        try {
          await SubscriptionService().incrementUsage(ContentType.expenses);
          debugPrint('✅ Счетчик расходов/поездок увеличен (офлайн)');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика расходов/поездок (офлайн): $e');
        }

        return trip;
      }
    } catch (e) {
      debugPrint('Ошибка создания поездки: $e');
      rethrow;
    }
  }

  /// Получить все поездки пользователя
  Future<List<FishingTripModel>> getUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Загружаем поездки из Firestore (убираем orderBy чтобы не требовать индекс)
        final tripsSnapshot = await _firestore
            .collection(_tripsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final trips = <FishingTripModel>[];

        for (var doc in tripsSnapshot.docs) {
          try {
            final tripData = doc.data();
            final trip = FishingTripModel.fromMapWithExpenses(tripData);
            trips.add(trip);
          } catch (e) {
            debugPrint('Ошибка парсинга поездки ${doc.id}: $e');
          }
        }

        // Сортируем в коде (новые сначала)
        trips.sort((a, b) => b.date.compareTo(a.date));

        // ДОБАВЛЕНО: Обновляем лимиты после загрузки поездок
        try {
          await SubscriptionService().refreshUsageLimits();
        } catch (e) {
          debugPrint('Ошибка обновления лимитов после загрузки поездок: $e');
        }

        return trips;
      } else {
        // TODO: Добавить офлайн загрузку
        return [];
      }
    } catch (e) {
      debugPrint('Ошибка загрузки поездок: $e');
      return [];
    }
  }

  /// Получить поездку по ID
  Future<FishingTripModel?> getTripById(String tripId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return null;

      final doc = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .get();

      if (doc.exists) {
        final tripData = doc.data()!;
        return FishingTripModel.fromMapWithExpenses(tripData);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения поездки: $e');
      return null;
    }
  }

  /// Обновить поездку
  Future<FishingTripModel> updateTrip(FishingTripModel trip) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final updatedTrip = trip.touch();
      final tripData = updatedTrip.toMapWithExpenses();

      await _firestore
          .collection(_tripsCollection)
          .doc(trip.id)
          .set(tripData);

      return updatedTrip.markAsSynced();
    } catch (e) {
      debugPrint('Ошибка обновления поездки: $e');
      rethrow;
    }
  }

  /// Удалить поездку
  Future<void> deleteTrip(String tripId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_tripsCollection).doc(tripId).delete();

      // ДОБАВЛЕНО: Уменьшаем счетчик использования после успешного удаления
      try {
        await SubscriptionService().decrementUsage(ContentType.expenses);
        debugPrint('✅ Счетчик расходов/поездок уменьшен');
      } catch (e) {
        debugPrint('❌ Ошибка уменьшения счетчика расходов/поездок: $e');
      }
    } catch (e) {
      debugPrint('Ошибка удаления поездки: $e');
      rethrow;
    }
  }

  /// Получить суммированные расходы по категориям
  Future<Map<FishingExpenseCategory, CategoryExpenseSummary>> getCategorySummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final trips = await getUserTrips();

      // Фильтруем поездки по периоду
      final filteredTrips = trips.where((trip) {
        if (startDate != null && trip.date.isBefore(startDate)) return false;
        if (endDate != null && trip.date.isAfter(endDate)) return false;
        return true;
      }).toList();

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
        }
      }

      return summaries;
    } catch (e) {
      debugPrint('Ошибка получения сводки по категориям: $e');
      return {};
    }
  }

  /// Получить статистику поездок
  Future<FishingTripStatistics> getTripStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allTrips = await getUserTrips();

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
      debugPrint('Ошибка получения статистики поездок: $e');
      return FishingTripStatistics.fromTrips([]);
    }
  }

  /// Удалить все поездки пользователя (для отладки)
  Future<void> deleteAllUserTrips() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final snapshot = await _firestore
          .collection(_tripsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка удаления всех поездок: $e');
      rethrow;
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
      debugPrint('Ошибка поиска поездок: $e');
      return [];
    }
  }

  /// Очистить кеш (для совместимости)
  Future<void> clearOfflineCache() async {
    // В новой архитектуре кеш не используется, но метод нужен для совместимости
    debugPrint('clearOfflineCache: метод вызван, но кеш не используется');
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