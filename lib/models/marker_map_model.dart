// Путь: lib/models/marker_map_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MarkerMapModel {
  final String id;
  final String userId;
  final String name;
  final DateTime date;
  final String? sector;
  final List<String> noteIds; // Изменено: теперь список ID заметок
  final List<String> noteNames; // Изменено: теперь список названий заметок
  final List<Map<String, dynamic>> markers;

  MarkerMapModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.sector,
    this.noteIds = const [],
    this.noteNames = const [],
    this.markers = const [],
  });

  factory MarkerMapModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return MarkerMapModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      date: (json['date'] != null)
          ? (json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(json['date']))
          : DateTime.now(),
      sector: json['sector'],
      // Поддерживаем старый формат для обратной совместимости
      noteIds: json['noteIds'] != null
          ? List<String>.from(json['noteIds'])
          : (json['noteId'] != null ? [json['noteId']] : []),
      noteNames: json['noteNames'] != null
          ? List<String>.from(json['noteNames'])
          : (json['noteName'] != null ? [json['noteName']] : []),
      markers: json['markers'] != null
          ? List<Map<String, dynamic>>.from(json['markers'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'sector': sector,
      'noteIds': noteIds,
      'noteNames': noteNames,
      'markers': markers,
    };
  }

  MarkerMapModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    String? sector,
    List<String>? noteIds,
    List<String>? noteNames,
    List<Map<String, dynamic>>? markers,
  }) {
    return MarkerMapModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      sector: sector ?? this.sector,
      noteIds: noteIds ?? this.noteIds,
      noteNames: noteNames ?? this.noteNames,
      markers: markers ?? this.markers,
    );
  }

  // Вспомогательные методы для работы с привязками
  bool hasNoteAttached(String noteId) {
    return noteIds.contains(noteId);
  }

  String get attachedNotesText {
    if (noteNames.isEmpty) return '';
    if (noteNames.length == 1) return noteNames.first;
    return '${noteNames.length} заметок';
  }

  // Метод для получения первой привязанной заметки (для обратной совместимости)
  String? get noteId => noteIds.isNotEmpty ? noteIds.first : null;
  String? get noteName => noteNames.isNotEmpty ? noteNames.first : null;
}