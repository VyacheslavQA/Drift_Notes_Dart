// Путь: lib/services/depth_analysis_service.dart

import 'dart:math' as math;
import 'dart:ui';
import '../models/depth_analysis_model.dart';

/// Сервис для анализа глубин и структуры дна
class DepthAnalysisService {
  // База знаний о рыбе и их предпочтениях (карпфишинг)
  static const Map<String, FishPreferences> _fishDatabase = {
    'карп': FishPreferences(
      preferredDepths: [1.0, 8.0], // от 1 до 8 метров
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ракушка', 'ровно_твердо'],
      preferredStructures: [StructureType.pit, StructureType.shelf, StructureType.plateau],
      activityPeriods: [FishingTimeOfDay.dawn, FishingTimeOfDay.evening, FishingTimeOfDay.night],
      seasonalFactors: {
        SeasonType.spring: 1.3,
        SeasonType.summer: 1.2,
        SeasonType.autumn: 1.1,
        SeasonType.winter: 0.4,
      },
    ),
    'амур': FishPreferences(
      preferredDepths: [0.5, 6.0], // от 0.5 до 6 метров
      preferredBottomTypes: ['трава_водоросли', 'ил', 'ровно_твердо'],
      preferredStructures: [StructureType.shallows, StructureType.shelf, StructureType.plateau],
      activityPeriods: [FishingTimeOfDay.morning, FishingTimeOfDay.day, FishingTimeOfDay.evening],
      seasonalFactors: {
        SeasonType.spring: 1.1,
        SeasonType.summer: 1.4,
        SeasonType.autumn: 1.0,
        SeasonType.winter: 0.2,
      },
    ),
    'сазан': FishPreferences(
      preferredDepths: [2.0, 10.0], // от 2 до 10 метров
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ракушка'],
      preferredStructures: [StructureType.pit, StructureType.channel, StructureType.dropoff],
      activityPeriods: [FishingTimeOfDay.dawn, FishingTimeOfDay.evening, FishingTimeOfDay.night],
      seasonalFactors: {
        SeasonType.spring: 1.2,
        SeasonType.summer: 1.3,
        SeasonType.autumn: 1.1,
        SeasonType.winter: 0.3,
      },
    ),
    'толстолобик': FishPreferences(
      preferredDepths: [1.0, 5.0], // от 1 до 5 метров (планктон в верхних слоях)
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ровно_твердо'],
      preferredStructures: [StructureType.plateau, StructureType.shelf, StructureType.shallows],
      activityPeriods: [FishingTimeOfDay.morning, FishingTimeOfDay.day],
      seasonalFactors: {
        SeasonType.spring: 1.1,
        SeasonType.summer: 1.3,
        SeasonType.autumn: 0.9,
        SeasonType.winter: 0.2,
      },
    ),
  };

  /// Анализирует профиль одного луча
  static DepthProfileAnalysis analyzeRayProfile(
      int rayIndex,
      List<Map<String, dynamic>> markers,
      AnalysisSettings settings,
      ) {
    // Фильтруем маркеры для данного луча
    final rayMarkers = markers
        .where((m) => (m['rayIndex'] as double?)?.toInt() == rayIndex)
        .where((m) => m['depth'] != null && m['distance'] != null)
        .toList();

    if (rayMarkers.isEmpty) {
      return DepthProfileAnalysis(
        rayIndex: rayIndex,
        points: [],
        structures: [],
        averageDepth: 0,
        maxDepth: 0,
        minDepth: 0,
        depthVariation: 0,
      );
    }

    // Сортируем по дистанции
    rayMarkers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Создаем точки глубины
    final points = rayMarkers.map((marker) {
      final bottomType = _getBottomType(marker);
      final color = _getBottomTypeColor(bottomType);
      final fishingScore = _calculatePointFishingScore(marker, settings);

      return DepthPoint(
        distance: marker['distance'] as double,
        depth: marker['depth'] as double,
        bottomType: bottomType,
        color: color,
        notes: marker['notes'] as String?,
        fishingScore: fishingScore,
      );
    }).toList();

    // Анализируем структуры дна
    final structures = _analyzeBottomStructures(points, settings);

    // Вычисляем статистику
    final depths = points.map((p) => p.depth).toList();
    final averageDepth = depths.reduce((a, b) => a + b) / depths.length;
    final maxDepth = depths.reduce(math.max);
    final minDepth = depths.reduce(math.min);
    final depthVariation = _calculateVariation(depths);

    return DepthProfileAnalysis(
      rayIndex: rayIndex,
      points: points,
      structures: structures,
      averageDepth: averageDepth,
      maxDepth: maxDepth,
      minDepth: minDepth,
      depthVariation: depthVariation,
    );
  }

