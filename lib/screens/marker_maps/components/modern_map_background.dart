// Путь: lib/screens/marker_maps/components/modern_map_background.dart

import 'package:flutter/material.dart';

/// Современный фон карты маркеров с градиентом
/// Заменяет Canvas отрисовку фона на простой Container
class ModernMapBackground extends StatelessWidget {
  const ModernMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white, // 🔥 СВЕТЛЫЙ БЕЛЫЙ
            Color(0xFFF8F9FA), // 🔥 ОЧЕНЬ СВЕТЛО-СЕРЫЙ для легкого градиента
          ],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }
}