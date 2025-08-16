// File: lib/repositories/fishing_diary_repository.dart (Modify file - заменить весь файл)

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_diary_model.dart';
import '../models/isar/fishing_diary_entity.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class FishingDiaryRepository {
  static final FishingDiaryRepository _instance = FishingDiaryRepository._internal();

  factory FishingDiaryRepository() {
    return _instance;
  }

  FishingDiaryRepository._internal();

  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Кэш для предотвращения повторных загрузок
  static List<FishingDiaryModel>? _cachedEntries;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // Флаги для предотвращения параллельной синхронизации
  static bool _syncInProgress = false;
  static DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(seconds: 10);

  /// Получение всех записей дневника пользователя
  Future<List<FishingDiaryModel>> getUserFishingDiaryEntries() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      // Проверяем кэш
      if (_cachedEntries != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          return _cachedEntries!;
        } else {
          clearCache();
        }
      }

      // Получаем данные из Isar с фильтрацией удаленных записей
      final isarEntries = await _isarService.getAllFishingDiaryEntries();

      final activeEntries = isarEntries.where((entity) =>
      entity.markedForDeletion == false
      ).toList();

      // Конвертируем в модели приложения
      final entries = activeEntries.map((entity) => _entityToModel(entity)).toList();

      // Кэшируем результат
      _cachedEntries = entries;
      _cacheTimestamp = DateTime.now();

      // Запускаем умную синхронизацию с проверкой cooldown
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _performBackgroundSync('getUserEntries');
      }

      return entries;
    } catch (e) {
      debugPrint('❌ Ошибка получения записей дневника: $e');
      return [];
    }
  }

  /// Добавление новой записи дневника
  Future<String> addFishingDiaryEntry(FishingDiaryModel entry) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final entryId = entry.id.isEmpty ? const Uuid().v4() : entry.id;

      // Создаем копию записи с установленным ID и UserID
      final entryToAdd = entry.copyWith(
        id: entryId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Конвертируем в Isar entity и сохраняем
      final entity = _modelToEntity(entryToAdd);
      entity.isSynced = false;
      entity.markedForDeletion = false;

      await _isarService.insertFishingDiaryEntry(entity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingDiaryToFirebase().then((_) {
          // Синхронизация завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации: $e');
        });
      }

      // Очищаем кэш
      clearCache();

      return entryId;
    } catch (e) {
      debugPrint('❌ Ошибка добавления записи дневника: $e');
      rethrow;
    }
  }

  /// Обновление записи дневника
  Future<void> updateFishingDiaryEntry(FishingDiaryModel entry) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (entry.id.isEmpty) {
        throw Exception('ID записи не может быть пустым');
      }

      // Находим существующую запись в Isar
      final existingEntity = await _isarService.getFishingDiaryEntryByFirebaseId(entry.id);
      if (existingEntity == null) {
        throw Exception('Запись не найдена в локальной базе');
      }

      // Проверяем, что запись не помечена для удаления
      if (existingEntity.markedForDeletion == true) {
        throw Exception('Нельзя обновлять удаленную запись');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(entry.copyWith(updatedAt: DateTime.now()));
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = entry.id; // Firebase ID
      updatedEntity.isSynced = false;
      updatedEntity.markedForDeletion = false;

      await _isarService.updateFishingDiaryEntry(updatedEntity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingDiaryToFirebase().then((_) {
          // Синхронизация обновления завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации: $e');
        });
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка обновления записи дневника: $e');
      rethrow;
    }
  }

  /// Удаление записи дневника
  Future<void> deleteFishingDiaryEntry(String entryId) async {
    try {
      if (entryId.isEmpty) {
        throw Exception('ID записи не может быть пустым');
      }

      final entity = await _isarService.getFishingDiaryEntryByFirebaseId(entryId);
      if (entity == null) {
        throw Exception('Запись не найдена в локальной базе');
      }

      final isOnline = await NetworkUtils.isNetworkAvailable();
      bool deletionSuccessful = false;

      if (isOnline) {
        // ОНЛАЙН РЕЖИМ: Сразу удаляем из Firebase и Isar
        try {
          deletionSuccessful = await _syncService.deleteFishingDiaryEntryByFirebaseId(entryId);

          if (deletionSuccessful) {
            debugPrint('✅ Онлайн удаление записи $entryId успешно');
          } else {
            debugPrint('⚠️ Онлайн удаление записи $entryId завершилось с ошибками');
          }
        } catch (e) {
          debugPrint('❌ Ошибка онлайн удаления записи $entryId: $e');
          throw Exception('Не удалось удалить запись: $e');
        }
      } else {
        // ОФЛАЙН РЕЖИМ: Помечаем для удаления
        try {
          entity.markedForDeletion = true;
          entity.updatedAt = DateTime.now();
          entity.isSynced = false;

          await _isarService.updateFishingDiaryEntry(entity);
          deletionSuccessful = true;

          debugPrint('✅ Офлайн удаление: запись $entryId помечена для удаления');
        } catch (e) {
          debugPrint('❌ Ошибка офлайн удаления записи $entryId: $e');
          throw Exception('Не удалось пометить запись для удаления: $e');
        }
      }

      if (deletionSuccessful) {
        // Очищаем кэш
        clearCache();
      }

    } catch (e) {
      debugPrint('❌ Критическая ошибка удаления записи $entryId: $e');
      rethrow;
    }
  }

  /// Поиск записей по названию и описанию
  Future<List<FishingDiaryModel>> searchFishingDiaryEntries(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getUserFishingDiaryEntries();
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final isarEntries = await _isarService.searchFishingDiaryEntries(query);

      final activeEntries = isarEntries.where((entity) =>
      entity.markedForDeletion == false
      ).toList();

      return activeEntries.map((entity) => _entityToModel(entity)).toList();
    } catch (e) {
      debugPrint('❌ Ошибка поиска записей дневника: $e');
      return [];
    }
  }

  /// Получение записи по ID
  Future<FishingDiaryModel?> getFishingDiaryEntryById(String entryId) async {
    try {
      if (entryId.isEmpty) {
        return null;
      }

      // Сначала ищем по Firebase ID
      FishingDiaryEntity? entity = await _isarService.getFishingDiaryEntryByFirebaseId(entryId);

      // Если не найдена, пробуем найти по локальному ID
      if (entity == null) {
        final localId = int.tryParse(entryId);
        if (localId != null) {
          entity = await _isarService.getFishingDiaryEntryById(localId);
        }
      }

      if (entity == null || entity.markedForDeletion == true) {
        return null;
      }

      return _entityToModel(entity);
    } catch (e) {
      debugPrint('❌ Ошибка получения записи по ID: $e');
      return null;
    }
  }

  /// Получение записей по списку ID
  Future<List<FishingDiaryModel>> getFishingDiaryEntriesByIds(List<String> entryIds) async {
    try {
      if (entryIds.isEmpty) {
        return [];
      }

      final List<FishingDiaryModel> entries = [];

      for (final id in entryIds) {
        final entry = await getFishingDiaryEntryById(id);
        if (entry != null) {
          entries.add(entry);
        }
      }

      return entries;
    } catch (e) {
      debugPrint('❌ Ошибка получения записей по списку ID: $e');
      return [];
    }
  }

  /// Переключение избранного
  Future<void> toggleFavorite(String entryId) async {
    try {
      final entry = await getFishingDiaryEntryById(entryId);
      if (entry == null) {
        throw Exception('Запись не найдена');
      }

      final updatedEntry = entry.copyWith(isFavorite: !entry.isFavorite);
      await updateFishingDiaryEntry(updatedEntry);
    } catch (e) {
      debugPrint('❌ Ошибка переключения избранного: $e');
      rethrow;
    }
  }

  /// Копирование записи дневника
  Future<String> copyFishingDiaryEntry(String entryId) async {
    try {
      final entry = await getFishingDiaryEntryById(entryId);
      if (entry == null) {
        throw Exception('Запись не найдена');
      }

      final copiedEntry = entry.copyWith(
        id: '', // Новый ID будет сгенерирован
        title: 'Копия: ${entry.title}',
        isFavorite: false, // Копия не избранная
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await addFishingDiaryEntry(copiedEntry);
    } catch (e) {
      debugPrint('❌ Ошибка копирования записи: $e');
      rethrow;
    }
  }

  // ========================================
  // 🆕 НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С ПАПКАМИ
  // ========================================

  /// Получение записей дневника по папке
  Future<List<FishingDiaryModel>> getFishingDiaryEntriesByFolder(String folderId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final isarEntries = await _isarService.getFishingDiaryEntriesByFolderId(folderId);

      return isarEntries.map((entity) => _entityToModel(entity)).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения записей по папке: $e');
      return [];
    }
  }

  /// Получение записей дневника без папки
  Future<List<FishingDiaryModel>> getFishingDiaryEntriesWithoutFolder() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final isarEntries = await _isarService.getFishingDiaryEntriesWithoutFolder();

      return isarEntries.map((entity) => _entityToModel(entity)).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения записей без папки: $e');
      return [];
    }
  }

  /// Перемещение записи в папку
  Future<void> moveFishingDiaryEntryToFolder(String entryId, String? folderId) async {
    try {
      if (entryId.isEmpty) {
        throw Exception('ID записи не может быть пустым');
      }

      // Получаем Entity напрямую из Isar
      final entity = await _isarService.getFishingDiaryEntryByFirebaseId(entryId);
      if (entity == null) {
        throw Exception('Запись не найдена в локальной базе');
      }

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Прямое обновление Entity
      entity.folderId = folderId;
      entity.updatedAt = DateTime.now();
      entity.isSynced = false; // Помечаем для синхронизации

      // Сохраняем изменения напрямую в Isar
      await _isarService.updateFishingDiaryEntry(entity);

      // 🔥 КРИТИЧЕСКОЕ: Очищаем кэш НЕМЕДЛЕННО
      clearCache();

      debugPrint('📁 Запись $entryId перемещена в папку $folderId');

      // Запускаем синхронизацию в фоне
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingDiaryToFirebase().catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации перемещения: $e');
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка перемещения записи в папку: $e');
      rethrow;
    }
  }

  /// Получение количества записей в папке
  Future<int> getFishingDiaryEntriesCountInFolder(String folderId) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return 0;
      }

      final entries = await getFishingDiaryEntriesByFolder(folderId);
      return entries.length;
    } catch (e) {
      debugPrint('❌ Ошибка получения количества записей в папке: $e');
      return 0;
    }
  }

  /// Получение количества записей без папки
  Future<int> getFishingDiaryEntriesCountWithoutFolder() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return 0;
      }

      final entries = await getFishingDiaryEntriesWithoutFolder();
      return entries.length;
    } catch (e) {
      debugPrint('❌ Ошибка получения количества записей без папки: $e');
      return 0;
    }
  }

  /// Копирование записи дневника в папку
  Future<String> copyFishingDiaryEntryToFolder(String entryId, String? targetFolderId) async {
    try {
      final entry = await getFishingDiaryEntryById(entryId);
      if (entry == null) {
        throw Exception('Запись не найдена');
      }

      final copiedEntry = entry.copyWith(
        id: '', // Новый ID будет сгенерирован
        title: 'Копия: ${entry.title}',
        folderId: targetFolderId, // 🆕 НОВОЕ: Устанавливаем целевую папку
        isFavorite: false, // Копия не избранная
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await addFishingDiaryEntry(copiedEntry);
    } catch (e) {
      debugPrint('❌ Ошибка копирования записи в папку: $e');
      rethrow;
    }
  }

  /// Перемещение всех записей из папки в другую папку (или в корень)
  Future<void> moveAllEntriesFromFolder(String sourceFolderId, String? targetFolderId) async {
    try {
      final entries = await getFishingDiaryEntriesByFolder(sourceFolderId);

      for (final entry in entries) {
        await moveFishingDiaryEntryToFolder(entry.id, targetFolderId);
      }

      debugPrint('📁 Перемещено ${entries.length} записей из папки $sourceFolderId в папку $targetFolderId');
    } catch (e) {
      debugPrint('❌ Ошибка перемещения всех записей из папки: $e');
      rethrow;
    }
  }

  /// Фильтрация записей по папке из кэша
  List<FishingDiaryModel> filterEntriesByFolder(List<FishingDiaryModel> entries, String? folderId) {
    if (folderId == null) {
      // Возвращаем записи без папки
      return entries.where((entry) => entry.folderId == null).toList();
    } else {
      // Возвращаем записи конкретной папки
      return entries.where((entry) => entry.folderId == folderId).toList();
    }
  }

  /// Группировка записей по папкам
  Map<String?, List<FishingDiaryModel>> groupEntriesByFolders(List<FishingDiaryModel> entries) {
    final Map<String?, List<FishingDiaryModel>> groupedEntries = {};

    for (final entry in entries) {
      final folderId = entry.folderId;
      if (!groupedEntries.containsKey(folderId)) {
        groupedEntries[folderId] = [];
      }
      groupedEntries[folderId]!.add(entry);
    }

    return groupedEntries;
  }

  /// Принудительная синхронизация
  Future<bool> forceSyncData() async {
    try {
      final result = await _syncService.fullSync();

      if (result) {
        clearCache();
      }

      return result;
    } catch (e) {
      debugPrint('❌ Ошибка принудительной синхронизации: $e');
      return false;
    }
  }

  /// Умная фоновая синхронизация с защитой от дублирования
  void _performBackgroundSync(String source) {
    // Проверяем не идет ли уже синхронизация
    if (_syncInProgress) {
      debugPrint('⏸️ FishingDiaryRepository: Синхронизация уже выполняется, пропускаем ($source)');
      return;
    }

    // Проверяем cooldown
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < _syncCooldown) {
        debugPrint('⏸️ FishingDiaryRepository: Cooldown активен, пропускаем синхронизацию ($source)');
        return;
      }
    }

    debugPrint('🔄 FishingDiaryRepository: Запускаем фоновую синхронизацию ($source)');

    _syncInProgress = true;
    _lastSyncTime = DateTime.now();

    _syncService.fullSync().then((result) {
      _syncInProgress = false;
      if (result) {
        clearCache();
        debugPrint('✅ FishingDiaryRepository: Фоновая синхронизация завершена ($source)');
      } else {
        debugPrint('⚠️ FishingDiaryRepository: Фоновая синхронизация завершилась с ошибками ($source)');
      }
    }).catchError((e) {
      _syncInProgress = false;
      debugPrint('❌ FishingDiaryRepository: Ошибка фоновой синхронизации ($source): $e');
    });
  }

  /// Конвертация FishingDiaryModel в FishingDiaryEntity
  FishingDiaryEntity _modelToEntity(FishingDiaryModel model) {
    final entity = FishingDiaryEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..title = model.title
      ..description = model.description
      ..isFavorite = model.isFavorite
      ..folderId = model.folderId // 🆕 НОВОЕ: Добавляем folderId
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt
      ..markedForDeletion = false;

    return entity;
  }

  /// Конвертация FishingDiaryEntity в FishingDiaryModel
  FishingDiaryModel _entityToModel(FishingDiaryEntity entity) {
    return FishingDiaryModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: entity.userId,
      title: entity.title,
      description: entity.description ?? '',
      isFavorite: entity.isFavorite,
      folderId: entity.folderId, // 🆕 НОВОЕ: Читаем folderId из Entity
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Очистка кэша
  static void clearCache() {
    _cachedEntries = null;
    _cacheTimestamp = null;
  }

  /// Очистка всех локальных данных (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      await _isarService.clearAllFishingDiaryEntries();
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка очистки данных: $e');
      rethrow;
    }
  }
}