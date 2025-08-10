// Путь: lib/services/offline/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/isar/fishing_note_entity.dart';
import '../../models/isar/budget_note_entity.dart';
import '../../models/isar/marker_map_entity.dart';
import '../../models/isar/policy_acceptance_entity.dart';
import '../../models/isar/user_usage_limits_entity.dart';
import '../isar_service.dart';
import '../../models/isar/bait_program_entity.dart';

class SyncService {
  static SyncService? _instance;
  final IsarService _isarService = IsarService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ ДОБАВЛЕНО: Защита от параллельных вызовов
  static bool _fullSyncInProgress = false;
  static bool _fishingNotesFromFirebaseInProgress = false;
  static Completer<bool>? _fullSyncCompleter;
  static Completer<bool>? _fishingNotesFromFirebaseCompleter;

  SyncService._();

  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  factory SyncService() => instance;

  /// Универсальный метод для парсинга временных меток
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Проверка доступности интернета
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Получение коллекции пользователя в Firestore
  CollectionReference? _getUserCollection(String collectionName) {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return _firestore.collection('users').doc(user.uid).collection(collectionName);
  }

  // ========================================
  // МЕТОДЫ ДЛЯ FISHING NOTES
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Полная конвертация FishingNoteEntity в Map для Firestore
  Map<String, dynamic> _fishingNoteEntityToFirestore(FishingNoteEntity entity) {
    final map = <String, dynamic>{
      'title': entity.title,
      'description': entity.description,
      'date': entity.date.millisecondsSinceEpoch, // Используем int для совместимости
      'location': entity.location,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),

      // ✅ ДОБАВЛЕНО: Основные недостающие поля
      'tackle': entity.tackle,
      'fishingType': entity.fishingType,
      'notes': entity.notes,
      'latitude': entity.latitude,
      'longitude': entity.longitude,
      'photoUrls': entity.photoUrls,
      'isOffline': false, // Пометка что заметка синхронизирована

    // ✅ ДОБАВИТЬ ЭТУ СТРОКУ:
    'baitProgramIds': entity.baitProgramIds,

      // ✅ ДОБАВЛЕНО: Многодневные рыбалки
      'isMultiDay': entity.isMultiDay,
    };

    // Добавляем endDate если есть
    if (entity.endDate != null) {
      map['endDate'] = entity.endDate!.millisecondsSinceEpoch;
    }

    // ✅ ДОБАВЛЕНО: Обработка mapMarkers из JSON
    if (entity.mapMarkersJson != null && entity.mapMarkersJson!.isNotEmpty) {
      try {
        map['mapMarkers'] = jsonDecode(entity.mapMarkersJson!);
      } catch (e) {
        map['mapMarkers'] = [];
      }
    } else {
      map['mapMarkers'] = [];
    }

    // ✅ ИСПРАВЛЕНО: Обработка погоды (правильное поле weather)
    if (entity.weatherData != null) {
      map['weather'] = {
        'temperature': entity.weatherData!.temperature,
        'feelsLike': entity.weatherData!.feelsLike,
        'humidity': entity.weatherData!.humidity,
        'windSpeed': entity.weatherData!.windSpeed,
        'windDirection': entity.weatherData!.windDirection,
        'pressure': entity.weatherData!.pressure,
        'cloudCover': entity.weatherData!.cloudCover,
        'isDay': entity.weatherData!.isDay,
        'sunrise': entity.weatherData!.sunrise,
        'sunset': entity.weatherData!.sunset,
        'condition': entity.weatherData!.condition,
      };

      // Добавляем observationTime (НЕ recordedAt!)
      if (entity.weatherData!.recordedAt != null) {
        map['weather']['observationTime'] = Timestamp.fromDate(entity.weatherData!.recordedAt!);
      }

      // Добавляем timestamp если есть
      if (entity.weatherData!.timestamp != null) {
        map['weather']['timestamp'] = entity.weatherData!.timestamp;
      }
    }

    // ✅ ИСПРАВЛЕНО: Обработка поклевок (правильные поля weight/length)
    map['biteRecords'] = entity.biteRecords.map((bite) {
      final biteMap = <String, dynamic>{
        'fishType': bite.fishType,
        'notes': bite.notes,
        'weight': bite.fishWeight, // fishWeight -> weight для Firebase
        'length': bite.fishLength, // fishLength -> length для Firebase
        'photoUrls': bite.photoUrls,
        'dayIndex': bite.dayIndex,    // ✅ ДОБАВИТЬ ЭТУ СТРОКУ
        'spotIndex': bite.spotIndex,  // ✅ ДОБАВИТЬ ЭТУ СТРОКУ
      };

      // Добавляем время если есть
      if (bite.time != null) {
        biteMap['time'] = bite.time!.millisecondsSinceEpoch;
      }

      // Добавляем ID если есть
      if (bite.biteId != null && bite.biteId!.isNotEmpty) {
        biteMap['id'] = bite.biteId;
      }

      return biteMap;
    }).toList();

    // ✅ ДОБАВЛЕНО: AI предсказание
    if (entity.aiPrediction != null) {
      map['aiPrediction'] = {
        'activityLevel': entity.aiPrediction!.activityLevel,
        'confidencePercent': entity.aiPrediction!.confidencePercent,
        'fishingType': entity.aiPrediction!.fishingType,
        'overallScore': entity.aiPrediction!.overallScore,
        'recommendation': entity.aiPrediction!.recommendation,
        'timestamp': entity.aiPrediction!.timestamp,
      };

      // Добавляем советы из JSON
      if (entity.aiPrediction!.tipsJson != null && entity.aiPrediction!.tipsJson!.isNotEmpty) {
        try {
          map['aiPrediction']['tips'] = jsonDecode(entity.aiPrediction!.tipsJson!);
        } catch (e) {
          map['aiPrediction']['tips'] = [];
        }
      }
    }

