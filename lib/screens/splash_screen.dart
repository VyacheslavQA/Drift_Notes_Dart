// Путь: lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/firebase/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isPressed = false;

  // Контроллер для анимации нажатия
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Настраиваем контроллер анимации для эффекта нажатия
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        )
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Обработка нажатия кнопки входа
  void _handleLogin() {
    // Если уже идет загрузка, не выполняем повторное действие
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Имитируем небольшую задержку для анимации
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Если пользователь уже авторизован, направляем на главный экран
        if (_firebaseService.isUserLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Если не авторизован, переходим на экран выбора способа входа
          Navigator.of(context).pushReplacementNamed('/auth_selection');
        }
      }
    });
  }

  // Обработка нажатия кнопки выхода
  void _handleExit() {
    SystemNavigator.pop(); // Закрываем приложение
  }

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана для адаптивности
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Заголовок приложения
                Text(
                  'Drift Notes',
                  style: TextStyle(
                    fontSize: 54 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),

                // Подзаголовок
                SizedBox(
                  width: screenSize.width * 0.8,
                  child: Text(
                    'Твой личный журнал рыбалки',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),

                // Дополнительный текст
                SizedBox(
                  width: screenSize.width * 0.8,
                  child: Text(
                    'Запоминай клёвые выезды',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                      color: Colors.white,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Кнопка входа - с эффектом нажатия
                SizedBox(
                  width: screenSize.width * 0.8,
                  height: 50,
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isPressed = true;
                      });
                      _animationController.forward();
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isPressed = false;
                      });
                      _animationController.reverse();
                      _handleLogin();
                    },
                    onTapCancel: () {
                      setState(() {
                        _isPressed = false;
                      });
                      _animationController.reverse();
                    },
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isPressed
                                  ? AppConstants.textColor.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25.0),
                              border: Border.all(
                                color: AppConstants.textColor,
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'ВОЙТИ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isLoading
                                      ? AppConstants.textColor.withOpacity(0.7)
                                      : AppConstants.textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.03),

                // Кнопка "Выход"
                TextButton(
                  onPressed: _isLoading ? null : _handleExit,
                  child: const Text(
                    'Выход',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}