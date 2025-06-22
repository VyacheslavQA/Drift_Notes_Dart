// Путь: lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSent = false;
    });

    try {
      await _firebaseService.sendPasswordResetEmail(
        _emailController.text.trim(),
        context,
      );

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
        color: color,
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
    Color? backgroundColor,
    Color? foregroundColor,
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
            backgroundColor: backgroundColor ?? const Color(0xFF2E7D32),
            foregroundColor: foregroundColor ?? AppConstants.textColor,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
            ),
            elevation: isLoading ? 0 : 4,
          ),
          child: isLoading
              ? SizedBox(
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            child: CircularProgressIndicator(
              color: AppConstants.textColor,
              strokeWidth: 2.5,
            ),
          )
              : FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              text,
              baseFontSize: 18.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: foregroundColor ?? AppConstants.textColor,
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
            colors: [Color(0xFF0A1F1C), Color(0xFF071714)],
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
                      // Кнопка "Назад"
                      Row(
                        children: [
                          Semantics(
                            button: true,
                            label: 'Вернуться к предыдущему экрану',
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
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),

                      SizedBox(height: isTablet ? 32 : 24),

                      // Заголовок экрана
                      _buildSafeText(
                        context,
                        localizations.translate('password_recovery'),
                        baseFontSize: 28.0,
                        isTablet: isTablet,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),

                      SizedBox(height: isTablet ? 48 : 32),

                      // Основной контент
                      if (_isSent)
                        _buildSuccessMessage(context, localizations, isTablet)
                      else
                        _buildForm(context, localizations, isTablet),
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

  // Сообщение об успешной отправке
  Widget _buildSuccessMessage(BuildContext context, AppLocalizations localizations, bool isTablet) {
    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Иконка и заголовок успеха
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: isTablet ? 28 : 24,
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Flexible(
                      child: _buildSafeText(
                        context,
                        localizations.translate('email_sent'),
                        baseFontSize: 18.0,
                        isTablet: isTablet,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 8),

                // Описание
                _buildSafeText(
                  context,
                  localizations.translate('recovery_instructions_sent'),
                  baseFontSize: 16.0,
                  isTablet: isTablet,
                  color: AppConstants.textColor,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 24 : 16),

          // Кнопка возврата к входу
          _buildSafeButton(
            context: context,
            text: localizations.translate('return_to_login'),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            isTablet: isTablet,
            semanticLabel: 'Вернуться к экрану входа',
          ),
        ],
      ),
    );
  }

  // Форма восстановления пароля
  Widget _buildForm(BuildContext context, AppLocalizations localizations, bool isTablet) {
    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
      child: Column(
        children: [
          // Описание
          _buildSafeText(
            context,
            localizations.translate('enter_email_for_recovery'),
            baseFontSize: 16.0,
            isTablet: isTablet,
            color: AppConstants.textColor,
            maxLines: 3,
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Поле ввода email
          Semantics(
            textField: true,
            label: 'Поле ввода email адреса',
            child: Form(
              key: _formKey,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: isTablet ? 56 : 48,
                  maxHeight: isTablet ? 72 : 64,
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  decoration: InputDecoration(
                    hintText: localizations.translate('email'),
                    hintStyle: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.5),
                      fontSize: isTablet ? 18 : 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF12332E),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      borderSide: BorderSide(
                        color: AppConstants.textColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                    errorStyle: TextStyle(
                      color: Colors.redAccent,
                      fontSize: isTablet ? 16 : 14,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 20 : 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => Validators.validateEmail(value, context),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _resetPassword(),
                ),
              ),
            ),
          ),

          SizedBox(height: isTablet ? 24 : 16),

          // Сообщение об ошибке
          if (_errorMessage.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Flexible(
                    child: _buildSafeText(
                      context,
                      _errorMessage,
                      baseFontSize: 14.0,
                      isTablet: isTablet,
                      color: Colors.redAccent,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
          ] else ...[
            SizedBox(height: isTablet ? 48 : 32),
          ],

          // Кнопка отправки
          _buildSafeButton(
            context: context,
            text: localizations.translate('send'),
            onPressed: _isLoading ? null : _resetPassword,
            isTablet: isTablet,
            isLoading: _isLoading,
            semanticLabel: 'Отправить письмо для восстановления пароля',
          ),
        ],
      ),
    );
  }
}