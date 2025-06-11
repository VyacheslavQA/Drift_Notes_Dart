// Путь: lib/services/user_consent_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_consent_models.dart';

/// Результат проверки согласий - что именно нужно принять
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

/// Сервис для управления согласиями пользователя с раздельным отслеживанием версий
class UserConsentService {
  static final UserConsentService _instance = UserConsentService._internal();
  factory UserConsentService() => _instance;
  UserConsentService._internal();

  // Ключи для локального хранения
  static const String _privacyPolicyAcceptedKey = 'privacy_policy_accepted';
  static const String _termsOfServiceAcceptedKey = 'terms_of_service_accepted';
  static const String _privacyPolicyVersionKey = 'privacy_policy_version';
  static const String _termsOfServiceVersionKey = 'terms_of_service_version';
  static const String _privacyPolicyHashKey = 'privacy_policy_hash';
  static const String _termsOfServiceHashKey = 'terms_of_service_hash';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Кэш для версий и хешей файлов
  String? _cachedPrivacyPolicyVersion;
  String? _cachedTermsOfServiceVersion;
  String? _cachedPrivacyPolicyHash;
  String? _cachedTermsOfServiceHash;

  /// НОВЫЙ МЕТОД: Получение локализованного описания
  String _getLocalizedDescription(String type, String version, String languageCode, bool isCurrent) {
    if (languageCode == 'ru') {
      if (type == 'privacy_policy') {
        return isCurrent
            ? 'Текущая версия политики конфиденциальности'
            : 'Архивная версия $version';
      } else {
        return isCurrent
            ? 'Текущая версия пользовательского соглашения'
            : 'Архивная версия $version';
      }
    } else {
      // Английский
      if (type == 'privacy_policy') {
        return isCurrent
            ? 'Current version of privacy policy'
            : 'Archived version $version';
      } else {
        return isCurrent
            ? 'Current version of terms of service'
            : 'Archived version $version';
      }
    }
  }

  /// Извлекает версию из первой строки файла
  String _extractVersionFromContent(String content) {
    try {
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines[0].trim();

        // Ищем версию (русский)
        RegExp versionRuPattern = RegExp(r'[Вв]ерсия\s*:\s*(\d+\.\d+(?:\.\d+)?)', caseSensitive: false);
        var match = versionRuPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          debugPrint('📄 Найдена версия (RU): ${match.group(1)}');
          return match.group(1)!;
        }

        // Ищем версию (английский)
        RegExp versionEnPattern = RegExp(r'[Vv]ersion\s*:\s*(\d+\.\d+(?:\.\d+)?)', caseSensitive: false);
        match = versionEnPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          debugPrint('📄 Найдена версия (EN): ${match.group(1)}');
          return match.group(1)!;
        }

