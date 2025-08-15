// Путь: lib/services/local/local_file_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../photo/photo_service.dart';

class LocalFileService {
  static LocalFileService? _instance;

  factory LocalFileService() {
    _instance ??= LocalFileService._internal();
    return _instance!;
  }

  LocalFileService._internal();

  final PhotoService _photoService = PhotoService();

  /// Сохранение локальных копий фото с улучшенной обработкой
  Future<List<String>> saveLocalCopies(List<File> photos) async {
    final localPaths = <String>[];

    if (photos.isEmpty) {
      debugPrint('📱 Нет фото для локального сохранения');
      return localPaths;
    }

    try {
      debugPrint('📱 Сохраняем ${photos.length} фото локально...');

      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        try {
          // Проверяем существует ли файл
          if (!await photo.exists()) {
            debugPrint('❌ Файл не существует: ${photo.path}');
            continue;
          }

          // Читаем и сжимаем фото через PhotoService
          final originalBytes = await photo.readAsBytes();
          final compressedBytes = await _photoService.compressPhotoSmart(originalBytes);

          // Сохраняем сжатую версию
          final localFile = await _photoService.savePermanentPhoto(compressedBytes);
          localPaths.add(localFile.path);

          debugPrint('✅ Локально сохранено фото ${i + 1}/${photos.length}: ${localFile.path}');
        } catch (e) {
          debugPrint('❌ Ошибка сохранения фото ${i + 1}: $e');

          // Fallback: пытаемся скопировать оригинал без сжатия
          try {
            final fallbackFile = await _copyOriginalFile(photo);
            if (fallbackFile != null) {
              localPaths.add(fallbackFile.path);
              debugPrint('⚠️ Сохранен оригинал без сжатия: ${fallbackFile.path}');
            }
          } catch (fallbackError) {
            debugPrint('❌ Fallback тоже не сработал: $fallbackError');
          }
        }
      }

      debugPrint('📱 Локальное сохранение завершено: ${localPaths.length}/${photos.length} фото');
      return localPaths;
    } catch (e) {
      debugPrint('❌ Критическая ошибка локального сохранения: $e');
      return localPaths;
    }
  }

  /// Резервное копирование оригинального файла
  Future<File?> _copyOriginalFile(File originalFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/fishing_photos/backup');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_$timestamp.jpg';
      final backupPath = '${backupDir.path}/$fileName';

      final backupFile = await originalFile.copy(backupPath);
      return backupFile;
    } catch (e) {
      debugPrint('❌ Ошибка резервного копирования: $e');
      return null;
    }
  }

  /// Сохранение одного локального файла
  Future<String?> saveLocalFile(File photo) async {
    try {
      if (!await photo.exists()) {
        debugPrint('❌ Файл не существует: ${photo.path}');
        return null;
      }

      final originalBytes = await photo.readAsBytes();
      final compressedBytes = await _photoService.compressPhotoSmart(originalBytes);
      final localFile = await _photoService.savePermanentPhoto(compressedBytes);

      debugPrint('✅ Локально сохранен файл: ${localFile.path}');
      return localFile.path;
    } catch (e) {
      debugPrint('❌ Ошибка сохранения локального файла: $e');
      return null;
    }
  }

  /// Создание локальной копии с обработкой
  Future<File?> createLocalCopy(File sourceFile, {bool compress = true}) async {
    try {
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не существует: ${sourceFile.path}');
      }

      final sourceBytes = await sourceFile.readAsBytes();

      if (compress) {
        // Сжимаем через PhotoService
        final compressedBytes = await _photoService.compressPhotoSmart(sourceBytes);
        return await _photoService.savePermanentPhoto(compressedBytes);
      } else {
        // Копируем без сжатия
        return await _photoService.savePermanentPhoto(sourceBytes);
      }
    } catch (e) {
      debugPrint('❌ Ошибка создания локальной копии: $e');
      return null;
    }
  }

  /// Получение информации о локальном хранилище
  Future<Map<String, dynamic>> getLocalStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fishingPhotosDir = Directory('${appDir.path}/fishing_photos');

      if (!await fishingPhotosDir.exists()) {
        return {
          'totalFiles': 0,
          'totalSizeBytes': 0,
          'totalSizeMB': 0.0,
          'directories': <String>[],
        };
      }

      final allFiles = <File>[];
      final directories = <String>[];

      await for (final entity in fishingPhotosDir.list(recursive: true)) {
        if (entity is File) {
          allFiles.add(entity);
        } else if (entity is Directory) {
          directories.add(entity.path);
        }
      }

      int totalSize = 0;
      final validFiles = <File>[];

      for (final file in allFiles) {
        try {
          final size = await file.length();
          totalSize += size;
          validFiles.add(file);
        } catch (e) {
          debugPrint('⚠️ Не удалось получить размер файла: ${file.path}');
        }
      }

      return {
        'totalFiles': validFiles.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'directories': directories,
        'validFiles': validFiles.length,
        'invalidFiles': allFiles.length - validFiles.length,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о локальном хранилище: $e');
      return {
        'totalFiles': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Очистка старых локальных файлов
  Future<int> cleanupOldLocalFiles({int maxAgeInDays = 30}) async {
    int deletedCount = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fishingPhotosDir = Directory('${appDir.path}/fishing_photos');

      if (!await fishingPhotosDir.exists()) {
        debugPrint('📁 Папка fishing_photos не существует');
        return 0;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: maxAgeInDays));

      await for (final entity in fishingPhotosDir.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();

            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
              deletedCount++;
              debugPrint('🗑️ Удален старый файл: ${entity.path}');
            }
          } catch (e) {
            debugPrint('❌ Ошибка удаления файла ${entity.path}: $e');
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('🧹 Очистка завершена: удалено $deletedCount старых файлов');
      } else {
        debugPrint('✅ Нет старых файлов для удаления');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых локальных файлов: $e');
      return deletedCount;
    }
  }

  /// Проверка валидности локальных файлов
  Future<Map<String, dynamic>> validateLocalFiles() async {
    final report = {
      'totalChecked': 0,
      'validFiles': 0,
      'invalidFiles': 0,
      'corruptedFiles': <String>[],
      'missingFiles': <String>[],
      'totalSizeBytes': 0,
    };

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fishingPhotosDir = Directory('${appDir.path}/fishing_photos');

      if (!await fishingPhotosDir.exists()) {
        return report;
      }

      await for (final entity in fishingPhotosDir.list(recursive: true)) {
        if (entity is File) {
          report['totalChecked'] = (report['totalChecked'] as int) + 1;

          try {
            // Проверяем существование
            if (!await entity.exists()) {
              (report['missingFiles'] as List<String>).add(entity.path);
              report['invalidFiles'] = (report['invalidFiles'] as int) + 1;
              continue;
            }

            // Проверяем размер
            final size = await entity.length();
            if (size == 0) {
              (report['corruptedFiles'] as List<String>).add(entity.path);
              report['invalidFiles'] = (report['invalidFiles'] as int) + 1;
              continue;
            }

            // Пытаемся прочитать первые байты
            final bytes = await entity.openRead(0, 10).first;
            if (bytes.isEmpty) {
              (report['corruptedFiles'] as List<String>).add(entity.path);
              report['invalidFiles'] = (report['invalidFiles'] as int) + 1;
              continue;
            }

            report['validFiles'] = (report['validFiles'] as int) + 1;
            report['totalSizeBytes'] = (report['totalSizeBytes'] as int) + size;
          } catch (e) {
            (report['corruptedFiles'] as List<String>).add(entity.path);
            report['invalidFiles'] = (report['invalidFiles'] as int) + 1;
          }
        }
      }

      debugPrint('🔍 Валидация завершена: ${report['validFiles']}/${report['totalChecked']} файлов валидны');
      return report;
    } catch (e) {
      debugPrint('❌ Ошибка валидации локальных файлов: $e');
      report['error'] = e.toString();
      return report;
    }
  }

  /// Получение списка всех локальных фото
  Future<List<File>> getAllLocalPhotos() async {
    final localPhotos = <File>[];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fishingPhotosDir = Directory('${appDir.path}/fishing_photos');

      if (!await fishingPhotosDir.exists()) {
        return localPhotos;
      }

      await for (final entity in fishingPhotosDir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
          if (await entity.exists()) {
            localPhotos.add(entity);
          }
        }
      }

      debugPrint('📱 Найдено ${localPhotos.length} локальных фото');
      return localPhotos;
    } catch (e) {
      debugPrint('❌ Ошибка получения списка локальных фото: $e');
      return localPhotos;
    }
  }

  /// Удаление конкретного локального файла
  Future<bool> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('⚠️ Файл уже не существует: $filePath');
        return true;
      }

      await file.delete();
      debugPrint('🗑️ Удален локальный файл: $filePath');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка удаления локального файла $filePath: $e');
      return false;
    }
  }

  /// Создание резервной копии важных локальных файлов
  Future<List<String>> createBackup(List<String> filePaths) async {
    final backupPaths = <String>[];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/fishing_photos/backup/${DateTime.now().millisecondsSinceEpoch}');

      await backupDir.create(recursive: true);

      for (final filePath in filePaths) {
        try {
          final sourceFile = File(filePath);
          if (!await sourceFile.exists()) continue;

          final fileName = filePath.split('/').last;
          final backupPath = '${backupDir.path}/$fileName';

          await sourceFile.copy(backupPath);
          backupPaths.add(backupPath);

          debugPrint('💾 Создана резервная копия: $backupPath');
        } catch (e) {
          debugPrint('❌ Ошибка создания резервной копии для $filePath: $e');
        }
      }

      debugPrint('💾 Резервное копирование завершено: ${backupPaths.length}/${filePaths.length} файлов');
      return backupPaths;
    } catch (e) {
      debugPrint('❌ Ошибка резервного копирования: $e');
      return backupPaths;
    }
  }
}