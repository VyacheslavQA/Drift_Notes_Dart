import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_usage_limits_entity.g.dart';

@Collection()
class UserUsageLimitsEntity {
  Id id = Isar.autoIncrement;
  String? firebaseId;           // ID документа в Firebase (обычно "current")
  late String userId;           // ID пользователя

  // ✅ ОСНОВНЫЕ СЧЕТЧИКИ (точно как в Firebase)
  int budgetNotesCount = 0;     // Количество бюджетных заметок
  int expensesCount = 0;        // Количество расходов
  int markerMapsCount = 0;      // Количество карт с маркерами
  int notesCount = 0;           // Количество заметок о рыбалке
  int tripsCount = 0;           // Количество поездок

  // ✅ МЕТАДАННЫЕ ПЕРЕСЧЕТА (точно как в Firebase)
  String? lastResetDate;        // Дата последнего сброса (строка ISO)
  String? recalculatedAt;       // Время пересчета (строка ISO)
  String? recalculationType;    // Тип пересчета ("force_recalculate", etc.)

  // ✅ СИСТЕМНЫЕ ПОЛЯ
  late DateTime createdAt;      // Время создания
  late DateTime updatedAt;      // Время обновления
  bool isSynced = false;        // Статус синхронизации
  bool markedForDeletion = false; // Помечен для удаления
  DateTime? lastSyncAt;         // Время последней синхронизации

  // ✅ КОНСТРУКТОР
  UserUsageLimitsEntity();

  // ✅ МЕТОД КОНВЕРТАЦИИ В FIRESTORE MAP
  Map<String, dynamic> toFirestoreMap() {
    return {
      'budgetNotesCount': budgetNotesCount,
      'expensesCount': expensesCount,
      'markerMapsCount': markerMapsCount,
      'notesCount': notesCount,
      'tripsCount': tripsCount,
      'lastResetDate': lastResetDate,
      'recalculatedAt': recalculatedAt,
      'recalculationType': recalculationType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ✅ СТАТИЧЕСКИЙ МЕТОД СОЗДАНИЯ ИЗ FIRESTORE MAP
  static UserUsageLimitsEntity fromFirestoreMap(String firebaseId, Map<String, dynamic> data, String userId) {
    final entity = UserUsageLimitsEntity();

    entity.firebaseId = firebaseId;
    entity.userId = userId;

    // Основные счетчики
    entity.budgetNotesCount = data['budgetNotesCount'] ?? 0;
    entity.expensesCount = data['expensesCount'] ?? 0;
    entity.markerMapsCount = data['markerMapsCount'] ?? 0;
    entity.notesCount = data['notesCount'] ?? 0;
    entity.tripsCount = data['tripsCount'] ?? 0;

    // Метаданные пересчета
    entity.lastResetDate = data['lastResetDate'];
    entity.recalculatedAt = data['recalculatedAt'];
    entity.recalculationType = data['recalculationType'];

    // Системные поля
    entity.createdAt = _parseTimestamp(data['createdAt']) ?? DateTime.now();
    entity.updatedAt = _parseTimestamp(data['updatedAt']) ?? DateTime.now();
    entity.isSynced = true; // Данные из Firebase считаются синхронизированными
    entity.markedForDeletion = false;
    entity.lastSyncAt = DateTime.now();

    return entity;
  }

  // ✅ ВСПОМОГАТЕЛЬНЫЙ МЕТОД ПАРСИНГА TIMESTAMP
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }

    return null;
  }

  // ✅ МЕТОДЫ УПРАВЛЕНИЯ СОСТОЯНИЕМ СИНХРОНИЗАЦИИ
  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void markAsModified() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markForDeletion() {
    markedForDeletion = true;
    isSynced = false;
    updatedAt = DateTime.now();
  }

  // ✅ МЕТОДЫ ОБНОВЛЕНИЯ СЧЕТЧИКОВ
  void incrementBudgetNotesCount() {
    budgetNotesCount++;
    markAsModified();
  }

  void decrementBudgetNotesCount() {
    if (budgetNotesCount > 0) budgetNotesCount--;
    markAsModified();
  }

  void incrementExpensesCount() {
    expensesCount++;
    markAsModified();
  }

  void decrementExpensesCount() {
    if (expensesCount > 0) expensesCount--;
    markAsModified();
  }

  void incrementMarkerMapsCount() {
    markerMapsCount++;
    markAsModified();
  }

  void decrementMarkerMapsCount() {
    if (markerMapsCount > 0) markerMapsCount--;
    markAsModified();
  }

  void incrementNotesCount() {
    notesCount++;
    markAsModified();
  }

  void decrementNotesCount() {
    if (notesCount > 0) notesCount--;
    markAsModified();
  }

  void incrementTripsCount() {
    tripsCount++;
    markAsModified();
  }

  void decrementTripsCount() {
    if (tripsCount > 0) tripsCount--;
    markAsModified();
  }

  // ✅ МЕТОД ПОЛНОГО ПЕРЕСЧЕТА
  void recalculateCounters({
    required int newBudgetNotesCount,
    required int newExpensesCount,
    required int newMarkerMapsCount,
    required int newNotesCount,
    required int newTripsCount,
    String recalculationType = 'manual_recalculate',
  }) {
    budgetNotesCount = newBudgetNotesCount;
    expensesCount = newExpensesCount;
    markerMapsCount = newMarkerMapsCount;
    notesCount = newNotesCount;
    tripsCount = newTripsCount;

    this.recalculationType = recalculationType;
    recalculatedAt = DateTime.now().toIso8601String();

    markAsModified();
  }

  // ✅ МЕТОД СБРОСА ЛИМИТОВ
  void resetLimits() {
    budgetNotesCount = 0;
    expensesCount = 0;
    markerMapsCount = 0;
    notesCount = 0;
    tripsCount = 0;

    lastResetDate = DateTime.now().toIso8601String();
    recalculationType = 'reset';
    recalculatedAt = DateTime.now().toIso8601String();

    markAsModified();
  }

  // ✅ МЕТОДЫ ДЛЯ ОТЛАДКИ
  @override
  String toString() {
    return 'UserUsageLimitsEntity{'
        'id: $id, '
        'firebaseId: $firebaseId, '
        'userId: $userId, '
        'budgetNotesCount: $budgetNotesCount, '
        'expensesCount: $expensesCount, '
        'markerMapsCount: $markerMapsCount, '
        'notesCount: $notesCount, '
        'tripsCount: $tripsCount, '
        'isSynced: $isSynced, '
        'lastSyncAt: $lastSyncAt'
        '}';
  }
}