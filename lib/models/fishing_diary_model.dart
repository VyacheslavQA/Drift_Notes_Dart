// File: lib/models/fishing_diary_model.dart (Modify file)

import '../models/isar/fishing_diary_entity.dart';

class FishingDiaryModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isFavorite;
  final String? folderId; // 🆕 НОВОЕ: ID папки, к которой относится запись
  final DateTime createdAt;
  final DateTime updatedAt;

  FishingDiaryModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.isFavorite = false,
    this.folderId, // 🆕 НОВОЕ: Поддержка папок
    required this.createdAt,
    required this.updatedAt,
  });

  factory FishingDiaryModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FishingDiaryModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      folderId: json['folderId'], // 🆕 НОВОЕ: Читаем folderId из JSON
      createdAt: (json['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: (json['updatedAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isFavorite': isFavorite,
      'folderId': folderId, // 🆕 НОВОЕ: Включаем folderId в JSON
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  FishingDiaryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isFavorite,
    String? folderId, // 🆕 НОВОЕ: Возможность изменить папку
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FishingDiaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: folderId ?? this.folderId, // 🆕 НОВОЕ: Копирование folderId
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🆕 НОВЫЙ МЕТОД: Перемещение в папку
  FishingDiaryModel moveToFolder(String? newFolderId) {
    return copyWith(
      folderId: newFolderId,
      updatedAt: DateTime.now(),
    );
  }

  // 🆕 НОВЫЙ МЕТОД: Проверка принадлежности к папке
  bool isInFolder(String? checkFolderId) {
    return folderId == checkFolderId;
  }

  // 🆕 НОВЫЙ МЕТОД: Проверка записи без папки
  bool get isWithoutFolder => folderId == null;

  // Преобразование в Entity для сохранения в Isar
  FishingDiaryEntity toEntity() {
    return FishingDiaryEntity()
      ..firebaseId = id
      ..userId = userId
      ..title = title
      ..description = description
      ..isFavorite = isFavorite
      ..folderId = folderId // 🆕 НОВОЕ: Устанавливаем folderId в Entity
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }

  // Создание модели из Entity
  factory FishingDiaryModel.fromEntity(FishingDiaryEntity entity) {
    return FishingDiaryModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: entity.userId,
      title: entity.title,
      description: entity.description ?? '',
      isFavorite: entity.isFavorite,
      folderId: entity.folderId, // 🆕 НОВОЕ: Читаем folderId из Entity
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FishingDiaryModel(id: $id, title: $title, folderId: $folderId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FishingDiaryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}