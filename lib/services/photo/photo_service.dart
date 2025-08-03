// Путь: lib/services/photo/photo_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/firebase_service.dart';
import '../../utils/network_utils.dart';
import '../../localization/app_localizations.dart';

class PhotoService {
  static PhotoService? _instance;

  factory PhotoService() {
    _instance ??= PhotoService._internal();
    return _instance!;
  }

  PhotoService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Кэш локальных фото
  static final Map<String, File> _localPhotoCache = {};

  // Контекст для локализации (устанавливается при первом использовании)
  BuildContext? _context;

  // Установка контекста для локализации
  void setContext(BuildContext context) {
    _context = context;
  }

  // Получение локализованной строки
  String _tr(String key, [Map<String, String>? args]) {
    if (_context == null) {
      // Возвращаем ключ, если контекст не установлен
      return key;
    }

    try {
      String translation = AppLocalizations.of(_context!).translate(key);

      // Замена плейсхолдеров если есть аргументы
      if (args != null) {
        args.forEach((placeholder, value) {
          translation = translation.replaceAll('{$placeholder}', value);
        });
      }

      return translation;
    } catch (e) {
      // Если ошибка локализации, возвращаем ключ
      return key;
    }
  }

  /// Умное сжатие фото с адаптивными настройками
  Future<Uint8List> compressPhotoSmart(Uint8List originalBytes) async {
    try {
      final originalSize = originalBytes.length;

      // Если файл уже маленький - минимальное сжатие
      if (originalSize < 1024 * 1024) { // < 1MB
        return await _lightCompress(originalBytes);
      }

      // Адаптивные настройки в зависимости от размера
      int quality = 85; // Высокое качество по умолчанию
      int maxWidth = 1920;
      int maxHeight = 1080;

      if (originalSize > 10 * 1024 * 1024) { // > 10MB
        quality = 75;
        maxWidth = 1280;
        maxHeight = 720;
      } else if (originalSize > 5 * 1024 * 1024) { // > 5MB
        quality = 80;
        maxWidth = 1600;
        maxHeight = 900;
      }

      debugPrint(_tr('photo_service.compress_start', {
        'originalSize': (originalSize / 1024 / 1024).toStringAsFixed(1),
        'quality': quality.toString(),
        'width': maxWidth.toString(),
        'height': maxHeight.toString()
      }));

      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        rotate: 0,
        autoCorrectionAngle: true,
        format: CompressFormat.jpeg,
      );

      // Проверяем что сжатие было эффективным
      if (compressedBytes.length > originalSize) {
        debugPrint(_tr('photo_service.compress_ineffective'));
        return originalBytes;
      }

      final compressedSize = compressedBytes.length;
      debugPrint(_tr('photo_service.compress_complete', {
        'compressedSize': (compressedSize / 1024 / 1024).toStringAsFixed(1),
        'savings': ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)
      }));

