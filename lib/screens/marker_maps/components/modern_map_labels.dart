// Путь: lib/screens/marker_maps/components/modern_map_labels.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../localization/app_localizations.dart';
import '../../../constants/app_constants.dart';

/// Современные подписи карты с поддержкой ориентиров
class ModernMapLabels extends StatelessWidget {
  final double maxDistance;
  final int rayCount;
  final double leftAngle;
  final double rightAngle;
  final Size screenSize;
  final Map<String, dynamic> rayLandmarks; // 🔥 НОВЫЙ параметр - ориентиры лучей
  final Function(int rayIndex)? onRayLabelTap; // 🔥 НОВЫЙ параметр - колбэк клика на подпись луча
  final Function(int rayIndex)? onLandmarkTap; // 🔥 НОВЫЙ параметр - колбэк клика на ориентир
  final List<bool> rayVisibility; // 🔥 НОВЫЙ ПАРАМЕТР для видимости лучей

  const ModernMapLabels({
    super.key,
    required this.maxDistance,
    required this.rayCount,
    required this.leftAngle,
    required this.rightAngle,
    required this.screenSize,
    this.rayLandmarks = const {}, // 🔥 НОВЫЙ параметр с дефолтным значением
    this.onRayLabelTap, // 🔥 НОВЫЙ параметр
    this.onLandmarkTap, // 🔥 НОВЫЙ параметр
    required this.rayVisibility, // 🔥 НОВЫЙ ОБЯЗАТЕЛЬНЫЙ ПАРАМЕТР
  });

  /// 🎯 СЛОВАРЬ ИКОНОК ОРИЕНТИРОВ
  static const Map<String, IconData> _landmarkIcons = {
    'tree': Icons.park,              // Дерево
    'reed': Icons.grass,             // Камыш
    'forest': Icons.forest,          // Хвойный лес
    'dry_trees': Icons.eco,          // Сухие деревья
    'rock': Icons.terrain,           // Скала
    'mountain': Icons.landscape,     // Гора
    'power_line': Icons.electric_bolt, // ЛЭП
    'factory': Icons.factory,        // Завод
    'house': Icons.home,             // Дом
    'radio_tower': Icons.cell_tower, // Радиовышка
    'lamp_post': Icons.lightbulb,    // Фонарь
    'gazebo': Icons.cottage,         // Беседка
    'internet_tower': Icons.wifi,    // Интернет вышка
    'bridge': Icons.straighten,         // 🌉 НОВАЯ СТРОКА - Мост/помост
    'exact_location': Icons.gps_fixed, // Точная локация
  };

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final centerX = screenSize.width / 2;
    final originY = screenSize.height - 20; // 🔥 ИСПРАВЛЕНО: отступ от низа экрана
    final pixelsPerMeter = screenSize.height / (maxDistance * 1.1);

