// Путь: lib/utils/fishing_type_icons.dart

import 'package:flutter/material.dart';

class FishingTypeIcons {
  // Карта с путями к иконкам для разных типов рыбалки
  static Map<String, String> iconPaths = {
    'Карповая рыбалка': 'assets/images/fishing_types/carp_fishing.png',
    'Спиннинг': 'assets/images/fishing_types/spinning.png',
    'Фидер': 'assets/images/fishing_types/feeder.png',
    'Поплавочная': 'assets/images/fishing_types/float_fishing.png',
    'Зимняя рыбалка': 'assets/images/fishing_types/ice_fishing.png',
    'Нахлыст': 'assets/images/fishing_types/fly_fishing.png',
    'Троллинг': 'assets/images/fishing_types/trolling.png',
    'Другое': 'assets/images/fishing_types/other.png',
  };

  // Карта с иконками Material Design для разных типов рыбалки, на случай если изображения недоступны
  static Map<String, IconData> fallbackIcons = {
    'Карповая рыбалка': Icons.waves,
    'Спиннинг': Icons.sailing,
    'Фидер': Icons.add_road,
    'Поплавочная': Icons.crop_free,
    'Зимняя рыбалка': Icons.ac_unit,
    'Нахлыст': Icons.air,
    'Троллинг': Icons.directions_boat,
    'Другое': Icons.category,
  };

  // Получить путь к иконке для данного типа рыбалки
  static String getIconPath(String fishingType) {
    return iconPaths[fishingType] ?? 'assets/images/fishing_types/other.png';
  }

  // Получить IconData для данного типа рыбалки
  static IconData getFallbackIcon(String fishingType) {
    return fallbackIcons[fishingType] ?? Icons.category;
  }

  // Получить виджет Image для данного типа рыбалки с запасным вариантом в виде иконки
  static Widget getIconWidget(String fishingType, {double size = 24.0}) {
    final iconPath = getIconPath(fishingType);
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        // Если изображение не загружается, показываем запасную иконку
        return Icon(
          getFallbackIcon(fishingType),
          size: size,
          color: Colors.white,
        );
      },
    );
  }
}