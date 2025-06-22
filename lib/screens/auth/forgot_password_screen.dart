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
    // Скрываем клавиатуру
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    // Простая адаптивность
    final bool isTablet = screenSize.width >= 600;
    final bool isSmallScreen = screenSize.height < 600;
    final bool isVerySmallScreen = screenSize.width < 360;

    // Адаптивные размеры
    final double horizontalPadding = isTablet ? 48.0 : (isVerySmallScreen ? 16.0 : 24.0);
    final double buttonHeight = isTablet ? 56.0 : 48.0;

    // Ограничение масштабирования текста
    final double textScale = textScaler.scale(1.0);
    final double adaptiveTextScale = textScale > 1.3 ? 1.3 / textScale : 1.0;

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
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (horizontalPadding * 2),
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Кнопка "Назад"
                      _buildBackButton(context, isTablet, buttonHeight),

                      SizedBox(height: isSmallScreen ? 16 : (isTablet ? 32 : 24)),

                      // Заголовок экрана
                      _buildTitle(context, localizations, adaptiveTextScale, isTablet),

                      SizedBox(height: isSmallScreen ? 24 : (isTablet ? 48 : 32)),

                      // Центрируем контент на планшетах
                      if (isTablet) ...[
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _buildContent(context, localizations, adaptiveTextScale,
                                isTablet, isSmallScreen, buttonHeight),
                          ),
                        ),
                      ] else ...[
                        _buildContent(context, localizations, adaptiveTextScale,
                            isTablet, isSmallScreen, buttonHeight),
                      ],
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

  // Кнопка "Назад"
  Widget _buildBackButton(BuildContext context, bool isTablet, double buttonHeight) {
    return Semantics(
      button: true,
      label: 'Вернуться к предыдущему экрану',
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppConstants.textColor,
          size: isTablet ? 28 : 24,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        style: IconButton.styleFrom(
          minimumSize: Size(buttonHeight, buttonHeight),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // Заголовок экрана
  Widget _buildTitle(BuildContext context, AppLocalizations localizations,
      double adaptiveTextScale, bool isTablet) {
    return Semantics(
      header: true,
      label: 'Восстановление пароля',
      child: Text(
        localizations.translate('password_recovery'),
        style: TextStyle(
          fontSize: (isTablet ? 32 : 28) * adaptiveTextScale,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
        ),
      ),
    );
  }

  // Основной контент
  Widget _buildContent(BuildContext context, AppLocalizations localizations,
      double adaptiveTextScale, bool isTablet, bool isSmallScreen,
      double buttonHeight) {
    if (_isSent) {
      return _buildSuccessMessage(context, localizations, adaptiveTextScale,
          isTablet, buttonHeight);
    } else {
      return _buildForm(context, localizations, adaptiveTextScale,
          isTablet, isSmallScreen, buttonHeight);
    }
  }

  // Сообщение об успешной отправке
  Widget _buildSuccessMessage(BuildContext context, AppLocalizations localizations,
      double adaptiveTextScale, bool isTablet, double buttonHeight) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Text(
                  localizations.translate('email_sent'),
                  style: TextStyle(
                    fontSize: (isTablet ? 20 : 18) * adaptiveTextScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 16 : 8),

          // Описание
          Text(
            localizations.translate('recovery_instructions_sent'),
            style: TextStyle(
              fontSize: (isTablet ? 18 : 16) * adaptiveTextScale,
              color: AppConstants.textColor,
              height: 1.4,
            ),
          ),

          SizedBox(height: isTablet ? 24 : 16),

          // Кнопка возврата к входу
          Semantics(
            button: true,
            label: 'Вернуться к экрану входа',
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: buttonHeight,
                maxHeight: buttonHeight * 1.5,
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: AppConstants.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                  ),
                  elevation: 4,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 16 : 14,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    localizations.translate('return_to_login'),
                    style: TextStyle(
                      fontSize: (isTablet ? 18 : 16) * adaptiveTextScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Форма восстановления пароля
  Widget _buildForm(BuildContext context, AppLocalizations localizations,
      double adaptiveTextScale, bool isTablet, bool isSmallScreen,
      double buttonHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Описание
        Text(
          localizations.translate('enter_email_for_recovery'),
          style: TextStyle(
            fontSize: (isTablet ? 18 : 16) * adaptiveTextScale,
            color: AppConstants.textColor,
            height: 1.4,
          ),
        ),

        SizedBox(height: isSmallScreen ? 24 : (isTablet ? 48 : 32)),

        // Поле ввода email
        _buildEmailField(context, localizations, isTablet),

        SizedBox(height: isTablet ? 24 : 16),

        // Сообщение об ошибке
        if (_errorMessage.isNotEmpty) ...[
          _buildErrorMessage(context, adaptiveTextScale, isTablet),
          SizedBox(height: isTablet ? 32 : 24),
        ] else ...[
          SizedBox(height: isTablet ? 48 : 32),
        ],

        // Кнопка отправки
        _buildSendButton(context, localizations, adaptiveTextScale, isTablet, buttonHeight),
      ],
    );
  }

  // Поле ввода email
  Widget _buildEmailField(BuildContext context, AppLocalizations localizations, bool isTablet) {
    return Semantics(
      textField: true,
      label: 'Поле ввода email адреса',
      child: Form(
        key: _formKey,
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
    );
  }

  // Сообщение об ошибке
  Widget _buildErrorMessage(BuildContext context, double adaptiveTextScale, bool isTablet) {
    return Container(
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
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: (isTablet ? 16 : 14) * adaptiveTextScale,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Кнопка отправки
  Widget _buildSendButton(BuildContext context, AppLocalizations localizations,
      double adaptiveTextScale, bool isTablet, double buttonHeight) {
    return Semantics(
      button: true,
      label: 'Отправить письмо для восстановления пароля',
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: buttonHeight,
          maxHeight: buttonHeight * 1.5, // Позволяем кнопке расти
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: AppConstants.textColor,
            disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
            ),
            elevation: _isLoading ? 0 : 4,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14, // Немного увеличили
            ),
          ),
          child: _isLoading
              ? SizedBox(
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            child: CircularProgressIndicator(
              color: AppConstants.textColor,
              strokeWidth: 2.5,
            ),
          )
              : FittedBox( // Автоматически подгоняет размер текста
            fit: BoxFit.scaleDown,
            child: Text(
              localizations.translate('send'),
              style: TextStyle(
                fontSize: (isTablet ? 20 : 18) * adaptiveTextScale,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}