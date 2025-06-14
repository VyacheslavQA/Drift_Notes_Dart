// Путь: lib/services/weather_preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum TemperatureUnit { celsius, fahrenheit }

enum WindSpeedUnit { metersPerSecond, kilometersPerHour }

enum PressureUnit { mmHg, hPa }

class WeatherPreferencesService {
  static final WeatherPreferencesService _instance =
      WeatherPreferencesService._internal();
  factory WeatherPreferencesService() => _instance;
  WeatherPreferencesService._internal();

  // Ключи для SharedPreferences
  static const String _temperatureUnitKey = 'weather_temperature_unit';
  static const String _windSpeedUnitKey = 'weather_wind_speed_unit';
  static const String _pressureUnitKey = 'weather_pressure_unit';
  static const String _pressureCalibrationKey = 'weather_pressure_calibration';

  // Текущие настройки
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  WindSpeedUnit _windSpeedUnit = WindSpeedUnit.metersPerSecond;
  PressureUnit _pressureUnit = PressureUnit.mmHg;
  double _pressureCalibration = 0.0; // Корректировка в гПа

  // Геттеры
  TemperatureUnit get temperatureUnit => _temperatureUnit;
  WindSpeedUnit get windSpeedUnit => _windSpeedUnit;
  PressureUnit get pressureUnit => _pressureUnit;
  double get pressureCalibration => _pressureCalibration;

  /// Инициализация сервиса - загружаем сохраненные настройки
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Загружаем единицы температуры
      final tempUnitIndex = prefs.getInt(_temperatureUnitKey) ?? 0;
      _temperatureUnit = TemperatureUnit.values[tempUnitIndex];

      // Загружаем единицы скорости ветра
      final windUnitIndex = prefs.getInt(_windSpeedUnitKey) ?? 0;
      _windSpeedUnit = WindSpeedUnit.values[windUnitIndex];

      // Загружаем единицы давления
      final pressureUnitIndex = prefs.getInt(_pressureUnitKey) ?? 0;
      _pressureUnit = PressureUnit.values[pressureUnitIndex];

      // Загружаем калибровку барометра
      _pressureCalibration = prefs.getDouble(_pressureCalibrationKey) ?? 0.0;

      debugPrint(
        '🌤️ Настройки погоды загружены: T=${_temperatureUnit}, W=${_windSpeedUnit}, P=${_pressureUnit}, Cal=${_pressureCalibration}',
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки настроек погоды: $e');
    }
  }

  /// Сохранение единиц температуры
  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    _temperatureUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_temperatureUnitKey, unit.index);
    debugPrint('💾 Единицы температуры сохранены: $unit');
  }

  /// Сохранение единиц скорости ветра
  Future<void> setWindSpeedUnit(WindSpeedUnit unit) async {
    _windSpeedUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_windSpeedUnitKey, unit.index);
    debugPrint('💾 Единицы скорости ветра сохранены: $unit');
  }

  /// Сохранение единиц давления
  Future<void> setPressureUnit(PressureUnit unit) async {
    _pressureUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pressureUnitKey, unit.index);
    debugPrint('💾 Единицы давления сохранены: $unit');
  }

  /// Сохранение калибровки барометра
  Future<void> setPressureCalibration(double calibration) async {
    _pressureCalibration = calibration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pressureCalibrationKey, calibration);
    debugPrint('💾 Калибровка барометра сохранена: $calibration гПа');
  }

  // === МЕТОДЫ КОНВЕРТАЦИИ ===

  /// Конвертация температуры
  double convertTemperature(double celsius) {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return (celsius * 9 / 5) + 32;
    }
  }

  /// Форматирование температуры с единицами
  String formatTemperature(double celsius, {bool showUnit = true}) {
    final converted = convertTemperature(celsius);
    final unit = showUnit ? getTemperatureUnitSymbol() : '';
    return '${converted.round()}$unit';
  }

  /// Конвертация скорости ветра (из км/ч)
  double convertWindSpeed(double kph) {
    switch (_windSpeedUnit) {
      case WindSpeedUnit.metersPerSecond:
        return kph / 3.6;
      case WindSpeedUnit.kilometersPerHour:
        return kph;
    }
  }

  /// Форматирование скорости ветра с единицами
  String formatWindSpeed(double kph, {bool showUnit = true}) {
    final converted = convertWindSpeed(kph);
    final unit = showUnit ? getWindSpeedUnitSymbol() : '';
    return '${converted.round()}$unit';
  }

  /// Конвертация давления с применением калибровки (из мб/гПа)
  double convertPressure(double mb) {
    // Сначала применяем калибровку
    final calibrated = mb + _pressureCalibration;

    switch (_pressureUnit) {
      case PressureUnit.hPa:
        return calibrated;
      case PressureUnit.mmHg:
        return calibrated / 1.333;
    }
  }

  /// Форматирование давления с единицами
  String formatPressure(double mb, {bool showUnit = true}) {
    final converted = convertPressure(mb);
    final unit = showUnit ? getPressureUnitSymbol() : '';
    return '${converted.round()}$unit';
  }

  // === ПОЛУЧЕНИЕ СИМВОЛОВ ЕДИНИЦ ===

  String getTemperatureUnitSymbol() {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return '°C';
      case TemperatureUnit.fahrenheit:
        return '°F';
    }
  }

  String getWindSpeedUnitSymbol() {
    switch (_windSpeedUnit) {
      case WindSpeedUnit.metersPerSecond:
        return ' м/с';
      case WindSpeedUnit.kilometersPerHour:
        return ' км/ч';
    }
  }

  String getPressureUnitSymbol() {
    switch (_pressureUnit) {
      case PressureUnit.hPa:
        return ' гПа';
      case PressureUnit.mmHg:
        return ' мм';
    }
  }

  // === ПОЛУЧЕНИЕ ЛОКАЛИЗОВАННЫХ НАЗВАНИЙ ===

  String getTemperatureUnitName(BuildContext context) {
    // TODO: Добавить локализацию
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return 'Цельсий (°C)';
      case TemperatureUnit.fahrenheit:
        return 'Фаренгейт (°F)';
    }
  }

  String getWindSpeedUnitName(BuildContext context) {
    // TODO: Добавить локализацию
    switch (_windSpeedUnit) {
      case WindSpeedUnit.metersPerSecond:
        return 'Метры в секунду (м/с)';
      case WindSpeedUnit.kilometersPerHour:
        return 'Километры в час (км/ч)';
    }
  }

  String getPressureUnitName(BuildContext context) {
    // TODO: Добавить локализацию
    switch (_pressureUnit) {
      case PressureUnit.hPa:
        return 'Гектопаскали (гПа)';
      case PressureUnit.mmHg:
        return 'Миллиметры рт. ст. (мм рт.ст.)';
    }
  }

  /// Получение значения калибровки с единицами для отображения
  String getFormattedCalibration() {
    if (_pressureCalibration == 0) return '0';

    final sign = _pressureCalibration > 0 ? '+' : '';
    return '$sign${_pressureCalibration.toStringAsFixed(1)} гПа';
  }

  /// Сброс всех настроек к значениям по умолчанию
  Future<void> resetToDefaults() async {
    await setTemperatureUnit(TemperatureUnit.celsius);
    await setWindSpeedUnit(WindSpeedUnit.metersPerSecond);
    await setPressureUnit(PressureUnit.mmHg);
    await setPressureCalibration(0.0);
    debugPrint('🔄 Настройки погоды сброшены к значениям по умолчанию');
  }
}
