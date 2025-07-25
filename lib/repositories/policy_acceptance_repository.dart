// Путь: lib/models/isar/policy_acceptance_entity.dart

import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// ✅ Entity модель для хранения принятия политики конфиденциальности в Isar
@Collection()
class PolicyAcceptanceEntity {
  Id id = Isar.autoIncrement;

  String? firebaseId = 'consents'; // Фиксированный ID документа в Firebase
  late String userId;

  // Политика конфиденциальности
  bool privacyPolicyAccepted = false;
  String privacyPolicyVersion = '1.0.0';
  String? privacyPolicyHash;

  // Пользовательское соглашение
  bool termsOfServiceAccepted = false;
  String termsOfServiceVersion = '1.0.0';
  String? termsOfServiceHash;

  // Общие данные
  String consentLanguage = 'ru';
  DateTime? consentTimestamp;

  // Метаданные
  bool isSynced = false;
  bool markedForDeletion = false;
  DateTime? lastSyncAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  // ========================================
  // МЕТОДЫ СИНХРОНИЗАЦИИ С FIREBASE
  // ========================================

  /// Преобразование в Firebase формат
  Map<String, dynamic> toFirestoreMap() {
    return {
      'privacy_policy_accepted': privacyPolicyAccepted,
      'privacy_policy_version': privacyPolicyVersion,
      'privacy_policy_hash': privacyPolicyHash,
      'terms_of_service_accepted': termsOfServiceAccepted,
      'terms_of_service_version': termsOfServiceVersion,
      'terms_of_service_hash': termsOfServiceHash,
      'consent_language': consentLanguage,
      'consent_timestamp': consentTimestamp != null
          ? Timestamp.fromDate(consentTimestamp!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Создание из Firebase данных
  static PolicyAcceptanceEntity fromFirestoreMap(String userId, Map<String, dynamic> data) {
    return PolicyAcceptanceEntity()
      ..firebaseId = 'consents'
      ..userId = userId
      ..privacyPolicyAccepted = data['privacy_policy_accepted'] ?? false
      ..privacyPolicyVersion = data['privacy_policy_version'] ?? '1.0.0'
      ..privacyPolicyHash = data['privacy_policy_hash']
      ..termsOfServiceAccepted = data['terms_of_service_accepted'] ?? false
      ..termsOfServiceVersion = data['terms_of_service_version'] ?? '1.0.0'
      ..termsOfServiceHash = data['terms_of_service_hash']
      ..consentLanguage = data['consent_language'] ?? 'ru'
      ..consentTimestamp = _parseTimestamp(data['consent_timestamp'])
      ..isSynced = true
      ..markedForDeletion = false
      ..lastSyncAt = DateTime.now()
      ..createdAt = _parseTimestamp(data['createdAt']) ?? DateTime.now()
      ..updatedAt = _parseTimestamp(data['updatedAt']) ?? DateTime.now();
  }

  /// Универсальный парсинг Timestamp/DateTime/int
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }

    return null;
  }

  // ========================================
  // МЕТОДЫ УПРАВЛЕНИЯ СОСТОЯНИЕМ
  // ========================================

  /// Отметить как синхронизированную
  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Отметить как измененную (требует синхронизации)
  void markAsModified() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  /// Отметить для удаления
  void markForDeletion() {
    markedForDeletion = true;
    isSynced = false;
    updatedAt = DateTime.now();
  }

  // ========================================
  // БИЗНЕС-ЛОГИКА
  // ========================================

  /// Проверяет, приняты ли все согласия с актуальными версиями
  bool isValid(String currentPrivacyVersion, String currentTermsVersion) {
    return privacyPolicyAccepted &&
        termsOfServiceAccepted &&
        privacyPolicyVersion == currentPrivacyVersion &&
        termsOfServiceVersion == currentTermsVersion;
  }

  /// Принимает политику конфиденциальности
  void acceptPrivacyPolicy(String version, {String? hash}) {
    privacyPolicyAccepted = true;
    privacyPolicyVersion = version;
    privacyPolicyHash = hash;
    consentTimestamp = DateTime.now();
    markAsModified();
  }

  /// Принимает пользовательское соглашение
  void acceptTermsOfService(String version, {String? hash}) {
    termsOfServiceAccepted = true;
    termsOfServiceVersion = version;
    termsOfServiceHash = hash;
    consentTimestamp = DateTime.now();
    markAsModified();
  }

  /// Принимает оба документа одновременно
  void acceptAll(String privacyVersion, String termsVersion, {
    String? privacyHash,
    String? termsHash,
    String? language,
  }) {
    privacyPolicyAccepted = true;
    privacyPolicyVersion = privacyVersion;
    privacyPolicyHash = privacyHash;

    termsOfServiceAccepted = true;
    termsOfServiceVersion = termsVersion;
    termsOfServiceHash = termsHash;

    if (language != null) {
      consentLanguage = language;
    }

    consentTimestamp = DateTime.now();
    markAsModified();
  }

  /// Сброс всех согласий
  void reset() {
    privacyPolicyAccepted = false;
    termsOfServiceAccepted = false;
    consentTimestamp = null;
    markAsModified();
  }

  // ========================================
  // ОТЛАДКА
  // ========================================

  @override
  String toString() {
    return 'PolicyAcceptanceEntity(id: $id, userId: $userId, '
        'privacy: $privacyPolicyAccepted($privacyPolicyVersion), '
        'terms: $termsOfServiceAccepted($termsOfServiceVersion), '
        'isSynced: $isSynced)';
  }
}