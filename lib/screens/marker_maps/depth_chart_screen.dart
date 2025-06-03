// Путь: lib/screens/marker_maps/depth_chart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../localization/app_localizations.dart';

class DepthChartScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const DepthChartScreen({
    super.key,
    required this.markerMap,
  });

  @override
  DepthChartScreenState createState() => DepthChartScreenState();
}

class DepthChartScreenState extends State<DepthChartScreen> {
  int _selectedRayIndex = 0;
  double _zoomLevel = 0.5; // Начальное значение 50%
  final int _maxRays = 5;

  // Константы для графика
  static const double MAX_DISTANCE = 200.0; // Всегда полная шкала до 200м
  static const double DISTANCE_STEP = 10.0; // Шаг в 10м

  // Фиксированная высота графика - 5 см (примерно 190 пикселей при стандартной плотности)
  static const double FIXED_CHART_HEIGHT = 190.0;

  // ИСПРАВЛЕНО: Увеличенные значения для достижения 7мм и 14мм
  // Экспериментально подобранные значения для нужных размеров
  static const double MIN_PIXELS_PER_METER = 4.6; // Для получения 7мм между отметками
  static const double MAX_PIXELS_PER_METER = 9.2; // Для получения 14мм между отметками

  // Цвета для типов дна (те же что и на карте)
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

  // Иконки для типов дна
  final Map<String, IconData> _bottomTypeIcons = {
    'ил': Icons.blur_linear,
    'глубокий_ил': Icons.waves,
    'ракушка': Icons.grain,
    'ровно_твердо': Icons.view_agenda,
    'камни': Icons.circle,
    'трава_водоросли': Icons.grass,
    'зацеп': Icons.warning,
    'бугор': Icons.landscape,
    'точка_кормления': Icons.room_service,
    'default': Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    // Разрешаем поворот экрана для графиков
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Восстанавливаем ориентацию по умолчанию
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ДОБАВЛЕНО: Функция для вычисления pixelsPerMeter на основе _zoomLevel
  double get _pixelsPerMeterDistance {
    // Интерполяция между минимальным и максимальным значением
    return MIN_PIXELS_PER_METER + (_zoomLevel * (MAX_PIXELS_PER_METER - MIN_PIXELS_PER_METER));
  }

  // Получение маркеров для выбранного луча
  List<Map<String, dynamic>> _getMarkersForRay(int rayIndex) {
    final markersForRay = widget.markerMap.markers
        .where((marker) => (marker['rayIndex'] as double?)?.toInt() == rayIndex)
        .where((marker) => marker['depth'] != null && marker['distance'] != null)
        .toList();

    // Сортируем по дистанции
    markersForRay.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return markersForRay;
  }

  // Получение названия типа дна
  String _getBottomTypeName(String? type) {
    final localizations = AppLocalizations.of(context);
    if (type == null) return localizations.translate('silt');

    switch (type) {
      case 'ил':
        return localizations.translate('silt');
      case 'глубокий_ил':
        return localizations.translate('deep_silt');
      case 'ракушка':
        return localizations.translate('shell');
      case 'ровно_твердо':
        return localizations.translate('firm_bottom');
      case 'камни':
        return localizations.translate('stones');
      case 'трава_водоросли':
        return localizations.translate('grass_algae');
      case 'зацеп':
        return localizations.translate('snag');
      case 'бугор':
        return localizations.translate('hill');
      case 'точка_кормления':
        return localizations.translate('feeding_spot');
      default:
        return localizations.translate('silt');
    }
  }

  // Конвертация старых типов в новые (для совместимости)
  String _convertLegacyTypeToNew(String? type) {
    if (type == null) return 'ил';

    switch (type) {
      case 'dropoff':
        return 'бугор';
      case 'weed':
        return 'трава_водоросли';
      case 'sandbar':
        return 'ровно_твердо';
      case 'structure':
        return 'зацеп';
      case 'default':
        return 'ил';
      default:
        return type;
    }
  }

  // Показ деталей маркера при тапе
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
                '${localizations.translate('marker')} - ${localizations.translate('ray')} ${_selectedRayIndex + 1}',
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
                    '${localizations.translate('distance_m')}: ${marker['distance'].toInt()} м',
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
                      '${localizations.translate('depth')}: ${marker['depth']} м',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D), // Тот же темный фон
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель с переключением лучей
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

