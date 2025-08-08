import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';

class RayLandmarksHelper {
  // 🎨 КОНСТАНТЫ ИКОНОК (14 штук)
  static const Map<String, IconData> landmarkIcons = {
    'park': Icons.park,                    // Дерево
    'grass': Icons.grass,                  // Камыш
    'forest': Icons.forest,                // Хвойный лес
    'eco': Icons.eco,                      // Сухие деревья
    'terrain': Icons.terrain,              // Скала
    'landscape': Icons.landscape,          // Гора
    'electric_bolt': Icons.electric_bolt,  // ЛЭП
    'factory': Icons.factory,              // Завод
    'home': Icons.home,                    // Дом
    'cell_tower': Icons.cell_tower,        // Радиовышка
    'lightbulb': Icons.lightbulb,          // Фонарь
    'cottage': Icons.cottage,              // Беседка
    'wifi': Icons.wifi,                    // Интернет вышка
    'gps_fixed': Icons.gps_fixed,          // Точная локация
  };

  // 🔍 ПРОВЕРКА СУЩЕСТВОВАНИЯ ОРИЕНТИРА
  static bool hasLandmark(Map<String, dynamic> rayLandmarks, int rayIndex) {
    return rayLandmarks.containsKey(rayIndex.toString());
  }

  // 📍 ПОЛУЧЕНИЕ ОРИЕНТИРА
  static Map<String, dynamic>? getLandmark(Map<String, dynamic> rayLandmarks, int rayIndex) {
    return rayLandmarks[rayIndex.toString()] as Map<String, dynamic>?;
  }

  // ➕ ДОБАВЛЕНИЕ ОРИЕНТИРА
  static Map<String, dynamic> addLandmark(
      Map<String, dynamic> rayLandmarks,
      int rayIndex,
      String iconType,
      String comment
      ) {
    final updated = Map<String, dynamic>.from(rayLandmarks);
    updated[rayIndex.toString()] = {
      'iconType': iconType,
      'comment': comment,
    };
    return updated;
  }

  // 🗑️ УДАЛЕНИЕ ОРИЕНТИРА
  static Map<String, dynamic> removeLandmark(Map<String, dynamic> rayLandmarks, int rayIndex) {
    final updated = Map<String, dynamic>.from(rayLandmarks);
    updated.remove(rayIndex.toString());
    return updated;
  }

  // 🏷️ ПОЛУЧЕНИЕ НАЗВАНИЯ ОРИЕНТИРА
  static String getLandmarkName(String iconType, AppLocalizations localizations) {
    switch (iconType) {
      case 'park': return localizations.translate('landmark_tree');
      case 'grass': return localizations.translate('landmark_reed');
      case 'forest': return localizations.translate('landmark_coniferous_forest');
      case 'eco': return localizations.translate('landmark_dry_trees');
      case 'terrain': return localizations.translate('landmark_rock');
      case 'landscape': return localizations.translate('landmark_mountain');
      case 'electric_bolt': return localizations.translate('landmark_power_line');
      case 'factory': return localizations.translate('landmark_factory');
      case 'home': return localizations.translate('landmark_house');
      case 'cell_tower': return localizations.translate('landmark_radio_tower');
      case 'lightbulb': return localizations.translate('landmark_lamp_post');
      case 'cottage': return localizations.translate('landmark_gazebo');
      case 'wifi': return localizations.translate('landmark_internet_tower');
      case 'gps_fixed': return localizations.translate('landmark_exact_location');
      default: return iconType;
    }
  }

  // 🎨 ПОЛУЧЕНИЕ ИКОНКИ
  static IconData getLandmarkIcon(String iconType) {
    return landmarkIcons[iconType] ?? Icons.place;
  }

  // 📋 ПОЛУЧЕНИЕ СПИСКА ВСЕХ ИКОНОК ДЛЯ ДИАЛОГА
  static List<String> getAllIconTypes() {
    return landmarkIcons.keys.toList();
  }

  // ✅ ВАЛИДАЦИЯ ICONTYPE
  static bool isValidIconType(String iconType) {
    return landmarkIcons.containsKey(iconType);
  }
}