// Путь: lib/services/isar_service.dart

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/isar/fishing_note_entity.dart';
import '../models/isar/budget_note_entity.dart';
import '../models/isar/marker_map_entity.dart';
import '../models/isar/policy_acceptance_entity.dart';
import '../models/isar/user_usage_limits_entity.dart'; // 🆕 ДОБАВЛЕНО


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
        UserUsageLimitsEntitySchema, // 🆕 ДОБАВЛЕНО
      ],
      directory: dir.path,
    );

    if (kDebugMode) {
      debugPrint('✅ IsarService инициализирован в: ${dir.path}');
      debugPrint('✅ IsarService инициализирован с поддержкой PolicyAcceptance и UserUsageLimits'); // 🆕 ОБНОВЛЕНО
    }
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
  // 🔥 ИСПРАВЛЕННЫЕ МЕТОДЫ ДЛЯ FISHING NOTES С ПОДДЕРЖКОЙ userId
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Вставка новой записи рыболовной заметки с логированием
  Future<int> insertFishingNote(FishingNoteEntity note) async {
    // ✅ ДОБАВЛЕНО: Подробное логирование в начале
    if (kDebugMode) {
      debugPrint('💾 insertFishingNote: сохраняем заметку id=${note.id}, firebaseId=${note.firebaseId}, userId=${note.userId}, isSynced=${note.isSynced}');
      debugPrint('💾 insertFishingNote: title="${note.title}", location="${note.location}"');
    }

    final result = await isar.writeTxn(() async {
      return await isar.fishingNoteEntitys.put(note);
    });

    // ✅ ДОБАВЛЕНО: Подтверждение успешного сохранения
    if (kDebugMode) {
      debugPrint('✅ insertFishingNote: заметка успешно сохранена в Isar с ID: $result');
    }

    return result;
  }

  /// ✅ ИСПРАВЛЕНО: Получение всех рыболовных заметок конкретного пользователя
  Future<List<FishingNoteEntity>> getAllFishingNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ getAllFishingNotes: пользователь не авторизован');
      }
      return [];
    }

    final notes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .sortByDateDesc()
        .findAll();

    if (kDebugMode) {
      debugPrint('📋 getAllFishingNotes: найдено ${notes.length} заметок для пользователя $userId');
      for (var note in notes.take(3)) { // Показываем первые 3 для отладки
        debugPrint('📝 Заметка: id=${note.id}, firebaseId=${note.firebaseId}, isSynced=${note.isSynced}, title="${note.title}"');
      }
    }

    return notes;
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

  /// ✅ ИСПРАВЛЕНО: Получение всех несинхронизированных заметок конкретного пользователя
  Future<List<FishingNoteEntity>> getUnsyncedNotes() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ getUnsyncedNotes: пользователь не авторизован');
      }
      return [];
    }

    // ✅ ДОБАВЛЕНО: Логирование общего количества заметок пользователя
    final allUserNotes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    if (kDebugMode) {
      debugPrint('🔍 getUnsyncedNotes: всего заметок пользователя $userId в Isar: ${allUserNotes.length}');
    }

    final unsyncedNotes = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();

    // ✅ ДОБАВЛЕНО: Подробные логи каждой несинхронизированной заметки
    if (kDebugMode) {
      debugPrint('🔍 getUnsyncedNotes: найдено несинхронизированных для пользователя $userId: ${unsyncedNotes.length}');
      for (var note in unsyncedNotes) {
        debugPrint('📝 Несинхронизированная заметка: id=${note.id}, firebaseId=${note.firebaseId}, title="${note.title}"');
      }
    }

    return unsyncedNotes;
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

        if (kDebugMode) {
          debugPrint('✅ markAsSynced: заметка $id помечена как синхронизированная с Firebase ID: $firebaseId');
        }
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

        if (kDebugMode) {
          debugPrint('⚠️ markAsUnsynced: заметка $id помечена как несинхронизированная');
        }
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

  /// 🔥 КРИТИЧНО ДОБАВЛЕНО: Получение количества рыболовных заметок конкретного пользователя
  Future<int> getFishingNotesCountByUser(String userId) async {
    final count = await isar.fishingNoteEntitys
        .filter()
        .userIdEqualTo(userId)
        .count();

    if (kDebugMode) {
      debugPrint('📊 getFishingNotesCountByUser($userId): найдено $count заметок');
    }

    return count;
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
    if (kDebugMode) {
      debugPrint('💾 insertPolicyAcceptance: сохраняем согласия id=${policy.id}, userId=${policy.userId}, isSynced=${policy.isSynced}');
      debugPrint('💾 insertPolicyAcceptance: privacy=${policy.privacyPolicyAccepted}, terms=${policy.termsOfServiceAccepted}');
    }

    final result = await isar.writeTxn(() async {
      return await isar.policyAcceptanceEntitys.put(policy);
    });

    if (kDebugMode) {
      debugPrint('✅ insertPolicyAcceptance: согласия успешно сохранены в Isar с ID: $result');
    }

    return result;
  }

  /// ✅ СУЩЕСТВУЮЩЕЕ: Получение всех согласий политики
  Future<List<PolicyAcceptanceEntity>> getAllPolicyAcceptances() async {
    final policies = await isar.policyAcceptanceEntitys.where().findAll();

    if (kDebugMode) {
      debugPrint('📋 getAllPolicyAcceptances: найдено ${policies.length} согласий в Isar');
      for (var policy in policies) {
        debugPrint('📝 Согласия: id=${policy.id}, userId=${policy.userId}, isSynced=${policy.isSynced}');
      }
    }

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

    if (kDebugMode) {
      debugPrint('🔍 getUnsyncedPolicyAcceptances: найдено несинхронизированных: ${unsyncedPolicies.length}');
      for (var policy in unsyncedPolicies) {
        debugPrint('📝 Несинхронизированные согласия: id=${policy.id}, userId=${policy.userId}');
      }
    }

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

        if (kDebugMode) {
          debugPrint('✅ markPolicyAcceptanceAsSynced: согласия $id помечены как синхронизированные с Firebase ID: $firebaseId');
        }
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

        if (kDebugMode) {
          debugPrint('⚠️ markPolicyAcceptanceAsUnsynced: согласия $id помечены как несинхронизированные');
        }
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

        if (kDebugMode) {
          debugPrint('🗑️ markPolicyAcceptanceForDeletion: согласия $id помечены для удаления');
        }
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
    if (kDebugMode) {
      debugPrint('💾 insertUserUsageLimits: сохраняем лимиты id=${limits.id}, userId=${limits.userId}, isSynced=${limits.isSynced}');
      debugPrint('💾 insertUserUsageLimits: notes=${limits.notesCount}, budget=${limits.budgetNotesCount}, maps=${limits.markerMapsCount}');
    }

    final result = await isar.writeTxn(() async {
      return await isar.userUsageLimitsEntitys.put(limits);
    });

    if (kDebugMode) {
      debugPrint('✅ insertUserUsageLimits: лимиты успешно сохранены в Isar с ID: $result');
    }

    return result;
  }

  /// 🆕 НОВОЕ: Получение всех лимитов пользователей
  Future<List<UserUsageLimitsEntity>> getAllUserUsageLimits() async {
    final limits = await isar.userUsageLimitsEntitys.where().findAll();

    if (kDebugMode) {
      debugPrint('📋 getAllUserUsageLimits: найдено ${limits.length} записей лимитов в Isar');
      for (var limit in limits) {
        debugPrint('📝 Лимиты: id=${limit.id}, userId=${limit.userId}, isSynced=${limit.isSynced}');
      }
    }

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

    if (kDebugMode) {
      debugPrint('🔍 getUnsyncedUserUsageLimits: найдено несинхронизированных: ${unsyncedLimits.length}');
      for (var limits in unsyncedLimits) {
        debugPrint('📝 Несинхронизированные лимиты: id=${limits.id}, userId=${limits.userId}');
      }
    }

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

        if (kDebugMode) {
          debugPrint('✅ markUserUsageLimitsAsSynced: лимиты $id помечены как синхронизированные с Firebase ID: $firebaseId');
        }
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

        if (kDebugMode) {
          debugPrint('⚠️ markUserUsageLimitsAsUnsynced: лимиты $id помечены как несинхронизированные');
        }
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

        if (kDebugMode) {
          debugPrint('🗑️ markUserUsageLimitsForDeletion: лимиты $id помечены для удаления');
        }
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

      if (kDebugMode) {
        debugPrint('🆕 Созданы новые лимиты для пользователя $userId');
      }
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

      if (kDebugMode) {
        debugPrint('🔄 Обновлены лимиты для пользователя $userId');
      }
    }

    return limits;
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
      await isar.userUsageLimitsEntitys.clear(); // 🆕 ДОБАВЛЕНО
    });

    if (kDebugMode) {
      debugPrint('🗑️ Все данные Isar очищены (включая UserUsageLimits)');
    }
  }

  /// ✅ ОБНОВЛЕНО: Получение общей статистики включая UserUsageLimits с правильной фильтрацией по пользователю
  Future<Map<String, dynamic>> getGeneralStats() async {
    final userId = getCurrentUserId();
    if (userId == null) return {};

    return {
      'fishingNotes': {
        'total': await getFishingNotesCountByUser(userId), // 🔥 ИСПРАВЛЕНО: теперь с фильтрацией по пользователю
        'unsynced': await getUnsyncedNotesCount(userId),   // 🔥 ИСПРАВЛЕНО: теперь с фильтрацией по пользователю
      },
      'budgetNotes': {
        'total': await getBudgetNotesCount(userId),
        'unsynced': await getUnsyncedBudgetNotesCount(userId),
      },
      'markerMaps': {
        'total': await getMarkerMapsCount(userId),
        'unsynced': await getUnsyncedMarkerMapsCount(userId),
      },
      'policyAcceptance': {
        'total': await getPolicyAcceptancesCount(),
        'unsynced': await getUnsyncedPolicyAcceptancesCount(),
      },
      'userUsageLimits': { // 🆕 ДОБАВЛЕНО
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

      await isar.userUsageLimitsEntitys // 🆕 ДОБАВЛЕНО
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();

      // 🔥 ИСПРАВЛЕНО: FishingNotes теперь также привязаны к userId
      await isar.fishingNoteEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });

    if (kDebugMode) {
      debugPrint('🗑️ Все данные пользователя $userId удалены (включая UserUsageLimits и FishingNotes)');
    }
  }

  /// Закрытие базы данных
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;

    if (kDebugMode) {
      debugPrint('🔒 IsarService закрыт');
    }
  }
}