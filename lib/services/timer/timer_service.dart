// Путь: lib/services/timer/timer_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../../models/timer_model.dart';

class TimerService {
  final List<FishingTimerModel> _timers = [];
  final List<Timer> _runningTimers = [];

  // Аудио плееры для воспроизведения звуков
  final Map<String, AudioPlayer> _alertPlayers = {};

  // Флаг для отслеживания проигрывания звуков по таймерам
  final Map<String, bool> _isPlayingAlert = {};

  // Стримы для обновления UI
  final _timerStreamController = StreamController<List<FishingTimerModel>>.broadcast();
  Stream<List<FishingTimerModel>> get timersStream => _timerStreamController.stream;

  bool _isInitialized = false;

  // Максимальное время воспроизведения в миллисекундах (20 секунд)
  final int _maxAlertDuration = 20000;

  // Цвета таймеров
  static final Map<String, Color> timerColors = {
    'green': const Color(0xFF2E7D32),   // Зеленый
    'red': const Color(0xFFD32F2F),     // Красный
    'orange': const Color(0xFFFF8F00),  // Оранжевый
    'blue': const Color(0xFF1976D2),    // Синий
  };

  // Звуки оповещений и их соответствующие ресурсы
  static final Map<String, String> alertSoundResources = {
    'default_alert.mp3': 'sounds/default_alert.mp3',
    'fish_splash.mp3': 'sounds/fish_splash.mp3',
    'bell.mp3': 'sounds/bell.mp3',
    'alarm.mp3': 'sounds/alarm.mp3',
  };

  // Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Загрузка сохраненных таймеров
    await _loadTimers();

    // Создание таймеров по умолчанию, если их нет
    if (_timers.isEmpty) {
      await _createDefaultTimers();
    } else {
      // Проверяем и мигрируем существующие таймеры
      await _migrateTimerNames();
    }

    // Восстановление работающих таймеров
    _restoreRunningTimers();

