// Путь: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Инициализация Firebase
    await Firebase.initializeApp();
    print('Firebase инициализирован успешно');
  } catch (e) {
    print('Ошибка инициализации Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriftNotes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const TestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DriftNotes Тест'),
      ),
      body: const Center(
        child: Text(
          'Тестовый экран',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}