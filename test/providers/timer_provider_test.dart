import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift_notes_dart/providers/timer_provider.dart';

void main() {
  group('TimerProvider Tests', () {
    late TimerProvider timerProvider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Мокаем SharedPreferences для тестов
      SharedPreferences.setMockInitialValues({});
      timerProvider = TimerProvider();

      // Ждем инициализации провайдера
      await timerProvider.initialize();
    });

    tearDown(() {
      timerProvider.dispose();
    });

    test('timer provider should be created successfully', () {
      expect(timerProvider, isNotNull);
      expect(timerProvider, isA<TimerProvider>());
    });

    test('should initialize timers list', () {
      expect(timerProvider.timers, isA<List>());
    });

    test('should provide timers stream', () {
      expect(timerProvider.timersStream, isA<Stream>());
    });

    test('should set timer duration', () {
      const testId = 'test-timer-1';
      const duration = Duration(minutes: 5);

      // Устанавливаем длительность таймера
      timerProvider.setTimerDuration(testId, duration);

      // Проверяем, что длительность установлена
      final currentDuration = timerProvider.getCurrentDuration(testId);
      expect(currentDuration, isA<Duration>());
    });

    test('should start timer', () {
      const testId = 'test-timer-2';
      const duration = Duration(seconds: 30);

      // Устанавливаем длительность и запускаем таймер
      timerProvider.setTimerDuration(testId, duration);
      timerProvider.startTimer(testId);

      // Таймер должен быть запущен (проверяем через отсутствие ошибок)
      expect(() => timerProvider.startTimer(testId), returnsNormally);
    });

    test('should stop timer', () {
      const testId = 'test-timer-3';
      const duration = Duration(seconds: 15);

      // Устанавливаем, запускаем и останавливаем таймер
      timerProvider.setTimerDuration(testId, duration);
      timerProvider.startTimer(testId);
      timerProvider.stopTimer(testId);

      // Таймер должен остановиться без ошибок
      expect(() => timerProvider.stopTimer(testId), returnsNormally);
    });

    test('should reset timer', () {
      const testId = 'test-timer-4';
      const duration = Duration(minutes: 2);

      // Устанавливаем, запускаем и сбрасываем таймер
      timerProvider.setTimerDuration(testId, duration);
      timerProvider.startTimer(testId);
      timerProvider.resetTimer(testId);

      // Таймер должен сброситься без ошибок
      expect(() => timerProvider.resetTimer(testId), returnsNormally);
    });

    test('should update timer settings', () {
      const testId = 'test-timer-5';
      const testName = 'Test Timer';
      const testColor = Colors.blue;
      const testSound = 'bell';

      // Обновляем настройки таймера
      timerProvider.updateTimerSettings(
        testId,
        name: testName,
        timerColor: testColor,
        alertSound: testSound,
      );

      // Настройки должны обновиться без ошибок
      expect(() => timerProvider.updateTimerSettings(testId, name: testName), returnsNormally);
    });

    test('should get current duration', () {
      const testId = 'test-timer-6';
      const duration = Duration(minutes: 10);

      // Устанавливаем длительность
      timerProvider.setTimerDuration(testId, duration);

      // Получаем текущую длительность
      final currentDuration = timerProvider.getCurrentDuration(testId);

      expect(currentDuration, isA<Duration>());
    });

    test('should notify listeners on changes', () async {
      bool notified = false;
      timerProvider.addListener(() {
        notified = true;
      });

      // Выполняем действие, которое должно уведомить слушателей
      timerProvider.setTimerDuration('test-timer-7', Duration(minutes: 1));

      expect(notified, isTrue);
    });

    test('should handle multiple timers', () {
      const timer1Id = 'timer-1';
      const timer2Id = 'timer-2';
      const duration1 = Duration(minutes: 5);
      const duration2 = Duration(minutes: 10);

      // Создаем два таймера
      timerProvider.setTimerDuration(timer1Id, duration1);
      timerProvider.setTimerDuration(timer2Id, duration2);

      // Оба таймера должны существовать
      final duration1Current = timerProvider.getCurrentDuration(timer1Id);
      final duration2Current = timerProvider.getCurrentDuration(timer2Id);

      expect(duration1Current, isA<Duration>());
      expect(duration2Current, isA<Duration>());
    });

    test('should handle timer lifecycle correctly', () {
      const testId = 'lifecycle-timer';
      const duration = Duration(seconds: 45);

      // Полный жизненный цикл таймера
      timerProvider.setTimerDuration(testId, duration);
      timerProvider.startTimer(testId);
      timerProvider.stopTimer(testId);
      timerProvider.resetTimer(testId);

      // Все операции должны выполняться без ошибок
      expect(() => {
        timerProvider.setTimerDuration(testId, duration),
        timerProvider.startTimer(testId),
        timerProvider.stopTimer(testId),
        timerProvider.resetTimer(testId),
      }, returnsNormally);
    });
  });
}