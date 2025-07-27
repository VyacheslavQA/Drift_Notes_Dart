// Путь: lib/services/localization/ai_localization_service.dart

import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../../localization/app_localizations.dart';

class AILocalizationService {
  /// Получить системное сообщение для OpenAI на нужном языке - УСИЛЕННАЯ ВЕРСИЯ
  String getSystemMessage(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return '''You are an expert fishing consultant specializing in practical advice for anglers.

CRITICAL LANGUAGE REQUIREMENT: 
- You MUST respond ONLY in English language
- NEVER use Russian, Spanish, French, German or any other language
- If you accidentally start in another language, immediately stop and restart in English
- All technical terms must be in English
- All recommendations must be in English

Your responses should be:
- Clear and practical
- Specific to fishing conditions
- Structured with numbered points when listing recommendations
- Professional but accessible to anglers of all levels

Remember: ENGLISH ONLY - no exceptions!''';

      case 'ru':
        return '''Ты эксперт по рыбалке, специализирующийся на практических советах для рыбаков.

КРИТИЧЕСКОЕ ТРЕБОВАНИЕ К ЯЗЫКУ:
- Ты ДОЛЖЕН отвечать ТОЛЬКО на русском языке
- НИКОГДА не используй английский, испанский, французский, немецкий или другие языки
- Если случайно начнешь на другом языке, немедленно остановись и начни заново на русском
- Все технические термины должны быть на русском
- Все рекомендации должны быть на русском

Твои ответы должны быть:
- Понятными и практичными
- Конкретными для условий рыбалки
- Структурированными с нумерованными пунктами при перечислении рекомендаций
- Профессиональными, но доступными для рыбаков любого уровня

Запомни: ТОЛЬКО РУССКИЙ ЯЗЫК - никаких исключений!''';

      case 'es':
        return '''Eres un experto consultor de pesca especializado en consejos prácticos para pescadores.

REQUISITO CRÍTICO DE IDIOMA:
- DEBES responder SOLO en español
- NUNCA uses inglés, ruso, francés, alemán u otros idiomas
- Si accidentalmente empiezas en otro idioma, detente inmediatamente y reinicia en español
- Todos los términos técnicos deben estar en español
- Todas las recomendaciones deben estar en español

Tus respuestas deben ser:
- Claras y prácticas
- Específicas para las condiciones de pesca
- Estructuradas con puntos numerados al listar recomendaciones
- Profesionales pero accesibles para pescadores de todos los niveles

Recuerda: SOLO ESPAÑOL - ¡sin excepciones!''';

      case 'fr':
        return '''Vous êtes un expert consultant en pêche spécialisé dans les conseils pratiques pour les pêcheurs.

EXIGENCE CRITIQUE DE LANGUE:
- Vous DEVEZ répondre UNIQUEMENT en français
- N'utilisez JAMAIS l'anglais, le russe, l'espagnol, l'allemand ou toute autre langue
- Si vous commencez accidentellement dans une autre langue, arrêtez-vous immédiatement et recommencez en français
- Tous les termes techniques doivent être en français
- Toutes les recommandations doivent être en français

Vos réponses doivent être:
- Claires et pratiques
- Spécifiques aux conditions de pêche
- Structurées avec des points numérotés lors de l'énumération des recommandations
- Professionnelles mais accessibles aux pêcheurs de tous niveaux

Rappelez-vous: FRANÇAIS UNIQUEMENT - aucune exception!''';

      case 'de':
        return '''Sie sind ein Experte für Angelberatung, spezialisiert auf praktische Ratschläge für Angler.

KRITISCHE SPRACHANFORDERUNG:
- Sie MÜSSEN AUSSCHLIESSLICH auf Deutsch antworten
- Verwenden Sie NIEMALS Englisch, Russisch, Spanisch, Französisch oder andere Sprachen
- Wenn Sie versehentlich in einer anderen Sprache beginnen, stoppen Sie sofort und beginnen Sie auf Deutsch neu
- Alle Fachbegriffe müssen auf Deutsch sein
- Alle Empfehlungen müssen auf Deutsch sein

Ihre Antworten sollten sein:
- Klar und praktisch
- Spezifisch für Angelbedingungen
- Strukturiert mit nummerierten Punkten bei der Auflistung von Empfehlungen
- Professionell, aber für Angler aller Niveaus zugänglich

Denken Sie daran: NUR DEUTSCH - keine Ausnahmen!''';

      default:
        return '''You are an expert fishing consultant specializing in practical advice for anglers.

CRITICAL LANGUAGE REQUIREMENT: 
- You MUST respond ONLY in English language
- NEVER use Russian, Spanish, French, German or any other language
- If you accidentally start in another language, immediately stop and restart in English
- All technical terms must be in English
- All recommendations must be in English

Remember: ENGLISH ONLY - no exceptions!''';
    }
  }

  /// Создать локализованный промпт для рекомендаций по ветру - УСИЛЕННАЯ ВЕРСИЯ
  String createWindRecommendationPrompt(String originalPrompt, AppLocalizations l10n) {
    final languageInstruction = _getStrongLanguageInstruction(l10n);

    switch (l10n.languageCode) {
      case 'en':
        return '''$languageInstruction

Weather conditions and wind situation: $originalPrompt

Please provide exactly 3-5 specific fishing recommendations for these wind conditions.
Format MUST be:
1. [First recommendation]
2. [Second recommendation] 
3. [Third recommendation]
etc.

Focus on:
- Lure/bait selection for wind
- Fishing technique adjustments
- Location and positioning tips
- Equipment recommendations
- Timing considerations

REMEMBER: Reply ONLY in English!''';

      case 'ru':
        return '''$languageInstruction

Погодные условия и ветровая обстановка: $originalPrompt

Дай точно 3-5 конкретных рекомендаций для рыбалки в этих ветровых условиях.
Формат ОБЯЗАТЕЛЬНО должен быть:
1. [Первая рекомендация]
2. [Вторая рекомендация]
3. [Третья рекомендация]
и т.д.

Сосредоточься на:
- Выбор приманок/наживки для ветра
- Корректировка техники ловли
- Выбор места и позиционирование
- Рекомендации по снастям
- Выбор времени

ПОМНИ: Отвечай ТОЛЬКО на русском!''';

      case 'es':
        return '''$languageInstruction

Condiciones meteorológicas y situación del viento: $originalPrompt

Proporciona exactamente 3-5 recomendaciones específicas de pesca para estas condiciones de viento.
El formato DEBE ser:
1. [Primera recomendación]
2. [Segunda recomendación]
3. [Tercera recomendación]
etc.

Enfócate en:
- Selección de señuelos/cebo para viento
- Ajustes de técnica de pesca
- Consejos de ubicación y posicionamiento
- Recomendaciones de equipo
- Consideraciones de tiempo

RECUERDA: ¡Responde SOLO en español!''';

      case 'fr':
        return '''$languageInstruction

Conditions météorologiques et situation du vent: $originalPrompt

Veuillez fournir exactement 3-5 recommandations de pêche spécifiques pour ces conditions de vent.
Le format DOIT être:
1. [Première recommandation]
2. [Deuxième recommandation]
3. [Troisième recommandation]
etc.

Concentrez-vous sur:
- Sélection des leurres/appâts pour le vent
- Ajustements de technique de pêche
- Conseils de localisation et positionnement
- Recommandations d'équipement
- Considérations de timing

RAPPELEZ-VOUS: Répondez UNIQUEMENT en français!''';

      case 'de':
        return '''$languageInstruction

Wetterbedingungen und Windsituation: $originalPrompt

Bitte geben Sie genau 3-5 spezifische Angelempfehlungen für diese Windbedingungen.
Das Format MUSS sein:
1. [Erste Empfehlung]
2. [Zweite Empfehlung]
3. [Dritte Empfehlung]
etc.

Konzentrieren Sie sich auf:
- Köder-/Köderfischauswahl für Wind
- Anpassungen der Angeltechnik
- Standort- und Positionierungstipps
- Ausrüstungsempfehlungen
- Timing-Überlegungen

DENKEN SIE DARAN: Antworten Sie NUR auf Deutsch!''';

      default:
        return createWindRecommendationPrompt(originalPrompt, l10n);
    }
  }

  /// Создать тестовый промпт для проверки соединения - УСИЛЕННАЯ ВЕРСИЯ
  String createTestPrompt(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return '''${_getStrongLanguageInstruction(l10n)}

Task: Respond with EXACTLY this phrase in English: "API works correctly"
Do not add any other text. Just this exact phrase in English.''';

      case 'ru':
        return '''${_getStrongLanguageInstruction(l10n)}

Задача: Ответь ТОЧНО этой фразой на русском языке: "API работает корректно"
Не добавляй никакого другого текста. Только эта точная фраза на русском.''';

      case 'es':
        return '''${_getStrongLanguageInstruction(l10n)}

Tarea: Responde con EXACTAMENTE esta frase en español: "La API funciona correctamente"
No agregues ningún otro texto. Solo esta frase exacta en español.''';

      case 'fr':
        return '''${_getStrongLanguageInstruction(l10n)}

Tâche: Répondez avec EXACTEMENT cette phrase en français: "L'API fonctionne correctement"
N'ajoutez aucun autre texte. Juste cette phrase exacte en français.''';

      case 'de':
        return '''${_getStrongLanguageInstruction(l10n)}

Aufgabe: Antworten Sie mit GENAU diesem Satz auf Deutsch: "API funktioniert korrekt"
Fügen Sie keinen anderen Text hinzu. Nur dieser genaue Satz auf Deutsch.''';

      default:
        return createTestPrompt(l10n);
    }
  }

  /// Создать специализированный промпт для конкретного типа рыбалки - УСИЛЕННАЯ ВЕРСИЯ
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
    final languageInstruction = _getStrongLanguageInstruction(l10n);
    final experienceLevelName = getExperienceLevelName(experienceLevel, l10n);

    switch (l10n.languageCode) {
      case 'en':
        return '''$languageInstruction

Fishing analysis for: "$typeName"
Current conditions:
- Temperature: ${temperature.round()}°C
- Pressure: ${pressure.round()} mb
- Wind: ${windSpeed.round()} km/h
- Current forecast score: $currentScore/100 points
- Angler experience: $experienceLevelName
- Has fishing history: ${hasHistory ? 'Yes' : 'No'}
- Time: $currentHour:00

Provide EXACTLY 3 specific tips for "$typeName" fishing in these conditions.
Format MUST be:
1. [Tip about lures/baits to use]
2. [Tip about fishing technique and tactics]
3. [Tip about location and timing]

Each tip should be practical and specific to the conditions mentioned above.
REMEMBER: Write ONLY in English!''';

      case 'ru':
        return '''$languageInstruction

Анализ рыбалки для: "$typeName"
Текущие условия:
- Температура: ${temperature.round()}°C
- Давление: ${pressure.round()} мб
- Ветер: ${windSpeed.round()} км/ч
- Текущий балл прогноза: $currentScore/100 баллов
- Опыт рыбака: $experienceLevelName
- Есть история рыбалок: ${hasHistory ? 'Да' : 'Нет'}
- Время: $currentHour:00

Дай ТОЧНО 3 конкретных совета для рыбалки "$typeName" в этих условиях.
Формат ОБЯЗАТЕЛЬНО должен быть:
1. [Совет о приманках/наживках]
2. [Совет о технике и тактике ловли]
3. [Совет о выборе места и времени]

Каждый совет должен быть практичным и конкретным для указанных условий.
ПОМНИ: Пиши ТОЛЬКО на русском языке!''';

      case 'es':
        return '''$languageInstruction

Análisis de pesca para: "$typeName"
Condiciones actuales:
- Temperatura: ${temperature.round()}°C
- Presión: ${pressure.round()} mb
- Viento: ${windSpeed.round()} km/h
- Puntuación actual del pronóstico: $currentScore/100 puntos
- Experiencia del pescador: $experienceLevelName
- Tiene historial de pesca: ${hasHistory ? 'Sí' : 'No'}
- Hora: $currentHour:00

Proporciona EXACTAMENTE 3 consejos específicos para pescar "$typeName" en estas condiciones.
El formato DEBE ser:
1. [Consejo sobre señuelos/cebos a usar]
2. [Consejo sobre técnica y táctica de pesca]
3. [Consejo sobre ubicación y tiempo]

Cada consejo debe ser práctico y específico para las condiciones mencionadas.
RECUERDA: ¡Escribe SOLO en español!''';

      case 'fr':
        return '''$languageInstruction

Analyse de pêche pour: "$typeName"
Conditions actuelles:
- Température: ${temperature.round()}°C
- Pression: ${pressure.round()} mb
- Vent: ${windSpeed.round()} km/h
- Score de prévision actuel: $currentScore/100 points
- Expérience du pêcheur: $experienceLevelName
- A un historique de pêche: ${hasHistory ? 'Oui' : 'Non'}
- Heure: $currentHour:00

Fournissez EXACTEMENT 3 conseils spécifiques pour pêcher "$typeName" dans ces conditions.
Le format DOIT être:
1. [Conseil sur les leurres/appâts à utiliser]
2. [Conseil sur la technique et tactique de pêche]
3. [Conseil sur l'emplacement et le timing]

Chaque conseil doit être pratique et spécifique aux conditions mentionnées.
RAPPELEZ-VOUS: Écrivez UNIQUEMENT en français!''';

      case 'de':
        return '''$languageInstruction

Angel-Analyse für: "$typeName"
Aktuelle Bedingungen:
- Temperatur: ${temperature.round()}°C
- Druck: ${pressure.round()} mb
- Wind: ${windSpeed.round()} km/h
- Aktuelle Vorhersage-Punktzahl: $currentScore/100 Punkte
- Angler-Erfahrung: $experienceLevelName
- Hat Angel-Historie: ${hasHistory ? 'Ja' : 'Nein'}
- Zeit: $currentHour:00

Geben Sie GENAU 3 spezifische Tipps für das Angeln "$typeName" unter diesen Bedingungen.
Das Format MUSS sein:
1. [Tipp über zu verwendende Köder/Köderfische]
2. [Tipp über Angeltechnik und Taktik]
3. [Tipp über Standort und Timing]

Jeder Tipp sollte praktisch und spezifisch für die genannten Bedingungen sein.
DENKEN SIE DARAN: Schreiben Sie NUR auf Deutsch!''';

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

  /// Парсинг обычных рекомендаций ИИ - УЛУЧШЕННАЯ ВЕРСИЯ
  List<String> parseAIRecommendations(String content) {
    final cleanContent = content.trim();
    List<String> recommendations = [];

    // Проверяем на неправильный язык и пытаемся исправить
    if (_isWrongLanguageResponse(cleanContent)) {
      if (kDebugMode) {
        debugPrint('⚠️ Обнаружен ответ на неправильном языке: ${cleanContent.substring(0, math.min(50, cleanContent.length))}...');
      }
      // Возвращаем fallback рекомендации
      return _getFallbackRecommendations();
    }

    // Сначала пробуем разделить по номерам
    final numberedLines = cleanContent.split(RegExp(r'\d+\.\s*'));
    if (numberedLines.length > 1) {
      recommendations = numberedLines
          .skip(1)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.length > 5)
          .take(6)
          .toList();
    }

    // Если нумерованных пунктов нет, разбиваем по переносам строк
    if (recommendations.isEmpty) {
      recommendations = cleanContent
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

  /// Парсинг специализированного ответа ИИ с иконками - УЛУЧШЕННАЯ ВЕРСИЯ
  List<String> parseSpecializedAIResponse(String content, AppLocalizations l10n) {
    final cleanResponse = content.trim();
    final tips = <String>[];

    // Проверяем язык ответа
    if (!validateResponseLanguage(cleanResponse, l10n)) {
      if (kDebugMode) {
        debugPrint('⚠️ AI ответил на неправильном языке. Ожидался: ${l10n.languageCode}');
      }
      // Возвращаем fallback совет на правильном языке
      return [_getFallbackAITip(l10n)];
    }

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

    return tips.isNotEmpty ? tips : [_getFallbackAITip(l10n)];
  }

  /// Валидация языка ответа - УЛУЧШЕННАЯ ВЕРСИЯ
  bool validateResponseLanguage(String response, AppLocalizations l10n) {
    if (response.isEmpty) return false;

    switch (l10n.languageCode) {
      case 'ru':
      // Проверяем наличие кириллических символов и отсутствие латинских слов
        final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);
        final hasEnglishWords = RegExp(r'\b[a-z]{3,}\b', caseSensitive: false).hasMatch(response);
        return hasCyrillic && !hasEnglishWords;

      case 'en':
      // Проверяем наличие латинских символов и отсутствие кириллицы
        final hasLatin = RegExp(r'[a-z]', caseSensitive: false).hasMatch(response);
        final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);
        return hasLatin && !hasCyrillic;

      case 'es':
      // Проверяем латинские символы, возможные испанские слова
        final hasLatin = RegExp(r'[a-záéíóúñü]', caseSensitive: false).hasMatch(response);
        final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);
        return hasLatin && !hasCyrillic;

      case 'fr':
      // Проверяем латинские символы, возможные французские слова
        final hasLatin = RegExp(r'[a-zàâäéèêëïîôöùûüÿç]', caseSensitive: false).hasMatch(response);
        final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);
        return hasLatin && !hasCyrillic;

      case 'de':
      // Проверяем латинские символы, возможные немецкие слова
        final hasLatin = RegExp(r'[a-zäöüß]', caseSensitive: false).hasMatch(response);
        final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(response);
        return hasLatin && !hasCyrillic;

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

  /// Получить УСИЛЕННУЮ инструкцию по языку для ИИ
  String _getStrongLanguageInstruction(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'en':
        return '''CRITICAL LANGUAGE REQUIREMENT:
You MUST respond ONLY in English. If you start writing in Russian, Spanish, French, German or any other language, STOP immediately and restart in English.
DO NOT MIX LANGUAGES. English only!''';

      case 'ru':
        return '''КРИТИЧЕСКОЕ ТРЕБОВАНИЕ К ЯЗЫКУ:
Ты ДОЛЖЕН отвечать ТОЛЬКО на русском языке. Если начнешь писать на английском, испанском, французском, немецком или любом другом языке, немедленно ОСТАНАВЛИВАЙСЯ и начинай заново на русском.
НЕ СМЕШИВАЙ ЯЗЫКИ. Только русский!''';

      case 'es':
        return '''REQUISITO CRÍTICO DE IDIOMA:
DEBES responder SOLO en español. Si empiezas a escribir en inglés, ruso, francés, alemán o cualquier otro idioma, DETENTE inmediatamente y reinicia en español.
NO MEZCLES IDIOMAS. ¡Solo español!''';

      case 'fr':
        return '''EXIGENCE CRITIQUE DE LANGUE:
Vous DEVEZ répondre UNIQUEMENT en français. Si vous commencez à écrire en anglais, russe, espagnol, allemand ou toute autre langue, ARRÊTEZ-VOUS immédiatement et recommencez en français.
NE MÉLANGEZ PAS LES LANGUES. Français uniquement!''';

      case 'de':
        return '''KRITISCHE SPRACHANFORDERUNG:
Sie MÜSSEN AUSSCHLIESSLICH auf Deutsch antworten. Wenn Sie anfangen, auf Englisch, Russisch, Spanisch, Französisch oder einer anderen Sprache zu schreiben, STOPPEN Sie sofort und beginnen Sie auf Deutsch neu.
MISCHEN SIE KEINE SPRACHEN. Nur Deutsch!''';

      default:
        return '''CRITICAL LANGUAGE REQUIREMENT:
You MUST respond ONLY in English. If you start writing in Russian, Spanish, French, German or any other language, STOP immediately and restart in English.
DO NOT MIX LANGUAGES. English only!''';
    }
  }

  /// Проверить, является ли ответ на неправильном языке
  bool _isWrongLanguageResponse(String content) {
    // Проверяем наличие смешанных языков или явно неправильного языка
    final hasCyrillic = RegExp(r'[а-яё]', caseSensitive: false).hasMatch(content);
    final hasLatin = RegExp(r'[a-z]', caseSensitive: false).hasMatch(content);

    // Если есть и кириллица, и латиница в большом количестве - это смешанный язык
    if (hasCyrillic && hasLatin) {
      final cyrillicCount = RegExp(r'[а-яё]', caseSensitive: false).allMatches(content).length;
      final latinCount = RegExp(r'[a-z]', caseSensitive: false).allMatches(content).length;

      // Если оба языка представлены значительно - это проблема
      return cyrillicCount > 10 && latinCount > 10;
    }

    return false;
  }

  /// Получить fallback рекомендации при ошибке языка
  List<String> _getFallbackRecommendations() {
    return [
      'AI language detection error - using default recommendations',
      'Check weather conditions before fishing',
      'Use appropriate lures for current conditions',
    ];
  }

  /// Получить fallback совет от ИИ на правильном языке
  String _getFallbackAITip(AppLocalizations l10n) {
    switch (l10n.languageCode) {
      case 'ru':
        return '🧠 ИИ анализ: Рекомендации адаптированы под текущие условия';
      case 'en':
        return '🧠 AI Analysis: Recommendations adapted to current conditions';
      case 'es':
        return '🧠 Análisis IA: Recomendaciones adaptadas a las condiciones actuales';
      case 'fr':
        return '🧠 Analyse IA: Recommandations adaptées aux conditions actuelles';
      case 'de':
        return '🧠 KI-Analyse: Empfehlungen an aktuelle Bedingungen angepasst';
      default:
        return '🧠 AI Analysis: Recommendations adapted to current conditions';
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