      return compressedBytes;
    } catch (e) {
      debugPrint(_tr('photo_service.compress_error', {'error': e.toString()}));
      return originalBytes;
    }
  }

  /// Легкое сжатие для небольших файлов
  Future<Uint8List> _lightCompress(Uint8List originalBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 90, // Высокое качество для маленьких файлов
        rotate: 0,
        autoCorrectionAngle: true,
        format: CompressFormat.jpeg,
      );

      return compressedBytes.length < originalBytes.length
          ? compressedBytes
          : originalBytes;
    } catch (e) {
      return originalBytes;
    }
  }

  /// Создание постоянного файла фото
  Future<File> savePermanentPhoto(Uint8List bytes) async {
    try {
      // Создаем папку для фото в постоянном хранилище
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/fishing_photos');

      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Создаем уникальное имя файла
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_${timestamp}_${const Uuid().v4().substring(0, 8)}.jpg';
      final filePath = '${photosDir.path}/$fileName';

      // Сохраняем файл
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Проверяем что файл создался
      if (await file.exists()) {
        debugPrint(_tr('photo_service.save_success', {
          'filePath': filePath,
          'size': (bytes.length / 1024).toStringAsFixed(1)
        }));
        return file;
      } else {
        throw Exception(_tr('photo_service.file_creation_failed'));
      }
    } catch (e) {
      throw Exception(_tr('photo_service.permanent_file_error', {'error': e.toString()}));
    }
  }

  /// Основной метод: обработка и сохранение фото
  Future<File> processAndSavePhoto(XFile pickedFile) async {
    try {
      // Читаем исходный файл
      final originalBytes = await pickedFile.readAsBytes();

      // Умное сжатие
      final compressedBytes = await compressPhotoSmart(originalBytes);

      // Сохраняем в постоянное место
      final permanentFile = await savePermanentPhoto(compressedBytes);

      // Добавляем в кэш
      _localPhotoCache[permanentFile.path] = permanentFile;

      return permanentFile;
    } catch (e) {
      throw Exception(_tr('photo_service.process_error', {'error': e.toString()}));
    }
  }

  /// Загрузка фото в Firebase Storage
  Future<List<String>> uploadPhotosToFirebase(
      List<File> photos,
      String noteId,
      ) async {
    final urls = <String>[];

    if (photos.isEmpty) return urls;

    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception(_tr('photo_service.user_not_authorized'));
      }

      debugPrint(_tr('photo_service.upload_start', {'count': photos.length.toString()}));

      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        try {
          final bytes = await photo.readAsBytes();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${timestamp}_${i}_${const Uuid().v4().substring(0, 8)}.jpg';
          final path = 'users/$userId/fishing_notes/$noteId/photos/$fileName';

          final url = await _firebaseService.uploadImage(path, bytes);
          urls.add(url);

          debugPrint(_tr('photo_service.upload_photo_success', {
            'current': (i + 1).toString(),
            'total': photos.length.toString(),
            'size': (bytes.length / 1024).toStringAsFixed(1)
          }));
        } catch (e) {
          debugPrint(_tr('photo_service.upload_photo_error', {
            'index': (i + 1).toString(),
            'error': e.toString()
          }));
          // Продолжаем загрузку остальных фото
        }
      }

      debugPrint(_tr('photo_service.upload_complete', {
        'uploaded': urls.length.toString(),
        'total': photos.length.toString()
      }));
      return urls;
    } catch (e) {
      debugPrint(_tr('photo_service.upload_critical_error', {'error': e.toString()}));
      return urls;
    }
  }

  /// ✅ ИСПРАВЛЕННЫЙ МЕТОД: Удаление фото из Firebase Storage
  Future<void> deletePhotosFromFirebase(List<String> photoUrls) async {
    try {
      final firebaseUrls = photoUrls.where((url) => url.startsWith('http')).toList();

      if (firebaseUrls.isEmpty) {
        debugPrint(_tr('photo_service.no_firebase_urls_to_delete'));
        return;
      }

      debugPrint(_tr('photo_service.delete_firebase_start', {'count': firebaseUrls.length.toString()}));

      for (final url in firebaseUrls) {
        try {
          // Новый метод извлечения пути из Firebase Storage URL
          String? filePath = _extractFilePathFromFirebaseUrl(url);

          if (filePath != null) {
            // Удаляем файл из Storage
            final ref = FirebaseStorage.instance.ref(filePath);
            await ref.delete();

            debugPrint(_tr('photo_service.delete_firebase_file_success', {'filePath': filePath}));
          } else {
            debugPrint(_tr('photo_service.invalid_url_format', {'url': url}));
          }
        } catch (e) {
          debugPrint(_tr('photo_service.delete_firebase_file_error', {
            'url': url,
            'error': e.toString()
          }));
          // Продолжаем удаление остальных фото
        }
      }

      debugPrint(_tr('photo_service.delete_firebase_complete'));
    } catch (e) {
      debugPrint(_tr('photo_service.delete_firebase_critical_error', {'error': e.toString()}));
      rethrow;
    }
  }

  /// Извлечение пути файла из Firebase Storage URL
  String? _extractFilePathFromFirebaseUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Проверяем, что это Firebase Storage URL
      if (!uri.host.contains('firebasestorage') && !uri.host.contains('googleapis.com')) {
        return null;
      }

      // Для новых URL вида: https://firebasestorage.googleapis.com/v0/b/{bucket}.firebasestorage.app/o/{path}
      if (uri.pathSegments.contains('o') && uri.pathSegments.length >= 4) {
        final oIndex = uri.pathSegments.indexOf('o');
        if (oIndex != -1 && oIndex < uri.pathSegments.length - 1) {
          // Берем все сегменты после '/o/' и декодируем
          final pathSegments = uri.pathSegments.skip(oIndex + 1).toList();
          final encodedPath = pathSegments.join('/');

          // Убираем query параметры если они есть в последнем сегменте
          final cleanPath = encodedPath.split('?').first;

          // Декодируем URL-encoded путь
          final decodedPath = Uri.decodeComponent(cleanPath);

          debugPrint('🔍 Извлечен путь из URL: $decodedPath');
          return decodedPath;
        }
      }

      // Для старых URL вида: https://storage.googleapis.com/{bucket}/{path}
      if (uri.pathSegments.isNotEmpty) {
        // Убираем первый сегмент (bucket) и берем остальное как путь
        if (uri.pathSegments.length > 1) {
          final pathSegments = uri.pathSegments.skip(1).toList();
          final path = pathSegments.join('/');
          debugPrint('🔍 Извлечен путь из старого URL: $path');
          return path;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Ошибка парсинга URL: $e');
      return null;
    }
  }

  /// ✅ НОВЫЙ МЕТОД: Удаление локальных файлов фото
  Future<void> deleteLocalPhotos(List<String> photoUrls) async {
    try {
      final localPaths = photoUrls.where((url) => !url.startsWith('http')).toList();

      if (localPaths.isEmpty) {
        debugPrint(_tr('photo_service.no_local_files_to_delete'));
        return;
      }

      debugPrint(_tr('photo_service.delete_local_start', {'count': localPaths.length.toString()}));

      for (final path in localPaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            debugPrint(_tr('photo_service.delete_local_file_success', {'path': path}));
          } else {
            debugPrint(_tr('photo_service.file_not_exists', {'path': path}));
          }
        } catch (e) {
          debugPrint(_tr('photo_service.delete_local_file_error', {
            'path': path,
            'error': e.toString()
          }));
          // Продолжаем удаление остальных файлов
        }
      }

      debugPrint(_tr('photo_service.delete_local_complete'));
    } catch (e) {
      debugPrint(_tr('photo_service.delete_local_critical_error', {'error': e.toString()}));
      rethrow;
    }
  }

  /// Загрузка одного фото в Firebase Storage
  Future<String?> uploadSinglePhotoToFirebase(
      File photo,
      String noteId,
      int index,
      ) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception(_tr('photo_service.user_not_authorized'));
      }

      final bytes = await photo.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${index}_${const Uuid().v4().substring(0, 8)}.jpg';
      final path = 'users/$userId/fishing_notes/$noteId/photos/$fileName';

      final url = await _firebaseService.uploadImage(path, bytes);
      debugPrint(_tr('photo_service.single_upload_success', {'url': url}));

      return url;
    } catch (e) {
      debugPrint(_tr('photo_service.single_upload_error', {'error': e.toString()}));
      return null;
    }
  }

  /// Гибридное сохранение: онлайн + офлайн
  Future<List<String>> savePhotosHybrid(
      List<File> photos,
      String noteId,
      ) async {
    final urls = <String>[];

    if (photos.isEmpty) return urls;

    final isOnline = await NetworkUtils.isNetworkAvailable();

    if (isOnline) {
      // Онлайн: загружаем в Firebase Storage
      final firebaseUrls = await uploadPhotosToFirebase(photos, noteId);
      urls.addAll(firebaseUrls);
    } else {
      // Офлайн: сохраняем локальные пути
      debugPrint(_tr('photo_service.offline_mode'));
      urls.addAll(photos.map((file) => file.path));
    }

    return urls;
  }

  /// Получение фото из кэша или создание
  Future<File?> getCachedPhoto(String path) async {
    if (_localPhotoCache.containsKey(path)) {
      final cachedFile = _localPhotoCache[path]!;
      if (await cachedFile.exists()) {
        return cachedFile;
      } else {
        _localPhotoCache.remove(path);
      }
    }

    final file = File(path);
    if (await file.exists()) {
      _localPhotoCache[path] = file;
      return file;
    }

    return null;
  }

  /// ✅ ОБНОВЛЕННЫЙ МЕТОД: Очистка старых временных файлов
  Future<void> cleanupOldTempFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final tempDir = Directory(directory.path);

      if (!await tempDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final files = tempDir.listSync(recursive: true);

      int deletedCount = 0;

      for (final entity in files) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);

            // Удаляем файлы старше 24 часов
            if (age.inHours > 24) {
              await entity.delete();
              deletedCount++;
            }
          } catch (e) {
            // Игнорируем ошибки отдельных файлов
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint(_tr('photo_service.cleanup_complete', {'count': deletedCount.toString()}));
      }
    } catch (e) {
      debugPrint(_tr('photo_service.cleanup_error', {'error': e.toString()}));
      // Не критично, продолжаем работу
    }
  }

  /// Получение информации о размере папки с фото
  Future<Map<String, dynamic>> getPhotosStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/fishing_photos');

      if (!await photosDir.exists()) {
        return {
          'totalFiles': 0,
          'totalSizeBytes': 0,
          'totalSizeMB': 0.0,
        };
      }

      final files = photosDir.listSync(recursive: true)
          .where((entity) => entity is File)
          .cast<File>();

      int totalSize = 0;
      int totalFiles = 0;

      for (final file in files) {
        try {
          totalSize += await file.length();
          totalFiles++;
        } catch (e) {
          // Игнорируем ошибки чтения отдельных файлов
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
      };
    } catch (e) {
      debugPrint(_tr('photo_service.storage_info_error', {'error': e.toString()}));
      return {
        'totalFiles': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Очистка кэша фото
  void clearPhotoCache() {
    _localPhotoCache.clear();
    debugPrint(_tr('photo_service.cache_cleared'));
  }
}