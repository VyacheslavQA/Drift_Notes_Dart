// Путь: lib/screens/settings/weather_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../services/weather_preferences_service.dart';
import '../../localization/app_localizations.dart';
import 'weather_notifications_settings_screen.dart';

class WeatherSettingsScreen extends StatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  State<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends State<WeatherSettingsScreen> {
  final WeatherPreferencesService _preferencesService = WeatherPreferencesService();
  final TextEditingController _calibrationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _calibrationController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    setState(() {
      _calibrationController.text = _preferencesService.pressureCalibration.toStringAsFixed(1);
    });
  }

  Future<void> _saveCalibration() async {
    final value = double.tryParse(_calibrationController.text) ?? 0.0;
    await _preferencesService.setPressureCalibration(value);

    if (mounted) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('settings_saved')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Настройки погоды',
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Уведомления о погоде
          _buildSectionHeader('Уведомления'),
          _buildNotificationsCard(),

          const SizedBox(height: 24),

          // Единицы измерения
          _buildSectionHeader('Единицы измерения'),
          _buildTemperatureUnitCard(),
          const SizedBox(height: 12),
          _buildWindSpeedUnitCard(),
          const SizedBox(height: 12),
          _buildPressureUnitCard(),

          const SizedBox(height: 24),

          // Калибровка барометра
          _buildSectionHeader('Калибровка барометра'),
          _buildCalibrationCard(),

          const SizedBox(height: 24),

          // Сброс настроек
          _buildResetCard(),

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

  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.amber),
        title: Text(
          'Уведомления о погоде',
          style: TextStyle(color: AppConstants.textColor),
        ),
        subtitle: Text(
          'Настройка уведомлений о благоприятных условиях',
          style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeatherNotificationsSettingsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemperatureUnitCard() {
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
              Icon(Icons.thermostat, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Text(
                'Температура',
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
                  'Цельсий (°C)',
                  _preferencesService.temperatureUnit == TemperatureUnit.celsius,
                      () => _setTemperatureUnit(TemperatureUnit.celsius),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  'Фаренгейт (°F)',
                  _preferencesService.temperatureUnit == TemperatureUnit.fahrenheit,
                      () => _setTemperatureUnit(TemperatureUnit.fahrenheit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWindSpeedUnitCard() {
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
              Icon(Icons.air, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Скорость ветра',
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
                  'Метры/сек (м/с)',
                  _preferencesService.windSpeedUnit == WindSpeedUnit.metersPerSecond,
                      () => _setWindSpeedUnit(WindSpeedUnit.metersPerSecond),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  'Км/час (км/ч)',
                  _preferencesService.windSpeedUnit == WindSpeedUnit.kilometersPerHour,
                      () => _setWindSpeedUnit(WindSpeedUnit.kilometersPerHour),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureUnitCard() {
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
              Icon(Icons.speed, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Атмосферное давление',
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
                  'мм рт.ст.',
                  _preferencesService.pressureUnit == PressureUnit.mmHg,
                      () => _setPressureUnit(PressureUnit.mmHg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  'Гектопаскали (гПа)',
                  _preferencesService.pressureUnit == PressureUnit.hPa,
                      () => _setPressureUnit(PressureUnit.hPa),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard() {
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
              Icon(Icons.tune, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Корректировка показаний',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Настройте корректировку на основе домашнего барометра. Значение в гПа будет добавлено ко всем показаниям давления.',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _calibrationController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    labelText: 'Корректировка (гПа)',
                    labelStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
                    hintText: '0.0',
                    hintStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.5)),
                    prefixText: _calibrationController.text.startsWith('-') ? '' : '+',
                    suffixText: 'гПа',
                    filled: true,
                    fillColor: AppConstants.backgroundColor.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppConstants.primaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveCalibration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Сохранить'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Пример: если домашний барометр показывает на 3 гПа больше, введите +3.0',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 13,
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

  Widget _buildResetCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.restore, color: Colors.grey),
        title: Text(
          'Сбросить настройки',
          style: TextStyle(color: AppConstants.textColor),
        ),
        subtitle: Text(
          'Вернуть все настройки к значениям по умолчанию',
          style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showResetConfirmation,
      ),
    );
  }

  Widget _buildUnitOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : AppConstants.backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppConstants.primaryColor, width: 2)
              : Border.all(color: AppConstants.textColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppConstants.primaryColor : AppConstants.textColor.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setTemperatureUnit(TemperatureUnit unit) async {
    await _preferencesService.setTemperatureUnit(unit);
    setState(() {});
  }

  Future<void> _setWindSpeedUnit(WindSpeedUnit unit) async {
    await _preferencesService.setWindSpeedUnit(unit);
    setState(() {});
  }

  Future<void> _setPressureUnit(PressureUnit unit) async {
    await _preferencesService.setPressureUnit(unit);
    setState(() {});
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Сброс настроек',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите сбросить все настройки погоды к значениям по умолчанию?',
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _preferencesService.resetToDefaults();
      _loadCurrentSettings();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки сброшены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}