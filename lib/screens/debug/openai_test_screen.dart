// Путь: lib/screens/debug/openai_test_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../config/api_keys.dart';

class OpenAITestScreen extends StatefulWidget {
  const OpenAITestScreen({super.key});

  @override
  State<OpenAITestScreen> createState() => _OpenAITestScreenState();
}

class _OpenAITestScreenState extends State<OpenAITestScreen> {
  final AIBitePredictionService _aiService = AIBitePredictionService();

  bool _isLoading = false;
  Map<String, dynamic>? _testResult;
  String? _directTestResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Тест OpenAI интеграции'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус конфигурации
            _buildConfigurationStatus(),

            const SizedBox(height: 24),

            // Кнопки тестирования
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runDirectTest,
                    icon: const Icon(Icons.science),
                    label: const Text('ПРЯМОЙ ТЕСТ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runIntegrationTest,
                    icon: const Icon(Icons.psychology),
                    label: const Text('ТЕСТ ИНТЕГРАЦИИ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Кнопка очистки кэша
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearCache,
                icon: const Icon(Icons.clear_all),
                label: const Text('ОЧИСТИТЬ КЭШ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Результаты тестов
            if (_isLoading) _buildLoadingIndicator(),
            if (_testResult != null) _buildTestResults(),
            if (_directTestResult != null) _buildDirectTestResults(),

            const SizedBox(height: 24),

            // Диагностика
            _buildDiagnostics(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStatus() {
    final apiKey = ApiKeys.openAIKey;
    final isConfigured = apiKey.isNotEmpty &&
        apiKey != 'YOUR_OPENAI_API_KEY_HERE' &&
        apiKey.startsWith('sk-') &&
        apiKey.length > 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConfigured ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfigured ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статус конфигурации',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                isConfigured ? Icons.check_circle : Icons.error,
                color: isConfigured ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConfigured
                      ? 'OpenAI API ключ настроен (${apiKey.length} символов)'
                      : 'OpenAI API ключ НЕ настроен',
                  style: TextStyle(
                    color: isConfigured ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Детали ключа
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Детали ключа:', style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold)),
                Text('• Длина: ${apiKey.length} символов', style: TextStyle(color: AppConstants.textColor)),
                Text('• Начинается с "sk-": ${apiKey.startsWith('sk-') ? 'Да' : 'Нет'}', style: TextStyle(color: AppConstants.textColor)),
                Text('• Первые 10 символов: ${apiKey.length > 10 ? apiKey.substring(0, 10) : apiKey}...', style: TextStyle(color: AppConstants.textColor)),
                Text('• Не является заглушкой: ${apiKey != 'YOUR_OPENAI_API_KEY_HERE' ? 'Да' : 'Нет'}', style: TextStyle(color: AppConstants.textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppConstants.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Тестируем соединение с OpenAI...',
              style: TextStyle(color: AppConstants.textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    final result = _testResult!;
    final isSuccess = result['success'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'РЕЗУЛЬТАТ ИНТЕГРАЦИОННОГО ТЕСТА:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isSuccess) ...[
            Text('✅ OpenAI интеграция РАБОТАЕТ',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (result['model'] != null)
              Text('📱 Модель: ${result['model']}', style: TextStyle(color: AppConstants.textColor)),
            if (result['response'] != null)
              Text('💬 Ответ: ${result['response']}', style: TextStyle(color: AppConstants.textColor)),
            if (result['response_time'] != null)
              Text('⏱️ Время ответа: ${result['response_time']}мс', style: TextStyle(color: AppConstants.textColor)),
          ] else ...[
            Text('❌ OpenAI интеграция НЕ РАБОТАЕТ',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (result['error'] != null)
              Text('❌ Ошибка: ${result['error']}',
                  style: TextStyle(color: Colors.red)),
            if (result['status'] != null)
              Text('📊 HTTP статус: ${result['status']}', style: TextStyle(color: AppConstants.textColor)),
          ],

          // Дополнительная диагностика
          const SizedBox(height: 12),
          Text('🔧 Настроен: ${result['configured'] ?? 'unknown'}', style: TextStyle(color: AppConstants.textColor)),

          if (result['key_length'] != null)
            Text('🔑 Длина ключа: ${result['key_length']}', style: TextStyle(color: AppConstants.textColor)),
          if (result['key_format'] != null)
            Text('🔑 Формат ключа: ${result['key_format']}', style: TextStyle(color: AppConstants.textColor)),
        ],
      ),
    );
  }

  Widget _buildDirectTestResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 РЕЗУЛЬТАТ ПРЯМОГО ТЕСТА:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _directTestResult!,
            style: TextStyle(color: AppConstants.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Диагностика:',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('1. Сначала запустите ПРЯМОЙ ТЕСТ', style: TextStyle(color: AppConstants.textColor)),
          Text('2. Если прямой тест прошел - запустите ТЕСТ ИНТЕГРАЦИИ', style: TextStyle(color: AppConstants.textColor)),
          Text('3. Если прямой тест не прошел - проверьте баланс на platform.openai.com', style: TextStyle(color: AppConstants.textColor)),
          Text('4. Очищайте кэш перед каждым новым тестом', style: TextStyle(color: AppConstants.textColor)),
        ],
      ),
    );
  }

  void _runIntegrationTest() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final result = await _aiService.testOpenAIConnection();
      setState(() {
        _testResult = result;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'error': e.toString(),
          'configured': false,
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _runDirectTest() async {
    setState(() {
      _isLoading = true;
      _directTestResult = null;
    });

    try {
      const prompt = 'Скажи "Тест пройден" если получил это сообщение';

      final result = await _makeDirectOpenAIRequest(prompt);

      setState(() {
        _directTestResult = 'Успех: $result';
      });
    } catch (e) {
      setState(() {
        _directTestResult = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _makeDirectOpenAIRequest(String prompt) async {
    final apiKey = ApiKeys.openAIKey;

    if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      throw Exception('API ключ не настроен');
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 50,
        'temperature': 0.0,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      final errorBody = response.body;
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }
  }

  void _clearCache() {
    _aiService.clearOldCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Кэш очищен'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}