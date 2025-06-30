// Путь: lib/models/fishing_trip_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'fishing_expense_model.dart';

/// Модель поездки на рыбалку
class FishingTripModel {
  /// Уникальный идентификатор поездки
  final String id;

  /// ID пользователя
  final String userId;

  /// Дата поездки
  final DateTime date;

  /// Название места рыбалки
  final String? locationName;

  /// Общие заметки о поездке
  final String? notes;

  /// Валюта поездки
  final String currency;

  /// Дата создания записи
  final DateTime createdAt;

  /// Дата последнего обновления
  final DateTime updatedAt;

  /// Признак синхронизации с сервером
  final bool isSynced;

  /// Список расходов в этой поездке (не сохраняется в Firestore, загружается отдельно)
  final List<FishingExpenseModel> expenses;

  const FishingTripModel({
    required this.id,
    required this.userId,
    required this.date,
    this.locationName,
    this.notes,
    this.currency = 'KZT',
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.expenses = const [],
  });

  /// Создать копию модели с изменениями
  FishingTripModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? locationName,
    String? notes,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    List<FishingExpenseModel>? expenses,
  }) {
    return FishingTripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      locationName: locationName ?? this.locationName,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      expenses: expenses ?? this.expenses,
    );
  }

  /// Создать модель из Map с расходами (например, из Firestore)
  factory FishingTripModel.fromMapWithExpenses(Map<String, dynamic> map) {
    final expenses = <FishingExpenseModel>[];

    // Парсим расходы из массива внутри документа
    if (map['expenses'] is List) {
      final expensesData = map['expenses'] as List;
      for (final expenseData in expensesData) {
        if (expenseData is Map<String, dynamic>) {
          try {
            // Создаем расход из данных Firestore
            final expense = FishingExpenseModel(
              id: expenseData['id'] as String,
              userId: expenseData['userId'] as String,
              tripId: expenseData['tripId'] as String? ?? '',
              amount: (expenseData['amount'] as num).toDouble(),
              description: expenseData['description'] as String,
              category: FishingExpenseCategory.fromId(expenseData['category'] as String) ?? FishingExpenseCategory.tackle,
              date: expenseData['date'] is Timestamp
                  ? (expenseData['date'] as Timestamp).toDate()
                  : DateTime.parse(expenseData['date'] as String),
              currency: expenseData['currency'] as String? ?? 'KZT',
              notes: expenseData['notes'] as String?,
              locationName: expenseData['locationName'] as String?,
              createdAt: expenseData['createdAt'] is Timestamp
                  ? (expenseData['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(expenseData['createdAt'] as String),
              updatedAt: expenseData['updatedAt'] is Timestamp
                  ? (expenseData['updatedAt'] as Timestamp).toDate()
                  : DateTime.parse(expenseData['updatedAt'] as String),
              isSynced: expenseData['isSynced'] as bool? ?? false,
            );
            expenses.add(expense);
          } catch (e) {
            debugPrint('Ошибка парсинга расхода: $e');
          }
        }
      }
    }

    return FishingTripModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      locationName: map['locationName'] as String?,
      notes: map['notes'] as String?,
      currency: map['currency'] as String? ?? 'KZT',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isSynced: map['isSynced'] as bool? ?? false,
      expenses: expenses,
    );
  }

  /// Преобразовать модель в Map с расходами для сохранения в Firestore
  Map<String, dynamic> toMapWithExpenses() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'notes': notes,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSynced': isSynced,
      'expenses': expenses.map((expense) => {
        'id': expense.id,
        'userId': expense.userId,
        'tripId': expense.tripId,
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category.id,
        'date': Timestamp.fromDate(expense.date),
        'currency': expense.currency,
        'notes': expense.notes,
        'locationName': expense.locationName,
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'updatedAt': Timestamp.fromDate(expense.updatedAt),
        'isSynced': expense.isSynced,
      }).toList(),
    };
  }

  /// Преобразовать модель в Map для сохранения в Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'notes': notes,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSynced': isSynced,
    };
  }

  /// Преобразовать в JSON для локального хранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'locationName': locationName,
      'notes': notes,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  /// Создать модель из JSON
  factory FishingTripModel.fromJson(Map<String, dynamic> json) {
    return FishingTripModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      locationName: json['locationName'] as String?,
      notes: json['notes'] as String?,
      currency: json['currency'] as String? ?? 'KZT',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  /// Создать новую поездку
  factory FishingTripModel.create({
    required String userId,
    required DateTime date,
    String? locationName,
    String? notes,
    String currency = 'KZT',
  }) {
    final now = DateTime.now();
    return FishingTripModel(
      id: 'trip_${now.millisecondsSinceEpoch}',
      userId: userId,
      date: date,
      locationName: locationName,
      notes: notes,
      currency: currency,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

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

  /// Общая сумма расходов в поездке
  double get totalAmount {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Отформатированная общая сумма
  String get formattedTotalAmount {
    return '$currencySymbol ${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';
  }

  /// Количество категорий с расходами
  int get categoriesCount {
    final categoryTotals = this.categoryTotals;
    return categoryTotals.values.where((amount) => amount > 0).length;
  }

  /// Расходы по категориям
  Map<FishingExpenseCategory, double> get categoryTotals {
    final Map<FishingExpenseCategory, double> totals = {};

    for (final category in FishingExpenseCategory.allCategories) {
      totals[category] = 0.0;
    }

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  /// Заголовок для отображения
  String get displayTitle {
    if (locationName != null && locationName!.isNotEmpty) {
      return locationName!;
    }
    return 'Рыбалка ${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Самая дорогая категория
  FishingExpenseCategory? get mostExpensiveCategory {
    if (expenses.isEmpty) return null;

    final totals = categoryTotals;
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.first.value > 0 ? sortedEntries.first.key : null;
  }

  /// Краткое описание поездки для списков
  String get shortDescription {
    final location = locationName?.isNotEmpty == true ? locationName! : 'Рыбалка';
    final count = categoriesCount;
    return count > 0 ? '$location ($count ${_getCategoriesWord(count)})' : location;
  }

  String _getCategoriesWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'категория';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'категории';
    } else {
      return 'категорий';
    }
  }

  /// Отформатированная дата для отображения
  String formatDate([String? locale]) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day.$month.$year';
  }

  /// Проверка валидности данных
  bool get isValid {
    return id.isNotEmpty && userId.isNotEmpty;
  }

  /// Отметить как синхронизированную
  FishingTripModel markAsSynced() {
    return copyWith(isSynced: true);
  }

  /// Обновить временную метку
  FishingTripModel touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Добавить расходы к поездке (для локального использования)
  FishingTripModel withExpenses(List<FishingExpenseModel> newExpenses) {
    return copyWith(expenses: newExpenses);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FishingTripModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FishingTripModel(id: $id, date: ${formatDate()}, location: $locationName, total: $formattedTotalAmount, categories: $categoriesCount)';
  }
}

/// Статистика поездок
class FishingTripStatistics {
  /// Общее количество поездок
  final int totalTrips;

  /// Общая сумма всех расходов
  final double totalAmount;

  /// Средняя сумма на поездку
  final double averagePerTrip;

  /// Минимальная сумма за поездку
  final double minTripAmount;

  /// Максимальная сумма за поездку
  final double maxTripAmount;

  /// Валюта статистики
  final String currency;

  /// Период статистики
  final DateTime startDate;
  final DateTime endDate;

  const FishingTripStatistics({
    required this.totalTrips,
    required this.totalAmount,
    required this.averagePerTrip,
    required this.minTripAmount,
    required this.maxTripAmount,
    this.currency = 'KZT',
    required this.startDate,
    required this.endDate,
  });

  /// Создать статистику из списка поездок
  factory FishingTripStatistics.fromTrips(
      List<FishingTripModel> trips, {
        DateTime? startDate,
        DateTime? endDate,
        String currency = 'KZT',
      }) {
    if (trips.isEmpty) {
      return FishingTripStatistics(
        totalTrips: 0,
        totalAmount: 0,
        averagePerTrip: 0,
        minTripAmount: 0,
        maxTripAmount: 0,
        currency: currency,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now(),
      );
    }

    final totalAmount = trips.fold<double>(0, (sum, trip) => sum + trip.totalAmount);
    final averagePerTrip = totalAmount / trips.length;

    final tripAmounts = trips.map((trip) => trip.totalAmount).toList();
    final minTripAmount = tripAmounts.reduce((a, b) => a < b ? a : b);
    final maxTripAmount = tripAmounts.reduce((a, b) => a > b ? a : b);

    return FishingTripStatistics(
      totalTrips: trips.length,
      totalAmount: totalAmount,
      averagePerTrip: averagePerTrip,
      minTripAmount: minTripAmount,
      maxTripAmount: maxTripAmount,
      currency: currency,
      startDate: startDate ?? trips.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b),
      endDate: endDate ?? trips.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

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

  /// Количество поездок (алиас для совместимости)
  int get tripCount => totalTrips;

  /// Отформатированная общая сумма
  String get formattedTotal {
    return '$currencySymbol ${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';
  }

  /// Отформатированная средняя сумма
  String get formattedAverage {
    return '$currencySymbol ${averagePerTrip.toStringAsFixed(averagePerTrip.truncateToDouble() == averagePerTrip ? 0 : 2)}';
  }

  /// Отформатированная средняя сумма за поездку
  String get formattedAveragePerTrip {
    return '$currencySymbol ${averagePerTrip.toStringAsFixed(0)}';
  }

  /// Отформатированная минимальная сумма за поездку
  String get formattedMinTrip {
    return '$currencySymbol ${minTripAmount.toStringAsFixed(0)}';
  }

  /// Отформатированная максимальная сумма за поездку
  String get formattedMaxTrip {
    return '$currencySymbol ${maxTripAmount.toStringAsFixed(0)}';
  }
}