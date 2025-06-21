// Путь: lib/models/depth_analysis_model.dart

import 'dart:ui';

/// Модель для анализа профиля дна
class DepthProfileAnalysis {
  final int rayIndex;
  final List<DepthPoint> points;
  final List<BottomStructure> structures;
  final double averageDepth;
  final double maxDepth;
  final double minDepth;
  final double depthVariation;

  const DepthProfileAnalysis({
    required this.rayIndex,
    required this.points,
    required this.structures,
    required this.averageDepth,
    required this.maxDepth,
    required this.minDepth,
    required this.depthVariation,
  });
}

/// Точка глубины с дополнительными данными
class DepthPoint {
  final double distance;
  final double depth;
  final String bottomType;
  final Color color;
  final String? notes;
  final double? fishingScore; // Рейтинг места для рыбалки (0-10)

  const DepthPoint({
    required this.distance,
    required this.depth,
    required this.bottomType,
    required this.color,
    this.notes,
    this.fishingScore,
  });
}

/// Структуры дна
class BottomStructure {
  final StructureType type;
  final double startDistance;
  final double endDistance;
  final double startDepth;
  final double endDepth;
  final double slope; // Уклон в градусах
  final double fishingRating; // Рейтинг для рыбалки (0-10)
  final String description;

  const BottomStructure({
    required this.type,
    required this.startDistance,
    required this.endDistance,
    required this.startDepth,
    required this.endDepth,
    required this.slope,
    required this.fishingRating,
    required this.description,
  });
}

/// Типы структур дна
enum StructureType {
  dropoff, // Свал
  shelf, // Полка
  hill, // Бугор
  pit, // Яма
  channel, // Русло
  shallows, // Отмель
  plateau, // Плато
  slope, // Склон
}

/// Рекомендации ИИ для конкретного места
class FishingRecommendation {
  final double distance;
  final double depth;
  final double rating; // 0-10
  final String reason;
  final String bestTime; // Лучшее время для ловли
  final RecommendationType type;

  const FishingRecommendation({
    required this.distance,
    required this.depth,
    required this.rating,
    required this.reason,
    required this.bestTime,
    required this.type,
  });
}

/// Типы рекомендаций
enum RecommendationType {
  excellent, // Отличное место
  good, // Хорошее место
  average, // Среднее место
  avoid, // Избегать
}

/// Настройки анализа (упрощенные - всегда для карповых)
class AnalysisSettings {
  final bool includeStructureAnalysis;
  final bool includeBottomTypeAnalysis;
  final double minFishingRating; // Минимальный рейтинг для показа

  const AnalysisSettings({
    this.includeStructureAnalysis = true,
    this.includeBottomTypeAnalysis = true,
    this.minFishingRating = 6.0,
  });
}



/// Результат комплексного анализа всех лучей
class MultiRayAnalysis {
  final List<DepthProfileAnalysis> rayAnalyses;
  final List<FishingRecommendation> topRecommendations;
  final String overallAssessment; // Общая оценка водоема
  final List<String> generalTips; // Общие советы

  const MultiRayAnalysis({
    required this.rayAnalyses,
    required this.topRecommendations,
    required this.overallAssessment,
    required this.generalTips,
  });
}

/// Конфигурация отображения для сравнения лучей
class RayComparisonConfig {
  final List<int> selectedRays;
  final Map<int, Color> rayColors;
  final bool showAllAtOnce;
  final bool showDepthLabels;
  final bool showStructureHighlights;
  final bool showRecommendations;
  final double transparency;

  const RayComparisonConfig({
    required this.selectedRays,
    required this.rayColors,
    this.showAllAtOnce = false,
    this.showDepthLabels = true,
    this.showStructureHighlights = true,
    this.showRecommendations = true,
    this.transparency = 0.8,
  });

  RayComparisonConfig copyWith({
    List<int>? selectedRays,
    Map<int, Color>? rayColors,
    bool? showAllAtOnce,
    bool? showDepthLabels,
    bool? showStructureHighlights,
    bool? showRecommendations,
    double? transparency,
  }) {
    return RayComparisonConfig(
      selectedRays: selectedRays ?? this.selectedRays,
      rayColors: rayColors ?? this.rayColors,
      showAllAtOnce: showAllAtOnce ?? this.showAllAtOnce,
      showDepthLabels: showDepthLabels ?? this.showDepthLabels,
      showStructureHighlights: showStructureHighlights ?? this.showStructureHighlights,
      showRecommendations: showRecommendations ?? this.showRecommendations,
      transparency: transparency ?? this.transparency,
    );
  }
}