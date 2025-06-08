// Путь: lib/widgets/center_button_tooltip.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';

class CenterButtonTooltip extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismiss;

  const CenterButtonTooltip({
    super.key,
    required this.child,
    this.onDismiss,
  });

  @override
  State<CenterButtonTooltip> createState() => _CenterButtonTooltipState();
}

class _CenterButtonTooltipState extends State<CenterButtonTooltip>
    with TickerProviderStateMixin {
  bool _showTooltip = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const String _tooltipShownKey = 'center_button_tooltip_shown';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkIfShouldShowTooltip();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkIfShouldShowTooltip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_tooltipShownKey) ?? false;

      if (!hasShown) {
        // Показываем подсказку через 2 секунды после загрузки экрана
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _showTooltip = true;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('Ошибка при проверке подсказки: $e');
    }
  }

  Future<void> _hideTooltip() async {
    try {
      await _animationController.reverse();

      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }

      // Сохраняем, что подсказка была показана
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tooltipShownKey, true);

      widget.onDismiss?.call();
    } catch (e) {
      debugPrint('Ошибка при скрытии подсказки: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showTooltip)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideTooltip,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Stack(
                  children: [
                    // Подсказка-балун
                    Positioned(
                      bottom: 140, // Выше центральной кнопки
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: _buildTooltipBalloon(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Стрелочка, указывающая на кнопку
                    Positioned(
                      bottom: 120, // Между балуном и кнопкой
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: CustomPaint(
                                size: const Size(20, 20),
                                painter: ArrowPainter(
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTooltipBalloon() {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: const BoxConstraints(maxWidth: 300), // Ограничиваем ширину
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка рыбки
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 30,
              height: 30,
            ),
          ),

          const SizedBox(height: 12),

          // Основной текст
          Text(
            localizations.translate('center_button_tooltip_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Ограничиваем количество строк
            overflow: TextOverflow.ellipsis, // Обрезаем если не помещается
          ),

          const SizedBox(height: 8),

          // Описание
          Text(
            localizations.translate('center_button_tooltip_description'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 3, // Ограничиваем количество строк
            overflow: TextOverflow.ellipsis, // Обрезаем если не помещается
          ),

          const SizedBox(height: 16),

          // Кнопка "Понятно"
          GestureDetector(
            onTap: _hideTooltip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                localizations.translate('got_it'),
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1, // Одна строка для кнопки
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Кастомный painter для стрелочки
class ArrowPainter extends CustomPainter {
  final Color color;

  ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Создаем треугольную стрелочку, указывающую вниз
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}