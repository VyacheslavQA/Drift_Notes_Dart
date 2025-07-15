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

/// ✅ УПРОЩЕННЫЙ сервис для синхронизации данных между локальным хранилищем и облаком
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalFileService _localFileService = LocalFileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isSyncing = false;
  Timer? _syncTimer;

  // Упрощенные счетчики ошибок
  final Map<String, int> _errorCounters = {};
  final int _maxRetries = 3;

  // ========================================
  // ПЕРИОДИЧЕСКАЯ СИНХРОНИЗАЦИЯ
  // ========================================

  /// Запустить периодическую синхронизацию
  void startPeriodicSync({Duration period = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(period, (timer) async {
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (isConnected) {
        await syncAll();
      }
    });

    debugPrint('🕒 Запущена периодическая синхронизация каждые ${period.inMinutes} минут');
  }

  /// Остановить периодическую синхронизацию
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('⏹️ Периодическая синхронизация остановлена');
  }

  // ========================================
  // ОСНОВНАЯ СИНХРОНИЗАЦИЯ
  // ========================================

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
        return;
      }

      // Проверяем авторизацию пользователя
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        debugPrint('❌ Пользователь не авторизован, синхронизация невозможна');
        return;
      }

      // Синхронизируем все типы данных
      await Future.wait([
        _syncFishingNotes(userId),
        _syncMarkerMaps(userId),
        _syncBudgetNotes(userId),
        _syncUsageCounters(),
        _syncSubscriptionStatus(),
      ]);

      // Обновляем время последней синхронизации
      await _offlineStorage.updateLastSyncTime();

      debugPrint('✅ Синхронизация всех данных завершена успешно');
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации данных: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ ЗАМЕТОК РЫБАЛКИ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация заметок рыбалки с правильной структурой subcollections
  Future<void> _syncFishingNotes(String userId) async {
    const dataType = 'fishing_notes';

    if (_shouldSkipSync(dataType)) {
      debugPrint('⏭️ Пропускаем синхронизацию заметок рыбалки из-за частых ошибок');
      return;
    }

    try {
      debugPrint('🔄 Начинаем синхронизацию заметок рыбалки...');

      // ✅ ИСПРАВЛЕНО: Используем правильную структуру subcollections
      final userNotesRef = _firestore
          .collection(SubscriptionConstants.usersCollection)
          .doc(userId)
          .collection(SubscriptionConstants.fishingNotesSubcollection);

      // Синхронизируем удаления
      await _syncDeletions(userNotesRef, false);

      // Синхронизируем обновления
      await _syncNoteUpdates(userNotesRef, userId);

      // Синхронизируем новые офлайн заметки
      await _syncOfflineNotes(userNotesRef, userId);

      debugPrint('✅ Синхронизация заметок рыбалки завершена');
      _errorCounters[dataType] = 0;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации заметок рыбалки: $e');
      _incrementErrorCounter(dataType);
      rethrow;
    }
  }

  /// Синхронизация обновлений заметок
  Future<void> _syncNoteUpdates(CollectionReference userNotesRef, String userId) async {
    final noteUpdates = await _offlineStorage.getAllNoteUpdates();
    if (noteUpdates.isEmpty) return;

    debugPrint('🔄 Синхронизация обновлений заметок (${noteUpdates.length} шт.)');

    for (var entry in noteUpdates.entries) {
      try {
        final noteId = entry.key;
        final noteData = entry.value as Map<String, dynamic>;

        // Устанавливаем userId
        noteData['userId'] = userId;
        noteData['id'] = noteId;

        // Обрабатываем локальные файлы
        await _processLocalFileUrls(noteData, userId);

        // Сохраняем в правильную структуру subcollections
        await userNotesRef.doc(noteId).set(noteData, SetOptions(merge: true));

        debugPrint('✅ Обновление заметки $noteId синхронизировано');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации обновления заметки: $e');
      }
    }

    await _offlineStorage.clearUpdates(false);
  }

  /// Синхронизация новых офлайн заметок
  Future<void> _syncOfflineNotes(CollectionReference userNotesRef, String userId) async {
    final offlineNotes = await _offlineStorage.getAllOfflineNotes();
    if (offlineNotes.isEmpty) return;

    debugPrint('🔄 Синхронизация новых офлайн заметок (${offlineNotes.length} шт.)');

    for (var noteData in offlineNotes) {
      try {
        final noteId = noteData['id']?.toString();
        if (noteId == null || noteId.isEmpty) continue;

        noteData['userId'] = userId;

        // Обрабатываем фотографии
        await _processPhotos(noteData, noteId, userId);

        // Сохраняем в правильную структуру subcollections
        await userNotesRef.doc(noteId).set(noteData);

        // Удаляем из локального хранилища
        await _offlineStorage.removeOfflineNote(noteId);

        debugPrint('✅ Офлайн заметка $noteId синхронизирована');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации офлайн заметки: $e');
      }
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ МАРКЕРНЫХ КАРТ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Синхронизация маркерных карт с правильной структурой subcollections
  Future<void> _syncMarkerMaps(String userId) async {
    const dataType = 'marker_maps';

    if (_shouldSkipSync(dataType)) {
      debugPrint('⏭️ Пропускаем синхронизацию маркерных карт из-за частых ошибок');
      return;
    }

    try {
      debugPrint('🔄 Начинаем синхронизацию маркерных карт...');

      // ✅ ИСПРАВЛЕНО: Используем правильную структуру subcollections
      final userMapsRef = _firestore
          .collection(SubscriptionConstants.usersCollection)
          .doc(userId)
          .collection(SubscriptionConstants.markerMapsSubcollection);

      // Синхронизируем удаления
      await _syncDeletions(userMapsRef, true);

      // Синхронизируем обновления
      await _syncMapUpdates(userMapsRef, userId);

      // Синхронизируем новые офлайн карты
      await _syncOfflineMaps(userMapsRef, userId);

      debugPrint('✅ Синхронизация маркерных карт завершена');
      _errorCounters[dataType] = 0;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации маркерных карт: $e');
      _incrementErrorCounter(dataType);
      rethrow;
    }
  }

  /// Синхронизация обновлений маркерных карт
  Future<void> _syncMapUpdates(CollectionReference userMapsRef, String userId) async {
    final mapUpdates = await _offlineStorage.getAllMarkerMapUpdates();
    if (mapUpdates.isEmpty) return;

    debugPrint('🔄 Синхронизация обновлений маркерных карт (${mapUpdates.length} шт.)');

    for (var entry in mapUpdates.entries) {
      try {
        final mapId = entry.key;
        final mapData = entry.value as Map<String, dynamic>;

        mapData['userId'] = userId;
        mapData['id'] = mapId;

        // Сохраняем в правильную структуру subcollections
        await userMapsRef.doc(mapId).set(mapData, SetOptions(merge: true));

        debugPrint('✅ Обновление маркерной карты $mapId синхронизировано');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации обновления маркерной карты: $e');
      }
    }

    await _offlineStorage.clearUpdates(true);
  }

  /// Синхронизация новых офлайн маркерных карт
  Future<void> _syncOfflineMaps(CollectionReference userMapsRef, String userId) async {
    final offlineMaps = await _offlineStorage.getAllOfflineMarkerMaps();
    if (offlineMaps.isEmpty) return;

    debugPrint('🔄 Синхронизация новых офлайн маркерных карт (${offlineMaps.length} шт.)');

    for (var mapData in offlineMaps) {
      try {
        final mapId = mapData['id']?.toString();
        if (mapId == null || mapId.isEmpty) continue;

        mapData['userId'] = userId;

        // Сохраняем в правильную структуру subcollections
        await userMapsRef.doc(mapId).set(mapData);

        // Удаляем из локального хранилища
        await _offlineStorage.removeOfflineMarkerMap(mapId);

        debugPrint('✅ Офлайн маркерная карта $mapId синхронизирована');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации офлайн маркерной карты: $e');
      }
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ ЗАМЕТОК БЮДЖЕТА
  // ========================================

  /// ✅ НОВОЕ: Синхронизация заметок бюджета с правильной структурой subcollections
  Future<void> _syncBudgetNotes(String userId) async {
    const dataType = 'budget_notes';

    if (_shouldSkipSync(dataType)) {
      debugPrint('⏭️ Пропускаем синхронизацию заметок бюджета из-за частых ошибок');
      return;
    }

    try {
      debugPrint('🔄 Начинаем синхронизацию заметок бюджета...');

      // ✅ НОВОЕ: Используем правильную структуру subcollections
      final userBudgetRef = _firestore
          .collection(SubscriptionConstants.usersCollection)
          .doc(userId)
          .collection(SubscriptionConstants.budgetNotesSubcollection);

      // Синхронизируем удаления
      await _syncDeletions(userBudgetRef, false);

      // Синхронизируем обновления заметок бюджета
      await _syncBudgetUpdates(userBudgetRef, userId);

      // Синхронизируем новые офлайн заметки бюджета
      await _syncOfflineBudgetNotes(userBudgetRef, userId);

      debugPrint('✅ Синхронизация заметок бюджета завершена');
      _errorCounters[dataType] = 0;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации заметок бюджета: $e');
      _incrementErrorCounter(dataType);
      rethrow;
    }
  }

  /// Синхронизация обновлений заметок бюджета
  Future<void> _syncBudgetUpdates(CollectionReference userBudgetRef, String userId) async {
    // Получаем обновления из офлайн хранилища
    final budgetUpdates = await _offlineStorage.getAllBudgetNoteUpdates();
    if (budgetUpdates.isEmpty) return;

    debugPrint('🔄 Синхронизация обновлений заметок бюджета (${budgetUpdates.length} шт.)');

    for (var entry in budgetUpdates.entries) {
      try {
        final budgetId = entry.key;
        final budgetData = entry.value as Map<String, dynamic>;

        budgetData['userId'] = userId;
        budgetData['id'] = budgetId;

        // Сохраняем в правильную структуру subcollections
        await userBudgetRef.doc(budgetId).set(budgetData, SetOptions(merge: true));

        debugPrint('✅ Обновление заметки бюджета $budgetId синхронизировано');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации обновления заметки бюджета: $e');
      }
    }

    await _offlineStorage.clearBudgetUpdates();
  }

  /// Синхронизация новых офлайн заметок бюджета
  Future<void> _syncOfflineBudgetNotes(CollectionReference userBudgetRef, String userId) async {
    final offlineBudgetNotes = await _offlineStorage.getAllOfflineBudgetNotes();
    if (offlineBudgetNotes.isEmpty) return;

    debugPrint('🔄 Синхронизация новых офлайн заметок бюджета (${offlineBudgetNotes.length} шт.)');

    for (var budgetData in offlineBudgetNotes) {
      try {
        final budgetId = budgetData['id']?.toString();
        if (budgetId == null || budgetId.isEmpty) continue;

        budgetData['userId'] = userId;

        // Сохраняем в правильную структуру subcollections
        await userBudgetRef.doc(budgetId).set(budgetData);

        // Удаляем из локального хранилища
        await _offlineStorage.removeOfflineBudgetNote(budgetId);

        debugPrint('✅ Офлайн заметка бюджета $budgetId синхронизирована');
      } catch (e) {
        debugPrint('❌ Ошибка при синхронизации офлайн заметки бюджета: $e');
      }
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ СЧЕТЧИКОВ И ПОДПИСКИ
  // ========================================

  /// ✅ УПРОЩЕНО: Синхронизация счетчиков использования без grace period
  Future<void> _syncUsageCounters() async {
    try {
      debugPrint('🔄 Синхронизация счетчиков использования...');

      if (!await NetworkUtils.isNetworkAvailable()) {
        debugPrint('❌ Нет сети для синхронизации счетчиков');
        return;
      }

      // Получаем локальные счетчики
      final localCounters = await _offlineStorage.getAllLocalUsageCounters();
      if (localCounters.isEmpty) {
        debugPrint('✅ Нет локальных счетчиков для синхронизации');
        return;
      }

      debugPrint('📊 Синхронизация локальных счетчиков: ${localCounters.length}');

      // Обновляем счетчики в Firebase
      for (final entry in localCounters.entries) {
        final contentType = entry.key;
        final localCount = entry.value;

        if (localCount > 0) {
          await _incrementServerCounter(contentType, localCount);
        }
      }

      // Сбрасываем локальные счетчики после синхронизации
      await _offlineStorage.resetLocalUsageCounters();

      debugPrint('✅ Синхронизация счетчиков завершена');
    } catch (e) {
      debugPrint('❌ Ошибка синхронизации счетчиков: $e');
    }
  }

  /// Увеличение счетчика на сервере
  Future<void> _incrementServerCounter(ContentType contentType, int count) async {
    try {
      final firebaseKey = SubscriptionConstants.getFirebaseCountField(contentType);
      await _firebaseService.incrementUsageCount(firebaseKey, increment: count);
      debugPrint('✅ Счетчик $firebaseKey увеличен на $count');
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счетчика на сервере: $e');
    }
  }

  /// Синхронизация статуса подписки
  Future<void> _syncSubscriptionStatus() async {
    try {
      debugPrint('🔄 Синхронизация статуса подписки...');

      if (!await NetworkUtils.isNetworkAvailable()) {
        return;
      }

      // Обновляем кэш подписки
      await _subscriptionService.refreshSubscriptionCache();

      debugPrint('✅ Статус подписки синхронизирован');
    } catch (e) {
      debugPrint('❌ Ошибка синхронизации подписки: $e');
    }
  }

  // ========================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Синхронизация удалений
  Future<void> _syncDeletions(CollectionReference collectionRef, bool isMarkerMaps) async {
    // Проверяем флаг на удаление всех элементов
    final shouldDeleteAll = await _offlineStorage.shouldDeleteAll(isMarkerMaps);
    if (shouldDeleteAll) {
      debugPrint('⚠️ Удаление всех элементов из коллекции');

      final snapshot = await collectionRef.get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _offlineStorage.clearDeleteAllFlag(isMarkerMaps);
      debugPrint('✅ Все элементы удалены (${snapshot.docs.length} шт.)');
      return;
    }

    // Синхронизируем отдельные удаления
    final idsToDelete = await _offlineStorage.getIdsToDelete(isMarkerMaps);
    if (idsToDelete.isNotEmpty) {
      debugPrint('🗑️ Синхронизация удалений (${idsToDelete.length} шт.)');

      for (var id in idsToDelete) {
        try {
          await collectionRef.doc(id).delete();
          debugPrint('✅ Элемент $id удален');
        } catch (e) {
          debugPrint('❌ Ошибка при удалении элемента $id: $e');
        }
      }

      await _offlineStorage.clearIdsToDelete(isMarkerMaps);
    }
  }

  /// ✅ ИСПРАВЛЕНО: Обработка локальных файлов
  Future<void> _processLocalFileUrls(Map<String, dynamic> data, String userId) async {
    if (data['photoUrls'] is List) {
      final photoUrls = List<String>.from(data['photoUrls']);
      final List<String> processedUrls = [];

      for (var url in photoUrls) {
        if (_localFileService.isLocalFileUri(url)) {
          try {
            final file = _localFileService.localUriToFile(url);
            if (file != null && await file.exists()) {
              final bytes = await file.readAsBytes();
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg';
              final path = 'users/$userId/photos/$fileName';

              final serverUrl = await _firebaseService.uploadImage(path, bytes);
              processedUrls.add(serverUrl);

              await _localFileService.deleteLocalFile(url);
              debugPrint('✅ Локальный файл заменен на серверный');
            }
          } catch (e) {
            debugPrint('❌ Ошибка обработки локального файла: $e');
            processedUrls.add(url);
          }
        } else if (url != 'offline_photo') {
          processedUrls.add(url);
        }
      }

      data['photoUrls'] = processedUrls;
    }
  }

  /// Обработка фотографий для заметок
  Future<void> _processPhotos(Map<String, dynamic> noteData, String noteId, String userId) async {
    final photoPaths = await _offlineStorage.getOfflinePhotoPaths(noteId);
    if (photoPaths.isEmpty) return;

    debugPrint('🖼️ Загрузка фотографий для заметки $noteId (${photoPaths.length} шт.)');

    List<String> photoUrls = [];
    if (noteData['photoUrls'] is List) {
      photoUrls = List<String>.from(noteData['photoUrls']);
    }

    for (var path in photoPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photoPaths.indexOf(path)}.jpg';
          final storagePath = 'users/$userId/photos/$fileName';

          final url = await _firebaseService.uploadImage(storagePath, bytes);
          if (!photoUrls.contains(url)) {
            photoUrls.add(url);
          }
          debugPrint('✅ Фото загружено: $url');
        }
      } catch (e) {
        debugPrint('❌ Ошибка загрузки фото: $e');
      }
    }

    noteData['photoUrls'] = photoUrls;
  }

  /// Проверка нужно ли пропустить синхронизацию
  bool _shouldSkipSync(String dataType) {
    final errorCount = _errorCounters[dataType] ?? 0;
    return errorCount >= _maxRetries;
  }

  /// Увеличение счетчика ошибок
  void _incrementErrorCounter(String dataType) {
    _errorCounters[dataType] = (_errorCounters[dataType] ?? 0) + 1;
    debugPrint('⚠️ Счетчик ошибок для $dataType: ${_errorCounters[dataType]}');
  }

  // ========================================
  // ПУБЛИЧНЫЕ МЕТОДЫ
  // ========================================

  /// Получить статус синхронизации
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

      final isConnected = await NetworkUtils.isNetworkAvailable();
      final localCounters = await _offlineStorage.getAllLocalUsageCounters();

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
        'localCounters': localCounters.map((k, v) => MapEntry(k.name, v)),
      };
    } catch (e) {
      debugPrint('❌ Ошибка при получении статуса синхронизации: $e');
      return {'error': e.toString()};
    }
  }

  /// Принудительная синхронизация
  Future<bool> forceSyncAll() async {
    try {
      if (_isSyncing) {
        debugPrint('⚠️ Синхронизация уже запущена');
        return false;
      }

      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        debugPrint('❌ Нет подключения к интернету');
        return false;
      }

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
      if (_isSyncing) return false;

      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) return false;

      await _syncUsageCounters();
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации счетчиков: $e');
      return false;
    }
  }
}