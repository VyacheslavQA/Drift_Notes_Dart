// Путь: lib/repositories/marker_map_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/marker_map_model.dart';
import '../models/isar/marker_map_entity.dart'; // ✅ ИСПРАВЛЕНО: правильный путь
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';
import '../utils/network_utils.dart';

class MarkerMapRepository {
  static final MarkerMapRepository _instance = MarkerMapRepository._internal();

  factory MarkerMapRepository() {
    return _instance;
  }

  MarkerMapRepository._internal();

  final SubscriptionService _subscriptionService = SubscriptionService();

  // ✅ Кэш для предотвращения повторных загрузок
  static List<MarkerMapModel>? _cachedMaps;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // ✅ Инициализация репозитория
  Future<void> initialize() async {
    try {
      // Репозиторий готов к работе после инициализации IsarService
      if (kDebugMode) {
        debugPrint('✅ MarkerMapRepository инициализирован с поддержкой Isar');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка инициализации MarkerMapRepository: $e');
      }
      rethrow;
    }
  }

  // ✅ ОСНОВНОЙ МЕТОД: Получить все маркерные карты пользователя
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      if (kDebugMode) {
        debugPrint('📍 Запрос маркерных карт пользователя через Isar');
      }

      // Проверяем кэш
      if (_cachedMaps != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          if (kDebugMode) {
            debugPrint('💾 Возвращаем карты из кэша (возраст: ${cacheAge.inSeconds}с)');
          }
          return _cachedMaps!;
        } else {
          if (kDebugMode) {
            debugPrint('💾 Кэш карт устарел, очищаем');
          }
          clearCache();
        }
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем карты из Isar
      final markerMapEntities = await IsarService.instance.getAllMarkerMaps(userId);

      if (kDebugMode) {
        debugPrint('💾 Найдено карт в Isar: ${markerMapEntities.length}');
      }

      // Преобразуем entities в models
      final markerMaps = markerMapEntities
          .map((entity) => _entityToModel(entity))
          .toList();

      // Сортируем по дате (от новых к старым)
      markerMaps.sort((a, b) => b.date.compareTo(a.date));

      // Кэшируем результат
      _cachedMaps = markerMaps;
      _cacheTimestamp = DateTime.now();

      if (kDebugMode) {
        debugPrint('✅ Загружено ${markerMaps.length} маркерных карт из Isar');
      }

