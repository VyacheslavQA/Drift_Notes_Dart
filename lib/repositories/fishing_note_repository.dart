// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fishing_note_model.dart';
import '../services/firebase/firebase_service.dart';

class FishingNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();

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
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при добавлении заметки: $e');
      rethrow;
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
}