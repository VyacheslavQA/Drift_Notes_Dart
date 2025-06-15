// Путь: lib/screens/settings/weather_settings_screen.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import 'dart:async';
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

  // ДОБАВЛЕНО: Флаг изменений для отслеживания необходимости сохранения
  bool _hasUnsavedChanges = false;

  // Для управления быстрым изменением калибровки
  Timer? _rapidChangeTimer;
  bool _isRapidChanging = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _rapidChangeTimer?.cancel();
    super.dispose();
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
    setState(() {
      _selectedTemperatureUnit = unit;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _updateWindSpeedUnit(WindSpeedUnit unit) async {
    setState(() {
      _selectedWindSpeedUnit = unit;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _updatePressureUnit(PressureUnit unit) async {
    setState(() {
      _selectedPressureUnit = unit;
      _hasUnsavedChanges = true;
    });
    // Обновляем отображение калибровки для новых единиц
    setState(() {});
  }

  Future<void> _updateBarometerCalibration(double calibration) async {
    setState(() {
      _barometerCalibration = calibration.clamp(-50.0, 50.0);
      _hasUnsavedChanges = true;
    });
  }

  // НОВЫЙ МЕТОД: Изменение калибровки на дельту с учетом текущих единиц
  void _adjustCalibration(double delta) {
    // Конвертируем дельту в мбар в зависимости от текущих единиц
    double deltaInMbar;
    switch (_selectedPressureUnit) {
      case PressureUnit.mmhg:
        deltaInMbar = delta * 1.333; // дельта в мм рт.ст. → мбар
        break;
      case PressureUnit.hpa:
        deltaInMbar = delta; // дельта уже в гПа (= мбар)
        break;
      case PressureUnit.inhg:
        deltaInMbar = delta * 33.8639; // дельта в inHg → мбар
        break;
    }

    final newValue = (_barometerCalibration + deltaInMbar).clamp(-50.0, 50.0);
    if (newValue != _barometerCalibration) {
      _updateBarometerCalibration(newValue);
    }
  }

  // НОВЫЙ МЕТОД: Начало быстрого изменения (долгое нажатие) с учетом единиц
  void _startRapidChange(double delta) {
    _isRapidChanging = true;
    _adjustCalibration(delta);

    _rapidChangeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _adjustCalibration(delta);
    });
  }

  // НОВЫЙ МЕТОД: Остановка быстрого изменения
  void _stopRapidChange() {
    _rapidChangeTimer?.cancel();
    _rapidChangeTimer = null;
    _isRapidChanging = false;
  }

  // НОВЫЙ МЕТОД: Сброс калибровки
  void _resetCalibration() {
    _updateBarometerCalibration(0.0);
  }

  // НОВЫЙ МЕТОД: Сохранение всех настроек
  Future<void> _saveAllSettings() async {
    try {
      await _weatherSettings.setTemperatureUnit(_selectedTemperatureUnit);
      await _weatherSettings.setWindSpeedUnit(_selectedWindSpeedUnit);
      await _weatherSettings.setPressureUnit(_selectedPressureUnit);
      await _weatherSettings.setBarometerCalibration(_barometerCalibration);

      setState(() {
        _hasUnsavedChanges = false;
      });

      _showSavedMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  // НОВЫЙ МЕТОД: Отмена изменений
  void _cancelChanges() {
    setState(() {
      _selectedTemperatureUnit = _weatherSettings.temperatureUnit;
      _selectedWindSpeedUnit = _weatherSettings.windSpeedUnit;
      _selectedPressureUnit = _weatherSettings.pressureUnit;
      _barometerCalibration = _weatherSettings.barometerCalibration;
      _hasUnsavedChanges = false;
    });
  }

  void _showSavedMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('settings_saved') ?? 'Настройки сохранены'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('error_saving_settings') ?? 'Ошибка сохранения настроек'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // УЛУЧШЕННЫЙ МЕТОД: Отображение калибровки с использованием нового сервиса
  String _getBarometerCalibrationText() {
    _weatherSettings.setLocale(AppLocalizations.of(context).locale.languageCode);

    if (_barometerCalibration == 0.0) {
      final localizations = AppLocalizations.of(context);
      return localizations.translate('no_calibration') ?? 'Без калибровки';
    }

    // Конвертируем калибровку в текущие единицы для отображения
    double displayValue = _barometerCalibration;
    String unitSymbol;

    switch (_selectedPressureUnit) {
      case PressureUnit.mmhg:
        displayValue = _barometerCalibration / 1.333;
        unitSymbol = AppLocalizations.of(context).locale.languageCode == 'en' ? 'mmHg' : 'мм рт.ст.';
        break;
      case PressureUnit.hpa:
        displayValue = _barometerCalibration;
        unitSymbol = AppLocalizations.of(context).locale.languageCode == 'en' ? 'hPa' : 'гПа';
        break;
      case PressureUnit.inhg:
        displayValue = _barometerCalibration / 33.8639;
        unitSymbol = 'inHg';
        break;
    }

    final sign = displayValue >= 0 ? '+' : '';
    return '$sign${displayValue.toStringAsFixed(1)} $unitSymbol';
  }

  // НОВЫЙ МЕТОД: Диалог подтверждения при несохраненных изменениях
  Future<bool?> _showUnsavedChangesDialog() async {
    final localizations = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Text(
            localizations.translate('unsaved_changes') ?? 'Несохраненные изменения',
            style: TextStyle(color: AppConstants.textColor),
          ),
          content: Text(
            localizations.translate('unsaved_changes_message') ??
                'У вас есть несохраненные изменения. Хотите их сохранить?',
            style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Выйти без сохранения
              child: Text(
                localizations.translate('discard') ?? 'Не сохранять',
                style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Остаться
              child: Text(
                localizations.translate('cancel') ?? 'Отмена',
                style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(false);
                await _saveAllSettings();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.translate('save') ?? 'Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    _weatherSettings.setLocale(localizations.locale.languageCode);

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
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
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _showUnsavedChangesDialog();
                if (shouldPop == true && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _cancelChanges,
                child: Text(
                  localizations.translate('cancel') ?? 'Отмена',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
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

                  const SizedBox(height: 100), // Место для кнопки сохранения
                ],
              ),
            ),
          ],
        ),

        // Кнопка сохранения внизу экрана
        bottomNavigationBar: _hasUnsavedChanges
            ? Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _saveAllSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('save_settings') ?? 'Сохранить настройки',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            : null,
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
                  isSelected:
                  _selectedTemperatureUnit == TemperatureUnit.celsius,
                  onTap: () => _updateTemperatureUnit(TemperatureUnit.celsius),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  title: localizations.translate('fahrenheit'),
                  subtitle: '°F',
                  isSelected:
                  _selectedTemperatureUnit == TemperatureUnit.fahrenheit,
                  onTap:
                      () => _updateTemperatureUnit(TemperatureUnit.fahrenheit),
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

  // НОВЫЙ МЕТОД: Калибровка барометра со стрелочками
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
          const SizedBox(height: 20),

          // Главный контрол со стрелочками
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.textColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Левая стрелка (уменьшение)
                GestureDetector(
                  onTap: () => _adjustCalibration(-0.1),
                  onLongPressStart: (_) => _startRapidChange(-0.1),
                  onLongPressEnd: (_) => _stopRapidChange(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                ),

                // Центральное значение
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getBarometerCalibrationText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Правая стрелка (увеличение)
                GestureDetector(
                  onTap: () => _adjustCalibration(0.1),
                  onLongPressStart: (_) => _startRapidChange(0.1),
                  onLongPressEnd: (_) => _stopRapidChange(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка сброса (если есть калибровка)
          if (_barometerCalibration != 0.0)
            Center(
              child: TextButton.icon(
                onPressed: _resetCalibration,
                icon: Icon(
                  Icons.refresh,
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
                label: Text(
                  localizations.translate('reset') ?? 'Сброс',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Подсказка
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppConstants.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.translate('calibration_tip') ??
                        'Касание: ±0.1, Долгое нажатие: быстрое изменение ±0.5',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
          color:
          isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : AppConstants.backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
            isSelected
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
                color:
                isSelected
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
                color:
                isSelected
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