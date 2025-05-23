// Путь: lib/utils/fishing_type_icons.dart

import 'package:flutter/material.dart';

class FishingTypeIcons {
  // Карта с путями к иконкам для разных типов рыбалки (по ключам локализации)
  static Map<String, String> iconPaths = {
    'carp_fishing': 'assets/images/fishing_types/carp_fishing.png',
    'spinning': 'assets/images/fishing_types/spinning.png',
    'feeder': 'assets/images/fishing_types/feeder.png',
    'float_fishing': 'assets/images/fishing_types/float_fishing.png',
    'ice_fishing': 'assets/images/fishing_types/ice_fishing.png',
    'fly_fishing': 'assets/images/fishing_types/fly_fishing.png',
    'trolling': 'assets/images/fishing_types/trolling.png',
    'other_fishing': 'assets/images/fishing_types/other.png',
  };

  // Карта с иконками Material Design для разных типов рыбалки, на случай если изображения недоступны
  static Map<String, IconData> fallbackIcons = {
    'carp_fishing': Icons.waves,
    'spinning': Icons.sailing,
    'feeder': Icons.add_road,
    'float_fishing': Icons.crop_free,
    'ice_fishing': Icons.ac_unit,
    'fly_fishing': Icons.air,
    'trolling': Icons.directions_boat,
    'other_fishing': Icons.category,
  };

  // Получить путь к иконке для данного типа рыбалки
  static String getIconPath(String fishingTypeKey) {
    return iconPaths[fishingTypeKey] ?? 'assets/images/fishing_types/other.png';
  }

  // Получить IconData для данного типа рыбалки
  static IconData getFallbackIcon(String fishingTypeKey) {
    return fallbackIcons[fishingTypeKey] ?? Icons.category;
  }

  // Получить виджет Image для данного типа рыбалки с запасным вариантом в виде иконки
  static Widget getIconWidget(String fishingTypeKey, {double size = 24.0}) {
    final iconPath = getIconPath(fishingTypeKey);
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        // Если изображение не загружается, показываем запасную иконку
        return Icon(
          getFallbackIcon(fishingTypeKey),
          size: size,
          color: Colors.white,
        );
      },
    );
  }
}