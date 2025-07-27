// Путь: lib/screens/settings/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../utils/password_validator.dart'; // ✅ ДОБАВЛЕН ИМПОРТ
import '../../localization/app_localizations.dart';
import '../../widgets/loading_overlay.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  String _successMessage = '';

  // ✅ НОВАЯ ЛОГИКА: Состояние валидации нового пароля
  PasswordValidationResult? _passwordValidationResult;
  bool _newPasswordFieldFocused = false;

  final FocusNode _newPasswordFocusNode = FocusNode();

  // ✅ ДОБАВЛЕНО: Регулярное выражение только для букв и цифр
  final RegExp _allowedPasswordChars = RegExp(r'^[a-zA-Z0-9]*$');

  @override
  void initState() {
    super.initState();

    // ✅ НОВОЕ: Слушатель для валидации нового пароля
    _newPasswordController.addListener(_checkNewPasswordRequirements);

    _newPasswordFocusNode.addListener(() {
      setState(() {
        _newPasswordFieldFocused = _newPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  // ✅ НОВАЯ ЛОГИКА: Проверка требований к новому паролю
  void _checkNewPasswordRequirements() {
    final password = _newPasswordController.text;
    setState(() {
      _passwordValidationResult = PasswordValidator.validatePasswordDetailed(password);
    });
  }

  // ✅ НОВАЯ ЛОГИКА: Валидация ввода нового пароля
  void _validateNewPasswordInput(String input) {
    if (!_allowedPasswordChars.hasMatch(input)) {
      final localizations = AppLocalizations.of(context);

      // Показываем SnackBar с предупреждением
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('password_no_special_chars') ??
                'Пароль не должен содержать специальные символы',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ НОВЫЙ ВИДЖЕТ: Индикатор правила пароля
  Widget _buildPasswordRuleIndicator(PasswordRule rule) {
    final localizations = AppLocalizations.of(context);
    final isValid = _passwordValidationResult != null &&
        !_passwordValidationResult!.violatedRules.contains(rule);

    String ruleText;
    switch (rule) {
      case PasswordRule.minLength:
        ruleText = localizations.translate('password_min_chars') ?? 'Мин. 8 символов';
        break;
      case PasswordRule.hasUppercase:
        ruleText = 'A-Z';
        break;
      case PasswordRule.hasDigit:
        ruleText = '0-9';
        break;
      case PasswordRule.noSpecialChars:
        ruleText = localizations.translate('password_no_special') ?? 'Только буквы и цифры';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            ruleText,
            style: TextStyle(
              color: isValid ? Colors.green : AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ НОВЫЙ ВИДЖЕТ: Блок с сообщениями об ошибках пароля
  Widget _buildPasswordErrorMessages() {
    if (_passwordValidationResult == null || _passwordValidationResult!.isValid) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context);
    final errorMessages = _passwordValidationResult!.getAllErrorMessages(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('password_requirements_not_met') ??
                      'Требования к паролю не выполнены:',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...errorMessages.map((message) => Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              '• $message',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Переавторизация пользователя с текущим паролем
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Изменяем пароль
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() {
          _successMessage = localizations.translate(
            'password_changed_successfully',
          );
          _errorMessage = '';
        });

        // Очищаем поля
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('password_changed_successfully'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Возвращаемся на предыдущий экран через 2 секунды
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        String errorMessage;

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              errorMessage = localizations.translate(
                'current_password_incorrect',
              );
              break;
            case 'weak-password':
              errorMessage = localizations.translate('weak_password');
              break;
            case 'requires-recent-login':
              errorMessage = localizations.translate('requires_recent_login');
              break;
            case 'too-many-requests':
              errorMessage = localizations.translate('too_many_requests');
              break;
            default:
              errorMessage = localizations.translate('password_change_error');
          }
        } else {
          errorMessage = localizations.translate('password_change_error');
        }

        setState(() {
          _errorMessage = errorMessage;
          _successMessage = '';
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

  Future<void> _resetPassword() async {
    final localizations = AppLocalizations.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        await _firebaseService.sendPasswordResetEmail(user!.email!, context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('password_reset_email_sent'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('password_reset_error')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('change_password_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('changing_password'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Текущий пароль
                TextFormField(
                  controller: _currentPasswordController,
                  style: TextStyle(color: AppConstants.textColor, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: localizations.translate('current_password'),
                    labelStyle: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(Icons.lock, color: AppConstants.textColor),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
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
                        _obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppConstants.textColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureCurrentPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate(
                        'please_enter_current_password',
                      );
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // ✅ ОБНОВЛЕНО: Новый пароль с валидацией
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      onChanged: (value) {
                        _validateNewPasswordInput(value);
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(_allowedPasswordChars),
                      ],
                      style: TextStyle(color: AppConstants.textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: localizations.translate('new_password'),
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppConstants.textColor,
                        ),
                        filled: true,
                        fillColor: AppConstants.surfaceColor,
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
                            _obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppConstants.textColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) => Validators.validatePassword(value, context),
                      textInputAction: TextInputAction.next,
                    ),

                    // ✅ НОВОЕ: Сообщения об ошибках валидации пароля
                    _buildPasswordErrorMessages(),

                    // ✅ НОВОЕ: Требования к паролю
                    if (_newPasswordFieldFocused || _newPasswordController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('password_requirements') ?? 'Требования к паролю:',
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              children: [
                                _buildPasswordRuleIndicator(PasswordRule.minLength),
                                _buildPasswordRuleIndicator(PasswordRule.hasUppercase),
                                _buildPasswordRuleIndicator(PasswordRule.hasDigit),
                                _buildPasswordRuleIndicator(PasswordRule.noSpecialChars),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Подтверждение нового пароля
                TextFormField(
                  controller: _confirmPasswordController,
                  style: TextStyle(color: AppConstants.textColor, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: localizations.translate('confirm_new_password'),
                    labelStyle: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppConstants.textColor,
                    ),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
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
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                    _newPasswordController.text,
                    context,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _changePassword(),
                ),

                const SizedBox(height: 16),

                // Ссылка "Забыли пароль?" перенесена сюда, после всех полей
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      localizations.translate('forgot_password_question'),
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Сообщение об успехе
                if (_successMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Сообщение об ошибке
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Кнопка изменения пароля
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
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
                        : Text(
                      localizations.translate('change_password'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}