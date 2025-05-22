// Путь: lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/offline/sync_service.dart';
import '../../utils/network_utils.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';
import 'storage_cleanup_screen.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  bool _isSyncing = false;
  Map<String, dynamic> _syncStatus = {};

  // Контроллер для анимации кнопки синхронизации
  late AnimationController _syncAnimationController;
  late Animation<double> _syncRotationAnimation;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();

    // Инициализация анимации для кнопки синхронизации
    _syncAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _syncRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // 360 градусов в радианах
    ).animate(CurvedAnimation(
      parent: _syncAnimationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
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

  String _getFormattedSyncDateTime() {
    if (_syncStatus['lastSyncTime'] == null) {
      return 'Нет данных';
    }

    try {
      DateTime? dateTime;

      if (_syncStatus['lastSyncTime'] is DateTime) {
        dateTime = _syncStatus['lastSyncTime'] as DateTime;
      } else if (_syncStatus['lastSyncTime'] is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(_syncStatus['lastSyncTime'] as int);
      } else {
        return 'Недавно';
      }

      if (dateTime == null) {
        return 'Недавно';
      }

      // Форматируем дату и время
      final String formattedDate = DateFormat('dd.MM.yyyy').format(dateTime);
      final String formattedTime = DateFormat('HH:mm').format(dateTime);

      return '$formattedDate $formattedTime';
    } catch (e) {
      debugPrint('Ошибка при форматировании времени: $e');
      return 'Недавно';
    }
  }

  Future<void> _forceSyncData() async {
    if (_isSyncing) return; // Предотвращаем повторный запуск синхронизации

    setState(() {
      _isSyncing = true;
    });

    // Запускаем анимацию вращения
    _syncAnimationController.reset();
    _syncAnimationController.repeat();

    try {
      // Проверяем подключение к интернету
      final isConnected = await NetworkUtils.isNetworkAvailable();
      if (!isConnected) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('no_internet_connection')),
            backgroundColor: Colors.red,
          ),
        );

        // Останавливаем анимацию
        _syncAnimationController.stop();

        setState(() {
          _isSyncing = false;
        });
        return;
      }

      final result = await _syncService.forceSyncAll();

      // Обновляем статус синхронизации
      await _loadSyncStatus();

      // Останавливаем анимацию
      _syncAnimationController.stop();

      setState(() {
        _isSyncing = false;
      });

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result
              ? localizations.translate('sync_success')
              : localizations.translate('sync_with_errors')),
          backgroundColor: result ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      // Останавливаем анимацию
      _syncAnimationController.stop();

      setState(() {
        _isSyncing = false;
      });

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('sync_error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('clear_all_data_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('clear_all_data_message'),
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
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
                    SnackBar(
                      content: Text(localizations.translate('data_cleared_success')),
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
                      content: Text('${localizations.translate('data_clear_error')}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(localizations.translate('clear')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('settings'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('please_wait'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Синхронизация
              _buildSectionHeader(localizations.translate('sync_settings')),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Заменяем ListTile на более красивую кнопку синхронизации
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: _isSyncing ? null : _forceSyncData,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Анимированная иконка синхронизации
                              AnimatedBuilder(
                                animation: _syncAnimationController,
                                builder: (_, child) {
                                  return Transform.rotate(
                                    angle: _syncRotationAnimation.value,
                                    child: Icon(
                                      Icons.sync,
                                      color: _isSyncing
                                          ? AppConstants.primaryColor
                                          : AppConstants.textColor,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              // Текст кнопки
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.translate('force_sync'),
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isSyncing
                                          ? localizations.translate('syncing_in_progress')
                                          : localizations.translate('sync_all_data_now'),
                                      style: TextStyle(
                                        color: AppConstants.textColor.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_syncStatus.isNotEmpty) ...[
                      const Divider(height: 1, color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Последняя синхронизация
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.translate('last_sync'),
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getFormattedSyncDateTime(),
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Ожидающие изменения
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  localizations.translate('pending_changes'),
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_syncStatus['pendingChanges'] ?? 0}',
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Статус сети
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  localizations.translate('network_status'),
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _syncStatus['isOnline'] == true ?
                                        Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _syncStatus['isOnline'] == true
                                          ? localizations.translate('online')
                                          : localizations.translate('offline'),
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Настройки языка
              _buildSectionHeader(localizations.translate('language')),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: Text(localizations.translate('language')),
                  subtitle: Text(localizations.translate('select_language')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Очистка данных
              _buildSectionHeader(localizations.translate('data_and_storage')),
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                      title: Text(localizations.translate('storage_cleanup')),
                      subtitle: Text(localizations.translate('remove_problematic_notes')),
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
                      title: Text(localizations.translate('clear_all_data')),
                      subtitle: Text(localizations.translate('delete_all_local_data')),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _clearAllData,
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
}