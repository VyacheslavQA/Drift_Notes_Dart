// Путь: lib/widgets/responsive/responsive_builder.dart

import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/responsive_constants.dart';

/// Основной виджет для создания адаптивных макетов
/// Автоматически выбирает подходящий layout в зависимости от размера экрана
class ResponsiveBuilder extends StatelessWidget {
  /// Layout для мобильных устройств (обязательный)
  final Widget mobile;

  /// Layout для планшетов (опциональный, если не указан - используется mobile)
  final Widget? tablet;

  /// Layout для десктопов (опциональный, если не указан - используется tablet или mobile)
  final Widget? desktop;

  /// Кастомная логика определения breakpoint (опционально)
  final ScreenBreakpoint Function(BuildContext context)? breakpointBuilder;

  /// Показывать ли debug информацию в dev режиме
  final bool showDebugInfo;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.breakpointBuilder,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = breakpointBuilder?.call(context) ??
        ResponsiveUtils.getScreenBreakpoint(context);

    Widget child;

    switch (breakpoint) {
      case ScreenBreakpoint.mobileSmall:
      case ScreenBreakpoint.mobileMedium:
      case ScreenBreakpoint.mobileLarge:
        child = mobile;
        break;
      case ScreenBreakpoint.tabletSmall:
        child = tablet ?? mobile;
        break;
      case ScreenBreakpoint.tabletLarge:
        child = desktop ?? tablet ?? mobile;
        break;
    }

    // В debug режиме добавляем информацию о текущем breakpoint
    if (showDebugInfo && ResponsiveConstants.enableResponsiveDebug) {
      return _buildWithDebugInfo(context, child, breakpoint);
    }

    return child;
  }

  Widget _buildWithDebugInfo(BuildContext context, Widget child, ScreenBreakpoint breakpoint) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            color: ResponsiveConstants.debugBorderColor.withOpacity(0.8),
            child: Text(
              breakpoint.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет для создания адаптивных значений на основе breakpoints
class ResponsiveValue<T> extends StatelessWidget {
  /// Значение для мобильных устройств (обязательное)
  final T mobile;

  /// Значение для планшетов (опциональное)
  final T? tablet;

  /// Значение для десктопов (опциональное)
  final T? desktop;

  /// Кастомные значения для каждого breakpoint
  final T? mobileSmall;
  final T? mobileMedium;
  final T? mobileLarge;
  final T? tabletSmall;
  final T? tabletLarge;

  /// Builder функция для создания виджета из значения
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileSmall,
    this.mobileMedium,
    this.mobileLarge,
    this.tabletSmall,
    this.tabletLarge,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveUtils.getValueByBreakpoint(
      context,
      mobileSmall: mobileSmall,
      mobileMedium: mobileMedium,
      mobileLarge: mobileLarge,
      tabletSmall: tabletSmall ?? tablet,
      tabletLarge: tabletLarge ?? desktop ?? tablet,
      defaultValue: mobile,
    );

    return builder(context, value);
  }
}

/// Виджет для создания адаптивной сетки
class ResponsiveGrid extends StatelessWidget {
  /// Список элементов для отображения
  final List<Widget> children;

  /// Количество колонок для разных breakpoints
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  /// Отступы между элементами
  final double? spacing;
  final double? runSpacing;

  /// Соотношение сторон элементов
  final double childAspectRatio;

  /// Кастомная высота элементов (альтернатива childAspectRatio)
  final double? itemHeight;

  /// Максимальная ширина сетки
  final double? maxWidth;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio = 1.0,
    this.itemHeight,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final int columns = ResponsiveUtils.getValueByBreakpoint(
      context,
      mobileLarge: mobileColumns ?? ResponsiveConstants.mobileColumns,
      tabletSmall: tabletColumns ?? ResponsiveConstants.tabletPortraitColumns,
      tabletLarge: desktopColumns ?? ResponsiveConstants.tabletLandscapeColumns,
      defaultValue: mobileColumns ?? ResponsiveConstants.mobileColumns,
    );

    final double crossAxisSpacing = spacing ?? ResponsiveUtils.getResponsiveValue(
      context,
      mobile: ResponsiveConstants.gridSpacingMobile,
      tablet: ResponsiveConstants.gridSpacingTablet,
    );

    final double mainAxisSpacing = runSpacing ?? crossAxisSpacing;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - (ResponsiveUtils.getHorizontalPadding(context) * 2) - (crossAxisSpacing * (columns - 1))) / columns;

    Widget grid = GridView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: itemHeight != null
            ? itemWidth / itemHeight!
            : childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

    // Ограничиваем максимальную ширину на больших экранах
    if (maxWidth != null) {
      grid = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: grid,
        ),
      );
    }

    return grid;
  }
}

/// Виджет для создания адаптивного wrap layout
class ResponsiveWrap extends StatelessWidget {
  /// Список элементов для отображения
  final List<Widget> children;

  /// Направление обертки
  final Axis direction;

