// Путь: lib/utils/countries_data.dart

import 'package:flutter/material.dart';
import '../services/geography_service.dart';

class CountriesData {
  static final GeographyService _geographyService = GeographyService();

  // Статические данные как fallback (на случай если сервис недоступен)
  static final List<String> _fallbackCountries = [
    'Россия',
    'Беларусь',
    'Украина',
    'Казахстан',
    'Узбекистан',
    'Кыргызстан',
    'Таджикистан',
    'Туркменистан',
    'Азербайджан',
    'Армения',
    'Грузия',
    'Молдова',
    'Латвия',
    'Литва',
    'Эстония',
  ];

  static final Map<String, List<String>> _fallbackCitiesByCountry = {
    'Россия': [
      'Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург',
      'Нижний Новгород', 'Казань', 'Челябинск', 'Омск', 'Самара',
      'Ростов-на-Дону', 'Уфа', 'Красноярск', 'Пермь', 'Воронеж', 'Волгоград',
      'Краснодар', 'Саратов', 'Тюмень', 'Тольятти', 'Ижевск',
    ],
    'Беларусь': [
      'Минск', 'Гомель', 'Могилев', 'Витебск', 'Гродно',
      'Брест', 'Бобруйск', 'Барановичи', 'Борисов', 'Пинск',
    ],
    'Казахстан': [
      'Алматы', 'Нур-Султан', 'Шымкент', 'Караганда', 'Актобе',
      'Тараз', 'Павлодар', 'Усть-Каменогорск', 'Семей', 'Атырау',
      'Костанай', 'Кызылорда', 'Уральск', 'Петропавловск', 'Актау',
    ],
    'Украина': [
      'Киев', 'Харьков', 'Одесса', 'Днепр', 'Донецк',
      'Запорожье', 'Львов', 'Кривой Рог', 'Николаев', 'Мариуполь',
    ],
  };

  /// Получить список локализованных стран
  static Future<List<String>> getLocalizedCountries(BuildContext context) async {
    try {
      final countries = await _geographyService.getLocalizedCountries(context);
      if (countries.isNotEmpty) {
        return countries;
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения локализованных стран: $e');
    }

    // Fallback на статические данные
    return _fallbackCountries;
  }

  /// Получить список локализованных городов для страны
  static Future<List<String>> getLocalizedCitiesForCountry(
      String countryName,
      BuildContext context
      ) async {
    try {
      final cities = await _geographyService.getLocalizedCitiesForCountry(
          countryName,
          context
      );
      if (cities.isNotEmpty) {
        return cities;
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения локализованных городов: $e');
    }

    // Fallback на статические данные
    return _fallbackCitiesByCountry[countryName] ?? [];
  }

  // Старые методы для обратной совместимости
  @Deprecated('Используйте getLocalizedCountries() вместо этого')
  static List<String> get countries => _fallbackCountries;

  @Deprecated('Используйте getLocalizedCitiesForCountry() вместо этого')
  static List<String> getCitiesForCountry(String country) {
    return _fallbackCitiesByCountry[country] ?? [];
  }

  /// Предзагрузить географические данные для быстрого доступа
  static Future<void> preloadGeographyData(BuildContext context) async {
    try {
      await _geographyService.getLocalizedCountries(context);
      debugPrint('✅ Географические данные предзагружены');
    } catch (e) {
      debugPrint('❌ Ошибка предзагрузки географических данных: $e');
    }
  }

  /// Очистить кэш географических данных (полезно при смене языка)
  static void clearGeographyCache() {
    _geographyService.clearCache();
    debugPrint('🗑️ Кэш географических данных очищен');
  }

  /// Получить информацию о кэше
  static Map<String, dynamic> getCacheInfo() {
    return _geographyService.getCacheInfo();
  }
}