    return RepaintBoundary(
      child: Stack(
        children: [
          // 📐 Подписи расстояний (10-50м)
          ..._buildDistanceLabels(centerX, originY, pixelsPerMeter),

          // 📐 Подписи больших расстояний (60-200м)
          ..._buildLargeDistanceLabels(centerX, originY, pixelsPerMeter),

          // 🎯 ОБНОВЛЕННЫЕ подписи лучей с поддержкой ориентиров
          ..._buildRayLabelsWithLandmarks(localizations, centerX, originY),
        ],
      ),
    );
  }

  /// 🔥 НОВЫЙ МЕТОД - Проверка нужно ли показывать луч
  bool _shouldShowRay(int rayIndex) {
    if (rayIndex < 0 || rayIndex >= rayVisibility.length) {
      return true; // По умолчанию показываем если индекс некорректный
    }
    return rayVisibility[rayIndex];
  }

  /// Подписи расстояний 10-50м (оригинальная логика)
  List<Widget> _buildDistanceLabels(double centerX, double originY, double pixelsPerMeter) {
    return List.generate(5, (index) {
      final distance = (index + 1) * 10; // 10, 20, 30, 40, 50

      return Positioned(
        left: centerX - distance * pixelsPerMeter + 4,
        top: originY - 35, // 🔥 ОПУСКАЕМ НИЖЕ (было -80, стало -35)
        child: Transform.rotate(
          angle: -math.pi / 2, // Поворот на 90 градусов
          child: Text(
            distance.toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Подписи больших расстояний (оригинальная логика)
  List<Widget> _buildLargeDistanceLabels(double centerX, double originY, double pixelsPerMeter) {
    final distancePositions = [
      {'distance': 60, 'offset': 95.0},
      {'distance': 70, 'offset': 70.0},
      {'distance': 80, 'offset': 55.0},
      {'distance': 90, 'offset': 50.0},
      {'distance': 100, 'offset': 40.0},
      {'distance': 110, 'offset': 35.0},
      {'distance': 120, 'offset': 30.0},
      {'distance': 130, 'offset': 25.0},
      {'distance': 140, 'offset': 22.0},
      {'distance': 150, 'offset': 22.0},
      {'distance': 160, 'offset': 18.0},
      {'distance': 170, 'offset': 18.0},
      {'distance': 180, 'offset': 15.0},
      {'distance': 190, 'offset': 15.0},
      {'distance': 200, 'offset': 15.0},
    ];

    return distancePositions.map((pos) {
      final distance = pos['distance'] as int;
      final offset = pos['offset'] as double;

      return Positioned(
        left: 8,
        top: originY - distance * pixelsPerMeter + offset,
        child: Text(
          distance.toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 🔥 НОВЫЙ МЕТОД - Подписи лучей с поддержкой ориентиров
  List<Widget> _buildRayLabelsWithLandmarks(AppLocalizations localizations, double centerX, double originY) {
    return List.generate(rayCount, (i) {
      final angle = _calculateRayAngle(i);

      // Базовые параметры позиционирования (та же логика что раньше)
      double labelY = 30.0;
      final rayAtLabelY = (originY - labelY);
      double labelX = centerX + rayAtLabelY / math.tan(angle);

      // Индивидуальные корректировки для каждого луча (оригинальная логика)
      switch (i) {
        case 0:
          labelY += 20.0;
          labelX -= 60.0;
          labelX = math.max(labelX, 30.0);
          break;
        case 1:
          labelY += 5.0;
          break;
        case 2:
          break;
        case 3:
          labelY += 5.0;
          break;
        case 4:
          labelY += 20.0;
          labelX += 40.0;
          labelX = math.min(labelX, screenSize.width - 30.0);
          break;
      }

      // 🔥 ПРОВЕРКА ВИДИМОСТИ - если луч скрыт, не показываем его подпись и ориентир
      final isRayVisible = _shouldShowRay(i);

      // 🔥 ПРОВЕРЯЕМ есть ли ориентир для этого луча
      final landmarkKey = i.toString(); // Ключ в rayLandmarks (0, 1, 2, 3, 4)
      final hasLandmark = rayLandmarks.containsKey(landmarkKey);
      final landmark = hasLandmark ? rayLandmarks[landmarkKey] : null;

      return Positioned(
        left: labelX - 30, // Центрируем текст
        top: labelY - 10,
        child: SizedBox(
          width: 60,
          height: 40, // 🔥 Увеличиваем высоту для лучшего таргетинга
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🎯 1. ПОКАЗЫВАЕМ ПОДПИСЬ ТОЛЬКО ЕСЛИ ЛУЧ ВИДИМ
              if (isRayVisible) ...[
                Text(
                  '${localizations.translate('ray')} ${i + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),

                // 🎯 2. КЛИКАБЕЛЬНЫЙ СЛОЙ ТОЛЬКО ДЛЯ ВИДИМЫХ ЛУЧЕЙ
                if (!hasLandmark) ...[
                  // 🔥 КЛИКАБЕЛЬНАЯ ПОДПИСЬ ЛУЧА (если нет ориентира)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          debugPrint('🎯 Клик на луч ${i + 1}');
                          onRayLabelTap?.call(i);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${localizations.translate('ray')} ${i + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600, // 🔥 Чуть жирнее для кликабельности
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // 🏗️ ИКОНКА ОРИЕНТИРА (если ориентир установлен)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          debugPrint('🏗️ Клик на ориентир луча ${i + 1}: ${landmark['type']}');
                          onLandmarkTap?.call(i);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _landmarkIcons[landmark['type']] ?? Icons.place,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    });
  }

  /// Вычисление угла луча (оригинальная логика)
  double _calculateRayAngle(int rayIndex) {
    final totalAngle = leftAngle - rightAngle;
    final angleStep = totalAngle / (rayCount - 1);
    final angleDegrees = leftAngle - (rayIndex * angleStep);
    return angleDegrees * (math.pi / 180);
  }
}