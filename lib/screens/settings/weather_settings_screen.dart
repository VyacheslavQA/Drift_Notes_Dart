// Путь: lib/screens/settings/weather_settings_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/weather_settings_service.dart';

class WeatherSettingsScreen extends StatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  State<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends State<WeatherSettingsScreen> {
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();

  late TemperatureUnit _selectedTemperatureUnit;
  late WindSpeedUnit _selectedWindSpeedUnit;
  late PressureUnit _selectedPressureUnit;
  late double _barometerCalibration;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    setState(() {
      _selectedTemperatureUnit = _weatherSettings.temperatureUnit;
      _selectedWindSpeedUnit = _weatherSettings.windSpeedUnit;
      _selectedPressureUnit = _weatherSettings.pressureUnit;
      _barometerCalibration = _weatherSettings.barometerCalibration;
    });
  }

  Future<void> _updateTemperatureUnit(TemperatureUnit unit) async {
    await _weatherSettings.setTemperatureUnit(unit);
    setState(() {
      _selectedTemperatureUnit = unit;
    });
    _showSavedMessage();
  }

  Future<void> _updateWindSpeedUnit(WindSpeedUnit unit) async {
    await _weatherSettings.setWindSpeedUnit(unit);
    setState(() {
      _selectedWindSpeedUnit = unit;
    });
    _showSavedMessage();
  }

  Future<void> _updatePressureUnit(PressureUnit unit) async {
    await _weatherSettings.setPressureUnit(unit);
    setState(() {
      _selectedPressureUnit = unit;
    });
    _showSavedMessage();
  }

  Future<void> _updateBarometerCalibration(double calibration) async {
    await _weatherSettings.setBarometerCalibration(calibration);
    setState(() {
      _barometerCalibration = calibration;
    });
    _showSavedMessage();
  }

  void _showSavedMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('settings_saved')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getBarometerCalibrationText() {
    // Получаем символ единицы для текущих настроек давления
    final unitSymbol = _weatherSettings.getPressureUnitSymbol();

    // Конвертируем значение калибровки в текущие единицы
    // Калибровка хранится в гПа, но отображаем в выбранных единицах
    double displayValue = _barometerCalibration;

    // Если выбраны мм рт.ст., конвертируем из гПа
    if (_selectedPressureUnit == PressureUnit.mmhg) {
      displayValue = _barometerCalibration / 1.333;
    } else if (_selectedPressureUnit == PressureUnit.inhg) {
      displayValue = _barometerCalibration / 33.8639;
    }
    // Для гПа оставляем как есть

    final sign = displayValue >= 0 ? '+' : '';
    return '$sign${displayValue.toStringAsFixed(1)} $unitSymbol';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('weather_settings'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Единицы измерения
          _buildSectionHeader(localizations.translate('units_of_measurement')),

          // Температура
          _buildTemperatureUnitCard(localizations),
          const SizedBox(height: 12),

          // Скорость ветра
          _buildWindSpeedUnitCard(localizations),
          const SizedBox(height: 12),

          // Давление
          _buildPressureUnitCard(localizations),

          const SizedBox(height: 24),

          // Калибровка
          _buildSectionHeader(localizations.translate('calibration')),

          // Калибровка барометра
          _buildBarometerCalibrationCard(localizations),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTemperatureUnitCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: AppConstants.textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('temperature'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUnitOption(
                  title: localizations.translate('celsius'),
                  subtitle: '°C',
                  isSelected: _selectedTemperatureUnit == TemperatureUnit.celsius,
                  onTap: () => _updateTemperatureUnit(TemperatureUnit.celsius),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  title: localizations.translate('fahrenheit'),
                  subtitle: '°F',
                  isSelected: _selectedTemperatureUnit == TemperatureUnit.fahrenheit,
                  onTap: () => _updateTemperatureUnit(TemperatureUnit.fahrenheit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWindSpeedUnitCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air, color: AppConstants.textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('wind_speed'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUnitOption(
                  title: 'm/s',
                  subtitle: localizations.translate('meters_per_second'),
                  isSelected: _selectedWindSpeedUnit == WindSpeedUnit.ms,
                  onTap: () => _updateWindSpeedUnit(WindSpeedUnit.ms),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitOption(
                  title: 'km/h',
                  subtitle: localizations.translate('kilometers_per_hour'),
                  isSelected: _selectedWindSpeedUnit == WindSpeedUnit.kmh,
                  onTap: () => _updateWindSpeedUnit(WindSpeedUnit.kmh),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitOption(
                  title: 'mph',
                  subtitle: localizations.translate('miles_per_hour'),
                  isSelected: _selectedWindSpeedUnit == WindSpeedUnit.mph,
                  onTap: () => _updateWindSpeedUnit(WindSpeedUnit.mph),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureUnitCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: AppConstants.textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('atmospheric_pressure'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUnitOption(
                  title: 'mmHg',
                  subtitle: localizations.translate('common'),
                  isSelected: _selectedPressureUnit == PressureUnit.mmhg,
                  onTap: () => _updatePressureUnit(PressureUnit.mmhg),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitOption(
                  title: 'hPa',
                  subtitle: localizations.translate('scientific'),
                  isSelected: _selectedPressureUnit == PressureUnit.hpa,
                  onTap: () => _updatePressureUnit(PressureUnit.hpa),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitOption(
                  title: 'inHg',
                  subtitle: localizations.translate('inches'),
                  isSelected: _selectedPressureUnit == PressureUnit.inhg,
                  onTap: () => _updatePressureUnit(PressureUnit.inhg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarometerCalibrationCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppConstants.textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.translate('barometer_calibration'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('pressure_calibration_description'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _barometerCalibration,
                  min: -20.0,
                  max: 20.0,
                  divisions: 80,
                  onChanged: (value) {
                    setState(() {
                      _barometerCalibration = value;
                    });
                  },
                  onChangeEnd: (value) {
                    _updateBarometerCalibration(value);
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getBarometerCalibrationText(),
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : AppConstants.backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? AppConstants.primaryColor.withValues(alpha: 0.8)
                    : AppConstants.textColor.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}