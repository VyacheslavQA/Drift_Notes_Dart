// Путь: lib/services/user_consent_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_consent_models.dart';
import 'firebase/firebase_service.dart';

/// ✅ УПРОЩЕННЫЙ результат проверки согласий - что именно нужно принять
class ConsentCheckResult {
  final bool allValid;
  final bool needPrivacyPolicy;
  final bool needTermsOfService;
  final String currentPrivacyVersion;
  final String currentTermsVersion;
  final String? savedPrivacyVersion;
  final String? savedTermsVersion;

  const ConsentCheckResult({
    required this.allValid,
    required this.needPrivacyPolicy,
    required this.needTermsOfService,
    required this.currentPrivacyVersion,
    required this.currentTermsVersion,
    this.savedPrivacyVersion,
    this.savedTermsVersion,
  });

  /// Есть ли что-то, что нужно принять заново
  bool get hasChanges => needPrivacyPolicy || needTermsOfService;

  @override
  String toString() {
    return 'ConsentCheckResult(allValid: $allValid, needPrivacy: $needPrivacyPolicy, needTerms: $needTermsOfService)';
  }
}

/// ✅ УПРОЩЕННЫЙ сервис для управления согласиями пользователя
class UserConsentService {
  static final UserConsentService _instance = UserConsentService._internal();
  factory UserConsentService() => _instance;
  UserConsentService._internal();

  // Ключи для локального хранения
  static const String _privacyPolicyAcceptedKey = 'privacy_policy_accepted';
  static const String _termsOfServiceAcceptedKey = 'terms_of_service_accepted';
  static const String _privacyPolicyVersionKey = 'privacy_policy_version';
  static const String _termsOfServiceVersionKey = 'terms_of_service_version';

  final FirebaseService _firebaseService = FirebaseService();

  // Кэш для версий файлов
  String? _cachedPrivacyPolicyVersion;
  String? _cachedTermsOfServiceVersion;

  /// Извлекает версию из первой строки файла
  String _extractVersionFromContent(String content) {
    try {
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines[0].trim();

        // Ищем версию (русский)
        RegExp versionRuPattern = RegExp(
          r'[Вв]ерсия\s*:\s*(\d+\.\d+(?:\.\d+)?)',
          caseSensitive: false,
        );
        var match = versionRuPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          return match.group(1)!;
        }

        // Ищем версию (английский)
        RegExp versionEnPattern = RegExp(
          r'[Vv]ersion\s*:\s*(\d+\.\d+(?:\.\d+)?)',
          caseSensitive: false,
        );
        match = versionEnPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          return match.group(1)!;
        }

