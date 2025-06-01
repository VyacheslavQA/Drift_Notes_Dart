// Путь: lib/models/ai_bite_prediction_model.dart

import '../services/ai_bite_prediction_service.dart';
import 'package:flutter/material.dart';

/// Мультитиповый прогноз для всех видов рыбалки
class MultiFishingTypePrediction {
  final String bestFishingType;
  final AIBitePrediction bestPrediction;
  final Map<String, AIBitePrediction> allPredictions;
  final ComparisonAnalysis comparison;
  final List<String> generalRecommendations;
  final WeatherSummary weatherSummary;
  final DateTime generatedAt;

  MultiFishingTypePrediction({
    required this.bestFishingType,
    required this.bestPrediction,
    required this.allPredictions,
    required this.comparison,
    required this.generalRecommendations,
    required this.weatherSummary,
    required this.generatedAt,
  });

  factory MultiFishingTypePrediction.fromJson(Map<String, dynamic> json) {
    return MultiFishingTypePrediction(
      bestFishingType: json['bestFishingType'] ?? '',
      bestPrediction: AIBitePrediction.fromJson(json['bestPrediction'] ?? {}),
      allPredictions: (json['allPredictions'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, AIBitePrediction.fromJson(value))),
      comparison: ComparisonAnalysis.fromJson(json['comparison'] ?? {}),
      generalRecommendations: List<String>.from(json['generalRecommendations'] ?? []),
      weatherSummary: WeatherSummary.fromJson(json['weatherSummary'] ?? {}),
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestFishingType': bestFishingType,
      'bestPrediction': bestPrediction.toJson(),
      'allPredictions': allPredictions.map((key, value) => MapEntry(key, value.toJson())),
      'comparison': comparison.toJson(),
      'generalRecommendations': generalRecommendations,
      'weatherSummary': weatherSummary.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Получить топ-N лучших типов рыбалки
  List<FishingTypeRanking> getTopFishingTypes(int count) {
    return comparison.rankings.take(count).toList();
  }

  /// Получить прогноз для конкретного типа
  AIBitePrediction? getPredictionForType(String fishingType) {
    return allPredictions[fishingType];
  }

  /// Проверить, есть ли альтернативы с хорошим скором
  bool hasGoodAlternatives({int minScore = 60}) {
    return comparison.rankings.where((r) => r.score >= minScore).length > 1;
  }

  /// Получить количество подходящих типов рыбалки
  int get suitableTypesCount {
    return comparison.rankings.where((r) => r.score >= 40).length;
  }
}

/// Анализ сравнения всех типов рыбалки
class ComparisonAnalysis {
  final List<FishingTypeRanking> rankings;
  final FishingTypeRanking bestOverall;
  final List<FishingTypeRanking> alternativeOptions;
  final List<FishingTypeRanking> worstOptions;

  ComparisonAnalysis({
    required this.rankings,
    required this.bestOverall,
    required this.alternativeOptions,
    required this.worstOptions,
  });

  factory ComparisonAnalysis.fromJson(Map<String, dynamic> json) {
    return ComparisonAnalysis(
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .map((item) => FishingTypeRanking.fromJson(item))
          .toList(),
      bestOverall: FishingTypeRanking.fromJson(json['bestOverall'] ?? {}),
      alternativeOptions: (json['alternativeOptions'] as List<dynamic>? ?? [])
          .map((item) => FishingTypeRanking.fromJson(item))
          .toList(),
      worstOptions: (json['worstOptions'] as List<dynamic>? ?? [])
          .map((item) => FishingTypeRanking.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rankings': rankings.map((r) => r.toJson()).toList(),
      'bestOverall': bestOverall.toJson(),
      'alternativeOptions': alternativeOptions.map((r) => r.toJson()).toList(),
      'worstOptions': worstOptions.map((r) => r.toJson()).toList(),
    };
  }

  /// Получить типы с отличными условиями (80+)
  List<FishingTypeRanking> get excellentTypes {
    return rankings.where((r) => r.score >= 80).toList();
  }

  /// Получить типы с хорошими условиями (60-79)
  List<FishingTypeRanking> get goodTypes {
    return rankings.where((r) => r.score >= 60 && r.score < 80).toList();
  }

  /// Получить типы со средними условиями (40-59)
  List<FishingTypeRanking> get moderateTypes {
    return rankings.where((r) => r.score >= 40 && r.score < 60).toList();
  }
}

/// Рейтинг конкретного типа рыбалки
class FishingTypeRanking {
  final String fishingType;
  final String typeName;
  final String icon;
  final int score;
  final ActivityLevel activityLevel;
  final String shortRecommendation;
  final List<String> keyFactors;

  FishingTypeRanking({
    required this.fishingType,
    required this.typeName,
    required this.icon,
    required this.score,
    required this.activityLevel,
    required this.shortRecommendation,
    required this.keyFactors,
  });

  factory FishingTypeRanking.fromJson(Map<String, dynamic> json) {
    return FishingTypeRanking(
      fishingType: json['fishingType'] ?? '',
      typeName: json['typeName'] ?? '',
      icon: json['icon'] ?? '🎣',
      score: json['score'] ?? 0,
      activityLevel: ActivityLevel.values.firstWhere(
            (e) => e.toString() == json['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      shortRecommendation: json['shortRecommendation'] ?? '',
      keyFactors: List<String>.from(json['keyFactors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fishingType': fishingType,
      'typeName': typeName,
      'icon': icon,
      'score': score,
      'activityLevel': activityLevel.toString(),
      'shortRecommendation': shortRecommendation,
      'keyFactors': keyFactors,
    };
  }

  /// Получить цвет по скору
  Color get scoreColor {
    if (score >= 80) return const Color(0xFF4CAF50); // Зеленый
    if (score >= 60) return const Color(0xFF8BC34A); // Светло-зеленый
    if (score >= 40) return const Color(0xFFFFC107); // Желтый
    if (score >= 20) return const Color(0xFFFF9800); // Оранжевый
    return const Color(0xFFF44336); // Красный
  }

  /// Получить текстовое описание уровня
  String get scoreDescription {
    if (score >= 80) return 'Отлично';
    if (score >= 60) return 'Хорошо';
    if (score >= 40) return 'Средне';
    if (score >= 20) return 'Слабо';
    return 'Очень слабо';
  }

  /// Подходящий ли это тип для рыбалки
  bool get isRecommended => score >= 60;

  /// Стоит ли рассматривать как альтернативу
  bool get isAlternative => score >= 40 && score < 60;

  /// Неподходящий тип
  bool get isNotRecommended => score < 40;
}

/// Краткая сводка погодных условий
class WeatherSummary {
  final double temperature;
  final double pressure;
  final double windSpeed;
  final int humidity;
  final String condition;
  final String moonPhase;

  WeatherSummary({
    required this.temperature,
    required this.pressure,
    required this.windSpeed,
    required this.humidity,
    required this.condition,
    required this.moonPhase,
  });

  factory WeatherSummary.fromJson(Map<String, dynamic> json) {
    return WeatherSummary(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      pressure: (json['pressure'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      humidity: json['humidity'] ?? 0,
      condition: json['condition'] ?? '',
      moonPhase: json['moonPhase'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'condition': condition,
      'moonPhase': moonPhase,
    };
  }

  /// Получить общую оценку погодных условий
  String get overallAssessment {
    int positiveFactors = 0;

    // Температура
    if (temperature >= 10 && temperature <= 25) positiveFactors++;

    // Давление
    if (pressure >= 1010 && pressure <= 1025) positiveFactors++;

    // Ветер
    if (windSpeed <= 15) positiveFactors++;

    // Влажность
    if (humidity >= 40 && humidity <= 70) positiveFactors++;

    if (positiveFactors >= 3) return 'Отличные условия';
    if (positiveFactors >= 2) return 'Хорошие условия';
    if (positiveFactors >= 1) return 'Средние условия';
    return 'Сложные условия';
  }
}

/// Оригинальная модель прогноза (ИСПРАВЛЕНА)
class AIBitePrediction {
  final int overallScore; // 0-100
  final ActivityLevel activityLevel;
  final double confidence; // 0.0-1.0
  final String recommendation;
  final String detailedAnalysis;
  final List<BiteFactorAnalysis> factors;
  final List<OptimalTimeWindow> bestTimeWindows;
  final List<String> tips;
  final DateTime generatedAt;
  final String dataSource; // 'local_ai', 'cloud_ai', 'hybrid'
  final String modelVersion;

  // ДОБАВЛЕНО: поля для обратной совместимости
  final String fishingType;

  AIBitePrediction({
    required this.overallScore,
    required this.activityLevel,
    required this.confidence,
    required this.recommendation,
    this.detailedAnalysis = '',
    this.factors = const [],
    this.bestTimeWindows = const [],
    required this.tips,
    DateTime? generatedAt,
    this.dataSource = 'local_ai',
    this.modelVersion = '1.0.0',
    this.fishingType = '', // ДОБАВЛЕНО
  }) : generatedAt = generatedAt ?? DateTime.now();

  // ДОБАВЛЕНО: геттер для обратной совместимости
  int get confidencePercent => (confidence * 100).round();

  factory AIBitePrediction.fromJson(Map<String, dynamic> json) {
    return AIBitePrediction(
      overallScore: json['overallScore'] ?? 0,
      activityLevel: ActivityLevel.values.firstWhere(
            (e) => e.toString() == json['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? '',
      factors: (json['factors'] as List<dynamic>? ?? [])
          .map((item) => BiteFactorAnalysis.fromJson(item))
          .toList(),
      bestTimeWindows: (json['bestTimeWindows'] as List<dynamic>? ?? [])
          .map((item) => OptimalTimeWindow.fromJson(item))
          .toList(),
      tips: List<String>.from(json['tips'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
      dataSource: json['dataSource'] ?? 'unknown',
      modelVersion: json['modelVersion'] ?? '1.0.0',
      fishingType: json['fishingType'] ?? '', // ДОБАВЛЕНО
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'activityLevel': activityLevel.toString(),
      'confidence': confidence,
      'recommendation': recommendation,
      'detailedAnalysis': detailedAnalysis,
      'factors': factors.map((f) => f.toJson()).toList(),
      'bestTimeWindows': bestTimeWindows.map((w) => w.toJson()).toList(),
      'tips': tips,
      'generatedAt': generatedAt.toIso8601String(),
      'dataSource': dataSource,
      'modelVersion': modelVersion,
      'fishingType': fishingType, // ДОБАВЛЕНО
    };
  }

  /// Получить топ-3 позитивных фактора
  List<BiteFactorAnalysis> get topPositiveFactors {
    return factors
        .where((f) => f.isPositive)
        .toList()
      ..sort((a, b) => b.impact.compareTo(a.impact))
      ..take(3);
  }

  /// Получить топ-3 негативных фактора
  List<BiteFactorAnalysis> get topNegativeFactors {
    return factors
        .where((f) => !f.isPositive)
        .toList()
      ..sort((a, b) => a.impact.compareTo(b.impact))
      ..take(3);
  }

  /// Получить самый важный фактор
  BiteFactorAnalysis? get mostImportantFactor {
    if (factors.isEmpty) return null;

    return factors.reduce((a, b) =>
    (a.impact.abs() * a.weight) > (b.impact.abs() * b.weight) ? a : b
    );
  }

  /// Получить следующее лучшее временное окно
  OptimalTimeWindow? get nextBestTimeWindow {
    if (bestTimeWindows.isEmpty) return null;

    final now = DateTime.now();

    // Ищем ближайшее будущее окно
    for (final window in bestTimeWindows) {
      if (window.startTime.isAfter(now)) {
        return window;
      }
    }

    // Если все окна в прошлом, возвращаем первое (на завтра)
    return bestTimeWindows.first;
  }

  /// Проверить, активно ли сейчас лучшее время
  bool get isCurrentlyBestTime {
    if (bestTimeWindows.isEmpty) return false;

    final now = DateTime.now();

    return bestTimeWindows.any((window) =>
    now.isAfter(window.startTime) && now.isBefore(window.endTime)
    );
  }

  /// Получить цветовую схему для скора
  Color get scoreColor {
    if (overallScore >= 80) return const Color(0xFF4CAF50);
    if (overallScore >= 60) return const Color(0xFF8BC34A);
    if (overallScore >= 40) return const Color(0xFFFFC107);
    if (overallScore >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

/// Анализ фактора влияющего на клев
class BiteFactorAnalysis {
  final String name;
  final String value;
  final int impact; // -100 to +100
  final double weight; // 0.0 to 1.0
  final String description;
  final bool isPositive;

  BiteFactorAnalysis({
    required this.name,
    required this.value,
    required this.impact,
    required this.weight,
    required this.description,
    required this.isPositive,
  });

  factory BiteFactorAnalysis.fromJson(Map<String, dynamic> json) {
    return BiteFactorAnalysis(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      impact: json['impact'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      isPositive: json['isPositive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'impact': impact,
      'weight': weight,
      'description': description,
      'isPositive': isPositive,
    };
  }

  /// Получить иконку для фактора
  String get icon {
    switch (name.toLowerCase()) {
      case 'температура':
        return '🌡️';
      case 'давление':
      case 'атмосферное давление':
        return '📊';
      case 'ветер':
        return '💨';
      case 'время суток':
        return '⏰';
      case 'фаза луны':
        return '🌙';
      case 'сезон':
        return '📅';
      case 'погодные условия':
        return '🌤️';
      case 'персональная история':
        return '📈';
      default:
        return '🎯';
    }
  }

  /// Получить цвет для отображения impact
  Color get impactColor {
    if (impact > 10) return const Color(0xFF4CAF50); // Зеленый
    if (impact > 0) return const Color(0xFF8BC34A); // Светло-зеленый
    if (impact == 0) return const Color(0xFF9E9E9E); // Серый
    if (impact > -10) return const Color(0xFFFF9800); // Оранжевый
    return const Color(0xFFF44336); // Красный
  }

  /// Получить текстовое описание силы влияния
  String get impactDescription {
    final absImpact = impact.abs();
    if (absImpact >= 15) return isPositive ? 'Сильно помогает' : 'Сильно мешает';
    if (absImpact >= 8) return isPositive ? 'Помогает' : 'Мешает';
    if (absImpact >= 3) return isPositive ? 'Слегка помогает' : 'Слегка мешает';
    return 'Нейтрально';
  }

  /// Получить важность фактора в процентах
  int get importancePercent {
    return (weight * 100).round();
  }
}

/// Оптимальное временное окно для рыбалки
class OptimalTimeWindow {
  final DateTime startTime;
  final DateTime endTime;
  final double activity; // 0.0-1.0
  final String reason;
  final List<String> recommendations;

  OptimalTimeWindow({
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.reason,
    required this.recommendations,
  });

  factory OptimalTimeWindow.fromJson(Map<String, dynamic> json) {
    return OptimalTimeWindow(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      activity: (json['activity'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'activity': activity,
      'reason': reason,
      'recommendations': recommendations,
    };
  }

  /// Получить временной диапазон в читаемом формате
  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Получить продолжительность окна
  Duration get duration {
    return endTime.difference(startTime);
  }

  /// Получить продолжительность в часах и минутах
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}ч ${minutes}м';
    } else if (hours > 0) {
      return '${hours}ч';
    } else {
      return '${minutes}м';
    }
  }

  /// Проверить, активно ли окно сейчас
  bool get isActiveNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Проверить, будет ли окно сегодня
  bool get isToday {
    final now = DateTime.now();
    return startTime.day == now.day &&
        startTime.month == now.month &&
        startTime.year == now.year;
  }

  /// Проверить, будет ли окно завтра
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return startTime.day == tomorrow.day &&
        startTime.month == tomorrow.month &&
        startTime.year == tomorrow.year;
  }

  /// Получить время до начала окна
  Duration? get timeUntilStart {
    final now = DateTime.now();
    if (startTime.isAfter(now)) {
      return startTime.difference(now);
    }
    return null; // Окно уже началось или прошло
  }

  /// Получить текст "через сколько начнется"
  String? get timeUntilStartText {
    final timeUntil = timeUntilStart;
    if (timeUntil == null) return null;

    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;

    if (hours > 0) {
      return 'Через ${hours}ч ${minutes}м';
    } else if (minutes > 0) {
      return 'Через ${minutes}м';
    } else {
      return 'Скоро';
    }
  }

  /// Получить цвет активности
  Color get activityColor {
    if (activity >= 0.8) return const Color(0xFF4CAF50);
    if (activity >= 0.6) return const Color(0xFF8BC34A);
    if (activity >= 0.4) return const Color(0xFFFFC107);
    if (activity >= 0.2) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  /// Получить процент активности для отображения
  int get activityPercent {
    return (activity * 100).round();
  }

  /// Получить иконку времени суток
  String get timeIcon {
    final hour = startTime.hour;
    if (hour >= 5 && hour < 12) return '🌅'; // Утро
    if (hour >= 12 && hour < 17) return '☀️'; // День
    if (hour >= 17 && hour < 21) return '🌇'; // Вечер
    return '🌙'; // Ночь
  }
}

/// Настройки пользователя для ИИ-анализа
class AIUserPreferences {
  final List<String> preferredFishingTypes;
  final Map<String, double> typeWeights; // Персональные веса важности типов
  final bool enableCloudAI;
  final bool enablePersonalization;
  final int maxRecommendations;
  final bool showDetailedFactors;
  final bool enableNotifications;

  AIUserPreferences({
    this.preferredFishingTypes = const [],
    this.typeWeights = const {},
    this.enableCloudAI = true,
    this.enablePersonalization = true,
    this.maxRecommendations = 3,
    this.showDetailedFactors = true,
    this.enableNotifications = false,
  });

  factory AIUserPreferences.fromJson(Map<String, dynamic> json) {
    return AIUserPreferences(
      preferredFishingTypes: List<String>.from(json['preferredFishingTypes'] ?? []),
      typeWeights: Map<String, double>.from(json['typeWeights'] ?? {}),
      enableCloudAI: json['enableCloudAI'] ?? true,
      enablePersonalization: json['enablePersonalization'] ?? true,
      maxRecommendations: json['maxRecommendations'] ?? 3,
      showDetailedFactors: json['showDetailedFactors'] ?? true,
      enableNotifications: json['enableNotifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredFishingTypes': preferredFishingTypes,
      'typeWeights': typeWeights,
      'enableCloudAI': enableCloudAI,
      'enablePersonalization': enablePersonalization,
      'maxRecommendations': maxRecommendations,
      'showDetailedFactors': showDetailedFactors,
      'enableNotifications': enableNotifications,
    };
  }

  /// Создать копию с изменениями
  AIUserPreferences copyWith({
    List<String>? preferredFishingTypes,
    Map<String, double>? typeWeights,
    bool? enableCloudAI,
    bool? enablePersonalization,
    int? maxRecommendations,
    bool? showDetailedFactors,
    bool? enableNotifications,
  }) {
    return AIUserPreferences(
      preferredFishingTypes: preferredFishingTypes ?? this.preferredFishingTypes,
      typeWeights: typeWeights ?? this.typeWeights,
      enableCloudAI: enableCloudAI ?? this.enableCloudAI,
      enablePersonalization: enablePersonalization ?? this.enablePersonalization,
      maxRecommendations: maxRecommendations ?? this.maxRecommendations,
      showDetailedFactors: showDetailedFactors ?? this.showDetailedFactors,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  /// Проверить, предпочитает ли пользователь данный тип рыбалки
  bool isPreferredType(String fishingType) {
    return preferredFishingTypes.contains(fishingType);
  }

  /// Получить вес для типа рыбалки (по умолчанию 1.0)
  double getTypeWeight(String fishingType) {
    return typeWeights[fishingType] ?? 1.0;
  }

  /// Добавить предпочитаемый тип рыбалки
  AIUserPreferences addPreferredType(String fishingType) {
    if (preferredFishingTypes.contains(fishingType)) return this;

    return copyWith(
      preferredFishingTypes: [...preferredFishingTypes, fishingType],
    );
  }

  /// Удалить предпочитаемый тип рыбалки
  AIUserPreferences removePreferredType(String fishingType) {
    return copyWith(
      preferredFishingTypes: preferredFishingTypes.where((type) => type != fishingType).toList(),
    );
  }

  /// Установить вес для типа рыбалки
  AIUserPreferences setTypeWeight(String fishingType, double weight) {
    final newWeights = Map<String, double>.from(typeWeights);
    newWeights[fishingType] = weight;

    return copyWith(typeWeights: newWeights);
  }
}