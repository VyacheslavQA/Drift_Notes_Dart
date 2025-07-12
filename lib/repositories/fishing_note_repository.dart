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

  // 🔥 ИСПРАВЛЕНО: Улучшена надежность получения заметок
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ getUserFishingNotes: Пользователь не авторизован');
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📝 Запрос заметок для пользователя: $userId');

      // ВСЕГДА получаем офлайн заметки ПЕРВЫМИ
      final offlineNotes = await _getOfflineNotes(userId);
      debugPrint('📱 Офлайн заметок найдено: ${offlineNotes.length}');

      // Отображаем ID офлайн заметок для отладки
      for (var note in offlineNotes) {
        debugPrint('📱 Офлайн заметка: ${note.id} - ${note.location} (${note.date})');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      List<FishingNoteModel> onlineNotes = [];

      if (isOnline) {
        // === ОНЛАЙН РЕЖИМ: Загружаем ТОЛЬКО из новой структуры ===
        try {
          debugPrint('☁️ Загружаем заметки из НОВОЙ структуры: users/$userId/fishing_notes');

          final snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .get();

          // Преобразуем результаты в модели
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data.isNotEmpty) {
              final note = FishingNoteModel.fromJson(
                Map<String, dynamic>.from(data),
                id: doc.id,
              );
              onlineNotes.add(note);
              debugPrint('☁️ Онлайн заметка: ${note.id} - ${note.location}');

              // 🚨 ИСПРАВЛЕНИЕ: Автоматически кэшируем онлайн заметки для офлайн доступа
              try {
                final noteJson = note.toJson();
                noteJson['id'] = note.id;
                noteJson['isSynced'] = true; // Помечаем как синхронизированную
                noteJson['isOffline'] = false; // Это не чисто офлайн заметка
                _offlineStorage.saveOfflineNote(noteJson).catchError((error) {
                  debugPrint('⚠️ Ошибка кэширования заметки ${note.id}: $error');
                });
              } catch (cacheError) {
                debugPrint('⚠️ Ошибка кэширования заметки ${note.id}: $cacheError');
                // Не критично - продолжаем работу
              }
            }
          }

          debugPrint('☁️ Заметок из НОВОЙ структуры: ${onlineNotes.length}');
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении заметок из НОВОЙ структуры: $e');
          // Если ошибка - попробуем загрузить из кэша
          onlineNotes = await _getCachedOnlineNotesFromNewStructure(userId);
        }
      } else {
        // === ОФЛАЙН РЕЖИМ: Загружаем из кэша новой структуры ===
        debugPrint('📱 ОФЛАЙН РЕЖИМ: Загружаем кэшированные заметки из НОВОЙ структуры...');
        onlineNotes = await _getCachedOnlineNotesFromNewStructure(userId);
      }

      // Объединяем списки, избегая дубликатов
      final Map<String, FishingNoteModel> uniqueNotes = {};

      // Сначала добавляем онлайн заметки
      for (var note in onlineNotes) {
        uniqueNotes[note.id] = note;
        debugPrint('➕ Добавлена онлайн заметка: ${note.id}');
      }

      // Затем добавляем офлайн заметки, которых нет в онлайн списке
      for (var note in offlineNotes) {
        if (!uniqueNotes.containsKey(note.id)) {
          uniqueNotes[note.id] = note;
          debugPrint('➕ Добавлена уникальная офлайн заметка: ${note.id}');
        } else {
          debugPrint('⚠️ Офлайн заметка ${note.id} уже есть в онлайн списке, пропускаем');
        }
      }

      // Преобразуем обратно в список и сортируем по дате
      final allNotes = uniqueNotes.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      debugPrint('📊 ИТОГОВЫЙ РЕЗУЛЬТАТ:');
      debugPrint('📊 Онлайн заметок: ${onlineNotes.length}');
      debugPrint('📊 Офлайн заметок: ${offlineNotes.length}');
      debugPrint('📊 Всего уникальных заметок: ${allNotes.length}');

      // Выводим финальный список для отладки
      debugPrint('📋 ФИНАЛЬНЫЙ СПИСОК ЗАМЕТОК:');
      for (int i = 0; i < allNotes.length; i++) {
        final note = allNotes[i];
        debugPrint('📋 ${i + 1}. ${note.id} - ${note.location} (${note.date})');
      }

      // Принудительное обновление лимитов после загрузки заметок
      try {
        await _subscriptionService.refreshUsageLimits();
        debugPrint('✅ Лимиты обновлены после загрузки заметок');
      } catch (e) {
        debugPrint('⚠️ Ошибка обновления лимитов: $e');
      }

      // Запускаем синхронизацию в фоне только если онлайн
      if (isOnline) {
        _syncService.syncAll();
      }

      // ВАЖНО: Всегда возвращаем результат, даже если он пустой
      debugPrint('🎯 Возвращаем ${allNotes.length} заметок в UI');
      return allNotes;
    } catch (e) {
      debugPrint('❌ КРИТИЧЕСКАЯ ОШИБКА в getUserFishingNotes: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн заметки
      try {
        final userId = _firebaseService.currentUserId ?? '';
        debugPrint('🔄 Аварийное получение офлайн заметок для: $userId');
        final emergencyNotes = await _getOfflineNotes(userId);
        debugPrint('🆘 Аварийно получено ${emergencyNotes.length} офлайн заметок');
        return emergencyNotes;
      } catch (innerError) {
        debugPrint('💥 ПОЛНЫЙ ПРОВАЛ при получении заметок: $innerError');
        // Возвращаем пустой список вместо исключения, чтобы UI не сломался
        return [];
      }
    }
  }

  // 🔥 УЛУЧШЕНО: Более надежное получение кэшированных заметок
  Future<List<FishingNoteModel>> _getCachedOnlineNotesFromNewStructure(String userId) async {
    try {
      debugPrint('💾 Пытаемся получить кэшированные заметки из НОВОЙ структуры...');

      // Пытаемся получить заметки из локального кэша Firestore (новая структура)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_notes')
          .get(const GetOptions(source: Source.cache)); // Получаем из кэша

      final List<FishingNoteModel> cachedNotes = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.isNotEmpty) {
          try {
            final note = FishingNoteModel.fromJson(
              Map<String, dynamic>.from(data),
              id: doc.id,
            );
            cachedNotes.add(note);
            debugPrint('💾 Кэшированная заметка: ${note.id} - ${note.location}');
          } catch (e) {
            debugPrint('⚠️ Ошибка парсинга кэшированной заметки ${doc.id}: $e');
          }
        }
      }

      debugPrint('💾 Всего кэшированных заметок из НОВОЙ структуры: ${cachedNotes.length}');
      return cachedNotes;
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении кэшированных заметок из НОВОЙ структуры: $e');

      // Если и кэш недоступен, пытаемся найти сохраненные заметки в оффлайн хранилище
      return await _getSavedOnlineNotesFromOfflineStorage(userId);
    }
  }

  // УЛУЧШЕНО: Получение сохраненных онлайн заметок из офлайн хранилища
  Future<List<FishingNoteModel>> _getSavedOnlineNotesFromOfflineStorage(String userId) async {
    try {
      debugPrint('🔍 Ищем сохраненные онлайн заметки в офлайн хранилище...');

      // Получаем все заметки и фильтруем те, которые были синхронизированы
      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
      final List<FishingNoteModel> savedOnlineNotes = [];

      for (var noteData in allOfflineNotes) {
        try {
          final noteUserId = noteData['userId']?.toString() ?? '';
          final isSynced = noteData['isSynced'] ?? true; // Если поле отсутствует, считаем синхронизированной
          final isOfflineOnly = noteData['isOffline'] ?? false;

          // Берем заметки текущего пользователя, которые были синхронизированы (не чисто офлайн)
          if (noteUserId == userId && (isSynced || !isOfflineOnly)) {
            final noteId = noteData['id']?.toString() ?? '';
            if (noteId.isNotEmpty) {
              final note = FishingNoteModel.fromJson(noteData, id: noteId);
              savedOnlineNotes.add(note);
              debugPrint('💾 Найдена сохраненная онлайн заметка: ${note.id} - ${note.location}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка обработки сохраненной заметки: $e');
        }
      }

      debugPrint('💾 Всего сохраненных онлайн заметок: ${savedOnlineNotes.length}');
      return savedOnlineNotes;
    } catch (e) {
      debugPrint('⚠️ Ошибка при получении сохраненных онлайн заметок: $e');
      return [];
    }
  }

  // 🔥 ЗНАЧИТЕЛЬНО УЛУЧШЕНО: Получение офлайн заметок с детальной отладкой
  Future<List<FishingNoteModel>> _getOfflineNotes(String userId) async {
    try {
      debugPrint('📱 === НАЧАЛО ПОЛУЧЕНИЯ ОФЛАЙН ЗАМЕТОК ===');
      debugPrint('📱 Запрашиваемый userId: $userId');

      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      debugPrint('📱 Всего заметок в офлайн хранилище: ${offlineNotes.length}');

      final List<FishingNoteModel> result = [];
      int processedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      // Обрабатываем каждую заметку отдельно
      for (int index = 0; index < offlineNotes.length; index++) {
        try {
          final note = offlineNotes[index];
          processedCount++;

          final noteId = note['id']?.toString() ?? '';
          final noteUserId = note['userId']?.toString() ?? '';
          final isOffline = note['isOffline'] ?? false;
          final location = note['location']?.toString() ?? 'Без названия';

          debugPrint('📱 Обрабатываем заметку $processedCount/${ offlineNotes.length}:');
          debugPrint('   ID: $noteId');
          debugPrint('   UserId: $noteUserId');
          debugPrint('   IsOffline: $isOffline');
          debugPrint('   Location: $location');

          if (noteId.isEmpty) {
            debugPrint('   ❌ Пропускаем - нет ID');
            skippedCount++;
            continue;
          }

          // Проверяем принадлежность пользователю
          bool belongsToUser = false;

          if (noteUserId.isNotEmpty && noteUserId == userId) {
            belongsToUser = true;
            debugPrint('   ✅ Заметка принадлежит пользователю');
          } else if (noteUserId.isEmpty) {
            // Заметка без userId - добавляем userId и считаем принадлежащей текущему пользователю
            debugPrint('   🔧 Заметка без userId, добавляем: $userId');
            note['userId'] = userId;
            belongsToUser = true;

            // Асинхронно сохраняем исправленную заметку
            _offlineStorage.saveOfflineNote(note).catchError((error) {
              debugPrint('   ⚠️ Ошибка при исправлении заметки: $error');
            });
          } else {
            debugPrint('   ❌ Заметка принадлежит другому пользователю: $noteUserId');
            skippedCount++;
          }

          if (belongsToUser) {
            try {
              final noteModel = FishingNoteModel.fromJson(note, id: noteId);
              result.add(noteModel);
              debugPrint('   ✅ Заметка успешно добавлена в результат');
            } catch (e) {
              debugPrint('   ❌ Ошибка преобразования в модель: $e');
              errorCount++;
            }
          }

        } catch (e) {
          debugPrint('❌ Ошибка обработки заметки $processedCount: $e');
          errorCount++;
          continue;
        }
      }

      debugPrint('📱 === ИТОГИ ОБРАБОТКИ ОФЛАЙН ЗАМЕТОК ===');
      debugPrint('📱 Обработано: $processedCount');
      debugPrint('📱 Пропущено: $skippedCount');
      debugPrint('📱 Ошибок: $errorCount');
      debugPrint('📱 Добавлено в результат: ${result.length}');

      // Сортируем по дате
      result.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('📱 === ФИНАЛЬНЫЙ СПИСОК ОФЛАЙН ЗАМЕТОК ===');
      for (int i = 0; i < result.length; i++) {
        final note = result[i];
        debugPrint('📱 ${i + 1}. ${note.id} - ${note.location} (${note.date})');
      }

      return result;
    } catch (e) {
      debugPrint('💥 КРИТИЧЕСКАЯ ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  // 🔥 ИСПРАВЛЕНО: Добавление новой заметки ТОЛЬКО в новую структуру
  Future<String> addFishingNote(
      FishingNoteModel note,
      List<File>? photos,
      ) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ addFishingNote: Пользователь не авторизован');
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final noteId = note.id.isEmpty ? const Uuid().v4() : note.id;
      debugPrint('📝 Добавление заметки с ID: $noteId в НОВУЮ структуру');

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(id: noteId, userId: userId);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети при добавлении: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // Если есть интернет, загружаем фото и добавляем заметку в НОВУЮ структуру
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
        final noteWithPhotos = noteToAdd.copyWith(photoUrls: photoUrls);

        // 🔥 ДОБАВЛЯЕМ В НОВУЮ СТРУКТУРУ: users/$userId/fishing_notes
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .doc(noteId)
              .set(noteWithPhotos.toJson());

          debugPrint('✅ Заметка $noteId добавлена в НОВУЮ структуру: users/$userId/fishing_notes');

          // Сохраняем копию в офлайн хранилище как синхронизированную
          final noteJson = noteWithPhotos.toJson();
          noteJson['id'] = noteId;
          noteJson['isSynced'] = true; // Помечаем как синхронизированную
          noteJson['isOffline'] = false; // Это не чисто офлайн заметка
          await _offlineStorage.saveOfflineNote(noteJson);
          debugPrint('💾 Синхронизированная заметка сохранена в кэше');

          // Обновляем счетчики лимитов после успешного сохранения
          try {
            if (!_subscriptionService.hasPremiumAccess()) {
              await _subscriptionService.incrementUsage(ContentType.fishingNotes);
              debugPrint('✅ Счетчик лимитов увеличен для заметок');
            }

            // Принудительно обновляем лимиты
            await _subscriptionService.refreshUsageLimits();
            debugPrint('✅ Лимиты принудительно обновлены');
          } catch (e) {
            debugPrint('⚠️ Ошибка обновления лимитов: $e');
          }

          // Проверяем, есть ли офлайн заметки для отправки
          _syncService.syncAll();

          return noteId;
        } catch (e) {
          debugPrint('⚠️ Ошибка при добавлении заметки в НОВУЮ структуру: $e');

          // Если ошибка при добавлении в новую структуру, сохраняем заметку локально
          await _saveOfflineNote(noteWithPhotos, photos);

          // Обновляем лимиты даже для офлайн заметок
          try {
            if (!_subscriptionService.hasPremiumAccess()) {
              await _subscriptionService.incrementUsage(ContentType.fishingNotes);
              debugPrint('✅ Счетчик лимитов увеличен для офлайн заметки');
            }
          } catch (limitError) {
            debugPrint('⚠️ Ошибка обновления лимитов для офлайн заметки: $limitError');
          }

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
        final noteWithLocalPhotos = noteToAdd.copyWith(photoUrls: localPhotoUris);

        // Сохраняем заметку локально
        debugPrint('📱 Сохранение заметки в офлайн режиме');
        await _saveOfflineNote(noteWithLocalPhotos, photos);

        // Обновляем лимиты для офлайн заметок
        try {
          if (!_subscriptionService.hasPremiumAccess()) {
            await _subscriptionService.incrementUsage(ContentType.fishingNotes);
            debugPrint('✅ Счетчик лимитов увеличен для офлайн заметки');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка обновления лимитов для офлайн заметки: $e');
        }

        return noteId;
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // 🔥 УЛУЧШЕНО: Более надежное сохранение офлайн заметки
  Future<void> _saveOfflineNote(
      FishingNoteModel note,
      List<File>? photos,
      ) async {
    try {
      // Проверяем, что у заметки есть ID
      if (note.id.isEmpty) {
        debugPrint('⚠️ Попытка сохранить заметку без ID!');
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('📱 === СОХРАНЕНИЕ ОФЛАЙН ЗАМЕТКИ ===');
      debugPrint('📱 ID: ${note.id}');
      debugPrint('📱 Location: ${note.location}');
      debugPrint('📱 UserId: ${note.userId}');

      // Сохраняем заметку
      final noteJson = note.toJson();
      noteJson['id'] = note.id; // Явно добавляем ID в JSON
      noteJson['isSynced'] = false; // Помечаем как не синхронизированную
      noteJson['isOffline'] = true; // Это чисто офлайн заметка

      debugPrint('📱 Сохраняем JSON: $noteJson');
      await _offlineStorage.saveOfflineNote(noteJson);

      // Сохраняем пути к фотографиям
      if (photos != null && photos.isNotEmpty) {
        final photoPaths = photos.map((file) => file.path).toList();
        await _offlineStorage.saveOfflinePhotoPaths(note.id, photoPaths);
        debugPrint('📱 Сохранено ${photoPaths.length} путей к фото для заметки ${note.id}');
      }

      debugPrint('✅ Заметка ${note.id} успешно сохранена в офлайн режиме');

      // Проверим, что заметка действительно сохранилась
      try {
        final savedNotes = await _offlineStorage.getAllOfflineNotes();
        final savedNote = savedNotes.where((n) => n['id'] == note.id).firstOrNull;
        if (savedNote != null) {
          debugPrint('✅ Подтверждение: заметка ${note.id} найдена в хранилище');
        } else {
          debugPrint('⚠️ ВНИМАНИЕ: заметка ${note.id} НЕ найдена в хранилище после сохранения!');
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при проверке сохранения: $e');
      }
    } catch (e) {
      debugPrint('💥 КРИТИЧЕСКАЯ ошибка при сохранении заметки офлайн: $e');
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Обновление заметки ТОЛЬКО в новой структуре
  Future<void> updateFishingNote(FishingNoteModel note) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (note.id.isEmpty) {
        debugPrint('⚠️ Попытка обновить заметку без ID!');
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔄 Обновление заметки: ${note.id} в НОВОЙ структуре');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети при обновлении: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      // Всегда сначала сохраняем заметку локально
      final noteJson = note.toJson();
      noteJson['id'] = note.id;
      await _offlineStorage.saveOfflineNote(noteJson);
      debugPrint('📱 Заметка ${note.id} сохранена локально');

      if (isOnline) {
        // 🔥 ОБНОВЛЯЕМ В НОВОЙ СТРУКТУРЕ: users/$userId/fishing_notes
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .doc(note.id)
              .update(note.toJson());

          debugPrint('✅ Заметка ${note.id} обновлена в НОВОЙ структуре: users/$userId/fishing_notes');
        } catch (e) {
          debugPrint('⚠️ Ошибка при обновлении заметки в НОВОЙ структуре: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при обновлении заметки: $e');

      // В случае ошибки, пытаемся сохранить заметку локально
      try {
        final noteJson = note.toJson();
        noteJson['id'] = note.id;
        await _offlineStorage.saveOfflineNote(noteJson);
        debugPrint('📱 Заметка ${note.id} сохранена локально (после общей ошибки)');
      } catch (innerError) {
        debugPrint('❌ Критическая ошибка при сохранении обновления: $innerError');
        rethrow;
      }
    }
  }

  // 🔥 ИСПРАВЛЕНО: Получение заметки по ID ТОЛЬКО из новой структуры
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔍 Получение заметки по ID: $noteId из НОВОЙ структуры');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      if (isOnline) {
        // 🔥 ПОЛУЧАЕМ ИЗ НОВОЙ СТРУКТУРЫ: users/$userId/fishing_notes
        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .doc(noteId)
              .get();

          if (doc.exists) {
            // Получаем заметку из новой структуры
            final note = FishingNoteModel.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            );
            debugPrint('✅ Заметка $noteId получена из НОВОЙ структуры');

            // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Сохраняем копию в офлайн хранилище для последующего доступа
            try {
              final noteJson = note.toJson();
              noteJson['id'] = note.id;
              noteJson['isSynced'] = true; // Помечаем как синхронизированную
              noteJson['isOffline'] = false; // Это не чисто офлайн заметка
              await _offlineStorage.saveOfflineNote(noteJson);
              debugPrint('💾 Онлайн заметка $noteId кэширована в офлайн хранилище для будущего доступа');
            } catch (cacheError) {
              debugPrint('⚠️ Ошибка кэширования заметки: $cacheError');
              // Не критично - заметку всё равно возвращаем
            }

            return note;
          } else {
            debugPrint('⚠️ Заметка не найдена в НОВОЙ структуре, ищем в офлайн хранилище');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении заметки из НОВОЙ структуры: $e');
        }
      } else {
        debugPrint('📱 Офлайн режим: ищем заметку $noteId в офлайн хранилище');
      }

      // Если не нашли онлайн или нет интернета, ищем в офлайн хранилище
      return await _getOfflineNoteById(noteId);
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

  // 🔥 ИСПРАВЛЕНО: Удаление заметки ТОЛЬКО из новой структуры
  Future<void> deleteFishingNote(String noteId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🗑️ Удаление заметки: $noteId из НОВОЙ структуры');

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
        // 🔥 УДАЛЯЕМ ИЗ НОВОЙ СТРУКТУРЫ: users/$userId/fishing_notes
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('fishing_notes')
              .doc(noteId)
              .delete();

          debugPrint('✅ Заметка $noteId удалена из НОВОЙ структуры: users/$userId/fishing_notes');

          // Обновляем счетчики лимитов после успешного удаления
          try {
            if (!_subscriptionService.hasPremiumAccess()) {
              await _subscriptionService.decrementUsage(ContentType.fishingNotes);
              debugPrint('✅ Счетчик лимитов уменьшен для заметок');
            }

            // Принудительно обновляем лимиты
            await _subscriptionService.refreshUsageLimits();
            debugPrint('✅ Лимиты принудительно обновлены после удаления');
          } catch (e) {
            debugPrint('⚠️ Ошибка обновления лимитов при удалении: $e');
          }

          // Удаляем локальную копию
          try {
            await _offlineStorage.removeOfflineNote(noteId);
            debugPrint('📱 Локальная копия заметки $noteId удалена');
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении локальной копии заметки: $e');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении заметки из НОВОЙ структуры: $e');

          // Если ошибка при удалении из новой структуры, отмечаем для удаления
          await _offlineStorage.markForDeletion(noteId, false);
          debugPrint('📱 Заметка $noteId отмечена для удаления');

          // Обновляем лимиты даже если удаление из новой структуры не удалось
          try {
            if (!_subscriptionService.hasPremiumAccess()) {
              await _subscriptionService.decrementUsage(ContentType.fishingNotes);
              debugPrint('✅ Счетчик лимитов уменьшен (офлайн удаление)');
            }
          } catch (limitError) {
            debugPrint('⚠️ Ошибка обновления лимитов при офлайн удалении: $limitError');
          }

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

        // Обновляем лимиты при офлайн удалении
        try {
          if (!_subscriptionService.hasPremiumAccess()) {
            await _subscriptionService.decrementUsage(ContentType.fishingNotes);
            debugPrint('✅ Счетчик лимитов уменьшен (полный офлайн)');
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка обновления лимитов при полном офлайн удалении: $e');
        }

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

  // 🔥 УЛУЧШЕНО: Получение заметки из офлайн хранилища по ID
  Future<FishingNoteModel> _getOfflineNoteById(String noteId) async {
    try {
      debugPrint('📱 === ПОИСК ОФЛАЙН ЗАМЕТКИ ПО ID ===');
      debugPrint('📱 Ищем заметку с ID: $noteId');

      final allOfflineNotes = await _offlineStorage.getAllOfflineNotes();
      debugPrint('📱 Всего офлайн заметок в хранилище: ${allOfflineNotes.length}');

      // Ищем заметку по ID
      final noteDataList = allOfflineNotes.where((note) => note['id'] == noteId).toList();

      if (noteDataList.isEmpty) {
        debugPrint('❌ Заметка $noteId НЕ найдена в офлайн хранилище');

        // Выводим все ID для отладки
        debugPrint('📱 Доступные ID в хранилище:');
        for (var note in allOfflineNotes) {
          final id = note['id']?.toString() ?? 'НЕТ ID';
          final location = note['location']?.toString() ?? 'Без названия';
          debugPrint('   - $id ($location)');
        }

        throw Exception('Заметка не найдена в офлайн хранилище');
      }

      // Берем первую найденную заметку
      final noteData = noteDataList.first;
      debugPrint('✅ Заметка $noteId найдена в офлайн хранилище');
      debugPrint('📱 Данные заметки: ${noteData['location']} (${noteData['date']})');

      return FishingNoteModel.fromJson(noteData, id: noteId);
    } catch (e) {
      debugPrint('💥 КРИТИЧЕСКАЯ ошибка при получении заметки из офлайн хранилища: $e');
      rethrow;
    }
  }

  // Остальные методы для совместимости...
  Future<FishingNoteModel> updateFishingNoteWithPhotos(
      FishingNoteModel note,
      List<File> newPhotos,
      ) async {
    // Реализация обновления заметки с фото...
    // [Можно оставить как есть, но изменить пути к новой структуре]
    throw UnimplementedError('Метод будет реализован при необходимости');
  }

  Future<void> _saveOfflineNoteUpdate(
      FishingNoteModel note,
      List<File> newPhotos,
      ) async {
    // Реализация сохранения обновления...
    throw UnimplementedError('Метод будет реализован при необходимости');
  }

  Future<void> saveOfflineNoteUpdate(
      FishingNoteModel note,
      List<File> newPhotos,
      ) async {
    // Реализация сохранения обновления...
    throw UnimplementedError('Метод будет реализован при необходимости');
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