// Путь: lib/services/user_consent_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_consent_models.dart';

/// Сервис для управления согласиями пользователя
class UserConsentService {
  static final UserConsentService _instance = UserConsentService._internal();
  factory UserConsentService() => _instance;
  UserConsentService._internal();

  static const String _privacyPolicyKey = 'privacy_policy_accepted';
  static const String _termsOfServiceKey = 'terms_of_service_accepted';
  static const String _userConsentVersionKey = 'user_consent_version';
  static const String _privacyPolicyHashKey = 'privacy_policy_hash';
  static const String _termsOfServiceHashKey = 'terms_of_service_hash';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Кэш для версий и хешей файлов
  String? _cachedPrivacyPolicyVersion;
  String? _cachedTermsOfServiceVersion;
  String? _cachedPrivacyPolicyHash;
  String? _cachedTermsOfServiceHash;

  /// Извлекает версию из первой строки файла (УПРОЩЕННАЯ ВЕРСИЯ БЕЗ ДАТ)
  String _extractVersionFromContent(String content) {
    try {
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines[0].trim();

        // Ищем только версию (русский) - БЕЗ ДНЕЙ
        RegExp versionRuPattern = RegExp(r'[Вв]ерсия\s*:\s*(\d+\.\d+(?:\.\d+)?)', caseSensitive: false);
        var match = versionRuPattern.firstMatch(firstLine);
        if (match != null && match.group(1) != null) {
          debugPrint('📄 Найдена версия (RU): ${match.group(1)}');
          return match.group(1)!;
        }

        // Ищем только версию (английский) - БЕЗ ДАТ
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

    // Если ничего не найдено, возвращаем дефолтную версию
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

  /// Получает текущую версию согласий из файлов (УПРОЩЕННАЯ ВЕРСИЯ)
  Future<String> getCurrentConsentVersion([String? languageCode]) async {
    languageCode ??= 'ru'; // По умолчанию русский

    try {
      // Загружаем информацию о обоих файлах
      final privacyInfo = await _loadPrivacyPolicyInfo(languageCode);
      final termsInfo = await _loadTermsOfServiceInfo(languageCode);

      // Кэшируем результаты
      _cachedPrivacyPolicyVersion = privacyInfo['version'];
      _cachedTermsOfServiceVersion = termsInfo['version'];
      _cachedPrivacyPolicyHash = privacyInfo['hash'];
      _cachedTermsOfServiceHash = termsInfo['hash'];

      // Используем только версию политики конфиденциальности как основную
      // (или можно комбинировать, если нужно: privacy_version-terms_version)
      final mainVersion = privacyInfo['version']!;
      debugPrint('🔗 Текущая версия документов: $mainVersion');

      return mainVersion;
    } catch (e) {
      debugPrint('❌ Ошибка получения версии согласий: $e');
      return '1.0.0';
    }
  }

  /// ГЛАВНЫЙ МЕТОД: Проверяет, принял ли пользователь все необходимые соглашения
  Future<bool> hasUserAcceptedAllConsents([String? languageCode]) async {
    try {
      languageCode ??= 'ru';

      // Получаем текущую версию из файлов
      final currentVersion = await getCurrentConsentVersion(languageCode);
      debugPrint('📋 Текущая версия документов: $currentVersion');

      final user = _auth.currentUser;

      if (user != null) {
        // Для авторизованного пользователя проверяем И Firebase И локальные данные
        debugPrint('👤 Проверяем согласия для авторизованного пользователя: ${user.uid}');

        // Проверяем Firebase
        final firebaseValid = await _checkFirebaseConsents(user.uid, currentVersion);
        debugPrint('🔍 Firebase согласия валидны: $firebaseValid');

        if (!firebaseValid) {
          debugPrint('❌ В Firebase нет валидных согласий, очищаем локальные данные');
          await clearAllConsents();
          return false;
        }

        // Если Firebase согласия валидны, проверяем локальные
        final localValid = await _checkLocalConsents(currentVersion);
        debugPrint('🔍 Локальные согласия валидны: $localValid');

        if (!localValid) {
          debugPrint('🔄 Синхронизируем согласия из Firebase в локальное хранилище');
          await syncConsentsFromFirestore(user.uid);

          // Проверяем еще раз после синхронизации
          final localValidAfterSync = await _checkLocalConsents(currentVersion);
          debugPrint('🔍 Локальные согласия после синхронизации: $localValidAfterSync');
          return localValidAfterSync;
        }

        return true;

      } else {
        // Для неавторизованного пользователя проверяем только локальные данные
        debugPrint('👤 Проверяем согласия для неавторизованного пользователя');
        return await _checkLocalConsents(currentVersion);
      }

    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      return false;
    }
  }

  /// Проверяет согласия в Firebase
  Future<bool> _checkFirebaseConsents(String userId, String currentVersion) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();

      if (!doc.exists) {
        debugPrint('📄 Документ согласий не найден в Firebase для пользователя: $userId');
        return false;
      }

      final data = doc.data()!;
      final privacyAccepted = data['privacy_policy_accepted'] ?? false;
      final termsAccepted = data['terms_of_service_accepted'] ?? false;
      final savedVersion = data['consent_version'] ?? '';

      debugPrint('🔍 Firebase: Privacy=$privacyAccepted, Terms=$termsAccepted, Version=$savedVersion');

      final isValid = privacyAccepted && termsAccepted && savedVersion == currentVersion;
      debugPrint('🔍 Firebase согласия валидны: $isValid');

      return isValid;

    } catch (e) {
      debugPrint('❌ Ошибка проверки Firebase согласий: $e');
      return false;
    }
  }

