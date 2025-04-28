// Путь: lib/screens/auth/auth_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана для адаптивности
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenSize.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                SizedBox(height: screenSize.height * 0.05),

                // Логотип приложения
                Container(
                  width: screenSize.width * 0.3,
                  height: screenSize.width * 0.3,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A392A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      color: AppConstants.accentColor,
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),

                // Название приложения
                Text(
                  'Drift Notes',
                  style: TextStyle(
                    fontSize: 36 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.accentColor,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.05),

                // Заголовок "Выберите способ входа"
                Text(
                  'Выберите способ входа',
                  style: TextStyle(
                    fontSize: 24 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.01),

                // Подзаголовок
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
                  child: Text(
                    'Выберите удобный для вас способ входа в приложение',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                      color: Colors.white70,
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.04),

                // Кнопка входа через Email
                _buildAuthButton(
                  context: context,
                  icon: Icons.email_outlined,
                  text: 'ВОЙТИ С ПОМОЩЬЮ EMAIL',
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  width: screenSize.width * 0.85,
                ),
                SizedBox(height: screenSize.height * 0.02),

                // Кнопка входа по номеру телефона
                _buildAuthButton(
                  context: context,
                  icon: Icons.phone,
                  text: 'ВОЙТИ ПО НОМЕРУ ТЕЛЕФОНА',
                  onPressed: () {
                    // Можно реализовать вход по телефону
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Вход по номеру телефона будет доступен позже')),
                    );
                  },
                  width: screenSize.width * 0.85,
                ),
                SizedBox(height: screenSize.height * 0.02),

                // Кнопка входа через Google
                SizedBox(
                  width: screenSize.width * 0.85,
                  child: ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                    ),
                    label: Text(
                      'ВОЙТИ ЧЕРЕЗ GOOGLE',
                      style: TextStyle(
                        fontSize: 16 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    onPressed: () {
                      // Реализация входа через Google
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Вход через Google будет доступен позже')),
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Ссылка на регистрацию
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    'Еще нет аккаунта? Зарегистрироваться',
                    style: TextStyle(
                      color: AppConstants.accentColor,
                      fontSize: 16 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                    ),
                  ),
                ),

                // Кнопка "Назад"
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Назад',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Метод для создания кнопок авторизации
  Widget _buildAuthButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required double width,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppConstants.accentColor),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
            color: AppConstants.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppConstants.accentColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}