// Путь: lib/widgets/animated_border_widget.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Виджет с анимированной светящейся обводкой, которая "бегает" по периметру
class AnimatedBorderWidget extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Color glowColor;
  final Color baseColor;
  final Duration animationDuration;
  final double glowSize;
  final double glowIntensity;
  final VoidCallback? onTap;
  final bool isEnabled;

  const AnimatedBorderWidget({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 20.0,
    this.glowColor = Colors.blue,
    this.baseColor = Colors.grey,
    this.animationDuration = const Duration(seconds: 3),
    this.glowSize = 40.0,
    this.glowIntensity = 0.8,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  State<AnimatedBorderWidget> createState() => _AnimatedBorderWidgetState();
}

class _AnimatedBorderWidgetState extends State<AnimatedBorderWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.isEnabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedBorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isEnabled != widget.isEnabled) {
      if (widget.isEnabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.dispose();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedBorderPainter(
              progress: _animation.value,
              borderWidth: widget.borderWidth,
              glowColor: widget.glowColor,
              baseColor: widget.baseColor,
              glowSize: widget.glowSize,
              glowIntensity: widget.glowIntensity,
              isEnabled: widget.isEnabled,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Кастомный painter для анимированной обводки
class AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final Color glowColor;
  final Color baseColor;
  final double glowSize;
  final double glowIntensity;
  final bool isEnabled;

  AnimatedBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.glowColor,
    required this.baseColor,
    required this.glowSize,
    required this.glowIntensity,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect borderRect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      const Radius.circular(20),
    );

    // Базовая рамка (статичная) - более яркая
    final Paint basePaint = Paint()
      ..color = baseColor.withValues(alpha: isEnabled ? 0.6 : 0.5)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(borderRect, basePaint);

    if (!isEnabled) return;

    // Анимированная светящаяся обводка
    final double perimeter = _calculatePerimeter(size);
    final double glowPosition = (progress / (2 * math.pi)) * perimeter;

    // Внешнее свечение (blur эффект)
    final Paint outerGlowPaint = Paint()
      ..shader = _createGlowGradient(size, glowPosition, perimeter)
      ..strokeWidth = borderWidth * 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSize / 2);

    canvas.drawRRect(borderRect, outerGlowPaint);

    // Основная светящаяся обводка
    final Paint glowPaint = Paint()
      ..shader = _createGlowGradient(size, glowPosition, perimeter)
      ..strokeWidth = borderWidth * 1.8
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize / 6);

    canvas.drawRRect(borderRect, glowPaint);

    // Внутренняя яркая линия для интенсивности
    final Paint innerGlowPaint = Paint()
      ..shader = _createGlowGradient(size, glowPosition, perimeter)
      ..strokeWidth = borderWidth * 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(borderRect, innerGlowPaint);
  }

  double _calculatePerimeter(Size size) {
    // Упрощенный расчет периметра прямоугольника с закругленными углами
    return 2 * (size.width + size.height - 80); // 80 = приблизительная корректировка на углы
  }

  Shader _createGlowGradient(Size size, double glowPosition, double perimeter) {
    // Определяем позицию свечения на периметре
    final double normalizedPosition = (glowPosition % perimeter) / perimeter;

    // Создаем более интенсивный sweeping gradient эффект
    final List<Color> colors = [
      glowColor.withValues(alpha: 0.0),
      glowColor.withValues(alpha: 0.1),
      glowColor.withValues(alpha: 0.4),
      glowColor.withValues(alpha: 0.8),
      glowColor.withValues(alpha: glowIntensity), // Пик свечения
      glowColor.withValues(alpha: 0.8),
      glowColor.withValues(alpha: 0.4),
      glowColor.withValues(alpha: 0.1),
      glowColor.withValues(alpha: 0.0),
    ];

    final List<double> stops = [
      (normalizedPosition - 0.2).clamp(0.0, 1.0),
      (normalizedPosition - 0.15).clamp(0.0, 1.0),
      (normalizedPosition - 0.1).clamp(0.0, 1.0),
      (normalizedPosition - 0.05).clamp(0.0, 1.0),
      normalizedPosition,
      (normalizedPosition + 0.05).clamp(0.0, 1.0),
      (normalizedPosition + 0.1).clamp(0.0, 1.0),
      (normalizedPosition + 0.15).clamp(0.0, 1.0),
      (normalizedPosition + 0.2).clamp(0.0, 1.0),
    ];

    return SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Упрощенная версия для быстрого использования
class PulseBorderWidget extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  const PulseBorderWidget({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.onTap,
  });

  @override
  State<PulseBorderWidget> createState() => _PulseBorderWidgetState();
}

class _PulseBorderWidgetState extends State<PulseBorderWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withValues(alpha: _opacityAnimation.value),
                width: 2 * _scaleAnimation.value,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _opacityAnimation.value * 0.5),
                  blurRadius: 10 * _scaleAnimation.value,
                  spreadRadius: 2 * _scaleAnimation.value,
                ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}