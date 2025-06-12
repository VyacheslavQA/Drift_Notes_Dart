// Путь: lib/services/notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'local_push_notification_service.dart';  // НОВЫЙ ИМПОРТ

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Uuid _uuid = const Uuid();
  final List<NotificationModel> _notifications = [];

  // НОВЫЙ: Интеграция с push-сервисом
  final LocalPushNotificationService _pushService = LocalPushNotificationService();

  // Stream для уведомления UI об изменениях
  final StreamController<List<NotificationModel>> _notificationsController =
  StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;

  // Ключ для SharedPreferences
  static const String _notificationsKey = 'local_notifications';

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('📱 Инициализация сервиса уведомлений...');

    try {
      // НОВЫЙ: Инициализируем push-сервис
      await _pushService.initialize();

      await _loadNotificationsFromStorage();

      // НОВЫЙ: Обновляем бейдж на основе непрочитанных уведомлений
      await _updateBadgeCount();

      // НОВЫЙ: Подписываемся на нажатия уведомлений
      _pushService.notificationTapStream.listen(_handleNotificationTap);

      debugPrint('✅ Сервис уведомлений инициализирован. Загружено: ${_notifications.length} уведомлений');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации сервиса уведомлений: $e');
    }
  }

  /// НОВЫЙ: Обработчик нажатий на уведомления
  void _handleNotificationTap(String payload) {
    try {
      final payloadData = json.decode(payload);
      final notificationId = payloadData['id'] as String?;

      if (notificationId != null) {
        // Отмечаем уведомление как прочитанное при нажатии
        markAsRead(notificationId);
        debugPrint('📱 Уведомление отмечено как прочитанное: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ Ошибка обработки нажатия на уведомление: $e');
    }
  }

  /// Загрузка уведомлений из локального хранилища
  Future<void> _loadNotificationsFromStorage() async {
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
        await _saveNotificationsToStorage();
      }

    } catch (e) {
      debugPrint('❌ Ошибка загрузки уведомлений: $e');
    }
  }

  /// Сохранение уведомлений в локальное хранилище
  Future<void> _saveNotificationsToStorage() async {
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

  /// НОВЫЙ: Обновление счетчика бейджа
  Future<void> _updateBadgeCount() async {
    try {
      final unreadCount = getUnreadCount();
      await _pushService.setBadgeCount(unreadCount);
    } catch (e) {
      debugPrint('❌ Ошибка обновления бейджа: $e');
    }
  }

  /// Добавление нового уведомления
  Future<void> addNotification(NotificationModel notification) async {
    try {
      // Проверяем, нет ли уже такого уведомления (по ID)
      final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);

      if (existingIndex != -1) {
        // Обновляем существующее
        _notifications[existingIndex] = notification;
      } else {
        // Добавляем новое в начало списка
        _notifications.insert(0, notification);
      }

      // Ограничиваем количество уведомлений
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }

      await _saveNotificationsToStorage();

      // НОВЫЙ: Отправляем push-уведомление
      await _pushService.showNotification(notification);

      // НОВЫЙ: Обновляем бейдж
      await _updateBadgeCount();

      // Уведомляем слушателей об изменениях
      _notificationsController.add(List.from(_notifications));

      debugPrint('✅ Уведомление добавлено: ${notification.title}');

    } catch (e) {
      debugPrint('❌ Ошибка добавления уведомления: $e');
    }
  }

  /// Создание и добавление уведомления (упрощенный метод)
  Future<void> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
    Map<String, dynamic> data = const {},
  }) async {
    final notification = NotificationModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    await addNotification(notification);
  }

  /// Получение всех уведомлений
  List<NotificationModel> getAllNotifications() {
    return List.from(_notifications);
  }

  /// Получение непрочитанных уведомлений
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  /// Количество непрочитанных уведомлений
  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotificationsToStorage();

        // НОВЫЙ: Обновляем бейдж
        await _updateBadgeCount();

        _notificationsController.add(List.from(_notifications));

        debugPrint('✅ Уведомление отмечено как прочитанное: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
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
        await _saveNotificationsToStorage();

        // НОВЫЙ: Очищаем бейдж при прочтении всех уведомлений
        await _pushService.clearBadge();

        _notificationsController.add(List.from(_notifications));

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
      _notifications.removeWhere((notification) => notification.id == notificationId);

      if (_notifications.length != initialLength) {
        await _saveNotificationsToStorage();

        // НОВЫЙ: Обновляем бейдж
        await _updateBadgeCount();

        // НОВЫЙ: Отменяем push-уведомление
        await _pushService.cancelNotification(notificationId);

        _notificationsController.add(List.from(_notifications));

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
      await _saveNotificationsToStorage();

      // НОВЫЙ: Очищаем все push-уведомления и бейдж
      await _pushService.cancelAllNotifications();
      await _pushService.clearBadge();

      _notificationsController.add(List.from(_notifications));

      debugPrint('✅ Все уведомления очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки уведомлений: $e');
    }
  }

  /// Получение уведомлений по типу
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  /// Добавление тестового уведомления (для разработки)
  Future<void> addTestNotification() async {
    await createNotification(
      title: 'Тестовое уведомление',
      message: 'Это тестовое уведомление для проверки работы системы',
      type: NotificationType.general,
      data: {
        'test': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Добавление уведомления о благоприятных условиях для рыбалки
  Future<void> addFavorableConditionsNotification({
    required int scorePoints,
    required String bestTime,
    Map<String, dynamic> additionalData = const {},
  }) async {
    await createNotification(
      title: 'Отличные условия для рыбалки!',
      message: 'Прогноз клева: $scorePoints баллов из 100. Лучшее время: $bestTime',
      type: NotificationType.biteForecast,
      data: {
        'scorePoints': scorePoints,
        'bestTime': bestTime,
        ...additionalData,
      },
    );
  }

  /// Добавление уведомления о изменении погоды
  Future<void> addWeatherChangeNotification({
    required String title,
    required String description,
    Map<String, dynamic> weatherData = const {},
  }) async {
    await createNotification(
      title: title,
      message: description,
      type: NotificationType.weatherUpdate,
      data: {
        'weatherChange': true,
        ...weatherData,
      },
    );
  }

  /// Добавление напоминания о рыбалке
  Future<void> addFishingReminder({
    required String location,
    required DateTime scheduledTime,
    Map<String, dynamic> additionalData = const {},
  }) async {
    await createNotification(
      title: 'Напоминание о рыбалке',
      message: 'Запланированная рыбалка в $location',
      type: NotificationType.fishingReminder,
      data: {
        'location': location,
        'scheduledTime': scheduledTime.toIso8601String(),
        ...additionalData,
      },
    );
  }

  /// НОВЫЙ: Получение настроек звука
  get soundSettings => _pushService.soundSettings;

  /// НОВЫЙ: Обновление настроек звука
  Future<void> updateSoundSettings(settings) async {
    await _pushService.updateSoundSettings(settings);
  }

  /// Освобождение ресурсов
  void dispose() {
    _notificationsController.close();
    _pushService.dispose();
  }
}