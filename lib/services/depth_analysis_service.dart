// Путь: lib/services/depth_analysis_service.dart

import 'dart:math' as math;
import 'dart:ui';
import '../models/depth_analysis_model.dart';

/// Универсальный сервис анализа рельефа для карпфишинга
/// БЕЗ привязки к сезонам, погоде, времени - только физика водоема
class DepthAnalysisService {

  /// Профессиональные мультипликаторы типов дна (опыт 20 лет)
  /// ТОЛЬКО реальные типы из приложения!
  static const Map<String, double> _bottomQualityScores = {
    // ТОП локации (профессиональные точки)
    'точка_кормления': 9.5,        // Проверенные годами места 🔵

    // Отличные природные структуры
    'ракушка': 8.5,                // Естественная кормовая база ⚪
    'бугор': 6.0,                  // Структура, но карп больше у подножия 🟠

    // Хорошие типы дна
    'ровно_твердо': 7.0,           // Стабильное твердое дно, отличное ложе 🟡
    'трава_водоросли': 6.5,        // Растительность = укрытие + кислород + корм 🟢
    'зацеп': 5.5,                  // Коряги - риск, но перспективно для крупного карпа 🔴
    'камни': 6.0,                  // Твердое дно, ракообразные 🔘

    // Стандартные типы
    'ил': 4.5,                     // Стандартное карповое дно 🟤
    'глубокий_ил': 3.5,            // Может быть бедным на корм, мягко 🟫

    // Неопределенные
    'default': 3.0,                // Неопределенные места
  };

  /// Анализ рельефа - ключевые структуры для карпа
  /// УБРАЛИ неиспользуемые константы
  static const Map<String, double> _reliefStructureScores = {
    // Эти константы НЕ ИСПОЛЬЗУЮТСЯ в новом алгоритме
    // Оставляем для совместимости, если понадобятся
    'переход_глубин_резкий': 9.0,
    'подножие_свала': 8.5,
    'ровное_дно': 4.0,
  };

  /// Комбинированные бонусы - УБРАЛИ неиспользуемые
  /// УБРАЛИ неиспользуемые константы
  static const Map<String, double> _combinationBonuses = {
    // Эти константы НЕ ИСПОЛЬЗУЮТСЯ в новом алгоритме
    // Оставляем для совместимости
    'стандартная_комбинация': 0.0,
  };

  /// Основной метод анализа всех лучей (УНИВЕРСАЛЬНЫЙ)
  static MultiRayAnalysis analyzeAllRays(
      List<Map<String, dynamic>> allMarkers,
      AnalysisSettings settings,
      ) {
    final rayAnalyses = <DepthProfileAnalysis>[];

    // Анализируем каждый луч (0-4)
    for (int i = 0; i < 5; i++) {
      final analysis = _analyzeRayProfile(i, allMarkers, settings);
      rayAnalyses.add(analysis);
    }

    final topRecommendations = _findTopSpots(rayAnalyses, settings);
    final overallAssessment = _generateWaterBodyAssessment(rayAnalyses);
    final professionalTips = _generateProfessionalTips(rayAnalyses);

    return MultiRayAnalysis(
      rayAnalyses: rayAnalyses,
      topRecommendations: topRecommendations,
      overallAssessment: overallAssessment,
      generalTips: professionalTips,
    );
  }

