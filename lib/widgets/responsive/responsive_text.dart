// Путь: lib/widgets/responsive/responsive_text.dart

import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/responsive_constants.dart';

/// Типы адаптивного текста
enum ResponsiveTextType {
  displayLarge,    // Большие заголовки (логотипы, главные заголовки)
  displayMedium,   // Средние заголовки экранов
  headlineLarge,   // Заголовки разделов
  headlineMedium,  // Подзаголовки
  titleLarge,      // Заголовки карточек, диалогов
  titleMedium,     // Заголовки элементов списка
  bodyLarge,       // Основной текст
  bodyMedium,      // Вторичный текст
  labelLarge,      // Текст кнопок
  labelMedium,     // Подписи
  labelSmall,      // Мелкие подписи
  caption,         // Подписи к изображениям, даты
}

/// Адаптивный текст с поддержкой accessibility и автомасштабированием
class ResponsiveText extends StatelessWidget {
  /// Текст для отображения
  final String text;

  /// Тип текста (определяет базовый стиль)
  final ResponsiveTextType type;

  /// Кастомный размер шрифта (переопределяет тип)
  final double? fontSize;

  /// Цвет текста
  final Color? color;

  /// Толщина шрифта
  final FontWeight? fontWeight;

  /// Стиль шрифта (курсив и т.д.)
  final FontStyle? fontStyle;

  /// Межстрочное расстояние
  final double? height;

  /// Межбуквенное расстояние
  final double? letterSpacing;

  /// Выравнивание текста
  final TextAlign? textAlign;

  /// Максимальное количество строк
  final int? maxLines;

  /// Поведение при переполнении
  final TextOverflow? overflow;

  /// Использовать ли мягкие переносы
  final bool softWrap;

  /// Множитель для масштабирования (относительно базового размера)
  final double scaleFactor;

  /// Минимальный размер шрифта (для accessibility)
  final double? minFontSize;

  /// Максимальный размер шрифта (для accessibility)
  final double? maxFontSize;

  /// Семантическая роль для screen readers
  final String? semanticsLabel;

  /// Использовать ли адаптивное масштабирование для планшетов
  final bool useTabletScaling;

  /// Подчеркивание
  final TextDecoration? decoration;

  /// Цвет подчеркивания
  final Color? decorationColor;

  /// Тень текста
  final List<Shadow>? shadows;

  const ResponsiveText(
      this.text, {
        super.key,
        this.type = ResponsiveTextType.bodyLarge,
        this.fontSize,
        this.color,
        this.fontWeight,
        this.fontStyle,
        this.height,
        this.letterSpacing,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.softWrap = true,
        this.scaleFactor = 1.0,
        this.minFontSize,
        this.maxFontSize,
        this.semanticsLabel,
        this.useTabletScaling = true,
        this.decoration,
        this.decorationColor,
        this.shadows,
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Получаем базовый стиль в зависимости от типа
    final baseStyle = _getBaseTextStyle(textTheme);

    // Вычисляем оптимальный размер шрифта
    final optimalFontSize = _calculateOptimalFontSize(context, baseStyle);

    // Создаем финальный стиль
    final finalStyle = baseStyle.copyWith(
      fontSize: optimalFontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      shadows: shadows,
    );

    Widget textWidget = Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );

    // Добавляем семантику для accessibility
    if (semanticsLabel != null) {
      textWidget = Semantics(
        label: semanticsLabel,
        child: textWidget,
      );
    }

    return textWidget;
  }

  /// Получение базового стиля текста в зависимости от типа
  TextStyle _getBaseTextStyle(TextTheme textTheme) {
    switch (type) {
      case ResponsiveTextType.displayLarge:
        return textTheme.displayLarge ?? const TextStyle();
      case ResponsiveTextType.displayMedium:
        return textTheme.displayMedium ?? const TextStyle();
      case ResponsiveTextType.headlineLarge:
        return textTheme.headlineLarge ?? const TextStyle();
      case ResponsiveTextType.headlineMedium:
        return textTheme.headlineMedium ?? const TextStyle();
      case ResponsiveTextType.titleLarge:
        return textTheme.titleLarge ?? const TextStyle();
      case ResponsiveTextType.titleMedium:
        return textTheme.titleMedium ?? const TextStyle();
      case ResponsiveTextType.bodyLarge:
        return textTheme.bodyLarge ?? const TextStyle();
      case ResponsiveTextType.bodyMedium:
        return textTheme.bodyMedium ?? const TextStyle();
      case ResponsiveTextType.labelLarge:
        return textTheme.labelLarge ?? const TextStyle();
      case ResponsiveTextType.labelMedium:
        return textTheme.labelMedium ?? const TextStyle();
      case ResponsiveTextType.labelSmall:
        return textTheme.labelSmall ?? const TextStyle();
      case ResponsiveTextType.caption:
        return textTheme.bodySmall ?? const TextStyle();
    }
  }

