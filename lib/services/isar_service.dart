// Путь: lib/services/isar_service.dart

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/isar/fishing_note_entity.dart';
import '../models/isar/budget_note_entity.dart';
import '../models/isar/marker_map_entity.dart';

class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// Проверка инициализации
  bool get isInitialized => _isar != null;

  /// Инициализация базы данных Isar
  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        FishingNoteEntitySchema,
        BudgetNoteEntitySchema,
        MarkerMapEntitySchema,
      ],
      directory: dir.path,
    );
  }

  /// Получение экземпляра Isar
  Isar get isar {
    if (_isar == null) {
      throw Exception('IsarService не инициализирован. Вызовите init() сначала.');
    }
    return _isar!;
  }

  /// Получение текущего пользователя
  String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // ========================================
  // МЕТОДЫ ДЛЯ FISHING NOTES
  // ========================================

  /// Вставка новой записи рыболовной заметки
  Future<int> insertFishingNote(FishingNoteEntity note) async {
    return await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.put(note);
    });
  }

  /// Получение всех рыболовных заметок
  Future<List<FishingNoteEntity>> getAllFishingNotes() async {
    return await isar.fishingNoteEntitys.where().sortByDateDesc().findAll();
  }

  /// Получение заметки по ID
  Future<FishingNoteEntity?> getFishingNoteById(int id) async {
    return await isar.fishingNoteEntitys.get(id);
  }

  /// Получение заметки по Firebase ID
  Future<FishingNoteEntity?> getFishingNoteByFirebaseId(String firebaseId) async {
    return await isar.fishingNoteEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();
  }

  /// Обновление существующей заметки
  Future<int> updateFishingNote(FishingNoteEntity note) async {
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.put(note);
    });
  }

  /// Удаление заметки по ID
  Future<bool> deleteFishingNote(int id) async {
    return await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.delete(id);
    });
  }

  /// Удаление заметки по Firebase ID
  Future<bool> deleteFishingNoteByFirebaseId(String firebaseId) async {
    final note = await getFishingNoteByFirebaseId(firebaseId);
    if (note != null) {
      return await deleteFishingNote(note.id);
    }
    return false;
  }

  /// Получение всех несинхронизированных заметок
  Future<List<FishingNoteEntity>> getUnsyncedNotes() async {
    return await isar.fishingNoteEntitys
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Помечает заметку как синхронизированную
  Future<void> markAsSynced(int id, String firebaseId) async {
    await isar.writeTxn(() async {
      final note = await isar.fishingNoteEntitys.get(id);
      if (note != null) {
        note.isSynced = true;
        note.firebaseId = firebaseId;
        note.updatedAt = DateTime.now();
        await isar.fishingNoteEntitys.put(note);
      }
    });
  }

  /// Помечает заметку как несинхронизированную (для обновлений)
  Future<void> markAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.fishingNoteEntitys.get(id);
      if (note != null) {
        note.isSynced = false;
        note.updatedAt = DateTime.now();
        await isar.fishingNoteEntitys.put(note);
      }
    });
  }

  /// Получение количества всех заметок
  Future<int> getNotesCount() async {
    return await isar.fishingNoteEntitys.count();
  }

  /// Получение количества несинхронизированных заметок
  Future<int> getUnsyncedNotesCount() async {
    return await isar.fishingNoteEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  // ========================================
  // МЕТОДЫ ДЛЯ BUDGET NOTES
  // ========================================

  /// Вставка новой записи заметки бюджета
  Future<int> insertBudgetNote(BudgetNoteEntity note) async {
    return await isar.writeTxn(() async {
      return await isar.budgetNoteEntitys.put(note);
    });
  }

  /// Получение всех заметок бюджета пользователя
  Future<List<BudgetNoteEntity>> getAllBudgetNotes(String userId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .sortByDateDesc()
        .findAll();
  }

  /// Получение заметки бюджета по ID
  Future<BudgetNoteEntity?> getBudgetNoteById(int id) async {
    return await isar.budgetNoteEntitys.get(id);
  }

  /// Получение заметки бюджета по Firebase ID
  Future<BudgetNoteEntity?> getBudgetNoteByFirebaseId(String firebaseId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();
  }

  /// Обновление существующей заметки бюджета
  Future<int> updateBudgetNote(BudgetNoteEntity note) async {
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.budgetNoteEntitys.put(note);
    });
  }

  /// Удаление заметки бюджета по ID
  Future<bool> deleteBudgetNote(int id) async {
    return await isar.writeTxn(() async {
      return await isar.budgetNoteEntitys.delete(id);
    });
  }

  /// Удаление заметки бюджета по Firebase ID
  Future<bool> deleteBudgetNoteByFirebaseId(String firebaseId) async {
    final note = await getBudgetNoteByFirebaseId(firebaseId);
    if (note != null) {
      return await deleteBudgetNote(note.id);
    }
    return false;
  }

  /// Получение всех несинхронизированных заметок бюджета
  Future<List<BudgetNoteEntity>> getUnsyncedBudgetNotes(String userId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .findAll();
  }

  /// Помечает заметку бюджета как синхронизированную
  Future<void> markBudgetNoteAsSynced(int id, String firebaseId) async {
    await isar.writeTxn(() async {
      final note = await isar.budgetNoteEntitys.get(id);
      if (note != null) {
        note.markAsSynced();
        note.firebaseId = firebaseId;
        await isar.budgetNoteEntitys.put(note);
      }
    });
  }

  /// Помечает заметку бюджета как несинхронизированную (для обновлений)
  Future<void> markBudgetNoteAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.budgetNoteEntitys.get(id);
      if (note != null) {
        note.markAsModified();
        await isar.budgetNoteEntitys.put(note);
      }
    });
  }

  /// Пометить заметку бюджета для удаления
  Future<void> markBudgetNoteForDeletion(String firebaseId) async {
    await isar.writeTxn(() async {
      final note = await getBudgetNoteByFirebaseId(firebaseId);
      if (note != null) {
        note.markForDeletion();
        await isar.budgetNoteEntitys.put(note);
      }
    });
  }

  /// Получение количества заметок бюджета пользователя
  Future<int> getBudgetNotesCount(String userId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// Получение количества несинхронизированных заметок бюджета
  Future<int> getUnsyncedBudgetNotesCount(String userId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// Удалить все заметки бюджета пользователя (для выхода из аккаунта)
  Future<int> deleteAllBudgetNotes(String userId) async {
    return await isar.writeTxn(() async {
      return await isar.budgetNoteEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  // ========================================
  // МЕТОДЫ ДЛЯ MARKER MAPS
  // ========================================

  /// Вставка новой записи маркерной карты
  Future<int> insertMarkerMap(MarkerMapEntity map) async {
    return await isar.writeTxn(() async {
      return await isar.markerMapEntitys.put(map);
    });
  }

  /// Получение всех маркерных карт пользователя
  Future<List<MarkerMapEntity>> getAllMarkerMaps(String userId) async {
    return await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .sortByDateDesc()
        .findAll();
  }

  /// Получение маркерной карты по ID
  Future<MarkerMapEntity?> getMarkerMapById(int id) async {
    return await isar.markerMapEntitys.get(id);
  }

  /// Получение маркерной карты по Firebase ID
  Future<MarkerMapEntity?> getMarkerMapByFirebaseId(String firebaseId) async {
    return await isar.markerMapEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();
  }

  /// Обновление существующей маркерной карты
  Future<int> updateMarkerMap(MarkerMapEntity map) async {
    map.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.markerMapEntitys.put(map);
    });
  }

  /// Удаление маркерной карты по ID
  Future<bool> deleteMarkerMap(int id) async {
    return await isar.writeTxn(() async {
      return await isar.markerMapEntitys.delete(id);
    });
  }

  /// Удаление маркерной карты по Firebase ID
  Future<bool> deleteMarkerMapByFirebaseId(String firebaseId) async {
    final map = await getMarkerMapByFirebaseId(firebaseId);
    if (map != null) {
      return await deleteMarkerMap(map.id);
    }
    return false;
  }

  /// Получение всех несинхронизированных маркерных карт
  Future<List<MarkerMapEntity>> getUnsyncedMarkerMaps(String userId) async {
    return await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .findAll();
  }

  /// Помечает маркерную карту как синхронизированную
  Future<void> markMarkerMapAsSynced(int id, String firebaseId) async {
    await isar.writeTxn(() async {
      final map = await isar.markerMapEntitys.get(id);
      if (map != null) {
        map.markAsSynced();
        map.firebaseId = firebaseId;
        await isar.markerMapEntitys.put(map);
      }
    });
  }

  /// Помечает маркерную карту как несинхронизированную (для обновлений)
  Future<void> markMarkerMapAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final map = await isar.markerMapEntitys.get(id);
      if (map != null) {
        map.markAsModified();
        await isar.markerMapEntitys.put(map);
      }
    });
  }

  /// Пометить маркерную карту для удаления
  Future<void> markMarkerMapForDeletion(String firebaseId) async {
    await isar.writeTxn(() async {
      final map = await getMarkerMapByFirebaseId(firebaseId);
      if (map != null) {
        map.markForDeletion();
        await isar.markerMapEntitys.put(map);
      }
    });
  }

  /// Получение количества маркерных карт пользователя
  Future<int> getMarkerMapsCount(String userId) async {
    return await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// Получение количества несинхронизированных маркерных карт
  Future<int> getUnsyncedMarkerMapsCount(String userId) async {
    return await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// Удалить все маркерные карты пользователя (для выхода из аккаунта)
  Future<int> deleteAllMarkerMaps(String userId) async {
    return await isar.writeTxn(() async {
      return await isar.markerMapEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  // ========================================
  // ОБЩИЕ МЕТОДЫ
  // ========================================

  /// Очистка всех данных (для отладки)
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.fishingNoteEntitys.clear();
      await isar.budgetNoteEntitys.clear();
      await isar.markerMapEntitys.clear();
    });
  }

  /// Получение общей статистики
  Future<Map<String, dynamic>> getGeneralStats() async {
    final userId = getCurrentUserId();
    if (userId == null) return {};

    return {
      'fishingNotes': {
        'total': await getNotesCount(),
        'unsynced': await getUnsyncedNotesCount(),
      },
      'budgetNotes': {
        'total': await getBudgetNotesCount(userId),
        'unsynced': await getUnsyncedBudgetNotesCount(userId),
      },
      'markerMaps': {
        'total': await getMarkerMapsCount(userId),
        'unsynced': await getUnsyncedMarkerMapsCount(userId),
      },
    };
  }

  /// Закрытие базы данных
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;
  }
}