  /// Анализ профиля одного луча (ТОЛЬКО рельеф + дно)
  static DepthProfileAnalysis _analyzeRayProfile(
      int rayIndex,
      List<Map<String, dynamic>> markers,
      AnalysisSettings settings,
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

    // Создаем точки с профессиональным анализом
    final points = rayMarkers.map((marker) {
      final bottomType = _getBottomType(marker);
      final color = _getBottomTypeColor(bottomType);
      final fishingScore = _calculateUniversalCarpScore(marker, rayMarkers);

      return DepthPoint(
        distance: marker['distance'] as double,
        depth: marker['depth'] as double,
        bottomType: bottomType,
        color: color,
        notes: marker['notes'] as String?,
        fishingScore: fishingScore,
      );
    }).toList();

    // Анализ структур рельефа
    final structures = _analyzeReliefStructures(points);

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

  /// ПРОФЕССИОНАЛЬНЫЙ расчет рейтинга (опыт карпятника 20 лет)
  static double _calculateUniversalCarpScore(
      Map<String, dynamic> marker,
      List<Map<String, dynamic>> allRayMarkers,
      ) {
    final depth = marker['depth'] as double;
    final bottomType = _getBottomType(marker); // ТОЛЬКО реальный тип из маркера!
    final distance = marker['distance'] as double;

    // 🐛 ДЕБАГ: выводим что получили из маркера
    print('🔍 ДЕБАГ МАРКЕРА:');
    print('  distance: $distance');
    print('  depth: $depth');
    print('  marker[bottomType]: ${marker['bottomType']}');
    print('  marker[type]: ${marker['type']}');
    print('  итоговый bottomType: $bottomType');
    print('  все поля маркера: ${marker.keys.toList()}');

    // 1. Базовый рейтинг по РЕАЛЬНОМУ типу дна из маркера
    double score = _bottomQualityScores[bottomType] ?? 3.0;
    print('  базовый рейтинг для $bottomType: $score');

    // 2. Анализ рельефа в точке (отдельно от типа дна)
    final reliefBonus = _analyzeLocalReliefBonus(marker, allRayMarkers);
    print('  reliefBonus: $reliefBonus');

    // 3. Анализ переходов типов дна (КЛЮЧЕВОЙ фактор!)
    final transitionBonus = _analyzeBottomTransitions(marker, allRayMarkers);
    print('  transitionBonus: $transitionBonus');

    // 4. Глубинные предпочтения (универсальные для карпа)
    final depthScore = _getDepthScore(depth);
    print('  depthScore: $depthScore');

    // 5. Анализ микрорельефа
    final microReliefBonus = _analyzeMicroRelief(marker, allRayMarkers);
    print('  microReliefBonus: $microReliefBonus');

    // Финальный расчет
    double finalScore = score;                    // Базовый рейтинг типа дна
    finalScore += reliefBonus;                    // Бонус за рельеф
    finalScore += transitionBonus;                // Переходы - магнит карпа
    finalScore += microReliefBonus;               // Мелкие детали
    finalScore *= depthScore;                     // Глубинный мультипликатор

    final result = math.max(0.0, math.min(10.0, finalScore));
    print('  ИТОГОВЫЙ рейтинг: $result');
    print('');

    return result;
  }

  /// Анализ локального рельефа - только бонус, НЕ замена типа дна!
  static double _analyzeLocalReliefBonus(
      Map<String, dynamic> current,
      List<Map<String, dynamic>> allMarkers,
      ) {
    final currentDepth = current['depth'] as double;
    final currentDistance = current['distance'] as double;

    // Находим соседние точки
    final neighbors = allMarkers.where((m) {
      final dist = m['distance'] as double;
      return (dist - currentDistance).abs() <= 20.0 && m != current;
    }).toList();

    if (neighbors.isEmpty) return 0.0;

    // Анализ перепадов глубин
    final depthChanges = neighbors.map((n) =>
    (n['depth'] as double) - currentDepth).toList();

    final maxIncrease = depthChanges.where((d) => d > 0).isEmpty ?
    0.0 : depthChanges.where((d) => d > 0).reduce(math.max);
    final maxDecrease = depthChanges.where((d) => d < 0).isEmpty ?
    0.0 : depthChanges.where((d) => d < 0).reduce(math.min).abs();

    // Бонусы за рельеф (НЕ замена типа дна!)
    if (maxIncrease > 1.5 || maxDecrease > 1.5) {
      return 2.0; // Drop-off >1.5м - отличный бонус
    } else if (maxIncrease > 0.8 || maxDecrease > 0.8) {
      return 1.0; // Средний перепад - хороший бонус
    } else if (maxIncrease > 0.3 || maxDecrease > 0.3) {
      return 0.5; // Небольшие неровности - малый бонус
    } else {
      return 0.0; // Плоский участок - без бонуса
    }
  }

  /// Поиск переходов типов дна (КРИТИЧЕСКИ важно!)
  static double _analyzeBottomTransitions(
      Map<String, dynamic> current,
      List<Map<String, dynamic>> allMarkers,
      ) {
    final currentType = _getBottomType(current);
    final currentDistance = current['distance'] as double;

    // Ищем изменения типа дна в радиусе 15м
    final nearbyMarkers = allMarkers.where((m) {
      final dist = m['distance'] as double;
      return (dist - currentDistance).abs() <= 15.0 && m != current;
    }).toList();

    double transitionBonus = 0.0;

    for (final marker in nearbyMarkers) {
      final nearbyType = _getBottomType(marker);
      if (nearbyType != currentType) {
        // Найден переход! Оцениваем качество перехода
        transitionBonus += _evaluateTransitionQuality(currentType, nearbyType);
      }
    }

    return math.min(2.5, transitionBonus); // Максимум +2.5 балла за переходы
  }

  /// Оценка качества перехода между типами дна
  static double _evaluateTransitionQuality(String type1, String type2) {
    // ТОП переходы (магнит для карпа) - ТОЛЬКО реальные типы!
    const topTransitions = {
      'ил_ракушка': 2.0,              // Классика карпфишинга 🟤→⚪
      'глубокий_ил_ракушка': 1.8,     // Мягкое → кормовая база 🟫→⚪
      'ровно_твердо_ракушка': 1.7,    // Твердое → кормовая база 🟡→⚪
      'ил_ровно_твердо': 1.5,         // Мягкое → твердое 🟤→🟡
      'трава_водоросли_ил': 1.3,      // Растительность → нейтральное 🟢→🟤
      'трава_водоросли_ровно_твердо': 1.2, // Растительность → твердое 🟢→🟡
      'глубокий_ил_ил': 1.0,          // Переход глубины ила 🟫→🟤
      'ил_камни': 1.1,                // Мягкое → твердое с рачками 🟤→🔘
      'камни_ракушка': 1.4,           // Твердое → кормовая база 🔘→⚪
    };

    // Проверяем оба направления перехода
    final key1 = '${type1}_${type2}';
    final key2 = '${type2}_${type1}';

    return topTransitions[key1] ?? topTransitions[key2] ?? 0.8; // Любой переход = +0.8
  }

  /// Универсальная оценка глубины для карпа
  static double _getDepthScore(double depth) {
    if (depth >= 1.5 && depth <= 4.5) {
      return 1.2; // Оптимальная зона для большинства ситуаций
    } else if (depth >= 0.8 && depth <= 6.0) {
      return 1.0; // Хорошая зона
    } else if (depth >= 0.3 && depth <= 8.0) {
      return 0.8; // Приемлемая зона
    } else {
      return 0.6; // Экстремальные глубины
    }
  }

  /// Анализ микрорельефа (мелкие детали)
  static double _analyzeMicroRelief(
      Map<String, dynamic> current,
      List<Map<String, dynamic>> allMarkers,
      ) {
    final currentDepth = current['depth'] as double;
    final currentDistance = current['distance'] as double;

    // Анализ в радиусе 10м
    final closeMarkers = allMarkers.where((m) {
      final dist = m['distance'] as double;
      return (dist - currentDistance).abs() <= 10.0 && m != current;
    }).toList();

    if (closeMarkers.length < 2) return 0.0;

    final depthVariations = closeMarkers.map((m) =>
        ((m['depth'] as double) - currentDepth).abs()).toList();

    final avgVariation = depthVariations.reduce((a, b) => a + b) / depthVariations.length;

    // Небольшие вариации = интересный микрорельеф
    if (avgVariation > 0.1 && avgVariation < 0.8) {
      return 0.5; // Бонус за интересный микрорельеф
    }
    return 0.0;
  }

  /// УБРАЛИ неиспользуемую функцию
  /// Поиск комбинации - НЕ ИСПОЛЬЗУЕТСЯ в новом алгоритме

  /// Анализ структур рельефа
  static List<BottomStructure> _analyzeReliefStructures(List<DepthPoint> points) {
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

      // Профессиональная классификация структур
      if (slope.abs() > 25) {
        structureType = StructureType.dropoff;
        fishingRating = 8.5; // ТОП структура для карпа
        description = slope > 0
            ? 'Drop-off: резкий свал (ТОП для карпа!) - концентрация корма'
            : 'Резкий подъем: граница мелководья';
      } else if (slope.abs() > 12) {
        structureType = StructureType.slope;
        fishingRating = 7.0;
        description = slope > 0
            ? 'Склон к глубине: путь миграции карпа'
            : 'Склон к мелководью: выход на кормежку';
      } else if (slope.abs() < 4) {
        structureType = StructureType.shelf;
        // Оценка полки зависит от глубины
        if (current.depth >= 1.5 && current.depth <= 4.0) {
          fishingRating = 7.5; // Идеальные кормовые столы
          description = 'Кормовой стол: идеальная глубина для карпа';
        } else if (current.depth < 1.0) {
          fishingRating = 6.0; // Мелководные флэты
          description = 'Мелководный флэт: возможны подходы карпа';
        } else {
          fishingRating = 5.5; // Глубокие полки
          description = 'Глубокая полка: стабильная зона';
        }
      }

      if (structureType != null) {
        // Бонус за качество дна на структуре
        final bottomBonus = _bottomQualityScores[current.bottomType] ?? 4.0;
        fishingRating += (bottomBonus - 5.0) * 0.3; // Влияние дна на структуру

        structures.add(BottomStructure(
          type: structureType,
          startDistance: current.distance,
          endDistance: next.distance,
          startDepth: current.depth,
          endDepth: next.depth,
          slope: slope,
          fishingRating: math.min(10.0, math.max(1.0, fishingRating)),
          description: description,
        ));
      }
    }

    return structures;
  }

