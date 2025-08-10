// Путь: lib/models/isar/bait_program_entity.dart

import 'package:isar/isar.dart';

part 'bait_program_entity.g.dart';

@Collection()
class BaitProgramEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  @Index()
  late String userId; // ID пользователя, которому принадлежит программа

  late String title; // Название программы

  String? description; // Описание программы

  bool isFavorite = false; // Избранная программа

  bool isSynced = false; // Флаг синхронизации с Firebase

  @Index()
  bool markedForDeletion = false; // Помечено для удаления (офлайн режим)

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}