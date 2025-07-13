// Путь: lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
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
                      SizedBox(width: ResponsiveConstants.spacingS),
                      Expanded(
                        child: Text(
                          localizations.translate('test_notification'), // ИСПРАВЛЕНО
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: ResponsiveConstants.spacingS),
                      Expanded(
                        child: Text(
                          localizations.translate('clear_all_data'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
        child: CircularProgressIndicator(color: AppConstants.textColor),
      )
          : _notifications.isEmpty
          ? _buildEmptyState(localizations)
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveConstants.spacingXL),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off,
                      color: AppConstants.textColor.withValues(alpha: 0.5),
                      size: isSmallScreen ? 48 : 64,
                    ),
                  ),
                  SizedBox(height: ResponsiveConstants.spacingXL),
                  Text(
                    localizations.translate('no_notifications'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveConstants.spacingS),
                  Text(
                    localizations.translate('notifications_description'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveConstants.spacingXXL),
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Увеличиваем высоту
                    child: ElevatedButton(
                      onPressed: _addTestNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12), // Добавляем вертикальные отступы
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center, // Центрируем по вертикали
                        children: [
                          const Icon(Icons.add_alert, size: 20), // Уменьшаем иконку
                          SizedBox(width: ResponsiveConstants.spacingS),
                          Text(
                            localizations.translate('test_notification'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.0, // Убираем лишнюю высоту строки
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingXL),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: ResponsiveConstants.spacingL),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeNotification(notification.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: ResponsiveConstants.minListItemHeight,
        ),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppConstants.surfaceColor
              : AppConstants.surfaceColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
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
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveConstants.spacingM),
            child: isSmallScreen
                ? _buildCompactLayout(notification)
                : _buildStandardLayout(notification),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(NotificationModel notification) {
    // Компактный layout для маленьких экранов
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(notification.typeColor).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Color(notification.typeColor),
                size: 20,
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    _getFormattedTime(notification.timestamp),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(notification.typeColor),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
        Text(
          notification.message,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConstants.spacingS,
            vertical: ResponsiveConstants.spacingXS,
          ),
          decoration: BoxDecoration(
            color: Color(notification.typeColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
          ),
          child: Text(
            _getNotificationTypeText(notification.type),
            style: TextStyle(
              color: Color(notification.typeColor),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardLayout(NotificationModel notification) {
    // Стандартный layout для больших экранов
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(width: ResponsiveConstants.spacingS),
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
                        SizedBox(height: ResponsiveConstants.spacingXS),
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
              SizedBox(height: ResponsiveConstants.spacingS),
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
              SizedBox(height: ResponsiveConstants.spacingS),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConstants.spacingS,
                  vertical: ResponsiveConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Color(notification.typeColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
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
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    final localizations = AppLocalizations.of(context);

    // Если это уведомление об обновлении политики, переходим к соглашениям
    if (notification.type == NotificationType.policyUpdate) {
      _markAsRead(notification.id);
      Navigator.pop(context);

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
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingS),
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
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
              SizedBox(height: ResponsiveConstants.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppConstants.textColor.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  SizedBox(width: ResponsiveConstants.spacingS),
                  Expanded(
                    child: Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(notification.timestamp),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (notification.data.isNotEmpty &&
                  notification.type != NotificationType.tournamentReminder) ...[
                SizedBox(height: ResponsiveConstants.spacingM),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
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
                      SizedBox(height: ResponsiveConstants.spacingS),
                      ...notification.data.entries
                          .where((entry) => ![
                        'sourceId',
                        'eventId',
                        'eventType',
                        'eventTitle',
                      ].contains(entry.key))
                          .map(
                            (entry) => Padding(
                          padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingXS),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          SizedBox(
            height: ResponsiveConstants.minTouchTarget,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.translate('close'),
                style: TextStyle(color: AppConstants.textColor),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
        ),
        title: Text(
          localizations.translate('clear_all_notifications_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('clear_all_notifications_message'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          SizedBox(
            height: ResponsiveConstants.minTouchTarget,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                localizations.translate('cancel'),
                style: TextStyle(color: AppConstants.textColor),
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveConstants.minTouchTarget,
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(localizations.translate('clear')),
            ),
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
      case NotificationType.tournamentReminder:
        return Icons.emoji_events;
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
      case NotificationType.tournamentReminder:
        return localizations.translate('notification_type_tournament_reminder');
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