  /// Поиск ТОП мест (строгий профессиональный отбор)
  static List<FishingRecommendation> _findTopSpots(
      List<DepthProfileAnalysis> analyses,
      AnalysisSettings settings,
      ) {
    final recommendations = <FishingRecommendation>[];

    for (final analysis in analyses) {
      for (final point in analysis.points) {
        // СТРОГИЙ профессиональный фильтр: только 7.0+
        if (point.fishingScore != null && point.fishingScore! >= 7.0) {
          final recommendation = FishingRecommendation(
            distance: point.distance,
            depth: point.depth,
            rating: point.fishingScore!,
            reason: _generateProfessionalReason(point, analysis.structures),
            bestTime: 'Универсально перспективное место',
            type: _getProfessionalRecommendationType(point.fishingScore!),
          );
          recommendations.add(recommendation);
        }
      }
    }

    recommendations.sort((a, b) => b.rating.compareTo(a.rating));
    return recommendations.take(8).toList(); // Топ-8 мест
  }

  /// Профессиональные типы рекомендаций
  static RecommendationType _getProfessionalRecommendationType(double rating) {
    if (rating >= 8.5) return RecommendationType.excellent;  // Элитные места
    if (rating >= 7.5) return RecommendationType.good;       // Очень хорошие
    if (rating >= 7.0) return RecommendationType.average;    // Хорошие
    return RecommendationType.avoid;
  }

