// Путь: lib/widgets/responsive/responsive_container.dart

import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/responsive_constants.dart';

/// Типы адаптивных контейнеров
enum ResponsiveContainerType {
  page,           // Контейнер для целой страницы
  section,        // Контейнер для секции страницы
  card,           // Контейнер для карточки
  form,           // Контейнер для формы
  content,        // Контейнер для основного контента
  sidebar,        // Контейнер для боковой панели
  fishing,        // Специальный контейнер для рыболовного контента
}

/// Адаптивный контейнер с автоматическими отступами и ограничениями
class ResponsiveContainer extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  /// Тип контейнера (определяет стандартные настройки)
  final ResponsiveContainerType type;

  /// Максимальная ширина контейнера
  final double? maxWidth;

  /// Минимальная ширина контейнера
  final double? minWidth;

  /// Максимальная высота контейнера
  final double? maxHeight;

  /// Минимальная высота контейнера
  final double? minHeight;

  /// Отступы внутри контейнера
  final EdgeInsetsGeometry? padding;

  /// Отступы снаружи контейнера
  final EdgeInsetsGeometry? margin;

  /// Выравнивание контента
  final AlignmentGeometry? alignment;

  /// Цвет фона
  final Color? backgroundColor;

  /// Декорация контейнера
  final BoxDecoration? decoration;

  /// Ширина (null = адаптивная)
  final double? width;

  /// Высота (null = адаптивная)
  final double? height;

  /// Использовать ли Safe Area
  final bool useSafeArea;

  /// Добавить ли стандартные горизонтальные отступы
  final bool addHorizontalPadding;

  /// Добавить ли стандартные вертикальные отступы
  final bool addVerticalPadding;

  /// Центрировать ли контейнер
  final bool centerContent;

  /// Ограничить ли ширину на планшетах
  final bool constrainWidth;

  /// Кастомные breakpoint настройки
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.type = ResponsiveContainerType.content,
    this.maxWidth,
    this.minWidth,
    this.maxHeight,
    this.minHeight,
    this.padding,
    this.margin,
    this.alignment,
    this.backgroundColor,
    this.decoration,
    this.width,
    this.height,
    this.useSafeArea = false,
    this.addHorizontalPadding = true,
    this.addVerticalPadding = false,
    this.centerContent = false,
    this.constrainWidth = true,
    this.mobilePadding,
    this.tabletPadding,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем конфигурацию для типа контейнера
    final config = _getConfigForType(context);

    // Рассчитываем финальные параметры
    final finalPadding = _calculatePadding(context, config);
    final finalMargin = _calculateMargin(context, config);
    final finalMaxWidth = _calculateMaxWidth(context, config);
    final finalAlignment = alignment ?? (centerContent ? Alignment.center : null);
    final finalDecoration = _buildDecoration(context, config);

    Widget container = Container(
      width: width,
      height: height,
      padding: finalPadding,
      margin: finalMargin,
      alignment: finalAlignment,
      decoration: finalDecoration,
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        maxWidth: finalMaxWidth,
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );

    // Добавляем Safe Area если нужно
    if (useSafeArea) {
      container = SafeArea(child: container);
    }

    // Центрируем контейнер если нужно ограничить ширину
    if (constrainWidth && finalMaxWidth < double.infinity) {
      container = Center(child: container);
    }

    return container;
  }

  /// Получение конфигурации для типа контейнера
  _ContainerConfig _getConfigForType(BuildContext context) {
    switch (type) {
      case ResponsiveContainerType.page:
        return _ContainerConfig(
          defaultMaxWidth: double.infinity,
          defaultHorizontalPadding: ResponsiveUtils.getHorizontalPadding(context),
          defaultVerticalPadding: ResponsiveUtils.getVerticalPadding(context),
          defaultBackgroundColor: null,
          defaultElevation: 0,
          defaultBorderRadius: 0,
        );

      case ResponsiveContainerType.section:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: ResponsiveConstants.maxContentWidth,
          ),
          defaultHorizontalPadding: ResponsiveUtils.getHorizontalPadding(context),
          defaultVerticalPadding: ResponsiveConstants.spacingL,
          defaultBackgroundColor: null,
          defaultElevation: 0,
          defaultBorderRadius: 0,
        );

      case ResponsiveContainerType.card:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: ResponsiveConstants.maxCardWidth,
          ),
          defaultHorizontalPadding: ResponsiveConstants.spacingM,
          defaultVerticalPadding: ResponsiveConstants.spacingM,
          defaultBackgroundColor: Theme.of(context).cardColor,
          defaultElevation: ResponsiveConstants.elevationLow,
          defaultBorderRadius: ResponsiveUtils.getBorderRadius(
            context,
            baseRadius: ResponsiveConstants.radiusL,
          ),
        );

      case ResponsiveContainerType.form:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: ResponsiveConstants.maxFormWidth,
          ),
          defaultHorizontalPadding: ResponsiveUtils.getHorizontalPadding(context),
          defaultVerticalPadding: ResponsiveConstants.spacingL,
          defaultBackgroundColor: null,
          defaultElevation: 0,
          defaultBorderRadius: 0,
        );

      case ResponsiveContainerType.content:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: ResponsiveConstants.maxContentWidth,
          ),
          defaultHorizontalPadding: ResponsiveUtils.getHorizontalPadding(context),
          defaultVerticalPadding: 0,
          defaultBackgroundColor: null,
          defaultElevation: 0,
          defaultBorderRadius: 0,
        );

      case ResponsiveContainerType.sidebar:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: 300,
          ),
          defaultHorizontalPadding: ResponsiveConstants.spacingM,
          defaultVerticalPadding: ResponsiveConstants.spacingL,
          defaultBackgroundColor: Theme.of(context).colorScheme.surface,
          defaultElevation: ResponsiveConstants.elevationLow,
          defaultBorderRadius: 0,
        );

      case ResponsiveContainerType.fishing:
        return _ContainerConfig(
          defaultMaxWidth: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: double.infinity,
            tablet: ResponsiveConstants.maxContentWidth,
          ),
          defaultHorizontalPadding: ResponsiveConstants.outdoorPadding,
          defaultVerticalPadding: ResponsiveConstants.outdoorPadding,
          defaultBackgroundColor: Theme.of(context).cardColor,
          defaultElevation: ResponsiveConstants.elevationMedium,
          defaultBorderRadius: ResponsiveUtils.getBorderRadius(
            context,
            baseRadius: ResponsiveConstants.radiusL,
          ),
        );
    }
  }

  /// Расчет отступов внутри контейнера
  EdgeInsetsGeometry _calculatePadding(BuildContext context, _ContainerConfig config) {
    if (padding != null) return padding!;

    // Используем кастомные отступы для breakpoints если указаны
    final isTablet = ResponsiveUtils.isTablet(context);
    if (isTablet && tabletPadding != null) return tabletPadding!;
    if (!isTablet && mobilePadding != null) return mobilePadding!;

    // Собираем отступы из компонентов
    double horizontal = 0;
    double vertical = 0;

    if (addHorizontalPadding) {
      horizontal = config.defaultHorizontalPadding;
    }

    if (addVerticalPadding) {
      vertical = config.defaultVerticalPadding;
    }

    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Расчет отступов снаружи контейнера
  EdgeInsetsGeometry? _calculateMargin(BuildContext context, _ContainerConfig config) {
    return margin;
  }

  /// Расчет максимальной ширины
  double _calculateMaxWidth(BuildContext context, _ContainerConfig config) {
    if (maxWidth != null) return maxWidth!;

    // Используем кастомные максимальные ширины для breakpoints
    final isTablet = ResponsiveUtils.isTablet(context);
    if (isTablet && tabletMaxWidth != null) return tabletMaxWidth!;
    if (!isTablet && mobileMaxWidth != null) return mobileMaxWidth!;

    return config.defaultMaxWidth;
  }

  /// Создание декорации контейнера
  BoxDecoration? _buildDecoration(BuildContext context, _ContainerConfig config) {
    if (decoration != null) return decoration;

    if (backgroundColor == null &&
        config.defaultBackgroundColor == null &&
        config.defaultElevation == 0) {
      return null;
    }

    return BoxDecoration(
      color: backgroundColor ?? config.defaultBackgroundColor,
      borderRadius: config.defaultBorderRadius > 0
          ? BorderRadius.circular(config.defaultBorderRadius)
          : null,
      boxShadow: config.defaultElevation > 0
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: config.defaultElevation,
          offset: Offset(0, config.defaultElevation / 2),
        ),
      ]
          : null,
    );
  }
}

