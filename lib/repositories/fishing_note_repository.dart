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
  static final FishingNoteRepository _instance = FishingNoteRepository._internal();

  factory FishingNoteRepository() {
    return _instance;
  }

  FishingNoteRepository._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalFileService _localFileService = LocalFileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // ✅ ДОБАВЛЕНО: Кэш для предотвращения повторных загрузок (как в BudgetNotesRepository)
  static List<FishingNoteModel>? _cachedNotes;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // ✅ ИСПРАВЛЕНО: Получение заметок с ПРАВИЛЬНЫМ кэшированием Firebase заметок
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ getUserFishingNotes: Пользователь не авторизован');
        return [];
      }

      debugPrint('📝 Загрузка заметок для пользователя: $userId');

      // ✅ ДОБАВЛЕНО: Проверяем кэш
      if (_cachedNotes != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Возвращаем заметки из кэша (возраст: ${cacheAge.inSeconds}с)');
          return _cachedNotes!;
        } else {
          debugPrint('💾 Кэш заметок устарел, очищаем');
          _cachedNotes = null;
          _cacheTimestamp = null;
        }
      }

      // Всегда получаем офлайн заметки первыми (теперь включает кэшированные)
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

          // 🔥 ИСПРАВЛЕНО: Используем ПРАВИЛЬНЫЙ метод кэширования
          if (onlineNotes.isNotEmpty) {
            try {
              debugPrint('💾 Кэшируем Firebase заметки через cacheFishingNotes...');
              final notesToCache = onlineNotes.map((note) {
                final noteJson = note.toJson();
                noteJson['id'] = note.id;
                noteJson['userId'] = userId;
                // 🔥 ДОБАВЛЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ для совместимости с кэшем
                noteJson['isSynced'] = true;   // Из Firebase - синхронизированы
                noteJson['isOffline'] = false; // Не офлайн заметки
                return noteJson;
              }).toList();

              await _offlineStorage.cacheFishingNotes(notesToCache);
              debugPrint('✅ ${onlineNotes.length} Firebase заметок кэшированы правильно');
            } catch (e) {
              debugPrint('⚠️ Ошибка кэширования Firebase заметок: $e');
              debugPrint('⚠️ Детали ошибки: ${e.toString()}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении заметок из Firebase: $e');
        }
      }

      // ✅ ИСПРАВЛЕНО: Объединяем списки правильно, избегая дубликатов
      final Map<String, FishingNoteModel> uniqueNotes = {};

      // Сначала добавляем онлайн заметки (приоритет)
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
      debugPrint('📊 Онлайн: ${onlineNotes.length}, Офлайн: ${offlineNotes.length}');

      // ✅ ДОБАВЛЕНО: Кэшируем результат
      _cachedNotes = allNotes;
      _cacheTimestamp = DateTime.now();

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        _syncService.syncAll();
      }

      return allNotes;
    } catch (e) {
      debugPrint('❌ Ошибка в getUserFishingNotes: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн заметки
      try {
        return await _getOfflineNotes(_firebaseService.currentUserId ?? '');
      } catch (_) {
        // В крайнем случае возвращаем пустой список
        return [];
      }
    }
  }

  // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Правильная загрузка без дублирования
  Future<List<FishingNoteModel>> _getOfflineNotes(String userId) async {
    try {
      final List<FishingNoteModel> result = [];
      final Set<String> processedIds = <String>{};

      debugPrint('📱 Загружаем кэшированные Firebase заметки...');

      // 1. ✅ ИСПРАВЛЕНО: Загружаем кэшированные Firebase заметки
      try {
        final cachedNotes = await _offlineStorage.getCachedFishingNotes();
        debugPrint('💾 Найдено кэшированных Firebase заметок: ${cachedNotes.length}');

        for (final noteData in cachedNotes) {
          try {
            final noteId = noteData['id']?.toString() ?? '';
            final noteUserId = noteData['userId']?.toString() ?? '';

            if (noteId.isEmpty) continue;

            // Проверяем принадлежность пользователю
            if (noteUserId == userId) {
              final noteModel = FishingNoteModel.fromJson(noteData, id: noteId);
              result.add(noteModel);
              processedIds.add(noteId);
              debugPrint('✅ Кэшированная заметка загружена: $noteId');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка обработки кэшированной заметки: $e');
            continue;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при загрузке кэшированных заметок: $e');
      }

      debugPrint('📱 Загружаем офлайн созданные заметки...');

      // 2. ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Загружаем ТОЛЬКО несинхронизированные офлайн заметки
      try {
        final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
        debugPrint('📱 Найдено офлайн созданных заметок: ${allOfflineNotes.length}');

        for (final note in allOfflineNotes) {
          try {
            final noteId = note['id']?.toString() ?? '';
            final noteUserId = note['userId']?.toString() ?? '';
            final isSynced = note['isSynced'] == true;
            final isOffline = note['isOffline'] == true;

            // ✅ ИСПРАВЛЕНО: Пропускаем уже обработанные заметки
            if (noteId.isEmpty || processedIds.contains(noteId)) {
              continue;
            }

            // ✅ ИСПРАВЛЕНО: Загружаем ТОЛЬКО несинхронизированные офлайн заметки
            if (!isSynced && isOffline) {
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
                processedIds.add(noteId);
                debugPrint('✅ Несинхронизированная офлайн заметка загружена: $noteId');
              }
            } else {
              debugPrint('⏭️ Пропускаем синхронизированную заметку: $noteId (isSynced: $isSynced, isOffline: $isOffline)');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка обработки офлайн заметки: $e');
            continue;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при загрузке офлайн заметок: $e');
      }

      // Сортируем по дате
      result.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ Всего заметок загружено из офлайн источников: ${result.length}');

      return result;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  // ✅ ИСПРАВЛЕНО: Добавление заметки с правильным кэшированием
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

          // 🔥 ИСПРАВЛЕНО: Кэшируем через ПРАВИЛЬНЫЙ метод
          try {
            final noteJson = noteWithPhotos.toJson();
            noteJson['id'] = noteId;
            noteJson['userId'] = userId;
            // 🔥 ДОБАВЛЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ
            noteJson['isSynced'] = true;   // Синхронизирована с Firebase
            noteJson['isOffline'] = false; // Не офлайн заметка

            // Кэшируем в общий кэш Firebase заметок
            await _offlineStorage.cacheFishingNotes([noteJson]);
            debugPrint('💾 Новая заметка кэширована правильно');
          } catch (e) {
            debugPrint('⚠️ Ошибка кэширования новой заметки: $e');
          }

          // ✅ УПРОЩЕНО: Увеличиваем счетчик ТОЛЬКО один раз
          try {
            await _firebaseService.incrementUsageCount('notesCount');
            debugPrint('✅ Счетчик увеличен через Firebase');
          } catch (e) {
            debugPrint('⚠️ Ошибка увеличения счетчика: $e');
          }

          // ✅ ДОБАВЛЕНО: Очищаем кэш после создания новой заметки
          clearCache();

          return noteId;
        } catch (e) {
          debugPrint('⚠️ Ошибка при сохранении в Firebase: $e');
          // Если ошибка - сохраняем локально
          await _saveOfflineNote(noteWithPhotos, photos);

          // ✅ ДОБАВЛЕНО: Очищаем кэш после создания новой заметки
          clearCache();

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

        // ✅ ДОБАВЛЕНО: Очищаем кэш после создания новой заметки
        clearCache();

        return noteId;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // ✅ ИСПРАВЛЕНО: Сохранение офлайн заметки с правильными флагами
  Future<void> _saveOfflineNote(
      FishingNoteModel note,
      List<File>? photos,
      ) async {
    try {
      if (note.id.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('📱 Сохранение офлайн заметки: ${note.id}');

      // ✅ ИСПРАВЛЕНО: Устанавливаем правильные флаги для офлайн заметки
      final noteJson = note.toJson();
      noteJson['id'] = note.id;
      noteJson['userId'] = note.userId;
      noteJson['isSynced'] = false;  // Требует синхронизации
      noteJson['isOffline'] = true;  // Создана офлайн
      noteJson['offlineCreatedAt'] = DateTime.now().toIso8601String();

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

  // ✅ ИСПРАВЛЕНО: Обновление заметки с правильным кэшированием
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

      // ✅ ИСПРАВЛЕНО: Правильные флаги для обновления
      final noteJson = note.toJson();
      noteJson['id'] = note.id;
      noteJson['userId'] = userId;
      noteJson['isSynced'] = false;  // Требует синхронизации
      noteJson['isOffline'] = false; // Обновлена, но не создана офлайн
      noteJson['updatedAt'] = DateTime.now().toIso8601String();

      // Всегда сначала сохраняем локально
      await _offlineStorage.saveOfflineNote(noteJson);

      // Если онлайн - пытаемся обновить в Firebase
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        try {
          await _firebaseService.updateFishingNoteNew(note.id, note.toJson());
          debugPrint('✅ Заметка обновлена в Firebase');

          // 🔥 ИСПРАВЛЕНО: Обновляем в ПРАВИЛЬНОМ кэше
          try {
            noteJson['userId'] = userId;
            noteJson['isSynced'] = true;   // Синхронизирована
            noteJson['isOffline'] = false; // Не офлайн заметка

            // Обновляем в общем кэше Firebase заметок
            await _offlineStorage.cacheFishingNotes([noteJson]);

            // Также обновляем в офлайн хранилище
            await _offlineStorage.saveOfflineNote(noteJson);

            debugPrint('💾 Заметка обновлена в кэше правильно');
          } catch (e) {
            debugPrint('⚠️ Ошибка обновления в кэше: $e');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении в Firebase: $e');
        }
      }

      // ✅ ДОБАВЛЕНО: Очищаем кэш после обновления заметки
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки: $e');
      rethrow;
    }
  }

  /// 🔥 ИСПРАВЛЕНО: Получение заметки по ID с ПРАВИЛЬНЫМ порядком поиска
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

      // 🔥 ИСПРАВЛЕНО: ШАГ 1 - СНАЧАЛА ищем в кэшированных Firebase заметках
      try {
        debugPrint('🔍 Ищем в кэшированных Firebase заметках...');
        final cachedNotes = await _offlineStorage.getCachedFishingNotes();
        final cachedNote = cachedNotes.where((note) => note['id'] == noteId).firstOrNull;

        if (cachedNote != null) {
          debugPrint('✅ Заметка найдена в кэше Firebase заметок');
          return FishingNoteModel.fromJson(cachedNote, id: noteId);
        } else {
          debugPrint('⚠️ Заметка НЕ найдена в кэше Firebase заметок');
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка поиска в кэше Firebase заметок: $e');
      }

      // 🔥 ИСПРАВЛЕНО: ШАГ 2 - Если не найдена в кэше, ищем в Firebase онлайн
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        try {
          debugPrint('🔍 Ищем в Firebase онлайн...');
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

            // 🔥 ИСПРАВЛЕНО: Кэшируем полученную заметку через ПРАВИЛЬНЫЙ метод
            try {
              final noteJson = note.toJson();
              noteJson['id'] = note.id;
              noteJson['userId'] = userId;
              noteJson['isSynced'] = true;   // Из Firebase
              noteJson['isOffline'] = false; // Не офлайн заметка

              // Кэшируем в общий кэш Firebase заметок
              await _offlineStorage.cacheFishingNotes([noteJson]);

              // Также сохраняем в офлайн хранилище
              await _offlineStorage.saveOfflineNote(noteJson);

              debugPrint('✅ Заметка найдена в Firebase и кэширована правильно: $noteId');
            } catch (e) {
              debugPrint('⚠️ Ошибка кэширования полученной заметки: $e');
            }

            return note;
          } else {
            debugPrint('⚠️ Заметка НЕ найдена в Firebase: $noteId');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении из Firebase: $e');
        }
      } else {
        debugPrint('📱 Офлайн режим: пропускаем поиск в Firebase');
      }

      // 🔥 ИСПРАВЛЕНО: ШАГ 3 - В конце ищем в офлайн хранилище
      debugPrint('🔍 Ищем в офлайн хранилище...');
      return await _getOfflineNoteByIdFromStorage(noteId);

    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки: $e');
      rethrow;
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Поиск ТОЛЬКО в офлайн хранилище (без кэша Firebase)
  Future<FishingNoteModel> _getOfflineNoteByIdFromStorage(String noteId) async {
    try {
      debugPrint('🔍 Поиск в офлайн хранилище заметок...');

      // Ищем ТОЛЬКО в офлайн заметках (не в кэше Firebase)
      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
      final noteDataList = allOfflineNotes.where((note) => note['id'] == noteId).toList();

      if (noteDataList.isEmpty) {
        throw Exception('Заметка не найдена ни в кэше, ни в Firebase, ни в офлайн хранилище');
      }

      final noteData = noteDataList.first;
      debugPrint('✅ Заметка найдена в офлайн хранилище');
      return FishingNoteModel.fromJson(noteData, id: noteId);
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки из офлайн хранилища: $e');
      rethrow;
    }
  }

  // ✅ ИСПРАВЛЕННЫЙ метод deleteFishingNote() с правильным удалением из кэша
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

          // 🔥 ИСПРАВЛЕНО: Удаляем из кэша Firebase заметок ПРАВИЛЬНО
          try {
            debugPrint('🔍 Удаляем заметку $noteId из кэша Firebase заметок...');

            final cachedNotes = await _offlineStorage.getCachedFishingNotes();
            debugPrint('🔍 Всего заметок в кэше: ${cachedNotes.length}');

            // ✅ ПРАВИЛЬНАЯ фильтрация
            final updatedCachedNotes = cachedNotes.where((note) => note['id']?.toString() != noteId).toList();

            debugPrint('🔍 После фильтрации: ${updatedCachedNotes.length} заметок');

            // Сохраняем обновленный кэш
            await _offlineStorage.cacheFishingNotes(updatedCachedNotes);
            debugPrint('✅ Заметка удалена из кэша Firebase заметок (было: ${cachedNotes.length}, стало: ${updatedCachedNotes.length})');

          } catch (e) {
            debugPrint('⚠️ Ошибка удаления из кэша Firebase заметок: $e');
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

      // ✅ ДОБАВЛЕНО: Очищаем кэш после удаления заметки
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки: $e');
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

  // ✅ ДОБАВЛЕНО: Очистить кеш данных (как в BudgetNotesRepository)
  static void clearCache() {
    _cachedNotes = null;
    _cacheTimestamp = null;
    debugPrint('💾 Кэш заметок рыбалки очищен');
  }
}