  /// Анализирует все лучи сразу
  static MultiRayAnalysis analyzeAllRays(
      List<Map<String, dynamic>> allMarkers,
      AnalysisSettings settings,
      ) {
    final rayAnalyses = <DepthProfileAnalysis>[];

    // Анализируем каждый луч
    for (int i = 0; i < 5; i++) {
      final analysis = analyzeRayProfile(i, allMarkers, settings);
      rayAnalyses.add(analysis);
    }

    // Находим топ рекомендации
    final topRecommendations = _findTopRecommendations(rayAnalyses, settings);

    // Вычисляем вероятности по видам рыб
    final fishProbabilities = _calculateFishProbabilities(rayAnalyses, settings);

    // Общая оценка водоема
    final overallAssessment = _generateOverallAssessment(rayAnalyses, settings);

    // Общие советы
    final generalTips = _generateGeneralTips(rayAnalyses, settings);

    return MultiRayAnalysis(
      rayAnalyses: rayAnalyses,
      topRecommendations: topRecommendations,
      fishProbabilities: fishProbabilities,
      overallAssessment: overallAssessment,
      generalTips: generalTips,
    );
  }

  /// Анализирует структуры дна
  static List<BottomStructure> _analyzeBottomStructures(
      List<DepthPoint> points,
      AnalysisSettings settings,
      ) {
    if (points.length < 2) return [];

    final structures = <BottomStructure>[];

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final depthDiff = next.depth - current.depth;
      final distanceDiff = next.distance - current.distance;
      final slope = math.atan(depthDiff / distanceDiff) * (180 / math.pi);

      StructureType? structureType;
      double fishingRating = 5.0;
      String description = '';
      List<String> recommendedFish = [];

      // Определяем тип структуры по уклону
      if (slope.abs() > 45) {
        // Крутой свал - хорошо для карпа (укрытие и кормовая база)
        structureType = StructureType.dropoff;
        fishingRating = 7.5;
        description = slope > 0 ? 'Крутой свал в глубину' : 'Крутой подъем';
        recommendedFish = ['карп', 'сазан'];
      } else if (slope.abs() > 20) {
        // Обычный склон - подходит для карпфишинга
        structureType = StructureType.slope;
        fishingRating = 6.5;
        description = slope > 0 ? 'Склон в глубину' : 'Подъем к мелководью';
        recommendedFish = ['карп', 'толстолобик'];
      } else if (slope.abs() < 5) {
        // Ровная полка - отличное место для карпа
        structureType = StructureType.shelf;
        fishingRating = 8.0;
        description = 'Ровная полка';
        recommendedFish = ['карп', 'амур', 'толстолобик'];
      }

      // Корректируем рейтинг на основе типа дна
      fishingRating *= _getBottomTypeMultiplier(current.bottomType);

      if (structureType != null) {
        structures.add(BottomStructure(
          type: structureType,
          startDistance: current.distance,
          endDistance: next.distance,
          startDepth: current.depth,
          endDepth: next.depth,
          slope: slope,
          fishingRating: math.min(10.0, fishingRating),
          description: description,
          recommendedFish: recommendedFish,
        ));
      }
    }

