// Путь: lib/repositories/marker_map_repository.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/marker_map_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class MarkerMapRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Константы для хранения офлайн данных
  static const String _offlineMapsKey = 'offline_marker_maps';
  static const String _offlineMapUpdateKey = 'offline_marker_map_updates';
  static const String _mapsToDeleteKey = 'maps_to_delete';

  // Получить все маркерные карты пользователя
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('Запрос маркерных карт для пользователя: $userId');

      // Простой запрос без сложной сортировки, чтобы избежать проблем с индексами
      final snapshot = await _firestore
          .collection('marker_maps')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('Получено документов: ${snapshot.docs.length}');

      // Преобразуем документы в модели
      final List<MarkerMapModel> maps = snapshot.docs
          .map((doc) => MarkerMapModel.fromJson(doc.data(), id: doc.id))
          .toList();

      // Удаляем дубликаты на основе ID
      final Map<String, MarkerMapModel> uniqueMaps = {};
      for (var map in maps) {
        uniqueMaps[map.id] = map;
      }

      // Сортируем локально по дате (от новых к старым)
      final result = uniqueMaps.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return result;
    } catch (e) {
      debugPrint('Ошибка при получении маркерных карт: $e');
      // Если ошибка связана с индексом, пытаемся выполнить запрос без сортировки
      if (e.toString().contains('index')) {
        debugPrint('Ошибка индекса в Firestore, выполняем запрос без сортировки');
        try {
          final userId = _firebaseService.currentUserId;
          if (userId == null || userId.isEmpty) {
            throw Exception('Пользователь не авторизован');
          }

          final snapshot = await _firestore
              .collection('marker_maps')
              .where('userId', isEqualTo: userId)
              .get();

          final List<MarkerMapModel> maps = snapshot.docs
              .map((doc) => MarkerMapModel.fromJson(doc.data(), id: doc.id))
              .toList();

          // Удаляем дубликаты и сортируем локально
          final Map<String, MarkerMapModel> uniqueMaps = {};
          for (var map in maps) {
            uniqueMaps[map.id] = map;
          }

          final result = uniqueMaps.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return result;
        } catch (innerError) {
          debugPrint('Повторная ошибка при получении маркерных карт: $innerError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  // Добавление новой маркерной карты
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('Добавление маркерной карты для пользователя: $userId');

      // Генерируем уникальный ID, если его еще нет
      final String mapId = map.id.isEmpty ? const Uuid().v4() : map.id;
      final mapToAdd = map.copyWith(
        id: mapId,
        userId: userId, // Убедимся, что ID пользователя установлен
        // Убедимся, что дата установлена
        date: map.date ?? DateTime.now(),
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Перед сохранением, проверим, что userId точно установлен
        final jsonData = mapToAdd.toJson();
        if (jsonData['userId'] == null || jsonData['userId'].isEmpty) {
          jsonData['userId'] = userId; // Двойная проверка
        }

        debugPrint('Сохранение маркерной карты с данными: $jsonData');

        // Если есть интернет, добавляем карту в Firestore
        await _firestore.collection('marker_maps').doc(mapId).set(jsonData);

        // Синхронизируем офлайн карты, если они есть
        await _syncOfflineMaps();

        return mapId;
      } else {
        // Если нет интернета, сохраняем карту локально
        await _saveMapOffline(mapToAdd);
        return mapId;
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении маркерной карты: $e');
      rethrow;
    }
  }

  // Обновление маркерной карты
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    try {
      if (map.id.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Перед сохранением, убедимся что userId установлен
        final jsonData = map.toJson();
        if (jsonData['userId'] == null || jsonData['userId'].isEmpty) {
          jsonData['userId'] = userId;
        }

        // Если есть интернет, обновляем карту в Firestore
        await _firestore.collection('marker_maps').doc(map.id).update(jsonData);
      } else {
        // Если нет интернета, сохраняем обновление локально
        await _saveMapUpdateOffline(map);
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении маркерной карты: $e');
      rethrow;
    }
  }

  // Удаление маркерной карты
  Future<void> deleteMarkerMap(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, удаляем карту из Firestore
        await _firestore.collection('marker_maps').doc(mapId).delete();
      } else {
        // Если нет интернета, добавляем ID в список для удаления
        // при появлении интернета
        await _markMapForDeletion(mapId);
      }
    } catch (e) {
      debugPrint('Ошибка при удалении маркерной карты: $e');
      rethrow;
    }
  }

  // Удаление всех маркерных карт пользователя
  Future<void> clearAllMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем все карты пользователя и удаляем их
        final snapshot = await _firestore
            .collection('marker_maps')
            .where('userId', isEqualTo: userId)
            .get();

        // Создаем пакетную операцию для удаления
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Выполняем пакетное удаление
        await batch.commit();

        debugPrint('Удалено ${snapshot.docs.length} маркерных карт пользователя');
      } else {
        // Если нет интернета, сохраняем информацию о необходимости удаления всех карт
        // при появлении интернета
        final prefs = await _firebaseService.getSharedPreferences();
        await prefs.setBool('delete_all_marker_maps', true);

        // Также очищаем локальное хранилище карт
        await prefs.setStringList(_offlineMapsKey, []);
        await prefs.setString(_offlineMapUpdateKey, '{}');
      }
    } catch (e) {
      debugPrint('Ошибка при удалении всех маркерных карт: $e');
      rethrow;
    }
  }

  // Получение маркерной карты по ID
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      final doc = await _firestore.collection('marker_maps').doc(mapId).get();

      if (!doc.exists) {
        throw Exception('Маркерная карта не найдена');
      }

      return MarkerMapModel.fromJson(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Ошибка при получении маркерной карты по ID: $e');
      rethrow;
    }
  }

  // Приватные методы для офлайн функциональности

  // Сохранение маркерной карты в офлайн режиме
  Future<void> _saveMapOffline(MarkerMapModel map) async {
    try {
      final prefs = await _firebaseService.getSharedPreferences();

      // Получаем текущие офлайн карты
      final List<String> offlineMapsJson = prefs.getStringList(_offlineMapsKey) ?? [];

      // Преобразуем карту в JSON
      final mapJson = map.toJson();
      mapJson['id'] = map.id; // Добавляем ID в JSON, т.к. он обычно не сериализуется в toJson

      // Проверяем, есть ли уже карта с таким ID
      bool exists = false;
      final List<String> updatedMapsJson = [];

      for (var jsonStr in offlineMapsJson) {
        final mapData = Map<String, dynamic>.from(jsonDecode(jsonStr));
        if (mapData['id'] == map.id) {
          // Обновляем существующую карту
          updatedMapsJson.add(jsonEncode(mapJson));
          exists = true;
        } else {
          updatedMapsJson.add(jsonStr);
        }
      }

      // Если карты с таким ID нет, добавляем новую
      if (!exists) {
        updatedMapsJson.add(jsonEncode(mapJson));
      }

      // Сохраняем обновленный список карт
      await prefs.setStringList(_offlineMapsKey, updatedMapsJson);
    } catch (e) {
      debugPrint('Ошибка при сохранении карты офлайн: $e');
      rethrow;
    }
  }

  // Сохранение обновления маркерной карты в офлайн режиме
  Future<void> _saveMapUpdateOffline(MarkerMapModel map) async {
    try {
      final prefs = await _firebaseService.getSharedPreferences();

      // Получаем текущие офлайн обновления
      final String offlineUpdatesJson = prefs.getString(_offlineMapUpdateKey) ?? '{}';
      Map<String, dynamic> offlineUpdates;

      try {
        offlineUpdates = jsonDecode(offlineUpdatesJson) as Map<String, dynamic>;
      } catch (e) {
        // Если ошибка парсинга JSON, создаем пустой словарь
        debugPrint('Ошибка парсинга офлайн обновлений: $e');
        offlineUpdates = {};
      }

      // Преобразуем карту в JSON
      final mapJson = map.toJson();
      mapJson['id'] = map.id; // Добавляем ID в JSON

      // Добавляем обновление для этой карты
      offlineUpdates[map.id] = mapJson;

      // Сохраняем обновленные данные
      await prefs.setString(_offlineMapUpdateKey, jsonEncode(offlineUpdates));
    } catch (e) {
      debugPrint('Ошибка при сохранении обновления карты офлайн: $e');
      rethrow;
    }
  }

  // Отмечаем карту для удаления
  Future<void> _markMapForDeletion(String mapId) async {
    try {
      final prefs = await _firebaseService.getSharedPreferences();

      // Получаем список ID карт для удаления
      final List<String> mapsToDelete = prefs.getStringList(_mapsToDeleteKey) ?? [];

      // Добавляем ID, если его ещё нет в списке
      if (!mapsToDelete.contains(mapId)) {
        mapsToDelete.add(mapId);
      }

      // Сохраняем обновленный список
      await prefs.setStringList(_mapsToDeleteKey, mapsToDelete);
    } catch (e) {
      debugPrint('Ошибка при отметке карты для удаления: $e');
      rethrow;
    }
  }

  // Синхронизация офлайн карт с сервером
  Future<void> _syncOfflineMaps() async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (!isOnline) return;

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) return;

      final prefs = await _firebaseService.getSharedPreferences();

      // Проверяем, нужно ли удалить все карты
      final deleteAll = prefs.getBool('delete_all_marker_maps') ?? false;
      if (deleteAll) {
        try {
          final snapshot = await _firestore
              .collection('marker_maps')
              .where('userId', isEqualTo: userId)
              .get();

          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
          await prefs.setBool('delete_all_marker_maps', false);

          // Если все карты удалены, нет смысла синхронизировать что-либо еще
          return;
        } catch (e) {
          debugPrint('Ошибка при удалении всех карт: $e');
        }
      }

      // Синхронизация новых карт
      final List<String> offlineMapsJson = prefs.getStringList(_offlineMapsKey) ?? [];

      if (offlineMapsJson.isNotEmpty) {
        for (var mapJsonStr in offlineMapsJson) {
          try {
            final mapData = jsonDecode(mapJsonStr) as Map<String, dynamic>;

            // Убедимся, что есть ID
            if (mapData['id'] == null || mapData['id'].isEmpty) {
              mapData['id'] = const Uuid().v4();
            }

            // Убедимся, что есть userId
            if (mapData['userId'] == null || mapData['userId'].isEmpty) {
              mapData['userId'] = userId;
            }

            final mapId = mapData['id'];

            // Удаляем ID из данных, т.к. оно будет идентификатором документа
            mapData.remove('id');

            // Добавляем карту в Firestore
            await _firestore.collection('marker_maps').doc(mapId).set(mapData);
          } catch (e) {
            debugPrint('Ошибка при синхронизации карты: $e');
          }
        }

        // Очищаем список офлайн карт после успешной синхронизации
        await prefs.setStringList(_offlineMapsKey, []);
      }

      // Синхронизация обновлений
      final String offlineUpdatesJson = prefs.getString(_offlineMapUpdateKey) ?? '{}';

      try {
        final Map<String, dynamic> updates = jsonDecode(offlineUpdatesJson) as Map<String, dynamic>;

        for (var entry in updates.entries) {
          try {
            final mapId = entry.key;
            final mapData = entry.value as Map<String, dynamic>;

            // Убедимся, что есть userId
            if (mapData['userId'] == null || mapData['userId'].isEmpty) {
              mapData['userId'] = userId;
            }

            // Удаляем ID из данных, т.к. оно будет идентификатором документа
            if (mapData.containsKey('id')) {
              mapData.remove('id');
            }

            // Обновляем карту в Firestore
            await _firestore.collection('marker_maps').doc(mapId).update(mapData);
          } catch (e) {
            debugPrint('Ошибка при синхронизации обновления карты: $e');
          }
        }

        // Очищаем список обновлений
        await prefs.setString(_offlineMapUpdateKey, '{}');
      } catch (e) {
        debugPrint('Ошибка при парсинге офлайн обновлений: $e');
      }

      // Синхронизация удалений
      final List<String> mapsToDelete = prefs.getStringList(_mapsToDeleteKey) ?? [];

      if (mapsToDelete.isNotEmpty) {
        for (var mapId in mapsToDelete) {
          try {
            await _firestore.collection('marker_maps').doc(mapId).delete();
          } catch (e) {
            debugPrint('Ошибка при синхронизации удаления карты: $e');
          }
        }

        // Очищаем список ID для удаления
        await prefs.setStringList(_mapsToDeleteKey, []);
      }
    } catch (e) {
      debugPrint('Ошибка при синхронизации офлайн карт: $e');
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await _syncOfflineMaps();
  }
}