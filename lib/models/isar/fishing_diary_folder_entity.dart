// File: lib/models/isar/fishing_diary_folder_entity.dart (New file)

import 'package:isar/isar.dart';

part 'fishing_diary_folder_entity.g.dart';

@Collection()
class FishingDiaryFolderEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  @Index()
  late String userId; // ID пользователя, которому принадлежит папка

  late String name; // Название папки

  String? description; // Описание папки

  late String colorHex; // Цвет папки в hex формате (например: "#4CAF50")

  int sortOrder = 0; // Порядок сортировки папок

  bool isSynced = false; // Флаг синхронизации с Firebase

  @Index()
  bool markedForDeletion = false; // Помечено для удаления (офлайн режим)

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  /// Помечает папку как синхронизированную
  void markAsSynced() {
    isSynced = true;
    updatedAt = DateTime.now();
  }

  /// Помечает папку как измененную (требует синхронизации)
  void markAsModified() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  /// Помечает папку для удаления
  void markForDeletion() {
    markedForDeletion = true;
    isSynced = false;
    updatedAt = DateTime.now();
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Создание entity из данных Firestore
  static FishingDiaryFolderEntity fromFirestoreMap(String firebaseId, Map<String, dynamic> data) {
    final entity = FishingDiaryFolderEntity()
      ..firebaseId = firebaseId
      ..userId = data['userId'] ?? ''
      ..name = data['name'] ?? ''
      ..description = data['description']
      ..colorHex = data['colorHex'] ?? '#4CAF50'
      ..sortOrder = data['sortOrder'] ?? 0
      ..isSynced = true
      ..markedForDeletion = false;

    // Парсинг временных меток
    if (data['createdAt'] != null) {
      if (data['createdAt'] is int) {
        entity.createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
      } else if (data['createdAt'].toDate != null) {
        entity.createdAt = data['createdAt'].toDate();
      }
    }

    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is int) {
        entity.updatedAt = DateTime.fromMillisecondsSinceEpoch(data['updatedAt']);
      } else if (data['updatedAt'].toDate != null) {
        entity.updatedAt = data['updatedAt'].toDate();
      }
    }

    return entity;
  }

  @override
  String toString() {
    return 'FishingDiaryFolderEntity(id: $id, firebaseId: $firebaseId, name: $name, colorHex: $colorHex, markedForDeletion: $markedForDeletion)';
  }
}