      // Запускаем синхронизацию в фоне, если есть интернет
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ Ошибка фоновой синхронизации: $e');
          }
        });
      }

      return markerMaps;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при получении маркерных карт: $e');
      }

      // В случае ошибки возвращаем пустой список
      return [];
    }
  }

  // ✅ СОЗДАНИЕ: Добавить новую маркерную карту
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      if (kDebugMode) {
        debugPrint('📍 Добавление новой маркерной карты');
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем лимиты ПЕРЕД созданием карты
      final canCreate = await _subscriptionService.canCreateContentOffline(
        ContentType.markerMaps,
      );

      if (!canCreate) {
        throw Exception('Достигнут лимит создания маркерных карт');
      }

      // Генерируем уникальный ID, если его нет
      final String mapId = map.id.isEmpty ? const Uuid().v4() : map.id;

      // Создаем entity из model
      final entity = _modelToEntity(map.copyWith(
        id: mapId,
        userId: userId,
      ));

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Онлайн режим: пытаемся синхронизировать сразу
        entity.isSynced = false; // Будет синхронизирована позже
      } else {
        // Офлайн режим: помечаем как несинхронизированную
        entity.isSynced = false;
      }

      // Сохраняем в Isar
      await IsarService.instance.insertMarkerMap(entity);

      if (kDebugMode) {
        debugPrint('✅ Маркерная карта сохранена в Isar: $mapId');
      }

      // Увеличиваем счетчик использования
      try {
        await _subscriptionService.incrementUsage(ContentType.markerMaps);
        if (kDebugMode) {
          debugPrint('✅ Счетчик маркерных карт увеличен');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка увеличения счетчика: $e');
        }
        // Не прерываем выполнение, карта уже сохранена
      }

      // Очищаем кэш
      clearCache();

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ Ошибка синхронизации после создания: $e');
          }
        });
      }

      return mapId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при добавлении маркерной карты: $e');
      }
      rethrow;
    }
  }

  // ✅ ОБНОВЛЕНИЕ: Обновить маркерную карту
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    try {
      if (kDebugMode) {
        debugPrint('📍 Обновление маркерной карты: ${map.id}');
        debugPrint('📍 Количество маркеров: ${map.markers.length}');
      }

      if (map.id.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Ищем существующую entity по Firebase ID
      MarkerMapEntity? existingEntity =
      await IsarService.instance.getMarkerMapByFirebaseId(map.id);

      if (existingEntity == null) {
        // Если не найдена по Firebase ID, создаем новую
        existingEntity = _modelToEntity(map.copyWith(userId: userId));
      } else {
        // Обновляем существующую entity
        existingEntity.name = map.name;
        existingEntity.date = map.date;
        existingEntity.sector = map.sector;
        existingEntity.noteIds = map.noteIds;
        existingEntity.noteNames = map.noteNames;
        existingEntity.markers = map.markers;
        existingEntity.markAsModified(); // Помечаем как измененную
      }

      // Сохраняем обновления в Isar
      await IsarService.instance.updateMarkerMap(existingEntity);

      if (kDebugMode) {
        debugPrint('✅ Маркерная карта обновлена в Isar');
      }

      // Очищаем кэш
      clearCache();

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ Ошибка синхронизации после обновления: $e');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при обновлении маркерной карты: $e');
      }
      rethrow;
    }
  }

  // ✅ УДАЛЕНИЕ: Удалить маркерную карту
  Future<void> deleteMarkerMap(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      if (kDebugMode) {
        debugPrint('📍 Удаление маркерной карты: $mapId');
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Онлайн режим: удаляем из Isar (синхронизация удалит из Firebase)
        final success = await IsarService.instance.deleteMarkerMapByFirebaseId(mapId);

        if (success) {
          if (kDebugMode) {
            debugPrint('✅ Маркерная карта удалена из Isar');
          }
        }
      } else {
        // Офлайн режим: помечаем для удаления
        await IsarService.instance.markMarkerMapForDeletion(mapId);

        if (kDebugMode) {
          debugPrint('✅ Маркерная карта помечена для удаления');
        }
      }

      // Уменьшаем счетчик использования
      try {
        await _subscriptionService.decrementUsage(ContentType.markerMaps);
        if (kDebugMode) {
          debugPrint('✅ Счетчик маркерных карт уменьшен');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка уменьшения счетчика: $e');
        }
        // Не прерываем выполнение
      }

      // Очищаем кэш
      clearCache();

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ Ошибка синхронизации после удаления: $e');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при удалении маркерной карты: $e');
      }
      rethrow;
    }
  }

  // ✅ ПОЛУЧЕНИЕ ПО ID: Получить маркерную карту по ID
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      if (kDebugMode) {
        debugPrint('📍 Получение маркерной карты по ID: $mapId');
      }

      // Ищем entity по Firebase ID
      final entity = await IsarService.instance.getMarkerMapByFirebaseId(mapId);

      if (entity == null) {
        throw Exception('Маркерная карта не найдена');
      }

      final model = _entityToModel(entity);

      if (kDebugMode) {
        debugPrint('✅ Маркерная карта найдена');
      }

      return model;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при получении маркерной карты по ID: $e');
      }
      rethrow;
    }
  }

  // ✅ ОЧИСТКА: Удалить все маркерные карты пользователя
  Future<void> clearAllMarkerMaps() async {
    try {
      if (kDebugMode) {
        debugPrint('📍 Удаление всех маркерных карт пользователя');
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Удаляем все карты пользователя из Isar
      await IsarService.instance.deleteAllMarkerMaps(userId);

      if (kDebugMode) {
        debugPrint('✅ Все маркерные карты пользователя удалены');
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при удалении всех маркерных карт: $e');
      }
      rethrow;
    }
  }

  // ✅ ПРОВЕРКИ И ЛИМИТЫ

  /// Проверка возможности создания новой маркерной карты
  Future<bool> canCreateMarkerMap() async {
    try {
      return await _subscriptionService.canCreateContentOffline(
        ContentType.markerMaps,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при проверке возможности создания карты: $e');
      }
      return false;
    }
  }

  /// Получение текущего использования маркерных карт
  Future<int> getCurrentUsage() async {
    try {
      return await _subscriptionService.getCurrentUsage(
        ContentType.markerMaps,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при получении текущего использования карт: $e');
      }
      return 0;
    }
  }

  /// Получение лимита маркерных карт
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.markerMaps);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при получении лимита карт: $e');
      }
      return 0;
    }
  }

  // ✅ СИНХРОНИЗАЦИЯ

  /// Синхронизация при запуске приложения
  Future<void> syncOfflineDataOnStartup() async {
    await SyncService.instance.fullSync();
  }

  /// Принудительная синхронизация данных
  Future<bool> forceSyncData() async {
    try {
      await SyncService.instance.fullSync();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при принудительной синхронизации: $e');
      }
      return false;
    }
  }

  /// Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null) return {};

      final total = await IsarService.instance.getMarkerMapsCount(userId);
      final unsynced = await IsarService.instance.getUnsyncedMarkerMapsCount(userId);

      return {
        'total': total,
        'synced': total - unsynced,
        'unsynced': unsynced,
        'syncPercentage': total > 0 ? ((total - unsynced) / total * 100).round() : 100,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при получении статуса синхронизации: $e');
      }
      return {};
    }
  }

  // ✅ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ

  /// Очистить кэш данных
  static void clearCache() {
    _cachedMaps = null;
    _cacheTimestamp = null;
    if (kDebugMode) {
      debugPrint('💾 Кэш маркерных карт очищен');
    }
  }

  /// Преобразование Entity в Model
  MarkerMapModel _entityToModel(MarkerMapEntity entity) {
    return MarkerMapModel(
      id: entity.firebaseId ?? '',
      userId: entity.userId,
      name: entity.name,
      date: entity.date,
      sector: entity.sector,
      noteIds: entity.noteIds,
      noteNames: entity.noteNames,
      markers: entity.markers,
    );
  }

  /// Преобразование Model в Entity
  MarkerMapEntity _modelToEntity(MarkerMapModel model) {
    return MarkerMapEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..name = model.name
      ..date = model.date
      ..sector = model.sector
      ..noteIds = model.noteIds
      ..noteNames = model.noteNames
      ..markers = model.markers
      ..isSynced = false
      ..markedForDeletion = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }
}