// Путь: lib/services/user_consent_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для управления согласиями пользователя
class UserConsentService {
  static final UserConsentService _instance = UserConsentService._internal();
  factory UserConsentService() => _instance;
  UserConsentService._internal();

  static const String _privacyPolicyKey = 'privacy_policy_accepted';
  static const String _termsOfServiceKey = 'terms_of_service_accepted';
  static const String _userConsentVersionKey = 'user_consent_version';
  static const String _currentConsentVersion = '1.0'; // Версия соглашений

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Проверяет, принял ли пользователь все необходимые соглашения
  Future<bool> hasUserAcceptedAllConsents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final privacyAccepted = prefs.getBool(_privacyPolicyKey) ?? false;
      final termsAccepted = prefs.getBool(_termsOfServiceKey) ?? false;
      final consentVersion = prefs.getString(_userConsentVersionKey) ?? '';

      // Проверяем что согласия приняты и версия актуальная
      final hasValidConsents = privacyAccepted &&
          termsAccepted &&
          consentVersion == _currentConsentVersion;

      debugPrint('🔍 Проверка согласий: Privacy=$privacyAccepted, Terms=$termsAccepted, Version=$consentVersion, Valid=$hasValidConsents');

      return hasValidConsents;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      return false;
    }
  }

  /// Сохраняет согласия пользователя локально и в Firestore
  Future<bool> saveUserConsents({
    required bool privacyPolicyAccepted,
    required bool termsOfServiceAccepted,
  }) async {
    try {
      // Проверяем что оба согласия приняты
      if (!privacyPolicyAccepted || !termsOfServiceAccepted) {
        debugPrint('❌ Не все согласия приняты');
        return false;
      }

      // Сохраняем локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyPolicyKey, privacyPolicyAccepted);
      await prefs.setBool(_termsOfServiceKey, termsOfServiceAccepted);
      await prefs.setString(_userConsentVersionKey, _currentConsentVersion);
      await prefs.setString('consent_timestamp', DateTime.now().toIso8601String());

      debugPrint('✅ Согласия сохранены локально');

      // Сохраняем в Firestore если пользователь авторизован
      final user = _auth.currentUser;
      if (user != null) {
        await _saveConsentsToFirestore(
          user.uid,
          privacyPolicyAccepted,
          termsOfServiceAccepted,
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
      ) async {
    try {
      await _firestore.collection('user_consents').doc(userId).set({
        'privacy_policy_accepted': privacyAccepted,
        'terms_of_service_accepted': termsAccepted,
        'consent_version': _currentConsentVersion,
        'consent_timestamp': FieldValue.serverTimestamp(),
        'user_id': userId,
      }, SetOptions(merge: true));

      debugPrint('✅ Согласия сохранены в Firestore для пользователя: $userId');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий в Firestore: $e');
      // Не бросаем ошибку, так как локальное сохранение уже прошло успешно
    }
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

        // Обновляем локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_privacyPolicyKey, privacyAccepted);
        await prefs.setBool(_termsOfServiceKey, termsAccepted);
        await prefs.setString(_userConsentVersionKey, consentVersion);

        debugPrint('✅ Согласия синхронизированы из Firestore');
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
      await prefs.remove('consent_timestamp');

      debugPrint('✅ Все согласия очищены');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке согласий: $e');
    }
  }

  /// Получает текущую версию согласий
  String getCurrentConsentVersion() => _currentConsentVersion;

  /// Проверяет актуальность версии согласий
  Future<bool> isConsentVersionCurrent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_userConsentVersionKey) ?? '';
      return savedVersion == _currentConsentVersion;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке версии согласий: $e');
      return false;
    }
  }
}