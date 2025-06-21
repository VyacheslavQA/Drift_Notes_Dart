// Путь: lib/services/depth_analysis_service.dart

import 'dart:math' as math;
import 'dart:ui';
import '../models/depth_analysis_model.dart';

/// Предпочтения карповых рыб (упрощенные)
class FishPreferences {
  final List<double> preferredDepths; // [min, max]
  final List<String> preferredBottomTypes;
  final double baseActivity; // Базовая активность вида

  const FishPreferences({
    required this.preferredDepths,
    required this.preferredBottomTypes,
    required this.baseActivity,
  });
}

/// Сервис для анализа глубин и структуры дна (карпфишинг)
class DepthAnalysisService {
  // База знаний для карповых рыб
  static const Map<String, FishPreferences> _carpFishDatabase = {
    'карп': FishPreferences(
      preferredDepths: [1.0, 8.0], // от 1 до 8 метров
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ракушка', 'ровно_твердо', 'точка_кормления'],
      baseActivity: 1.2,
    ),
    'амур': FishPreferences(
      preferredDepths: [0.5, 6.0], // от 0.5 до 6 метров
      preferredBottomTypes: ['трава_водоросли', 'ил', 'ровно_твердо', 'точка_кормления'],
      baseActivity: 1.1,
    ),
    'сазан': FishPreferences(
      preferredDepths: [2.0, 10.0], // от 2 до 10 метров
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ракушка', 'точка_кормления'],
      baseActivity: 1.3,
    ),
    'толстолобик': FishPreferences(
      preferredDepths: [1.0, 5.0], // от 1 до 5 метров
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ровно_твердо', 'точка_кормления'],
      baseActivity: 1.0,
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

    // Общая оценка водоема
    final overallAssessment = _generateOverallAssessment(rayAnalyses, settings);

    // Общие советы
    final generalTips = _generateGeneralTips(rayAnalyses, settings);

    return MultiRayAnalysis(
      rayAnalyses: rayAnalyses,
      topRecommendations: topRecommendations,
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

      // Определяем тип структуры по уклону
      if (slope.abs() > 45) {
        // Крутой свал - хорошо для рыбалки (укрытие и кормовая база)
        structureType = StructureType.dropoff;
        fishingRating = 7.5;
        description = slope > 0 ? 'Крутой свал в глубину' : 'Крутой подъем';
      } else if (slope.abs() > 20) {
        // Обычный склон - подходит для рыбалки
        structureType = StructureType.slope;
        fishingRating = 6.5;
        description = slope > 0 ? 'Склон в глубину' : 'Подъем к мелководью';
      } else if (slope.abs() < 5) {
        // Ровная полка - отличное место для рыбалки
        structureType = StructureType.shelf;
        fishingRating = 8.0;
        description = 'Ровная полка';
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
        ));
      }
    }

    return structures;
  }

  /// Вычисляет рейтинг точки для карповой рыбалки
  static double _calculatePointFishingScore(
      Map<String, dynamic> marker,
      AnalysisSettings settings,
      ) {
    double maxScore = 0.0; // Максимальный рейтинг среди всех карповых

    final depth = marker['depth'] as double;
    final bottomType = _getBottomType(marker);

    // Анализируем по каждому виду карповых
    for (final entry in _carpFishDatabase.entries) {
      final fishName = entry.key;
      final preferences = entry.value;

      double fishScore = 4.0; // Базовый рейтинг для карповых

      // Проверка глубины
      if (depth >= preferences.preferredDepths[0] && depth <= preferences.preferredDepths[1]) {
        fishScore += 3.0; // Идеальная глубина
      } else {
        // Штраф за отклонение от оптимальной глубины
        final minDistance = (depth - preferences.preferredDepths[0]).abs();
        final maxDistance = (depth - preferences.preferredDepths[1]).abs();
        final deviation = math.min(minDistance, maxDistance);
        fishScore += math.max(0, 3.0 - deviation * 0.5);
      }

      // Проверка типа дна
      if (preferences.preferredBottomTypes.contains(bottomType)) {
        fishScore += 2.0; // Подходящий тип дна
      } else {
        fishScore += 0.5; // Неоптимальный, но приемлемый
      }

      // Применяем базовую активность вида
      fishScore *= preferences.baseActivity;

      // Корректируем на основе типа дна
      fishScore *= _getBottomTypeMultiplier(bottomType);

      maxScore = math.max(maxScore, fishScore);
    }

    return math.min(10.0, maxScore);
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
    final shelves = allStructures.where((s) => s.type == StructureType.shelf).length;

    if (dropoffs > 0) {
      tips.add('Найдено $dropoffs свал(ов) - отличные места для карпа и сазана');
    }

    if (shelves > 0) {
      tips.add('Найдено $shelves полок - идеальные места для кормления карповых');
    }

    // Анализ глубин
    final allPoints = analyses.expand((a) => a.points).toList();
    if (allPoints.isNotEmpty) {
      final avgDepth = allPoints.map((p) => p.depth).reduce((a, b) => a + b) / allPoints.length;

      if (avgDepth > 8) {
        tips.add('Глубокий водоем - ищите бровки и свалы для крупного карпа');
      } else if (avgDepth < 3) {
        tips.add('Мелководный участок - хорош для амура и толстолобика');
      } else {
        tips.add('Средние глубины - универсальный участок для всех карповых');
      }
    }

    // Анализ типов дна (карпфишинг специфика)
    final bottomTypes = allPoints.map((p) => p.bottomType).toSet();
    if (bottomTypes.contains('точка_кормления')) {
      tips.add('Есть проверенные точки кормления - приоритет №1 для карпфишинга');
    }
    if (bottomTypes.contains('трава_водоросли')) {
      tips.add('Много растительности - отлично для амура, используйте pop-up насадки');
    }
    if (bottomTypes.contains('ракушка')) {
      tips.add('Ракушечное дно - естественная кормовая база для карпа');
    }
    if (bottomTypes.contains('ил')) {
      tips.add('Илистое дно - классика карпфишинга, используйте бойлы');
    }
    if (bottomTypes.contains('зацеп')) {
      tips.add('Есть закоряженные участки - перспективные, но осторожно с оснасткой');
    }

    // Добавляем карпфишинг советы
    final avgRating = allPoints
        .where((p) => p.fishingScore != null)
        .map((p) => p.fishingScore!)
        .fold<double>(0.0, (sum, score) => sum + score) / allPoints.length;

    if (avgRating >= 8.0) {
      tips.add('Отличный карповый водоем - готовьте дальние забросы и терпение');
    } else if (avgRating >= 6.0) {
      tips.add('Хороший потенциал - найдите рабочие точки и прикармливайте');
    } else {
      tips.add('Сложный водоем - требует разведки и поиска активной рыбы');
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
      ),
    );

    return '${nearbyStructure.description} с типом дна "${point.bottomType}"';
  }

  static String _getBestTime(DepthPoint point, AnalysisSettings settings) {
    // Логика времени для карповых
    if (point.depth > 8) {
      return 'Рассвет, вечер, ночь'; // Глубокие места
    } else if (point.depth < 3) {
      return 'Утро, день, вечер'; // Мелкие места
    } else if (point.bottomType == 'точка_кормления') {
      return 'Любое время'; // Проверенные места
    }
    return 'Рассвет, утро, вечер'; // Стандартное время для карпа
  }

  static RecommendationType _getRecommendationType(double rating) {
    if (rating >= 8.5) return RecommendationType.excellent;
    if (rating >= 7.0) return RecommendationType.good;
    if (rating >= 5.0) return RecommendationType.average;
    return RecommendationType.avoid;
  }
}