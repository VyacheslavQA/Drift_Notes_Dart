// Путь: lib/utils/network_utils.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkUtils {
  // Singleton для отслеживания состояния сети
  static final NetworkUtils _instance = NetworkUtils._internal();

  factory NetworkUtils() {
    return _instance;
  }

  NetworkUtils._internal();

  bool? _lastKnownConnectionState;
  final List<Function(bool)> _connectionListeners = [];

  // Проверяет наличие подключения к интернету
  static Future<bool> isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Ошибка при проверке подключения: $e');
      return false;
    }
  }

  // Запускает указанную функцию, обрабатывая состояние сети
  static Future<T?> runWithNetworkCheck<T>({
    required Future<T> Function() onlineAction,
    Future<T> Function()? offlineAction,
    required Function(dynamic) onError,
  }) async {
    try {
      final isOnline = await isNetworkAvailable();
      if (isOnline) {
        return await onlineAction();
      } else {
        if (offlineAction != null) {
          return await offlineAction();
        } else {
          onError('Отсутствует подключение к интернету');
          return null;
        }
      }
    } catch (e) {
      onError(e);
      return null;
    }
  }

  // Начать мониторинг состояния сети
  void startNetworkMonitoring() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final isConnected = result != ConnectivityResult.none;

      // Уведомляем только при изменении состояния
      if (_lastKnownConnectionState != isConnected) {
        _lastKnownConnectionState = isConnected;
        _notifyConnectionChange(isConnected);
      }
    });

    // Инициализация начального состояния
    isNetworkAvailable().then((value) {
      _lastKnownConnectionState = value;
      _notifyConnectionChange(value);
    });

    debugPrint('Мониторинг состояния сети запущен');
  }

  // Добавить слушателя изменений состояния сети
  void addConnectionListener(Function(bool) listener) {
    _connectionListeners.add(listener);

    // Если состояние сети уже известно, уведомляем слушателя сразу
    if (_lastKnownConnectionState != null) {
      listener(_lastKnownConnectionState!);
    }
  }

  // Удалить слушателя изменений состояния сети
  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  // Уведомить всех слушателей об изменении состояния сети
  void _notifyConnectionChange(bool isConnected) {
    for (var listener in _connectionListeners) {
      listener(isConnected);
    }
  }

  // Получить текущее состояние сети (или null, если не известно)
  bool? get currentConnectionState => _lastKnownConnectionState;
}