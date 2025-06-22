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

  // Безопасный расчет размера шрифта с ограничением
  double _getSafeFontSize(double baseSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    final scale = textScaler.scale(1.0);

    // КРИТИЧНО: еще более строгое ограничение
    final adaptiveScale = scale > 1.1 ? 1.1 / scale : 1.0;
    return baseSize * adaptiveScale;
  }

  // Проверка, является ли экран планшетом
  bool _isTablet() {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600;
  }

  // Безопасная кнопка с FittedBox (по гайду)
  Widget _buildSafeButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    String? semanticLabel,
  }) {
    final isTablet = _isTablet();
    final buttonHeight = isTablet ? 56.0 : 48.0;

    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: buttonHeight,
          maxHeight: buttonHeight * 2.0, // УВЕЛИЧИВАЕМ лимит для больших шрифтов
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppConstants.textColor,
            side: BorderSide(color: AppConstants.textColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 12, // Уменьшаем вертикальный padding
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppConstants.textColor,
              ),
            ),
          )
              : FittedBox( // КРИТИЧНО для предотвращения обрезания
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: _getSafeFontSize(16),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1, // КРИТИЧНО: ограничиваем одной строкой
              overflow: TextOverflow.ellipsis, // Fallback защита
            ),
          ),
        ),
      ),
    );
  }

  // Безопасный текст с ограничением масштабирования
  Widget _buildSafeText(String text, {
    double baseFontSize = 16.0,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _getSafeFontSize(baseFontSize),
        fontWeight: fontWeight,
        color: color ?? AppConstants.textColor,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis, // Fallback защита
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = _isTablet();

    // 🛡️ БЕЗОПАСНАЯ ФОРМУЛА ЭКРАНА ИЗ ГАЙДА
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
        child: SafeArea( // ОБЯЗАТЕЛЬНО
          child: LayoutBuilder( // КРИТИЧНО для предотвращения overflow
            builder: (context, constraints) {
              return SingleChildScrollView( // ВСЕГДА как fallback
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Основной контент без сложных вложенностей
  Widget _buildContent() {
    final localizations = AppLocalizations.of(context);
    final isTablet = _isTablet();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка назад
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            label: 'Вернуться назад',
            hint: 'Возврат к предыдущему экрану',
            button: true,
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
              style: IconButton.styleFrom(
                minimumSize: Size(48, 48), // Минимум для аудита
              ),
            ),
          ),
        ),

        // Заголовок и логотип
        Column(
          children: [
            _buildSafeText(
              localizations.translate('login_with_email_title'),
              baseFontSize: isTablet ? 28 : 24,
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
              'Drift Notes',
              baseFontSize: isTablet ? 36 : 30,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // Форма входа
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email поле
              _buildInputField(
                controller: _emailController,
                hintText: localizations.translate('email'),
                prefixIcon: Icons.email,
                validator: (value) => Validators.validateEmail(value, context),
                textInputAction: TextInputAction.next,
              ),

              SizedBox(height: isTablet ? 24 : 16),

              // Password поле
              _buildInputField(
                controller: _passwordController,
                hintText: localizations.translate('password'),
                prefixIcon: Icons.lock,
                obscureText: _obscurePassword,
                validator: (value) => Validators.validatePassword(value, context),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
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
                    minimumSize: Size(48, 48), // Минимум для аудита
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // Чекбокс и ссылка забыли пароль
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRememberMeCheckbox(),
                  _buildForgotPasswordButton(),
                ],
              ),
            ],
          ),
        ),

        // Нижняя часть: ошибка и кнопки
        Column(
          children: [
            // Сообщение об ошибке
            if (_errorMessage.isNotEmpty) ...[
              Container(
                constraints: BoxConstraints(minHeight: 48),
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSafeText(
                  _errorMessage,
                  baseFontSize: 14,
                  color: Colors.redAccent,
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Кнопка входа
            _buildSafeButton(
              text: localizations.translate('login'),
              onPressed: _isLoading ? null : _login,
              isLoading: _isLoading,
              semanticLabel: 'Войти в приложение',
            ),

            SizedBox(height: isTablet ? 24 : 16),

            // Ссылка на регистрацию
            _buildRegistrationLink(),
          ],
        ),
      ],
    );
  }

  // Безопасное поле ввода
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
  }) {
    final isTablet = _isTablet();

    return Container(
      constraints: BoxConstraints(
        minHeight: 48, // Минимум для аудита
        maxHeight: 72, // Позволяем расти
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: _getSafeFontSize(16),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.5),
            fontSize: _getSafeFontSize(16),
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
            fontSize: _getSafeFontSize(12),
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
  Widget _buildRememberMeCheckbox() {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48, // Минимум для аудита
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
              color: AppConstants.textColor.withValues(alpha: 0.5),
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
              constraints: BoxConstraints(minHeight: 48), // Минимум для аудита
              alignment: Alignment.centerLeft,
              child: FittedBox( // КРИТИЧНО для предотвращения обрезания
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _buildSafeText(
                  localizations.translate('remember_me'),
                  baseFontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Кнопка "Забыли пароль?"
  Widget _buildForgotPasswordButton() {
    final localizations = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: 'Забыли пароль?',
      child: Container(
        constraints: BoxConstraints(
          minHeight: 48, // Минимум для аудита
          minWidth: 48,
        ),
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot_password');
          },
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.textColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size(48, 48), // Минимум для аудита
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: FittedBox( // КРИТИЧНО для предотвращения обрезания
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              localizations.translate('forgot_password'),
              baseFontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Ссылка на регистрацию
  Widget _buildRegistrationLink() {
    final localizations = AppLocalizations.of(context);
    final registrationText = localizations.translate('no_account_register');
    final parts = registrationText.split('?');

    if (parts.length < 2) {
      return _buildSafeText(
        registrationText,
        baseFontSize: 14,
        textAlign: TextAlign.center,
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        _buildSafeText(
          '${parts[0]}? ',
          baseFontSize: 14,
          color: AppConstants.textColor.withValues(alpha: 0.7),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          child: _buildSafeText(
            parts[1],
            baseFontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ),
      ],
    );
  }
}