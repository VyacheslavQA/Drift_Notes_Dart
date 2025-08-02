// Путь: lib/services/location_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Ключи для SharedPreferences
  static const String _locationPermissionRequestedKey = 'location_permission_requested';
  static const String _locationPermissionGrantedKey = 'location_permission_granted';
  static const String _lastKnownLatitudeKey = 'last_known_latitude';
  static const String _lastKnownLongitudeKey = 'last_known_longitude';
  static const String _lastLocationUpdateKey = 'last_location_update';

  // Внутренние переменные
  bool _permissionRequested = false;
  bool _permissionGranted = false;
  Position? _lastKnownPosition;
  String _currentLocale = 'ru';

  // Геттеры
  bool get isPermissionRequested => _permissionRequested;
  bool get isPermissionGranted => _permissionGranted;
  Position? get lastKnownPosition => _lastKnownPosition;
  bool get hasLocation => _lastKnownPosition != null;

  // Установка локали для локализации сообщений
  void setLocale(String locale) {
    _currentLocale = locale;
  }

  // Инициализация - загрузка настроек
  Future<void> initialize() async {
    await _loadSettings();
  }

  // Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _permissionRequested = prefs.getBool(_locationPermissionRequestedKey) ?? false;
      _permissionGranted = prefs.getBool(_locationPermissionGrantedKey) ?? false;

      // Загружаем последнее известное местоположение
      final latitude = prefs.getDouble(_lastKnownLatitudeKey);
      final longitude = prefs.getDouble(_lastKnownLongitudeKey);
      final timestamp = prefs.getInt(_lastLocationUpdateKey);

      if (latitude != null && longitude != null && timestamp != null) {
        _lastKnownPosition = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  // Сохранение настроек
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_locationPermissionRequestedKey, _permissionRequested);
      await prefs.setBool(_locationPermissionGrantedKey, _permissionGranted);

      // Сохраняем последнее известное местоположение
      if (_lastKnownPosition != null) {
        await prefs.setDouble(_lastKnownLatitudeKey, _lastKnownPosition!.latitude);
        await prefs.setDouble(_lastKnownLongitudeKey, _lastKnownPosition!.longitude);
        await prefs.setInt(_lastLocationUpdateKey, _lastKnownPosition!.timestamp.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  // Проверка, запрашивались ли разрешения ранее
  Future<bool> hasRequestedPermissionBefore() async {
    await _loadSettings();
    return _permissionRequested;
  }

  // Проверка текущего статуса разрешений
  Future<bool> checkLocationPermission() async {
    try {
      // Проверяем через permission_handler
      final permissionStatus = await Permission.location.status;

      // Проверяем через geolocator
      final geolocatorPermission = await Geolocator.checkPermission();

      final isGranted = permissionStatus == PermissionStatus.granted &&
          (geolocatorPermission == LocationPermission.always ||
              geolocatorPermission == LocationPermission.whileInUse);

      _permissionGranted = isGranted;
      await _saveSettings();

      return isGranted;
    } catch (e) {
      return false;
    }
  }

  // Запрос разрешения на геолокацию (СИСТЕМНЫЙ ДИАЛОГ)
  Future<bool> requestLocationPermission() async {
    try {
      // Отмечаем, что разрешение было запрошено
      _permissionRequested = true;

      // Сначала проверяем, включены ли службы геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _saveSettings();
        return false;
      }

      // Запрашиваем разрешение через geolocator (показывает системный диалог)
      LocationPermission geolocatorPermission = await Geolocator.requestPermission();

      // Проверяем результат
      final isGranted = geolocatorPermission == LocationPermission.always ||
          geolocatorPermission == LocationPermission.whileInUse;

      _permissionGranted = isGranted;
      await _saveSettings();

      return isGranted;
    } catch (e) {
      _permissionRequested = true;
      _permissionGranted = false;
      await _saveSettings();
      return false;
    }
  }

  // Получение текущего местоположения
  Future<Position?> getCurrentPosition() async {
    try {
      // Проверяем разрешения
      if (!await checkLocationPermission()) {
        return _lastKnownPosition;
      }

      // Проверяем, включены ли службы геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _lastKnownPosition;
      }

      // Получаем текущую позицию
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Сохраняем как последнее известное местоположение
      _lastKnownPosition = position;
      await _saveSettings();

      return position;
    } catch (e) {
      return _lastKnownPosition;
    }
  }

  // Получение последнего известного местоположения (быстрое)
  Future<Position?> getLastKnownPosition() async {
    try {
      if (!await checkLocationPermission()) {
        return _lastKnownPosition;
      }

      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        _lastKnownPosition = lastPosition;
        await _saveSettings();
      }

      return lastPosition ?? _lastKnownPosition;
    } catch (e) {
      return _lastKnownPosition;
    }
  }

  // Открытие настроек приложения для управления разрешениями
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      // Silent error handling for production
    }
  }

  // Открытие настроек местоположения устройства
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      // Silent error handling for production
    }
  }

  // Проверка, устарело ли последнее местоположение
  bool isLocationStale({Duration maxAge = const Duration(hours: 1)}) {
    if (_lastKnownPosition == null) return true;

    final now = DateTime.now();
    final locationAge = now.difference(_lastKnownPosition!.timestamp);

    return locationAge > maxAge;
  }

  // Получение читаемой строки местоположения
  String getLocationDisplayString() {
    if (_lastKnownPosition == null) {
      return _currentLocale == 'en'
          ? 'Location unknown'
          : 'Местоположение неизвестно';
    }

    final lat = _lastKnownPosition!.latitude.toStringAsFixed(4);
    final lng = _lastKnownPosition!.longitude.toStringAsFixed(4);

    return '$lat, $lng';
  }

  // Получение сообщения о статусе разрешений
  String getPermissionStatusMessage() {
    if (!_permissionRequested) {
      return _currentLocale == 'en'
          ? 'Location permission not requested yet'
          : 'Разрешение на местоположение еще не запрашивалось';
    }

    if (!_permissionGranted) {
      return _currentLocale == 'en'
          ? 'Location permission denied'
          : 'Разрешение на местоположение отклонено';
    }

    return _currentLocale == 'en'
        ? 'Location permission granted'
        : 'Разрешение на местоположение предоставлено';
  }

  // Сброс настроек (для тестирования)
  Future<void> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_locationPermissionRequestedKey);
      await prefs.remove(_locationPermissionGrantedKey);
      await prefs.remove(_lastKnownLatitudeKey);
      await prefs.remove(_lastKnownLongitudeKey);
      await prefs.remove(_lastLocationUpdateKey);

      _permissionRequested = false;
      _permissionGranted = false;
      _lastKnownPosition = null;
    } catch (e) {
      // Silent error handling for production
    }
  }

  // Получение расстояния между двумя точками
  double getDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Получение расстояния от текущего местоположения до точки
  double? getDistanceToPoint(double latitude, double longitude) {
    if (_lastKnownPosition == null) return null;

    return getDistanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      latitude,
      longitude,
    );
  }

  // Форматирование расстояния
  String formatDistance(double meters) {
    if (meters < 1000) {
      return _currentLocale == 'en'
          ? '${meters.round()} m'
          : '${meters.round()} м';
    } else {
      final km = meters / 1000;
      return _currentLocale == 'en'
          ? '${km.toStringAsFixed(1)} km'
          : '${km.toStringAsFixed(1)} км';
    }
  }
}