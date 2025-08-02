import 'dart:io';
import 'dart:developer' as developer;

void main(List<String> arguments) async {
  developer.log('🧪 Запуск полного тестирования DriftNotes приложения...\n');

  // Определяем путь к Flutter
  final flutterPath = await findFlutterPath();

  if (flutterPath == null) {
    developer.log('❌ Flutter не найден в PATH');
    developer.log('💡 Попробуйте запустить напрямую: flutter test');
    return;
  }

  final testSuites = {
    'Провайдеры (Providers)': 'test/providers/',
    'Модели данных (Models)': 'test/models/',
    'Утилиты и валидаторы (Utils)': 'test/utils/',
    'Интеграционные тесты (Integration)': 'test/integration/',
    'Виджеты (Widgets)': 'test/widget_test.dart',
  };

  if (arguments.isEmpty) {
    developer.log('Выберите набор тестов для запуска:');
    var index = 1;
    // Исправлено: заменили forEach на обычный цикл for
    for (final suite in testSuites.keys) {
      developer.log('$index. $suite');
      index++;
    }
    developer.log('6. Запустить ВСЕ тесты');
    developer.log('7. Запустить тесты с покрытием кода');
    developer.log('8. Быстрые тесты (только провайдеры)');
    developer.log('0. Выход');

    stdout.write('\nВведите номер (0-8): ');
    final input = stdin.readLineSync();
    final choice = int.tryParse(input ?? '') ?? 0;

    switch (choice) {
      case 1:
        await runTestSuite(flutterPath, 'Провайдеры', 'test/providers/');
        break;
      case 2:
        await runTestSuite(flutterPath, 'Модели данных', 'test/models/');
        break;
      case 3:
        await runTestSuite(flutterPath, 'Утилиты и валидаторы', 'test/utils/');
        break;
      case 4:
        await runTestSuite(flutterPath, 'Интеграционные тесты', 'test/integration/');
        break;
      case 5:
        await runTestSuite(flutterPath, 'Виджеты', 'test/widget_test.dart');
        break;
      case 6:
        await runAllTests(flutterPath);
        break;
      case 7:
        await runTestsWithCoverage(flutterPath);
        break;
      case 8:
        await runQuickTests(flutterPath);
        break;
      default:
        developer.log('Выход из тестирования.');
        exit(0);
    }
  } else {
    await handleCommandLineArgs(flutterPath, arguments);
  }
}

Future<String?> findFlutterPath() async {
  // Проверяем стандартные пути для Windows
  final possiblePaths = [
    'flutter',
    'flutter.bat',
    'C:\\flutter\\bin\\flutter.bat',
    'C:\\flutter\\bin\\flutter',
  ];

  for (final path in possiblePaths) {
    try {
      final result = await Process.run(path, ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        return path;
      }
    } catch (e) {
      // Игнорируем ошибки и пробуем следующий путь
    }
  }

  return null;
}

Future<void> runTestSuite(String flutterPath, String suiteName, String path) async {
  developer.log('🎯 Запуск: $suiteName');
  developer.log('📁 Путь: $path\n');

  if (await Directory(path).exists() || await File(path).exists()) {
    await runCommand(flutterPath, ['test', path]);
  } else {
    developer.log('⚠️  Путь не найден: $path');
    developer.log('💡 Создайте тесты в этой папке:');
    if (path.contains('models')) {
      developer.log('   - Тесты для моделей данных (FishingNoteModel, BiteRecordModel)');
    } else if (path.contains('utils')) {
      developer.log('   - Тесты для валидаторов (email, пароли, вес рыбы)');
    } else if (path.contains('integration')) {
      developer.log('   - Интеграционные тесты (полные сценарии использования)');
    }
    developer.log('');
  }
}

Future<void> runAllTests(String flutterPath) async {
  developer.log('🚀 Запуск ВСЕХ тестов...\n');

  final startTime = DateTime.now();

  await runCommand(flutterPath, ['test']);

  final duration = DateTime.now().difference(startTime);
  developer.log('\n⏱️  Общее время выполнения: ${duration.inSeconds} секунд');
  developer.log('✅ Полное тестирование завершено!');
}

