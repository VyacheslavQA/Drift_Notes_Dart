// Путь: lib/screens/marker_maps/utils/map_calculations.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Утилиты для математических вычислений карты маркеров
/// Вынесены из основного файла для переиспользования
class MapCalculations {
  /// Вычисление угла луча
  static double calculateRayAngle({
    required int rayIndex,
    required int totalRays,
    required double leftAngle,
    required double rightAngle,
  }) {
    final totalAngle = leftAngle - rightAngle;
    final angleStep = totalAngle / (totalRays - 1);
    final angleDegrees = leftAngle - (rayIndex * angleStep);
    return angleDegrees * (math.pi / 180);
  }

  /// Вычисление позиции маркера на экране
  static Offset calculateMarkerPosition({
    required int rayIndex,
    required double distance,
    required int totalRays,
    required double maxDistance,
    required double leftAngle,
    required double rightAngle,
    required Size screenSize,
  }) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 5;
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    final angle = calculateRayAngle(
      rayIndex: rayIndex,
      totalRays: totalRays,
      leftAngle: leftAngle,
      rightAngle: rightAngle,
    );

    final ratio = distance / maxDistance;
    final maxRayLength = maxDistance * pixelsPerMeter;

    final dx = centerX + maxRayLength * ratio * math.cos(angle);
    final dy = originY - maxRayLength * ratio * math.sin(angle);

    return Offset(dx, dy);
  }

  /// Вычисление позиции точки пересечения сетки и луча
  static Offset calculateGridIntersection({
    required int rayIndex,
    required int distance,
    required int totalRays,
    required double leftAngle,
    required double rightAngle,
    required Size screenSize,
    required double maxDistance,
  }) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 5;
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    final angle = calculateRayAngle(
      rayIndex: rayIndex,
      totalRays: totalRays,
      leftAngle: leftAngle,
      rightAngle: rightAngle,
    );

    final radius = distance * pixelsPerMeter;
    final pointX = centerX + radius * math.cos(angle);
    final pointY = originY - radius * math.sin(angle);

    return Offset(pointX, pointY);
  }

  /// Вычисление позиции для подписи луча
  static Offset calculateRayLabelPosition({
    required int rayIndex,
    required int totalRays,
    required double leftAngle,
    required double rightAngle,
    required Size screenSize,
    required double maxDistance,
  }) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 5;

    final angle = calculateRayAngle(
      rayIndex: rayIndex,
      totalRays: totalRays,
      leftAngle: leftAngle,
      rightAngle: rightAngle,
    );

    double labelY = 50.0;
    final rayAtLabelY = (originY - labelY);
    double labelX = centerX + rayAtLabelY / math.tan(angle);

    // Индивидуальные корректировки для каждого луча
    switch (rayIndex) {
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

    return Offset(labelX, labelY);
  }

  /// Проверка попадания точки в область маркера
  static bool isPointInMarker({
    required Offset point,
    required Offset markerCenter,
    double markerRadius = 20.0,
  }) {
    return (markerCenter - point).distance <= markerRadius;
  }

  /// Конвертация старых типов маркеров в новые (для совместимости)
  static String convertLegacyMarkerType(String? type) {
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

  /// Валидация позиции маркера
  static bool isValidMarkerPosition({
    required int rayIndex,
    required double distance,
    required int totalRays,
    required double maxDistance,
  }) {
    return rayIndex >= 0 &&
        rayIndex < totalRays &&
        distance >= 0 &&
        distance <= maxDistance;
  }

  /// Вычисление видимых границ карты
  static Rect calculateMapBounds({
    required Size screenSize,
    required double maxDistance,
  }) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 5;
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);
    final radius = maxDistance * pixelsPerMeter;

    return Rect.fromCenter(
      center: Offset(centerX, originY),
      width: radius * 2,
      height: radius,
    );
  }
}