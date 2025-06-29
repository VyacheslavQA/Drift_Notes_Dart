// Путь: lib/models/fishing_expense_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Категории расходов на рыбалку
enum FishingExpenseCategory {
  tackle('tackle', '🎣'),           // Снасти и оборудование
  bait('bait', '🪱'),              // Наживка и прикормка
  transport('transport', '🚗'),     // Транспорт
  accommodation('accommodation', '🏠'), // Проживание
  food('food', '🍽️'),             // Питание
  license('license', '📋');         // Лицензии и разрешения

  const FishingExpenseCategory(this.id, this.icon);
  final String id;
  final String icon;

  /// Получить категорию по ID
  static FishingExpenseCategory? fromId(String id) {
    for (var category in FishingExpenseCategory.values) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Получить все категории в виде списка
  static List<FishingExpenseCategory> get allCategories => FishingExpenseCategory.values;
}

/// Модель расхода на рыбалку
class FishingExpenseModel {
  /// Уникальный идентификатор
  final String id;

  /// ID пользователя
  final String userId;

  /// Сумма расхода
  final double amount;

  /// Категория расхода
  final FishingExpenseCategory category;

  /// Описание расхода
  final String description;

  /// Дата расхода
  final DateTime date;

  /// Дата создания записи
  final DateTime createdAt;

  /// Дата последнего обновления
  final DateTime updatedAt;

  /// Связанная заметка о рыбалке (опционально)
  final String? fishingNoteId;

  /// Валюта (по умолчанию тенге)
  final String currency;

  /// Дополнительные заметки
  final String? notes;

  /// Геолокация покупки (опционально)
  final GeoPoint? location;

  /// Название места покупки
  final String? locationName;

  /// Признак синхронизации с сервером
  final bool isSynced;

