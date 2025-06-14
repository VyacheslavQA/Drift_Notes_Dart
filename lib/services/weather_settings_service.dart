// Путь: lib/services/weather_settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum TemperatureUnit { celsius, fahrenheit }

enum WindSpeedUnit { ms, kmh, mph }

enum PressureUnit { mmhg, hpa, inhg }

class WeatherSettingsService {
  static final WeatherSettingsService _instance =
      WeatherSettingsService._internal();
  factory WeatherSettingsService() => _instance;
  WeatherSettingsService._internal();

  // Ключи для SharedPreferences
  static const String _temperatureUnitKey = 'weather_temperature_unit';
  static const String _windSpeedUnitKey = 'weather_wind_speed_unit';
  static const String _pressureUnitKey = 'weather_pressure_unit';
  static const String _barometerCalibrationKey =
      'weather_barometer_calibration';

  // Настройки по умолчанию
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  WindSpeedUnit _windSpeedUnit = WindSpeedUnit.ms;
  PressureUnit _pressureUnit = PressureUnit.mmhg;
  double _barometerCalibration = 0.0;

  // Геттеры
  TemperatureUnit get temperatureUnit => _temperatureUnit;
  WindSpeedUnit get windSpeedUnit => _windSpeedUnit;
  PressureUnit get pressureUnit => _pressureUnit;
  double get barometerCalibration => _barometerCalibration;

  // Инициализация - загрузка настроек
  Future<void> initialize() async {
    await _loadSettings();
  }

  // Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Температура
      final tempIndex = prefs.getInt(_temperatureUnitKey) ?? 0;
      _temperatureUnit = TemperatureUnit.values[tempIndex];

      // Скорость ветра
      final windIndex = prefs.getInt(_windSpeedUnitKey) ?? 0;
      _windSpeedUnit = WindSpeedUnit.values[windIndex];

      // Давление
      final pressureIndex = prefs.getInt(_pressureUnitKey) ?? 0;
      _pressureUnit = PressureUnit.values[pressureIndex];

      // Калибровка барометра
      _barometerCalibration = prefs.getDouble(_barometerCalibrationKey) ?? 0.0;

      debugPrint(
        '🌤️ Настройки погоды загружены: T:$_temperatureUnit, W:$_windSpeedUnit, P:$_pressureUnit',
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки настроек погоды: $e');
    }
  }

  // Сохранение настроек
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_temperatureUnitKey, _temperatureUnit.index);
      await prefs.setInt(_windSpeedUnitKey, _windSpeedUnit.index);
      await prefs.setInt(_pressureUnitKey, _pressureUnit.index);
      await prefs.setDouble(_barometerCalibrationKey, _barometerCalibration);

      debugPrint('✅ Настройки погоды сохранены');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настроек погоды: $e');
    }
  }

  // Установка единицы температуры
  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    _temperatureUnit = unit;
    await _saveSettings();
  }

  // Установка единицы скорости ветра
  Future<void> setWindSpeedUnit(WindSpeedUnit unit) async {
    _windSpeedUnit = unit;
    await _saveSettings();
  }

  // Установка единицы давления
  Future<void> setPressureUnit(PressureUnit unit) async {
    _pressureUnit = unit;
    await _saveSettings();
  }

  // Установка калибровки барометра
  Future<void> setBarometerCalibration(double calibration) async {
    _barometerCalibration = calibration;
    await _saveSettings();
  }

  // Конвертация температуры
  double convertTemperature(double celsius) {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return (celsius * 9 / 5) + 32;
    }
  }

  // Конвертация скорости ветра (из км/ч)
  double convertWindSpeed(double kmh) {
    switch (_windSpeedUnit) {
      case WindSpeedUnit.ms:
        return kmh / 3.6;
      case WindSpeedUnit.kmh:
        return kmh;
      case WindSpeedUnit.mph:
        return kmh / 1.609344;
    }
  }

  // Конвертация давления (из мбар)
  double convertPressure(double mbar) {
    double calibratedPressure = mbar + _barometerCalibration;

    switch (_pressureUnit) {
      case PressureUnit.mmhg:
        return calibratedPressure / 1.333;
      case PressureUnit.hpa:
        return calibratedPressure;
      case PressureUnit.inhg:
        return calibratedPressure / 33.8639;
    }
  }

  // Получение символа единицы температуры
  String getTemperatureUnitSymbol() {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return '°C';
      case TemperatureUnit.fahrenheit:
        return '°F';
    }
  }

  // Получение символа единицы скорости ветра
  String getWindSpeedUnitSymbol() {
    switch (_windSpeedUnit) {
      case WindSpeedUnit.ms:
        return 'м/с';
      case WindSpeedUnit.kmh:
        return 'км/ч';
      case WindSpeedUnit.mph:
        return 'mph';
    }
  }

  // Получение символа единицы давления
  String getPressureUnitSymbol() {
    switch (_pressureUnit) {
      case PressureUnit.mmhg:
        return 'мм рт.ст.';
      case PressureUnit.hpa:
        return 'гПа';
      case PressureUnit.inhg:
        return 'inHg';
    }
  }

  // Получение полного названия единицы температуры
  String getTemperatureUnitName() {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return 'Цельсий';
      case TemperatureUnit.fahrenheit:
        return 'Фаренгейт';
    }
  }

  // Получение полного названия единицы скорости ветра
  String getWindSpeedUnitName() {
    switch (_windSpeedUnit) {
      case WindSpeedUnit.ms:
        return 'Метры в секунду';
      case WindSpeedUnit.kmh:
        return 'Километры в час';
      case WindSpeedUnit.mph:
        return 'Мили в час';
    }
  }

  // Получение полного названия единицы давления
  String getPressureUnitName() {
    switch (_pressureUnit) {
      case PressureUnit.mmhg:
        return 'Миллиметры ртутного столба';
      case PressureUnit.hpa:
        return 'Гектопаскали';
      case PressureUnit.inhg:
        return 'Дюймы ртутного столба';
    }
  }

  // Форматирование температуры с единицей
  String formatTemperature(double celsius, {bool showUnit = true}) {
    final converted = convertTemperature(celsius);
    final rounded = converted.round();
    return showUnit ? '$rounded${getTemperatureUnitSymbol()}' : '$rounded';
  }

  // Форматирование скорости ветра с единицей
  String formatWindSpeed(double kmh, {bool showUnit = true, int decimals = 0}) {
    final converted = convertWindSpeed(kmh);
    final formatted =
        decimals == 0
            ? converted.round().toString()
            : converted.toStringAsFixed(decimals);
    return showUnit ? '$formatted ${getWindSpeedUnitSymbol()}' : formatted;
  }

  // Форматирование давления с единицей
  String formatPressure(double mbar, {bool showUnit = true, int decimals = 0}) {
    final converted = convertPressure(mbar);
    final formatted =
        decimals == 0
            ? converted.round().toString()
            : converted.toStringAsFixed(decimals);
    return showUnit ? '$formatted ${getPressureUnitSymbol()}' : formatted;
  }
}
