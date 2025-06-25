// Путь: lib/screens/fishing_note/fishing_type_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import 'add_fishing_note_screen.dart';

class FishingTypeSelectionScreen extends StatefulWidget {
  const FishingTypeSelectionScreen({super.key});

  @override
  State<FishingTypeSelectionScreen> createState() =>
      _FishingTypeSelectionScreenState();
}

class _FishingTypeSelectionScreenState
    extends State<FishingTypeSelectionScreen> {
  String _selectedFishingType = AppConstants.fishingTypes.first;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dialogShown) {
        _dialogShown = true;
        _showFishingTypeDialog();
      }
    });
  }

  void _continueToNoteCreation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFishingNoteScreen(fishingType: _selectedFishingType),
      ),
    );

    if (mounted) {
      if (result == true) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _cancelAndClose() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  void _showFishingTypeDialog() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            _cancelAndClose();
            return false;
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F1D),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20), // Еще меньше padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка - уменьшаем размер
                  Container(
                    width: isSmallScreen ? 50 : 60, // Уменьшили
                    height: isSmallScreen ? 50 : 60,
                    padding: const EdgeInsets.all(6), // Уменьшили padding
                    decoration: const BoxDecoration(
                      color: Color(0xFF12332E),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      color: AppConstants.textColor,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16), // Уменьшили отступы

                  // Заголовок - еще меньше
                  Text(
                    localizations.translate('select_fishing_type'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isSmallScreen ? 18 : 22, // Еще меньше
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Dropdown - делаем компактнее
                  Container(
                    constraints: BoxConstraints(minHeight: 44), // Чуть меньше
                    decoration: BoxDecoration(
                      color: const Color(0xFF12332E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // Меньше padding
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFishingType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF12332E),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppConstants.textColor,
                              size: 20, // Уменьшили иконку
                            ),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16, // Уменьшили шрифт
                            ),
                            items: AppConstants.fishingTypes.map((String typeKey) {
                              return DropdownMenuItem<String>(
                                value: typeKey,
                                child: Row(
                                  children: [
                                    FishingTypeIcons.getIconWidget(
                                      typeKey,
                                      size: isSmallScreen ? 28 : 32, // Уменьшили иконки
                                    ),
                                    const SizedBox(width: 10), // Меньше отступ
                                    Expanded(
                                      child: Text(
                                        localizations.translate(typeKey),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFishingType = newValue;
                                });
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
                  SizedBox(height: isSmallScreen ? 12 : 16), // Уменьшили отступ перед кнопками

                  // Кнопки - ВСЕГДА в два ряда для экономии места
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Первый ряд - главная кнопка Continue
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _continueToNoteCreation();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, // Убираем дефолтный padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            localizations.translate('continue'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8), // Маленький отступ между рядами
                      // Второй ряд - кнопка Cancel
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _cancelAndClose();
                          },
                          child: Text(
                            localizations.translate('cancel'),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
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

    return WillPopScope(
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
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppConstants.textColor,
            ),
            onPressed: _cancelAndClose,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
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
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
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