  const FishingExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.fishingNoteId,
    this.currency = 'KZT',
    this.notes,
    this.location,
    this.locationName,
    this.isSynced = false,
  });

  /// Создать копию модели с изменениями
  FishingExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    FishingExpenseCategory? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fishingNoteId,
    String? currency,
    String? notes,
    GeoPoint? location,
    String? locationName,
    bool? isSynced,
  }) {
    return FishingExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fishingNoteId: fishingNoteId ?? this.fishingNoteId,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Создать модель из Map (например, из Firestore)
  factory FishingExpenseModel.fromMap(Map<String, dynamic> map) {
    return FishingExpenseModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: FishingExpenseCategory.fromId(map['category'] as String) ??
          FishingExpenseCategory.tackle,
      description: map['description'] as String,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      fishingNoteId: map['fishingNoteId'] as String?,
      currency: map['currency'] as String? ?? 'KZT',
      notes: map['notes'] as String?,
      location: map['location'] as GeoPoint?,
      locationName: map['locationName'] as String?,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  /// Преобразовать модель в Map для сохранения в Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category.id,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fishingNoteId': fishingNoteId,
      'currency': currency,
      'notes': notes,
      'location': location,
      'locationName': locationName,
      'isSynced': isSynced,
    };
  }

  /// Преобразовать в JSON для локального хранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category.id,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fishingNoteId': fishingNoteId,
      'currency': currency,
      'notes': notes,
      'location': location != null ? {
        'latitude': location!.latitude,
        'longitude': location!.longitude,
      } : null,
      'locationName': locationName,
      'isSynced': isSynced,
    };
  }

  /// Создать модель из JSON
  factory FishingExpenseModel.fromJson(Map<String, dynamic> json) {
    return FishingExpenseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: FishingExpenseCategory.fromId(json['category'] as String) ??
          FishingExpenseCategory.tackle,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      fishingNoteId: json['fishingNoteId'] as String?,
      currency: json['currency'] as String? ?? 'KZT',
      notes: json['notes'] as String?,
      location: json['location'] != null ?
      GeoPoint(
        json['location']['latitude'] as double,
        json['location']['longitude'] as double,
      ) : null,
      locationName: json['locationName'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  /// Создать новый расход
  factory FishingExpenseModel.create({
    required String userId,
    required double amount,
    required FishingExpenseCategory category,
    required String description,
    DateTime? date,
    String? fishingNoteId,
    String currency = 'KZT',
    String? notes,
    GeoPoint? location,
    String? locationName,
  }) {
    final now = DateTime.now();
    return FishingExpenseModel(
      id: 'expense_${now.millisecondsSinceEpoch}',
      userId: userId,
      amount: amount,
      category: category,
      description: description,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
      fishingNoteId: fishingNoteId,
      currency: currency,
      notes: notes,
      location: location,
      locationName: locationName,
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

  /// Отформатированная сумма с символом валюты
  String get formattedAmount {
    return '$currencySymbol ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  /// Краткое отформатированное описание для списков
  String get shortDescription {
    if (description.length <= 50) return description;
    return '${description.substring(0, 47)}...';
  }

  /// Проверка валидности данных
  bool get isValid {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        amount > 0 &&
        description.isNotEmpty;
  }

  /// Отметить как синхронизированный
  FishingExpenseModel markAsSynced() {
    return copyWith(isSynced: true);
  }

  /// Обновить временную метку
  FishingExpenseModel touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FishingExpenseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FishingExpenseModel(id: $id, amount: $formattedAmount, category: ${category.id}, description: $description)';
  }
}

/// Модель статистики расходов
class FishingExpenseStatistics {
  /// Общая сумма расходов
  final double totalAmount;

  /// Количество расходов
  final int totalCount;

  /// Расходы по категориям
  final Map<FishingExpenseCategory, double> categoryTotals;

  /// Количество расходов по категориям
  final Map<FishingExpenseCategory, int> categoryCounts;

  /// Средний расход
  final double averageExpense;

  /// Самый дорогой расход
  final FishingExpenseModel? mostExpensive;

  /// Период статистики
  final DateTime startDate;
  final DateTime endDate;

  /// Валюта статистики
  final String currency;

  const FishingExpenseStatistics({
    required this.totalAmount,
    required this.totalCount,
    required this.categoryTotals,
    required this.categoryCounts,
    required this.averageExpense,
    this.mostExpensive,
    required this.startDate,
    required this.endDate,
    this.currency = 'KZT',
  });

  /// Создать статистику из списка расходов
  factory FishingExpenseStatistics.fromExpenses(
      List<FishingExpenseModel> expenses, {
        DateTime? startDate,
        DateTime? endDate,
        String currency = 'KZT',
      }) {
    if (expenses.isEmpty) {
      return FishingExpenseStatistics(
        totalAmount: 0,
        totalCount: 0,
        categoryTotals: {},
        categoryCounts: {},
        averageExpense: 0,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now(),
        currency: currency,
      );
    }

    // Фильтруем расходы по периоду если указан
    var filteredExpenses = expenses;
    if (startDate != null || endDate != null) {
      filteredExpenses = expenses.where((expense) {
        if (startDate != null && expense.date.isBefore(startDate)) return false;
        if (endDate != null && expense.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    // Вычисляем общую сумму
    final totalAmount = filteredExpenses.fold<double>(
      0, (sum, expense) => sum + expense.amount,
    );

    // Группируем по категориям
    final Map<FishingExpenseCategory, double> categoryTotals = {};
    final Map<FishingExpenseCategory, int> categoryCounts = {};

    for (var expense in filteredExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
      categoryCounts[expense.category] =
          (categoryCounts[expense.category] ?? 0) + 1;
    }

    // Находим самый дорогой расход
    FishingExpenseModel? mostExpensive;
    if (filteredExpenses.isNotEmpty) {
      mostExpensive = filteredExpenses.reduce(
            (current, next) => current.amount > next.amount ? current : next,
      );
    }

    return FishingExpenseStatistics(
      totalAmount: totalAmount,
      totalCount: filteredExpenses.length,
      categoryTotals: categoryTotals,
      categoryCounts: categoryCounts,
      averageExpense: filteredExpenses.isEmpty ? 0 : totalAmount / filteredExpenses.length,
      mostExpensive: mostExpensive,
      startDate: startDate ?? (filteredExpenses.isEmpty ? DateTime.now() :
      filteredExpenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b)),
      endDate: endDate ?? (filteredExpenses.isEmpty ? DateTime.now() :
      filteredExpenses.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b)),
      currency: currency,
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

  /// Отформатированная общая сумма
  String get formattedTotal {
    return '$currencySymbol ${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}';
  }

  /// Отформатированная средняя сумма
  String get formattedAverage {
    return '$currencySymbol ${averageExpense.toStringAsFixed(averageExpense.truncateToDouble() == averageExpense ? 0 : 2)}';
  }

  /// Получить процент расходов по категории
  double getCategoryPercentage(FishingExpenseCategory category) {
    if (totalAmount == 0) return 0;
    final categoryAmount = categoryTotals[category] ?? 0;
    return (categoryAmount / totalAmount) * 100;
  }

  /// Получить топ категории по расходам
  List<MapEntry<FishingExpenseCategory, double>> getTopCategories([int limit = 3]) {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }
}