// Путь: lib/screens/marker_maps/components/modern_map_labels.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../localization/app_localizations.dart';

/// Современные подписи карты
/// Заменяет TextPainter на Positioned Text виджеты
class ModernMapLabels extends StatelessWidget {
  final double maxDistance;
  final int rayCount;
  final double leftAngle;
  final double rightAngle;
  final Size screenSize;

  const ModernMapLabels({
    super.key,
    required this.maxDistance,
    required this.rayCount,
    required this.leftAngle,
    required this.rightAngle,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 20; // 🔥 ИСПРАВЛЕНО: отступ от низа экрана
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    return RepaintBoundary(
      child: Stack(
        children: [
          // Подписи расстояний (10-50м)
          ..._buildDistanceLabels(centerX, originY, pixelsPerMeter),

          // Подписи больших расстояний (60-200м)
          ..._buildLargeDistanceLabels(centerX, originY, pixelsPerMeter),

          // Подписи лучей
          ..._buildRayLabels(localizations, centerX, originY),
        ],
      ),
    );
  }

  /// Подписи расстояний 10-50м (вертикальные) - ОПУСКАЕМ НИЖЕ
  List<Widget> _buildDistanceLabels(double centerX, double originY, double pixelsPerMeter) {
    return List.generate(5, (index) {
      final distance = (index + 1) * 10; // 10, 20, 30, 40, 50

      return Positioned(
        left: centerX - distance * pixelsPerMeter + 4,
        top: originY - 35, // 🔥 ОПУСКАЕМ НИЖЕ (было -80, стало -35)
        child: Transform.rotate(
          angle: -math.pi / 2, // Поворот на 90 градусов
          child: Text(
            distance.toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Подписи больших расстояний (60-200м) с фиксированными позициями
  List<Widget> _buildLargeDistanceLabels(double centerX, double originY, double pixelsPerMeter) {
    final distancePositions = [
      {'distance': 60, 'offset': 95.0},
      {'distance': 70, 'offset': 70.0},
      {'distance': 80, 'offset': 55.0},
      {'distance': 90, 'offset': 50.0},
      {'distance': 100, 'offset': 40.0},
      {'distance': 110, 'offset': 35.0},
      {'distance': 120, 'offset': 30.0},
      {'distance': 130, 'offset': 25.0},
      {'distance': 140, 'offset': 22.0},
      {'distance': 150, 'offset': 22.0},
      {'distance': 160, 'offset': 18.0},
      {'distance': 170, 'offset': 18.0},
      {'distance': 180, 'offset': 15.0},
      {'distance': 190, 'offset': 15.0},
      {'distance': 200, 'offset': 15.0},
    ];

    return distancePositions.map((pos) {
      final distance = pos['distance'] as int;
      final offset = pos['offset'] as double;

      return Positioned(
        left: 8,
        top: originY - distance * pixelsPerMeter + offset,
        child: Text(
          distance.toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Подписи лучей
  List<Widget> _buildRayLabels(AppLocalizations localizations, double centerX, double originY) {
    return List.generate(rayCount, (i) {
      final angle = _calculateRayAngle(i);

      // Базовые параметры
      double labelY = 50.0;
      final rayAtLabelY = (originY - labelY);
      double labelX = centerX + rayAtLabelY / math.tan(angle);

      // Индивидуальные корректировки для каждого луча
      switch (i) {
        case 0:
          labelY += 20.0;
          labelX -= 50.0;
          labelX = math.max(labelX, 35.0);
          break;
        case 1:
          labelY += 5.0;
          break;
        case 2:
          break;
        case 3:
          labelY += 5.0;
          break;
        case 4:
          labelY += 20.0;
          labelX += 50.0;
          labelX = math.min(labelX, screenSize.width - 35.0);
          break;
      }

      return Positioned(
        left: labelX - 30, // Центрируем текст
        top: labelY - 10,
        child: SizedBox(
          width: 60,
          child: Text(
            '${localizations.translate('ray')} ${i + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Вычисление угла луча (та же логика что в оригинале)
  double _calculateRayAngle(int rayIndex) {
    final totalAngle = leftAngle - rightAngle;
    final angleStep = totalAngle / (rayCount - 1);
    final angleDegrees = leftAngle - (rayIndex * angleStep);
    return angleDegrees * (math.pi / 180);
  }
}