  /// Выравнивание элементов
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final WrapAlignment runAlignment;

  /// Отступы между элементами
  final double? spacing;
  final double? runSpacing;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.spacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveSpacing = spacing ?? ResponsiveUtils.getResponsiveValue(
      context,
      mobile: ResponsiveConstants.spacingS,
      tablet: ResponsiveConstants.spacingM,
    );

    final double effectiveRunSpacing = runSpacing ?? effectiveSpacing;

    return Wrap(
      direction: direction,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      runAlignment: runAlignment,
      spacing: effectiveSpacing,
      runSpacing: effectiveRunSpacing,
      children: children,
    );
  }
}

/// Виджет для создания адаптивного макета с боковой панелью
class ResponsiveSidebarLayout extends StatelessWidget {
  /// Основной контент
  final Widget body;

  /// Боковая панель (показывается только на планшетах/десктопах)
  final Widget? sidebar;

  /// Ширина боковой панели
  final double sidebarWidth;

  /// Показывать ли боковую панель на планшетах в портретной ориентации
  final bool showSidebarOnTabletPortrait;

  /// Drawer для мобильных устройств (альтернатива sidebar)
  final Widget? drawer;

  const ResponsiveSidebarLayout({
    super.key,
    required this.body,
    this.sidebar,
    this.sidebarWidth = 300,
    this.showSidebarOnTabletPortrait = false,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);

    final showSidebar = sidebar != null &&
        isTablet &&
        (isLandscape || showSidebarOnTabletPortrait);

    if (showSidebar) {
      return Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: sidebar!,
          ),
          Expanded(child: body),
        ],
      );
    }

    // На мобильных используем Drawer если предоставлен
    if (drawer != null && !isTablet) {
      return Scaffold(
        drawer: drawer,
        body: body,
      );
    }

    return body;
  }
}

/// Виджет для создания адаптивного макета master-detail
class ResponsiveMasterDetail extends StatelessWidget {
  /// Список элементов (master)
  final Widget masterView;

  /// Детальный просмотр (detail)
  final Widget? detailView;

  /// Placeholder когда не выбран элемент
  final Widget? emptyDetailView;

  /// Ширина master панели
  final double masterWidth;

  /// Показывать ли detail view на мобильных (push в navigation)
  final bool pushDetailOnMobile;

  const ResponsiveMasterDetail({
    super.key,
    required this.masterView,
    this.detailView,
    this.emptyDetailView,
    this.masterWidth = 320,
    this.pushDetailOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);

    if (isTablet) {
      // На планшетах показываем side-by-side
      return Row(
        children: [
          SizedBox(
            width: masterWidth,
            child: masterView,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: detailView ??
                emptyDetailView ??
                const Center(
                  child: Text('Выберите элемент для просмотра'),
                ),
          ),
        ],
      );
    }

    // На мобильных показываем только master view
    // Detail view открывается через Navigator.push
    return masterView;
  }
}

/// Виджет для создания адаптивного контейнера с ограничениями
class ResponsiveContainer extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  /// Максимальная ширина контейнера
  final double? maxWidth;

  /// Отступы
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Выравнивание контента
  final AlignmentGeometry alignment;

  /// Добавить ли стандартные горизонтальные отступы
  final bool addHorizontalPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
    this.alignment = Alignment.center,
    this.addHorizontalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveMaxWidth = maxWidth ?? ResponsiveUtils.getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: ResponsiveConstants.maxContentWidth,
    );

    final EdgeInsetsGeometry effectivePadding = padding ?? (addHorizontalPadding
        ? EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getHorizontalPadding(context),
    )
        : EdgeInsets.zero);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: effectivePadding,
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}

/// Виджет для условного рендеринга в зависимости от размера экрана
class ResponsiveVisibility extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  /// Видимость на разных устройствах
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;

  /// Виджет-заместитель когда элемент скрыт
  final Widget replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveUtils.getScreenBreakpoint(context);

    bool isVisible;

    switch (breakpoint) {
      case ScreenBreakpoint.mobileSmall:
      case ScreenBreakpoint.mobileMedium:
      case ScreenBreakpoint.mobileLarge:
        isVisible = visibleOnMobile;
        break;
      case ScreenBreakpoint.tabletSmall:
        isVisible = visibleOnTablet;
        break;
      case ScreenBreakpoint.tabletLarge:
        isVisible = visibleOnDesktop;
        break;
    }

    return isVisible ? child : replacement;
  }
}

/// Дополнительные утилиты для ResponsiveBuilder
extension ResponsiveBuilderExtensions on BuildContext {
  /// Быстрый доступ к ResponsiveValue
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return ResponsiveUtils.getResponsiveValue(
      this,
      mobile: mobile,
      tablet: tablet,
    );
  }

  /// Быстрая проверка типа устройства
  bool get isMobile => ResponsiveUtils.getDeviceType(this) == DeviceType.mobile;
  bool get isTablet => ResponsiveUtils.getDeviceType(this) == DeviceType.tablet;
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
}