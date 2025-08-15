// File: lib/widgets/dialogs/fishing_diary_folder_dialog.dart (New file)

import 'package:flutter/material.dart';
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
    '#4CAF50', // Зеленый
    '#2196F3', // Синий
    '#FF9800', // Оранжевый
    '#9C27B0', // Фиолетовый
    '#F44336', // Красный
    '#00BCD4', // Бирюзовый
    '#8BC34A', // Светло-зеленый
    '#FF5722', // Темно-оранжевый
    '#607D8B', // Сине-серый
    '#795548', // Коричневый
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

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                    size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: Text(
                    _isEditing
                        ? localizations.translate('edit_folder')
                        : localizations.translate('create_folder'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppConstants.textColor,
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: ResponsiveConstants.spacingL),

            // Поле названия
            Text(
              localizations.translate('folder_name'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            TextField(
              controller: _nameController,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
              ),
              decoration: InputDecoration(
                fillColor: AppConstants.backgroundColor,
                filled: true,
                hintText: localizations.translate('folder_name_hint'),
                hintStyle: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.5),
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConstants.spacingM,
                  vertical: ResponsiveConstants.spacingM,
                ),
              ),
              maxLength: 50,
            ),

            SizedBox(height: ResponsiveConstants.spacingM),

            // Поле описания (опционально)
            Text(
              localizations.translate('folder_description'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            TextField(
              controller: _descriptionController,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
              ),
              decoration: InputDecoration(
                fillColor: AppConstants.backgroundColor,
                filled: true,
                hintText: localizations.translate('folder_description_hint'),
                hintStyle: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.5),
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConstants.spacingM,
                  vertical: ResponsiveConstants.spacingM,
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            SizedBox(height: ResponsiveConstants.spacingM),

            // Выбор цвета
            Text(
              localizations.translate('folder_color'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            Wrap(
              spacing: ResponsiveConstants.spacingS,
              runSpacing: ResponsiveConstants.spacingS,
              children: _folderColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                      border: Border.all(
                        color: isSelected ? AppConstants.textColor : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                    )
                        : null,
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: ResponsiveConstants.spacingXL),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                      ),
                    ),
                    child: Text(
                      localizations.translate('cancel'),
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      _isEditing
                          ? localizations.translate('save_changes')
                          : localizations.translate('create_folder'),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        fontWeight: FontWeight.w600,
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
  }

  Future<void> _handleSave() async {
    final localizations = AppLocalizations.of(context);

    // Валидация
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('folder_name_required')),
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
          content: Text('${localizations.translate('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}