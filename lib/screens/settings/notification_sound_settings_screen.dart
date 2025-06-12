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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _settings = _pushService.soundSettings;
      _isLoading = false;
    });
  }

  Future<void> _updateSettings(NotificationSoundSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });

    await _pushService.updateSoundSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    try {
      await _pushService.showNotification(
        NotificationModel(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Тест уведомлений',
          message: 'Это тестовое уведомление для проверки настроек звука',
          type: NotificationType.general,
          timestamp: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовое уведомление отправлено'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
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
          title: const Text('Звуки уведомлений'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Звуки уведомлений',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Кнопка тестирования
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Тест уведомления',
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
            _buildSectionHeader('Звуковые уведомления'),
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
                      'Звуковые уведомления',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Проигрывать звук при получении уведомлений',
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

                    // Громкость
                    ListTile(
                      title: Text(
                        'Громкость',
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
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppConstants.primaryColor,
                              inactiveTrackColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                              thumbColor: AppConstants.primaryColor,
                              overlayColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _settings.volume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              onChanged: (value) {
                                _updateSettings(_settings.copyWith(volume: value));
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
            _buildSectionHeader('Вибрация'),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  'Вибрация',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Включить вибрацию при получении уведомлений',
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
            _buildSectionHeader('Тихие часы'),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Тихие часы',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Отключать звук и вибрацию в определенное время',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    value: _settings.quietHoursEnabled,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      _updateSettings(_settings.copyWith(quietHoursEnabled: value));
                    },
                  ),

                  if (_settings.quietHoursEnabled) ...[
                    const Divider(height: 1, color: Colors.white10),

                    // Время начала
                    ListTile(
                      title: Text(
                        'Начало тихих часов',
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
                        'Окончание тихих часов',
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
                            color: _settings.isQuietHours()
                                ? Colors.orange
                                : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _settings.isQuietHours()
                                ? 'Сейчас тихие часы'
                                : 'Звуки включены',
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.8),
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
                        'Информация',
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
                    '• Уведомления помогут не пропустить благоприятные условия для рыбалки\n'
                        '• Тихие часы автоматически отключают звук в указанное время\n'
                        '• Используйте кнопку тестирования для проверки настроек\n'
                        '• Настройки сохраняются автоматически',
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

  void _showTimePicker(bool isStartTime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                  initialItem: isStartTime ? _settings.quietHoursStart : _settings.quietHoursEnd,
                ),
                onSelectedItemChanged: (index) {
                  if (isStartTime) {
                    _updateSettings(_settings.copyWith(quietHoursStart: index));
                  } else {
                    _updateSettings(_settings.copyWith(quietHoursEnd: index));
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