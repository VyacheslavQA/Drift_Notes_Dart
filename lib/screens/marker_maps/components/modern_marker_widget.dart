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
    final isPointMarker = bottomType == 'точка'; // 🔥 ПРОВЕРКА на маркер "точка"

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
                  // 🔥 ОБНОВЛЕННЫЙ маркер с условиями для "точка"
                  Container(
                    width: isPointMarker ? 7 : 14, // 🔥 В 2 раза меньше для "точка"
                    height: isPointMarker ? 7 : 14, // 🔥 В 2 раза меньше для "точка"
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
                    // 🔥 УБИРАЕМ ИКОНКУ для маркера "точка"
                    child: isPointMarker ? null : Icon(
                      widget.icon,
                      color: Colors.black87,
                      size: 8,
                    ),
                  ),

                  // 🆕 ПОДПИСЬ ДИСТАНЦИИ СЛЕВА ОТ МАРКЕРА (темно-синий)
                  Positioned(
                    right: isPointMarker ? 9 : 16, // 🔥 Ближе для маленького маркера "точка"
                    top: 4, // Опущено еще ниже (было 2, стало 4)
                    child: Text(
                      '${distance.toInt()}', // Только цифра дистанции
                      style: const TextStyle(
                        color: Color(0xFF003366), // 🔥 Темно-синий цвет
                        fontSize: 5.5, // 🔥 Увеличили на 1 (было 4.5, стало 5.5)
                        fontWeight: FontWeight.w900, // 🔥 Максимально жирный
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.white, // 🔥 Белая тень для читаемости
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Подпись глубины справа от маркера (если есть)
                  if (depth != null)
                    Positioned(
                      left: isPointMarker ? 9 : 16, // 🔥 Ближе для маленького маркера "точка"
                      top: 4, // Опущено еще ниже (было 2, стало 4)
                      child: Text(
                        '${depth.toStringAsFixed(1)}', // 🔥 Убрали букву "м"
                        style: const TextStyle(
                          color: Color(0xFF006400), // 🔥 Темно-зеленый цвет
                          fontSize: 5.5, // 🔥 Увеличили на 1 (было 4.5, стало 5.5)
                          fontWeight: FontWeight.w900, // 🔥 Максимально жирный
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.white, // 🔥 Белая тень для читаемости
                            ),
                          ],
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