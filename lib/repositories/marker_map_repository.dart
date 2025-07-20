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
  static final MarkerMapRepository _instance = MarkerMapRepository._internal();

  factory MarkerMapRepository() {
    return _instance;
  }

  MarkerMapRepository._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // ✅ ДОБАВЛЕНО: Кэш для предотвращения повторных загрузок (как в BudgetNotesRepository)
  static List<MarkerMapModel>? _cachedMaps;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // ✅ ИСПРАВЛЕНО: Получить все маркерные карты пользователя с ПРАВИЛЬНЫМ кэшированием
  Future<List<MarkerMapModel>> getUserMarkerMaps() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Запрос маркерных карт для пользователя: $userId');

      // ✅ ДОБАВЛЕНО: Проверяем кэш
      if (_cachedMaps != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('💾 Возвращаем карты из кэша (возраст: ${cacheAge.inSeconds}с)');
          return _cachedMaps!;
        } else {
          debugPrint('💾 Кэш карт устарел, очищаем');
          _cachedMaps = null;
          _cacheTimestamp = null;
        }
      }

      // Всегда получаем офлайн карты первыми (теперь включает кэшированные)
      final offlineMaps = await _getOfflineMarkerMaps(userId);
      debugPrint('📱 Офлайн карт найдено: ${offlineMaps.length}');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${isOnline ? 'Онлайн' : 'Офлайн'}');

      List<MarkerMapModel> onlineMaps = [];

      if (isOnline) {
        try {
          debugPrint('📍 Загружаем карты из НОВОЙ структуры Firebase...');

          // ✅ ИСПРАВЛЕНО: Используем НОВУЮ структуру через FirebaseService
          final snapshot = await _firebaseService.getUserMarkerMaps();
          debugPrint('📍 Получено ${snapshot.docs.length} карт из Firebase');

          // Преобразуем документы в модели
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final map = MarkerMapModel.fromJson(data, id: doc.id);
              onlineMaps.add(map);
            } catch (e) {
              debugPrint('❌ Ошибка парсинга карты ${doc.id}: $e');
              continue;
            }
          }

          debugPrint('📍 Успешно обработано ${onlineMaps.length} карт');

          // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Кэшируем Firebase карты через ПРАВИЛЬНЫЙ метод
          if (onlineMaps.isNotEmpty) {
            try {
              debugPrint('💾 Кэшируем Firebase карты через cacheMarkerMaps...');
              final mapsToCache = onlineMaps.map((map) {
                final mapJson = map.toJson();
                mapJson['id'] = map.id;
                mapJson['userId'] = userId;
                // 🔥 ДОБАВЛЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ для совместимости с кэшем
                mapJson['isSynced'] = true;   // Из Firebase - синхронизированы
                mapJson['isOffline'] = false; // Не офлайн карты
                return mapJson;
              }).toList();

              await _offlineStorage.cacheMarkerMaps(mapsToCache);
              debugPrint('✅ ${onlineMaps.length} Firebase карт кэшированы правильно');
            } catch (e) {
              debugPrint('⚠️ Ошибка кэширования Firebase карт: $e');
              debugPrint('⚠️ Детали ошибки: ${e.toString()}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при получении карт из Firebase: $e');
        }
      }

      // ✅ ИСПРАВЛЕНО: Объединяем списки правильно, избегая дубликатов
      final Map<String, MarkerMapModel> uniqueMaps = {};

      // Сначала добавляем онлайн карты (приоритет)
      for (var map in onlineMaps) {
        uniqueMaps[map.id] = map;
      }

      // Затем добавляем офлайн карты, которых нет в онлайн списке
      for (var map in offlineMaps) {
        if (!uniqueMaps.containsKey(map.id)) {
          uniqueMaps[map.id] = map;
        }
      }

      // Преобразуем в список и сортируем по дате
      final allMaps = uniqueMaps.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      debugPrint('📊 Итого карт: ${allMaps.length}');
      debugPrint('📊 Онлайн: ${onlineMaps.length}, Офлайн: ${offlineMaps.length}');

      // ✅ ДОБАВЛЕНО: Кэшируем результат
      _cachedMaps = allMaps;
      _cacheTimestamp = DateTime.now();

      // Запускаем синхронизацию в фоне
      if (isOnline) {
        _syncService.syncAll();
      }

      return allMaps;
    } catch (e) {
      debugPrint('❌ Ошибка при получении маркерных карт: $e');

      // В случае ошибки, пытаемся вернуть хотя бы офлайн карты
      try {
        return await _getOfflineMarkerMaps(
          _firebaseService.currentUserId ?? '',
        );
      } catch (_) {
        // В крайнем случае возвращаем пустой список
        return [];
      }
    }
  }

  // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Получение карт из ВСЕХ источников
  Future<List<MarkerMapModel>> _getOfflineMarkerMaps(String userId) async {
    try {
      final List<MarkerMapModel> result = [];
      final Set<String> processedIds = <String>{};

      debugPrint('📱 Загружаем кэшированные Firebase карты...');

      // 1. ✅ ИСПРАВЛЕНО: Загружаем кэшированные Firebase карты
      try {
        final cachedMaps = await _offlineStorage.getCachedMarkerMaps();
        debugPrint('💾 Найдено кэшированных Firebase карт: ${cachedMaps.length}');

        for (final mapData in cachedMaps) {
          try {
            final mapId = mapData['id']?.toString() ?? '';
            final mapUserId = mapData['userId']?.toString() ?? '';

            if (mapId.isEmpty) continue;

            // Проверяем принадлежность пользователю
            if (mapUserId == userId) {
              final map = MarkerMapModel.fromJson(mapData, id: mapId);
              result.add(map);
              processedIds.add(mapId);
              debugPrint('✅ Кэшированная карта загружена: $mapId');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка обработки кэшированной карты: $e');
            continue;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при загрузке кэшированных карт: $e');
      }

      debugPrint('📱 Загружаем офлайн созданные карты...');

      // 2. ✅ КРИТИЧЕСКИ ИСПРАВЛЕНО: Загружаем ТОЛЬКО несинхронизированные офлайн карты
      try {
        final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
        debugPrint('📱 Найдено офлайн созданных карт: ${offlineMaps.length}');

        // Фильтруем и преобразуем данные в модели
        for (final mapData in offlineMaps) {
          try {
            final mapId = mapData['id']?.toString() ?? '';
            final mapUserId = mapData['userId']?.toString() ?? '';
            final isSynced = mapData['isSynced'] == true;
            final isOffline = mapData['isOffline'] == true;

            // ✅ ИСПРАВЛЕНО: Пропускаем уже обработанные карты
            if (mapId.isEmpty || processedIds.contains(mapId)) {
              continue;
            }

            // ✅ ИСПРАВЛЕНО: Загружаем ТОЛЬКО несинхронизированные офлайн карты
            if (!isSynced && isOffline) {
              // Проверяем принадлежность пользователю
              bool belongsToUser = false;

              if (mapUserId.isNotEmpty && mapUserId == userId) {
                belongsToUser = true;
              } else if (mapUserId.isEmpty) {
                // Карта без userId - добавляем userId
                mapData['userId'] = userId;
                belongsToUser = true;
                _offlineStorage.saveOfflineMarkerMap(mapData).catchError((error) {
                  debugPrint('⚠️ Ошибка при исправлении карты: $error');
                });
              }

              if (belongsToUser) {
                final map = MarkerMapModel.fromJson(mapData, id: mapId);
                result.add(map);
                processedIds.add(mapId);
                debugPrint('✅ Несинхронизированная офлайн карта загружена: $mapId');
              }
            } else {
              debugPrint('⏭️ Пропускаем синхронизированную карту: $mapId (isSynced: $isSynced, isOffline: $isOffline)');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка обработки офлайн карты: $e');
            continue;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при загрузке офлайн карт: $e');
      }

      // Сортируем по дате (от новых к старым)
      result.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ Всего карт загружено из офлайн источников: ${result.length}');

      return result;
    } catch (e) {
      debugPrint('❌ Ошибка при получении офлайн маркерных карт: $e');
      return [];
    }
  }

  // 🔥 КРИТИЧЕСКИ ИСПРАВЛЕНО: Добавление новой маркерной карты с передачей кастомного ID
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
        // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Передаем кастомный ID в FirebaseService
        try {
          final savedMapId = await _firebaseService.addMarkerMap(
            mapToAdd.toJson(),
            customId: mapId,  // 🔥 ПЕРЕДАЕМ КАСТОМНЫЙ ID
          );

          debugPrint('✅ Маркерная карта добавлена в НОВУЮ структуру с ID: $savedMapId');

          // 🔥 ИСПРАВЛЕНО: Кэшируем новую карту через ПРАВИЛЬНЫЙ метод
          try {
            final mapJson = mapToAdd.toJson();
            mapJson['id'] = mapId;
            mapJson['userId'] = userId;
            // 🔥 ДОБАВЛЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ
            mapJson['isSynced'] = true;   // Синхронизирована с Firebase
            mapJson['isOffline'] = false; // Не офлайн карта

            // Кэшируем в общий кэш Firebase карт
            await _offlineStorage.cacheMarkerMaps([mapJson]);

            debugPrint('💾 Новая карта кэширована правильно');
          } catch (e) {
            debugPrint('⚠️ Ошибка кэширования новой карты: $e');
          }

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

      // ✅ ДОБАВЛЕНО: Очищаем кэш после создания новой карты
      clearCache();

      return mapId;
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении маркерной карты: $e');
      rethrow;
    }
  }

  // ✅ ИСПРАВЛЕНО: Сохранение карты в офлайн режиме
  Future<void> _saveMapOffline(MarkerMapModel map) async {
    try {
      if (map.id.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      debugPrint('📱 Сохранение офлайн карты: ${map.id}');

      // ✅ ИСПРАВЛЕНО: Устанавливаем правильные флаги для офлайн карты
      final mapJson = map.toJson();
      mapJson['id'] = map.id;
      mapJson['userId'] = map.userId;
      mapJson['isSynced'] = false;  // Требует синхронизации
      mapJson['isOffline'] = true;  // Создана офлайн
      mapJson['offlineCreatedAt'] = DateTime.now().toIso8601String();

      await _offlineStorage.saveOfflineMarkerMap(mapJson);
      debugPrint('✅ Карта сохранена в офлайн режиме');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении карты офлайн: $e');
      rethrow;
    }
  }

  // 🔥 ПОЛНОСТЬЮ ПЕРЕПИСАННЫЙ метод updateMarkerMap() с ОБНОВЛЕНИЕМ КЭША
  Future<void> updateMarkerMap(MarkerMapModel map) async {
    debugPrint('🔥🔥🔥 ВЫЗВАН updateMarkerMap() для карты: ${map.id}');
    debugPrint('🔥🔥🔥 Количество маркеров в карте: ${map.markers.length}');
    debugPrint('🔥🔥🔥 Последний маркер: ${map.markers.isNotEmpty ? map.markers.last['id'] ?? "БЕЗ ID" : "НЕТ МАРКЕРОВ"}');

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

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Подготавливаем данные карты
      final mapJson = mapToUpdate.toJson();
      mapJson['id'] = map.id;
      mapJson['userId'] = userId;
      mapJson['updatedAt'] = DateTime.now().toIso8601String();

      // 🔥 КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Обновляем КЭШ FIREBASE первым делом!
      debugPrint('💾 Обновляем кэш Firebase карт с новыми маркерами...');

      // Загружаем существующий кэш
      final cachedMaps = await _offlineStorage.getCachedMarkerMaps();
      debugPrint('📋 Найдено в кэше карт: ${cachedMaps.length}');

      // Обновляем нужную карту в кэше или добавляем новую
      bool mapFoundInCache = false;
      final updatedCachedMaps = <Map<String, dynamic>>[];

      for (final cachedMap in cachedMaps) {
        if (cachedMap['id'] == map.id) {
          // 🔥 ОБНОВЛЯЕМ существующую карту в кэше
          final updatedCachedMap = Map<String, dynamic>.from(mapJson);
          updatedCachedMap['isSynced'] = true;   // В кэше - синхронизированные
          updatedCachedMap['isOffline'] = false; // Не офлайн карты
          updatedCachedMaps.add(updatedCachedMap);
          mapFoundInCache = true;
          debugPrint('✅ Карта обновлена в кэше Firebase: ${map.id}');
        } else {
          updatedCachedMaps.add(cachedMap);
        }
      }

      if (!mapFoundInCache) {
        // 🔥 ДОБАВЛЯЕМ новую карту в кэш
        final newCachedMap = Map<String, dynamic>.from(mapJson);
        newCachedMap['isSynced'] = true;   // В кэше - синхронизированные
        newCachedMap['isOffline'] = false; // Не офлайн карты
        updatedCachedMaps.add(newCachedMap);
        debugPrint('✅ Карта добавлена в кэш Firebase: ${map.id}');
      }

      // 🔥 СОХРАНЯЕМ обновленный кэш
      await _offlineStorage.cacheMarkerMaps(updatedCachedMaps);
      debugPrint('💾 Кэш Firebase карт обновлен с новыми маркерами');

      // 🔥 БЫСТРОЕ офлайн сохранение (для синхронизации)
      mapJson['isSynced'] = false;  // Требует синхронизации с сервером
      mapJson['isOffline'] = true;  // Офлайн обновление
      await _offlineStorage.saveOfflineMarkerMap(mapJson);
      debugPrint('💾 Карта сохранена в офлайн хранилище для синхронизации');

      // Очищаем кэш Repository для обновления UI
      clearCache();
      debugPrint('🗑️ Кэш Repository очищен после сохранения');

      // 🔥 АСИНХРОННАЯ синхронизация в фоне (не блокирует UI)
      _syncMapInBackground(map.id, mapToUpdate);

    } catch (e) {
      debugPrint('❌ Ошибка при обновлении маркерной карты: $e');

      // В случае ошибки, сохраняем обновление локально
      try {
        await _offlineStorage.saveMarkerMapUpdate(map.id, map.toJson());
        debugPrint('💾 Карта сохранена в fallback режиме');
      } catch (_) {
        rethrow;
      }
    }
  }

  // 🔥 ИСПРАВЛЕННЫЙ метод: Фоновая синхронизация с правильными флагами
  void _syncMapInBackground(String mapId, MarkerMapModel mapToUpdate) async {
    try {
      debugPrint('🌊 Запуск фоновой синхронизации для карты: $mapId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ Пытаемся синхронизировать с Firebase в фоне
        try {
          await _firebaseService.updateMarkerMap(mapId, mapToUpdate.toJson());
          debugPrint('✅ Карта синхронизирована с Firebase в фоне: $mapId');

          // 🔥 ИСПРАВЛЕНО: Обновляем кэш после успешной синхронизации
          final mapJson = mapToUpdate.toJson();
          mapJson['id'] = mapId;
          mapJson['userId'] = mapToUpdate.userId;
          mapJson['isSynced'] = true;   // Синхронизирована
          mapJson['isOffline'] = false; // Не офлайн карта
          mapJson['updatedAt'] = DateTime.now().toIso8601String();

          // Обновляем кэш Firebase
          final cachedMaps = await _offlineStorage.getCachedMarkerMaps();
          final updatedCachedMaps = <Map<String, dynamic>>[];

          bool foundInCache = false;
          for (final cachedMap in cachedMaps) {
            if (cachedMap['id'] == mapId) {
              updatedCachedMaps.add(mapJson);
              foundInCache = true;
            } else {
              updatedCachedMaps.add(cachedMap);
            }
          }

          if (!foundInCache) {
            updatedCachedMaps.add(mapJson);
          }

          await _offlineStorage.cacheMarkerMaps(updatedCachedMaps);
          debugPrint('💾 Карта обновлена в кэше после синхронизации');
        } catch (e) {
          debugPrint('❌ Фоновая синхронизация не удалась, карта остается локальной: $e');

          // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: В офлайн режиме помечаем как офлайн карту
          final mapJson = mapToUpdate.toJson();
          mapJson['id'] = mapId;
          mapJson['userId'] = mapToUpdate.userId;
          mapJson['isSynced'] = false;  // Требует синхронизации
          mapJson['isOffline'] = true;  // 🔥 ИЗМЕНЕНО: true вместо false - это ОФЛАЙН карта!
          mapJson['updatedAt'] = DateTime.now().toIso8601String();

          await _offlineStorage.saveOfflineMarkerMap(mapJson);
          debugPrint('💾 Карта помечена как офлайн после неудачной синхронизации');
        }
      } else {
        debugPrint('📱 Нет сети - карта остается в офлайн режиме');

        // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: В офлайн режиме помечаем как офлайн карту
        final mapJson = mapToUpdate.toJson();
        mapJson['id'] = mapId;
        mapJson['userId'] = mapToUpdate.userId;
        mapJson['isSynced'] = false;  // Требует синхронизации
        mapJson['isOffline'] = true;  // 🔥 ИЗМЕНЕНО: true вместо false - это ОФЛАЙН карта!
        mapJson['updatedAt'] = DateTime.now().toIso8601String();

        await _offlineStorage.saveOfflineMarkerMap(mapJson);
        debugPrint('💾 Карта помечена как офлайн в отсутствие сети');
      }

      debugPrint('🌊 Фоновая синхронизация завершена для карты: $mapId');
    } catch (e) {
      debugPrint('❌ Ошибка фоновой синхронизации: $e');

      // 🔥 ДОБАВЛЕНО: В случае ошибки тоже помечаем как офлайн
      try {
        final mapJson = mapToUpdate.toJson();
        mapJson['id'] = mapId;
        mapJson['userId'] = mapToUpdate.userId;
        mapJson['isSynced'] = false;  // Требует синхронизации
        mapJson['isOffline'] = true;  // Это офлайн карта
        mapJson['updatedAt'] = DateTime.now().toIso8601String();

        await _offlineStorage.saveOfflineMarkerMap(mapJson);
        debugPrint('💾 Карта помечена как офлайн после ошибки синхронизации');
      } catch (saveError) {
        debugPrint('❌ Критическая ошибка сохранения: $saveError');
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Удаление маркерной карты (убрано двойное уменьшение счетчиков)
  Future<void> deleteMarkerMap(String mapId) async {
    try {
      if (mapId.isEmpty) {
        throw Exception('ID карты не может быть пустым');
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📍 Удаление маркерной карты: $mapId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // ✅ ИСПРАВЛЕНО: Используем FirebaseService для удаления из НОВОЙ структуры
        try {
          await _firebaseService.deleteMarkerMap(mapId);
          debugPrint('✅ Маркерная карта удалена из НОВОЙ структуры: $mapId');

          // ✅ ИСПРАВЛЕНИЕ: Уменьшаем счетчик ТОЛЬКО через FirebaseService (онлайн режим)
          try {
            await _firebaseService.incrementUsageCount('markerMapsCount', increment: -1);
            debugPrint('✅ Счетчик маркерных карт уменьшен через Firebase');
          } catch (e) {
            debugPrint('⚠️ Ошибка уменьшения счетчика через Firebase: $e');
          }

          // ✅ ДОБАВЛЕНО: Удаляем из кэша Firebase карт
          try {
            final cachedMaps = await _offlineStorage.getCachedMarkerMaps();
            final updatedCachedMaps = cachedMaps.where((map) => map['id'] != mapId).toList();
            await _offlineStorage.cacheMarkerMaps(updatedCachedMaps);
            debugPrint('✅ Карта удалена из кэша Firebase карт');
          } catch (e) {
            debugPrint('⚠️ Ошибка удаления из кэша Firebase карт: $e');
          }

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

        debugPrint('✅ Маркерная карта удалена онлайн: $mapId');
      } else {
        // Если нет интернета, отмечаем карту для удаления
        await _offlineStorage.markForDeletion(mapId, true);

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

      // Удаляем локальную копию, если она есть
      try {
        await _offlineStorage.removeOfflineMarkerMap(mapId);
        debugPrint('✅ Локальная копия карты удалена');
      } catch (e) {
        debugPrint('⚠️ Ошибка при удалении локальной копии карты: $e');
      }

      // ✅ ДОБАВЛЕНО: Очищаем кэш после удаления карты
      clearCache();
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

  // ✅ ИСПРАВЛЕНО: Получение маркерной карты по ID из НОВОЙ структуры
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
        // ✅ ИСПРАВЛЕНО: Получаем из НОВОЙ структуры через FirebaseService
        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('marker_maps')
              .doc(mapId)
              .get();

          if (doc.exists) {
            final map = MarkerMapModel.fromJson(doc.data()!, id: doc.id);

            // 🔥 ИСПРАВЛЕНО: Кэшируем полученную карту через ПРАВИЛЬНЫЙ метод
            try {
              final mapJson = map.toJson();
              mapJson['id'] = map.id;
              mapJson['userId'] = userId;
              mapJson['isSynced'] = true;   // Из Firebase
              mapJson['isOffline'] = false; // Не офлайн карта

              // Кэшируем в общий кэш Firebase карт
              await _offlineStorage.cacheMarkerMaps([mapJson]);

              // Также сохраняем в офлайн хранилище
              await _offlineStorage.saveOfflineMarkerMap(mapJson);

              debugPrint('✅ Карта найдена в НОВОЙ структуре и кэширована правильно: $mapId');
            } catch (e) {
              debugPrint('⚠️ Ошибка кэширования полученной карты: $e');
            }

            return map;
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

  // 🔥 ИСПРАВЛЕНО: Получение маркерной карты из офлайн хранилища по ID
  Future<MarkerMapModel> _getOfflineMarkerMapById(String mapId) async {
    try {
      // Сначала ищем в кэшированных Firebase картах
      try {
        final cachedMaps = await _offlineStorage.getCachedMarkerMaps();
        final cachedMap = cachedMaps.where((map) => map['id'] == mapId).firstOrNull;

        if (cachedMap != null) {
          debugPrint('✅ Карта найдена в кэше Firebase карт');
          return MarkerMapModel.fromJson(cachedMap, id: mapId);
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка поиска в кэше Firebase карт: $e');
      }

      // Если не найдена в кэше - ищем в офлайн картах
      final allOfflineMaps = await _offlineStorage.getAllOfflineMarkerMaps();

      // Ищем карту по ID
      final mapData = allOfflineMaps.firstWhere(
            (map) => map['id'] == mapId,
        orElse: () => throw Exception(
          'Маркерная карта не найдена в офлайн хранилище',
        ),
      );

      debugPrint('✅ Карта найдена в офлайн хранилище');
      return MarkerMapModel.fromJson(mapData, id: mapId);
    } catch (e) {
      debugPrint(
        '❌ Ошибка при получении маркерной карты из офлайн хранилища: $e',
      );
      rethrow;
    }
  }

  // ✅ ИСПРАВЛЕНО: Удаление всех маркерных карт пользователя из НОВОЙ структуры
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
        // ✅ ИСПРАВЛЕНО: Получаем и удаляем все карты из НОВОЙ структуры
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

      // ✅ ДОБАВЛЕНО: Очищаем кэш после удаления всех карт
      clearCache();
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

  // ✅ ИСПРАВЛЕНО: Получение текущего использования маркерных карт
  Future<int> getCurrentUsage() async {
    try {
      // ✅ ИСПРАВЛЕНО: getCurrentOfflineUsage → getCurrentUsage
      return await _subscriptionService.getCurrentUsage(
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

  // ✅ ДОБАВЛЕНО: Очистить кеш данных (как в BudgetNotesRepository)
  static void clearCache() {
    _cachedMaps = null;
    _cacheTimestamp = null;
    debugPrint('💾 Кэш маркерных карт очищен');
  }
}