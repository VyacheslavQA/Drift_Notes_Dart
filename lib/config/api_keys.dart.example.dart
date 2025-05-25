// Путь: lib/config/api_keys.dart.example
// Скопируйте этот файл в api_keys.dart и добавьте реальные ключи

import 'dart:io';

class ApiKeys {
  // Замени на свой реальный API ключ с weatherapi.com
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY_HERE';

  // Google Maps API ключ - добавьте ваш ключ сюда
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Firebase API ключи (если нужны дополнительные)
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';

  // YouTube API ключ (для будущего использования)
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY_HERE';

  // Проверки наличия ключей
  static bool get hasWeatherKey =>
      weatherApiKey.isNotEmpty &&
          !weatherApiKey.contains('YOUR_');

  static bool get hasGoogleMapsKey =>
      googleMapsApiKey.isNotEmpty &&
          !googleMapsApiKey.contains('YOUR_');

  static bool get hasFirebaseKey =>
      firebaseApiKey.isNotEmpty &&
          !firebaseApiKey.contains('YOUR_');

  static bool get hasYouTubeKey =>
      youtubeApiKey.isNotEmpty &&
          !youtubeApiKey.contains('YOUR_');

// Остальные методы...
}