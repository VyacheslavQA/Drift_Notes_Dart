// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/fishing_note_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class FishingNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();

  // Ключ для хранения офлайн заметок
  static const String _offlineNotesKey = 'offline_fishing_notes';
  static const String _offlinePhotosKey = 'offline_fishing_photos';

  // Получение всех заметок пользователя
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final snapshot = await _firebaseService.getUserFishingNotes(userId);
      return snapshot.docs
          .map((doc) => FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Ошибка при получении заметок: $e');
      rethrow;
    }
  }

  // Добавление новой заметки
  Future<String> addFishingNote(FishingNoteModel note, List<File>? photos) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, загружаем фото и добавляем заметку в Firestore

        // Загружаем фото и получаем URL
        final List<String> photoUrls = [];
        if (photos != null && photos.isNotEmpty) {
          for (var photo in photos) {
            final bytes = await photo.readAsBytes();
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
            final path = 'users/$userId/photos/$fileName';
            final url = await _firebaseService.uploadImage(path, bytes);
            photoUrls.add(url);
          }
        }

        // Создаем копию заметки с URL фотографий и ID пользователя
        final noteToAdd = note.copyWith(
          photoUrls: photoUrls,
          userId: userId,
        );

        // Добавляем заметку в Firestore
        final docRef = await _firebaseService.addFishingNote(noteToAdd.toJson());

        // Проверяем, есть ли офлайн заметки для отправки
        await _syncOfflineNotes();

        return docRef.id;
      } else {
        // Если нет интернета, сохраняем заметку локально
        await _saveNoteOffline(note, photos);
        return note.id;
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // Сохранение заметки в офлайн режиме
  Future<void> _saveNoteOffline(FishingNoteModel note, List<File>? photos) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Получаем текущие офлайн заметки
      final List<String> offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      // Добавляем новую заметку
      final noteToAdd = note.copyWith(
        userId: _firebaseService.currentUserId ?? '',
      );
      offlineNotesJson.add(jsonEncode(noteToAdd.toJson()));

      // Сохраняем обновленный список заметок
      await prefs.setStringList(_offlineNotesKey, offlineNotesJson);

      // Сохраняем фотографии локально, если они есть
      if (photos != null && photos.isNotEmpty) {
        // Создаем карту с путями к фотографиям для этой заметки
        Map<String, List<String>> offlinePhotos = {};

        // Загружаем существующие фото
        final String? offlinePhotosJson = prefs.getString(_offlinePhotosKey);
        if (offlinePhotosJson != null) {
          offlinePhotos = Map<String, List<String>>.from(
            jsonDecode(offlinePhotosJson).map(
                  (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          );
        }

        // Сохраняем пути к фото для этой заметки
        offlinePhotos[note.id] = photos.map((file) => file.path).toList();

        // Обновляем хранилище
        await prefs.setString(_offlinePhotosKey, jsonEncode(offlinePhotos));
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении заметки офлайн: $e');
      rethrow;
    }
  }

  // Синхронизация офлайн заметок с сервером
  Future<void> _syncOfflineNotes() async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (!isOnline) return;

      final userId = _firebaseService.currentUserId;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final List<String> offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      if (offlineNotesJson.isEmpty) return;

      // Получаем пути к офлайн фотографиям
      final String? offlinePhotosJson = prefs.getString(_offlinePhotosKey);
      Map<String, List<String>> offlinePhotos = {};
      if (offlinePhotosJson != null) {
        offlinePhotos = Map<String, List<String>>.from(
          jsonDecode(offlinePhotosJson).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      }

      // Массивы для хранения успешно синхронизированных заметок
      final List<String> syncedNotes = [];
      final List<String> syncedNoteIds = [];

      // Загружаем каждую заметку на сервер
      for (var i = 0; i < offlineNotesJson.length; i++) {
        try {
          final noteJson = jsonDecode(offlineNotesJson[i]) as Map<String, dynamic>;
          final note = FishingNoteModel.fromJson(noteJson);

          // Получаем пути к фотографиям для этой заметки
          final List<String> photoPaths = offlinePhotos[note.id] ?? [];

          // Загружаем фото и получаем URL
          final List<String> photoUrls = [];
          for (var path in photoPaths) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photoPaths.indexOf(path)}.jpg';
                final storagePath = 'users/$userId/photos/$fileName';
                final url = await _firebaseService.uploadImage(storagePath, bytes);
                photoUrls.add(url);
              }
            } catch (e) {
              debugPrint('Ошибка при загрузке фото: $e');
            }
          }

          // Создаем копию заметки с URL фотографий
          final noteToAdd = note.copyWith(
            photoUrls: photoUrls,
            userId: userId,
          );

          // Добавляем заметку в Firestore
          await _firebaseService.addFishingNote(noteToAdd.toJson());

          // Добавляем заметку в список синхронизированных
          syncedNotes.add(offlineNotesJson[i]);
          syncedNoteIds.add(note.id);

        } catch (e) {
          debugPrint('Ошибка при синхронизации заметки: $e');
        }
      }

      // Удаляем синхронизированные заметки из локального хранилища
      if (syncedNotes.isNotEmpty) {
        final updatedNotes = offlineNotesJson.where((note) => !syncedNotes.contains(note)).toList();
        await prefs.setStringList(_offlineNotesKey, updatedNotes);

        // Удаляем пути к синхронизированным фотографиям
        for (var noteId in syncedNoteIds) {
          offlinePhotos.remove(noteId);
        }
        await prefs.setString(_offlinePhotosKey, jsonEncode(offlinePhotos));
      }

    } catch (e) {
      debugPrint('Ошибка при синхронизации офлайн заметок: $e');
    }
  }

  // Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('fishing_notes')
          .doc(noteId)
          .get();

      if (!doc.exists) {
        throw Exception('Заметка не найдена');
      }

      return FishingNoteModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
    } catch (e) {
      debugPrint('Ошибка при получении заметки по ID: $e');
      rethrow;
    }
  }

  // Обновление заметки
  Future<void> updateFishingNote(FishingNoteModel note) async {
    try {
      await _firebaseService.updateFishingNote(note.id, note.toJson());
    } catch (e) {
      debugPrint('Ошибка при обновлении заметки: $e');
      rethrow;
    }
  }

  // Удаление заметки
  Future<void> deleteFishingNote(String noteId) async {
    try {
      await FirebaseFirestore.instance
          .collection('fishing_notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('Ошибка при удалении заметки: $e');
      rethrow;
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await _syncOfflineNotes();
  }
}