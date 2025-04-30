// Путь: lib/models/timer_model.dart

import 'package:flutter/material.dart';

class FishingTimerModel {
  String id;
  String name;
  Duration duration;
  bool isRunning;
  DateTime? startTime;
  Color timerColor;
  String alertSound;

  FishingTimerModel({
    required this.id,
    required this.name,
    this.duration = const Duration(seconds: 0),
    this.isRunning = false,
    this.startTime,
    this.timerColor = Colors.green,
    this.alertSound = 'default_alert.mp3',
  });

  // Копирование модели с обновленными значениями
  FishingTimerModel copyWith({
    String? id,
    String? name,
    Duration? duration,
    bool? isRunning,
    DateTime? startTime,
    Color? timerColor,
    String? alertSound,
  }) {
    return FishingTimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
      timerColor: timerColor ?? this.timerColor,
      alertSound: alertSound ?? this.alertSound,
    );
  }

  // Преобразование в Map для сохранения в SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration.inSeconds,
      'isRunning': isRunning,
      'startTime': startTime?.millisecondsSinceEpoch,
      'timerColor': timerColor.value,
      'alertSound': alertSound,
    };
  }

  // Создание объекта из Map
  factory FishingTimerModel.fromJson(Map<String, dynamic> json) {
    return FishingTimerModel(
      id: json['id'],
      name: json['name'],
      duration: Duration(seconds: json['duration'] ?? 0),
      isRunning: json['isRunning'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'])
          : null,
      timerColor: Color(json['timerColor'] ?? Colors.green.value),
      alertSound: json['alertSound'] ?? 'default_alert.mp3',
    );
  }
}