                  // Переключатель лучей
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
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

            // График с горизонтальной прокруткой и центрированием
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
                        min: 0.0, // От 0%
                        max: 1.0, // До 100%
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
    final markersForRay = _getMarkersForRay(_selectedRayIndex);

    // ИСПРАВЛЕНО: Используем геттер вместо локального вычисления
    final pixelsPerMeterDistance = _pixelsPerMeterDistance;

    // Фиксированная высота графика 5 см = 190 пикселей
    final chartHeight = FIXED_CHART_HEIGHT;

    // Вычисляем размеры графика
    final chartWidth = MAX_DISTANCE * pixelsPerMeterDistance;

    // Отступы для осей и подписей
    final leftPadding = 80.0;
    final rightPadding = 40.0;
    final topPadding = 40.0;
    final bottomPadding = 60.0;

    final totalWidth = chartWidth + leftPadding + rightPadding;
    final totalHeight = chartHeight + topPadding + bottomPadding;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          key: ValueKey('${_zoomLevel}_${_selectedRayIndex}'), // ИСПРАВЛЕНО: уникальный ключ
          size: Size(totalWidth, totalHeight),
          painter: DepthChartPainter(
            markers: markersForRay,
            zoomLevel: _zoomLevel,
            bottomTypeColors: _bottomTypeColors,
            bottomTypeIcons: _bottomTypeIcons,
            onMarkerTap: _showMarkerDetails,
            context: context,
            isLandscape: isLandscape,
            convertLegacyType: _convertLegacyTypeToNew,
            fixedChartHeight: chartHeight,
            pixelsPerMeterDistance: pixelsPerMeterDistance,
          ),
          child: markersForRay.isEmpty ? Center(
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
                Text(
                  '${localizations.translate('ray')} ${_selectedRayIndex + 1}',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.3),
                    fontSize: isLandscape ? 10 : 12,
                  ),
                ),
              ],
            ),
          ) : null,
        ),
      ),
    );
  }
}

class DepthChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> markers;
  final double zoomLevel;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final Function(Map<String, dynamic>) onMarkerTap;
  final BuildContext context;
  final bool isLandscape;
  final String Function(String?) convertLegacyType;
  final double fixedChartHeight;
  final double pixelsPerMeterDistance;

  // Константы
  static const double MAX_DISTANCE = 200.0;
  static const double DISTANCE_STEP = 10.0;

  DepthChartPainter({
    required this.markers,
    required this.zoomLevel,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.onMarkerTap,
    required this.context,
    required this.isLandscape,
    required this.convertLegacyType,
    required this.fixedChartHeight,
    required this.pixelsPerMeterDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Отступы
    final leftPadding = 80.0;
    final rightPadding = 40.0;
    final topPadding = 40.0;
    final bottomPadding = 60.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = fixedChartHeight;

    // Фиксированные диапазоны дистанций (ВСЕГДА 0-200м)
    final minDistance = 0.0;
    final maxDistance = MAX_DISTANCE;

    // Используем переданный pixelsPerMeterDistance для расчета ширины
    final actualChartWidth = maxDistance * pixelsPerMeterDistance;

    // Диапазон глубин определяем по маркерам
    double minDepth = 0.0;
    double maxDepth = 10.0;

    if (markers.isNotEmpty) {
      final depths = markers.map((m) => m['depth'] as double).toList();
      minDepth = depths.reduce(math.min);
      maxDepth = depths.reduce(math.max);

      // Добавляем отступы к диапазону глубин
      final depthRange = maxDepth - minDepth;
      if (depthRange > 0) {
        minDepth = math.max(0.0, minDepth - depthRange * 0.1);
        maxDepth = maxDepth + depthRange * 0.1;
      } else {
        // Если все маркеры на одной глубине, создаем небольшой диапазон
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

    // Рисуем сетку
    _drawGrid(canvas, size, leftPadding, topPadding, actualChartWidth, chartHeight, minDistance, maxDistance, minDepth, maxDepth);

    // Рисуем линию профиля дна и маркеры (только если есть маркеры)
    if (markers.isNotEmpty) {
      _drawProfileLine(canvas, distanceToX, depthToY);
      _drawMarkers(canvas, distanceToX, depthToY);
    }

    // Рисуем подписи осей
    _drawAxisLabels(canvas, size, leftPadding, topPadding, actualChartWidth, chartHeight, minDistance, maxDistance, minDepth, maxDepth);
  }

  void _drawGrid(Canvas canvas, Size size, double leftPadding, double topPadding,
      double chartWidth, double chartHeight, double minDistance, double maxDistance,
      double minDepth, double maxDepth) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Вертикальные линии (дистанция) - каждые 10м от 0 до 200
    for (double d = 0; d <= maxDistance; d += DISTANCE_STEP) {
      final x = leftPadding + (d * pixelsPerMeterDistance);
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + chartHeight),
        paint,
      );
    }

    // Горизонтальные линии (глубина)
    final depthStep = _calculateDepthStep(maxDepth - minDepth);
    for (double d = (minDepth / depthStep).ceil() * depthStep; d <= maxDepth; d += depthStep) {
      final y = topPadding + (d - minDepth) / (maxDepth - minDepth) * chartHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        paint,
      );
    }
  }

  void _drawProfileLine(Canvas canvas, double Function(double) distanceToX, double Function(double) depthToY) {
    if (markers.length < 2) return;

    final paint = Paint()
      ..color = Color(0xFF6B9AC4) // Приглушенный голубой
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

  void _drawMarkers(Canvas canvas, double Function(double) distanceToX, double Function(double) depthToY) {
    for (final marker in markers) {
      final x = distanceToX(marker['distance'] as double);
      final y = depthToY(marker['depth'] as double);

      // Определяем цвет маркера
      String bottomType = marker['bottomType'] ?? convertLegacyType(marker['type']) ?? 'ил';
      final markerColor = bottomTypeColors[bottomType] ?? Colors.blue;

      // Рисуем точку маркера
      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), isLandscape ? 4 : 5, markerPaint);

      // Рисуем подпись глубины (желтым цветом)
      _drawDepthLabel(canvas, x, y, marker['depth'] as double);

      // Рисуем символ типа дна
      _drawBottomTypeSymbol(canvas, x, y, bottomType);

      // Сохраняем позицию для обработки тапов
      marker['_chartX'] = x;
      marker['_chartY'] = y;
      marker['_hitRadius'] = isLandscape ? 15.0 : 20.0;
    }
  }

  void _drawDepthLabel(Canvas canvas, double x, double y, double depth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: depth.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.yellow.shade300,
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
    textPainter.paint(canvas, Offset(x + 8, y + 8));
  }

  void _drawBottomTypeSymbol(Canvas canvas, double x, double y, String bottomType) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getBottomTypeSymbol(bottomType),
        style: TextStyle(
          color: Colors.white,
          fontSize: isLandscape ? 8 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 8, y - 15));
  }

  String _getBottomTypeSymbol(String bottomType) {
    switch (bottomType) {
      case 'ил': return '≈';
      case 'глубокий_ил': return '≋';
      case 'ракушка': return '◦';
      case 'ровно_твердо': return '■';
      case 'камни': return '●';
      case 'трава_водоросли': return '♠';
      case 'зацеп': return '⚠';
      case 'бугор': return '▲';
      case 'точка_кормления': return '✦';
      default: return '●';
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double leftPadding, double topPadding,
      double chartWidth, double chartHeight, double minDistance, double maxDistance,
      double minDepth, double maxDepth) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: isLandscape ? 10 : 12,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Подписи дистанции (ось X) - каждые 10м от 0 до 200
    for (double d = 0; d <= maxDistance; d += DISTANCE_STEP) {
      final x = leftPadding + (d * pixelsPerMeterDistance);

      textPainter.text = TextSpan(text: '${d.toInt()}', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, topPadding + chartHeight + 8));
    }

    // Подписи глубины (ось Y)
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
    // Проверяем попадание по маркерам
    for (final marker in markers) {
      if (marker.containsKey('_chartX') && marker.containsKey('_chartY') && marker.containsKey('_hitRadius')) {
        final center = Offset(marker['_chartX'], marker['_chartY']);
        final radius = marker['_hitRadius'];

        if ((center - position).distance <= radius) {
          onMarkerTap(marker);
          return true;
        }
      }
    }
    return null;
  }
}