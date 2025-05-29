// Путь: lib/services/notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Ключ для хранения уведомлений
  static const String _notificationsKey = 'app_notifications';

  // Список уведомлений
  final List<NotificationModel> _notifications = [];

  // Stream контроллер для уведомлений
  final StreamController<List<NotificationModel>> _notificationsController =
  StreamController<List<NotificationModel>>.broadcast();

  // Getter для получения stream уведомлений
  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;

  // Getter для получения текущих уведомлений
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  // Getter для получения непрочитанных уведомлений
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((notification) => !notification.isRead).toList();

  // Getter для количества непрочитанных уведомлений
  int get unreadCount => unreadNotifications.length;

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('📱 Инициализация сервиса уведомлений...');

    try {
      await _loadNotifications();
      debugPrint('✅ Сервис уведомлений инициализирован. Загружено: ${_notifications.length} уведомлений');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации сервиса уведомлений: $e');
    }
  }

  /// Загрузка уведомлений из локального хранилища
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      _notifications.clear();

      for (final notificationJson in notificationsJson) {
        try {
          final notificationMap = json.decode(notificationJson);
          final notification = NotificationModel.fromJson(notificationMap);
          _notifications.add(notification);
        } catch (e) {
          debugPrint('❌ Ошибка парсинга уведомления: $e');
        }
      }

      // Сортируем по времени (новые сначала)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Ограничиваем количество уведомлений (максимум 100)
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
        await _saveNotifications(); // Сохраняем обрезанный список
      }

      _notifyListeners();

    } catch (e) {
      debugPrint('❌ Ошибка загрузки уведомлений: $e');
    }
  }

  /// Сохранение уведомлений в локальное хранилище
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => json.encode(notification.toJson()))
          .toList();

      await prefs.setStringList(_notificationsKey, notificationsJson);

    } catch (e) {
      debugPrint('❌ Ошибка сохранения уведомлений: $e');
    }
  }

  /// Добавление нового уведомления
  Future<void> addNotification(NotificationModel notification) async {
    try {
      _notifications.insert(0, notification); // Добавляем в начало списка

      // Ограничиваем количество уведомлений
      if (_notifications.length > 100) {
        _notifications.removeLast();
      }

      await _saveNotifications();
      _notifyListeners();

      debugPrint('✅ Уведомление добавлено: ${notification.title}');

    } catch (e) {
      debugPrint('❌ Ошибка добавления уведомления: $e');
    }
  }

  /// Отметка уведомления как прочитанного
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        _notifyListeners();

        debugPrint('✅ Уведомление отмечено как прочитанное: $notificationId');
      }

    } catch (e) {
      debugPrint('❌ Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметка всех уведомлений как прочитанных
  Future<void> markAllAsRead() async {
    try {
      bool hasChanges = false;

      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _saveNotifications();
        _notifyListeners();

        debugPrint('✅ Все уведомления отмечены как прочитанные');
      }

    } catch (e) {
      debugPrint('❌ Ошибка отметки всех уведомлений как прочитанных: $e');
    }
  }

  /// Удаление уведомления
  Future<void> removeNotification(String notificationId) async {
    try {
      final initialLength = _notifications.length;
      _notifications.removeWhere((n) => n.id == notificationId);

      if (_notifications.length != initialLength) {
        await _saveNotifications();
        _notifyListeners();

        debugPrint('✅ Уведомление удалено: $notificationId');
      }

    } catch (e) {
      debugPrint('❌ Ошибка удаления уведомления: $e');
    }
  }

  /// Очистка всех уведомлений
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      _notifyListeners();

      debugPrint('✅ Все уведомления очищены');

    } catch (e) {
      debugPrint('❌ Ошибка очистки уведомлений: $e');
    }
  }

  /// Получение уведомлений по типу
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Получение уведомлений за период
  List<NotificationModel> getNotificationsForPeriod(DateTime startDate, DateTime endDate) {
    return _notifications.where((n) =>
    n.timestamp.isAfter(startDate) && n.timestamp.isBefore(endDate)
    ).toList();
  }

  /// Уведомление слушателей об изменениях
  void _notifyListeners() {
    if (!_notificationsController.isClosed) {
      _notificationsController.add(List.unmodifiable(_notifications));
    }
  }

  /// Создание быстрых уведомлений для тестирования
  Future<void> addTestNotifications() async {
    final testNotifications = [
      NotificationModel(
        id: 'test_1',
        title: 'Добро пожаловать!',
        message: 'Спасибо за использование Drift Notes!',
        type: NotificationType.general,
        timestamp: DateTime.now(),
      ),
      NotificationModel(
        id: 'test_2',
        title: 'Прогноз клева',
        message: 'Сегодня отличные условия для рыбалки!',
        type: NotificationType.biteForecast,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    for (final notification in testNotifications) {
      await addNotification(notification);
    }
  }

  /// Очистка ресурсов
  void dispose() {
    _notificationsController.close();
  }
}