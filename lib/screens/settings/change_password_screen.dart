// Путь: lib/screens/settings/change_password_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _firebaseService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        context,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context);

        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('password_changed_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Возвращаемся назад
        Navigator.pop(context);
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

  Future<void> _sendPasswordResetEmail() async {
    final localizations = AppLocalizations.of(context);
    final user = _firebaseService.currentUser;

    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('user_not_authorized')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('password_reset_confirmation'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('password_reset_email_will_be_sent'),
              style: TextStyle(color: AppConstants.textColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user?.email ?? '',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('check_spam_folder'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.translate('send_reset_email')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.sendPasswordResetEmail(user?.email ?? '', context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('password_reset_email_sent')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final adaptiveTextScale = textScale > 1.2 ? 1.2 / textScale : 1.0;
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, size.height * 0.02, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.02),

              // Форма смены пароля
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поле текущего пароля
                    TextFormField(
                      controller: _currentPasswordController,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: localizations.translate('enter_current_password'),
                        labelText: localizations.translate('current_password'),
                        hintStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                        ),
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
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
                            _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
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
                          return localizations.translate('please_enter_password');
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),

                    SizedBox(height: size.height * 0.01),

                    // Ссылка "Забыли пароль?"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendPasswordResetEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.textColor,
                        ),
                        child: Text(
                          localizations.translate('forgot_password_question'),
                          style: TextStyle(
                            fontSize: 14 * adaptiveTextScale,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Поле нового пароля
                    TextFormField(
                      controller: _newPasswordController,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: localizations.translate('enter_new_password'),
                        labelText: localizations.translate('new_password'),
                        hintStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                        ),
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
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
                            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
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

                    SizedBox(height: size.height * 0.02),

                    // Поле подтверждения нового пароля
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: localizations.translate('confirm_your_new_password'),
                        labelText: localizations.translate('confirm_new_password'),
                        hintStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                        ),
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
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
                        _newPasswordController.text,
                        context,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _changePassword(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

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
                  ),
                ),

              SizedBox(height: _errorMessage.isNotEmpty ? size.height * 0.03 : size.height * 0.04),

              // Кнопка смены пароля
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
                    disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
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
                      letterSpacing: 1.2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}