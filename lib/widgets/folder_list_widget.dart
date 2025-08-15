// File: lib/widgets/folder_list_widget.dart (New file)

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_utils.dart';
import '../localization/app_localizations.dart';
import '../models/fishing_diary_folder_model.dart';
import '../models/fishing_diary_model.dart';

class FolderListWidget extends StatelessWidget {
  final List<FishingDiaryFolderModel> folders;
  final List<FishingDiaryModel> entriesWithoutFolder;
  final String? selectedFolderId;
  final Function(String? folderId)? onFolderTap;
  final Function(FishingDiaryFolderModel folder)? onFolderEdit;
  final Function(FishingDiaryFolderModel folder)? onFolderDelete;
  final Function(FishingDiaryFolderModel folder)? onFolderOptions;
  final bool showEntriesCount;
  final bool isExpanded;

  const FolderListWidget({
    super.key,
    required this.folders,
    required this.entriesWithoutFolder,
    this.selectedFolderId,
    this.onFolderTap,
    this.onFolderEdit,
    this.onFolderDelete,
    this.onFolderOptions,
    this.showEntriesCount = true,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Записи без папки
        if (entriesWithoutFolder.isNotEmpty)
          _buildFolderItem(
            context: context,
            localizations: localizations,
            icon: Icons.folder_open_outlined,
            name: localizations.translate('entries_without_folder'),
            description: null,
            color: AppConstants.textColor.withOpacity(0.6),
            entriesCount: entriesWithoutFolder.length,
            isSelected: selectedFolderId == null,
            folderId: null,
            isWithoutFolder: true,
          ),

        // Разделитель если есть записи без папки
        if (entriesWithoutFolder.isNotEmpty && folders.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveConstants.spacingS,
              horizontal: ResponsiveUtils.getHorizontalPadding(context),
            ),
            child: Divider(color: AppConstants.textColor.withOpacity(0.2)),
          ),

        // Список папок
        ...folders.map((folder) => _buildFolderItem(
          context: context,
          localizations: localizations,
          icon: Icons.folder,
          name: folder.name,
          description: folder.description,
          color: Color(int.parse(folder.colorHex.replaceFirst('#', '0xFF'))),
          entriesCount: _getEntriesCountInFolder(folder.id),
          isSelected: selectedFolderId == folder.id,
          folderId: folder.id,
          folder: folder,
        )).toList(),

        // Сообщение если нет папок
        if (folders.isEmpty && entriesWithoutFolder.isEmpty)
          _buildEmptyState(context, localizations),
      ],
    );
  }

  Widget _buildFolderItem({
    required BuildContext context,
    required AppLocalizations localizations,
    required IconData icon,
    required String name,
    String? description,
    required Color color,
    required int entriesCount,
    required bool isSelected,
    required String? folderId,
    FishingDiaryFolderModel? folder,
    bool isWithoutFolder = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.1)
            : AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        border: isSelected
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => onFolderTap?.call(folderId),
        onLongPress: !isWithoutFolder && folder != null
            ? () => onFolderOptions?.call(folder)
            : null,
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
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingM),

              // Информация о папке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название папки
                    Text(
                      name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Описание папки (если есть)
                    if (description != null && description.isNotEmpty) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Количество записей
                    if (showEntriesCount) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        _getEntriesCountText(localizations, entriesCount),
                        style: TextStyle(
                          color: color,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Количество записей как бейдж
              if (showEntriesCount && entriesCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveConstants.spacingS,
                    vertical: ResponsiveConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                  ),
                  child: Text(
                    entriesCount.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Кнопка опций (только для обычных папок)
              if (!isWithoutFolder && folder != null) ...[
                SizedBox(width: ResponsiveConstants.spacingS),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  onPressed: () => onFolderOptions?.call(folder),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        children: [
          SizedBox(height: ResponsiveConstants.spacingXL),
          Container(
            padding: EdgeInsets.all(ResponsiveConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_outlined,
              size: ResponsiveUtils.getIconSize(context, baseSize: 48),
              color: AppConstants.primaryColor,
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingL),
          Text(
            localizations.translate('no_folders_created'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          Text(
            localizations.translate('create_folder_description'),
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConstants.spacingXL),
        ],
      ),
    );
  }

  int _getEntriesCountInFolder(String folderId) {
    // Этот метод будет переопределен в родительском виджете
    // или передан через callback
    return 0;
  }

  String _getEntriesCountText(AppLocalizations localizations, int count) {
    if (count == 0) {
      return localizations.translate('no_entries');
    } else if (count == 1) {
      return localizations.translate('one_entry');
    } else {
      return localizations.translate('entries_count').replaceAll('{count}', count.toString());
    }
  }
}

// Расширенный виджет списка папок с подсчетом записей
class FolderListWithCountsWidget extends StatelessWidget {
  final List<FishingDiaryFolderModel> folders;
  final List<FishingDiaryModel> allEntries;
  final String? selectedFolderId;
  final Function(String? folderId)? onFolderTap;
  final Function(FishingDiaryFolderModel folder)? onFolderEdit;
  final Function(FishingDiaryFolderModel folder)? onFolderDelete;
  final Function(FishingDiaryFolderModel folder)? onFolderOptions;
  final bool showEntriesCount;

  const FolderListWithCountsWidget({
    super.key,
    required this.folders,
    required this.allEntries,
    this.selectedFolderId,
    this.onFolderTap,
    this.onFolderEdit,
    this.onFolderDelete,
    this.onFolderOptions,
    this.showEntriesCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final entriesWithoutFolder = allEntries
        .where((entry) => entry.folderId == null)
        .toList();

    return FolderListWidget(
      folders: folders,
      entriesWithoutFolder: entriesWithoutFolder,
      selectedFolderId: selectedFolderId,
      onFolderTap: onFolderTap,
      onFolderEdit: onFolderEdit,
      onFolderDelete: onFolderDelete,
      onFolderOptions: onFolderOptions,
      showEntriesCount: showEntriesCount,
    );
  }

  int _getEntriesCountInFolder(String folderId) {
    return allEntries.where((entry) => entry.folderId == folderId).length;
  }
}