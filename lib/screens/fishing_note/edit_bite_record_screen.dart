// Путь: lib/screens/fishing_note/edit_bite_record_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../localization/app_localizations.dart';

class EditBiteRecordScreen extends StatefulWidget {
  final BiteRecord biteRecord;

  const EditBiteRecordScreen({
    Key? key,
    required this.biteRecord,
  }) : super(key: key);

  @override
  _EditBiteRecordScreenState createState() => _EditBiteRecordScreenState();
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
    _fishTypeController = TextEditingController(text: widget.biteRecord.fishType);
    _weightController = TextEditingController(
        text: widget.biteRecord.weight > 0 ? widget.biteRecord.weight.toString() : ''
    );
    _lengthController = TextEditingController(
        text: widget.biteRecord.length > 0 ? widget.biteRecord.length.toString() : ''
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
            dialogBackgroundColor: AppConstants.backgroundColor,
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

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('edit_bite'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveBiteRecord,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Время поклевки
              _buildSectionHeader(localizations.translate('bite_time')),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12332E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppConstants.textColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('HH:mm').format(_selectedTime),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppConstants.textColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Тип рыбы
              _buildSectionHeader(localizations.translate('fish_type')),
              TextFormField(
                controller: _fishTypeController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: localizations.translate('fish_type_hint'),
                  hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.set_meal,
                    color: AppConstants.textColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Ряд для веса и длины (два поля в одной строке)
              Row(
                children: [
                  // Вес
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(localizations.translate('weight_kg')),
                        TextFormField(
                          controller: _weightController,
                          style: TextStyle(color: AppConstants.textColor),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFF12332E),
                            filled: true,
                            hintText: localizations.translate('weight'),
                            hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.scale,
                              color: AppConstants.textColor,
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Длина
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(localizations.translate('length_cm')),
                        TextFormField(
                          controller: _lengthController,
                          style: TextStyle(color: AppConstants.textColor),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFF12332E),
                            filled: true,
                            hintText: localizations.translate('length'),
                            hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.straighten,
                              color: AppConstants.textColor,
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
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Заметки
              _buildSectionHeader(localizations.translate('additional_notes')),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: localizations.translate('additional_notes_hint'),
                  hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveBiteRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  localizations.translate('save').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}