/// Конфигурация для типа контейнера
class _ContainerConfig {
  final double defaultMaxWidth;
  final double defaultHorizontalPadding;
  final double defaultVerticalPadding;
  final Color? defaultBackgroundColor;
  final double defaultElevation;
  final double defaultBorderRadius;

  const _ContainerConfig({
    required this.defaultMaxWidth,
    required this.defaultHorizontalPadding,
    required this.defaultVerticalPadding,
    this.defaultBackgroundColor,
    required this.defaultElevation,
    required this.defaultBorderRadius,
  });
}

/// Адаптивный контейнер с прокруткой
class ResponsiveScrollableContainer extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  /// Тип контейнера
  final ResponsiveContainerType type;

  /// Направление прокрутки
  final Axis scrollDirection;

  /// Контроллер прокрутки
  final ScrollController? controller;

  /// Физика прокрутки
  final ScrollPhysics? physics;

  /// Отступы для прокрутки
  final EdgeInsetsGeometry? scrollPadding;

  /// Остальные параметры ResponsiveContainer
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useSafeArea;

  const ResponsiveScrollableContainer({
    super.key,
    required this.child,
    this.type = ResponsiveContainerType.content,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.scrollPadding,
    this.maxWidth,
    this.padding,
    this.margin,
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      type: type,
      maxWidth: maxWidth,
      padding: padding,
      margin: margin,
      useSafeArea: useSafeArea,
      child: SingleChildScrollView(
        scrollDirection: scrollDirection,
        controller: controller,
        physics: physics,
        padding: scrollPadding,
        child: child,
      ),
    );
  }
}

