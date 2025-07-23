// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/fishing_note_model.dart';
import '../models/isar/fishing_note_entity.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/firebase/firebase_service.dart';
import '../services/local/local_file_service.dart';
import '../utils/network_utils.dart';
import '../services/calendar_event_service.dart';

class FishingNoteRepository {
  static final FishingNoteRepository _instance = FishingNoteRepository._internal();

  factory FishingNoteRepository() {
    return _instance;
  }

  FishingNoteRepository._internal();

  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final LocalFileService _localFileService = LocalFileService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingNoteModel>? _cachedNotes;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// Инициализация репозитория
  Future<void> initialize() async {
    try {
      await _isarService.init();
      debugPrint('✅ FishingNoteRepository инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации FishingNoteRepository: $e');
      rethrow;
    }
  }

  /// ✅ НОВЫЙ МЕТОД: Синхронизация офлайн данных при запуске
  Future<void> syncOfflineDataOnStartup() async {
    try {
      debugPrint('🔄 Синхронизация офлайн данных при запуске');

      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        // Запускаем полную синхронизацию в фоне
        _syncService.fullSync().then((result) {
          if (result) {
            debugPrint('✅ Синхронизация при запуске завершена успешно');
            clearCache(); // Обновляем кэш после синхронизации
          } else {
            debugPrint('⚠️ Синхронизация при запуске завершена с ошибками');
          }
        }).catchError((e) {
          debugPrint('❌ Ошибка синхронизации при запуске: $e');
        });
      } else {
        debugPrint('📱 Офлайн режим - синхронизация пропущена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка в syncOfflineDataOnStartup: $e');
    }
  }

