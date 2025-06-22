// Путь: lib/widgets/responsive/responsive_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/responsive_constants.dart';

/// Типы адаптивных кнопок
enum ResponsiveButtonType {
  primary,     // ElevatedButton стиль
  secondary,   // OutlinedButton стиль
  text,        // TextButton стиль
  icon,        // IconButton стиль
  floating,    // FloatingActionButton стиль
}

/// Размеры кнопок
enum ResponsiveButtonSize {
  small,    // Компактные кнопки
  medium,   // Стандартные кнопки
  large,    // Увеличенные кнопки
  outdoor,  // Для использования на рыбалке (в перчатках)
}

/// Адаптивная кнопка с поддержкой accessibility и специальных размеров
class ResponsiveButton extends StatefulWidget {
  /// Текст кнопки
  final String? text;

  /// Иконка кнопки
  final IconData? icon;

  /// Виджет вместо текста (для кастомного контента)
  final Widget? child;

  /// Callback при нажатии
  final VoidCallback? onPressed;

  /// Тип кнопки
  final ResponsiveButtonType type;

  /// Размер кнопки
  final ResponsiveButtonSize size;

  /// Ширина кнопки (null = адаптивная ширина)
  final double? width;

  /// Высота кнопки (null = адаптивная высота)
  final double? height;

  /// Кастомные цвета
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  /// Радиус скругления (null = адаптивный)
  final double? borderRadius;

  /// Отступы внутри кнопки
  final EdgeInsetsGeometry? padding;

  /// Elevation (для primary кнопок)
  final double? elevation;

  /// Показать ли loading состояние
  final bool isLoading;

  /// Виджет для loading состояния
  final Widget? loadingWidget;

  /// Семантическая метка для accessibility
  final String? semanticLabel;

  /// Подсказка для accessibility
  final String? tooltip;

  /// Включить ли haptic feedback
  final bool enableHapticFeedback;

  /// Кастомная анимация нажатия
  final bool enablePressAnimation;

  /// Автоматически расширить кнопку на всю ширину
  final bool expandToFillWidth;

  const ResponsiveButton({
    super.key,
    this.text,
    this.icon,
    this.child,
    required this.onPressed,
    this.type = ResponsiveButtonType.primary,
    this.size = ResponsiveButtonSize.medium,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.isLoading = false,
    this.loadingWidget,
    this.semanticLabel,
    this.tooltip,
    this.enableHapticFeedback = true,
    this.enablePressAnimation = true,
    this.expandToFillWidth = false,
  }) : assert(
  text != null || icon != null || child != null,
  'ResponsiveButton должна иметь text, icon или child',
  );

  @override
  State<ResponsiveButton> createState() => _ResponsiveButtonState();
}

