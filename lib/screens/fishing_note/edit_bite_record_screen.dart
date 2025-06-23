// Путь: lib/screens/fishing_note/edit_bite_record_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../localization/app_localizations.dart';

class EditBiteRecordScreen extends StatefulWidget {
  final BiteRecord biteRecord;

  const EditBiteRecordScreen({super.key, required this.biteRecord});

  @override
  State<EditBiteRecordScreen> createState() => _EditBiteRecordScreenState();
}

class _EditBiteRecordScreenState extends State<EditBiteRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fishTypeController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _notesController;

  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();

    // Инициализация контроллеров из существующей записи
    _fishTypeController = TextEditingController(
      text: widget.biteRecord.fishType,
    );
    _weightController = TextEditingController(
      text:
      widget.biteRecord.weight > 0
          ? widget.biteRecord.weight.toString()
          : '',
    );
    _lengthController = TextEditingController(
      text:
      widget.biteRecord.length > 0
          ? widget.biteRecord.length.toString()
          : '',
    );
    _notesController = TextEditingController(text: widget.biteRecord.notes);

    _selectedTime = widget.biteRecord.time;
  }

  @override
  void dispose() {
    _fishTypeController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.textColor,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppConstants.backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveBiteRecord() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    double weight = 0.0;
    if (_weightController.text.isNotEmpty) {
      // Преобразуем запятую в точку для корректного парсинга
      final weightText = _weightController.text.replaceAll(',', '.');
      weight = double.tryParse(weightText) ?? 0.0;
    }

    double length = 0.0;
    if (_lengthController.text.isNotEmpty) {
      // Преобразуем запятую в точку для корректного парсинга
      final lengthText = _lengthController.text.replaceAll(',', '.');
      length = double.tryParse(lengthText) ?? 0.0;
    }

    final updatedRecord = widget.biteRecord.copyWith(
      time: _selectedTime,
      fishType: _fishTypeController.text.trim(),
      weight: weight,
      length: length,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, updatedRecord);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('edit_bite'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
              Icons.check,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _saveBiteRecord,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              // Время поклевки
              _buildSectionHeader(localizations.translate('bite_time')),
              _buildTimeSelector(context, localizations),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Тип рыбы
              _buildSectionHeader(localizations.translate('fish_type')),
              _buildFishTypeField(localizations),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Вес и длина - адаптивная раскладка
              _buildWeightLengthFields(localizations),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Заметки
              _buildSectionHeader(localizations.translate('additional_notes')),
              _buildNotesField(localizations),
              SizedBox(height: ResponsiveConstants.spacingXL),

              // Кнопка сохранения
              _buildSaveButton(localizations),
            ],
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
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConstants.spacingM,
          horizontal: ResponsiveConstants.spacingM,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child:               Text(
                DateFormat('HH:mm').format(_selectedTime),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFishTypeField(AppLocalizations localizations) {
    return TextFormField(
      controller: _fishTypeController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
      ),
      decoration: InputDecoration(
        fillColor: const Color(0xFF12332E),
        filled: true,
        hintText: localizations.translate('fish_type_hint'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.set_meal,
          color: AppConstants.textColor,
          size: ResponsiveUtils.getIconSize(context),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveConstants.spacingM,
          vertical: ResponsiveConstants.spacingM,
        ),
      ),
    );
  }

  Widget _buildWeightLengthFields(AppLocalizations localizations) {
    return ResponsiveUtils.isSmallScreen(context)
        ? Column( // На маленьких экранах - вертикально
      children: [
        _buildWeightField(localizations),
        SizedBox(height: ResponsiveConstants.spacingM),
        _buildLengthField(localizations),
      ],
    )
        : Row( // На больших экранах - горизонтально
      children: [
        Expanded(child: _buildWeightField(localizations)),
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(child: _buildLengthField(localizations)),
      ],
    );
  }

  Widget _buildWeightField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('weight_kg')),
        TextFormField(
          controller: _weightController,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
          ),
          decoration: InputDecoration(
            fillColor: const Color(0xFF12332E),
            filled: true,
            hintText: localizations.translate('weight'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.5),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
              ),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.scale,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.spacingM,
              vertical: ResponsiveConstants.spacingM,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Проверяем, что введено корректное число
              final weightText = value.replaceAll(',', '.');
              if (double.tryParse(weightText) == null) {
                return localizations.translate('enter_correct_number');
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLengthField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('length_cm')),
        TextFormField(
          controller: _lengthController,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
          ),
          decoration: InputDecoration(
            fillColor: const Color(0xFF12332E),
            filled: true,
            hintText: localizations.translate('length'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.5),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
              ),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.straighten,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.spacingM,
              vertical: ResponsiveConstants.spacingM,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Проверяем, что введено корректное число
              final lengthText = value.replaceAll(',', '.');
              if (double.tryParse(lengthText) == null) {
                return localizations.translate('enter_correct_number');
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(AppLocalizations localizations) {
    return TextFormField(
      controller: _notesController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
      ),
      decoration: InputDecoration(
        fillColor: const Color(0xFF12332E),
        filled: true,
        hintText: localizations.translate('additional_notes_hint'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
      ),
      maxLines: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 3,
        tablet: 4,
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveBiteRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
          padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusXL),
            ),
          ),
        ),
        child: Text(
          localizations.translate('save').toUpperCase(),
          style: TextStyle(
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}