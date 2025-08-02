// Путь: lib/services/user_consent_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/user_consent_models.dart';
import 'firebase/firebase_service.dart';

/// ✅ ПРОДАКШЕН результат проверки согласий
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

  bool get hasChanges => needPrivacyPolicy || needTermsOfService;

  /// Получить список устаревших политик для селективного показа
  List<String> get outdatedPolicies {
    List<String> outdated = [];
    debugPrint('🔍 ConsentCheckResult.outdatedPolicies:');
    debugPrint('   - needPrivacyPolicy: $needPrivacyPolicy');
    debugPrint('   - needTermsOfService: $needTermsOfService');

    if (needPrivacyPolicy) {
      outdated.add('privacy');
      debugPrint('   - добавляем privacy');
    }
    if (needTermsOfService) {
      outdated.add('terms');
      debugPrint('   - добавляем terms');
    }

    debugPrint('   - итоговый результат: $outdated');
    return outdated;
  }

  @override
  String toString() {
    return 'ConsentCheckResult(allValid: $allValid, needPrivacy: $needPrivacyPolicy, needTerms: $needTermsOfService, outdated: $outdatedPolicies)';
  }
}

/// ✅ ПРОДАКШЕН сервис для управления согласиями пользователя
/// БЕЗОПАСНО работает с существующими данными в Firebase
class UserConsentService {
  static final UserConsentService _instance = UserConsentService._internal();
  factory UserConsentService() => _instance;
  UserConsentService._internal();

  // Ключи для локального хранения (совместимость с существующим кодом)
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

  /// ✅ АВТОМАТИЧЕСКИЙ поиск последней версии файла политики
  Future<Map<String, String>> _loadPrivacyPolicyInfo(String languageCode) async {
    try {
      // Список версий для проверки (от новых к старым)
      final versionsToTry = [
        '2.0.0', '1.9.0', '1.8.0', '1.7.0', '1.6.0', '1.5.0', '1.4.0', '1.3.0', '1.2.0', '1.1.0', '1.0.0'
      ];

      String content = '';
      String foundVersion = '1.0.0';
      String usedFileName = '';

      // Пробуем загрузить файлы с версиями
      for (String version in versionsToTry) {
        final fileName = 'assets/privacy_policy/privacy_policy_${languageCode}_$version.txt';
        try {
          content = await rootBundle.loadString(fileName);
          usedFileName = fileName;
          debugPrint('✅ Найден файл с версией: $fileName');
          break;
        } catch (e) {
          debugPrint('🔍 Файл $fileName не найден, пробуем следующую версию...');
        }
      }

      // Если версионные файлы не найдены, пробуем базовый файл
      if (content.isEmpty) {
        try {
          final fileName = 'assets/privacy_policy/privacy_policy_$languageCode.txt';
          content = await rootBundle.loadString(fileName);
          usedFileName = fileName;
          debugPrint('✅ Загружен базовый файл: $fileName');
        } catch (e) {
          debugPrint('❌ Базовый файл не найден: $e');
          // Фоллбэк на английскую версию
          try {
            content = await rootBundle.loadString('assets/privacy_policy/privacy_policy_en.txt');
            usedFileName = 'privacy_policy_en.txt';
            debugPrint('✅ Загружен английский fallback файл');
          } catch (e2) {
            debugPrint('❌ Английский файл тоже не найден: $e2');
          }
        }
      }

      // Извлекаем версию из содержимого файла
      final extractedVersion = _extractVersionFromContent(content);
      foundVersion = extractedVersion.isNotEmpty ? extractedVersion : '1.0.0';

      debugPrint('📋 Результат загрузки Privacy Policy:');
      debugPrint('   - Использован файл: $usedFileName');
      debugPrint('   - Извлеченная версия: $foundVersion');

      return {'version': foundVersion, 'content': content};
    } catch (e) {
      debugPrint('❌ Ошибка загрузки политики конфиденциальности: $e');
      return {'version': '1.0.0', 'content': ''};
    }
  }