/// Контейнер для карточек с адаптивными размерами
class ResponsiveFishingCard extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  /// Заголовок карточки
  final String? title;

  /// Подзаголовок карточки
  final String? subtitle;

  /// Действие при нажатии
  final VoidCallback? onTap;

  /// Кастомные отступы
  final EdgeInsetsGeometry? padding;

  /// Кастомная высота
  final double? height;

  /// Показывать ли тень
  final bool showElevation;

  /// Добавить ли специальные отступы для рыбалки
  final bool useOutdoorSpacing;

  const ResponsiveFishingCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onTap,
    this.padding,
    this.height,
    this.showElevation = true,
    this.useOutdoorSpacing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = ResponsiveContainer(
      type: useOutdoorSpacing ? ResponsiveContainerType.fishing : ResponsiveContainerType.card,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
        ),
        boxShadow: showElevation ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveConstants.elevationLow,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) SizedBox(height: ResponsiveConstants.spacingXS),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
          ],
          Flexible(child: child),
        ],
      ),
    );

    if (height != null) {
      cardContent = SizedBox(
        height: height,
        child: cardContent,
      );
    } else {
      // Минимальная высота для карточек рыбалки
      cardContent = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ResponsiveConstants.fishingNoteCardMinHeight,
        ),
        child: cardContent,
      );
    }

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Контейнер для фотографий с адаптивными размерами
class ResponsiveFishingPhotoContainer extends StatelessWidget {
  /// Виджет изображения
  final Widget imageWidget;

  /// Подпись к фото
  final String? caption;

  /// Действие при нажатии на фото
  final VoidCallback? onTap;

  /// Соотношение сторон (по умолчанию 16:9)
  final double aspectRatio;

  /// Максимальная ширина фото
  final double? maxWidth;

  /// Показывать ли рамку
  final bool showBorder;

  const ResponsiveFishingPhotoContainer({
    super.key,
    required this.imageWidget,
    this.caption,
    this.onTap,
    this.aspectRatio = ResponsiveConstants.photoAspectRatio,
    this.maxWidth,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final photoSize = ResponsiveUtils.getImageSize(context, aspectRatio: aspectRatio);
    final effectiveMaxWidth = maxWidth ?? photoSize.width;

    Widget photo = Container(
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
        maxHeight: effectiveMaxWidth / aspectRatio,
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          child: imageWidget,
        ),
      ),
    );

    if (showBorder) {
      photo = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        child: photo,
      );
    }

    if (onTap != null) {
      photo = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        child: photo,
      );
    }

    if (caption != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          photo,
          SizedBox(height: ResponsiveConstants.spacingS),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.spacingS),
            child: Text(
              caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 12),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      );
    }

    return photo;
  }
}

/// Фабричные методы для быстрого создания контейнеров
extension ResponsiveContainerFactory on ResponsiveContainer {
  /// Создать контейнер для страницы
  static ResponsiveContainer page({
    Key? key,
    required Widget child,
    bool useSafeArea = true,
  }) {
    return ResponsiveContainer(
      key: key,
      type: ResponsiveContainerType.page,
      useSafeArea: useSafeArea,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: child,
    );
  }

  /// Создать контейнер для карточки
  static ResponsiveContainer card({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) {
    Widget container = ResponsiveContainer(
      key: key,
      type: ResponsiveContainerType.card,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      container = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
        child: container,
      );
    }

    return container as ResponsiveContainer;
  }

  /// Создать контейнер для формы
  static ResponsiveContainer form({
    Key? key,
    required Widget child,
    bool centerContent = true,
  }) {
    return ResponsiveContainer(
      key: key,
      type: ResponsiveContainerType.form,
      centerContent: centerContent,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: child,
    );
  }
}