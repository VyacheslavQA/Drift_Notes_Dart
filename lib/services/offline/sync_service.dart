// Путь: lib/services/offline/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/isar/fishing_note_entity.dart';
import '../../models/isar/budget_note_entity.dart';
import '../../models/isar/marker_map_entity.dart';
import '../../models/isar/policy_acceptance_entity.dart';
import '../../models/isar/user_usage_limits_entity.dart'; // 🆕 ДОБАВЛЕНО
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
        log('Ошибка декодирования mapMarkers: $e');
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
          log('Ошибка декодирования AI tips: $e');
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
        log('Ошибка кодирования mapMarkers: $e');
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
          ..fishLength = biteMap['length']?.toDouble(); // length -> fishLength

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
          log('Ошибка кодирования AI tips: $e');
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
        log('Нет подключения к интернету для FishingNotes');
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedNotes();
      log('🔄 Найдено ${unsyncedNotes.length} несинхронизированных рыболовных заметок');

      for (final note in unsyncedNotes) {
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
              log('✅ Обновлена существующая рыболовная заметка: ${note.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(firebaseData);
              log('✅ Создана рыболовная заметка с существующим ID: ${note.firebaseId}');
            }
            await _isarService.markAsSynced(note.id, note.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(firebaseData);
            await _isarService.markAsSynced(note.id, docRef.id);
            log('✅ Создана новая рыболовная заметка: ${docRef.id}');
          }
        } catch (e) {
          log('❌ Ошибка синхронизации рыболовной заметки ${note.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncFishingNotesToFirebase: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация FishingNotes из Firestore в локальную БД
  Future<bool> syncFishingNotesFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для загрузки FishingNotes');
        return false;
      }

      final collection = _getUserCollection('fishing_notes');
      if (collection == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('📥 Получено ${querySnapshot.docs.length} рыболовных записей из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingNote = await _isarService.getFishingNoteByFirebaseId(firebaseId);

          if (existingNote == null) {
            final entity = _firestoreToFishingNoteEntity(firebaseId, data);
            await _isarService.insertFishingNote(entity);
            log('✅ Добавлена новая рыболовная заметка из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingNote.updatedAt)) {
              final updatedEntity = _firestoreToFishingNoteEntity(firebaseId, data);
              updatedEntity.id = existingNote.id;
              await _isarService.updateFishingNote(updatedEntity);
              log('✅ Обновлена рыболовная заметка из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('❌ Ошибка обработки рыболовного документа ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncFishingNotesFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ BUDGET NOTES
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация BudgetNotes с Firebase с проверкой существования документов
  Future<bool> syncBudgetNotesToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для BudgetNotes');
        return false;
      }

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedNotes = await _isarService.getUnsyncedBudgetNotes(userId);
      log('🔄 Найдено ${unsyncedNotes.length} несинхронизированных бюджетных заметок');

      for (final note in unsyncedNotes) {
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
              log('✅ Обновлена существующая бюджетная заметка: ${note.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(data);
              log('✅ Создана бюджетная заметка с существующим ID: ${note.firebaseId}');
            }
            await _isarService.markBudgetNoteAsSynced(note.id, note.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(data);
            await _isarService.markBudgetNoteAsSynced(note.id, docRef.id);
            log('✅ Создана новая бюджетная заметка: ${docRef.id}');
          }
        } catch (e) {
          log('❌ Ошибка синхронизации бюджетной заметки ${note.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncBudgetNotesToFirebase: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация BudgetNotes из Firebase с улучшенным логированием
  Future<bool> syncBudgetNotesFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для загрузки BudgetNotes');
        return false;
      }

      final collection = _getUserCollection('budget_notes');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('📥 Получено ${querySnapshot.docs.length} бюджетных записей из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingNote = await _isarService.getBudgetNoteByFirebaseId(firebaseId);

          if (existingNote == null) {
            final entity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertBudgetNote(entity);
            log('✅ Добавлена новая бюджетная заметка из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingNote.updatedAt)) {
              final updatedEntity = BudgetNoteEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingNote.id;
              await _isarService.updateBudgetNote(updatedEntity);
              log('✅ Обновлена бюджетная заметка из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('❌ Ошибка обработки бюджетного документа ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncBudgetNotesFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ MARKER MAPS
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация MarkerMaps с Firebase с проверкой существования документов
  Future<bool> syncMarkerMapsToFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для MarkerMaps');
        return false;
      }

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final unsyncedMaps = await _isarService.getUnsyncedMarkerMaps(userId);
      log('🔄 Найдено ${unsyncedMaps.length} несинхронизированных карт с маркерами');

      for (final map in unsyncedMaps) {
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
              log('✅ Обновлена существующая карта: ${map.firebaseId}');
            } else {
              // Документ не существует - создаем новый
              await docRef.set(data);
              log('✅ Создана карта с существующим ID: ${map.firebaseId}');
            }
            await _isarService.markMarkerMapAsSynced(map.id, map.firebaseId!);
          } else {
            // firebaseId == null - создаем новый документ
            final docRef = await collection.add(data);
            await _isarService.markMarkerMapAsSynced(map.id, docRef.id);
            log('✅ Создана новая карта: ${docRef.id}');
          }
        } catch (e) {
          log('❌ Ошибка синхронизации карты ${map.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncMarkerMapsToFirebase: $e');
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Синхронизация MarkerMaps из Firebase с улучшенным логированием
  Future<bool> syncMarkerMapsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для загрузки MarkerMaps');
        return false;
      }

      final collection = _getUserCollection('marker_maps');
      if (collection == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final querySnapshot = await collection.orderBy('date', descending: true).get();
      log('📥 Получено ${querySnapshot.docs.length} карт из Firebase');

      for (final doc in querySnapshot.docs) {
        try {
          final firebaseId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          final existingMap = await _isarService.getMarkerMapByFirebaseId(firebaseId);

          if (existingMap == null) {
            final entity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
            await _isarService.insertMarkerMap(entity);
            log('✅ Добавлена новая карта из Firebase: $firebaseId');
          } else {
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingMap.updatedAt)) {
              final updatedEntity = MarkerMapEntity.fromFirestoreMap(firebaseId, data);
              updatedEntity.id = existingMap.id;
              await _isarService.updateMarkerMap(updatedEntity);
              log('✅ Обновлена карта из Firebase: $firebaseId');
            }
          }
        } catch (e) {
          log('❌ Ошибка обработки карты ${doc.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncMarkerMapsFromFirebase: $e');
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
        log('Нет подключения к интернету для PolicyAcceptance');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('Пользователь не авторизован для синхронизации PolicyAcceptance');
        return false;
      }

      // Получаем коллекцию согласий пользователя
      final userConsentsCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents');

      final unsyncedPolicies = await _isarService.getUnsyncedPolicyAcceptances();
      log('🔄 Найдено ${unsyncedPolicies.length} несинхронизированных согласий политики');

      for (final policy in unsyncedPolicies) {
        try {
          final data = policy.toFirestoreMap();

          // PolicyAcceptance всегда использует фиксированный ID 'consents'
          final docRef = userConsentsCollection.doc('consents');
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Документ существует - обновляем
            await docRef.update(data);
            log('✅ Обновлены существующие согласия политики: consents');
          } else {
            // Документ не существует - создаем новый
            await docRef.set(data);
            log('✅ Созданы новые согласия политики: consents');
          }

          // Отмечаем как синхронизированные
          await _isarService.markPolicyAcceptanceAsSynced(policy.id, 'consents');
        } catch (e) {
          log('❌ Ошибка синхронизации согласий политики ${policy.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncPolicyAcceptanceToFirebase: $e');
      return false;
    }
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Синхронизация PolicyAcceptance из Firebase
  Future<bool> syncPolicyAcceptanceFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для загрузки PolicyAcceptance');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('Пользователь не авторизован для загрузки PolicyAcceptance');
        return false;
      }

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents')
          .doc('consents');

      final docSnapshot = await docRef.get();
      log('📥 Получение согласий политики из Firebase для пользователя: $userId');

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
            log('✅ Добавлены новые согласия политики из Firebase');
          } else {
            // Проверяем нужно ли обновление
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingPolicy.updatedAt)) {
              final updatedEntity = PolicyAcceptanceEntity.fromFirestoreMap(userId, data);
              updatedEntity.id = existingPolicy.id;
              await _isarService.updatePolicyAcceptance(updatedEntity);
              log('✅ Обновлены согласия политики из Firebase');
            } else {
              log('📋 Согласия политики уже актуальны');
            }
          }
        } catch (e) {
          log('❌ Ошибка обработки документа согласий политики: $e');
        }
      } else {
        log('📋 Согласия политики не найдены в Firebase');
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncPolicyAcceptanceFromFirebase: $e');
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
        log('Нет подключения к интернету для UserUsageLimits');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('Пользователь не авторизован для синхронизации UserUsageLimits');
        return false;
      }

      // Получаем коллекцию лимитов пользователя
      final userLimitsCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_usage_limits');

      final unsyncedLimits = await _isarService.getUnsyncedUserUsageLimits();
      log('🔄 Найдено ${unsyncedLimits.length} несинхронизированных лимитов пользователя');

      for (final limits in unsyncedLimits) {
        try {
          final data = limits.toFirestoreMap();

          // UserUsageLimits всегда использует фиксированный ID 'current'
          final docRef = userLimitsCollection.doc('current');
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Документ существует - обновляем
            await docRef.update(data);
            log('✅ Обновлены существующие лимиты пользователя: current');
          } else {
            // Документ не существует - создаем новый
            await docRef.set(data);
            log('✅ Созданы новые лимиты пользователя: current');
          }

          // Отмечаем как синхронизированные
          await _isarService.markUserUsageLimitsAsSynced(limits.id, 'current');

          if (limits.userId == userId) {
            log('✅ Синхронизированы лимиты: notes=${limits.notesCount}, budget=${limits.budgetNotesCount}, maps=${limits.markerMapsCount}');
          }
        } catch (e) {
          log('❌ Ошибка синхронизации лимитов пользователя ${limits.id}: $e');
        }
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncUserUsageLimitsToFirebase: $e');
      return false;
    }
  }

  /// 🆕 НОВОЕ: Синхронизация UserUsageLimits из Firebase
  Future<bool> syncUserUsageLimitsFromFirebase() async {
    try {
      if (!await _hasInternetConnection()) {
        log('Нет подключения к интернету для загрузки UserUsageLimits');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('Пользователь не авторизован для загрузки UserUsageLimits');
        return false;
      }

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_usage_limits')
          .doc('current');

      final docSnapshot = await docRef.get();
      log('📥 Получение лимитов пользователя из Firebase для пользователя: $userId');

      if (docSnapshot.exists) {
        try {
          final data = docSnapshot.data() as Map<String, dynamic>;

          // Ищем существующие лимиты пользователя в Isar
          final existingLimits = await _isarService.getUserUsageLimitsByUserId(userId);

          if (existingLimits == null) {
            // Создаем новые лимиты
            final entity = UserUsageLimitsEntity.fromFirestoreMap('current', data, userId);
            await _isarService.insertUserUsageLimits(entity);
            log('✅ Добавлены новые лимиты пользователя из Firebase');
            log('📊 Лимиты: notes=${entity.notesCount}, budget=${entity.budgetNotesCount}, maps=${entity.markerMapsCount}');
          } else {
            // Проверяем нужно ли обновление
            final firebaseUpdatedAt = _parseTimestamp(data['updatedAt']);
            if (firebaseUpdatedAt.isAfter(existingLimits.updatedAt)) {
              final updatedEntity = UserUsageLimitsEntity.fromFirestoreMap('current', data, userId);
              updatedEntity.id = existingLimits.id;
              await _isarService.updateUserUsageLimits(updatedEntity);
              log('✅ Обновлены лимиты пользователя из Firebase');
              log('📊 Новые лимиты: notes=${updatedEntity.notesCount}, budget=${updatedEntity.budgetNotesCount}, maps=${updatedEntity.markerMapsCount}');
            } else {
              log('📋 Лимиты пользователя уже актуальны');
            }
          }
        } catch (e) {
          log('❌ Ошибка обработки документа лимитов пользователя: $e');
        }
      } else {
        log('📋 Лимиты пользователя не найдены в Firebase - это нормально для новых пользователей');
      }

      return true;
    } catch (e) {
      log('❌ Ошибка syncUserUsageLimitsFromFirebase: $e');
      return false;
    }
  }

  // ========================================
  // ✅ НОВЫЕ МЕТОДЫ УДАЛЕНИЯ (ЭТАП 15)
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Удаление заметки по Firebase ID с улучшенным логированием
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

  /// ✅ НОВОЕ: Удаление заметки бюджета по Firebase ID с улучшенным логированием
  Future<bool> deleteBudgetNoteByFirebaseId(String firebaseId) async {
    try {
      log('🗑️ Удаление заметки бюджета по Firebase ID: $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('budget_notes');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            log('✅ Заметка бюджета удалена из Firebase: $firebaseId');
          } catch (e) {
            log('❌ Ошибка удаления заметки бюджета из Firebase: $e');
            // Не возвращаем false, продолжаем удаление из Isar
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getBudgetNoteByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteBudgetNote(entity.id);
        log('✅ Заметка бюджета удалена из Isar: ${entity.id}');
      } else {
        log('⚠️ Заметка бюджета не найдена в Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      log('❌ Ошибка deleteBudgetNoteByFirebaseId: $e');
      return false;
    }
  }

  /// ✅ НОВОЕ: Удаление маркерной карты по Firebase ID с улучшенным логированием
  Future<bool> deleteMarkerMapByFirebaseId(String firebaseId) async {
    try {
      log('🗑️ Удаление маркерной карты по Firebase ID: $firebaseId');

      // Сначала удаляем из Firebase
      if (await _hasInternetConnection()) {
        final collection = _getUserCollection('marker_maps');
        if (collection != null) {
          try {
            await collection.doc(firebaseId).delete();
            log('✅ Маркерная карта удалена из Firebase: $firebaseId');
          } catch (e) {
            log('❌ Ошибка удаления маркерной карты из Firebase: $e');
            // Не возвращаем false, продолжаем удаление из Isar
          }
        }
      }

      // Затем находим и удаляем из Isar по firebaseId
      final entity = await _isarService.getMarkerMapByFirebaseId(firebaseId);
      if (entity != null) {
        await _isarService.deleteMarkerMapByFirebaseId(firebaseId);
        log('✅ Маркерная карта удалена из Isar: ${entity.id}');
      } else {
        log('⚠️ Маркерная карта не найдена в Isar: $firebaseId');
      }

      return true;
    } catch (e) {
      log('❌ Ошибка deleteMarkerMapByFirebaseId: $e');
      return false;
    }
  }

  // ========================================
  // ОБНОВЛЕННЫЕ ОБЩИЕ МЕТОДЫ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Удаление заметки и синхронизация удаления с Firebase
  Future<bool> deleteNoteAndSync(int localId) async {
    try {
      log('🗑️ Удаление и синхронизация заметки с localId: $localId');

      final note = await _isarService.getFishingNoteById(localId);
      if (note == null) {
        log('⚠️ Заметка с ID $localId не найдена в Isar');
        return false;
      }

      // Сначала удаляем из Firebase, потом из Isar
      if (note.firebaseId != null && await _hasInternetConnection()) {
        final collection = _getUserCollection('fishing_notes');
        if (collection != null) {
          try {
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

  /// ✅ ОБНОВЛЕНО: Синхронизация всех данных в Firebase включая UserUsageLimits
  Future<bool> syncAll() async {
    try {
      log('🔄 Начинается синхронизация всех данных в Firebase');

      final results = await Future.wait([
        syncFishingNotesToFirebase(),
        syncBudgetNotesToFirebase(),
        syncMarkerMapsToFirebase(),
        syncPolicyAcceptanceToFirebase(),
        syncUserUsageLimitsToFirebase(), // 🆕 ДОБАВЛЕНО
      ]);

      final success = results.every((result) => result);
      log('📤 Синхронизация всех данных в Firebase завершена. Успех: $success');
      log('📊 Результаты: FishingNotes=${results[0]}, BudgetNotes=${results[1]}, MarkerMaps=${results[2]}, PolicyAcceptance=${results[3]}, UserUsageLimits=${results[4]}');

      return success;
    } catch (e) {
      log('❌ Ошибка syncAll: $e');
      return false;
    }
  }

  /// ✅ ОБНОВЛЕНО: Полная двусторонняя синхронизация всех типов данных включая UserUsageLimits
  Future<bool> fullSync() async {
    try {
      log('🔄 Начинается полная двусторонняя синхронизация');

      // Отправляем локальные изменения в Firebase
      log('📤 Этап 1: Отправка локальных изменений в Firebase');
      final toFirebaseResults = await Future.wait([
        syncFishingNotesToFirebase(),
        syncBudgetNotesToFirebase(),
        syncMarkerMapsToFirebase(),
        syncPolicyAcceptanceToFirebase(),
        syncUserUsageLimitsToFirebase(), // 🆕 ДОБАВЛЕНО
      ]);

      // Получаем обновления из Firebase
      log('📥 Этап 2: Получение обновлений из Firebase');
      final fromFirebaseResults = await Future.wait([
        syncFishingNotesFromFirebase(),
        syncBudgetNotesFromFirebase(),
        syncMarkerMapsFromFirebase(),
        syncPolicyAcceptanceFromFirebase(),
        syncUserUsageLimitsFromFirebase(), // 🆕 ДОБАВЛЕНО
      ]);

      final success = [...toFirebaseResults, ...fromFirebaseResults].every((result) => result);
      log('✅ Полная синхронизация завершена. Общий успех: $success');
      log('📊 К Firebase: FishingNotes=${toFirebaseResults[0]}, BudgetNotes=${toFirebaseResults[1]}, MarkerMaps=${toFirebaseResults[2]}, PolicyAcceptance=${toFirebaseResults[3]}, UserUsageLimits=${toFirebaseResults[4]}');
      log('📊 Из Firebase: FishingNotes=${fromFirebaseResults[0]}, BudgetNotes=${fromFirebaseResults[1]}, MarkerMaps=${fromFirebaseResults[2]}, PolicyAcceptance=${fromFirebaseResults[3]}, UserUsageLimits=${fromFirebaseResults[4]}');

      return success;
    } catch (e) {
      log('❌ Ошибка fullSync: $e');
      return false;
    }
  }

  /// Принудительная полная синхронизация
  Future<bool> forceSyncAll() async {
    log('🔄 Запуск принудительной полной синхронизации');
    return await fullSync();
  }

  /// Публичный метод для внешнего использования
  Future<bool> performFullSync() async {
    return await fullSync();
  }

  /// ✅ УЛУЧШЕНО: Периодическая синхронизация с логированием
  void startPeriodicSync() {
    log('⏰ Запуск периодической синхронизации (каждые 5 минут)');
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (await _hasInternetConnection()) {
        log('⏰ Выполнение периодической синхронизации');
        final result = await fullSync();
        log('⏰ Периодическая синхронизация завершена: $result');
      } else {
        log('⏰ Периодическая синхронизация пропущена - нет интернета');
      }
    });
  }

  /// ✅ ОБНОВЛЕНО: Получение статуса синхронизации всех типов данных включая UserUsageLimits
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('⚠️ Пользователь не авторизован для получения статуса синхронизации');
        return {
          'fishingNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
          'budgetNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
          'markerMaps': {'total': 0, 'unsynced': 0, 'synced': 0},
          'policyAcceptance': {'total': 0, 'unsynced': 0, 'synced': 0},
          'userUsageLimits': {'total': 0, 'unsynced': 0, 'synced': 0}, // 🆕 ДОБАВЛЕНО
        };
      }

      log('📊 Получение статуса синхронизации для пользователя: $userId');

      final fishingNotesTotal = await _isarService.getNotesCount();
      final fishingNotesUnsynced = await _isarService.getUnsyncedNotesCount();

      final budgetNotesTotal = await _isarService.getBudgetNotesCount(userId);
      final budgetNotesUnsynced = await _isarService.getUnsyncedBudgetNotesCount(userId);

      final markerMapsTotal = await _isarService.getMarkerMapsCount(userId);
      final markerMapsUnsynced = await _isarService.getUnsyncedMarkerMapsCount(userId);

      final policyAcceptanceTotal = await _isarService.getPolicyAcceptancesCount();
      final policyAcceptanceUnsynced = await _isarService.getUnsyncedPolicyAcceptancesCount();

      // 🆕 ДОБАВЛЕНО: Статус синхронизации UserUsageLimits
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
        'userUsageLimits': { // 🆕 ДОБАВЛЕНО
          'total': userUsageLimitsTotal,
          'unsynced': userUsageLimitsUnsynced,
          'synced': userUsageLimitsTotal - userUsageLimitsUnsynced,
        },
      };

      log('📊 Статус синхронизации: FishingNotes(${fishingNotesTotal}/${fishingNotesUnsynced}), BudgetNotes(${budgetNotesTotal}/${budgetNotesUnsynced}), MarkerMaps(${markerMapsTotal}/${markerMapsUnsynced}), PolicyAcceptance(${policyAcceptanceTotal}/${policyAcceptanceUnsynced}), UserUsageLimits(${userUsageLimitsTotal}/${userUsageLimitsUnsynced})');

      return status;
    } catch (e) {
      log('❌ Ошибка получения статуса синхронизации: $e');
      return {
        'fishingNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'budgetNotes': {'total': 0, 'unsynced': 0, 'synced': 0},
        'markerMaps': {'total': 0, 'unsynced': 0, 'synced': 0},
        'policyAcceptance': {'total': 0, 'unsynced': 0, 'synced': 0},
        'userUsageLimits': {'total': 0, 'unsynced': 0, 'synced': 0}, // 🆕 ДОБАВЛЕНО
        'error': e.toString(),
      };
    }
  }
}