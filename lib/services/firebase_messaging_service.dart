import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';
import 'firebase/firebase_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseService _firebaseService = FirebaseService();

  String? _fcmToken;
  bool _isInitialized = false;

  // Ключи для SharedPreferences
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmEnabledKey = 'fcm_enabled';

  /// Инициализация Firebase Cloud Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔥 Инициализация Firebase Cloud Messaging...');

      // 1. Запрашиваем разрешения
      await _requestPermissions();

      // 2. Получаем FCM токен
      await _getFCMToken();

      // 3. Настраиваем обработчики сообщений
      _setupMessageHandlers();

      // 4. Обрабатываем уведомления при открытии приложения
      await _handleInitialMessage();

      _isInitialized = true;
      debugPrint('✅ Firebase Cloud Messaging инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации FCM: $e');
    }
  }

  /// Запрос разрешений на push-уведомления
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        carPlay: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Разрешения на push-уведомления получены');
        await _setFCMEnabled(true);
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Получены провизорные разрешения на уведомления');
        await _setFCMEnabled(true);
      } else {
        debugPrint('❌ Разрешения на push-уведомления отклонены');
        await _setFCMEnabled(false);
      }
    } catch (e) {
      debugPrint('❌ Ошибка запроса разрешений FCM: $e');
      await _setFCMEnabled(false);
    }
  }

  /// Получение FCM токена
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        debugPrint('✅ FCM токен получен: ${_fcmToken!.substring(0, 20)}...');


        // Сохраняем токен локально
        await _saveFCMToken(_fcmToken!);

        // Отправляем токен на сервер (если пользователь авторизован)
        await _sendTokenToServer(_fcmToken!);
      } else {
        debugPrint('❌ Не удалось получить FCM токен');
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения FCM токена: $e');
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений когда приложение в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления когда приложение в background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Обновление токена
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Обработка сообщений в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📱 Получено FCM сообщение в foreground: ${message.messageId}');

      await _processRemoteMessage(message, isBackground: false);
    } catch (e) {
      debugPrint('❌ Ошибка обработки foreground сообщения: $e');
    }
  }

  /// Обработка нажатий на уведомления из background
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    try {
      debugPrint('📱 Нажатие на FCM уведомление из background: ${message.messageId}');

      await _processRemoteMessage(message, isBackground: true, isTap: true);
    } catch (e) {
      debugPrint('❌ Ошибка обработки background tap: $e');
    }
  }

  /// Обработка начального сообщения (при открытии из terminated state)
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint('📱 Приложение открыто из FCM уведомления: ${initialMessage.messageId}');
        await _processRemoteMessage(initialMessage, isBackground: true, isTap: true);
      }
    } catch (e) {
      debugPrint('❌ Ошибка обработки initial message: $e');
    }
  }

  /// Обработка обновления токена
  Future<void> _onTokenRefresh(String newToken) async {
    try {
      debugPrint('🔄 FCM токен обновлен');

      _fcmToken = newToken;
      await _saveFCMToken(newToken);
      await _sendTokenToServer(newToken);
    } catch (e) {
      debugPrint('❌ Ошибка обработки обновления токена: $e');
    }
  }

  /// Обработка удаленного сообщения
  Future<void> _processRemoteMessage(
      RemoteMessage message, {
        bool isBackground = false,
        bool isTap = false,
      }) async {
    try {
      // Извлекаем данные из сообщения
      final title = message.notification?.title ?? 'Уведомление';
      final body = message.notification?.body ?? '';
      final data = message.data;

      // Определяем тип уведомления
      final notificationType = _getNotificationTypeFromData(data);

      // Создаем локальное уведомление
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: body,
        type: notificationType,
        timestamp: DateTime.now(),
        data: data,
        isRead: isTap, // Если пользователь нажал на уведомление, считаем прочитанным
      );

      // Добавляем в локальную систему уведомлений
      await _notificationService.addNotification(notification);

      debugPrint('✅ FCM сообщение обработано: $title');
    } catch (e) {
      debugPrint('❌ Ошибка обработки FCM сообщения: $e');
    }
  }

  /// Определение типа уведомления из данных
  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    switch (type) {
      case 'fishing_reminder':
        return NotificationType.fishingReminder;
      case 'tournament_reminder':
        return NotificationType.tournamentReminder;
      case 'bite_forecast':
        return NotificationType.biteForecast;
      case 'weather_update':
        return NotificationType.weatherUpdate;
      case 'new_features':
        return NotificationType.newFeatures;
      case 'system_update':
        return NotificationType.systemUpdate;
      case 'policy_update':
        return NotificationType.policyUpdate;
      default:
        return NotificationType.general;
    }
  }

  /// Отправка токена на сервер
  Future<void> _sendTokenToServer(String token) async {
    try {
      if (!_firebaseService.isUserLoggedIn) {
        debugPrint('⚠️ Пользователь не авторизован, токен не отправлен');
        return;
      }

      // Сохраняем токен в профиле пользователя
      await _firebaseService.updateUserProfile({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        'devicePlatform': defaultTargetPlatform.name,
      });

      debugPrint('✅ FCM токен отправлен на сервер');
    } catch (e) {
      debugPrint('❌ Ошибка отправки токена на сервер: $e');
    }
  }

  /// Сохранение FCM токена локально
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения FCM токена: $e');
    }
  }

  /// Загрузка FCM токена
  Future<String?> _loadFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('❌ Ошибка загрузки FCM токена: $e');
      return null;
    }
  }

  /// Установка статуса FCM
  Future<void> _setFCMEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fcmEnabledKey, enabled);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения статуса FCM: $e');
    }
  }

  /// Получение статуса FCM
  Future<bool> isFCMEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_fcmEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ Ошибка получения статуса FCM: $e');
      return false;
    }
  }

  /// Подписка на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Подписка на топик: $topic');
    } catch (e) {
      debugPrint('❌ Ошибка подписки на топик $topic: $e');
    }
  }

  /// Отписка от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Отписка от топика: $topic');
    } catch (e) {
      debugPrint('❌ Ошибка отписки от топика $topic: $e');
    }
  }

  /// Получение текущего FCM токена
  String? get fcmToken => _fcmToken;

  /// Проверка инициализации
  bool get isInitialized => _isInitialized;
}

/// Background message handler (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background FCM сообщение: ${message.messageId}');

  // Здесь можно добавить дополнительную обработку background сообщений
  // Например, сохранение в локальную базу данных
}