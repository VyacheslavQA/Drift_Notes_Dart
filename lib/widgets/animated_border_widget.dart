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
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

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
            painter: SmoothAnimatedBorderPainter(
              progress: _animation.value,
              borderWidth: widget.borderWidth,
              borderRadius: widget.borderRadius,
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

/// Улучшенный кастомный painter с плавной анимацией
class SmoothAnimatedBorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final double borderRadius;
  final Color glowColor;
  final Color baseColor;
  final double glowSize;
  final double glowIntensity;
  final bool isEnabled;

  SmoothAnimatedBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
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
      Radius.circular(borderRadius),
    );

    // Базовая рамка (статичная)
    final Paint basePaint =
        Paint()
          ..color = baseColor.withValues(alpha: isEnabled ? 0.6 : 0.5)
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(borderRect, basePaint);

    if (!isEnabled) return;

    // Рассчитываем плавную позицию свечения по периметру
    final glowPosition = _calculateSmoothGlowPosition(size, progress);

    // Создаем множественные слои свечения для лучшего эффекта
    _drawGlowLayers(canvas, size, borderRect, glowPosition);
  }

  /// Рассчитывает плавную позицию свечения по периметру прямоугольника
  Offset _calculateSmoothGlowPosition(Size size, double progress) {
    // Используем sinusoidal функции для более плавного движения
    final smoothProgress =
        (math.sin(progress * 2 * math.pi - math.pi / 2) + 1) / 2;

    final width = size.width - borderWidth;
    final height = size.height - borderWidth;
    final cornerRadius = borderRadius;

    // Рассчитываем периметр с учетом скругленных углов
    final straightWidth = width - 2 * cornerRadius;
    final straightHeight = height - 2 * cornerRadius;
    final cornerPerimeter = 2 * math.pi * cornerRadius;
    final totalPerimeter =
        2 * straightWidth + 2 * straightHeight + cornerPerimeter;

    final currentDistance = smoothProgress * totalPerimeter;

    // Определяем, на какой стороне/углу находится свечение
    double x, y;

    if (currentDistance <= straightWidth) {
      // Верхняя сторона
      x = cornerRadius + currentDistance;
      y = borderWidth / 2;
    } else if (currentDistance <= straightWidth + math.pi * cornerRadius / 2) {
      // Правый верхний угол
      final angleProgress =
          (currentDistance - straightWidth) / (math.pi * cornerRadius / 2);
      final angle = -math.pi / 2 + angleProgress * math.pi / 2;
      x = width - cornerRadius + cornerRadius * math.cos(angle);
      y = cornerRadius + cornerRadius * math.sin(angle);
    } else if (currentDistance <=
        straightWidth + math.pi * cornerRadius / 2 + straightHeight) {
      // Правая сторона
      final sideProgress =
          currentDistance - straightWidth - math.pi * cornerRadius / 2;
      x = width - borderWidth / 2;
      y = cornerRadius + sideProgress;
    } else if (currentDistance <=
        straightWidth + math.pi * cornerRadius + straightHeight) {
      // Правый нижний угол
      final angleStart =
          straightWidth + math.pi * cornerRadius / 2 + straightHeight;
      final angleProgress =
          (currentDistance - angleStart) / (math.pi * cornerRadius / 2);
      final angle = angleProgress * math.pi / 2;
      x = width - cornerRadius + cornerRadius * math.cos(angle);
      y = height - cornerRadius + cornerRadius * math.sin(angle);
    } else if (currentDistance <=
        2 * straightWidth + math.pi * cornerRadius + straightHeight) {
      // Нижняя сторона
      final sideStart = straightWidth + math.pi * cornerRadius + straightHeight;
      final sideProgress = currentDistance - sideStart;
      x = width - cornerRadius - sideProgress;
      y = height - borderWidth / 2;
    } else if (currentDistance <=
        2 * straightWidth + 3 * math.pi * cornerRadius / 2 + straightHeight) {
      // Левый нижний угол
      final angleStart =
          2 * straightWidth + math.pi * cornerRadius + straightHeight;
      final angleProgress =
          (currentDistance - angleStart) / (math.pi * cornerRadius / 2);
      final angle = math.pi / 2 + angleProgress * math.pi / 2;
      x = cornerRadius + cornerRadius * math.cos(angle);
      y = height - cornerRadius + cornerRadius * math.sin(angle);
    } else if (currentDistance <=
        2 * straightWidth +
            3 * math.pi * cornerRadius / 2 +
            2 * straightHeight) {
      // Левая сторона
      final sideStart =
          2 * straightWidth + 3 * math.pi * cornerRadius / 2 + straightHeight;
      final sideProgress = currentDistance - sideStart;
      x = borderWidth / 2;
      y = height - cornerRadius - sideProgress;
    } else {
      // Левый верхний угол
      final angleStart =
          2 * straightWidth +
          3 * math.pi * cornerRadius / 2 +
          2 * straightHeight;
      final angleProgress =
          (currentDistance - angleStart) / (math.pi * cornerRadius / 2);
      final angle = math.pi + angleProgress * math.pi / 2;
      x = cornerRadius + cornerRadius * math.cos(angle);
      y = cornerRadius + cornerRadius * math.sin(angle);
    }

    return Offset(x.clamp(0, size.width), y.clamp(0, size.height));
  }

  /// Рисует множественные слои свечения для лучшего эффекта
  void _drawGlowLayers(
    Canvas canvas,
    Size size,
    RRect borderRect,
    Offset glowCenter,
  ) {
    // Внешнее свечение (самое размытое)
    final Paint outerGlowPaint =
        Paint()
          ..shader = _createRadialGlowGradient(glowCenter, glowSize * 1.5, 0.3)
          ..strokeWidth = borderWidth * 3.5
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSize * 0.8);

    canvas.drawRRect(borderRect, outerGlowPaint);

    // Среднее свечение
    final Paint middleGlowPaint =
        Paint()
          ..shader = _createRadialGlowGradient(glowCenter, glowSize, 0.6)
          ..strokeWidth = borderWidth * 2.5
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize * 0.4);

    canvas.drawRRect(borderRect, middleGlowPaint);

    // Внутреннее свечение (самое яркое)
    final Paint innerGlowPaint =
        Paint()
          ..shader = _createRadialGlowGradient(
            glowCenter,
            glowSize * 0.6,
            glowIntensity,
          )
          ..strokeWidth = borderWidth * 1.8
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize * 0.2);

    canvas.drawRRect(borderRect, innerGlowPaint);

    // Основная яркая линия
    final Paint corePaint =
        Paint()
          ..shader = _createRadialGlowGradient(glowCenter, glowSize * 0.3, 1.0)
          ..strokeWidth = borderWidth * 1.2
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(borderRect, corePaint);
  }

  /// Создает радиальный градиент для свечения
  Shader _createRadialGlowGradient(
    Offset center,
    double radius,
    double intensity,
  ) {
    return RadialGradient(
      center: Alignment.topLeft,
      focal: Alignment.topLeft,
      focalRadius: 0.1,
      radius: 2.0,
      colors: [
        glowColor.withValues(alpha: intensity),
        glowColor.withValues(alpha: intensity * 0.8),
        glowColor.withValues(alpha: intensity * 0.4),
        glowColor.withValues(alpha: intensity * 0.1),
        glowColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      transform: GradientRotation(math.atan2(center.dy, center.dx)),
    ).createShader(Rect.fromCircle(center: center, radius: radius));
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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
                  color: widget.color.withValues(
                    alpha: _opacityAnimation.value * 0.5,
                  ),
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
