// Путь: lib/models/isar/fishing_diary_entity.dart

import 'package:isar/isar.dart';

part 'fishing_diary_entity.g.dart';

@Collection()
class FishingDiaryEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  @Index()
  late String userId; // ID пользователя, которому принадлежит запись

  late String title; // Название записи дневника

  String? description; // Описание записи дневника

  bool isFavorite = false; // Избранная запись

  bool isSynced = false; // Флаг синхронизации с Firebase

  @Index()
  bool markedForDeletion = false; // Помечено для удаления (офлайн режим)

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}