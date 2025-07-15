// Путь: lib/services/firebase/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../offline/offline_storage_service.dart';
import '../../utils/network_utils.dart';
import '../../localization/app_localizations.dart';
import '../../constants/app_constants.dart';
import '../../constants/subscription_constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Ключи для хранения пользовательских данных
  static const String _authUserEmailKey = 'auth_user_email';
  static const String _authUserIdKey = 'auth_user_id';
  static const String _authUserDisplayNameKey = 'auth_user_display_name';

  // Офлайн авторизация
  static const String _offlineAuthEnabledKey = 'offline_auth_enabled';
  static const String _lastOnlineAuthKey = 'last_online_auth_timestamp';
  static const String _offlineUserDataKey = 'offline_cached_user_data';
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
      debugPrint('Ошибка при загрузке ID пользователя из кэша: $e');
    }
  }

  // ========================================
  // ОФЛАЙН АВТОРИЗАЦИЯ
  // ========================================

  /// Проверка возможности офлайн авторизации
  Future<bool> canAuthenticateOffline() async {
    try {
      final isValid = await _offlineStorage.isOfflineAuthValid();
      debugPrint('Офлайн авторизация: ${isValid ? 'доступна' : 'недоступна'}');
      return isValid;
    } catch (e) {
      debugPrint('Ошибка при проверке офлайн авторизации: $e');
      return false;
    }
  }

  /// Кэширование данных пользователя для офлайн режима
  Future<void> cacheUserDataForOffline(User user) async {
    try {
      debugPrint('Кэширование данных для офлайн режима: ${user.email}');

      // Используем OfflineStorageService
      await _offlineStorage.saveOfflineUserData(user);

      // Дополнительно сохраняем в старом формате для совместимости
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineAuthEnabledKey, true);
      await prefs.setInt(_lastOnlineAuthKey, DateTime.now().millisecondsSinceEpoch);

      final expiryDate = DateTime.now().add(Duration(days: _offlineAuthValidityDays));
      await prefs.setInt(_offlineAuthExpiryKey, expiryDate.millisecondsSinceEpoch);

      debugPrint('Данные пользователя кэшированы для офлайн режима');
    } catch (e) {
      debugPrint('Ошибка при кэшировании данных пользователя: $e');
    }
  }

  /// Попытка офлайн авторизации
  Future<bool> tryOfflineAuthentication() async {
    try {
      debugPrint('Попытка офлайн авторизации...');

      final canAuth = await canAuthenticateOffline();
      if (!canAuth) {
        return false;
      }

      final cachedData = await _offlineStorage.getCachedUserData();
      if (cachedData == null) {
        return false;
      }

      final cachedUserId = cachedData['uid'] as String?;
      if (cachedUserId == null) {
        return false;
      }

      _isOfflineMode = true;
      _cachedUserId = cachedUserId;

      await _offlineStorage.saveUserData({
        'uid': cachedUserId,
        'email': cachedData['email'] ?? '',
        'displayName': cachedData['displayName'] ?? '',
        'isOfflineMode': true,
        'offlineAuthTimestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Офлайн авторизация успешна: ${cachedData['email']}');
      return true;
    } catch (e) {
      debugPrint('Ошибка при офлайн авторизации: $e');
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
        debugPrint('Переключен в онлайн режим');
      }
    } catch (e) {
      debugPrint('Ошибка при переключении в онлайн режим: $e');
    }
  }

  /// Отключение офлайн режима
  Future<void> disableOfflineMode() async {
    try {
      _isOfflineMode = false;
      _cachedUserId = null;

      await _offlineStorage.clearOfflineAuthData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineAuthEnabledKey, false);
      await prefs.remove(_offlineUserDataKey);
      await prefs.remove(_offlineAuthExpiryKey);

      debugPrint('Офлайн режим отключен');
    } catch (e) {
      debugPrint('Ошибка при отключении офлайн режима: $e');
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

  /// Сохранение данных пользователя в кэш
  Future<void> _cacheUserData(User? user) async {
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authUserEmailKey, user.email ?? '');
      await prefs.setString(_authUserIdKey, user.uid);
      await prefs.setString(_authUserDisplayNameKey, user.displayName ?? '');

      _cachedUserId = user.uid;

      await _offlineStorage.saveUserData({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении данных пользователя в кэш: $e');
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

    debugPrint('Firebase Auth Error: $e');
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
      debugPrint('Ошибка при выходе: $e');
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

      debugPrint('Профиль пользователя создан/обновлен: $userId');
    } catch (e) {
      debugPrint('Ошибка при создании профиля пользователя: $e');
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
      debugPrint('Ошибка при получении профиля пользователя: $e');
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

      debugPrint('Профиль пользователя обновлен: $userId');
    } catch (e) {
      debugPrint('Ошибка при обновлении профиля пользователя: $e');
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
      debugPrint('Ошибка при добавлении заметки о рыбалке: $e');
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
      debugPrint('Ошибка при обновлении заметки о рыбалке: $e');
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
      debugPrint('Ошибка при получении заметок о рыбалке: $e');
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
      debugPrint('Ошибка при удалении заметки о рыбалке: $e');
      rethrow;
    }
  }

  // ========================================
  // МАРКЕРНЫЕ КАРТЫ
  // ========================================

  /// Добавление маркерной карты
  Future<String> addMarkerMap(Map<String, dynamic> mapData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.markerMapsSubcollection)
          .add({
        ...mapData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Маркерная карта добавлена с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при добавлении маркерной карты: $e');
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
      debugPrint('Ошибка при обновлении маркерной карты: $e');
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
      debugPrint('Ошибка при получении маркерных карт: $e');
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
      debugPrint('Ошибка при удалении маркерной карты: $e');
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
      debugPrint('Ошибка при добавлении заметки о бюджете: $e');
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
      debugPrint('Ошибка при обновлении заметки о бюджете: $e');
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
      debugPrint('Ошибка при получении заметок о бюджете: $e');
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
      debugPrint('Ошибка при удалении заметки о бюджете: $e');
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

      debugPrint('Согласия успешно сохранены');
    } catch (e) {
      debugPrint('Ошибка при сохранении согласий: $e');
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
      debugPrint('Ошибка при получении согласий: $e');
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

      debugPrint('Подписка успешно сохранена');
    } catch (e) {
      debugPrint('Ошибка при сохранении подписки: $e');
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
      debugPrint('Ошибка при получении подписки: $e');
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
      debugPrint('Ошибка при проверке активности подписки: $e');
      return false;
    }
  }

  // ========================================
  // ЛИМИТЫ ИСПОЛЬЗОВАНИЯ
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
      debugPrint('Ошибка при получении лимитов использования: $e');
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
        debugPrint('Ошибка при подсчете заметок рыбалки: $e');
      }

      try {
        final markerMapsSnapshot = await getUserMarkerMaps();
        markerMapsCount = markerMapsSnapshot.docs.length;
      } catch (e) {
        debugPrint('Ошибка при подсчете маркерных карт: $e');
      }

      try {
        final budgetNotesSnapshot = await getUserBudgetNotes();
        budgetNotesCount = budgetNotesSnapshot.docs.length;
      } catch (e) {
        debugPrint('Ошибка при подсчете заметок бюджета: $e');
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

      debugPrint('Начальные лимиты созданы для пользователя: $userId');
    } catch (e) {
      debugPrint('Ошибка при создании начальных лимитов: $e');
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

      debugPrint('Счетчик $countType увеличен на $increment');
      return true;
    } catch (e) {
      debugPrint('Ошибка при увеличении счетчика использования: $e');
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
      debugPrint('Ошибка при проверке лимита использования: $e');
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
      debugPrint('Ошибка при проверке возможности создания элемента: $e');
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
      debugPrint('Ошибка при получении статистики использования: $e');
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

      debugPrint('Лимиты использования сброшены для пользователя: $userId');
    } catch (e) {
      debugPrint('Ошибка при сбросе лимитов использования: $e');
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
      debugPrint('Ошибка при загрузке изображения: $e');
      rethrow;
    }
  }
}