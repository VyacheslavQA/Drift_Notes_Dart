// Путь: lib/screens/auth/auth_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/auth/google_sign_in_service.dart';

class AuthSelectionScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthSelectionScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✅ БЕЗОПАСНАЯ ФОРМУЛА ЭКРАНА из гайда
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = MediaQuery.of(context).size.width >= 600;
            final localizations = AppLocalizations.of(context);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                child: Column(
                  children: [
                    // Кнопка "Назад" с правильной семантикой
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Вернуться назад',
                          child: Container(
                            width: 48,
                            height: 48,
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
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),

                    // Основной контент
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isTablet ? 40 : 20),

                        // Логотип с адаптивным размером
                        _buildAppLogo(context, isTablet),

                        SizedBox(height: isTablet ? 24 : 16),

                        // Название приложения с безопасным текстом
                        _buildSafeText(
                          context,
                          'Drift Notes',
                          baseFontSize: 32.0,
                          isTablet: isTablet,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // Заголовок
                        _buildSafeText(
                          context,
                          localizations.translate('select_login_method'),
                          baseFontSize: 24.0,
                          isTablet: isTablet,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),

                        SizedBox(height: isTablet ? 12 : 8),

                        // Подзаголовок
                        _buildSafeText(
                          context,
                          localizations.translate('select_convenient_login_method'),
                          baseFontSize: 16.0,
                          isTablet: isTablet,
                          color: Colors.white70,
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isTablet ? 48 : 36),

                        // Кнопка Email с безопасной формулой
                        _buildSafeButton(
                          context: context,
                          text: localizations.translate('login_with_email'),
                          icon: Icons.email_outlined,
                          isTablet: isTablet,
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
                          semanticLabel: 'Войти через Email',
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppConstants.textColor,
                          borderColor: AppConstants.textColor,
                        ),

                        SizedBox(height: isTablet ? 20 : 16),

                        // Кнопка Google с loading
                        _buildGoogleButton(context, localizations, isTablet),

                        SizedBox(height: isTablet ? 48 : 40),

                        // Ссылка на регистрацию
                        Semantics(
                          button: true,
                          label: 'Зарегистрироваться',
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
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
                              child: _buildSafeText(
                                context,
                                localizations.translate('no_account_register'),
                                baseFontSize: 16.0,
                                isTablet: isTablet,
                                color: AppConstants.textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Безопасный адаптивный текст из гайда
  Widget _buildSafeText(
      BuildContext context,
      String text, {
        required double baseFontSize,
        required bool isTablet,
        FontWeight? fontWeight,
        Color? color,
        TextAlign? textAlign,
      }) {
    final textScaler = MediaQuery.of(context).textScaler;
    final scale = textScaler.scale(1.0);

    // ВАЖНО: ограничиваем масштабирование (из гайда)
    final adaptiveScale = scale > 1.3 ? 1.3 / scale : 1.0;
    final fontSize = (isTablet ? baseFontSize * 1.2 : baseFontSize) * adaptiveScale;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  /// Безопасная кнопка из гайда
  Widget _buildSafeButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    required bool isTablet,
    IconData? icon,
    String? semanticLabel,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
  }) {
    final buttonHeight = isTablet ? 56.0 : 48.0;

    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: buttonHeight,
          maxHeight: buttonHeight * 1.5,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            side: borderColor != null ? BorderSide(color: borderColor) : null,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: icon != null ? Icon(icon, size: isTablet ? 28 : 24) : const SizedBox.shrink(),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              text,
              baseFontSize: 16.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Логотип приложения
  Widget _buildAppLogo(BuildContext context, bool isTablet) {
    final logoSize = isTablet ? 200.0 : MediaQuery.of(context).size.width * 0.3;

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.phishing,
              size: logoSize * 0.5,
              color: AppConstants.textColor,
            ),
          );
        },
      ),
    );
  }

  /// Кнопка Google с loading состоянием
  Widget _buildGoogleButton(BuildContext context, AppLocalizations localizations, bool isTablet) {
    final buttonHeight = isTablet ? 56.0 : 48.0;

    return Semantics(
      button: true,
      label: 'Войти через Google',
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: buttonHeight,
          maxHeight: buttonHeight * 1.5,
        ),
        child: ElevatedButton.icon(
          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: _isGoogleLoading
              ? SizedBox(
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
            ),
          )
              : Image.asset(
            'assets/images/google_logo.png',
            height: isTablet ? 28 : 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.account_circle,
                size: isTablet ? 28 : 24,
                color: Colors.black87,
              );
            },
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              localizations.translate('login_with_google'),
              baseFontSize: 16.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  /// Упрощенный метод для входа через Google
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
            duration: Duration(seconds: 2),
          ),
        );

        // Выполняем переход и коллбэк
        if (widget.onAuthSuccess != null) {
          debugPrint('🎯 Вызываем коллбэк после успешной Google авторизации');
          Navigator.of(context).pushReplacementNamed('/home');
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onAuthSuccess!();
          });
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (mounted) {
        debugPrint('❌ Google авторизация не завершена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка входа через Google: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа через Google: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }
}