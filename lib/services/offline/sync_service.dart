// Путь: lib/services/offline/sync_service.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase/firebase_service.dart';
import '../subscription/subscription_service.dart';
import 'offline_storage_service.dart';
import '../../utils/network_utils.dart';
import '../local/local_file_service.dart';
import '../../constants/subscription_constants.dart';

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
  final LocalFileService _localFileService = LocalFileService();

  // 🔥 НОВЫЕ ПОЛЯ для офлайн премиум
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isSyncing = false;
  Timer? _syncTimer;

  // Хранение последней попытки синхронизации для каждого типа данных
  final Map<String, DateTime> _lastSyncAttempt = {};
  // Счетчики ошибок
  final Map<String, int> _errorCounters = {};
  // Максимальное количество попыток
  final int _maxRetries = 3;

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

    debugPrint(
      '🕒 Запущена периодическая синхронизация каждые ${period.inMinutes} минут',
    );
  }

  /// Остановить периодическую синхронизацию
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('⏹️ Периодическая синхронизация остановлена');
  }

  /// Синхронизировать все данные
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('⚠️ Синхронизация уже выполняется, пропускаем');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Начинаем синхронизацию всех данных...');

      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('❌ Нет подключения к интернету, синхронизация невозможна');
        _isSyncing = false;
        return;
      }

      // Проверяем авторизацию пользователя
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('❌ Пользователь не авторизован, синхронизация невозможна');
        _isSyncing = false;
        return;
      }

      // 🔥 НОВОЕ: Синхронизируем счетчики использования ПЕРВЫМИ
      await syncUsageCounters();

      // 🔥 НОВОЕ: Синхронизируем статус подписки
      await syncSubscriptionStatus();

      // Синхронизируем все типы данных
      await Future.wait([_syncMarkerMaps(userId), _syncNotes(userId)]);

      // Обновляем время последней синхронизации
      await _offlineStorage.updateLastSyncTime();

      debugPrint('✅ Синхронизация всех данных завершена успешно');
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации данных: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // 🔥 НОВЫЕ МЕТОДЫ для синхронизации счетчиков

  /// Синхронизация счетчиков использования после восстановления сети
  Future<void> syncUsageCounters() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Начинаем синхронизацию счетчиков использования...');
      }

      // Проверяем доступность сети
      if (!await NetworkUtils.isNetworkAvailable()) {
        if (kDebugMode) {
          debugPrint('❌ Нет сети для синхронизации счетчиков');
        }
        return;
      }

      // 1. Получаем локальные счетчики
      final localCounters = await _offlineStorage.getAllLocalUsageCounters();

      if (localCounters.isEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Нет локальных счетчиков для синхронизации');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('📊 Локальные счетчики для синхронизации:');
        for (final entry in localCounters.entries) {
          debugPrint('   ${entry.key.name}: ${entry.value}');
        }
      }

      // 2. Обновляем актуальные лимиты с сервера
      await _subscriptionService.refreshUsageLimits();

      // 3. Проверяем превышения лимитов
      bool hasOverages = false;
      for (final entry in localCounters.entries) {
        final contentType = entry.key;
        final localCount = entry.value;

        if (localCount > 0) {
          await _checkAndHandleLimitOverage(contentType, localCount);
          hasOverages = true;
        }
      }

      // 4. Сбрасываем локальные счетчики после успешной синхронизации
      await _offlineStorage.resetLocalUsageCounters();

      if (kDebugMode) {
        debugPrint('✅ Синхронизация счетчиков завершена');
      }

      // 5. Показываем уведомление о синхронизации
      await _showSyncNotification(hasOverages);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка синхронизации счетчиков: $e');
      }
      rethrow;
    }
  }

  /// Проверка и обработка превышения лимитов
  Future<void> _checkAndHandleLimitOverage(ContentType contentType, int localCount) async {
    try {
      // Получаем текущее использование с сервера
      final serverUsage = await _subscriptionService.getCurrentUsage(contentType);
      final limit = _subscriptionService.getLimit(contentType);
      final totalUsage = serverUsage + localCount;

      if (kDebugMode) {
        debugPrint('🔍 Проверка превышения для $contentType:');
        debugPrint('   Серверное использование: $serverUsage');
        debugPrint('   Локальное использование: $localCount');
        debugPrint('   Общее использование: $totalUsage');
        debugPrint('   Лимит: $limit');
      }

      // Проверяем превышение лимита + grace period
      if (totalUsage > limit + SubscriptionConstants.offlineGraceLimit) {
        await handleOfflineLimitExceeded(contentType, totalUsage - limit);
      } else if (totalUsage > limit) {
        await _handleGracePeriodUsage(contentType, totalUsage - limit);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки превышения лимитов для $contentType: $e');
      }
    }
  }

  /// Обработка превышения лимита + grace period
  Future<void> handleOfflineLimitExceeded(ContentType contentType, int exceededBy) async {
    try {
      if (kDebugMode) {
        debugPrint('🚨 Превышение лимита для $contentType на $exceededBy элементов');
      }

      // Логируем превышение
      await _logLimitExceeded(contentType, exceededBy);

      // Показываем уведомление пользователю
      await _showLimitExceededNotification(contentType, exceededBy);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обработки превышения лимита: $e');
      }
    }
  }

  /// Обработка использования в пределах grace period
  Future<void> _handleGracePeriodUsage(ContentType contentType, int overageCount) async {
    try {
      if (kDebugMode) {
        debugPrint('⚠️ Использование в grace period для $contentType: +$overageCount элементов');
      }

      // Показываем предупреждение о приближении к лимиту
      await _showGracePeriodWarning(contentType, overageCount);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка обработки grace period: $e');
      }
    }
  }

  /// Синхронизация статуса подписки
  Future<void> syncSubscriptionStatus() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Синхронизация статуса подписки...');
      }

      // Проверяем доступность сети
      if (!await NetworkUtils.isNetworkAvailable()) {
        if (kDebugMode) {
          debugPrint('❌ Нет сети для синхронизации подписки');
        }
        return;
      }

      // Кэшируем данные подписки
      await _subscriptionService.cacheSubscriptionDataOnline();

      if (kDebugMode) {
        debugPrint('✅ Статус подписки синхронизирован');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка синхронизации подписки: $e');
      }
    }
  }

  /// Логирование превышения лимита
  Future<void> _logLimitExceeded(ContentType contentType, int exceededBy) async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'contentType': contentType.name,
        'exceededBy': exceededBy,
        'userId': _firebaseService.currentUserId,
        'type': 'limit_exceeded_offline',
      };

      // Можно отправить в аналитику или сохранить локально
      if (kDebugMode) {
        debugPrint('📊 Лог превышения лимита: $logData');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка логирования превышения лимита: $e');
      }
    }
  }

  /// Показать уведомление о превышении лимита
  Future<void> _showLimitExceededNotification(ContentType contentType, int exceededBy) async {
    try {
      final contentName = SubscriptionConstants.getContentTypeName(contentType);

      if (kDebugMode) {
        debugPrint('🚨 Уведомление: Превышен лимит $contentName на $exceededBy элементов');
      }

      // Здесь можно добавить показ уведомления пользователю
      // Например, через NotificationService или SnackBar

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка показа уведомления о превышении лимита: $e');
      }
    }
  }

  /// Показать предупреждение о grace period
  Future<void> _showGracePeriodWarning(ContentType contentType, int overageCount) async {
    try {
      final contentName = SubscriptionConstants.getContentTypeName(contentType);
      final remaining = SubscriptionConstants.offlineGraceLimit - overageCount;

      if (kDebugMode) {
        debugPrint('⚠️ Предупреждение: Использовано $overageCount из ${SubscriptionConstants.offlineGraceLimit} дополнительных $contentName. Осталось: $remaining');
      }

      // Здесь можно добавить показ предупреждения пользователю

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка показа предупреждения grace period: $e');
      }
    }
  }

  /// Показать уведомление о синхронизации
  Future<void> _showSyncNotification(bool hasOverages) async {
    try {
      if (hasOverages) {
        if (kDebugMode) {
          debugPrint('🔄 Синхронизация завершена с превышениями лимитов');
        }
      } else {
        if (kDebugMode) {
          debugPrint('✅ Синхронизация завершена успешно');
        }
      }

      // Здесь можно добавить показ уведомления пользователю

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка показа уведомления о синхронизации: $e');
      }
    }
  }

  /// Обрабатывает локальные URI файлов в структуре данных и заменяет их на серверные URL
  Future<void> _processLocalFileUrls(
      Map<String, dynamic> data,
      String userId,
      ) async {
    // Проверяем наличие списка photoUrls
    if (data['photoUrls'] is List) {
      final photoUrls = List<String>.from(data['photoUrls']);
      final List<String> processedUrls = [];
      bool hasChanges = false;

      for (var url in photoUrls) {
        // Проверяем, является ли URL локальным файлом или placeholder
        if (_localFileService.isLocalFileUri(url)) {
          // Обрабатываем локальный файл
          try {
            final file = _localFileService.localUriToFile(url);
            if (file != null && await file.exists()) {
              // Загружаем файл на сервер
              final bytes = await file.readAsBytes();
              final fileName =
                  '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg';
              final path = 'users/$userId/photos/$fileName';
              final serverUrl = await _firebaseService.uploadImage(path, bytes);

              processedUrls.add(serverUrl);
              hasChanges = true;

              // Удаляем локальную копию после успешной загрузки
              await _localFileService.deleteLocalFile(url);
              debugPrint(
                '🔄 Локальный файл $url заменен на серверный $serverUrl',
              );
            } else {
              // Если файл не существует, сохраняем исходный URL (будет обработан как ошибка)
              processedUrls.add(url);
              debugPrint('⚠️ Локальный файл $url не существует');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка при обработке локального файла $url: $e');
            // Если произошла ошибка, сохраняем исходный URL
            processedUrls.add(url);
          }
        } else if (url == 'offline_photo') {
          // Удаляем placeholder
          hasChanges = true;
          debugPrint('🧹 Удален placeholder offline_photo');
        } else {
          // Сохраняем исходный URL
          processedUrls.add(url);
        }
      }

      // Обновляем список URL только если были изменения
      if (hasChanges) {
        // Фильтруем, удаляя placeholder 'offline_photo'
        data['photoUrls'] =
            processedUrls.where((url) => url != 'offline_photo').toList();
      }
    }
  }

  /// Синхронизировать заметки
  Future<void> _syncNotes(String userId) async {
    const dataType = 'notes';

    // Проверка на слишком частые попытки синхронизации с ошибками
    if (_shouldSkipSync(dataType)) {
      debugPrint('⏭️ Пропускаем синхронизацию заметок из-за частых ошибок');
      return;
    }

    try {
      debugPrint('🔄 Начинаем синхронизацию заметок...');
      _lastSyncAttempt[dataType] = DateTime.now();

      // Проверяем флаг на удаление всех заметок
      final shouldDeleteAll = await _offlineStorage.shouldDeleteAll(false);
      if (shouldDeleteAll) {
        debugPrint('⚠️ Обнаружен флаг на удаление всех заметок');

        try {
          // Получаем все заметки пользователя и удаляем их
          final snapshot =
          await _firestore
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
          debugPrint(
            '✅ Все заметки пользователя удалены (${snapshot.docs.length} шт.)',
          );
        } catch (e) {
          debugPrint('❌ Ошибка при удалении всех заметок: $e');
          _incrementErrorCounter(dataType);
        }

        // Если все заметки удалены, нет смысла продолжать синхронизацию
        return;
      }

      // Синхронизируем отдельные удаления
      final notesToDelete = await _offlineStorage.getIdsToDelete(false);
      if (notesToDelete.isNotEmpty) {
        debugPrint(
          '🗑️ Синхронизация удалений заметок (${notesToDelete.length} шт.)',
        );

        for (var noteId in notesToDelete) {
          try {
            await _firestore.collection('fishing_notes').doc(noteId).delete();
            debugPrint('✅ Заметка $noteId удалена из Firestore');
          } catch (e) {
            debugPrint(
              '❌ Ошибка при удалении заметки $noteId из Firestore: $e',
            );
          }
        }

        // Очищаем список заметок для удаления
        await _offlineStorage.clearIdsToDelete(false);
      }

      // Синхронизируем обновления заметок
      final noteUpdates = await _offlineStorage.getAllNoteUpdates();
      if (noteUpdates.isNotEmpty) {
        debugPrint(
          '🔄 Синхронизация обновлений заметок (${noteUpdates.length} шт.)',
        );

        for (var entry in noteUpdates.entries) {
          try {
            final noteId = entry.key;
            final noteData = entry.value as Map<String, dynamic>;

            // Проверяем и устанавливаем userId
            if (noteData['userId'] == null || noteData['userId'].isEmpty) {
              noteData['userId'] = userId;
            }

            // Проверяем наличие ID в данных
            if (!noteData.containsKey('id')) {
              noteData['id'] = noteId;
            }

            // Обрабатываем локальные URI файлов перед сохранением
            await _processLocalFileUrls(noteData, userId);

            // Сохраняем обновления в Firestore
            await _firestore
                .collection('fishing_notes')
                .doc(noteId)
                .set(noteData, SetOptions(merge: true));

            debugPrint('✅ Обновление заметки $noteId успешно синхронизировано');
          } catch (e) {
            debugPrint('❌ Ошибка при синхронизации обновления заметки: $e');
            _incrementErrorCounter(dataType);
          }
        }

        // Очищаем список обновлений
        await _offlineStorage.clearUpdates(false);
      }

      // Синхронизируем новые заметки
      final offlineNotes = await _offlineStorage.getAllOfflineNotes();
      if (offlineNotes.isNotEmpty) {
        debugPrint(
          '🔄 Синхронизация новых заметок (${offlineNotes.length} шт.)',
        );

        for (var noteData in offlineNotes) {
          try {
            // Удостоверяемся, что у заметки есть ID и UserID
            final noteId = noteData['id']?.toString();
            if (noteId == null || noteId.isEmpty) {
              debugPrint('⚠️ Заметка без ID, пропускаем');
              continue;
            }

            // Проверяем и устанавливаем userId
            if (noteData['userId'] == null || noteData['userId'].isEmpty) {
              noteData['userId'] = userId;
            }

            // Проверяем, есть ли фотографии для загрузки
            final photoPaths = await _offlineStorage.getOfflinePhotoPaths(
              noteId,
            );

            // Обрабатываем локальные URI в данных заметки
            await _processLocalFileUrls(noteData, userId);

            // Загрузка исходных фотографий из сохраненных путей
            if (photoPaths.isNotEmpty) {
              debugPrint(
                '🖼️ Загрузка фотографий для заметки $noteId (${photoPaths.length} шт.)',
              );

              // Получаем текущий список URL фотографий
              List<String> photoUrls = [];
              if (noteData['photoUrls'] is List) {
                photoUrls = List<String>.from(noteData['photoUrls']);
              }

              for (var path in photoPaths) {
                try {
                  final file = File(path);
                  if (await file.exists()) {
                    final bytes = await file.readAsBytes();
                    final fileName =
                        '${DateTime.now().millisecondsSinceEpoch}_${photoPaths.indexOf(path)}.jpg';
                    final storagePath = 'users/$userId/photos/$fileName';

                    final url = await _firebaseService.uploadImage(
                      storagePath,
                      bytes,
                    );
                    // Добавляем URL только если его еще нет в списке
                    if (!photoUrls.contains(url)) {
                      photoUrls.add(url);
                    }
                    debugPrint('✅ Фото загружено: $url');
                  } else {
                    debugPrint('⚠️ Файл не существует: $path');
                  }
                } catch (e) {
                  debugPrint('❌ Ошибка при загрузке фото из $path: $e');
                }
              }

              // Обновляем URL фотографий в данных заметки
              noteData['photoUrls'] = photoUrls;
            }

            // Сохраняем или обновляем заметку в Firestore
            await _firestore
                .collection('fishing_notes')
                .doc(noteId)
                .set(noteData);

            // Удаляем заметку из локального хранилища после успешной синхронизации
            await _offlineStorage.removeOfflineNote(noteId);

            debugPrint('✅ Заметка $noteId успешно синхронизирована');
          } catch (e) {
            debugPrint('❌ Ошибка при синхронизации заметки: $e');
            _incrementErrorCounter(dataType);
          }
        }
      }

      debugPrint('✅ Синхронизация заметок завершена');

      // Сбрасываем счетчик ошибок, если все прошло успешно
      _errorCounters[dataType] = 0;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации заметок: $e');
      _incrementErrorCounter(dataType);
      rethrow;
    }
  }

  /// Синхронизировать маркерные карты
  Future<void> _syncMarkerMaps(String userId) async {
    const dataType = 'marker_maps';

    // Проверка на слишком частые попытки синхронизации с ошибками
    if (_shouldSkipSync(dataType)) {
      debugPrint(
        '⏭️ Пропускаем синхронизацию маркерных карт из-за частых ошибок',
      );
      return;
    }

    try {
      debugPrint('🔄 Начинаем синхронизацию маркерных карт...');
      _lastSyncAttempt[dataType] = DateTime.now();

      // Проверяем флаг на удаление всех маркерных карт
      final shouldDeleteAll = await _offlineStorage.shouldDeleteAll(true);
      if (shouldDeleteAll) {
        debugPrint('⚠️ Обнаружен флаг на удаление всех маркерных карт');

        try {
          // Получаем все маркерные карты пользователя и удаляем их
          final snapshot =
          await _firestore
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
          debugPrint(
            '✅ Все маркерные карты пользователя удалены (${snapshot.docs.length} шт.)',
          );
        } catch (e) {
          debugPrint('❌ Ошибка при удалении всех маркерных карт: $e');
          _incrementErrorCounter(dataType);
        }

        // Если все маркерные карты удалены, нет смысла продолжать синхронизацию
        return;
      }

      // Синхронизируем отдельные удаления
      final mapsToDelete = await _offlineStorage.getIdsToDelete(true);
      if (mapsToDelete.isNotEmpty) {
        debugPrint(
          '🗑️ Синхронизация удалений маркерных карт (${mapsToDelete.length} шт.)',
        );

        for (var mapId in mapsToDelete) {
          try {
            await _firestore.collection('marker_maps').doc(mapId).delete();
            debugPrint('✅ Маркерная карта $mapId удалена из Firestore');
          } catch (e) {
            debugPrint(
              '❌ Ошибка при удалении маркерной карты $mapId из Firestore: $e',
            );
          }
        }

        // Очищаем список маркерных карт для удаления
        await _offlineStorage.clearIdsToDelete(true);
      }

      // Синхронизируем обновления маркерных карт
      final mapUpdates = await _offlineStorage.getAllMarkerMapUpdates();
      if (mapUpdates.isNotEmpty) {
        debugPrint(
          '🔄 Синхронизация обновлений маркерных карт (${mapUpdates.length} шт.)',
        );

        for (var entry in mapUpdates.entries) {
          try {
            final mapId = entry.key;
            final mapData = entry.value as Map<String, dynamic>;

            // Проверяем и устанавливаем userId
            if (mapData['userId'] == null || mapData['userId'].isEmpty) {
              mapData['userId'] = userId;
            }

            // Проверяем наличие ID в данных
            if (!mapData.containsKey('id')) {
              mapData['id'] = mapId;
            }

            // Сохраняем обновления в Firestore
            await _firestore
                .collection('marker_maps')
                .doc(mapId)
                .set(mapData, SetOptions(merge: true));

            debugPrint(
              '✅ Обновление маркерной карты $mapId успешно синхронизировано',
            );
          } catch (e) {
            debugPrint(
              '❌ Ошибка при синхронизации обновления маркерной карты: $e',
            );
            _incrementErrorCounter(dataType);
          }
        }

        // Очищаем список обновлений
        await _offlineStorage.clearUpdates(true);
      }

      // Синхронизируем новые маркерные карты
      final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
      if (offlineMaps.isNotEmpty) {
        debugPrint(
          '🔄 Синхронизация новых маркерных карт (${offlineMaps.length} шт.)',
        );

        for (var mapData in offlineMaps) {
          try {
            // Удостоверяемся, что у карты есть ID и UserID
            final mapId = mapData['id']?.toString();
            if (mapId == null || mapId.isEmpty) {
              debugPrint('⚠️ Маркерная карта без ID, пропускаем');
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

            debugPrint('✅ Маркерная карта $mapId успешно синхронизирована');
          } catch (e) {
            debugPrint('❌ Ошибка при синхронизации маркерной карты: $e');
            _incrementErrorCounter(dataType);
          }
        }
      }

      debugPrint('✅ Синхронизация маркерных карт завершена');

      // Сбрасываем счетчик ошибок, если все прошло успешно
      _errorCounters[dataType] = 0;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации маркерных карт: $e');
      _incrementErrorCounter(dataType);
      rethrow;
    }
  }

  // Проверка, следует ли пропустить синхронизацию для данного типа данных
  bool _shouldSkipSync(String dataType) {
    final lastAttempt = _lastSyncAttempt[dataType];
    final errorCount = _errorCounters[dataType] ?? 0;

    // Если ошибок нет, продолжаем синхронизацию
    if (errorCount < _maxRetries) return false;

    // Если была попытка синхронизации менее 5 минут назад и были частые ошибки,
    // пропускаем синхронизацию
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt).inMinutes < 5 &&
        errorCount >= _maxRetries) {
      return true;
    }

    // В остальных случаях продолжаем синхронизацию
    return false;
  }

  // Увеличение счетчика ошибок для данного типа данных
  void _incrementErrorCounter(String dataType) {
    _errorCounters[dataType] = (_errorCounters[dataType] ?? 0) + 1;
    debugPrint('⚠️ Счетчик ошибок для $dataType: ${_errorCounters[dataType]}');
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

      final pendingChanges =
          offlineNotes.length +
              offlineNoteUpdates.length +
              offlineMaps.length +
              offlineMapUpdates.length +
              notesToDelete.length +
              mapsToDelete.length;

      final isConnected = await NetworkUtils.isNetworkAvailable();

      // Получаем размер кэша локальных файлов
      final localFilesCount = await _getLocalFilesCount();
      final localFilesCacheSize = await _localFileService.getCacheSize();

      // 🔥 НОВОЕ: Добавляем информацию о локальных счетчиках
      final localCounters = await _offlineStorage.getAllLocalUsageCounters();
      final subscriptionCacheInfo = await _subscriptionService.getSubscriptionCacheInfo();

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
        'isOnline': isConnected,
        'errorCounters': _errorCounters,
        'localFilesCount': localFilesCount,
        'localFilesCacheSize': _formatFileSize(localFilesCacheSize),
        // 🔥 НОВЫЕ ПОЛЯ
        'localCounters': localCounters.map((k, v) => MapEntry(k.name, v)),
        'subscriptionCache': subscriptionCacheInfo,
      };
    } catch (e) {
      debugPrint('❌ Ошибка при получении статуса синхронизации: $e');
      return {'error': e.toString()};
    }
  }

  /// Форматирует размер файла в человекочитаемый вид
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  /// Получить количество локальных файлов
  Future<int> _getLocalFilesCount() async {
    try {
      final cachePath = await _localFileService.getCacheDirectoryPath();
      final directory = Directory(cachePath);

      if (!await directory.exists()) return 0;

      final files =
      await directory.list().where((entity) => entity is File).toList();
      return files.length;
    } catch (e) {
      debugPrint('❌ Ошибка при подсчете локальных файлов: $e');
      return 0;
    }
  }

  /// Принудительно запустить полную синхронизацию
  Future<bool> forceSyncAll() async {
    try {
      if (_isSyncing) {
        debugPrint('⚠️ Синхронизация уже запущена, пропускаем');
        return false;
      }

      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('❌ Нет подключения к интернету, синхронизация невозможна');
        return false;
      }

      // Сбрасываем счетчики ошибок
      _errorCounters.clear();

      await syncAll();
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при принудительной синхронизации: $e');
      return false;
    }
  }

  /// Принудительная синхронизация только счетчиков
  Future<bool> forceSyncCounters() async {
    try {
      if (_isSyncing) {
        debugPrint('⚠️ Синхронизация уже запущена, пропускаем');
        return false;
      }

      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('❌ Нет подключения к интернету, синхронизация невозможна');
        return false;
      }

      await syncUsageCounters();
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при принудительной синхронизации счетчиков: $e');
      return false;
    }
  }

  /// Получение статистики офлайн использования
  Future<Map<String, dynamic>> getOfflineUsageStatistics() async {
    try {
      return await _subscriptionService.getOfflineUsageStatistics();
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики офлайн использования: $e');
      return {};
    }
  }
}