  /// ✅ АВТОМАТИЧЕСКИЙ поиск последней версии файла пользовательского соглашения
  Future<Map<String, String>> _loadTermsOfServiceInfo(String languageCode) async {
    try {
      // Список версий для проверки (от новых к старым)
      final versionsToTry = [
        '2.0.0', '1.9.0', '1.8.0', '1.7.0', '1.6.0', '1.5.0', '1.4.0', '1.3.0', '1.2.0', '1.1.0', '1.0.0'
      ];

      String content = '';
      String foundVersion = '1.0.0';
      String usedFileName = '';

      // Пробуем загрузить файлы с версиями
      for (String version in versionsToTry) {
        final fileName = 'assets/terms_of_service/terms_of_service_${languageCode}_$version.txt';
        try {
          content = await rootBundle.loadString(fileName);
          usedFileName = fileName;
          debugPrint('✅ Найден файл с версией: $fileName');
          break;
        } catch (e) {
          debugPrint('🔍 Файл $fileName не найден, пробуем следующую версию...');
        }
      }

      // Если версионные файлы не найдены, пробуем базовый файл
      if (content.isEmpty) {
        try {
          final fileName = 'assets/terms_of_service/terms_of_service_$languageCode.txt';
          content = await rootBundle.loadString(fileName);
          usedFileName = fileName;
          debugPrint('✅ Загружен базовый файл: $fileName');
        } catch (e) {
          debugPrint('❌ Базовый файл не найден: $e');
          // Фоллбэк на английскую версию
          try {
            content = await rootBundle.loadString('assets/terms_of_service/terms_of_service_en.txt');
            usedFileName = 'terms_of_service_en.txt';
            debugPrint('✅ Загружен английский fallback файл');
          } catch (e2) {
            debugPrint('❌ Английский файл тоже не найден: $e2');
          }
        }
      }

      // Извлекаем версию из содержимого файла
      final extractedVersion = _extractVersionFromContent(content);
      foundVersion = extractedVersion.isNotEmpty ? extractedVersion : '1.0.0';

      debugPrint('📋 Результат загрузки Terms of Service:');
      debugPrint('   - Использован файл: $usedFileName');
      debugPrint('   - Извлеченная версия: $foundVersion');

      return {'version': foundVersion, 'content': content};
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

  /// ✅ ПРОДАКШЕН: Проверяет согласия и возвращает что именно нужно принять
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

  /// ✅ ПРОДАКШЕН: Безопасная проверка Firebase с поддержкой обоих форматов
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

      // ✅ ПРОДАКШЕН: Поддержка обоих форматов полей (camelCase и snake_case)
      final privacyAccepted = data['privacyPolicyAccepted'] ??
          data['privacy_policy_accepted'] ?? false;
      final termsAccepted = data['termsOfServiceAccepted'] ??
          data['terms_of_service_accepted'] ?? false;
      final savedPrivacyVersion = data['privacyPolicyVersion'] ??
          data['privacy_policy_version'] ?? '';
      final savedTermsVersion = data['termsOfServiceVersion'] ??
          data['terms_of_service_version'] ?? '';

      debugPrint('📊 Firebase данные:');
      debugPrint('   Privacy: accepted=$privacyAccepted, version=$savedPrivacyVersion');
      debugPrint('   Terms: accepted=$termsAccepted, version=$savedTermsVersion');

      // Проверяем версии
      final privacyValid = privacyAccepted && savedPrivacyVersion == currentPrivacyVersion;
      final termsValid = termsAccepted && savedTermsVersion == currentTermsVersion;

      debugPrint('📊 Валидация версий:');
      debugPrint('   Privacy: $savedPrivacyVersion == $currentPrivacyVersion → valid=$privacyValid');
      debugPrint('   Terms: $savedTermsVersion == $currentTermsVersion → valid=$termsValid');
      debugPrint('   needPrivacyPolicy: ${!privacyValid}');
      debugPrint('   needTermsOfService: ${!termsValid}');

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

  /// ✅ ПРОДАКШЕН: Селективное сохранение с поддержкой существующего формата
  Future<bool> saveSelectiveConsents({
    bool? privacyPolicyAccepted,
    bool? termsOfServiceAccepted,
    String? languageCode,
    List<String>? outdatedPolicies,
  }) async {
    try {
      languageCode ??= 'ru';
      outdatedPolicies ??= [];

      final prefs = await SharedPreferences.getInstance();

      debugPrint('🔄 ПРОДАКШЕН: Селективное сохранение согласий');
      debugPrint('📋 Контекст устаревших политик: $outdatedPolicies');
      debugPrint('📋 Передано: Privacy=${privacyPolicyAccepted}, Terms=${termsOfServiceAccepted}');

      // Валидация параметров
      if (outdatedPolicies.isNotEmpty) {
        _validateSelectiveParameters(
          privacyPolicyAccepted,
          termsOfServiceAccepted,
          outdatedPolicies,
        );
      }

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

      // Записываем метрику обновления
      if (outdatedPolicies.isNotEmpty) {
        await prefs.setString('last_updated_policies', outdatedPolicies.join(','));
        debugPrint('📊 Метрика: обновлены политики ${outdatedPolicies.join(', ')}');
      }

      // Сохраняем в Firebase если пользователь авторизован
      if (_firebaseService.isUserLoggedIn) {
        await _saveSelectiveConsentsToFirestore(
          privacyPolicyAccepted,
          termsOfServiceAccepted,
          languageCode,
          outdatedPolicies,
        );
      }

      debugPrint('✅ ПРОДАКШЕН: Селективное сохранение завершено успешно');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при селективном сохранении согласий: $e');
      return false;
    }
  }

  /// Валидация параметров селективного сохранения
  void _validateSelectiveParameters(
      bool? privacyAccepted,
      bool? termsAccepted,
      List<String> outdatedPolicies,
      ) {
    for (String policy in outdatedPolicies) {
      switch (policy) {
        case 'privacy':
          if (privacyAccepted != true) {
            debugPrint('⚠️ Предупреждение: Privacy Policy устарела, но не передана для принятия');
          }
          break;
        case 'terms':
          if (termsAccepted != true) {
            debugPrint('⚠️ Предупреждение: Terms of Service устарели, но не переданы для принятия');
          }
          break;
        default:
          debugPrint('⚠️ Предупреждение: Неизвестная политика в outdatedPolicies: $policy');
      }
    }

    if (privacyAccepted == true && !outdatedPolicies.contains('privacy')) {
      debugPrint('⚠️ Предупреждение: Privacy Policy передана для принятия, но не указана как устаревшая');
    }
    if (termsAccepted == true && !outdatedPolicies.contains('terms')) {
      debugPrint('⚠️ Предупреждение: Terms of Service переданы для принятия, но не указаны как устаревшие');
    }
  }

  /// ✅ ПРОДАКШЕН: Безопасное сохранение в Firebase с поддержкой существующего формата
  Future<void> _saveSelectiveConsentsToFirestore(
      bool? privacyAccepted,
      bool? termsAccepted,
      String languageCode,
      List<String> outdatedPolicies,
      ) async {
    try {
      // ✅ ПРОДАКШЕН: Сохраняем в ТОМ ЖЕ ФОРМАТЕ что уже есть в Firebase
      Map<String, dynamic> updateData = {
        'consent_language': languageCode,
        'consent_timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Добавляем контекстную информацию
      if (outdatedPolicies.isNotEmpty) {
        updateData['last_updated_policies'] = outdatedPolicies.join(',');
        updateData['update_context'] = 'selective_update';
      }

      if (privacyAccepted == true) {
        final currentPrivacyVersion = await getCurrentPrivacyPolicyVersion(languageCode);

        // ✅ ПРОДАКШЕН: Обновляем ОБА формата для совместимости
        updateData.addAll({
          // Новый формат (snake_case)
          'privacy_policy_accepted': true,
          'privacy_policy_version': currentPrivacyVersion,
          // Старый формат (camelCase) - для совместимости
          'privacyPolicyAccepted': true,
          'privacyPolicyVersion': currentPrivacyVersion,
        });
      }

      if (termsAccepted == true) {
        final currentTermsVersion = await getCurrentTermsOfServiceVersion(languageCode);

        // ✅ ПРОДАКШЕН: Обновляем ОБА формата для совместимости
        updateData.addAll({
          // Новый формат (snake_case)
          'terms_of_service_accepted': true,
          'terms_of_service_version': currentTermsVersion,
          // Старый формат (camelCase) - для совместимости
          'termsOfServiceAccepted': true,
          'termsOfServiceVersion': currentTermsVersion,
        });
      }

      await _firebaseService.updateUserConsents(updateData);
      debugPrint('✅ ПРОДАКШЕН: Селективные согласия сохранены в Firebase с поддержкой обоих форматов');
    } catch (e) {
      debugPrint('❌ Ошибка при селективном сохранении согласий в Firebase: $e');
    }
  }

  /// Получает список устаревших политик на основе проверки
  Future<List<String>> getOutdatedPolicies([String? languageCode]) async {
    final checkResult = await checkUserConsents(languageCode);
    return checkResult.outdatedPolicies;
  }

  /// Обновляет только определенную политику
  Future<bool> updatePrivacyPolicyAcceptance(String? languageCode) async {
    return await saveSelectiveConsents(
      privacyPolicyAccepted: true,
      termsOfServiceAccepted: null,
      languageCode: languageCode,
      outdatedPolicies: ['privacy'],
    );
  }

  /// Обновляет только пользовательское соглашение
  Future<bool> updateTermsOfServiceAcceptance(String? languageCode) async {
    return await saveSelectiveConsents(
      privacyPolicyAccepted: null,
      termsOfServiceAccepted: true,
      languageCode: languageCode,
      outdatedPolicies: ['terms'],
    );
  }

  /// ✅ ПРОДАКШЕН: Безопасная синхронизация с поддержкой обоих форматов
  Future<void> syncConsentsFromFirestore() async {
    try {
      if (!_firebaseService.isUserLoggedIn) {
        debugPrint('❌ Пользователь не авторизован для синхронизации');
        return;
      }

      final doc = await _firebaseService.getUserConsents();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // ✅ ПРОДАКШЕН: Чтение с поддержкой обоих форматов
        final privacyAccepted = data['privacyPolicyAccepted'] ??
            data['privacy_policy_accepted'] ?? false;
        final termsAccepted = data['termsOfServiceAccepted'] ??
            data['terms_of_service_accepted'] ?? false;
        final privacyVersion = data['privacyPolicyVersion'] ??
            data['privacy_policy_version'] ?? '';
        final termsVersion = data['termsOfServiceVersion'] ??
            data['terms_of_service_version'] ?? '';
        final consentLanguage = data['consentLanguage'] ??
            data['consent_language'] ?? 'ru';

        // Обновляем локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_privacyPolicyAcceptedKey, privacyAccepted);
        await prefs.setBool(_termsOfServiceAcceptedKey, termsAccepted);
        await prefs.setString(_privacyPolicyVersionKey, privacyVersion);
        await prefs.setString(_termsOfServiceVersionKey, termsVersion);
        await prefs.setString('consent_language', consentLanguage);

        debugPrint('✅ ПРОДАКШЕН: Согласия синхронизированы из Firebase');
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
      await prefs.remove('last_updated_policies');

      // Очищаем кэш
      _cachedPrivacyPolicyVersion = null;
      _cachedTermsOfServiceVersion = null;

      debugPrint('✅ Все согласия очищены');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке согласий: $e');
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
      outdatedPolicies: ['privacy', 'terms'],
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

        // ✅ ПРОДАКШЕН: Проверка с поддержкой обоих форматов
        final hasPrivacy = data['privacyPolicyAccepted'] == true ||
            data['privacy_policy_accepted'] == true;
        final hasTerms = data['termsOfServiceAccepted'] == true ||
            data['terms_of_service_accepted'] == true;

        return !(hasPrivacy && hasTerms);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке нового пользователя: $e');
      return true;
    }
  }

  /// ✅ ПРОДАКШЕН: Получает статус согласий пользователя
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
}