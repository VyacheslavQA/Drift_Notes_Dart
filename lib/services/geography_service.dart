// Путь: lib/services/geography_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class GeographyService {
  static final GeographyService _instance = GeographyService._internal();
  factory GeographyService() => _instance;
  GeographyService._internal();

  // Кэшированные данные для каждого языка
  Map<String, Map<String, dynamic>> _geographyCache = {};

  /// Загрузить географические данные для указанного языка
  Future<Map<String, dynamic>> _loadGeographyData(String languageCode) async {
    // Проверяем кэш
    if (_geographyCache.containsKey(languageCode)) {
      return _geographyCache[languageCode]!;
    }

    try {
      // Загружаем JSON файл
      final jsonString = await rootBundle.loadString(
          'assets/localization/geography/geography_$languageCode.json'
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      // Кэшируем данные
      _geographyCache[languageCode] = data;

      debugPrint('🌍 Географические данные загружены для языка: $languageCode');
      return data;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки географических данных для $languageCode: $e');

      // Fallback на русский язык
      if (languageCode != 'ru') {
        debugPrint('🔄 Попытка загрузки русских данных как fallback');
        return await _loadGeographyData('ru');
      }

      // Если и русский не загружается, возвращаем пустые данные
      return {
        'countries': <String, String>{},
        'cities': <String, Map<String, String>>{},
      };
    }
  }

  /// Получить список локализованных стран
  Future<List<String>> getLocalizedCountries(BuildContext context) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final countries = data['countries'] as Map<String, dynamic>? ?? {};

      // Возвращаем отсортированный список названий стран
      final countryNames = countries.values.cast<String>().toList();
      countryNames.sort();

      return countryNames;
    } catch (e) {
      debugPrint('❌ Ошибка при получении списка стран: $e');
      return [];
    }
  }

  /// Получить список локализованных городов для указанной страны
  Future<List<String>> getLocalizedCitiesForCountry(
      String countryName,
      BuildContext context
      ) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final countries = data['countries'] as Map<String, dynamic>? ?? {};
      final cities = data['cities'] as Map<String, dynamic>? ?? {};

      // Находим ключ страны по её локализованному названию
      String? countryKey;
      for (final entry in countries.entries) {
        if (entry.value == countryName) {
          countryKey = entry.key;
          break;
        }
      }

      if (countryKey == null) {
        debugPrint('❌ Страна не найдена: $countryName');
        return [];
      }

      // Получаем города для найденной страны
      final countryCities = cities[countryKey] as Map<String, dynamic>? ?? {};
      final cityNames = countryCities.values.cast<String>().toList();
      cityNames.sort();

      return cityNames;
    } catch (e) {
      debugPrint('❌ Ошибка при получении городов для страны $countryName: $e');
      return [];
    }
  }

  /// Получить ключ страны по её локализованному названию
  Future<String?> getCountryKeyByName(String countryName, BuildContext context) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final countries = data['countries'] as Map<String, dynamic>? ?? {};

      for (final entry in countries.entries) {
        if (entry.value == countryName) {
          return entry.key;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при поиске ключа страны: $e');
      return null;
    }
  }

  /// Получить ключ города по его локализованному названию и стране
  Future<String?> getCityKeyByName(
      String cityName,
      String countryName,
      BuildContext context
      ) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final countries = data['countries'] as Map<String, dynamic>? ?? {};
      final cities = data['cities'] as Map<String, dynamic>? ?? {};

      // Находим ключ страны
      String? countryKey;
      for (final entry in countries.entries) {
        if (entry.value == countryName) {
          countryKey = entry.key;
          break;
        }
      }

      if (countryKey == null) return null;

      // Находим ключ города
      final countryCities = cities[countryKey] as Map<String, dynamic>? ?? {};
      for (final entry in countryCities.entries) {
        if (entry.value == cityName) {
          return entry.key;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при поиске ключа города: $e');
      return null;
    }
  }

  /// Получить локализованное название страны по ключу
  Future<String?> getCountryNameByKey(String countryKey, BuildContext context) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final countries = data['countries'] as Map<String, dynamic>? ?? {};

      return countries[countryKey] as String?;
    } catch (e) {
      debugPrint('❌ Ошибка при получении названия страны: $e');
      return null;
    }
  }

  /// Получить локализованное название города по ключу
  Future<String?> getCityNameByKey(
      String cityKey,
      String countryKey,
      BuildContext context
      ) async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final data = await _loadGeographyData(languageCode);
      final cities = data['cities'] as Map<String, dynamic>? ?? {};

      final countryCities = cities[countryKey] as Map<String, dynamic>? ?? {};
      return countryCities[cityKey] as String?;
    } catch (e) {
      debugPrint('❌ Ошибка при получении названия города: $e');
      return null;
    }
  }

  /// Очистить кэш (полезно при смене языка)
  void clearCache() {
    _geographyCache.clear();
    debugPrint('🗑️ Кэш географических данных очищен');
  }

  /// Предзагрузить данные для указанного языка
  Future<void> preloadData(String languageCode) async {
    await _loadGeographyData(languageCode);
  }

  /// Получить статистику кэша
  Map<String, dynamic> getCacheInfo() {
    return {
      'cachedLanguages': _geographyCache.keys.toList(),
      'cacheSize': _geographyCache.length,
    };
  }
}