        // Ищем любые цифры как версию
        RegExp numbersPattern = RegExp(r'(\d+\.\d+(?:\.\d+)?)');
        match = numbersPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          debugPrint('📄 Найдены цифры как версия: ${match.group(1)}');
          return match.group(1)!;
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка извлечения версии: $e');
    }

    debugPrint('⚠️ Версия не найдена, используется дефолтная: 1.0.0');
    return '1.0.0';
  }

  /// Генерирует хеш содержимого файла
  String _generateContentHash(String content) {
    final bytes = utf8.encode(content.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Загружает и анализирует файл политики конфиденциальности
  Future<Map<String, String>> _loadPrivacyPolicyInfo(String languageCode) async {
    try {
      final fileName = 'assets/privacy_policy/privacy_policy_$languageCode.txt';
      String content;

      try {
        content = await rootBundle.loadString(fileName);
      } catch (e) {
        debugPrint('❌ Не удалось загрузить $fileName, загружаем английскую версию');
        content = await rootBundle.loadString('assets/privacy_policy/privacy_policy_en.txt');
      }

      final version = _extractVersionFromContent(content);
      final hash = _generateContentHash(content);

      debugPrint('📄 Политика конфиденциальности: версия=$version, хеш=${hash.substring(0, 8)}');

      return {
        'version': version,
        'hash': hash,
        'content': content,
      };
    } catch (e) {
      debugPrint('❌ Ошибка загрузки политики конфиденциальности: $e');
      return {
        'version': '1.0.0',
        'hash': 'unknown',
        'content': '',
      };
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
        debugPrint('❌ Не удалось загрузить $fileName, загружаем английскую версию');
        content = await rootBundle.loadString('assets/terms_of_service/terms_of_service_en.txt');
      }

      final version = _extractVersionFromContent(content);
      final hash = _generateContentHash(content);

      debugPrint('📄 Пользовательское соглашение: версия=$version, хеш=${hash.substring(0, 8)}');

      return {
        'version': version,
        'hash': hash,
        'content': content,
      };
    } catch (e) {
      debugPrint('❌ Ошибка загрузки пользовательского соглашения: $e');
      return {
        'version': '1.0.0',
        'hash': 'unknown',
        'content': '',
      };
    }
  }

  /// Получает текущую версию политики конфиденциальности
  Future<String> getCurrentPrivacyPolicyVersion([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final privacyInfo = await _loadPrivacyPolicyInfo(languageCode);
      _cachedPrivacyPolicyVersion = privacyInfo['version'];
      _cachedPrivacyPolicyHash = privacyInfo['hash'];
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
      _cachedTermsOfServiceHash = termsInfo['hash'];
      return termsInfo['version'] ?? '1.0.0';
    } catch (e) {
      debugPrint('❌ Ошибка получения версии пользовательского соглашения: $e');
      return '1.0.0';
    }
  }

  /// ГЛАВНЫЙ МЕТОД: Проверяет согласия и возвращает что именно нужно принять
  Future<ConsentCheckResult> checkUserConsents([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      // Получаем текущие версии из файлов
      final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
      final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);

      debugPrint('📋 Текущие версии: Privacy=$currentPrivacyVersion, Terms=$currentTermsVersion');

      final user = _auth.currentUser;

      if (user != null) {
        // Для авторизованного пользователя проверяем Firebase и локальные данные
        debugPrint('👤 Проверяем согласия для авторизованного пользователя: ${user.uid}');

        // Сначала проверяем Firebase
        final firebaseResult = await _checkFirebaseConsents(
            user.uid,
            currentPrivacyVersion,
            currentTermsVersion
        );

        // Если в Firebase что-то не так, очищаем локальные данные
        if (!firebaseResult.allValid) {
          debugPrint('❌ Firebase согласия неактуальны, очищаем локальные данные');
          await clearAllConsents();
          return firebaseResult;
        }

        // Проверяем локальные данные
        final localResult = await _checkLocalConsents(
            currentPrivacyVersion,
            currentTermsVersion
        );

        // Если локальные данные неактуальны, синхронизируем из Firebase
        if (!localResult.allValid) {
          debugPrint('🔄 Синхронизируем согласия из Firebase в локальное хранилище');
          await syncConsentsFromFirestore(user.uid);

          // Проверяем еще раз после синхронизации
          return await _checkLocalConsents(currentPrivacyVersion, currentTermsVersion);
        }

        return localResult;

      } else {
        // Для неавторизованного пользователя проверяем только локальные данные
        debugPrint('👤 Проверяем согласия для неавторизованного пользователя');
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

  /// Проверяет согласия в Firebase (раздельно)
  Future<ConsentCheckResult> _checkFirebaseConsents(
      String userId,
      String currentPrivacyVersion,
      String currentTermsVersion
      ) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();

      if (!doc.exists) {
        debugPrint('📄 Документ согласий не найден в Firebase для пользователя: $userId');
        return ConsentCheckResult(
          allValid: false,
          needPrivacyPolicy: true,
          needTermsOfService: true,
          currentPrivacyVersion: currentPrivacyVersion,
          currentTermsVersion: currentTermsVersion,
        );
      }

      final data = doc.data()!;
      final privacyAccepted = data['privacy_policy_accepted'] ?? false;
      final termsAccepted = data['terms_of_service_accepted'] ?? false;
      final savedPrivacyVersion = data['privacy_policy_version'] ?? '';
      final savedTermsVersion = data['terms_of_service_version'] ?? '';

      debugPrint('🔍 Firebase: Privacy($privacyAccepted, $savedPrivacyVersion), Terms($termsAccepted, $savedTermsVersion)');

      // Раздельная проверка версий
      final privacyValid = privacyAccepted && savedPrivacyVersion == currentPrivacyVersion;
      final termsValid = termsAccepted && savedTermsVersion == currentTermsVersion;

      final result = ConsentCheckResult(
        allValid: privacyValid && termsValid,
        needPrivacyPolicy: !privacyValid,
        needTermsOfService: !termsValid,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
        savedPrivacyVersion: savedPrivacyVersion.isEmpty ? null : savedPrivacyVersion,
        savedTermsVersion: savedTermsVersion.isEmpty ? null : savedTermsVersion,
      );

      debugPrint('🔍 Firebase результат: $result');
      return result;

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

  /// Проверяет локальные согласия (раздельно)
  Future<ConsentCheckResult> _checkLocalConsents(
      String currentPrivacyVersion,
      String currentTermsVersion
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceAcceptedKey) ?? false;
      final savedPrivacyVersion = prefs.getString(_privacyPolicyVersionKey) ?? '';
      final savedTermsVersion = prefs.getString(_termsOfServiceVersionKey) ?? '';

      debugPrint('🔍 Локальные: Privacy($privacyAccepted, $savedPrivacyVersion), Terms($termsAccepted, $savedTermsVersion)');

      // Раздельная проверка версий
      final privacyValid = privacyAccepted && savedPrivacyVersion == currentPrivacyVersion;
      final termsValid = termsAccepted && savedTermsVersion == currentTermsVersion;

      final result = ConsentCheckResult(
        allValid: privacyValid && termsValid,
        needPrivacyPolicy: !privacyValid,
        needTermsOfService: !termsValid,
        currentPrivacyVersion: currentPrivacyVersion,
        currentTermsVersion: currentTermsVersion,
        savedPrivacyVersion: savedPrivacyVersion.isEmpty ? null : savedPrivacyVersion,
        savedTermsVersion: savedTermsVersion.isEmpty ? null : savedTermsVersion,
      );

      debugPrint('🔍 Локальный результат: $result');
      return result;

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

  /// ОБРАТНАЯ СОВМЕСТИМОСТЬ: старый метод для существующего кода
  Future<bool> hasUserAcceptedAllConsents([String? languageCode]) async {
    final result = await checkUserConsents(languageCode);
    return result.allValid;
  }

  /// Сохраняет согласия пользователя (теперь раздельно!)
  Future<bool> saveUserConsents({
    required bool privacyPolicyAccepted,
    required bool termsOfServiceAccepted,
    String? languageCode,
  }) async {
    try {
      languageCode ??= 'ru';

      // Проверяем что оба согласия приняты
      if (!privacyPolicyAccepted || !termsOfServiceAccepted) {
        debugPrint('❌ Не все согласия приняты');
        return false;
      }

      // Получаем текущие версии из файлов
      final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
      final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);

      // Сохраняем локально (РАЗДЕЛЬНО!)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyPolicyAcceptedKey, privacyPolicyAccepted);
      await prefs.setBool(_termsOfServiceAcceptedKey, termsOfServiceAccepted);
      await prefs.setString(_privacyPolicyVersionKey, currentPrivacyVersion);
      await prefs.setString(_termsOfServiceVersionKey, currentTermsVersion);
      await prefs.setString('consent_timestamp', DateTime.now().toIso8601String());
      await prefs.setString('consent_language', languageCode);

      // Сохраняем хеши файлов для отслеживания изменений
      if (_cachedPrivacyPolicyHash != null) {
        await prefs.setString(_privacyPolicyHashKey, _cachedPrivacyPolicyHash!);
      }
      if (_cachedTermsOfServiceHash != null) {
        await prefs.setString(_termsOfServiceHashKey, _cachedTermsOfServiceHash!);
      }

      debugPrint('✅ Согласия сохранены локально: Privacy=$currentPrivacyVersion, Terms=$currentTermsVersion');

      // Сохраняем в Firestore если пользователь авторизован
      final user = _auth.currentUser;
      if (user != null) {
        await _saveConsentsToFirestore(
          user.uid,
          privacyPolicyAccepted,
          termsOfServiceAccepted,
          currentPrivacyVersion,
          currentTermsVersion,
          languageCode,
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий: $e');
      return false;
    }
  }

  /// Селективное сохранение согласий (только измененные документы)
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

        if (_cachedPrivacyPolicyHash != null) {
          await prefs.setString(_privacyPolicyHashKey, _cachedPrivacyPolicyHash!);
        }

        debugPrint('✅ Политика конфиденциальности принята: версия $currentPrivacyVersion');
      }

      // Если принимается пользовательское соглашение
      if (termsOfServiceAccepted == true) {
        final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);
        await prefs.setBool(_termsOfServiceAcceptedKey, true);
        await prefs.setString(_termsOfServiceVersionKey, currentTermsVersion);

        if (_cachedTermsOfServiceHash != null) {
          await prefs.setString(_termsOfServiceHashKey, _cachedTermsOfServiceHash!);
        }

        debugPrint('✅ Пользовательское соглашение принято: версия $currentTermsVersion');
      }

      // Обновляем общие данные
      await prefs.setString('consent_timestamp', DateTime.now().toIso8601String());
      await prefs.setString('consent_language', languageCode);

      // Сохраняем в Firestore если пользователь авторизован
      final user = _auth.currentUser;
      if (user != null) {
        await _saveSelectiveConsentsToFirestore(
          user.uid,
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

  /// Сохраняет согласия в Firestore (раздельно)
  Future<void> _saveConsentsToFirestore(
      String userId,
      bool privacyAccepted,
      bool termsAccepted,
      String privacyVersion,
      String termsVersion,
      String languageCode,
      ) async {
    try {
      await _firestore.collection('user_consents').doc(userId).set({
        'privacy_policy_accepted': privacyAccepted,
        'terms_of_service_accepted': termsAccepted,
        'privacy_policy_version': privacyVersion,
        'terms_of_service_version': termsVersion,
        'consent_language': languageCode,
        'consent_timestamp': FieldValue.serverTimestamp(),
        'user_id': userId,
        'privacy_policy_hash': _cachedPrivacyPolicyHash,
        'terms_of_service_hash': _cachedTermsOfServiceHash,
      }, SetOptions(merge: true));

      debugPrint('✅ Согласия сохранены в Firestore для пользователя: $userId');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий в Firestore: $e');
    }
  }

  /// Селективное сохранение в Firestore
  Future<void> _saveSelectiveConsentsToFirestore(
      String userId,
      bool? privacyAccepted,
      bool? termsAccepted,
      String languageCode,
      ) async {
    try {
      Map<String, dynamic> updateData = {
        'consent_language': languageCode,
        'consent_timestamp': FieldValue.serverTimestamp(),
        'user_id': userId,
      };

      if (privacyAccepted == true) {
        final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
        updateData.addAll({
          'privacy_policy_accepted': true,
          'privacy_policy_version': currentPrivacyVersion,
          'privacy_policy_hash': _cachedPrivacyPolicyHash,
        });
      }

      if (termsAccepted == true) {
        final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);
        updateData.addAll({
          'terms_of_service_accepted': true,
          'terms_of_service_version': currentTermsVersion,
          'terms_of_service_hash': _cachedTermsOfServiceHash,
        });
      }

      await _firestore.collection('user_consents').doc(userId).set(
          updateData,
          SetOptions(merge: true)
      );

      debugPrint('✅ Селективные согласия сохранены в Firestore для пользователя: $userId');
    } catch (e) {
      debugPrint('❌ Ошибка при селективном сохранении согласий в Firestore: $e');
    }
  }

  /// Проверяет, является ли пользователь новым
  Future<bool> isNewGoogleUser(String userId) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final hasConsents = data?['privacy_policy_accepted'] == true &&
            data?['terms_of_service_accepted'] == true;
        debugPrint('🔍 Пользователь $userId имеет согласия в Firestore: $hasConsents');
        return !hasConsents;
      }

      debugPrint('🔍 Пользователь $userId не найден в Firestore - новый пользователь');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке нового пользователя: $e');
      return true;
    }
  }

  /// Синхронизирует согласия из Firestore в локальное хранилище (раздельно)
  Future<void> syncConsentsFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final privacyAccepted = data?['privacy_policy_accepted'] ?? false;
        final termsAccepted = data?['terms_of_service_accepted'] ?? false;
        final privacyVersion = data?['privacy_policy_version'] ?? '';
        final termsVersion = data?['terms_of_service_version'] ?? '';
        final consentLanguage = data?['consent_language'] ?? 'ru';
        final consentTimestamp = data?['consent_timestamp'];

        // Обновляем локальные данные (РАЗДЕЛЬНО!)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_privacyPolicyAcceptedKey, privacyAccepted);
        await prefs.setBool(_termsOfServiceAcceptedKey, termsAccepted);
        await prefs.setString(_privacyPolicyVersionKey, privacyVersion);
        await prefs.setString(_termsOfServiceVersionKey, termsVersion);
        await prefs.setString('consent_language', consentLanguage);

        if (consentTimestamp != null) {
          await prefs.setString('consent_timestamp', (consentTimestamp as Timestamp).toDate().toIso8601String());
        }

        // Также синхронизируем хеши если они есть
        if (data?['privacy_policy_hash'] != null) {
          await prefs.setString(_privacyPolicyHashKey, data!['privacy_policy_hash']);
        }
        if (data?['terms_of_service_hash'] != null) {
          await prefs.setString(_termsOfServiceHashKey, data!['terms_of_service_hash']);
        }

        debugPrint('✅ Согласия синхронизированы из Firestore: Privacy($privacyAccepted, $privacyVersion), Terms($termsAccepted, $termsVersion)');
      } else {
        debugPrint('❌ Документ согласий не найден в Firestore для синхронизации');
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
      await prefs.remove(_privacyPolicyHashKey);
      await prefs.remove(_termsOfServiceHashKey);
      await prefs.remove('consent_timestamp');
      await prefs.remove('consent_language');

      // Очищаем кэш
      _cachedPrivacyPolicyVersion = null;
      _cachedTermsOfServiceVersion = null;
      _cachedPrivacyPolicyHash = null;
      _cachedTermsOfServiceHash = null;

      debugPrint('✅ Все согласия очищены');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке согласий: $e');
    }
  }

  /// Получает статус согласий пользователя (обновленный)
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
        consentVersion: '$currentPrivacyVersion-$currentTermsVersion', // Комбинированная для совместимости
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

  /// УСТАРЕВШИЙ метод для обратной совместимости
  @deprecated
  Future<String> getCurrentConsentVersion([String? languageCode]) async {
    final privacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);
    final termsVersion = await getCurrentTermsOfServiceVersion(languageCode);
    return '${privacyVersion}_$termsVersion'; // Комбинированная версия
  }

  /// УСТАРЕВШИЙ метод для обратной совместимости
  @deprecated
  Future<bool> isConsentVersionCurrent([String? languageCode]) async {
    final result = await checkUserConsents(languageCode);
    return result.allValid;
  }

  /// Ищет архивные версии политики конфиденциальности
  Future<List<String>> _findArchivedPrivacyVersions(String languageCode) async {
    List<String> versions = [];

    // Начинаем поиск с версии 1.0.0 и идем вверх
    for (int major = 1; major <= 10; major++) {
      for (int minor = 0; minor <= 20; minor++) {
        for (int patch = 0; patch <= 10; patch++) {
          final version = '$major.$minor.$patch';
          final fileName = 'assets/privacy_policy/privacy_policy_${languageCode}_v$version.txt';

          try {
            await rootBundle.loadString(fileName);
            versions.add(version);
            debugPrint('📦 Найдена архивная версия политики: $version');
          } catch (e) {
            // Файл не существует, продолжаем поиск
          }

          // Если несколько версий подряд не найдены, переходим к следующему minor
          if (patch > 5 && versions.isEmpty) break;
        }
        // Если несколько minor версий подряд не найдены, переходим к следующему major
        if (minor > 10 && versions.where((v) => v.startsWith('$major.')).isEmpty) break;
      }
    }

    return versions..sort((a, b) => _compareVersions(b, a)); // Сортируем по убыванию
  }

  /// Ищет архивные версии пользовательского соглашения
  Future<List<String>> _findArchivedTermsVersions(String languageCode) async {
    List<String> versions = [];

    // Аналогичный поиск для terms of service
    for (int major = 1; major <= 10; major++) {
      for (int minor = 0; minor <= 20; minor++) {
        for (int patch = 0; patch <= 10; patch++) {
          final version = '$major.$minor.$patch';
          final fileName = 'assets/terms_of_service/terms_of_service_${languageCode}_v$version.txt';

          try {
            await rootBundle.loadString(fileName);
            versions.add(version);
            debugPrint('📦 Найдена архивная версия соглашения: $version');
          } catch (e) {
            // Файл не существует, продолжаем поиск
          }

          if (patch > 5 && versions.isEmpty) break;
        }
        if (minor > 10 && versions.where((v) => v.startsWith('$major.')).isEmpty) break;
      }
    }

    return versions..sort((a, b) => _compareVersions(b, a)); // Сортируем по убыванию
  }

  /// Сравнивает две версии (например, "1.2.0" и "1.1.5")
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part != v2Part) {
        return v1Part.compareTo(v2Part);
      }
    }

    return 0; // Версии равны
  }

  /// ИСПРАВЛЕНО: Получает историю версий политики конфиденциальности с локализацией
  Future<List<DocumentVersion>> getPrivacyPolicyHistory([String? languageCode]) async {
    languageCode ??= 'ru';
    List<DocumentVersion> history = [];

    try {
      // Добавляем текущую версию
      final currentVersion = await getCurrentPrivacyPolicyVersion(languageCode);
      history.add(DocumentVersion(
        version: currentVersion,
        releaseDate: DateTime.now(),
        documentType: 'privacy_policy',
        language: languageCode,
        description: _getLocalizedDescription('privacy_policy', currentVersion, languageCode, true),
        hash: _cachedPrivacyPolicyHash?.substring(0, 8),
        isCurrent: true,
      ));

      // Ищем архивные версии
      final archivedVersions = await _findArchivedPrivacyVersions(languageCode);
      for (final version in archivedVersions) {
        if (version != currentVersion) { // Не дублируем текущую версию
          history.add(DocumentVersion(
            version: version,
            releaseDate: DateTime.now(), // В реальности можно парсить из файла
            documentType: 'privacy_policy',
            language: languageCode,
            description: _getLocalizedDescription('privacy_policy', version, languageCode, false),
            isCurrent: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения истории политики конфиденциальности: $e');
    }

    return history;
  }

  /// ИСПРАВЛЕНО: Получает историю версий пользовательского соглашения с локализацией
  Future<List<DocumentVersion>> getTermsOfServiceHistory([String? languageCode]) async {
    languageCode ??= 'ru';
    List<DocumentVersion> history = [];

    try {
      // Добавляем текущую версию
      final currentVersion = await getCurrentTermsOfServiceVersion(languageCode);
      history.add(DocumentVersion(
        version: currentVersion,
        releaseDate: DateTime.now(),
        documentType: 'terms_of_service',
        language: languageCode,
        description: _getLocalizedDescription('terms_of_service', currentVersion, languageCode, true),
        hash: _cachedTermsOfServiceHash?.substring(0, 8),
        isCurrent: true,
      ));

      // Ищем архивные версии
      final archivedVersions = await _findArchivedTermsVersions(languageCode);
      for (final version in archivedVersions) {
        if (version != currentVersion) { // Не дублируем текущую версию
          history.add(DocumentVersion(
            version: version,
            releaseDate: DateTime.now(), // В реальности можно парсить из файла
            documentType: 'terms_of_service',
            language: languageCode,
            description: _getLocalizedDescription('terms_of_service', version, languageCode, false),
            isCurrent: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения истории пользовательского соглашения: $e');
    }

    return history;
  }

  /// Получает информацию о текущих версиях документов (обновленный)
  Future<Map<String, dynamic>> getDocumentVersionsInfo([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final privacyInfo = await _loadPrivacyPolicyInfo(languageCode);
      final termsInfo = await _loadTermsOfServiceInfo(languageCode);

      return {
        'privacy_policy': {
          'version': privacyInfo['version'],
          'hash': privacyInfo['hash']?.substring(0, 8),
        },
        'terms_of_service': {
          'version': termsInfo['version'],
          'hash': termsInfo['hash']?.substring(0, 8),
        },
        'language': languageCode,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о версиях: $e');
      return {};
    }
  }
}