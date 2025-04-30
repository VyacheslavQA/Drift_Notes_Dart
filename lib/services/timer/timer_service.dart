// Путь: lib/services/timer/timer_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/timer_model.dart';

class TimerService {
  final List<FishingTimerModel> _timers = [];
  final List<Timer> _runningTimers = [];

  // Стримы для обновления UI
  final _timerStreamController = StreamController<List<FishingTimerModel>>.broadcast();
  Stream<List<FishingTimerModel>> get timersStream => _timerStreamController.stream;

  bool _isInitialized = false;

  // Цвета таймеров
  static final Map<String, Color> timerColors = {
    'green': const Color(0xFF2E7D32),   // Зеленый
    'red': const Color(0xFFD32F2F),     // Красный
    'orange': const Color(0xFFFF8F00),  // Оранжевый
    'blue': const Color(0xFF1976D2),    // Синий
  };

  // Звуки оповещений
  static final List<String> alertSounds = [
    'default_alert.mp3',
    'fish_splash.mp3',
    'bell.mp3',
    'alarm.mp3',
  ];

  // Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Загрузка сохраненных таймеров
    await _loadTimers();

    // Создание таймеров по умолчанию, если их нет
    if (_timers.isEmpty) {
      for (int i = 1; i <= 4; i++) {
        _timers.add(FishingTimerModel(
          id: i.toString(),
          name: 'Таймер $i',
        ));
      }
    }

    // Восстановление работающих таймеров
    _restoreRunningTimers();

    _isInitialized = true;
    _notifyListeners();
  }

  // Получение списка таймеров
  List<FishingTimerModel> get timers => List.unmodifiable(_timers);

  // Запуск таймера
  void startTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    final now = DateTime.now();
    _timers[index] = _timers[index].copyWith(
      isRunning: true,
      startTime: now,
    );

    // Запускаем таймер
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Нам нужно обновить только UI, сам таймер идет от startTime
      _notifyListeners();
    });

    // Сохраняем таймер
    _runningTimers.add(timer);

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }

  // Остановка таймера
  void stopTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    // Если таймер был запущен, сохраняем прошедшее время
    if (_timers[index].isRunning && _timers[index].startTime != null) {
      final elapsed = DateTime.now().difference(_timers[index].startTime!);
      final newDuration = _timers[index].duration + elapsed;

      _timers[index] = _timers[index].copyWith(
        isRunning: false,
        duration: newDuration,
        startTime: null,
      );
    } else {
      _timers[index] = _timers[index].copyWith(
        isRunning: false,
        startTime: null,
      );
    }

    // Останавливаем таймер
    if (index < _runningTimers.length) {
      _runningTimers[index].cancel();
      _runningTimers.removeAt(index);
    }

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }

  // Сброс таймера
  void resetTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    // Останавливаем таймер если он запущен
    if (_timers[index].isRunning) {
      if (index < _runningTimers.length) {
        _runningTimers[index].cancel();
        _runningTimers.removeAt(index);
      }
    }

    // Сбрасываем все значения
    _timers[index] = _timers[index].copyWith(
      isRunning: false,
      duration: const Duration(seconds: 0),
      startTime: null,
    );

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }

  // Обновление настроек таймера
  void updateTimerSettings(String id, {
    String? name,
    Color? timerColor,
    String? alertSound,
  }) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    _timers[index] = _timers[index].copyWith(
      name: name,
      timerColor: timerColor,
      alertSound: alertSound,
    );

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }

  // Получение текущего времени таймера
  Duration getCurrentDuration(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return Duration.zero;

    final timer = _timers[index];
    if (!timer.isRunning || timer.startTime == null) {
      return timer.duration;
    }

    // Вычисляем прошедшее время с момента запуска
    final elapsed = DateTime.now().difference(timer.startTime!);
    return timer.duration + elapsed;
  }

  // Сохранение таймеров
  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> timersJson = _timers.map((timer) =>
        jsonEncode(timer.toJson())).toList();

    await prefs.setStringList('fishing_timers', timersJson);
  }

  // Загрузка таймеров
  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? timersJson = prefs.getStringList('fishing_timers');

    if (timersJson != null) {
      _timers.clear();
      for (var timerJson in timersJson) {
        final Map<String, dynamic> timerMap = jsonDecode(timerJson);
        _timers.add(FishingTimerModel.fromJson(timerMap));
      }
    }
  }

  // Восстановление работающих таймеров
  void _restoreRunningTimers() {
    for (var timer in _timers) {
      if (timer.isRunning && timer.startTime != null) {
        // Запускаем таймер
        final timerInstance = Timer.periodic(const Duration(seconds: 1), (t) {
          _notifyListeners();
        });
        _runningTimers.add(timerInstance);
      }
    }
  }

  // Метод для оповещения слушателей об изменениях
  void _notifyListeners() {
    _timerStreamController.add(List.unmodifiable(_timers));
  }

  // Очистка ресурсов
  void dispose() {
    for (var timer in _runningTimers) {
      timer.cancel();
    }
    _runningTimers.clear();
    _timerStreamController.close();
  }
  // Установка длительности таймера
  void setTimerDuration(String id, Duration duration) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    _timers[index] = _timers[index].copyWith(
      duration: duration,
    );

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }
}