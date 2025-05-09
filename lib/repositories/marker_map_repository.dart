// Путь: lib/repositories/marker_map_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  // Получить все маркерные карты пользователя
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final snapshot = await _firestore
          .collection('marker_maps')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MarkerMapModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Ошибка при получении маркерных карт: $e');
      rethrow;
    }
  }

  // Добавление новой маркерной карты
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, добавляем карту в Firestore
        final mapToAdd = map.copyWith(userId: userId);
        final docRef = await _firestore.collection('marker_maps').add(mapToAdd.toJson());

        // Синхронизируем офлайн карты, если они есть
        await _syncOfflineMaps();

        return docRef.id;
      } else {
        // Если нет интернета, сохраняем карту локально
        await _saveMapOffline(map.copyWith(userId: userId));
        return map.id;
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении маркерной карты: $e');
      rethrow;
    }
  }

  // Обновление маркерной карты
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем карту в Firestore
        await _firestore.collection('marker_maps').doc(map.id).update(map.toJson());
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

  // Получение маркерной карты по ID
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
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
      final List<String> offlineMaps = prefs.getStringList(_offlineMapsKey) ?? [];

      // Создаем ID для новой карты, если его нет
      final mapToSave = map.id.isEmpty
          ? map.copyWith(id: const Uuid().v4())
          : map;

      // Преобразуем в JSON и добавляем в список
      offlineMaps.add(mapToSave.toJson().toString());

      // Сохраняем обновленный список карт
      await prefs.setStringList(_offlineMapsKey, offlineMaps);
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
      final Map<String, dynamic> offlineUpdates = Map<String, dynamic>.from(
          offlineUpdatesJson.isNotEmpty ? offlineUpdatesJson as Map : {});

      // Добавляем обновление для этой карты
      offlineUpdates[map.id] = map.toJson();

      // Сохраняем обновленные данные
      await prefs.setString(_offlineMapUpdateKey, offlineUpdates.toString());
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
      final List<String> mapsToDelete = prefs.getStringList('maps_to_delete') ?? [];

      // Добавляем ID, если его ещё нет в списке
      if (!mapsToDelete.contains(mapId)) {
        mapsToDelete.add(mapId);
      }

      // Сохраняем обновленный список
      await prefs.setStringList('maps_to_delete', mapsToDelete);
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
      if (userId == null) return;

      final prefs = await _firebaseService.getSharedPreferences();

      // Синхронизация новых карт
      final List<String> offlineMaps = prefs.getStringList(_offlineMapsKey) ?? [];
      if (offlineMaps.isNotEmpty) {
        for (var mapJson in offlineMaps) {
          try {
            final map = MarkerMapModel.fromJson(
                Map<String, dynamic>.from(mapJson as Map));
            await _firestore.collection('marker_maps').add(map.toJson());
          } catch (e) {
            debugPrint('Ошибка при синхронизации карты: $e');
          }
        }
        // Очищаем список офлайн карт
        await prefs.setStringList(_offlineMapsKey, []);
      }

      // Синхронизация обновлений
      final String offlineUpdatesJson = prefs.getString(_offlineMapUpdateKey) ?? '{}';
      if (offlineUpdatesJson.isNotEmpty) {
        final Map<String, dynamic> updates = Map<String, dynamic>.from(
            offlineUpdatesJson as Map);
        for (var entry in updates.entries) {
          try {
            await _firestore.collection('marker_maps').doc(entry.key).update(entry.value);
          } catch (e) {
            debugPrint('Ошибка при синхронизации обновления карты: $e');
          }
        }
        // Очищаем список обновлений
        await prefs.setString(_offlineMapUpdateKey, '{}');
      }

      // Синхронизация удалений
      final List<String> mapsToDelete = prefs.getStringList('maps_to_delete') ?? [];
      if (mapsToDelete.isNotEmpty) {
        for (var mapId in mapsToDelete) {
          try {
            await _firestore.collection('marker_maps').doc(mapId).delete();
          } catch (e) {
            debugPrint('Ошибка при синхронизации удаления карты: $e');
          }
        }
        // Очищаем список ID для удаления
        await prefs.setStringList('maps_to_delete', []);
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