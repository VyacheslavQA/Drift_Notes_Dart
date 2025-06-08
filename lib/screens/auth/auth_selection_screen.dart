// Путь: lib/screens/auth/auth_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/auth/google_sign_in_service.dart';

class AuthSelectionScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthSelectionScreen({
    super.key,
    this.onAuthSuccess,
  });

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана для адаптивности
    final screenSize = MediaQuery.of(context).size;
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Центрируем содержимое
            children: [
              // Логотип приложения
              SizedBox(
                width: screenSize.width * 0.5,
                height: screenSize.width * 0.5,
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Если логотип не найден, показываем иконку
                    return Container(
                      width: screenSize.width * 0.3,
                      height: screenSize.width * 0.3,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.phishing,
                        size: screenSize.width * 0.15,
                        color: AppConstants.textColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Название приложения
              Text(
                'Drift Notes',
                style: TextStyle(
                  fontSize: 36 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 24),

              // Заголовок "Выберите способ входа"
              Text(
                localizations.translate('select_login_method'),
                style: TextStyle(
                  fontSize: 24 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Подзаголовок
              Text(
                localizations.translate('select_convenient_login_method'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 36),

              // Кнопка входа через Email
              _buildAuthButton(
                context: context,
                icon: Icons.email_outlined,
                text: localizations.translate('login_with_email'),
                onPressed: () {
                  // Переходим к экрану входа с передачей коллбэка
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(onAuthSuccess: widget.onAuthSuccess),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Кнопка входа через Google
              SizedBox(
                width: double.infinity, // Занимает всю ширину
                child: ElevatedButton.icon(
                  icon: _isGoogleLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  )
                      : Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Если изображение не найдено, показываем иконку
                      return const Icon(
                        Icons.account_circle,
                        size: 24,
                        color: Colors.black87,
                      );
                    },
                  ),
                  label: Text(
                    localizations.translate('login_with_google'),
                    style: TextStyle(
                      fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 16),

              // Кнопка входа по номеру телефона
              _buildAuthButton(
                context: context,
                icon: Icons.phone,
                text: localizations.translate('login_with_phone'),
                onPressed: () {
                  // Можно реализовать вход по телефону
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.translate('phone_login_later'))),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Ссылка на регистрацию
              TextButton(
                onPressed: () {
                  // Переходим к экрану регистрации с передачей коллбэка
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(onAuthSuccess: widget.onAuthSuccess),
                    ),
                  );
                },
                child: Text(
                  localizations.translate('no_account_register'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Метод для входа через Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await _googleSignInService.signInWithGoogle(context);

      if (userCredential != null && mounted) {
        final localizations = AppLocalizations.of(context);

        // Показываем сообщение об успешном входе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('google_login_successful')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Проверяем, есть ли коллбэк для выполнения отложенного действия
        if (widget.onAuthSuccess != null) {
          debugPrint('🎯 Вызываем коллбэк после успешной авторизации через Google');
          // Переходим на главный экран
          Navigator.of(context).pushReplacementNamed('/home');
          // Вызываем коллбэк через небольшую задержку
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onAuthSuccess!();
          });
        } else {
          // Если нет коллбэка, просто переходим на главный экран
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('Ошибка входа через Google: $e');
      // Ошибка уже обработана в GoogleSignInService
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  // Метод для создания кнопок авторизации
  Widget _buildAuthButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    return SizedBox(
      width: double.infinity, // Занимает всю доступную ширину
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppConstants.textColor),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: AppConstants.textColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}