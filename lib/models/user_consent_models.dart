// Путь: lib/models/user_consent_models.dart

/// Статус согласий пользователя
class UserConsentStatus {
  final bool privacyPolicyAccepted;
  final bool termsOfServiceAccepted;
  final String? consentVersion;
  final DateTime? consentTimestamp;
  final String? consentLanguage;
  final bool isVersionCurrent;
  final String? currentVersion;

  const UserConsentStatus({
    required this.privacyPolicyAccepted,
    required this.termsOfServiceAccepted,
    this.consentVersion,
    this.consentTimestamp,
    this.consentLanguage,
    required this.isVersionCurrent,
    this.currentVersion,
  });

  /// Проверяет, приняты ли все необходимые согласия
  bool get hasAllConsents => privacyPolicyAccepted && termsOfServiceAccepted && isVersionCurrent;

  /// Проверяет, есть ли обновления в соглашениях
  bool get hasUpdates => !isVersionCurrent;

  /// Создание из JSON
  factory UserConsentStatus.fromJson(Map<String, dynamic> json) {
    return UserConsentStatus(
      privacyPolicyAccepted: json['privacyPolicyAccepted'] ?? false,
      termsOfServiceAccepted: json['termsOfServiceAccepted'] ?? false,
      consentVersion: json['consentVersion'],
      consentTimestamp: json['consentTimestamp'] != null
          ? DateTime.parse(json['consentTimestamp'])
          : null,
      consentLanguage: json['consentLanguage'],
      isVersionCurrent: json['isVersionCurrent'] ?? false,
      currentVersion: json['currentVersion'],
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'privacyPolicyAccepted': privacyPolicyAccepted,
      'termsOfServiceAccepted': termsOfServiceAccepted,
      'consentVersion': consentVersion,
      'consentTimestamp': consentTimestamp?.toIso8601String(),
      'consentLanguage': consentLanguage,
      'isVersionCurrent': isVersionCurrent,
      'currentVersion': currentVersion,
    };
  }

  @override
  String toString() {
    return 'UserConsentStatus(privacy: $privacyPolicyAccepted, terms: $termsOfServiceAccepted, version: $consentVersion, current: $isVersionCurrent)';
  }
}

/// Версия документа (соглашения)
class DocumentVersion {
  final String version;
  final DateTime releaseDate;
  final String documentType; // 'privacy_policy' или 'terms_of_service'
  final String language;
  final String? description;
  final String? hash;
  final bool isCurrent;

  const DocumentVersion({
    required this.version,
    required this.releaseDate,
    required this.documentType,
    required this.language,
    this.description,
    this.hash,
    required this.isCurrent,
  });

  /// Создание из JSON
  factory DocumentVersion.fromJson(Map<String, dynamic> json) {
    return DocumentVersion(
      version: json['version'] ?? '1.0.0',
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : DateTime.now(),
      documentType: json['documentType'] ?? 'unknown',
      language: json['language'] ?? 'ru',
      description: json['description'],
      hash: json['hash'],
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'releaseDate': releaseDate.toIso8601String(),
      'documentType': documentType,
      'language': language,
      'description': description,
      'hash': hash,
      'isCurrent': isCurrent,
    };
  }

  /// Получение локализованного названия типа документа
  String getLocalizedDocumentType() {
    switch (documentType) {
      case 'privacy_policy':
        return language == 'ru' ? 'Политика конфиденциальности' : 'Privacy Policy';
      case 'terms_of_service':
        return language == 'ru' ? 'Пользовательское соглашение' : 'Terms of Service';
      default:
        return documentType;
    }
  }

  @override
  String toString() {
    return 'DocumentVersion(type: $documentType, version: $version, date: $releaseDate, lang: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentVersion &&
        other.version == version &&
        other.documentType == documentType &&
        other.language == language;
  }

  @override
  int get hashCode {
    return version.hashCode ^ documentType.hashCode ^ language.hashCode;
  }
}