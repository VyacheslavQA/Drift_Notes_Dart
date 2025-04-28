// Путь: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  await Firebase.initializeApp();

  runApp(const DriftNotesApp());
}

class DriftNotesApp extends StatelessWidget {
  const DriftNotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriftNotes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF1E2B23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2B23),
          foregroundColor: Color(0xFFD7CCA1),
        ),
        cardColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFD7CCA1),
          surface: const Color(0xFF1E2B23),
          onSurface: const Color(0xFFFFFFFF),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Задержка для отображения сплеш-экрана
    Future.delayed(const Duration(seconds: 2), () {
      // Здесь будет навигация на экран авторизации или главный экран
      // в зависимости от статуса авторизации пользователя
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/app_logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const Text(
              'DriftNotes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD7CCA1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}