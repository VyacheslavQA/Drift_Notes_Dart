import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:drift_notes_dart/main.dart';
import 'package:drift_notes_dart/providers/timer_provider.dart';
import 'package:drift_notes_dart/providers/statistics_provider.dart';
import 'package:drift_notes_dart/providers/language_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => TimerProvider()),
          ChangeNotifierProvider(create: (context) => StatisticsProvider()),
          ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ],
        child: const DriftNotesApp(),
      ),
    );

    // Verify that our app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
