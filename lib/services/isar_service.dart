// Путь: lib/services/isar_service.dart

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/isar/fishing_note_entity.dart';
import '../models/isar/budget_note_entity.dart';
import '../models/isar/marker_map_entity.dart';
import '../models/isar/policy_acceptance_entity.dart';
import '../models/isar/user_usage_limits_entity.dart';
import '../models/isar/bait_program_entity.dart';
import '../models/isar/fishing_diary_entity.dart';
import '../models/isar/fishing_diary_folder_entity.dart';


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
        PolicyAcceptanceEntitySchema,
        UserUsageLimitsEntitySchema,
        BaitProgramEntitySchema,
        FishingDiaryEntitySchema,
        FishingDiaryFolderEntitySchema
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

  /// Получение базы данных (alias для isar)
  Future<Isar> get database async {
    if (_isar == null) {
      await init();
    }
    return _isar!;
  }

  /// Получение текущего пользователя
  String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // ========================================
  // 🔥 ОБНОВЛЕННЫЕ МЕТОДЫ ДЛЯ FISHING NOTES С ПОДДЕРЖКОЙ ОФЛАЙН УДАЛЕНИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Вставка новой записи рыболовной заметки с логированием
  Future<int> insertFishingNote(FishingNoteEntity note) async {
    final result = await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.put(note);
    });

    debugPrint('📝 IsarService: Вставлена FishingNote с ID=$result, firebaseId=${note.firebaseId}, markedForDeletion=${note.markedForDeletion}');
    return result;
  }

  /// ✅ ИСПРАВЛЕНО: Получение всех АКТИВНЫХ рыболовных заметок (исключая помеченные для удаления)
  Future<List<FishingNoteEntity>> getAllFishingNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint('⚠️ IsarService: getCurrentUserId() вернул null');
      return [];
    }

    // 🔥 ИСПРАВЛЕНО: Простой фильтр - исключаем только явно помеченные для удаления
    final notes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .sortByDateDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${notes.length} активных FishingNotes для пользователя $userId');
    debugPrint('📊 IsarService: Детали заметок:');
    for (final note in notes) {
      debugPrint('  - ID=${note.id}, firebaseId=${note.firebaseId}, markedForDeletion=${note.markedForDeletion}');
    }
    return notes;
  }

  /// ✅ НОВОЕ: Получение всех заметок включая помеченные для удаления (для синхронизации)
  Future<List<FishingNoteEntity>> getAllFishingNotesIncludingDeleted() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final notes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByDateDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${notes.length} ВСЕХ FishingNotes (включая удаленные) для пользователя $userId');
    return notes;
  }

  /// Получение заметки по ID
  Future<FishingNoteEntity?> getFishingNoteById(int id) async {
    final note = await isar.fishingNoteEntitys.get(id);
    debugPrint('🔍 IsarService: getFishingNoteById($id) = ${note != null ? "найдена" : "не найдена"}');
    return note;
  }

  /// Получение заметки по Firebase ID
  Future<FishingNoteEntity?> getFishingNoteByFirebaseId(String firebaseId) async {
    final note = await isar.fishingNoteEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();

    debugPrint('🔍 IsarService: getFishingNoteByFirebaseId($firebaseId) = ${note != null ? "найдена" : "не найдена"}');
    if (note != null) {
      debugPrint('📝 IsarService: Заметка markedForDeletion=${note.markedForDeletion}, isSynced=${note.isSynced}');
    }
    return note;
  }

  /// Обновление существующей заметки
  Future<int> updateFishingNote(FishingNoteEntity note) async {
    note.updatedAt = DateTime.now();
    final result = await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.put(note);
    });

    debugPrint('🔄 IsarService: Обновлена FishingNote ID=${note.id}, firebaseId=${note.firebaseId}, markedForDeletion=${note.markedForDeletion}, isSynced=${note.isSynced}');
    return result;
  }

  /// ✅ НОВОЕ: Пометить заметку для офлайн удаления
  Future<void> markFishingNoteForDeletion(String firebaseId) async {
    final note = await getFishingNoteByFirebaseId(firebaseId);
    if (note == null) {
      debugPrint('❌ IsarService: Заметка с firebaseId=$firebaseId не найдена для маркировки удаления');
      throw Exception('Заметка не найдена в локальной базе');
    }

    note.markedForDeletion = true;
    note.isSynced = false; // Требует синхронизации удаления
    note.updatedAt = DateTime.now();

    await updateFishingNote(note);
    debugPrint('✅ IsarService: Заметка $firebaseId помечена для удаления');
  }

  /// ✅ НОВОЕ: Получение заметок помеченных для удаления (для синхронизации)
  Future<List<FishingNoteEntity>> getMarkedForDeletionFishingNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final notes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${notes.length} заметок помеченных для удаления');
    return notes;
  }

  /// Удаление заметки по ID (физическое удаление)
  Future<bool> deleteFishingNote(int id) async {
    final result = await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.delete(id);
    });

    debugPrint('🗑️ IsarService: Физически удалена FishingNote ID=$id, результат=$result');
    return result;
  }

  /// Удаление заметки по Firebase ID (физическое удаление)
  Future<bool> deleteFishingNoteByFirebaseId(String firebaseId) async {
    final note = await getFishingNoteByFirebaseId(firebaseId);
    if (note != null) {
      final result = await deleteFishingNote(note.id);
      debugPrint('🗑️ IsarService: Физически удалена FishingNote firebaseId=$firebaseId, результат=$result');
      return result;
    }
    debugPrint('⚠️ IsarService: Заметка firebaseId=$firebaseId не найдена для физического удаления');
    return false;
  }

  /// ✅ ИСПРАВЛЕНО: Получение всех несинхронизированных заметок конкретного пользователя
  Future<List<FishingNoteEntity>> getUnsyncedNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final unsyncedNotes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    debugPrint('🔍 IsarService: getUnsyncedNotes найдено ${unsyncedNotes.length} несинхронизированных заметок');

    // Разделяем на обычные и помеченные для удаления
    final normalNotes = unsyncedNotes.where((note) => note.markedForDeletion != true).toList();
    final deletedNotes = unsyncedNotes.where((note) => note.markedForDeletion == true).toList();

    debugPrint('📊 IsarService: Из них ${normalNotes.length} обычных и ${deletedNotes.length} помеченных для удаления');

    // 🔥 НОВОЕ: Запускаем очистку синхронизированных удаленных записей
    cleanupSyncedDeletedNotes();

    return unsyncedNotes;
  }

  /// ✅ НОВОЕ: Очистка синхронизированных удаленных записей
  Future<void> cleanupSyncedDeletedNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return;
    }

    // Находим записи которые помечены для удаления И синхронизированы
    final syncedDeletedNotes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .and()
        .isSyncedEqualTo(true)
        .findAll();

    if (syncedDeletedNotes.isNotEmpty) {
      debugPrint('🧹 IsarService: Найдено ${syncedDeletedNotes.length} синхронизированных удаленных записей для очистки');

      // Физически удаляем каждую синхронизированную запись
      for (final note in syncedDeletedNotes) {
        await deleteFishingNote(note.id);
        debugPrint('🗑️ IsarService: Физически удалена синхронизированная запись ID=${note.id}, firebaseId=${note.firebaseId}');
      }

      debugPrint('✅ IsarService: Очистка завершена - удалено ${syncedDeletedNotes.length} записей');
    } else {
      debugPrint('📝 IsarService: Нет синхронизированных удаленных записей для очистки');
    }
  }

  /// Помечает заметку как синхронизированную
  Future<void> markAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final note = await isar.fishingNoteEntitys.get(id);
      if (note != null) {
        note.isSynced = true;
        note.firebaseId = firebaseId;
        note.updatedAt = DateTime.now();
        await isar.fishingNoteEntitys.put(note);
        debugPrint('✅ IsarService: Заметка ID=$id помечена как синхронизированная с firebaseId=$firebaseId');

        // 🔥 ИСПРАВЛЕНО: Проверяем нужно ли удалить, но НЕ удаляем внутри транзакции
        if (note.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    // 🔥 ИСПРАВЛЕНО: Физическое удаление ПОСЛЕ завершения транзакции
    if (shouldDelete) {
      await deleteFishingNote(id);
      debugPrint('🧹 IsarService: Автоматически удалена синхронизированная помеченная запись ID=$id');
    }
  }

  /// Помечает заметку как несинхронизированную (для обновлений)
  Future<void> markAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.fishingNoteEntitys.get(id);
      if (note != null) {
        note.isSynced = false;
        note.updatedAt = DateTime.now();
        await isar.fishingNoteEntitys.put(note);
        debugPrint('🔄 IsarService: Заметка ID=$id помечена как несинхронизированная');
      }
    });
  }

  /// ✅ ИСПРАВЛЕНО: Получение количества всех заметок (теперь с опциональной фильтрацией по пользователю)
  Future<int> getNotesCount([String? userId]) async {
    if (userId != null) {
      return await getFishingNotesCountByUser(userId);
    }

    // Для обратной совместимости - возвращаем все заметки
    return await isar.fishingNoteEntitys.count();
  }

  /// ✅ ИСПРАВЛЕНО: Получение количества несинхронизированных заметок конкретного пользователя
  Future<int> getUnsyncedNotesCount([String? userId]) async {
    if (userId != null) {
      return await isar.fishingNoteEntitys
          .filter()
          .userIdEqualTo(userId)
          .and()
          .isSyncedEqualTo(false)
          .count();
    }

    // Для обратной совместимости - возвращаем все несинхронизированные заметки
    return await isar.fishingNoteEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  /// 🔥 КРИТИЧНО ДОБАВЛЕНО: Получение количества рыболовных заметок конкретного пользователя (только активные)
  Future<int> getFishingNotesCountByUser(String userId) async {
    final count = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .count();

    debugPrint('📊 IsarService: Активных FishingNotes пользователя $userId: $count');
    return count;
  }

  // ========================================
  // 🔥 ОБНОВЛЕННЫЕ МЕТОДЫ ДЛЯ BUDGET NOTES С ПОДДЕРЖКОЙ ОФЛАЙН УДАЛЕНИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Вставка новой записи заметки бюджета с логированием
  Future<int> insertBudgetNote(BudgetNoteEntity note) async {
    final result = await isar.writeTxn(() async {
      return await isar.budgetNoteEntitys.put(note);
    });

    debugPrint('📝 IsarService: Вставлена BudgetNote с ID=$result, firebaseId=${note.firebaseId}, markedForDeletion=${note.markedForDeletion}');
    return result;
  }

  /// ✅ ИСПРАВЛЕНО: Получение всех АКТИВНЫХ заметок бюджета (исключая помеченные для удаления)
  Future<List<BudgetNoteEntity>> getAllBudgetNotes(String userId) async {
    final notes = await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .sortByDateDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${notes.length} активных BudgetNotes для пользователя $userId');
    debugPrint('📊 IsarService: Детали заметок:');
    for (final note in notes) {
      debugPrint('  - ID=${note.id}, firebaseId=${note.firebaseId}, markedForDeletion=${note.markedForDeletion}');
    }
    return notes;
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

  /// ✅ НОВОЕ: Пометить заметку бюджета для офлайн удаления
  Future<void> markBudgetNoteForDeletion(String firebaseId) async {
    final note = await getBudgetNoteByFirebaseId(firebaseId);
    if (note == null) {
      debugPrint('❌ IsarService: BudgetNote с firebaseId=$firebaseId не найдена для маркировки удаления');
      throw Exception('Заметка бюджета не найдена в локальной базе');
    }

    note.markedForDeletion = true;
    note.isSynced = false; // Требует синхронизации удаления
    note.updatedAt = DateTime.now();

    await updateBudgetNote(note);
    debugPrint('✅ IsarService: BudgetNote $firebaseId помечена для удаления');
  }

  /// ✅ НОВОЕ: Получение заметок бюджета помеченных для удаления (для синхронизации)
  Future<List<BudgetNoteEntity>> getMarkedForDeletionBudgetNotes(String userId) async {
    final notes = await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${notes.length} BudgetNotes помеченных для удаления');
    return notes;
  }

  /// ✅ НОВОЕ: Очистка синхронизированных удаленных заметок бюджета
  Future<void> cleanupSyncedDeletedBudgetNotes(String userId) async {
    // Находим записи которые помечены для удаления И синхронизированы
    final syncedDeletedNotes = await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .and()
        .isSyncedEqualTo(true)
        .findAll();

    if (syncedDeletedNotes.isNotEmpty) {
      debugPrint('🧹 IsarService: Найдено ${syncedDeletedNotes.length} синхронизированных удаленных BudgetNotes для очистки');

      // Физически удаляем каждую синхронизированную запись
      for (final note in syncedDeletedNotes) {
        await deleteBudgetNote(note.id);
        debugPrint('🗑️ IsarService: Физически удалена синхронизированная BudgetNote ID=${note.id}, firebaseId=${note.firebaseId}');
      }

      debugPrint('✅ IsarService: Очистка BudgetNotes завершена - удалено ${syncedDeletedNotes.length} записей');
    } else {
      debugPrint('📝 IsarService: Нет синхронизированных удаленных BudgetNotes для очистки');
    }
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

  /// ✅ ИСПРАВЛЕНО: Получение всех несинхронизированных заметок бюджета (включая помеченные для удаления)
  Future<List<BudgetNoteEntity>> getUnsyncedBudgetNotes(String userId) async {
    final unsyncedNotes = await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    debugPrint('🔍 IsarService: getUnsyncedBudgetNotes найдено ${unsyncedNotes.length} несинхронизированных заметок бюджета');

    // Разделяем на обычные и помеченные для удаления
    final normalNotes = unsyncedNotes.where((note) => note.markedForDeletion != true).toList();
    final deletedNotes = unsyncedNotes.where((note) => note.markedForDeletion == true).toList();

    debugPrint('📊 IsarService: Из них ${normalNotes.length} обычных и ${deletedNotes.length} помеченных для удаления');

    // 🔥 НОВОЕ: Запускаем очистку синхронизированных удаленных записей
    cleanupSyncedDeletedBudgetNotes(userId);

    return unsyncedNotes;
  }

  /// ✅ ИСПРАВЛЕНО: Помечает заметку бюджета как синхронизированную с автоудалением
  Future<void> markBudgetNoteAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final note = await isar.budgetNoteEntitys.get(id);
      if (note != null) {
        note.markAsSynced();
        note.firebaseId = firebaseId;
        await isar.budgetNoteEntitys.put(note);
        debugPrint('✅ IsarService: BudgetNote ID=$id помечена как синхронизированная с firebaseId=$firebaseId');

        // 🔥 ИСПРАВЛЕНО: Проверяем нужно ли удалить, но НЕ удаляем внутри транзакции
        if (note.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    // 🔥 ИСПРАВЛЕНО: Физическое удаление ПОСЛЕ завершения транзакции
    if (shouldDelete) {
      await deleteBudgetNote(id);
      debugPrint('🧹 IsarService: Автоматически удалена синхронизированная помеченная BudgetNote ID=$id');
    }
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

  /// Получение количества заметок бюджета пользователя
  Future<int> getBudgetNotesCount(String userId) async {
    return await isar.budgetNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// 🆕 ИСПРАВЛЕНО: Получение количества заметок бюджета конкретного пользователя (алиас для существующего метода)
  Future<int> getBudgetNotesCountByUser(String userId) async {
    return await getBudgetNotesCount(userId);
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
  // 🔥 ОБНОВЛЕННЫЕ МЕТОДЫ ДЛЯ MARKER MAPS С ПОДДЕРЖКОЙ ОФЛАЙН УДАЛЕНИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Вставка новой записи маркерной карты с логированием
  Future<int> insertMarkerMap(MarkerMapEntity map) async {
    final result = await isar.writeTxn(() async {
      return await isar.markerMapEntitys.put(map);
    });

    debugPrint('📝 IsarService: Вставлена MarkerMap с ID=$result, firebaseId=${map.firebaseId}, markedForDeletion=${map.markedForDeletion}');
    return result;
  }

  /// ✅ ИСПРАВЛЕНО: Получение всех АКТИВНЫХ маркерных карт (исключая помеченные для удаления)
  Future<List<MarkerMapEntity>> getAllMarkerMaps(String userId) async {
    final maps = await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .sortByDateDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${maps.length} активных MarkerMaps для пользователя $userId');
    debugPrint('📊 IsarService: Детали карт:');
    for (final map in maps) {
      debugPrint('  - ID=${map.id}, firebaseId=${map.firebaseId}, markedForDeletion=${map.markedForDeletion}');
    }
    return maps;
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

  /// ✅ ИСПРАВЛЕНО: Получение всех несинхронизированных маркерных карт (включая помеченные для удаления)
  Future<List<MarkerMapEntity>> getUnsyncedMarkerMaps(String userId) async {
    final unsyncedMaps = await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    debugPrint('🔍 IsarService: getUnsyncedMarkerMaps найдено ${unsyncedMaps.length} несинхронизированных маркерных карт');

    // Разделяем на обычные и помеченные для удаления
    final normalMaps = unsyncedMaps.where((map) => map.markedForDeletion != true).toList();
    final deletedMaps = unsyncedMaps.where((map) => map.markedForDeletion == true).toList();

    debugPrint('📊 IsarService: Из них ${normalMaps.length} обычных и ${deletedMaps.length} помеченных для удаления');

    // 🔥 НОВОЕ: Запускаем очистку синхронизированных удаленных записей
    cleanupSyncedDeletedMarkerMaps(userId);

    return unsyncedMaps;
  }

  /// ✅ ИСПРАВЛЕНО: Помечает маркерную карту как синхронизированную с автоудалением
  Future<void> markMarkerMapAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final map = await isar.markerMapEntitys.get(id);
      if (map != null) {
        map.markAsSynced();
        map.firebaseId = firebaseId;
        await isar.markerMapEntitys.put(map);
        debugPrint('✅ IsarService: MarkerMap ID=$id помечена как синхронизированная с firebaseId=$firebaseId');

        // 🔥 ИСПРАВЛЕНО: Проверяем нужно ли удалить, но НЕ удаляем внутри транзакции
        if (map.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    // 🔥 ИСПРАВЛЕНО: Физическое удаление ПОСЛЕ завершения транзакции
    if (shouldDelete) {
      await deleteMarkerMap(id);
      debugPrint('🧹 IsarService: Автоматически удалена синхронизированная помеченная MarkerMap ID=$id');
    }
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

  /// ✅ НОВОЕ: Пометить маркерную карту для офлайн удаления
  Future<void> markMarkerMapForDeletion(String firebaseId) async {
    final map = await getMarkerMapByFirebaseId(firebaseId);
    if (map == null) {
      debugPrint('❌ IsarService: MarkerMap с firebaseId=$firebaseId не найдена для маркировки удаления');
      throw Exception('Маркерная карта не найдена в локальной базе');
    }

    map.markedForDeletion = true;
    map.isSynced = false; // Требует синхронизации удаления
    map.updatedAt = DateTime.now();

    await updateMarkerMap(map);
    debugPrint('✅ IsarService: MarkerMap $firebaseId помечена для удаления');
  }

  /// ✅ НОВОЕ: Получение маркерных карт помеченных для удаления (для синхронизации)
  Future<List<MarkerMapEntity>> getMarkedForDeletionMarkerMaps(String userId) async {
    final maps = await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${maps.length} MarkerMaps помеченных для удаления');
    return maps;
  }

  /// ✅ НОВОЕ: Очистка синхронизированных удаленных маркерных карт
  Future<void> cleanupSyncedDeletedMarkerMaps(String userId) async {
    // Находим записи которые помечены для удаления И синхронизированы
    final syncedDeletedMaps = await isar.markerMapEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .and()
        .isSyncedEqualTo(true)
        .findAll();

    if (syncedDeletedMaps.isNotEmpty) {
      debugPrint('🧹 IsarService: Найдено ${syncedDeletedMaps.length} синхронизированных удаленных MarkerMaps для очистки');

      // Физически удаляем каждую синхронизированную запись
      for (final map in syncedDeletedMaps) {
        await deleteMarkerMap(map.id);
        debugPrint('🗑️ IsarService: Физически удалена синхронизированная MarkerMap ID=${map.id}, firebaseId=${map.firebaseId}');
      }

      debugPrint('✅ IsarService: Очистка MarkerMaps завершена - удалено ${syncedDeletedMaps.length} записей');
    } else {
      debugPrint('📝 IsarService: Нет синхронизированных удаленных MarkerMaps для очистки');
    }
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

  /// 🆕 ИСПРАВЛЕНО: Получение количества маркерных карт конкретного пользователя (алиас для существующего метода)
  Future<int> getMarkerMapsCountByUser(String userId) async {
    return await getMarkerMapsCount(userId);
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
  // МЕТОДЫ ДЛЯ POLICY ACCEPTANCE
  // ========================================

  /// ✅ СУЩЕСТВУЮЩЕЕ: Вставка новой записи согласий политики
  Future<int> insertPolicyAcceptance(PolicyAcceptanceEntity policy) async {
    final result = await isar.writeTxn(() async {
      return await isar.policyAcceptanceEntitys.put(policy);
    });

    return result;
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение всех согласий политики
  Future<List<PolicyAcceptanceEntity>> getAllPolicyAcceptances() async {
    final policies = await isar.policyAcceptanceEntitys.where().findAll();

    return policies;
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение согласий политики по ID
  Future<PolicyAcceptanceEntity?> getPolicyAcceptanceById(int id) async {
    return await isar.policyAcceptanceEntitys.get(id);
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение согласий политики по пользователю
  Future<PolicyAcceptanceEntity?> getPolicyAcceptanceByUserId(String userId) async {
    return await isar.policyAcceptanceEntitys
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Обновление существующих согласий политики
  Future<int> updatePolicyAcceptance(PolicyAcceptanceEntity policy) async {
    policy.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.policyAcceptanceEntitys.put(policy);
    });
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Удаление согласий политики по ID
  Future<bool> deletePolicyAcceptance(int id) async {
    return await isar.writeTxn(() async {
      return await isar.policyAcceptanceEntitys.delete(id);
    });
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Удаление согласий политики по пользователю
  Future<bool> deletePolicyAcceptanceByUserId(String userId) async {
    final policy = await getPolicyAcceptanceByUserId(userId);
    if (policy != null) {
      return await deletePolicyAcceptance(policy.id);
    }
    return false;
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение всех несинхронизированных согласий политики
  Future<List<PolicyAcceptanceEntity>> getUnsyncedPolicyAcceptances() async {
    final unsyncedPolicies = await isar.policyAcceptanceEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .findAll();

    return unsyncedPolicies;
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Помечает согласия политики как синхронизированные
  Future<void> markPolicyAcceptanceAsSynced(int id, String firebaseId) async {
    await isar.writeTxn(() async {
      final policy = await isar.policyAcceptanceEntitys.get(id);
      if (policy != null) {
        policy.markAsSynced();
        policy.firebaseId = firebaseId;
        await isar.policyAcceptanceEntitys.put(policy);
      }
    });
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Помечает согласия политики как несинхронизированные (для обновлений)
  Future<void> markPolicyAcceptanceAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final policy = await isar.policyAcceptanceEntitys.get(id);
      if (policy != null) {
        policy.markAsModified();
        await isar.policyAcceptanceEntitys.put(policy);
      }
    });
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Пометить согласия политики для удаления
  Future<void> markPolicyAcceptanceForDeletion(int id) async {
    await isar.writeTxn(() async {
      final policy = await isar.policyAcceptanceEntitys.get(id);
      if (policy != null) {
        policy.markForDeletion();
        await isar.policyAcceptanceEntitys.put(policy);
      }
    });
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение количества согласий политики
  Future<int> getPolicyAcceptancesCount() async {
    return await isar.policyAcceptanceEntitys
        .filter()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение количества несинхронизированных согласий политики
  Future<int> getUnsyncedPolicyAcceptancesCount() async {
    return await isar.policyAcceptanceEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Удалить все согласия политики пользователя (для выхода из аккаунта)
  Future<int> deleteAllPolicyAcceptances(String userId) async {
    return await isar.writeTxn(() async {
      return await isar.policyAcceptanceEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  // ========================================
  // 🆕 МЕТОДЫ ДЛЯ USER USAGE LIMITS
  // ========================================

  /// 🆕 НОВОЕ: Вставка новой записи лимитов пользователя
  Future<int> insertUserUsageLimits(UserUsageLimitsEntity limits) async {
    final result = await isar.writeTxn(() async {
      return await isar.userUsageLimitsEntitys.put(limits);
    });

    return result;
  }

  /// 🆕 НОВОЕ: Получение всех лимитов пользователей
  Future<List<UserUsageLimitsEntity>> getAllUserUsageLimits() async {
    final limits = await isar.userUsageLimitsEntitys.where().findAll();

    return limits;
  }

  /// 🆕 НОВОЕ: Получение лимитов по ID
  Future<UserUsageLimitsEntity?> getUserUsageLimitsById(int id) async {
    return await isar.userUsageLimitsEntitys.get(id);
  }

  /// 🆕 НОВОЕ: Получение лимитов по пользователю
  Future<UserUsageLimitsEntity?> getUserUsageLimitsByUserId(String userId) async {
    return await isar.userUsageLimitsEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(false)
        .findFirst();
  }

  /// 🆕 НОВОЕ: Получение лимитов по Firebase ID
  Future<UserUsageLimitsEntity?> getUserUsageLimitsByFirebaseId(String firebaseId) async {
    return await isar.userUsageLimitsEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();
  }

  /// 🆕 НОВОЕ: Обновление существующих лимитов пользователя
  Future<int> updateUserUsageLimits(UserUsageLimitsEntity limits) async {
    limits.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.userUsageLimitsEntitys.put(limits);
    });
  }

  /// 🆕 НОВОЕ: Удаление лимитов по ID
  Future<bool> deleteUserUsageLimits(int id) async {
    return await isar.writeTxn(() async {
      return await isar.userUsageLimitsEntitys.delete(id);
    });
  }

  /// 🆕 НОВОЕ: Удаление лимитов по пользователю
  Future<bool> deleteUserUsageLimitsByUserId(String userId) async {
    final limits = await getUserUsageLimitsByUserId(userId);
    if (limits != null) {
      return await deleteUserUsageLimits(limits.id);
    }
    return false;
  }

  /// 🆕 НОВОЕ: Получение всех несинхронизированных лимитов пользователей
  Future<List<UserUsageLimitsEntity>> getUnsyncedUserUsageLimits() async {
    final unsyncedLimits = await isar.userUsageLimitsEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .findAll();

    return unsyncedLimits;
  }

  /// 🆕 НОВОЕ: Помечает лимиты как синхронизированные
  Future<void> markUserUsageLimitsAsSynced(int id, String firebaseId) async {
    await isar.writeTxn(() async {
      final limits = await isar.userUsageLimitsEntitys.get(id);
      if (limits != null) {
        limits.markAsSynced();
        limits.firebaseId = firebaseId;
        await isar.userUsageLimitsEntitys.put(limits);
      }
    });
  }

  /// 🆕 НОВОЕ: Помечает лимиты как несинхронизированные (для обновлений)
  Future<void> markUserUsageLimitsAsUnsynced(int id) async {
    await isar.writeTxn(() async {
      final limits = await isar.userUsageLimitsEntitys.get(id);
      if (limits != null) {
        limits.markAsModified();
        await isar.userUsageLimitsEntitys.put(limits);
      }
    });
  }

  /// 🆕 НОВОЕ: Пометить лимиты для удаления
  Future<void> markUserUsageLimitsForDeletion(int id) async {
    await isar.writeTxn(() async {
      final limits = await isar.userUsageLimitsEntitys.get(id);
      if (limits != null) {
        limits.markForDeletion();
        await isar.userUsageLimitsEntitys.put(limits);
      }
    });
  }

  /// 🆕 НОВОЕ: Получение количества записей лимитов
  Future<int> getUserUsageLimitsCount() async {
    return await isar.userUsageLimitsEntitys
        .filter()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// 🆕 НОВОЕ: Получение количества несинхронизированных лимитов
  Future<int> getUnsyncedUserUsageLimitsCount() async {
    return await isar.userUsageLimitsEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .markedForDeletionEqualTo(false)
        .count();
  }

  /// 🆕 НОВОЕ: Удалить все лимиты пользователя (для выхода из аккаунта)
  Future<int> deleteAllUserUsageLimits(String userId) async {
    return await isar.writeTxn(() async {
      return await isar.userUsageLimitsEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  /// 🆕 НОВОЕ: Создание или обновление лимитов для пользователя
  Future<UserUsageLimitsEntity> createOrUpdateUserUsageLimits(String userId, {
    int? budgetNotesCount,
    int? expensesCount,
    int? markerMapsCount,
    int? notesCount,
    int? tripsCount,
    String? recalculationType,
  }) async {
    // Ищем существующие лимиты
    var limits = await getUserUsageLimitsByUserId(userId);

    if (limits == null) {
      // Создаем новые лимиты
      limits = UserUsageLimitsEntity()
        ..userId = userId
        ..budgetNotesCount = budgetNotesCount ?? 0
        ..expensesCount = expensesCount ?? 0
        ..markerMapsCount = markerMapsCount ?? 0
        ..notesCount = notesCount ?? 0
        ..tripsCount = tripsCount ?? 0
        ..recalculationType = recalculationType
        ..recalculatedAt = DateTime.now().toIso8601String()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isSynced = false;

      await insertUserUsageLimits(limits);
    } else {
      // Обновляем существующие лимиты
      if (budgetNotesCount != null) limits.budgetNotesCount = budgetNotesCount;
      if (expensesCount != null) limits.expensesCount = expensesCount;
      if (markerMapsCount != null) limits.markerMapsCount = markerMapsCount;
      if (notesCount != null) limits.notesCount = notesCount;
      if (tripsCount != null) limits.tripsCount = tripsCount;
      if (recalculationType != null) limits.recalculationType = recalculationType;

      limits.recalculatedAt = DateTime.now().toIso8601String();
      limits.markAsModified();

      await updateUserUsageLimits(limits);
    }

    return limits;
  }

  // ========================================
// 🆕 НОВЫЕ МЕТОДЫ ДЛЯ BAIT PROGRAMS
// ========================================

  /// Вставка новой прикормочной программы
  Future<int> insertBaitProgram(BaitProgramEntity program) async {
    final result = await isar.writeTxn(() async {
      return await isar.baitProgramEntitys.put(program);
    });

    debugPrint('📝 IsarService: Вставлена BaitProgram с ID=$result, firebaseId=${program.firebaseId}, markedForDeletion=${program.markedForDeletion}');
    return result;
  }

  /// Получение всех АКТИВНЫХ прикормочных программ (исключая помеченные для удаления)
  Future<List<BaitProgramEntity>> getAllBaitPrograms() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint('⚠️ IsarService: getCurrentUserId() вернул null для BaitPrograms');
      return [];
    }

    final programs = await isar.baitProgramEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${programs.length} активных BaitPrograms для пользователя $userId');
    return programs;
  }

  /// Получение программы по ID
  Future<BaitProgramEntity?> getBaitProgramById(int id) async {
    final program = await isar.baitProgramEntitys.get(id);
    debugPrint('🔍 IsarService: getBaitProgramById($id) = ${program != null ? "найдена" : "не найдена"}');
    return program;
  }

  /// Получение программы по Firebase ID
  Future<BaitProgramEntity?> getBaitProgramByFirebaseId(String firebaseId) async {
    final program = await isar.baitProgramEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();

    debugPrint('🔍 IsarService: getBaitProgramByFirebaseId($firebaseId) = ${program != null ? "найдена" : "не найдена"}');
    if (program != null) {
      debugPrint('📝 IsarService: Программа markedForDeletion=${program.markedForDeletion}, isSynced=${program.isSynced}');
    }
    return program;
  }

  /// Обновление существующей программы
  Future<int> updateBaitProgram(BaitProgramEntity program) async {
    program.updatedAt = DateTime.now();
    final result = await isar.writeTxn(() async {
      return await isar.baitProgramEntitys.put(program);
    });

    debugPrint('🔄 IsarService: Обновлена BaitProgram ID=${program.id}, firebaseId=${program.firebaseId}, markedForDeletion=${program.markedForDeletion}, isSynced=${program.isSynced}');
    return result;
  }

  /// Удаление программы по ID (физическое удаление)
  Future<bool> deleteBaitProgram(int id) async {
    final result = await isar.writeTxn(() async {
      return await isar.baitProgramEntitys.delete(id);
    });

    debugPrint('🗑️ IsarService: Физически удалена BaitProgram ID=$id, результат=$result');
    return result;
  }

  /// Удаление программы по Firebase ID (физическое удаление)
  Future<bool> deleteBaitProgramByFirebaseId(String firebaseId) async {
    final program = await getBaitProgramByFirebaseId(firebaseId);
    if (program != null) {
      final result = await deleteBaitProgram(program.id);
      debugPrint('🗑️ IsarService: Физически удалена BaitProgram firebaseId=$firebaseId, результат=$result');
      return result;
    }
    debugPrint('⚠️ IsarService: Программа firebaseId=$firebaseId не найдена для физического удаления');
    return false;
  }

  /// Поиск программ по названию и описанию
  Future<List<BaitProgramEntity>> searchBaitPrograms(String query) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final programs = await isar.baitProgramEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .and()
        .group((q) => q
        .titleContains(query, caseSensitive: false)
        .or()
        .descriptionContains(query, caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();

    debugPrint('🔍 IsarService: Поиск "$query" нашел ${programs.length} программ');
    return programs;
  }

  /// Получение всех несинхронизированных программ
  Future<List<BaitProgramEntity>> getUnsyncedBaitPrograms() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final unsyncedPrograms = await isar.baitProgramEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    debugPrint('🔍 IsarService: getUnsyncedBaitPrograms найдено ${unsyncedPrograms.length} несинхронизированных программ');
    return unsyncedPrograms;
  }

  /// Помечает программу как синхронизированную
  Future<void> markBaitProgramAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final program = await isar.baitProgramEntitys.get(id);
      if (program != null) {
        program.isSynced = true;
        program.firebaseId = firebaseId;
        program.updatedAt = DateTime.now();
        await isar.baitProgramEntitys.put(program);
        debugPrint('✅ IsarService: Программа ID=$id помечена как синхронизированная с firebaseId=$firebaseId');

        if (program.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    if (shouldDelete) {
      await deleteBaitProgram(id);
      debugPrint('🧹 IsarService: Автоматически удалена синхронизированная помеченная программа ID=$id');
    }
  }

  /// Получение количества прикормочных программ пользователя
  Future<int> getBaitProgramsCountByUser(String userId) async {
    final count = await isar.baitProgramEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .count();

    debugPrint('📊 IsarService: Активных BaitPrograms пользователя $userId: $count');
    return count;
  }

  /// Получение количества несинхронизированных программ
  Future<int> getUnsyncedBaitProgramsCount([String? userId]) async {
    if (userId != null) {
      return await isar.baitProgramEntitys
          .filter()
          .userIdEqualTo(userId)
          .and()
          .isSyncedEqualTo(false)
          .count();
    }

    return await isar.baitProgramEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  /// Очистка всех данных программ
  Future<void> clearAllBaitPrograms() async {
    await isar.writeTxn(() async {
      await isar.baitProgramEntitys.clear();
    });
    debugPrint('🧹 IsarService: Очищены все BaitPrograms');
  }

/// Получение прикормочных программ помеченных для удаления
  Future<List<BaitProgramEntity>> getMarkedForDeletionBaitPrograms() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final markedPrograms = await isar.baitProgramEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${markedPrograms.length} BaitPrograms помеченных для удаления');
    return markedPrograms;
  }

  // ========================================
  // 🆕 НОВЫЕ МЕТОДЫ ДЛЯ FISHING DIARY
  // ========================================

  /// Вставка новой записи дневника рыбалки
  Future<int> insertFishingDiaryEntry(FishingDiaryEntity entry) async {
    final result = await isar.writeTxn(() async {
      return await isar.fishingDiaryEntitys.put(entry);
    });

    debugPrint('📝 IsarService: Вставлена FishingDiaryEntry с ID=$result, firebaseId=${entry.firebaseId}, markedForDeletion=${entry.markedForDeletion}');
    return result;
  }

  /// Получение всех АКТИВНЫХ записей дневника (исключая помеченные для удаления)
  Future<List<FishingDiaryEntity>> getAllFishingDiaryEntries() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint('⚠️ IsarService: getCurrentUserId() вернул null для FishingDiaryEntries');
      return [];
    }

    final entries = await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not() // НЕ равно true
        .markedForDeletionEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${entries.length} активных FishingDiaryEntries для пользователя $userId');
    return entries;
  }

  /// Получение записи по ID
  Future<FishingDiaryEntity?> getFishingDiaryEntryById(int id) async {
    final entry = await isar.fishingDiaryEntitys.get(id);
    debugPrint('🔍 IsarService: getFishingDiaryEntryById($id) = ${entry != null ? "найдена" : "не найдена"}');
    return entry;
  }

  /// Получение записи по Firebase ID
  Future<FishingDiaryEntity?> getFishingDiaryEntryByFirebaseId(String firebaseId) async {
    final entry = await isar.fishingDiaryEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();

    debugPrint('🔍 IsarService: getFishingDiaryEntryByFirebaseId($firebaseId) = ${entry != null ? "найдена" : "не найдена"}');
    if (entry != null) {
      debugPrint('📝 IsarService: Запись markedForDeletion=${entry.markedForDeletion}, isSynced=${entry.isSynced}');
    }
    return entry;
  }

  /// Обновление существующей записи
  Future<int> updateFishingDiaryEntry(FishingDiaryEntity entry) async {
    entry.updatedAt = DateTime.now();
    final result = await isar.writeTxn(() async {
      return await isar.fishingDiaryEntitys.put(entry);
    });

    debugPrint('🔄 IsarService: Обновлена FishingDiaryEntry ID=${entry.id}, firebaseId=${entry.firebaseId}, markedForDeletion=${entry.markedForDeletion}, isSynced=${entry.isSynced}');
    return result;
  }

  /// Удаление записи по ID (физическое удаление)
  Future<bool> deleteFishingDiaryEntry(int id) async {
    final result = await isar.writeTxn(() async {
      return await isar.fishingDiaryEntitys.delete(id);
    });

    debugPrint('🗑️ IsarService: Физически удалена FishingDiaryEntry ID=$id, результат=$result');
    return result;
  }

  /// Удаление записи по Firebase ID (физическое удаление)
  Future<bool> deleteFishingDiaryEntryByFirebaseId(String firebaseId) async {
    final entry = await getFishingDiaryEntryByFirebaseId(firebaseId);
    if (entry != null) {
      final result = await deleteFishingDiaryEntry(entry.id);
      debugPrint('🗑️ IsarService: Физически удалена FishingDiaryEntry firebaseId=$firebaseId, результат=$result');
      return result;
    }
    debugPrint('⚠️ IsarService: Запись firebaseId=$firebaseId не найдена для физического удаления');
    return false;
  }

  /// Поиск записей по названию и описанию
  Future<List<FishingDiaryEntity>> searchFishingDiaryEntries(String query) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final entries = await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .and()
        .group((q) => q
        .titleContains(query, caseSensitive: false)
        .or()
        .descriptionContains(query, caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();

    debugPrint('🔍 IsarService: Поиск "$query" нашел ${entries.length} записей дневника');
    return entries;
  }

  /// Получение всех несинхронизированных записей
  Future<List<FishingDiaryEntity>> getUnsyncedFishingDiaryEntries() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final unsyncedEntries = await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    debugPrint('🔍 IsarService: getUnsyncedFishingDiaryEntries найдено ${unsyncedEntries.length} несинхронизированных записей');
    return unsyncedEntries;
  }

  /// Помечает запись как синхронизированную
  Future<void> markFishingDiaryEntryAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final entry = await isar.fishingDiaryEntitys.get(id);
      if (entry != null) {
        entry.isSynced = true;
        entry.firebaseId = firebaseId;
        entry.updatedAt = DateTime.now();
        await isar.fishingDiaryEntitys.put(entry);
        debugPrint('✅ IsarService: Запись дневника ID=$id помечена как синхронизированная с firebaseId=$firebaseId');

        if (entry.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    if (shouldDelete) {
      await deleteFishingDiaryEntry(id);
      debugPrint('🧹 IsarService: Автоматически удалена синхронизированная помеченная запись дневника ID=$id');
    }
  }

  /// Получение количества записей дневника пользователя
  Future<int> getFishingDiaryEntriesCountByUser(String userId) async {
    final count = await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .count();

    debugPrint('📊 IsarService: Активных FishingDiaryEntries пользователя $userId: $count');
    return count;
  }

  /// Получение количества несинхронизированных записей
  Future<int> getUnsyncedFishingDiaryEntriesCount([String? userId]) async {
    if (userId != null) {
      return await isar.fishingDiaryEntitys
          .filter()
          .userIdEqualTo(userId)
          .and()
          .isSyncedEqualTo(false)
          .count();
    }

    return await isar.fishingDiaryEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  /// Очистка всех данных записей дневника
  Future<void> clearAllFishingDiaryEntries() async {
    await isar.writeTxn(() async {
      await isar.fishingDiaryEntitys.clear();
    });
    debugPrint('🧹 IsarService: Очищены все FishingDiaryEntries');
  }

/// Получение записей FishingDiary помеченных для удаления
  Future<List<FishingDiaryEntity>> getMarkedForDeletionFishingDiaryEntries() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final markedEntries = await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${markedEntries.length} FishingDiary записей помеченных для удаления');
    return markedEntries;
  }

  // ========================================
  // ОБНОВЛЕННЫЕ ОБЩИЕ МЕТОДЫ
  // ========================================

  /// ✅ ОБНОВЛЕНО: Очистка всех данных включая UserUsageLimits (для отладки)
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.fishingNoteEntitys.clear();
      await isar.budgetNoteEntitys.clear();
      await isar.markerMapEntitys.clear();
      await isar.policyAcceptanceEntitys.clear();
      await isar.userUsageLimitsEntitys.clear();
      await isar.baitProgramEntitys.clear();
      await isar.fishingDiaryEntitys.clear();
      await isar.fishingDiaryFolderEntitys.clear();
    });
  }

  /// ✅ ОБНОВЛЕНО: Получение общей статистики включая UserUsageLimits с правильной фильтрацией по пользователю
  Future<Map<String, dynamic>> getGeneralStats() async {
    final userId = getCurrentUserId();
    if (userId == null) return {};

    return {
      'fishingNotes': {
        'total': await getFishingNotesCountByUser(userId),
        'unsynced': await getUnsyncedNotesCount(userId),
      },
      'budgetNotes': {
        'total': await getBudgetNotesCount(userId),
        'unsynced': await getUnsyncedBudgetNotesCount(userId),
      },
      'markerMaps': {
        'total': await getMarkerMapsCount(userId),
        'unsynced': await getUnsyncedMarkerMapsCount(userId),
      },
      'baitPrograms': {
        'total': await getBaitProgramsCountByUser(userId),
        'unsynced': await getUnsyncedBaitProgramsCount(userId),
      },
      'fishingDiary': {
        'total': await getFishingDiaryEntriesCountByUser(userId),
        'unsynced': await getUnsyncedFishingDiaryEntriesCount(userId),
      },
      'fishingDiaryFolders': {
        'total': await getFishingDiaryFoldersCountByUser(userId),
        'unsynced': await getUnsyncedFishingDiaryFoldersCount(userId),
      },
      'policyAcceptance': {
        'total': await getPolicyAcceptancesCount(),
        'unsynced': await getUnsyncedPolicyAcceptancesCount(),
      },
      'userUsageLimits': {
        'total': await getUserUsageLimitsCount(),
        'unsynced': await getUnsyncedUserUsageLimitsCount(),
      },
    };
  }

  /// ✅ ОБНОВЛЕНО: Удаление всех данных пользователя включая UserUsageLimits (для выхода из аккаунта)
  Future<void> deleteAllUserData(String userId) async {
    await isar.writeTxn(() async {
      // Удаляем данные пользователя из всех коллекций
      await isar.budgetNoteEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.markerMapEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.policyAcceptanceEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.userUsageLimitsEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.baitProgramEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.fishingDiaryEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      await isar.fishingDiaryFolderEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      // 🔥 ИСПРАВЛЕНО: FishingNotes теперь также привязаны к userId
      await isar.fishingNoteEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  // ========================================
  // МЕТОДЫ ДЛЯ ПАПОК ДНЕВНИКА РЫБАЛКИ
  // ========================================

  /// Вставка новой папки
  Future<int> insertFishingDiaryFolder(FishingDiaryFolderEntity folder) async {
    final result = await isar.writeTxn(() async {
      return await isar.fishingDiaryFolderEntitys.put(folder);
    });
    debugPrint('📝 IsarService: Вставлена папка с ID=$result, name=${folder.name}');
    return result;
  }

  /// Получение всех папок пользователя
  Future<List<FishingDiaryFolderEntity>> getAllFishingDiaryFolders() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final folders = await isar.fishingDiaryFolderEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .sortBySortOrder()
        .findAll();

    debugPrint('📋 IsarService: Найдено ${folders.length} папок для пользователя $userId');
    return folders;
  }

  /// Получение папки по Firebase ID
  Future<FishingDiaryFolderEntity?> getFishingDiaryFolderByFirebaseId(String firebaseId) async {
    return await isar.fishingDiaryFolderEntitys
        .filter()
        .firebaseIdEqualTo(firebaseId)
        .findFirst();
  }

  /// Обновление папки
  Future<int> updateFishingDiaryFolder(FishingDiaryFolderEntity folder) async {
    folder.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.fishingDiaryFolderEntitys.put(folder);
    });
  }

  /// Удаление папки
  Future<bool> deleteFishingDiaryFolder(int id) async {
    return await isar.writeTxn(() async {
      return await isar.fishingDiaryFolderEntitys.delete(id);
    });
  }

  /// Получение записей по папке
  Future<List<FishingDiaryEntity>> getFishingDiaryEntriesByFolderId(String folderId) async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    return await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .folderIdEqualTo(folderId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Получение записей без папки
  Future<List<FishingDiaryEntity>> getFishingDiaryEntriesWithoutFolder() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    return await isar.fishingDiaryEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .folderIdIsNull()
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Перемещение записи в папку
  Future<void> moveFishingDiaryEntryToFolder(String entryFirebaseId, String? folderId) async {
    final entry = await getFishingDiaryEntryByFirebaseId(entryFirebaseId);
    if (entry == null) throw Exception('Запись не найдена');

    entry.folderId = folderId;
    entry.markAsModified();
    await updateFishingDiaryEntry(entry);
  }

  /// Несинхронизированные папки
  Future<List<FishingDiaryFolderEntity>> getUnsyncedFishingDiaryFolders() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    return await isar.fishingDiaryFolderEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Пометить папку как синхронизированную
  Future<void> markFishingDiaryFolderAsSynced(int id, String firebaseId) async {
    bool shouldDelete = false;

    await isar.writeTxn(() async {
      final folder = await isar.fishingDiaryFolderEntitys.get(id);
      if (folder != null) {
        folder.isSynced = true;
        folder.firebaseId = firebaseId;
        await isar.fishingDiaryFolderEntitys.put(folder);

        if (folder.markedForDeletion == true) {
          shouldDelete = true;
        }
      }
    });

    if (shouldDelete) {
      await deleteFishingDiaryFolder(id);
    }
  }

  /// Поиск папок по названию
  Future<List<FishingDiaryFolderEntity>> searchFishingDiaryFolders(String query) async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    return await isar.fishingDiaryFolderEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .and()
        .nameContains(query, caseSensitive: false)
        .sortBySortOrder()
        .findAll();
  }

  /// Получение папки по ID (локальный ID)
  Future<FishingDiaryFolderEntity?> getFishingDiaryFolderById(int id) async {
    return await isar.fishingDiaryFolderEntitys.get(id);
  }

  /// Очистка всех папок дневника
  Future<void> clearAllFishingDiaryFolders() async {
    await isar.writeTxn(() async {
      await isar.fishingDiaryFolderEntitys.clear();
    });
    debugPrint('🧹 IsarService: Очищены все папки дневника');
  }

  /// Получение папок дневника помеченных для удаления
  Future<List<FishingDiaryFolderEntity>> getMarkedForDeletionFishingDiaryFolders() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final markedFolders = await isar.fishingDiaryFolderEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .markedForDeletionEqualTo(true)
        .findAll();

    debugPrint('🗑️ IsarService: Найдено ${markedFolders.length} папок дневника помеченных для удаления');
    return markedFolders;
  }

  /// Пометить папку дневника для офлайн удаления
  Future<void> markFishingDiaryFolderForDeletion(String firebaseId) async {
    final folder = await getFishingDiaryFolderByFirebaseId(firebaseId);
    if (folder == null) {
      debugPrint('❌ IsarService: Папка с firebaseId=$firebaseId не найдена для маркировки удаления');
      throw Exception('Папка дневника не найдена в локальной базе');
    }

    folder.markedForDeletion = true;
    folder.isSynced = false; // Требует синхронизации удаления
    folder.updatedAt = DateTime.now();

    await updateFishingDiaryFolder(folder);
    debugPrint('✅ IsarService: Папка дневника $firebaseId помечена для удаления');
  }

  /// Получение количества папок дневника пользователя
  Future<int> getFishingDiaryFoldersCountByUser(String userId) async {
    final count = await isar.fishingDiaryFolderEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .markedForDeletionEqualTo(true)
        .count();

    debugPrint('📊 IsarService: Активных папок дневника пользователя $userId: $count');
    return count;
  }

  /// Получение количества несинхронизированных папок
  Future<int> getUnsyncedFishingDiaryFoldersCount([String? userId]) async {
    if (userId != null) {
      return await isar.fishingDiaryFolderEntitys
          .filter()
          .userIdEqualTo(userId)
          .and()
          .isSyncedEqualTo(false)
          .count();
    }

    return await isar.fishingDiaryFolderEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  /// Закрытие базы данных
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;
  }
}