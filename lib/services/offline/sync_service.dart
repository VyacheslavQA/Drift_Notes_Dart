// Путь: lib/services/offline/sync_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/isar/fishing_note_entity.dart';
import '../../models/isar/budget_note_entity.dart';
import '../../models/isar/marker_map_entity.dart';
import '../isar_service.dart';

class SyncService {
  static SyncService? _instance;
  final IsarService _isarService = IsarService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      log('Пользователь не авторизован');
      return null;
    }
    return _firestore.collection('users').doc(user.uid).collection(collectionName);
  }

  // ========================================
  // МЕТОДЫ ДЛЯ FISHING NOTES
  // ========================================

  /// Конвертация FishingNoteEntity в Map для Firestore
  Map<String, dynamic> _fishingNoteEntityToFirestore(FishingNoteEntity entity) {
    return {
      'title': entity.title,
      'description': entity.description,
      'date': Timestamp.fromDate(entity.date),
      'location': entity.location,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
      'weatherData': entity.weatherData != null ? {
        'temperature': entity.weatherData!.temperature,
        'humidity': entity.weatherData!.humidity,
        'windSpeed': entity.weatherData!.windSpeed,
        'windDirection': entity.weatherData!.windDirection,
        'pressure': entity.weatherData!.pressure,
        'condition': entity.weatherData!.condition,
        'recordedAt': entity.weatherData!.recordedAt != null
            ? Timestamp.fromDate(entity.weatherData!.recordedAt!)
            : null,
      } : null,
      'biteRecords': entity.biteRecords.map((bite) => {
        'time': bite.time != null ? Timestamp.fromDate(bite.time!) : null,
        'fishType': bite.fishType,
        'baitUsed': bite.baitUsed,
        'success': bite.success,
        'fishWeight': bite.fishWeight,
        'fishLength': bite.fishLength,
        'notes': bite.notes,
      }).toList(),
    };
  }

  /// Конвертация данных из Firestore в FishingNoteEntity
  FishingNoteEntity _firestoreToFishingNoteEntity(String firebaseId, Map<String, dynamic> data) {
    final entity = FishingNoteEntity()
      ..firebaseId = firebaseId
      ..title = data['title'] ?? ''
      ..description = data['description']
      ..date = _parseTimestamp(data['date'])  // ✅ ИСПРАВЛЕНО
      ..location = data['location']
      ..createdAt = _parseTimestamp(data['createdAt'])  // ✅ ИСПРАВЛЕНО
      ..updatedAt = _parseTimestamp(data['updatedAt'])  // ✅ ИСПРАВЛЕНО
      ..isSynced = true;

    // 🔥 ИСПРАВЛЕНИЕ: Добавляем поля endDate и isMultiDay
    if (data['endDate'] != null) {
      entity.endDate = _parseTimestamp(data['endDate']);
    }
    entity.isMultiDay = data['isMultiDay'] ?? false;

    // 🔥 ИСПРАВЛЕНИЕ: Добавляем обработку weather данных
    if (data['weather'] != null) {
      final weatherMap = data['weather'] as Map<String, dynamic>;
      entity.weatherData = WeatherDataEntity()
        ..temperature = weatherMap['temperature']?.toDouble()
        ..humidity = weatherMap['humidity'].toDouble()
        ..windSpeed = weatherMap['windSpeed']?.toDouble()
        ..windDirection = weatherMap['windDirection']
        ..pressure = weatherMap['pressure']?.toDouble()
        ..condition = weatherMap['condition']
        ..recordedAt = weatherMap['observationTime'] != null
            ? _parseTimestamp(weatherMap['observationTime'])
            : null
      // Дополнительные поля из Firebase
        ..feelsLike = weatherMap['feelsLike']?.toDouble()
        ..cloudCover = weatherMap['cloudCover']?.toDouble()
        ..isDay = weatherMap['isDay'] ?? true
        ..sunrise = weatherMap['sunrise']
        ..sunset = weatherMap['sunset'];
    }

    // Конвертация записей о поклевках
    if (data['biteRecords'] != null) {
      final List<dynamic> biteList = data['biteRecords'];
      entity.biteRecords = biteList.map((bite) {
        final biteMap = bite as Map<String, dynamic>;
        return BiteRecordEntity()
          ..time = biteMap['time'] != null
              ? _parseTimestamp(biteMap['time'])  // ✅ ИСПРАВЛЕНО
              : null
          ..fishType = biteMap['fishType']
          ..baitUsed = biteMap['baitUsed']
          ..success = biteMap['success'] ?? false
          ..fishWeight = biteMap['weight']?.toDouble()  // ✅ ИСПРАВЛЕНО: weight вместо fishWeight
          ..fishLength = biteMap['length']?.toDouble()  // ✅ ИСПРАВЛЕНО: length вместо fishLength
          ..notes = biteMap['notes'];
      }).toList();
    }

    return entity;
  }

  /// Синхронизация локальных несинхронизированных FishingNotes в Firestore
  Future<bool> syncFishingNotesToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету');
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedNotes();
      log('Найдено ${unsyncedNotes.length} несинхронизированных рыболовных заметок');

      for (final note in unsyncedNotes) {
        try {
          if (note.firebaseId != null) {
            await collection.doc(note.firebaseId).update(_fishingNoteEntityToFirestore(note));
            log('Обновлена заметка: ${note.firebaseId}');
          } else {
            final docRef = await collection.add(_fishingNoteEntityToFirestore(note));
            await _isarService.markAsSynced(note.id, docRef.id);
            log('Создана новая заметка: ${docRef.id}');
            continue;
          }
          await _isarService.markAsSynced(note.id, note.firebaseId!);
        } catch (e) {
          log('Ошибка синхронизации заметки ${note.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncFishingNotesToFirebase: $e');
      return false;
    }
  }

  /// Синхронизация FishingNotes из Firestore в локальную БД
  Future<bool> syncFishingNotesFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету');
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('Получено ${querySnapshot.docs.length} рыболовных записей из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingNote = await _isarService.getFishingNoteByFirebaseId(firebaseId);

          if (existingNote == null) {
            final entity = _firestoreToFishingNoteEntity(firebaseId, data);
            await _isarService.insertFishingNote(entity);
            log('Добавлена новая заметка из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);  // ✅ ИСПРАВЛЕНО
            if (firebaseUpdatedAt.isAfter(existingNote.updatedAt)) {
              final updatedEntity = _firestoreToFishingNoteEntity(firebaseId, data);
              updatedEntity.id = existingNote.id;
              await _isarService.updateFishingNote(updatedEntity);
              log('Обновлена заметка из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('Ошибка обработки документа ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncFishingNotesFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ BUDGET NOTES
  // ========================================

  /// Синхронизация BudgetNotes с Firebase
  Future<bool> syncBudgetNotesToFirebase() async {
    try {
      if (!await _hasInternetConnection()) return false;

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedBudgetNotes(userId);
      log('Найдено ${unsyncedNotes.length} несинхронизированных бюджетных заметок');

      for (final note in unsyncedNotes) {
        try {
          final data = note.toFirestoreMap();

          if (note.firebaseId != null) {
            await collection.doc(note.firebaseId).update(data);
            log('Обновлена бюджетная заметка: ${note.firebaseId}');
          } else {
            final docRef = await collection.add(data);
            await _isarService.markBudgetNoteAsSynced(note.id, docRef.id);
            log('Создана новая бюджетная заметка: ${docRef.id}');
            continue;
          }
          await _isarService.markBudgetNoteAsSynced(note.id, note.firebaseId!);
        } catch (e) {
          log('Ошибка синхронизации бюджетной заметки ${note.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncBudgetNotesToFirebase: $e');
      return false;
    }
  }

  /// Синхронизация BudgetNotes из Firebase
  Future<bool> syncBudgetNotesFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) return false;

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('Получено ${querySnapshot.docs.length} бюджетных записей из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingNote = await _isarService.getBudgetNoteByFirebaseId(firebaseId);

          if (existingNote == null) {
            final entity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertBudgetNote(entity);
            log('Добавлена новая бюджетная заметка из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);  // ✅ ИСПРАВЛЕНО
            if (firebaseUpdatedAt.isAfter(existingNote.updatedAt)) {
              final updatedEntity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingNote.id;
              await _isarService.updateBudgetNote(updatedEntity);
              log('Обновлена бюджетная заметка из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('Ошибка обработки бюджетного документа ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncBudgetNotesFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ MARKER MAPS
  // ========================================

  /// Синхронизация MarkerMaps с Firebase
  Future<bool> syncMarkerMapsToFirebase() async {
    try {
      if (!await _hasInternetConnection()) return false;

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedMaps = await _isarService.getUnsyncedMarkerMaps(userId);
      log('Найдено ${unsyncedMaps.length} несинхронизированных карт с маркерами');

      for (final map in unsyncedMaps) {
        try {
          final data = map.toFirestoreMap();

          if (map.firebaseId != null) {
            await collection.doc(map.firebaseId).update(data);
            log('Обновлена карта: ${map.firebaseId}');
          } else {
            final docRef = await collection.add(data);
            await _isarService.markMarkerMapAsSynced(map.id, docRef.id);
            log('Создана новая карта: ${docRef.id}');
            continue;
          }
          await _isarService.markMarkerMapAsSynced(map.id, map.firebaseId!);
        } catch (e) {
          log('Ошибка синхронизации карты ${map.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncMarkerMapsToFirebase: $e');
      return false;
    }
  }

  /// Синхронизация MarkerMaps из Firebase
  Future<bool> syncMarkerMapsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) return false;

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('Получено ${querySnapshot.docs.length} карт из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingMap = await _isarService.getMarkerMapByFirebaseId(firebaseId);

          if (existingMap == null) {
            final entity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertMarkerMap(entity);
            log('Добавлена новая карта из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);  // ✅ ИСПРАВЛЕНО
            if (firebaseUpdatedAt.isAfter(existingMap.updatedAt)) {
              final updatedEntity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingMap.id;
              await _isarService.updateMarkerMap(updatedEntity);
              log('Обновлена карта из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('Ошибка обработки карты ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('Ошибка syncMarkerMapsFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // ОБЩИЕ МЕТОДЫ
  // ========================================

  /// Синхронизация всех данных в Firebase
  Future<bool> syncAll() async {
    try {
      log('Начинается синхронизация всех данных');

      final results = await Future.wait([
        syncFishingNotesToFirebase(),
        syncBudgetNotesToFirebase(),
        syncMarkerMapsToFirebase(),
      ]);

      final success = results.every((result) => result);
      log('Синхронизация всех данных в Firebase завершена. Успех: $success');
      return success;
    } catch (e) {
      log('Ошибка syncAll: $e');
      return false;
    }
  }

  /// Полная двусторонняя синхронизация всех типов данных
  Future<bool> fullSync() async {
    try {
      log('Начинается полная синхронизация');

      // Отправляем локальные изменения в Firebase
      final toFirebaseResults = await Future.wait([
        syncFishingNotesToFirebase(),
        syncBudgetNotesToFirebase(),
        syncMarkerMapsToFirebase(),
      ]);

      // Получаем обновления из Firebase
      final fromFirebaseResults = await Future.wait([
        syncFishingNotesFromFirebase(),
        syncBudgetNotesFromFirebase(),
        syncMarkerMapsFromFirebase(),
      ]);

      final success = [...toFirebaseResults, ...fromFirebaseResults].every((result) => result);
      log('Полная синхронизация завершена. Успех: $success');

      return success;
    } catch (e) {
      log('Ошибка fullSync: $e');
      return false;
    }
  }

  /// Принудительная полная синхронизация
  Future<bool> forceSyncAll() async {
    return await fullSync();
  }

  /// Периодическая синхронизация (каждые 5 минут)
  void startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (await _hasInternetConnection()) {
        await fullSync();
      }
    });
  }

  /// 🔥 ИСПРАВЛЕНО: Удаление заметки по Firebase ID (новый метод)
  Future<bool> deleteNoteByFirebaseId(String firebaseId) async {
    try {
      log('🗑️ Удаление заметки по Firebase ID: $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('fishing_notes');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            log('✅ Заметка удалена из Firebase: $firebaseId');
          } catch (e) {
            log('❌ Ошибка удаления из Firebase: $e');
            // Не возвращаем false, продолжаем удаление из Isar
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getFishingNoteByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteFishingNote(entity.id);
        log('✅ Заметка удалена из Isar: ${entity.id}');
      }

      return true;
    } catch (e) {
      log('❌ Ошибка deleteNoteByFirebaseId: $e');
      return false;
    }
  }

  /// Удаление заметки и синхронизация удаления с Firebase
  Future<bool> deleteNoteAndSync(int localId) async {
    try {
      final note = await _isarService.getFishingNoteById(localId);
      if (note == null) return false;

      // 🔥 ИСПРАВЛЕНО: Сначала удаляем из Firebase, потом из Isar
      if (note.firebaseId != null && await _hasInternetConnection()) {
        final collection = _getUserCollection('fishing_notes');
        if (collection != null) {
          try {
            // 🔥 ИСПРАВЛЕНО: Правильное удаление из Firebase
            await collection.doc(note.firebaseId).delete();
            log('✅ Заметка удалена из Firebase: ${note.firebaseId}');
          } catch (e) {
            log('❌ Ошибка удаления из Firebase: $e');
            // Не возвращаем false, продолжаем удаление из Isar
          }
        }
      }

      // Удаляем из Isar после успешного удаления из Firebase
      await _isarService.deleteFishingNote(localId);
      log('✅ Заметка удалена из Isar: $localId');

      return true;
    } catch (e) {
      log('❌ Ошибка deleteNoteAndSync: $e');
      return false;
    }
  }

  /// Получение статуса синхронизации всех типов данных
  Future<Map<String, dynamic>> getSyncStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {
        'fishingNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'budgetNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'markerMaps': {'total': 0, 'unsynced': 0, 'synced': 0},
      };
    }

    final fishingNotesTotal = await _isarService.getNotesCount();
    final fishingNotesUnsynced = await _isarService.getUnsyncedNotesCount();

    final budgetNotesTotal = await _isarService.getBudgetNotesCount(userId);
    final budgetNotesUnsynced = await _isarService.getUnsyncedBudgetNotesCount(userId);

    final markerMapsTotal = await _isarService.getMarkerMapsCount(userId);
    final markerMapsUnsynced = await _isarService.getUnsyncedMarkerMapsCount(userId);

    return {
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
    };
  }
}