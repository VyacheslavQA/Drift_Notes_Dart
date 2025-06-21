// Путь: lib/services/depth_analysis_service.dart

import 'dart:math' as math;
import 'dart:ui';
import '../models/depth_analysis_model.dart';

/// Сезоны года для анализа карпфишинга
enum CarpSeason { spring, summer, autumn, winter }

/// Время суток для карпфишинга
enum CarpTimeOfDay { dawn, morning, day, evening, night }

/// Предпочтения карповых рыб с учетом сезонности
class CarpFishPreferences {
  final Map<CarpSeason, SeasonalCarpData> seasonalData;
  final double baseActivity;
  final double optimalTempMin;
  final double optimalTempMax;
  final List<String> preferredBottomTypes;

  const CarpFishPreferences({
    required this.seasonalData,
    required this.baseActivity,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.preferredBottomTypes,
  });
}

/// Сезонные данные карпа
class SeasonalCarpData {
  final List<double> preferredDepths; // [min, max]
  final List<String> primaryZones; // Приоритетные зоны
  final Map<CarpTimeOfDay, double> timeMultipliers; // Активность по времени
  final double seasonalBonus; // Сезонный бонус
  final String behavior; // Описание поведения

  const SeasonalCarpData({
    required this.preferredDepths,
    required this.primaryZones,
    required this.timeMultipliers,
    required this.seasonalBonus,
    required this.behavior,
  });
}

/// Улучшенный сервис анализа с автоматическим определением условий
class DepthAnalysisService {

