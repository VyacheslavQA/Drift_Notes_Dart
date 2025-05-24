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
import '../services/local/local_file_service.dart'; // Новый импорт

class FishingNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalFileService _localFileService = LocalFileService(); // Новый сервис

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
              .map((doc) => FishingNoteModel.fromJson(doc.data()!, id: doc.id))
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
          await _firestore
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
        // Если нет интернета, создаем локальные копии фотографий и сохраняем локальные URI
        List<String> localPhotoUris = [];
        if (photos != null && photos.isNotEmpty) {
          debugPrint('📱 Создание локальных копий ${photos.length} фото');
          localPhotoUris = await _localFileService.saveLocalCopies(photos);
          debugPrint('📱 Создано ${localPhotoUris.length} локальных копий фото');
        }

        // Создаем копию заметки с локальными URI фотографий
        final noteWithLocalPhotos = noteToAdd.copyWith(
          photoUrls: localPhotoUris,
        );

        // Сохраняем заметку локально
        debugPrint('📱 Сохранение заметки в офлайн режиме');
        await _saveOfflineNote(noteWithLocalPhotos, photos);
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

      // ВАЖНОЕ ИЗМЕНЕНИЕ: Всегда сначала сохраняем заметку локально,
      // чтобы изменения были доступны немедленно даже в офлайн режиме
      final noteJson = note.toJson();
      noteJson['id'] = note.id; // Явно добавляем ID в JSON
      await _offlineStorage.saveOfflineNote(noteJson);
      debugPrint('📱 Заметка ${note.id} сохранена локально');

      if (isOnline) {
        // Если есть интернет, обновляем заметку в Firestore
        try {
          await _firestore
              .collection('fishing_notes')
              .doc(note.id)
              .update(note.toJson());

          debugPrint('✅ Заметка ${note.id} обновлена в Firestore');
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении заметки в Firestore: $e');
          // Поскольку мы уже сохранили заметку локально, нам не нужно дублировать код здесь
        }
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

  // Метод updateFishingNoteWithPhotos - обновлён для поддержки локальных файлов
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

      // Список для хранения всех URL фотографий (существующие + новые)
      final List<String> allPhotoUrls = List.from(note.photoUrls);

      // Список для хранения локальных URI для синхронизации
      final List<String> localUris = [];

      // ИЗМЕНЕНО: Обработка в зависимости от соединения
      if (isOnline) {
        // Если онлайн - загружаем фото на сервер
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

        // Проверяем, есть ли локальные URI в списке и загружаем их
        final offlineUris = allPhotoUrls.where((url) =>
        _localFileService.isLocalFileUri(url) || url == 'offline_photo').toList();

        if (offlineUris.isNotEmpty) {
          debugPrint('🔄 Обнаружены локальные URI (${offlineUris.length}), загружаем их на сервер');

          for (var localUri in offlineUris) {
            try {
              if (localUri == 'offline_photo') continue;

              if (_localFileService.isLocalFileUri(localUri)) {
                final file = _localFileService.localUriToFile(localUri);
                if (file != null && await file.exists()) {
                  final bytes = await file.readAsBytes();
                  final fileName = '${DateTime.now().millisecondsSinceEpoch}_${offlineUris.indexOf(localUri)}.jpg';
                  final path = 'users/$userId/photos/$fileName';
                  final url = await _firebaseService.uploadImage(path, bytes);

                  // Заменяем локальный URI на сетевой
                  allPhotoUrls[allPhotoUrls.indexOf(localUri)] = url;
                  debugPrint('🔄 Локальное фото заменено на серверное: $url');

                  // Удаляем локальную копию
                  await _localFileService.deleteLocalFile(localUri);
                }
              } else if (localUri == 'offline_photo') {
                // Удаляем placeholder
                allPhotoUrls.remove(localUri);
              }
            } catch (e) {
              debugPrint('⚠️ Ошибка при загрузке локального фото: $e');
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

          debugPrint('✅ Заметка ${note.id} обновлена с новыми фото в Firestore');

          // Обновляем также локальную копию
          final noteJson = updatedNote.toJson();
          noteJson['id'] = updatedNote.id; // Явно добавляем ID в JSON
          await _offlineStorage.saveOfflineNote(noteJson);

          return updatedNote;
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении заметки в Firestore: $e');

          // Если ошибка при обновлении, сохраняем локально
          await _saveOfflineNoteUpdate(updatedNote, newPhotos);
          return updatedNote;
        }
      } else {
        // Если оффлайн - создаем локальные копии
        debugPrint('📱 Создание локальных копий ${newPhotos.length} фото');
        final newLocalUris = await _localFileService.saveLocalCopies(newPhotos);
        debugPrint('📱 Создано ${newLocalUris.length} локальных копий фото');

        // Добавляем локальные URI к существующим фото
        allPhotoUrls.addAll(newLocalUris);
        localUris.addAll(newLocalUris);

        // Создаем обновленную модель заметки с локальными URI
        final updatedNote = note.copyWith(photoUrls: allPhotoUrls);

        // Сохраняем заметку локально
        final noteJson = updatedNote.toJson();
        noteJson['id'] = updatedNote.id; // Явно добавляем ID в JSON
        await _offlineStorage.saveOfflineNote(noteJson);

        // Сохраняем пути к исходным файлам для последующей синхронизации
        if (newPhotos.isNotEmpty) {
          final photoPaths = newPhotos.map((file) => file.path).toList();
          final existingPaths = await _offlineStorage.getOfflinePhotoPaths(note.id);
          await _offlineStorage.saveOfflinePhotoPaths(note.id, [...existingPaths, ...photoPaths]);
          debugPrint('📱 Сохранено ${photoPaths.length} путей к фото для заметки ${note.id}');
        }

        debugPrint('✅ Заметка ${note.id} обновлена с локальными фото');
        return updatedNote;
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при обновлении заметки с фото: $e');

      // В случае ошибки, пытаемся сохранить хотя бы с локальными копиями
      try {
        // Создаем локальные копии фото
        final localUris = await _localFileService.saveLocalCopies(newPhotos);
        final updatedPhotoUrls = [...note.photoUrls, ...localUris];
        final updatedNote = note.copyWith(photoUrls: updatedPhotoUrls);

        // Сохраняем локально
        final noteJson = updatedNote.toJson();
        noteJson['id'] = updatedNote.id;
        await _offlineStorage.saveOfflineNote(noteJson);

        // Сохраняем пути к исходным файлам
        final photoPaths = newPhotos.map((file) => file.path).toList();
        final existingPaths = await _offlineStorage.getOfflinePhotoPaths(note.id);
        await _offlineStorage.saveOfflinePhotoPaths(note.id, [...existingPaths, ...photoPaths]);

        debugPrint('📱 Заметка с фото сохранена локально после ошибки');
        return updatedNote;
      } catch (innerError) {
        debugPrint('❌ Критическая ошибка при обработке фото: $innerError');
        rethrow;
      }
    }
  }

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

  // Публичный метод для сохранения обновления заметки в офлайн режиме
  Future<void> saveOfflineNoteUpdate(FishingNoteModel note, List<File> newPhotos) async {
    try {
      // Проверка на наличие локальных копий для фото в офлайн режиме
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (!isOnline && newPhotos.isNotEmpty) {
        // Создаем локальные копии фото
        final localUris = await _localFileService.saveLocalCopies(newPhotos);

        // Добавляем локальные URI к существующим фото
        final updatedPhotoUrls = [...note.photoUrls, ...localUris];
        final updatedNote = note.copyWith(photoUrls: updatedPhotoUrls);

        // Сохраняем заметку с локальными URI
        await _saveOfflineNoteUpdate(updatedNote, newPhotos);
        return;
      }

      await _saveOfflineNoteUpdate(note, newPhotos);
    } catch (e) {
      debugPrint('⚠️ Ошибка при сохранении обновления заметки: $e');
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

      // Получаем данные заметки для удаления локальных файлов
      FishingNoteModel? note;
      try {
        note = await _getOfflineNoteById(noteId);
      } catch (e) {
        debugPrint('⚠️ Не удалось получить данные заметки для удаления: $e');
      }

      // Удаляем локальные копии файлов, если они есть
      if (note != null && note.photoUrls.isNotEmpty) {
        for (var url in note.photoUrls) {
          if (_localFileService.isLocalFileUri(url)) {
            await _localFileService.deleteLocalFile(url);
            debugPrint('🗑️ Удален локальный файл: $url');
          }
        }
      }

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

  // Очистка кэша локальных файлов
  Future<void> clearLocalFilesCache() async {
    try {
      await _localFileService.clearCache();
      debugPrint('✅ Кэш локальных файлов очищен');
    } catch (e) {
      debugPrint('⚠️ Ошибка при очистке кэша локальных файлов: $e');
      rethrow;
    }
  }

  // Получить размер кэша локальных файлов
  Future<int> getLocalFilesCacheSize() async {
    try {
      return await _localFileService.getCacheSize();
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении размера кэша: $e');
      return 0;
    }
  }
}