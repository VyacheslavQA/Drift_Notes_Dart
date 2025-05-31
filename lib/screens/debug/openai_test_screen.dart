// Путь: lib/screens/debug/openai_test_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../services/weather/weather_api_service.dart';
import '../../config/api_keys.dart';

class OpenAITestScreen extends StatefulWidget {
  const OpenAITestScreen({super.key});

  @override
  State<OpenAITestScreen> createState() => _OpenAITestScreenState();
}

class _OpenAITestScreenState extends State<OpenAITestScreen> {
  final AIBitePredictionService _aiService = AIBitePredictionService();
  final WeatherApiService _weatherService = WeatherApiService();

  bool _isLoading = false;
  String _result = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkOpenAIConfiguration();
  }

  void _checkOpenAIConfiguration() {
    setState(() {
      if (ApiKeys.openAIKey.isEmpty || ApiKeys.openAIKey == 'YOUR_OPENAI_API_KEY_HERE') {
        _status = '❌ OpenAI API ключ НЕ настроен';
      } else if (ApiKeys.openAIKey.startsWith('sk-proj') || ApiKeys.openAIKey.startsWith('sk-')) {
        _status = '✅ OpenAI API ключ настроен (${ApiKeys.openAIKey.length} символов)';
      } else {
        _status = '⚠️ OpenAI API ключ настроен, но формат подозрительный';
      }
    });
  }

  // Прямой тест OpenAI API
  Future<void> _testOpenAIDirectly() async {
    setState(() {
      _isLoading = true;
      _result = 'Тестируем прямое подключение к OpenAI...';
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAIKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': 'Ответь одним словом: работает ли API?',
            },
          ],
          'max_tokens': 10,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      setState(() {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final answer = data['choices'][0]['message']['content'] as String;
          _result = '''
✅ ПРЯМОЙ ТЕСТ OpenAI УСПЕШЕН!

📤 Отправили: "Ответь одним словом: работает ли API?"
📥 Получили: "$answer"

🔧 Технические детали:
- Статус: ${response.statusCode}
- Модель: gpt-3.5-turbo
- Время ответа: < 15 сек

Это означает, что OpenAI API работает корректно!
Проблема может быть в интеграции внутри приложения.
''';
        } else {
          final errorData = json.decode(response.body);
          _result = '''
❌ ПРЯМОЙ ТЕСТ OpenAI НЕУСПЕШЕН

🔴 Статус: ${response.statusCode}
📝 Ошибка: ${errorData['error']?['message'] ?? 'Неизвестная ошибка'}

Возможные причины:
${_getErrorExplanation(response.statusCode, errorData)}
''';
        }
      });

    } catch (e) {
      setState(() {
        _result = '''
❌ ОШИБКА ПРЯМОГО ТЕСТА:

${e.toString()}

Возможные причины:
- Нет интернет соединения
- Заблокирован доступ к OpenAI
- Таймаут соединения (>15 сек)
- Проблемы с сертификатами SSL
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOpenAIIntegration() async {
    setState(() {
      _isLoading = true;
      _result = 'Тестируем интеграцию с OpenAI через ИИ сервис...';
    });

    try {
      // Очищаем кэш для чистого теста
      _aiService.clearOldCache();

      setState(() {
        _result = 'Загружаем погоду...';
      });

      // Получаем тестовые данные о погоде (Павлодар)
      final weather = await _weatherService.getCurrentWeather(
        latitude: 52.2962,
        longitude: 76.9574,
      );

      setState(() {
        _result = 'Генерируем ИИ прогноз...';
      });

      // Генерируем ИИ прогноз
      final prediction = await _aiService.getMultiFishingTypePrediction(
        weather: weather,
        latitude: 52.2962,
        longitude: 76.9574,
      );

      // Проверяем, использовался ли OpenAI
      bool openAIUsed = false;
      String openAITip = '';

      for (final tip in prediction.bestPrediction.tips) {
        if (tip.contains('💡 Совет ИИ:')) {
          openAIUsed = true;
          openAITip = tip;
          break;
        }
      }

      setState(() {
        _result = '''
🎯 РЕЗУЛЬТАТ ИНТЕГРАЦИОННОГО ТЕСТА:

${openAIUsed ? '✅ OpenAI ИНТЕГРАЦИЯ РАБОТАЕТ!' : '❌ OpenAI ИНТЕГРАЦИЯ НЕ РАБОТАЕТ'}

📊 Базовый анализ:
- Лучший тип: ${prediction.bestFishingType}
- Балл: ${prediction.bestPrediction.overallScore}/100
- Уверенность: ${prediction.bestPrediction.confidencePercent}%

🤖 OpenAI статус:
${openAIUsed ? '✅ Совет от OpenAI получен' : '❌ Совет от OpenAI НЕ получен'}

${openAIUsed ? '💡 Совет OpenAI:\n$openAITip' : ''}

🔧 Технические детали:
- Источник данных: ${prediction.bestPrediction.dataSource}
- Версия модели: ${prediction.bestPrediction.modelVersion}
- Время генерации: ${prediction.generatedAt}
- Количество советов: ${prediction.bestPrediction.tips.length}

📝 Все советы:
${prediction.bestPrediction.tips.join('\n')}
''';
      });

    } catch (e) {
      setState(() {
        _result = '''
❌ ОШИБКА ИНТЕГРАЦИОННОГО ТЕСТА:

${e.toString()}

Возможные причины:
1. Неверный OpenAI API ключ
2. Превышен лимит запросов  
3. Нет интернет соединения
4. Проблемы с WeatherAPI
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorExplanation(int statusCode, Map<String, dynamic>? errorData) {
    switch (statusCode) {
      case 401:
        return '• Неверный API ключ\n• Ключ неактивен\n• Проверьте правильность ключа';
      case 429:
        return '• Превышен лимит запросов\n• Слишком много запросов в минуту\n• Подождите или обновите план';
      case 402:
        return '• Недостаточно средств на аккаунте\n• Пополните баланс на platform.openai.com';
      case 403:
        return '• Доступ запрещен\n• Возможно, ключ деактивирован';
      case 500:
        return '• Ошибка сервера OpenAI\n• Попробуйте позже';
      default:
        return '• Неизвестная ошибка\n• Код: $statusCode';
    }
  }

  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Результат скопирован в буфер обмена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Тест OpenAI интеграции',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppConstants.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_result.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: _copyResult,
              tooltip: 'Копировать результат',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус конфигурации
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _status.contains('✅') ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Статус конфигурации',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('✅') ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Кнопки тестирования
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testOpenAIDirectly,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.api),
                    label: const Text('ПРЯМОЙ ТЕСТ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testOpenAIIntegration,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.psychology),
                    label: const Text('ТЕСТ ИНТЕГРАЦИИ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Кнопка очистки кэша
            ElevatedButton.icon(
              onPressed: () {
                _aiService.clearOldCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Кэш очищен. Запустите тест заново.')),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('ОЧИСТИТЬ КЭШ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Результат
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? '''
Выберите тип теста:

🔵 ПРЯМОЙ ТЕСТ - проверяет прямое подключение к OpenAI API

🟢 ТЕСТ ИНТЕГРАЦИИ - проверяет работу OpenAI внутри вашего ИИ сервиса

🟠 ОЧИСТИТЬ КЭШ - удаляет кэшированные результаты для чистого теста
''' : _result,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Инструкции
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Диагностика:',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '''1. Сначала запустите ПРЯМОЙ ТЕСТ
2. Если прямой тест прошел - запустите ТЕСТ ИНТЕГРАЦИИ
3. Если прямой тест не прошел - проверьте баланс на platform.openai.com
4. Очищайте кэш перед каждым новым тестом''',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}