class _ResponsiveButtonState extends State<ResponsiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: ResponsiveConstants.buttonPressAnimation,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (widget.enablePressAnimation && widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp() {
    if (widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onPressed?.call();
  }

  // Получение размеров кнопки в зависимости от size и context
  ({double width, double height}) _getButtonDimensions(BuildContext context) {
    double height;
    double width;

    switch (widget.size) {
      case ResponsiveButtonSize.small:
        height = ResponsiveConstants.buttonHeightSmall;
        width = ResponsiveUtils.getResponsiveValue(context, mobile: 120, tablet: 140);
        break;
      case ResponsiveButtonSize.medium:
        height = ResponsiveUtils.getButtonHeight(context);
        width = MediaQuery.of(context).size.width * ResponsiveUtils.getButtonWidthPercent(context);
        break;
      case ResponsiveButtonSize.large:
        height = ResponsiveConstants.buttonHeightLarge;
        width = MediaQuery.of(context).size.width * ResponsiveUtils.getButtonWidthPercent(context);
        break;
      case ResponsiveButtonSize.outdoor:
        height = ResponsiveUtils.getButtonHeight(context, isOutdoorUse: true);
        width = MediaQuery.of(context).size.width * ResponsiveUtils.getButtonWidthPercent(context);
        break;
    }

    // Ограничиваем максимальную ширину на планшетах
    final maxWidth = ResponsiveUtils.getMaxButtonWidth(context);
    if (width > maxWidth) {
      width = maxWidth;
    }

    return (width: width, height: height);
  }

  // Получение стилей в зависимости от типа кнопки
  ButtonStyle _getButtonStyle(BuildContext context) {
    final dimensions = _getButtonDimensions(context);
    final theme = Theme.of(context);

    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(
          widget.width ?? (widget.expandToFillWidth ? double.infinity : dimensions.width),
          widget.height ?? dimensions.height,
        ),
      ),
      padding: WidgetStateProperty.all(
        widget.padding ?? EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: ResponsiveConstants.spacingM,
            tablet: ResponsiveConstants.spacingL,
          ),
          vertical: ResponsiveConstants.spacingS,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? ResponsiveUtils.getBorderRadius(
              context,
              baseRadius: ResponsiveConstants.radiusM,
            ),
          ),
        ),
      ),
    );

    switch (widget.type) {
      case ResponsiveButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.primary.withOpacity(ResponsiveConstants.opacityDisabled);
            }
            return widget.backgroundColor ?? theme.colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.all(
            widget.foregroundColor ?? theme.colorScheme.onPrimary,
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return (widget.elevation ?? ResponsiveConstants.elevationMedium) / 2;
            }
            return widget.elevation ?? ResponsiveConstants.elevationMedium;
          }),
        );

      case ResponsiveButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.primary.withOpacity(ResponsiveConstants.opacityDisabled);
            }
            return widget.foregroundColor ?? theme.colorScheme.primary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? theme.colorScheme.primary.withOpacity(ResponsiveConstants.opacityDisabled)
                : widget.borderColor ?? theme.colorScheme.primary;
            return BorderSide(color: color);
          }),
        );

      case ResponsiveButtonType.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.primary.withOpacity(ResponsiveConstants.opacityDisabled);
            }
            return widget.foregroundColor ?? theme.colorScheme.primary;
          }),
          elevation: WidgetStateProperty.all(0),
        );

      case ResponsiveButtonType.icon:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(ResponsiveConstants.opacityDisabled);
            }
            return widget.foregroundColor ?? theme.colorScheme.onSurface;
          }),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(const CircleBorder()),
        );

      case ResponsiveButtonType.floating:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.secondary.withOpacity(ResponsiveConstants.opacityDisabled);
            }
            return widget.backgroundColor ?? theme.colorScheme.secondary;
          }),
          foregroundColor: WidgetStateProperty.all(
            widget.foregroundColor ?? theme.colorScheme.onSecondary,
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return (widget.elevation ?? ResponsiveConstants.elevationMedium) * 1.5;
            }
            return widget.elevation ?? ResponsiveConstants.elevationMedium;
          }),
          shape: WidgetStateProperty.all(const CircleBorder()),
        );
    }
  }

  // Создание контента кнопки
  Widget _buildButtonContent(BuildContext context) {
    if (widget.isLoading) {
      return widget.loadingWidget ?? SizedBox(
        width: ResponsiveUtils.getIconSize(context, baseSize: 20),
        height: ResponsiveUtils.getIconSize(context, baseSize: 20),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (widget.child != null) {
      return widget.child!;
    }

    if (widget.icon != null && widget.text != null) {
      // Кнопка с иконкой и текстом
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: ResponsiveUtils.getIconSize(context),
          ),
          SizedBox(width: ResponsiveConstants.spacingS),
          Flexible(
            child: Text(
              widget.text!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: ResponsiveUtils.getOptimalFontSize(
                  context,
                  widget.size == ResponsiveButtonSize.outdoor ? 18 : 16,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (widget.icon != null) {
      // Только иконка
      return Icon(
        widget.icon,
        size: ResponsiveUtils.getIconSize(context),
      );
    }

    // Только текст
    return Text(
      widget.text!,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          widget.size == ResponsiveButtonSize.outdoor ? 18 : 16,
        ),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildButton(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final content = _buildButtonContent(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget button;

    switch (widget.type) {
      case ResponsiveButtonType.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? _handleTap : null,
          style: buttonStyle,
          child: content,
        );
        break;

      case ResponsiveButtonType.secondary:
        button = OutlinedButton(
          onPressed: isEnabled ? _handleTap : null,
          style: buttonStyle,
          child: content,
        );
        break;

      case ResponsiveButtonType.text:
        button = TextButton(
          onPressed: isEnabled ? _handleTap : null,
          style: buttonStyle,
          child: content,
        );
        break;

      case ResponsiveButtonType.icon:
        button = IconButton(
          onPressed: isEnabled ? _handleTap : null,
          style: buttonStyle,
          icon: content,
        );
        break;

      case ResponsiveButtonType.floating:
        button = FloatingActionButton(
          onPressed: isEnabled ? _handleTap : null,
          backgroundColor: buttonStyle.backgroundColor?.resolve({}),
          foregroundColor: buttonStyle.foregroundColor?.resolve({}),
          elevation: buttonStyle.elevation?.resolve({}),
          child: content,
        );
        break;
    }

    // Добавляем анимацию нажатия
    if (widget.enablePressAnimation) {
      button = GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapUp,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          ),
        ),
      );
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton(context);

    // Добавляем Semantics для accessibility
    if (widget.semanticLabel != null || widget.tooltip != null) {
      button = Semantics(
        label: widget.semanticLabel ?? widget.text,
        hint: widget.tooltip,
        button: true,
        enabled: widget.onPressed != null && !widget.isLoading,
        child: button,
      );
    }

    // Добавляем Tooltip если указан
    if (widget.tooltip != null && widget.type != ResponsiveButtonType.floating) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Специализированные фабричные методы для быстрого создания кнопок
extension ResponsiveButtonFactory on ResponsiveButton {
  /// Создать primary кнопку для основных действий
  static ResponsiveButton primary({
    Key? key,
    required String text,
    IconData? icon,
    required VoidCallback? onPressed,
    ResponsiveButtonSize size = ResponsiveButtonSize.medium,
    bool isLoading = false,
    String? semanticLabel,
    bool expandToFillWidth = true,
  }) {
    return ResponsiveButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      type: ResponsiveButtonType.primary,
      size: size,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      expandToFillWidth: expandToFillWidth,
    );
  }

  /// Создать кнопку для использования на рыбалке (увеличенные размеры)
  static ResponsiveButton outdoor({
    Key? key,
    required String text,
    IconData? icon,
    required VoidCallback? onPressed,
    ResponsiveButtonType type = ResponsiveButtonType.primary,
    bool isLoading = false,
    String? semanticLabel,
  }) {
    return ResponsiveButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      type: type,
      size: ResponsiveButtonSize.outdoor,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      expandToFillWidth: true,
    );
  }

  /// Создать иконочную кнопку
  static ResponsiveButton icon({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    ResponsiveButtonSize size = ResponsiveButtonSize.medium,
    String? tooltip,
    String? semanticLabel,
  }) {
    return ResponsiveButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      type: ResponsiveButtonType.icon,
      size: size,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
    );
  }

  /// Создать floating action button
  static ResponsiveButton floating({
    Key? key,
    IconData? icon,
    Widget? child,
    required VoidCallback? onPressed,
    String? tooltip,
    String? semanticLabel,
  }) {
    return ResponsiveButton(
      key: key,
      icon: icon,
      child: child,
      onPressed: onPressed,
      type: ResponsiveButtonType.floating,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
    );
  }
}