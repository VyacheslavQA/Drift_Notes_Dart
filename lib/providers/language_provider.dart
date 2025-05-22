// Путь: lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('ru', 'RU');
  static const String _prefsKey = 'app_language';
  static const String _systemLanguageKey = 'use_system_language';

  LanguageProvider() {
    // При создании провайдера загружаем сохраненный язык
    _loadSavedLanguage();
  }

  // Геттер для получения текущей локали
  Locale get currentLocale => _currentLocale;

  // Геттер для получения кода языка
  String get languageCode => _currentLocale.languageCode;

  // Загрузка сохраненного языка из SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useSystemLanguage = prefs.getBool(_systemLanguageKey) ?? false;

      if (useSystemLanguage) {
        // Используем системный язык
        final systemLocale = await getDeviceLocale();
        _currentLocale = systemLocale;
      } else {
        // Используем сохраненный язык
        final savedLanguage = prefs.getString(_prefsKey);
        if (savedLanguage != null) {
          _currentLocale = Locale(savedLanguage);
        }
      }

      debugPrint('📱 Загружен язык: ${_currentLocale.languageCode}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке языка: $e');
    }
  }

  // Изменение языка
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) {
      debugPrint('🔄 Язык уже установлен: ${newLocale.languageCode}');
      return;
    }

    debugPrint('🌐 Смена языка с ${_currentLocale.languageCode} на ${newLocale.languageCode}');

    _currentLocale = newLocale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newLocale.languageCode);
      await prefs.setBool(_systemLanguageKey, false); // Отключаем системный язык

      debugPrint('✅ Язык сохранен в настройках: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении языка: $e');
    }

    // Принудительно уведомляем всех слушателей об изменении
    notifyListeners();
  }

  // Установка системного языка
  Future<void> setSystemLanguage() async {
    debugPrint('🔧 Установка системного языка');

    try {
      final systemLocale = await getDeviceLocale();
      _currentLocale = systemLocale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemLanguageKey, true);
      await prefs.remove(_prefsKey); // Удаляем фиксированный язык

      debugPrint('✅ Установлен системный язык: ${systemLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Ошибка при установке системного языка: $e');
    }

    notifyListeners();
  }

  // Проверка, используется ли системный язык
  Future<bool> isUsingSystemLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_systemLanguageKey) ?? false;
    } catch (e) {
      debugPrint('❌ Ошибка при проверке системного языка: $e');
      return false;
    }
  }

  // Получение системного языка устройства
  static Future<Locale> getDeviceLocale() async {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      debugPrint('📱 Системный язык устройства: ${deviceLocale.languageCode}');

      // Проверяем, поддерживается ли системный язык
      if (['ru', 'en'].contains(deviceLocale.languageCode)) {
        return Locale(deviceLocale.languageCode);
      }

      debugPrint('⚠️ Системный язык не поддерживается, используем русский по умолчанию');
      // Если не поддерживается, возвращаем русский по умолчанию
      return const Locale('ru', 'RU');
    } catch (e) {
      debugPrint('❌ Ошибка при получении системного языка: $e');
      return const Locale('ru', 'RU');
    }
  }

  // Получение локализованного названия языка
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  // Получение списка поддерживаемых языков
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'system', 'name': 'Системный язык', 'nativeName': 'System Language'},
      {'code': 'ru', 'name': 'Русский', 'nativeName': 'Russian'},
      {'code': 'en', 'name': 'English', 'nativeName': 'Английский'},
    ];
  }

  // Сброс к настройкам по умолчанию
  Future<void> resetToDefault() async {
    debugPrint('🔄 Сброс языка к настройкам по умолчанию');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_systemLanguageKey);

      _currentLocale = const Locale('ru', 'RU');

      debugPrint('✅ Язык сброшен к русскому по умолчанию');
    } catch (e) {
      debugPrint('❌ Ошибка при сбросе языка: $e');
    }

    notifyListeners();
  }
}