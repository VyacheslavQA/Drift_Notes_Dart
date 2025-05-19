// Путь: lib/repositories/marker_map_repository.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/marker_map_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
import '../services/offline/offline_storage_service.dart';
import '../services/offline/sync_service.dart';

class MarkerMapRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();

  // Получить все маркерные карты пользователя
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        debugPrint('Запрос маркерных карт для пользователя: $userId');

        // Если есть подключение, получаем карты из Firestore
        final snapshot = await _firestore
            .collection('marker_maps')
            .where('userId', isEqualTo: userId)
            .get();

        debugPrint('Получено документов: ${snapshot.docs.length}');

        // Преобразуем документы в модели
        final onlineMaps = snapshot.docs
            .map((doc) => MarkerMapModel.fromJson(doc.data(), id: doc.id))
            .toList();

        // Получаем офлайн карты, которые еще не были синхронизированы
        final offlineMaps = await _getOfflineMarkerMaps(userId);

        // Объединяем списки, избегая дубликатов
        final allMaps = [...onlineMaps];

        for (var offlineMap in offlineMaps) {
          // Проверяем, что такой карты еще нет в списке
          if (!allMaps.any((map) => map.id == offlineMap.id)) {
            allMaps.add(offlineMap);
          }
        }

        // Удаляем дубликаты на основе ID
        final Map<String, MarkerMapModel> uniqueMaps = {};
        for (var map in allMaps) {
          uniqueMaps[map.id] = map;
        }

        // Сортируем локально по дате (от новых к старым)
        final result = uniqueMaps.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Запускаем синхронизацию в фоне
        _syncService.syncAll();

        return result;
      } else {
        debugPrint('Получение маркерных карт из офлайн хранилища');

        // Если нет подключения, получаем карты из офлайн хранилища
        return await _getOfflineMarkerMaps(userId);
      }
    } catch (e) {
      debugPrint('Ошибка при получении маркерных карт: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн карты
      try {
        return await _getOfflineMarkerMaps(_firebaseService.currentUserId ?? '');
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение маркерных карт из офлайн хранилища
  Future<List<MarkerMapModel>> _getOfflineMarkerMaps(String userId) async {
    try {
      final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();

      // Фильтруем и преобразуем данные в модели
      final offlineMapModels = offlineMaps
          .where((map) => map['userId'] == userId) // Фильтруем по userId
          .map((map) => MarkerMapModel.fromJson(map, id: map['id'] as String))
          .toList();

      // Сортируем по дате (от новых к старым)
      offlineMapModels.sort((a, b) => b.date.compareTo(a.date));

      return offlineMapModels;
    } catch (e) {
      debugPrint('Ошибка при получении офлайн маркерных карт: $e');
      return [];
    }
  }

  // Добавление новой маркерной карты
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем уникальный ID, если его еще нет
      final String mapId = map.id.isEmpty ? const Uuid().v4() : map.id;

      // Создаем копию карты с установленным ID и UserID
      final mapToAdd = map.copyWith(
        id: mapId,
        userId: userId,
        // Убедимся, что дата установлена
        date: map.date ?? DateTime.now(),
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, добавляем карту в Firestore
        await _firestore.collection('marker_maps').doc(mapId).set(mapToAdd.toJson());

        // Синхронизируем офлайн карты, если они есть
        await _syncService.syncAll();

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

  // Сохранение карты в офлайн режиме
  Future<void> _saveMapOffline(MarkerMapModel map) async {
    try {
      await _offlineStorage.saveOfflineMarkerMap(map.toJson());
      debugPrint('Маркерная карта ${map.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('Ошибка при сохранении карты офлайн: $e');
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

      // Создаем копию карты с установленным UserID
      final mapToUpdate = map.copyWith(userId: userId);

      if (isOnline) {
        // Если есть интернет, обновляем карту в Firestore
        await _firestore.collection('marker_maps').doc(map.id).update(mapToUpdate.toJson());
      } else {
        // Если нет интернета, сохраняем обновление локально
        await _offlineStorage.saveMarkerMapUpdate(map.id, mapToUpdate.toJson());
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении маркерной карты: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveMarkerMapUpdate(map.id, map.toJson());
      } catch (_) {
        rethrow;
      }
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

        // Удаляем локальную копию, если она есть
        try {
          await _offlineStorage.removeOfflineMarkerMap(mapId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии карты: $e');
        }
      } else {
        // Если нет интернета, отмечаем карту для удаления
        await _offlineStorage.markForDeletion(mapId, true);

        // Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineMarkerMap(mapId);
        } catch (e) {
          debugPrint('Ошибка при удалении локальной копии карты: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при удалении маркерной карты: $e');

      // В случае ошибки, отмечаем карту для удаления
      try {
        await _offlineStorage.markForDeletion(mapId, true);
      } catch (_) {
        rethrow;
      }
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
        // Если нет интернета, отмечаем все карты для удаления
        await _offlineStorage.markAllMarkerMapsForDeletion();
      }

      // В любом случае, очищаем локальное хранилище карт
      try {
        final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
        for (var map in offlineMaps) {
          final mapId = map['id'];
          if (mapId != null) {
            await _offlineStorage.removeOfflineMarkerMap(mapId);
          }
        }
      } catch (e) {
        debugPrint('Ошибка при очистке локального хранилища карт: $e');
      }
    } catch (e) {
      debugPrint('Ошибка при удалении всех маркерных карт: $e');

      // В случае ошибки, отмечаем все карты для удаления
      try {
        await _offlineStorage.markAllMarkerMapsForDeletion();
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение маркерной карты по ID
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем карту из Firestore
        final doc = await _firestore.collection('marker_maps').doc(mapId).get();

        if (!doc.exists) {
          // Если карта не найдена в Firestore, пробуем найти в офлайн хранилище
          return await _getOfflineMarkerMapById(mapId);
        }

        return MarkerMapModel.fromJson(doc.data()!, id: doc.id);
      } else {
        // Если нет интернета, ищем карту в офлайн хранилище
        return await _getOfflineMarkerMapById(mapId);
      }
    } catch (e) {
      debugPrint('Ошибка при получении маркерной карты по ID: $e');

      // В случае ошибки, пытаемся получить карту из офлайн хранилища
      try {
        return await _getOfflineMarkerMapById(mapId);
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение маркерной карты из офлайн хранилища по ID
  Future<MarkerMapModel> _getOfflineMarkerMapById(String mapId) async {
    try {
      final allOfflineMaps = await _offlineStorage.getAllOfflineMarkerMaps();

      // Ищем карту по ID
      final mapData = allOfflineMaps.firstWhere(
            (map) => map['id'] == mapId,
        orElse: () => throw Exception('Маркерная карта не найдена в офлайн хранилище'),
      );

      return MarkerMapModel.fromJson(mapData, id: mapId);
    } catch (e) {
      debugPrint('Ошибка при получении маркерной карты из офлайн хранилища: $e');
      rethrow;
    }
  }

  // Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await _syncService.syncAll();
  }

  // Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      return await _syncService.forceSyncAll();
    } catch (e) {
      debugPrint('Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  // Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }
}