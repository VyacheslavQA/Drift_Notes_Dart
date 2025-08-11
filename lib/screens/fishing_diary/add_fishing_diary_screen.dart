// Путь: lib/screens/fishing_diary/add_fishing_diary_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_diary_model.dart';
import '../../repositories/fishing_diary_repository.dart';

class AddFishingDiaryScreen extends StatefulWidget {
  const AddFishingDiaryScreen({super.key});

  @override
  State<AddFishingDiaryScreen> createState() => _AddFishingDiaryScreenState();
}

class _AddFishingDiaryScreenState extends State<AddFishingDiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FishingDiaryRepository _repository = FishingDiaryRepository();

  bool _isFavorite = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveEntry() async {
    final localizations = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final entry = FishingDiaryModel(
        id: '',
        userId: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isFavorite: _isFavorite,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.addFishingDiaryEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );

        _hasUnsavedChanges = false;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: localizations.translate('retry'),
              textColor: Colors.white,
              onPressed: _saveEntry,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final localizations = AppLocalizations.of(context);

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Text(
            localizations.translate('cancel_creation'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('cancel_creation_confirmation'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations.translate('no'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations.translate('yes_cancel'),
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.translate('new_diary_entry'),
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
            onPressed: () async {
              final shouldExit = await _onWillPop();
              if (shouldExit && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (!_isSaving)
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: AppConstants.textColor,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                onPressed: _saveEntry,
              )
            else
              Padding(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                child: SizedBox(
                  width: ResponsiveConstants.minTouchTarget,
                  height: ResponsiveConstants.minTouchTarget,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                SizedBox(height: ResponsiveConstants.spacingL),

                // Название записи
                _buildSectionHeader('${localizations.translate('diary_entry_title')}*'),
                _buildTitleField(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Описание записи
                _buildSectionHeader('${localizations.translate('diary_entry_description')}*'),
                _buildDescriptionField(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Избранное
                _buildFavoriteCheckbox(localizations),
                SizedBox(height: ResponsiveConstants.spacingXXL),

                // Кнопки
                _buildBottomButtons(localizations),
                SizedBox(height: ResponsiveConstants.spacingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingS),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTitleField(AppLocalizations localizations) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
      ),
      decoration: InputDecoration(
        fillColor: AppConstants.surfaceColor,
        filled: true,
        hintText: localizations.translate('diary_entry_title'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withOpacity(0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.book_outlined,
          color: AppConstants.textColor,
          size: ResponsiveUtils.getIconSize(context),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveConstants.spacingM,
          vertical: ResponsiveConstants.spacingM,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return localizations.translate('diary_entry_title');
        }
        return null;
      },
      maxLength: 100,
    );
  }

  Widget _buildDescriptionField(AppLocalizations localizations) {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
      ),
      decoration: InputDecoration(
        fillColor: AppConstants.surfaceColor,
        filled: true,
        hintText: localizations.translate('diary_entry_description'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withOpacity(0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
        alignLabelWithHint: true,
      ),
      maxLines: 8,
      maxLength: 10000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return localizations.translate('diary_entry_description');
        }
        return null;
      },
    );
  }

  Widget _buildFavoriteCheckbox(AppLocalizations localizations) {
    return InkWell(
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        _markAsChanged();
      },
      borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      child: Container(
        padding: EdgeInsets.all(ResponsiveConstants.spacingM),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingS),
              decoration: BoxDecoration(
                color: (_isFavorite ? AppConstants.primaryColor : AppConstants.textColor)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
              ),
              child: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? AppConstants.primaryColor : AppConstants.textColor,
                size: ResponsiveUtils.getIconSize(context, baseSize: 24),
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: Text(
                localizations.translate('add_to_favorites'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: _isFavorite,
              onChanged: (value) {
                setState(() {
                  _isFavorite = value;
                });
                _markAsChanged();
              },
              activeColor: AppConstants.primaryColor,
              activeTrackColor: AppConstants.primaryColor.withOpacity(0.3),
              inactiveThumbColor: AppConstants.textColor.withOpacity(0.5),
              inactiveTrackColor: AppConstants.textColor.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(AppLocalizations localizations) {
    return ResponsiveUtils.isSmallScreen(context)
        ? Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final shouldExit = await _onWillPop();
              if (shouldExit && mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
            ),
            child: Text(
              localizations.translate('cancel').toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
              disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.5),
            ),
            child: _isSaving
                ? SizedBox(
              width: ResponsiveUtils.getIconSize(context, baseSize: 24),
              height: ResponsiveUtils.getIconSize(context, baseSize: 24),
              child: CircularProgressIndicator(
                color: AppConstants.textColor,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              localizations.translate('save').toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    )
        : Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final shouldExit = await _onWillPop();
              if (shouldExit && mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
            ),
            child: Text(
              localizations.translate('cancel').toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
              disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.5),
            ),
            child: _isSaving
                ? SizedBox(
              width: ResponsiveUtils.getIconSize(context, baseSize: 24),
              height: ResponsiveUtils.getIconSize(context, baseSize: 24),
              child: CircularProgressIndicator(
                color: AppConstants.textColor,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              localizations.translate('save').toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}