// Путь: lib/repositories/bait_program_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bait_program_model.dart';
import '../models/isar/bait_program_entity.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class BaitProgramRepository {
  static final BaitProgramRepository _instance = BaitProgramRepository._internal();

  factory BaitProgramRepository() {
    return _instance;
  }

  BaitProgramRepository._internal();

  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Кэш для предотвращения повторных загрузок
  static List<BaitProgramModel>? _cachedPrograms;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 2);

  // Флаги для предотвращения параллельной синхронизации
  static bool _syncInProgress = false;
  static DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(seconds: 10);

  /// Получение всех программ пользователя
  Future<List<BaitProgramModel>> getUserBaitPrograms() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      // Проверяем кэш
      if (_cachedPrograms != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidity) {
          return _cachedPrograms!;
        } else {
          clearCache();
        }
      }

      // Получаем данные из Isar с фильтрацией удаленных записей
      final isarPrograms = await _isarService.getAllBaitPrograms();

      final activePrograms = isarPrograms.where((entity) =>
      entity.markedForDeletion == false
      ).toList();

      // Конвертируем в модели приложения
      final programs = activePrograms.map((entity) => _entityToModel(entity)).toList();

      // Кэшируем результат
      _cachedPrograms = programs;
      _cacheTimestamp = DateTime.now();

      // Запускаем умную синхронизацию с проверкой cooldown
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _performBackgroundSync('getUserPrograms');
      }

      return programs;
    } catch (e) {
      debugPrint('❌ Ошибка получения программ: $e');
      return [];
    }
  }

  /// Добавление новой программы
  Future<String> addBaitProgram(BaitProgramModel program) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Генерируем ID, если его нет
      final programId = program.id.isEmpty ? const Uuid().v4() : program.id;

      // Создаем копию программы с установленным ID и UserID
      final programToAdd = program.copyWith(
        id: programId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Конвертируем в Isar entity и сохраняем
      final entity = _modelToEntity(programToAdd);
      entity.isSynced = false;
      entity.markedForDeletion = false;

      await _isarService.insertBaitProgram(entity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncBaitProgramsToFirebase().then((_) {
          // Синхронизация завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации: $e');
        });
      }

      // Очищаем кэш
      clearCache();

      return programId;
    } catch (e) {
      debugPrint('❌ Ошибка добавления программы: $e');
      rethrow;
    }
  }

  /// Обновление программы
  Future<void> updateBaitProgram(BaitProgramModel program) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      if (program.id.isEmpty) {
        throw Exception('ID программы не может быть пустым');
      }

      // Находим существующую запись в Isar
      final existingEntity = await _isarService.getBaitProgramByFirebaseId(program.id);
      if (existingEntity == null) {
        throw Exception('Программа не найдена в локальной базе');
      }

      // Проверяем, что программа не помечена для удаления
      if (existingEntity.markedForDeletion == true) {
        throw Exception('Нельзя обновлять удаленную программу');
      }

      // Обновляем данные
      final updatedEntity = _modelToEntity(program.copyWith(updatedAt: DateTime.now()));
      updatedEntity.id = existingEntity.id; // Сохраняем локальный ID
      updatedEntity.firebaseId = program.id; // Firebase ID
      updatedEntity.isSynced = false;
      updatedEntity.markedForDeletion = false;

      await _isarService.updateBaitProgram(updatedEntity);

      // Если онлайн, запускаем синхронизацию
      final isOnline = await NetworkUtils.isNetworkAvailable();
      if (isOnline) {
        _syncService.syncBaitProgramsToFirebase().then((_) {
          // Синхронизация обновления завершена
        }).catchError((e) {
          debugPrint('❌ Ошибка фоновой синхронизации: $e');
        });
      }

      // Очищаем кэш
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка обновления программы: $e');
      rethrow;
    }
  }

  /// Удаление программы
  Future<void> deleteBaitProgram(String programId) async {
    try {
      if (programId.isEmpty) {
        throw Exception('ID программы не может быть пустым');
      }

      final entity = await _isarService.getBaitProgramByFirebaseId(programId);
      if (entity == null) {
        throw Exception('Программа не найдена в локальной базе');
      }

      final isOnline = await NetworkUtils.isNetworkAvailable();
      bool deletionSuccessful = false;

      if (isOnline) {
        // ОНЛАЙН РЕЖИМ: Сразу удаляем из Firebase и Isar
        try {
          deletionSuccessful = await _syncService.deleteBaitProgramByFirebaseId(programId);

          if (deletionSuccessful) {
            debugPrint('✅ Онлайн удаление программы $programId успешно');
          } else {
            debugPrint('⚠️ Онлайн удаление программы $programId завершилось с ошибками');
          }
        } catch (e) {
          debugPrint('❌ Ошибка онлайн удаления программы $programId: $e');
          throw Exception('Не удалось удалить программу: $e');
        }
      } else {
        // ОФЛАЙН РЕЖИМ: Помечаем для удаления
        try {
          entity.markedForDeletion = true;
          entity.updatedAt = DateTime.now();
          entity.isSynced = false;

          await _isarService.updateBaitProgram(entity);
          deletionSuccessful = true;

          debugPrint('✅ Офлайн удаление: программа $programId помечена для удаления');
        } catch (e) {
          debugPrint('❌ Ошибка офлайн удаления программы $programId: $e');
          throw Exception('Не удалось пометить программу для удаления: $e');
        }
      }

      if (deletionSuccessful) {
        // Очищаем кэш
        clearCache();
      }

    } catch (e) {
      debugPrint('❌ Критическая ошибка удаления программы $programId: $e');
      rethrow;
    }
  }

  /// Поиск программ по названию и описанию
  Future<List<BaitProgramModel>> searchBaitPrograms(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getUserBaitPrograms();
      }

      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final isarPrograms = await _isarService.searchBaitPrograms(query);

      final activePrograms = isarPrograms.where((entity) =>
      entity.markedForDeletion == false
      ).toList();

      return activePrograms.map((entity) => _entityToModel(entity)).toList();
    } catch (e) {
      debugPrint('❌ Ошибка поиска программ: $e');
      return [];
    }
  }

  /// Получение программы по ID
  Future<BaitProgramModel?> getBaitProgramById(String programId) async {
    try {
      if (programId.isEmpty) {
        return null;
      }

      // Сначала ищем по Firebase ID
      BaitProgramEntity? entity = await _isarService.getBaitProgramByFirebaseId(programId);

      // Если не найдена, пробуем найти по локальному ID
      if (entity == null) {
        final localId = int.tryParse(programId);
        if (localId != null) {
          entity = await _isarService.getBaitProgramById(localId);
        }
      }

      if (entity == null || entity.markedForDeletion == true) {
        return null;
      }

      return _entityToModel(entity);
    } catch (e) {
      debugPrint('❌ Ошибка получения программы по ID: $e');
      return null;
    }
  }

  /// Получение программ по списку ID
  Future<List<BaitProgramModel>> getBaitProgramsByIds(List<String> programIds) async {
    try {
      if (programIds.isEmpty) {
        return [];
      }

      final List<BaitProgramModel> programs = [];

      for (final id in programIds) {
        final program = await getBaitProgramById(id);
        if (program != null) {
          programs.add(program);
        }
      }

      return programs;
    } catch (e) {
      debugPrint('❌ Ошибка получения программ по списку ID: $e');
      return [];
    }
  }

  /// Переключение избранного
  Future<void> toggleFavorite(String programId) async {
    try {
      final program = await getBaitProgramById(programId);
      if (program == null) {
        throw Exception('Программа не найдена');
      }

      final updatedProgram = program.copyWith(isFavorite: !program.isFavorite);
      await updateBaitProgram(updatedProgram);
    } catch (e) {
      debugPrint('❌ Ошибка переключения избранного: $e');
      rethrow;
    }
  }

  /// Копирование программы
  Future<String> copyBaitProgram(String programId) async {
    try {
      final program = await getBaitProgramById(programId);
      if (program == null) {
        throw Exception('Программа не найдена');
      }

      final copiedProgram = program.copyWith(
        id: '', // Новый ID будет сгенерирован
        title: 'Копия: ${program.title}',
        isFavorite: false, // Копия не избранная
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await addBaitProgram(copiedProgram);
    } catch (e) {
      debugPrint('❌ Ошибка копирования программы: $e');
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
      debugPrint('❌ Ошибка принудительной синхронизации: $e');
      return false;
    }
  }

  /// Умная фоновая синхронизация с защитой от дублирования
  void _performBackgroundSync(String source) {
    // Проверяем не идет ли уже синхронизация
    if (_syncInProgress) {
      debugPrint('⏸️ BaitRepository: Синхронизация уже выполняется, пропускаем ($source)');
      return;
    }

    // Проверяем cooldown
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < _syncCooldown) {
        debugPrint('⏸️ BaitRepository: Cooldown активен, пропускаем синхронизацию ($source)');
        return;
      }
    }

    debugPrint('🔄 BaitRepository: Запускаем фоновую синхронизацию ($source)');

    _syncInProgress = true;
    _lastSyncTime = DateTime.now();

    _syncService.fullSync().then((result) {
      _syncInProgress = false;
      if (result) {
        clearCache();
        debugPrint('✅ BaitRepository: Фоновая синхронизация завершена ($source)');
      } else {
        debugPrint('⚠️ BaitRepository: Фоновая синхронизация завершилась с ошибками ($source)');
      }
    }).catchError((e) {
      _syncInProgress = false;
      debugPrint('❌ BaitRepository: Ошибка фоновой синхронизации ($source): $e');
    });
  }

  /// Конвертация BaitProgramModel в BaitProgramEntity
  BaitProgramEntity _modelToEntity(BaitProgramModel model) {
    final entity = BaitProgramEntity()
      ..firebaseId = model.id.isNotEmpty ? model.id : null
      ..userId = model.userId
      ..title = model.title
      ..description = model.description
      ..isFavorite = model.isFavorite
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt
      ..markedForDeletion = false;

    return entity;
  }

  /// Конвертация BaitProgramEntity в BaitProgramModel
  BaitProgramModel _entityToModel(BaitProgramEntity entity) {
    return BaitProgramModel(
      id: entity.firebaseId ?? entity.id.toString(),
      userId: entity.userId,
      title: entity.title,
      description: entity.description ?? '',
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Очистка кэша
  static void clearCache() {
    _cachedPrograms = null;
    _cacheTimestamp = null;
  }

  /// Очистка всех локальных данных (для отладки)
  Future<void> clearAllLocalData() async {
    try {
      await _isarService.clearAllBaitPrograms();
      clearCache();
    } catch (e) {
      debugPrint('❌ Ошибка очистки данных: $e');
      rethrow;
    }
  }
}