// Путь: lib/screens/marker_maps/components/modern_marker_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Современный виджет отдельного маркера
/// Включает анимации, тактильную обратную связь и современные эффекты
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

class _ModernMarkerWidgetState extends State<ModernMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Настройка анимаций
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Запускаем анимацию появления
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Тактильная обратная связь
    HapticFeedback.lightImpact();

    // Анимация нажатия
    _animationController.reset();
    _animationController.forward();

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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (_isPressed ? 0.9 : 1.0),
          child: GestureDetector(
            onTap: _handleTap,
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: () => _handleTapUp(),
            // 🎯 ОПТИМАЛЬНАЯ область нажатия 24x24 (удобно, но без перекрытий)
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Основной маркер 14x14
                  Container(
                    width: 14,
                    height: 14,
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
                    child: Icon(
                      widget.icon,
                      color: Colors.black87,
                      size: 8,
                    ),
                  ),

                  // Подпись глубины (если есть)
                  if (depth != null)
                    Positioned(
                      left: 16, // Справа от маркера (чуть ближе из-за меньшей области)
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade300.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${depth.toStringAsFixed(1)}м',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}