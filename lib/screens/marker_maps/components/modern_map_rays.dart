// Путь: lib/screens/marker_maps/components/modern_map_rays.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🚀 ОПТИМИЗИРОВАННЫЕ лучи карты
/// Заменяет 5 отдельных CustomPaint виджетов ОДНИМ!
class ModernMapRays extends StatelessWidget {
  final int rayCount;
  final double maxDistance;
  final double leftAngle;
  final double rightAngle;
  final Size screenSize;
  final List<bool> rayVisibility;

  const ModernMapRays({
    super.key,
    required this.rayCount,
    required this.maxDistance,
    required this.leftAngle,
    required this.rightAngle,
    required this.screenSize,
    required this.rayVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 20;
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);
    final rayLength = maxDistance * pixelsPerMeter;

    return RepaintBoundary(
      child: CustomPaint(
        size: screenSize,
        painter: _OptimizedRaysPainter(
          rayCount: rayCount,
          centerX: centerX,
          originY: originY,
          rayLength: rayLength,
          leftAngle: leftAngle,
          rightAngle: rightAngle,
          rayVisibility: rayVisibility,
        ),
      ),
    );
  }
}

/// 🚀 ЕДИНЫЙ Painter для ВСЕХ лучей
class _OptimizedRaysPainter extends CustomPainter {
  final int rayCount;
  final double centerX;
  final double originY;
  final double rayLength;
  final double leftAngle;
  final double rightAngle;
  final List<bool> rayVisibility;

  // 🔥 КЭШИРОВАННЫЕ углы для производительности
  static final Map<String, double> _angleCache = {};

  _OptimizedRaysPainter({
    required this.rayCount,
    required this.centerX,
    required this.originY,
    required this.rayLength,
    required this.leftAngle,
    required this.rightAngle,
    required this.rayVisibility,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 🚀 РИСУЕМ ВСЕ ЛУЧИ В ОДНОМ МЕТОДЕ
    for (int i = 0; i < rayCount; i++) {
      // Проверяем видимость луча
      if (!_shouldShowRay(i)) continue;

      final angle = _getCachedRayAngle(i);
      final endX = centerX + rayLength * math.cos(angle);
      final endY = originY - rayLength * math.sin(angle);

      // Рисуем линию луча
      canvas.drawLine(
        Offset(centerX, originY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  /// 🔥 Проверка видимости луча
  bool _shouldShowRay(int rayIndex) {
    if (rayIndex < 0 || rayIndex >= rayVisibility.length) {
      return true; // По умолчанию показываем если индекс некорректный
    }
    return rayVisibility[rayIndex];
  }

  /// 🔥 КЭШИРОВАННОЕ вычисление угла луча
  double _getCachedRayAngle(int rayIndex) {
    final key = '$rayIndex-$leftAngle-$rightAngle-$rayCount';

    return _angleCache.putIfAbsent(key, () {
      final totalAngle = leftAngle - rightAngle;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = leftAngle - (rayIndex * angleStep);
      return angleDegrees * (math.pi / 180);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _OptimizedRaysPainter &&
        other.rayCount == rayCount &&
        other.leftAngle == leftAngle &&
        other.rightAngle == rightAngle &&
        _listEquals(other.rayVisibility, rayVisibility);
  }

  @override
  int get hashCode {
    return Object.hash(rayCount, leftAngle, rightAngle, rayVisibility);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 🧹 Статический метод для очистки кэша
  static void clearCache() {
    _angleCache.clear();
  }
}