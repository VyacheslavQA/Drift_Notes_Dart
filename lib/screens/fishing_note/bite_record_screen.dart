// Путь: lib/screens/fishing_note/bite_record_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';

class BiteRecordScreen extends StatefulWidget {
  const BiteRecordScreen({Key? key}) : super(key: key);

  @override
  _BiteRecordScreenState createState() => _BiteRecordScreenState();
}

class _BiteRecordScreenState extends State<BiteRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fishTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedTime = DateTime.now();

  @override
  void dispose() {
    _fishTypeController.dispose();
    _weightController.dispose();
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

    final biteRecord = BiteRecord(
      id: const Uuid().v4(),
      time: _selectedTime,
      fishType: _fishTypeController.text.trim(),
      weight: weight,
      notes: _notesController.text.trim(),
      dayIndex: 0, // Будет установлено при сохранении заметки
      spotIndex: 0, // Будет установлено при сохранении заметки
    );

    Navigator.pop(context, biteRecord);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Запись о поклевке',
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
              _buildSectionHeader('Время поклевки'),
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
              _buildSectionHeader('Тип рыбы'),
              TextFormField(
                controller: _fishTypeController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: 'Укажите тип рыбы (необязательно)',
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

              // Вес
              _buildSectionHeader('Вес (кг)'),
              TextFormField(
                controller: _weightController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: 'Укажите вес (необязательно)',
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
                      return 'Введите корректное число';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Заметки
              _buildSectionHeader('Заметки'),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: 'Дополнительные заметки (необязательно)',
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
                child: const Text(
                  'СОХРАНИТЬ',
                  style: TextStyle(
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