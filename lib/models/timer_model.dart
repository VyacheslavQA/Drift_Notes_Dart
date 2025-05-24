// Путь: lib/models/timer_model.dart

import 'package:flutter/material.dart';

class FishingTimerModel {
  String id;
  String name;
  Duration duration;      // Общая длительность
  Duration remainingTime; // Оставшееся время для обратного отсчета
  bool isRunning;
  DateTime? startTime;
  bool isCountdown;       // Флаг для определения режима (обычный/обратный отсчет)
  Color timerColor;
  String alertSound;

  FishingTimerModel({
    required this.id,
    required this.name,
    this.duration = const Duration(seconds: 0),
    this.remainingTime = const Duration(seconds: 0),
    this.isRunning = false,
    this.startTime,
    this.isCountdown = true, // Всегда в режиме обратного отсчета
    this.timerColor = Colors.green,
    this.alertSound = 'default_alert.mp3',
  });

  // Копирование модели с обновленными значениями
  FishingTimerModel copyWith({
    String? id,
    String? name,
    Duration? duration,
    Duration? remainingTime,
    bool? isRunning,
    DateTime? startTime,
    bool? isCountdown,
    Color? timerColor,
    String? alertSound,
  }) {
    return FishingTimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
      isCountdown: true, // Всегда в режиме обратного отсчета независимо от параметра isCountdown
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
      'remainingTime': remainingTime.inSeconds,
      'isRunning': isRunning,
      'startTime': startTime?.millisecondsSinceEpoch,
      'isCountdown': true, // Всегда true
      'timerColor': timerColor.value.toRadixString(16),
      'alertSound': alertSound,
    };
  }

  // Создание объекта из Map
  factory FishingTimerModel.fromJson(Map<String, dynamic> json) {
    return FishingTimerModel(
      id: json['id'],
      name: json['name'],
      duration: Duration(seconds: json['duration'] ?? 0),
      remainingTime: Duration(seconds: json['remainingTime'] ?? 0),
      isRunning: json['isRunning'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'])
          : null,
      isCountdown: true, // Всегда true, независимо от значения в JSON
      timerColor: Color(json['timerColor'] ?? Colors.green.value),
      alertSound: json['alertSound'] ?? 'default_alert.mp3',
    );
  }
}