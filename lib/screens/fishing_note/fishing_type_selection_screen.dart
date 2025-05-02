// Путь: lib/screens/fishing_note/fishing_type_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/navigation.dart';
import '../../utils/fishing_type_icons.dart';
import 'add_fishing_note_screen.dart';

class FishingTypeSelectionScreen extends StatelessWidget {
  const FishingTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Выберите тип рыбалки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Выберите тип рыбалки для создания заметки',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: AppConstants.fishingTypes.length,
                itemBuilder: (context, index) {
                  final type = AppConstants.fishingTypes[index];
                  return _buildFishingTypeCard(context, type, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFishingTypeCard(BuildContext context, String fishingType, int index) {
    // Используем иконки из FishingTypeIcons, если они доступны
    // Иначе используем стандартные Material иконки
    IconData iconData;
    // Временно назначаем иконки, в будущем можно заменить на FishingTypeIcons.getIconWidget
    switch (index) {
      case 0: // Карповая рыбалка
        iconData = Icons.waves;
        break;
      case 1: // Спиннинг
        iconData = Icons.sailing;
        break;
      case 2: // Фидер
        iconData = Icons.add_road;
        break;
      case 3: // Поплавочная
        iconData = Icons.crop_free;
        break;
      case 4: // Зимняя рыбалка
        iconData = Icons.ac_unit;
        break;
      case 5: // Нахлыст
        iconData = Icons.air;
        break;
      case 6: // Троллинг
        iconData = Icons.directions_boat;
        break;
      default: // Другое
        iconData = Icons.category;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Переход к экрану создания заметки с выбранным типом
          AppNavigation.navigateToScreen(
            context,
            AddFishingNoteScreen(fishingType: fishingType),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  iconData,
                  color: AppConstants.textColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  fishingType,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.textColor.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}