// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_note_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
import '../services/offline/offline_storage_service.dart';
import '../services/offline/sync_service.dart';
import '../services/local/local_file_service.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

class FishingNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalFileService _localFileService = LocalFileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // 🔥 УПРОЩЕНО: Получение заметок без сложных проверок
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ getUserFishingNotes: Пользователь не авторизован');
        return [];
      }

      debugPrint('📝 Загрузка заметок для пользователя: $userId');

      // Всегда получаем офлайн заметки первыми
      final offlineNotes = await _getOfflineNotes(userId);
      debugPrint('📱 Офлайн заметок найдено: ${offlineNotes.length}');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      List<FishingNoteModel> onlineNotes = [];

      if (isOnline) {
        try {
          debugPrint('☁️ Загружаем заметки из Firebase');
          final snapshot = await _firebaseService.getUserFishingNotesNew();

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.isNotEmpty) {
              final note = FishingNoteModel.fromJson(data, id: doc.id);
              onlineNotes.add(note);
            }
          }

          debugPrint('☁️ Заметок из Firebase: ${onlineNotes.length}');
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении заметок из Firebase: $e');
        }
      }

      // Объединяем списки, избегая дубликатов
      final Map<String, FishingNoteModel> uniqueNotes = {};

      // Сначала добавляем онлайн заметки
      for (var note in onlineNotes) {
        uniqueNotes[note.id] = note;
      }

      // Затем добавляем офлайн заметки, которых нет в онлайн списке
      for (var note in offlineNotes) {
        if (!uniqueNotes.containsKey(note.id)) {
          uniqueNotes[note.id] = note;
        }
      }

      // Преобразуем в список и сортируем по дате
      final allNotes = uniqueNotes.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      debugPrint('📊 Итого заметок: ${allNotes.length}');

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        _syncService.syncAll();
      }

      return allNotes;
    } catch (e) {
      debugPrint('❌ Ошибка в getUserFishingNotes: $e');
      // В случае ошибки возвращаем пустой список
      return [];
    }
  }

  // 🔥 УПРОЩЕНО: Получение офлайн заметок
  Future<List<FishingNoteModel>> _getOfflineNotes(String userId) async {
    try {
      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      final List<FishingNoteModel> result = [];

      for (final note in offlineNotes) {
        try {
          final noteId = note['id']?.toString() ?? '';
          final noteUserId = note['userId']?.toString() ?? '';

          if (noteId.isEmpty) continue;

          // Проверяем принадлежность пользователю
          bool belongsToUser = false;

          if (noteUserId.isNotEmpty && noteUserId == userId) {
            belongsToUser = true;
          } else if (noteUserId.isEmpty) {
            // Заметка без userId - добавляем userId
            note['userId'] = userId;
            belongsToUser = true;
            _offlineStorage.saveOfflineNote(note).catchError((error) {
              debugPrint('⚠️ Ошибка при исправлении заметки: $error');
            });
          }

          if (belongsToUser) {
            final noteModel = FishingNoteModel.fromJson(note, id: noteId);
            result.add(noteModel);
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка обработки заметки: $e');
          continue;
        }
      }

      result.sort((a, b) => b.date.compareTo(a.date));
      return result;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  // 🔥 КРИТИЧЕСКИ УПРОЩЕНО: Добавление заметки БЕЗ сложных проверок лимитов
  Future<String> addFishingNote(
      FishingNoteModel note,
      List<File>? photos,
      ) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final noteId = note.id.isEmpty ? const Uuid().v4() : note.id;
      debugPrint('📝 Добавление заметки с ID: $noteId');

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(id: noteId, userId: userId);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // ОНЛАЙН: Загружаем фото и сохраняем в Firebase
        List<String> photoUrls = [];

        if (photos != null && photos.isNotEmpty) {
          debugPrint('🖼️ Загрузка ${photos.length} фото');
          for (var photo in photos) {
            try {
              final bytes = await photo.readAsBytes();
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
              final path = 'users/$userId/photos/$fileName';
              final url = await _firebaseService.uploadImage(path, bytes);
              photoUrls.add(url);
            } catch (e) {
              debugPrint('⚠️ Ошибка при загрузке фото: $e');
            }
          }
        }

        final noteWithPhotos = noteToAdd.copyWith(photoUrls: photoUrls);

        try {
          // ✅ ИСПРАВЛЕНО: Используем правильный метод addFishingNoteNew
          await _firebaseService.addFishingNoteNew(noteWithPhotos.toJson());
          debugPrint('✅ Заметка сохранена в Firebase');

          // Сохраняем копию в офлайн хранилище
          final noteJson = noteWithPhotos.toJson();
          noteJson['id'] = noteId;
          noteJson['isSynced'] = true;
          noteJson['isOffline'] = false;
          await _offlineStorage.saveOfflineNote(noteJson);

          // ✅ УПРОЩЕНО: Увеличиваем счетчик ТОЛЬКО один раз
          try {
            await _firebaseService.incrementUsageCount('notesCount');
            debugPrint('✅ Счетчик увеличен через Firebase');
          } catch (e) {
            debugPrint('⚠️ Ошибка увеличения счетчика: $e');
          }

          return noteId;
        } catch (e) {
          debugPrint('⚠️ Ошибка при сохранении в Firebase: $e');
          // Если ошибка - сохраняем локально
          await _saveOfflineNote(noteWithPhotos, photos);
          return noteId;
        }
      } else {
        // ОФЛАЙН: Создаем локальные копии фото
        List<String> localPhotoUris = [];
        if (photos != null && photos.isNotEmpty) {
          localPhotoUris = await _localFileService.saveLocalCopies(photos);
        }

        final noteWithLocalPhotos = noteToAdd.copyWith(photoUrls: localPhotoUris);
        await _saveOfflineNote(noteWithLocalPhotos, photos);

        return noteId;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // 🔥 УПРОЩЕНО: Сохранение офлайн заметки
  Future<void> _saveOfflineNote(
      FishingNoteModel note,
      List<File>? photos,
      ) async {
    try {
      if (note.id.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('📱 Сохранение офлайн заметки: ${note.id}');

      // Сохраняем заметку
      final noteJson = note.toJson();
      noteJson['id'] = note.id;
      noteJson['isSynced'] = false;
      noteJson['isOffline'] = true;

      await _offlineStorage.saveOfflineNote(noteJson);

      // Сохраняем пути к фотографиям
      if (photos != null && photos.isNotEmpty) {
        final photoPaths = photos.map((file) => file.path).toList();
        await _offlineStorage.saveOfflinePhotoPaths(note.id, photoPaths);
      }

      debugPrint('✅ Заметка сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении офлайн заметки: $e');
      rethrow;
    }
  }

  // 🔥 УПРОЩЕНО: Обновление заметки
  Future<void> updateFishingNote(FishingNoteModel note) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (note.id.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔄 Обновление заметки: ${note.id}');

      // Всегда сначала сохраняем локально
      final noteJson = note.toJson();
      noteJson['id'] = note.id;
      await _offlineStorage.saveOfflineNote(noteJson);

      // Если онлайн - пытаемся обновить в Firebase
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        try {
          await _firebaseService.updateFishingNoteNew(note.id, note.toJson());
          debugPrint('✅ Заметка обновлена в Firebase');
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении в Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки: $e');
      rethrow;
    }
  }

  // 🔥 УПРОЩЕНО: Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔍 Получение заметки по ID: $noteId');

      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .doc(noteId)
              .get();

          if (doc.exists) {
            final note = FishingNoteModel.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            );
            debugPrint('✅ Заметка получена из Firebase');
            return note;
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении из Firebase: $e');
        }
      }

      // Если не нашли онлайн - ищем в офлайн хранилище
      return await _getOfflineNoteById(noteId);
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки: $e');
      rethrow;
    }
  }

  // 🔥 УПРОЩЕНО: Удаление заметки
  Future<void> deleteFishingNote(String noteId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🗑️ Удаление заметки: $noteId');

      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        try {
          // Удаляем из Firebase
          await _firebaseService.deleteFishingNoteNew(noteId);
          debugPrint('✅ Заметка удалена из Firebase');

          // ✅ УПРОЩЕНО: Уменьшаем счетчик ТОЛЬКО один раз
          try {
            await _firebaseService.incrementUsageCount('notesCount', increment: -1);
            debugPrint('✅ Счетчик уменьшен через Firebase');
          } catch (e) {
            debugPrint('⚠️ Ошибка уменьшения счетчика: $e');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении из Firebase: $e');
          // Отмечаем для удаления при появлении соединения
          await _offlineStorage.markForDeletion(noteId, false);
        }
      } else {
        // Офлайн - отмечаем для удаления
        await _offlineStorage.markForDeletion(noteId, false);
      }

      // Удаляем локальную копию
      try {
        await _offlineStorage.removeOfflineNote(noteId);
        debugPrint('✅ Локальная копия удалена');
      } catch (e) {
        debugPrint('⚠️ Ошибка при удалении локальной копии: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки: $e');
      rethrow;
    }
  }

  // 🔥 УПРОЩЕНО: Получение офлайн заметки по ID
  Future<FishingNoteModel> _getOfflineNoteById(String noteId) async {
    try {
      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
      final noteDataList = allOfflineNotes.where((note) => note['id'] == noteId).toList();

      if (noteDataList.isEmpty) {
        throw Exception('Заметка не найдена в офлайн хранилище');
      }

      final noteData = noteDataList.first;
      return FishingNoteModel.fromJson(noteData, id: noteId);
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн заметки: $e');
      rethrow;
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    try {
      await _syncService.syncAll();
    } catch (e) {
      debugPrint('⚠️ Ошибка при синхронизации: $e');
    }
  }

  // Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      return await _syncService.forceSyncAll();
    } catch (e) {
      debugPrint('⚠️ Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  // Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      return await _syncService.getSyncStatus();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Очистка кэша локальных файлов
  Future<void> clearLocalFilesCache() async {
    try {
      await _localFileService.clearCache();
    } catch (e) {
      debugPrint('⚠️ Ошибка при очистке кэша: $e');
      rethrow;
    }
  }

  // Получить размер кэша локальных файлов
  Future<int> getLocalFilesCacheSize() async {
    try {
      return await _localFileService.getCacheSize();
    } catch (e) {
      return 0;
    }
  }
}