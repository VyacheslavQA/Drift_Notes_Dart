// Путь: lib/screens/fishing_note/bite_record_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/firebase/firebase_service.dart';

class BiteRecordScreen extends StatefulWidget {
  final BiteRecord? initialRecord; // Параметр для редактирования
  final int dayIndex; // Добавлен параметр для выбранного дня

  const BiteRecordScreen({
    Key? key,
    this.initialRecord,
    this.dayIndex = 0,
  }) : super(key: key);

  @override
  _BiteRecordScreenState createState() => _BiteRecordScreenState();
}

class _BiteRecordScreenState extends State<BiteRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fishTypeController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _notesController;
  final _firebaseService = FirebaseService();

  DateTime _selectedTime = DateTime.now();
  List<File> _selectedPhotos = []; // Для новых фото
  List<String> _existingPhotoUrls = []; // Для существующих фото
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialRecord != null;

    // Инициализация контроллеров
    _fishTypeController = TextEditingController(
        text: _isEditing ? widget.initialRecord!.fishType : '');

    _weightController = TextEditingController(
        text: _isEditing && widget.initialRecord!.weight > 0
            ? widget.initialRecord!.weight.toString()
            : '');

    _lengthController = TextEditingController(
        text: _isEditing && widget.initialRecord!.length > 0
            ? widget.initialRecord!.length.toString()
            : '');

    _notesController = TextEditingController(
        text: _isEditing ? widget.initialRecord!.notes : '');

    // Установка времени
    if (_isEditing) {
      _selectedTime = widget.initialRecord!.time;
      _existingPhotoUrls = List.from(widget.initialRecord!.photoUrls);
    }
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

  // Метод для выбора фото из галереи
  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 70, // Компрессия для оптимизации размера
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // Добавляем новые фото к уже существующим
          _selectedPhotos.addAll(
              pickedFiles.map((xFile) => File(xFile.path)).toList()
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображений: $e')),
      );
    }
  }

  // Сделать фото с камеры
  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedPhotos.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при получении фото: $e')),
      );
    }
  }

  // Удаление фото из списка
  void _removePhoto(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingPhotoUrls.removeAt(index);
      } else {
        _selectedPhotos.removeAt(index);
      }
    });
  }

  // Загрузка выбранных фото в Firebase Storage
  Future<List<String>> _uploadPhotos() async {
    if (_selectedPhotos.isEmpty) return [];

    final List<String> photoUrls = [];

    try {
      setState(() => _isLoading = true);

      for (var photo in _selectedPhotos) {
        final bytes = await photo.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedPhotos.indexOf(photo)}.jpg';
        final userId = _firebaseService.currentUserId;

        if (userId == null) {
          throw Exception('Пользователь не авторизован');
        }

        final path = 'users/$userId/bite_photos/$fileName';
        final url = await _firebaseService.uploadImage(path, bytes);
        photoUrls.add(url);
      }

      return photoUrls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке фото: $e')),
      );
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Сохранение записи о поклёвке
  Future<void> _saveBiteRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      // Загружаем новые фотографии
      final newPhotoUrls = await _uploadPhotos();

      // Объединяем с существующими URL
      final allPhotoUrls = [..._existingPhotoUrls, ...newPhotoUrls];

      final biteRecord = BiteRecord(
        id: _isEditing ? widget.initialRecord!.id : const Uuid().v4(),
        time: _selectedTime,
        fishType: _fishTypeController.text.trim(),
        weight: weight,
        length: length,
        notes: _notesController.text.trim(),
        dayIndex: _isEditing ? widget.initialRecord!.dayIndex : widget.dayIndex,
        spotIndex: _isEditing ? widget.initialRecord!.spotIndex : 0,
        photoUrls: allPhotoUrls,
      );

      Navigator.pop(context, biteRecord);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Подтверждение удаления записи
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Удалить запись?',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить эту поклёвку? Это действие нельзя отменить.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              Navigator.pop(context, 'delete'); // Возвращаем команду удаления
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактирование поклёвки' : 'Новая поклёвка',
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
          // Добавляем кнопку удаления, если редактируем запись
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveBiteRecord,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Сохранение...',
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Информация о выбранном дне (для многодневной рыбалки)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'День рыбалки: ${widget.dayIndex + 1}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Время поклевки
                _buildSectionHeader('Время поклёвки*'),
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

                // Вид рыбы
                _buildSectionHeader('Вид рыбы'),
                TextFormField(
                  controller: _fishTypeController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: 'Укажите вид рыбы (например, "Карп")',
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
                    // Вес рыбы
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Вес (кг)'),
                          TextFormField(
                            controller: _weightController,
                            style: TextStyle(color: AppConstants.textColor),
                            decoration: InputDecoration(
                              fillColor: const Color(0xFF12332E),
                              filled: true,
                              hintText: 'Вес',
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Длина рыбы
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Длина (см)'),
                          TextFormField(
                            controller: _lengthController,
                            style: TextStyle(color: AppConstants.textColor),
                            decoration: InputDecoration(
                              fillColor: const Color(0xFF12332E),
                              filled: true,
                              hintText: 'Длина',
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
                                  return 'Введите корректное число';
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
                _buildSectionHeader('Заметки'),
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: 'Дополнительные заметки (например, используемый прикорм, поведение рыбы)',
                    hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Фотографии
                _buildSectionHeader('Фотографии'),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Из галереи'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: AppConstants.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _pickImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Камера'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: AppConstants.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _takePhoto,
                      ),
                    ),
                  ],
                ),

                // Отображение существующих фото
                if (_existingPhotoUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader('Существующие фото'),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingPhotoUrls.length,
                      itemBuilder: (context, index) {
                        return _buildPhotoItem(_existingPhotoUrls[index], index, true);
                      },
                    ),
                  ),
                ],

                // Отображение новых фото
                if (_selectedPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader('Новые фото'),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return _buildPhotoItem(_selectedPhotos[index].path, index, false);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Кнопка сохранения
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBiteRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'СОХРАНИТЬ ИЗМЕНЕНИЯ' : 'ДОБАВИТЬ ПОКЛЁВКУ',
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

  // Построитель карточки фото
  Widget _buildPhotoItem(String source, int index, bool isExisting) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: isExisting
                  ? NetworkImage(source) as ImageProvider
                  : FileImage(File(source)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 8,
          child: GestureDetector(
            onTap: () => _removePhoto(index, isExisting),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}