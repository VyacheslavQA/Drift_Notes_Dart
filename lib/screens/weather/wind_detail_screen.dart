/// Получает ИИ-рекомендации для ветра
Future<List<String>> getWindFishingRecommendations(String prompt) async {
  try {
    final response = await _makeOpenAIRequest([
      {'role': 'user', 'content': prompt}
    ]);

    if (response != null && response['choices'] != null && response['choices'].isNotEmpty) {
      final content = response['choices'][0]['message']['content'] as String?;

      if (content != null && content.isNotEmpty) {
        // Разбиваем на отдельные рекомендации
        final recommendations = content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .where((line) => line.length > 10) // Фильтруем слишком короткие строки
            .take(4) // Максимум 4 рекомендации
            .toList();

        return recommendations.isNotEmpty ? recommendations : ['Рекомендации не получены'];
      }
    }

    return ['Не удалось получить рекомендации от ИИ'];
  } catch (e) {
    debugPrint('❌ Ошибка получения ИИ-рекомендаций для ветра: $e');
    return ['Ошибка получения рекомендаций: $e'];
  }
}