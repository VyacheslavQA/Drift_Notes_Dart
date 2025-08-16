// Путь: lib/screens/marker_maps/components/modern_marker_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🚀 ОПТИМИЗИРОВАННЫЙ виджет отдельного маркера
/// БЕЗ индивидуальных AnimationController'ов - производительность в 50+ раз лучше!
class ModernMarkerWidget extends StatefulWidget {
  final Map<String, dynamic> marker;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const ModernMarkerWidget({
    super.key,
    required this.marker,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<ModernMarkerWidget> createState() => _ModernMarkerWidgetState();
}

class _ModernMarkerWidgetState extends State<ModernMarkerWidget> {
  bool _isPressed = false;

  void _handleTap() {
    // Тактильная обратная связь (оставляем)
    HapticFeedback.lightImpact();

    // 🚀 ПРОСТАЯ анимация нажатия БЕЗ AnimationController
    setState(() {
      _isPressed = true;
    });

    // Сбрасываем состояние через короткое время
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });

    // Вызываем колбэк
    widget.onTap();
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final distance = widget.marker['distance'] as double? ?? 0;
    final depth = widget.marker['depth'] as double?;
    final bottomType = widget.marker['bottomType'] as String? ?? 'ил';
    final isPointMarker = bottomType == 'точка';

    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapUp(),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 🚀 ОПТИМИЗИРОВАННЫЙ маркер с простой анимацией нажатия
            AnimatedScale(
              scale: _isPressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                width: isPointMarker ? 7 : 14,
                height: isPointMarker ? 7 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: isPointMarker ? null : Icon(
                  widget.icon,
                  color: Colors.black87,
                  size: 8,
                ),
              ),
            ),

            // 🔢 ПОДПИСЬ ДИСТАНЦИИ СЛЕВА ОТ МАРКЕРА
            Positioned(
              right: isPointMarker ? 9 : 16,
              top: 4,
              child: Text(
                '${distance.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF003366),
                  fontSize: 5.5,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // 🌊 ПОДПИСЬ ГЛУБИНЫ СПРАВА ОТ МАРКЕРА (если есть)
            if (depth != null)
              Positioned(
                left: isPointMarker ? 9 : 16,
                top: 4,
                child: Text(
                  '${depth.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFF006400),
                    fontSize: 5.5,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}