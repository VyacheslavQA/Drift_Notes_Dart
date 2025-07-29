// Путь: lib/repositories/fishing_note_repository.dart

import 'dart:convert';
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
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';
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
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingNoteModel>? _cachedNotes;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// Инициализация репозитория
  Future<void> initialize() async {
    try {
      await _isarService.init();
    } catch (e) {
      rethrow;
    }
  }

  /// Синхронизация офлайн данных при запуске
  Future<void> syncOfflineDataOnStartup() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        // Запускаем полную синхронизацию в фоне
        _syncService.fullSync().then((result) {
          if (result) {
            clearCache(); // Обновляем кэш после синхронизации
          }
        }).catchError((e) {
          // Игнорируем ошибки фоновой синхронизации
        });
      }
    } catch (e) {
      // Игнорируем ошибки синхронизации при запуске
    }
  }

  /// Получение всех заметок пользователя
  Future<List<FishingNoteModel>> getUserFishingNotes() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      // Проверяем кэш
      if (_cachedNotes != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          return _cachedNotes!;
        } else {
          clearCache();
        }
      }

      // ✅ ИСПРАВЛЕНО: Получаем данные из Isar с фильтрацией удаленных записей
      final isarNotes = await _isarService.getAllFishingNotes();

      // ✅ НОВОЕ: Фильтруем записи помеченные для удаления
      final activeNotes = isarNotes.where((entity) =>
      entity.markedForDeletion == null || entity.markedForDeletion == false
      ).toList();

      // Конвертируем в модели приложения
      final notes = activeNotes.map((entity) => _entityToModel(entity)).toList();

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
          // Игнорируем ошибки фоновой синхронизации
        });
      }

      return notes;
    } catch (e) {
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

      // Создаем копию заметки с установленным ID и UserID
      final noteToAdd = note.copyWith(id: noteId, userId: userId);

      // Обрабатываем фотографии
      List<String> photoUrls = [];
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline && photos != null && photos.isNotEmpty) {
        // Онлайн: загружаем фото в Firebase Storage
        for (var photo in photos) {
          try {
            final bytes = await photo.readAsBytes();
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
            final path = 'users/$userId/photos/$fileName';
            final url = await _firebaseService.uploadImage(path, bytes);
            photoUrls.add(url);
          } catch (e) {
            // Игнорируем ошибки загрузки отдельных фото
          }
        }
      } else if (photos != null && photos.isNotEmpty) {
        // Офлайн: сохраняем локальные копии
        photoUrls = await _localFileService.saveLocalCopies(photos);
      }

      final noteWithPhotos = noteToAdd.copyWith(photoUrls: photoUrls);

      // Конвертируем в Isar entity и сохраняем в Isar
      final entity = _modelToEntity(noteWithPhotos);
      entity.isSynced = false; // Помечаем как несинхронизированную
      entity.markedForDeletion = false; // ✅ НОВОЕ: Явно помечаем как не удаленную

      await _isarService.insertFishingNote(entity);

      // Если онлайн, запускаем синхронизацию
      if (isOnline) {
        _syncService.syncFishingNotesToFirebase().then((_) {
          // Синхронизация завершена
        }).catchError((e) {
          // Игнорируем ошибки фоновой синхронизации
        });
      }

      // Очищаем кэш
      clearCache();

      return noteId;
    } catch (e) {
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

      // Находим существующую запись в Isar
      final existingEntity = await _isarService.getFishingNoteByFirebaseId(note.id);
      if (existingEntity == null) {
        throw Exception('Заметка не найдена в локальной базе');
      }

      // ✅ НОВОЕ: Проверяем, что заметка не помечена для удаления
      if (existingEntity.markedForDeletion == true) {
        throw Exception('Нельзя обновлять удаленную заметку');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(note);
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = note.id; // Firebase ID
      updatedEntity.isSynced = false; // Помечаем как несинхронизированную
      updatedEntity.markedForDeletion = false; // ✅ НОВОЕ: Сохраняем статус не удаленной
      updatedEntity.updatedAt = DateTime.now();

      await _isarService.updateFishingNote(updatedEntity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingNotesToFirebase().then((_) {
          // Синхронизация обновления завершена
        }).catchError((e) {
          // Игнорируем ошибки фоновой синхронизации
        });
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Получение заметки по ID
  Future<FishingNoteModel> getFishingNoteById(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

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

      // ✅ НОВОЕ: Проверяем, что заметка не помечена для удаления
      if (entity.markedForDeletion == true) {
        throw Exception('Заметка была удалена');
      }

      return _entityToModel(entity);
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ ПОЛНОСТЬЮ ИСПРАВЛЕНО: Удаление заметки с поддержкой офлайн режима
  Future<void> deleteFishingNote(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      final isOnline = await NetworkUtils.isNetworkAvailable();
      bool deletionSuccessful = false;

      if (isOnline) {
        // ✅ ОНЛАЙН РЕЖИМ: Сразу удаляем из Firebase и Isar
        try {
          deletionSuccessful = await _syncService.deleteNoteByFirebaseId(noteId);

          if (deletionSuccessful) {
            debugPrint('✅ Онлайн удаление заметки $noteId успешно');
          } else {
            debugPrint('⚠️ Онлайн удаление заметки $noteId завершилось с ошибками');
          }
        } catch (e) {
          debugPrint('❌ Ошибка онлайн удаления заметки $noteId: $e');
          throw Exception('Не удалось удалить заметку: $e');
        }
      } else {
        // ✅ ОФЛАЙН РЕЖИМ: Помечаем для удаления, НЕ удаляем физически
        try {
          final entity = await _isarService.getFishingNoteByFirebaseId(noteId);
          if (entity == null) {
            throw Exception('Заметка не найдена в локальной базе');
          }

          // Помечаем как удаленную, но оставляем в базе для синхронизации
          entity.markedForDeletion = true;
          entity.updatedAt = DateTime.now();
          entity.isSynced = false; // Требует синхронизации удаления

          await _isarService.updateFishingNote(entity);
          deletionSuccessful = true;

          debugPrint('✅ Офлайн удаление: заметка $noteId помечена для удаления');
        } catch (e) {
          debugPrint('❌ Ошибка офлайн удаления заметки $noteId: $e');
          throw Exception('Не удалось пометить заметку для удаления: $e');
        }
      }

      // ✅ ВСЕГДА обновляем лимиты при успешном удалении
      if (deletionSuccessful) {
        try {
          await _subscriptionService.decrementUsage(ContentType.fishingNotes);
          debugPrint('✅ Лимит fishingNotes успешно уменьшен');
        } catch (e) {
          debugPrint('⚠️ Ошибка обновления лимита: $e');
          // Не прерываем выполнение, заметка уже удалена/помечена
        }

        // Очищаем кэш
        clearCache();
      }

    } catch (e) {
      debugPrint('❌ Критическая ошибка удаления заметки $noteId: $e');
      rethrow;
    }
  }

  /// Принудительная синхронизация
  Future<bool> forceSyncData() async {
    try {
      final result = await _syncService.fullSync();

      if (result) {
        // Очищаем кэш для обновления данных
        clearCache();
      }

      return result;
    } catch (e) {
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
      return {
        'total': 0,
        'synced': 0,
        'unsynced': 0,
        'hasInternet': false,
        'error': e.toString(),
      };
    }
  }

  /// Конвертация FishingNoteModel в FishingNoteEntity
  FishingNoteEntity _modelToEntity(FishingNoteModel model) {
    final entity = FishingNoteEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..title = model.title.isNotEmpty ? model.title : model.location
      ..date = model.date
      ..location = model.location
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..markedForDeletion = false; // ✅ НОВОЕ: По умолчанию не удалена

    // Сохраняем все основные поля
    entity.tackle = model.tackle;
    entity.fishingType = model.fishingType;
    entity.notes = model.notes;
    entity.latitude = model.latitude;
    entity.longitude = model.longitude;
    entity.photoUrls = model.photoUrls;

    // description как дополнительное поле (если notes пустые)
    if (model.notes.isNotEmpty) {
      entity.description = model.notes;
    }

    // Многодневные рыбалки
    entity.isMultiDay = model.isMultiDay;
    entity.endDate = model.endDate;

    // Маркеры карты как JSON
    if (model.mapMarkers.isNotEmpty) {
      try {
        entity.mapMarkersJson = jsonEncode(model.mapMarkers);
      } catch (e) {
        entity.mapMarkersJson = '[]';
      }
    }

    // Погодные данные с всеми полями
    if (model.weather != null) {
      entity.weatherData = WeatherDataEntity()
        ..temperature = model.weather!.temperature
        ..feelsLike = model.weather!.feelsLike
        ..humidity = model.weather!.humidity.toDouble()
        ..windSpeed = model.weather!.windSpeed
        ..windDirection = model.weather!.windDirection
        ..pressure = model.weather!.pressure
        ..cloudCover = model.weather!.cloudCover.toDouble()
        ..isDay = model.weather!.isDay
        ..sunrise = model.weather!.sunrise
        ..sunset = model.weather!.sunset
        ..condition = model.weather!.weatherDescription
        ..recordedAt = model.weather!.observationTime;
    }

    // Поклевки с ID и фото
    if (model.biteRecords.isNotEmpty) {
      entity.biteRecords = model.biteRecords.map((bite) {
        return BiteRecordEntity()
          ..biteId = bite.id
          ..time = bite.time
          ..fishType = bite.fishType
          ..baitUsed = ''
          ..success = bite.weight > 0
          ..fishWeight = bite.weight
          ..fishLength = bite.length
          ..notes = bite.notes
          ..photoUrls = bite.photoUrls
          ..dayIndex = bite.dayIndex      // ✅ ДОБАВИТЬ
          ..spotIndex = bite.spotIndex;   // ✅ ДОБАВИТЬ (точка с запятой только в конце!)
      }).toList();
    }

    // AI предсказание
    if (model.aiPrediction != null) {
      entity.aiPrediction = AiPredictionEntity()
        ..activityLevel = model.aiPrediction!['activityLevel']
        ..confidencePercent = model.aiPrediction!['confidencePercent']
        ..fishingType = model.aiPrediction!['fishingType']
        ..overallScore = model.aiPrediction!['overallScore']
        ..recommendation = model.aiPrediction!['recommendation']
        ..timestamp = model.aiPrediction!['timestamp'];

      // Кодируем советы в JSON
      if (model.aiPrediction!['tips'] != null) {
        try {
          entity.aiPrediction!.tipsJson = jsonEncode(model.aiPrediction!['tips']);
        } catch (e) {
          entity.aiPrediction!.tipsJson = '[]';
        }
      }
    }

    return entity;
  }

  /// Конвертация FishingNoteEntity в FishingNoteModel
  FishingNoteModel _entityToModel(FishingNoteEntity entity) {
    // Погодные данные со всеми полями
    FishingWeather? weather;
    if (entity.weatherData != null) {
      weather = FishingWeather(
        temperature: entity.weatherData!.temperature ?? 0.0,
        feelsLike: entity.weatherData!.feelsLike ?? entity.weatherData!.temperature ?? 0.0,
        humidity: entity.weatherData!.humidity?.toInt() ?? 0,
        pressure: entity.weatherData!.pressure ?? 0.0,
        windSpeed: entity.weatherData!.windSpeed ?? 0.0,
        windDirection: entity.weatherData!.windDirection ?? '',
        weatherDescription: entity.weatherData!.condition ?? '',
        cloudCover: entity.weatherData!.cloudCover?.toInt() ?? 0,
        moonPhase: '',
        observationTime: entity.weatherData!.recordedAt ?? DateTime.now(),
        sunrise: entity.weatherData!.sunrise ?? '',
        sunset: entity.weatherData!.sunset ?? '',
        isDay: entity.weatherData!.isDay,
      );
    }

    // Поклевки с ID и фото из Entity
    List<BiteRecord> biteRecords = [];
    if (entity.biteRecords.isNotEmpty) {
      biteRecords = entity.biteRecords.map((bite) {
        return BiteRecord(
          id: bite.biteId ?? const Uuid().v4(),
          time: bite.time ?? DateTime.now(),
          fishType: bite.fishType ?? '',
          weight: bite.fishWeight ?? 0.0,
          length: bite.fishLength ?? 0.0,
          notes: bite.notes ?? '',
          dayIndex: bite.dayIndex ?? 0,     // ✅ ИСПРАВЛЕНО
          spotIndex: bite.spotIndex ?? 0,   // ✅ ИСПРАВЛЕНО
          photoUrls: bite.photoUrls,
        );
      }).toList();
    }

    // Маркеры карты из JSON
    List<Map<String, dynamic>> mapMarkers = [];
    if (entity.mapMarkersJson != null && entity.mapMarkersJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.mapMarkersJson!);
        if (decoded is List) {
          mapMarkers = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        mapMarkers = [];
      }
    }

    // AI предсказание из Entity
    Map<String, dynamic>? aiPrediction;
    if (entity.aiPrediction != null) {
      List<String> tips = [];
      if (entity.aiPrediction!.tipsJson != null && entity.aiPrediction!.tipsJson!.isNotEmpty) {
        try {
          final decoded = jsonDecode(entity.aiPrediction!.tipsJson!);
          if (decoded is List) {
            tips = List<String>.from(decoded);
          }
        } catch (e) {
          tips = [];
        }
      }

      aiPrediction = {
        'activityLevel': entity.aiPrediction!.activityLevel ?? '',
        'confidencePercent': entity.aiPrediction!.confidencePercent ?? 0,
        'fishingType': entity.aiPrediction!.fishingType ?? '',
        'overallScore': entity.aiPrediction!.overallScore ?? 0,
        'recommendation': entity.aiPrediction!.recommendation ?? '',
        'timestamp': entity.aiPrediction!.timestamp ?? DateTime.now().millisecondsSinceEpoch,
        'tips': tips,
      };
    }

    return FishingNoteModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: _firebaseService.currentUserId ?? '',
      location: entity.location ?? '',

      // Все основные поля из Entity
      latitude: entity.latitude ?? 0.0,
      longitude: entity.longitude ?? 0.0,
      tackle: entity.tackle ?? '',
      fishingType: entity.fishingType ?? '',
      notes: entity.notes ?? entity.description ?? '',
      photoUrls: entity.photoUrls,

      date: entity.date,
      endDate: entity.endDate,
      isMultiDay: entity.isMultiDay,
      weather: weather,
      biteRecords: biteRecords,
      mapMarkers: mapMarkers,
      title: entity.title,
      aiPrediction: aiPrediction,

      // Поля которые есть только в старой модели
      dayBiteMaps: const {},
      fishingSpots: const ['Основная точка'],
      coverPhotoUrl: '',
      coverCropSettings: null,
      reminderEnabled: false,
      reminderType: ReminderType.none,
      reminderTime: null,
    );
  }

  /// Очистка кэша
  static void clearCache() {
    _cachedNotes = null;
    _cacheTimestamp = null;
  }

  /// Очистка всех локальных данных (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      await _isarService.clearAllData();
      clearCache();
    } catch (e) {
      rethrow;
    }
  }
}