  /// Вычисление оптимального размера шрифта с учетом всех факторов
  double _calculateOptimalFontSize(BuildContext context, TextStyle baseStyle) {
    // Получаем базовый размер из стиля или кастомного параметра
    double baseFontSize = fontSize ?? baseStyle.fontSize ?? ResponsiveConstants.fontSizeBody;

    // Применяем scaling factor
    baseFontSize *= scaleFactor;

    // Применяем планшетное масштабирование если включено
    if (useTabletScaling && ResponsiveUtils.isTablet(context)) {
      baseFontSize *= ResponsiveConstants.tabletFontMultiplier;
    }

    // Получаем оптимальный размер с учетом accessibility
    double optimalSize = ResponsiveUtils.getOptimalFontSize(
      context,
      baseFontSize,
      maxSize: maxFontSize,
    );

    // Применяем минимальные и максимальные ограничения
    if (minFontSize != null && optimalSize < minFontSize!) {
      optimalSize = minFontSize!;
    }

    if (maxFontSize != null && optimalSize > maxFontSize!) {
      optimalSize = maxFontSize!;
    }

    // Убеждаемся, что размер не меньше accessibility минимума
    if (optimalSize < ResponsiveConstants.minAccessibleFontSize) {
      optimalSize = ResponsiveConstants.minAccessibleFontSize;
    }

    return optimalSize;
  }
}

/// Виджет для отображения адаптивного rich text
class ResponsiveRichText extends StatelessWidget {
  /// Список TextSpan для rich text
  final List<InlineSpan> children;

  /// Базовый стиль текста
  final ResponsiveTextType baseType;

  /// Выравнивание текста
  final TextAlign? textAlign;

  /// Максимальное количество строк
  final int? maxLines;

  /// Поведение при переполнении
  final TextOverflow? overflow;

  /// Использовать ли мягкие переносы
  final bool softWrap;

  /// Множитель для масштабирования
  final double scaleFactor;

  /// Семантическая метка
  final String? semanticsLabel;

  const ResponsiveRichText({
    super.key,
    required this.children,
    this.baseType = ResponsiveTextType.bodyLarge,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.scaleFactor = 1.0,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Получаем базовый стиль
    final baseStyle = _getBaseTextStyle(textTheme);

    // Вычисляем оптимальный размер шрифта
    double baseFontSize = baseStyle.fontSize ?? ResponsiveConstants.fontSizeBody;
    baseFontSize *= scaleFactor;

    if (ResponsiveUtils.isTablet(context)) {
      baseFontSize *= ResponsiveConstants.tabletFontMultiplier;
    }

    final optimalFontSize = ResponsiveUtils.getOptimalFontSize(context, baseFontSize);

    final finalBaseStyle = baseStyle.copyWith(fontSize: optimalFontSize);

    Widget richText = RichText(
      text: TextSpan(
        style: finalBaseStyle,
        children: children,
      ),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: softWrap,
    );

    if (semanticsLabel != null) {
      richText = Semantics(
        label: semanticsLabel,
        child: richText,
      );
    }

    return richText;
  }

  TextStyle _getBaseTextStyle(TextTheme textTheme) {
    switch (baseType) {
      case ResponsiveTextType.displayLarge:
        return textTheme.displayLarge ?? const TextStyle();
      case ResponsiveTextType.displayMedium:
        return textTheme.displayMedium ?? const TextStyle();
      case ResponsiveTextType.headlineLarge:
        return textTheme.headlineLarge ?? const TextStyle();
      case ResponsiveTextType.headlineMedium:
        return textTheme.headlineMedium ?? const TextStyle();
      case ResponsiveTextType.titleLarge:
        return textTheme.titleLarge ?? const TextStyle();
      case ResponsiveTextType.titleMedium:
        return textTheme.titleMedium ?? const TextStyle();
      case ResponsiveTextType.bodyLarge:
        return textTheme.bodyLarge ?? const TextStyle();
      case ResponsiveTextType.bodyMedium:
        return textTheme.bodyMedium ?? const TextStyle();
      case ResponsiveTextType.labelLarge:
        return textTheme.labelLarge ?? const TextStyle();
      case ResponsiveTextType.labelMedium:
        return textTheme.labelMedium ?? const TextStyle();
      case ResponsiveTextType.labelSmall:
        return textTheme.labelSmall ?? const TextStyle();
      case ResponsiveTextType.caption:
        return textTheme.bodySmall ?? const TextStyle();
    }
  }
}

/// Виджет для адаптивного текста с автоматическим изменением размера
class ResponsiveAutoSizeText extends StatelessWidget {
  /// Текст для отображения
  final String text;

