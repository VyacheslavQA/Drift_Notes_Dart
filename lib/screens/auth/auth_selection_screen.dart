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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Центрируем содержимое
            children: [
              // Логотип приложения
              SizedBox(
                width: screenSize.width * 0.5,
                height: screenSize.width * 0.5,
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Название приложения
              Text(
                'Drift Notes',
                style: TextStyle(
                  fontSize: 36 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentColor,
                ),
              ),
              const SizedBox(height: 24),

              // Заголовок "Выберите способ входа"
              Text(
                'Выберите способ входа',
                style: TextStyle(
                  fontSize: 24 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Подзаголовок
              Text(
                'Выберите удобный для вас способ входа в приложение',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * (textScaleFactor > 1.2 ? 1.2 / textScaleFactor : 1),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 36),

              // Кнопка входа через Email
              _buildAuthButton(
                context: context,
                icon: Icons.email_outlined,
                text: 'ВОЙТИ С ПОМОЩЬЮ EMAIL',
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
              const SizedBox(height: 16),

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
              ),
              const SizedBox(height: 16),

              // Кнопка входа через Google
              SizedBox(
                width: double.infinity, // Занимает всю ширину
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
              const SizedBox(height: 24),

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

              // Удалена кнопка "Назад", чтобы сэкономить место
            ],
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
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return SizedBox(
      width: double.infinity, // Занимает всю доступную ширину
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