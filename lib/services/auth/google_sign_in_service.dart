// Путь: lib/services/auth/google_sign_in_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_service.dart';
import '../../localization/app_localizations.dart';

/// Сервис для работы с Google Sign-In
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Вход через Google аккаунт
  Future<UserCredential?> signInWithGoogle([BuildContext? context]) async {
    try {
      // Проверяем, есть ли интернет соединение
      if (kIsWeb) {
        return await _signInWithGoogleWeb(context);
      } else {
        return await _signInWithGoogleMobile(context);
      }
    } catch (e) {
      debugPrint('Ошибка входа через Google: $e');
      _handleGoogleSignInError(e, context);
      return null;
    }
  }

  /// Вход через Google для мобильных платформ
  Future<UserCredential?> _signInWithGoogleMobile([
    BuildContext? context,
  ]) async {
    try {
      // Показываем диалог выбора аккаунта Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Пользователь отменил вход
        debugPrint('Пользователь отменил вход через Google');
        return null;
      }

      // Получаем аутентификационные данные
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Создаем credential для Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входим в Firebase с Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Кэшируем данные пользователя через Firebase сервис
      await _firebaseService.cacheUserDataFromCredential(userCredential);

      // НОВАЯ СТРУКТУРА: Создаем/обновляем профиль пользователя
      await _createOrUpdateUserProfile(userCredential);

      debugPrint('Успешный вход через Google: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Ошибка входа через Google (мобильная версия): $e');
      rethrow;
    }
  }

  /// Вход через Google для веб-платформы
  Future<UserCredential?> _signInWithGoogleWeb([BuildContext? context]) async {
    try {
      // Создаем провайдер для Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Выполняем вход через popup
      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );

      // Кэшируем данные пользователя через Firebase сервис
      await _firebaseService.cacheUserDataFromCredential(userCredential);

      // НОВАЯ СТРУКТУРА: Создаем/обновляем профиль пользователя
      await _createOrUpdateUserProfile(userCredential);

      debugPrint(
        'Успешный вход через Google (веб): ${userCredential.user?.email}',
      );
      return userCredential;
    } catch (e) {
      debugPrint('Ошибка входа через Google (веб-версия): $e');
      rethrow;
    }
  }

  /// Создает или обновляет профиль пользователя в новой структуре
  Future<void> _createOrUpdateUserProfile(
      UserCredential userCredential,
      ) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      // Проверяем, существует ли уже профиль пользователя
      final existingProfile = await _firebaseService.getUserProfile();

      if (!existingProfile.exists) {
        // === СОЗДАЕМ НОВЫЙ ПРОФИЛЬ ===
        await _firebaseService.createUserProfile({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'authProvider': 'google',
          // Дефолтные значения для профиля
          'country': '',
          'city': '',
          'experience': 'beginner',
          'fishingTypes': ['Обычная рыбалка'],
        });

        // === СОХРАНЯЕМ БАЗОВЫЕ СОГЛАСИЯ ДЛЯ GOOGLE ===
        await _firebaseService.updateUserConsents({
          'privacyPolicyAccepted': true, // Google пользователи автоматически соглашаются
          'termsOfServiceAccepted': true,
          'consentDate': FieldValue.serverTimestamp(),
          'appVersion': '1.0.0',
          'authProvider': 'google',
          'deviceInfo': {
            'platform': kIsWeb ? 'web' : 'mobile',
          },
        });

        debugPrint(
          '✅ Создан новый профиль пользователя для Google аккаунта: ${user.email}',
        );
      } else {
        // === ОБНОВЛЯЕМ СУЩЕСТВУЮЩИЙ ПРОФИЛЬ ===
        final existingData = existingProfile.data() as Map<String, dynamic>?;

        await _firebaseService.updateUserProfile({
          'email': user.email ?? existingData?['email'] ?? '',
          'displayName': user.displayName ?? existingData?['displayName'] ?? '',
          'photoUrl': user.photoURL ?? existingData?['photoUrl'] ?? '',
          'authProvider': 'google',
          // Сохраняем существующие пользовательские данные
          'country': existingData?['country'] ?? '',
          'city': existingData?['city'] ?? '',
          'experience': existingData?['experience'] ?? 'beginner',
          'fishingTypes': existingData?['fishingTypes'] ?? ['Обычная рыбалка'],
        });

        debugPrint(
          '✅ Обновлен профиль пользователя для Google аккаунта: ${user.email}',
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка при создании/обновлении профиля пользователя: $e');
      // Не пробрасываем ошибку дальше, чтобы не нарушить процесс входа
    }
  }

  /// Выход из Google аккаунта
  Future<void> signOutGoogle() async {
    try {
      // Выходим из Google
      await _googleSignIn.signOut();

      // Выходим из Firebase (очищает кэш)
      await _firebaseService.signOut();

      debugPrint('✅ Успешный выход из Google аккаунта');
    } catch (e) {
      debugPrint('❌ Ошибка при выходе из Google аккаунта: $e');
    }
  }

  /// Проверка, выполнен ли вход через Google
  bool get isSignedInGoogle => _googleSignIn.currentUser != null;

  /// Получение текущего Google пользователя
  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  /// Связывание текущего аккаунта с Google
  Future<UserCredential?> linkWithGoogle([BuildContext? context]) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('user_not_authorized')
              : 'Пользователь не авторизован',
        );
      }

      // Получаем Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Связываем аккаунты
      final UserCredential userCredential = await currentUser
          .linkWithCredential(credential);

      // НОВАЯ СТРУКТУРА: Обновляем профиль после связывания
      await _updateProfileAfterLinking(userCredential);

      debugPrint('Аккаунт успешно связан с Google');
      return userCredential;
    } catch (e) {
      debugPrint('Ошибка при связывании с Google: $e');
      _handleGoogleSignInError(e, context);
      return null;
    }
  }

  /// Обновление профиля после связывания с Google
  Future<void> _updateProfileAfterLinking(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      // Обновляем профиль с данными из Google
      await _firebaseService.updateUserProfile({
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'authProvider': 'email+google', // Показываем, что связаны оба метода
      });

      debugPrint('✅ Профиль обновлен после связывания с Google');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении профиля после связывания: $e');
    }
  }

  /// Отвязка Google аккаунта
  Future<void> unlinkGoogle([BuildContext? context]) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
          context != null
              ? AppLocalizations.of(context).translate('user_not_authorized')
              : 'Пользователь не авторизован',
        );
      }

      // Отвязываем Google провайдер
      await currentUser.unlink(GoogleAuthProvider.PROVIDER_ID);

      // Выходим из Google
      await _googleSignIn.signOut();

      // Обновляем профиль - убираем указание на Google
      await _firebaseService.updateUserProfile({
        'authProvider': 'email', // Остается только email
      });

      debugPrint('Google аккаунт успешно отвязан');
    } catch (e) {
      debugPrint('Ошибка при отвязке Google аккаунта: $e');
      _handleGoogleSignInError(e, context);
    }
  }

  /// Проверка, связан ли текущий аккаунт с Google
  bool get isLinkedWithGoogle {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    return currentUser.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  /// Обработка ошибок Google Sign-In
  void _handleGoogleSignInError(dynamic error, [BuildContext? context]) {
    String errorMessage;

    if (context != null) {
      final localizations = AppLocalizations.of(context);

      if (error.toString().contains('network_error') ||
          error.toString().contains('NetworkError')) {
        errorMessage = localizations.translate('network_request_failed');
      } else if (error.toString().contains('sign_in_canceled')) {
        errorMessage = localizations.translate('google_sign_in_canceled');
      } else if (error.toString().contains('sign_in_failed')) {
        errorMessage = localizations.translate('google_sign_in_failed');
      } else if (error.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMessage = localizations.translate(
          'account_exists_different_credential',
        );
      } else {
        errorMessage = localizations.translate('google_sign_in_error');
      }
    } else {
      // Fallback сообщения на русском
      if (error.toString().contains('network_error') ||
          error.toString().contains('NetworkError')) {
        errorMessage = 'Проверьте подключение к интернету';
      } else if (error.toString().contains('sign_in_canceled')) {
        errorMessage = 'Вход через Google отменен';
      } else if (error.toString().contains('sign_in_failed')) {
        errorMessage = 'Не удалось войти через Google';
      } else if (error.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMessage = 'Аккаунт с таким email уже существует';
      } else {
        errorMessage = 'Ошибка входа через Google';
      }
    }

    // Показываем ошибку пользователю, если есть контекст
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Получение профильной информации из Google
  Future<Map<String, dynamic>?> getGoogleProfile() async {
    try {
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser == null) return null;

      return {
        'displayName': currentUser.displayName ?? '',
        'email': currentUser.email,
        'photoUrl': currentUser.photoUrl,
        'id': currentUser.id,
      };
    } catch (e) {
      debugPrint('Ошибка при получении профиля Google: $e');
      return null;
    }
  }

  /// Автоматический тихий вход (если пользователь уже входил)
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();

      // Если удалось войти тихо, обновляем Firebase Auth
      if (account != null) {
        final GoogleSignInAuthentication googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        debugPrint('✅ Тихий вход через Google выполнен успешно');
      }

      return account;
    } catch (e) {
      debugPrint('Ошибка при тихом входе через Google: $e');
      return null;
    }
  }

  /// Создание профиля для существующего Google пользователя (миграция)
  Future<void> createProfileForExistingUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Проверяем, что пользователь вошел через Google
      final isGoogleUser = user.providerData.any(
            (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
      );

      if (!isGoogleUser) return;

      // Проверяем, есть ли уже профиль
      final existingProfile = await _firebaseService.getUserProfile();
      if (existingProfile.exists) return;

      // Создаем профиль для существующего Google пользователя
      await _firebaseService.createUserProfile({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'authProvider': 'google',
        'country': '',
        'city': '',
        'experience': 'beginner',
        'fishingTypes': ['Обычная рыбалка'],
      });

      // Сохраняем базовые согласия
      await _firebaseService.updateUserConsents({
        'privacyPolicyAccepted': true,
        'termsOfServiceAccepted': true,
        'consentDate': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
        'authProvider': 'google',
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      });

      debugPrint('✅ Создан профиль для существующего Google пользователя');
    } catch (e) {
      debugPrint('❌ Ошибка при создании профиля для существующего пользователя: $e');
    }
  }
}