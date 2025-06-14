// Путь: lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../settings/accepted_agreements_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _notificationService.getAllNotifications();
      _isLoading = false;
    });
  }

  void _subscribeToNotifications() {
    _notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> _removeNotification(String notificationId) async {
    final localizations = AppLocalizations.of(context);

    await _notificationService.removeNotification(notificationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('notification_deleted')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final localizations = AppLocalizations.of(context);

    await _notificationService.markAllAsRead();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('all_notifications_read')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addTestNotification() async {
    final localizations = AppLocalizations.of(context);
    await _notificationService.addTestNotification(
      title: localizations.translate('test_notification_title'),
      message: localizations.translate('test_notification_message'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('notifications')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            // Кнопка "Отметить все как прочитанные"
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: localizations.translate('mark_all_as_read'),
              onPressed: _markAllAsRead,
            ),
            // Меню с дополнительными действиями
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'clear_all':
                    await _showClearAllDialog();
                    break;
                  case 'add_test':
                    await _addTestNotification();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'add_test',
                  child: Row(
                    children: [
                      const Icon(Icons.add_alert, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(localizations.translate('add_test_notification')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.clear_all, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(localizations.translate('clear_all_data')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppConstants.textColor,
        ),
      )
          : _notifications.isEmpty
          ? _buildEmptyState(localizations)
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off,
              color: AppConstants.textColor.withValues(alpha: 0.5),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('no_notifications'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('notifications_description'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addTestNotification,
            icon: const Icon(Icons.add_alert),
            label: Text(localizations.translate('add_test_notification')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppConstants.surfaceColor
              : AppConstants.surfaceColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(
            color: Color(notification.typeColor).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: notification.isRead
              ? null
              : [
            BoxShadow(
              color: Color(notification.typeColor).withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            _showNotificationDetails(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка типа уведомления
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(notification.typeColor).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Color(notification.typeColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Содержимое уведомления
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок и время
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getFormattedTime(notification.timestamp),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              if (!notification.isRead) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Color(notification.typeColor),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Сообщение
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Тип уведомления
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(notification.typeColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getNotificationTypeText(notification.type),
                          style: TextStyle(
                            color: Color(notification.typeColor),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    final localizations = AppLocalizations.of(context);

    // Если это уведомление об обновлении политики, переходим к соглашениям
    if (notification.type == NotificationType.policyUpdate) {
      _markAsRead(notification.id);
      Navigator.pop(context); // Закрываем экран уведомлений

      // Переходим к экрану принятых соглашений
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AcceptedAgreementsScreen(),
        ),
      );
      return;
    }

    // Для других типов уведомлений показываем диалог
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(notification.typeColor).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Color(notification.typeColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(notification.timestamp),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('additional_data'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...notification.data.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('close'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDialog() async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('clear_all_notifications_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('clear_all_notifications_message'),
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(localizations.translate('clear')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearAllNotifications();
    }
  }

  String _getFormattedTime(DateTime dateTime) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return localizations.translate('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${localizations.translate('days_ago')}';
    } else {
      return DateFormat('dd.MM').format(dateTime);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.fishingReminder:
        return Icons.catching_pokemon;
      case NotificationType.biteForecast:
        return Icons.show_chart;
      case NotificationType.weatherUpdate:
        return Icons.cloud;
      case NotificationType.newFeatures:
        return Icons.star;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.policyUpdate:
        return Icons.security;
    }
  }

  String _getNotificationTypeText(NotificationType type) {
    final localizations = AppLocalizations.of(context);

    switch (type) {
      case NotificationType.general:
        return localizations.translate('notification_type_general');
      case NotificationType.fishingReminder:
        return localizations.translate('notification_type_fishing_reminder');
      case NotificationType.biteForecast:
        return localizations.translate('notification_type_bite_forecast');
      case NotificationType.weatherUpdate:
        return localizations.translate('notification_type_weather_update');
      case NotificationType.newFeatures:
        return localizations.translate('notification_type_new_features');
      case NotificationType.systemUpdate:
        return localizations.translate('notification_type_system_update');
      case NotificationType.policyUpdate:
        return localizations.translate('notification_type_policy_update');
    }
  }
}