// Путь: lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../services/offline/sync_service.dart';
import '../../utils/network_utils.dart';
import '../../widgets/loading_overlay.dart';
import 'storage_cleanup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  Map<String, dynamic> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
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

  String _getFormattedSyncTime() {
    if (_syncStatus['lastSyncTime'] == null) {
      return 'Нет данных';
    }

    try {
      DateTime dateTime;

      if (_syncStatus['lastSyncTime'] is DateTime) {
        dateTime = _syncStatus['lastSyncTime'];
      } else if (_syncStatus['lastSyncTime'] is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(_syncStatus['lastSyncTime']);
      } else {
        try {
          // Пытаемся получить значение через millisecondsSinceEpoch
          dateTime = DateTime.fromMillisecondsSinceEpoch(
              _syncStatus['lastSyncTime'].millisecondsSinceEpoch);
        } catch (e) {
          return 'Недавно';
        }
      }

      // Форматируем дату и время по отдельности
      String date = '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
      String time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      // Возвращаем с явным пробелом между датой и временем
      return '$date $time';
    } catch (e) {
      debugPrint('Ошибка при форматировании времени: $e');
      return 'Недавно';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Синхронизация',
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
              // Синхронизация
              _buildSectionHeader('Синхронизация данных'),
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
                            // Последняя синхронизация
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Последняя синхронизация',
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                // Принудительное разделение даты и времени
                                Text(
                                  _getFormattedSyncTime(),
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
                                  'Ожидающие изменения',
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
                                  'Статус сети',
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _syncStatus['isOnline'] == true ? 'Онлайн' : 'Офлайн',
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
                      leading: const Icon(Icons.cleaning_services, color: Colors.orange),
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