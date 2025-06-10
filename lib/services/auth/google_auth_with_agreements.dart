// Путь: lib/services/auth/google_auth_with_agreements.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'google_sign_in_service.dart';
import '../user_consent_service.dart';
import '../../widgets/user_agreements_dialog.dart';
import '../../localization/app_localizations.dart';

/// Расширенный сервис для Google авторизации с проверкой соглашений
class GoogleAuthWithAgreements {
  static final GoogleAuthWithAgreements _instance = GoogleAuthWithAgreements._internal();
  factory GoogleAuthWithAgreements() => _instance;
  GoogleAuthWithAgreements._internal();

  final GoogleSignInService _googleSignInService = GoogleSignInService();
  final UserConsentService _consentService = UserConsentService();

  /// Вход через Google с проверкой соглашений
  Future<UserCredential?> signInWithGoogleAndCheckAgreements(
      BuildContext context, {
        VoidCallback? onAuthSuccess,
      }) async {
    try {
      debugPrint('🚀 Начинаем процесс входа через Google с проверкой соглашений');

      // Сначала выполняем Google авторизацию
      final userCredential = await _googleSignInService.signInWithGoogle(context);

      if (userCredential == null) {
        debugPrint('❌ Google авторизация отменена или неудачна');
        return null;
      }

      final user = userCredential.user;
      if (user == null) {
        debugPrint('❌ Пользователь null после Google авторизации');
        return null;
      }

      debugPrint('✅ Google авторизация успешна для: ${user.email}');

      // Синхронизируем согласия из Firestore
      await _consentService.syncConsentsFromFirestore(user.uid);

      // Проверяем, новый ли это пользователь и приняты ли соглашения
      final isNewUser = await _consentService.isNewGoogleUser(user.uid);
      final hasAcceptedAgreements = await _consentService.hasUserAcceptedAllConsents();

      debugPrint('🔍 Новый пользователь: $isNewUser, Соглашения приняты: $hasAcceptedAgreements');

      if (isNewUser || !hasAcceptedAgreements) {
        debugPrint('📋 Показываем диалог соглашений');

        // Показываем диалог соглашений и ждем результата
        final agreementsAccepted = await _showAgreementsDialog(context, onAuthSuccess);

        if (!agreementsAccepted) {
          debugPrint('❌ Пользователь не принял соглашения, выходим из аккаунта');

          // Выходим из Google аккаунта если соглашения не приняты
          await _googleSignInService.signOutGoogle();
          return null;
        }
      } else {
        debugPrint('✅ Соглашения уже приняты, продолжаем');

        // Если соглашения уже приняты, показываем успешное сообщение и выполняем коллбэк
        if (context.mounted) {
          _showSuccessMessage(context);

          if (onAuthSuccess != null) {
            debugPrint('🎯 Вызываем коллбэк после успешной авторизации');
            Navigator.of(context).pushReplacementNamed('/home');
            Future.delayed(const Duration(milliseconds: 500), () {
              onAuthSuccess();
            });
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }

      return userCredential;

    } catch (e) {
      debugPrint('❌ Ошибка в процессе Google авторизации с соглашениями: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      return null;
    }
  }

  /// Показывает диалог соглашений и возвращает результат
  Future<bool> _showAgreementsDialog(
      BuildContext context,
      VoidCallback? onAuthSuccess,
      ) async {
    if (!context.mounted) return false;

    bool agreementsAccepted = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Нельзя закрыть нажатием вне диалога
      builder: (BuildContext dialogContext) {
        return UserAgreementsDialog(
          onAgreementsAccepted: () {
            debugPrint('✅ Соглашения приняты в диалоге');
            agreementsAccepted = true;

            // Показываем успешное сообщение
            if (context.mounted) {
              _showSuccessMessage(context);

              // Выполняем переход и коллбэк
              if (onAuthSuccess != null) {
                debugPrint('🎯 Вызываем коллбэк после принятия соглашений');
                Navigator.of(context).pushReplacementNamed('/home');
                Future.delayed(const Duration(milliseconds: 500), () {
                  onAuthSuccess();
                });
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            }
          },
          onCancel: () {
            debugPrint('❌ Пользователь отменил принятие соглашений');
            agreementsAccepted = false;
          },
        );
      },
    );

    return agreementsAccepted;
  }

  /// Показывает сообщение об успешном входе
  void _showSuccessMessage(BuildContext context) {
    if (!context.mounted) return;

    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('google_login_successful')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}