// Путь: lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
                    fontSize: 48 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.accentColor,
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
                      fontSize: 24 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
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
                      fontSize: 22 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/auth_selection');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppConstants.accentColor,
                      side: const BorderSide(color: AppConstants.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: const Text(
                      'ВОЙТИ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.03),

                // Кнопка "Выход" вместо "Назад"
                TextButton(
                  onPressed: () {
                    // Выход из приложения
                    SystemNavigator.pop();
                  },
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