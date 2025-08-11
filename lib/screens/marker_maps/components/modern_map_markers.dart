// Путь: lib/screens/marker_maps/components/modern_map_markers.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'modern_marker_widget.dart';

/// Современные маркеры карты
/// Заменяет Canvas отрисовку на AnimatedPositioned с Hero анимациями
class ModernMapMarkers extends StatelessWidget {
  final List<Map<String, dynamic>> markers;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final Function(Map<String, dynamic>) onMarkerTap;
  final double maxDistance;
  final int rayCount;
  final double leftAngle;
  final double rightAngle;
  final Size screenSize;
  final List<bool> rayVisibility; // 🔥 НОВЫЙ ПАРАМЕТР для видимости лучей

  const ModernMapMarkers({
    super.key,
    required this.markers,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.onMarkerTap,
    required this.maxDistance,
    required this.rayCount,
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

    return RepaintBoundary(
      child: Stack(
        children: [
          // Генерируем маркеры с анимациями
          for (final marker in markers)
          // 🔥 НОВАЯ ПРОВЕРКА ВИДИМОСТИ - показываем маркер только если луч видим
            if (_shouldShowMarker(marker))
              _buildAnimatedMarker(
                marker: marker,
                centerX: centerX,
                originY: originY,
                pixelsPerMeter: pixelsPerMeter,
              ),
        ],
      ),
    );
  }

  /// 🔥 НОВЫЙ МЕТОД - Проверка нужно ли показывать маркер
  bool _shouldShowMarker(Map<String, dynamic> marker) {
    final rayIndex = (marker['rayIndex'] as double? ?? 0).toInt();

    // Проверяем корректность индекса луча
    if (rayIndex < 0 || rayIndex >= rayVisibility.length) {
      return true; // По умолчанию показываем если индекс некорректный
    }

    // Показываем маркер только если луч видим
    return rayVisibility[rayIndex];
  }

  /// Построение анимированного маркера
  Widget _buildAnimatedMarker({
    required Map<String, dynamic> marker,
    required double centerX,
    required double originY,
    required double pixelsPerMeter,
  }) {
    final rayIndex = (marker['rayIndex'] as double? ?? 0).toInt();
    final distance = marker['distance'] as double? ?? 0;

    // Проверяем корректность индекса луча
    if (rayIndex >= rayCount || rayIndex < 0) {
      return const SizedBox.shrink();
    }

    // Вычисляем позицию маркера
    final angle = _calculateRayAngle(rayIndex);
    final ratio = distance / maxDistance;
    final maxRayLength = maxDistance * pixelsPerMeter;

    final dx = centerX + maxRayLength * ratio * math.cos(angle);
    final dy = originY - maxRayLength * ratio * math.sin(angle);

    // Определяем цвет маркера (конвертация старых типов)
    String bottomType = marker['bottomType'] ?? 'default';
    if (bottomType == 'default' && marker['type'] != null) {
      switch (marker['type']) {
        case 'dropoff':
          bottomType = 'бугор';
          break;
        case 'weed':
          bottomType = 'трава_водоросли';
          break;
        case 'sandbar':
          bottomType = 'ровно_твердо';
          break;
        case 'structure':
          bottomType = 'зацеп';
          break;
        default:
          bottomType = 'ил';
      }
    }

    final markerColor = bottomTypeColors[bottomType] ?? Colors.blue;
    final markerIcon = bottomTypeIcons[bottomType] ?? Icons.location_on;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: dx - 12, // 🎯 ИСПРАВЛЕНО: центрирование для области 24x24 (24/2 = 12)
      top: dy - 12,  // 🎯 ИСПРАВЛЕНО: центрирование для области 24x24 (24/2 = 12)
      child: Hero(
        tag: marker['id'] ?? 'marker_${rayIndex}_$distance',
        child: ModernMarkerWidget(
          marker: marker,
          color: markerColor,
          icon: markerIcon,
          onTap: () => onMarkerTap(marker),
        ),
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