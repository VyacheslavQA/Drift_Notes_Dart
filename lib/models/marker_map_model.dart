// Путь: lib/models/marker_map_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MarkerMapModel {
  final String id;
  final String userId;
  final String name;
  final DateTime date;
  final String? sector;
  final String? noteId;
  final String? noteName;
  final List<Map<String, dynamic>> markers;

  MarkerMapModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.sector,
    this.noteId,
    this.noteName,
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
      noteId: json['noteId'],
      noteName: json['noteName'],
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
      'noteId': noteId,
      'noteName': noteName,
      'markers': markers,
    };
  }

  MarkerMapModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    String? sector,
    String? noteId,
    String? noteName,
    List<Map<String, dynamic>>? markers,
  }) {
    return MarkerMapModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      sector: sector ?? this.sector,
      noteId: noteId ?? this.noteId,
      noteName: noteName ?? this.noteName,
      markers: markers ?? this.markers,
    );
  }
}