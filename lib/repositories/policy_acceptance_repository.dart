// Путь: lib/repositories/policy_acceptance_repository.dart

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart'; // ✅ ДОБАВИТЬ ЭТУ СТРОКУ
import '../models/isar/policy_acceptance_entity.dart';
import '../services/isar_service.dart';
import '../services/offline/sync_service.dart';
import '../services/firebase/firebase_service.dart';

/// ✅ Repository для управления принятием политики конфиденциальности через Isar
class PolicyAcceptanceRepository {
  static final PolicyAcceptanceRepository _instance = PolicyAcceptanceRepository._internal();
  factory PolicyAcceptanceRepository() => _instance;
  PolicyAcceptanceRepository._internal();

  final IsarService _isarService = IsarService.instance;
  final SyncService _syncService = SyncService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // ========================================
  // CRUD ОПЕРАЦИИ
  // ========================================

  /// Получение текущих согласий пользователя
  Future<PolicyAcceptanceEntity?> getUserPolicyAcceptance(String userId) async {
    try {
      debugPrint('📋 Получение согласий для пользователя: $userId');

      final entities = await _isarService.getAllPolicyAcceptances();
      final userEntity = entities.where((e) => e.userId == userId).firstOrNull;

      if (userEntity != null) {
        debugPrint('✅ Найдены согласия пользователя: ${userEntity.toString()}');
        return userEntity;
      }

      debugPrint('❌ Согласия для пользователя не найдены');
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при получении согласий: $e');
      return null;
    }
  }

  /// Сохранение согласий пользователя
  Future<bool> savePolicyAcceptance(PolicyAcceptanceEntity entity) async {
    try {
      debugPrint('💾 Сохранение согласий: ${entity.toString()}');

      // Устанавливаем временные метки
      if (entity.id == Isar.autoIncrement) {
        entity.createdAt = DateTime.now();
      }
      entity.updatedAt = DateTime.now();
      entity.markAsModified(); // isSynced = false

      // Сохраняем в Isar
      await _isarService.insertPolicyAcceptance(entity);

      debugPrint('✅ Согласия сохранены в Isar: ID=${entity.id}');

      // Триггерим синхронизацию в фоновом режиме
      _triggerSyncServiceInBackground();

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий: $e');
      return false;
    }
  }

  /// Создание или обновление согласий пользователя
  Future<bool> createOrUpdatePolicyAcceptance({
    required String userId,
    bool? privacyPolicyAccepted,
    bool? termsOfServiceAccepted,
    String? privacyVersion,
    String? termsVersion,
    String? privacyHash,
    String? termsHash,
    String? language,
  }) async {
    try {
      debugPrint('🔄 Создание/обновление согласий для пользователя: $userId');

      // Ищем существующие согласия
      PolicyAcceptanceEntity entity = await getUserPolicyAcceptance(userId) ??
          PolicyAcceptanceEntity()
            ..userId = userId
            ..firebaseId = 'consents'
            ..createdAt = DateTime.now();

      // Обновляем данные
      if (privacyPolicyAccepted == true && privacyVersion != null) {
        entity.acceptPrivacyPolicy(privacyVersion, hash: privacyHash);
      }

      if (termsOfServiceAccepted == true && termsVersion != null) {
        entity.acceptTermsOfService(termsVersion, hash: termsHash);
      }

      if (language != null) {
        entity.consentLanguage = language;
      }

      // Сохраняем
      return await savePolicyAcceptance(entity);
    } catch (e) {
      debugPrint('❌ Ошибка при создании/обновлении согласий: $e');
      return false;
    }
  }

  /// Принятие всех согласий одновременно
  Future<bool> acceptAllPolicies({
    required String userId,
    required String privacyVersion,
    required String termsVersion,
    String? privacyHash,
    String? termsHash,
    String? language,
  }) async {
    try {
      debugPrint('✅ Принятие всех согласий для пользователя: $userId');

      // Ищем существующие согласия или создаем новые
      PolicyAcceptanceEntity entity = await getUserPolicyAcceptance(userId) ??
          PolicyAcceptanceEntity()
            ..userId = userId
            ..firebaseId = 'consents'
            ..createdAt = DateTime.now();

      // Принимаем все согласия
      entity.acceptAll(
        privacyVersion,
        termsVersion,
        privacyHash: privacyHash,
        termsHash: termsHash,
        language: language ?? 'ru',
      );

      // Сохраняем
      return await savePolicyAcceptance(entity);
    } catch (e) {
      debugPrint('❌ Ошибка при принятии всех согласий: $e');
      return false;
    }
  }

