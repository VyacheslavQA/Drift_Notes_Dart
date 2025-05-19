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

  // Получение всех заметок пользователя
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть подключение, получаем заметки из Firestore
        final snapshot = await _firebaseService.getUserFishingNotes(userId);

        // Преобразуем результаты в модели
        final onlineNotes = snapshot.docs
            .map((doc) => FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
            .toList();

        // Получаем офлайн заметки, которые еще не были синхронизированы
        final offlineNotes = await _getOfflineNotes(userId);

        // Объединяем списки, избегая дубликатов
        final allNotes = [...onlineNotes];

        for (var offlineNote in offlineNotes) {
          // Проверяем, что такой заметки еще нет в списке
          if (!allNotes.any((note) => note.id == offlineNote.id)) {
            allNotes.add(offlineNote);
          }
        }

        // Запускаем синхронизацию в фоне
        _syncService.syncAll();

        return allNotes;
      } else {
        // Если нет подключения, получаем заметки из офлайн хранилища
        return await _getOfflineNotes(userId);
      }
    } catch (e) {
      debugPrint('Ошибка при получении заметок: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн заметки
      try {
        return await _getOfflineNotes(_firebaseService.currentUserId ?? '');
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение заметок из офлайн хранилища
  Future<List<FishingNoteModel>> _getOfflineNotes(String userId) async {
    try {
      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      final offlineNoteModels = offlineNotes
          .where((note) => note['userId'] == userId) // Фильтруем по userId
          .map((note) => FishingNoteModel.fromJson(note, id: note['id'] as String))
          .toList();

      return offlineNoteModels;
    } catch (e) {
      debugPrint('Ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  // Добавление новой заметки
  Future<String> addFishingNote(FishingNoteModel note, List<File>? photos) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final noteId = note.id.isEmpty ? const Uuid().v4() : note.id;

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(
        id: noteId,
        userId: userId,
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, загружаем фото и добавляем заметку в Firestore
        List<String> photoUrls = [];

        // Загружаем фото и получаем URL
        if (photos != null && photos.isNotEmpty) {
          for (var photo in photos) {
            final bytes = await photo.readAsBytes();
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
            final path = 'users/$userId/photos/$fileName';
            final url = await _firebaseService.uploadImage(path, bytes);
            photoUrls.add(url);
          }
        }

        // Создаем копию заметки с URL фотографий
        final noteWithPhotos = noteToAdd.copyWith(
          photoUrls: photoUrls,
        );

        // Добавляем заметку в Firestore
        final docRef = await _firebaseService.addFishingNote(noteWithPhotos.toJson());

        // Проверяем, есть ли офлайн заметки для отправки
        await _syncService.syncAll();

        return docRef.id;
      } else {
        // Если нет интернета, сохраняем заметку локально
        await _saveNoteOffline(noteToAdd, photos);
        return noteId;
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // Сохранение заметки в офлайн режиме
  Future<void> _saveNoteOffline(FishingNoteModel note, List<File>? photos) async {
    try {
      // Сохраняем заметку
      await _offlineStorage.saveOfflineNote(note.toJson());

      // Сохраняем пути к фотографиям
      if (photos != null && photos.isNotEmpty) {
        final photoPaths = photos.map((file) => file.path).toList();
        await _offlineStorage.saveOfflinePhotoPaths(note.id, photoPaths);
      }

      debugPrint('Заметка ${note.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('Ошибка при сохранении заметки офлайн: $e');
      rethrow;
    }
  }

  // Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем заметку из Firestore
        final doc = await FirebaseFirestore.instance
            .collection('fishing_notes')
            .doc(noteId)
            .get();

        if (!doc.exists) {
          // Если заметка не найдена в Firestore, пробуем найти в офлайн хранилище
          return await _getOfflineNoteById(noteId);
        }

        return FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
      } else {
        // Если нет интернета, ищем заметку в офлайн хранилище
        return await _getOfflineNoteById(noteId);
      }
    } catch (e) {
      debugPrint('Ошибка при получении заметки по ID: $e');

      // В случае ошибки, пытаемся получить заметку из офлайн хранилища
      try {
        return await _getOfflineNoteById(noteId);
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение заметки из офлайн хранилища по ID
  Future<FishingNoteModel> _getOfflineNoteById(String noteId) async {
    try {
      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();

      // Ищем заметку по ID
      final noteData = allOfflineNotes.firstWhere(
            (note) => note['id'] == noteId,
        orElse: () => throw Exception('Заметка не найдена в офлайн хранилище'),
      );

      return FishingNoteModel.fromJson(noteData, id: noteId);
    } catch (e) {
      debugPrint('Ошибка при получении заметки из офлайн хранилища: $e');
      rethrow;
    }
  }

  // Обновление заметки
  Future<void> updateFishingNote(FishingNoteModel note) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем заметку в Firestore
        await _firebaseService.updateFishingNote(note.id, note.toJson());
      } else {
        // Если нет интернета, сохраняем обновление локально
        await _offlineStorage.saveNoteUpdate(note.id, note.toJson());
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении заметки: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveNoteUpdate(note.id, note.toJson());
      } catch (_) {
        rethrow;
      }
    }
  }

  // Удаление заметки
  Future<void> deleteFishingNote(String noteId) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, удаляем заметку из Firestore
        await FirebaseFirestore.instance
            .collection('fishing_notes')
            .doc(noteId)
            .delete();

        // Удаляем локальную копию, если она есть
        try {
          await _offlineStorage.removeOfflineNote(noteId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии заметки: $e');
        }
      } else {
        // Если нет интернета, отмечаем заметку для удаления при появлении соединения
        await _offlineStorage.markForDeletion(noteId, false);

        // Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineNote(noteId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии заметки: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при удалении заметки: $e');

      // В случае ошибки, отмечаем заметку для удаления
      try {
        await _offlineStorage.markForDeletion(noteId, false);
      } catch (_) {
        rethrow;
      }
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await _syncService.syncAll();
  }

  // Обновление заметки с загрузкой новых фотографий
  Future<FishingNoteModel> updateFishingNoteWithPhotos(FishingNoteModel note, List<File> newPhotos) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Список для хранения всех URL фотографий (существующие + новые)
        final List<String> allPhotoUrls = List.from(note.photoUrls);

        // Загрузка новых фото
        if (newPhotos.isNotEmpty) {
          for (var photo in newPhotos) {
            final bytes = await photo.readAsBytes();
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${newPhotos.indexOf(photo)}.jpg';
            final path = 'users/$userId/photos/$fileName';
            final url = await _firebaseService.uploadImage(path, bytes);
            allPhotoUrls.add(url);
          }
        }

        // Создаем обновленную модель заметки с новыми фото
        final updatedNote = note.copyWith(photoUrls: allPhotoUrls);

        // Обновляем заметку в Firestore
        await _firebaseService.updateFishingNote(note.id, updatedNote.toJson());

        return updatedNote;
      } else {
        // Если нет интернета, сохраняем обновление локально
        await saveOfflineNoteUpdate(note, newPhotos);

        // Добавляем пути к новым фото в модель
        // Это временное решение для отображения пользователю
        final updatedNote = note.copyWith(
          photoUrls: [...note.photoUrls, ...newPhotos.map((_) => 'offline')],
        );

        return updatedNote;
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении заметки с фото: $e');

      // В случае ошибки, сохраняем обновление локально
      await saveOfflineNoteUpdate(note, newPhotos);
      rethrow;
    }
  }

  // Сохранение обновления заметки в офлайн режиме
  Future<void> saveOfflineNoteUpdate(FishingNoteModel note, List<File> newPhotos) async {
    try {
      // Сохраняем обновление заметки
      await _offlineStorage.saveNoteUpdate(note.id, note.toJson());

      // Если есть новые фото
      if (newPhotos.isNotEmpty) {
        // Получаем существующие пути к фото для этой заметки
        final existingPaths = await _offlineStorage.getOfflinePhotoPaths(note.id);

        // Добавляем пути к новым фото
        final newPaths = newPhotos.map((photo) => photo.path).toList();
        final allPaths = [...existingPaths, ...newPaths];

        // Сохраняем обновленные пути
        await _offlineStorage.saveOfflinePhotoPaths(note.id, allPaths);
      }

      debugPrint('Обновление заметки ${note.id} сохранено в офлайн режиме');
    } catch (e) {
      debugPrint('Ошибка при сохранении обновления заметки офлайн: $e');
      rethrow;
    }
  }

  // Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      return await _syncService.forceSyncAll();
    } catch (e) {
      debugPrint('Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  // Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }
}