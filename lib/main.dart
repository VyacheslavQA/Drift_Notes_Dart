// Путь: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'constants/app_constants.dart';
import 'screens/auth/auth_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'firebase_options.dart'; // Добавьте этот импорт
import 'firebase_options.dart'; // Используем сгенерированный файл

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Устанавливаем ориентацию экрана только на портретный режим
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Инициализация Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase успешно инициализирован');
  } catch (e) {
    debugPrint('Ошибка инициализации Firebase: $e');
  }

  runApp(const DriftNotesApp());
}

class DriftNotesApp extends StatelessWidget {
  const DriftNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drift Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: AppConstants.textColor,
            displayColor: AppConstants.textColor,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppConstants.textColor,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ),
        cardTheme: CardTheme(
          color: AppConstants.surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        colorScheme: ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor, // Теперь это светло-бежевый вместо голубого
          surface: AppConstants.surfaceColor,
          background: AppConstants.backgroundColor,
          onPrimary: AppConstants.textColor,
          onSecondary: Colors.black, // Черный текст на светло-бежевом фоне для контраста
          onSurface: AppConstants.textColor,
          onBackground: AppConstants.textColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.textColor,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.surfaceColor,
          hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConstants.textColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      // Начальный экран приложения
      home: const SplashScreen(),
      // Определение маршрутов для навигации
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth_selection': (context) => const AuthSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}