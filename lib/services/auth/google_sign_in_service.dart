// Путь: lib/services/auth/google_sign_in_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_service.dart';
import '../../localization/app_localizations.dart';

/// Сервис для работы с Google Sign-In
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

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
  Future<UserCredential?> _signInWithGoogleMobile([BuildContext? context]) async {
    try {
      // Показываем диалог выбора аккаунта Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Пользователь отменил вход
        debugPrint('Пользователь отменил вход через Google');
        return null;
      }

      // Получаем аутентификационные данные
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Создаем credential для Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входим в Firebase с Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Кэшируем данные пользователя через Firebase сервис
      await _firebaseService.cacheUserDataFromCredential(userCredential);

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
      // Создаем провайдер для веб-платформы
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Вход через popup (для веб)
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);

      // Кэшируем данные пользователя
      await _firebaseService.cacheUserDataFromCredential(userCredential);

      debugPrint('Успешный вход через Google (веб): ${userCredential.user?.email}');
      return userCredential;

    } catch (e) {
      debugPrint('Ошибка входа через Google (веб-версия): $e');
      rethrow;
    }
  }

  /// Выход из Google аккаунта
  Future<void> signOutGoogle() async {
    try {
      // Выходим из Google
      await _googleSignIn.signOut();

      // Выходим из Firebase
      await _firebaseService.signOut();

      debugPrint('Успешный выход из Google аккаунта');
    } catch (e) {
      debugPrint('Ошибка при выходе из Google аккаунта: $e');
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
        throw Exception(context != null
            ? AppLocalizations.of(context).translate('user_not_authorized')
            : 'Пользователь не авторизован');
      }

      // Получаем Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Связываем аккаунты
      final UserCredential userCredential = await currentUser.linkWithCredential(credential);

      debugPrint('Аккаунт успешно связан с Google');
      return userCredential;

    } catch (e) {
      debugPrint('Ошибка при связывании с Google: $e');
      _handleGoogleSignInError(e, context);
      return null;
    }
  }

  /// Отвязка Google аккаунта
  Future<void> unlinkGoogle([BuildContext? context]) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(context != null
            ? AppLocalizations.of(context).translate('user_not_authorized')
            : 'Пользователь не авторизован');
      }

      // Отвязываем Google провайдер
      await currentUser.unlink(GoogleAuthProvider.PROVIDER_ID);

      // Выходим из Google
      await _googleSignIn.signOut();

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
      } else if (error.toString().contains('account-exists-with-different-credential')) {
        errorMessage = localizations.translate('account_exists_different_credential');
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
      } else if (error.toString().contains('account-exists-with-different-credential')) {
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
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Ошибка при тихом входе через Google: $e');
      return null;
    }
  }
}