// Путь: lib/models/isar/marker_map_entity.dart

import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Index, Query;
import 'dart:convert';

part 'marker_map_entity.g.dart';

@Collection()
class MarkerMapEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  @Index()
  late String userId; // ID пользователя

  late String name; // Название карты

  late DateTime date; // Дата создания карты

  String? sector; // Сектор/область

  List<String> noteIds = []; // Список ID заметок

  List<String> noteNames = []; // Список названий заметок

  String markersJson = '[]'; // JSON строка с маркерами

  bool isSynced = false; // Флаг синхронизации с Firebase

  // ✅ ИСПРАВЛЕНО: Добавлен индекс для эффективных запросов офлайн удаления
  @Index()
  bool markedForDeletion = false; // Флаг для удаления

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  // ========================================
  // ✅ КОНСТРУКТОР ПО УМОЛЧАНИЮ (КРИТИЧНО!)
  // ========================================

  MarkerMapEntity();

  // ========================================
  // МЕТОДЫ ДЛЯ РАБОТЫ С МАРКЕРАМИ
  // ========================================

  // Вспомогательные методы для работы с маркерами (не сохраняются в БД)
  @ignore
  List<Map<String, dynamic>> get markers {
    try {
      if (markersJson.isEmpty) return [];
      final dynamic decoded = _decodeJson(markersJson);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 🔥 ИСПРАВЛЕНО: убрана аннотация @ignore с сеттера
  set markers(List<Map<String, dynamic>> value) {
    try {
      markersJson = _encodeJson(value);
    } catch (e) {
      markersJson = '[]';
    }
  }

  // ========================================
  // ✅ МЕТОДЫ ДЛЯ SYNC_SERVICE (КРИТИЧНО!)
  // ========================================

  /// Преобразовать в Map для Firestore (для SyncService)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'name': name,
      'date': Timestamp.fromDate(date),
      'sector': sector,
      'noteIds': noteIds,
      'noteNames': noteNames,
      'markers': markers, // Преобразуем JSON обратно в List для Firestore
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSynced': true, // В Firestore всегда синхронизировано
      'markedForDeletion': markedForDeletion,
    };
  }

  /// Создать из Firestore Map (для SyncService)
  factory MarkerMapEntity.fromFirestoreMap(String firebaseId, Map<String, dynamic> data) {
    final entity = MarkerMapEntity()
      ..firebaseId = firebaseId
      ..userId = data['userId'] as String
      ..name = data['name'] as String
      ..date = (data['date'] as Timestamp).toDate()
      ..sector = data['sector'] as String?
      ..noteIds = List<String>.from(data['noteIds'] ?? [])
      ..noteNames = List<String>.from(data['noteNames'] ?? [])
      ..createdAt = data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now()
      ..updatedAt = data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now()
      ..isSynced = true // Из Firestore всегда синхронизировано
      ..markedForDeletion = data['markedForDeletion'] as bool? ?? false;

    // Парсим маркеры из Firestore
    final markersData = data['markers'] as List<dynamic>? ?? [];
    entity.markers = markersData.map((marker) => Map<String, dynamic>.from(marker)).toList();

    return entity;
  }

  // ========================================
  // МЕТОДЫ ДЛЯ СИНХРОНИЗАЦИИ
  // ========================================

  void markAsSynced() {
    isSynced = true;
    updatedAt = DateTime.now();
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

  // ========================================
  // МЕТОДЫ ДЛЯ РАБОТЫ С ПРИВЯЗКАМИ
  // ========================================

  // Вспомогательные методы для работы с привязками
  bool hasNoteAttached(String noteId) {
    return noteIds.contains(noteId);
  }

  String get attachedNotesText {
    if (noteNames.isEmpty) return '';
    if (noteNames.length == 1) return noteNames.first;
    return '${noteNames.length} заметок';
  }

  // Методы для получения первой привязанной заметки (для обратной совместимости)
  String? get noteId => noteIds.isNotEmpty ? noteIds.first : null;
  String? get noteName => noteNames.isNotEmpty ? noteNames.first : null;

  // ========================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ JSON
  // ========================================

  // JSON методы для работы с маркерами
  static dynamic _decodeJson(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      return [];
    }
  }

  static String _encodeJson(dynamic object) {
    try {
      return json.encode(object);
    } catch (e) {
      return '[]';
    }
  }

  // ========================================
  // ✅ ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ
  // ========================================

  /// Добавить привязку к заметке
  void attachNote(String noteId, String noteName) {
    if (!noteIds.contains(noteId)) {
      noteIds.add(noteId);
      noteNames.add(noteName);
      markAsModified();
    }
  }

  /// Удалить привязку к заметке
  void detachNote(String noteId) {
    final index = noteIds.indexOf(noteId);
    if (index != -1) {
      noteIds.removeAt(index);
      if (index < noteNames.length) {
        noteNames.removeAt(index);
      }
      markAsModified();
    }
  }

  /// Обновить название привязанной заметки
  void updateNoteName(String noteId, String newName) {
    final index = noteIds.indexOf(noteId);
    if (index != -1 && index < noteNames.length) {
      noteNames[index] = newName;
      markAsModified();
    }
  }

  /// Добавить маркер
  void addMarker(Map<String, dynamic> marker) {
    final currentMarkers = markers;
    currentMarkers.add(marker);
    markers = currentMarkers;
    markAsModified();
  }

  /// Удалить маркер по индексу
  void removeMarker(int index) {
    final currentMarkers = markers;
    if (index >= 0 && index < currentMarkers.length) {
      currentMarkers.removeAt(index);
      markers = currentMarkers;
      markAsModified();
    }
  }

  /// Обновить маркер
  void updateMarker(int index, Map<String, dynamic> updatedMarker) {
    final currentMarkers = markers;
    if (index >= 0 && index < currentMarkers.length) {
      currentMarkers[index] = updatedMarker;
      markers = currentMarkers;
      markAsModified();
    }
  }

  /// Получить количество маркеров
  int get markersCount => markers.length;

  /// Проверить есть ли маркеры
  bool get hasMarkers => markers.isNotEmpty;

  /// Очистить все маркеры
  void clearMarkers() {
    markers = [];
    markAsModified();
  }

  @override
  String toString() {
    return 'MarkerMapEntity(id: $id, firebaseId: $firebaseId, name: $name, userId: $userId, markersCount: $markersCount, notesCount: ${noteIds.length})';
  }
}