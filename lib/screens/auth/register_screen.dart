// Путь: lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';
import '../help/privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  bool _acceptedPrivacyPolicy = false;
  String _errorMessage = '';

  // Состояние требований к паролю
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordFieldFocused = false;
  bool _confirmPasswordFieldFocused = false;

  // Состояние совпадения паролей
  bool _passwordsMatch = true;
  bool _showPasswordMatchError = false;

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordRequirements);
    _confirmPasswordController.addListener(_checkPasswordsMatch);

    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFieldFocused = _passwordFocusNode.hasFocus;
      });
    });

    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _confirmPasswordFieldFocused = _confirmPasswordFocusNode.hasFocus;
        if (!_confirmPasswordFieldFocused && _confirmPasswordController.text.isNotEmpty) {
          _showPasswordMatchError = true;
        }
      });
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

    // Также проверяем совпадение паролей
    _checkPasswordsMatch();
  }

  void _checkPasswordsMatch() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _passwordsMatch = password == confirmPassword;
      // Показываем ошибку только если поле подтверждения не пустое
      if (confirmPassword.isNotEmpty) {
        _showPasswordMatchError = !_passwordsMatch;
      } else {
        _showPasswordMatchError = false;
      }
    });
  }

  Future<void> _register() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Проверяем согласие с политикой конфиденциальности
    if (!_acceptedPrivacyPolicy) {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _errorMessage = localizations.translate('privacy_policy_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await _firebaseService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        context,
      );

      // Обновляем имя пользователя
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Создаем запись о пользователе в Firestore с информацией о согласии
      await _firebaseService.updateUserData(userCredential.user!.uid, {
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'privacyPolicyAccepted': true,
        'privacyPolicyAcceptedAt': DateTime.now().millisecondsSinceEpoch,
      });

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

        // Небольшая задержка перед навигацией
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
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
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final localizations = AppLocalizations.of(context);

    if (!_passwordFieldFocused && _passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('password_requirements'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            localizations.translate('min_8_characters'),
            _hasMinLength,
          ),
          const SizedBox(height: 4),
          _buildRequirementItem(
            localizations.translate('one_uppercase_letter'),
            _hasUppercase,
          ),
          const SizedBox(height: 4),
          _buildRequirementItem(
            localizations.translate('one_number'),
            _hasNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid
                ? Colors.green
                : AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordMatchIndicator() {
    final localizations = AppLocalizations.of(context);

    if (!_showPasswordMatchError || _confirmPasswordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
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
            Icons.cancel,
            color: Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            localizations.translate('passwords_dont_match'),
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyCheckbox() {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptedPrivacyPolicy,
              onChanged: (value) {
                setState(() {
                  _acceptedPrivacyPolicy = value ?? false;
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
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: localizations.translate('i_have_read_and_agree')),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: localizations.translate('privacy_policy_agreement'),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, size.height * 0.02, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Центрируем все содержимое
                children: [
                  // Выравниваем кнопку "Назад" слева
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),

                  // Заголовок экрана (центрированный)
                  Text(
                    localizations.translate('registration'),
                    style: TextStyle(
                      fontSize: 32 * adaptiveTextScale,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.01),

                  // Подзаголовок (центрированный)
                  Text(
                    localizations.translate('create_account_access'),
                    style: TextStyle(
                      fontSize: 16 * adaptiveTextScale,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Форма регистрации
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Поле для имени
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations.translate('name'),
                            hintStyle: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF12332E),
                            prefixIcon: Icon(Icons.person, color: AppConstants.textColor),
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
                              vertical: 16,
                            ),
                          ),
                          validator: (value) => Validators.validateName(value, context),
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Поле для email
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(
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
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => Validators.validateEmail(value, context),
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Поле для пароля
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          style: TextStyle(
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
                              vertical: 16,
                            ),
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
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) => Validators.validatePassword(value, context),
                          textInputAction: TextInputAction.next,
                        ),

                        // Требования к паролю
                        _buildPasswordRequirements(),

                        SizedBox(height: size.height * 0.02),

                        // Поле для подтверждения пароля
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations.translate('confirm_password'),
                            hintStyle: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF12332E),
                            prefixIcon: Icon(Icons.lock_outline, color: AppConstants.textColor),
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
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: AppConstants.textColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) => Validators.validateConfirmPassword(
                            value,
                            _passwordController.text,
                            context,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),

                        // Индикатор совпадения паролей
                        _buildPasswordMatchIndicator(),
                      ],
                    ),
                  ),

                  // Чекбокс с политикой конфиденциальности
                  _buildPrivacyPolicyCheckbox(),

                  SizedBox(height: size.height * 0.02),

                  // Сообщение об ошибке
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14 * adaptiveTextScale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: _errorMessage.isNotEmpty ? size.height * 0.03 : size.height * 0.04),

                  // Кнопка регистрации
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_acceptedPrivacyPolicy || !_passwordsMatch) ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppConstants.textColor,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Center(
                        child: Text(
                          localizations.translate('register'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),

                  // Ссылка на вход
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textColor,
                    ),
                    child: Text(
                      localizations.translate('already_have_account'),
                      style: TextStyle(
                        fontSize: 16 * adaptiveTextScale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}