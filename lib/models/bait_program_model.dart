// Путь: lib/models/bait_program_model.dart

class BaitProgramModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaitProgramModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BaitProgramModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return BaitProgramModel(
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

  BaitProgramModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BaitProgramModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}