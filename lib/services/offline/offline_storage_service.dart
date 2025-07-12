// Путь: lib/services/offline/offline_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/subscription_constants.dart';
import '../../models/subscription_model.dart';
import '../../models/usage_limits_model.dart';

/// Сервис для централизованного управления офлайн хранилищем данных
class OfflineStorageService {
  static final OfflineStorageService _instance =
  OfflineStorageService._internal();

  factory OfflineStorageService() {
    return _instance;
  }

  OfflineStorageService._internal();

  SharedPreferences? _preferences;

  // Константы для ключей хранилища
  static const String _offlineNotesKey = 'offline_fishing_notes';
  static const String _offlineNotesUpdatesKey = 'offline_note_updates';
  static const String _offlinePhotosKey = 'offline_fishing_photos';
  static const String _offlineMarkerMapsKey = 'offline_marker_maps';
  static const String _offlineMarkerMapsUpdatesKey =
      'offline_marker_map_updates';
  static const String _mapsToDeleteKey = 'maps_to_delete';
  static const String _notesToDeleteKey = 'notes_to_delete';
  static const String _statisticsCacheKey = 'cached_statistics';
  static const String _userDataKey = 'offline_user_data';
  static const String _syncTimeKey = 'last_sync_time';
  static const String _deleteAllMarkerMapsKey = 'delete_all_marker_maps';
  static const String _deleteAllNotesKey = 'delete_all_notes';

  // 🔥 НОВЫЕ КОНСТАНТЫ для кэширования подписки
  static const String _cachedSubscriptionKey = 'cached_subscription_data';
  static const String _subscriptionCacheTimeKey = 'subscription_cache_time';
  static const String _usageLimitsKey = 'usage_limits_data';

  // 🔥 НОВЫЕ КОНСТАНТЫ для локальных счетчиков офлайн операций
  static const String _localNotesCountKey = 'local_notes_count';
  static const String _localMapsCountKey = 'local_maps_count';
  static const String _localExpensesCountKey = 'local_expenses_count';
  static const String _localDepthChartCountKey = 'local_depth_chart_count';
  static const String _localCountersResetKey = 'local_counters_reset_time';

