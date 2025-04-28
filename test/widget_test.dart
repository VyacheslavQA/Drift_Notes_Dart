// Путь: test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Импортируем main.dart из корневой директории проекта
import '../lib/main.dart';

void main() {
  testWidgets('Проверка загрузки приложения', (WidgetTester tester) async {
    // Создаем экземпляр нашего приложения
    await tester.pumpWidget(const MyApp());

    // В тесте просто проверяем, что приложение запускается без ошибок
    expect(find.byType(MyApp), findsOneWidget);
  });
}