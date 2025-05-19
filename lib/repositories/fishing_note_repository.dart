// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/fishing_note_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
import '../services/offline/offline_storage_service.dart';
import '../services/offline/sync_service.dart';

class FishingNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение всех заметок пользователя
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ getUserFishingNotes: Пользователь не авторизован');
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📝 Запрос заметок для пользователя: $userId');

      // Получаем офлайн заметки в любом случае
      final offlineNotes = await _getOfflineNotes(userId);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');
      debugPrint('📱 Офлайн заметок: ${offlineNotes.length}');

      if (isOnline) {
        // Если есть подключение, получаем заметки из Firestore
        try {
          final snapshot = await _firestore
              .collection('fishing_notes')
              .where('userId', isEqualTo: userId)
              .get();

          // Преобразуем результаты в модели
          final onlineNotes = snapshot.docs
              .map((doc) => FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
              .toList();

          debugPrint('☁️ Онлайн заметок: ${onlineNotes.length}');

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
              debugPrint('➕ Добавлена офлайн заметка: ${note.id}');
            }
          }

          // Преобразуем обратно в список и сортируем по дате
          final allNotes = uniqueNotes.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          debugPrint('📊 Всего уникальных заметок: ${allNotes.length}');

          // Запускаем синхронизацию в фоне
          _syncService.syncAll();

          return allNotes;
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении онлайн заметок: $e');
          // Если ошибка при получении онлайн заметок, возвращаем офлайн заметки
          return offlineNotes;
        }
      } else {
        // Если нет подключения, возвращаем заметки из офлайн хранилища
        debugPrint('📱 Возвращаем только офлайн заметки');
        return offlineNotes;
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка в getUserFishingNotes: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн заметки
      try {
        final userId = _firebaseService.currentUserId ?? '';
        debugPrint('🔄 Пытаемся получить офлайн заметки для: $userId');
        return await _getOfflineNotes(userId);
      } catch (innerError) {
        debugPrint('❌ Критическая ошибка при получении офлайн заметок: $innerError');
        rethrow;
      }
    }
  }

  // Получение заметок из офлайн хранилища
  Future<List<FishingNoteModel>> _getOfflineNotes(String userId) async {
    try {
      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      debugPrint('📱 Всего офлайн заметок в хранилище: ${offlineNotes.length}');

      // Выводим id всех заметок для отладки
      for (var note in offlineNotes) {
        debugPrint('📄 Офлайн заметка: ${note['id']} (user: ${note['userId']})');
      }

      final offlineNoteModels = offlineNotes
          .where((note) => note['userId'] == userId) // Фильтруем по userId
          .map((note) {
        final id = note['id']?.toString() ?? '';
        if (id.isEmpty) {
          debugPrint('⚠️ Обнаружена заметка без ID!');
        }
        return FishingNoteModel.fromJson(note, id: id);
      })
          .toList();

      debugPrint('📱 Заметок для пользователя $userId: ${offlineNoteModels.length}');

      // Сортируем по дате
      offlineNoteModels.sort((a, b) => b.date.compareTo(a.date));

      return offlineNoteModels;
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  // Добавление новой заметки
  Future<String> addFishingNote(FishingNoteModel note, List<File>? photos) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ addFishingNote: Пользователь не авторизован');
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final noteId = note.id.isEmpty ? const Uuid().v4() : note.id;
      debugPrint('📝 Добавление заметки с ID: $noteId');

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(
        id: noteId,
        userId: userId,
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети при добавлении: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Если есть интернет, загружаем фото и добавляем заметку в Firestore
        List<String> photoUrls = [];

        // Загружаем фото и получаем URL
        if (photos != null && photos.isNotEmpty) {
          debugPrint('🖼️ Загрузка ${photos.length} фото');
          for (var photo in photos) {
            try {
              final bytes = await photo.readAsBytes();
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
              final path = 'users/$userId/photos/$fileName';
              final url = await _firebaseService.uploadImage(path, bytes);
              photoUrls.add(url);
              debugPrint('🖼️ Фото загружено: $url');
            } catch (e) {
              debugPrint('⚠️ Ошибка при загрузке фото: $e');
            }
          }
        }

        // Создаем копию заметки с URL фотографий
        final noteWithPhotos = noteToAdd.copyWith(
          photoUrls: photoUrls,
        );

        // Добавляем заметку в Firestore
        try {
          final docRef = await _firestore
              .collection('fishing_notes')
              .doc(noteId)
              .set(noteWithPhotos.toJson());

          debugPrint('✅ Заметка $noteId добавлена в Firestore');

          // Проверяем, есть ли офлайн заметки для отправки
          _syncService.syncAll();

          return noteId;
        } catch (e) {
          debugPrint('⚠️ Ошибка при добавлении заметки в Firestore: $e');

          // Если ошибка при добавлении в Firestore, сохраняем заметку локально
          await _saveOfflineNote(noteWithPhotos, photos);
          return noteId;
        }
      } else {
        // Если нет интернета, сохраняем заметку локально
        debugPrint('📱 Сохранение заметки в офлайн режиме');
        await _saveOfflineNote(noteToAdd, photos);
        return noteId;
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // Сохранение заметки в офлайн режиме
  Future<void> _saveOfflineNote(FishingNoteModel note, List<File>? photos) async {
    try {
      // Проверяем, что у заметки есть ID
      if (note.id.isEmpty) {
        debugPrint('⚠️ Попытка сохранить заметку без ID!');
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('📱 Сохранение заметки ${note.id} в офлайн режиме');

      // Сохраняем заметку
      final noteJson = note.toJson();
      noteJson['id'] = note.id; // Явно добавляем ID в JSON
      await _offlineStorage.saveOfflineNote(noteJson);

      // Сохраняем пути к фотографиям
      if (photos != null && photos.isNotEmpty) {
        final photoPaths = photos.map((file) => file.path).toList();
        await _offlineStorage.saveOfflinePhotoPaths(note.id, photoPaths);
        debugPrint('📱 Сохранено ${photoPaths.length} путей к фото для заметки ${note.id}');
      }

      debugPrint('✅ Заметка ${note.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('⚠️ Ошибка при сохранении заметки офлайн: $e');
      rethrow;
    }
  }

  // Обновление заметки
  Future<void> updateFishingNote(FishingNoteModel note) async {
    try {
      if (note.id.isEmpty) {
        debugPrint('⚠️ Попытка обновить заметку без ID!');
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔄 Обновление заметки: ${note.id}');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети при обновлении: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Если есть интернет, обновляем заметку в Firestore
        try {
          await _firestore
              .collection('fishing_notes')
              .doc(note.id)
              .update(note.toJson());

          debugPrint('✅ Заметка ${note.id} обновлена в Firestore');

          // Даже при успешном онлайн-обновлении, обновляем локальную копию
          // Это гарантирует согласованность данных в случае перехода в офлайн
          final noteJson = note.toJson();
          noteJson['id'] = note.id; // Явно добавляем ID в JSON
          await _offlineStorage.saveOfflineNote(noteJson);
          debugPrint('📱 Заметка ${note.id} также обновлена локально');
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении заметки в Firestore: $e');

          // В случае ошибки сохраняем заметку локально
          final noteJson = note.toJson();
          noteJson['id'] = note.id; // Явно добавляем ID в JSON
          await _offlineStorage.saveOfflineNote(noteJson);
          debugPrint('📱 Заметка ${note.id} сохранена локально (после ошибки Firestore)');
        }
      } else {
        // Если нет интернета, сохраняем заметку локально
        final noteJson = note.toJson();
        noteJson['id'] = note.id; // Явно добавляем ID в JSON
        await _offlineStorage.saveOfflineNote(noteJson);
        debugPrint('📱 Заметка ${note.id} сохранена локально (офлайн режим)');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при обновлении заметки: $e');

      // В случае ошибки, пытаемся сохранить заметку локально
      try {
        final noteJson = note.toJson();
        noteJson['id'] = note.id; // Явно добавляем ID в JSON
        await _offlineStorage.saveOfflineNote(noteJson);
        debugPrint('📱 Заметка ${note.id} сохранена локально (после общей ошибки)');
      } catch (innerError) {
        debugPrint('❌ Критическая ошибка при сохранении обновления: $innerError');
        rethrow;
      }
    }
  }

  // Обновление заметки с загрузкой новых фотографий
  Future<FishingNoteModel> updateFishingNoteWithPhotos(FishingNoteModel note, List<File> newPhotos) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (note.id.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔄 Обновление заметки с новыми фото: ${note.id}');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Список для хранения всех URL фотографий (существующие + новые)
        final List<String> allPhotoUrls = List.from(note.photoUrls);

        // Загрузка новых фото
        if (newPhotos.isNotEmpty) {
          debugPrint('🖼️ Загрузка ${newPhotos.length} новых фото');
          for (var photo in newPhotos) {
            try {
              final bytes = await photo.readAsBytes();
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${newPhotos.indexOf(photo)}.jpg';
              final path = 'users/$userId/photos/$fileName';
              final url = await _firebaseService.uploadImage(path, bytes);
              allPhotoUrls.add(url);
              debugPrint('🖼️ Фото загружено: $url');
            } catch (e) {
              debugPrint('⚠️ Ошибка при загрузке фото: $e');
            }
          }
        }

        // Создаем обновленную модель заметки с новыми фото
        final updatedNote = note.copyWith(photoUrls: allPhotoUrls);

        // Обновляем заметку в Firestore
        try {
          await _firestore
              .collection('fishing_notes')
              .doc(note.id)
              .update(updatedNote.toJson());

          debugPrint('✅ Заметка ${note.id} обновлена с новыми фото');

          // Обновляем также локальную копию
          final noteJson = updatedNote.toJson();
          noteJson['id'] = updatedNote.id; // Явно добавляем ID в JSON
          await _offlineStorage.saveOfflineNote(noteJson);

          return updatedNote;
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении заметки в Firestore: $e');

          // Если ошибка при обновлении, сохраняем локально
          await _saveOfflineNoteUpdate(updatedNote, newPhotos);
          debugPrint('📱 Обновление заметки ${note.id} с фото сохранено локально');
          return updatedNote;
        }
      } else {
        // Если нет интернета, сохраняем обновление локально
        debugPrint('📱 Сохранение обновления заметки ${note.id} с фото в офлайн режиме');
        await _saveOfflineNoteUpdate(note, newPhotos);

        // Добавляем пути к новым фото в модель
        // Это временное решение для отображения пользователю
        final updatedNote = note.copyWith(
          photoUrls: [...note.photoUrls, ...newPhotos.map((_) => 'offline_photo')],
        );

        // Сохраняем полную модель в офлайн хранилище
        final noteJson = updatedNote.toJson();
        noteJson['id'] = updatedNote.id; // Явно добавляем ID в JSON
        await _offlineStorage.saveOfflineNote(noteJson);

        return updatedNote;
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при обновлении заметки с фото: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _saveOfflineNoteUpdate(note, newPhotos);
        debugPrint('📱 Обновление заметки с фото сохранено локально (после ошибки)');
      } catch (_) {
        // Игнорируем вторичную ошибку
      }
      rethrow;
    }
  }

  // Сохранение обновления заметки в офлайн режиме
  Future<void> _saveOfflineNoteUpdate(FishingNoteModel note, List<File> newPhotos) async {
    try {
      if (note.id.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      // Сохраняем обновление заметки
      final noteJson = note.toJson();
      noteJson['id'] = note.id; // Явно добавляем ID в JSON
      await _offlineStorage.saveOfflineNote(noteJson);

      // Если есть новые фото
      if (newPhotos.isNotEmpty) {
        // Получаем существующие пути к фото для этой заметки
        final existingPaths = await _offlineStorage.getOfflinePhotoPaths(note.id);

        // Добавляем пути к новым фото
        final newPaths = newPhotos.map((photo) => photo.path).toList();
        final allPaths = [...existingPaths, ...newPaths];

        // Сохраняем обновленные пути
        await _offlineStorage.saveOfflinePhotoPaths(note.id, allPaths);
        debugPrint('📱 Сохранено ${newPaths.length} новых путей к фото (всего: ${allPaths.length})');
      }

      debugPrint('✅ Обновление заметки ${note.id} сохранено в офлайн режиме');
    } catch (e) {
      debugPrint('⚠️ Ошибка при сохранении обновления заметки офлайн: $e');
      rethrow;
    }
  }

  // Удаление заметки
  Future<void> deleteFishingNote(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🗑️ Удаление заметки: $noteId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Если есть интернет, удаляем заметку из Firestore
        try {
          await _firestore
              .collection('fishing_notes')
              .doc(noteId)
              .delete();

          debugPrint('✅ Заметка $noteId удалена из Firestore');

          // Удаляем локальную копию, если она есть
          try {
            await _offlineStorage.removeOfflineNote(noteId);
            debugPrint('📱 Локальная копия заметки $noteId удалена');
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении локальной копии заметки: $e');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении заметки из Firestore: $e');

          // Если ошибка при удалении из Firestore, отмечаем для удаления
          await _offlineStorage.markForDeletion(noteId, false);
          debugPrint('📱 Заметка $noteId отмечена для удаления');

          // Удаляем локальную копию
          try {
            await _offlineStorage.removeOfflineNote(noteId);
            debugPrint('📱 Локальная копия заметки $noteId удалена');
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении локальной копии заметки: $e');
          }
        }
      } else {
        // Если нет интернета, отмечаем заметку для удаления при появлении соединения
        await _offlineStorage.markForDeletion(noteId, false);
        debugPrint('📱 Заметка $noteId отмечена для удаления (офлайн)');

        // Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineNote(noteId);
          debugPrint('📱 Локальная копия заметки $noteId удалена');
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении локальной копии заметки: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при удалении заметки: $e');

      // В случае ошибки, отмечаем заметку для удаления
      try {
        await _offlineStorage.markForDeletion(noteId, false);
        debugPrint('📱 Заметка $noteId отмечена для удаления (после ошибки)');
      } catch (_) {
        // Игнорируем вторичную ошибку
      }
      rethrow;
    }
  }

  // Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔍 Получение заметки по ID: $noteId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Если есть интернет, получаем заметку из Firestore
        try {
          final doc = await _firestore
              .collection('fishing_notes')
              .doc(noteId)
              .get();

          if (!doc.exists) {
            debugPrint('⚠️ Заметка не найдена в Firestore, ищем в офлайн хранилище');
            // Если заметка не найдена в Firestore, пробуем найти в офлайн хранилище
            return await _getOfflineNoteById(noteId);
          }

          // Получаем заметку из Firestore и сохраняем ее локально для дальнейшего использования в офлайн
          final note = FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
          debugPrint('✅ Заметка $noteId получена из Firestore');

          // Сохраняем копию в офлайн хранилище для будущего использования
          final noteJson = note.toJson();
          noteJson['id'] = note.id; // Явно добавляем ID в JSON
          await _offlineStorage.saveOfflineNote(noteJson);

          return note;
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении заметки из Firestore: $e');

          // Если ошибка при получении из Firestore, ищем в офлайн хранилище
          return await _getOfflineNoteById(noteId);
        }
      } else {
        // Если нет интернета, ищем заметку в офлайн хранилище
        debugPrint('📱 Ищем заметку $noteId в офлайн хранилище');
        return await _getOfflineNoteById(noteId);
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении заметки по ID: $e');

      // В случае ошибки, пытаемся получить заметку из офлайн хранилища
      try {
        debugPrint('🔄 Пытаемся получить заметку $noteId из офлайн хранилища');
        return await _getOfflineNoteById(noteId);
      } catch (innerError) {
        debugPrint('❌ Критическая ошибка при получении офлайн заметки: $innerError');
        rethrow;
      }
    }
  }

  // Получение заметки из офлайн хранилища по ID
  Future<FishingNoteModel> _getOfflineNoteById(String noteId) async {
    try {
      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
      debugPrint('📱 Всего офлайн заметок: ${allOfflineNotes.length}');

      // Ищем заметку по ID
      final noteDataList = allOfflineNotes.where((note) => note['id'] == noteId).toList();

      if (noteDataList.isEmpty) {
        debugPrint('⚠️ Заметка $noteId не найдена в офлайн хранилище');
        throw Exception('Заметка не найдена в офлайн хранилище');
      }

      // Берем первую найденную заметку
      final noteData = noteDataList.first;

      debugPrint('✅ Заметка $noteId найдена в офлайн хранилище');
      return FishingNoteModel.fromJson(noteData, id: noteId);
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении заметки из офлайн хранилища: $e');
      rethrow;
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    try {
      debugPrint('🔄 Запуск синхронизации при запуске приложения');
      await _syncService.syncAll();
      debugPrint('✅ Синхронизация при запуске завершена');
    } catch (e) {
      debugPrint('⚠️ Ошибка при синхронизации при запуске: $e');
    }
  }

  // Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      debugPrint('🔄 Запуск принудительной синхронизации');
      final result = await _syncService.forceSyncAll();
      debugPrint('✅ Принудительная синхронизация завершена: ${result ? 'успешно' : 'есть ошибки'}');
      return result;
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
      debugPrint('⚠️ Ошибка при получении статуса синхронизации: $e');
      return {'error': e.toString()};
    }
  }
}