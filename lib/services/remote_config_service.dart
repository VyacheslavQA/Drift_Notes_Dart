import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static RemoteConfigService? _instance;
  static RemoteConfigService get instance => _instance ??= RemoteConfigService._();

  RemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Инициализация Remote Config
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Настройки конфигурации
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(seconds: 10)  // Для тестирования
            : const Duration(hours: 1),    // Для продакшена
      ));

      // Значения по умолчанию (fallback если сервер недоступен)
      await _remoteConfig!.setDefaults({
        'show_weather_feature': true,
        'max_free_notes': 10,
        'maintenance_message': '',
        'enable_new_features': false,
      });

      // Получаем конфигурацию с сервера
      await _remoteConfig!.fetchAndActivate();

      _initialized = true;
      debugPrint('✅ Remote Config инициализирован успешно');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации Remote Config: $e');
      // Продолжаем работу с значениями по умолчанию
      _initialized = false;
    }
  }

  /// Проверка готовности сервиса
  bool get isInitialized => _initialized && _remoteConfig != null;

  /// Получить все параметры (для отладки)
  Map<String, dynamic> getAllParameters() {
    if (!isInitialized) return {};

    return {
      'show_weather_feature': showWeatherFeature,
      'max_free_notes': maxFreeNotes,
      'maintenance_message': maintenanceMessage,
      'enable_new_features': enableNewFeatures,
    };
  }

  // ==========================================
  // ГЕТТЕРЫ ДЛЯ ПАРАМЕТРОВ
  // ==========================================

  /// Показывать ли функции погоды
  bool get showWeatherFeature {
    try {
      return _remoteConfig?.getBool('show_weather_feature') ?? true;
    } catch (e) {
      debugPrint('Ошибка получения show_weather_feature: $e');
      return true; // значение по умолчанию
    }
  }

  /// Максимальное количество заметок для бесплатных пользователей
  int get maxFreeNotes {
    try {
      return _remoteConfig?.getInt('max_free_notes') ?? 10;
    } catch (e) {
      debugPrint('Ошибка получения max_free_notes: $e');
      return 10; // значение по умолчанию
    }
  }

  /// Сообщение о техническом обслуживании
  String get maintenanceMessage {
    try {
      return _remoteConfig?.getString('maintenance_message') ?? '';
    } catch (e) {
      debugPrint('Ошибка получения maintenance_message: $e');
      return ''; // значение по умолчанию
    }
  }

  /// Включить ли бета-функции
  bool get enableNewFeatures {
    try {
      return _remoteConfig?.getBool('enable_new_features') ?? false;
    } catch (e) {
      debugPrint('Ошибка получения enable_new_features: $e');
      return false; // значение по умолчанию
    }
  }

  // ==========================================
  // МЕТОДЫ УПРАВЛЕНИЯ
  // ==========================================

  /// Принудительное обновление конфигурации
  Future<bool> forceRefresh() async {
    try {
      if (!isInitialized) return false;

      await _remoteConfig!.fetchAndActivate();
      debugPrint('✅ Remote Config обновлен принудительно');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка принудительного обновления: $e');
      return false;
    }
  }

  /// Проверка на техническое обслуживание
  bool get isMaintenanceMode {
    final message = maintenanceMessage;
    return message.isNotEmpty;
  }

  /// Получить информацию о последнем обновлении
  DateTime? get lastFetchTime {
    try {
      return _remoteConfig?.lastFetchTime;
    } catch (e) {
      return null;
    }
  }

  /// Получить статус последней загрузки
  String get lastFetchStatus {
    try {
      final status = _remoteConfig?.lastFetchStatus;
      if (status == null) return 'unknown';

      return status.name; // Используем встроенное свойство name
    } catch (e) {
      return 'error';
    }
  }

  // ==========================================
  // МЕТОДЫ ДЛЯ ИНТЕГРАЦИИ С БИЗНЕС-ЛОГИКОЙ
  // ==========================================

  /// Проверить может ли пользователь создать заметку
  bool canCreateNote(int currentNotesCount, bool isPremiumUser) {
    if (isPremiumUser) return true;
    return currentNotesCount < maxFreeNotes;
  }

  /// Получить лимит заметок с учетом подписки
  int getNotesLimit(bool isPremiumUser) {
    return isPremiumUser ? 999999 : maxFreeNotes;
  }

  /// Debug информация
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'last_fetch_time': lastFetchTime?.toIso8601String(),
      'last_fetch_status': lastFetchStatus,
      'parameters': getAllParameters(),
    };
  }
}