  /// Карповая база знаний (ТОЛЬКО природные типы дна)
  static const Map<String, CarpFishPreferences> _carpKnowledge = {
    'карп': CarpFishPreferences(
      baseActivity: 1.2,
      optimalTempMin: 23.0,
      optimalTempMax: 30.0,
      preferredBottomTypes: [
        // ТОЛЬКО природные типы (без пользовательских меток!)
        'ил', 'глубокий_ил', 'трава_водоросли', 'ракушка',
        'ровно_твердо', 'заросли', 'бровка', 'drop_off'
      ],
      seasonalData: {
        CarpSeason.spring: SeasonalCarpData(
          preferredDepths: [0.5, 2.5], // Мелководье для нереста
          primaryZones: ['flat_с_растительностью', 'заросли', 'литораль'],
          seasonalBonus: 1.4, // Высокая активность в нерест
          behavior: 'Нерест в зарослях на мелководье (17-22°C)',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.2,
            CarpTimeOfDay.morning: 1.3,
            CarpTimeOfDay.day: 1.1,
            CarpTimeOfDay.evening: 1.2,
            CarpTimeOfDay.night: 0.9,
          },
        ),
        CarpSeason.summer: SeasonalCarpData(
          preferredDepths: [1.5, 4.0], // Бровки и столы
          primaryZones: ['бровка', 'ровный_стол', 'drop_off'],
          seasonalBonus: 1.3,
          behavior: 'Активная кормежка на бровках, ночью на флэтах',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.4,
            CarpTimeOfDay.morning: 1.1,
            CarpTimeOfDay.day: 0.8, // Днем в укрытиях
            CarpTimeOfDay.evening: 1.3,
            CarpTimeOfDay.night: 1.5, // Пик активности ночью
          },
        ),
        CarpSeason.autumn: SeasonalCarpData(
          preferredDepths: [2.0, 5.0], // Переход на глубину
          primaryZones: ['бровка', 'яма_неглубокая', 'ровный_стол'],
          seasonalBonus: 1.1,
          behavior: 'Запасы перед зимовкой, переход на глубину',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.2,
            CarpTimeOfDay.morning: 1.2,
            CarpTimeOfDay.day: 1.0,
            CarpTimeOfDay.evening: 1.1,
            CarpTimeOfDay.night: 1.0,
          },
        ),
        CarpSeason.winter: SeasonalCarpData(
          preferredDepths: [4.0, 8.0], // Глубокие ямы
          primaryZones: ['яма_глубокая', 'ровное_дно_глубина'],
          seasonalBonus: 0.6, // Низкая активность
          behavior: 'Зимовка в глубоких ямах с ровным дном',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 0.8,
            CarpTimeOfDay.morning: 0.9,
            CarpTimeOfDay.day: 1.0, // Относительно стабильная активность
            CarpTimeOfDay.evening: 0.9,
            CarpTimeOfDay.night: 0.8,
          },
        ),
      },
    ),

    'амур': CarpFishPreferences(
      baseActivity: 1.1,
      optimalTempMin: 20.0,
      optimalTempMax: 28.0,
      preferredBottomTypes: ['трава_водоросли', 'ил', 'ровно_твердо'],
      seasonalData: {
        CarpSeason.spring: SeasonalCarpData(
          preferredDepths: [0.5, 2.0],
          primaryZones: ['flat_с_растительностью', 'заросли'],
          seasonalBonus: 1.2,
          behavior: 'Активен в зарослях, питается растительностью',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.1,
            CarpTimeOfDay.morning: 1.3,
            CarpTimeOfDay.day: 1.2,
            CarpTimeOfDay.evening: 1.1,
            CarpTimeOfDay.night: 0.8,
          },
        ),
        CarpSeason.summer: SeasonalCarpData(
          preferredDepths: [1.0, 3.5],
          primaryZones: ['заросли', 'flat_с_растительностью'],
          seasonalBonus: 1.4, // Пик активности летом
          behavior: 'Максимальная активность в растительности',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.2,
            CarpTimeOfDay.morning: 1.4,
            CarpTimeOfDay.day: 1.3,
            CarpTimeOfDay.evening: 1.2,
            CarpTimeOfDay.night: 0.9,
          },
        ),
        CarpSeason.autumn: SeasonalCarpData(
          preferredDepths: [1.5, 4.0],
          primaryZones: ['заросли', 'бровка'],
          seasonalBonus: 1.0,
          behavior: 'Продолжает питаться растительностью',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.0,
            CarpTimeOfDay.morning: 1.2,
            CarpTimeOfDay.day: 1.1,
            CarpTimeOfDay.evening: 1.0,
            CarpTimeOfDay.night: 0.9,
          },
        ),
        CarpSeason.winter: SeasonalCarpData(
          preferredDepths: [3.0, 6.0],
          primaryZones: ['яма_неглубокая', 'ровное_дно_глубина'],
          seasonalBonus: 0.5,
          behavior: 'Малоактивен зимой, редко питается',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 0.7,
            CarpTimeOfDay.morning: 0.8,
            CarpTimeOfDay.day: 0.9,
            CarpTimeOfDay.evening: 0.8,
            CarpTimeOfDay.night: 0.6,
          },
        ),
      },
    ),

    'сазан': CarpFishPreferences(
      baseActivity: 1.3,
      optimalTempMin: 20.0,
      optimalTempMax: 28.0,
      preferredBottomTypes: ['ил', 'глубокий_ил', 'ракушка', 'точка_кормления'],
      seasonalData: {
        CarpSeason.spring: SeasonalCarpData(
          preferredDepths: [1.0, 3.0],
          primaryZones: ['flat_с_растительностью', 'бровка'],
          seasonalBonus: 1.3,
          behavior: 'Активный нерест, агрессивная кормежка',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.3,
            CarpTimeOfDay.morning: 1.2,
            CarpTimeOfDay.day: 1.0,
            CarpTimeOfDay.evening: 1.3,
            CarpTimeOfDay.night: 1.1,
          },
        ),
        CarpSeason.summer: SeasonalCarpData(
          preferredDepths: [2.0, 5.0],
          primaryZones: ['бровка', 'drop_off', 'яма_неглубокая'],
          seasonalBonus: 1.4,
          behavior: 'Пик активности, предпочитает бровки',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.5,
            CarpTimeOfDay.morning: 1.2,
            CarpTimeOfDay.day: 0.9,
            CarpTimeOfDay.evening: 1.4,
            CarpTimeOfDay.night: 1.6, // Максимальная активность ночью
          },
        ),
        CarpSeason.autumn: SeasonalCarpData(
          preferredDepths: [2.5, 6.0],
          primaryZones: ['бровка', 'яма_неглубокая', 'drop_off'],
          seasonalBonus: 1.2,
          behavior: 'Интенсивная кормежка перед зимой',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 1.3,
            CarpTimeOfDay.morning: 1.1,
            CarpTimeOfDay.day: 1.0,
            CarpTimeOfDay.evening: 1.2,
            CarpTimeOfDay.night: 1.3,
          },
        ),
        CarpSeason.winter: SeasonalCarpData(
          preferredDepths: [4.0, 10.0],
          primaryZones: ['яма_глубокая', 'ровное_дно_глубина'],
          seasonalBonus: 0.7,
          behavior: 'Зимовка в самых глубоких местах',
          timeMultipliers: {
            CarpTimeOfDay.dawn: 0.8,
            CarpTimeOfDay.morning: 0.9,
            CarpTimeOfDay.day: 1.0,
            CarpTimeOfDay.evening: 0.9,
            CarpTimeOfDay.night: 0.8,
          },
        ),
      },
    ),
  };

  /// Мультипликаторы типов дна для карпфишинга (РЕАЛИСТИЧНЫЕ)
  static const Map<String, double> _bottomMultipliers = {
    // Действительно ТОП локации (очень редкие!)
    'точка_кормления': 1.6,        // Проверенные места
    'заросли': 1.4,                // Site fidelity места
    'flat_с_растительностью': 1.3, // Нерестовые зоны

    // Хорошие структурные элементы
    'бровка': 1.2,                 // Drop-off зоны
    'drop_off': 1.2,               // Границы глубин
    'зацеп': 1.1,                  // Коряги
    'яма_неглубокая': 1.1,         // Летние стоянки
    'яма_глубокая': 1.0,           // Зимовальные ямы

    // Обычные типы дна (нейтральные)
    'трава_водоросли': 1.1,        // Кислород + укрытие + корм
    'ракушка': 1.0,                // Кормовая база
    'ровный_стол': 0.9,            // Летние столы
    'камни': 0.9,                  // Твердое дно
    'ровно_твердо': 0.8,           // Стабильное дно
    'ровное_дно_глубина': 0.8,     // Зимовальные зоны

    // Менее привлекательные (штрафы)
    'ил': 0.7,                     // Стандартное дно
    'глубокий_ил': 0.6,            // Может быть бедным
    'литораль': 0.7,               // Нейтральная зона
    'default': 0.5,                // Неопределенные места
  };

  /// Автоматическое определение сезона
  static CarpSeason _getCurrentSeason() {
    final now = DateTime.now();
    switch (now.month) {
      case 3:
      case 4:
      case 5:
        return CarpSeason.spring;
      case 6:
      case 7:
      case 8:
        return CarpSeason.summer;
      case 9:
      case 10:
      case 11:
        return CarpSeason.autumn;
      case 12:
      case 1:
      case 2:
        return CarpSeason.winter;
      default:
        return CarpSeason.summer;
    }
  }

  /// Автоматическое определение времени суток
  static CarpTimeOfDay _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 7) {
      return CarpTimeOfDay.dawn;
    } else if (hour >= 7 && hour < 12) {
      return CarpTimeOfDay.morning;
    } else if (hour >= 12 && hour < 17) {
      return CarpTimeOfDay.day;
    } else if (hour >= 17 && hour < 21) {
      return CarpTimeOfDay.evening;
    } else {
      return CarpTimeOfDay.night;
    }
  }

  /// Автоматическое определение температуры по сезону
  static double _getSeasonalTemperature(CarpSeason season) {
    switch (season) {
      case CarpSeason.spring:
        return 12.0;
      case CarpSeason.summer:
        return 24.0; // Оптимальная для карпа
      case CarpSeason.autumn:
        return 15.0;
      case CarpSeason.winter:
        return 4.0;
    }
  }

  /// Температурный мультипликатор
  static double _getTemperatureMultiplier(double temperature) {
    if (temperature >= 23 && temperature <= 30) {
      return 1.3; // Пик активности
    } else if (temperature >= 17 && temperature <= 35) {
      return 1.0; // Нормальная активность
    } else if (temperature >= 10 && temperature <= 17) {
      return 0.7; // Сниженная активность
    } else if (temperature >= 3 && temperature <= 10) {
      return 0.4; // Зимняя пассивность
    } else {
      return 0.1; // Экстремальные условия
    }
  }

  /// Основной метод анализа всех лучей (АВТОМАТИЧЕСКИЙ)
  static MultiRayAnalysis analyzeAllRays(
      List<Map<String, dynamic>> allMarkers,
      AnalysisSettings settings,
      ) {
    // Автоматически определяем текущие условия
    final currentSeason = _getCurrentSeason();
    final currentTime = _getCurrentTimeOfDay();
    final waterTemperature = _getSeasonalTemperature(currentSeason);

    final rayAnalyses = <DepthProfileAnalysis>[];

    // Анализируем каждый луч (0-4)
    for (int i = 0; i < 5; i++) {
      final analysis = _analyzeRayProfile(
        i,
        allMarkers,
        settings,
        currentSeason,
        currentTime,
        waterTemperature,
      );
      rayAnalyses.add(analysis);
    }

    final topRecommendations = _findTopRecommendations(
        rayAnalyses,
        settings,
        currentSeason,
        currentTime
    );

    final overallAssessment = _generateScientificAssessment(
        rayAnalyses,
        settings,
        currentSeason,
        waterTemperature
    );

    final generalTips = _generateAdvancedTips(
        rayAnalyses,
        settings,
        currentSeason,
        currentTime,
        waterTemperature
    );

    return MultiRayAnalysis(
      rayAnalyses: rayAnalyses,
      topRecommendations: topRecommendations,
      overallAssessment: overallAssessment,
      generalTips: generalTips,
    );
  }

  /// Анализ профиля одного луча
  static DepthProfileAnalysis _analyzeRayProfile(
      int rayIndex,
      List<Map<String, dynamic>> markers,
      AnalysisSettings settings,
      CarpSeason currentSeason,
      CarpTimeOfDay currentTime,
      double waterTemperature,
      ) {
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

    rayMarkers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Создаем точки с научным анализом
    final points = rayMarkers.map((marker) {
      final bottomType = _getBottomType(marker);
      final color = _getBottomTypeColor(bottomType);
      final fishingScore = _calculateAdvancedFishingScore(
          marker,
          settings,
          currentSeason,
          currentTime,
          waterTemperature
      );

      return DepthPoint(
        distance: marker['distance'] as double,
        depth: marker['depth'] as double,
        bottomType: bottomType,
        color: color,
        notes: marker['notes'] as String?,
        fishingScore: fishingScore,
      );
    }).toList();

    // Анализ структур
    final structures = _analyzeBottomStructures(points, settings, currentSeason);

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

  /// ПРАВИЛЬНЫЙ расчет рейтинга (только природные данные!)
  static double _calculateAdvancedFishingScore(
      Map<String, dynamic> marker,
      AnalysisSettings settings,
      CarpSeason currentSeason,
      CarpTimeOfDay currentTime,
      double waterTemperature,
      ) {
    double maxScore = 0.0;

    final depth = marker['depth'] as double;
    final bottomType = _getBottomType(marker);

    // ИГНОРИРУЕМ пользовательские метки (точка_кормления)
    final naturalBottomType = _getNaturalBottomType(bottomType);

    // Анализируем каждый вид карповых
    for (final entry in _carpKnowledge.entries) {
      final fishName = entry.key;
      final preferences = entry.value;
      final seasonalData = preferences.seasonalData[currentSeason]!;

      // Строгий базовый рейтинг
      double fishScore = 2.0;

      // 1. Сезонная глубина (главный фактор!)
      final depthMin = seasonalData.preferredDepths[0];
      final depthMax = seasonalData.preferredDepths[1];

      if (depth >= depthMin && depth <= depthMax) {
        fishScore += 3.0; // Идеальная глубина для сезона
      } else {
        final deviation = math.min(
            (depth - depthMin).abs(),
            (depth - depthMax).abs()
        );
        // Штраф за неподходящую глубину
        fishScore += math.max(0, 3.0 - deviation * 1.0);
      }

      // 2. ТОЛЬКО природный тип дна
      final bottomBonus = _getNaturalBottomBonus(naturalBottomType, currentSeason);
      fishScore += bottomBonus;

      // 3. Сезонный фактор
      fishScore *= seasonalData.seasonalBonus;

      // 4. Время суток
      final timeMultiplier = seasonalData.timeMultipliers[currentTime] ?? 1.0;
      fishScore *= timeMultiplier;

      // 5. Температурный фактор
      final tempMultiplier = _getTemperatureMultiplier(waterTemperature);
      fishScore *= tempMultiplier;

      // 6. Природный мультипликатор дна
      final bottomMultiplier = _getNaturalBottomMultiplier(naturalBottomType);
      fishScore *= bottomMultiplier;

      // 7. Базовая активность вида
      fishScore *= preferences.baseActivity;

      maxScore = math.max(maxScore, fishScore);
    }

    return math.min(10.0, maxScore);
  }

  /// Получение ТОЛЬКО природного типа дна (без пользовательских меток)
  static String _getNaturalBottomType(String bottomType) {
    // Исключаем пользовательские метки
    if (bottomType == 'точка_кормления') {
      return 'ил'; // По умолчанию считаем илом
    }
    return bottomType;
  }

  /// Бонус за природный тип дна в зависимости от сезона
  static double _getNaturalBottomBonus(String naturalBottomType, CarpSeason season) {
    switch (naturalBottomType) {
    // Растительность - отлично весной для нереста
      case 'трава_водоросли':
      case 'заросли':
      case 'flat_с_растительностью':
        return season == CarpSeason.spring ? 2.5 : 1.5;

    // Ракушка - хорошая кормовая база
      case 'ракушка':
        return 2.0;

    // Структуры - хороши летом
      case 'бровка':
      case 'drop_off':
        return season == CarpSeason.summer ? 2.0 : 1.5;

    // Зацепы - укрытие
      case 'зацеп':
        return 1.5;

    // Твердое дно - средне
      case 'ровно_твердо':
      case 'камни':
        return 1.0;

    // Ил - зависит от глубины и сезона
      case 'ил':
        return season == CarpSeason.winter ? 1.2 : 0.8;

      case 'глубокий_ил':
        return season == CarpSeason.winter ? 1.0 : 0.5;

      default:
        return 0.8;
    }
  }

  /// Природные мультипликаторы дна (без учета пользовательских меток)
  static double _getNaturalBottomMultiplier(String naturalBottomType) {
    const naturalMultipliers = {
      // Растительность - отлично для карпа
      'трава_водоросли': 1.3,
      'заросли': 1.3,
      'flat_с_растительностью': 1.2,

      // Кормовая база
      'ракушка': 1.2,

      // Структуры
      'бровка': 1.2,
      'drop_off': 1.2,
      'зацеп': 1.1,

      // Ямы
      'яма_неглубокая': 1.0,
      'яма_глубокая': 1.0,

      // Обычное дно
      'ровно_твердо': 0.9,
      'камни': 0.9,
      'ровный_стол': 0.9,

      // Ил
      'ил': 0.8,
      'глубокий_ил': 0.7,

      // Прочее
      'литораль': 0.8,
      'default': 0.7,
    };
    return naturalMultipliers[naturalBottomType] ?? 0.7;
  }

  /// Анализ структур дна с учетом сезона
  static List<BottomStructure> _analyzeBottomStructures(
      List<DepthPoint> points,
      AnalysisSettings settings,
      CarpSeason currentSeason,
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

      // Анализ структур для карповых
      if (slope.abs() > 30) {
        structureType = StructureType.dropoff;
        fishingRating = currentSeason == CarpSeason.summer ? 9.0 : 7.5;
        description = slope > 0
            ? 'Drop-off: граница мелководья и глубины (TOP для карпа!)'
            : 'Подъем к мелководью';
      } else if (slope.abs() > 15) {
        structureType = StructureType.slope;
        fishingRating = 7.0;
        description = slope > 0 ? 'Склон к глубине' : 'Склон к мелководью';
      } else if (slope.abs() < 3) {
        structureType = StructureType.shelf;
        if (currentSeason == CarpSeason.spring && current.depth < 2.5) {
          fishingRating = 8.5; // Нерестовые флэты
          description = 'Flat: нерестовая зона (весенний приоритет)';
        } else if (currentSeason == CarpSeason.summer && current.depth > 1.5 && current.depth < 4.0) {
          fishingRating = 8.0; // Летние столы
          description = 'Стол: кормовая зона (летняя активность)';
        } else if (currentSeason == CarpSeason.winter && current.depth > 4.0) {
          fishingRating = 7.5; // Зимовальные ямы
          description = 'Глубокий стол: зимовальная зона';
        } else {
          fishingRating = 6.0;
          description = 'Ровная полка';
        }
      }

      if (structureType != null) {
        final bottomBonus = _bottomMultipliers[current.bottomType] ?? 1.0;
        fishingRating *= bottomBonus;

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

  /// Поиск топ рекомендаций (ОЧЕНЬ строгий отбор)
  static List<FishingRecommendation> _findTopRecommendations(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      CarpSeason currentSeason,
      CarpTimeOfDay currentTime,
      ) {
    final recommendations = <FishingRecommendation>[];

    for (final analysis in analyses) {
      for (final point in analysis.points) {
        // ОЧЕНЬ СТРОГИЙ фильтр: только места с рейтингом 7.0+ (было 6.5+)
        if (point.fishingScore != null && point.fishingScore! >= 7.0) {
          final recommendation = FishingRecommendation(
            distance: point.distance,
            depth: point.depth,
            rating: point.fishingScore!,
            reason: _generateScientificReason(point, analysis.structures, currentSeason),
            bestTime: _getOptimalTime(point, currentSeason, currentTime),
            type: _getRecommendationType(point.fishingScore!),
          );
          recommendations.add(recommendation);
        }
      }
    }

    recommendations.sort((a, b) => b.rating.compareTo(a.rating));
    return recommendations.take(5).toList(); // Еще меньше рекомендаций - максимум 5!
  }

  /// ОЧЕНЬ строгие типы рекомендаций
  static RecommendationType _getRecommendationType(double rating) {
    if (rating >= 8.0) return RecommendationType.excellent;  // Повышен с 8.5
    if (rating >= 7.0) return RecommendationType.good;       // Понижен с 7.5
    if (rating >= 6.0) return RecommendationType.average;    // Понижен с 6.5
    return RecommendationType.avoid;
  }

  /// Научно обоснованная общая оценка
  static String _generateScientificAssessment(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      CarpSeason currentSeason,
      double waterTemperature,
      ) {
    final totalPoints = analyses.fold<int>(0, (sum, analysis) => sum + analysis.points.length);
    if (totalPoints == 0) return 'Недостаточно данных для научного анализа';

    final allPoints = analyses.expand((a) => a.points).toList();
    final avgRating = allPoints
        .where((p) => p.fishingScore != null)
        .map((p) => p.fishingScore!)
        .fold<double>(0.0, (sum, score) => sum + score) / totalPoints;

    String seasonText = _getSeasonText(currentSeason);
    String assessment = '$seasonText: ';

    if (avgRating >= 8.5) {
      assessment += 'ОТЛИЧНЫЙ водоем! Высокий потенциал для карпфишинга. ';
    } else if (avgRating >= 7.0) {
      assessment += 'ХОРОШИЙ водоем с перспективными зонами. ';
    } else if (avgRating >= 5.5) {
      assessment += 'СРЕДНИЙ водоем, требует поиска активных точек. ';
    } else {
      assessment += 'СЛОЖНЫЙ водоем, нужна детальная разведка. ';
    }

    // Температурный анализ
    if (waterTemperature >= 23 && waterTemperature <= 30) {
      assessment += 'Температура воды ОПТИМАЛЬНАЯ ($waterTemperature°C) для карпа!';
    } else if (waterTemperature >= 17 && waterTemperature <= 35) {
      assessment += 'Температура воды ПРИЕМЛЕМАЯ ($waterTemperature°C).';
    } else {
      assessment += 'Температура воды НЕ ОПТИМАЛЬНАЯ ($waterTemperature°C) - снижена активность.';
    }

    return assessment;
  }

  /// Расширенные научные советы
  static List<String> _generateAdvancedTips(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      CarpSeason currentSeason,
      CarpTimeOfDay currentTime,
      double waterTemperature,
      ) {
    final tips = <String>[];

    // Сезонные рекомендации
    switch (currentSeason) {
      case CarpSeason.spring:
        tips.add('🌱 ВЕСНА: Ищите заросшие флэты 0.5-2.5м для нереста карпа');
        tips.add('🎯 Site fidelity: Карп возвращается на одни места нереста годами');
        tips.add('🌡️ Оптимум нереста: 17-22°C в зарослях мелководья');
        break;
      case CarpSeason.summer:
        tips.add('☀️ ЛЕТО: Приоритет - бровки (drop-off) 2-4м глубиной');
        tips.add('🌙 Ночью карп выходит кормиться на флэты, днем в укрытиях');
        tips.add('🎣 Пик активности: рассвет и ночь на границах глубин');
        break;
      case CarpSeason.autumn:
        tips.add('🍂 ОСЕНЬ: Карп запасается перед зимой, переходит на глубину');
        tips.add('📍 Ищите переходные зоны 2-5м между летними и зимними стоянками');
        break;
      case CarpSeason.winter:
        tips.add('❄️ ЗИМА: Карп концентрируется в глубоких ямах 4-8м');
        tips.add('🐌 Минимальная активность, пассивные методы ловли');
        tips.add('🎯 Ровное дно глубоких зон - основные зимовальные места');
        break;
    }

    // Анализ структур
    final allStructures = analyses.expand((a) => a.structures).toList();
    final dropoffs = allStructures.where((s) => s.type == StructureType.dropoff).length;
    final shelves = allStructures.where((s) => s.type == StructureType.shelf).length;

    if (dropoffs > 0) {
      tips.add('📊 Найдено $dropoffs drop-off зон - ТОП места для карпа! (концентрация корма)');
    }
    if (shelves > 0) {
      tips.add('📏 Найдено $shelves столов/полок - отличные кормовые зоны');
    }

    // Анализ типов дна
    final allPoints = analyses.expand((a) => a.points).toList();
    final bottomTypes = allPoints.map((p) => p.bottomType).toSet();

    if (bottomTypes.contains('точка_кормления')) {
      tips.add('🎯 ПРОВЕРЕННЫЕ точки кормления - максимальный приоритет!');
    }
    if (bottomTypes.contains('заросли') || bottomTypes.contains('flat_с_растительностью')) {
      tips.add('🌿 Растительные зоны найдены - отлично для амура и нерестового карпа');
    }
    if (bottomTypes.contains('бровка') || bottomTypes.contains('drop_off')) {
      tips.add('📈 Drop-off зоны - научно доказанные концентраторы карпа');
    }
    if (bottomTypes.contains('ракушка')) {
      tips.add('🐚 Ракушечник - естественная кормовая база карпа');
    }

    // Температурные советы
    if (waterTemperature < 10) {
      tips.add('🧊 Низкая температура - карп малоактивен, используйте минимум прикорма');
    } else if (waterTemperature >= 23 && waterTemperature <= 30) {
      tips.add('🔥 ОПТИМАЛЬНАЯ температура для карпа - максимальная активность!');
    }

    // Временные рекомендации
    switch (currentTime) {
      case CarpTimeOfDay.night:
        if (currentSeason == CarpSeason.summer) {
          tips.add('🌙 НОЧЬ летом - пик активности карпа на флэтах и в зарослях');
        }
        break;
      case CarpTimeOfDay.dawn:
        tips.add('🌅 РАССВЕТ - одно из лучших времен для карпфишинга');
        break;
      case CarpTimeOfDay.day:
        if (currentSeason == CarpSeason.summer) {
          tips.add('☀️ ДЕНЬ летом - карп в укрытиях, ищите тенистые глубокие места');
        }
        break;
      default:
        break;
    }

    return tips;
  }

  // Вспомогательные методы
  static String _getBottomType(Map<String, dynamic> marker) {
    return marker['bottomType'] as String? ??
        _convertLegacyType(marker['type'] as String?) ??
        'ил';
  }

  static String? _convertLegacyType(String? type) {
    if (type == null) return null;
    const conversionMap = {
      'dropoff': 'drop_off',
      'weed': 'трава_водоросли',
      'sandbar': 'ровно_твердо',
      'structure': 'зацеп',
      'flat': 'ровный_стол',
      'default': 'ил',
    };
    return conversionMap[type] ?? type;
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
      'заросли': Color(0xFF32CD32),
      'flat_с_растительностью': Color(0xFF98FB98),
      'бровка': Color(0xFF4169E1),
      'drop_off': Color(0xFF1E90FF),
      'яма_неглубокая': Color(0xFF6495ED),
      'яма_глубокая': Color(0xFF191970),
      'ровный_стол': Color(0xFFDDD8C7),
      'ровное_дно_глубина': Color(0xFF696969),
      'литораль': Color(0xFFF0E68C),
    };
    return colors[bottomType] ?? const Color(0xFF0000FF);
  }

  static double _calculateVariation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  static String _getSeasonText(CarpSeason season) {
    switch (season) {
      case CarpSeason.spring:
        return 'Весенний период (нерест 17-22°C)';
      case CarpSeason.summer:
        return 'Летний период (активная кормежка)';
      case CarpSeason.autumn:
        return 'Осенний период (подготовка к зиме)';
      case CarpSeason.winter:
        return 'Зимний период (пассивная зимовка)';
    }
  }

  static String _generateScientificReason(
      DepthPoint point,
      List<BottomStructure> structures,
      CarpSeason currentSeason
      ) {
    final nearbyStructure = structures.firstWhere(
          (s) => point.distance >= s.startDistance && point.distance <= s.endDistance,
      orElse: () => BottomStructure(
        type: StructureType.shelf,
        startDistance: 0, endDistance: 0, startDepth: 0, endDepth: 0,
        slope: 0, fishingRating: 0, description: 'Стандартная зона',
      ),
    );

    String seasonalContext = '';
    switch (currentSeason) {
      case CarpSeason.spring:
        seasonalContext = 'весенняя активность в нерестовых зонах';
        break;
      case CarpSeason.summer:
        seasonalContext = 'летняя кормежка на бровках и столах';
        break;
      case CarpSeason.autumn:
        seasonalContext = 'осенний жор перед зимовкой';
        break;
      case CarpSeason.winter:
        seasonalContext = 'зимовальная концентрация в глубинах';
        break;
    }

    return '${nearbyStructure.description} (${point.bottomType}) - $seasonalContext';
  }

  static String _getOptimalTime(DepthPoint point, CarpSeason currentSeason, CarpTimeOfDay currentTime) {
    final naturalBottomType = _getNaturalBottomType(point.bottomType);

    // Особые случаи для природных типов
    if (['заросли', 'трава_водоросли', 'flat_с_растительностью'].contains(naturalBottomType)) {
      return currentSeason == CarpSeason.spring ?
      'Утро, день (нерестовая активность в растительности)' :
      'Рассвет, вечер (кормежка в зарослях)';
    }

    switch (currentSeason) {
      case CarpSeason.spring:
        return 'Утро, день (нерестовая активность)';
      case CarpSeason.summer:
        if (point.depth < 2.0) {
          return 'Ночь, рассвет (выход на мелководье)';
        } else {
          return 'Рассвет, вечер, ночь (бровки и глубины)';
        }
      case CarpSeason.autumn:
        return 'Рассвет, утро, вечер (осенний жор)';
      case CarpSeason.winter:
        return 'День (минимальная активность)';
    }
  }
}