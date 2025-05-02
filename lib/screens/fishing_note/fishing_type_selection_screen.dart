// Путь: lib/screens/fishing_note/fishing_type_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'add_fishing_note_screen.dart';

class FishingTypeSelectionScreen extends StatefulWidget {
  const FishingTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  _FishingTypeSelectionScreenState createState() => _FishingTypeSelectionScreenState();
}

class _FishingTypeSelectionScreenState extends State<FishingTypeSelectionScreen> {
  String _selectedFishingType = AppConstants.fishingTypes.first;

  @override
  void initState() {
    super.initState();

    // Сразу показываем выпадающий список при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFishingTypeDialog();
    });
  }

  void _continueToNoteCreation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddFishingNoteScreen(fishingType: _selectedFishingType),
      ),
    );
  }

  // Получение иконки для типа рыбалки
  IconData _getFishingTypeIcon(String type) {
    switch (type) {
      case 'Карповая рыбалка':
        return Icons.waves;
      case 'Спиннинг':
        return Icons.sailing;
      case 'Фидер':
        return Icons.add_road;
      case 'Поплавочная':
        return Icons.crop_free;
      case 'Зимняя рыбалка':
        return Icons.ac_unit;
      case 'Нахлыст':
        return Icons.air;
      case 'Троллинг':
        return Icons.directions_boat;
      default:
        return Icons.category;
    }
  }

  // Метод для отображения выпадающего списка типов рыбалки как на скриншоте
  void _showFishingTypeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по нажатию вне диалога
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Прозрачный фон
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 40), // Отступы по бокам
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F1D), // Цвет как на скриншоте
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка рыбы сверху (как на скриншоте)
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12332E),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    color: AppConstants.textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Заголовок
                Text(
                  'Выберите тип\nрыбалки',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Выпадающий список
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF12332E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFishingType,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF12332E),
                          icon: Icon(Icons.arrow_drop_down, color: AppConstants.textColor),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                          ),
                          items: AppConstants.fishingTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getFishingTypeIcon(type),
                                    color: AppConstants.textColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFishingType = newValue;
                              });

                              // Обновляем состояние родительского виджета
                              this.setState(() {
                                _selectedFishingType = newValue;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Кнопки внизу
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка "Отмена"
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Закрываем диалог
                        Navigator.pop(context); // Возвращаемся на предыдущий экран
                      },
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Кнопка "Продолжить"
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green, // Зеленая кнопка как на скриншоте
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Закрываем диалог
                          _continueToNoteCreation(); // Переходим к заполнению заметки
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Продолжить',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Новая заметка',
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
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Выбор типа рыбалки...',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
