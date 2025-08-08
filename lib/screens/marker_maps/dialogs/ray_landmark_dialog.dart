import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_localizations.dart';
import '../helpers/ray_landmarks_helper.dart';

class RayLandmarkDialog extends StatefulWidget {
  final int rayIndex;
  final Map<String, dynamic>? existingLandmark;

  const RayLandmarkDialog({
    super.key,
    required this.rayIndex,
    this.existingLandmark,
  });

  @override
  State<RayLandmarkDialog> createState() => _RayLandmarkDialogState();
}

class _RayLandmarkDialogState extends State<RayLandmarkDialog> {
  late TextEditingController _commentController;
  String? _selectedIconType;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.existingLandmark?['comment'] ?? '',
    );
    _selectedIconType = widget.existingLandmark?['iconType'];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isEditing = widget.existingLandmark != null;

    return Dialog(
      backgroundColor: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📋 ЗАГОЛОВОК
            _buildHeader(localizations, isEditing),

            // 📄 СОДЕРЖИМОЕ
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 ВЫБОР ИКОНКИ
                    _buildIconSelection(localizations),
                    const SizedBox(height: 20),

                    // 💬 ПОЛЕ КОММЕНТАРИЯ
                    _buildCommentField(localizations),
                  ],
                ),
              ),
            ),

            // 🔘 КНОПКИ
            _buildButtons(localizations, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add_location,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing
                  ? localizations.translate('edit_landmark')
                  : localizations.translate('add_landmark'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Номер луча
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.rayIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('select_landmark_type'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Сетка иконок
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RayLandmarksHelper.getAllIconTypes().map((iconType) {
            final isSelected = _selectedIconType == iconType;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIconType = iconType;
                });
              },
              child: Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withOpacity(0.2)
                      : AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      RayLandmarksHelper.getLandmarkIcon(iconType),
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textColor,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RayLandmarksHelper.getLandmarkName(iconType, localizations),
                      style: TextStyle(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.textColor,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('comment_optional'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          style: TextStyle(color: AppConstants.textColor),
          decoration: InputDecoration(
            hintText: localizations.translate('landmark_comment'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppConstants.primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }

  // 🚀 ИСПРАВЛЕННЫЙ метод _buildButtons без overflow
  Widget _buildButtons(AppLocalizations localizations, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppConstants.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: isEditing
          ? _buildEditingButtons(localizations)
          : _buildAddingButtons(localizations),
    );
  }

  // 🚀 НОВЫЙ метод для кнопок добавления (без кнопки удаления)
  Widget _buildAddingButtons(AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _selectedIconType != null ? () {
              Navigator.pop(context, {
                'action': 'save',
                'iconType': _selectedIconType!,
                'comment': _commentController.text.trim(),
              });
            } : null,
            child: Text(
              localizations.translate('save'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // 🚀 НОВЫЙ метод для кнопок редактирования (с кнопкой удаления)
  Widget _buildEditingButtons(AppLocalizations localizations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Первая строка: кнопка удаления
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context, {'action': 'delete'}),
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            label: Text(
              localizations.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Вторая строка: кнопки отмены и сохранения
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localizations.translate('cancel'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectedIconType != null ? () {
                  Navigator.pop(context, {
                    'action': 'save',
                    'iconType': _selectedIconType!,
                    'comment': _commentController.text.trim(),
                  });
                } : null,
                child: Text(
                  localizations.translate('save'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}