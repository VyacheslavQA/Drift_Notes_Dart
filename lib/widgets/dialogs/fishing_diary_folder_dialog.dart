import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_diary_folder_model.dart';

class FishingDiaryFolderDialog extends StatefulWidget {
  final FishingDiaryFolderModel? folder; // null = создание новой папки
  final Function(FishingDiaryFolderModel) onSave;

  const FishingDiaryFolderDialog({
    super.key,
    this.folder,
    required this.onSave,
  });

  @override
  State<FishingDiaryFolderDialog> createState() => _FishingDiaryFolderDialogState();
}

class _FishingDiaryFolderDialogState extends State<FishingDiaryFolderDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String _selectedColor = '#4CAF50'; // Зеленый по умолчанию
  bool _isLoading = false;

  // Предустановленные цвета для папок
  final List<String> _folderColors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336',
    '#00BCD4', '#8BC34A', '#FF5722', '#607D8B', '#795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _descriptionController = TextEditingController(text: widget.folder?.description ?? '');
    _selectedColor = widget.folder?.colorHex ?? '#4CAF50';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.folder != null;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // 🔥 РАДИКАЛЬНОЕ ИСПРАВЛЕНИЕ: Полная изоляция от системы
    return PopScope(
      canPop: true,
      child: Scaffold(
        // 🔥 КРИТИЧЕСКОЕ: Отключаем реакцию на клавиатуру
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black54, // Полупрозрачный фон
        body: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.all(24.0),
              width: double.maxFinite,
              height: 520, // Жестко фиксированная высота
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
              ),
              child: Column(
                children: [
                  // 🔥 ЗАГОЛОВОК (фиксированная высота)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppConstants.textColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder,
                            color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isEditing ? 'Редактировать папку' : 'Создать папку',
                            style: const TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(
                              Icons.close,
                              color: AppConstants.textColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔥 КОНТЕНТ (расширяемая область)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Поле названия
                          const Text(
                            'Название папки',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(color: AppConstants.textColor, fontSize: 16),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Введите название...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF7A7A7A),
                                  fontSize: 16,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                counterText: '',
                              ),
                              maxLength: 50,
                              inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Поле описания
                          const Text(
                            'Описание (необязательно)',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _descriptionController,
                              style: const TextStyle(color: AppConstants.textColor, fontSize: 16),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Добавьте описание...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF7A7A7A),
                                  fontSize: 16,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                counterText: '',
                              ),
                              maxLines: 2,
                              maxLength: 200,
                              inputFormatters: [LengthLimitingTextInputFormatter(200)],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Выбор цвета
                          const Text(
                            'Цвет папки',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 🔥 ФИКСИРОВАННАЯ ОБЛАСТЬ ДЛЯ ЦВЕТОВ
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _folderColors.map((color) {
                                  final isSelected = _selectedColor == color;
                                  return GestureDetector(
                                    onTap: () {
                                      if (!isSelected) {
                                        setState(() => _selectedColor = color);
                                      }
                                    },
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? AppConstants.textColor : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔥 КНОПКИ (фиксированная высота)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppConstants.textColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppConstants.textColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Отмена',
                                style: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _handleSave,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Text(
                                _isEditing ? 'Сохранить' : 'Создать',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final localizations = AppLocalizations.of(context);

    // Валидация
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Название папки обязательно'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final folderData = FishingDiaryFolderModel(
        id: widget.folder?.id ?? '',
        userId: widget.folder?.userId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        colorHex: _selectedColor,
        sortOrder: widget.folder?.sortOrder ?? 0,
        createdAt: widget.folder?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(folderData);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}