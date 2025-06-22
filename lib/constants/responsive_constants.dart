// Путь: lib/constants/responsive_constants.dart

import 'package:flutter/material.dart';

/// Централизованные константы для адаптивной системы Drift Notes
class ResponsiveConstants {
  ResponsiveConstants._(); // Приватный конструктор

  // ========== BREAKPOINTS ==========

  /// Breakpoints для различных размеров экрана
  static const double mobileSmallBreakpoint = 400.0;
  static const double mobileMediumBreakpoint = 600.0;
  static const double mobileLargeBreakpoint = 768.0;
  static const double tabletSmallBreakpoint = 1024.0;
  static const double tabletLargeBreakpoint = 1200.0;

  /// Минимальная поддерживаемая ширина экрана
  static const double minSupportedWidth = 320.0;

  // ========== TOUCH TARGETS ==========

  /// Минимальные размеры для touch targets (Apple HIG & Material Design)
  static const double minTouchTargetIOS = 44.0;
  static const double minTouchTargetAndroid = 48.0;
  static const double minTouchTarget = 48.0; // Используем Android стандарт

  /// Увеличенные размеры для использования на рыбалке (в перчатках)
  static const double outdoorTouchTarget = 56.0;
  static const double largeTouchTarget = 64.0; // Для критичных действий

  // ========== SPACING SYSTEM (8px grid) ==========

  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;

  // ========== TYPOGRAPHY ==========

  /// Базовые размеры шрифтов
  static const double fontSizeCaption = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeLargeHeading = 28.0;
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeLargeDisplay = 48.0;

  /// Максимальное масштабирование текста для стабильности UI
  static const double maxTextScaleFactor = 1.3;
  static const double minTextScaleFactor = 0.8;

  /// Высота строк для разных типов контента
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightLoose = 1.6;

  // ========== SIZING ==========

  /// Стандартные размеры элементов
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightOutdoor = 56.0;

  /// Размеры иконок
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  /// Размеры аватаров и изображений
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;

  // ========== BORDER RADIUS ==========

  static const double radiusXS = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 100.0; // Для круглых элементов

  // ========== ELEVATION & SHADOWS ==========

  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationVeryHigh = 16.0;

  // ========== ANIMATION DURATIONS ==========

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // Специфичные для приложения анимации
  static const Duration buttonPressAnimation = Duration(milliseconds: 120);
  static const Duration pageTransitionAnimation = Duration(milliseconds: 250);
  static const Duration splashAnimation = Duration(milliseconds: 2000);
  static const Duration loadingAnimation = Duration(milliseconds: 1000);

  // ========== OPACITY VALUES ==========

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityOverlay = 0.5;

  // ========== ASPECT RATIOS ==========

  static const double aspectRatioSquare = 1.0;
  static const double aspectRatio4x3 = 4.0 / 3.0;
  static const double aspectRatio16x9 = 16.0 / 9.0;
  static const double aspectRatioGolden = 1.618;

  // Специфичные для рыболовного приложения
  static const double photoAspectRatio = aspectRatio16x9;
  static const double mapPreviewAspectRatio = aspectRatio4x3;

  // ========== RESPONSIVE MULTIPLIERS ==========

  /// Множители для адаптации размеров на планшетах
  static const double tabletSizeMultiplier = 1.2;
  static const double tabletSpacingMultiplier = 1.5;
  static const double tabletFontMultiplier = 1.1;

  // ========== GRID SYSTEM ==========

  /// Количество колонок для разных breakpoints
  static const int mobileColumns = 1;
  static const int tabletPortraitColumns = 2;
  static const int tabletLandscapeColumns = 3;
  static const int desktopColumns = 4;

  /// Отступы между элементами сетки
  static const double gridSpacingMobile = spacingM;
  static const double gridSpacingTablet = spacingL;

  // ========== LAYOUT CONSTRAINTS ==========

  /// Максимальная ширина контента на больших экранах
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;
  static const double maxCardWidth = 400.0;

  /// Минимальная высота для различных элементов
  static const double minListItemHeight = 56.0;
  static const double minCardHeight = 120.0;
  static const double minButtonHeight = minTouchTarget;

  // ========== СПЕЦИФИКА РЫБОЛОВНОГО ПРИЛОЖЕНИЯ ==========

  /// Размеры специфичные для использования на рыбалке
  static const double fishingMapControlSize = 56.0;
  static const double fishingNoteCardMinHeight = 140.0;
  static const double fishingPhotoPreviewSize = 80.0;

  /// Отступы для outdoor использования (увеличенные для удобства)
  static const double outdoorSpacing = spacingL;
  static const double outdoorPadding = spacingXL;

  // ========== Z-INDEX LAYERS ==========

  static const int zIndexBackground = 0;
  static const int zIndexContent = 1;
  static const int zIndexAppBar = 10;
  static const int zIndexFloatingButton = 20;
  static const int zIndexBottomSheet = 30;
  static const int zIndexModal = 40;
  static const int zIndexTooltip = 50;
  static const int zIndexSnackBar = 60;

  // ========== ACCESSIBILITY ==========

  /// Минимальные размеры для accessibility
  static const double minAccessibleTouchTarget = 48.0;
  static const double minAccessibleFontSize = 14.0;
  static const double maxAccessibleFontSize = 28.0;

  /// Контрастность (для проверки в коде)
  static const double minContrastRatio = 4.5;
  static const double preferredContrastRatio = 7.0;

  // ========== PERFORMANCE ==========

  /// Константы для оптимизации производительности
  static const int maxVisibleListItems = 50;
  static const int imageQualityMobile = 80;
  static const int imageQualityTablet = 90;
  static const double imageCompressionRatio = 0.8;

  // ========== SAFE AREA HANDLING ==========

  /// Минимальные отступы от краев экрана
  static const double minSafeAreaPadding = 16.0;
  static const double iosNotchPadding = 44.0; // Типичная высота notch
  static const double androidNavBarHeight = 48.0;

  // ========== RESPONSIVE HELPERS ==========

  /// Получить размер touch target в зависимости от использования
  static double getTouchTargetSize({bool isOutdoor = false, bool isLarge = false}) {
    if (isLarge) return largeTouchTarget;
    if (isOutdoor) return outdoorTouchTarget;
    return minTouchTarget;
  }

  /// Получить отступы в зависимости от контекста
  static double getContextualSpacing({
    bool isOutdoor = false,
    bool isCompact = false,
  }) {
    if (isOutdoor) return outdoorSpacing;
    if (isCompact) return spacingS;
    return spacingM;
  }

  /// Получить размер шрифта с ограничениями
  static double getConstrainedFontSize(double fontSize) {
    return fontSize.clamp(minAccessibleFontSize, maxAccessibleFontSize);
  }

  /// Проверить, является ли размер достаточным для touch target
  static bool isValidTouchTarget(double size) {
    return size >= minAccessibleTouchTarget;
  }

  // ========== DEBUG CONSTANTS ==========

  /// Константы для debug режима
  static const bool enableResponsiveDebug = false; // Включить в debug сборках
  static const Color debugBorderColor = Colors.red;
  static const double debugBorderWidth = 1.0;

  /// Debug информация
  static const String debugPrefix = '[RESPONSIVE]';
}