    return structures;
  }

  /// Вычисляет рейтинг точки для рыбалки
  static double _calculatePointFishingScore(
      Map<String, dynamic> marker,
      AnalysisSettings settings,
      ) {
    double score = 5.0; // Базовый рейтинг

    final depth = marker['depth'] as double;
    final bottomType = _getBottomType(marker);

    // Анализируем по каждому целевому виду рыбы
    for (final fish in settings.targetFish) {
      final preferences = _fishDatabase[fish.toLowerCase()];
      if (preferences == null) continue;

      double fishScore = 0.0;

      // Проверка глубины
      if (depth >= preferences.preferredDepths[0] && depth <= preferences.preferredDepths[1]) {
        fishScore += 3.0;
      } else {
        final depthDeviation = math.min(
          (depth - preferences.preferredDepths[0]).abs(),
          (depth - preferences.preferredDepths[1]).abs(),
        );
        fishScore += math.max(0, 3.0 - depthDeviation);
      }

      // Проверка типа дна
      if (preferences.preferredBottomTypes.contains(bottomType)) {
        fishScore += 2.0;
      }

      // Сезонная корректировка
      fishScore *= preferences.seasonalFactors[settings.season] ?? 1.0;

      score = math.max(score, fishScore);
    }

    return math.min(10.0, score);
  }

  /// Находит топ рекомендации
  static List<FishingRecommendation> _findTopRecommendations(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      ) {
    final recommendations = <FishingRecommendation>[];

    for (final analysis in analyses) {
      for (final point in analysis.points) {
        if (point.fishingScore != null && point.fishingScore! >= settings.minFishingRating) {
          final recommendation = FishingRecommendation(
            distance: point.distance,
            depth: point.depth,
            rating: point.fishingScore!,
            reason: _generateRecommendationReason(point, analysis.structures),
            targetFish: _getRecommendedFishForPoint(point, settings),
            recommendedBaits: _getRecommendedBaits(point, settings),
            bestTime: _getBestTime(point, settings),
            type: _getRecommendationType(point.fishingScore!),
          );
          recommendations.add(recommendation);
        }
      }
    }

    // Сортируем по рейтингу и берем топ-10
    recommendations.sort((a, b) => b.rating.compareTo(a.rating));
    return recommendations.take(10).toList();
  }

  // Вспомогательные методы

  static String _getBottomType(Map<String, dynamic> marker) {
    return marker['bottomType'] as String? ??
        _convertLegacyType(marker['type'] as String?) ??
        'ил';
  }

  static String? _convertLegacyType(String? type) {
    if (type == null) return null;
    switch (type) {
      case 'dropoff': return 'бугор';
      case 'weed': return 'трава_водоросли';
      case 'sandbar': return 'ровно_твердо';
      case 'structure': return 'зацеп';
      default: return type;
    }
  }

  static Color _getBottomTypeColor(String bottomType) {
    const colors = {
      'ил': Color(0xFFD4A574),
      'глубокий_ил': Color(0xFF8B4513),
      'ракушка': Color(0xFFFFFFFF),
      'ровно_твердо': Color(0xFFFFFF00),
      'камни': Color(0xFF808080),
      'трава_водоросли': Color(0xFF90EE90),
      'зацеп': Color(0xFFFF0000),
      'бугор': Color(0xFFFF8C00),
      'точка_кормления': Color(0xFF00BFFF),
    };
    return colors[bottomType] ?? const Color(0xFF0000FF);
  }

  static double _getBottomTypeMultiplier(String bottomType) {
    const multipliers = {
      'ил': 0.7,
      'глубокий_ил': 0.6,
      'ракушка': 1.2,
      'ровно_твердо': 1.1,
      'камни': 1.3,
      'трава_водоросли': 1.4,
      'зацеп': 1.5,
      'бугор': 1.2,
      'точка_кормления': 1.8,
    };
    return multipliers[bottomType] ?? 1.0;
  }

  static double _calculateVariation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  static Map<String, double> _calculateFishProbabilities(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      ) {
    final probabilities = <String, double>{};

    for (final fish in ['карп', 'амур', 'сазан', 'толстолобик']) {
      double totalScore = 0.0;
      int pointCount = 0;

      for (final analysis in analyses) {
        for (final point in analysis.points) {
          final score = point.fishingScore ?? 0.0;
          totalScore += score;
          pointCount++;
        }
      }

      probabilities[fish] = pointCount > 0 ? (totalScore / pointCount) / 10.0 : 0.0;
    }

    return probabilities;
  }

  static String _generateOverallAssessment(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      ) {
    final totalPoints = analyses.fold<int>(0, (sum, analysis) => sum + analysis.points.length);
    if (totalPoints == 0) return 'Недостаточно данных для анализа';

    final avgRating = analyses
        .expand((a) => a.points)
        .where((p) => p.fishingScore != null)
        .map((p) => p.fishingScore!)
        .fold<double>(0.0, (sum, score) => sum + score) / totalPoints;

    if (avgRating >= 8.0) {
      return 'Отличный водоем с высоким потенциалом для рыбалки';
    } else if (avgRating >= 6.0) {
      return 'Хороший водоем с перспективными местами';
    } else if (avgRating >= 4.0) {
      return 'Средний водоем, требует поиска рыбных мест';
    } else {
      return 'Сложный водоем, нужна детальная разведка';
    }
  }

  static List<String> _generateGeneralTips(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      ) {
    final tips = <String>[];

    // Анализ структур
    final allStructures = analyses.expand((a) => a.structures).toList();
    final dropoffs = allStructures.where((s) => s.type == StructureType.dropoff).length;

    if (dropoffs > 0) {
      tips.add('Найдено $dropoffs свал(ов) - перспективные места для карпа');
    }

    // Анализ глубин
    final avgDepth = analyses
        .expand((a) => a.points)
        .map((p) => p.depth)
        .fold<double>(0.0, (sum, depth) => sum + depth) /
        analyses.expand((a) => a.points).length;

    if (avgDepth > 8) {
      tips.add('Глубокий водоем - подходит для крупного карпа и сазана');
    } else if (avgDepth < 3) {
      tips.add('Мелководный участок - хорош для амура и толстолобика');
    }

    return tips;
  }

  static String _generateRecommendationReason(DepthPoint point, List<BottomStructure> structures) {
    final nearbyStructure = structures.firstWhere(
          (s) => point.distance >= s.startDistance && point.distance <= s.endDistance,
      orElse: () => BottomStructure(
        type: StructureType.shelf,
        startDistance: 0,
        endDistance: 0,
        startDepth: 0,
        endDepth: 0,
        slope: 0,
        fishingRating: 0,
        description: 'Обычное место',
        recommendedFish: [],
      ),
    );

    return '${nearbyStructure.description} с типом дна "${point.bottomType}"';
  }

  static List<String> _getRecommendedFishForPoint(DepthPoint point, AnalysisSettings settings) {
    return settings.targetFish.where((fish) {
      final preferences = _fishDatabase[fish.toLowerCase()];
      if (preferences == null) return false;

      return point.depth >= preferences.preferredDepths[0] &&
          point.depth <= preferences.preferredDepths[1] &&
          preferences.preferredBottomTypes.contains(point.bottomType);
    }).toList();
  }

  static List<String> _getRecommendedBaits(DepthPoint point, AnalysisSettings settings) {
    // Рекомендации приманок для карпфишинга
    if (point.bottomType == 'ил' || point.bottomType == 'глубокий_ил') {
      return ['Бойлы', 'Пеллетс', 'Кукуруза', 'Червь'];
    } else if (point.bottomType == 'ракушка') {
      return ['Бойлы', 'Тигровые орехи', 'Пеллетс'];
    } else if (point.bottomType == 'ровно_твердо') {
      return ['Бойлы', 'Кукуруза', 'Конопля', 'Пеллетс'];
    } else if (point.bottomType == 'трава_водоросли') {
      return ['Pop-up бойлы', 'Плавающая кукуруза', 'Пеллетс'];
    }
    return ['Бойлы', 'Кукуруза', 'Пеллетс'];
  }

  static String _getBestTime(DepthPoint point, AnalysisSettings settings) {
    // Упрощенная логика времени
    if (point.depth > 8) {
      return 'Рассвет, вечер';
    } else if (point.depth < 3) {
      return 'Утро, день';
    }
    return 'Утро, вечер';
  }

  static RecommendationType _getRecommendationType(double rating) {
    if (rating >= 8.5) return RecommendationType.excellent;
    if (rating >= 7.0) return RecommendationType.good;
    if (rating >= 5.0) return RecommendationType.average;
    return RecommendationType.avoid;
  }
}

/// Предпочтения рыбы
class FishPreferences {
  final List<double> preferredDepths; // [min, max]
  final List<String> preferredBottomTypes;
  final List<StructureType> preferredStructures;
  final List<FishingTimeOfDay> activityPeriods;
  final Map<SeasonType, double> seasonalFactors;

  const FishPreferences({
    required this.preferredDepths,
    required this.preferredBottomTypes,
    required this.preferredStructures,
    required this.activityPeriods,
    required this.seasonalFactors,
  });
}