  /// Очистка согласий пользователя (при выходе из аккаунта)
  Future<bool> clearUserPolicyAcceptance(String userId) async {
    try {
      debugPrint('🗑️ Очистка согласий для пользователя: $userId');

      final entity = await getUserPolicyAcceptance(userId);
      if (entity != null) {
        await _isarService.deletePolicyAcceptance(entity.id);
        debugPrint('✅ Согласия очищены для пользователя: $userId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при очистке согласий: $e');
      return false;
    }
  }

  // ========================================
  // ПРОВЕРКА ВАЛИДНОСТИ
  // ========================================

  /// Проверка актуальности согласий
  Future<bool> arePoliciesValid({
    required String userId,
    required String currentPrivacyVersion,
    required String currentTermsVersion,
  }) async {
    try {
      final entity = await getUserPolicyAcceptance(userId);

      if (entity == null) {
        debugPrint('❌ Согласия не найдены для пользователя: $userId');
        return false;
      }

      final isValid = entity.isValid(currentPrivacyVersion, currentTermsVersion);
      debugPrint('🔍 Валидность согласий для $userId: $isValid');

      return isValid;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке валидности согласий: $e');
      return false;
    }
  }

  /// Получение статуса согласий (для совместимости с существующим кодом)
  Future<Map<String, dynamic>> getPolicyStatus(String userId) async {
    try {
      final entity = await getUserPolicyAcceptance(userId);

      if (entity == null) {
        return {
          'privacy_policy_accepted': false,
          'terms_of_service_accepted': false,
          'privacy_policy_version': '1.0.0',
          'terms_of_service_version': '1.0.0',
          'consent_language': 'ru',
          'consent_timestamp': null,
          'exists': false,
        };
      }

      return {
        'privacy_policy_accepted': entity.privacyPolicyAccepted,
        'terms_of_service_accepted': entity.termsOfServiceAccepted,
        'privacy_policy_version': entity.privacyPolicyVersion,
        'terms_of_service_version': entity.termsOfServiceVersion,
        'privacy_policy_hash': entity.privacyPolicyHash,
        'terms_of_service_hash': entity.termsOfServiceHash,
        'consent_language': entity.consentLanguage,
        'consent_timestamp': entity.consentTimestamp,
        'exists': true,
      };
    } catch (e) {
      debugPrint('❌ Ошибка при получении статуса согласий: $e');
      return {
        'privacy_policy_accepted': false,
        'terms_of_service_accepted': false,
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  // ========================================
  // СИНХРОНИЗАЦИЯ
  // ========================================

  /// Получение несинхронизированных согласий
  Future<List<PolicyAcceptanceEntity>> getUnsyncedPolicyAcceptances() async {
    try {
      final allEntities = await _isarService.getAllPolicyAcceptances();
      final unsynced = allEntities.where((entity) => !entity.isSynced).toList();

      debugPrint('🔄 Найдено несинхронизированных согласий: ${unsynced.length}');
      return unsynced;
    } catch (e) {
      debugPrint('❌ Ошибка при получении несинхронизированных согласий: $e');
      return [];
    }
  }

  /// Триггер синхронизации в фоновом режиме
  void _triggerSyncServiceInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        await _syncService.performFullSync();
      } catch (e) {
        debugPrint('❌ Ошибка фоновой синхронизации согласий: $e');
      }
    });
  }

  // ========================================
  // ОБРАТНАЯ СОВМЕСТИМОСТЬ
  // ========================================

  /// Миграция данных из SharedPreferences (если нужно)
  Future<void> migrateFromSharedPreferences(String userId) async {
    try {
      debugPrint('🔄 Попытка миграции согласий из SharedPreferences для: $userId');

      // Проверяем, есть ли уже данные в Isar
      final existingEntity = await getUserPolicyAcceptance(userId);
      if (existingEntity != null) {
        debugPrint('✅ Согласия уже существуют в Isar, миграция не нужна');
        return;
      }

      // Здесь можно добавить логику чтения из SharedPreferences
      // и создания PolicyAcceptanceEntity
      debugPrint('🔄 Миграция из SharedPreferences пока не реализована');
    } catch (e) {
      debugPrint('❌ Ошибка при миграции из SharedPreferences: $e');
    }
  }

  /// Синхронизация с Firebase (прямая, если SyncService недоступен)
  Future<bool> syncWithFirebase(String userId) async {
    try {
      debugPrint('🔄 Прямая синхронизация согласий с Firebase для: $userId');

      // Получаем данные из Firebase
      final firebaseDoc = await _firebaseService.getUserConsents();

      if (firebaseDoc.exists) {
        final data = firebaseDoc.data() as Map<String, dynamic>;
        final entity = PolicyAcceptanceEntity.fromFirestoreMap(userId, data);

        // Сохраняем в Isar
        await _isarService.insertPolicyAcceptance(entity);

        debugPrint('✅ Согласия синхронизированы с Firebase');
        return true;
      } else {
        debugPrint('❌ Согласия не найдены в Firebase');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации с Firebase: $e');
      return false;
    }
  }

  // ========================================
  // ДИАГНОСТИКА
  // ========================================

  /// Получение всех согласий для диагностики
  Future<List<PolicyAcceptanceEntity>> getAllPolicyAcceptances() async {
    try {
      return await _isarService.getAllPolicyAcceptances();
    } catch (e) {
      debugPrint('❌ Ошибка при получении всех согласий: $e');
      return [];
    }
  }

  /// Информация о состоянии
  Future<Map<String, dynamic>> getRepositoryInfo() async {
    try {
      final allEntities = await getAllPolicyAcceptances();
      final unsyncedCount = allEntities.where((e) => !e.isSynced).length;

      return {
        'total_entities': allEntities.length,
        'unsynced_count': unsyncedCount,
        'synced_count': allEntities.length - unsyncedCount,
        'repository_type': 'PolicyAcceptanceRepository',
        'storage_backend': 'Isar',
        'sync_service': 'SyncService',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'repository_type': 'PolicyAcceptanceRepository',
      };
    }
  }
}