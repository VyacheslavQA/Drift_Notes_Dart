// Путь: lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('ru', 'RU');
  static const String _prefsKey = 'app_language';

  LanguageProvider() {
    // При создании провайдера загружаем сохраненный язык
    _loadSavedLanguage();
  }

  // Геттер для получения текущей локали
  Locale get currentLocale => _currentLocale;

  // Загрузка сохраненного языка из SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_prefsKey);

      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке языка: $e');
    }
  }

  // Изменение языка
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) return;

    _currentLocale = newLocale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Ошибка при сохранении языка: $e');
    }

    notifyListeners();
  }

  // Получение системного языка устройства
  static Future<Locale> getDeviceLocale() async {
    final deviceLocale = WidgetsBinding.instance.window.locale;

    // Проверяем, поддерживается ли системный язык
    if (['ru', 'en'].contains(deviceLocale.languageCode)) {
      return Locale(deviceLocale.languageCode);
    }

    // Если не поддерживается, возвращаем русский по умолчанию
    return const Locale('ru', 'RU');
  }
}