  /// Проверяет локальные согласия
  Future<bool> _checkLocalConsents(String currentVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceKey) ?? false;
      final savedVersion = prefs.getString(_userConsentVersionKey) ?? '';

      debugPrint('🔍 Локальные: Privacy=$privacyAccepted, Terms=$termsAccepted, Version=$savedVersion');

      final isValid = privacyAccepted && termsAccepted && savedVersion == currentVersion;
      debugPrint('🔍 Локальные согласия валидны: $isValid');

      return isValid;

    } catch (e) {
      debugPrint('❌ Ошибка проверки локальных согласий: $e');
      return false;
    }
  }

  /// Сохраняет согласия пользователя локально и в Firestore
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

      // Получаем текущую версию из файлов
      final currentVersion = await getCurrentConsentVersion(languageCode);

      // Сохраняем локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyPolicyKey, privacyPolicyAccepted);
      await prefs.setBool(_termsOfServiceKey, termsOfServiceAccepted);
      await prefs.setString(_userConsentVersionKey, currentVersion);
      await prefs.setString('consent_timestamp', DateTime.now().toIso8601String());
      await prefs.setString('consent_language', languageCode);

      // Сохраняем хеши файлов для отслеживания изменений
      if (_cachedPrivacyPolicyHash != null) {
        await prefs.setString(_privacyPolicyHashKey, _cachedPrivacyPolicyHash!);
      }
      if (_cachedTermsOfServiceHash != null) {
        await prefs.setString(_termsOfServiceHashKey, _cachedTermsOfServiceHash!);
      }

      debugPrint('✅ Согласия сохранены локально с версией: $currentVersion');

      // Сохраняем в Firestore если пользователь авторизован
      final user = _auth.currentUser;
      if (user != null) {
        await _saveConsentsToFirestore(
          user.uid,
          privacyPolicyAccepted,
          termsOfServiceAccepted,
          currentVersion,
          languageCode,
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий: $e');
      return false;
    }
  }

  /// Сохраняет согласия в Firestore
  Future<void> _saveConsentsToFirestore(
      String userId,
      bool privacyAccepted,
      bool termsAccepted,
      String version,
      String languageCode,
      ) async {
    try {
      await _firestore.collection('user_consents').doc(userId).set({
        'privacy_policy_accepted': privacyAccepted,
        'terms_of_service_accepted': termsAccepted,
        'consent_version': version,
        'consent_language': languageCode,
        'consent_timestamp': FieldValue.serverTimestamp(),
        'user_id': userId,
        'privacy_policy_version': _cachedPrivacyPolicyVersion,
        'terms_of_service_version': _cachedTermsOfServiceVersion,
        'privacy_policy_hash': _cachedPrivacyPolicyHash,
        'terms_of_service_hash': _cachedTermsOfServiceHash,
      }, SetOptions(merge: true));

      debugPrint('✅ Согласия сохранены в Firestore для пользователя: $userId');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий в Firestore: $e');
      // Не бросаем ошибку, так как локальное сохранение уже прошло успешно
    }
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

  /// Проверяет, является ли пользователь новым (впервые входящим через Google)
  Future<bool> isNewGoogleUser(String userId) async {
    try {
      // Проверяем есть ли данные о согласиях в Firestore
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
      // В случае ошибки считаем пользователя новым для безопасности
      return true;
    }
  }

  /// Синхронизирует согласия из Firestore в локальное хранилище
  Future<void> syncConsentsFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final privacyAccepted = data?['privacy_policy_accepted'] ?? false;
        final termsAccepted = data?['terms_of_service_accepted'] ?? false;
        final consentVersion = data?['consent_version'] ?? '';
        final consentLanguage = data?['consent_language'] ?? 'ru';
        final consentTimestamp = data?['consent_timestamp'];

        // Обновляем локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_privacyPolicyKey, privacyAccepted);
        await prefs.setBool(_termsOfServiceKey, termsAccepted);
        await prefs.setString(_userConsentVersionKey, consentVersion);
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

        debugPrint('✅ Согласия синхронизированы из Firestore');
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
      await prefs.remove(_privacyPolicyKey);
      await prefs.remove(_termsOfServiceKey);
      await prefs.remove(_userConsentVersionKey);
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

  /// Проверяет актуальность версии согласий
  Future<bool> isConsentVersionCurrent([String? languageCode]) async {
    try {
      languageCode ??= 'ru';
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_userConsentVersionKey) ?? '';
      final currentVersion = await getCurrentConsentVersion(languageCode);

      final isCurrent = savedVersion == currentVersion;
      debugPrint('📋 Проверка актуальности: сохранена=$savedVersion, текущая=$currentVersion, актуальна=$isCurrent');

      return isCurrent;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке версии согласий: $e');
      return false;
    }
  }

  /// Получает статус согласий пользователя
  Future<UserConsentStatus> getUserConsentStatus([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceKey) ?? false;
      final savedVersion = prefs.getString(_userConsentVersionKey);
      final consentTimestampStr = prefs.getString('consent_timestamp');
      final consentLanguage = prefs.getString('consent_language');

      final currentVersion = await getCurrentConsentVersion(languageCode);
      final isVersionCurrent = savedVersion == currentVersion;

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
        consentVersion: savedVersion,
        consentTimestamp: consentTimestamp,
        consentLanguage: consentLanguage,
        isVersionCurrent: isVersionCurrent,
        currentVersion: currentVersion,
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

  /// Получает текущую версию политики конфиденциальности
  Future<String> getCurrentPrivacyPolicyVersion([String? languageCode]) async {
    languageCode ??= 'ru';

    try {
      final privacyInfo = await _loadPrivacyPolicyInfo(languageCode);
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
      return termsInfo['version'] ?? '1.0.0';
    } catch (e) {
      debugPrint('❌ Ошибка получения версии пользовательского соглашения: $e');
      return '1.0.0';
    }
  }

  /// Получает историю версий политики конфиденциальности (НОВЫЙ МЕТОД)
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
        description: languageCode == 'ru'
            ? 'Текущая версия политики конфиденциальности'
            : 'Current version of privacy policy',
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
            description: languageCode == 'ru'
                ? 'Архивная версия $version'
                : 'Archived version $version',
            isCurrent: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения истории политики конфиденциальности: $e');
    }

    return history;
  }

  /// Получает историю версий пользовательского соглашения (НОВЫЙ МЕТОД)
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
        description: languageCode == 'ru'
            ? 'Текущая версия пользовательского соглашения'
            : 'Current version of terms of service',
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
            description: languageCode == 'ru'
                ? 'Архивная версия $version'
                : 'Archived version $version',
            isCurrent: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения истории пользовательского соглашения: $e');
    }

    return history;
  }

  /// Получает информацию о текущих версиях документов
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
        'current_version': privacyInfo['version'], // Используем основную версию
        'language': languageCode,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о версиях: $e');
      return {};
    }
  }
}