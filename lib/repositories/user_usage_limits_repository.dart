// Путь: lib/repositories/user_usage_limits_repository.dart


import '../models/isar/user_usage_limits_entity.dart';
import '../models/usage_limits_model.dart';
import '../models/usage_limits_models.dart';
import '../constants/subscription_constants.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';

/// Repository для работы с лимитами пользователя
/// Обеспечивает совместимость между новой архитектурой Isar и существующей UsageLimitsModel
class UserUsageLimitsRepository {
  static UserUsageLimitsRepository? _instance;
  final IsarService _isarService;
  final SyncService _syncService;

  UserUsageLimitsRepository._({
    required IsarService isarService,
    required SyncService syncService,
  }) : _isarService = isarService,
        _syncService = syncService;

  static UserUsageLimitsRepository get instance {
    _instance ??= UserUsageLimitsRepository._(
      isarService: IsarService.instance,
      syncService: SyncService.instance,
    );
    return _instance!;
  }

  // ========================================
  // ОСНОВНЫЕ CRUD ОПЕРАЦИИ
  // ========================================

  /// ✅ Получение лимитов пользователя (основной метод)
  Future<UsageLimitsModel?> getUserLimits(String userId) async {
    try {
      // ✅ УБРАНО: debugPrint('📊 getUserLimits: получаем лимиты для пользователя $userId');

      // Ищем в Isar
      final entity = await _isarService.getUserUsageLimitsByUserId(userId);

      if (entity != null) {
        final model = _entityToModel(entity);

        // ✅ УБРАНО: debugPrint('✅ getUserLimits: найдены лимиты в Isar: $model');

        return model;
      }

      // Если в Isar нет - создаем пустые лимиты
      // ✅ УБРАНО: debugPrint('⚠️ getUserLimits: лимиты не найдены, создаем по умолчанию');

      return UsageLimitsModel.defaultLimits(userId);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ getUserLimits: ошибка получения лимитов: $e');
      return UsageLimitsModel.defaultLimits(userId);
    }
  }

  /// ✅ Сохранение/обновление лимитов пользователя
  Future<UsageLimitsModel> saveUserLimits(UsageLimitsModel model) async {
    try {
      // ✅ УБРАНО: debugPrint('💾 saveUserLimits: сохраняем лимиты для пользователя ${model.userId}');
      // ✅ УБРАНО: debugPrint('💾 saveUserLimits: ${model.toString()}');

      // Конвертируем модель в entity
      final entity = _modelToEntity(model);

      // Ищем существующую запись
      final existingEntity = await _isarService.getUserUsageLimitsByUserId(model.userId);

      if (existingEntity != null) {
        // Обновляем существующую
        entity.id = existingEntity.id;
        entity.firebaseId = existingEntity.firebaseId;
        await _isarService.updateUserUsageLimits(entity);

        // ✅ УБРАНО: debugPrint('🔄 saveUserLimits: обновлены существующие лимиты ID: ${entity.id}');
      } else {
        // Создаем новую
        await _isarService.insertUserUsageLimits(entity);

        // ✅ УБРАНО: debugPrint('🆕 saveUserLimits: созданы новые лимиты ID: ${entity.id}');
      }

      // Запускаем фоновую синхронизацию
      _triggerSyncInBackground();

      return _entityToModel(entity);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ saveUserLimits: ошибка сохранения лимитов: $e');
      rethrow;
    }
  }

  /// ✅ Удаление лимитов пользователя
  Future<bool> deleteUserLimits(String userId) async {
    try {
      // ✅ УБРАНО: debugPrint('🗑️ deleteUserLimits: удаляем лимиты пользователя $userId');

      final deleted = await _isarService.deleteUserUsageLimitsByUserId(userId);

      if (deleted) {
        // Запускаем фоновую синхронизацию
        _triggerSyncInBackground();

        // ✅ УБРАНО: debugPrint('✅ deleteUserLimits: лимиты пользователя $userId удалены');
      }

      return deleted;

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ deleteUserLimits: ошибка удаления лимитов: $e');
      return false;
    }
  }

  // ========================================
  // ОПЕРАЦИИ СО СЧЕТЧИКАМИ
  // ========================================