    _isInitialized = true;
    _notifyListeners();
  }

  // Создание таймеров по умолчанию с ключами локализации
  Future<void> _createDefaultTimers() async {
    for (int i = 1; i <= 4; i++) {
      _timers.add(FishingTimerModel(
        id: i.toString(),
        name: 'timer_$i', // Сохраняем ключ локализации
      ));
    }
    await _saveTimers();
    debugPrint('Созданы таймеры по умолчанию с ключами локализации');
  }

  // Миграция существующих названий таймеров на ключи локализации
  Future<void> _migrateTimerNames() async {
    bool needsSave = false;

    for (int i = 0; i < _timers.length; i++) {
      final timer = _timers[i];

      // Проверяем, нужно ли мигрировать название
      if (_shouldMigrateTimerName(timer.name, timer.id)) {
        _timers[i] = timer.copyWith(name: 'timer_${timer.id}');
        needsSave = true;
        debugPrint('Мигрировали таймер ${timer.id}: "${timer.name}" -> "timer_${timer.id}"');
      }
    }

    if (needsSave) {
      await _saveTimers();
      debugPrint('Миграция названий таймеров завершена');
    }
  }

  // Проверяем, нужно ли мигрировать название таймера
  bool _shouldMigrateTimerName(String currentName, String timerId) {
    // Список старых русских названий, которые нужно заменить
    final oldRussianNames = [
      'Таймер 1', 'Таймер 2', 'Таймер 3', 'Таймер 4',
      'Timer 1', 'Timer 2', 'Timer 3', 'Timer 4',
    ];

    // Если название уже является ключом локализации, не мигрируем
    if (currentName.startsWith('timer_')) {
      return false;
    }

    // Если это одно из стандартных названий и ID соответствует
    if (oldRussianNames.contains(currentName)) {
      return true;
    }

    // Если название пустое или совпадает с ID
    if (currentName.isEmpty || currentName == timerId) {
      return true;
    }

    return false;
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
      // Проверяем режим таймера (обратный отсчет)
      final currentDuration = getCurrentDuration(id);

      // Если время вышло, останавливаем таймер и запускаем уведомление
      if (currentDuration.inSeconds <= 0) {
        stopTimer(id);
        _notifyTimeIsUp(id);
        return;
      }

      // Нам нужно обновить только UI, сам таймер идет от startTime
      _notifyListeners();
    });

    // Сохраняем таймер
    _runningTimers.add(timer);

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }

  // Метод для уведомления о том, что время вышло
  Future<void> _notifyTimeIsUp(String id) async {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    // Проверяем, что звук уже не воспроизводится для этого таймера
    if (_isPlayingAlert[id] == true) {
      return;
    }

    // Отмечаем, что звук начал воспроизводиться
    _isPlayingAlert[id] = true;

    // Воспроизводим звук в зависимости от настроек таймера
    final soundFile = _timers[index].alertSound;
    await _playAlertSound(id, soundFile);

    // Автоматически останавливаем звук через определенное время
    Timer(Duration(milliseconds: _maxAlertDuration), () {
      _stopAlertSound(id);
      _isPlayingAlert[id] = false;
    });

    // Обновляем UI
    _notifyListeners();
  }

  // Воспроизведение звука оповещения
  Future<void> _playAlertSound(String timerId, String soundFile) async {
    try {
      // Сначала останавливаем звук, если он уже воспроизводится
      _stopAlertSound(timerId);

      // Создаем новый плеер для этого таймера
      _alertPlayers[timerId] = AudioPlayer();

      // Настраиваем обработчик окончания воспроизведения
      _alertPlayers[timerId]!.onPlayerComplete.listen((_) {
        _isPlayingAlert[timerId] = false;
      });

      // Проверяем, есть ли такой звук в ресурсах
      final soundResource = alertSoundResources[soundFile];
      if (soundResource != null) {
        debugPrint('Воспроизведение звука: $soundResource');
        await _alertPlayers[timerId]!.play(AssetSource(soundResource));
      } else {
        // Если звук не найден, воспроизводим звук по умолчанию
        debugPrint('Звук не найден, воспроизведение звука по умолчанию');
        await _alertPlayers[timerId]!.play(AssetSource(alertSoundResources['default_alert.mp3']!));
      }
    } catch (e) {
      debugPrint('Ошибка при воспроизведении звука: $e');
      _isPlayingAlert[timerId] = false;
    }
  }

  // Остановка звука оповещения
  void _stopAlertSound(String timerId) {
    if (_alertPlayers.containsKey(timerId)) {
      _alertPlayers[timerId]!.stop();
      _alertPlayers[timerId]!.dispose();
      _alertPlayers.remove(timerId);
    }
    _isPlayingAlert[timerId] = false;
  }

  // Метод для предварительного прослушивания звука
  Future<void> previewSound(String soundFile) async {
    final previewPlayer = AudioPlayer();
    try {
      final soundResource = alertSoundResources[soundFile];
      if (soundResource != null) {
        await previewPlayer.play(AssetSource(soundResource));
      }
    } catch (e) {
      debugPrint('Ошибка при предварительном воспроизведении: $e');
    } finally {
      // Освобождаем ресурсы после воспроизведения
      Timer(Duration(milliseconds: _maxAlertDuration), () {
        previewPlayer.stop();
        previewPlayer.dispose();
      });
    }
  }

  // Остановка таймера
  void stopTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    // Останавливаем звук оповещения, если он воспроизводится
    _stopAlertSound(id);

    // Если таймер был запущен, сохраняем оставшееся время
    if (_timers[index].isRunning && _timers[index].startTime != null) {
      final elapsed = DateTime.now().difference(_timers[index].startTime!);
      final remainingTimeInSeconds = _timers[index].remainingTime.inSeconds - elapsed.inSeconds;
      final newRemainingTime = Duration(seconds: remainingTimeInSeconds > 0 ? remainingTimeInSeconds : 0);

      _timers[index] = _timers[index].copyWith(
        isRunning: false,
        remainingTime: newRemainingTime,
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

    // Останавливаем звук оповещения, если он воспроизводится
    _stopAlertSound(id);

    // Останавливаем таймер если он запущен
    if (_timers[index].isRunning) {
      if (index < _runningTimers.length) {
        _runningTimers[index].cancel();
        _runningTimers.removeAt(index);
      }
    }

    // Сбрасываем все значения - ставим на ноль!
    _timers[index] = _timers[index].copyWith(
      isRunning: false,
      duration: Duration.zero, // Сбрасываем длительность на ноль
      remainingTime: Duration.zero, // Сбрасываем оставшееся время на ноль
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

    // Если таймер не запущен
    if (!timer.isRunning || timer.startTime == null) {
      return timer.remainingTime;
    }

    // Если таймер запущен
    final elapsed = DateTime.now().difference(timer.startTime!);

    // Для обратного отсчета вычитаем прошедшее время
    final remainingTimeInSeconds = timer.remainingTime.inSeconds - elapsed.inSeconds;
    return Duration(seconds: remainingTimeInSeconds > 0 ? remainingTimeInSeconds : 0);
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
        try {
          final Map<String, dynamic> timerMap = jsonDecode(timerJson);
          _timers.add(FishingTimerModel.fromJson(timerMap));
        } catch (e) {
          debugPrint('Ошибка при загрузке таймера: $e');
        }
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

    // Останавливаем и освобождаем все звуковые ресурсы
    for (var player in _alertPlayers.values) {
      player.stop();
      player.dispose();
    }
    _alertPlayers.clear();

    _timerStreamController.close();
  }

  // Установка длительности таймера
  void setTimerDuration(String id, Duration duration) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index == -1) return;

    _timers[index] = _timers[index].copyWith(
      duration: duration,
      remainingTime: duration, // Устанавливаем оставшееся время равным общей длительности
    );

    // Сохраняем состояние
    _saveTimers();
    _notifyListeners();
  }
}