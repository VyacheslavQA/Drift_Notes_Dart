// File: lib/widgets/dialogs/move_entry_dialog.dart (New file)

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_diary_folder_model.dart';
import '../../models/fishing_diary_model.dart';

class MoveEntryDialog extends StatefulWidget {
  final List<FishingDiaryModel> entries; // Записи для перемещения
  final List<FishingDiaryFolderModel> availableFolders;
  final Function(String? targetFolderId) onMove;

  const MoveEntryDialog({
    super.key,
    required this.entries,
    required this.availableFolders,
    required this.onMove,
  });

  @override
  State<MoveEntryDialog> createState() => _MoveEntryDialogState();
}

class _MoveEntryDialogState extends State<MoveEntryDialog> {
  String? _selectedFolderId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isMultipleEntries = widget.entries.length > 1;

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusL),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
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
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                  ),
                  child: Icon(
                    Icons.drive_file_move,
                    color: AppConstants.primaryColor,
                    size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: Text(
                    isMultipleEntries
                        ? localizations.translate('move_entries')
                        : localizations.translate('move_entry'),
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

            // Информация о перемещаемых записях
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMultipleEntries
                        ? localizations.translate('selected_entries_count')
                        .replaceAll('{count}', widget.entries.length.toString())
                        : localizations.translate('selected_entry'),
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.8),
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isMultipleEntries) ...[
                    SizedBox(height: ResponsiveConstants.spacingXS),
                    Text(
                      widget.entries.first.title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: ResponsiveConstants.spacingL),

            // Выбор целевой папки
            Text(
              localizations.translate('select_target_folder'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: ResponsiveConstants.spacingM),

            // Список доступных папок
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Опция "Без папки"
                    _buildFolderOption(
                      context: context,
                      localizations: localizations,
                      folderId: null,
                      name: localizations.translate('no_folder'),
                      icon: Icons.folder_open_outlined,
                      color: AppConstants.textColor.withOpacity(0.6),
                      isSelected: _selectedFolderId == null,
                    ),

                    if (widget.availableFolders.isNotEmpty)
                      Divider(
                        color: AppConstants.textColor.withOpacity(0.2),
                        height: ResponsiveConstants.spacingL,
                      ),

                    // Список папок
                    ...widget.availableFolders.map((folder) => _buildFolderOption(
                      context: context,
                      localizations: localizations,
                      folderId: folder.id,
                      name: folder.name,
                      description: folder.description,
                      icon: Icons.folder,
                      color: Color(int.parse(folder.colorHex.replaceFirst('#', '0xFF'))),
                      isSelected: _selectedFolderId == folder.id,
                    )).toList(),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveConstants.spacingL),

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
                    onPressed: _isLoading ? null : _handleMove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
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
                      localizations.translate('move'),
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

  Widget _buildFolderOption({
    required BuildContext context,
    required AppLocalizations localizations,
    required String? folderId,
    required String name,
    String? description,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingS),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.1)
            : AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        border: isSelected
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : Border.all(color: AppConstants.textColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedFolderId = folderId),
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
          child: Row(
            children: [
              // Иконка папки
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingM),

              // Информация о папке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Индикатор выбора
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: AppConstants.textColor.withOpacity(0.3),
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMove() async {
    setState(() => _isLoading = true);

    try {
      widget.onMove(_selectedFolderId);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Вспомогательный класс для группового перемещения
class BulkMoveHelper {
  static Future<void> showMoveDialog({
    required BuildContext context,
    required List<FishingDiaryModel> entries,
    required List<FishingDiaryFolderModel> availableFolders,
    required Function(String? targetFolderId) onMove,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => MoveEntryDialog(
        entries: entries,
        availableFolders: availableFolders,
        onMove: onMove,
      ),
    );
  }

  static String getMoveConfirmationMessage({
    required AppLocalizations localizations,
    required int entriesCount,
    required String? targetFolderName,
  }) {
    final entriesText = entriesCount == 1
        ? localizations.translate('one_entry')
        : localizations.translate('entries_count').replaceAll('{count}', entriesCount.toString());

    final targetText = targetFolderName == null
        ? localizations.translate('no_folder')
        : targetFolderName;

    return localizations.translate('move_confirmation')
        .replaceAll('{entries}', entriesText)
        .replaceAll('{folder}', targetText);
  }
}