// Путь: lib/screens/debug/openai_test_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../localization/app_localizations.dart';

class OpenAITestScreen extends StatefulWidget {
  const OpenAITestScreen({super.key});

  @override
  State<OpenAITestScreen> createState() => _OpenAITestScreenState();
}

class _OpenAITestScreenState extends State<OpenAITestScreen> {
  final AIBitePredictionService _aiService = AIBitePredictionService();

  bool _isLoading = false;
  String _predictionSource = 'Неизвестно';
  String _statusMessage = '';
  Color _statusColor = Colors.grey;
  String _detailsMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPredictionSource();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Источник прогнозов',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Главная карточка с источником прогноза
            _buildMainSourceCard(),

            const SizedBox(height: 30),

            // Кнопка проверки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runSourceCheck,
                icon:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.refresh, size: 24),
                label: Text(
                  _isLoading ? 'ПРОВЕРЯЕМ...' : 'ПРОВЕРИТЬ ИСТОЧНИК',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Объяснение
            _buildExplanationCard(),

            const SizedBox(height: 20),

            // Дополнительные детали (если есть)
            if (_detailsMessage.isNotEmpty) _buildDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSourceCard() {
    IconData sourceIcon;
    String sourceTitle;
    String sourceDescription;

    if (_predictionSource == 'ИИ (OpenAI)') {
      sourceIcon = Icons.psychology;
      sourceTitle = '🧠 Искусственный Интеллект';
      sourceDescription = 'Ваши прогнозы создаёт настоящий ИИ от OpenAI';
    } else if (_predictionSource == 'Алгоритм') {
      sourceIcon = Icons.calculate;
      sourceTitle = '🔢 Математический алгоритм';
      sourceDescription = 'Прогнозы создаются локальным алгоритмом';
    } else {
      sourceIcon = Icons.help_outline;
      sourceTitle = '❓ Проверяем...';
      sourceDescription = 'Определяем источник ваших прогнозов';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Иконка источника
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(sourceIcon, size: 48, color: _statusColor),
          ),

          const SizedBox(height: 16),

          // Заголовок
          Text(
            sourceTitle,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Описание
          Text(
            sourceDescription,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Статус
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: _statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Как это работает?',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildExplanationItem(
            '🧠',
            'ИИ от OpenAI',
            'Анализирует погоду с помощью искусственного интеллекта. Даёт самые точные прогнозы.',
          ),

          const SizedBox(height: 12),

          _buildExplanationItem(
            '🔢',
            'Локальный алгоритм',
            'Использует математические формулы. Работает всегда, даже без интернета.',
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Приложение автоматически выбирает лучший доступный источник для ваших прогнозов.',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Детали проверки:',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _detailsMessage,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _checkPredictionSource() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Проверяем...';
      _statusColor = Colors.orange;
    });

    try {
      final isAIAvailable = _aiService.isAIAvailable;

      if (isAIAvailable) {
        // Проверяем, действительно ли AI работает
        final testResult = await _aiService.testOpenAIConnection(AppLocalizations.of(context));

        if (testResult['success'] == true) {
          setState(() {
            _predictionSource = 'ИИ (OpenAI)';
            _statusMessage = 'ИИ работает ✨';
            _statusColor = Colors.green;
            _detailsMessage =
                'Модель: ${testResult['model'] ?? 'gpt-3.5-turbo'}\n'
                'Время ответа: ${testResult['response_time'] ?? 'н/д'}мс';
          });
        } else {
          setState(() {
            _predictionSource = 'Алгоритм';
            _statusMessage = 'ИИ недоступен';
            _statusColor = Colors.blue;
            _detailsMessage =
                'Причина: ${testResult['error'] ?? 'Неизвестная ошибка'}';
          });
        }
      } else {
        setState(() {
          _predictionSource = 'Алгоритм';
          _statusMessage = 'ИИ не настроен';
          _statusColor = Colors.blue;
          _detailsMessage = 'OpenAI API ключ не найден или неверно настроен';
        });
      }
    } catch (e) {
      setState(() {
        _predictionSource = 'Алгоритм';
        _statusMessage = 'Ошибка проверки';
        _statusColor = Colors.orange;
        _detailsMessage = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _runSourceCheck() {
    _checkPredictionSource();
  }
}
