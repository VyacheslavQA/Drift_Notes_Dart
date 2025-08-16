// Путь: lib/screens/marker_maps/components/modern_map_grid.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🚀 ОПТИМИЗИРОВАННАЯ сетка концентрических окружностей
/// Заменяет 20 отдельных CustomPaint виджетов ОДНИМ!
class ModernMapGrid extends StatelessWidget {
  final double maxDistance;
  final double distanceStep;
  final Size screenSize;

  const ModernMapGrid({
    super.key,
    required this.maxDistance,
    required this.distanceStep,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 20;
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    return RepaintBoundary(
      child: CustomPaint(
        size: screenSize,
        painter: _OptimizedGridPainter(
          centerX: centerX,
          originY: originY,
          maxDistance: maxDistance,
          pixelsPerMeter: pixelsPerMeter,
        ),
      ),
    );
  }
}

/// 🚀 ЕДИНЫЙ Painter для ВСЕХ концентрических кругов
class _OptimizedGridPainter extends CustomPainter {
  final double centerX;
  final double originY;
  final double maxDistance;
  final double pixelsPerMeter;

  _OptimizedGridPainter({
    required this.centerX,
    required this.originY,
    required this.maxDistance,
    required this.pixelsPerMeter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 🚀 РИСУЕМ ВСЕ КРУГИ В ОДНОМ МЕТОДЕ
    for (int distance = 10; distance <= maxDistance.toInt(); distance += 10) {
      final radius = distance * pixelsPerMeter;
      _drawDashedSemicircle(canvas, radius, paint);
    }
  }

  /// 🔥 ОПТИМИЗИРОВАННАЯ отрисовка пунктирного полукруга
  void _drawDashedSemicircle(Canvas canvas, double radius, Paint paint) {
    const dashLength = 3.0;
    const gapLength = 3.0;

    final semicircleLength = math.pi * radius;
    final dashCount = (semicircleLength / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = math.pi + (i * (dashLength + gapLength) / radius);
      final endAngle = math.pi + ((i * (dashLength + gapLength) + dashLength) / radius);

      if (endAngle > 2 * math.pi) break;

      final startX = centerX + radius * math.cos(startAngle);
      final startY = originY + radius * math.sin(startAngle);
      final endX = centerX + radius * math.cos(endAngle);
      final endY = originY + radius * math.sin(endAngle);

      // 🚀 РИСУЕМ ДУГУ НАПРЯМУЮ без создания Path
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, originY), radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}