  /// Генерация профессионального обоснования
  static String _generateProfessionalReason(
      DepthPoint point,
      List<BottomStructure> structures,
      ) {
    // 🐛 ДЕБАГ: что попало в генерацию причины
    print('🎯 ГЕНЕРАЦИЯ ПРИЧИНЫ:');
    print('  point.bottomType: ${point.bottomType}');
    print('  point.depth: ${point.depth}');
    print('  point.distance: ${point.distance}');
    print('  point.fishingScore: ${point.fishingScore}');

    // ИСПОЛЬЗУЕМ ТОЛЬКО реальный тип дна из маркера!
    String reason = 'Тип дна: ${point.bottomType}. ';
    reason += 'Глубина: ${point.depth.toStringAsFixed(1)}м. ';

    // Анализ структур рельефа (если есть)
    final nearbyStructure = structures.where((s) =>
    point.distance >= s.startDistance && point.distance <= s.endDistance
    ).isNotEmpty ? structures.firstWhere((s) =>
    point.distance >= s.startDistance && point.distance <= s.endDistance
    ) : null;

    if (nearbyStructure != null) {
      reason += '${nearbyStructure.description}. ';
      print('  найдена структура: ${nearbyStructure.description}');
    } else {
      print('  структур рядом не найдено');
    }

    // Профессиональный анализ РЕАЛЬНОГО типа дна
    switch (point.bottomType) {
      case 'точка_кормления':
        reason += 'Проверенная точка кормления - работает годами, максимальный приоритет!';
        break;
      case 'ракушка':
        reason += 'Естественная кормовая база - карп найдет здесь мидий, личинок и ракообразных.';
        break;
      case 'ровно_твердо':
        reason += 'Твердое дно - отличное ложе для оснастки, карп чувствует себя уверенно.';
        break;
      case 'трава_водоросли':
        reason += 'Растительность - укрытие, кислород и корм, ищите границы зарослей.';
        break;
      case 'зацеп':
        reason += 'Зацеп - риск для снастей, но крупный карп любит укрытия.';
        break;
      case 'бугор':
        reason += 'Бугор - ищите подножие, а не вершину. Там скапливается смытый корм.';
        break;
      case 'камни':
        reason += 'Каменистое дно - твердая основа плюс ракообразные.';
        break;
      case 'ил':
        reason += 'Стандартное карповое дно - нейтральное место.';
        break;
      case 'глубокий_ил':
        reason += 'Глубокий ил - может быть бедным на корм, мягкое ложе.';
        break;
      default:
        reason += 'Анализ рельефа и структуры дна.';
        print('  ⚠️ НЕИЗВЕСТНЫЙ ТИП ДНА: ${point.bottomType}');
    }

    print('  итоговая причина: $reason');
    print('');
    return reason;
  }

