import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DriftNotes App Basic Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Мокаем SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Basic widget creation test', (WidgetTester tester) async {
      // Простой тест создания виджета
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Test App'),
          ),
        ),
      );

      // Проверяем, что виджет создается
      expect(find.text('Test App'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Material app components work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Center(
              child: Text('Hello World'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}