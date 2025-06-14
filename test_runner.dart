import 'dart:io';

void main(List<String> arguments) async {
  print('🧪 Запуск полного тестирования DriftNotes приложения...\n');

  // Определяем путь к Flutter
  final flutterPath = await findFlutterPath();

  if (flutterPath == null) {
    print('❌ Flutter не найден в PATH');
    print('💡 Попробуйте запустить напрямую: flutter test');
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
    print('Выберите набор тестов для запуска:');
    var index = 1;
    testSuites.keys.forEach((suite) {
      print('$index. $suite');
      index++;
    });
    print('6. Запустить ВСЕ тесты');
    print('7. Запустить тесты с покрытием кода');
    print('8. Быстрые тесты (только провайдеры)');
    print('0. Выход');

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
        print('Выход из тестирования.');
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
  print('🎯 Запуск: $suiteName');
  print('📁 Путь: $path\n');

  if (await Directory(path).exists() || await File(path).exists()) {
    await runCommand(flutterPath, ['test', path]);
  } else {
    print('⚠️  Путь не найден: $path');
    print('💡 Создайте тесты в этой папке:');
    if (path.contains('models')) {
      print('   - Тесты для моделей данных (FishingNoteModel, BiteRecordModel)');
    } else if (path.contains('utils')) {
      print('   - Тесты для валидаторов (email, пароли, вес рыбы)');
    } else if (path.contains('integration')) {
      print('   - Интеграционные тесты (полные сценарии использования)');
    }
    print('');
  }
}

Future<void> runAllTests(String flutterPath) async {
  print('🚀 Запуск ВСЕХ тестов...\n');

  final startTime = DateTime.now();

  await runCommand(flutterPath, ['test']);

  final duration = DateTime.now().difference(startTime);
  print('\n⏱️  Общее время выполнения: ${duration.inSeconds} секунд');
  print('✅ Полное тестирование завершено!');
}

Future<void> runTestsWithCoverage(String flutterPath) async {
  print('📊 Запуск тестов с анализом покрытия кода...\n');

  await runCommand(flutterPath, ['test', '--coverage']);

  print('\n📈 Анализ покрытия кода:');
  if (await File('coverage/lcov.info').exists()) {
    print('✅ Отчет о покрытии создан: coverage/lcov.info');
    print('💡 Для просмотра HTML отчета:');
    print('   1. Установите lcov (если нет)');
    print('   2. Выполните: genhtml coverage/lcov.info -o coverage/html');
    print('   3. Откройте: coverage/html/index.html');
  } else {
    print('⚠️  Файл покрытия не найден');
  }
}

Future<void> runQuickTests(String flutterPath) async {
  print('⚡ Запуск быстрых тестов (только провайдеры)...\n');

  if (await Directory('test/providers/').exists()) {
    await runCommand(flutterPath, ['test', 'test/providers/']);
  } else {
    print('⚠️  Папка test/providers/ не найдена');
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
      print('❌ Неизвестная команда: ${arguments[0]}');
      printUsage();
  }
}

Future<void> runCommand(String command, List<String> arguments) async {
  print('🔧 Выполняется: $command ${arguments.join(' ')}');

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
      print('✅ Тесты прошли успешно');
    } else {
      print('❌ Тесты завершились с ошибкой (код: $exitCode)');
    }
  } catch (e) {
    print('❌ Ошибка выполнения команды: $e');
    print('💡 Попробуйте запустить напрямую: $command ${arguments.join(' ')}');
  }
}

void printUsage() {
  print('📚 Использование:');
  print('dart test_runner.dart [команда]');
  print('');
  print('🎯 Доступные команды:');
  print('  all         # Все тесты');
  print('  providers   # Только провайдеры');
  print('  models      # Только модели данных');
  print('  utils       # Только утилиты и валидаторы');
  print('  integration # Только интеграционные тесты');
  print('  coverage    # Тесты с анализом покрытия кода');
  print('  quick       # Быстрые тесты (провайдеры)');
  print('');
  print('💡 Примеры:');
  print('  dart test_runner.dart all');
  print('  dart test_runner.dart providers');
  print('  dart test_runner.dart coverage');
  print('');
  print('🎯 Текущий статус тестов:');
  print('  ✅ Провайдеры: 35 тестов работают');
  print('  🆕 Модели: создайте test/models/');
  print('  🆕 Утилиты: создайте test/utils/');
  print('  🆕 Интеграция: создайте test/integration/');
}