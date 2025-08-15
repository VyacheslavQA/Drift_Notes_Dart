// File: lib/models/fishing_diary_folder_model.dart (New file)

import '../models/isar/fishing_diary_folder_entity.dart';

class FishingDiaryFolderModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String colorHex; // Цвет папки в hex формате (например: "#4CAF50")
  final int sortOrder; // Порядок сортировки папок
  final DateTime createdAt;
  final DateTime updatedAt;

  const FishingDiaryFolderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.colorHex,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание копии с изменениями
  FishingDiaryFolderModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? colorHex,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FishingDiaryFolderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Преобразование в JSON для Firebase
  Map<String, dynamic> toJson() {
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

  // Создание модели из JSON
  factory FishingDiaryFolderModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FishingDiaryFolderModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      colorHex: json['colorHex'] ?? '#4CAF50',
      sortOrder: json['sortOrder'] ?? 0,
      createdAt: (json['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: (json['updatedAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Преобразование в Entity для сохранения в Isar
  FishingDiaryFolderEntity toEntity() {
    return FishingDiaryFolderEntity()
      ..firebaseId = id
      ..userId = userId
      ..name = name
      ..description = description
      ..colorHex = colorHex
      ..sortOrder = sortOrder
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }

  // Создание модели из Entity
  factory FishingDiaryFolderModel.fromEntity(FishingDiaryFolderEntity entity) {
    return FishingDiaryFolderModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      colorHex: entity.colorHex,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FishingDiaryFolderModel(id: $id, name: $name, colorHex: $colorHex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FishingDiaryFolderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}