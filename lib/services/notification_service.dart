// Путь: lib/services/notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'local_push_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Uuid _uuid = const Uuid();
  final List<NotificationModel> _notifications = [];

  // Интеграция с push-сервисом
  final LocalPushNotificationService _pushService = LocalPushNotificationService();

  // Stream для уведомления UI об изменениях
  final StreamController<List<NotificationModel>> _notificationsController = StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;

  // Ключ для SharedPreferences
  static const String _notificationsKey = 'local_notifications';

  /// Фильтр для очистки технических ошибок
  String _cleanErrorMessage(String message, String title) {
    final lowercaseMessage = message.toLowerCase();
    final lowercaseTitle = title.toLowerCase();

    // Проверяем различные типы сетевых ошибок
    if (_isNetworkError(lowercaseMessage, lowercaseTitle)) {
      return 'Проверьте подключение к интернету';
    }

    // Проверяем ошибки API
    if (_isApiError(lowercaseMessage, lowercaseTitle)) {
      return 'Ошибка загрузки данных. Попробуйте позже';
    }

    // Проверяем ошибки погоды
    if (_isWeatherError(lowercaseMessage, lowercaseTitle)) {
      return 'Не удалось загрузить погоду. Проверьте интернет';
    }

    // Проверяем другие технические ошибки
    if (_isTechnicalError(message)) {
      return 'Произошла ошибка. Попробуйте позже';
    }

    // Если сообщение слишком длинное (больше 200 символов), обрезаем
    if (message.length > 200) {
      return 'Произошла ошибка при загрузке данных';
    }

    return message;
  }

  /// Проверка сетевых ошибок
  bool _isNetworkError(String message, String title) {
    final networkKeywords = [
      'socketexception',
      'failed host lookup',
      'network is unreachable',
      'connection timed out',
      'connection refused',
      'no address associated with hostname',
      'clientexception',
      'handshakeexception',
      'certificateexception',
      'нет подключения',
      'отсутствует соединение',
      'проверьте интернет',
      'no internet',
      'connection error',
      'network error',
    ];

    final combinedText = '$message $title';
    return networkKeywords.any((keyword) => combinedText.contains(keyword));
  }

  /// Проверка ошибок API
  bool _isApiError(String message, String title) {
    final apiKeywords = [
      'weather api error',
      'api key',
      'invalid key',
      'access denied',
      'unauthorized',
      '401',
      '403',
      '500',
      '502',
      '503',
      '504',
      'ошибка api',
      'неверный ключ',
    ];

    final combinedText = '$message $title';
    return apiKeywords.any((keyword) => combinedText.contains(keyword));
  }

  /// Проверка ошибок погоды
  bool _isWeatherError(String message, String title) {
    final weatherKeywords = [
      'weather',
      'погода',
      'прогноз',
      'forecast',
      'метео',
      'open-meteo',
      'weatherapi',
    ];

    final errorKeywords = [
      'ошибка',
      'error',
      'failed',
      'exception',
    ];

    final combinedText = '$message $title';
    return weatherKeywords.any((keyword) => combinedText.contains(keyword)) &&
        errorKeywords.any((keyword) => combinedText.contains(keyword));
  }

  /// Проверка технических ошибок (по длине и наличию технических терминов)
  bool _isTechnicalError(String message) {
    // Если сообщение очень длинное, скорее всего это техническая ошибка
    if (message.length > 300) return true;

    final technicalKeywords = [
      'exception',
      'stacktrace',
      'at line',
      'http://',
      'https://',
      'api.',
      '.com/',
      'latitude=',
      'longitude=',
      'temperature_',
      'pressure_',
      'wind_',
      'humidity_',
      'errno',
      'uri=',
      'stacktrace',
      'runtimeerror',
      'formatexception',
    ];

    return technicalKeywords.any((keyword) => message.toLowerCase().contains(keyword));
  }

  /// Очистка заголовка от технических терминов
  String _cleanErrorTitle(String title) {
    if (title.toLowerCase().contains('ошибка загрузки') &&
        title.toLowerCase().contains('exception')) {
      return 'Ошибка загрузки';
    }

    if (title.toLowerCase().contains('clientexception') ||
        title.toLowerCase().contains('socketexception')) {
      return 'Ошибка подключения';
    }

    if (title.toLowerCase().contains('weather') &&
        title.toLowerCase().contains('error')) {
      return 'Ошибка погоды';
    }

    // Если заголовок слишком длинный, сокращаем
    if (title.length > 50) {
      return 'Ошибка приложения';
    }

    return title;
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    // ✅ УБРАНО: debugPrint('📱 Инициализация сервиса уведомлений...');

    try {
      // Инициализируем push-сервис
      await _pushService.initialize();

      await _loadNotificationsFromStorage();

      // Обновляем бейдж на основе непрочитанных уведомлений
      await _updateBadgeCount();

      // ✅ УБРАНО: debugPrint('✅ Сервис уведомлений инициализирован. Загружено: ${_notifications.length} уведомлений');
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки инициализации
    }
  }

  /// Обработчик нажатий на уведомления
  void _handleNotificationTap(String payload) {
    try {
      final payloadData = json.decode(payload);
      final notificationId = payloadData['id'] as String?;

      if (notificationId != null) {
        // Отмечаем уведомление как прочитанное при нажатии
        markAsRead(notificationId);
        // ✅ УБРАНО: debugPrint('📱 Уведомление отмечено как прочитанное: $notificationId');
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки обработки нажатия на уведомление
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
          // ✅ УБРАНО: debugPrint с деталями ошибки парсинга уведомления
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
      // ✅ УБРАНО: debugPrint с деталями ошибки загрузки уведомлений
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
      // ✅ УБРАНО: debugPrint с деталями ошибки сохранения уведомлений
    }
  }

  /// Обновление счетчика бейджа
  Future<void> _updateBadgeCount() async {
    try {
      final unreadCount = getUnreadCount();
      await _pushService.setBadgeCount(unreadCount);
      // ✅ УБРАНО: debugPrint('✅ Бейдж обновлен: $unreadCount');
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки обновления бейджа
    }
  }

  /// Добавление нового уведомления с фильтрацией ошибок
  Future<void> addNotification(NotificationModel notification) async {
    try {
      // Очищаем сообщение и заголовок от технических ошибок
      final cleanedTitle = _cleanErrorTitle(notification.title);
      final cleanedMessage = _cleanErrorMessage(notification.message, notification.title);

      // Создаем очищенное уведомление
      final cleanedNotification = notification.copyWith(
        title: cleanedTitle,
        message: cleanedMessage,
      );

      // ✅ УБРАНО: Логирование очистки уведомлений с техническими деталями

      // Проверяем, нет ли уже такого уведомления (по ID)
      final existingIndex = _notifications.indexWhere((n) => n.id == cleanedNotification.id);

      if (existingIndex != -1) {
        // Обновляем существующее
        _notifications[existingIndex] = cleanedNotification;
      } else {
        // Добавляем новое в начало списка
        _notifications.insert(0, cleanedNotification);
      }

      // Ограничиваем количество уведомлений
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }

      await _saveNotificationsToStorage();

      // Отправляем очищенное push-уведомление
      await _pushService.showNotification(cleanedNotification);

      // Обновляем бейдж
      await _updateBadgeCount();

      // Уведомляем слушателей об изменениях
      _notificationsController.add(List.from(_notifications));

      // ✅ УБРАНО: debugPrint('✅ Уведомление добавлено: ${cleanedNotification.title}');
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки добавления уведомления
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

  /// Специальный метод для добавления уведомлений о турнирах
  Future<void> addTournamentReminderNotification({
    required String id,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Очищаем сообщение от технических данных
      String cleanMessage = message;

      // Удаляем техническую информацию из сообщения
      final lines = cleanMessage.split('\n');
      final filteredLines = lines.where((line) {
        return !line.startsWith('eventId:') &&
            !line.startsWith('eventType:') &&
            !line.startsWith('location:') &&
            !line.startsWith('eventTitle:') &&
            !line.startsWith('eventStartDate:') &&
            !line.trim().startsWith('Дополнительные данные:');
      }).toList();

      cleanMessage = filteredLines.join('\n').trim();

      final notification = NotificationModel(
        id: id,
        title: title,
        message: cleanMessage,
        type: NotificationType.tournamentReminder,
        timestamp: DateTime.now(),
        data: data,
      );

      await addNotification(notification);

      // ✅ УБРАНО: debugPrint с деталями добавления уведомления о турнире
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки добавления уведомления о турнире
    }
  }

  /// Специальный метод для добавления уведомлений о рыбалке
  Future<void> addFishingReminderNotification({
    required String id,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Очищаем сообщение от технических данных
      String cleanMessage = message;

      // Удаляем техническую информацию из сообщения
      final lines = cleanMessage.split('\n');
      final filteredLines = lines.where((line) {
        return !line.startsWith('eventId:') &&
            !line.startsWith('eventType:') &&
            !line.startsWith('location:') &&
            !line.startsWith('eventTitle:') &&
            !line.startsWith('eventStartDate:') &&
            !line.trim().startsWith('Дополнительные данные:');
      }).toList();

      cleanMessage = filteredLines.join('\n').trim();

      final notification = NotificationModel(
        id: id,
        title: title,
        message: cleanMessage,
        type: NotificationType.fishingReminder,
        timestamp: DateTime.now(),
        data: data,
      );

      await addNotification(notification);

      // ✅ УБРАНО: debugPrint с подтверждением добавления уведомления о рыбалке
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки добавления уведомления о рыбалке
    }
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

        // Обновляем бейдж
        await _updateBadgeCount();

        _notificationsController.add(List.from(_notifications));

        // ✅ УБРАНО: debugPrint('✅ Уведомление отмечено как прочитанное: $notificationId');
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки отметки уведомления как прочитанного
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

        // Очищаем бейдж при прочтении всех уведомлений
        await _pushService.clearBadge();

        _notificationsController.add(List.from(_notifications));

        // ✅ УБРАНО: debugPrint с подтверждением отметки всех уведомлений как прочитанных
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки отметки всех уведомлений как прочитанных
    }
  }

  /// Удаление уведомления
  Future<void> removeNotification(String notificationId) async {
    try {
      final initialLength = _notifications.length;
      _notifications.removeWhere((notification) => notification.id == notificationId);

      if (_notifications.length != initialLength) {
        await _saveNotificationsToStorage();

        // Обновляем бейдж
        await _updateBadgeCount();

        // Отменяем push-уведомление
        await _pushService.cancelNotification(notificationId);

        _notificationsController.add(List.from(_notifications));

        // ✅ УБРАНО: debugPrint('✅ Уведомление удалено: $notificationId');
      }
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки удаления уведомления
    }
  }

  /// Очистка всех уведомлений
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      await _saveNotificationsToStorage();

      // Очищаем все push-уведомления и бейдж
      await _pushService.cancelAllNotifications();
      await _pushService.clearBadge();

      _notificationsController.add(List.from(_notifications));

      // ✅ УБРАНО: debugPrint с подтверждением очистки всех уведомлений
    } catch (e) {
      // ✅ УБРАНО: debugPrint с деталями ошибки очистки уведомлений
    }
  }

  /// Получение уведомлений по типу
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  /// Добавление тестового уведомления с локализацией
  Future<void> addTestNotification({
    required String title,
    required String message,
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: NotificationType.general,
      data: {'test': true, 'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  /// Добавление уведомления о благоприятных условиях для рыбалки
  Future<void> addFavorableConditionsNotification({
    required String title,
    required String message,
    required int scorePoints,
    required String bestTime,
    Map<String, dynamic> additionalData = const {},
  }) async {
    await createNotification(
      title: title,
      message: message,
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
      data: {'weatherChange': true, ...weatherData},
    );
  }

  /// Добавление напоминания о рыбалке
  Future<void> addFishingReminder({
    required String title,
    required String message,
    required String location,
    required DateTime scheduledTime,
    Map<String, dynamic> additionalData = const {},
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: NotificationType.fishingReminder,
      data: {
        'location': location,
        'scheduledTime': scheduledTime.toIso8601String(),
        ...additionalData,
      },
    );
  }

  /// Получение настроек звука
  get soundSettings => _pushService.soundSettings;

  /// Обновление настроек звука
  Future<void> updateSoundSettings(settings) async {
    await _pushService.updateSoundSettings(settings);
  }

  /// Освобождение ресурсов
  void dispose() {
    _notificationsController.close();
    _pushService.dispose();
  }
}