Future<void> runTestsWithCoverage(String flutterPath) async {
  developer.log('📊 Запуск тестов с анализом покрытия кода...\n');

  await runCommand(flutterPath, ['test', '--coverage']);

  developer.log('\n📈 Анализ покрытия кода:');
  if (await File('coverage/lcov.info').exists()) {
    developer.log('✅ Отчет о покрытии создан: coverage/lcov.info');
    developer.log('💡 Для просмотра HTML отчета:');
    developer.log('   1. Установите lcov (если нет)');
    developer.log('   2. Выполните: genhtml coverage/lcov.info -o coverage/html');
    developer.log('   3. Откройте: coverage/html/index.html');
  } else {
    developer.log('⚠️  Файл покрытия не найден');
  }
}

Future<void> runQuickTests(String flutterPath) async {
  developer.log('⚡ Запуск быстрых тестов (только провайдеры)...\n');

  if (await Directory('test/providers/').exists()) {
    await runCommand(flutterPath, ['test', 'test/providers/']);
  } else {
    developer.log('⚠️  Папка test/providers/ не найдена');
  }
}

Future<void> handleCommandLineArgs(String flutterPath, List<String> arguments) async {
  switch (arguments[0]) {
    case 'all':
      await runAllTests(flutterPath);
      break;
    case 'providers':
      await runTestSuite(flutterPath, 'Провайдеры', 'test/providers/');
      break;
    case 'models':
      await runTestSuite(flutterPath, 'Модели', 'test/models/');
      break;
    case 'utils':
      await runTestSuite(flutterPath, 'Утилиты', 'test/utils/');
      break;
    case 'integration':
      await runTestSuite(flutterPath, 'Интеграция', 'test/integration/');
      break;
    case 'coverage':
      await runTestsWithCoverage(flutterPath);
      break;
    case 'quick':
      await runQuickTests(flutterPath);
      break;
    default:
      developer.log('❌ Неизвестная команда: ${arguments[0]}');
      printUsage();
  }
}

Future<void> runCommand(String command, List<String> arguments) async {
  developer.log('🔧 Выполняется: $command ${arguments.join(' ')}');

  try {
    final process = await Process.start(
      command,
      arguments,
      runInShell: Platform.isWindows,
    );

    process.stdout.listen((data) {
      stdout.add(data);
    });

    process.stderr.listen((data) {
      stderr.add(data);
    });

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      developer.log('✅ Тесты прошли успешно');
    } else {
      developer.log('❌ Тесты завершились с ошибкой (код: $exitCode)');
    }
  } catch (e) {
    developer.log('❌ Ошибка выполнения команды: $e');
    developer.log('💡 Попробуйте запустить напрямую: $command ${arguments.join(' ')}');
  }
}

void printUsage() {
  developer.log('📚 Использование:');
  developer.log('dart test_runner.dart [команда]');
  developer.log('');
  developer.log('🎯 Доступные команды:');
  developer.log('  all         # Все тесты');
  developer.log('  providers   # Только провайдеры');
  developer.log('  models      # Только модели данных');
  developer.log('  utils       # Только утилиты и валидаторы');
  developer.log('  integration # Только интеграционные тесты');
  developer.log('  coverage    # Тесты с анализом покрытия кода');
  developer.log('  quick       # Быстрые тесты (провайдеры)');
  developer.log('');
  developer.log('💡 Примеры:');
  developer.log('  dart test_runner.dart all');
  developer.log('  dart test_runner.dart providers');
  developer.log('  dart test_runner.dart coverage');
  developer.log('');
  developer.log('🎯 Текущий статус тестов:');
  developer.log('  ✅ Провайдеры: 35 тестов работают');
  developer.log('  🆕 Модели: создайте test/models/');
  developer.log('  🆕 Утилиты: создайте test/utils/');
  developer.log('  🆕 Интеграция: создайте test/integration/');
}