// Путь: lib/services/offline/sync_service.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_service.dart';
import 'offline_storage_service.dart';
import '../../utils/network_utils.dart';

/// Сервис для синхронизации данных между локальным хранилищем и облаком
class SyncService {
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSyncing = false;
  Timer? _syncTimer;

  /// Запустить периодическую синхронизацию данных
  void startPeriodicSync({Duration period = const Duration(minutes: 5)}) {
    // Отменяем предыдущий таймер, если он был запущен
    _syncTimer?.cancel();

    // Запускаем новый таймер
    _syncTimer = Timer.periodic(period, (timer) async {
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (isConnected) {
        await syncAll();
      }
    });

    debugPrint('Запущена периодическая синхронизация каждые ${period.inMinutes} минут');
  }

  /// Остановить периодическую синхронизацию
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Периодическая синхронизация остановлена');
  }

  /// Синхронизировать все данные
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('Синхронизация уже выполняется, пропускаем');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('Начинаем синхронизацию всех данных...');

      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('Нет подключения к интернету, синхронизация невозможна');
        _isSyncing = false;
        return;
      }

      // Проверяем авторизацию пользователя
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('Пользователь не авторизован, синхронизация невозможна');
        _isSyncing = false;
        return;
      }

      // Синхронизируем все типы данных
      await Future.wait([
        _syncMarkerMaps(userId),
        _syncNotes(userId),
      ]);

      // Обновляем время последней синхронизации
      await _offlineStorage.updateLastSyncTime();

      debugPrint('Синхронизация всех данных завершена успешно');
    } catch (e) {
      debugPrint('Ошибка при синхронизации данных: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Синхронизировать заметки
  Future<void> _syncNotes(String userId) async {
    try {
      debugPrint('Начинаем синхронизацию заметок...');

      // Проверяем флаг на удаление всех заметок
      final shouldDeleteAll = await _offlineStorage.shouldDeleteAll(false);
      if (shouldDeleteAll) {
        debugPrint('Обнаружен флаг на удаление всех заметок');

        try {
          // Получаем все заметки пользователя и удаляем их
          final snapshot = await _firestore
              .collection('fishing_notes')
              .where('userId', isEqualTo: userId)
              .get();

          // Создаем пакетную операцию для удаления
          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
          await _offlineStorage.clearDeleteAllFlag(false);
          debugPrint('Все заметки пользователя удалены (${snapshot.docs.length} шт.)');
        } catch (e) {
          debugPrint('Ошибка при удалении всех заметок: $e');
        }

        // Если все заметки удалены, нет смысла продолжать синхронизацию
        return;
      }

      // Синхронизируем отдельные удаления
      final notesToDelete = await _offlineStorage.getIdsToDelete(false);
      if (notesToDelete.isNotEmpty) {
        debugPrint('Синхронизация удалений заметок (${notesToDelete.length} шт.)');

        for (var noteId in notesToDelete) {
          try {
            await _firestore.collection('fishing_notes').doc(noteId).delete();
            debugPrint('Заметка $noteId удалена из Firestore');
          } catch (e) {
            debugPrint('Ошибка при удалении заметки $noteId из Firestore: $e');
          }
        }

        // Очищаем список заметок для удаления
        await _offlineStorage.clearIdsToDelete(false);
      }

      // Синхронизируем новые заметки
      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      if (offlineNotes.isNotEmpty) {
        debugPrint('Синхронизация новых заметок (${offlineNotes.length} шт.)');

        for (var noteData in offlineNotes) {
          try {
            // Удостоверяемся, что у заметки есть ID и UserID
            final noteId = noteData['id'];
            if (noteId == null || noteId.isEmpty) {
              debugPrint('Заметка без ID, пропускаем');
              continue;
            }

            // Проверяем и устанавливаем userId
            if (noteData['userId'] == null || noteData['userId'].isEmpty) {
              noteData['userId'] = userId;
            }

            // Проверяем, есть ли фотографии для загрузки
            final photoPaths = await _offlineStorage.getOfflinePhotoPaths(noteId);
            final List<String> photoUrls = List<String>.from(noteData['photoUrls'] ?? []);

            // Загружаем фотографии
            if (photoPaths.isNotEmpty) {
              debugPrint('Загрузка фотографий для заметки $noteId (${photoPaths.length} шт.)');

              for (var path in photoPaths) {
                try {
                  final file = File(path);
                  if (await file.exists()) {
                    final bytes = await file.readAsBytes();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photoPaths.indexOf(path)}.jpg';
                    final storagePath = 'users/$userId/photos/$fileName';

                    final url = await _firebaseService.uploadImage(storagePath, bytes);
                    photoUrls.add(url);
                    debugPrint('Фото загружено: $url');
                  } else {
                    debugPrint('Файл не существует: $path');
                  }
                } catch (e) {
                  debugPrint('Ошибка при загрузке фото из $path: $e');
                }
              }

              // Обновляем URL фотографий в данных заметки
              noteData['photoUrls'] = photoUrls;
            }

            // Сохраняем или обновляем заметку в Firestore
            await _firestore.collection('fishing_notes').doc(noteId).set(noteData);

            // Удаляем заметку из локального хранилища после успешной синхронизации
            await _offlineStorage.removeOfflineNote(noteId);

            debugPrint('Заметка $noteId успешно синхронизирована');
          } catch (e) {
            debugPrint('Ошибка при синхронизации заметки: $e');
          }
        }
      }

      // Синхронизируем обновления заметок
      final noteUpdates = await _offlineStorage.getAllNoteUpdates();
      if (noteUpdates.isNotEmpty) {
        debugPrint('Синхронизация обновлений заметок (${noteUpdates.length} шт.)');

        for (var entry in noteUpdates.entries) {
          try {
            final noteId = entry.key;
            final noteData = entry.value as Map<String, dynamic>;

            // Проверяем и устанавливаем userId
            if (noteData['userId'] == null || noteData['userId'].isEmpty) {
              noteData['userId'] = userId;
            }

            // Сохраняем обновления в Firestore
            await _firestore.collection('fishing_notes').doc(noteId).update(noteData);

            debugPrint('Обновление заметки $noteId успешно синхронизировано');
          } catch (e) {
            debugPrint('Ошибка при синхронизации обновления заметки: $e');
          }
        }

        // Очищаем список обновлений
        await _offlineStorage.clearUpdates(false);
      }

      debugPrint('Синхронизация заметок завершена');
    } catch (e) {
      debugPrint('Ошибка при синхронизации заметок: $e');
      rethrow;
    }
  }

  /// Синхронизировать маркерные карты
  Future<void> _syncMarkerMaps(String userId) async {
    try {
      debugPrint('Начинаем синхронизацию маркерных карт...');

      // Проверяем флаг на удаление всех маркерных карт
      final shouldDeleteAll = await _offlineStorage.shouldDeleteAll(true);
      if (shouldDeleteAll) {
        debugPrint('Обнаружен флаг на удаление всех маркерных карт');

        try {
          // Получаем все маркерные карты пользователя и удаляем их
          final snapshot = await _firestore
              .collection('marker_maps')
              .where('userId', isEqualTo: userId)
              .get();

          // Создаем пакетную операцию для удаления
          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
          await _offlineStorage.clearDeleteAllFlag(true);
          debugPrint('Все маркерные карты пользователя удалены (${snapshot.docs.length} шт.)');
        } catch (e) {
          debugPrint('Ошибка при удалении всех маркерных карт: $e');
        }

        // Если все маркерные карты удалены, нет смысла продолжать синхронизацию
        return;
      }

      // Синхронизируем отдельные удаления
      final mapsToDelete = await _offlineStorage.getIdsToDelete(true);
      if (mapsToDelete.isNotEmpty) {
        debugPrint('Синхронизация удалений маркерных карт (${mapsToDelete.length} шт.)');

        for (var mapId in mapsToDelete) {
          try {
            await _firestore.collection('marker_maps').doc(mapId).delete();
            debugPrint('Маркерная карта $mapId удалена из Firestore');
          } catch (e) {
            debugPrint('Ошибка при удалении маркерной карты $mapId из Firestore: $e');
          }
        }

        // Очищаем список маркерных карт для удаления
        await _offlineStorage.clearIdsToDelete(true);
      }

      // Синхронизируем новые маркерные карты
      final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
      if (offlineMaps.isNotEmpty) {
        debugPrint('Синхронизация новых маркерных карт (${offlineMaps.length} шт.)');

        for (var mapData in offlineMaps) {
          try {
            // Удостоверяемся, что у карты есть ID и UserID
            final mapId = mapData['id'];
            if (mapId == null || mapId.isEmpty) {
              debugPrint('Маркерная карта без ID, пропускаем');
              continue;
            }

            // Проверяем и устанавливаем userId
            if (mapData['userId'] == null || mapData['userId'].isEmpty) {
              mapData['userId'] = userId;
            }

            // Сохраняем маркерную карту в Firestore
            await _firestore.collection('marker_maps').doc(mapId).set(mapData);

            // Удаляем маркерную карту из локального хранилища после успешной синхронизации
            await _offlineStorage.removeOfflineMarkerMap(mapId);

            debugPrint('Маркерная карта $mapId успешно синхронизирована');
          } catch (e) {
            debugPrint('Ошибка при синхронизации маркерной карты: $e');
          }
        }
      }

      // Синхронизируем обновления маркерных карт
      final mapUpdates = await _offlineStorage.getAllMarkerMapUpdates();
      if (mapUpdates.isNotEmpty) {
        debugPrint('Синхронизация обновлений маркерных карт (${mapUpdates.length} шт.)');

        for (var entry in mapUpdates.entries) {
          try {
            final mapId = entry.key;
            final mapData = entry.value as Map<String, dynamic>;

            // Проверяем и устанавливаем userId
            if (mapData['userId'] == null || mapData['userId'].isEmpty) {
              mapData['userId'] = userId;
            }

            // Сохраняем обновления в Firestore
            await _firestore.collection('marker_maps').doc(mapId).update(mapData);

            debugPrint('Обновление маркерной карты $mapId успешно синхронизировано');
          } catch (e) {
            debugPrint('Ошибка при синхронизации обновления маркерной карты: $e');
          }
        }

        // Очищаем список обновлений
        await _offlineStorage.clearUpdates(true);
      }

      debugPrint('Синхронизация маркерных карт завершена');
    } catch (e) {
      debugPrint('Ошибка при синхронизации маркерных карт: $e');
      rethrow;
    }
  }

  /// Получить информацию о статусе синхронизации
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final lastSyncTime = await _offlineStorage.getLastSyncTime();

      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      final offlineNoteUpdates = await _offlineStorage.getAllNoteUpdates();
      final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
      final offlineMapUpdates = await _offlineStorage.getAllMarkerMapUpdates();

      final notesToDelete = await _offlineStorage.getIdsToDelete(false);
      final mapsToDelete = await _offlineStorage.getIdsToDelete(true);

      final pendingChanges = offlineNotes.length +
          offlineNoteUpdates.length +
          offlineMaps.length +
          offlineMapUpdates.length +
          notesToDelete.length +
          mapsToDelete.length;

      return {
        'lastSyncTime': lastSyncTime,
        'isSyncing': _isSyncing,
        'pendingChanges': pendingChanges,
        'offlineNotes': offlineNotes.length,
        'offlineNoteUpdates': offlineNoteUpdates.length,
        'offlineMaps': offlineMaps.length,
        'offlineMapUpdates': offlineMapUpdates.length,
        'notesToDelete': notesToDelete.length,
        'mapsToDelete': mapsToDelete.length,
      };
    } catch (e) {
      debugPrint('Ошибка при получении статуса синхронизации: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Принудительно запустить полную синхронизацию
  Future<bool> forceSyncAll() async {
    try {
      if (_isSyncing) {
        debugPrint('Синхронизация уже запущена, пропускаем');
        return false;
      }

      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('Нет подключения к интернету, синхронизация невозможна');
        return false;
      }

      await syncAll();
      return true;
    } catch (e) {
      debugPrint('Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }
}