  // 🔥 НОВЫЕ КОНСТАНТЫ для офлайн авторизации
  static const String _offlineUserDataKey = 'offline_auth_user_data';
  static const String _offlineAuthValidUntilKey = 'offline_auth_valid_until';
  static const String _offlineAuthCacheTimeKey = 'offline_auth_cache_time';

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
      debugPrint('OfflineStorageService инициализирован');
    }
  }

  /// Получить указатель на хранилище
  Future<SharedPreferences> get preferences async {
    if (_preferences == null) {
      await initialize();
    }
    return _preferences!;
  }

  // 🔥 НОВЫЕ МЕТОДЫ для офлайн авторизации

  /// Сохранить данные пользователя для офлайн авторизации
  Future<void> saveOfflineUserData(User user) async {
    try {
      final prefs = await preferences;

      // Создаем объект данных пользователя
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'providerId': user.providerData.isNotEmpty ? user.providerData.first.providerId : null,
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        'phoneNumber': user.phoneNumber,
        'refreshToken': user.refreshToken,
      };

      // Сохраняем данные пользователя
      await prefs.setString(_offlineUserDataKey, jsonEncode(userData));

      // Устанавливаем время кэширования
      await prefs.setInt(_offlineAuthCacheTimeKey, DateTime.now().millisecondsSinceEpoch);

      // Устанавливаем время действия офлайн авторизации (30 дней)
      final validUntil = DateTime.now().add(Duration(days: 30));
      await prefs.setString(_offlineAuthValidUntilKey, validUntil.toIso8601String());

      // 🔥 ПРИНУДИТЕЛЬНО СОХРАНЯЕМ В ПАМЯТЬ УСТРОЙСТВА
      debugPrint('🔄 Принудительное сохранение данных в SharedPreferences...');

      // Проверяем, что данные действительно сохранились
      final savedData = prefs.getString(_offlineUserDataKey);
      if (savedData != null && savedData.isNotEmpty) {
        debugPrint('✅ Данные УСПЕШНО сохранены в SharedPreferences');
        debugPrint('📊 Размер сохраненных данных: ${savedData.length} символов');
      } else {
        debugPrint('❌ ОШИБКА: Данные НЕ сохранились в SharedPreferences!');
      }

      debugPrint('Данные пользователя сохранены в офлайн хранилище');
      debugPrint('Данные пользователя сохранены в кэш');
      debugPrint('📅 Офлайн авторизация действительна до: $validUntil');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения данных пользователя для офлайн: $e');
      rethrow;
    }
  }

  /// Получить кэшированные данные пользователя
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final prefs = await preferences;
      final userDataJson = prefs.getString(_offlineUserDataKey);

      if (userDataJson == null || userDataJson.isEmpty) {
        debugPrint('🔒 Нет кэшированных данных пользователя');
        return null;
      }

      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      debugPrint('✅ Загружены кэшированные данные пользователя: ${userData['email']}');
      return userData;
    } catch (e) {
      debugPrint('❌ Ошибка получения кэшированных данных пользователя: $e');
      return null;
    }
  }

  /// Проверить, действительна ли офлайн авторизация
  Future<bool> isOfflineAuthValid() async {
    try {
      final prefs = await preferences;

      // Проверяем наличие данных пользователя
      final userData = await getCachedUserData();
      if (userData == null) {
        debugPrint('🔒 Нет данных пользователя для офлайн авторизации');
        return false;
      }

      // Проверяем время действия
      final validUntilStr = prefs.getString(_offlineAuthValidUntilKey);
      if (validUntilStr == null) {
        debugPrint('📅 Не найдено время действия офлайн авторизации');
        return false;
      }

      final validUntil = DateTime.tryParse(validUntilStr);
      if (validUntil == null) {
        debugPrint('📅 Неверный формат времени действия офлайн авторизации');
        return false;
      }

      final now = DateTime.now();
      final isValid = now.isBefore(validUntil);

      if (isValid) {
        debugPrint('✅ Офлайн авторизация действительна до: $validUntil');
      } else {
        debugPrint('❌ Офлайн авторизация истекла: $validUntil');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Ошибка проверки офлайн авторизации: $e');
      return false;
    }
  }

  /// Очистить данные офлайн авторизации
  Future<void> clearOfflineAuthData() async {
    try {
      // 🔥 ДОБАВЛЯЕМ ОТЛАДКУ ДЛЯ ПОИСКА МЕСТА ВЫЗОВА
      if (kDebugMode) {
        debugPrint('🚨 OfflineStorageService.clearOfflineAuthData() ВЫЗВАН!');
        debugPrint('📍 Stack trace вызова:');
        debugPrint(StackTrace.current.toString());
      }

      final prefs = await preferences;
      await prefs.remove(_offlineUserDataKey);
      await prefs.remove(_offlineAuthValidUntilKey);
      await prefs.remove(_offlineAuthCacheTimeKey);
      debugPrint('🧹 Данные офлайн авторизации очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки данных офлайн авторизации: $e');
    }
  }

  /// Обновить время действия офлайн авторизации
  Future<void> refreshOfflineAuthValidity() async {
    try {
      final prefs = await preferences;
      final validUntil = DateTime.now().add(Duration(days: 30));
      await prefs.setString(_offlineAuthValidUntilKey, validUntil.toIso8601String());
      debugPrint('📅 Время действия офлайн авторизации обновлено до: $validUntil');
    } catch (e) {
      debugPrint('❌ Ошибка обновления времени действия офлайн авторизации: $e');
    }
  }

  // 🔥 НОВЫЕ МЕТОДЫ для кэширования подписки

  /// Кэширование статуса подписки при онлайн режиме
  Future<void> cacheSubscriptionStatus(SubscriptionModel subscription) async {
    try {
      final prefs = await preferences;

      // Сохраняем данные подписки
      final subscriptionData = {
        'userId': subscription.userId,
        'status': subscription.status.name,
        'type': subscription.type?.name,
        'expirationDate': subscription.expirationDate?.toIso8601String(),
        'purchaseToken': subscription.purchaseToken,
        'platform': subscription.platform,
        'createdAt': subscription.createdAt.toIso8601String(),
        'updatedAt': subscription.updatedAt.toIso8601String(),
        'isActive': subscription.isActive,
      };

      await prefs.setString(_cachedSubscriptionKey, jsonEncode(subscriptionData));
      await prefs.setInt(_subscriptionCacheTimeKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Статус подписки кэширован для офлайн использования');
    } catch (e) {
      debugPrint('❌ Ошибка кэширования подписки: $e');
      rethrow;
    }
  }

  /// Получение кэшированного статуса подписки
  Future<SubscriptionModel?> getCachedSubscriptionStatus() async {
    try {
      final prefs = await preferences;
      final cachedData = prefs.getString(_cachedSubscriptionKey);

      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;

      // Парсим данные подписки
      final status = SubscriptionStatus.values
          .where((s) => s.name == data['status'])
          .firstOrNull ?? SubscriptionStatus.none;

      final type = data['type'] != null
          ? SubscriptionType.values
          .where((t) => t.name == data['type'])
          .firstOrNull
          : null;

      final expirationDate = data['expirationDate'] != null
          ? DateTime.tryParse(data['expirationDate'])
          : null;

      final createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
      final updatedAt = DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now();

      return SubscriptionModel(
        userId: data['userId'] ?? '',
        status: status,
        type: type,
        expirationDate: expirationDate,
        purchaseToken: data['purchaseToken'] ?? '',
        platform: data['platform'] ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
        isActive: data['isActive'] ?? false,
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения кэшированной подписки: $e');
      return null;
    }
  }

  /// Проверка актуальности кэша подписки
  Future<bool> isSubscriptionCacheValid() async {
    try {
      final prefs = await preferences;
      final cacheTime = prefs.getInt(_subscriptionCacheTimeKey);

      if (cacheTime == null) {
        return false;
      }

      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      final daysSinceCache = now.difference(cacheDateTime).inDays;

      // Кэш доверия 30 дней
      return daysSinceCache < 30;
    } catch (e) {
      debugPrint('❌ Ошибка проверки актуальности кэша: $e');
      return false;
    }
  }

  /// Кэширование лимитов использования
  Future<void> cacheUsageLimits(UsageLimitsModel limits) async {
    try {
      final prefs = await preferences;

      final limitsData = {
        'userId': limits.userId,
        'notesCount': limits.notesCount,
        'markerMapsCount': limits.markerMapsCount,
        'expensesCount': limits.expensesCount,
        'lastResetDate': limits.lastResetDate.toIso8601String(),
        'updatedAt': limits.updatedAt.toIso8601String(),
      };

      await prefs.setString(_usageLimitsKey, jsonEncode(limitsData));
      debugPrint('✅ Лимиты использования кэшированы');
    } catch (e) {
      debugPrint('❌ Ошибка кэширования лимитов: $e');
      rethrow;
    }
  }

  /// Получение кэшированных лимитов использования
  Future<UsageLimitsModel?> getCachedUsageLimits() async {
    try {
      final prefs = await preferences;
      final cachedData = prefs.getString(_usageLimitsKey);

      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;

      return UsageLimitsModel(
        userId: data['userId'] ?? '',
        notesCount: data['notesCount'] ?? 0,
        markerMapsCount: data['markerMapsCount'] ?? 0,
        expensesCount: data['expensesCount'] ?? 0,
        lastResetDate: DateTime.tryParse(data['lastResetDate'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения кэшированных лимитов: $e');
      return null;
    }
  }

  // 🔥 НОВЫЕ МЕТОДЫ для локальных счетчиков

  /// Увеличение локального счетчика использования
  Future<void> incrementLocalUsage(ContentType contentType) async {
    try {
      final prefs = await preferences;
      final key = _getLocalCountKey(contentType);
      final currentCount = prefs.getInt(key) ?? 0;

      await prefs.setInt(key, currentCount + 1);
      debugPrint('✅ Увеличен локальный счетчик $contentType: ${currentCount + 1}');
    } catch (e) {
      debugPrint('❌ Ошибка увеличения локального счетчика: $e');
      rethrow;
    }
  }

  /// Уменьшение локального счетчика использования
  Future<void> decrementLocalUsage(ContentType contentType) async {
    try {
      final prefs = await preferences;
      final key = _getLocalCountKey(contentType);
      final currentCount = prefs.getInt(key) ?? 0;

      if (currentCount > 0) {
        await prefs.setInt(key, currentCount - 1);
        debugPrint('✅ Уменьшен локальный счетчик $contentType: ${currentCount - 1}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка уменьшения локального счетчика: $e');
      rethrow;
    }
  }

  /// Получение локального счетчика использования
  Future<int> getLocalUsageCount(ContentType contentType) async {
    try {
      final prefs = await preferences;
      final key = _getLocalCountKey(contentType);
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('❌ Ошибка получения локального счетчика: $e');
      return 0;
    }
  }

  /// Сброс всех локальных счетчиков использования
  Future<void> resetLocalUsageCounters() async {
    try {
      final prefs = await preferences;

      await prefs.setInt(_localNotesCountKey, 0);
      await prefs.setInt(_localMapsCountKey, 0);
      await prefs.setInt(_localExpensesCountKey, 0);
      await prefs.setInt(_localDepthChartCountKey, 0);
      await prefs.setInt(_localCountersResetKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Все локальные счетчики сброшены');
    } catch (e) {
      debugPrint('❌ Ошибка сброса локальных счетчиков: $e');
      rethrow;
    }
  }

  /// Получение всех локальных счетчиков
  Future<Map<ContentType, int>> getAllLocalUsageCounters() async {
    try {
      final prefs = await preferences;

      return {
        ContentType.fishingNotes: prefs.getInt(_localNotesCountKey) ?? 0,
        ContentType.markerMaps: prefs.getInt(_localMapsCountKey) ?? 0,
        ContentType.expenses: prefs.getInt(_localExpensesCountKey) ?? 0,
        ContentType.depthChart: prefs.getInt(_localDepthChartCountKey) ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения всех локальных счетчиков: $e');
      return {};
    }
  }

  /// Получение ключа для локального счетчика по типу контента
  String _getLocalCountKey(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return _localNotesCountKey;
      case ContentType.markerMaps:
        return _localMapsCountKey;
      case ContentType.expenses:
        return _localExpensesCountKey;
      case ContentType.depthChart:
        return _localDepthChartCountKey;
    }
  }

  /// Получение времени последнего сброса локальных счетчиков
  Future<DateTime?> getLocalCountersResetTime() async {
    try {
      final prefs = await preferences;
      final timestamp = prefs.getInt(_localCountersResetKey);

      if (timestamp == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ Ошибка получения времени сброса счетчиков: $e');
      return null;
    }
  }

  // 🔥 НОВЫЕ МЕТОДЫ для кэширования данных

  /// Кэширование заметок рыбалки для офлайн доступа
  Future<void> cacheFishingNotes(List<dynamic> notes) async {
    try {
      final prefs = await preferences;
      final notesJson = notes.map((note) => jsonEncode(note)).toList();

      await prefs.setStringList('cached_fishing_notes', notesJson);
      debugPrint('✅ Заметки рыбалки кэшированы (${notes.length} записей)');
    } catch (e) {
      debugPrint('❌ Ошибка кэширования заметок: $e');
      rethrow;
    }
  }

  /// Получение кэшированных заметок рыбалки
  Future<List<Map<String, dynamic>>> getCachedFishingNotes() async {
    try {
      final prefs = await preferences;
      final notesJson = prefs.getStringList('cached_fishing_notes') ?? [];

      List<Map<String, dynamic>> notes = [];
      for (var noteJson in notesJson) {
        try {
          notes.add(jsonDecode(noteJson) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Ошибка декодирования кэшированной заметки: $e');
        }
      }

      return notes;
    } catch (e) {
      debugPrint('❌ Ошибка получения кэшированных заметок: $e');
      return [];
    }
  }

  /// Кэширование маркерных карт для офлайн доступа
  Future<void> cacheMarkerMaps(List<dynamic> maps) async {
    try {
      final prefs = await preferences;
      final mapsJson = maps.map((map) => jsonEncode(map)).toList();

      await prefs.setStringList('cached_marker_maps', mapsJson);
      debugPrint('✅ Маркерные карты кэшированы (${maps.length} записей)');
    } catch (e) {
      debugPrint('❌ Ошибка кэширования маркерных карт: $e');
      rethrow;
    }
  }

  /// Получение кэшированных маркерных карт
  Future<List<Map<String, dynamic>>> getCachedMarkerMaps() async {
    try {
      final prefs = await preferences;
      final mapsJson = prefs.getStringList('cached_marker_maps') ?? [];

      List<Map<String, dynamic>> maps = [];
      for (var mapJson in mapsJson) {
        try {
          maps.add(jsonDecode(mapJson) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Ошибка декодирования кэшированной карты: $e');
        }
      }

      return maps;
    } catch (e) {
      debugPrint('❌ Ошибка получения кэшированных карт: $e');
      return [];
    }
  }

  /// 🔥 ДОБАВЛЕННЫЙ НЕДОСТАЮЩИЙ МЕТОД: Получить офлайн заметки для конкретного пользователя
  Future<List<Map<String, dynamic>>> getOfflineFishingNotes(String userId) async {
    try {
      final prefs = await preferences;
      final offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      if (kDebugMode) {
        debugPrint('📱 Всего офлайн заметок в хранилище: ${offlineNotesJson.length}');
      }

      List<Map<String, dynamic>> userNotes = [];

      if (kDebugMode) {
        debugPrint('🔍 Ищем заметки для пользователя: $userId');
      }

      for (var noteJson in offlineNotesJson) {
        try {
          final note = jsonDecode(noteJson) as Map<String, dynamic>;
          final noteUserId = note['userId']?.toString();

          if (kDebugMode) {
            debugPrint('🔍 Проверяем заметку: ${note['id']}, userId: $noteUserId');
          }

          if (noteUserId == userId) {
            userNotes.add(note);
            if (kDebugMode) {
              debugPrint('✅ Найдена заметка для пользователя: ${note['id']}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Ошибка при декодировании офлайн заметки: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('📊 ИТОГО найдено заметок для пользователя $userId: ${userNotes.length}');
      }

      return userNotes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка получения офлайн заметок: $e');
      }
      return [];
    }
  }

  /// Сохранение заметки рыбалки в офлайн режиме с флагом синхронизации (С ОТЛАДКОЙ)
  Future<void> saveOfflineFishingNote(Map<String, dynamic> noteData) async {
    try {
      debugPrint('🔥 === НАЧАЛО СОХРАНЕНИЯ ОФЛАЙН ЗАМЕТКИ ===');
      debugPrint('🔥 Данные заметки: ${noteData.keys.toList()}');
      debugPrint('🔥 ID заметки: ${noteData['id']}');
      debugPrint('🔥 userId заметки: ${noteData['userId']}');
      debugPrint('🔥 Локация: ${noteData['location']}');

      // Добавляем флаг синхронизации
      noteData['isSynced'] = false;
      noteData['offlineCreatedAt'] = DateTime.now().toIso8601String();

      // ПРИНУДИТЕЛЬНО проверяем, что userId есть
      if (noteData['userId'] == null || noteData['userId'].toString().isEmpty) {
        debugPrint('❌ КРИТИЧЕСКАЯ ОШИБКА: userId отсутствует в данных заметки!');
        debugPrint('❌ Полные данные: $noteData');
        throw Exception('userId обязателен для офлайн заметки');
      }

      await saveOfflineNote(noteData);
      debugPrint('✅ Заметка сохранена в офлайн режиме с флагом синхронизации');
      debugPrint('🔥 === КОНЕЦ СОХРАНЕНИЯ ОФЛАЙН ЗАМЕТКИ ===');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения заметки в офлайн режиме: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Сохранение маркерной карты в офлайн режиме с флагом синхронизации
  Future<void> saveOfflineMarkerMapWithSync(Map<String, dynamic> mapData) async {
    try {
      // Добавляем флаг синхронизации
      mapData['isSynced'] = false;
      mapData['offlineCreatedAt'] = DateTime.now().toIso8601String();

      await saveOfflineMarkerMap(mapData);
      debugPrint('✅ Маркерная карта сохранена в офлайн режиме с флагом синхронизации');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения маркерной карты в офлайн режиме: $e');
      rethrow;
    }
  }

  /// Сохранить заметку о рыбалке в офлайн хранилище
  Future<void> saveOfflineNote(Map<String, dynamic> noteData) async {
    try {
      final prefs = await preferences;
      List<String> offlineNotesJson =
          prefs.getStringList(_offlineNotesKey) ?? [];

      // Проверяем, есть ли уже заметка с таким ID
      final noteId = noteData['id'];
      if (noteId == null || noteId.toString().isEmpty) {
        throw Exception('ID заметки не может быть пустым');
      }

      bool noteExists = false;
      List<String> updatedNotes = [];

      for (var noteJson in offlineNotesJson) {
        try {
          final note = jsonDecode(noteJson) as Map<String, dynamic>;
          if (note['id'] == noteId) {
            // Обновляем существующую заметку
            updatedNotes.add(jsonEncode(noteData));
            noteExists = true;
            debugPrint(
              '📝 Обновлена существующая заметка $noteId в офлайн хранилище',
            );
          } else {
            updatedNotes.add(noteJson);
          }
        } catch (e) {
          // Если с парсингом JSON проблема, сохраняем оригинальную строку
          updatedNotes.add(noteJson);
          debugPrint('⚠️ Ошибка при декодировании существующей заметки: $e');
        }
      }

      // Если такой заметки нет, добавляем новую
      if (!noteExists) {
        updatedNotes.add(jsonEncode(noteData));
        debugPrint('📝 Добавлена новая заметка $noteId в офлайн хранилище');
      }

      await prefs.setStringList(_offlineNotesKey, updatedNotes);
      debugPrint('✅ Заметка $noteId сохранена в офлайн хранилище');

      // Удаляем из списка обновлений, так как мы теперь имеем полную копию заметки
      String offlineUpdatesJson =
          prefs.getString(_offlineNotesUpdatesKey) ?? '{}';
      try {
        Map<String, dynamic> updates =
        jsonDecode(offlineUpdatesJson) as Map<String, dynamic>;
        if (updates.containsKey(noteId.toString())) {
          updates.remove(noteId.toString());
          await prefs.setString(_offlineNotesUpdatesKey, jsonEncode(updates));
          debugPrint('🧹 Удалено устаревшее обновление для заметки $noteId');
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при обработке списка обновлений: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при сохранении заметки в офлайн хранилище: $e');
      rethrow;
    }
  }

  /// Сохранить обновление заметки
  Future<void> saveNoteUpdate(
      String noteId,
      Map<String, dynamic> noteData,
      ) async {
    try {
      final prefs = await preferences;
      String offlineUpdatesJson =
          prefs.getString(_offlineNotesUpdatesKey) ?? '{}';
      Map<String, dynamic> updates;

      try {
        updates = jsonDecode(offlineUpdatesJson) as Map<String, dynamic>;
      } catch (e) {
        updates = {};
      }

      updates[noteId] = noteData;
      await prefs.setString(_offlineNotesUpdatesKey, jsonEncode(updates));
      debugPrint('Обновление заметки $noteId сохранено в офлайн хранилище');
    } catch (e) {
      debugPrint('Ошибка при сохранении обновления заметки: $e');
      rethrow;
    }
  }

  /// Сохранить пути к фотографиям для заметки
  Future<void> saveOfflinePhotoPaths(
      String noteId,
      List<String> photoPaths,
      ) async {
    try {
      final prefs = await preferences;
      String offlinePhotosJson = prefs.getString(_offlinePhotosKey) ?? '{}';
      Map<String, dynamic> photosMap;

      try {
        photosMap = jsonDecode(offlinePhotosJson) as Map<String, dynamic>;
      } catch (e) {
        photosMap = {};
      }

      photosMap[noteId] = photoPaths;
      await prefs.setString(_offlinePhotosKey, jsonEncode(photosMap));
      debugPrint(
        'Пути к фото для заметки $noteId сохранены (${photoPaths.length} фото)',
      );
    } catch (e) {
      debugPrint('Ошибка при сохранении путей к фото: $e');
      rethrow;
    }
  }

  /// Получить пути к фотографиям для заметки
  Future<List<String>> getOfflinePhotoPaths(String noteId) async {
    try {
      final prefs = await preferences;
      String offlinePhotosJson = prefs.getString(_offlinePhotosKey) ?? '{}';
      Map<String, dynamic> photosMap;

      try {
        photosMap = jsonDecode(offlinePhotosJson) as Map<String, dynamic>;
      } catch (e) {
        return [];
      }

      if (photosMap.containsKey(noteId)) {
        return List<String>.from(photosMap[noteId]);
      }

      return [];
    } catch (e) {
      debugPrint('Ошибка при получении путей к фото: $e');
      return [];
    }
  }

  /// Сохранить маркерную карту в офлайн хранилище
  Future<void> saveOfflineMarkerMap(Map<String, dynamic> mapData) async {
    try {
      final prefs = await preferences;
      List<String> offlineMapsJson =
          prefs.getStringList(_offlineMarkerMapsKey) ?? [];

      // Проверяем, есть ли уже карта с таким ID
      final mapId = mapData['id'];
      bool mapExists = false;

      List<String> updatedMaps = [];
      for (var mapJson in offlineMapsJson) {
        final map = jsonDecode(mapJson) as Map<String, dynamic>;
        if (map['id'] == mapId) {
          // Обновляем существующую карту
          updatedMaps.add(jsonEncode(mapData));
          mapExists = true;
        } else {
          updatedMaps.add(mapJson);
        }
      }

      // Если такой карты нет, добавляем новую
      if (!mapExists) {
        updatedMaps.add(jsonEncode(mapData));
      }

      await prefs.setStringList(_offlineMarkerMapsKey, updatedMaps);
      debugPrint('Маркерная карта $mapId сохранена в офлайн хранилище');
    } catch (e) {
      debugPrint('Ошибка при сохранении маркерной карты: $e');
      rethrow;
    }
  }

  /// Сохранить обновление маркерной карты
  Future<void> saveMarkerMapUpdate(
      String mapId,
      Map<String, dynamic> mapData,
      ) async {
    try {
      final prefs = await preferences;
      String offlineUpdatesJson =
          prefs.getString(_offlineMarkerMapsUpdatesKey) ?? '{}';
      Map<String, dynamic> updates;

      try {
        updates = jsonDecode(offlineUpdatesJson) as Map<String, dynamic>;
      } catch (e) {
        updates = {};
      }

      updates[mapId] = mapData;
      await prefs.setString(_offlineMarkerMapsUpdatesKey, jsonEncode(updates));
      debugPrint('Обновление маркерной карты $mapId сохранено');
    } catch (e) {
      debugPrint('Ошибка при сохранении обновления маркерной карты: $e');
      rethrow;
    }
  }

  /// Отметить объект для удаления
  Future<void> markForDeletion(String id, bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key = isMarkerMap ? _mapsToDeleteKey : _notesToDeleteKey;
      List<String> idsToDelete = prefs.getStringList(key) ?? [];

      if (!idsToDelete.contains(id)) {
        idsToDelete.add(id);
      }

      await prefs.setStringList(key, idsToDelete);
      final type = isMarkerMap ? 'маркерная карта' : 'заметка';
      debugPrint('$type с ID $id отмечена для удаления');
    } catch (e) {
      debugPrint('Ошибка при отметке для удаления: $e');
      rethrow;
    }
  }

  /// Отметить для удаления всех маркерных карт
  Future<void> markAllMarkerMapsForDeletion() async {
    try {
      final prefs = await preferences;
      await prefs.setBool(_deleteAllMarkerMapsKey, true);
      debugPrint('Все маркерные карты отмечены для удаления');
    } catch (e) {
      debugPrint('Ошибка при отметке всех маркерных карт для удаления: $e');
      rethrow;
    }
  }

  /// Отметить для удаления всех заметок
  Future<void> markAllNotesForDeletion() async {
    try {
      final prefs = await preferences;
      await prefs.setBool(_deleteAllNotesKey, true);
      debugPrint('Все заметки отмечены для удаления');
    } catch (e) {
      debugPrint('Ошибка при отметке всех заметок для удаления: $e');
      rethrow;
    }
  }

  /// Сохранить кэш статистики
  Future<void> saveStatisticsCache(Map<String, dynamic> statistics) async {
    try {
      final prefs = await preferences;
      await prefs.setString(_statisticsCacheKey, jsonEncode(statistics));
      debugPrint('Статистика сохранена в кэш');
    } catch (e) {
      debugPrint('Ошибка при сохранении статистики в кэш: $e');
      rethrow;
    }
  }

  /// Получить кэш статистики
  Future<Map<String, dynamic>?> getStatisticsCache() async {
    try {
      final prefs = await preferences;
      final cachedData = prefs.getString(_statisticsCacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      return jsonDecode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Ошибка при получении кэша статистики: $e');
      return null;
    }
  }

  /// Сохранить данные пользователя для офлайн доступа
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await preferences;
      await prefs.setString(_userDataKey, jsonEncode(userData));
      debugPrint('Данные пользователя сохранены в офлайн хранилище');
    } catch (e) {
      debugPrint('Ошибка при сохранении данных пользователя: $e');
      rethrow;
    }
  }

  /// Получить данные пользователя из офлайн хранилища
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await preferences;
      final userData = prefs.getString(_userDataKey);

      if (userData == null || userData.isEmpty) {
        return null;
      }

      return jsonDecode(userData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Ошибка при получении данных пользователя: $e');
      return null;
    }
  }

  /// Обновить время последней синхронизации
  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await preferences;
      await prefs.setInt(_syncTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('Время последней синхронизации обновлено');
    } catch (e) {
      debugPrint('Ошибка при обновлении времени синхронизации: $e');
    }
  }

  /// Получить время последней синхронизации
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await preferences;
      final timestamp = prefs.getInt(_syncTimeKey);

      if (timestamp == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('Ошибка при получении времени синхронизации: $e');
      return null;
    }
  }

  /// Получить все офлайн заметки
  Future<List<Map<String, dynamic>>> getAllOfflineNotes() async {
    try {
      final prefs = await preferences;
      final offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      List<Map<String, dynamic>> notes = [];
      for (var noteJson in offlineNotesJson) {
        try {
          notes.add(jsonDecode(noteJson) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Ошибка при декодировании заметки: $e');
          // Пропускаем заметки с неверным форматом JSON
        }
      }

      return notes;
    } catch (e) {
      debugPrint('Ошибка при получении офлайн заметок: $e');
      return [];
    }
  }

  /// Получить все офлайн маркерные карты
  Future<List<Map<String, dynamic>>> getAllOfflineMarkerMaps() async {
    try {
      final prefs = await preferences;
      final offlineMapsJson = prefs.getStringList(_offlineMarkerMapsKey) ?? [];

      List<Map<String, dynamic>> maps = [];
      for (var mapJson in offlineMapsJson) {
        try {
          maps.add(jsonDecode(mapJson) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Ошибка при декодировании маркерной карты: $e');
          // Пропускаем карты с неверным форматом JSON
        }
      }

      return maps;
    } catch (e) {
      debugPrint('Ошибка при получении офлайн маркерных карт: $e');
      return [];
    }
  }

  /// Получить все обновления заметок
  Future<Map<String, dynamic>> getAllNoteUpdates() async {
    try {
      final prefs = await preferences;
      final updatesJson = prefs.getString(_offlineNotesUpdatesKey) ?? '{}';

      return jsonDecode(updatesJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Ошибка при получении обновлений заметок: $e');
      return {};
    }
  }

  /// Получить все обновления маркерных карт
  Future<Map<String, dynamic>> getAllMarkerMapUpdates() async {
    try {
      final prefs = await preferences;
      final updatesJson = prefs.getString(_offlineMarkerMapsUpdatesKey) ?? '{}';

      return jsonDecode(updatesJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Ошибка при получении обновлений маркерных карт: $e');
      return {};
    }
  }

  /// Получить все ID для удаления
  Future<List<String>> getIdsToDelete(bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key = isMarkerMap ? _mapsToDeleteKey : _notesToDeleteKey;

      return prefs.getStringList(key) ?? [];
    } catch (e) {
      debugPrint('Ошибка при получении ID для удаления: $e');
      return [];
    }
  }

  /// Проверить, нужно ли удалить все объекты
  Future<bool> shouldDeleteAll(bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key = isMarkerMap ? _deleteAllMarkerMapsKey : _deleteAllNotesKey;

      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('Ошибка при проверке флага удаления всех объектов: $e');
      return false;
    }
  }

  /// Очистить флаг удаления всех объектов
  Future<void> clearDeleteAllFlag(bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key = isMarkerMap ? _deleteAllMarkerMapsKey : _deleteAllNotesKey;

      await prefs.setBool(key, false);
    } catch (e) {
      debugPrint('Ошибка при очистке флага удаления всех объектов: $e');
    }
  }

  /// Очистить список ID для удаления
  Future<void> clearIdsToDelete(bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key = isMarkerMap ? _mapsToDeleteKey : _notesToDeleteKey;

      await prefs.setStringList(key, []);
    } catch (e) {
      debugPrint('Ошибка при очистке списка ID для удаления: $e');
    }
  }

  /// Очистить список обновлений
  Future<void> clearUpdates(bool isMarkerMap) async {
    try {
      final prefs = await preferences;
      final key =
      isMarkerMap ? _offlineMarkerMapsUpdatesKey : _offlineNotesUpdatesKey;

      await prefs.setString(key, '{}');
    } catch (e) {
      debugPrint('Ошибка при очистке списка обновлений: $e');
    }
  }

  /// Удалить офлайн заметку
  Future<void> removeOfflineNote(String noteId) async {
    try {
      final prefs = await preferences;
      final offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      List<String> updatedNotes = [];
      for (var noteJson in offlineNotesJson) {
        try {
          final note = jsonDecode(noteJson) as Map<String, dynamic>;
          if (note['id'] != noteId) {
            updatedNotes.add(noteJson);
          }
        } catch (e) {
          // Если JSON неверный, добавляем заметку как есть
          updatedNotes.add(noteJson);
        }
      }

      await prefs.setStringList(_offlineNotesKey, updatedNotes);

      // Удаляем пути к фото для этой заметки
      String offlinePhotosJson = prefs.getString(_offlinePhotosKey) ?? '{}';
      try {
        Map<String, dynamic> photosMap =
        jsonDecode(offlinePhotosJson) as Map<String, dynamic>;
        photosMap.remove(noteId);
        await prefs.setString(_offlinePhotosKey, jsonEncode(photosMap));
      } catch (e) {
        debugPrint('Ошибка при удалении путей к фото для заметки $noteId: $e');
      }

      debugPrint('Заметка $noteId удалена из офлайн хранилища');
    } catch (e) {
      debugPrint('Ошибка при удалении заметки из офлайн хранилища: $e');
      rethrow;
    }
  }

  /// Удалить офлайн маркерную карту
  Future<void> removeOfflineMarkerMap(String mapId) async {
    try {
      final prefs = await preferences;
      final offlineMapsJson = prefs.getStringList(_offlineMarkerMapsKey) ?? [];

      List<String> updatedMaps = [];
      for (var mapJson in offlineMapsJson) {
        try {
          final map = jsonDecode(mapJson) as Map<String, dynamic>;
          if (map['id'] != mapId) {
            updatedMaps.add(mapJson);
          }
        } catch (e) {
          // Если JSON неверный, добавляем карту как есть
          updatedMaps.add(mapJson);
        }
      }

      await prefs.setStringList(_offlineMarkerMapsKey, updatedMaps);
      debugPrint('Маркерная карта $mapId удалена из офлайн хранилища');
    } catch (e) {
      debugPrint('Ошибка при удалении маркерной карты из офлайн хранилища: $e');
      rethrow;
    }
  }

  /// Очистить все офлайн данные
  Future<void> clearAllOfflineData() async {
    try {
      // 🔥 ДОБАВЛЯЕМ ОТЛАДКУ ДЛЯ ПОИСКА МЕСТА ВЫЗОВА
      if (kDebugMode) {
        debugPrint('🚨 OfflineStorageService.clearAllOfflineData() ВЫЗВАН!');
        debugPrint('📍 Stack trace вызова:');
        debugPrint(StackTrace.current.toString());
      }

      final prefs = await preferences;
      await prefs.remove(_offlineNotesKey);
      await prefs.remove(_offlineNotesUpdatesKey);
      await prefs.remove(_offlinePhotosKey);
      await prefs.remove(_offlineMarkerMapsKey);
      await prefs.remove(_offlineMarkerMapsUpdatesKey);
      await prefs.remove(_mapsToDeleteKey);
      await prefs.remove(_notesToDeleteKey);
      await prefs.remove(_statisticsCacheKey);
      await prefs.remove(_deleteAllMarkerMapsKey);
      await prefs.remove(_deleteAllNotesKey);

      // 🔥 Очищаем новые ключи
      await prefs.remove(_cachedSubscriptionKey);
      await prefs.remove(_subscriptionCacheTimeKey);
      await prefs.remove(_usageLimitsKey);
      await prefs.remove(_localNotesCountKey);
      await prefs.remove(_localMapsCountKey);
      await prefs.remove(_localExpensesCountKey);
      await prefs.remove(_localDepthChartCountKey);
      await prefs.remove(_localCountersResetKey);
      await prefs.remove('cached_fishing_notes');
      await prefs.remove('cached_marker_maps');

      // 🔥 Очищаем данные офлайн авторизации
      await clearOfflineAuthData();

      debugPrint('Все офлайн данные очищены');
    } catch (e) {
      debugPrint('Ошибка при очистке всех офлайн данных: $e');
      rethrow;
    }
  }

  /// Очистить проблемную заметку по ID
  Future<bool> clearCorruptedNote(String noteId) async {
    try {
      final prefs = await preferences;
      final offlineNotesJson = prefs.getStringList(_offlineNotesKey) ?? [];

      // Проверяем, есть ли заметка с таким ID
      bool noteExists = false;
      List<String> updatedNotes = [];

      for (var noteJson in offlineNotesJson) {
        try {
          final note = jsonDecode(noteJson) as Map<String, dynamic>;
          if (note['id'] == noteId) {
            noteExists = true;
            // Пропускаем эту заметку (не добавляем в обновленный список)
            debugPrint('Удаляем проблемную заметку с ID: $noteId');
          } else {
            updatedNotes.add(noteJson);
          }
        } catch (e) {
          // Если JSON неверный, пропускаем эту заметку
          debugPrint('Пропущена заметка с неверным форматом JSON');
        }
      }

      if (noteExists) {
        // Обновляем список заметок
        await prefs.setStringList(_offlineNotesKey, updatedNotes);

        // Удаляем соответствующие данные
        String offlineUpdatesJson =
            prefs.getString(_offlineNotesUpdatesKey) ?? '{}';
        try {
          Map<String, dynamic> updates = jsonDecode(offlineUpdatesJson);
          updates.remove(noteId);
          await prefs.setString(_offlineNotesUpdatesKey, jsonEncode(updates));
        } catch (e) {
          // Игнорируем ошибки при работе с обновлениями
        }

        // Удаляем пути к фото
        String offlinePhotosJson = prefs.getString(_offlinePhotosKey) ?? '{}';
        try {
          Map<String, dynamic> photosMap = jsonDecode(offlinePhotosJson);
          photosMap.remove(noteId);
          await prefs.setString(_offlinePhotosKey, jsonEncode(photosMap));
        } catch (e) {
          // Игнорируем ошибки при работе с путями к фото
        }

        debugPrint('✅ Проблемная заметка $noteId успешно удалена из хранилища');
        return true;
      } else {
        debugPrint('⚠️ Заметка $noteId не найдена в хранилище');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при удалении проблемной заметки: $e');
      return false;
    }
  }
}