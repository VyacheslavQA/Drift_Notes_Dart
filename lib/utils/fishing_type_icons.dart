// Путь: lib/utils/fishing_type_icons.dart

import 'package:flutter/material.dart';

class FishingTypeIcons {
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

  // Получить путь к иконке для данного типа рыбалки
  static String getIconPath(String fishingType) {
    return iconPaths[fishingType] ?? 'assets/images/fishing_types/other.png';
  }

  // Получить виджет Image для данного типа рыбалки
  static Widget getIconWidget(String fishingType, {double size = 24.0}) {
    return Image.asset(
      getIconPath(fishingType),
      width: size,
      height: size,
    );
  }
}