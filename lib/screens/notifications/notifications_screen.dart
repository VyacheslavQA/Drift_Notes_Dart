// Путь: lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
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

    setState(() {
      // Добавляем тестовые уведомления
      _notifications.addAll([
        NotificationItem(
          title: 'Новые функции',
          message: 'В приложении Drift Notes появилась новая функция "Календарь рыбалок"',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.update,
          isRead: false,
        ),
        NotificationItem(
          title: 'Напоминание о рыбалке',
          message: 'Завтра запланирована рыбалка на озере Байкал',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.reminder,
          isRead: true,
        ),
        NotificationItem(
          title: 'Прогноз клева',
          message: 'По прогнозу сегодня хороший клев в Вашем районе',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: NotificationType.forecast,
          isRead: true,
        ),
      ]);

      _isLoading = false;
    });
  }

  // Метод для отметки уведомления как прочитанного
  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  // Метод для удаления уведомления
  void _removeNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  // Отметить все уведомления как прочитанные
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все уведомления прочитаны'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Отметить все как прочитанные',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              color: AppConstants.textColor.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'У вас нет уведомлений',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Уведомление удалено'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: notification.isRead
                  ? AppConstants.cardColor
                  : AppConstants.cardColor.withOpacity(0.85),
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
                    color: _getNotificationColor(notification.type).withOpacity(0.2),
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
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFormattedDate(notification.date),
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.6),
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

  // Форматирование даты
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Вчера, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад, ${DateFormat('HH:mm').format(date)}';
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
      default:
        return Icons.notifications;
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
      default:
        return Colors.grey;
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