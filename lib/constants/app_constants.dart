// Путь: lib/constants/app_constants.dart

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class AppConstants {
  // Цвета приложения
  static const Color backgroundColor = Color(0xFF0A1F1C); // Тёмно-зелёный
  static const Color surfaceColor = Color(0xFF12332E); // Чуть светлее фона
  static const Color textColor = Color(0xFFE3D8B2); // Светло-бежевый
  static const Color accentColor = Color(0xFFE3D8B2); // Светло-бежевый
  static const Color primaryColor = Color(0xFF2E7D32); // Зелёный для кнопок
  static const Color secondaryTextColor = Color(0xFFCCCCCC); // Серый для вторичного текста
  static const Color cardColor = Color(0xFF12332E); // Цвет карточек
  static const Color bottomBarColor = Color(0xFF0B1F1D); // Цвет нижней панели
  static const Color dividerColor = Color(0xFF164C45); // Цвет разделителей

  // Градиенты
  static const List<Color> authGradient = [
    Color(0xFF0A1F1C), // Тёмно-зелёный
    Color(0xFF071714), // Более тёмный оттенок
  ];

  static const List<Color> cardGradient = [
    Color(0xFF123430), // Верхний цвет карточки
    Color(0xFF0F2923), // Нижний цвет карточки
  ];

  // Радиусы скругления
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  // Отступы
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Размеры текста
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;

  // Типы рыбалки - ключи локализации
  static const List<String> fishingTypes = [
    'carp_fishing',
    'spinning',
    'feeder',
    'float_fishing',
    'ice_fishing',
    'fly_fishing',
    'trolling',
    'other_fishing',
  ];

  // Уровни опыта рыболова - ИСПРАВЛЕНО: теперь ключи локализации
  static const List<String> experienceLevels = [
    'novice',
    'amateur',
    'advanced',
    'professional',
    'expert',
  ];

  // Страны
  static const List<String> countries = [
    'Азербайджан',
    'Армения',
    'Беларусь',
    'Грузия',
    'Казахстан',
    'Кыргызстан',
    'Россия',
    'Таджикистан',
    'Туркменистан',
    'Узбекистан',
    'Украина',
  ];

  // Города Казахстана
  static const List<String> kazakhstanCities = [
    'Акколь', 'Аксу', 'Актау', 'Актобе', 'Алга', 'Алматы', 'Алтай', 'Аральск', 'Аркалык', 'Астана', 'Атбасар', 'Атырау',
    'Байконур', 'Балхаш', 'Булаево',
    'Державинск',
    'Ерейментау', 'Есик',
    'Жанаозен', 'Жанатас', 'Жаркент', 'Жезказган', 'Житикара',
    'Зайсан', 'Зыряновск',
    'Кандыагаш', 'Капшагай', 'Караганда', 'Каражал', 'Каратау', 'Каскелен', 'Кентау', 'Кокшетау', 'Костанай', 'Кызылорда',
    'Ленгер',
    'Макинск',
    'Павлодар', 'Петропавловск', 'Приозерск',
    'Риддер', 'Рудный',
    'Сарань', 'Сатпаев', 'Семей', 'Сергеевка', 'Степногорск',
    'Талгар', 'Талдыкорган', 'Тараз', 'Текели', 'Темир', 'Темиртау', 'Туркестан',
    'Уральск', 'Усть-Каменогорск',
    'Форт-Шевченко',
    'Хромтау',
    'Шалкар', 'Шар', 'Шардара', 'Шахтинск', 'Шемонаиха', 'Шу', 'Шымкент',
    'Щучинск',
    'Экибастуз',
  ];

  // Города России
  static const List<String> russiaCities = [
    'Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург', 'Казань',
    'Нижний Новгород', 'Челябинск', 'Самара', 'Омск', 'Ростов-на-Дону',
    'Уфа', 'Красноярск', 'Воронеж', 'Пермь', 'Волгоград',
  ];

  // Карта городов по странам
  static const Map<String, List<String>> citiesByCountry = {
    'Казахстан': kazakhstanCities,
    'Россия': russiaCities,
  };

  // Стили текста
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
  );

  // Тени
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Анимации
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  // Вспомогательный метод для получения переведенного названия типа рыбалки
  static String getLocalizedFishingType(String fishingTypeKey, BuildContext context) {
    try {
      final localizations = AppLocalizations.of(context);
      return localizations.translate(fishingTypeKey);
    } catch (e) {
      // Если что-то пошло не так, возвращаем fallback
    }

    // Fallback на русский
    switch (fishingTypeKey) {
      case 'carp_fishing': return 'Карповая рыбалка';
      case 'spinning': return 'Спиннинг';
      case 'feeder': return 'Фидер';
      case 'float_fishing': return 'Поплавочная';
      case 'ice_fishing': return 'Зимняя рыбалка';
      case 'fly_fishing': return 'Нахлыст';
      case 'trolling': return 'Троллинг';
      case 'other_fishing': return 'Другое';
      default: return fishingTypeKey;
    }
  }

  // ДОБАВЛЕНО: Вспомогательный метод для получения переведенного уровня опыта
  static String getLocalizedExperienceLevel(String experienceLevelKey, BuildContext context) {
    try {
      final localizations = AppLocalizations.of(context);
      return localizations.translate(experienceLevelKey);
    } catch (e) {
      // Если что-то пошло не так, возвращаем fallback
    }

    // Fallback на русский
    switch (experienceLevelKey) {
      case 'novice': return 'Новичок';
      case 'amateur': return 'Любитель';
      case 'advanced': return 'Продвинутый';
      case 'professional': return 'Профи';
      case 'expert': return 'Эксперт';
      default: return experienceLevelKey;
    }
  }
}