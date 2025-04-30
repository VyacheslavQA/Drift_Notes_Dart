// Путь: lib/providers/timer_provider.dart

import 'package:flutter/material.dart';
import '../models/timer_model.dart';
import '../services/timer/timer_service.dart';

class TimerProvider extends ChangeNotifier {
  final TimerService _timerService = TimerService();

  List<FishingTimerModel> get timers => _timerService.timers;
  Stream<List<FishingTimerModel>> get timersStream => _timerService.timersStream;

  // Инициализация провайдера
  Future<void> initialize() async {
    await _timerService.initialize();
    notifyListeners();
  }

  // Установка длительности таймера
  void setTimerDuration(String id, Duration duration) {
    _timerService.setTimerDuration(id, duration);
    notifyListeners();
  }

  // Запуск таймера
  void startTimer(String id) {
    _timerService.startTimer(id);
    notifyListeners();
  }

  // Остановка таймера
  void stopTimer(String id) {
    _timerService.stopTimer(id);
    notifyListeners();
  }

  // Сброс таймера
  void resetTimer(String id) {
    _timerService.resetTimer(id);
    notifyListeners();
  }

  // Обновление настроек таймера
  void updateTimerSettings(String id, {
    String? name,
    Color? timerColor,
    String? alertSound,
  }) {
    _timerService.updateTimerSettings(
      id,
      name: name,
      timerColor: timerColor,
      alertSound: alertSound,
    );
    notifyListeners();
  }

  // Получение текущего времени таймера
  Duration getCurrentDuration(String id) {
    return _timerService.getCurrentDuration(id);
  }

  // Очистка ресурсов
  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
}