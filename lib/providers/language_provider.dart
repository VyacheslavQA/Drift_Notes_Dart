// Путь: lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/countries_data.dart';
import '../services/weather_notification_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('ru', 'RU');
  static const String _prefsKey = 'app_language';
  static const String _systemLanguageKey = 'use_system_language';

  // ИСПРАВЛЕНО: Флаг инициализации
  bool _isInitialized = false;

  LanguageProvider() {
    // ИСПРАВЛЕНО: Убираем асинхронный вызов из конструктора
    // ✅ УБРАНО: debugPrint('🏗️ LanguageProvider создан с дефолтным языком: ${_currentLocale.languageCode}');
  }

  // Геттер для получения текущей локали
  Locale get currentLocale => _currentLocale;

  // Геттер для получения кода языка
  String get languageCode => _currentLocale.languageCode;

  // Геттер для проверки инициализации
  bool get isInitialized => _isInitialized;

  // ИСПРАВЛЕНО: Публичный метод для инициализации (вызывается из main)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // ✅ УБРАНО: debugPrint('🚀 Инициализация LanguageProvider...');
    await _loadSavedLanguage();
    _isInitialized = true;
    // ✅ УБРАНО: debugPrint('✅ LanguageProvider инициализирован');
  }

  // Загрузка сохраненного языка из SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useSystemLanguage = prefs.getBool(_systemLanguageKey) ?? false;

      if (useSystemLanguage) {
        // Используем системный язык
        final systemLocale = await getDeviceLocale();
        _currentLocale = systemLocale;
        // ✅ УБРАНО: debugPrint('📱 Загружен системный язык: ${_currentLocale.languageCode}');
      } else {
        // Используем сохраненный язык
        final savedLanguage = prefs.getString(_prefsKey);
        if (savedLanguage != null) {
          _currentLocale = Locale(savedLanguage);
          // ✅ УБРАНО: debugPrint('💾 Загружен сохраненный язык: ${_currentLocale.languageCode}');
        } else {
          // ✅ УБРАНО: debugPrint('🔧 Используем дефолтный язык: ${_currentLocale.languageCode}');
        }
      }

      // ДОБАВЛЕНО: Синхронизация с WeatherNotificationService при загрузке
      await _syncWeatherServiceLanguage();

      // ИСПРАВЛЕНО: notifyListeners только если есть слушатели
      if (_isInitialized) {
        notifyListeners();
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при загрузке языка: $e');
      // При ошибке оставляем дефолтный язык
    }
  }

  // Изменение языка
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) {
      // ✅ УБРАНО: debugPrint('🔄 Язык уже установлен: ${newLocale.languageCode}');
      // Очищаем кэш географических данных при смене языка
      CountriesData.clearGeographyCache();
      return;
    }

    // ✅ УБРАНО: debugPrint('🌐 Смена языка с ${_currentLocale.languageCode} на ${newLocale.languageCode}');

    _currentLocale = newLocale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newLocale.languageCode);
      await prefs.setBool(
        _systemLanguageKey,
        false,
      ); // Отключаем системный язык

      // ✅ УБРАНО: debugPrint('✅ Язык сохранен в настройках: ${newLocale.languageCode}');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при сохранении языка: $e');
    }

    // ДОБАВЛЕНО: Синхронизация с WeatherNotificationService
    await _syncWeatherServiceLanguage();

    // Принудительно уведомляем всех слушателей об изменении
    notifyListeners();

    // Очищаем кэш географических данных при смене языка
    CountriesData.clearGeographyCache();
  }

  // Установка системного языка
  Future<void> setSystemLanguage() async {
    // ✅ УБРАНО: debugPrint('🔧 Установка системного языка');

    try {
      final systemLocale = await getDeviceLocale();
      _currentLocale = systemLocale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemLanguageKey, true);
      await prefs.remove(_prefsKey); // Удаляем фиксированный язык

      // ✅ УБРАНО: debugPrint('✅ Установлен системный язык: ${systemLocale.languageCode}');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при установке системного языка: $e');
    }

    // ДОБАВЛЕНО: Синхронизация с WeatherNotificationService
    await _syncWeatherServiceLanguage();

    notifyListeners();
  }

  // ДОБАВЛЕНО: Синхронизация языка с WeatherNotificationService
  Future<void> _syncWeatherServiceLanguage() async {
    try {
      await WeatherNotificationService().updateLanguage(_currentLocale.languageCode);
      // ✅ УБРАНО: debugPrint('🌤️ Язык синхронизирован с WeatherNotificationService: ${_currentLocale.languageCode}');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка синхронизации языка с WeatherNotificationService: $e');
    }
  }

  // Проверка, используется ли системный язык
  Future<bool> isUsingSystemLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_systemLanguageKey) ?? false;
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при проверке системного языка: $e');
      return false;
    }
  }

  // Получение системного языка устройства
  static Future<Locale> getDeviceLocale() async {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      // ✅ УБРАНО: debugPrint('📱 Системный язык устройства: ${deviceLocale.languageCode}');

      // ОБНОВЛЕНО: Проверяем, поддерживается ли системный язык (добавлен 'kk')
      if (['ru', 'en', 'kk'].contains(deviceLocale.languageCode)) {
        return Locale(deviceLocale.languageCode);
      }

      // ✅ УБРАНО: debugPrint('⚠️ Системный язык не поддерживается, используем русский по умолчанию');
      // Если не поддерживается, возвращаем русский по умолчанию
      return const Locale('ru', 'RU');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при получении системного языка: $e');
      return const Locale('ru', 'RU');
    }
  }

  // ОБНОВЛЕНО: Получение локализованного названия языка (добавлен казахский)
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'kk':                    // ДОБАВЛЕНО
        return 'Қазақша';           // ДОБАВЛЕНО
      default:
        return 'Unknown';
    }
  }

  // ОБНОВЛЕНО: Получение списка поддерживаемых языков (добавлен казахский)
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {
        'code': 'system',
        'name': 'Системный язык',
        'nativeName': 'System Language',
      },
      {'code': 'ru', 'name': 'Русский', 'nativeName': 'Russian'},
      {'code': 'en', 'name': 'English', 'nativeName': 'Английский'},
      {'code': 'kk', 'name': 'Қазақша', 'nativeName': 'Казахский'},  // ДОБАВЛЕНО
    ];
  }

  // Сброс к настройкам по умолчанию
  Future<void> resetToDefault() async {
    // ✅ УБРАНО: debugPrint('🔄 Сброс языка к настройкам по умолчанию');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_systemLanguageKey);

      _currentLocale = const Locale('ru', 'RU');

      // ✅ УБРАНО: debugPrint('✅ Язык сброшен к русскому по умолчанию');
    } catch (e) {
      // ✅ УБРАНО: debugPrint('❌ Ошибка при сбросе языка: $e');
    }

    // ДОБАВЛЕНО: Синхронизация с WeatherNotificationService при сбросе
    await _syncWeatherServiceLanguage();

    notifyListeners();
  }

  // ДОБАВЛЕНО: Метод для принудительного обновления локали
  Future<void> refreshLanguage() async {
    // ✅ УБРАНО: debugPrint('🔄 Принудительное обновление языка');
    await _loadSavedLanguage();
  }
}