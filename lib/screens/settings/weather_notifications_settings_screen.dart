// Путь: lib/screens/settings/weather_notifications_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_alert_model.dart';
import '../../services/weather_notification_service.dart';
import '../../localization/app_localizations.dart';

class WeatherNotificationsSettingsScreen extends StatefulWidget {
  const WeatherNotificationsSettingsScreen({super.key});

  @override
  State<WeatherNotificationsSettingsScreen> createState() => _WeatherNotificationsSettingsScreenState();
}

class _WeatherNotificationsSettingsScreenState extends State<WeatherNotificationsSettingsScreen> {
  final WeatherNotificationService _notificationService = WeatherNotificationService();
  late WeatherNotificationSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _settings = _notificationService.settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _notificationService.updateSettings(_settings);
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.translate('weather_notifications'),
            style: TextStyle(color: AppConstants.textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('weather_notifications'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Общие настройки
          _buildSectionHeader(localizations.translate('general_settings')),
          _buildMainToggle(localizations),

          if (_settings.enabled) ...[
            const SizedBox(height: 24),

            // Типы уведомлений
            _buildSectionHeader(localizations.translate('notification_types')),
            _buildNotificationTypeCard(
              localizations.translate('pressure_change_notifications'),
              localizations.translate('pressure_change_notifications_desc'),
              Icons.speed,
              _settings.pressureChangeEnabled,
                  (value) => setState(() {
                _settings = _settings.copyWith(pressureChangeEnabled: value);
              }),
            ),

            _buildNotificationTypeCard(
              localizations.translate('favorable_conditions_notifications'),
              localizations.translate('favorable_conditions_notifications_desc'),
              Icons.wb_sunny,
              _settings.favorableConditionsEnabled,
                  (value) => setState(() {
                _settings = _settings.copyWith(favorableConditionsEnabled: value);
              }),
            ),

            _buildNotificationTypeCard(
              localizations.translate('storm_warning_notifications'),
              localizations.translate('storm_warning_notifications_desc'),
              Icons.warning,
              _settings.stormWarningEnabled,
                  (value) => setState(() {
                _settings = _settings.copyWith(stormWarningEnabled: value);
              }),
            ),

            _buildNotificationTypeCard(
              localizations.translate('daily_forecast_notifications'),
              localizations.translate('daily_forecast_notifications_desc'),
              Icons.today,
              _settings.dailyForecastEnabled,
                  (value) => setState(() {
                _settings = _settings.copyWith(dailyForecastEnabled: value);
              }),
            ),

            const SizedBox(height: 24),

            // Настройки порогов
            _buildSectionHeader(localizations.translate('threshold_settings')),

            if (_settings.pressureChangeEnabled)
              _buildThresholdSetting(
                localizations.translate('pressure_threshold'),
                localizations.translate('pressure_threshold_desc'),
                _settings.pressureThreshold,
                'мм рт.ст.',
                1.0,
                20.0,
                    (value) => setState(() {
                  _settings = _settings.copyWith(pressureThreshold: value);
                }),
              ),

            const SizedBox(height: 24),

            // Временные настройки
            _buildSectionHeader(localizations.translate('time_settings')),

            if (_settings.dailyForecastEnabled)
              _buildDetailedTimeSetting(),

            const SizedBox(height: 24),

            // Кнопки действий
            _buildActionButtons(),
          ],

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

  Widget _buildMainToggle(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_active,
              color: AppConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('weather_notifications'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.translate('weather_notifications_desc'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings.enabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(enabled: value);
              });
            },
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeCard(
      String title,
      String description,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.textColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSetting(
      String title,
      String description,
      double value,
      String unit,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
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
                  value: value,
                  min: min,
                  max: max,
                  divisions: ((max - min) / 1.0).round(),
                  onChanged: onChanged,
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
                  '${value.toStringAsFixed(1)} $unit',
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

  Widget _buildDetailedTimeSetting() {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('daily_forecast_time'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.translate('daily_forecast_time_desc'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Кнопка для выбора времени
          GestureDetector(
            onTap: _showTimePicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _settings.formattedTime,
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppConstants.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker() {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Позволяет контролировать размер
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom;

        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('select_time'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Picker
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(2024, 1, 1, _settings.dailyForecastHour, _settings.dailyForecastMinute),
                    minuteInterval: 5,
                    use24hFormat: true,
                    onDateTimeChanged: (DateTime newTime) {
                      setState(() {
                        _settings = _settings.copyWith(
                          dailyForecastHour: newTime.hour,
                          dailyForecastMinute: newTime.minute,
                        );
                      });
                    },
                  ),
                ),

                // Кнопка подтверждения
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.translate('confirm'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _notificationService.forceWeatherCheck();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('weather_check_completed')),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text(localizations.translate('check_weather_now')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _notificationService.forceDailyForecast();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('daily_forecast_sent')),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.today),
            label: Text(localizations.translate('send_daily_forecast')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}