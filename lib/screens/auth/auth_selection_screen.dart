// Путь: lib/screens/auth/auth_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/auth/google_sign_in_service.dart';
import '../../services/auth/google_auth_with_agreements.dart';

class AuthSelectionScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthSelectionScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  final GoogleAuthWithAgreements _googleAuthWithAgreements =
  GoogleAuthWithAgreements();
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    // Простая адаптивность
    final bool isTablet = screenSize.width >= 600;
    final bool isSmallScreen = screenSize.height < 600;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32.0 : 24.0,
            vertical: 16.0,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom - 32,
            child: Column(
              children: [
                // Кнопка "Назад"
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Вернуться к предыдущему экрану',
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppConstants.textColor,
                          size: isTablet ? 28 : 24,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/splash');
                          }
                        },
                        style: IconButton.styleFrom(
                          minimumSize: Size(48, 48), // Минимум для аудита
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),

                // Основной контент в центре
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Логотип
                      Container(
                        width: isTablet ? 200 : (isSmallScreen ? screenSize.width * 0.3 : screenSize.width * 0.4),
                        height: isTablet ? 200 : (isSmallScreen ? screenSize.width * 0.3 : screenSize.width * 0.4),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.phishing,
                                size: isTablet ? 100 : (isSmallScreen ? screenSize.width * 0.15 : screenSize.width * 0.2),
                                color: AppConstants.textColor,
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: isTablet ? 32 : (isSmallScreen ? 16 : 24)),

                      // Название приложения
                      Semantics(
                        header: true,
                        label: 'Drift Notes - приложение для рыбалки',
                        child: Text(
                          'Drift Notes',
                          style: TextStyle(
                            fontSize: (isTablet ? 40 : (isSmallScreen ? 28 : 36)) *
                                (textScaler.scale(1.0) > 1.3 ? 1.3 / textScaler.scale(1.0) : 1),
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Заголовок
                      Text(
                        localizations.translate('select_login_method'),
                        style: TextStyle(
                          fontSize: (isTablet ? 26 : (isSmallScreen ? 20 : 24)) *
                              (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Подзаголовок
                      Text(
                        localizations.translate('select_convenient_login_method'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (isTablet ? 18 : 16) *
                              (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                          color: Colors.white70,
                        ),
                      ),

                      SizedBox(height: isTablet ? 48 : (isSmallScreen ? 24 : 36)),

                      // Ограничиваем ширину кнопок на планшетах
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            // Кнопка входа через Email
                            Semantics(
                              button: true,
                              label: 'Войти используя email адрес',
                              child: SizedBox(
                                width: double.infinity,
                                height: isTablet ? 56 : 48,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.email_outlined,
                                    color: AppConstants.textColor,
                                    size: isTablet ? 24 : 20,
                                  ),
                                  label: Text(
                                    localizations.translate('login_with_email'),
                                    style: TextStyle(
                                      fontSize: (isTablet ? 18 : 16) *
                                          (textScaler.scale(1.0) > 1.3 ? 1.3 / textScaler.scale(1.0) : 1),
                                      color: AppConstants.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: AppConstants.textColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                          onAuthSuccess: widget.onAuthSuccess,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 16),

                            // Кнопка входа через Google
                            Semantics(
                              button: true,
                              label: 'Войти через Google аккаунт',
                              child: SizedBox(
                                width: double.infinity,
                                height: isTablet ? 56 : 48,
                                child: ElevatedButton.icon(
                                  icon: _isGoogleLoading
                                      ? SizedBox(
                                    width: isTablet ? 24 : 20,
                                    height: isTablet ? 24 : 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                    ),
                                  )
                                      : Image.asset(
                                    'assets/images/google_logo.png',
                                    height: isTablet ? 24 : 20,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.account_circle,
                                        size: isTablet ? 24 : 20,
                                        color: Colors.black87,
                                      );
                                    },
                                  ),
                                  label: Text(
                                    localizations.translate('login_with_google'),
                                    style: TextStyle(
                                      fontSize: (isTablet ? 18 : 16) *
                                          (textScaler.scale(1.0) > 1.3 ? 1.3 / textScaler.scale(1.0) : 1),
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isTablet ? 48 : 32),

                      // Ссылка на регистрацию
                      Semantics(
                        button: true,
                        label: 'Перейти к регистрации нового аккаунта',
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(
                                  onAuthSuccess: widget.onAuthSuccess,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size(double.minPositive, 48), // Минимум для аудита
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            localizations.translate('no_account_register'),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: (isTablet ? 18 : 16) *
                                  (textScaler.scale(1.0) > 1.3 ? 1.3 / textScaler.scale(1.0) : 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Метод для входа через Google с проверкой соглашений
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await _googleAuthWithAgreements
          .signInWithGoogleAndCheckAgreements(
        context,
        onAuthSuccess: widget.onAuthSuccess,
      );

      if (userCredential == null && mounted) {
        debugPrint('❌ Google авторизация не завершена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка входа через Google: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }
}