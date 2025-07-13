// Путь: lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';
import '../help/privacy_policy_screen.dart';
import '../help/terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const RegisterScreen({super.key, this.onAuthSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTermsAndPrivacy = false;
  String _errorMessage = '';

  // Состояние требований к паролю
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordFieldFocused = false;

  // Для валидации символов пароля
  bool _showInvalidCharMessage = false;
  String _invalidCharMessage = '';

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Регулярное выражение для допустимых символов в пароле
  final RegExp _allowedPasswordChars = RegExp(r'^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{}|;:,.<>?]*$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordRequirements);

    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFieldFocused = _passwordFocusNode.hasFocus;
      });
    });

    // Добавляем слушатель для предотвращения автовыделения в поле email
    _emailController.addListener(() {
      if (_emailController.selection.start == 0 &&
          _emailController.selection.end == _emailController.text.length) {
        // Используем Future.microtask для избежания рекурсии
        Future.microtask(() {
          if (mounted && _emailController.selection.start == 0 &&
              _emailController.selection.end == _emailController.text.length) {
            _emailController.selection = TextSelection.collapsed(
              offset: _emailController.text.length,
            );
          }
        });
      }
    });

    // Добавляем такой же слушатель для поля имени
    _nameController.addListener(() {
      if (_nameController.selection.start == 0 &&
          _nameController.selection.end == _nameController.text.length) {
        Future.microtask(() {
          if (mounted && _nameController.selection.start == 0 &&
              _nameController.selection.end == _nameController.text.length) {
            _nameController.selection = TextSelection.collapsed(
              offset: _nameController.text.length,
            );
          }
        });
      }
    });

    // И для поля подтверждения пароля
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordController.selection.start == 0 &&
          _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
        Future.microtask(() {
          if (mounted && _confirmPasswordController.selection.start == 0 &&
              _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
            _confirmPasswordController.selection = TextSelection.collapsed(
              offset: _confirmPasswordController.text.length,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _checkPasswordRequirements() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _validatePasswordInput(String input) {
    if (!_allowedPasswordChars.hasMatch(input)) {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _showInvalidCharMessage = true;
        _invalidCharMessage = localizations.translate('password_invalid_characters');
      });

      // Скрываем сообщение через 3 секунды
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showInvalidCharMessage = false;
          });
        }
      });
    }
  }

  // Функция для создания профиля пользователя (новая структура)
  Future<void> _createUserProfile(String userId, String name, String email) async {
    try {
      await _firebaseService.createUserProfile({
        'email': email,
        'displayName': name,
        'photoUrl': null,
        'city': '',
        'country': '',
        'experience': 'beginner',
        'fishingTypes': ['Обычная рыбалка'],
      });

      debugPrint('✅ Профиль пользователя создан в новой структуре');
    } catch (e) {
      debugPrint('❌ Ошибка при создании профиля пользователя: $e');
      // Не прерываем регистрацию, если не удалось создать профиль
    }
  }

  // Функция для сохранения согласий пользователя (новая структура)
  Future<void> _saveUserConsents() async {
    try {
      await _firebaseService.updateUserConsents({
        'privacyPolicyAccepted': true,
        'termsOfServiceAccepted': true,
        'consentDate': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // Можно получить из package_info_plus
        'deviceInfo': {
          'platform': Theme.of(context).platform.name,
          // Можно добавить больше информации об устройстве
        },
      });

      debugPrint('✅ Согласия пользователя сохранены в новой структуре');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении согласий: $e');
      // Не прерываем регистрацию, если не удалось сохранить согласия
    }
  }

  Future<void> _register() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Проверяем согласие с условиями
    if (!_acceptedTermsAndPrivacy) {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _errorMessage = localizations.translate('terms_and_privacy_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      // Регистрируем пользователя в Firebase Auth
      final userCredential = await _firebaseService
          .registerWithEmailAndPassword(email, password, context);

      final user = userCredential.user;

      if (user != null) {
        // Обновляем имя пользователя
        await user.updateDisplayName(name);

        // === НОВАЯ СТРУКТУРА: Создаем профиль пользователя ===
        await _createUserProfile(user.uid, name, email);

        // === НОВАЯ СТРУКТУРА: Сохраняем согласия пользователя ===
        await _saveUserConsents();

        if (mounted) {
          final localizations = AppLocalizations.of(context);

          // Показываем сообщение об успешной регистрации
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('registration_successful')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Проверяем, есть ли коллбэк для выполнения отложенного действия
          if (widget.onAuthSuccess != null) {
            debugPrint('🎯 Вызываем коллбэк после успешной регистрации');
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
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
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
            colors: [
              Color(0xFF0A1F1C), // Тёмно-зеленый
              Color(0xFF071714), // Более тёмный оттенок
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ✅ Простая логика из гайда
              final isTablet = MediaQuery.of(context).size.width >= 600;
              final textScale = MediaQuery.of(context).textScaler.scale(1.0);
              // ✅ Ограничиваем масштабирование из гайда
              final adaptiveTextScale = textScale > 1.3 ? 1.3 / textScale : 1.0;
              final localizations = AppLocalizations.of(context);

              return SingleChildScrollView(
                // ✅ Fallback на случай overflow
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Кнопка "Назад" с правильной семантикой
                      const SizedBox(height: 16),
                      Semantics(
                        button: true,
                        label: localizations.translate('go_back'),
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
                              // Безопасный возврат назад
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                // Если не можем вернуться назад, переходим к экрану выбора авторизации
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/auth_selection',
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      // Основной контент без Flexible в ScrollView
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Верхняя часть: заголовок без логотипа
                          Column(
                            children: [
                              // Заголовок экрана - увеличенный размер
                              Text(
                                localizations.translate('registration'),
                                style: TextStyle(
                                  fontSize: (isTablet ? 32 * 1.2 : 32) * adaptiveTextScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textColor,
                                ),
                              ),

                              SizedBox(height: isTablet ? 16 : 12),

                              // Подзаголовок - увеличенный размер
                              Text(
                                localizations.translate('create_account_access'),
                                style: TextStyle(
                                  fontSize: (isTablet ? 16 * 1.2 : 16) * adaptiveTextScale,
                                  color: AppConstants.textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2, // ✅ Защита от overflow
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: isTablet ? 32 : 24),

                              // Название приложения - увеличенный размер
                              Text(
                                'Drift Notes',
                                style: TextStyle(
                                  fontSize: (isTablet ? 36 * 1.2 : 36) * adaptiveTextScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textColor,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isTablet ? 40 : 30),

                          // Средняя часть: форма регистрации
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Поле для имени
                                Container(
                                  constraints: BoxConstraints(
                                    minHeight: isTablet ? 56 : 48,
                                    maxHeight: isTablet ? 72 : 64,
                                  ),
                                  child: TextFormField(
                                    controller: _nameController,
                                    onTap: () {
                                      // Предотвращаем автовыделение всего текста
                                      Future.delayed(Duration.zero, () {
                                        if (_nameController.selection.baseOffset == 0 &&
                                            _nameController.selection.extentOffset == _nameController.text.length) {
                                          // Если весь текст выделен, ставим курсор в конец
                                          _nameController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: _nameController.text.length),
                                          );
                                        }
                                      });
                                    },
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: localizations.translate('name'),
                                      hintStyle: TextStyle(
                                        color: AppConstants.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF12332E),
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: AppConstants.textColor,
                                        size: isTablet ? 28 : 24,
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
                                      errorStyle: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 24 : 20,
                                        vertical: isTablet ? 20 : 16,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                        Validators.validateName(value, context),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Поле для email
                                Container(
                                  constraints: BoxConstraints(
                                    minHeight: isTablet ? 56 : 48,
                                    maxHeight: isTablet ? 72 : 64,
                                  ),
                                  child: TextFormField(
                                    controller: _emailController,
                                    onTap: () {
                                      // Множественные попытки сбросить автовыделение для старых устройств
                                      Future.microtask(() {
                                        if (_emailController.selection.start == 0 &&
                                            _emailController.selection.end == _emailController.text.length) {
                                          _emailController.selection = TextSelection.collapsed(
                                            offset: _emailController.text.length,
                                          );
                                        }
                                      });

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_emailController.selection.start == 0 &&
                                            _emailController.selection.end == _emailController.text.length) {
                                          _emailController.selection = TextSelection.collapsed(
                                            offset: _emailController.text.length,
                                          );
                                        }
                                      });

                                      // Дополнительная проверка через небольшую задержку
                                      Future.delayed(Duration(milliseconds: 10), () {
                                        if (_emailController.selection.start == 0 &&
                                            _emailController.selection.end == _emailController.text.length) {
                                          _emailController.selection = TextSelection.collapsed(
                                            offset: _emailController.text.length,
                                          );
                                        }
                                      });
                                    },
                                    onChanged: (value) {
                                      // Сбрасываем автовыделение при вводе символов (особенно @ и других спецсимволов)
                                      // Используем несколько методов для максимальной надежности
                                      if (_emailController.selection.start == 0 &&
                                          _emailController.selection.end == _emailController.text.length) {
                                        _emailController.selection = TextSelection.collapsed(
                                          offset: _emailController.text.length,
                                        );
                                      }

                                      Future.microtask(() {
                                        if (_emailController.selection.start == 0 &&
                                            _emailController.selection.end == _emailController.text.length) {
                                          _emailController.selection = TextSelection.collapsed(
                                            offset: _emailController.text.length,
                                          );
                                        }
                                      });

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_emailController.selection.start == 0 &&
                                            _emailController.selection.end == _emailController.text.length) {
                                          _emailController.selection = TextSelection.collapsed(
                                            offset: _emailController.text.length,
                                          );
                                        }
                                      });
                                    },
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: localizations.translate('email'),
                                      hintStyle: TextStyle(
                                        color: AppConstants.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF12332E),
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: AppConstants.textColor,
                                        size: isTablet ? 28 : 24,
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
                                      errorStyle: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 24 : 20,
                                        vertical: isTablet ? 20 : 16,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                        Validators.validateEmail(value, context),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Поле для пароля с валидацией символов
                                Column(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        minHeight: isTablet ? 56 : 48,
                                        maxHeight: isTablet ? 72 : 64,
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        onTap: () {
                                          // Множественные попытки сбросить автовыделение для старых устройств
                                          Future.microtask(() {
                                            if (_passwordController.selection.start == 0 &&
                                                _passwordController.selection.end == _passwordController.text.length) {
                                              _passwordController.selection = TextSelection.collapsed(
                                                offset: _passwordController.text.length,
                                              );
                                            }
                                          });

                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (_passwordController.selection.start == 0 &&
                                                _passwordController.selection.end == _passwordController.text.length) {
                                              _passwordController.selection = TextSelection.collapsed(
                                                offset: _passwordController.text.length,
                                              );
                                            }
                                          });

                                          // Дополнительная проверка через небольшую задержку
                                          Future.delayed(Duration(milliseconds: 10), () {
                                            if (_passwordController.selection.start == 0 &&
                                                _passwordController.selection.end == _passwordController.text.length) {
                                              _passwordController.selection = TextSelection.collapsed(
                                                offset: _passwordController.text.length,
                                              );
                                            }
                                          });
                                        },
                                        onChanged: (value) {
                                          // Сбрасываем автовыделение при вводе символов и одновременно валидируем
                                          Future.microtask(() {
                                            if (_passwordController.selection.start == 0 &&
                                                _passwordController.selection.end == _passwordController.text.length) {
                                              _passwordController.selection = TextSelection.collapsed(
                                                offset: _passwordController.text.length,
                                              );
                                            }
                                          });
                                          _validatePasswordInput(value);
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(_allowedPasswordChars),
                                        ],
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: isTablet ? 18 : 16,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: localizations.translate(
                                            'password',
                                          ),
                                          hintStyle: TextStyle(
                                            color: AppConstants.textColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF12332E),
                                          prefixIcon: Icon(
                                            Icons.lock,
                                            color: AppConstants.textColor,
                                            size: isTablet ? 28 : 24,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: AppConstants.textColor,
                                              size: isTablet ? 28 : 24,
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
                                          errorStyle: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 24 : 20,
                                            vertical: isTablet ? 20 : 16,
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator:
                                            (value) => Validators.validatePassword(
                                          value,
                                          context,
                                        ),
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),

                                    // Сообщение о недопустимых символах
                                    if (_showInvalidCharMessage)
                                      Container(
                                        margin: EdgeInsets.only(top: isTablet ? 8 : 6),
                                        padding: EdgeInsets.all(isTablet ? 12 : 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.redAccent.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.redAccent,
                                              size: isTablet ? 18 : 16,
                                            ),
                                            SizedBox(width: isTablet ? 8 : 6),
                                            Expanded(
                                              child: Text(
                                                _invalidCharMessage,
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: isTablet ? 12 : 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Требования к паролю под полем
                                    if (_passwordFieldFocused ||
                                        _passwordController.text.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(top: isTablet ? 12 : 8),
                                        padding: EdgeInsets.all(isTablet ? 16 : 12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF12332E,
                                          ).withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _hasMinLength
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                  _hasMinLength
                                                      ? Colors.green
                                                      : Colors.red.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  localizations.translate('password_min_chars'),
                                                  style: TextStyle(
                                                    color:
                                                    _hasMinLength
                                                        ? Colors.green
                                                        : AppConstants.textColor
                                                        .withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _hasUppercase
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                  _hasUppercase
                                                      ? Colors.green
                                                      : Colors.red.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'A-Z',
                                                  style: TextStyle(
                                                    color:
                                                    _hasUppercase
                                                        ? Colors.green
                                                        : AppConstants.textColor
                                                        .withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _hasNumber
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                  _hasNumber
                                                      ? Colors.green
                                                      : Colors.red.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '0-9',
                                                  style: TextStyle(
                                                    color:
                                                    _hasNumber
                                                        ? Colors.green
                                                        : AppConstants.textColor
                                                        .withValues(
                                                      alpha: 0.7,
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Поле для подтверждения пароля
                                Container(
                                  constraints: BoxConstraints(
                                    minHeight: isTablet ? 56 : 48,
                                    maxHeight: isTablet ? 72 : 64,
                                  ),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    onTap: () {
                                      // Множественные попытки сбросить автовыделение для старых устройств
                                      Future.microtask(() {
                                        if (_confirmPasswordController.selection.start == 0 &&
                                            _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
                                          _confirmPasswordController.selection = TextSelection.collapsed(
                                            offset: _confirmPasswordController.text.length,
                                          );
                                        }
                                      });

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_confirmPasswordController.selection.start == 0 &&
                                            _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
                                          _confirmPasswordController.selection = TextSelection.collapsed(
                                            offset: _confirmPasswordController.text.length,
                                          );
                                        }
                                      });

                                      // Дополнительная проверка через небольшую задержку
                                      Future.delayed(Duration(milliseconds: 10), () {
                                        if (_confirmPasswordController.selection.start == 0 &&
                                            _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
                                          _confirmPasswordController.selection = TextSelection.collapsed(
                                            offset: _confirmPasswordController.text.length,
                                          );
                                        }
                                      });
                                    },
                                    onChanged: (value) {
                                      // Сбрасываем автовыделение при вводе символов
                                      Future.microtask(() {
                                        if (_confirmPasswordController.selection.start == 0 &&
                                            _confirmPasswordController.selection.end == _confirmPasswordController.text.length) {
                                          _confirmPasswordController.selection = TextSelection.collapsed(
                                            offset: _confirmPasswordController.text.length,
                                          );
                                        }
                                      });
                                    },
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: localizations.translate(
                                        'confirm_password',
                                      ),
                                      hintStyle: TextStyle(
                                        color: AppConstants.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF12332E),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: AppConstants.textColor,
                                        size: isTablet ? 28 : 24,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: AppConstants.textColor,
                                          size: isTablet ? 28 : 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
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
                                      errorStyle: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 24 : 20,
                                        vertical: isTablet ? 20 : 16,
                                      ),
                                    ),
                                    obscureText: _obscureConfirmPassword,
                                    validator:
                                        (value) => Validators.validateConfirmPassword(
                                      value,
                                      _passwordController.text,
                                      context,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _register(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 20),

                          // Чекбокс с пользовательским соглашением и политикой - увеличенный
                          Semantics(
                            label: localizations.translate('agreement_consent_label'),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: isTablet ? 28 : 24,
                                    height: isTablet ? 28 : 24,
                                    child: Checkbox(
                                      value: _acceptedTermsAndPrivacy,
                                      onChanged: (value) {
                                        setState(() {
                                          _acceptedTermsAndPrivacy = value ?? false;
                                        });
                                      },
                                      activeColor: AppConstants.primaryColor,
                                      checkColor: AppConstants.textColor,
                                      side: BorderSide(
                                        color: AppConstants.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 16 : 12),
                                  Flexible(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: isTablet ? 16 : 14,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: localizations.translate(
                                              'i_have_read_and_agree',
                                            ),
                                          ),
                                          const TextSpan(text: ' '),
                                          TextSpan(
                                            text: localizations.translate('terms_of_service'),
                                            style: TextStyle(
                                              color: AppConstants.primaryColor,
                                              decoration: TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = _showTermsOfService,
                                          ),
                                          const TextSpan(text: ' '),
                                          TextSpan(
                                            text: localizations.translate('and'),
                                          ),
                                          const TextSpan(text: ' '),
                                          TextSpan(
                                            text: localizations.translate(
                                              'privacy_policy_agreement',
                                            ),
                                            style: TextStyle(
                                              color: AppConstants.primaryColor,
                                              decoration: TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = _showPrivacyPolicy,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 20),

                          // Нижняя часть: ошибка и кнопки
                          Column(
                            children: [
                              // Сообщение об ошибке - компактная версия
                              if (_errorMessage.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                                  margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: (isTablet ? 12 * 1.2 : 12) * adaptiveTextScale,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3, // ✅ Защита от overflow
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              // Кнопка регистрации
                              Semantics(
                                button: true,
                                label: localizations.translate('register'),
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    minHeight: isTablet ? 56 : 48, // ✅ Минимум для touch target
                                    maxHeight: (isTablet ? 56 : 48) * 1.5, // ✅ Позволяем расти
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                    (_isLoading || !_acceptedTermsAndPrivacy)
                                        ? null
                                        : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: AppConstants.textColor,
                                      side: BorderSide(color: AppConstants.textColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 32 : 24,
                                        vertical: isTablet ? 16 : 14,
                                      ),
                                      disabledBackgroundColor: Colors.transparent,
                                      elevation: 0,
                                    ),
                                    child:
                                    _isLoading
                                        ? SizedBox(
                                      width: isTablet ? 28 : 24,
                                      height: isTablet ? 28 : 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          AppConstants.textColor,
                                        ),
                                      ),
                                    )
                                        : FittedBox( // ✅ КРИТИЧНО для длинного текста
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        localizations.translate('register'),
                                        style: TextStyle(
                                          fontSize: (isTablet ? 16 * 1.2 : 16) * adaptiveTextScale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isTablet ? 20 : 16),

                              // Ссылка на вход
                              Semantics(
                                label: localizations.translate('login_existing_account'),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      localizations
                                          .translate('already_have_account')
                                          .split('?')[0] +
                                          '? ',
                                      style: TextStyle(
                                        color: AppConstants.textColor.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: (isTablet ? 14 * 1.2 : 14) * adaptiveTextScale,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/login',
                                        );
                                      },
                                      child: Text(
                                        localizations
                                            .translate('already_have_account')
                                            .split('? ')[1],
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: (isTablet ? 14 * 1.2 : 14) * adaptiveTextScale,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 20 : 16), // Нижний отступ
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
}