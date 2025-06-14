// Путь: lib/services/offline/offline_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
