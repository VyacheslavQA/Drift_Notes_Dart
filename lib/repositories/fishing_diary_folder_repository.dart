// File: lib/repositories/fishing_diary_folder_repository.dart (New file)

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fishing_diary_folder_model.dart';
import '../models/isar/fishing_diary_folder_entity.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class FishingDiaryFolderRepository {
  static final FishingDiaryFolderRepository _instance = FishingDiaryFolderRepository._internal();

  factory FishingDiaryFolderRepository() {
    return _instance;
  }

  FishingDiaryFolderRepository._internal();

  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Кэш для папок
  static List<FishingDiaryFolderModel>? _cachedFolders;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  /// Получение всех папок дневника пользователя
  Future<List<FishingDiaryFolderModel>> getUserFishingDiaryFolders() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      // Проверяем кэш
      if (_cachedFolders != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          return _cachedFolders!;
        } else {
          clearCache();
        }
      }

      // Получаем данные из Isar
      final isarFolders = await _isarService.getAllFishingDiaryFolders();

      // Конвертируем в модели приложения
      final folders = isarFolders.map((entity) => _entityToModel(entity)).toList();

      // Кэшируем результат
      _cachedFolders = folders;
      _cacheTimestamp = DateTime.now();

      // Запускаем синхронизацию если онлайн
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _performBackgroundSync('getUserFolders');
      }

      return folders;
    } catch (e) {
      debugPrint('❌ Ошибка получения папок дневника: $e');
      return [];
    }
  }

  /// Добавление новой папки дневника
  Future<String> addFishingDiaryFolder(FishingDiaryFolderModel folder) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final folderId = folder.id.isEmpty ? const Uuid().v4() : folder.id;

      // Создаем копию папки с установленным ID и UserID
      final folderToAdd = folder.copyWith(
        id: folderId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Конвертируем в Isar entity и сохраняем
      final entity = _modelToEntity(folderToAdd);
      entity.isSynced = false;
      entity.markedForDeletion = false;

      await _isarService.insertFishingDiaryFolder(entity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingDiaryFoldersToFirebase().then((_) {
          // Синхронизация завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации папок: $e');
        });
      }

      // Очищаем кэш
      clearCache();

      return folderId;
    } catch (e) {
      debugPrint('❌ Ошибка добавления папки дневника: $e');
      rethrow;
    }
  }

  /// Обновление папки дневника
  Future<void> updateFishingDiaryFolder(FishingDiaryFolderModel folder) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (folder.id.isEmpty) {
        throw Exception('ID папки не может быть пустым');
      }

      // Находим существующую папку в Isar
      final existingEntity = await _isarService.getFishingDiaryFolderByFirebaseId(folder.id);
      if (existingEntity == null) {
        throw Exception('Папка не найдена в локальной базе');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(folder.copyWith(updatedAt: DateTime.now()));
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = folder.id; // Firebase ID
      updatedEntity.isSynced = false;
      updatedEntity.markedForDeletion = false;

      await _isarService.updateFishingDiaryFolder(updatedEntity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncFishingDiaryFoldersToFirebase().then((_) {
          // Синхронизация обновления завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации папок: $e');
        });
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка обновления папки дневника: $e');
      rethrow;
    }
  }

  /// Удаление папки дневника
  Future<void> deleteFishingDiaryFolder(String folderId, {bool moveEntriesToRoot = true}) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('ID папки не может быть пустым');
      }

      final entity = await _isarService.getFishingDiaryFolderByFirebaseId(folderId);
      if (entity == null) {
        throw Exception('Папка не найдена в локальной базе');
      }

      // Если нужно, перемещаем записи в корень
      if (moveEntriesToRoot) {
        final entriesInFolder = await _isarService.getFishingDiaryEntriesByFolderId(folderId);
        for (final entry in entriesInFolder) {
          entry.folderId = null;
          entry.markAsModified();
          await _isarService.updateFishingDiaryEntry(entry);
        }
        debugPrint('📁 Перемещено ${entriesInFolder.length} записей в корень');
      }

      final isOnline = await NetworkUtils.isNetworkAvailable();
      bool deletionSuccessful = false;

      if (isOnline) {
        // ОНЛАЙН РЕЖИМ: Сразу удаляем из Firebase и Isar
        try {
          deletionSuccessful = await _syncService.deleteFishingDiaryFolderByFirebaseId(folderId);

          if (deletionSuccessful) {
            debugPrint('✅ Онлайн удаление папки $folderId успешно');
          } else {
            debugPrint('⚠️ Онлайн удаление папки $folderId завершилось с ошибками');
          }
        } catch (e) {
          debugPrint('❌ Ошибка онлайн удаления папки $folderId: $e');
          throw Exception('Не удалось удалить папку: $e');
        }
      } else {
        // ОФЛАЙН РЕЖИМ: Помечаем для удаления
        try {
          entity.markedForDeletion = true;
          entity.updatedAt = DateTime.now();
          entity.isSynced = false;

          await _isarService.updateFishingDiaryFolder(entity);
          deletionSuccessful = true;

          debugPrint('✅ Офлайн удаление: папка $folderId помечена для удаления');
        } catch (e) {
          debugPrint('❌ Ошибка офлайн удаления папки $folderId: $e');
          throw Exception('Не удалось пометить папку для удаления: $e');
        }
      }

      if (deletionSuccessful) {
        // Очищаем кэш
        clearCache();
      }
    } catch (e) {
      debugPrint('❌ Критическая ошибка удаления папки $folderId: $e');
      rethrow;
    }
  }

  /// Получение папки по ID
  Future<FishingDiaryFolderModel?> getFishingDiaryFolderById(String folderId) async {
    try {
      if (folderId.isEmpty) {
        return null;
      }

      final entity = await _isarService.getFishingDiaryFolderByFirebaseId(folderId);
      if (entity == null || entity.markedForDeletion == true) {
        return null;
      }

      return _entityToModel(entity);
    } catch (e) {
      debugPrint('❌ Ошибка получения папки по ID: $e');
      return null;
    }
  }

  /// Копирование папки
  Future<String> copyFishingDiaryFolder(String folderId) async {
    try {
      final folder = await getFishingDiaryFolderById(folderId);
      if (folder == null) {
        throw Exception('Папка не найдена');
      }

      final copiedFolder = folder.copyWith(
        id: '', // Новый ID будет сгенерирован
        name: 'Копия: ${folder.name}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await addFishingDiaryFolder(copiedFolder);
    } catch (e) {
      debugPrint('❌ Ошибка копирования папки: $e');
      rethrow;
    }
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
      debugPrint('❌ Ошибка принудительной синхронизации папок: $e');
      return false;
    }
  }

  /// Фоновая синхронизация
  void _performBackgroundSync(String source) {
    _syncService.syncFishingDiaryFoldersToFirebase().then((result) {
      if (result) {
        clearCache();
        debugPrint('✅ FolderRepository: Фоновая синхронизация папок завершена ($source)');
      } else {
        debugPrint('⚠️ FolderRepository: Фоновая синхронизация папок завершилась с ошибками ($source)');
      }
    }).catchError((e) {
      debugPrint('❌ FolderRepository: Ошибка фоновой синхронизации папок ($source): $e');
    });
  }

  /// Конвертация FishingDiaryFolderModel в FishingDiaryFolderEntity
  FishingDiaryFolderEntity _modelToEntity(FishingDiaryFolderModel model) {
    final entity = FishingDiaryFolderEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..name = model.name
      ..description = model.description
      ..colorHex = model.colorHex
      ..sortOrder = model.sortOrder
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt
      ..markedForDeletion = false;

    return entity;
  }

  /// Конвертация FishingDiaryFolderEntity в FishingDiaryFolderModel
  FishingDiaryFolderModel _entityToModel(FishingDiaryFolderEntity entity) {
    return FishingDiaryFolderModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      colorHex: entity.colorHex,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Очистка кэша
  static void clearCache() {
    _cachedFolders = null;
    _cacheTimestamp = null;
  }

  /// Очистка всех локальных данных папок (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      await _isarService.clearAllFishingDiaryFolders();
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка очистки данных папок: $e');
      rethrow;
    }
  }
}