    return map;
  }

  /// ✅ ИСПРАВЛЕНО: Полная конвертация данных из Firestore в FishingNoteEntity
  FishingNoteEntity _firestoreToFishingNoteEntity(String firebaseId, Map<String, dynamic> data) {
    final entity = FishingNoteEntity()
      ..firebaseId = firebaseId
      ..title = data['title'] ?? ''
      ..description = data['description']
      ..date = _parseTimestamp(data['date'])
      ..location = data['location']
      ..createdAt = _parseTimestamp(data['createdAt'])
      ..updatedAt = _parseTimestamp(data['updatedAt'])
      ..isSynced = true;
    entity.userId = _auth.currentUser?.uid ?? '';

    // ✅ ДОБАВЛЕНО: Основные недостающие поля
    entity.tackle = data['tackle'];
    entity.fishingType = data['fishingType'];
    entity.notes = data['notes'];
    entity.latitude = data['latitude']?.toDouble();
    entity.longitude = data['longitude']?.toDouble();

    // ✅ ДОБАВЛЕНО: Фото заметки
    if (data['photoUrls'] != null) {
      entity.photoUrls = List<String>.from(data['photoUrls']);
    }

    // ✅ ДОБАВИТЬ ЭТИ СТРОКИ:
    if (data['baitProgramIds'] != null) {
      entity.baitProgramIds = List<String>.from(data['baitProgramIds']);
    }

    // ✅ ДОБАВЛЕНО: Многодневные рыбалки
    entity.isMultiDay = data['isMultiDay'] ?? false;
    if (data['endDate'] != null) {
      entity.endDate = _parseTimestamp(data['endDate']);
    }

    // ✅ ДОБАВЛЕНО: Маркеры карты как JSON
    if (data['mapMarkers'] != null) {
      try {
        entity.mapMarkersJson = jsonEncode(data['mapMarkers']);
      } catch (e) {
        entity.mapMarkersJson = '[]';
      }
    }

    // ✅ ИСПРАВЛЕНО: Обработка погоды (правильное поле weather)
    if (data['weather'] != null) {
      final weatherMap = data['weather'] as Map<String, dynamic>;
      entity.weatherData = WeatherDataEntity()
        ..temperature = weatherMap['temperature']?.toDouble()
        ..feelsLike = weatherMap['feelsLike']?.toDouble()
        ..humidity = weatherMap['humidity']?.toDouble()
        ..windSpeed = weatherMap['windSpeed']?.toDouble()
        ..windDirection = weatherMap['windDirection']
        ..pressure = weatherMap['pressure']?.toDouble()
        ..cloudCover = weatherMap['cloudCover']?.toDouble()
        ..isDay = weatherMap['isDay'] ?? true
        ..sunrise = weatherMap['sunrise']
        ..sunset = weatherMap['sunset']
        ..condition = weatherMap['condition'];

      // Правильное поле observationTime (НЕ recordedAt!)
      if (weatherMap['observationTime'] != null) {
        entity.weatherData!.recordedAt = _parseTimestamp(weatherMap['observationTime']);
      }

      // Дополнительный timestamp
      if (weatherMap['timestamp'] != null) {
        entity.weatherData!.timestamp = weatherMap['timestamp'];
      }
    }

    // ✅ ИСПРАВЛЕНО: Обработка поклевок (правильные поля weight/length)
    if (data['biteRecords'] != null) {
      final List<dynamic> biteList = data['biteRecords'];
      entity.biteRecords = biteList.map((bite) {
        final biteMap = bite as Map<String, dynamic>;
        final biteEntity = BiteRecordEntity()
          ..biteId = biteMap['id'] // ID поклевки из Firebase
          ..fishType = biteMap['fishType']
          ..notes = biteMap['notes']
          ..fishWeight = biteMap['weight']?.toDouble() // weight -> fishWeight
          ..fishLength = biteMap['length']?.toDouble() // length -> fishLength
          ..dayIndex = biteMap['dayIndex'] ?? 0        // ✅ ДОБАВЛЕНО
          ..spotIndex = biteMap['spotIndex'] ?? 0;     // ✅ ДОБАВЛЕНО

        // Время поклевки
        if (biteMap['time'] != null) {
          biteEntity.time = _parseTimestamp(biteMap['time']);
        }

        // Фото поклевки
        if (biteMap['photoUrls'] != null) {
          biteEntity.photoUrls = List<String>.from(biteMap['photoUrls']);
        }

        return biteEntity;
      }).toList();
    }

    // ✅ ДОБАВЛЕНО: AI предсказание
    if (data['aiPrediction'] != null) {
      final aiMap = data['aiPrediction'] as Map<String, dynamic>;
      entity.aiPrediction = AiPredictionEntity()
        ..activityLevel = aiMap['activityLevel']
        ..confidencePercent = aiMap['confidencePercent']
        ..fishingType = aiMap['fishingType']
        ..overallScore = aiMap['overallScore']
        ..recommendation = aiMap['recommendation']
        ..timestamp = aiMap['timestamp'];

      // Советы как JSON
      if (aiMap['tips'] != null) {
        try {
          entity.aiPrediction!.tipsJson = jsonEncode(aiMap['tips']);
        } catch (e) {
          entity.aiPrediction!.tipsJson = '[]';
        }
      }
    }

    return entity;
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация локальных несинхронизированных FishingNotes в Firestore
  Future<bool> syncFishingNotesToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedNotes();

      // Фильтруем только НЕ помеченные для удаления
      final notesToSync = unsyncedNotes.where((note) => note.markedForDeletion != true).toList();
      debugPrint('📤 SyncService: Синхронизируем ${notesToSync.length} заметок в Firebase');

      for (final note in notesToSync) {
        try {
          final firebaseData = _fishingNoteEntityToFirestore(note);

          // ✅ ИСПРАВЛЕНО: Правильная логика для офлайн заметок
          if (note.firebaseId != null) {
            // ✅ ПРОВЕРЯЕМ: Существует ли документ в Firebase
            final docRef = collection.doc(note.firebaseId);
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              // Документ существует - обновляем
              await docRef.update(firebaseData);
              debugPrint('🔄 SyncService: Обновлена заметка ${note.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(firebaseData);
              debugPrint('✅ SyncService: Создана заметка ${note.firebaseId}');
            }
            await _isarService.markAsSynced(note.id, note.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(firebaseData);
            await _isarService.markAsSynced(note.id, docRef.id);
            debugPrint('✅ SyncService: Создана новая заметка ${docRef.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка синхронизации заметки ${note.firebaseId}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncFishingNotesToFirebase: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Синхронизация удаления помеченных FishingNotes
  Future<bool> syncFishingNotesDeletion() async {
    try {
      if (!await _hasInternetConnection()) {
        debugPrint('📱 SyncService: Нет интернета для синхронизации удаления');
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) {
        debugPrint('❌ SyncService: Не удалось получить коллекцию fishing_notes');
        return false;
      }

      // 🔥 НОВОЕ: Получаем записи помеченные для удаления
      final markedForDeletion = await _isarService.getMarkedForDeletionFishingNotes();
      debugPrint('🗑️ SyncService: Найдено ${markedForDeletion.length} записей для удаления из Firebase');

      for (final note in markedForDeletion) {
        try {
          if (note.firebaseId != null) {
            // Удаляем из Firebase
            await collection.doc(note.firebaseId).delete();
            debugPrint('✅ SyncService: Удалена из Firebase: ${note.firebaseId}');

            // Помечаем как синхронизированную (это запустит автоудаление из Isar)
            await _isarService.markAsSynced(note.id, note.firebaseId!);
            debugPrint('✅ SyncService: Запущено автоудаление из Isar для ID=${note.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка удаления ${note.firebaseId}: $e');
          // Продолжаем с другими записями
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка синхронизации удаления: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Полная синхронизация FishingNotes (создание/обновление + удаление)
  Future<bool> syncFishingNotesToFirebaseWithDeletion() async {
    try {
      // 1. Сначала синхронизируем создание/обновление
      final createUpdateResult = await syncFishingNotesToFirebase();

      // 2. Затем синхронизируем удаление
      final deletionResult = await syncFishingNotesDeletion();

      debugPrint('📊 SyncService: Результаты синхронизации FishingNotes - создание/обновление: $createUpdateResult, удаление: $deletionResult');

      return createUpdateResult && deletionResult;
    } catch (e) {
      debugPrint('❌ SyncService: Ошибка полной синхронизации FishingNotes: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация FishingNotes из Firestore с защитой от race condition
  Future<bool> syncFishingNotesFromFirebase() async {
    // ✅ ЗАЩИТА: Если синхронизация уже идет, ждем ее завершения
    if (_fishingNotesFromFirebaseInProgress) {
      debugPrint('⏸️ SyncService: syncFishingNotesFromFirebase уже выполняется, ждем завершения...');

      if (_fishingNotesFromFirebaseCompleter != null) {
        return await _fishingNotesFromFirebaseCompleter!.future;
      }

      return false;
    }

    debugPrint('🔄 SyncService: Начинаем syncFishingNotesFromFirebase');
    debugPrint('📍 Stack trace: ${StackTrace.current.toString().split('\n').take(3).join('\n')}');

    _fishingNotesFromFirebaseInProgress = true;
    _fishingNotesFromFirebaseCompleter = Completer<bool>();

    try {
      if (!await _hasInternetConnection()) {
        _fishingNotesFromFirebaseInProgress = false;
        _fishingNotesFromFirebaseCompleter?.complete(false);
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) {
        _fishingNotesFromFirebaseInProgress = false;
        _fishingNotesFromFirebaseCompleter?.complete(false);
        return false;
      }

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      debugPrint('📥 SyncService: Получено ${querySnapshot.docs.length} заметок из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          // ✅ ИСПРАВЛЕНИЕ: Используем UPSERT логику вместо отдельных INSERT/UPDATE
          await _upsertFishingNoteFromFirebase(firebaseId, data);

        } catch (e) {
          debugPrint('❌ SyncService: Ошибка обработки заметки ${doc.id}: $e');
        }
      }

      _fishingNotesFromFirebaseInProgress = false;
      _fishingNotesFromFirebaseCompleter?.complete(true);
      debugPrint('✅ SyncService: syncFishingNotesFromFirebase завершена успешно');
      return true;

    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncFishingNotesFromFirebase: $e');
      _fishingNotesFromFirebaseInProgress = false;
      _fishingNotesFromFirebaseCompleter?.complete(false);
      return false;
    }
  }

  Future<void> _upsertFishingNoteFromFirebase(String firebaseId, Map<String, dynamic> data) async {
    // Без транзакции - проще и надежнее
    final existingNote = await _isarService.getFishingNoteByFirebaseId(firebaseId);

    if (existingNote == null) {
      final entity = _firestoreToFishingNoteEntity(firebaseId, data);
      await _isarService.insertFishingNote(entity);
    } else {
      // обновление
    }
  }

  // ========================================
  // 🔥 ОБНОВЛЕННЫЕ МЕТОДЫ ДЛЯ BUDGET NOTES С ПОДДЕРЖКОЙ ОФЛАЙН УДАЛЕНИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация BudgetNotes с Firebase с проверкой существования документов
  Future<bool> syncBudgetNotesToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedBudgetNotes(userId);

      // Фильтруем только НЕ помеченные для удаления
      final notesToSync = unsyncedNotes.where((note) => note.markedForDeletion != true).toList();
      debugPrint('📤 SyncService: Синхронизируем ${notesToSync.length} BudgetNotes в Firebase');

      for (final note in notesToSync) {
        try {
          final data = note.toFirestoreMap();

          // ✅ ИСПРАВЛЕНО: Добавлена проверка существования документа (как у FishingNotes)
          if (note.firebaseId != null) {
            // ✅ ПРОВЕРЯЕМ: Существует ли документ в Firebase
            final docRef = collection.doc(note.firebaseId);
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              // Документ существует - обновляем
              await docRef.update(data);
              debugPrint('🔄 SyncService: Обновлена BudgetNote ${note.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(data);
              debugPrint('✅ SyncService: Создана BudgetNote ${note.firebaseId}');
            }
            await _isarService.markBudgetNoteAsSynced(note.id, note.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(data);
            await _isarService.markBudgetNoteAsSynced(note.id, docRef.id);
            debugPrint('✅ SyncService: Создана новая BudgetNote ${docRef.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка синхронизации BudgetNote ${note.firebaseId}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncBudgetNotesToFirebase: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Синхронизация удаления помеченных BudgetNotes
  Future<bool> syncBudgetNotesDeletion() async {
    try {
      if (!await _hasInternetConnection()) {
        debugPrint('📱 SyncService: Нет интернета для синхронизации удаления BudgetNotes');
        return false;
      }

      final collection = _getUserCollection('budget_notes');
      if (collection == null) {
        debugPrint('❌ SyncService: Не удалось получить коллекцию budget_notes');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ SyncService: Пользователь не авторизован');
        return false;
      }

      // 🔥 НОВОЕ: Получаем записи помеченные для удаления
      final markedForDeletion = await _isarService.getMarkedForDeletionBudgetNotes(userId);
      debugPrint('🗑️ SyncService: Найдено ${markedForDeletion.length} BudgetNotes для удаления из Firebase');

      for (final note in markedForDeletion) {
        try {
          if (note.firebaseId != null) {
            // Удаляем из Firebase
            await collection.doc(note.firebaseId).delete();
            debugPrint('✅ SyncService: Удалена BudgetNote из Firebase: ${note.firebaseId}');

            // Помечаем как синхронизированную (это запустит автоудаление из Isar)
            await _isarService.markBudgetNoteAsSynced(note.id, note.firebaseId!);
            debugPrint('✅ SyncService: Запущено автоудаление BudgetNote из Isar для ID=${note.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка удаления BudgetNote ${note.firebaseId}: $e');
          // Продолжаем с другими записями
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка синхронизации удаления BudgetNotes: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Полная синхронизация BudgetNotes (создание/обновление + удаление)
  Future<bool> syncBudgetNotesToFirebaseWithDeletion() async {
    try {
      // 1. Сначала синхронизируем создание/обновление
      final createUpdateResult = await syncBudgetNotesToFirebase();

      // 2. Затем синхронизируем удаление
      final deletionResult = await syncBudgetNotesDeletion();

      debugPrint('📊 SyncService: Результаты синхронизации BudgetNotes - создание/обновление: $createUpdateResult, удаление: $deletionResult');

      return createUpdateResult && deletionResult;
    } catch (e) {
      debugPrint('❌ SyncService: Ошибка полной синхронизации BudgetNotes: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация BudgetNotes из Firebase с улучшенным логированием
  Future<bool> syncBudgetNotesFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingNote = await _isarService.getBudgetNoteByFirebaseId(firebaseId);

          if (existingNote == null) {
            final entity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertBudgetNote(entity);
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingNote.updatedAt)) {
              final updatedEntity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingNote.id;
              await _isarService.updateBudgetNote(updatedEntity);
            }
          }
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // 🔥 ОБНОВЛЕННЫЕ МЕТОДЫ ДЛЯ MARKER MAPS С ПОДДЕРЖКОЙ ОФЛАЙН УДАЛЕНИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация MarkerMaps с Firebase с проверкой существования документов
  Future<bool> syncMarkerMapsToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedMaps = await _isarService.getUnsyncedMarkerMaps(userId);

      // Фильтруем только НЕ помеченные для удаления
      final mapsToSync = unsyncedMaps.where((map) => map.markedForDeletion != true).toList();
      debugPrint('📤 SyncService: Синхронизируем ${mapsToSync.length} MarkerMaps в Firebase');

      for (final map in mapsToSync) {
        try {
          final data = map.toFirestoreMap();

          // ✅ ИСПРАВЛЕНО: Добавлена проверка существования документа (как у FishingNotes)
          if (map.firebaseId != null) {
            // ✅ ПРОВЕРЯЕМ: Существует ли документ в Firebase
            final docRef = collection.doc(map.firebaseId);
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              // Документ существует - обновляем
              await docRef.update(data);
              debugPrint('🔄 SyncService: Обновлена MarkerMap ${map.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(data);
              debugPrint('✅ SyncService: Создана MarkerMap ${map.firebaseId}');
            }
            await _isarService.markMarkerMapAsSynced(map.id, map.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(data);
            await _isarService.markMarkerMapAsSynced(map.id, docRef.id);
            debugPrint('✅ SyncService: Создана новая MarkerMap ${docRef.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка синхронизации MarkerMap ${map.firebaseId}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncMarkerMapsToFirebase: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Синхронизация удаления помеченных MarkerMaps
  Future<bool> syncMarkerMapsDeletion() async {
    try {
      if (!await _hasInternetConnection()) {
        debugPrint('📱 SyncService: Нет интернета для синхронизации удаления MarkerMaps');
        return false;
      }

      final collection = _getUserCollection('marker_maps');
      if (collection == null) {
        debugPrint('❌ SyncService: Не удалось получить коллекцию marker_maps');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ SyncService: Пользователь не авторизован');
        return false;
      }

      // 🔥 НОВОЕ: Получаем записи помеченные для удаления
      final markedForDeletion = await _isarService.getMarkedForDeletionMarkerMaps(userId);
      debugPrint('🗑️ SyncService: Найдено ${markedForDeletion.length} MarkerMaps для удаления из Firebase');

      for (final map in markedForDeletion) {
        try {
          if (map.firebaseId != null) {
            // Удаляем из Firebase
            await collection.doc(map.firebaseId).delete();
            debugPrint('✅ SyncService: Удалена MarkerMap из Firebase: ${map.firebaseId}');

            // Помечаем как синхронизированную (это запустит автоудаление из Isar)
            await _isarService.markMarkerMapAsSynced(map.id, map.firebaseId!);
            debugPrint('✅ SyncService: Запущено автоудаление MarkerMap из Isar для ID=${map.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка удаления MarkerMap ${map.firebaseId}: $e');
          // Продолжаем с другими записями
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка синхронизации удаления MarkerMaps: $e');
      return false;
    }
  }

  /// 🔥 НОВОЕ: Полная синхронизация MarkerMaps (создание/обновление + удаление)
  Future<bool> syncMarkerMapsToFirebaseWithDeletion() async {
    try {
      // 1. Сначала синхронизируем создание/обновление
      final createUpdateResult = await syncMarkerMapsToFirebase();

      // 2. Затем синхронизируем удаление
      final deletionResult = await syncMarkerMapsDeletion();

      debugPrint('📊 SyncService: Результаты синхронизации MarkerMaps - создание/обновление: $createUpdateResult, удаление: $deletionResult');

      return createUpdateResult && deletionResult;
    } catch (e) {
      debugPrint('❌ SyncService: Ошибка полной синхронизации MarkerMaps: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация MarkerMaps из Firebase с улучшенным логированием
  Future<bool> syncMarkerMapsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingMap = await _isarService.getMarkerMapByFirebaseId(firebaseId);

          if (existingMap == null) {
            final entity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertMarkerMap(entity);
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingMap.updatedAt)) {
              final updatedEntity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingMap.id;
              await _isarService.updateMarkerMap(updatedEntity);
            }
          }
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ POLICY ACCEPTANCE
  // ========================================

  /// ✅ СУЩЕСТВУЮЩЕЕ: Синхронизация PolicyAcceptance с Firebase
  Future<bool> syncPolicyAcceptanceToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      // Получаем коллекцию согласий пользователя
      final userConsentsCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents');

      final unsyncedPolicies = await _isarService.getUnsyncedPolicyAcceptances();

      for (final policy in unsyncedPolicies) {
        try {
          final data = policy.toFirestoreMap();

          // PolicyAcceptance всегда использует фиксированный ID 'consents'
          final docRef = userConsentsCollection.doc('consents');
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Документ существует - обновляем
            await docRef.update(data);
          } else {
            // Документ не существует - создаем новый
            await docRef.set(data);
          }

          // Отмечаем как синхронизированные
          await _isarService.markPolicyAcceptanceAsSynced(policy.id, 'consents');
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Синхронизация PolicyAcceptance из Firebase
  Future<bool> syncPolicyAcceptanceFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents')
          .doc('consents');

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        try {
          final data = docSnapshot.data() as Map<String, dynamic>;

          // Ищем существующие согласия пользователя в Isar
          final existingPolicies = await _isarService.getAllPolicyAcceptances();
          final existingPolicy = existingPolicies
              .where((p) => p.userId == userId)
              .firstOrNull;

          if (existingPolicy == null) {
            // Создаем новые согласия
            final entity = PolicyAcceptanceEntity.fromFirestoreMap(userId, data);
            await _isarService.insertPolicyAcceptance(entity);
          } else {
            // Проверяем нужно ли обновление
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingPolicy.updatedAt)) {
              final updatedEntity = PolicyAcceptanceEntity.fromFirestoreMap(userId, data);
              updatedEntity.id = existingPolicy.id;
              await _isarService.updatePolicyAcceptance(updatedEntity);
            }
          }
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // 🆕 МЕТОДЫ ДЛЯ USER USAGE LIMITS
  // ========================================

  /// 🆕 НОВОЕ: Синхронизация UserUsageLimits с Firebase
  Future<bool> syncUserUsageLimitsToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      // Получаем коллекцию лимитов пользователя
      final userLimitsCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_usage_limits');

      final unsyncedLimits = await _isarService.getUnsyncedUserUsageLimits();

      for (final limits in unsyncedLimits) {
        try {
          final data = limits.toFirestoreMap();

          // UserUsageLimits всегда использует фиксированный ID 'current'
          final docRef = userLimitsCollection.doc('current');
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Документ существует - обновляем
            await docRef.update(data);
          } else {
            // Документ не существует - создаем новый
            await docRef.set(data);
          }

          // Отмечаем как синхронизированные
          await _isarService.markUserUsageLimitsAsSynced(limits.id, 'current');
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 НОВОЕ: Синхронизация UserUsageLimits из Firebase
  Future<bool> syncUserUsageLimitsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_usage_limits')
          .doc('current');

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        try {
          final data = docSnapshot.data() as Map<String, dynamic>;

          // Ищем существующие лимиты пользователя в Isar
          final existingLimits = await _isarService.getUserUsageLimitsByUserId(userId);

          if (existingLimits == null) {
            // Создаем новые лимиты
            final entity = UserUsageLimitsEntity.fromFirestoreMap('current', data, userId);
            await _isarService.insertUserUsageLimits(entity);
          } else {
            // Проверяем нужно ли обновление
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingLimits.updatedAt)) {
              final updatedEntity = UserUsageLimitsEntity.fromFirestoreMap('current', data, userId);
              updatedEntity.id = existingLimits.id;
              await _isarService.updateUserUsageLimits(updatedEntity);
            }
          }
        } catch (e) {
          // Silent error handling for production
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
// 🆕 НОВЫЕ МЕТОДЫ ДЛЯ BAIT PROGRAMS
// ========================================

  /// Конвертация BaitProgramEntity в Map для Firestore
  Map<String, dynamic> _baitProgramEntityToFirestore(BaitProgramEntity entity) {
    return {
      'title': entity.title,
      'description': entity.description,
      'isFavorite': entity.isFavorite,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  /// Конвертация данных из Firestore в BaitProgramEntity
  BaitProgramEntity _firestoreToBaitProgramEntity(String firebaseId, Map<String, dynamic> data) {
    final entity = BaitProgramEntity()
      ..firebaseId = firebaseId
      ..title = data['title'] ?? ''
      ..description = data['description'] ?? ''
      ..isFavorite = data['isFavorite'] ?? false
      ..createdAt = _parseTimestamp(data['createdAt'])
      ..updatedAt = _parseTimestamp(data['updatedAt'])
      ..isSynced = true;
    entity.userId = _auth.currentUser?.uid ?? '';
    return entity;
  }

  /// Синхронизация BaitPrograms в Firebase
  Future<bool> syncBaitProgramsToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('bait_programs');
      if (collection == null) return false;

      final unsyncedPrograms = await _isarService.getUnsyncedBaitPrograms();
      final programsToSync = unsyncedPrograms.where((program) => program.markedForDeletion != true).toList();

      debugPrint('📤 SyncService: Синхронизируем ${programsToSync.length} BaitPrograms в Firebase');

      for (final program in programsToSync) {
        try {
          final data = _baitProgramEntityToFirestore(program);

          if (program.firebaseId != null) {
            final docRef = collection.doc(program.firebaseId);
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              await docRef.update(data);
              debugPrint('🔄 SyncService: Обновлена BaitProgram ${program.firebaseId}');
            } else {
              await docRef.set(data);
              debugPrint('✅ SyncService: Создана BaitProgram ${program.firebaseId}');
            }
            await _isarService.markBaitProgramAsSynced(program.id, program.firebaseId!);
          } else {
            final docRef = await collection.add(data);
            await _isarService.markBaitProgramAsSynced(program.id, docRef.id);
            debugPrint('✅ SyncService: Создана новая BaitProgram ${docRef.id}');
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка синхронизации BaitProgram ${program.firebaseId}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncBaitProgramsToFirebase: $e');
      return false;
    }
  }

  /// Синхронизация BaitPrograms из Firebase
  Future<bool> syncBaitProgramsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        return false;
      }

      final collection = _getUserCollection('bait_programs');
      if (collection == null) return false;

      final querySnapshot = await collection.orderBy('createdAt', descending: true).get();
      debugPrint('📥 SyncService: Получено ${querySnapshot.docs.length} BaitPrograms из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingProgram = await _isarService.getBaitProgramByFirebaseId(firebaseId);

          if (existingProgram == null) {
            final entity = _firestoreToBaitProgramEntity(firebaseId, data);
            await _isarService.insertBaitProgram(entity);
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingProgram.updatedAt)) {
              final updatedEntity = _firestoreToBaitProgramEntity(firebaseId, data);
              updatedEntity.id = existingProgram.id;
              await _isarService.updateBaitProgram(updatedEntity);
            }
          }
        } catch (e) {
          debugPrint('❌ SyncService: Ошибка обработки BaitProgram ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка syncBaitProgramsFromFirebase: $e');
      return false;
    }
  }

  /// Удаление BaitProgram по Firebase ID
  Future<bool> deleteBaitProgramByFirebaseId(String firebaseId) async {
    try {
      debugPrint('🗑️ SyncService: Начинаем удаление BaitProgram $firebaseId');

      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('bait_programs');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            debugPrint('✅ SyncService: BaitProgram удалена из Firebase: $firebaseId');
          } catch (e) {
            debugPrint('❌ SyncService: Ошибка удаления BaitProgram из Firebase $firebaseId: $e');
          }
        }
      }

      final entity = await _isarService.getBaitProgramByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteBaitProgram(entity.id);
        debugPrint('✅ SyncService: BaitProgram удалена из Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка deleteBaitProgramByFirebaseId $firebaseId: $e');
      return false;
    }
  }

  // ========================================
  // ✅ МЕТОДЫ УДАЛЕНИЯ (ЭТАП 15)
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Удаление заметки по Firebase ID с улучшенным логированием
  Future<bool> deleteNoteByFirebaseId(String firebaseId) async {
    try {
      debugPrint('🗑️ SyncService: Начинаем удаление заметки $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('fishing_notes');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            debugPrint('✅ SyncService: Удалена из Firebase: $firebaseId');
          } catch (e) {
            debugPrint('❌ SyncService: Ошибка удаления из Firebase $firebaseId: $e');
            // Continue with local deletion even if Firebase fails
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getFishingNoteByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteFishingNote(entity.id);
        debugPrint('✅ SyncService: Удалена из Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка deleteNoteByFirebaseId $firebaseId: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удаление заметки бюджета по Firebase ID с улучшенным логированием
  Future<bool> deleteBudgetNoteByFirebaseId(String firebaseId) async {
    try {
      debugPrint('🗑️ SyncService: Начинаем удаление BudgetNote $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('budget_notes');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            debugPrint('✅ SyncService: BudgetNote удалена из Firebase: $firebaseId');
          } catch (e) {
            debugPrint('❌ SyncService: Ошибка удаления BudgetNote из Firebase $firebaseId: $e');
            // Continue with local deletion even if Firebase fails
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getBudgetNoteByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteBudgetNote(entity.id);
        debugPrint('✅ SyncService: BudgetNote удалена из Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка deleteBudgetNoteByFirebaseId $firebaseId: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удаление маркерной карты по Firebase ID с улучшенным логированием
  Future<bool> deleteMarkerMapByFirebaseId(String firebaseId) async {
    try {
      debugPrint('🗑️ SyncService: Начинаем удаление MarkerMap $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('marker_maps');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            debugPrint('✅ SyncService: MarkerMap удалена из Firebase: $firebaseId');
          } catch (e) {
            debugPrint('❌ SyncService: Ошибка удаления MarkerMap из Firebase $firebaseId: $e');
            // Continue with local deletion even if Firebase fails
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getMarkerMapByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteMarkerMap(entity.id);
        debugPrint('✅ SyncService: MarkerMap удалена из Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ SyncService: Критическая ошибка deleteMarkerMapByFirebaseId $firebaseId: $e');
      return false;
    }
  }

  // ========================================
  // 🔥 ОБНОВЛЕННЫЕ ОБЩИЕ МЕТОДЫ
  // ========================================

  /// ✅ ОБНОВЛЕНО: Синхронизация всех данных включая удаление MarkerMaps
  Future<bool> syncAll() async {
    try {
      debugPrint('🔄 SyncService: Начинаем syncAll...');
      final results = await Future.wait([
        syncFishingNotesToFirebaseWithDeletion(), // 🔥 ОБНОВЛЕНО: с удалением
        syncBudgetNotesToFirebaseWithDeletion(),  // 🔥 НОВОЕ: с удалением
        syncMarkerMapsToFirebaseWithDeletion(),   // 🔥 НОВОЕ: с удалением
        syncPolicyAcceptanceToFirebase(),
        syncUserUsageLimitsToFirebase(),
        syncBaitProgramsToFirebase(),
      ]);

      final success = results.every((result) => result);
      debugPrint('📊 SyncService: syncAll результат: $success');
      return success;
    } catch (e) {
      debugPrint('❌ SyncService: Ошибка syncAll: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Полная двусторонняя синхронизация с защитой от параллельных вызовов
  Future<bool> fullSync() async {
    // ✅ ЗАЩИТА: Если полная синхронизация уже идет, ждем ее завершения
    if (_fullSyncInProgress) {
      debugPrint('⏸️ SyncService: fullSync уже выполняется, ждем завершения...');

      if (_fullSyncCompleter != null) {
        return await _fullSyncCompleter!.future;
      }

      return false;
    }

    debugPrint('🔄 SyncService: Начинаем полную синхронизацию...');

    _fullSyncInProgress = true;
    _fullSyncCompleter = Completer<bool>();

    try {
      // Отправляем локальные изменения в Firebase (включая удаление)
      final toFirebaseResults = await Future.wait([
        syncFishingNotesToFirebaseWithDeletion(), // 🔥 ОБНОВЛЕНО: с удалением
        syncBudgetNotesToFirebaseWithDeletion(),  // 🔥 НОВОЕ: с удалением
        syncMarkerMapsToFirebaseWithDeletion(),   // 🔥 НОВОЕ: с удалением
        syncPolicyAcceptanceToFirebase(),
        syncUserUsageLimitsToFirebase(),
        syncBaitProgramsToFirebase(),
      ]);

      // Получаем обновления из Firebase
      final fromFirebaseResults = await Future.wait([
        syncFishingNotesFromFirebase(),
        syncBudgetNotesFromFirebase(),
        syncMarkerMapsFromFirebase(),
        syncPolicyAcceptanceFromFirebase(),
        syncUserUsageLimitsFromFirebase(),
        syncBaitProgramsFromFirebase(),
      ]);

      final success = [...toFirebaseResults, ...fromFirebaseResults].every((result) => result);

      _fullSyncInProgress = false;
      _fullSyncCompleter?.complete(success);

      debugPrint('✅ SyncService: Полная синхронизация завершена, результат: $success');
      return success;

    } catch (e) {
      debugPrint('❌ SyncService: Ошибка полной синхронизации: $e');
      _fullSyncInProgress = false;
      _fullSyncCompleter?.complete(false);
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Удаление заметки и синхронизация удаления с Firebase
  Future<bool> deleteNoteAndSync(int localId) async {
    try {
      final note = await _isarService.getFishingNoteById(localId);
      if (note == null) {
        return false;
      }

      // Сначала удаляем из Firebase, потом из Isar
      if (note.firebaseId != null && await _hasInternetConnection()) {
        final collection = _getUserCollection('fishing_notes');
        if (collection != null) {
          try {
            await collection.doc(note.firebaseId).delete();
          } catch (e) {
            // Continue with local deletion even if Firebase fails
          }
        }
      }

      // Удаляем из Isar после успешного удаления из Firebase
      await _isarService.deleteFishingNote(localId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Принудительная полная синхронизация
  Future<bool> forceSyncAll() async {
    return await fullSync();
  }

  /// Публичный метод для внешнего использования
  Future<bool> performFullSync() async {
    return await fullSync();
  }

  /// ✅ УЛУЧШЕНО: Периодическая синхронизация с логированием
  void startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (await _hasInternetConnection()) {
        final result = await fullSync();
        debugPrint('⏰ SyncService: Периодическая синхронизация: $result');
      }
    });
  }

  /// ✅ ОБНОВЛЕНО: Получение статуса синхронизации всех типов данных включая UserUsageLimits
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'fishingNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
          'budgetNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
          'markerMaps': {'total': 0, 'unsynced': 0, 'synced': 0},
          'policyAcceptance': {'total': 0, 'unsynced': 0, 'synced': 0},
          'userUsageLimits': {'total': 0, 'unsynced': 0, 'synced': 0},
        };
      }

      final baitProgramsTotal = await _isarService.getBaitProgramsCountByUser(userId);
      final baitProgramsUnsynced = await _isarService.getUnsyncedBaitProgramsCount(userId);

      final fishingNotesTotal = await _isarService.getNotesCount();
      final fishingNotesUnsynced = await _isarService.getUnsyncedNotesCount();

      final budgetNotesTotal = await _isarService.getBudgetNotesCount(userId);
      final budgetNotesUnsynced = await _isarService.getUnsyncedBudgetNotesCount(userId);

      final markerMapsTotal = await _isarService.getMarkerMapsCount(userId);
      final markerMapsUnsynced = await _isarService.getUnsyncedMarkerMapsCount(userId);

      final policyAcceptanceTotal = await _isarService.getPolicyAcceptancesCount();
      final policyAcceptanceUnsynced = await _isarService.getUnsyncedPolicyAcceptancesCount();

      final userUsageLimitsTotal = await _isarService.getUserUsageLimitsCount();
      final userUsageLimitsUnsynced = await _isarService.getUnsyncedUserUsageLimitsCount();

      final status = {
        'fishingNotes': {
          'total': fishingNotesTotal,
          'unsynced': fishingNotesUnsynced,
          'synced': fishingNotesTotal - fishingNotesUnsynced,
        },
        'budgetNotes': {
          'total': budgetNotesTotal,
          'unsynced': budgetNotesUnsynced,
          'synced': budgetNotesTotal - budgetNotesUnsynced,
        },
        'markerMaps': {
          'total': markerMapsTotal,
          'unsynced': markerMapsUnsynced,
          'synced': markerMapsTotal - markerMapsUnsynced,
        },
        'policyAcceptance': {
          'total': policyAcceptanceTotal,
          'unsynced': policyAcceptanceUnsynced,
          'synced': policyAcceptanceTotal - policyAcceptanceUnsynced,
        },
        'userUsageLimits': {
          'total': userUsageLimitsTotal,
          'unsynced': userUsageLimitsUnsynced,
          'synced': userUsageLimitsTotal - userUsageLimitsUnsynced,
        },
        'baitPrograms': {
          'total': baitProgramsTotal,
          'unsynced': baitProgramsUnsynced,
          'synced': baitProgramsTotal - baitProgramsUnsynced,
        },
      };

      return status;
    } catch (e) {
      return {
        'fishingNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'budgetNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'markerMaps': {'total': 0, 'unsynced': 0, 'synced': 0},
        'policyAcceptance': {'total': 0, 'unsynced': 0, 'synced': 0},
        'userUsageLimits': {'total': 0, 'unsynced': 0, 'synced': 0},
        'baitPrograms': {'total': 0, 'unsynced': 0, 'synced': 0},
        'error': e.toString(),
      };
    }
  }
}