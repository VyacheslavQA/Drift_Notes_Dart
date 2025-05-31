// Путь: lib/services/ai_preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AIPreferencesService {
  static final AIPreferencesService _instance = AIPreferencesService._internal();
  factory AIPreferencesService() => _instance;
  AIPreferencesService._internal();

  static const String _preferredTypesKey = 'ai_preferred_fishing_types';

  Future<List<String>> getPreferredFishingTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_preferredTypesKey) ?? [];
    } catch (e) {
      debugPrint('❌ Ошибка загрузки предпочтений ИИ: $e');
      return [];
    }
  }

  Future<void> setPreferredFishingTypes(List<String> types) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_preferredTypesKey, types);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения предпочтений ИИ: $e');
    }
  }
}