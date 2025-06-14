// Путь: lib/utils/bottom_type_assets.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class BottomTypeAssets {
  // Карта с путями к PNG изображениям для разных типов дна
  static const Map<String, String> assetPaths = {
    'ил': 'assets/images/bottom_types/silt.png',
    'глубокий_ил': 'assets/images/bottom_types/deep_silt.png',
    'ракушка': 'assets/images/bottom_types/shell.png',
    'ровно_твердо': 'assets/images/bottom_types/firm_bottom.png',
    'камни': 'assets/images/bottom_types/stones.png',
    'трава_водоросли': 'assets/images/bottom_types/grass_algae.png',
    'зацеп': 'assets/images/bottom_types/snag.png',
    'бугор': 'assets/images/bottom_types/hill.png',
    'точка_кормления': 'assets/images/bottom_types/feeding_spot.png',
    'default': 'assets/images/bottom_types/silt.png',
  };

  // Запасные иконки Material Design на случай, если PNG недоступен
  static const Map<String, IconData> fallbackIcons = {
    'ил': Icons.blur_linear,
    'глубокий_ил': Icons.waves,
    'ракушка': Icons.grain,
    'ровно_твердо': Icons.view_agenda,
    'камни': Icons.circle,
    'трава_водоросли': Icons.grass,
    'зацеп': Icons.warning,
    'бугор': Icons.landscape,
    'точка_кормления': Icons.room_service,
    'default': Icons.location_on,
  };

  // Получить путь к PNG изображению для данного типа дна
  static String getAssetPath(String bottomType) {
    return assetPaths[bottomType] ?? assetPaths['default']!;
  }

  // Получить запасную иконку для данного типа дна
  static IconData getFallbackIcon(String bottomType) {
    return fallbackIcons[bottomType] ?? fallbackIcons['default']!;
  }

  // Получить виджет Image для данного типа дна с запасным вариантом в виде иконки
  static Widget getBottomTypeWidget(
    String bottomType, {
    double size = 24.0,
    Color? color,
  }) {
    final assetPath = getAssetPath(bottomType);

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color, // Для тонирования PNG изображения
      errorBuilder: (context, error, stackTrace) {
        // Если PNG изображение не загружается, показываем запасную иконку
        return Icon(
          getFallbackIcon(bottomType),
          size: size,
          color: color ?? Colors.white,
        );
      },
    );
  }

  // Специальная функция для Canvas - возвращает ui.Image для отрисовки
  static Future<ui.Image?> getCanvasImage(
    String bottomType, {
    double size = 24.0,
  }) async {
    try {
      final assetPath = getAssetPath(bottomType);
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size.round(),
        targetHeight: size.round(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Ошибка загрузки PNG изображения для $bottomType: $e');
      return null;
    }
  }

  // Получить список всех доступных типов дна
  static List<String> getAllBottomTypes() {
    return assetPaths.keys.where((key) => key != 'default').toList();
  }

  // Проверить, существует ли тип дна
  static bool isValidBottomType(String bottomType) {
    return assetPaths.containsKey(bottomType);
  }
}
