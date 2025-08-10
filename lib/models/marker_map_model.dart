// Путь: lib/models/marker_map_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MarkerMapModel {
  final String id;
  final String userId;
  final String name;
  final DateTime date;
  final String? sector;
  final List<Map<String, dynamic>> markers;
  final Map<String, dynamic> rayLandmarks; // 🔥 НОВОЕ ПОЛЕ для ориентиров

  MarkerMapModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.sector,
    this.markers = const [],
    this.rayLandmarks = const {}, // 🔥 НОВОЕ ПОЛЕ с дефолтным значением
  });

  factory MarkerMapModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return MarkerMapModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      date:
      (json['date'] != null)
          ? (json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(json['date']))
          : DateTime.now(),
      sector: json['sector'],
      markers:
      json['markers'] != null
          ? List<Map<String, dynamic>>.from(json['markers'])
          : [],
      // 🔥 НОВАЯ ЛОГИКА для парсинга ориентиров
      rayLandmarks:
      json['rayLandmarks'] != null
          ? Map<String, dynamic>.from(json['rayLandmarks'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'sector': sector,
      'markers': markers,
      'rayLandmarks': rayLandmarks, // 🔥 НОВОЕ ПОЛЕ в JSON
    };
  }

  MarkerMapModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    String? sector,
    List<Map<String, dynamic>>? markers,
    Map<String, dynamic>? rayLandmarks, // 🔥 НОВЫЙ ПАРАМЕТР в copyWith
  }) {
    return MarkerMapModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      sector: sector ?? this.sector,
      markers: markers ?? this.markers,
      rayLandmarks: rayLandmarks ?? this.rayLandmarks, // 🔥 НОВАЯ ЛОГИКА копирования
    );
  }
}