  /// Получение всех заметок пользователя
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ getUserFishingNotes: Пользователь не авторизован');
        return [];
      }

      debugPrint('📝 Загрузка заметок для пользователя: $userId');

      // Проверяем кэш
      if (_cachedNotes != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Возвращаем заметки из кэша (возраст: ${cacheAge.inSeconds}с)');
          return _cachedNotes!;
        } else {
          debugPrint('💾 Кэш заметок устарел, очищаем');
          clearCache();
        }
      }

      // Получаем данные из Isar (локальная БД)
      final isarNotes = await _isarService.getAllFishingNotes();
      debugPrint('📱 Найдено заметок в Isar: ${isarNotes.length}');

      // Конвертируем в модели приложения
      final notes = isarNotes.map((entity) => _entityToModel(entity)).toList();

      // Кэшируем результат
      _cachedNotes = notes;
      _cacheTimestamp = DateTime.now();

      // Запускаем синхронизацию в фоне, если есть интернет
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingNotesFromFirebase().then((_) {
          // После синхронизации обновляем кэш
          clearCache();
        }).catchError((e) {
          debugPrint('⚠️ Ошибка фоновой синхронизации: $e');
        });
      }

      debugPrint('📊 Итого заметок возвращено: ${notes.length}');
      return notes;
    } catch (e) {
      debugPrint('❌ Ошибка в getUserFishingNotes: $e');
      return [];
    }
  }

  /// Создание новой заметки
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
      debugPrint('📝 Создание заметки с ID: $noteId');

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(id: noteId, userId: userId);

      // Обрабатываем фотографии
      List<String> photoUrls = [];
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline && photos != null && photos.isNotEmpty) {
        // Онлайн: загружаем фото в Firebase Storage
        debugPrint('🖼️ Загрузка ${photos.length} фото в Firebase Storage');
        for (var photo in photos) {
          try {
            final bytes = await photo.readAsBytes();
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
            final path = 'users/$userId/photos/$fileName';
            final url = await _firebaseService.uploadImage(path, bytes);
            photoUrls.add(url);
          } catch (e) {
            debugPrint('⚠️ Ошибка загрузки фото: $e');
          }
        }
      } else if (photos != null && photos.isNotEmpty) {
        // Офлайн: сохраняем локальные копии
        debugPrint('📱 Сохранение ${photos.length} фото локально');
        photoUrls = await _localFileService.saveLocalCopies(photos);
      }

      final noteWithPhotos = noteToAdd.copyWith(photoUrls: photoUrls);

      // Конвертируем в Isar entity и сохраняем в Isar
      final entity = _modelToEntity(noteWithPhotos);
      entity.isSynced = false; // Помечаем как несинхронизированную

      await _isarService.insertFishingNote(entity);
      debugPrint('✅ Заметка сохранена в Isar');

      // Если онлайн, запускаем синхронизацию
      if (isOnline) {
        _syncService.syncFishingNotesToFirebase().then((_) {
          debugPrint('✅ Синхронизация с Firebase завершена');
        }).catchError((e) {
          debugPrint('⚠️ Ошибка синхронизации с Firebase: $e');
        });
      }

      // Очищаем кэш
      clearCache();

      return noteId;
    } catch (e) {
      debugPrint('❌ Ошибка при создании заметки: $e');
      rethrow;
    }
  }

  /// Обновление существующей заметки
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

      // Находим существующую запись в Isar
      final existingEntity = await _isarService.getFishingNoteByFirebaseId(note.id);
      if (existingEntity == null) {
        throw Exception('Заметка не найдена в локальной базе');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(note);
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = note.id; // Firebase ID
      updatedEntity.isSynced = false; // Помечаем как несинхронизированную
      updatedEntity.updatedAt = DateTime.now();

      await _isarService.updateFishingNote(updatedEntity);
      debugPrint('✅ Заметка обновлена в Isar');

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingNotesToFirebase().then((_) {
          debugPrint('✅ Синхронизация обновления с Firebase завершена');
        }).catchError((e) {
          debugPrint('⚠️ Ошибка синхронизации обновления: $e');
        });
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки: $e');
      rethrow;
    }
  }

  /// Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      debugPrint('🔍 Получение заметки по ID: $noteId');

      // Сначала ищем по Firebase ID
      FishingNoteEntity? entity = await _isarService.getFishingNoteByFirebaseId(noteId);

      // Если не найдена, пробуем найти по локальному ID
      if (entity == null) {
        final localId = int.tryParse(noteId);
        if (localId != null) {
          entity = await _isarService.getFishingNoteById(localId);
        }
      }

      if (entity == null) {
        throw Exception('Заметка не найдена');
      }

      debugPrint('✅ Заметка найдена в Isar');
      return _entityToModel(entity);
    } catch (e) {
      debugPrint('❌ Ошибка при получении заметки: $e');
      rethrow;
    }
  }

  /// Удаление заметки
  Future<void> deleteFishingNote(String noteId) async {
    try {
      debugPrint('🗑️ Удаление заметки: $noteId');

      // 🔥 ИСПОЛЬЗУЕМ НОВЫЙ МЕТОД: Удаление по Firebase ID
      final result = await _syncService.deleteNoteByFirebaseId(noteId);

      if (result) {
        debugPrint('✅ Заметка удалена успешно');
      } else {
        debugPrint('⚠️ Удаление выполнено с предупреждениями');
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки: $e');
      rethrow;
    }
  }

  /// Принудительная синхронизация
  Future<bool> forceSyncData() async {
    try {
      debugPrint('🔄 Принудительная синхронизация данных');
      final result = await _syncService.fullSync();

      if (result) {
        // Очищаем кэш для обновления данных
        clearCache();
        debugPrint('✅ Принудительная синхронизация завершена успешно');
      } else {
        debugPrint('⚠️ Принудительная синхронизация завершена с ошибками');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Ошибка принудительной синхронизации: $e');
      return false;
    }
  }

  /// Получение статуса синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final syncStatus = await _syncService.getSyncStatus();
      final fishingStatus = syncStatus['fishingNotes'] as Map<String, dynamic>? ?? {};

      return {
        'total': fishingStatus['total'] ?? 0,
        'synced': fishingStatus['synced'] ?? 0,
        'unsynced': fishingStatus['unsynced'] ?? 0,
        'hasInternet': await NetworkUtils.isNetworkAvailable(),
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения статуса синхронизации: $e');
      return {
        'total': 0,
        'synced': 0,
        'unsynced': 0,
        'hasInternet': false,
        'error': e.toString(),
      };
    }
  }

  /// ✅ ИСПРАВЛЕНО: Конвертация FishingNoteModel в FishingNoteEntity
  FishingNoteEntity _modelToEntity(FishingNoteModel model) {
    final entity = FishingNoteEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..title = model.title.isNotEmpty ? model.title : model.location // Если title пустой, используем location
      ..date = model.date
      ..location = model.location
      ..createdAt = DateTime.now() // У старой модели нет createdAt
      ..updatedAt = DateTime.now();

    // ✅ ИСПРАВЛЕНО: description = notes из старой модели
    if (model.notes.isNotEmpty) {
      entity.description = model.notes;
    }

    // ✅ ИСПРАВЛЕНО: Конвертируем погодные данные с правильными полями
    if (model.weather != null) {
      entity.weatherData = WeatherDataEntity()
        ..temperature = model.weather!.temperature
        ..humidity = model.weather!.humidity.toDouble()
        ..windSpeed = model.weather!.windSpeed
        ..windDirection = model.weather!.windDirection
        ..pressure = model.weather!.pressure
        ..condition = model.weather!.weatherDescription // weatherDescription -> condition
        ..recordedAt = model.weather!.observationTime;
    }

    // ✅ ИСПРАВЛЕНО: Конвертируем записи о поклевках с правильными полями
    if (model.biteRecords.isNotEmpty) {
      entity.biteRecords = model.biteRecords.map((bite) {
        return BiteRecordEntity()
          ..time = bite.time
          ..fishType = bite.fishType
          ..baitUsed = '' // У старой модели нет baitUsed, ставим пустую строку
          ..success = bite.weight > 0 // Считаем успешной, если есть вес рыбы
          ..fishWeight = bite.weight
          ..fishLength = bite.length
          ..notes = bite.notes;
      }).toList();
    }

    return entity;
  }

  /// ✅ ИСПРАВЛЕНО: Конвертация FishingNoteEntity в FishingNoteModel
  FishingNoteModel _entityToModel(FishingNoteEntity entity) {
    // Конвертируем погодные данные
    FishingWeather? weather;
    if (entity.weatherData != null) {
      weather = FishingWeather(
        temperature: entity.weatherData!.temperature ?? 0.0,
        feelsLike: entity.weatherData!.temperature ?? 0.0, // Используем temperature
        humidity: entity.weatherData!.humidity?.toInt() ?? 0,
        pressure: entity.weatherData!.pressure ?? 0.0,
        windSpeed: entity.weatherData!.windSpeed ?? 0.0,
        windDirection: entity.weatherData!.windDirection ?? '',
        weatherDescription: entity.weatherData!.condition ?? '', // condition -> weatherDescription
        cloudCover: 0, // У Entity нет cloudCover
        moonPhase: '', // У Entity нет moonPhase
        observationTime: entity.weatherData!.recordedAt ?? DateTime.now(),
        sunrise: '', // У Entity нет sunrise
        sunset: '', // У Entity нет sunset
        isDay: true, // По умолчанию день
      );
    }

    // Конвертируем записи о поклевках
    List<BiteRecord> biteRecords = [];
    if (entity.biteRecords.isNotEmpty) {
      biteRecords = entity.biteRecords.map((bite) {
        return BiteRecord(
          id: const Uuid().v4(), // Генерируем ID для старой модели
          time: bite.time ?? DateTime.now(),
          fishType: bite.fishType ?? '',
          weight: bite.fishWeight ?? 0.0, // fishWeight -> weight
          length: bite.fishLength ?? 0.0, // fishLength -> length
          notes: bite.notes ?? '',
          dayIndex: 0, // У Entity нет dayIndex
          spotIndex: 0, // У Entity нет spotIndex
          photoUrls: [], // У Entity нет photoUrls для bite records
        );
      }).toList();
    }

    return FishingNoteModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: _firebaseService.currentUserId ?? '',
      location: entity.location ?? '',
      latitude: 0.0, // У Entity нет latitude
      longitude: 0.0, // У Entity нет longitude
      date: entity.date,
      endDate: null, // У Entity нет endDate
      isMultiDay: false, // У Entity нет isMultiDay
      tackle: '', // У Entity нет tackle
      notes: entity.description ?? '', // description -> notes
      photoUrls: [], // TODO: Реализовать получение URL фотографий
      fishingType: '', // У Entity нет fishingType
      weather: weather,
      biteRecords: biteRecords,
      dayBiteMaps: const {}, // У Entity нет dayBiteMaps
      fishingSpots: const ['Основная точка'], // У Entity нет fishingSpots
      mapMarkers: const [], // У Entity нет mapMarkers
      coverPhotoUrl: '', // У Entity нет coverPhotoUrl
      coverCropSettings: null, // У Entity нет coverCropSettings
      title: entity.title,
      aiPrediction: null, // У Entity нет aiPrediction
      reminderEnabled: false, // У Entity нет reminderEnabled
      reminderType: ReminderType.none, // У Entity нет reminderType
      reminderTime: null, // У Entity нет reminderTime
    );
  }

  /// Очистка кэша
  static void clearCache() {
    _cachedNotes = null;
    _cacheTimestamp = null;
    debugPrint('💾 Кэш заметок рыбалки очищен');
  }

  /// Очистка всех локальных данных (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      await _isarService.clearAllData();
      clearCache();
      debugPrint('✅ Все локальные данные очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки локальных данных: $e');
      rethrow;
    }
  }
}