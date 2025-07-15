// Путь: lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/user_consent_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';
import '../../utils/network_utils.dart';
import '../../widgets/user_agreements_dialog.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginScreen({super.key, this.onAuthSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _userConsentService = UserConsentService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMessage = '';

  // Офлайн режим
  bool _isOfflineMode = false;
  bool _hasInternet = true;
  bool _canAuthenticateOffline = false;
  bool _checkingConnection = false;

  // Ключи для сохранения данных
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkNetworkStatusAndOfflineCapability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Проверка сетевого статуса и возможности офлайн авторизации
  Future<void> _checkNetworkStatusAndOfflineCapability() async {
    setState(() {
      _checkingConnection = true;
    });

    try {
      final hasInternet = await NetworkUtils.isNetworkAvailable();
      final canOfflineAuth = await _firebaseService.canAuthenticateOffline();

      setState(() {
        _hasInternet = hasInternet;
        _canAuthenticateOffline = canOfflineAuth;
        _isOfflineMode = !hasInternet;
      });

      debugPrint('🌐 Сетевой статус: ${hasInternet ? 'Онлайн' : 'Офлайн'}');
      debugPrint('📱 Офлайн авторизация: ${canOfflineAuth ? 'Доступна' : 'Недоступна'}');
    } catch (e) {
      debugPrint('❌ Ошибка проверки сетевого статуса: $e');
      setState(() {
        _hasInternet = false;
        _canAuthenticateOffline = false;
      });
    } finally {
      setState(() {
        _checkingConnection = false;
      });
    }
  }

  /// Повторная проверка подключения
  Future<void> _refreshConnection() async {
    await _checkNetworkStatusAndOfflineCapability();

    if (_hasInternet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('internet_connection_restored')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Загрузка сохраненных данных при открытии экрана
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

      if (rememberMe) {
        final savedEmail = prefs.getString(_keySavedEmail) ?? '';
        final savedPasswordHash = prefs.getString(_keySavedPassword) ?? '';

        if (savedEmail.isNotEmpty && savedPasswordHash.isNotEmpty) {
          try {
            final decodedPassword = utf8.decode(base64Decode(savedPasswordHash));

            setState(() {
              _emailController.text = savedEmail;
              _passwordController.text = decodedPassword;
              _rememberMe = true;
            });
          } catch (e) {
            debugPrint('Ошибка при расшифровке сохраненного пароля: $e');
            await _clearSavedCredentials();
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке сохраненных данных: $e');
    }
  }

  /// Сохранение данных для входа
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        final encodedPassword = base64Encode(utf8.encode(password));
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keySavedEmail, email);
        await prefs.setString(_keySavedPassword, encodedPassword);
        debugPrint('Данные для входа сохранены');
      } else {
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении данных для входа: $e');
    }
  }

  /// Очистка сохраненных данных
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

  /// ✅ ИСПРАВЛЕНО: Проверка и создание профиля пользователя БЕЗ автоматических согласий
  Future<void> _ensureUserProfileExists(String email, String? displayName) async {
    try {
      final existingProfile = await _firebaseService.getUserProfile();

      if (!existingProfile.exists) {
        // Создаем профиль БЕЗ автоматических согласий
        await _firebaseService.createUserProfile({
          'email': email,
          'displayName': displayName ?? '',
          'photoUrl': '',
          'authProvider': 'email',
          'country': '',
          'city': '',
          'experience': 'beginner',
          'fishingTypes': ['Обычная рыбалка'],
        });

        debugPrint('✅ Создан профиль для пользователя: $email');
      } else {
        debugPrint('✅ Профиль пользователя уже существует: $email');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке/создании профиля пользователя: $e');
    }
  }

  /// ✅ ИСПРАВЛЕНО: Проверка согласий через UserConsentService
  Future<bool> _checkUserConsents() async {
    try {
      final result = await _userConsentService.checkUserConsents();

      debugPrint('🔍 Проверка согласий: ${result.toString()}');

      // Если все согласия действительны - возвращаем true
      return result.allValid;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      // При ошибке считаем что согласия НЕ приняты
      return false;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Показ диалога согласий с правильной обработкой
  Future<bool> _showAgreementsDialog() async {
    try {
      bool agreementsAccepted = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false, // Нельзя закрыть нажатием вне диалога
        builder: (BuildContext context) {
          return UserAgreementsDialog(
            onAgreementsAccepted: () {
              // Пользователь принял соглашения
              agreementsAccepted = true;
              debugPrint('✅ Пользователь принял соглашения');
            },
            onCancel: () {
              // Пользователь отклонил соглашения
              agreementsAccepted = false;
              debugPrint('❌ Пользователь отклонил соглашения');
            },
          );
        },
      );

      return agreementsAccepted;
    } catch (e) {
      debugPrint('❌ Ошибка при показе диалога согласий: $e');
      return false;
    }
  }

  /// Основной метод авторизации с поддержкой офлайн
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Проверяем подключение к интернету
      final hasInternet = await NetworkUtils.isNetworkAvailable();

      if (hasInternet) {
        // ОНЛАЙН АВТОРИЗАЦИЯ
        await _performOnlineLogin(email, password);
      } else {
        // ОФЛАЙН АВТОРИЗАЦИЯ
        await _performOfflineLogin(email, password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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

  /// ✅ ИСПРАВЛЕНО: Онлайн авторизация с правильной проверкой согласий
  Future<void> _performOnlineLogin(String email, String password) async {
    debugPrint('🌐 Выполняем онлайн авторизацию');

    try {
      // Выполняем обычную авторизацию
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
        context,
      );

      if (userCredential.user != null) {
        // Создаем профиль БЕЗ автоматических согласий
        await _ensureUserProfileExists(
          email,
          userCredential.user!.displayName,
        );

        // ✅ НОВАЯ ЛОГИКА: Проверяем согласия ПОСЛЕ создания профиля
        final hasValidConsents = await _checkUserConsents();

        if (!hasValidConsents) {
          debugPrint('⚠️ Согласия НЕ приняты - показываем диалог');

          // Показываем ОБЯЗАТЕЛЬНЫЙ диалог согласий
          final agreementsAccepted = await _showAgreementsDialog();

          if (!agreementsAccepted) {
            // Пользователь отклонил согласия - выходим из аккаунта
            debugPrint('❌ Пользователь отклонил согласия - выход из аккаунта');
            await _firebaseService.signOut();

            if (mounted) {
              setState(() {
                _errorMessage = AppLocalizations.of(context).translate('agreements_required')
                    ?? 'Для использования приложения необходимо принять соглашения';
              });
            }
            return; // Прерываем процесс входа
          }
        }

        debugPrint('✅ Согласия проверены - продолжаем вход');

        // Кэшируем данные пользователя для офлайн режима
        await _firebaseService.cacheUserDataForOffline(userCredential.user!);
        debugPrint('✅ Данные пользователя закэшированы для офлайн режима');
      }

      await _saveCredentials(email, password);
      await _proceedToHomeScreen('login_successful');
    } catch (e) {
      debugPrint('❌ Ошибка онлайн авторизации: $e');

      // Если Firebase недоступен, пробуем офлайн авторизацию
      if (e.toString().contains('network') || e.toString().contains('unavailable')) {
        debugPrint('🔄 Переключаемся на офлайн авторизацию из-за сетевой ошибки');
        await _performOfflineLogin(email, password);
      } else {
        rethrow;
      }
    }
  }

  /// ✅ ИСПРАВЛЕНО: Офлайн авторизация БЕЗ проверки согласий
  Future<void> _performOfflineLogin(String email, String password) async {
    debugPrint('📱 Выполняем офлайн авторизацию');

    try {
      final canOfflineAuth = await _firebaseService.canAuthenticateOffline();

      if (!canOfflineAuth) {
        throw Exception(AppLocalizations.of(context).translate('offline_auth_unavailable'));
      }

      // Пытаемся выполнить офлайн авторизацию
      final success = await _firebaseService.tryOfflineAuthentication();

      if (success) {
        // ✅ ИСПРАВЛЕНО: Офлайн авторизация БЕЗ проверки согласий
        // В офлайн режиме полагаемся на ранее принятые согласия
        // (проверка согласий требует онлайн подключения)

        await _saveCredentials(email, password);
        await _proceedToHomeScreen('offline_login_successful');
        debugPrint('✅ Офлайн авторизация успешна');
      } else {
        throw Exception(AppLocalizations.of(context).translate('offline_auth_failed'));
      }
    } catch (e) {
      debugPrint('❌ Ошибка офлайн авторизации: $e');
      rethrow;
    }
  }

  /// Переход к главному экрану после успешной авторизации
  Future<void> _proceedToHomeScreen(String successMessageKey) async {
    if (mounted) {
      final localizations = AppLocalizations.of(context);
      final message = successMessageKey == 'offline_login_successful'
          ? localizations.translate('offline_login_successful')
          : localizations.translate('login_successful');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _isOfflineMode ? Colors.orange : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      if (widget.onAuthSuccess != null) {
        debugPrint('🎯 Вызываем коллбэк после успешной авторизации');
        Navigator.of(context).pushReplacementNamed('/home');
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onAuthSuccess!();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    }
  }

  /// Показать диалог для офлайн авторизации
  Future<void> _showOfflineAuthDialog() async {
    if (!_canAuthenticateOffline) {
      _showOfflineAuthError();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context).translate('offline_mode')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('no_internet_connection')),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context).translate('can_login_offline')),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('offline_mode_limited'),
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).translate('login_offline')),
          ),
        ],
      ),
    );

    if (result == true) {
      await _performOfflineLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  /// Показать ошибку невозможности офлайн авторизации
  void _showOfflineAuthError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context).translate('offline_auth_unavailable_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('offline_auth_requirements')),
            SizedBox(height: 8),
            Text('• ${AppLocalizations.of(context).translate('login_with_internet_first')}'),
            Text('• ${AppLocalizations.of(context).translate('cache_user_data')}'),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context).translate('connect_internet_try_again')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('ok')),
          ),
        ],
      ),
    );
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

    final adaptiveScale = scale > 1.3 ? 1.3 / scale : 1.0;
    final fontSize = (isTablet ? baseFontSize * 1.2 : baseFontSize) * adaptiveScale;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppConstants.textColor,
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
    Color? textColor,
    Color? borderColor,
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
            backgroundColor: backgroundColor ?? Colors.transparent,
            foregroundColor: textColor ?? AppConstants.textColor,
            side: BorderSide(color: borderColor ?? AppConstants.textColor),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
            width: isTablet ? 24 : 20,
            height: isTablet ? 24 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor ?? AppConstants.textColor),
            ),
          )
              : FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              text,
              baseFontSize: 16.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppConstants.textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Индикатор статуса сети
  Widget _buildNetworkStatusIndicator(bool isTablet) {
    if (_checkingConnection) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
              ),
            ),
            SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).translate('checking_connection'),
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppConstants.textColor,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasInternet) {
      return GestureDetector(
        onTap: _refreshConnection,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).translate('no_connection'),
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.refresh, size: 14, color: Colors.orange),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 16, color: Colors.green),
          SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).translate('connected'),
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppConstants.authGradient,
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
                      // Кнопка назад и статус сети
                      Row(
                        children: [
                          Semantics(
                            label: localizations.translate('go_back'),
                            hint: localizations.translate('return_to_previous_screen'),
                            button: true,
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
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacementNamed(context, '/auth_selection');
                                  }
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildNetworkStatusIndicator(isTablet),
                        ],
                      ),

                      SizedBox(height: isTablet ? 32 : 24),

                      // Заголовок и логотип
                      Column(
                        children: [
                          _buildSafeText(
                            context,
                            localizations.translate('login_with_email_title'),
                            baseFontSize: 24.0,
                            isTablet: isTablet,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Логотип
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: isTablet ? 100 : 80,
                            height: isTablet ? 100 : 80,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: isTablet ? 100 : 80,
                                height: isTablet ? 100 : 80,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.phishing,
                                  size: isTablet ? 50 : 40,
                                  color: AppConstants.textColor,
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          _buildSafeText(
                            context,
                            'Drift Notes',
                            baseFontSize: 30.0,
                            isTablet: isTablet,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 48 : 36),

                      // Форма входа
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email поле
                            _buildInputField(
                              context: context,
                              controller: _emailController,
                              hintText: localizations.translate('email'),
                              prefixIcon: Icons.email,
                              validator: (value) => Validators.validateEmail(value, context),
                              textInputAction: TextInputAction.next,
                              isTablet: isTablet,
                            ),

                            SizedBox(height: isTablet ? 24 : 16),

                            // Password поле
                            _buildInputField(
                              context: context,
                              controller: _passwordController,
                              hintText: localizations.translate('password'),
                              prefixIcon: Icons.lock,
                              obscureText: _obscurePassword,
                              validator: (value) => Validators.validatePassword(value, context),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              isTablet: isTablet,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppConstants.textColor,
                                  size: isTablet ? 28 : 24,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  minimumSize: Size(48, 48),
                                ),
                              ),
                            ),

                            SizedBox(height: isTablet ? 16 : 12),

                            // Чекбокс и ссылка забыли пароль
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRememberMeCheckbox(context, isTablet),
                                _buildForgotPasswordButton(context, isTablet),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isTablet ? 40 : 32),

                      // Сообщение об ошибке
                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          constraints: BoxConstraints(minHeight: 48),
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildSafeText(
                            context,
                            _errorMessage,
                            baseFontSize: 14.0,
                            isTablet: isTablet,
                            color: Colors.redAccent,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ),
                      ],

                      // Кнопка входа (основная)
                      _buildSafeButton(
                        context: context,
                        text: _hasInternet ? localizations.translate('login') : localizations.translate('login_online'),
                        onPressed: _isLoading ? null : _login,
                        isTablet: isTablet,
                        isLoading: _isLoading,
                        semanticLabel: localizations.translate('login_to_app'),
                      ),

                      // Кнопка офлайн входа (если нет интернета)
                      if (!_hasInternet) ...[
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildSafeButton(
                          context: context,
                          text: localizations.translate('login_offline'),
                          onPressed: _canAuthenticateOffline && !_isLoading ? _showOfflineAuthDialog : null,
                          isTablet: isTablet,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          textColor: _canAuthenticateOffline ? Colors.orange : Colors.grey,
                          borderColor: _canAuthenticateOffline ? Colors.orange : Colors.grey,
                          semanticLabel: localizations.translate('login_offline_mode'),
                        ),
                      ],

                      SizedBox(height: isTablet ? 24 : 16),

                      // Ссылка на регистрацию
                      _buildRegistrationLink(context, isTablet),
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

  /// Безопасное поле ввода
  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    required bool isTablet,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 48,
        maxHeight: 72,
      ),
      child: TextFormField(
        controller: controller,
        onTap: () {
          Future.microtask(() {
            if (controller.selection.start == 0 &&
                controller.selection.end == controller.text.length) {
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
            }
          });
        },
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppConstants.textColor.withOpacity(0.5),
            fontSize: isTablet ? 18 : 16,
          ),
          filled: true,
          fillColor: const Color(0xFF12332E),
          prefixIcon: Icon(
            prefixIcon,
            color: AppConstants.textColor,
            size: isTablet ? 28 : 24,
          ),
          suffixIcon: suffixIcon,
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
          errorStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: isTablet ? 14 : 12,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
        ),
        obscureText: obscureText,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  /// Чекбокс "Запомнить меня"
  Widget _buildRememberMeCheckbox(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
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
              color: AppConstants.textColor.withOpacity(0.5),
              width: 1.5,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Container(
              constraints: BoxConstraints(minHeight: 48),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _buildSafeText(
                  context,
                  localizations.translate('remember_me'),
                  baseFontSize: 13.0,
                  isTablet: isTablet,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Кнопка "Забыли пароль?"
  Widget _buildForgotPasswordButton(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: localizations.translate('forgot_password'),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 48,
          minWidth: 48,
        ),
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot_password');
          },
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.textColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildSafeText(
              context,
              localizations.translate('forgot_password'),
              baseFontSize: 13.0,
              isTablet: isTablet,
            ),
          ),
        ),
      ),
    );
  }

  /// Ссылка на регистрацию
  Widget _buildRegistrationLink(BuildContext context, bool isTablet) {
    final localizations = AppLocalizations.of(context);
    final registrationText = localizations.translate('no_account_register');
    final parts = registrationText.split('?');

    if (parts.length < 2) {
      return _buildSafeText(
        context,
        registrationText,
        baseFontSize: 14.0,
        isTablet: isTablet,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _buildSafeText(
            context,
            '${parts[0]}? ',
            baseFontSize: 14.0,
            isTablet: isTablet,
            color: AppConstants.textColor.withOpacity(0.7),
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: _buildSafeText(
              context,
              parts[1],
              baseFontSize: 14.0,
              isTablet: isTablet,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
        ),
      ],
    );
  }
}