        // Ищем любые цифры как версию
        RegExp numbersPattern = RegExp(r'(\d+\.\d+(?:\.\d+)?)');
        match = numbersPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          return match.group(1)!;
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка извлечения версии: $e');
    }

    return '1.0.0'; // Версия по умолчанию
  }

  /// Загружает и анализирует файл политики конфиденциальности
  Future<Map<String, String>> _loadPrivacyPolicyInfo(String languageCode) async {
    try {
      final fileName = 'assets/privacy_policy/privacy_policy_$languageCode.txt';
      String content;

      try {
        content = await rootBundle.loadString(fileName);
      } catch (e) {
        // Фоллбэк на английскую версию
        content = await rootBundle.loadString('assets/privacy_policy/privacy_policy_en.txt');
      }

      final version = _extractVersionFromContent(content);
      return {'version': version, 'content': content};
    } catch (e) {
      debugPrint('❌ Ошибка загрузки политики конфиденциальности: $e');
      return {'version': '1.0.0', 'content': ''};
    }
  }

  /// Загружает и анализирует файл пользовательского соглашения
  Future<Map<String, String>> _loadTermsOfServiceInfo(String languageCode) async {
    try {
      final fileName = 'assets/terms_of_service/terms_of_service_$languageCode.txt';
      String content;

      try {
        content = await rootBundle.loadString(fileName);
      } catch (e) {
        // Фоллбэк на английскую версию
        content = await rootBundle.loadString('assets/terms_of_service/terms_of_service_en.txt');
      }

      final version = _extractVersionFromContent(content);
      return {'version': version, 'content': content};
    } catch (e) {
      debugPrint('❌ Ошибка загрузки пользовательского соглашения: $e');
      return {'version': '1.0.0', 'content': ''};
    }
  }

  /// Получает текущую версию политики конфиденциальности
  Future<String> getCurrentPrivacyPolicyVersion([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final privacyInfo = await _loadPrivacyPolicyInfo(languageCode);
      _cachedPrivacyPolicyVersion = privacyInfo['version'];
      return privacyInfo['version'] ?? '1.0.0';
    } catch (e) {
      debugPrint('❌ Ошибка получения версии политики конфиденциальности: $e');
      return '1.0.0';
    }
  }

  /// Получает текущую версию пользовательского соглашения
  Future<String> getCurrentTermsOfServiceVersion([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final termsInfo = await _loadTermsOfServiceInfo(languageCode);
      _cachedTermsOfServiceVersion = termsInfo['version'];
      return termsInfo['version'] ?? '1.0.0';
    } catch (e) {
      debugPrint('❌ Ошибка получения версии пользовательского соглашения: $e');
      return '1.0.0';
    }
  }

  /// ✅ ГЛАВНЫЙ МЕТОД: Проверяет согласия и возвращает что именно нужно принять
  Future<ConsentCheckResult> checkUserConsents([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      // Получаем текущие версии из файлов
      final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
      final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);

      debugPrint('📋 Текущие версии: Privacy=$currentPrivacyVersion, Terms=$currentTermsVersion');

      if (_firebaseService.isUserLoggedIn) {
        // Для авторизованного пользователя проверяем Firebase
        final firebaseResult = await _checkFirebaseConsents(
          currentPrivacyVersion,
          currentTermsVersion,
        );

        if (!firebaseResult.allValid) {
          return firebaseResult;
        }

        // Проверяем локальные данные
        final localResult = await _checkLocalConsents(
          currentPrivacyVersion,
          currentTermsVersion,
        );

        // Если локальные данные неактуальны, синхронизируем из Firebase
        if (!localResult.allValid) {
          await syncConsentsFromFirestore();
          return await _checkLocalConsents(currentPrivacyVersion, currentTermsVersion);
        }

        return localResult;
      } else {
        // Для неавторизованного пользователя проверяем только локальные данные
        return await _checkLocalConsents(currentPrivacyVersion, currentTermsVersion);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      return ConsentCheckResult(
        allValid: false,
        needPrivacyPolicy: true,
        needTermsOfService: true,
        currentPrivacyVersion: '1.0.0',
        currentTermsVersion: '1.0.0',
      );
    }
  }

  /// Проверяет согласия в Firebase
  Future<ConsentCheckResult> _checkFirebaseConsents(
      String currentPrivacyVersion,
      String currentTermsVersion,
      ) async {
    try {
      final doc = await _firebaseService.getUserConsents();

      if (!doc.exists) {
        return ConsentCheckResult(
          allValid: false,
          needPrivacyPolicy: true,
          needTermsOfService: true,
          currentPrivacyVersion: currentPrivacyVersion,
          currentTermsVersion: currentTermsVersion,
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final privacyAccepted = data['privacy_policy_accepted'] ?? false;
      final termsAccepted = data['terms_of_service_accepted'] ?? false;
      final savedPrivacyVersion = data['privacy_policy_version'] ?? '';
      final savedTermsVersion = data['terms_of_service_version'] ?? '';

      // Проверяем версии
      final privacyValid = privacyAccepted && savedPrivacyVersion == currentPrivacyVersion;
      final termsValid = termsAccepted && savedTermsVersion == currentTermsVersion;

      return ConsentCheckResult(
        allValid: privacyValid && termsValid,
        needPrivacyPolicy: !privacyValid,
        needTermsOfService: !termsValid,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
        savedPrivacyVersion: savedPrivacyVersion.isEmpty ? null : savedPrivacyVersion,
        savedTermsVersion: savedTermsVersion.isEmpty ? null : savedTermsVersion,
      );
    } catch (e) {
      debugPrint('❌ Ошибка проверки Firebase согласий: $e');
      return ConsentCheckResult(
        allValid: false,
        needPrivacyPolicy: true,
        needTermsOfService: true,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
      );
    }
  }

  /// Проверяет локальные согласия
  Future<ConsentCheckResult> _checkLocalConsents(
      String currentPrivacyVersion,
      String currentTermsVersion,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceAcceptedKey) ?? false;
      final savedPrivacyVersion = prefs.getString(_privacyPolicyVersionKey) ?? '';
      final savedTermsVersion = prefs.getString(_termsOfServiceVersionKey) ?? '';

      // Проверяем версии
      final privacyValid = privacyAccepted && savedPrivacyVersion == currentPrivacyVersion;
      final termsValid = termsAccepted && savedTermsVersion == currentTermsVersion;

      return ConsentCheckResult(
        allValid: privacyValid && termsValid,
        needPrivacyPolicy: !privacyValid,
        needTermsOfService: !termsValid,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
        savedPrivacyVersion: savedPrivacyVersion.isEmpty ? null : savedPrivacyVersion,
        savedTermsVersion: savedTermsVersion.isEmpty ? null : savedTermsVersion,
      );
    } catch (e) {
      debugPrint('❌ Ошибка проверки локальных согласий: $e');
      return ConsentCheckResult(
        allValid: false,
        needPrivacyPolicy: true,
        needTermsOfService: true,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
      );
    }
  }

  /// ✅ УПРОЩЕННЫЙ: Селективное сохранение согласий (только измененные документы)
  Future<bool> saveSelectiveConsents({
    bool? privacyPolicyAccepted,
    bool? termsOfServiceAccepted,
    String? languageCode,
  }) async {
    try {
      languageCode ??= 'ru';
      final prefs = await SharedPreferences.getInstance();

      // Если принимается политика конфиденциальности
      if (privacyPolicyAccepted == true) {
        final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
        await prefs.setBool(_privacyPolicyAcceptedKey, true);
        await prefs.setString(_privacyPolicyVersionKey, currentPrivacyVersion);
        debugPrint('✅ Политика конфиденциальности принята: версия $currentPrivacyVersion');
      }

      // Если принимается пользовательское соглашение
      if (termsOfServiceAccepted == true) {
        final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);
        await prefs.setBool(_termsOfServiceAcceptedKey, true);
        await prefs.setString(_termsOfServiceVersionKey, currentTermsVersion);
        debugPrint('✅ Пользовательское соглашение принято: версия $currentTermsVersion');
      }

      // Обновляем общие данные
      await prefs.setString('consent_timestamp', DateTime.now().toIso8601String());
      await prefs.setString('consent_language', languageCode);

      // Сохраняем в Firebase если пользователь авторизован
      if (_firebaseService.isUserLoggedIn) {
        await _saveSelectiveConsentsToFirestore(
          privacyPolicyAccepted,
          termsOfServiceAccepted,
          languageCode,
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при селективном сохранении согласий: $e');
      return false;
    }
  }

  /// Сохраняет согласия в Firebase
  Future<void> _saveSelectiveConsentsToFirestore(
      bool? privacyAccepted,
      bool? termsAccepted,
      String languageCode,
      ) async {
    try {
      Map<String, dynamic> updateData = {
        'consent_language': languageCode,
        'consent_timestamp': FieldValue.serverTimestamp(),
      };

      if (privacyAccepted == true) {
        final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
        updateData.addAll({
          'privacy_policy_accepted': true,
          'privacy_policy_version': currentPrivacyVersion,
        });
      }

      if (termsAccepted == true) {
        final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);
        updateData.addAll({
          'terms_of_service_accepted': true,
          'terms_of_service_version': currentTermsVersion,
        });
      }

      await _firebaseService.updateUserConsents(updateData);
      debugPrint('✅ Селективные согласия сохранены в Firebase');
    } catch (e) {
      debugPrint('❌ Ошибка при селективном сохранении согласий в Firebase: $e');
    }
  }

  /// Синхронизирует согласия из Firebase
  Future<void> syncConsentsFromFirestore() async {
    try {
      if (!_firebaseService.isUserLoggedIn) {
        debugPrint('❌ Пользователь не авторизован для синхронизации');
        return;
      }

      final doc = await _firebaseService.getUserConsents();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final privacyAccepted = data['privacy_policy_accepted'] ?? false;
        final termsAccepted = data['terms_of_service_accepted'] ?? false;
        final privacyVersion = data['privacy_policy_version'] ?? '';
        final termsVersion = data['terms_of_service_version'] ?? '';
        final consentLanguage = data['consent_language'] ?? 'ru';

        // Обновляем локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_privacyPolicyAcceptedKey, privacyAccepted);
        await prefs.setBool(_termsOfServiceAcceptedKey, termsAccepted);
        await prefs.setString(_privacyPolicyVersionKey, privacyVersion);
        await prefs.setString(_termsOfServiceVersionKey, termsVersion);
        await prefs.setString('consent_language', consentLanguage);

        debugPrint('✅ Согласия синхронизированы из Firebase');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации согласий: $e');
    }
  }

  /// Очищает все согласия (для выхода из аккаунта)
  Future<void> clearAllConsents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_privacyPolicyAcceptedKey);
      await prefs.remove(_termsOfServiceAcceptedKey);
      await prefs.remove(_privacyPolicyVersionKey);
      await prefs.remove(_termsOfServiceVersionKey);
      await prefs.remove('consent_timestamp');
      await prefs.remove('consent_language');

      // Очищаем кэш
      _cachedPrivacyPolicyVersion = null;
      _cachedTermsOfServiceVersion = null;

      debugPrint('✅ Все согласия очищены');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке согласий: $e');
    }
  }

  /// ✅ УПРОЩЕННЫЙ: Получает статус согласий пользователя
  Future<UserConsentStatus> getUserConsentStatus([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceAcceptedKey) ?? false;
      final savedPrivacyVersion = prefs.getString(_privacyPolicyVersionKey);
      final savedTermsVersion = prefs.getString(_termsOfServiceVersionKey);
      final consentTimestampStr = prefs.getString('consent_timestamp');
      final consentLanguage = prefs.getString('consent_language');

      final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
      final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);

      final isPrivacyVersionCurrent = savedPrivacyVersion == currentPrivacyVersion;
      final isTermsVersionCurrent = savedTermsVersion == currentTermsVersion;

      DateTime? consentTimestamp;
      if (consentTimestampStr != null) {
        try {
          consentTimestamp = DateTime.parse(consentTimestampStr);
        } catch (e) {
          debugPrint('❌ Ошибка парсинга времени согласия: $e');
        }
      }

      return UserConsentStatus(
        privacyPolicyAccepted: privacyAccepted,
        termsOfServiceAccepted: termsAccepted,
        consentVersion: '$currentPrivacyVersion-$currentTermsVersion',
        consentTimestamp: consentTimestamp,
        consentLanguage: consentLanguage,
        isVersionCurrent: isPrivacyVersionCurrent && isTermsVersionCurrent,
        currentVersion: '$currentPrivacyVersion-$currentTermsVersion',
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения статуса согласий: $e');
      return const UserConsentStatus(
        privacyPolicyAccepted: false,
        termsOfServiceAccepted: false,
        isVersionCurrent: false,
      );
    }
  }

  /// ✅ ОБРАТНАЯ СОВМЕСТИМОСТЬ: старый метод для существующего кода
  Future<bool> hasUserAcceptedAllConsents([String? languageCode]) async {
    final result = await checkUserConsents(languageCode);
    return result.allValid;
  }

  /// ✅ ОБРАТНАЯ СОВМЕСТИМОСТЬ: Сохранение согласий (полное)
  Future<bool> saveUserConsents({
    required bool privacyPolicyAccepted,
    required bool termsOfServiceAccepted,
    String? languageCode,
  }) async {
    if (!privacyPolicyAccepted || !termsOfServiceAccepted) {
      debugPrint('❌ Не все согласия приняты');
      return false;
    }

    return await saveSelectiveConsents(
      privacyPolicyAccepted: privacyPolicyAccepted,
      termsOfServiceAccepted: termsOfServiceAccepted,
      languageCode: languageCode,
    );
  }

  /// ✅ ОБРАТНАЯ СОВМЕСТИМОСТЬ: Проверка нового Google пользователя
  Future<bool> isNewGoogleUser() async {
    try {
      if (!_firebaseService.isUserLoggedIn) {
        return true;
      }

      final doc = await _firebaseService.getUserConsents();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final hasConsents = data['privacy_policy_accepted'] == true &&
            data['terms_of_service_accepted'] == true;
        return !hasConsents;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке нового пользователя: $e');
      return true;
    }
  }
}