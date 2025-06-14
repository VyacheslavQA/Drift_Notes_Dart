// Путь: lib/services/local_push_notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_sound_settings_model.dart';
import '../models/notification_model.dart';

class LocalPushNotificationService {
  static final LocalPushNotificationService _instance =
  LocalPushNotificationService._internal();
  factory LocalPushNotificationService() => _instance;
  LocalPushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  NotificationSoundSettings _soundSettings = const NotificationSoundSettings();
  bool _isInitialized = false;
  int _currentBadgeCount = 0;

  // Ключи для SharedPreferences
  static const String _soundSettingsKey = 'notification_sound_settings';
  static const String _badgeCountKey = 'notification_badge_count';

  // Stream для уведомления о нажатиях на уведомления
  final StreamController<String> _notificationTapStreamController =
  StreamController<String>.broadcast();

  Stream<String> get notificationTapStream =>
      _notificationTapStreamController.stream;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔔 Инициализация сервиса локальных push-уведомлений...');

    try {
      await _loadSoundSettings();
      await _loadBadgeCount();
      await _initializeNotifications();

      _isInitialized = true;
      debugPrint('✅ Сервис локальных push-уведомлений инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации push-уведомлений: $e');
    }
  }

  /// Инициализация плагина уведомлений
  Future<void> _initializeNotifications() async {
    try {
      // Настройки для Android
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // Настройки для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      debugPrint('✅ Flutter Local Notifications инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации уведомлений: $e');
    }
  }

  /// Обработчик нажатий на уведомления
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Нажатие на уведомление: ${response.payload}');
    if (response.payload != null) {
      _notificationTapStreamController.add(response.payload!);
    }
  }

  /// Отправка уведомления
  Future<void> showNotification(NotificationModel notification) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Сервис не инициализирован');
      return;
    }

    try {
      // Проверяем настройки звука
      final shouldPlaySound = _soundSettings.shouldPlaySound();
      final shouldVibrate = _soundSettings.vibrationEnabled && !_soundSettings.isQuietHours();

      // Настройки для Android
      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Уведомления',
        channelDescription: 'Уведомления приложения',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: shouldVibrate,
        playSound: shouldPlaySound,
        // Убираем sound параметр - будет использоваться системный звук по умолчанию
        icon: '@mipmap/launcher_icon',
        color: Color(notification.typeColor),
        styleInformation: BigTextStyleInformation(
          notification.message,
          contentTitle: notification.title,
        ),
      );

      // Настройки для iOS
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: shouldPlaySound,
        // Убираем sound параметр - будет использоваться системный звук по умолчанию
        subtitle: _getNotificationTypeText(notification.type),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Отправляем уведомление
      await _notifications.show(
        notification.id.hashCode,
        notification.title,
        notification.message,
        notificationDetails,
        payload: json.encode({
          'id': notification.id,
          'type': notification.type.toString(),
          'timestamp': notification.timestamp.toIso8601String(),
        }),
      );

      // Обновляем счетчик
      if (_soundSettings.badgeEnabled) {
        await _incrementBadge();
      }

      debugPrint('✅ Уведомление отправлено: ${notification.title}');

    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления: $e');
    }
  }

  /// Получение текста типа уведомления
  String _getNotificationTypeText(NotificationType type) {
    // Используем английские fallback значения, так как у нас нет доступа к контексту
    // В реальном push-уведомлении это не так критично
    switch (type) {
      case NotificationType.general:
        return 'General';
      case NotificationType.fishingReminder:
        return 'Reminder';
      case NotificationType.tournamentReminder:
        return 'Tournament';
      case NotificationType.biteForecast:
        return 'Bite forecast';
      case NotificationType.weatherUpdate:
        return 'Weather';
      case NotificationType.newFeatures:
        return 'News';
      case NotificationType.systemUpdate:
        return 'System';
      case NotificationType.policyUpdate:
        return 'Documents';
    }
  }

  // Упрощенные методы для работы с бейджем

  /// Увеличение счетчика бейджа
  Future<void> _incrementBadge() async {
    _currentBadgeCount++;
    await _updateBadge();
  }

  /// Установка конкретного значения бейджа
  Future<void> setBadgeCount(int count) async {
    _currentBadgeCount = count;
    await _updateBadge();
  }

  /// Очистка бейджа
  Future<void> clearBadge() async {
    _currentBadgeCount = 0;
    await _updateBadge();
  }

  /// Обновление бейджа на иконке
  Future<void> _updateBadge() async {
    try {
      if (_soundSettings.badgeEnabled && _currentBadgeCount > 0) {
        await AppBadgePlus.updateBadge(_currentBadgeCount);
        debugPrint('✅ Бейдж обновлен: $_currentBadgeCount');
      } else {
        await AppBadgePlus.updateBadge(0);
        debugPrint('✅ Бейдж очищен');
      }

      // Сохраняем в SharedPreferences
      await _saveBadgeCount();

    } catch (e) {
      debugPrint('❌ Ошибка обновления бейджа: $e');
    }
  }

  /// Сохранение счетчика бейджа
  Future<void> _saveBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, _currentBadgeCount);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения счетчика бейджа: $e');
    }
  }

  /// Загрузка счетчика бейджа
  Future<void> _loadBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBadgeCount = prefs.getInt(_badgeCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки счетчика бейджа: $e');
    }
  }

  // Методы для работы с настройками звука

  /// Получение текущих настроек звука
  NotificationSoundSettings get soundSettings => _soundSettings;

  /// Обновление настроек звука
  Future<void> updateSoundSettings(NotificationSoundSettings newSettings) async {
    _soundSettings = newSettings;
    await _saveSoundSettings();
  }

  /// Загрузка настроек звука
  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_soundSettingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson);
        _soundSettings = NotificationSoundSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки настроек звука: $e');
    }
  }

  /// Сохранение настроек звука
  Future<void> _saveSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_soundSettings.toJson());
      await prefs.setString(_soundSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настроек звука: $e');
    }
  }

  /// Отмена всех уведомлений
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомлений: $e');
    }
  }

  /// Отмена конкретного уведомления
  Future<void> cancelNotification(String notificationId) async {
    try {
      await _notifications.cancel(notificationId.hashCode);
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомления: $e');
    }
  }

  /// Проверка поддержки бейджей
  Future<bool> isBadgeSupported() async {
    try {
      return await AppBadgePlus.isSupported();
    } catch (e) {
      debugPrint('❌ Ошибка проверки поддержки бейджа: $e');
      return Platform.isIOS; // Fallback - iOS всегда поддерживает
    }
  }

  /// Освобождение ресурсов
  void dispose() {
    _notificationTapStreamController.close();
  }
}