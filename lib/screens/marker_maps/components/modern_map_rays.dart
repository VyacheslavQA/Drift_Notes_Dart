// Путь: lib/screens/marker_maps/components/modern_map_rays.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Современные лучи карты
/// Заменяет Canvas линии на простые линии от центра до краев
class ModernMapRays extends StatelessWidget {
  final int rayCount;
  final double maxDistance;
  final double leftAngle;
  final double rightAngle;
  final Size screenSize;
  final List<bool> rayVisibility; // 🔥 НОВЫЙ ПАРАМЕТР для видимости лучей

  const ModernMapRays({
    super.key,
    required this.rayCount,
    required this.maxDistance,
    required this.leftAngle,
    required this.rightAngle,
    required this.screenSize,
    required this.rayVisibility, // 🔥 НОВЫЙ ОБЯЗАТЕЛЬНЫЙ ПАРАМЕТР
  });

  @override
  Widget build(BuildContext context) {
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 20; // 🔥 ИСПРАВЛЕНО: отступ от низа экрана
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);
    final rayLength = maxDistance * pixelsPerMeter;

    return RepaintBoundary(
      child: Stack(
        children: [
          // Генерируем лучи
          for (int i = 0; i < rayCount; i++)
          // 🔥 НОВАЯ ПРОВЕРКА ВИДИМОСТИ
            if (_shouldShowRay(i))
              _buildRayLine(
                centerX: centerX,
                originY: originY,
                rayLength: rayLength,
                rayIndex: i,
              ),
        ],
      ),
    );
  }

  /// 🔥 НОВЫЙ МЕТОД - Проверка нужно ли показывать луч
  bool _shouldShowRay(int rayIndex) {
    if (rayIndex < 0 || rayIndex >= rayVisibility.length) {
      return true; // По умолчанию показываем если индекс некорректный
    }
    return rayVisibility[rayIndex];
  }

  /// Построение одного луча от центра до края
  Widget _buildRayLine({
    required double centerX,
    required double originY,
    required double rayLength,
    required int rayIndex,
  }) {
    final angle = _calculateRayAngle(rayIndex);

    // Вычисляем конечную точку луча
    final endX = centerX + rayLength * math.cos(angle);
    final endY = originY - rayLength * math.sin(angle);

    return CustomPaint(
      size: screenSize,
      painter: _RayPainter(
        startX: centerX,
        startY: originY,
        endX: endX,
        endY: endY,
      ),
    );
  }

  /// Вычисление угла луча (та же логика что в оригинале)
  double _calculateRayAngle(int rayIndex) {
    final totalAngle = leftAngle - rightAngle;
    final angleStep = totalAngle / (rayCount - 1);
    final angleDegrees = leftAngle - (rayIndex * angleStep);
    return angleDegrees * (math.pi / 180);
  }
}

/// Простой painter для рисования одной линии
class _RayPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  _RayPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6) // 🔥 УВЕЛИЧИЛИ прозрачность для видимости
      ..strokeWidth = 1.5 // 🔥 УВЕЛИЧИЛИ толщину линии
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}