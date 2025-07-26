// Путь: lib/screens/marker_maps/components/modern_map_grid.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Современная сетка концентрических окружностей
/// Заменяет Canvas дуги на Stack из Container с borders
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
    final originY = screenSize.height - 20; // 🔥 ИСПРАВЛЕНО: отступ от низа экрана
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    return RepaintBoundary(
      child: Stack(
        children: [
          // Генерируем концентрические полукруги
          for (int distance = 10; distance <= maxDistance.toInt(); distance += 10)
            _buildGridCircle(
              centerX: centerX,
              originY: originY,
              distance: distance,
              pixelsPerMeter: pixelsPerMeter,
            ),
        ],
      ),
    );
  }

  /// Построение одного полукруга сетки с пунктиром
  Widget _buildGridCircle({
    required double centerX,
    required double originY,
    required int distance,
    required double pixelsPerMeter,
  }) {
    final radius = distance * pixelsPerMeter;

    return Positioned(
      left: centerX - radius,
      top: originY - radius,
      child: CustomPaint(
        size: Size(radius * 2, radius * 2),
        painter: _DashedCirclePainter(
          radius: radius,
          color: Colors.white.withOpacity(0.3),
          strokeWidth: 1.0,
          dashLength: 3.0, // 🔥 МЕЛКИЙ пунктир
          gapLength: 3.0,
        ),
      ),
    );
  }
}

/// 🔥 ДОБАВИЛИ: Painter для пунктирных полукругов
class _DashedCirclePainter extends CustomPainter {
  final double radius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(radius, radius);

    // Рисуем только нижнюю половину окружности (полукруг) пунктиром
    final path = Path();

    // Вычисляем общую длину полукруга
    final semicircleLength = math.pi * radius;
    final dashCount = (semicircleLength / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = math.pi + (i * (dashLength + gapLength) / radius);
      final endAngle = math.pi + ((i * (dashLength + gapLength) + dashLength) / radius);

      if (endAngle > 2 * math.pi) break;

      final startX = center.dx + radius * math.cos(startAngle);
      final startY = center.dy + radius * math.sin(startAngle);
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      path.moveTo(startX, startY);
      path.arcToPoint(
        Offset(endX, endY),
        radius: Radius.circular(radius),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}