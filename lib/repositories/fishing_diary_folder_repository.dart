// ЗАМЕНИ ВЕСЬ ФАЙЛ lib/repositories/fishing_diary_folder_repository.dart НА:

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
      debugPrint('📁 FolderRepository: Получение папок для пользователя: $userId');

      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ FolderRepository: Пользователь не авторизован');
        return [];
      }

      // Проверяем кэш
      if (_cachedFolders != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          debugPrint('✅ FolderRepository: Возвращаем данные из кэша (${_cachedFolders!.length} папок)');
          return _cachedFolders!;
        } else {
          debugPrint('🔄 FolderRepository: Кэш устарел, очищаем');
          clearCache();
        }
      }

      // Получаем данные из Isar
      debugPrint('📁 FolderRepository: Загружаем папки из Isar');
      final isarFolders = await _isarService.getAllFishingDiaryFolders();
      debugPrint('📁 FolderRepository: Загружено из Isar: ${isarFolders.length} папок');

      // Конвертируем в модели приложения
      final folders = isarFolders
          .where((entity) => entity.markedForDeletion != true) // Исключаем удаленные
          .map((entity) => _entityToModel(entity))
          .toList();

      // Сортируем по sortOrder, затем по дате создания
      folders.sort((a, b) {
        final orderComparison = a.sortOrder.compareTo(b.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      debugPrint('✅ FolderRepository: Обработано папок: ${folders.length}');

      // Кэшируем результат
      _cachedFolders = folders;
      _cacheTimestamp = DateTime.now();

      // Запускаем синхронизацию если онлайн
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        debugPrint('🌐 FolderRepository: Запускаем фоновую синхронизацию');
        _performBackgroundSync('getUserFolders');
      } else {
        debugPrint('📱 FolderRepository: Офлайн режим, синхронизация пропущена');
      }

      return folders;
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка получения папок дневника: $e');
      return [];
    }
  }

  /// Добавление новой папки дневника
  Future<String> addFishingDiaryFolder(FishingDiaryFolderModel folder) async {
    try {
      final userId = _firebaseService.currentUserId;
      debugPrint('📁 FolderRepository: Добавление папки "${folder.name}" для пользователя: $userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final folderId = folder.id.isEmpty ? const Uuid().v4() : folder.id;
      debugPrint('📁 FolderRepository: Сгенерирован ID папки: $folderId');

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
      debugPrint('✅ FolderRepository: Папка сохранена в Isar');

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        debugPrint('🌐 FolderRepository: Запускаем синхронизацию с Firebase');
        _syncService.syncFishingDiaryFoldersToFirebase().then((_) {
          debugPrint('✅ FolderRepository: Синхронизация добавления завершена');
        }).catchError((e) {
          debugPrint('❌ FolderRepository: Ошибка фоновой синхронизации папок: $e');
        });
      } else {
        debugPrint('📱 FolderRepository: Офлайн режим, папка будет синхронизирована позже');
      }

      // Очищаем кэш
      clearCache();
      debugPrint('🔄 FolderRepository: Кэш очищен');

      return folderId;
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка добавления папки дневника: $e');
      rethrow;
    }
  }

  /// Обновление папки дневника
  Future<void> updateFishingDiaryFolder(FishingDiaryFolderModel folder) async {
    try {
      final userId = _firebaseService.currentUserId;
      debugPrint('📁 FolderRepository: Обновление папки "${folder.name}" (ID: ${folder.id})');

      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (folder.id.isEmpty) {
        throw Exception('ID папки не может быть пустым');
      }

      // Находим существующую папку в Isar
      final existingEntity = await _isarService.getFishingDiaryFolderByFirebaseId(folder.id);
      if (existingEntity == null) {
        debugPrint('❌ FolderRepository: Папка не найдена в локальной базе');
        throw Exception('Папка не найдена в локальной базе');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(folder.copyWith(updatedAt: DateTime.now()));
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = folder.id; // Firebase ID
      updatedEntity.isSynced = false;
      updatedEntity.markedForDeletion = false;

      await _isarService.updateFishingDiaryFolder(updatedEntity);
      debugPrint('✅ FolderRepository: Папка обновлена в Isar');

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        debugPrint('🌐 FolderRepository: Запускаем синхронизацию обновления с Firebase');
        _syncService.syncFishingDiaryFoldersToFirebase().then((_) {
          debugPrint('✅ FolderRepository: Синхронизация обновления завершена');
        }).catchError((e) {
          debugPrint('❌ FolderRepository: Ошибка фоновой синхронизации папок: $e');
        });
      } else {
        debugPrint('📱 FolderRepository: Офлайн режим, обновление будет синхронизировано позже');
      }

      // Очищаем кэш
      clearCache();
      debugPrint('🔄 FolderRepository: Кэш очищен');
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка обновления папки дневника: $e');
      rethrow;
    }
  }

  /// Удаление папки дневника
  Future<void> deleteFishingDiaryFolder(String folderId, {bool moveEntriesToRoot = true}) async {
    try {
      debugPrint('📁 FolderRepository: Удаление папки $folderId (moveEntriesToRoot: $moveEntriesToRoot)');

      if (folderId.isEmpty) {
        throw Exception('ID папки не может быть пустым');
      }

      final entity = await _isarService.getFishingDiaryFolderByFirebaseId(folderId);
      if (entity == null) {
        debugPrint('❌ FolderRepository: Папка не найдена в локальной базе');
        throw Exception('Папка не найдена в локальной базе');
      }

      // Если нужно, перемещаем записи в корень
      if (moveEntriesToRoot) {
        debugPrint('📁 FolderRepository: Перемещаем записи из папки в корень');
        final entriesInFolder = await _isarService.getFishingDiaryEntriesByFolderId(folderId);
        for (final entry in entriesInFolder) {
          entry.folderId = null;
          entry.markAsModified();
          await _isarService.updateFishingDiaryEntry(entry);
        }
        debugPrint('✅ FolderRepository: Перемещено ${entriesInFolder.length} записей в корень');
      }

      final isOnline = await NetworkUtils.isNetworkAvailable();
      bool deletionSuccessful = false;

      if (isOnline) {
        // ОНЛАЙН РЕЖИМ: Сразу удаляем из Firebase и Isar
        debugPrint('🌐 FolderRepository: ОНЛАЙН режим - удаляем из Firebase');
        try {
          deletionSuccessful = await _syncService.deleteFishingDiaryFolderByFirebaseId(folderId);

          if (deletionSuccessful) {
            debugPrint('✅ FolderRepository: Онлайн удаление папки $folderId успешно');
          } else {
            debugPrint('⚠️ FolderRepository: Онлайн удаление папки $folderId завершилось с ошибками');
          }
        } catch (e) {
          debugPrint('❌ FolderRepository: Ошибка онлайн удаления папки $folderId: $e');
          throw Exception('Не удалось удалить папку: $e');
        }
      } else {
        // ОФЛАЙН РЕЖИМ: Помечаем для удаления
        debugPrint('📱 FolderRepository: ОФЛАЙН режим - помечаем для удаления');
        try {
          entity.markedForDeletion = true;
          entity.updatedAt = DateTime.now();
          entity.isSynced = false;

          await _isarService.updateFishingDiaryFolder(entity);
          deletionSuccessful = true;

          debugPrint('✅ FolderRepository: Офлайн удаление: папка $folderId помечена для удаления');
        } catch (e) {
          debugPrint('❌ FolderRepository: Ошибка офлайн удаления папки $folderId: $e');
          throw Exception('Не удалось пометить папку для удаления: $e');
        }
      }

      if (deletionSuccessful) {
        // Очищаем кэш
        clearCache();
        debugPrint('🔄 FolderRepository: Кэш очищен после удаления');
      }
    } catch (e) {
      debugPrint('❌ FolderRepository: Критическая ошибка удаления папки $folderId: $e');
      rethrow;
    }
  }

  /// Получение папки по ID
  Future<FishingDiaryFolderModel?> getFishingDiaryFolderById(String folderId) async {
    try {
      debugPrint('📁 FolderRepository: Поиск папки по ID: $folderId');

      if (folderId.isEmpty) {
        return null;
      }

      final entity = await _isarService.getFishingDiaryFolderByFirebaseId(folderId);
      if (entity == null || entity.markedForDeletion == true) {
        debugPrint('❌ FolderRepository: Папка $folderId не найдена или удалена');
        return null;
      }

      final model = _entityToModel(entity);
      debugPrint('✅ FolderRepository: Папка найдена: "${model.name}"');
      return model;
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка получения папки по ID: $e');
      return null;
    }
  }

  /// Копирование папки
  Future<String> copyFishingDiaryFolder(String folderId) async {
    try {
      debugPrint('📁 FolderRepository: Копирование папки: $folderId');

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

      final newFolderId = await addFishingDiaryFolder(copiedFolder);
      debugPrint('✅ FolderRepository: Папка скопирована с новым ID: $newFolderId');

      return newFolderId;
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка копирования папки: $e');
      rethrow;
    }
  }

  /// Принудительная синхронизация
  Future<bool> forceSyncData() async {
    try {
      debugPrint('🔄 FolderRepository: Запуск принудительной синхронизации');
      final result = await _syncService.fullSync();

      if (result) {
        clearCache();
        debugPrint('✅ FolderRepository: Принудительная синхронизация завершена успешно');
      } else {
        debugPrint('⚠️ FolderRepository: Принудительная синхронизация завершена с ошибками');
      }

      return result;
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка принудительной синхронизации папок: $e');
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
    debugPrint('🔄 FolderRepository: Кэш папок очищен');
  }

  /// Очистка всех локальных данных папок (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      debugPrint('🗑️ FolderRepository: Очистка всех локальных данных папок');
      await _isarService.clearAllFishingDiaryFolders();
      clearCache();
      debugPrint('✅ FolderRepository: Все локальные данные папок очищены');
    } catch (e) {
      debugPrint('❌ FolderRepository: Ошибка очистки данных папок: $e');
      rethrow;
    }
  }
}