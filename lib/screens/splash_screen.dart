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

class _SplashScreenState extends State<SplashScreen> {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  // Обработка нажатия кнопки входа
  void _handleLogin() {
    setState(() {
      _isLoading = true;
    });

    // Если пользователь уже авторизован, направляем на главный экран
    if (_firebaseService.isUserLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Если не авторизован, переходим на экран выбора способа входа
      Navigator.of(context).pushReplacementNamed('/auth_selection');
    }
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

                // Кнопка входа
                SizedBox(
                  width: screenSize.width * 0.8,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppConstants.textColor,
                      side: BorderSide(color: AppConstants.textColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      padding: EdgeInsets.zero, // Убираем отступы
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
                        : const Center( // Добавляем явное центрирование
                      child: Text(
                        'ВОЙТИ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.0, // Фиксируем высоту строки
                        ),
                      ),
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