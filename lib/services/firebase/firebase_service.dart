// Путь: lib/services/firebase/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../offline/offline_storage_service.dart';
import '../../localization/app_localizations.dart';
import '../../constants/subscription_constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // ✅ ИСПРАВЛЕНО: Унифицированные ключи для хранения данных
  static const String _authUserEmailKey = 'auth_user_email';
  static const String _authUserIdKey = 'auth_user_id';
  static const String _authUserDisplayNameKey = 'auth_user_display_name';

  // ✅ ДОБАВЛЕНО: Ключи для "Запомнить меня" (совместимость с login_screen.dart)
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPasswordHash = 'saved_password_hash';

  // ✅ УПРОЩЕНО: Офлайн авторизация
  static const String _offlineAuthEnabledKey = 'offline_auth_enabled';
  static const String _offlineAuthExpiryKey = 'offline_auth_expiry_date';
  static const int _offlineAuthValidityDays = 30;

  // Кэшированные данные
  static String? _cachedUserId;
  static bool _isOfflineMode = false;

  // ========================================
  // БАЗОВЫЕ СВОЙСТВА
  // ========================================

  /// Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  /// Проверка авторизации пользователя
  bool get isUserLoggedIn => _auth.currentUser != null || _isOfflineMode;

  /// Проверка офлайн режима
  bool get isOfflineMode => _isOfflineMode;

  /// Получение ID текущего пользователя
  String? get currentUserId {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    } else if (_isOfflineMode) {
      return _cachedUserId;
    } else {
      return _getCachedUserId();
    }
  }

  /// Получение ID пользователя из кэша
  String? _getCachedUserId() {
    if (_cachedUserId != null) {
      return _cachedUserId;
    }
    _loadCachedUserIdAsync();
    return null;
  }

  /// Асинхронная загрузка userId из SharedPreferences
  Future<void> _loadCachedUserIdAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_authUserIdKey);
    } catch (e) {
      // Silent error handling for production
    }
  }

  // ========================================
  // УПРОЩЕННАЯ ОФЛАЙН АВТОРИЗАЦИЯ
  // ========================================

  /// ✅ ИСПРАВЛЕНО: Проверка возможности офлайн авторизации с правильными ключами
  Future<bool> canAuthenticateOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ ИСПРАВЛЕНО: Проверяем базовые данные по правильным ключам
      final isEnabled = prefs.getBool(_offlineAuthEnabledKey) ?? false;
      final savedEmail = prefs.getString(_keySavedEmail);
      final savedPasswordHash = prefs.getString(_keySavedPasswordHash);
      final expiryTimestamp = prefs.getInt(_offlineAuthExpiryKey);

      if (!isEnabled || savedEmail == null || savedPasswordHash == null || expiryTimestamp == null) {
        return false;
      }

      // Проверяем срок действия (30 дней)
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      final now = DateTime.now();
      final isNotExpired = now.isBefore(expiryDate);

      return isNotExpired;
    } catch (e) {
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Кэширование данных пользователя для офлайн режима
  Future<void> cacheUserDataForOffline(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ ИСПРАВЛЕНО: Сохраняем только в основные ключи
      await prefs.setBool(_offlineAuthEnabledKey, true);
      await prefs.setString(_authUserEmailKey, user.email ?? '');
      await prefs.setString(_authUserIdKey, user.uid);
      await prefs.setString(_authUserDisplayNameKey, user.displayName ?? '');
      await prefs.setString(_keySavedEmail, user.email ?? '');

      // Устанавливаем срок действия (30 дней)
      final expiryDate = DateTime.now().add(Duration(days: _offlineAuthValidityDays));
      await prefs.setInt(_offlineAuthExpiryKey, expiryDate.millisecondsSinceEpoch);
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// ✅ ИСПРАВЛЕНО: Попытка офлайн авторизации с правильными ключами
  Future<bool> tryOfflineAuthentication() async {
    try {
      // Проверяем возможность авторизации
      final canAuth = await canAuthenticateOffline();
      if (!canAuth) {
        return false;
      }

      // ✅ ИСПРАВЛЕНО: Загружаем данные из правильных ключей
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString(_authUserIdKey);
      final cachedEmail = prefs.getString(_keySavedEmail);

      if (cachedUserId == null || cachedEmail == null) {
        return false;
      }

      // Переключаемся в офлайн режим
      _isOfflineMode = true;
      _cachedUserId = cachedUserId;

      // ✅ ИСПРАВЛЕНО: Сохраняем данные через простой метод без конфликта ключей
      await _offlineStorage.saveUserData({
        'uid': cachedUserId,
        'email': cachedEmail,
        'displayName': prefs.getString(_authUserDisplayNameKey) ?? '',
        'isOfflineMode': true,
        'offlineAuthTimestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _isOfflineMode = false;
      _cachedUserId = null;
      return false;
    }
  }

  /// Переключение в онлайн режим
  Future<void> switchToOnlineMode() async {
    try {
      if (_isOfflineMode && _auth.currentUser != null) {
        _isOfflineMode = false;
        await cacheUserDataForOffline(_auth.currentUser!);
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// ✅ УПРОЩЕНО: Отключение офлайн режима
  Future<void> disableOfflineMode() async {
    try {
      _isOfflineMode = false;
      _cachedUserId = null;

      // Очищаем данные
      await _offlineStorage.clearOfflineAuthData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineAuthEnabledKey, false);
      await prefs.remove(_offlineAuthExpiryKey);
    } catch (e) {
      // Silent error handling for production
    }
  }

  // ========================================
  // АУТЕНТИФИКАЦИЯ
  // ========================================

  /// Проверка валидности email
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Регистрация нового пользователя
  Future<UserCredential> registerWithEmailAndPassword(
      String email,
      String password, [
        BuildContext? context,
      ]) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _cacheUserData(userCredential.user);

      if (userCredential.user != null) {
        await cacheUserDataForOffline(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e, context);
    }
  }

  /// Вход пользователя
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password, [
        BuildContext? context,
      ]) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('invalid_email')
              : 'Неверный формат email',
        );
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _cacheUserData(userCredential.user);

      if (userCredential.user != null) {
        await cacheUserDataForOffline(userCredential.user!);
        _isOfflineMode = false;
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e, context);
    }
  }

  /// ✅ ИСПРАВЛЕНО: Сохранение данных пользователя в основные ключи
  Future<void> _cacheUserData(User? user) async {
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ ИСПРАВЛЕНО: Сохраняем только в основные ключи
      await prefs.setString(_authUserEmailKey, user.email ?? '');
      await prefs.setString(_authUserIdKey, user.uid);
      await prefs.setString(_authUserDisplayNameKey, user.displayName ?? '');
      await prefs.setString(_keySavedEmail, user.email ?? '');

      _cachedUserId = user.uid;

      // ✅ ИСПРАВЛЕНО: Простое сохранение через OfflineStorageService
      await _offlineStorage.saveUserData({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
      });
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// Обработка ошибок аутентификации
  String _handleAuthException(dynamic e, [BuildContext? context]) {
    String errorMessage = context != null
        ? AppLocalizations.of(context).translate('unknown_error')
        : 'Произошла неизвестная ошибка';

    if (e is FirebaseAuthException) {
      if (context != null) {
        final localizations = AppLocalizations.of(context);
        switch (e.code) {
          case 'user-not-found':
            errorMessage = localizations.translate('user_not_found');
            break;
          case 'wrong-password':
            errorMessage = localizations.translate('wrong_password');
            break;
          case 'invalid-email':
            errorMessage = localizations.translate('invalid_email');
            break;
          case 'email-already-in-use':
            errorMessage = localizations.translate('email_already_in_use');
            break;
          case 'weak-password':
            errorMessage = localizations.translate('weak_password');
            break;
          case 'network-request-failed':
            errorMessage = localizations.translate('network_request_failed');
            break;
          case 'invalid-credential':
            errorMessage = localizations.translate('invalid_credentials');
            break;
          default:
            errorMessage = localizations.translate('auth_error_general');
        }
      } else {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Пользователь с таким email не найден';
            break;
          case 'wrong-password':
            errorMessage = 'Неверный пароль';
            break;
          case 'invalid-email':
            errorMessage = 'Неверный формат email';
            break;
          case 'email-already-in-use':
            errorMessage = 'Email уже используется другим аккаунтом';
            break;
          case 'weak-password':
            errorMessage = 'Слишком простой пароль';
            break;
          case 'network-request-failed':
            errorMessage = 'Проверьте подключение к интернету';
            break;
          case 'invalid-credential':
            errorMessage = 'Неверный email или пароль';
            break;
          default:
            errorMessage = 'Ошибка входа. Проверьте данные и попробуйте снова';
        }
      }
    }

    return errorMessage;
  }

  /// Кэширование данных пользователя из UserCredential
  Future<void> cacheUserDataFromCredential(UserCredential userCredential) async {
    await _cacheUserData(userCredential.user);

    if (userCredential.user != null) {
      await cacheUserDataForOffline(userCredential.user!);
      _isOfflineMode = false;
    }
  }

  /// Выход пользователя
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authUserEmailKey);
      await prefs.remove(_authUserIdKey);
      await prefs.remove(_authUserDisplayNameKey);

      _cachedUserId = null;
      _isOfflineMode = false;

      await _auth.signOut();
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// Отправка письма для сброса пароля
  Future<void> sendPasswordResetEmail(String email, [BuildContext? context]) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e, context);
    }
  }

  /// Смена пароля пользователя
  Future<void> changePassword(
      String currentPassword,
      String newPassword, [
        BuildContext? context,
      ]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('user_not_authorized')
              : 'Пользователь не авторизован',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e, context);
    }
  }

  // ========================================
  // ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ
  // ========================================

  /// Создание или обновление профиля пользователя
  Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...profileData,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Получение профиля пользователя
  Future<DocumentSnapshot> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      rethrow;
    }
  }

  /// Обновление профиля пользователя
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore.collection('users').doc(userId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        ...profileData,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // ЗАМЕТКИ РЫБАЛКИ (НОВАЯ СТРУКТУРА)
  // ========================================

  /// Добавление заметки о рыбалке
  Future<DocumentReference> addFishingNoteNew(Map<String, dynamic> noteData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.fishingNotesSubcollection)
          .add({
        ...noteData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Обновление заметки о рыбалке
  Future<void> updateFishingNoteNew(String noteId, Map<String, dynamic> noteData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.fishingNotesSubcollection)
          .doc(noteId)
          .update({
        ...noteData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Получение заметок о рыбалке пользователя
  Future<QuerySnapshot> getUserFishingNotesNew() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.fishingNotesSubcollection)
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      if (e.toString().contains('index')) {
        return await _firestore
            .collection('users')
            .doc(userId)
            .collection(SubscriptionConstants.fishingNotesSubcollection)
            .get();
      }
      rethrow;
    }
  }

  /// Удаление заметки о рыбалке
  Future<void> deleteFishingNoteNew(String noteId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.fishingNotesSubcollection)
          .doc(noteId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // 🔥 КРИТИЧЕСКИ ИСПРАВЛЕНО: МАРКЕРНЫЕ КАРТЫ
  // ========================================

  /// 🔥 ИСПРАВЛЕНО: Добавление маркерной карты с использованием кастомного ID
  Future<String> addMarkerMap(Map<String, dynamic> mapData, {String? customId}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем кастомный ID если передан
      if (customId != null && customId.isNotEmpty) {
        // Используем .set() с кастомным ID вместо .add()
        await _firestore
            .collection('users')
            .doc(userId)
            .collection(SubscriptionConstants.markerMapsSubcollection)
            .doc(customId)  // 🔥 ИСПОЛЬЗУЕМ ПЕРЕДАННЫЙ ID
            .set({
          ...mapData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return customId;  // 🔥 ВОЗВРАЩАЕМ КАСТОМНЫЙ ID
      } else {
        // Если ID не передан - используем автогенерацию (для обратной совместимости)
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection(SubscriptionConstants.markerMapsSubcollection)
            .add({
          ...mapData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return docRef.id;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновление маркерной карты
  Future<void> updateMarkerMap(String mapId, Map<String, dynamic> mapData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.markerMapsSubcollection)
          .doc(mapId)
          .update({
        ...mapData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Получение маркерных карт пользователя
  Future<QuerySnapshot> getUserMarkerMaps() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.markerMapsSubcollection)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      rethrow;
    }
  }

  /// Удаление маркерной карты
  Future<void> deleteMarkerMap(String mapId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.markerMapsSubcollection)
          .doc(mapId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // ЗАМЕТКИ БЮДЖЕТА
  // ========================================

  /// Добавление заметки о бюджете
  Future<DocumentReference> addBudgetNote(Map<String, dynamic> budgetData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.budgetNotesSubcollection)
          .add({
        ...budgetData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Обновление заметки о бюджете
  Future<void> updateBudgetNote(String noteId, Map<String, dynamic> budgetData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.budgetNotesSubcollection)
          .doc(noteId)
          .update({
        ...budgetData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Получение заметок о бюджете пользователя
  Future<QuerySnapshot> getUserBudgetNotes() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.budgetNotesSubcollection)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      rethrow;
    }
  }

  /// Удаление заметки о бюджете
  Future<void> deleteBudgetNote(String noteId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.budgetNotesSubcollection)
          .doc(noteId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // СОГЛАСИЯ ПОЛЬЗОВАТЕЛЯ
  // ========================================

  /// Обновление согласий пользователя
  Future<void> updateUserConsents(Map<String, dynamic> consentsData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents')
          .doc('consents')
          .set({
        ...consentsData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Получение согласий пользователя
  Future<DocumentSnapshot> getUserConsents() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents')
          .doc('consents')
          .get();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // ПОДПИСКА ПОЛЬЗОВАТЕЛЯ
  // ========================================

  /// Обновление подписки пользователя
  Future<void> updateUserSubscription(Map<String, dynamic> subscriptionData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.subscriptionSubcollection)
          .doc('current')
          .set({
        ...subscriptionData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Получение подписки пользователя
  Future<DocumentSnapshot> getUserSubscription() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.subscriptionSubcollection)
          .doc('current')
          .get();
    } catch (e) {
      rethrow;
    }
  }

  /// Проверка активности подписки
  Future<bool> isSubscriptionActive() async {
    try {
      final doc = await getUserSubscription();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final isActive = data['isActive'] ?? false;
      final status = data['status'] ?? 'none';

      if (data['expirationDate'] != null) {
        final expirationDate = (data['expirationDate'] as Timestamp).toDate();
        final isNotExpired = DateTime.now().isBefore(expirationDate);
        return isActive && status == 'active' && isNotExpired;
      }

      return isActive && status == 'active';
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // ⚠️ КРИТИЧНО: ЛИМИТЫ ИСПОЛЬЗОВАНИЯ (НЕ ТРОГАЕМ!)
  // ========================================

  /// Получение лимитов использования пользователя
  Future<DocumentSnapshot> getUserUsageLimits() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.userUsageLimitsSubcollection)
          .doc(SubscriptionConstants.currentUsageLimitsDocument);

      final doc = await docRef.get();

      if (!doc.exists) {
        await _createInitialUsageLimits();
        return await docRef.get();
      }

      return doc;
    } catch (e) {
      rethrow;
    }
  }

  /// Создание начальных лимитов с подсчетом существующих данных
  Future<void> _createInitialUsageLimits() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      // Подсчитываем существующие данные
      int fishingNotesCount = 0;
      int markerMapsCount = 0;
      int budgetNotesCount = 0;

      try {
        final fishingNotesSnapshot = await getUserFishingNotesNew();
        fishingNotesCount = fishingNotesSnapshot.docs.length;
      } catch (e) {
        // Silent error handling
      }

      try {
        final markerMapsSnapshot = await getUserMarkerMaps();
        markerMapsCount = markerMapsSnapshot.docs.length;
      } catch (e) {
        // Silent error handling
      }

      try {
        final budgetNotesSnapshot = await getUserBudgetNotes();
        budgetNotesCount = budgetNotesSnapshot.docs.length;
      } catch (e) {
        // Silent error handling
      }

      final initialLimits = {
        SubscriptionConstants.notesCountField: fishingNotesCount,
        SubscriptionConstants.markerMapsCountField: markerMapsCount,
        SubscriptionConstants.budgetNotesCountField: budgetNotesCount,
        SubscriptionConstants.lastResetDateField: DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.userUsageLimitsSubcollection)
          .doc(SubscriptionConstants.currentUsageLimitsDocument)
          .set(initialLimits);
    } catch (e) {
      rethrow;
    }
  }

  /// Увеличение счетчика использования
  Future<bool> incrementUsageCount(String countType, {int increment = 1}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.userUsageLimitsSubcollection)
          .doc(SubscriptionConstants.currentUsageLimitsDocument);

      final doc = await docRef.get();
      if (!doc.exists) {
        await _createInitialUsageLimits();
      }

      await docRef.update({
        countType: FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверка лимита использования
  Future<Map<String, dynamic>> checkUsageLimit(String countType, int maxLimit) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      final doc = await getUserUsageLimits();

      if (!doc.exists) {
        return {
          'canProceed': true,
          'currentCount': 0,
          'maxLimit': maxLimit,
          'remaining': maxLimit,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      final currentCount = data[countType] ?? 0;
      final remaining = maxLimit - currentCount;
      final canProceed = currentCount < maxLimit;

      return {
        'canProceed': canProceed,
        'currentCount': currentCount,
        'maxLimit': maxLimit,
        'remaining': remaining,
      };
    } catch (e) {
      return {
        'canProceed': true,
        'currentCount': 0,
        'maxLimit': maxLimit,
        'remaining': maxLimit,
        'error': e.toString(),
      };
    }
  }

  /// Проверка может ли пользователь создать новый элемент
  Future<Map<String, dynamic>> canCreateItem(String itemType) async {
    try {
      // Проверяем активность подписки
      final isActive = await isSubscriptionActive();
      if (isActive) {
        return {
          'canProceed': true,
          'currentCount': 0,
          'maxLimit': 999999,
          'remaining': 999999,
          'subscriptionActive': true,
        };
      }

      // Получаем лимит для бесплатного пользователя
      final maxLimit = SubscriptionConstants.getContentLimit(
        _getContentTypeFromFirebaseKey(itemType),
      );

      return await checkUsageLimit(itemType, maxLimit);
    } catch (e) {
      return {
        'canProceed': true,
        'currentCount': 0,
        'maxLimit': 999999,
        'remaining': 999999,
        'error': e.toString(),
      };
    }
  }

  /// Преобразование Firebase ключа в ContentType
  ContentType _getContentTypeFromFirebaseKey(String firebaseKey) {
    switch (firebaseKey) {
      case 'notesCount':
        return ContentType.fishingNotes;
      case 'markerMapsCount':
        return ContentType.markerMaps;
      case 'budgetNotesCount':
        return ContentType.budgetNotes;
      default:
        return ContentType.fishingNotes;
    }
  }

  /// Получение статистики использования
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final doc = await getUserUsageLimits();

      if (!doc.exists) {
        return {
          SubscriptionConstants.notesCountField: 0,
          SubscriptionConstants.markerMapsCountField: 0,
          SubscriptionConstants.budgetNotesCountField: 0,
          'exists': false,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        SubscriptionConstants.notesCountField: data[SubscriptionConstants.notesCountField] ?? 0,
        SubscriptionConstants.markerMapsCountField: data[SubscriptionConstants.markerMapsCountField] ?? 0,
        SubscriptionConstants.budgetNotesCountField: data[SubscriptionConstants.budgetNotesCountField] ?? 0,
        SubscriptionConstants.lastResetDateField: data[SubscriptionConstants.lastResetDateField],
        'updatedAt': data['updatedAt'],
        'exists': true,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Сброс лимитов использования
  Future<void> resetUserUsageLimits({String? resetReason}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      final resetData = {
        SubscriptionConstants.notesCountField: 0,
        SubscriptionConstants.markerMapsCountField: 0,
        SubscriptionConstants.budgetNotesCountField: 0,
        SubscriptionConstants.lastResetDateField: DateTime.now().toIso8601String(),
        'resetReason': resetReason ?? 'manual_reset',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.userUsageLimitsSubcollection)
          .doc(SubscriptionConstants.currentUsageLimitsDocument)
          .set(resetData, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // ЗАГРУЗКА ФАЙЛОВ
  // ========================================

  /// Загрузка изображения в Firebase Storage
  Future<String> uploadImage(String path, List<int> imageBytes) async {
    try {
      final ref = _storage.ref().child(path);
      final Uint8List uint8List = Uint8List.fromList(imageBytes);
      final uploadTask = ref.putData(uint8List);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}