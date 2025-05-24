// Путь: lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Метод для загрузки уведомлений (в будущем будет использоваться реальная логика)
  Future<void> _loadNotifications() async {
    // Имитация загрузки данных
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final localizations = AppLocalizations.of(context);

      setState(() {
        // Добавляем тестовые уведомления с локализацией
        _notifications.addAll([
          NotificationItem(
            title: localizations.translate('new_features'),
            message: localizations.translate('new_features_message'),
            date: DateTime.now().subtract(const Duration(hours: 2)),
            type: NotificationType.update,
            isRead: false,
          ),
          NotificationItem(
            title: localizations.translate('fishing_reminder'),
            message: localizations.translate('fishing_reminder_message'),
            date: DateTime.now().subtract(const Duration(days: 1)),
            type: NotificationType.reminder,
            isRead: true,
          ),
          NotificationItem(
            title: localizations.translate('bite_forecast'),
            message: localizations.translate('bite_forecast_message'),
            date: DateTime.now().subtract(const Duration(days: 2)),
            type: NotificationType.forecast,
            isRead: true,
          ),
        ]);

        _isLoading = false;
      });
    }
  }

  // Метод для отметки уведомления как прочитанного
  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  // Метод для удаления уведомления
  void _removeNotification(int index) async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _notifications.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('notification_deleted')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Отметить все уведомления как прочитанные
  void _markAllAsRead() {
    final localizations = AppLocalizations.of(context);

    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('all_notifications_read')),
        duration: const Duration(seconds: 2),
      ),
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
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: localizations.translate('mark_all_as_read'),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              color: AppConstants.textColor
          )
      )
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              color: AppConstants.textColor.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_notifications'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];

          return Dismissible(
            key: Key(index.toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _removeNotification(index);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: notification.isRead
                  ? AppConstants.cardColor
                  : AppConstants.cardColor.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: notification.isRead
                    ? BorderSide.none
                    : BorderSide(
                  color: _getNotificationColor(notification.type),
                  width: 1.5,
                ),
              ),
              elevation: notification.isRead ? 1 : 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFormattedDate(notification.date),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notification.isRead) {
                    _markAsRead(index);
                  }

                  // Здесь может быть логика для открытия соответствующего экрана
                  // в зависимости от типа уведомления
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Форматирование даты с учетом локализации
  String _getFormattedDate(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${localizations.translate('today')}, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return '${localizations.translate('yesterday')}, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${localizations.translate('days_ago')}, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd.MM.yyyy, HH:mm').format(date);
    }
  }

  // Получение иконки в зависимости от типа уведомления
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.access_time;
      case NotificationType.update:
        return Icons.system_update;
      case NotificationType.forecast:
        return Icons.wb_sunny;
    }
  }

  // Получение цвета в зависимости от типа уведомления
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.update:
        return Colors.blue;
      case NotificationType.forecast:
        return Colors.green;
    }
  }
}

// Класс для хранения данных уведомления
class NotificationItem {
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });
}

// Перечисление типов уведомлений
enum NotificationType {
  reminder, // Напоминание
  update,   // Обновление
  forecast, // Прогноз
}