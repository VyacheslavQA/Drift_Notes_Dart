// Путь: lib/screens/marker_maps/depth_chart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../models/depth_analysis_model.dart';
import '../../services/depth_analysis_service.dart';
import '../../localization/app_localizations.dart';

class DepthChartScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const DepthChartScreen({super.key, required this.markerMap});

  @override
  DepthChartScreenState createState() => DepthChartScreenState();
}

class DepthChartScreenState extends State<DepthChartScreen> {
  int _selectedRayIndex = 0;
  double _zoomLevel = 0.5;
  final int _maxRays = 5;

  // Новые переменные для улучшенного функционала
  bool _isComparisonMode = false;
  List<int> _selectedRaysForComparison = [0];
  bool _showAIAnalysis = false;
  MultiRayAnalysis? _aiAnalysis;
  AnalysisSettings _analysisSettings = const AnalysisSettings(); // Упрощенные настройки

  // Цвета для разных лучей в режиме сравнения
  final List<Color> _rayColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  // Константы для графика
  static const double MAX_DISTANCE = 200.0;
  static const double DISTANCE_STEP = 10.0;
  static const double FIXED_CHART_HEIGHT = 190.0;
  static const double MIN_PIXELS_PER_METER = 4.6;
  static const double MAX_PIXELS_PER_METER = 9.2;

  // Цвета для типов дна
  final Map<String, Color> _bottomTypeColors = {
    'ил': Color(0xFFD4A574),
    'глубокий_ил': Color(0xFF8B4513),
    'ракушка': Colors.white,
    'ровно_твердо': Colors.yellow,
    'камни': Colors.grey,
    'трава_водоросли': Color(0xFF90EE90),
    'зацеп': Colors.red,
    'бугор': Color(0xFFFF8C00),
    'точка_кормления': Color(0xFF00BFFF),
    'default': Colors.blue,
  };

