// Путь: lib/screens/fishing_diary/fishing_diary_detail_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_diary_model.dart';
import '../../repositories/fishing_diary_repository.dart';
import 'edit_fishing_diary_screen.dart';

class FishingDiaryDetailScreen extends StatefulWidget {
  final FishingDiaryModel entry;

  const FishingDiaryDetailScreen({super.key, required this.entry});

  @override
  State<FishingDiaryDetailScreen> createState() => _FishingDiaryDetailScreenState();
}

class _FishingDiaryDetailScreenState extends State<FishingDiaryDetailScreen> {
  final FishingDiaryRepository _repository = FishingDiaryRepository();
  late FishingDiaryModel _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  Future<void> _toggleFavorite() async {
    try {
      await _repository.toggleFavorite(_currentEntry.id);

      setState(() {
        _currentEntry = _currentEntry.copyWith(isFavorite: !_currentEntry.isFavorite);
      });

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _currentEntry.isFavorite
                    ? localizations.translate('add_to_favorites')
                    : localizations.translate('remove_from_favorites')
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyEntry() async {
    final localizations = AppLocalizations.of(context);

    try {
      await _repository.copyFishingDiaryEntry(_currentEntry.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка копирования: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFishingDiaryScreen(entry: _currentEntry),
      ),
    );

    if (result == true) {
      // Обновляем данные записи
      try {
        final updatedEntry = await _repository.getFishingDiaryEntryById(_currentEntry.id);
        if (updatedEntry != null && mounted) {
          setState(() {
            _currentEntry = updatedEntry;
          });
        }
      } catch (e) {
        // Если не удалось обновить, возвращаемся назад
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('entry_details'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 22),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentEntry.isFavorite ? Icons.star : Icons.star_border,
              color: _currentEntry.isFavorite ? AppConstants.primaryColor : AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _editEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveConstants.spacingL),

              // Карточка с основной информацией
              _buildMainInfoCard(localizations),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Описание записи
              _buildDescriptionCard(localizations),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Информация о записи
              _buildInfoCard(localizations),
              SizedBox(height: ResponsiveConstants.spacingXXL),

              // Кнопки действий
              _buildActionButtons(localizations),
              SizedBox(height: ResponsiveConstants.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: AppConstants.primaryColor,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 32),
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentEntry.title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 24),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentEntry.isFavorite)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppConstants.primaryColor,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 16),
                          ),
                          SizedBox(width: ResponsiveConstants.spacingXS),
                          Text(
                            localizations.translate('favorites'),
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('diary_entry_description'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingM),
          Text(
            _currentEntry.description.isNotEmpty
                ? _currentEntry.description
                : localizations.translate('no_description_provided'),
            style: TextStyle(
              color: _currentEntry.description.isNotEmpty
                  ? AppConstants.textColor
                  : AppConstants.textColor.withOpacity(0.6),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              height: ResponsiveConstants.lineHeightNormal,
              fontStyle: _currentEntry.description.isNotEmpty
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingM),

          _buildInfoRow(
            Icons.date_range,
            'Создана',
            _formatDate(_currentEntry.createdAt),
          ),
          SizedBox(height: ResponsiveConstants.spacingS),

          _buildInfoRow(
            Icons.update,
            'Обновлена',
            _formatDate(_currentEntry.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withOpacity(0.7),
          size: ResponsiveUtils.getIconSize(context, baseSize: 20),
        ),
        SizedBox(width: ResponsiveConstants.spacingS),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Column(
      children: [
        // Кнопка редактирования
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _editEntry,
            icon: Icon(
              Icons.edit,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('edit_diary_entry'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingM),

        // Кнопка копирования
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _copyEntry,
            icon: Icon(
              Icons.copy,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('copy_diary_entry'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
                side: BorderSide(
                  color: AppConstants.textColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}