  /// ✅ Увеличение счетчика для типа контента
  Future<UsageLimitsModel> incrementCounter(String userId, ContentType contentType) async {
    try {
      // ✅ УБРАНО: debugPrint('📈 incrementCounter: увеличиваем счетчик $contentType для пользователя $userId');

      // Получаем текущие лимиты
      var model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);

      // Увеличиваем счетчик
      model = model.incrementCounter(contentType);

      // Сохраняем
      return await saveUserLimits(model);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ incrementCounter: ошибка увеличения счетчика: $e');
      rethrow;
    }
  }

  /// ✅ Уменьшение счетчика для типа контента
  Future<UsageLimitsModel> decrementCounter(String userId, ContentType contentType) async {
    try {
      // ✅ УБРАНО: debugPrint('📉 decrementCounter: уменьшаем счетчик $contentType для пользователя $userId');

      // Получаем текущие лимиты
      var model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);

      // Уменьшаем счетчик
      model = model.decrementCounter(contentType);

      // Сохраняем
      return await saveUserLimits(model);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ decrementCounter: ошибка уменьшения счетчика: $e');
      rethrow;
    }
  }

  /// ✅ Полный пересчет лимитов
  Future<UsageLimitsModel> recalculateCounters(String userId, {
    required int notesCount,
    required int markerMapsCount,
    required int budgetNotesCount,
    String recalculationType = 'manual_recalculate',
  }) async {
    try {
      // ✅ УБРАНО: debugPrint('🔢 recalculateCounters: пересчитываем лимиты для пользователя $userId');
      // ✅ УБРАНО: debugPrint('🔢 recalculateCounters: notes=$notesCount, maps=$markerMapsCount, budget=$budgetNotesCount');

      // Создаем/обновляем через IsarService
      final entity = await _isarService.createOrUpdateUserUsageLimits(
        userId,
        notesCount: notesCount,
        markerMapsCount: markerMapsCount,
        budgetNotesCount: budgetNotesCount,
        recalculationType: recalculationType,
      );

      // Запускаем фоновую синхронизацию
      _triggerSyncInBackground();

      final model = _entityToModel(entity);

      // ✅ УБРАНО: debugPrint('✅ recalculateCounters: лимиты пересчитаны: $model');

      return model;

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ recalculateCounters: ошибка пересчета лимитов: $e');
      rethrow;
    }
  }

  /// ✅ Сброс всех счетчиков
  Future<UsageLimitsModel> resetAllCounters(String userId) async {
    try {
      // ✅ УБРАНО: debugPrint('🔄 resetAllCounters: сбрасываем все счетчики для пользователя $userId');

      // Получаем текущие лимиты
      var model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);

      // Сбрасываем счетчики
      model = model.resetAllCounters();

      // Сохраняем
      return await saveUserLimits(model);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ resetAllCounters: ошибка сброса счетчиков: $e');
      rethrow;
    }
  }

  // ========================================
  // ПРОВЕРКИ ЛИМИТОВ
  // ========================================

  /// ✅ Проверка возможности создания контента
  Future<ContentCreationResult> canCreateContent(String userId, ContentType contentType) async {
    try {
      final model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);

      final canCreate = model.canCreateNew(contentType);
      final currentCount = model.getCountForType(contentType);
      final limit = SubscriptionConstants.getContentLimit(contentType);
      final remaining = model.getRemainingCount(contentType);

      ContentCreationBlockReason? reason;
      if (!canCreate) {
        if (contentType == ContentType.depthChart) {
          reason = ContentCreationBlockReason.premiumRequired;
        } else {
          reason = ContentCreationBlockReason.limitReached;
        }
      }

      return ContentCreationResult(
        canCreate: canCreate,
        reason: reason,
        currentCount: currentCount,
        limit: limit,
        remaining: remaining,
      );

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ canCreateContent: ошибка проверки лимитов: $e');

      return ContentCreationResult(
        canCreate: false,
        reason: ContentCreationBlockReason.error,
        currentCount: 0,
        limit: 0,
        remaining: 0,
      );
    }
  }

  /// ✅ Получение предупреждений о лимитах
  Future<List<ContentTypeWarning>> getContentWarnings(String userId) async {
    try {
      final model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);
      final warnings = <ContentTypeWarning>[];

      for (final contentType in [ContentType.fishingNotes, ContentType.markerMaps, ContentType.budgetNotes]) {
        if (model.shouldShowWarning(contentType)) {
          warnings.add(ContentTypeWarning(
            contentType: contentType,
            currentCount: model.getCountForType(contentType),
            limit: SubscriptionConstants.getContentLimit(contentType),
            remaining: model.getRemainingCount(contentType),
            percentage: model.getUsagePercentage(contentType),
          ));
        }
      }

      return warnings;

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ getContentWarnings: ошибка получения предупреждений: $e');
      return [];
    }
  }

  // ========================================
  // СТАТИСТИКА И ОТЧЕТЫ
  // ========================================

  /// ✅ Получение статистики использования
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    try {
      final model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);
      return model.getUsageStats();

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ getUsageStats: ошибка получения статистики: $e');
      return {};
    }
  }

  /// ✅ Получение статистики для конкретного типа контента
  Future<Map<String, dynamic>> getStatsForType(String userId, ContentType contentType) async {
    try {
      final model = await getUserLimits(userId) ?? UsageLimitsModel.defaultLimits(userId);
      return model.getStatsForType(contentType);

    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ getStatsForType: ошибка получения статистики для типа: $e');
      return {};
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ
  // ========================================

  /// ✅ Получение несинхронизированных лимитов
  Future<List<UserUsageLimitsEntity>> getUnsyncedLimits() async {
    try {
      return await _isarService.getUnsyncedUserUsageLimits();
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ getUnsyncedLimits: ошибка получения несинхронизированных лимитов: $e');
      return [];
    }
  }

  /// ✅ Пометка лимитов как синхронизированных
  Future<void> markAsSynced(int id, String firebaseId) async {
    try {
      await _isarService.markUserUsageLimitsAsSynced(id, firebaseId);

      // ✅ УБРАНО: debugPrint('✅ markAsSynced: лимиты $id помечены как синхронизированные');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ markAsSynced: ошибка пометки синхронизации: $e');
    }
  }

  /// ✅ Запуск синхронизации в фоновом режиме
  void _triggerSyncInBackground() {
    try {
      // Запускаем синхронизацию без ожидания результата
      _syncService.syncUserUsageLimitsToFirebase().catchError((error) {
        // ✅ УБРАНО: debugPrint('⚠️ Фоновая синхронизация лимитов завершилась с ошибкой: $error');
        return false; // 🔥 ИСПРАВЛЕНО: добавлен return
      });

      // ✅ УБРАНО: debugPrint('🔄 Запущена фоновая синхронизация лимитов');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка запуска фоновой синхронизации лимитов: $e');
    }
  }

  // ========================================
  // КОНВЕРТАЦИЯ МЕЖДУ МОДЕЛЯМИ
  // ========================================

  /// ✅ Конвертация Entity в Model
  UsageLimitsModel _entityToModel(UserUsageLimitsEntity entity) {
    return UsageLimitsModel(
      userId: entity.userId,
      notesCount: entity.notesCount,
      markerMapsCount: entity.markerMapsCount,
      budgetNotesCount: entity.budgetNotesCount,
      lastResetDate: entity.lastResetDate != null
          ? DateTime.tryParse(entity.lastResetDate!) ?? entity.createdAt
          : entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// ✅ Конвертация Model в Entity
  UserUsageLimitsEntity _modelToEntity(UsageLimitsModel model) {
    final entity = UserUsageLimitsEntity();

    entity.userId = model.userId;
    entity.budgetNotesCount = model.budgetNotesCount;
    entity.expensesCount = model.budgetNotesCount; // Совместимость со старой структурой
    entity.markerMapsCount = model.markerMapsCount;
    entity.notesCount = model.notesCount;
    entity.tripsCount = 0; // Пока не используется в UsageLimitsModel

    entity.lastResetDate = model.lastResetDate.toIso8601String();
    entity.recalculatedAt = DateTime.now().toIso8601String();
    entity.recalculationType = 'repository_update';

    entity.createdAt = DateTime.now();
    entity.updatedAt = model.updatedAt;
    entity.isSynced = false; // Всегда помечаем как несинхронизированные для отправки в Firebase

    return entity;
  }

  // ========================================
  // ОТЛАДКА И ДИАГНОСТИКА
  // ========================================

  /// ✅ Получение отладочной информации
  Future<Map<String, dynamic>> getDebugInfo(String userId) async {
    try {
      final entity = await _isarService.getUserUsageLimitsByUserId(userId);
      final model = await getUserLimits(userId);

      return {
        'hasEntity': entity != null,
        'hasModel': model != null,
        'entity': entity?.toString(),
        'model': model?.toString(),
        'syncStatus': entity?.isSynced ?? false,
        'lastSync': entity?.lastSyncAt?.toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// ✅ Очистка всех лимитов (для отладки)
  Future<void> clearAllLimits() async {
    try {
      // ✅ УБРАНО: debugPrint('🗑️ clearAllLimits: очищаем все лимиты пользователей');

      // Получаем все записи и удаляем их
      final allLimits = await _isarService.getAllUserUsageLimits();
      for (final limits in allLimits) {
        await _isarService.deleteUserUsageLimits(limits.id);
      }

      // ✅ УБРАНО: debugPrint('✅ clearAllLimits: все лимиты очищены');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ clearAllLimits: ошибка очистки лимитов: $e');
    }
  }
}