  final Map<String, IconData> _bottomTypeIcons = {
    'ил': Icons.view_headline,
    'глубокий_ил': Icons.waves_outlined,
    'ракушка': Icons.wifi,
    'ровно_твердо': Icons.remove,
    'камни': Icons.more_horiz,
    'трава_водоросли': Icons.grass,
    'зацеп': Icons.warning,
    'бугор': Icons.landscape,
    'точка_кормления': Icons.gps_fixed,
    'default': Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Запускаем анализ после первого build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAIAnalysis();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // Запуск ИИ анализа
  Future<void> _runAIAnalysis() async {
    try {
      final localizations = AppLocalizations.of(context);
      final analysis = DepthAnalysisService.analyzeAllRays(
        widget.markerMap.markers,
        _analysisSettings,
        localizations,
      );

      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
        });
      }
    } catch (e) {
      debugPrint('Ошибка ИИ анализа: $e');
    }
  }

  double get _pixelsPerMeterDistance {
    return MIN_PIXELS_PER_METER +
        (_zoomLevel * (MAX_PIXELS_PER_METER - MIN_PIXELS_PER_METER));
  }

  // Получение маркеров для выбранного луча
  List<Map<String, dynamic>> _getMarkersForRay(int rayIndex) {
    final markersForRay = widget.markerMap.markers
        .where((marker) => (marker['rayIndex'] as double?)?.toInt() == rayIndex)
        .where((marker) => marker['depth'] != null && marker['distance'] != null)
        .toList();

    markersForRay.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return markersForRay;
  }

  // Получение маркеров для нескольких лучей
  List<List<Map<String, dynamic>>> _getMarkersForSelectedRays() {
    return _selectedRaysForComparison
        .map((rayIndex) => _getMarkersForRay(rayIndex))
        .toList();
  }

  // Переключение режима сравнения
  void _toggleComparisonMode() {
    setState(() {
      _isComparisonMode = !_isComparisonMode;
      if (!_isComparisonMode) {
        _selectedRaysForComparison = [_selectedRayIndex];
      }
    });
  }

  // Переключение луча для сравнения
  void _toggleRayForComparison(int rayIndex) {
    setState(() {
      if (_selectedRaysForComparison.contains(rayIndex)) {
        if (_selectedRaysForComparison.length > 1) {
          _selectedRaysForComparison.remove(rayIndex);
        }
      } else {
        _selectedRaysForComparison.add(rayIndex);
      }
    });
  }

  // Переключение ИИ анализа
  void _toggleAIAnalysis() {
    setState(() {
      _showAIAnalysis = !_showAIAnalysis;
    });
  }

  // Компактная ИИ кнопка для размещения в строке с лучами
  Widget _buildCompactAIButton() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    String statusText = '';
    Color statusColor = AppConstants.primaryColor;

    if (_aiAnalysis != null && _aiAnalysis!.topRecommendations.isNotEmpty) {
      final topRating = _aiAnalysis!.topRecommendations.first.rating;
      if (topRating >= 9.0) {
        statusText = '🟢';
        statusColor = Colors.green;
      } else if (topRating >= 8.0) {
        statusText = '🔵';
        statusColor = Colors.blue;
      } else {
        statusText = '🟠';
        statusColor = Colors.orange;
      }
    }

    return GestureDetector(
      onTap: _showDetailedAIAnalysis,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 8 : 12,
          vertical: isLandscape ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              color: statusColor,
              size: isLandscape ? 16 : 18,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: isLandscape ? 12 : 14,
              ),
            ),
            if (_aiAnalysis != null && _aiAnalysis!.topRecommendations.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                _aiAnalysis!.topRecommendations.first.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isLandscape ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: isLandscape ? 14 : 16,
            ),
          ],
        ),
      ),
    );
  }

  // Показ детального ИИ анализа в модальном окне
  void _showDetailedAIAnalysis() {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${localizations.translate('ai_analysis')}: ${localizations.translate('carp_fishing')}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Содержимое с прокруткой
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Общая оценка
                          _buildAnalysisSection(
                            localizations.translate('overall_waterbody_assessment'),
                            _aiAnalysis!.overallAssessment,
                            Icons.assessment,
                          ),

                          // Топ рекомендации
                          if (_aiAnalysis!.topRecommendations.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildTopRecommendationsSection(),
                          ],

                          // Общие советы
                          if (_aiAnalysis!.generalTips.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildGeneralTipsSection(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Кнопка закрытия
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: Text(
                          localizations.translate('close'),
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalysisSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecommendationsSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('best_spots_for_carp'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_aiAnalysis!.topRecommendations.take(5).map((rec) {
            Color ratingColor;
            switch (rec.type) {
              case RecommendationType.excellent:
                ratingColor = Colors.green;
                break;
              case RecommendationType.good:
                ratingColor = Colors.blue;
                break;
              case RecommendationType.average:
                ratingColor = Colors.orange;
                break;
              case RecommendationType.avoid:
                ratingColor = Colors.red;
                break;
            }

            // Получаем цвет луча для визуального разделения
            final rayColor = _rayColors[rec.rayIndex];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ratingColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: rayColor.withValues(alpha: 0.8), // Обводка цветом луча!
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Индикатор луча с его цветом
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rayColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${localizations.translate('ray')} ${rec.rayIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rec.distance.toInt()}${localizations.translate('m')}, ${rec.depth.toStringAsFixed(1)}${localizations.translate('m')}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ratingColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${rec.rating.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Кнопка "Перейти к лучу"
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rec.reason,
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Закрываем модальное окно и переключаемся на нужный луч
                          Navigator.pop(context);
                          setState(() {
                            _selectedRayIndex = rec.rayIndex;
                            _isComparisonMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rayColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rayColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location,
                                color: rayColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations.translate('show'),
                                style: TextStyle(
                                  color: rayColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList()),

          // Дополнительная информация о лучах
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 ${localizations.translate('ray_legend')}:',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: List.generate(5, (index) {
                    final markersCount = _getMarkersForRay(index).length;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _rayColors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${localizations.translate('ray')} ${index + 1} ($markersCount ${localizations.translate('points')})',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 ${localizations.translate('tap_show_for_ray_recommendation')}',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTipsSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('carp_fishing_tips'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_aiAnalysis!.generalTips.map((tip) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.yellow,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  // Получение названия типа дна
  String _getBottomTypeName(String? type) {
    final localizations = AppLocalizations.of(context);
    if (type == null) return localizations.translate('silt');

    switch (type) {
      case 'ил': return localizations.translate('silt');
      case 'глубокий_ил': return localizations.translate('deep_silt');
      case 'ракушка': return localizations.translate('shell');
      case 'ровно_твердо': return localizations.translate('firm_bottom');
      case 'камни': return localizations.translate('stones');
      case 'трава_водоросли': return localizations.translate('grass_algae');
      case 'зацеп': return localizations.translate('snag');
      case 'бугор': return localizations.translate('hill');
      case 'точка_кормления': return localizations.translate('feeding_spot');
      default: return localizations.translate('silt');
    }
  }

  // Конвертация старых типов в новые
  String _convertLegacyTypeToNew(String? type) {
    if (type == null) return 'ил';
    switch (type) {
      case 'dropoff': return 'бугор';
      case 'weed': return 'трава_водоросли';
      case 'sandbar': return 'ровно_твердо';
      case 'structure': return 'зацеп';
      case 'default': return 'ил';
      default: return type;
    }
  }

  // Показ деталей маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('marker')} - ${localizations.translate('ray')} ${(marker['rayIndex'] as double).toInt() + 1}',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Дистанция
              Row(
                children: [
                  Icon(Icons.straighten, color: AppConstants.textColor),
                  const SizedBox(width: 8),
                  Text(
                    '${localizations.translate('distance_m')}: ${(marker['distance'] as double).toInt()} ${localizations.translate('m')}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Глубина
              if (marker['depth'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.waves, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Text(
                      '${localizations.translate('depth')}: ${marker['depth']} ${localizations.translate('m')}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ИИ рекомендация для этой точки
              if (_aiAnalysis != null) ...[
                const SizedBox(height: 8),
                _buildAIRecommendationForPoint(marker),
              ],

              // Тип дна
              if (marker['bottomType'] != null || marker['type'] != null) ...[
                Row(
                  children: [
                    Icon(
                      _bottomTypeIcons[marker['bottomType'] ?? _convertLegacyTypeToNew(marker['type'])] ?? Icons.terrain,
                      color: AppConstants.textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${localizations.translate('marker_type')}: ${_getBottomTypeName(marker['bottomType'] ?? _convertLegacyTypeToNew(marker['type']))}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Заметки
              if (marker['notes'] != null && marker['notes'].isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        marker['notes'],
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Кнопка закрытия
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    child: Text(
                      localizations.translate('close'),
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Виджет с ИИ рекомендацией для конкретной точки - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ ВЕРСИЯ
  Widget _buildAIRecommendationForPoint(Map<String, dynamic> marker) {
    final localizations = AppLocalizations.of(context);

    if (_aiAnalysis == null) return const SizedBox.shrink();

    final distance = marker['distance'] as double;
    final markerRayIndex = (marker['rayIndex'] as double?)?.toInt() ?? 0;

    print('🔍 Ищем рекомендацию для маркера:');
    print('  луч маркера: $markerRayIndex');
    print('  дистанция маркера: $distance');

    // ВАРИАНТ 1: Ищем в topRecommendations (теперь с rayIndex)
    final nearbyRecommendation = _aiAnalysis!.topRecommendations
        .where((rec) => rec.rayIndex == markerRayIndex) // Теперь rayIndex есть!
        .where((rec) => (rec.distance - distance).abs() < 5.0) // в пределах 5 метров
        .firstOrNull;

    if (nearbyRecommendation != null) {
      print('  найдена рекомендация в topRecommendations: ${nearbyRecommendation.rating}');
      return _buildRecommendationWidget(nearbyRecommendation);
    }

    // ВАРИАНТ 2: Ищем в rayAnalyses.points (если нет в топе)
    final rayAnalysis = _aiAnalysis!.rayAnalyses
        .where((analysis) => analysis.rayIndex == markerRayIndex)
        .firstOrNull;

    if (rayAnalysis != null) {
      final nearbyPoint = rayAnalysis.points
          .where((point) => (point.distance - distance).abs() < 5.0) // в пределах 5 метров
          .where((point) => point.fishingScore != null && point.fishingScore! >= 6.0) // минимальный рейтинг
          .firstOrNull;

      if (nearbyPoint != null) {
        print('  найдена точка в rayAnalyses: ${nearbyPoint.fishingScore}');
        return _buildPointWidget(nearbyPoint);
      }
    }

    print('  ничего не найдено');

    // ВАРИАНТ 3: Показываем нейтральную оценку
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localizations.translate('ai_standard_fishing_spot'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения рекомендации из topRecommendations
  Widget _buildRecommendationWidget(FishingRecommendation recommendation) {
    final localizations = AppLocalizations.of(context);

    Color recommendationColor;
    switch (recommendation.type) {
      case RecommendationType.excellent:
        recommendationColor = Colors.green;
        break;
      case RecommendationType.good:
        recommendationColor = Colors.blue;
        break;
      case RecommendationType.average:
        recommendationColor = Colors.orange;
        break;
      case RecommendationType.avoid:
        recommendationColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendationColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: recommendationColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: recommendationColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${localizations.translate('ai_analysis')}: ${localizations.translate('carp_potential')}',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendationColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recommendation.rating.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.reason,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${localizations.translate('time')}: ${recommendation.bestTime}',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения точки из rayAnalyses
  Widget _buildPointWidget(DepthPoint point) {
    final localizations = AppLocalizations.of(context);
    final score = point.fishingScore!;
    Color recommendationColor;
    String recommendationType;

    if (score >= 9.0) {
      recommendationColor = Colors.green;
      recommendationType = localizations.translate('excellent');
    } else if (score >= 8.0) {
      recommendationColor = Colors.blue;
      recommendationType = localizations.translate('good');
    } else if (score >= 7.0) {
      recommendationColor = Colors.orange;
      recommendationType = localizations.translate('average');
    } else {
      recommendationColor = Colors.red;
      recommendationType = localizations.translate('poor');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendationColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: recommendationColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: recommendationColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${localizations.translate('ai_analysis')}: ${localizations.translate('carp_potential')}',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendationColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${score.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$recommendationType ${localizations.translate('carp_fishing_spot')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.translate('ai_recommendation_based_on_relief_analysis'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D),
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель
            Container(
              height: isLandscape ? 50 : 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Кнопка назад
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppConstants.textColor,
                      size: isLandscape ? 20 : 24,
                    ),
                  ),

                  // Заголовок
                  Expanded(
                    child: Text(
                      localizations.translate('charts'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: isLandscape ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Кнопка режима сравнения
                  IconButton(
                    onPressed: _toggleComparisonMode,
                    icon: Icon(
                      _isComparisonMode ? Icons.layers : Icons.layers_outlined,
                      color: _isComparisonMode ? AppConstants.primaryColor : AppConstants.textColor,
                      size: isLandscape ? 20 : 24,
                    ),
                    tooltip: localizations.translate('comparison_mode'),
                  ),

                  // Кнопка ИИ анализа
                  IconButton(
                    onPressed: _toggleAIAnalysis,
                    icon: Icon(
                      _showAIAnalysis ? Icons.psychology : Icons.psychology_outlined,
                      color: _showAIAnalysis ? AppConstants.primaryColor : AppConstants.textColor,
                      size: isLandscape ? 20 : 24,
                    ),
                    tooltip: localizations.translate('ai_analysis'),
                  ),
                ],
              ),
            ),

            // Панель выбора лучей (только в режиме сравнения)
            if (_isComparisonMode) ...[
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${localizations.translate('select_rays')}:',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: List.generate(_maxRays, (index) {
                          final markersCount = _getMarkersForRay(index).length;
                          final isSelected = _selectedRaysForComparison.contains(index);

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleRayForComparison(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _rayColors[index].withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? _rayColors[index]
                                        : AppConstants.textColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? _rayColors[index]
                                            : AppConstants.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (markersCount > 0)
                                      Text(
                                        '($markersCount)',
                                        style: TextStyle(
                                          color: isSelected
                                              ? _rayColors[index]
                                              : AppConstants.textColor.withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // ИИ кнопка справа в режиме сравнения
                    if (_showAIAnalysis && _aiAnalysis != null) ...[
                      const SizedBox(width: 12),
                      _buildCompactAIButton(),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Обычная панель переключения лучей с ИИ кнопкой
              Container(
                height: isLandscape ? 50 : 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Лучи (смещены влево)
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            height: isLandscape ? 35 : 40,
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_maxRays, (index) {
                                final markersCount = _getMarkersForRay(index).length;
                                final isSelected = index == _selectedRayIndex;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedRayIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 8 : 12,
                                      vertical: isLandscape ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppConstants.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${index + 1}${markersCount > 0 ? ' ($markersCount)' : ''}',
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: isLandscape ? 12 : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ИИ кнопка справа
                    if (_showAIAnalysis && _aiAnalysis != null) ...[
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildCompactAIButton(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // График с горизонтальной прокруткой
            Expanded(
              child: Container(
                margin: EdgeInsets.all(isLandscape ? 8 : 16),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildChart(isLandscape),
                  ),
                ),
              ),
            ),

            // Нижняя панель с масштабом
            Container(
              height: isLandscape ? 50 : 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    localizations.translate('size'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isLandscape ? 14 : 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppConstants.primaryColor,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        thumbColor: AppConstants.primaryColor,
                        overlayColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _zoomLevel,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _zoomLevel = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isLandscape ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isLandscape) {
    final localizations = AppLocalizations.of(context);

    final pixelsPerMeterDistance = _pixelsPerMeterDistance;
    final chartHeight = FIXED_CHART_HEIGHT;
    final chartWidth = MAX_DISTANCE * pixelsPerMeterDistance;

    final leftPadding = 80.0;
    final rightPadding = 40.0;
    final topPadding = 40.0;
    final bottomPadding = 60.0;

    final totalWidth = chartWidth + leftPadding + rightPadding;
    final totalHeight = chartHeight + topPadding + bottomPadding;

    // Получаем данные для отображения
    final markersData = _isComparisonMode
        ? _getMarkersForSelectedRays()
        : [_getMarkersForRay(_selectedRayIndex)];

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          key: ValueKey('${_zoomLevel}_${_selectedRayIndex}_${_isComparisonMode}_${_selectedRaysForComparison.join('-')}_${_showAIAnalysis}'),
          size: Size(totalWidth, totalHeight),
          painter: EnhancedDepthChartPainter(
            markersData: markersData,
            allMarkers: widget.markerMap.markers,
            selectedRays: _isComparisonMode ? _selectedRaysForComparison : [_selectedRayIndex],
            rayColors: _rayColors,
            isComparisonMode: _isComparisonMode,
            zoomLevel: _zoomLevel,
            bottomTypeColors: _bottomTypeColors,
            bottomTypeIcons: _bottomTypeIcons,
            onMarkerTap: _showMarkerDetails,
            context: context,
            isLandscape: isLandscape,
            convertLegacyType: _convertLegacyTypeToNew,
            fixedChartHeight: chartHeight,
            pixelsPerMeterDistance: pixelsPerMeterDistance,
            aiAnalysis: _showAIAnalysis ? _aiAnalysis : null,
          ),
          child: markersData.every((markers) => markers.isEmpty)
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: isLandscape ? 40 : 50,
                  color: AppConstants.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.translate('no_data_to_display'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.5),
                    fontSize: isLandscape ? 12 : 14,
                  ),
                ),
              ],
            ),
          )
              : null,
        ),
      ),
    );
  }
}

// Улучшенный painter с поддержкой сравнения и ИИ анализа
class EnhancedDepthChartPainter extends CustomPainter {
  final List<List<Map<String, dynamic>>> markersData;
  final List<Map<String, dynamic>> allMarkers;
  final List<int> selectedRays;
  final List<Color> rayColors;
  final bool isComparisonMode;
  final double zoomLevel;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final Function(Map<String, dynamic>) onMarkerTap;
  final BuildContext context;
  final bool isLandscape;
  final String Function(String?) convertLegacyType;
  final double fixedChartHeight;
  final double pixelsPerMeterDistance;
  final MultiRayAnalysis? aiAnalysis;

  static const double MAX_DISTANCE = 200.0;
  static const double DISTANCE_STEP = 10.0;

  EnhancedDepthChartPainter({
    required this.markersData,
    required this.allMarkers,
    required this.selectedRays,
    required this.rayColors,
    required this.isComparisonMode,
    required this.zoomLevel,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.onMarkerTap,
    required this.context,
    required this.isLandscape,
    required this.convertLegacyType,
    required this.fixedChartHeight,
    required this.pixelsPerMeterDistance,
    this.aiAnalysis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 80.0;
    final rightPadding = 40.0;
    final topPadding = 40.0;
    final bottomPadding = 60.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = fixedChartHeight;

    // Определяем общий диапазон глубин для всех лучей
    double minDepth = 0.0;
    double maxDepth = 10.0;

    final allVisibleMarkers = markersData.expand((markers) => markers).toList();
    if (allVisibleMarkers.isNotEmpty) {
      final depths = allVisibleMarkers.map((m) => m['depth'] as double).toList();
      minDepth = depths.reduce(math.min);
      maxDepth = depths.reduce(math.max);

      final depthRange = maxDepth - minDepth;
      if (depthRange > 0) {
        minDepth = math.max(0.0, minDepth - depthRange * 0.1);
        maxDepth = maxDepth + depthRange * 0.1;
      } else {
        minDepth = math.max(0.0, minDepth - 1.0);
        maxDepth = maxDepth + 1.0;
      }
    }

    // Функции преобразования координат
    double distanceToX(double distance) {
      return leftPadding + (distance * pixelsPerMeterDistance);
    }

    double depthToY(double depth) {
      return topPadding + (depth - minDepth) / (maxDepth - minDepth) * chartHeight;
    }

    // Рисуем ИИ рекомендации для текущего луча (если включены)
    if (aiAnalysis != null) {
      if (isComparisonMode) {
        _drawAIRecommendationsForSelectedRays(canvas, distanceToX, depthToY);
      } else {
        _drawAIRecommendationsForSingleRay(canvas, distanceToX, depthToY, selectedRays[0]);
      }
    }

    // Рисуем профили для всех выбранных лучей
    for (int i = 0; i < markersData.length; i++) {
      final markers = markersData[i];
      final rayIndex = selectedRays[i];
      final rayColor = isComparisonMode
          ? rayColors[rayIndex].withValues(alpha: 0.8)
          : const Color(0xFF6B9AC4);

      if (markers.isNotEmpty) {
        // Профильная линия (без градиентной заливки в режиме сравнения)
        _drawProfileLine(canvas, distanceToX, depthToY, markers, rayColor);

        // Маркеры
        _drawMarkers(canvas, distanceToX, depthToY, markers, rayColor, rayIndex);

        // Иконки типов дна (только в обычном режиме, не в сравнении)
        if (!isComparisonMode) {
          _drawBottomTypeIndicators(canvas, distanceToX, topPadding, markers);
        }
      }
    }

    // Рисуем подписи осей
    _drawAxisLabels(
      canvas,
      size,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      0.0,
      MAX_DISTANCE,
      minDepth,
      maxDepth,
    );

    // Легенда для режима сравнения
    if (isComparisonMode && selectedRays.length > 1) {
      _drawComparisonLegend(canvas, size, rightPadding);
    }
  }

  // Отрисовка ИИ рекомендаций для одного выбранного луча
  void _drawAIRecommendationsForSingleRay(
      Canvas canvas,
      double Function(double) distanceToX,
      double Function(double) depthToY,
      int selectedRayIndex,
      ) {
    if (aiAnalysis == null) return;

    // Ищем анализ для конкретного луча
    final rayAnalysis = aiAnalysis!.rayAnalyses
        .where((a) => a.rayIndex == selectedRayIndex)
        .firstOrNull;

    if (rayAnalysis == null) return;

    // Рисуем рекомендации для всех точек на этом луче с хорошим рейтингом
    for (final point in rayAnalysis.points) {
      if (point.fishingScore != null && point.fishingScore! >= 7.0) {
        final x = distanceToX(point.distance);
        final y = depthToY(point.depth);
        final score = point.fishingScore!;

        Color recommendationColor;
        double glowRadius;

        if (score >= 9.0) {
          recommendationColor = Colors.green;
          glowRadius = 20;
        } else if (score >= 8.0) {
          recommendationColor = Colors.blue;
          glowRadius = 15;
        } else {
          recommendationColor = Colors.orange;
          glowRadius = 12;
        }

        // Рисуем подсвечивающий круг
        final glowPaint = Paint()
          ..color = recommendationColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), glowRadius, glowPaint);

        // Рисуем обводку
        final borderPaint = Paint()
          ..color = recommendationColor.withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(Offset(x, y), glowRadius, borderPaint);

        // Рисуем звездочку для топ рекомендаций
        if (score >= 9.0) {
          _drawStar(canvas, Offset(x, y - glowRadius - 8), recommendationColor, 8);
        }

        // Рисуем рейтинг рядом с местом
        _drawScoreLabel(canvas, Offset(x + glowRadius + 5, y), score, recommendationColor);
      }
    }
  }

  // Отрисовка ИИ рекомендаций для выбранных лучей в режиме сравнения
  void _drawAIRecommendationsForSelectedRays(
      Canvas canvas,
      double Function(double) distanceToX,
      double Function(double) depthToY,
      ) {
    if (aiAnalysis == null) return;

    // Проходим только по выбранным лучам
    for (final rayIndex in selectedRays) {
      final rayAnalysis = aiAnalysis!.rayAnalyses
          .where((a) => a.rayIndex == rayIndex)
          .firstOrNull;

      if (rayAnalysis == null) continue;

      // Рисуем рекомендации для этого луча
      for (final point in rayAnalysis.points) {
        if (point.fishingScore != null && point.fishingScore! >= 7.0) {
          final x = distanceToX(point.distance);
          final y = depthToY(point.depth);
          final score = point.fishingScore!;

          Color recommendationColor;
          double glowRadius;

          if (score >= 9.0) {
            recommendationColor = Colors.green;
            glowRadius = 20;
          } else if (score >= 8.0) {
            recommendationColor = Colors.blue;
            glowRadius = 15;
          } else {
            recommendationColor = Colors.orange;
            glowRadius = 12;
          }

          // Рисуем подсвечивающий круг
          final glowPaint = Paint()
            ..color = recommendationColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

          canvas.drawCircle(Offset(x, y), glowRadius, glowPaint);

          // Рисуем обводку с цветом луча для различения
          final borderPaint = Paint()
            ..color = rayColors[rayIndex].withValues(alpha: 0.8)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

          canvas.drawCircle(Offset(x, y), glowRadius, borderPaint);

          // Рисуем звездочку для топ рекомендаций
          if (score >= 9.0) {
            _drawStar(canvas, Offset(x, y - glowRadius - 8), recommendationColor, 8);
          }

          // Рисуем рейтинг рядом с местом
          _drawScoreLabel(canvas, Offset(x + glowRadius + 5, y), score, recommendationColor);
        }
      }
    }
  }

  // Рисование звездочки
  void _drawStar(Canvas canvas, Offset center, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double angle = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? size : size * 0.5;
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  // Рисование рейтинга рядом с маркером
  void _drawScoreLabel(Canvas canvas, Offset position, double score, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: isLandscape ? 10 : 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  // Легенда для режима сравнения
  void _drawComparisonLegend(Canvas canvas, Size size, double rightPadding) {
    final localizations = AppLocalizations.of(context);
    final legendX = size.width - rightPadding + 10;
    var legendY = 60.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < selectedRays.length; i++) {
      final rayIndex = selectedRays[i];
      final rayColor = rayColors[rayIndex];

      // Цветная линия
      final linePaint = Paint()
        ..color = rayColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(legendX, legendY),
        Offset(legendX + 20, legendY),
        linePaint,
      );

      // Подпись луча
      textPainter.text = TextSpan(
        text: '${localizations.translate('ray')} ${rayIndex + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 25, legendY - 6));

      legendY += 25;
    }
  }

  void _drawProfileLine(
      Canvas canvas,
      double Function(double) distanceToX,
      double Function(double) depthToY,
      List<Map<String, dynamic>> markers,
      Color lineColor,
      ) {
    if (markers.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirst = true;

    for (final marker in markers) {
      final x = distanceToX(marker['distance'] as double);
      final y = depthToY(marker['depth'] as double);

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawMarkers(
      Canvas canvas,
      double Function(double) distanceToX,
      double Function(double) depthToY,
      List<Map<String, dynamic>> markers,
      Color rayColor,
      int rayIndex,
      ) {
    for (final marker in markers) {
      final x = distanceToX(marker['distance'] as double);
      final y = depthToY(marker['depth'] as double);

      String bottomType = marker['bottomType'] ?? convertLegacyType(marker['type']) ?? 'ил';
      final markerColor = isComparisonMode
          ? rayColor
          : (bottomTypeColors[bottomType] ?? Colors.blue);

      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), isLandscape ? 2 : 2.5, markerPaint);

      _drawDepthLabel(canvas, x, y, marker['depth'] as double, rayColor);

      marker['_chartX'] = x;
      marker['_chartY'] = y;
      marker['_hitRadius'] = isLandscape ? 15.0 : 20.0;
    }
  }

  void _drawDepthLabel(Canvas canvas, double x, double y, double depth, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: depth.toStringAsFixed(1),
        style: TextStyle(
          color: isComparisonMode ? color : Colors.yellow.shade300,
          fontSize: isLandscape ? 9 : 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 12));
  }

  void _drawBottomTypeIndicators(
      Canvas canvas,
      double Function(double) distanceToX,
      double topPadding,
      List<Map<String, dynamic>> markers,
      ) {
    for (final marker in markers) {
      final x = distanceToX(marker['distance'] as double);
      final y = marker['_chartY'] as double;

      String bottomType = marker['bottomType'] ?? convertLegacyType(marker['type']) ?? 'ил';
      final iconData = bottomTypeIcons[bottomType] ?? Icons.location_on;

      _drawIcon(canvas, iconData, Offset(x, topPadding - 20), isLandscape ? 15.0 : 17.0);
      _drawDashedLine(canvas, Offset(x, topPadding - 5), Offset(x, y));
    }
  }

  void _drawIcon(Canvas canvas, IconData iconData, Offset center, double size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const dashWidth = 3.0;
    const dashSpace = 3.0;

    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startOffset = start + (end - start) * (i * (dashWidth + dashSpace) / distance);
      final endOffset = start + (end - start) * ((i * (dashWidth + dashSpace) + dashWidth) / distance);

      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  void _drawAxisLabels(
      Canvas canvas,
      Size size,
      double leftPadding,
      double topPadding,
      double chartWidth,
      double chartHeight,
      double minDistance,
      double maxDistance,
      double minDepth,
      double maxDepth,
      ) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: isLandscape ? 10 : 12,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Подписи дистанции
    for (double d = 0; d <= maxDistance; d += DISTANCE_STEP) {
      final x = leftPadding + (d * pixelsPerMeterDistance);

      textPainter.text = TextSpan(text: '${d.toInt()}', style: textStyle);
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topPadding + chartHeight + 8),
      );
    }

    // Подписи глубины
    final depthStep = _calculateDepthStep(maxDepth - minDepth);
    for (double d = (minDepth / depthStep).ceil() * depthStep; d <= maxDepth; d += depthStep) {
      final y = topPadding + (d - minDepth) / (maxDepth - minDepth) * chartHeight;

      textPainter.text = TextSpan(text: '${d.toStringAsFixed(1)}', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - textPainter.height / 2));
    }
  }

  double _calculateDepthStep(double range) {
    if (range <= 0) return 1.0;

    final magnitude = math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
    final normalized = range / magnitude;

    if (normalized <= 1) return magnitude * 0.2;
    if (normalized <= 2) return magnitude * 0.5;
    if (normalized <= 5) return magnitude * 1.0;
    return magnitude * 2.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) {
    for (final markers in markersData) {
      for (final marker in markers) {
        if (marker.containsKey('_chartX') &&
            marker.containsKey('_chartY') &&
            marker.containsKey('_hitRadius')) {
          final center = Offset(marker['_chartX'], marker['_chartY']);
          final radius = marker['_hitRadius'];

          if ((center - position).distance <= radius) {
            onMarkerTap(marker);
            return true;
          }
        }
      }
    }
    return null;
  }
}