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
  final SyncService _syncService = SyncService
      .instance; // ✅ ДОБАВЛЕНО для правильного удаления

  // ✅ Кэш для предотвращения повторных загрузок
  static List<MarkerMapModel>? _cachedMaps;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // ✅ Инициализация репозитория
  Future<void> initialize() async {
    try {
      // Репозиторий готов к работе после инициализации IsarService
      // ✅ УБРАНО: debugPrint с подтверждением инициализации с поддержкой Isar
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки инициализации
      rethrow;
    }
  }

  // ✅ ОСНОВНОЙ МЕТОД: Получить все маркерные карты пользователя
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      // ✅ УБРАНО: debugPrint о запросе маркерных карт пользователя через Isar

      // Проверяем кэш
      if (_cachedMaps != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          // ✅ УБРАНО: debugPrint с информацией о возврате карт из кэша
          return _cachedMaps!;
        } else {
          // ✅ УБРАНО: debugPrint об устаревшем кэше карт
          clearCache();
        }
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем карты из Isar
      final markerMapEntities = await IsarService.instance.getAllMarkerMaps(
          userId);

      // ✅ УБРАНО: debugPrint('💾 Найдено карт в Isar: ${markerMapEntities.length}');

      // Преобразуем entities в models
      final markerMaps = markerMapEntities
          .map((entity) => _entityToModel(entity))
          .toList();

      // Сортируем по дате (от новых к старым)
      markerMaps.sort((a, b) => b.date.compareTo(a.date));

      // Кэшируем результат
      _cachedMaps = markerMaps;
      _cacheTimestamp = DateTime.now();

      // ✅ УБРАНО: debugPrint('✅ Загружено ${markerMaps.length} маркерных карт из Isar');

      // Запускаем синхронизацию в фоне, если есть интернет
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          // ✅ УБРАНО: debugPrint с деталями ошибки фоновой синхронизации
          return false; // 🔥 ИСПРАВЛЕНО: добавлен return
        });
      }

      return markerMaps;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении маркерных карт

      // В случае ошибки возвращаем пустой список
      return [];
    }
  }

  // ✅ СОЗДАНИЕ: Добавить новую маркерную карту
  Future<String> addMarkerMap(MarkerMapModel map) async {
    try {
      // ✅ УБРАНО: debugPrint о добавлении новой маркерной карты

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

      // ✅ УБРАНО: debugPrint('✅ Маркерная карта сохранена в Isar: $mapId');

      // Увеличиваем счетчик использования
      try {
        await _subscriptionService.incrementUsage(ContentType.markerMaps);
        // ✅ УБРАНО: debugPrint с подтверждением увеличения счетчика маркерных карт
      } catch (e) {
        // ✅ УБРАНО: debugPrint с деталями ошибки увеличения счетчика
        // Не прерываем выполнение, карта уже сохранена
      }

      // Очищаем кэш
      clearCache();

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          // ✅ УБРАНО: debugPrint с деталями ошибки синхронизации после создания
          return false; // 🔥 ИСПРАВЛЕНО: добавлен return
        });
      }

      return mapId;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при добавлении маркерной карты
      rethrow;
    }
  }

  // ✅ ОБНОВЛЕНИЕ: Обновить маркерную карту (БЕЗ полей связей)
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    try {
      // ✅ УБРАНО: debugPrint('📍 Обновление маркерной карты: ${map.id}');
      // ✅ УБРАНО: debugPrint('📍 Количество маркеров: ${map.markers.length}');

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
        // 🔥 ИСПРАВЛЕНО: Обновляем существующую entity БЕЗ полей связей
        existingEntity.name = map.name;
        existingEntity.date = map.date;
        existingEntity.sector = map.sector;
        existingEntity.markers = map.markers;
        existingEntity.rayLandmarks = map.rayLandmarks; // ➕ ДОБАВЬТЕ ЭТУ СТРОКУ
        existingEntity.markAsModified(); // Помечаем как измененную
      }

      // Сохраняем обновления в Isar
      await IsarService.instance.updateMarkerMap(existingEntity);

      // ✅ УБРАНО: debugPrint с подтверждением обновления маркерной карты в Isar

      // Очищаем кэш
      clearCache();

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          // ✅ УБРАНО: debugPrint с деталями ошибки синхронизации после обновления
          return false; // 🔥 ИСПРАВЛЕНО: добавлен return
        });
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при обновлении маркерной карты
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Удалить маркерную карту с двухэтапной логикой (онлайн/офлайн)
  Future<void> deleteMarkerMap(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint(
          '🗑️ MarkerMapRepository: Начинаем удаление маркерной карты $mapId');

      // 🔥 НОВОЕ: Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 MarkerMapRepository: Статус сети: ${isOnline
          ? 'Онлайн'
          : 'Офлайн'}');

      if (isOnline) {
        // 🔥 ОНЛАЙН: Сразу удаляем из Firebase + Isar
        debugPrint(
            '📱 MarkerMapRepository: Режим ОНЛАЙН - сразу удаляем из Firebase и Isar');
        final result = await _syncService.deleteMarkerMapByFirebaseId(mapId);

        if (result) {
          debugPrint('✅ MarkerMapRepository: Онлайн удаление прошло успешно');
        } else {
          debugPrint(
              '⚠️ MarkerMapRepository: Онлайн удаление завершилось с предупреждениями');
        }
      } else {
        // 🔥 ОФЛАЙН: Помечаем для удаления, НЕ удаляем физически
        debugPrint(
            '📴 MarkerMapRepository: Режим ОФЛАЙН - помечаем для удаления');

        try {
          await IsarService.instance.markMarkerMapForDeletion(mapId);
          debugPrint(
              '✅ MarkerMapRepository: Маркерная карта помечена для офлайн удаления');
        } catch (e) {
          debugPrint(
              '❌ MarkerMapRepository: Ошибка при маркировке карты для удаления: $e');
          rethrow;
        }
      }

      // 🔥 ВСЕГДА: Уменьшаем счетчик независимо от режима
      try {
        await _subscriptionService.decrementUsage(ContentType.markerMaps);
        debugPrint('✅ MarkerMapRepository: Счетчик лимитов уменьшен');
      } catch (e) {
        debugPrint('❌ MarkerMapRepository: Ошибка уменьшения счетчика: $e');
        // Не прерываем выполнение, карта уже удалена/помечена
      }

      // Очищаем кэш
      clearCache();

      // 🔥 ЗАПУСКАЕМ СИНХРОНИЗАЦИЮ: Если онлайн или при включении интернета
      if (isOnline) {
        SyncService.instance.fullSync().catchError((e) {
          // ✅ УБРАНО: debugPrint с деталями ошибки синхронизации после удаления
          return false; // 🔥 ИСПРАВЛЕНО: добавлен return
        });
      }

      debugPrint(
          '🎯 MarkerMapRepository: Удаление маркерной карты завершено успешно');
    } catch (e) {
      debugPrint(
          '❌ MarkerMapRepository: Критическая ошибка при удалении маркерной карты $mapId: $e');
      rethrow;
    }
  }

  // ✅ ПОЛУЧЕНИЕ ПО ID: Получить маркерную карту по ID
  Future<MarkerMapModel> getMarkerMapById(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      // ✅ УБРАНО: debugPrint('📍 Получение маркерной карты по ID: $mapId');

      // Ищем entity по Firebase ID
      final entity = await IsarService.instance.getMarkerMapByFirebaseId(mapId);

      if (entity == null) {
        throw Exception('Маркерная карта не найдена');
      }

      final model = _entityToModel(entity);

      // ✅ УБРАНО: debugPrint с подтверждением нахождения маркерной карты

      return model;
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении маркерной карты по ID
      rethrow;
    }
  }

  // ✅ ОЧИСТКА: Удалить все маркерные карты пользователя
  Future<void> clearAllMarkerMaps() async {
    try {
      // ✅ УБРАНО: debugPrint об удалении всех маркерных карт пользователя

      // Получаем ID текущего пользователя
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Удаляем все карты пользователя из Isar
      await IsarService.instance.deleteAllMarkerMaps(userId);

      // ✅ УБРАНО: debugPrint с подтверждением удаления всех маркерных карт пользователя

      // Очищаем кэш
      clearCache();
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при удалении всех маркерных карт
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
      // ✅ УБРАНО: debugPrint с деталями ошибки при проверке возможности создания карты
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
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении текущего использования карт
      return 0;
    }
  }

  /// Получение лимита маркерных карт
  Future<int> getUsageLimit() async {
    try {
      return _subscriptionService.getLimit(ContentType.markerMaps);
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении лимита карт
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
      // ✅ УБРАНО: debugPrint с деталями ошибки при принудительной синхронизации
      return false;
    }
  }

  /// Получить статус синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = IsarService.instance.getCurrentUserId();
      if (userId == null) return {};

      final total = await IsarService.instance.getMarkerMapsCount(userId);
      final unsynced = await IsarService.instance.getUnsyncedMarkerMapsCount(
          userId);

      return {
        'total': total,
        'synced': total - unsynced,
        'unsynced': unsynced,
        'syncPercentage': total > 0
            ? ((total - unsynced) / total * 100).round()
            : 100,
      };
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки при получении статуса синхронизации
      return {};
    }
  }

  // ✅ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ

  /// Очистить кэш данных
  static void clearCache() {
    _cachedMaps = null;
    _cacheTimestamp = null;
    // ✅ УБРАНО: debugPrint с уведомлением об очистке кэша маркерных карт
  }

  MarkerMapModel _entityToModel(MarkerMapEntity entity) {
    return MarkerMapModel(
      id: entity.firebaseId ?? '',
      userId: entity.userId,
      name: entity.name,
      date: entity.date,
      sector: entity.sector,
      markers: entity.markers,
      rayLandmarks: entity.rayLandmarks, // ➕ ДОБАВЬТЕ ЭТУ СТРОКУ
    );
  }

  MarkerMapEntity _modelToEntity(MarkerMapModel model) {
    return MarkerMapEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..name = model.name
      ..date = model.date
      ..sector = model.sector
      ..markers = model.markers
      ..rayLandmarks = model.rayLandmarks // ➕ ДОБАВЬТЕ ЭТУ СТРОКУ
      ..isSynced = false
      ..markedForDeletion = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }
}