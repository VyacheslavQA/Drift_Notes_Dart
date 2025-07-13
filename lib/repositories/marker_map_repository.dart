// Путь: lib/repositories/marker_map_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/marker_map_model.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';
import '../services/offline/offline_storage_service.dart';
import '../services/offline/sync_service.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';

class MarkerMapRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // 🔥 ИСПРАВЛЕНО: Получить все маркерные карты пользователя из НОВОЙ структуры
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Запрос маркерных карт для пользователя: $userId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        debugPrint('📍 Загружаем карты из НОВОЙ структуры Firebase...');

        // 🔥 ИСПРАВЛЕНО: Используем НОВУЮ структуру через FirebaseService
        final snapshot = await _firebaseService.getUserMarkerMaps();
        debugPrint('📍 Получено ${snapshot.docs.length} карт из Firebase');

        // Преобразуем документы в модели
        final onlineMaps = snapshot.docs
            .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return MarkerMapModel.fromJson(data, id: doc.id);
          } catch (e) {
            debugPrint('❌ Ошибка парсинга карты ${doc.id}: $e');
            return null;
          }
        })
            .where((map) => map != null)
            .cast<MarkerMapModel>()
            .toList();

        debugPrint('📍 Успешно обработано ${onlineMaps.length} карт');

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

        debugPrint('✅ Получено ${result.length} уникальных карт');

        // Запускаем синхронизацию в фоне
        _syncService.syncAll();

        // Обновляем лимиты после загрузки карт
        try {
          await _subscriptionService.refreshUsageLimits();
        } catch (e) {
          debugPrint('Ошибка обновления лимитов после загрузки карт: $e');
        }

        return result;
      } else {
        debugPrint('📱 Получение маркерных карт из офлайн хранилища');

        // Если нет подключения, получаем карты из офлайн хранилища
        return await _getOfflineMarkerMaps(userId);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении маркерных карт: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн карты
      try {
        return await _getOfflineMarkerMaps(
          _firebaseService.currentUserId ?? '',
        );
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
          .map((map) {
        try {
          return MarkerMapModel.fromJson(map, id: map['id'] as String);
        } catch (e) {
          debugPrint('❌ Ошибка парсинга офлайн карты: $e');
          return null;
        }
      })
          .where((map) => map != null)
          .cast<MarkerMapModel>()
          .toList();

      // Сортируем по дате (от новых к старым)
      offlineMapModels.sort((a, b) => b.date.compareTo(a.date));

      return offlineMapModels;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн маркерных карт: $e');
      return [];
    }
  }

  // ✅ ИСПРАВЛЕНО: Добавление новой маркерной карты (убрано двойное увеличение счетчиков)
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Добавление маркерной карты для пользователя: $userId');

      // ✅ КРИТИЧНО: Проверяем лимиты ДО создания карты
      final canCreate = await _subscriptionService.canCreateContentOffline(
        ContentType.markerMaps,
      );

      if (!canCreate) {
        throw Exception('Достигнут лимит создания маркерных карт');
      }

      // Генерируем уникальный ID, если его еще нет
      final String mapId = map.id.isEmpty ? const Uuid().v4() : map.id;

      // Создаем копию карты с установленным ID и UserID
      final mapToAdd = map.copyWith(
        id: mapId,
        userId: userId,
        date: map.date,
      );

      debugPrint('📍 Создаем карту с ID: $mapId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Используем FirebaseService для добавления в НОВУЮ структуру
        try {
          await _firebaseService.addMarkerMap(mapToAdd.toJson());
          debugPrint('✅ Маркерная карта добавлена в НОВУЮ структуру: $mapId');

          // ✅ ИСПРАВЛЕНИЕ: Увеличиваем счетчик ТОЛЬКО через FirebaseService (онлайн режим)
          try {
            await _firebaseService.incrementUsageCount('markerMapsCount');
            debugPrint('✅ Счетчик маркерных карт увеличен через Firebase');
          } catch (e) {
            debugPrint('❌ Ошибка увеличения счетчика через Firebase: $e');
            // Не прерываем выполнение, карта уже сохранена
          }

        } catch (e) {
          debugPrint('❌ Ошибка добавления в Firebase, сохраняем офлайн: $e');
          await _saveMapOffline(mapToAdd);

          // ✅ ИСПРАВЛЕНИЕ: Увеличиваем счетчик ТОЛЬКО через SubscriptionService (офлайн режим)
          try {
            await _subscriptionService.incrementUsage(ContentType.markerMaps);
            debugPrint('✅ Счетчик маркерных карт увеличен через SubscriptionService');
          } catch (e) {
            debugPrint('❌ Ошибка увеличения счетчика через SubscriptionService: $e');
            // Не прерываем выполнение, карта уже сохранена
          }
        }

        // Синхронизируем офлайн карты, если они есть
        _syncService.syncAll();

        debugPrint('✅ Маркерная карта добавлена онлайн: $mapId');
      } else {
        // Если нет интернета, сохраняем карту локально
        await _saveMapOffline(mapToAdd);

        // ✅ ИСПРАВЛЕНИЕ: Увеличиваем счетчик ТОЛЬКО через SubscriptionService (офлайн режим)
        try {
          await _subscriptionService.incrementUsage(ContentType.markerMaps);
          debugPrint('✅ Счетчик маркерных карт увеличен офлайн');
        } catch (e) {
          debugPrint('❌ Ошибка увеличения счетчика офлайн: $e');
          // Не прерываем выполнение, карта уже сохранена
        }

        debugPrint('✅ Маркерная карта добавлена офлайн: $mapId');
      }

      return mapId;
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении маркерной карты: $e');
      rethrow;
    }
  }

  // Сохранение карты в офлайн режиме
  Future<void> _saveMapOffline(MarkerMapModel map) async {
    try {
      await _offlineStorage.saveOfflineMarkerMap(map.toJson());
      debugPrint('📱 Маркерная карта ${map.id} сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении карты офлайн: $e');
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Обновление маркерной карты в НОВОЙ структуре
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    try {
      if (map.id.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Обновление маркерной карты: ${map.id}');

      // Создаем копию карты с установленным UserID
      final mapToUpdate = map.copyWith(userId: userId);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Используем FirebaseService для обновления в НОВОЙ структуре
        try {
          await _firebaseService.updateMarkerMap(map.id, mapToUpdate.toJson());
          debugPrint('✅ Маркерная карта обновлена в НОВОЙ структуре: ${map.id}');
        } catch (e) {
          debugPrint('❌ Ошибка обновления в Firebase, сохраняем офлайн: $e');
          await _offlineStorage.saveMarkerMapUpdate(map.id, mapToUpdate.toJson());
        }
      } else {
        // Если нет интернета, сохраняем обновление локально
        await _offlineStorage.saveMarkerMapUpdate(map.id, mapToUpdate.toJson());

        debugPrint('✅ Маркерная карта обновлена офлайн: ${map.id}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении маркерной карты: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveMarkerMapUpdate(map.id, map.toJson());
      } catch (_) {
        rethrow;
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Удаление маркерной карты (убрано двойное уменьшение счетчиков)
  Future<void> deleteMarkerMap(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      debugPrint('📍 Удаление маркерной карты: $mapId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Используем FirebaseService для удаления из НОВОЙ структуры
        try {
          await _firebaseService.deleteMarkerMap(mapId);
          debugPrint('✅ Маркерная карта удалена из НОВОЙ структуры: $mapId');

          // ✅ ИСПРАВЛЕНИЕ: Уменьшаем счетчик ТОЛЬКО через FirebaseService (онлайн режим)
          // НЕ через SubscriptionService чтобы избежать двойного уменьшения
          // FirebaseService уже обрабатывает счетчики в онлайн режиме

        } catch (e) {
          debugPrint('❌ Ошибка удаления из Firebase, отмечаем для удаления: $e');
          await _offlineStorage.markForDeletion(mapId, true);

          // ✅ ИСПРАВЛЕНИЕ: Уменьшаем счетчик ТОЛЬКО через SubscriptionService (офлайн режим)
          try {
            await _subscriptionService.decrementUsage(ContentType.markerMaps);
            debugPrint('✅ Счетчик маркерных карт уменьшен через SubscriptionService');
          } catch (e) {
            debugPrint('❌ Ошибка уменьшения счетчика через SubscriptionService: $e');
            // Не прерываем выполнение, карта уже отмечена для удаления
          }
        }

        // Удаляем локальную копию, если она есть
        try {
          await _offlineStorage.removeOfflineMarkerMap(mapId);
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении локальной копии карты: $e');
        }

        debugPrint('✅ Маркерная карта удалена онлайн: $mapId');
      } else {
        // Если нет интернета, отмечаем карту для удаления
        await _offlineStorage.markForDeletion(mapId, true);

        // Удаляем локальную копию
        try {
          await _offlineStorage.removeOfflineMarkerMap(mapId);
        } catch (e) {
          debugPrint('⚠️ Ошибка при удалении локальной копии карты: $e');
        }

        // ✅ ИСПРАВЛЕНИЕ: Уменьшаем счетчик ТОЛЬКО через SubscriptionService (офлайн режим)
        try {
          await _subscriptionService.decrementUsage(ContentType.markerMaps);
          debugPrint('✅ Счетчик маркерных карт уменьшен офлайн');
        } catch (e) {
          debugPrint('❌ Ошибка уменьшения счетчика офлайн: $e');
          // Не прерываем выполнение, карта уже отмечена для удаления
        }

        debugPrint('✅ Маркерная карта отмечена для удаления: $mapId');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении маркерной карты: $e');

      // В случае ошибки, отмечаем карту для удаления
      try {
        await _offlineStorage.markForDeletion(mapId, true);
      } catch (_) {
        rethrow;
      }
    }
  }

  // 🔥 ИСПРАВЛЕНО: Получение маркерной карты по ID из НОВОЙ структуры
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Получение маркерной карты по ID: $mapId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Получаем из НОВОЙ структуры через FirebaseService
        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('marker_maps')
              .doc(mapId)
              .get();

          if (doc.exists) {
            debugPrint('✅ Карта найдена в НОВОЙ структуре: $mapId');
            return MarkerMapModel.fromJson(doc.data()!, id: doc.id);
          } else {
            debugPrint('⚠️ Карта не найдена в НОВОЙ структуре, ищем офлайн: $mapId');
          }
        } catch (e) {
          debugPrint('❌ Ошибка получения из Firebase: $e');
        }
      } else {
        debugPrint('📱 Офлайн режим: ищем карту в офлайн хранилище');
      }

      // Если не найдена онлайн или нет интернета, ищем в офлайн хранилище
      return await _getOfflineMarkerMapById(mapId);
    } catch (e) {
      debugPrint('❌ Ошибка при получении маркерной карты по ID: $e');

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
        orElse: () => throw Exception(
          'Маркерная карта не найдена в офлайн хранилище',
        ),
      );

      return MarkerMapModel.fromJson(mapData, id: mapId);
    } catch (e) {
      debugPrint(
        '❌ Ошибка при получении маркерной карты из офлайн хранилища: $e',
      );
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Удаление всех маркерных карт пользователя из НОВОЙ структуры
  Future<void> clearAllMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Удаление всех маркерных карт пользователя: $userId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // 🔥 ИСПРАВЛЕНО: Получаем и удаляем все карты из НОВОЙ структуры
        final snapshot = await _firebaseService.getUserMarkerMaps();

        // Создаем пакетную операцию для удаления
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Выполняем пакетное удаление
        await batch.commit();

        debugPrint(
          '✅ Удалено ${snapshot.docs.length} маркерных карт из НОВОЙ структуры',
        );
      } else {
        // Если нет интернета, отмечаем все карты для удаления
        await _offlineStorage.markAllMarkerMapsForDeletion();
        debugPrint('📱 Все карты отмечены для удаления (офлайн)');
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
        debugPrint('✅ Локальное хранилище карт очищено');
      } catch (e) {
        debugPrint('❌ Ошибка при очистке локального хранилища карт: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении всех маркерных карт: $e');

      // В случае ошибки, отмечаем все карты для удаления
      try {
        await _offlineStorage.markAllMarkerMapsForDeletion();
      } catch (_) {
        rethrow;
      }
    }
  }

  // Проверка возможности создания новой маркерной карты
  Future<bool> canCreateMarkerMap() async {
    try {
      return await _subscriptionService.canCreateContentOffline(
        ContentType.markerMaps,
      );
    } catch (e) {
      debugPrint('❌ Ошибка при проверке возможности создания карты: $e');
      return false;
    }
  }

  // Получение текущего использования маркерных карт
  Future<int> getCurrentUsage() async {
    try {
      return await _subscriptionService.getCurrentOfflineUsage(
        ContentType.markerMaps,
      );
    } catch (e) {
      debugPrint('❌ Ошибка при получении текущего использования карт: $e');
      return 0;
    }
  }

  // Получение лимита маркерных карт
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.markerMaps);
    } catch (e) {
      debugPrint('❌ Ошибка при получении лимита карт: $e');
      return 0;
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
      debugPrint('❌ Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  // Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }
}