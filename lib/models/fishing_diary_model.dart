// Путь: lib/models/fishing_diary_model.dart

import '../models/isar/fishing_diary_entity.dart';

class FishingDiaryModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  FishingDiaryModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.isFavorite = false,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FishingDiaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Преобразование в Entity для сохранения в Isar
  FishingDiaryEntity toEntity() {
    return FishingDiaryEntity()
      ..firebaseId = id
      ..userId = userId
      ..title = title
      ..description = description
      ..isFavorite = isFavorite
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
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}