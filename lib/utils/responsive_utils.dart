// Путь: lib/utils/responsive_utils.dart

import 'package:flutter/material.dart';

/// Типы устройств для адаптивности
enum DeviceType { mobile, tablet }

/// Breakpoints экрана
enum ScreenBreakpoint {
  mobileSmall,   // < 400px
  mobileMedium,  // 400px - 599px
  mobileLarge,   // 600px - 767px
  tabletSmall,   // 768px - 1023px
  tabletLarge,   // 1024px+
}

/// Утилиты для работы с адаптивностью
class ResponsiveUtils {
  /// Константы breakpoints
  static const double mobileSmallBreakpoint = 400;
  static const double mobileMediumBreakpoint = 600;
  static const double mobileLargeBreakpoint = 768;
  static const double tabletSmallBreakpoint = 1024;

  /// Минимальные размеры touch targets
  static const double minTouchTargetSize = 48.0;
  static const double fishingTouchTargetSize = 56.0; // Для использования в перчатках

  /// Максимальное масштабирование текста для UI стабильности
  static const double maxTextScaleFactor = 1.3;

  /// Система отступов (8px grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  /// Определение типа устройства
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= mobileLargeBreakpoint ? DeviceType.tablet : DeviceType.mobile;
  }

  /// Определение текущего breakpoint
  static ScreenBreakpoint getScreenBreakpoint(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmallBreakpoint) {
      return ScreenBreakpoint.mobileSmall;
    } else if (screenWidth < mobileMediumBreakpoint) {
      return ScreenBreakpoint.mobileMedium;
    } else if (screenWidth < mobileLargeBreakpoint) {
      return ScreenBreakpoint.mobileLarge;
    } else if (screenWidth < tabletSmallBreakpoint) {
      return ScreenBreakpoint.tabletSmall;
    } else {
      return ScreenBreakpoint.tabletLarge;
    }
  }

  /// Проверка, является ли устройство планшетом
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Проверка, является ли экран маленьким (для особой обработки)
  static bool isSmallScreen(BuildContext context) {
    return getScreenBreakpoint(context) == ScreenBreakpoint.mobileSmall;
  }

  /// Получение значения в зависимости от размера экрана
  static T getResponsiveValue<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
      }) {
    return isTablet(context) ? (tablet ?? mobile) : mobile;
  }

  /// Получение значения в зависимости от конкретного breakpoint
  static T getValueByBreakpoint<T>(
      BuildContext context, {
        T? mobileSmall,
        T? mobileMedium,
        T? mobileLarge,
        T? tabletSmall,
        T? tabletLarge,
        required T defaultValue,
      }) {
    final breakpoint = getScreenBreakpoint(context);

    switch (breakpoint) {
      case ScreenBreakpoint.mobileSmall:
        return mobileSmall ?? defaultValue;
      case ScreenBreakpoint.mobileMedium:
        return mobileMedium ?? defaultValue;
      case ScreenBreakpoint.mobileLarge:
        return mobileLarge ?? defaultValue;
      case ScreenBreakpoint.tabletSmall:
        return tabletSmall ?? defaultValue;
      case ScreenBreakpoint.tabletLarge:
        return tabletLarge ?? defaultValue;
    }
  }

  /// Оптимальный размер шрифта с учетом accessibility
  static double getOptimalFontSize(
      BuildContext context,
      double baseFontSize, {
        double? maxSize,
      }) {
    final textScaler = MediaQuery.of(context).textScaler;
    final scaledSize = baseFontSize * textScaler.scale(1.0);

    // Ограничиваем максимальное масштабирование для стабильности UI
    final maxScaleFactor = maxTextScaleFactor;
    final limitedSize = baseFontSize * maxScaleFactor;

    final finalSize = scaledSize > limitedSize ? limitedSize : scaledSize;

    return maxSize != null && finalSize > maxSize ? maxSize : finalSize;
  }

  /// Размер кнопки в зависимости от экрана и контекста использования
  static double getButtonHeight(
      BuildContext context, {
        bool isOutdoorUse = false, // Для использования на рыбалке
      }) {
    final baseSize = isOutdoorUse ? fishingTouchTargetSize : minTouchTargetSize;

    return getResponsiveValue(
      context,
      mobile: baseSize,
      tablet: baseSize + 8, // Немного больше на планшетах
    );
  }

  /// Ширина кнопки в процентах от экрана
  static double getButtonWidthPercent(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 0.8, // 80% на мобильных
      tablet: 0.6, // 60% на планшетах
    );
  }

  /// Максимальная ширина кнопки для планшетов
  static double getMaxButtonWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 400.0,
    );
  }

  /// Количество колонок для списков
  static int getListColumns(BuildContext context) {
    final breakpoint = getScreenBreakpoint(context);

    switch (breakpoint) {
      case ScreenBreakpoint.mobileSmall:
      case ScreenBreakpoint.mobileMedium:
      case ScreenBreakpoint.mobileLarge:
        return 1;
      case ScreenBreakpoint.tabletSmall:
        return 2;
      case ScreenBreakpoint.tabletLarge:
        return 3;
    }
  }

  /// Горизонтальные отступы для контента
  static double getHorizontalPadding(BuildContext context) {
    return getValueByBreakpoint(
      context,
      mobileSmall: spacingM,
      mobileMedium: spacingM,
      mobileLarge: spacingL,
      tabletSmall: spacingXL,
      tabletLarge: spacingXXL,
      defaultValue: spacingM,
    );
  }

  /// Вертикальные отступы для контента
  static double getVerticalPadding(BuildContext context) {
    return getValueByBreakpoint(
      context,
      mobileSmall: spacingM,
      mobileMedium: spacingL,
      mobileLarge: spacingL,
      tabletSmall: spacingXL,
      tabletLarge: spacingXL,
      defaultValue: spacingL,
    );
  }

  /// Размер иконок в зависимости от экрана
  static double getIconSize(BuildContext context, {double baseSize = 24.0}) {
    return getResponsiveValue(
      context,
      mobile: baseSize,
      tablet: baseSize + 4,
    );
  }

  /// Радиус скругления элементов
  static double getBorderRadius(BuildContext context, {double baseRadius = 8.0}) {
    return getResponsiveValue(
      context,
      mobile: baseRadius,
      tablet: baseRadius + 2,
    );
  }

  /// Получение safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Проверка, открыта ли клавиатура
  static bool isKeyboardOpen(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return bottomInset > 0;
  }

  /// Высота экрана без клавиатуры
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.viewInsets.bottom;
  }

  /// Является ли устройство в альбомной ориентации
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Проверка высококонтрастного режима
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Получение плотности пикселей
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Конвертация логических пикселей в физические
  static double logicalToPhysicalPixels(BuildContext context, double logicalPixels) {
    return logicalPixels * getPixelRatio(context);
  }

  /// Размер для изображений в зависимости от экрана
  static Size getImageSize(BuildContext context, {double aspectRatio = 16/9}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getHorizontalPadding(context) * 2;
    final imageWidth = screenWidth - padding;

    // Ограничиваем максимальную ширину на планшетах
    final maxWidth = isTablet(context) ? 600.0 : imageWidth;
    final finalWidth = imageWidth > maxWidth ? maxWidth : imageWidth;

    return Size(finalWidth, finalWidth / aspectRatio);
  }

  /// Дебаг информация об экране
  static void printScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    print('=== Screen Info ===');
    print('Size: ${mediaQuery.size}');
    print('Device Type: ${getDeviceType(context)}');
    print('Breakpoint: ${getScreenBreakpoint(context)}');
    print('Orientation: ${mediaQuery.orientation}');
    print('Pixel Ratio: ${mediaQuery.devicePixelRatio}');
    print('Text Scale Factor: ${mediaQuery.textScaler.scale(1.0)}');
    print('High Contrast: ${mediaQuery.highContrast}');
    print('Padding: ${mediaQuery.padding}');
    print('View Insets: ${mediaQuery.viewInsets}');
    print('==================');
  }
}