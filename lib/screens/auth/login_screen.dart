// Путь: lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginScreen({
    super.key,
    this.onAuthSuccess,
  });

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
          // Расшифровываем пароль (в данном случае используем простое base64 декодирование)
          try {
            final decodedPassword = utf8.decode(base64Decode(savedPasswordHash));

            setState(() {
              _emailController.text = savedEmail;
              _passwordController.text = decodedPassword;
              _rememberMe = true;
            });
          } catch (e) {
            debugPrint('Ошибка при расшифровке сохраненного пароля: $e');
            // Если не удалось расшифровать, очищаем сохраненные данные
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
        // Шифруем пароль (используем простое base64 кодирование)
        final encodedPassword = base64Encode(utf8.encode(password));

        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keySavedEmail, email);
        await prefs.setString(_keySavedPassword, encodedPassword);

        debugPrint('Данные для входа сохранены');
      } else {
        // Если чекбокс не отмечен, очищаем сохраненные данные
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
    // Скрываем клавиатуру
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

      // Сохраняем данные, если успешно вошли
      await _saveCredentials(email, password);

      if (mounted) {
        final localizations = AppLocalizations.of(context);

        // Показываем сообщение об успешном входе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('login_successful')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Проверяем, есть ли коллбэк для выполнения отложенного действия
        if (widget.onAuthSuccess != null) {
          debugPrint('🎯 Вызываем коллбэк после успешной авторизации');
          // Переходим на главный экран
          Navigator.of(context).pushReplacementNamed('/home');
          // Вызываем коллбэк через небольшую задержку
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onAuthSuccess!();
          });
        } else {
          // Обычная навигация без коллбэка
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
          // ИСПРАВЛЕНО: Убираем приставку "Ошибка:" и показываем чистое сообщение
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

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана для адаптивности
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final adaptiveTextScale = textScale > 1.2 ? 1.2 / textScale : 1.0;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1F1C),  // Тёмно-зеленый
              Color(0xFF071714),  // Более тёмный оттенок
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка "Назад" - уменьшенный отступ
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                // Основной контент в Expanded для автоматического распределения
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Верхняя часть: заголовок и логотип
                      Column(
                        children: [
                          // Заголовок экрана - уменьшенный размер
                          Text(
                            localizations.translate('login_with_email_title'),
                            style: TextStyle(
                              fontSize: 24 * adaptiveTextScale,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Логотип - без контейнера
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: size.width * 0.22,
                            height: size.width * 0.22,
                          ),

                          const SizedBox(height: 16),

                          // Название приложения - уменьшенный размер
                          Text(
                            'Drift Notes',
                            style: TextStyle(
                              fontSize: 30 * adaptiveTextScale,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                          ),
                        ],
                      ),

                      // Средняя часть: форма входа
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email поле - компактная версия
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: localizations.translate('email'),
                                hintStyle: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF12332E),
                                prefixIcon: Icon(Icons.email, color: AppConstants.textColor),
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
                                errorStyle: const TextStyle(color: Colors.redAccent),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14, // Уменьшенный padding
                                ),
                              ),
                              validator: (value) => Validators.validateEmail(value, context),
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 16), // Уменьшенный отступ

                            // Password поле - компактная версия
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: localizations.translate('password'),
                                hintStyle: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF12332E),
                                prefixIcon: Icon(Icons.lock, color: AppConstants.textColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: AppConstants.textColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
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
                                errorStyle: const TextStyle(color: Colors.redAccent),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14, // Уменьшенный padding
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) => Validators.validatePassword(value, context),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                            ),

                            const SizedBox(height: 12), // Уменьшенный отступ

                            // Чекбокс "Запомнить меня" и "Забыли пароль?" в одной строке
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Чекбокс "Запомнить меня"
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
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
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                      child: Text(
                                        localizations.translate('remember_me'),
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: 13 * adaptiveTextScale,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Ссылка "Забыли пароль?"
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot_password');
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppConstants.textColor,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    localizations.translate('forgot_password'),
                                    style: TextStyle(
                                      fontSize: 13 * adaptiveTextScale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Нижняя часть: ошибка и кнопка входа
                      Column(
                        children: [
                          // Сообщение об ошибке - компактная версия
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13 * adaptiveTextScale,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Кнопка входа - компактная версия
                          SizedBox(
                            width: double.infinity,
                            height: 50, // Уменьшенная высота
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppConstants.textColor,
                                side: BorderSide(color: AppConstants.textColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.zero,
                                disabledBackgroundColor: Colors.transparent,
                                elevation: 0,
                              ),
                              child: _isLoading
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
                                  : Text(
                                localizations.translate('login'),
                                style: TextStyle(
                                  fontSize: 16 * adaptiveTextScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Ссылка на регистрацию
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.translate('no_account_register').split('?')[0] + '? ',
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 14 * adaptiveTextScale,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/register');
                                },
                                child: Text(
                                  localizations.translate('no_account_register').split('? ')[1],
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 14 * adaptiveTextScale,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16), // Нижний отступ
              ],
            ),
          ),
        ),
      ),
    );
  }
}