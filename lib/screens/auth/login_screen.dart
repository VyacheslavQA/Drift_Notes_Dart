// Путь: lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginScreen({super.key, this.onAuthSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMessage = '';

  // Ключи для сохранения данных
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Загрузка сохраненных данных при открытии экрана
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

      if (rememberMe) {
        final savedEmail = prefs.getString(_keySavedEmail) ?? '';
        final savedPasswordHash = prefs.getString(_keySavedPassword) ?? '';

        if (savedEmail.isNotEmpty && savedPasswordHash.isNotEmpty) {
          try {
            final decodedPassword = utf8.decode(
              base64Decode(savedPasswordHash),
            );

            setState(() {
              _emailController.text = savedEmail;
              _passwordController.text = decodedPassword;
              _rememberMe = true;
            });
          } catch (e) {
            debugPrint('Ошибка при расшифровке сохраненного пароля: $e');
            await _clearSavedCredentials();
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке сохраненных данных: $e');
    }
  }

  // Сохранение данных для входа
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        final encodedPassword = base64Encode(utf8.encode(password));
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keySavedEmail, email);
        await prefs.setString(_keySavedPassword, encodedPassword);
        debugPrint('Данные для входа сохранены');
      } else {
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении данных для входа: $e');
    }
  }

  // Очистка сохраненных данных
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
      debugPrint('Сохраненные данные для входа очищены');
    } catch (e) {
      debugPrint('Ошибка при очистке сохраненных данных: $e');
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
        context,
      );

      await _saveCredentials(email, password);

      if (mounted) {
        final localizations = AppLocalizations.of(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('login_successful')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.onAuthSuccess != null) {
          debugPrint('🎯 Вызываем коллбэк после успешной авторизации');
          Navigator.of(context).pushReplacementNamed('/home');
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onAuthSuccess!();
          });
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        int? maxLines,
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
        color: color ?? AppConstants.textColor,
      ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines ?? 2,
    );
  }

  /// Безопасная кнопка из гайда
  Widget _buildSafeButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    required bool isTablet,
    String? semanticLabel,
    bool isLoading = false,
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
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppConstants.textColor,
            side: BorderSide(color: AppConstants.textColor),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
            width: isTablet ? 24 : 20,
            height: isTablet ? 24 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
            ),
          )
              : FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              text,
              baseFontSize: 16.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ БЕЗОПАСНАЯ ФОРМУЛА ЭКРАНА из гайда
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppConstants.authGradient,
          ),
        ),
        child: SafeArea(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Кнопка назад
                      Row(
                        children: [
                          Semantics(
                            label: 'Вернуться назад',
                            hint: 'Возврат к предыдущему экрану',
                            button: true,
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
                                    Navigator.pushReplacementNamed(context, '/auth_selection');
                                  }
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),

                      SizedBox(height: isTablet ? 32 : 24),

                      // Заголовок и логотип
                      Column(
                        children: [
                          _buildSafeText(
                            context,
                            localizations.translate('login_with_email_title'),
                            baseFontSize: 24.0,
                            isTablet: isTablet,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Логотип
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: isTablet ? 100 : 80,
                            height: isTablet ? 100 : 80,
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          _buildSafeText(
                            context,
                            'Drift Notes',
                            baseFontSize: 30.0,
                            isTablet: isTablet,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 48 : 36),

                      // Форма входа
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email поле
                            _buildInputField(
                              context: context,
                              controller: _emailController,
                              hintText: localizations.translate('email'),
                              prefixIcon: Icons.email,
                              validator: (value) => Validators.validateEmail(value, context),
                              textInputAction: TextInputAction.next,
                              isTablet: isTablet,
                            ),

                            SizedBox(height: isTablet ? 24 : 16),

                            // Password поле
                            _buildInputField(
                              context: context,
                              controller: _passwordController,
                              hintText: localizations.translate('password'),
                              prefixIcon: Icons.lock,
                              obscureText: _obscurePassword,
                              validator: (value) => Validators.validatePassword(value, context),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              isTablet: isTablet,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppConstants.textColor,
                                  size: isTablet ? 28 : 24,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  minimumSize: Size(48, 48),
                                ),
                              ),
                            ),

                            SizedBox(height: isTablet ? 16 : 12),

                            // Чекбокс и ссылка забыли пароль
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRememberMeCheckbox(context, isTablet),
                                _buildForgotPasswordButton(context, isTablet),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isTablet ? 40 : 32),

                      // Сообщение об ошибке
                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          constraints: BoxConstraints(minHeight: 48),
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildSafeText(
                            context,
                            _errorMessage,
                            baseFontSize: 14.0,
                            isTablet: isTablet,
                            color: Colors.redAccent,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ),
                      ],

                      // Кнопка входа
                      _buildSafeButton(
                        context: context,
                        text: localizations.translate('login'),
                        onPressed: _isLoading ? null : _login,
                        isTablet: isTablet,
                        isLoading: _isLoading,
                        semanticLabel: 'Войти в приложение',
                      ),

                      SizedBox(height: isTablet ? 24 : 16),

                      // Ссылка на регистрацию
                      _buildRegistrationLink(context, isTablet),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Безопасное поле ввода
  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    required bool isTablet,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 48,
        maxHeight: 72,
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppConstants.textColor.withOpacity(0.5),
            fontSize: isTablet ? 18 : 16,
          ),
          filled: true,
          fillColor: const Color(0xFF12332E),
          prefixIcon: Icon(
            prefixIcon,
            color: AppConstants.textColor,
            size: isTablet ? 28 : 24,
          ),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppConstants.textColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: isTablet ? 14 : 12,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
        ),
        obscureText: obscureText,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  // Чекбокс "Запомнить меня"
  Widget _buildRememberMeCheckbox(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            activeColor: AppConstants.primaryColor,
            checkColor: AppConstants.textColor,
            side: BorderSide(
              color: AppConstants.textColor.withOpacity(0.5),
              width: 1.5,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Container(
              constraints: BoxConstraints(minHeight: 48),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _buildSafeText(
                  context,
                  localizations.translate('remember_me'),
                  baseFontSize: 13.0,
                  isTablet: isTablet,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Кнопка "Забыли пароль?"
  Widget _buildForgotPasswordButton(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: 'Забыли пароль?',
      child: Container(
        constraints: BoxConstraints(
          minHeight: 48,
          minWidth: 48,
        ),
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot_password');
          },
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.textColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              localizations.translate('forgot_password'),
              baseFontSize: 13.0,
              isTablet: isTablet,
            ),
          ),
        ),
      ),
    );
  }

  // Ссылка на регистрацию
  Widget _buildRegistrationLink(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);
    final registrationText = localizations.translate('no_account_register');
    final parts = registrationText.split('?');

    if (parts.length < 2) {
      return _buildSafeText(
        context,
        registrationText,
        baseFontSize: 14.0,
        isTablet: isTablet,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _buildSafeText(
            context,
            '${parts[0]}? ',
            baseFontSize: 14.0,
            isTablet: isTablet,
            color: AppConstants.textColor.withOpacity(0.7),
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: _buildSafeText(
              context,
              parts[1],
              baseFontSize: 14.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
        ),
      ],
    );
  }
}