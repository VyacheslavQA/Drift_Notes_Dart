// Путь: lib/services/sound/direct_audio_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DirectAudioService {
  static final DirectAudioService _instance = DirectAudioService._internal();

  factory DirectAudioService() {
    return _instance;
  }

  DirectAudioService._internal();

  final Map<String, AudioPlayer> _activePlayers = {};
  final Map<String, String> _tempFilePaths = {};
  bool _initialized = false;

  // Звуки и их пути
  final Map<String, String> _soundAssetPaths = {
    'default_alert.mp3': 'assets/sounds/default_alert.mp3',
    'fish_splash.mp3': 'assets/sounds/fish_splash.mp3',
    'bell.mp3': 'assets/sounds/bell.mp3',
    'alarm.mp3': 'assets/sounds/alarm.mp3',
  };

  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🎵 Инициализация DirectAudioService...');

    try {
      // Проверяем наличие и копируем звуки во временную директорию
      await _prepareAudioFiles();
      _initialized = true;
      debugPrint('✅ DirectAudioService успешно инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка при инициализации DirectAudioService: $e');
    }
  }

  // Подготовка аудиофайлов (копирование их во временную директорию)
  Future<void> _prepareAudioFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();

      for (final entry in _soundAssetPaths.entries) {
        final soundName = entry.key;
        final assetPath = entry.value;

        try {
          // Загружаем данные из ресурсов
          final ByteData data = await rootBundle.load(assetPath);
          final List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );

          // Создаем временный файл
          final tempFile = File('${tempDir.path}/$soundName');
          await tempFile.writeAsBytes(bytes);

          // Сохраняем путь к временному файлу
          _tempFilePaths[soundName] = tempFile.path;

          debugPrint(
            '✅ Звук $soundName скопирован во временную директорию: ${tempFile.path}',
          );
        } catch (e) {
          debugPrint('❌ Ошибка при копировании звука $soundName: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при подготовке аудиофайлов: $e');
    }
  }

  // Воспроизведение звука напрямую из временного файла
  Future<bool> playSound(String soundName) async {
    if (!_initialized) {
      await initialize();
    }

    // Генерируем уникальный ключ для этого воспроизведения
    final playerId = '${soundName}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Проверяем, есть ли звук во временной директории
      if (!_tempFilePaths.containsKey(soundName)) {
        debugPrint('❌ Звук $soundName не найден во временной директории');
        return false;
      }

      final filePath = _tempFilePaths[soundName]!;
      final player = AudioPlayer();
      _activePlayers[playerId] = player;

      debugPrint('🎵 Воспроизведение звука $soundName из файла $filePath');

      // Используем DeviceFileSource для воспроизведения из файловой системы
      final source = DeviceFileSource(filePath);
      await player.play(source);

      debugPrint('✅ Звук $soundName запущен с ID $playerId');

      // Настраиваем автоматическое очищение плеера после воспроизведения
      player.onPlayerComplete.listen((event) {
        _cleanupPlayer(playerId);
      });

      // Дополнительный таймер для очистки плеера (если что-то пойдет не так)
      Timer(Duration(seconds: 5), () {
        _cleanupPlayer(playerId);
      });

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при воспроизведении звука $soundName: $e');
      _cleanupPlayer(playerId);

      // Пробуем альтернативный метод
      return _playWithAlternativeMethod(soundName);
    }
  }

  // Альтернативный метод воспроизведения
  Future<bool> _playWithAlternativeMethod(String soundName) async {
    try {
      debugPrint('🎵 Попытка альтернативного воспроизведения звука $soundName');

      final playerId =
          'alt_${soundName}_${DateTime.now().millisecondsSinceEpoch}';
      final player = AudioPlayer();
      _activePlayers[playerId] = player;

      // Путь к ресурсу
      final assetPath = _soundAssetPaths[soundName];
      if (assetPath == null) {
        debugPrint('❌ Путь к ресурсу не найден для звука $soundName');
        return false;
      }

      // Пробуем воспроизвести напрямую из ресурсов
      final source = AssetSource(assetPath.replaceFirst('assets/', ''));
      await player.play(source);

      debugPrint(
        '✅ Звук $soundName запущен альтернативным методом с ID $playerId',
      );

      // Настраиваем автоматическое очищение плеера после воспроизведения
      player.onPlayerComplete.listen((event) {
        _cleanupPlayer(playerId);
      });

      Timer(Duration(seconds: 5), () {
        _cleanupPlayer(playerId);
      });

      return true;
    } catch (e) {
      debugPrint(
        '❌ Ошибка при альтернативном воспроизведении звука $soundName: $e',
      );
      return false;
    }
  }

  // Очистка плеера после использования
  void _cleanupPlayer(String playerId) {
    try {
      if (_activePlayers.containsKey(playerId)) {
        final player = _activePlayers[playerId]!;
        player.stop();
        player.dispose();
        _activePlayers.remove(playerId);
        debugPrint('🧹 Плеер $playerId очищен');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при очистке плеера $playerId: $e');
    }
  }

  // Остановить все плееры
  void stopAllSounds() {
    for (final playerId in _activePlayers.keys.toList()) {
      _cleanupPlayer(playerId);
    }
    debugPrint('🔇 Все звуки остановлены');
  }

  // Проверка доступности звука
  bool isSoundAvailable(String soundName) {
    return _soundAssetPaths.containsKey(soundName) ||
        _tempFilePaths.containsKey(soundName);
  }

  // Тест звука (воспроизведение и информация о результате)
  Future<Map<String, dynamic>> testSound(String soundName) async {
    if (!_initialized) {
      await initialize();
    }

    final result = {
      'sound': soundName,
      'assetPath': _soundAssetPaths[soundName],
      'tempFilePath': _tempFilePaths[soundName],
      'assetExists': false,
      'tempFileExists': false,
      'playAttempt': false,
      'playSuccess': false,
      'error': null,
    };

    try {
      // Проверка существования ресурса
      if (_soundAssetPaths.containsKey(soundName)) {
        try {
          await rootBundle.load(_soundAssetPaths[soundName]!);
          result['assetExists'] = true;
        } catch (e) {
          result['error'] = 'Ресурс не найден: $e';
        }
      }

      // Проверка существования временного файла
      if (_tempFilePaths.containsKey(soundName)) {
        final file = File(_tempFilePaths[soundName]!);
        result['tempFileExists'] = await file.exists();
      }

      // Попытка воспроизведения
      result['playAttempt'] = true;
      result['playSuccess'] = await playSound(soundName);
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  // Освобождение ресурсов
  void dispose() {
    stopAllSounds();
    _initialized = false;
    debugPrint('🎵 DirectAudioService освобожден');
  }
}
