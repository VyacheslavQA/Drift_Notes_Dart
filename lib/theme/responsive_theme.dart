// Путь: lib/theme/responsive_theme.dart

import 'package:flutter/material.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_utils.dart';

/// Адаптивная система тем для Drift Notes
class ResponsiveTheme {
  ResponsiveTheme._(); // Приватный конструктор

  // ========== ЦВЕТОВАЯ СХЕМА ==========

  /// Основные цвета приложения (из app_constants.dart)
  static const Color primaryColor = Color(0xFF2196F3); // Синий как вода
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);

  static const Color accentColor = Color(0xFF4CAF50); // Зеленый как природа
  static const Color accentDarkColor = Color(0xFF388E3C);
  static const Color accentLightColor = Color(0xFFC8E6C9);

  static const Color backgroundColor = Color(0xFF121212); // Темная тема
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2C2C2C);

  static const Color textPrimaryColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFFB3B3B3);
  static const Color textDisabledColor = Color(0xFF666666);

  static const Color errorColor = Color(0xFFEF5350);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // ========== СОЗДАНИЕ АДАПТИВНОЙ ТЕМЫ ==========

  /// Создание основной темы с учетом размера экрана
  static ThemeData createTheme(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final isTablet = deviceType == DeviceType.tablet;
    final isHighContrast = ResponsiveUtils.isHighContrast(context);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Цветовая схема
      colorScheme: _createColorScheme(isHighContrast),

      // Типографика
      textTheme: _createTextTheme(context),

      // Компоненты
      appBarTheme: _createAppBarTheme(context),
      elevatedButtonTheme: _createElevatedButtonTheme(context),
      textButtonTheme: _createTextButtonTheme(context),
      outlinedButtonTheme: _createOutlinedButtonTheme(context),
      cardTheme: _createCardTheme(context),
      inputDecorationTheme: _createInputDecorationTheme(context),
      floatingActionButtonTheme: _createFABTheme(context),
      bottomNavigationBarTheme: _createBottomNavTheme(context),
      listTileTheme: _createListTileTheme(context),
      dialogTheme: _createDialogTheme(context),
      snackBarTheme: _createSnackBarTheme(context),

      // Общие настройки
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: surfaceColor,
      dividerColor: textSecondaryColor.withValues(alpha: 0.2),

      // Анимации
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ========== ЦВЕТОВЫЕ СХЕМЫ ==========

  static ColorScheme _createColorScheme(bool isHighContrast) {
    if (isHighContrast) {
      return const ColorScheme.dark(
        primary: Color(0xFF64B5F6), // Более яркий синий
        primaryContainer: Color(0xFF1565C0),
        secondary: Color(0xFF81C784), // Более яркий зеленый
        secondaryContainer: Color(0xFF2E7D32),
        surface: Color(0xFF000000), // Чистый черный
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
        onError: Color(0xFF000000),
      );
    }

    return const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryDarkColor,
      secondary: accentColor,
      secondaryContainer: accentDarkColor,
      surface: surfaceColor,
      onPrimary: textPrimaryColor,
      onSecondary: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: textPrimaryColor,
    );
  }

  // ========== ТИПОГРАФИКА ==========

  static TextTheme _createTextTheme(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final multiplier = isTablet ? ResponsiveConstants.tabletFontMultiplier : 1.0;

    return TextTheme(
      // Display стили (большие заголовки)
      displayLarge: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeLargeDisplay * multiplier,
        ),
        fontWeight: FontWeight.w300,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightTight,
      ),
      displayMedium: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeDisplay * multiplier,
        ),
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightTight,
      ),

      // Headline стили (заголовки экранов)
      headlineLarge: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeLargeHeading * multiplier,
        ),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeHeading * multiplier,
        ),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),

      // Title стили (заголовки карточек, диалогов)
      titleLarge: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeTitle * multiplier,
        ),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeSubtitle * multiplier,
        ),
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),

      // Body стили (основной текст)
      bodyLarge: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeBody * multiplier,
        ),
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),
      bodyMedium: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeSmall * multiplier,
        ),
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: ResponsiveConstants.lineHeightNormal,
      ),

      // Label стили (кнопки, подписи)
      labelLarge: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeBody * multiplier,
        ),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: ResponsiveConstants.lineHeightTight,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeSmall * multiplier,
        ),
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        height: ResponsiveConstants.lineHeightTight,
      ),
      labelSmall: TextStyle(
        fontSize: ResponsiveUtils.getOptimalFontSize(
          context,
          ResponsiveConstants.fontSizeCaption * multiplier,
        ),
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: ResponsiveConstants.lineHeightTight,
      ),
    );
  }

  // ========== APP BAR THEME ==========

  static AppBarTheme _createAppBarTheme(BuildContext context) {
    return AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: ResponsiveConstants.elevationLow,
      centerTitle: true,
      titleTextStyle: _createTextTheme(context).titleLarge,
      toolbarHeight: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: kToolbarHeight,
        tablet: kToolbarHeight + 8,
      ),
      iconTheme: IconThemeData(
        color: textPrimaryColor,
        size: ResponsiveUtils.getIconSize(context),
      ),
    );
  }

  // ========== BUTTON THEMES ==========

  static ElevatedButtonThemeData _createElevatedButtonTheme(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);

    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryColor,
        elevation: ResponsiveConstants.elevationMedium,
        minimumSize: Size(double.minPositive, buttonHeight),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveConstants.spacingL,
          vertical: ResponsiveConstants.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        textStyle: _createTextTheme(context).labelLarge,
      ),
    );
  }

  static TextButtonThemeData _createTextButtonTheme(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);

    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: Size(double.minPositive, buttonHeight),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveConstants.spacingM,
          vertical: ResponsiveConstants.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        textStyle: _createTextTheme(context).labelLarge?.copyWith(
          color: primaryColor,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _createOutlinedButtonTheme(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);

    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        minimumSize: Size(double.minPositive, buttonHeight),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveConstants.spacingL,
          vertical: ResponsiveConstants.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        textStyle: _createTextTheme(context).labelLarge?.copyWith(
          color: primaryColor,
        ),
      ),
    );
  }

  // ========== CARD THEME ==========

  static CardThemeData _createCardTheme(BuildContext context) {
    return CardThemeData(
      color: cardColor,
      elevation: ResponsiveConstants.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
        ),
      ),
      margin: EdgeInsets.all(ResponsiveConstants.spacingS),
    );
  }

  // ========== INPUT DECORATION THEME ==========

  static InputDecorationTheme _createInputDecorationTheme(BuildContext context) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        borderSide: BorderSide(color: textSecondaryColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        borderSide: BorderSide(color: textSecondaryColor.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.spacingM,
        vertical: ResponsiveConstants.spacingM,
      ),
      labelStyle: _createTextTheme(context).bodyMedium,
      hintStyle: _createTextTheme(context).bodyMedium?.copyWith(
        color: textSecondaryColor.withValues(alpha: 0.6),
      ),
    );
  }

  // ========== FLOATING ACTION BUTTON THEME ==========

  static FloatingActionButtonThemeData _createFABTheme(BuildContext context) {
    return FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: textPrimaryColor,
      elevation: ResponsiveConstants.elevationMedium,
      sizeConstraints: BoxConstraints.tightFor(
        width: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 56,
          tablet: 64,
        ),
        height: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 56,
          tablet: 64,
        ),
      ),
    );
  }

  // ========== BOTTOM NAVIGATION THEME ==========

  static BottomNavigationBarThemeData _createBottomNavTheme(BuildContext context) {
    return BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: ResponsiveConstants.elevationMedium,
      selectedLabelStyle: _createTextTheme(context).labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _createTextTheme(context).labelSmall,
    );
  }

  // ========== LIST TILE THEME ==========

  static ListTileThemeData _createListTileTheme(BuildContext context) {
    return ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: primaryColor.withValues(alpha: 0.1),
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveConstants.spacingS,
      ),
      minVerticalPadding: ResponsiveConstants.spacingS,
      titleTextStyle: _createTextTheme(context).bodyLarge,
      subtitleTextStyle: _createTextTheme(context).bodyMedium,
      leadingAndTrailingTextStyle: _createTextTheme(context).labelMedium,
    );
  }

  // ========== DIALOG THEME ==========

  static DialogThemeData _createDialogTheme(BuildContext context) {
    return DialogThemeData(
      backgroundColor: cardColor,
      elevation: ResponsiveConstants.elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusXL),
        ),
      ),
      titleTextStyle: _createTextTheme(context).titleLarge,
      contentTextStyle: _createTextTheme(context).bodyMedium,
    );
  }

  // ========== SNACKBAR THEME ==========

  static SnackBarThemeData _createSnackBarTheme(BuildContext context) {
    return SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: _createTextTheme(context).bodyMedium?.copyWith(
        color: textPrimaryColor,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
      ),
      elevation: ResponsiveConstants.elevationMedium,
    );
  }

  // ========== СПЕЦИФИЧНЫЕ ДЛЯ РЫБАЛКИ СТИЛИ ==========

  /// Стиль для кнопок, используемых на рыбалке (увеличенные)
  static ButtonStyle getOutdoorButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: Size(
        double.minPositive,
        ResponsiveConstants.getTouchTargetSize(isOutdoor: true),
      ),
      padding: EdgeInsets.all(ResponsiveConstants.outdoorPadding),
      textStyle: _createTextTheme(context).labelLarge?.copyWith(
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
      ),
    );
  }

  /// Стиль для карточек заметок о рыбалке
  static BoxDecoration getFishingCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: ResponsiveConstants.elevationMedium,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Получить размеры для фотографий в заметках
  static Size getFishingPhotoSize(BuildContext context) {
    return ResponsiveUtils.getImageSize(
      context,
      aspectRatio: ResponsiveConstants.photoAspectRatio,
    );
  }
}