  /// Стиль текста
  final TextStyle? style;

  /// Минимальный размер шрифта
  final double minFontSize;

  /// Максимальный размер шрифта
  final double maxFontSize;

  /// Шаг изменения размера
  final double stepGranularity;

  /// Максимальное количество строк
  final int? maxLines;

  /// Выравнивание текста
  final TextAlign? textAlign;

  /// Поведение при переполнении
  final TextOverflow overflow;

  const ResponsiveAutoSizeText(
      this.text, {
        super.key,
        this.style,
        this.minFontSize = 12.0,
        this.maxFontSize = 100.0,
        this.stepGranularity = 1.0,
        this.maxLines,
        this.textAlign,
        this.overflow = TextOverflow.clip,
      });

  @override
  Widget build(BuildContext context) {
    // Простая реализация автоматического изменения размера
    // В реальном проекте можно использовать пакет auto_size_text

    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyLarge ?? const TextStyle();

    // Адаптируем размер под экран
    double adaptiveFontSize = baseStyle.fontSize ?? ResponsiveConstants.fontSizeBody;

    if (ResponsiveUtils.isTablet(context)) {
      adaptiveFontSize *= ResponsiveConstants.tabletFontMultiplier;
    }

    // Применяем accessibility масштабирование
    adaptiveFontSize = ResponsiveUtils.getOptimalFontSize(context, adaptiveFontSize);

    // Ограничиваем размер
    if (adaptiveFontSize < minFontSize) adaptiveFontSize = minFontSize;
    if (adaptiveFontSize > maxFontSize) adaptiveFontSize = maxFontSize;

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: adaptiveFontSize),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

/// Фабричные методы для быстрого создания текста
extension ResponsiveTextFactory on ResponsiveText {
  /// Создать заголовок экрана
  static ResponsiveText headline(
      String text, {
        Key? key,
        ResponsiveTextType type = ResponsiveTextType.headlineLarge,
        Color? color,
        FontWeight? fontWeight,
        TextAlign? textAlign,
        int? maxLines,
      }) {
    return ResponsiveText(
      text,
      key: key,
      type: type,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w600,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }

  /// Создать основной текст
  static ResponsiveText body(
      String text, {
        Key? key,
        ResponsiveTextType type = ResponsiveTextType.bodyLarge,
        Color? color,
        TextAlign? textAlign,
        int? maxLines,
        TextOverflow? overflow,
      }) {
    return ResponsiveText(
      text,
      key: key,
      type: type,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Создать подпись или вторичный текст
  static ResponsiveText caption(
      String text, {
        Key? key,
        Color? color,
        TextAlign? textAlign,
        int? maxLines,
        FontStyle? fontStyle,
      }) {
    return ResponsiveText(
      text,
      key: key,
      type: ResponsiveTextType.caption,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      fontStyle: fontStyle,
    );
  }

  /// Создать текст для кнопок
  static ResponsiveText button(
      String text, {
        Key? key,
        Color? color,
        FontWeight? fontWeight,
        double? letterSpacing,
      }) {
    return ResponsiveText(
      text,
      key: key,
      type: ResponsiveTextType.labelLarge,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w600,
      letterSpacing: letterSpacing ?? 0.5,
    );
  }

  /// Создать текст для рыболовного приложения с увеличенным размером
  static ResponsiveText fishing(
      String text, {
        Key? key,
        ResponsiveTextType type = ResponsiveTextType.bodyLarge,
        Color? color,
        TextAlign? textAlign,
        int? maxLines,
      }) {
    return ResponsiveText(
      text,
      key: key,
      type: type,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      scaleFactor: 1.1, // Немного увеличиваем для лучшей читаемости на улице
      minFontSize: ResponsiveConstants.fontSizeSmall + 2, // Минимум чуть больше
    );
  }
}

/// Виджет для отображения многоязычного текста с правильной типографикой
class ResponsiveLocalizedText extends StatelessWidget {
  /// Ключ локализации
  final String localizationKey;

  /// Тип текста
  final ResponsiveTextType type;

  /// Параметры для подстановки в локализованный текст
  final Map<String, dynamic>? args;

  /// Стилизация текста
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveLocalizedText(
      this.localizationKey, {
        super.key,
        this.type = ResponsiveTextType.bodyLarge,
        this.args,
        this.color,
        this.fontWeight,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    // Здесь должна быть интеграция с системой локализации
    // Для примера используем простую заглушку
    final localizedText = _getLocalizedText(context);

    return ResponsiveText(
      localizedText,
      type: type,
      color: color,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  String _getLocalizedText(BuildContext context) {
    // Заглушка для локализации
    // В реальном приложении здесь должен быть вызов AppLocalizations.of(context).translate()
    return localizationKey;
  }
}