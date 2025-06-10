// Путь: lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';
import '../help/privacy_policy_screen.dart';
import '../help/terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const RegisterScreen({
    super.key,
    this.onAuthSuccess,
  });

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
  bool _acceptedTermsAndPrivacy = false; // Изменили название переменной
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
        if (!_confirmPasswordFieldFocused &&
            _confirmPasswordController.text.isNotEmpty) {
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

  // Функция для сохранения согласий пользователя в Firebase
  Future<void> _saveUserConsents(String userId) async {
    try {
      final consentsData = {
        'userId': userId,
        'privacyPolicyAccepted': true,
        'termsOfServiceAccepted': true,
        'consentDate': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // Можно получить из package_info_plus
        'deviceInfo': {
          'platform': Theme.of(context).platform.name,
          // Можно добавить больше информации об устройстве
        },
      };

      await FirebaseFirestore.instance
          .collection('user_consents')
          .doc(userId)
          .set(consentsData);

      debugPrint('✅ Согласия пользователя сохранены в Firebase');
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
      final userCredential = await _firebaseService.registerWithEmailAndPassword(
        email,
        password,
        context,
      );

      final user = userCredential.user;

      if (user != null) {
        // Обновляем имя пользователя
        await user.updateDisplayName(name);

        // Сохраняем согласия пользователя в Firestore
        await _saveUserConsents(user.uid);

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
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
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
                  onPressed: () {
                    // Безопасный возврат назад
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // Если не можем вернуться назад, переходим к экрану выбора авторизации
                      Navigator.pushReplacementNamed(context, '/auth_selection');
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                // Основной контент в Expanded для автоматического распределения
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Верхняя часть: заголовок без логотипа
                      Column(
                        children: [
                          // Заголовок экрана - увеличенный размер
                          Text(
                            localizations.translate('registration'),
                            style: TextStyle(
                              fontSize: 32 * adaptiveTextScale,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Подзаголовок - увеличенный размер
                          Text(
                            localizations.translate('create_account_access'),
                            style: TextStyle(
                              fontSize: 16 * adaptiveTextScale,
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Название приложения - увеличенный размер
                          Text(
                            'Drift Notes',
                            style: TextStyle(
                              fontSize: 36 * adaptiveTextScale,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                          ),
                        ],
                      ),

                      // Средняя часть: форма регистрации
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Поле для имени - компактная версия
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
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
                                  vertical: 16, // Увеличенный padding
                                ),
                              ),
                              validator: (value) => Validators.validateName(value, context),
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 16), // Увеличенный отступ

                            // Поле для email - компактная версия
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
                                  vertical: 16, // Увеличенный padding
                                ),
                              ),
                              validator: (value) => Validators.validateEmail(value, context),
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 16), // Увеличенный отступ

                            // Поле для пароля - возвращаем нормальную ширину
                            Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
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
                                      vertical: 16, // Увеличенный padding
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) => Validators.validatePassword(value, context),
                                  textInputAction: TextInputAction.next,
                                ),

                                // Требования к паролю под полем
                                if (_passwordFieldFocused || _passwordController.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12332E).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _hasMinLength ? Icons.check_circle : Icons.cancel,
                                              color: _hasMinLength ? Colors.green : Colors.red.withValues(alpha: 0.7),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '8+ симв.',
                                              style: TextStyle(
                                                color: _hasMinLength ? Colors.green : AppConstants.textColor.withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _hasUppercase ? Icons.check_circle : Icons.cancel,
                                              color: _hasUppercase ? Colors.green : Colors.red.withValues(alpha: 0.7),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'A-Z',
                                              style: TextStyle(
                                                color: _hasUppercase ? Colors.green : AppConstants.textColor.withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _hasNumber ? Icons.check_circle : Icons.cancel,
                                              color: _hasNumber ? Colors.green : Colors.red.withValues(alpha: 0.7),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '0-9',
                                              style: TextStyle(
                                                color: _hasNumber ? Colors.green : AppConstants.textColor.withValues(alpha: 0.7),
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

                            const SizedBox(height: 16), // Увеличенный отступ

                            // Поле для подтверждения пароля - нормальной ширины
                            TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              style: const TextStyle(
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
                                  vertical: 16, // Увеличенный padding
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

                            // Индикатор совпадения паролей - только при ошибке
                            if (_showPasswordMatchError)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      localizations.translate('passwords_dont_match'),
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Чекбокс с пользовательским соглашением и политикой - увеличенный
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
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
                                    TextSpan(
                                      text: localizations.translate('i_have_read_and_agree'),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: 'Пользовательским соглашением',
                                      style: TextStyle(
                                        color: AppConstants.primaryColor,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _showTermsOfService,
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: localizations.translate('and'),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: localizations.translate('privacy_policy_agreement'),
                                      style: TextStyle(
                                        color: AppConstants.primaryColor,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _showPrivacyPolicy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Нижняя часть: ошибка и кнопки
                      Column(
                        children: [
                          // Сообщение об ошибке - компактная версия
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12 * adaptiveTextScale,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Кнопка регистрации - увеличенная версия
                          SizedBox(
                            width: double.infinity,
                            height: 56, // Увеличенная высота
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_acceptedTermsAndPrivacy || !_passwordsMatch) ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppConstants.textColor,
                                side: BorderSide(color: AppConstants.textColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: EdgeInsets.zero,
                                disabledBackgroundColor: Colors.transparent,
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppConstants.textColor,
                                  ),
                                ),
                              )
                                  : Text(
                                localizations.translate('register'),
                                style: TextStyle(
                                  fontSize: 16 * adaptiveTextScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Ссылка на вход
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.translate('already_have_account').split('?')[0] + '? ',
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 14 * adaptiveTextScale,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: Text(
                                  localizations.translate('already_have_account').split('? ')[1],
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