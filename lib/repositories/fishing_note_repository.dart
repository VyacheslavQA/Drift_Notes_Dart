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
import '../services/subscription/subscription_service.dart'; // ✅ ДОБАВЛЕНО
import '../constants/subscription_constants.dart'; // ✅ ДОБАВЛЕНО
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
  final SubscriptionService _subscriptionService = SubscriptionService(); // ✅ ДОБАВЛЕНО

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

  /// Синхронизация офлайн данных при запуске
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

      // ✅ ИСПРАВЛЕНО: Конвертируем в Isar entity и сохраняем в Isar
      final entity = _modelToEntity(noteWithPhotos);
      entity.isSynced = false; // Помечаем как несинхронизированную
      // ❌ УБРАНО: entity.userId = userId; (у FishingNoteEntity нет поля userId)

      await _isarService.insertFishingNote(entity);
      debugPrint('✅ Заметка сохранена в Isar с ID: ${entity.id}, firebaseId: ${entity.firebaseId}, isSynced: ${entity.isSynced}');

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

  /// ✅ ИСПРАВЛЕНО: Удаление заметки с обновлением лимитов
  Future<void> deleteFishingNote(String noteId) async {
    try {
      debugPrint('🗑️ Удаление заметки: $noteId');

      // 1. Удаляем через SyncService (Firebase + Isar)
      final result = await _syncService.deleteNoteByFirebaseId(noteId);

      if (result) {
        // 2. ✅ ДОБАВЛЕНО: Уменьшаем лимит через SubscriptionService
        try {
          await _subscriptionService.decrementUsage(ContentType.fishingNotes);
          debugPrint('✅ Заметка удалена успешно и лимит обновлен');
        } catch (e) {
          debugPrint('⚠️ Ошибка обновления лимита после удаления: $e');
          // Не прерываем выполнение, заметка уже удалена
        }
      } else {
        debugPrint('⚠️ Удаление выполнено с предупреждениями');
      }

      // 3. Очищаем кэш
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

  /// ✅ ПОЛНОСТЬЮ ИСПРАВЛЕНО: Конвертация FishingNoteModel в FishingNoteEntity
  FishingNoteEntity _modelToEntity(FishingNoteModel model) {
    final entity = FishingNoteEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId  // 🔥 КРИТИЧНО ДОБАВЛЕНО: заполняем userId!
      ..title = model.title.isNotEmpty ? model.title : model.location
      ..date = model.date
      ..location = model.location
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    // ✅ ИСПРАВЛЕНО: Сохраняем ВСЕ основные поля
    entity.tackle = model.tackle;
    entity.fishingType = model.fishingType;
    entity.notes = model.notes;
    entity.latitude = model.latitude;
    entity.longitude = model.longitude;
    entity.photoUrls = model.photoUrls;

    // ✅ ИСПРАВЛЕНО: description как дополнительное поле (если notes пустые)
    if (model.notes.isNotEmpty) {
      entity.description = model.notes;
    }

    // ✅ ИСПРАВЛЕНО: Многодневные рыбалки
    entity.isMultiDay = model.isMultiDay;
    entity.endDate = model.endDate;

    // ✅ ИСПРАВЛЕНО: Маркеры карты как JSON (model.mapMarkers уже Map)
    if (model.mapMarkers.isNotEmpty) {
      try {
        entity.mapMarkersJson = jsonEncode(model.mapMarkers);
      } catch (e) {
        debugPrint('❌ Ошибка кодирования mapMarkers: $e');
        entity.mapMarkersJson = '[]';
      }
    }

    // ✅ ИСПРАВЛЕНО: Погодные данные с ВСЕМИ полями
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

    // ✅ ИСПРАВЛЕНО: Поклевки с ID и фото
    if (model.biteRecords.isNotEmpty) {
      entity.biteRecords = model.biteRecords.map((bite) {
        return BiteRecordEntity()
          ..biteId = bite.id
          ..time = bite.time
          ..fishType = bite.fishType
          ..baitUsed = '' // У старой модели нет baitUsed
          ..success = bite.weight > 0
          ..fishWeight = bite.weight
          ..fishLength = bite.length
          ..notes = bite.notes
          ..photoUrls = bite.photoUrls;
      }).toList();
    }

    // ✅ НОВОЕ: AI предсказание (model.aiPrediction это Map<String, dynamic>?)
    if (model.aiPrediction != null) {
      entity.aiPrediction = AiPredictionEntity()
        ..activityLevel = model.aiPrediction!['activityLevel']
        ..confidencePercent = model.aiPrediction!['confidencePercent']
        ..fishingType = model.aiPrediction!['fishingType']
        ..overallScore = model.aiPrediction!['overallScore']
        ..recommendation = model.aiPrediction!['recommendation']
        ..timestamp = model.aiPrediction!['timestamp'];

      // Кодируем советы в JSON (tips это List)
      if (model.aiPrediction!['tips'] != null) {
        try {
          entity.aiPrediction!.tipsJson = jsonEncode(model.aiPrediction!['tips']);
        } catch (e) {
          debugPrint('❌ Ошибка кодирования AI tips: $e');
          entity.aiPrediction!.tipsJson = '[]';
        }
      }
    }

    return entity;
  }

  /// ✅ ПОЛНОСТЬЮ ИСПРАВЛЕНО: Конвертация FishingNoteEntity в FishingNoteModel
  FishingNoteModel _entityToModel(FishingNoteEntity entity) {
    // ✅ ИСПРАВЛЕНО: Погодные данные со ВСЕМИ полями
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
        moonPhase: '', // У Entity нет moonPhase
        observationTime: entity.weatherData!.recordedAt ?? DateTime.now(),
        sunrise: entity.weatherData!.sunrise ?? '',
        sunset: entity.weatherData!.sunset ?? '',
        isDay: entity.weatherData!.isDay,
      );
    }

    // ✅ ИСПРАВЛЕНО: Поклевки с ID и фото из Entity
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
          dayIndex: 0, // У Entity нет dayIndex
          spotIndex: 0, // У Entity нет spotIndex
          photoUrls: bite.photoUrls,
        );
      }).toList();
    }

    // ✅ ИСПРАВЛЕНО: Маркеры карты из JSON (возвращаем как List<Map<String, dynamic>>)
    List<Map<String, dynamic>> mapMarkers = [];
    if (entity.mapMarkersJson != null && entity.mapMarkersJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.mapMarkersJson!);
        if (decoded is List) {
          mapMarkers = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        debugPrint('❌ Ошибка декодирования mapMarkers: $e');
        mapMarkers = [];
      }
    }

    // ✅ НОВОЕ: AI предсказание из Entity (возвращаем как Map<String, dynamic>?)
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
          debugPrint('❌ Ошибка декодирования AI tips: $e');
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

      // ✅ ИСПРАВЛЕНО: Все основные поля из Entity
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

      // ✅ ИСПРАВЛЕНО: Поля которые есть только в старой модели
      dayBiteMaps: const {},
      fishingSpots: const ['Основная точка'],
      coverPhotoUrl: '',
      coverCropSettings: null,
      reminderEnabled: false,
      reminderType: ReminderType.none, // Использовать ReminderType.none
      reminderTime: null,
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