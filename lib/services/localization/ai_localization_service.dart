// Путь: lib/services/localization/ai_localization_service.dart

import 'package:flutter/foundation.dart';
import '../../localization/app_localizations.dart';

class AILocalizationService {
  /// Получить системное сообщение для OpenAI на нужном языке
  String getSystemMessage(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return '''You are an expert fishing consultant. Always respond in English with detailed and specific advice. 
Structure your responses clearly and provide practical recommendations for anglers.
IMPORTANT: Always respond in English language only, regardless of the user's query language.''';

      case 'ru':
        return '''Ты эксперт по рыбалке и рыболовный консультант. Всегда отвечай на русском языке с подробными и конкретными советами.
Структурируй свои ответы четко и давай практические рекомендации для рыбаков.
ВАЖНО: Всегда отвечай только на русском языке, независимо от языка запроса пользователя.''';

      case 'es':
        return '''Eres un experto consultor de pesca. Siempre responde en español con consejos detallados y específicos.
Estructura tus respuestas claramente y proporciona recomendaciones prácticas para pescadores.
IMPORTANTE: Siempre responde solo en español, independientemente del idioma de la consulta del usuario.''';

      case 'fr':
        return '''Vous êtes un expert consultant en pêche. Répondez toujours en français avec des conseils détaillés et spécifiques.
Structurez vos réponses clairement et fournissez des recommandations pratiques pour les pêcheurs.
IMPORTANT: Répondez toujours uniquement en français, quel que soit la langue de la requête de l'utilisateur.''';

      case 'de':
        return '''Sie sind ein Experte für Angelberatung. Antworten Sie immer auf Deutsch mit detaillierten und spezifischen Ratschlägen.
Strukturieren Sie Ihre Antworten klar und geben Sie praktische Empfehlungen für Angler.
WICHTIG: Antworten Sie immer nur auf Deutsch, unabhängig von der Sprache der Benutzeranfrage.''';

      default:
        return '''You are an expert fishing consultant. Always respond in English with detailed and specific advice. 
Structure your responses clearly and provide practical recommendations for anglers.
IMPORTANT: Always respond in English language only, regardless of the user's query language.''';
    }
  }

  /// Создать локализованный промпт для рекомендаций по ветру
  String createWindRecommendationPrompt(String originalPrompt, AppLocalizations l10n) {
    final languageInstruction = _getLanguageInstruction(l10n);

    switch (l10n.languageCode) {
      case 'en':
        return '''$languageInstruction

Weather conditions and wind situation: $originalPrompt

Please provide 3-5 specific fishing recommendations for these wind conditions:
1. Lure/bait selection
2. Fishing technique adjustments  
3. Location and positioning tips
4. Equipment recommendations
5. Timing considerations

Format each recommendation as a numbered list item.''';

      case 'ru':
        return '''$languageInstruction

Погодные условия и ветровая обстановка: $originalPrompt

Дай 3-5 конкретных рекомендаций для рыбалки в этих ветровых условиях:
1. Выбор приманок/наживки
2. Корректировка техники ловли
3. Выбор места и позиционирование
4. Рекомендации по снастям
5. Выбор времени

Оформи каждую рекомендацию как пронумерованный пункт.''';

      case 'es':
        return '''$languageInstruction

Condiciones meteorológicas y situación del viento: $originalPrompt

Proporciona 3-5 recomendaciones específicas de pesca para estas condiciones de viento:
1. Selección de señuelos/cebo
2. Ajustes de técnica de pesca
3. Consejos de ubicación y posicionamiento
4. Recomendaciones de equipo
5. Consideraciones de tiempo

Formatea cada recomendación como un elemento de lista numerada.''';

      case 'fr':
        return '''$languageInstruction

Conditions météorologiques et situation du vent: $originalPrompt

Veuillez fournir 3-5 recommandations de pêche spécifiques pour ces conditions de vent:
1. Sélection des leurres/appâts
2. Ajustements de technique de pêche
3. Conseils de localisation et positionnement
4. Recommandations d'équipement
5. Considérations de timing

Formatez chaque recommandation comme un élément de liste numérotée.''';

      case 'de':
        return '''$languageInstruction

Wetterbedingungen und Windsituation: $originalPrompt

Bitte geben Sie 3-5 spezifische Angelempfehlungen für diese Windbedingungen:
1. Köder-/Köderfischauswahl
2. Anpassungen der Angeltechnik
3. Standort- und Positionierungstipps
4. Ausrüstungsempfehlungen
5. Timing-Überlegungen

Formatieren Sie jede Empfehlung als nummeriertes Listenelement.''';

      default:
        return createWindRecommendationPrompt(originalPrompt, l10n);
    }
  }

  /// Создать тестовый промпт для проверки соединения
  String createTestPrompt(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return '''${_getLanguageInstruction(l10n)}

Respond with one short phrase: "API works correctly"''';

      case 'ru':
        return '''${_getLanguageInstruction(l10n)}

Ответь одной короткой фразой: "API работает корректно"''';

      case 'es':
        return '''${_getLanguageInstruction(l10n)}

Responde con una frase corta: "La API funciona correctamente"''';

      case 'fr':
        return '''${_getLanguageInstruction(l10n)}

Répondez par une phrase courte: "L'API fonctionne correctement"''';

      case 'de':
        return '''${_getLanguageInstruction(l10n)}

Antworten Sie mit einem kurzen Satz: "API funktioniert korrekt"''';

      default:
        return createTestPrompt(l10n);
    }
  }

  /// Создать специализированный промпт для конкретного типа рыбалки
  String createSpecializedPrompt({
    required String typeName,
    required double temperature,
    required double pressure,
    required double windSpeed,
    required int currentScore,
    required String experienceLevel,
    required bool hasHistory,
    required int currentHour,
    required AppLocalizations l10n,
  }) {
    final languageInstruction = _getLanguageInstruction(l10n);
    final experienceLevelName = getExperienceLevelName(experienceLevel, l10n);

    switch (l10n.languageCode) {
      case 'en':
        return '''$languageInstruction

Fishing conditions for "$typeName":
- Weather: ${temperature.round()}°C, pressure ${pressure.round()} mb, wind ${windSpeed.round()} km/h
- Current forecast: $currentScore points out of 100
- Angler level: $experienceLevelName
- Has fishing history: $hasHistory
- Time of day: $currentHour:00

Give 3 specific tips for "$typeName" in these conditions:
1. What lures/baits to use
2. Fishing technique and tactics
3. Location and timing selection

Each tip should be a separate line starting with a number.''';

      case 'ru':
        return '''$languageInstruction

Условия для рыбалки "$typeName":
- Погода: ${temperature.round()}°C, давление ${pressure.round()} мб, ветер ${windSpeed.round()} км/ч
- Текущий прогноз: $currentScore баллов из 100
- Уровень рыбака: $experienceLevelName
- Есть история рыбалок: ${hasHistory ? 'да' : 'нет'}
- Время суток: $currentHour:00

Дай 3 конкретных совета именно для "$typeName" в этих условиях:
1. Какие приманки/наживки использовать
2. Техника и тактика ловли  
3. Выбор места и времени

Каждый совет - отдельная строка, начинающаяся с номера.''';

      case 'es':
        return '''$languageInstruction

Condiciones para la pesca "$typeName":
- Clima: ${temperature.round()}°C, presión ${pressure.round()} mb, viento ${windSpeed.round()} km/h
- Pronóstico actual: $currentScore puntos de 100
- Nivel del pescador: $experienceLevelName
- Tiene historial de pesca: ${hasHistory ? 'sí' : 'no'}
- Hora del día: $currentHour:00

Da 3 consejos específicos para "$typeName" en estas condiciones:
1. Qué señuelos/cebos usar
2. Técnica y táctica de pesca
3. Selección de lugar y tiempo

Cada consejo debe ser una línea separada que comience con un número.''';

      case 'fr':
        return '''$languageInstruction

Conditions pour la pêche "$typeName":
- Météo: ${temperature.round()}°C, pression ${pressure.round()} mb, vent ${windSpeed.round()} km/h
- Prévision actuelle: $currentScore points sur 100
- Niveau du pêcheur: $experienceLevelName
- A un historique de pêche: ${hasHistory ? 'oui' : 'non'}
- Heure de la journée: $currentHour:00

Donnez 3 conseils spécifiques pour "$typeName" dans ces conditions:
1. Quels leurres/appâts utiliser
2. Technique et tactique de pêche
3. Sélection du lieu et du timing

Chaque conseil doit être une ligne séparée commençant par un numéro.''';

      case 'de':
        return '''$languageInstruction

Bedingungen für das Angeln "$typeName":
- Wetter: ${temperature.round()}°C, Druck ${pressure.round()} mb, Wind ${windSpeed.round()} km/h
- Aktuelle Vorhersage: $currentScore Punkte von 100
- Angler-Level: $experienceLevelName
- Hat Angel-Historie: ${hasHistory ? 'ja' : 'nein'}
- Tageszeit: $currentHour:00

Geben Sie 3 spezifische Tipps für "$typeName" unter diesen Bedingungen:
1. Welche Köder/Köderfische zu verwenden
2. Angeltechnik und Taktik
3. Orts- und Zeitauswahl

Jeder Tipp sollte eine separate Zeile sein, die mit einer Nummer beginnt.''';

      default:
        return createSpecializedPrompt(
          typeName: typeName,
          temperature: temperature,
          pressure: pressure,
          windSpeed: windSpeed,
          currentScore: currentScore,
          experienceLevel: experienceLevel,
          hasHistory: hasHistory,
          currentHour: currentHour,
          l10n: l10n,
        );
    }
  }

  /// Парсинг обычных рекомендаций ИИ
  List<String> parseAIRecommendations(String content) {
    final cleanContent = content.trim();
    List<String> recommendations = [];

    // Сначала пробуем разделить по номерам
    final numberedLines = cleanContent.split(RegExp(r'\d+\.\s*'));
    if (numberedLines.length > 1) {
      recommendations =
          numberedLines
              .skip(1)
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty && line.length > 5)
              .take(6)
              .toList();
    }

    // Если нумерованных пунктов нет, разбиваем по переносам строк
    if (recommendations.isEmpty) {
      recommendations =
          cleanContent
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty && line.length > 5)
              .take(6)
              .toList();
    }

    // Если и так не получилось, возвращаем весь ответ как одну рекомендацию
    if (recommendations.isEmpty && cleanContent.length > 10) {
      recommendations = [cleanContent];
    }

    return recommendations;
  }

  /// Парсинг специализированного ответа ИИ с иконками
  List<String> parseSpecializedAIResponse(String content, AppLocalizations l10n) {
    final cleanResponse = content.trim();
    final tips = <String>[];

    if (cleanResponse.isNotEmpty && cleanResponse.length > 10) {
      // Разбиваем ответ на отдельные советы по номерам
      final numberedTips = cleanResponse.split(RegExp(r'\d+\.\s*'));

      if (numberedTips.length > 1) {
        // Убираем первый пустой элемент и обрабатываем советы
        final parsedTips = numberedTips
            .skip(1)
            .map((tip) => tip.trim())
            .where((tip) => tip.isNotEmpty && tip.length > 5)
            .take(3)
            .toList();

        // Добавляем каждый совет с префиксом
        for (int i = 0; i < parsedTips.length; i++) {
          final categories = _getAITipCategories(l10n);
          final category = i < categories.length ? categories[i] : _getGenericTipIcon(l10n);
          tips.add('$category: ${parsedTips[i]}');
        }
      } else {
        // Если не удалось разбить по номерам, добавляем весь ответ
        tips.add('${_getAIAnalysisIcon(l10n)}: $cleanResponse');
      }
    }

    return tips;
  }

  /// Валидация языка ответа
  bool validateResponseLanguage(String response, AppLocalizations l10n) {
    if (response.isEmpty) return false;

    switch (l10n.languageCode) {
      case 'ru':
      // Проверяем наличие кириллических символов
        return RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);

      case 'en':
      // Проверяем наличие латинских символов и отсутствие кириллицы
        return RegExp(r'[a-z]', caseSensitive: false).hasMatch(response) &&
            !RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);

      case 'es':
      // Проверяем латинские символы и испанские специфичные символы
        return RegExp(r'[a-záéíóúñü]', caseSensitive: false).hasMatch(response);

      case 'fr':
      // Проверяем латинские символы и французские специфичные символы
        return RegExp(r'[a-zàâäéèêëïîôöùûüÿç]', caseSensitive: false).hasMatch(response);

      case 'de':
      // Проверяем латинские символы и немецкие специфичные символы
        return RegExp(r'[a-zäöüß]', caseSensitive: false).hasMatch(response);

      default:
        return true; // Для неизвестных языков возвращаем true
    }
  }

  /// Получить название типа рыбалки на нужном языке
  String getFishingTypeName(String fishingType, AppLocalizations l10n) {
    switch (fishingType) {
      case 'spinning':
        return l10n.translate('ai_spinning');
      case 'feeder':
        return l10n.translate('ai_feeder');
      case 'carp_fishing':
        return l10n.translate('ai_carp_fishing');
      case 'float_fishing':
        return l10n.translate('ai_float_fishing');
      case 'ice_fishing':
        return l10n.translate('ai_ice_fishing');
      case 'fly_fishing':
        return l10n.translate('ai_fly_fishing');
      case 'trolling':
        return l10n.translate('ai_trolling');
      default:
        return fishingType;
    }
  }

  /// Получить название уровня опыта на нужном языке
  String getExperienceLevelName(String level, AppLocalizations l10n) {
    switch (level) {
      case 'beginner':
        return l10n.translate('ai_beginner');
      case 'intermediate':
        return l10n.translate('ai_intermediate');
      case 'expert':
        return l10n.translate('ai_expert');
      default:
        return level;
    }
  }

  /// Получить название сезона на нужном языке
  String getSeasonName(String season, AppLocalizations l10n) {
    switch (season) {
      case 'spring':
        return l10n.translate('ai_spring');
      case 'summer':
        return l10n.translate('ai_summer');
      case 'autumn':
        return l10n.translate('ai_autumn');
      case 'winter':
        return l10n.translate('ai_winter');
      default:
        return season;
    }
  }

  // Приватные методы

  /// Получить инструкцию по языку для ИИ
  String _getLanguageInstruction(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return 'IMPORTANT: Respond ONLY in English language. Do not use any other language.';
      case 'ru':
        return 'ВАЖНО: Отвечай ТОЛЬКО на русском языке. Не используй другие языки.';
      case 'es':
        return 'IMPORTANTE: Responde SOLO en español. No uses otros idiomas.';
      case 'fr':
        return 'IMPORTANT: Répondez UNIQUEMENT en français. N\'utilisez pas d\'autres langues.';
      case 'de':
        return 'WICHTIG: Antworten Sie NUR auf Deutsch. Verwenden Sie keine anderen Sprachen.';
      default:
        return 'IMPORTANT: Respond ONLY in English language. Do not use any other language.';
    }
  }

  /// Получить категории советов ИИ с иконками
  List<String> _getAITipCategories(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'ru':
        return ['🎯 Приманки', '⚡ Техника', '📍 Место и время'];
      case 'en':
        return ['🎯 Lures', '⚡ Technique', '📍 Place & Time'];
      case 'es':
        return ['🎯 Señuelos', '⚡ Técnica', '📍 Lugar y Tiempo'];
      case 'fr':
        return ['🎯 Leurres', '⚡ Technique', '📍 Lieu et Temps'];
      case 'de':
        return ['🎯 Köder', '⚡ Technik', '📍 Ort & Zeit'];
      default:
        return ['🎯 Lures', '⚡ Technique', '📍 Place & Time'];
    }
  }

  /// Получить иконку для общего совета
  String _getGenericTipIcon(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'ru':
        return '💡 Совет';
      case 'en':
        return '💡 Tip';
      case 'es':
        return '💡 Consejo';
      case 'fr':
        return '💡 Conseil';
      case 'de':
        return '💡 Tipp';
      default:
        return '💡 Tip';
    }
  }

  /// Получить иконку для ИИ анализа
  String _getAIAnalysisIcon(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'ru':
        return '🧠 ИИ анализ';
      case 'en':
        return '🧠 AI Analysis';
      case 'es':
        return '🧠 Análisis IA';
      case 'fr':
        return '🧠 Analyse IA';
      case 'de':
        return '🧠 KI-Analyse';
      default:
        return '🧠 AI Analysis';
    }
  }
}