// Путь: lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

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
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

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

      // Создаем запись о пользователе в Firestore
      await _firebaseService.updateUserData(userCredential.user!.uid, {
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        final localizations = AppLocalizations.of(context);

        // Показываем сообщение об успешной регистрации
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('success_saved')),
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

                        SizedBox(height: size.height * 0.02),

                        // Поле для подтверждения пароля
                        TextFormField(
                          controller: _confirmPasswordController,
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
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: _errorMessage.isNotEmpty ? size.height * 0.03 : size.height * 0.04),

                  // Кнопка регистрации
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: EdgeInsets.zero, // Убираем отступы
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
                          : Center( // Явно центрируем текст
                        child: Text(
                          localizations.translate('register'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.0, // Фиксируем высоту строки
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