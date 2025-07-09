// Путь: lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/firebase/firebase_service.dart';
import '../localization/app_localizations.dart';
import '../utils/responsive_utils.dart';
import '../constants/responsive_constants.dart';
import '../widgets/responsive/responsive_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isPressed = false;

  // Контроллеры для разных анимаций
  late AnimationController _pressAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _shimmerAnimationController;
  late AnimationController _loadingAnimationController;

  // Анимации
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _loadingRotation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPulseAnimation();
  }

  void _setupAnimations() {
    // Анимация нажатия (быстрая)
    _pressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _pressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Анимация пульсации (медленная, повторяющаяся)
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Анимация шиммера (блеск)
    _shimmerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Анимация загрузки
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.linear,
      ),
    );
  }

  void _startPulseAnimation() {
    // Запускаем пульсацию с задержкой
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isLoading) {
        _pulseAnimationController.repeat(reverse: true);

        // Запускаем шиммер периодически
        _startShimmerAnimation();
      }
    });
  }

  void _startShimmerAnimation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isLoading) {
        _shimmerAnimationController.forward().then((_) {
          _shimmerAnimationController.reset();
          // Повторяем шиммер каждые 4 секунды
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted && !_isLoading) {
              _startShimmerAnimation();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _pressAnimationController.dispose();
    _pulseAnimationController.dispose();
    _shimmerAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  // Обработка нажатия кнопки входа
  void _handleLogin() {
    if (_isLoading) return;

    // Системная вибрация
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    // Останавливаем пульсацию и шиммер
    _pulseAnimationController.stop();
    _shimmerAnimationController.stop();

    // Запускаем анимацию загрузки
    _loadingAnimationController.repeat();

    // Имитируем небольшую задержку для анимации
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (_firebaseService.isUserLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/auth_selection');
        }
      }
    });
  }

  void _handleExit() {
    SystemNavigator.pop();
  }

  Widget _buildAnimatedButton() {
    final screenSize = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context);

    // Простые адаптивные размеры
    final bool isTablet = screenSize.width >= 600;
    final double buttonWidth = isTablet
        ? (screenSize.width * 0.6).clamp(200.0, 400.0)
        : screenSize.width * 0.8;
    final double buttonHeight = isTablet ? 64.0 : 56.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressAnimationController,
        _pulseAnimationController,
        _shimmerAnimationController,
        _loadingAnimationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value *
              (_isLoading ? 1.0 : _pulseAnimation.value),
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                // Основная тень
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: _isLoading ? 8 : 12,
                  spreadRadius: _isLoading ? 0 : 1,
                  offset: const Offset(0, 4),
                ),
                // Дополнительная тень для глубины
                if (!_isLoading)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: Stack(
                children: [
                  // Основной фон кнопки
                  Container(
                    decoration: BoxDecoration(
                      color: _isPressed
                          ? AppConstants.textColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: AppConstants.textColor,
                        width: 1.0,
                      ),
                    ),
                  ),

                  // Шиммер эффект
                  if (!_isLoading)
                    Positioned(
                      left: _shimmerAnimation.value * buttonWidth * 0.5,
                      child: Container(
                        width: buttonWidth * 0.3,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Содержимое кнопки
                  Center(
                    child: _isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _loadingRotation.value * 2 * 3.14159,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          localizations.translate('biting'),
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    )
                        : Text(
                      localizations.translate('enter'),
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Overlay для эффекта нажатия
                  if (_isPressed)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    // Простая адаптивность
    final bool isTablet = screenSize.width >= 600;
    final bool isSmallScreen = screenSize.height < 600;

    // Адаптивные размеры шрифтов
    final double titleFontSize = (isTablet ? 60 : (isSmallScreen ? 42 : 54)) *
        (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1);
    final double subtitleFontSize = (isTablet ? 22 : (isSmallScreen ? 16 : 20)) *
        (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Используем доступную высоту для расчета отступов
                final double contentHeight = constraints.maxHeight;
                final double buttonHeight = isTablet ? 64.0 : 56.0;
                final double totalFixedHeight = titleFontSize +
                    (subtitleFontSize * 2) +
                    buttonHeight +
                    200; // Приблизительная высота фиксированного контента

                // Если контент не помещается, делаем экран прокручиваемым
                if (totalFixedHeight > contentHeight) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 16.0,
                      vertical: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: contentHeight,
                      ),
                      child: _buildContentWithIntrinsicHeight(context, isTablet, isSmallScreen, titleFontSize, subtitleFontSize),
                    ),
                  );
                } else {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 16.0,
                      vertical: 16.0,
                    ),
                    child: _buildContent(context, isTablet, isSmallScreen, titleFontSize, subtitleFontSize),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Версия контента с фиксированными отступами (для прокрутки)
  Widget _buildContentWithIntrinsicHeight(BuildContext context, bool isTablet, bool isSmallScreen, double titleFontSize, double subtitleFontSize) {
    final screenSize = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context);

    return IntrinsicHeight(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Верхний отступ
          SizedBox(height: isSmallScreen ? 40 : (isTablet ? 80 : 60)),

          // Заголовок приложения
          Text(
            'Drift Notes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),

          SizedBox(height: isTablet ? 32 : (isSmallScreen ? 16 : 24)),

          // Подзаголовок
          Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : screenSize.width * 0.85,
            ),
            child: Text(
              localizations.translate('your_personal_fishing_journal'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 8 : 16),

          // Дополнительный текст
          Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : screenSize.width * 0.85,
            ),
            child: Text(
              localizations.translate('remember_great_trips'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.white,
              ),
            ),
          ),

          // Средний отступ
          SizedBox(height: isSmallScreen ? 60 : (isTablet ? 120 : 80)),

          // Кнопка входа
          GestureDetector(
            onTapDown: (_) {
              if (!_isLoading) {
                setState(() {
                  _isPressed = true;
                });
                _pressAnimationController.forward();
              }
            },
            onTapUp: (_) {
              if (!_isLoading) {
                setState(() {
                  _isPressed = false;
                });
                _pressAnimationController.reverse();
                _handleLogin();
              }
            },
            onTapCancel: () {
              if (!_isLoading) {
                setState(() {
                  _isPressed = false;
                });
                _pressAnimationController.reverse();
              }
            },
            child: _buildAnimatedButton(),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Кнопка "Выход"
          TextButton(
            onPressed: _isLoading ? null : _handleExit,
            child: Text(
              localizations.translate('exit'),
              style: TextStyle(
                color: _isLoading ? Colors.white38 : Colors.white70,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 40 : (isTablet ? 80 : 60)),
        ],
      ),
    );
  }

  // Версия контента с гибкими отступами (без прокрутки)
  Widget _buildContent(BuildContext context, bool isTablet, bool isSmallScreen, double titleFontSize, double subtitleFontSize) {
    final screenSize = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Гибкий верхний отступ
        Expanded(
          flex: isSmallScreen ? 1 : (isTablet ? 3 : 2),
          child: Container(),
        ),

        // Заголовок приложения
        Text(
          'Drift Notes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ),

        SizedBox(height: isTablet ? 32 : (isSmallScreen ? 16 : 24)),

        // Подзаголовок
        Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : screenSize.width * 0.85,
          ),
          child: Text(
            localizations.translate('your_personal_fishing_journal'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 8 : 16),

        // Дополнительный текст
        Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : screenSize.width * 0.85,
          ),
          child: Text(
            localizations.translate('remember_great_trips'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.white,
            ),
          ),
        ),

        // Гибкий средний отступ
        Expanded(
          flex: isSmallScreen ? 2 : (isTablet ? 4 : 3),
          child: Container(),
        ),

        // Кнопка входа
        GestureDetector(
          onTapDown: (_) {
            if (!_isLoading) {
              setState(() {
                _isPressed = true;
              });
              _pressAnimationController.forward();
            }
          },
          onTapUp: (_) {
            if (!_isLoading) {
              setState(() {
                _isPressed = false;
              });
              _pressAnimationController.reverse();
              _handleLogin();
            }
          },
          onTapCancel: () {
            if (!_isLoading) {
              setState(() {
                _isPressed = false;
              });
              _pressAnimationController.reverse();
            }
          },
          child: _buildAnimatedButton(),
        ),

        SizedBox(height: isTablet ? 32 : 24),

        // Кнопка "Выход"
        TextButton(
          onPressed: _isLoading ? null : _handleExit,
          child: Text(
            localizations.translate('exit'),
            style: TextStyle(
              color: _isLoading ? Colors.white38 : Colors.white70,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 16 : (isTablet ? 48 : 32)),
      ],
    );
  }
}