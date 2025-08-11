// Путь: lib/models/isar/budget_note_entity.dart

import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Index, Query;
import 'dart:convert';
import '../fishing_expense_model.dart';
import '../fishing_trip_model.dart';

part 'budget_note_entity.g.dart';

@Collection()
class BudgetNoteEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  @Index()
  late String userId; // ID пользователя

  late DateTime date; // Дата поездки

  DateTime? endDate; // Дата окончания (для многодневных поездок)

  bool isMultiDay = false; // Многодневная поездка

  String? locationName; // Название места рыбалки

  String? notes; // Общие заметки о поездке

  double totalAmount = 0.0; // Общая сумма расходов

  int expenseCount = 0; // Количество расходов

  // Расходы в JSON формате (Isar не поддерживает List<Object>)
  String expensesJson = '[]';

  bool isSynced = false; // Флаг синхронизации с Firebase

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  // Дополнительные поля для синхронизации
  DateTime? lastSyncAt;

  // ✅ ИСПРАВЛЕНО: Добавлен индекс для эффективных запросов офлайн удаления
  @Index()
  bool markedForDeletion = false;

  BudgetNoteEntity();

  /// Получить расходы из JSON
  @ignore
  List<FishingExpenseModel> get expenses {
    if (expensesJson.isEmpty || expensesJson == '[]') return [];

    try {
      final List<dynamic> data = jsonDecode(expensesJson);
      return data.map((item) => FishingExpenseModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Установить расходы (конвертирует в JSON)
  // 🔥 ИСПРАВЛЕНО: убрана аннотация @ignore с сеттера
  set expenses(List<FishingExpenseModel> newExpenses) {
    if (newExpenses.isEmpty) {
      expensesJson = '[]';
      totalAmount = 0.0;
      expenseCount = 0;
    } else {
      try {
        final expensesData = newExpenses.map((expense) => expense.toJson()).toList();
        expensesJson = jsonEncode(expensesData);
        totalAmount = newExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
        expenseCount = newExpenses.length;
      } catch (e) {
        expensesJson = '[]';
        totalAmount = 0.0;
        expenseCount = 0;
      }
    }
    updatedAt = DateTime.now();
  }

  // ========================================
  // ✅ МЕТОДЫ ДЛЯ SYNC_SERVICE (КРИТИЧНО!)
  // ========================================

  /// Преобразовать в Map для Firestore (для SyncService)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isMultiDay': isMultiDay,
      'locationName': locationName,
      'notes': notes,
      'totalAmount': totalAmount,
      'expenseCount': expenseCount,
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSynced': true, // В Firestore всегда синхронизировано
      'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
      'markedForDeletion': markedForDeletion,
    };
  }

  /// Создать из Firestore Map (для SyncService)
  factory BudgetNoteEntity.fromFirestoreMap(String firebaseId, Map<String, dynamic> data) {
    final entity = BudgetNoteEntity()
      ..firebaseId = firebaseId
      ..userId = data['userId'] as String
      ..date = (data['date'] as Timestamp).toDate()
      ..endDate = data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null
      ..isMultiDay = data['isMultiDay'] as bool? ?? false
      ..locationName = data['locationName'] as String?
      ..notes = data['notes'] as String?
      ..totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0
      ..expenseCount = data['expenseCount'] as int? ?? 0
      ..createdAt = data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now()
      ..updatedAt = data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now()
      ..isSynced = true // Из Firestore всегда синхронизировано
      ..lastSyncAt = data['lastSyncAt'] != null
          ? (data['lastSyncAt'] as Timestamp).toDate()
          : null
      ..markedForDeletion = data['markedForDeletion'] as bool? ?? false;

    // Парсим расходы из Firestore
    final expensesData = data['expenses'] as List<dynamic>? ?? [];
    final expensesList = expensesData
        .map((data) => FishingExpenseModel.fromMap(data as Map<String, dynamic>))
        .toList();

    entity.expenses = expensesList;

    return entity;
  }

  // ========================================
  // ОСТАЛЬНЫЕ МЕТОДЫ (БЕЗ ИЗМЕНЕНИЙ)
  // ========================================

  /// Создать из FishingTripModel
  factory BudgetNoteEntity.fromTripModel(FishingTripModel trip) {
    final entity = BudgetNoteEntity()
      ..firebaseId = trip.id
      ..userId = trip.userId
      ..date = trip.date
      ..locationName = trip.locationName
      ..notes = trip.notes
      ..createdAt = trip.createdAt
      ..updatedAt = trip.updatedAt
      ..isSynced = trip.isSynced;

    // Устанавливаем расходы через setter
    entity.expenses = trip.expenses;

    return entity;
  }

  /// Преобразовать в FishingTripModel
  FishingTripModel toTripModel() {
    return FishingTripModel(
      id: firebaseId ?? 'local_$id',
      userId: userId,
      date: date,
      locationName: locationName,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      expenses: expenses,
    );
  }

  /// Создать новую заметку бюджета
  factory BudgetNoteEntity.create({
    required String customId,
    required String userId,
    required DateTime date,
    DateTime? endDate,
    bool isMultiDay = false,
    String? locationName,
    String? notes,
    List<FishingExpenseModel> expenses = const [],
  }) {
    final now = DateTime.now();
    final entity = BudgetNoteEntity()
      ..firebaseId = customId
      ..userId = userId
      ..date = date
      ..endDate = endDate
      ..isMultiDay = isMultiDay
      ..locationName = locationName
      ..notes = notes
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false;

    // Устанавливаем расходы через setter
    entity.expenses = expenses;

    return entity;
  }

  /// Преобразовать в Map для Firestore (совместимость с существующим кодом)
  Map<String, dynamic> toMapWithExpenses() {
    return {
      'id': firebaseId,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isMultiDay': isMultiDay,
      'locationName': locationName,
      'notes': notes,
      'totalAmount': totalAmount,
      'expenseCount': expenseCount,
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced,
      'isOffline': !isSynced,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
      'markedForDeletion': markedForDeletion,
    };
  }

  /// Создать из Map (совместимость с существующим кодом)
  factory BudgetNoteEntity.fromMapWithExpenses(Map<String, dynamic> map) {
    final entity = BudgetNoteEntity()
      ..firebaseId = map['id'] as String?
      ..userId = map['userId'] as String
      ..date = DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
      ..endDate = map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null
      ..isMultiDay = map['isMultiDay'] as bool? ?? false
      ..locationName = map['locationName'] as String?
      ..notes = map['notes'] as String?
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0.0
      ..expenseCount = map['expenseCount'] as int? ?? 0
      ..createdAt = map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now()
      ..isSynced = map['isSynced'] as bool? ?? false
      ..lastSyncAt = map['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncAt'] as int)
          : null
      ..markedForDeletion = map['markedForDeletion'] as bool? ?? false;

    // Парсим расходы
    final expensesData = map['expenses'] as List<dynamic>? ?? [];
    final expensesList = expensesData
        .map((data) => FishingExpenseModel.fromMap(data as Map<String, dynamic>))
        .toList();

    entity.expenses = expensesList;

    return entity;
  }

  /// Отметить как синхронизированную
  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Отметить как измененную (требует синхронизации)
  void markAsModified() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  /// Отметить для удаления
  void markForDeletion() {
    markedForDeletion = true;
    updatedAt = DateTime.now();
  }

  /// Обновить временную метку
  void touch() {
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'BudgetNoteEntity(id: $id, firebaseId: $firebaseId, userId: $userId, totalAmount: $totalAmount, expenses: ${expenses.length})';
  }
}