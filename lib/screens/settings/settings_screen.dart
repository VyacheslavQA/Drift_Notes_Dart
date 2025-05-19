// Путь: lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/offline/sync_service.dart';
import '../../utils/network_utils.dart';
import '../../widgets/loading_overlay.dart';
import '../auth/login_screen.dart';
import 'storage_cleanup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();

  String _appVersion = '';
  bool _isLoading = false;
  Map<String, dynamic> _syncStatus = {};
  bool _isDarkTheme = true;
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadSettings();
    _loadSyncStatus();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      debugPrint('Ошибка при получении информации о приложении: $e');
      setState(() {
        _appVersion = 'Неизвестно';
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkTheme = prefs.getBool('darkThemeEnabled') ?? true;
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _soundsEnabled = prefs.getBool('soundsEnabled') ?? true;
        _locationEnabled = prefs.getBool('locationEnabled') ?? true;
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке настроек: $e');
    }
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await _syncService.getSyncStatus();
      setState(() {
        _syncStatus = status;
      });
    } catch (e) {
      debugPrint('Ошибка при получении статуса синхронизации: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkThemeEnabled', _isDarkTheme);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('soundsEnabled', _soundsEnabled);
      await prefs.setBool('locationEnabled', _locationEnabled);
    } catch (e) {
      debugPrint('Ошибка при сохранении настроек: $e');
    }
  }

  Future<void> _forceSyncData() async {
    setState(() => _isLoading = true);

    try {
      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет подключения к интернету'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final result = await _syncService.forceSyncAll();

      // Обновляем статус синхронизации
      await _loadSyncStatus();

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result
              ? 'Синхронизация выполнена успешно'
              : 'Синхронизация выполнена с ошибками'),
          backgroundColor: result ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при синхронизации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          'Выйти из аккаунта?',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите выйти из своего аккаунта? Ваши данные останутся на устройстве, но синхронизация будет недоступна.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context); // Закрыть диалог
              setState(() => _isLoading = true);

              try {
                await _firebaseService.signOut();

                if (mounted) {
                  setState(() => _isLoading = false);

                  // Перейти на экран входа
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка при выходе: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          'Очистить все данные?',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите очистить все локальные данные? Это действие нельзя отменить.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context); // Закрыть диалог
              setState(() => _isLoading = true);

              try {
                await _offlineStorage.clearAllOfflineData();

                if (mounted) {
                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Все данные успешно очищены'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Обновляем статус синхронизации
                  await _loadSyncStatus();
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка при очистке данных: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://www.yourdomain.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть ссылку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfUse() async {
    const url = 'https://www.yourdomain.com/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть ссылку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    const email = 'support@yourdomain.com';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Обратная связь - Drift Notes&body=',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть почтовый клиент'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Пожалуйста, подождите...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Настройки приложения
              _buildSectionHeader('Настройки приложения'),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Темная тема'),
                      value: _isDarkTheme,
                      onChanged: (value) {
                        setState(() {
                          _isDarkTheme = value;
                        });
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.brightness_4),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Уведомления'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.notifications),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Звуки'),
                      value: _soundsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundsEnabled = value;
                        });
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.volume_up),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Использовать геолокацию'),
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _locationEnabled = value;
                        });
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.location_on),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Синхронизация
              _buildSectionHeader('Синхронизация'),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Принудительная синхронизация'),
                      subtitle: const Text(
                          'Синхронизировать данные сейчас'),
                      leading: const Icon(Icons.sync),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _forceSyncData,
                    ),
                    if (_syncStatus.isNotEmpty) ...[
                      const Divider(height: 1, color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSyncStatusItem(
                              'Последняя синхронизация',
                              _syncStatus['lastSyncTime'] != null
                                  ? DateFormat('dd.MM.yyyy HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      _syncStatus['lastSyncTime']
                                          .millisecondsSinceEpoch))
                                  : 'Нет данных',
                            ),
                            _buildSyncStatusItem(
                              'Ожидающие изменения',
                              _syncStatus['pendingChanges']?.toString() ?? '0',
                            ),
                            _buildSyncStatusItem(
                              'Статус сети',
                              _syncStatus['isOnline'] == true
                                  ? 'Онлайн'
                                  : 'Офлайн',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Очистка данных
              _buildSectionHeader('Данные и хранилище'),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services, color: Colors.red),
                      title: const Text('Очистка хранилища'),
                      subtitle: const Text('Удаление проблемных заметок'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StorageCleanupScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Очистить все данные'),
                      subtitle: const Text(
                          'Удалить все локальные данные'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _clearAllData,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Аккаунт
              _buildSectionHeader('Аккаунт'),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                      const Icon(Icons.account_circle, color: Colors.blue),
                      title: Text('Email: ${_firebaseService.currentUser?.email ?? 'Нет данных'}'),
                      subtitle: const Text('Ваш аккаунт'),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text('Выйти из аккаунта'),
                      subtitle: const Text(
                          'Выйти из текущего аккаунта'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _signOut,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // О приложении
              _buildSectionHeader('О приложении'),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Версия приложения'),
                      subtitle: Text(_appVersion),
                      leading: const Icon(Icons.info),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      title: const Text('Политика конфиденциальности'),
                      leading: const Icon(Icons.privacy_tip),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _openPrivacyPolicy,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      title: const Text('Условия использования'),
                      leading: const Icon(Icons.description),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _openTermsOfUse,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      title: const Text('Обратная связь'),
                      leading: const Icon(Icons.feedback),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _sendFeedback,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildSyncStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}