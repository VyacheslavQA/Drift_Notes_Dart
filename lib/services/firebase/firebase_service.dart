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
import '../auth/google_sign_in_service.dart';
import '../../constants/app_constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Ключи для хранения пользовательских данных
  static const String _authUserEmailKey = 'auth_user_email';
  static const String _authUserIdKey = 'auth_user_id';
  static const String _authUserDisplayNameKey = 'auth_user_display_name';

  // Кэшированные данные для быстрого доступа
  static String? _cachedUserId;

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Проверка авторизации пользователя
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Получение ID текущего пользователя
  String? get currentUserId {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    } else {
      // Если пользователь не авторизован, пытаемся получить ID из кэша
      return _getCachedUserId();
    }
  }

  // Получение ID пользователя из кэша
  String? _getCachedUserId() {
    // Используем статическую переменную для кэширования userId
    if (_cachedUserId != null) {
      return _cachedUserId;
    }

    // Если у нас нет закэшированного ID, возвращаем null
    // А затем асинхронно пытаемся загрузить его из SharedPreferences
    _loadCachedUserIdAsync();
    return null;
  }

  // Асинхронная загрузка userId из SharedPreferences
  Future<void> _loadCachedUserIdAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_authUserIdKey);
      if (kDebugMode) {
        debugPrint('Загружен кэшированный ID пользователя: $_cachedUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при загрузке ID пользователя из кэша: $e');
      }
    }
  }

  Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // Проверка валидности email перед отправкой
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Регистрация нового пользователя с email и паролем
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

      // Сохраняем данные пользователя в кэш
      await _cacheUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e, context);
    }
  }

  // Вход пользователя с email и паролем
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password, [
        BuildContext? context,
      ]) async {
    try {
      // Проверяем формат email перед отправкой
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

      // Сохраняем данные пользователя в кэш
      await _cacheUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e, context);
    }
  }

  // Сохранение данных пользователя в кэш
  Future<void> _cacheUserData(User? user) async {
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authUserEmailKey, user.email ?? '');
      await prefs.setString(_authUserIdKey, user.uid);
      await prefs.setString(_authUserDisplayNameKey, user.displayName ?? '');

      // Обновляем статический кэш
      _cachedUserId = user.uid;

      // Также сохраняем в сервисе офлайн хранилища
      await _offlineStorage.saveUserData({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
      });

      if (kDebugMode) {
        debugPrint('Данные пользователя сохранены в кэш');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при сохранении данных пользователя в кэш: $e');
      }
    }
  }

  // Обработка ошибок аутентификации Firebase
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
          case 'user-disabled':
            errorMessage = localizations.translate('user_disabled');
            break;
          case 'email-already-in-use':
            errorMessage = localizations.translate('email_already_in_use');
            break;
          case 'operation-not-allowed':
            errorMessage = localizations.translate('operation_not_allowed');
            break;
          case 'weak-password':
            errorMessage = localizations.translate('weak_password');
            break;
          case 'network-request-failed':
            errorMessage = localizations.translate('network_request_failed');
            break;
          case 'too-many-requests':
            errorMessage = localizations.translate('too_many_requests');
            break;
          case 'invalid-credential':
          // Для invalid-credential показываем универсальное сообщение
            errorMessage = localizations.translate('invalid_credentials');
            break;
          case 'user-token-expired':
            errorMessage = localizations.translate('session_expired');
            break;
          case 'requires-recent-login':
            errorMessage = localizations.translate('requires_recent_login');
            break;
          default:
            errorMessage = localizations.translate('auth_error_general');
        }
      } else {
        // Fallback для русского
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
          case 'user-disabled':
            errorMessage = 'Учетная запись отключена';
            break;
          case 'email-already-in-use':
            errorMessage = 'Email уже используется другим аккаунтом';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Операция не разрешена';
            break;
          case 'weak-password':
            errorMessage = 'Слишком простой пароль';
            break;
          case 'network-request-failed':
            errorMessage = 'Проверьте подключение к интернету';
            break;
          case 'too-many-requests':
            errorMessage = 'Слишком много попыток входа. Попробуйте позже';
            break;
          case 'invalid-credential':
            errorMessage = 'Неверный email или пароль';
            break;
          case 'user-token-expired':
            errorMessage = 'Сессия истекла. Войдите заново';
            break;
          case 'requires-recent-login':
            errorMessage = 'Требуется повторная авторизация';
            break;
          default:
            errorMessage = 'Ошибка входа. Проверьте данные и попробуйте снова';
        }
      }
    }

    if (kDebugMode) {
      debugPrint('Firebase Auth Error: $e');
    }
    return errorMessage;
  }

  /// Кэширование данных пользователя из UserCredential (для Google Sign-In)
  Future<void> cacheUserDataFromCredential(UserCredential userCredential) async {
    await _cacheUserData(userCredential.user);
  }

  // Выход пользователя
  Future<void> signOut() async {
    // Удаляем кэшированные данные пользователя
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authUserEmailKey);
      await prefs.remove(_authUserIdKey);
      await prefs.remove(_authUserDisplayNameKey);

      // Очищаем статический кэш
      _cachedUserId = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении кэшированных данных пользователя: $e');
      }
    }

    await _auth.signOut();
  }

  // Отправка письма для сброса пароля
  Future<void> sendPasswordResetEmail(String email, [BuildContext? context]) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e, context);
    }
  }

  // Смена пароля пользователя
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

      // Создаем учетные данные для повторной аутентификации
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Повторно аутентифицируем пользователя
      await user.reauthenticateWithCredential(credential);

      // Меняем пароль
      await user.updatePassword(newPassword);

      if (kDebugMode) {
        debugPrint('Пароль успешно изменен');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при смене пароля: $e');
      }
      throw _handleAuthException(e, context);
    }
  }

  // Обновление данных пользователя в Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем данные в Firestore
        await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
      }

      // В любом случае, сохраняем данные локально
      await _offlineStorage.saveUserData(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении данных пользователя: $e');
      }

      // В случае ошибки, сохраняем данные локально
      try {
        await _offlineStorage.saveUserData(data);
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение данных пользователя из Firestore
  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем данные из Firestore
        return await _firestore.collection('users').doc(userId).get();
      } else {
        // Если нет интернета, возвращаем исключение
        throw Exception('Нет подключения к интернету');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при получении данных пользователя: $e');
      }
      rethrow;
    }
  }

  // === СТАРЫЕ МЕТОДЫ (СОХРАНЕНЫ ДЛЯ СОВМЕСТИМОСТИ) ===

  // Добавление заметки о рыбалке (старый метод)
  Future<DocumentReference> addFishingNote(Map<String, dynamic> noteData) async {
    try {
      return await _firestore.collection('fishing_notes').add(noteData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при добавлении заметки: $e');
      }
      rethrow;
    }
  }

  // Обновление заметки о рыбалке (старый метод)
  Future<void> updateFishingNote(String noteId, Map<String, dynamic> noteData) async {
    try {
      await _firestore.collection('fishing_notes').doc(noteId).update(noteData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении заметки: $e');
      }
      rethrow;
    }
  }

  // Получение заметок пользователя (старый метод)
  Future<QuerySnapshot> getUserFishingNotes(String userId) async {
    try {
      return await _firestore
          .collection('fishing_notes')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      // Если ошибка связана с индексом, пытаемся выполнить запрос без сортировки
      if (e.toString().contains('index')) {
        if (kDebugMode) {
          debugPrint('Ошибка индекса в Firestore, выполняем запрос без сортировки');
        }
        return await _firestore
            .collection('fishing_notes')
            .where('userId', isEqualTo: userId)
            .get();
      }
      if (kDebugMode) {
        debugPrint('Ошибка при получении заметок пользователя: $e');
      }
      rethrow;
    }
  }

  // Загрузка изображения в Firebase Storage
  Future<String> uploadImage(String path, List<int> imageBytes) async {
    try {
      final ref = _storage.ref().child(path);
      // Преобразуем List<int> в Uint8List
      final Uint8List uint8List = Uint8List.fromList(imageBytes);
      final uploadTask = ref.putData(uint8List);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при загрузке изображения: $e');
      }
      rethrow;
    }
  }

  // Удаление аккаунта пользователя
  Future<void> deleteAccount([BuildContext? context]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('user_not_authorized')
              : 'Пользователь не авторизован',
        );
      }

      final String userId = user.uid;

      // Проверяем, требуется ли повторная аутентификация
      try {
        // Пытаемся удалить аккаунт сразу
        await user.delete();

        // Если удаление прошло успешно, удаляем данные
        await _deleteUserDataFromFirestore(userId);
        await _clearUserCache();

        if (kDebugMode) {
          debugPrint('Аккаунт успешно удален: $userId');
        }
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          // Требуется повторная аутентификация
          await _reauthenticateAndDelete(user, userId, context);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении аккаунта: $e');
      }
      throw _handleAuthException(e, context);
    }
  }

  // Повторная аутентификация и удаление аккаунта
  Future<void> _reauthenticateAndDelete(User user, String userId, [BuildContext? context]) async {
    try {
      // Получаем методы аутентификации пользователя
      final providerData = user.providerData;

      if (providerData.isNotEmpty) {
        final providerId = providerData.first.providerId;

        if (providerId == 'password') {
          // Если пользователь вошел через email/пароль
          await _reauthenticateWithPassword(user, context);
        } else if (providerId == 'google.com') {
          // Если пользователь вошел через Google
          await _reauthenticateWithGoogle(user, context);
        } else {
          // Для других провайдеров показываем сообщение
          throw Exception(
            context != null
                ? 'Для удаления аккаунта требуется повторный вход. Пожалуйста, выйдите и войдите снова.'
                : 'Требуется повторный вход для удаления аккаунта',
          );
        }
      }

      // После успешной реаутентификации удаляем аккаунт
      await user.delete();

      // Удаляем данные из Firestore и кэш
      await _deleteUserDataFromFirestore(userId);
      await _clearUserCache();

      if (kDebugMode) {
        debugPrint('Аккаунт успешно удален после реаутентификации: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при реаутентификации и удалении: $e');
      }
      rethrow;
    }
  }

  // Повторная аутентификация с паролем
  Future<void> _reauthenticateWithPassword(User user, [BuildContext? context]) async {
    if (context == null) {
      throw Exception('Требуется повторная аутентификация');
    }

    final localizations = AppLocalizations.of(context);

    // Показываем диалог для ввода пароля
    final password = await _showPasswordDialog(context, localizations);

    if (password == null || password.isEmpty) {
      throw Exception(localizations.translate('account_deletion_canceled'));
    }

    // Создаем учетные данные для повторной аутентификации
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    // Повторно аутентифицируем пользователя
    await user.reauthenticateWithCredential(credential);
  }

  // Повторная аутентификация через Google
  Future<void> _reauthenticateWithGoogle(User user, [BuildContext? context]) async {
    try {
      // Импортируем Google Sign-In Service
      final GoogleSignInService googleService = GoogleSignInService();

      // Выполняем повторный вход через Google
      final userCredential = await googleService.signInWithGoogle(context);

      if (userCredential == null) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('account_deletion_canceled')
              : 'Отменено пользователем',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при повторной аутентификации через Google: $e');
      }
      rethrow;
    }
  }

  // Диалог для ввода пароля
  Future<String?> _showPasswordDialog(BuildContext context, AppLocalizations localizations) async {
    final passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Text(
            localizations.translate('password_confirmation_title'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.translate('enter_password_to_delete'),
                style: TextStyle(color: AppConstants.textColor, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(color: AppConstants.textColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text(
                localizations.translate('cancel'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: Text(
                localizations.translate('confirm'),
                style: TextStyle(color: AppConstants.textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Удаление всех данных пользователя из Firestore
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    try {
      final batch = _firestore.batch();

      // Удаляем документ профиля пользователя
      final userDoc = _firestore.collection('users').doc(userId);
      batch.delete(userDoc);

      // Удаляем все заметки пользователя
      final notesQuery = await _firestore
          .collection('fishing_notes')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем все маркерные карты пользователя
      final mapsQuery = await _firestore
          .collection('marker_maps')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in mapsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Выполняем пакетное удаление
      await batch.commit();

      if (kDebugMode) {
        debugPrint('Данные пользователя удалены из Firestore: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении данных пользователя из Firestore: $e');
      }
      throw e;
    }
  }

  // Очистка кэшированных данных пользователя
  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authUserEmailKey);
      await prefs.remove(_authUserIdKey);
      await prefs.remove(_authUserDisplayNameKey);

      // Очищаем статический кэш
      _cachedUserId = null;

      if (kDebugMode) {
        debugPrint('Кэшированные данные пользователя очищены');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при очистке кэша пользователя: $e');
      }
    }
  }

  // ========================================================================
  // === НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С SUBCOLLECTIONS (СТРУКТУРА "ПО ПОЛОЧКАМ") ===
  // ========================================================================

  // === МЕТОДЫ ДЛЯ ПРОФИЛЯ ПОЛЬЗОВАТЕЛЯ ===

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

      if (kDebugMode) {
        debugPrint('Профиль пользователя создан/обновлен: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при создании профиля пользователя: $e');
      }
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
      if (kDebugMode) {
        debugPrint('Ошибка при получении профиля пользователя: $e');
      }
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

      if (kDebugMode) {
        debugPrint('Профиль пользователя обновлен: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении профиля пользователя: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ ЗАМЕТОК О РЫБАЛКЕ (НОВАЯ СТРУКТУРА) ===

  /// Добавление заметки о рыбалке (новая структура)
  Future<DocumentReference> addFishingNoteNew(Map<String, dynamic> noteData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_notes')
          .add({
        ...noteData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при добавлении заметки о рыбалке: $e');
      }
      rethrow;
    }
  }

  /// Обновление заметки о рыбалке (новая структура)
  Future<void> updateFishingNoteNew(String noteId, Map<String, dynamic> noteData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_notes')
          .doc(noteId)
          .update({
        ...noteData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении заметки о рыбалке: $e');
      }
      rethrow;
    }
  }

  /// Получение заметок о рыбалке пользователя (новая структура) - ИСПРАВЛЕНО
  Future<QuerySnapshot> getUserFishingNotesNew() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      // Сортируем по 'date' (это поле точно есть в заметках)
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_notes')
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      // Если ошибка связана с индексом, пытаемся выполнить запрос без сортировки
      if (e.toString().contains('index')) {
        if (kDebugMode) {
          debugPrint('Ошибка индекса в Firestore, выполняем запрос без сортировки');
        }
        return await _firestore
            .collection('users')
            .doc(userId)
            .collection('fishing_notes')
            .get();
      }
      if (kDebugMode) {
        debugPrint('Ошибка при получении заметок о рыбалке: $e');
      }
      rethrow;
    }
  }

  /// Удаление заметки о рыбалке (новая структура)
  Future<void> deleteFishingNoteNew(String noteId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении заметки о рыбалке: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ ПОЕЗДОК НА РЫБАЛКУ ===

  /// Добавление поездки на рыбалку
  Future<DocumentReference> addFishingTrip(Map<String, dynamic> tripData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_trips')
          .add({
        ...tripData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при добавлении поездки на рыбалку: $e');
      }
      rethrow;
    }
  }

  /// Обновление поездки на рыбалку
  Future<void> updateFishingTrip(String tripId, Map<String, dynamic> tripData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_trips')
          .doc(tripId)
          .update({
        ...tripData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении поездки на рыбалку: $e');
      }
      rethrow;
    }
  }

  /// Получение поездок на рыбалку пользователя
  Future<QuerySnapshot> getUserFishingTrips() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_trips')
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при получении поездок на рыбалку: $e');
      }
      rethrow;
    }
  }

  /// Удаление поездки на рыбалку
  Future<void> deleteFishingTrip(String tripId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishing_trips')
          .doc(tripId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении поездки на рыбалку: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ МАРКЕРНЫХ КАРТ ===

  /// Добавление маркерной карты
  Future<DocumentReference> addMarkerMap(Map<String, dynamic> mapData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('marker_maps')
          .add({
        ...mapData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при добавлении маркерной карты: $e');
      }
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
          .collection('marker_maps')
          .doc(mapId)
          .update({
        ...mapData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении маркерной карты: $e');
      }
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
          .collection('marker_maps')
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при получении маркерных карт: $e');
      }
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
          .collection('marker_maps')
          .doc(mapId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении маркерной карты: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ БЮДЖЕТА ===

  /// Добавление заметки о бюджете
  Future<DocumentReference> addBudgetNote(Map<String, dynamic> budgetData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('budget_notes')
          .add({
        ...budgetData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при добавлении заметки о бюджете: $e');
      }
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
          .collection('budget_notes')
          .doc(noteId)
          .update({
        ...budgetData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении заметки о бюджете: $e');
      }
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
          .collection('budget_notes')
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при получении заметок о бюджете: $e');
      }
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
          .collection('budget_notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при удалении заметки о бюджете: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ СОГЛАСИЙ ПОЛЬЗОВАТЕЛЯ ===

  /// Обновление согласий пользователя
  Future<void> updateUserConsents(Map<String, dynamic> consentsData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_consents')
          .doc('consents') // Используем фиксированный ID для согласий
          .set({
        ...consentsData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('Согласия пользователя обновлены: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка при обновлении согласий пользователя: $e');
      }
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
      if (kDebugMode) {
        debugPrint('Ошибка при получении согласий пользователя: $e');
      }
      rethrow;
    }
  }
}