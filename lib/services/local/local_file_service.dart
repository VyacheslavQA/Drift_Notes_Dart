// Путь: lib/services/local/local_file_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

/// Сервис для управления локальными файлами (фотографиями, и т.д.)
class LocalFileService {
  static final LocalFileService _instance = LocalFileService._internal();

  factory LocalFileService() {
    return _instance;
  }

  LocalFileService._internal();

  // Базовая директория для хранения файлов
  Directory? _cacheDirectory;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_cacheDirectory != null) return;

    try {
      // Получаем директорию для временных файлов
      final appTempDir = await getTemporaryDirectory();
      final driftNotesDir = Directory('${appTempDir.path}/drift_notes_files');

      // Создаем директорию, если она не существует
      if (!await driftNotesDir.exists()) {
        await driftNotesDir.create(recursive: true);
      }

      _cacheDirectory = driftNotesDir;
      debugPrint('📁 LocalFileService инициализирован: ${driftNotesDir.path}');
    } catch (e) {
      debugPrint('❌ Ошибка при инициализации LocalFileService: $e');
      rethrow;
    }
  }

  /// Копирует файл во временную директорию приложения и возвращает локальный URI
  Future<String> saveLocalCopy(File sourceFile) async {
    await initialize();

    try {
      // Генерируем уникальное имя файла, сохраняя оригинальное расширение
      final fileExtension = path.extension(sourceFile.path).toLowerCase();
      final uuid = const Uuid().v4();
      final newFileName = '$uuid$fileExtension';

      // Создаем путь к новому файлу
      final localPath = '${_cacheDirectory!.path}/$newFileName';

      // Копируем файл
      final localFile = await sourceFile.copy(localPath);
      debugPrint('📷 Создана локальная копия файла: $localPath');

      // Возвращаем локальный URI
      return 'file://${localFile.path}';
    } catch (e) {
      debugPrint('❌ Ошибка при создании локальной копии файла: $e');
      rethrow;
    }
  }

  /// Возвращает список локальных URI для нескольких исходных файлов
  Future<List<String>> saveLocalCopies(List<File> sourceFiles) async {
    final List<String> localUris = [];

    for (final file in sourceFiles) {
      try {
        final localUri = await saveLocalCopy(file);
        localUris.add(localUri);
      } catch (e) {
        debugPrint('⚠️ Не удалось сохранить копию файла ${file.path}: $e');
        // Пропускаем проблемный файл, но продолжаем обработку остальных
      }
    }

    return localUris;
  }

  /// Проверяет, существует ли локальный файл
  Future<bool> localFileExists(String localUri) async {
    if (!localUri.startsWith('file://')) return false;

    final filePath = localUri.substring(7); // удаляем 'file://'
    return File(filePath).exists();
  }

  /// Удаляет локальный файл по URI
  Future<void> deleteLocalFile(String localUri) async {
    if (!localUri.startsWith('file://')) return;

    try {
      final filePath = localUri.substring(7); // удаляем 'file://'
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Удален локальный файл: $filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при удалении локального файла: $e');
    }
  }

  /// Конвертирует локальный URI в объект File
  File? localUriToFile(String localUri) {
    if (!localUri.startsWith('file://')) return null;

    try {
      final filePath = localUri.substring(7); // удаляем 'file://'
      return File(filePath);
    } catch (e) {
      debugPrint('⚠️ Ошибка при конвертации URI в File: $e');
      return null;
    }
  }

  /// Очищает временный кэш файлов
  Future<void> clearCache() async {
    await initialize();

    try {
      final allFiles = await _cacheDirectory!.list().toList();

      for (var entity in allFiles) {
        if (entity is File) {
          await entity.delete();
          debugPrint('🗑️ Удален кэшированный файл: ${entity.path}');
        }
      }

      debugPrint('✅ Кэш файлов очищен');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке кэша файлов: $e');
    }
  }

  /// Проверяет, является ли URL локальным файлом
  bool isLocalFileUri(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('file://');
  }

  /// Получает размер кэша в байтах
  Future<int> getCacheSize() async {
    await initialize();

    try {
      int totalSize = 0;
      final allFiles = await _cacheDirectory!.list().toList();

      for (var entity in allFiles) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Ошибка при получении размера кэша: $e');
      return 0;
    }
  }

  /// Получает путь к кэш-директории
  Future<String> getCacheDirectoryPath() async {
    await initialize();
    return _cacheDirectory!.path;
  }
}