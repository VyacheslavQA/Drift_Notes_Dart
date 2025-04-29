// Путь: lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _isSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSent = false;
    });

    try {
      await _firebaseService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _isSent = true;
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
    final textScale = MediaQuery.of(context).textScaleFactor;
    final adaptiveTextScale = textScale > 1.2 ? 1.2 / textScale : 1.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1F1C),
              Color(0xFF071714),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, size.height * 0.02, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка "Назад"
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFE3D8B2)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(height: size.height * 0.02),

                  // Заголовок экрана
                  Text(
                    'Восстановление пароля',
                    style: TextStyle(
                      fontSize: 28 * adaptiveTextScale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE3D8B2),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  if (_isSent)
                  // Сообщение об успешной отправке
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Письмо отправлено',
                                style: TextStyle(
                                  fontSize: 18 * adaptiveTextScale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Инструкции по восстановлению пароля были отправлены на указанный email.',
                            style: TextStyle(
                              fontSize: 16 * adaptiveTextScale,
                              color: const Color(0xFFE3D8B2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: const Color(0xFFE3D8B2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Вернуться к входу',
                                style: TextStyle(fontSize: 16 * adaptiveTextScale),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Описание
                        Text(
                          'Укажите email, с которым вы регистрировались. Мы отправим на него инструкции по восстановлению пароля.',
                          style: TextStyle(
                            fontSize: 16 * adaptiveTextScale,
                            color: const Color(0xFFE3D8B2),
                          ),
                        ),

                        SizedBox(height: size.height * 0.04),

                        // Форма сброса пароля
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Color(0xFFE3D8B2),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: const Color(0xFFE3D8B2).withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF12332E),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3D8B2),
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
                            validator: (value) => Validators.validateEmail(value),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _resetPassword(),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Сообщение об ошибке
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
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

                        SizedBox(height: _errorMessage.isNotEmpty ? size.height * 0.04 : size.height * 0.06),

                        // Кнопка отправки
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: const Color(0xFFE3D8B2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: EdgeInsets.zero,
                              disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.5),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFFE3D8B2),
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text(
                              'ОТПРАВИТЬ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
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