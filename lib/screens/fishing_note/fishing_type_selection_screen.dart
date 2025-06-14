// Путь: lib/screens/fishing_note/fishing_type_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import 'add_fishing_note_screen.dart';

class FishingTypeSelectionScreen extends StatefulWidget {
  const FishingTypeSelectionScreen({super.key});

  @override
  State<FishingTypeSelectionScreen> createState() => _FishingTypeSelectionScreenState();
}

class _FishingTypeSelectionScreenState extends State<FishingTypeSelectionScreen> {
  String _selectedFishingType = AppConstants.fishingTypes.first;
  bool _dialogShown = false; // ДОБАВЛЕНО: флаг для предотвращения повторного показа диалога

  @override
  void initState() {
    super.initState();

    // Сразу показываем выпадающий список при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dialogShown) {
        _dialogShown = true;
        _showFishingTypeDialog();
      }
    });
  }

  // ИСПРАВЛЕНО: метод теперь правильно обрабатывает результат
  void _continueToNoteCreation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFishingNoteScreen(fishingType: _selectedFishingType),
      ),
    );

    // ИСПРАВЛЕНО: передаем результат дальше только если заметка была создана
    if (mounted) {
      if (result == true) {
        // Заметка была успешно создана
        Navigator.pop(context, true);
      } else {
        // Пользователь отменил создание заметки - просто закрываем этот экран без результата
        Navigator.pop(context);
      }
    }
  }

  // ИСПРАВЛЕНО: метод для безопасного закрытия без результата
  void _cancelAndClose() {
    if (mounted) {
      Navigator.pop(context); // Закрываем БЕЗ возврата результата
    }
  }

  // ДОБАВЛЕНО: обработчик системной кнопки "назад"
  Future<bool> _onWillPop() async {
    // При нажатии системной кнопки "назад" просто закрываем без результата
    return true;
  }

  // Метод для отображения выпадающего списка типов рыбалки как на скриншоте
  void _showFishingTypeDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по нажатию вне диалога
      builder: (BuildContext context) {
        return WillPopScope( // ДОБАВЛЕНО: обработка системной кнопки "назад"
          onWillPop: () async {
            // При нажатии системной кнопки "назад" в диалоге - закрываем весь экран
            Navigator.pop(context); // Закрываем диалог
            _cancelAndClose(); // Закрываем экран без результата
            return false; // Предотвращаем стандартное поведение
          },
          child: Dialog(
            backgroundColor: Colors.transparent, // Прозрачный фон
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40), // Отступы по бокам
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF12332E),
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
                    localizations.translate('select_fishing_type'),
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
                            items: AppConstants.fishingTypes.map((String typeKey) {
                              return DropdownMenuItem<String>(
                                value: typeKey,
                                child: Row(
                                  children: [
                                    // Используем FishingTypeIcons.getIconWidget для ключа
                                    FishingTypeIcons.getIconWidget(typeKey, size: 36.0),
                                    const SizedBox(width: 12),
                                    // Переводим ключ в локализованный текст
                                    Text(localizations.translate(typeKey)),
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
                          _cancelAndClose(); // ИСПРАВЛЕНО: закрываем без результата
                        },
                        child: Text(
                          localizations.translate('cancel'),
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
                              localizations.translate('continue'),
                              style: const TextStyle(
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return WillPopScope( // ДОБАВЛЕНО: обработка системной кнопки "назад"
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.translate('new_note'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
            onPressed: _cancelAndClose, // ИСПРАВЛЕНО: используем безопасное закрытие
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
                    localizations.translate('loading'),
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
      ),
    );
  }
}