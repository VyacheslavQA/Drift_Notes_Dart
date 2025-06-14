// Путь: lib/screens/settings/notification_sound_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/notification_sound_settings_model.dart';
import '../../models/notification_model.dart';
import '../../services/local_push_notification_service.dart';

class NotificationSoundSettingsScreen extends StatefulWidget {
  const NotificationSoundSettingsScreen({super.key});

  @override
  State<NotificationSoundSettingsScreen> createState() =>
      _NotificationSoundSettingsScreenState();
}

class _NotificationSoundSettingsScreenState
    extends State<NotificationSoundSettingsScreen> {
  final LocalPushNotificationService _pushService =
      LocalPushNotificationService();

  late NotificationSoundSettings _settings;
  bool _isLoading = true;
  bool _isBadgeSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBadgeSupport();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _settings = _pushService.soundSettings;
      _isLoading = false;
    });
  }

  Future<void> _checkBadgeSupport() async {
    final isSupported = await _pushService.isBadgeSupported();
    if (mounted) {
      setState(() {
        _isBadgeSupported = isSupported;
      });
    }
  }

  Future<void> _updateSettings(NotificationSoundSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });

    await _pushService.updateSoundSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('settings_saved'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    try {
      await _pushService.showNotification(
        NotificationModel(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          title: AppLocalizations.of(
            context,
          ).translate('test_notifications_title'),
          message: AppLocalizations.of(
            context,
          ).translate('test_notification_message'),
          type: NotificationType.general,
          timestamp: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('test_notification_sent'),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error')}: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).translate('notification_sounds'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('notification_sounds'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Кнопка тестирования
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: AppLocalizations.of(
              context,
            ).translate('test_notification'),
            onPressed: _testNotification,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основные настройки звука
            _buildSectionHeader(
              AppLocalizations.of(context).translate('sound_notifications'),
            ),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Включить/выключить звук
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('sound_notifications'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('play_sound_on_notifications'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    value: _settings.soundEnabled,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      _updateSettings(_settings.copyWith(soundEnabled: value));
                    },
                  ),

                  if (_settings.soundEnabled) ...[
                    const Divider(height: 1, color: Colors.white10),

                    // Пока убираем выбор типа звука - будем использовать системный
                    // TODO: Добавить позже когда настроим звуковые ресурсы

                    // Громкость
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context).translate('volume'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(_settings.volume * 100).round()}%',
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppConstants.primaryColor,
                              inactiveTrackColor: AppConstants.primaryColor
                                  .withValues(alpha: 0.3),
                              thumbColor: AppConstants.primaryColor,
                              overlayColor: AppConstants.primaryColor
                                  .withValues(alpha: 0.1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _settings.volume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              onChanged: (value) {
                                _updateSettings(
                                  _settings.copyWith(volume: value),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Вибрация
            _buildSectionHeader(
              AppLocalizations.of(context).translate('vibration'),
            ),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  AppLocalizations.of(context).translate('vibration'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).translate('enable_vibration_on_notifications'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                value: _settings.vibrationEnabled,
                activeColor: AppConstants.primaryColor,
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(vibrationEnabled: value));
                },
              ),
            ),

            const SizedBox(height: 20),

            // Тихие часы
            _buildSectionHeader(
              AppLocalizations.of(context).translate('quiet_hours'),
            ),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context).translate('quiet_hours'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('disable_sound_vibration_at_time'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    value: _settings.quietHoursEnabled,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(quietHoursEnabled: value),
                      );
                    },
                  ),

                  if (_settings.quietHoursEnabled) ...[
                    const Divider(height: 1, color: Colors.white10),

                    // Время начала
                    ListTile(
                      title: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('quiet_hours_start'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${_settings.quietHoursStart.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time, size: 20),
                      onTap: () => _showTimePicker(true),
                    ),

                    const Divider(height: 1, color: Colors.white10),

                    // Время окончания
                    ListTile(
                      title: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('quiet_hours_end'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${_settings.quietHoursEnd.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time, size: 20),
                      onTap: () => _showTimePicker(false),
                    ),

                    // Текущий статус
                    const Divider(height: 1, color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _settings.isQuietHours()
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color:
                                _settings.isQuietHours()
                                    ? Colors.orange
                                    : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _settings.isQuietHours()
                                ? AppLocalizations.of(
                                  context,
                                ).translate('currently_quiet_hours')
                                : AppLocalizations.of(
                                  context,
                                ).translate('sounds_enabled'),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Бейдж на иконке (только если поддерживается)
            if (_isBadgeSupported) ...[
              _buildSectionHeader(
                AppLocalizations.of(context).translate('badge_on_icon'),
              ),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context).translate('show_badge'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('red_dot_on_app_icon_with_number'),
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      value: _settings.badgeEnabled,
                      activeColor: AppConstants.primaryColor,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(badgeEnabled: value),
                        );
                      },
                    ),

                    if (_settings.badgeEnabled) ...[
                      const Divider(height: 1, color: Colors.white10),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context).translate('clear_badge'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('remove_red_dot_from_app_icon'),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.clear, size: 20),
                        onTap: () async {
                          await _pushService.clearBadge();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('badge_cleared'),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Информационная карточка
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).translate('information'),
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).translate('notification_help_text'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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

  // ВРЕМЕННО ЗАКОММЕНТИРОВАНО - добавим позже
  /*
  void _showSoundTypePicker() {
    // Код метода...
  }

  String _getSoundTypeDisplayName(NotificationSoundType type) {
    // Код метода...
  }

  String _getSoundTypeDescription(NotificationSoundType type) {
    // Код метода...
  }
  */

  void _showTimePicker(bool isStartTime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  isStartTime ? 'Начало тихих часов' : 'Окончание тихих часов',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: Colors.transparent,
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem:
                          isStartTime
                              ? _settings.quietHoursStart
                              : _settings.quietHoursEnd,
                    ),
                    onSelectedItemChanged: (index) {
                      if (isStartTime) {
                        _updateSettings(
                          _settings.copyWith(quietHoursStart: index),
                        );
                      } else {
                        _updateSettings(
                          _settings.copyWith(quietHoursEnd: index),
                        );
                      }
                    },
                    children: List.generate(24, (index) {
                      return Center(
                        child: Text(
                          '${index.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Готово'),
                ),
              ],
            ),
          ),
    );
  }
}
