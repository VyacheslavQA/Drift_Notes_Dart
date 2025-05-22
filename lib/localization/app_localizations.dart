// Путь: lib/localization/app_localizations.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_localization_delegate.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Вспомогательный метод для хранения экземпляра класса для каждого локального контекста
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Статический метод для инициализации делегата
  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationDelegate();

  // Кэш для переводов
  late Map<String, String> _localizedStrings;

  // Загрузка JSON файлов с переводами
  Future<bool> load() async {
    try {
      // Загружаем JSON файл из папки assets
      String jsonString = await rootBundle.loadString('assets/localization/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      // Если файл не найден, возвращаем пустую карту
      print('Ошибка загрузки локализации для ${locale.languageCode}: $e');
      _localizedStrings = {};
      return false;
    }
  }

  // Метод для получения перевода с резервным значением
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Удобный геттер для использования вместо метода
  String get(String key) => translate(key);

  // Получение текущего кода языка
  String get languageCode => locale.languageCode;

  // Список поддерживаемых локалей
  static List<Locale> supportedLocales() {
    return [
      const Locale('ru', 'RU'), // Русский
      const Locale('en', 'US'), // Английский
    ];
  }

  // Получение названия языка по коду
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  // Проверка, загружены ли переводы
  bool get isLoaded => _localizedStrings.isNotEmpty;
}