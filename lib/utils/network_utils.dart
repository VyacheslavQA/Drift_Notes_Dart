// Путь: lib/utils/network_utils.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkUtils {
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
}