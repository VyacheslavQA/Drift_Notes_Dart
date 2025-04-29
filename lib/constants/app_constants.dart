// Путь: lib/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // Цвета из ТЗ без голубого
  static const Color backgroundColor = Color(0xFF0A1F1C); // Тёмно-зелёный
  static const Color surfaceColor = Color(0xFF12332E); // Чуть светлее фона
  static const Color textColor = Color(0xFFE3D8B2); // Светло-бежевый
  static const Color accentColor = Color(0xFFE3D8B2); // Теперь используем светло-бежевый вместо голубого
  static const Color primaryColor = Color(0xFF2E7D32); // Зелёный для кнопок
  static const Color secondaryTextColor = Color(0xFFCCCCCC); // Серый для вторичного текста

  // Градиент для фона авторизации
  static const List<Color> authGradient = [
    Color(0xFF0A1F1C), // Тёмно-зелёный
    Color(0xFF071714), // Более тёмный оттенок
  ];

  // Типы рыбалки
  static const List<String> fishingTypes = [
    'Карповая рыбалка',
    'Спиннинг',
    'Фидер',
    'Поплавочная',
    'Зимняя рыбалка',
    'Нахлыст',
    'Троллинг',
    'Другое',
  ];

  // Уровни опыта рыболова
  static const List<String> experienceLevels = [
    'Новичок',
    'Любитель',
    'Продвинутый',
    'Профи',
    'Эксперт',
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
}