  /// Общая оценка водоема
  static String _generateWaterBodyAssessment(List<DepthProfileAnalysis> analyses) {
    final totalPoints = analyses.fold<int>(0, (sum, analysis) => sum + analysis.points.length);
    if (totalPoints == 0) return 'Недостаточно данных для анализа рельефа';

    final allPoints = analyses.expand((a) => a.points).toList();
    final validScores = allPoints
        .where((p) => p.fishingScore != null)
        .map((p) => p.fishingScore!)
        .toList();

    if (validScores.isEmpty) return 'Нет точек для оценки';

    final avgRating = validScores.reduce((a, b) => a + b) / validScores.length;
    final topSpots = validScores.where((score) => score >= 7.0).length;
    final eliteSpots = validScores.where((score) => score >= 8.5).length;

    String assessment = '';

    if (avgRating >= 7.5) {
      assessment = '🔥 ЭЛИТНЫЙ водоем! ';
    } else if (avgRating >= 6.5) {
      assessment = '✅ ОТЛИЧНЫЙ водоем! ';
    } else if (avgRating >= 5.5) {
      assessment = '👍 ХОРОШИЙ водоем. ';
    } else if (avgRating >= 4.5) {
      assessment = '⚠️ СРЕДНИЙ водоем. ';
    } else {
      assessment = '❌ СЛОЖНЫЙ водоем. ';
    }

    assessment += 'Рейтинг рельефа: ${avgRating.toStringAsFixed(1)}/10. ';

    if (eliteSpots > 0) {
      assessment += 'Найдено $eliteSpots элитных мест (8.5+)! ';
    }
    if (topSpots > 0) {
      assessment += 'Перспективных точек: $topSpots. ';
    }

    return assessment;
  }

  /// Профессиональные советы по рельефу
  static List<String> _generateProfessionalTips(List<DepthProfileAnalysis> analyses) {
    final tips = <String>[];
    final allPoints = analyses.expand((a) => a.points).toList();
    final allStructures = analyses.expand((a) => a.structures).toList();

    // Анализ найденных структур
    final dropoffs = allStructures.where((s) => s.type == StructureType.dropoff).length;
    final shelves = allStructures.where((s) => s.type == StructureType.shelf).length;
    final slopes = allStructures.where((s) => s.type == StructureType.slope).length;

    if (dropoffs > 0) {
      tips.add('🎯 Найдено $dropoffs drop-off зон - ТОП места! Карп использует свалы как пути миграции и концентрации корма');
    }
    if (shelves > 0) {
      tips.add('📏 Найдено $shelves кормовых столов - ставьте снасти на глубине 2-4м для максимального эффекта');
    }
    if (slopes > 0) {
      tips.add('⛰️ Найдено $slopes склонов - ищите подножие склонов, там скапливается смытый корм');
    }

    // Анализ типов дна
    final bottomTypes = allPoints.map((p) => p.bottomType).toSet();

    if (bottomTypes.contains('ракушка')) {
      tips.add('🐚 Ракушечник обнаружен - естественная кормовая база! Карп найдет здесь мидий, личинок, ракообразных');
    }
    if (bottomTypes.contains('точка_кормления')) {
      tips.add('🎯 Проверенные точки кормления - МАКСИМАЛЬНЫЙ приоритет! Эти места работают годами');
    }
    if (bottomTypes.contains('заросли') || bottomTypes.contains('трава_водоросли')) {
      tips.add('🌿 Растительные зоны - ищите ГРАНИЦЫ зарослей, а не центр. Карп кормится по краям');
    }
    if (bottomTypes.any((type) => type.contains('бровка') || type.contains('drop_off'))) {
      tips.add('📈 Drop-off структуры - золотая жила карпятника! Концентрация корма + пути миграции');
    }

    // Общие профессиональные советы
    tips.add('💡 ЗОЛОТОЕ ПРАВИЛО: Ищите места где встречаются 2+ фактора: комфорт + безопасность + корм');
    tips.add('🔄 Переходы типов дна (ил→ракушка, глина→песок) = магнит для карпа');
    tips.add('🏔️ Подножие структур > вершина структур (карп редко лежит на буграх)');
    tips.add('📍 Излом бровки > прямая бровка (непрямолинейные структуры интереснее)');

    return tips;
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  static String _getBottomType(Map<String, dynamic> marker) {
    // 🐛 ДЕБАГ: что у нас в маркере
    print('📋 _getBottomType вызван:');
    print('  marker keys: ${marker.keys.toList()}');
    print('  marker[bottomType]: ${marker['bottomType']}');
    print('  marker[type]: ${marker['type']}');

    final bottomType = marker['bottomType'] as String?;
    final legacyType = marker['type'] as String?;

    if (bottomType != null && bottomType.isNotEmpty) {
      print('  ✅ используем bottomType: $bottomType');
      return bottomType;
    }

    if (legacyType != null) {
      final converted = _convertLegacyType(legacyType);
      print('  🔄 конвертируем type $legacyType → $converted');
      return converted ?? 'ил';
    }

    print('  ⚠️ используем дефолт: ил');
    return 'ил';
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
      // ТОЧНЫЕ цвета из приложения
      'ил': Color(0xFFD4A574),              // Светло ярко коричневый 🟤
      'глубокий_ил': Color(0xFF8B4513),     // Темно коричневый 🟫
      'ракушка': Color(0xFFFFFFFF),         // Белый ⚪
      'ровно_твердо': Color(0xFFFFFF00),    // Желтый 🟡
      'камни': Color(0xFF808080),           // Серый 🔘
      'трава_водоросли': Color(0xFF90EE90), // Светло зеленый 🟢
      'зацеп': Color(0xFFFF0000),           // Красный 🔴
      'бугор': Color(0xFFFF8C00),           // Ярко оранжевый 🟠
      'точка_кормления': Color(0xFF00BFFF), // Ярко голубой 🔵
      'default': Color(0xFF0000FF),         // Синий для обратной совместимости
    };
    return colors[bottomType] ?? const Color(0xFF0000FF);
  }

  static double _calculateVariation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
}