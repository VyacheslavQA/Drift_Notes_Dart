// Путь: lib/screens/fishing_note/bite_record_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/firebase/firebase_service.dart';
import '../../localization/app_localizations.dart';

class BiteRecordScreen extends StatefulWidget {
  final BiteRecord? initialRecord; // Параметр для редактирования
  final int dayIndex; // Добавлен параметр для выбранного дня
  final DateTime? fishingStartDate; // Дата начала рыбалки
  final DateTime?
  fishingEndDate; // Дата окончания рыбалки (может быть null для однодневной)
  final bool isMultiDay; // Флаг многодневной рыбалки

  const BiteRecordScreen({
    super.key,
    this.initialRecord,
    this.dayIndex = 0,
    this.fishingStartDate,
    this.fishingEndDate,
    this.isMultiDay = false,
  });

  @override
  State<BiteRecordScreen> createState() => _BiteRecordScreenState();
}

class _BiteRecordScreenState extends State<BiteRecordScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fishTypeController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _notesController;
  final _firebaseService = FirebaseService();

  DateTime _selectedTime = DateTime.now();
  final List<File> _selectedPhotos = []; // Для новых фото
  final List<String> _existingPhotoUrls = []; // Для существующих фото
  bool _isLoading = false;
  bool _isEditing = false;

  // Новые переменные для автоматического переключения дней
  late int _selectedDayIndex;
  final List<DateTime> _fishingDays = [];
  int _totalFishingDays = 1;

  // Переменная для отслеживания последней проверенной даты
  DateTime? _lastCheckedDate;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialRecord != null;

    // Добавляем наблюдатель за жизненным циклом приложения
    WidgetsBinding.instance.addObserver(this);

    // Инициализация контроллеров
    _fishTypeController = TextEditingController(
      text: _isEditing ? widget.initialRecord!.fishType : '',
    );

    _weightController = TextEditingController(
      text:
      _isEditing && widget.initialRecord!.weight > 0
          ? widget.initialRecord!.weight.toString()
          : '',
    );

    _lengthController = TextEditingController(
      text:
      _isEditing && widget.initialRecord!.length > 0
          ? widget.initialRecord!.length.toString()
          : '',
    );

    _notesController = TextEditingController(
      text: _isEditing ? widget.initialRecord!.notes : '',
    );

    // Установка времени
    if (_isEditing) {
      _selectedTime = widget.initialRecord!.time;
      _existingPhotoUrls.addAll(widget.initialRecord!.photoUrls);
    }

    // Инициализация дней рыбалки и автоматический выбор дня
    _initializeFishingDays();

    // Запоминаем текущую дату для отслеживания изменений
    _lastCheckedDate = DateTime.now();
  }

  @override
  void dispose() {
    // Удаляем наблюдатель при уничтожении виджета
    WidgetsBinding.instance.removeObserver(this);
    _fishTypeController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Переопределяем метод для отслеживания изменений жизненного цикла приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Когда приложение возвращается в активное состояние
    if (state == AppLifecycleState.resumed) {
      _checkForDateChange();
    }
  }

  // Метод для проверки смены календарного дня
  void _checkForDateChange() {
    if (_lastCheckedDate == null || _isEditing) return;

    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastCheckedDate!.year,
      _lastCheckedDate!.month,
      _lastCheckedDate!.day,
    );

    // Если календарный день изменился
    if (!nowDate.isAtSameMomentAs(lastDate)) {
      debugPrint(
        '🗓️ Обнаружена смена календарного дня: ${DateFormat('dd.MM.yyyy').format(lastDate)} → ${DateFormat('dd.MM.yyyy').format(nowDate)}',
      );

      // Обновляем последнюю проверенную дату
      _lastCheckedDate = now;

      // Пересчитываем текущий день рыбалки
      final newDayIndex = _determineCurrentFishingDay();

      // Если день изменился, обновляем интерфейс
      if (newDayIndex != _selectedDayIndex) {
        setState(() {
          _selectedDayIndex = newDayIndex;
        });
        debugPrint(
          '🗓️ Автоматически переключились на день ${_selectedDayIndex + 1}',
        );
      }
    }
  }

  // Новый метод для инициализации дней рыбалки
  void _initializeFishingDays() {
    if (widget.fishingStartDate != null) {
      _fishingDays.clear();
      DateTime currentDay = DateTime(
        widget.fishingStartDate!.year,
        widget.fishingStartDate!.month,
        widget.fishingStartDate!.day,
      );

      if (widget.isMultiDay && widget.fishingEndDate != null) {
        // Многодневная рыбалка
        DateTime endDay = DateTime(
          widget.fishingEndDate!.year,
          widget.fishingEndDate!.month,
          widget.fishingEndDate!.day,
        );

        while (!currentDay.isAfter(endDay)) {
          _fishingDays.add(currentDay);
          currentDay = currentDay.add(const Duration(days: 1));
        }
        _totalFishingDays = _fishingDays.length;
      } else {
        // Однодневная рыбалка
        _fishingDays.add(currentDay);
        _totalFishingDays = 1;
      }

      // Автоматический выбор дня на основе текущей даты
      _selectedDayIndex = _determineCurrentFishingDay();
    } else {
      // Если даты рыбалки не переданы, используем переданный dayIndex
      _selectedDayIndex = widget.dayIndex;
      _totalFishingDays = 1;
    }
  }

  // Метод для определения текущего дня рыбалки
  int _determineCurrentFishingDay() {
    if (_isEditing) {
      // При редактировании возвращаем день из существующей записи
      return widget.initialRecord!.dayIndex;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Ищем соответствующий день в списке дней рыбалки
    for (int i = 0; i < _fishingDays.length; i++) {
      if (_fishingDays[i].isAtSameMomentAs(todayDate)) {
        debugPrint(
          '🗓️ Автоматически выбран день ${i + 1} (${DateFormat('dd.MM.yyyy').format(_fishingDays[i])})',
        );
        return i;
      }
    }

    // Если текущий день не найден среди дней рыбалки
    if (_fishingDays.isNotEmpty) {
      // Если сегодня до начала рыбалки - выбираем первый день
      if (todayDate.isBefore(_fishingDays.first)) {
        debugPrint('🗓️ Сегодня до начала рыбалки, выбран первый день');
        return 0;
      }
      // Если сегодня после окончания рыбалки - выбираем последний день
      else if (todayDate.isAfter(_fishingDays.last)) {
        debugPrint(
          '🗓️ Сегодня после окончания рыбалки, выбран последний день',
        );
        return _fishingDays.length - 1;
      }
    }

    // По умолчанию возвращаем переданный dayIndex или 0
    return widget.dayIndex.clamp(0, _totalFishingDays - 1);
  }

  // Метод для получения названия дня
  String _getDayName(int index) {
    final localizations = AppLocalizations.of(context);
    if (_fishingDays.isNotEmpty && index < _fishingDays.length) {
      final date = _fishingDays[index];
      return '${localizations.translate('day_fishing')} ${index + 1} (${DateFormat('dd.MM.yyyy').format(date)})';
    }
    return '${localizations.translate('day_fishing')} ${index + 1}';
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
    final localizations = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 70, // Компрессия для оптимизации размера
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // Добавляем новые фото к уже существующим
          _selectedPhotos.addAll(
            pickedFiles.map((xFile) => File(xFile.path)).toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_selecting_images')}: $e',
            ),
          ),
        );
      }
    }
  }

  // Сделать фото с камеры
  Future<void> _takePhoto() async {
    final localizations = AppLocalizations.of(context);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_taking_photo')}: $e',
            ),
          ),
        );
      }
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
        try {
          final bytes = await photo.readAsBytes();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${_selectedPhotos.indexOf(photo)}.jpg';
          final userId = _firebaseService.currentUserId;

          if (userId == null) {
            if (mounted) {
              throw Exception(
                AppLocalizations.of(context).translate('user_not_found'),
              );
            }
            return [];
          }

          final path = 'users/$userId/bite_photos/$fileName';
          final url = await _firebaseService.uploadImage(path, bytes);
          photoUrls.add(url);
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      return photoUrls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading_image')}: $e',
            ),
          ),
        );
      }
      return [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Сохранение записи о поклёвке
  Future<void> _saveBiteRecord() async {
    final localizations = AppLocalizations.of(context);

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
        dayIndex: _selectedDayIndex, // Используем выбранный день
        spotIndex: _isEditing ? widget.initialRecord!.spotIndex : 0,
        photoUrls: allPhotoUrls,
      );

      // ✅ ДОБАВИТЬ ЭТОТ ЛОГ:
      debugPrint('🐛 СОЗДАНИЕ ПОКЛЕВКИ: dayIndex=${_selectedDayIndex}, selectedDay=${_selectedDayIndex + 1}');

      if (mounted) {
        Navigator.pop(context, biteRecord);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_saving')}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Подтверждение удаления записи
  void _confirmDelete() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_bite_record'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('delete_bite_confirmation'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              Navigator.pop(
                context,
                'delete',
              ); // Возвращаем команду удаления
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = ResponsiveUtils.getAvailableHeight(context);

    // Динамическое определение layout параметров
    final shouldUseCompactLayout = isSmallScreen || (isLandscape && !isTablet);
    final contentWidth = isTablet
        ? (screenWidth > 800 ? 600.0 : screenWidth * 0.8)
        : screenWidth;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? localizations.translate('edit_bite')
              : localizations.translate('new_bite'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 22),
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
          // Добавляем кнопку удаления, если редактируем запись
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
                size: ResponsiveUtils.getIconSize(context),
              ),
              onPressed: _confirmDelete,
            ),
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
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('saving'),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: contentWidth,
                maxHeight: screenHeight,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: ResponsiveUtils.getVerticalPadding(context),
                  ),
                  children: [
                    // Селектор дня рыбалки (только для многодневной рыбалки)
                    if (_totalFishingDays > 1) ...[
                      _buildSectionHeader(localizations.translate('day_fishing')),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: ResponsiveConstants.minTouchTarget,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12332E),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveConstants.spacingM,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedDayIndex,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF12332E),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                              fontWeight: FontWeight.w500,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppConstants.textColor,
                              size: ResponsiveUtils.getIconSize(context),
                            ),
                            items: List.generate(_totalFishingDays, (index) {
                              final isToday =
                                  _fishingDays.isNotEmpty &&
                                      index < _fishingDays.length &&
                                      _isToday(_fishingDays[index]);

                              return DropdownMenuItem<int>(
                                value: index,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getDayName(index),
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontWeight:
                                          isToday
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (isToday)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveConstants.spacingXS,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          localizations.translate('today'),
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: ResponsiveUtils.getOptimalFontSize(context, 12),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            onChanged: (int? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDayIndex = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveConstants.spacingL),
                    ] else ...[
                      // Информация о дне (для однодневной рыбалки)
                      Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
                        child: Text(
                          _getDayName(_selectedDayIndex),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // Время поклевки
                    _buildSectionHeader('${localizations.translate('bite_time')}*'),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: ResponsiveConstants.minTouchTarget,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveConstants.spacingS,
                          horizontal: ResponsiveConstants.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12332E),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppConstants.textColor,
                              size: ResponsiveUtils.getIconSize(context),
                            ),
                            SizedBox(width: ResponsiveConstants.spacingS),
                            Expanded(
                              child: Text(
                                DateFormat('HH:mm').format(_selectedTime),
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                                  fontWeight: FontWeight.w500,
                                ),
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
                    ),

                    SizedBox(height: ResponsiveConstants.spacingL),

                    // Вид рыбы
                    _buildSectionHeader(localizations.translate('fish_type')),
                    TextFormField(
                      controller: _fishTypeController,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFF12332E),
                        filled: true,
                        hintText: localizations.translate('specify_fish_type'),
                        hintStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
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
                    ),

                    SizedBox(height: ResponsiveConstants.spacingL),

                    // Ряд для веса и длины - динамический адаптивный layout
                    _buildWeightLengthSection(localizations, shouldUseCompactLayout),

                    SizedBox(height: ResponsiveConstants.spacingL),

                    // Заметки
                    _buildSectionHeader(localizations.translate('notes')),
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFF12332E),
                        filled: true,
                        hintText: localizations.translate(
                          'additional_notes_fishing',
                        ),
                        hintStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: ResponsiveConstants.spacingL),

                    // Фотографии - динамический layout
                    _buildPhotosSection(localizations, shouldUseCompactLayout),

                    // Отображение фото галерей
                    _buildPhotoGalleries(localizations),

                    SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                    // Кнопка сохранения - адаптивная ширина
                    _buildSaveButton(localizations),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Проверяет, является ли переданная дата сегодняшней
  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingXS),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Динамическая секция для веса и длины
  Widget _buildWeightLengthSection(AppLocalizations localizations, bool useCompactLayout) {
    if (useCompactLayout) {
      return Column(
        children: [
          _buildWeightField(localizations),
          SizedBox(height: ResponsiveConstants.spacingM),
          _buildLengthField(localizations),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildWeightField(localizations)),
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(child: _buildLengthField(localizations)),
      ],
    );
  }

  // Динамическая секция для фотографий
  Widget _buildPhotosSection(AppLocalizations localizations, bool useCompactLayout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('photos')),
        LayoutBuilder(
          builder: (context, constraints) {
            // Если ширина меньше 300px или компактный режим - используем Column
            if (constraints.maxWidth < 300 || useCompactLayout) {
              return Column(
                children: [
                  _buildPhotoButton(
                    Icons.photo_library,
                    localizations.translate('gallery'),
                    _pickImages,
                  ),
                  SizedBox(height: ResponsiveConstants.spacingS),
                  _buildPhotoButton(
                    Icons.camera_alt,
                    localizations.translate('camera'),
                    _takePhoto,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildPhotoButton(
                    Icons.photo_library,
                    localizations.translate('gallery'),
                    _pickImages,
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingS),
                Expanded(
                  child: _buildPhotoButton(
                    Icons.camera_alt,
                    localizations.translate('camera'),
                    _takePhoto,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Секция галерей фотографий с адаптивным количеством колонок
  Widget _buildPhotoGalleries(AppLocalizations localizations) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Динамическое определение размера фото и количества в ряду
    final photoSize = ResponsiveUtils.getValueByBreakpoint(
      context,
      mobileSmall: 80.0,
      mobileMedium: 90.0,
      mobileLarge: 100.0,
      tabletSmall: 110.0,
      tabletLarge: 120.0,
      defaultValue: 100.0,
    );

    // Определяем количество фото в ряду на основе ширины экрана
    final photosPerRow = isTablet
        ? (screenWidth > 800 ? 6 : 4)
        : (screenWidth > 400 ? 4 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Существующие фото
        if (_existingPhotoUrls.isNotEmpty) ...[
          SizedBox(height: ResponsiveConstants.spacingS),
          _buildSectionHeader(localizations.translate('existing_photos')),
          _buildPhotoGrid(_existingPhotoUrls, true, photoSize, photosPerRow),
        ],

        // Новые фото
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(height: ResponsiveConstants.spacingS),
          _buildSectionHeader(localizations.translate('new_photos')),
          _buildPhotoGrid(
            _selectedPhotos.map((file) => file.path).toList(),
            false,
            photoSize,
            photosPerRow,
          ),
        ],
      ],
    );
  }

  // Адаптивная сетка фотографий
  Widget _buildPhotoGrid(List<String> photos, bool isExisting, double photoSize, int photosPerRow) {
    if (photos.length <= photosPerRow) {
      // Если фото помещаются в один ряд - используем горизонтальный список
      return SizedBox(
        height: photoSize,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return _buildPhotoItem(photos[index], index, isExisting);
          },
        ),
      );
    }

    // Если фото много - используем обёртку
    return Wrap(
      spacing: ResponsiveConstants.spacingXS,
      runSpacing: ResponsiveConstants.spacingXS,
      children: photos.asMap().entries.map((entry) {
        return _buildPhotoItem(entry.value, entry.key, isExisting);
      }).toList(),
    );
  }

  // Адаптивная кнопка сохранения
  Widget _buildSaveButton(AppLocalizations localizations) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 400 : double.infinity,
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveBiteRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textColor,
            minimumSize: Size(
              double.infinity,
              ResponsiveUtils.getButtonHeight(context),
            ),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveConstants.spacingM,
              horizontal: ResponsiveConstants.spacingL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: 24),
              ),
            ),
          ),
          child: Text(
            _isEditing
                ? localizations.translate('save_changes_btn')
                : localizations.translate('add_bite_btn'),
            style: TextStyle(
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Виджет для поля веса
  Widget _buildWeightField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          localizations.translate('weight_kg'),
        ),
        TextFormField(
          controller: _weightController,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
          ),
          decoration: InputDecoration(
            fillColor: const Color(0xFF12332E),
            filled: true,
            hintText: localizations.translate('weight'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.5),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
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
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Проверяем, что введено корректное число
              final weightText = value.replaceAll(',', '.');
              if (double.tryParse(weightText) == null) {
                return localizations.translate(
                  'enter_correct_number',
                );
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // Виджет для поля длины
  Widget _buildLengthField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          localizations.translate('length_cm'),
        ),
        TextFormField(
          controller: _lengthController,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
          ),
          decoration: InputDecoration(
            fillColor: const Color(0xFF12332E),
            filled: true,
            hintText: localizations.translate('length'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.5),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
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
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Проверяем запятую в точку для корректного парсинга
              final lengthText = value.replaceAll(',', '.');
              if (double.tryParse(lengthText) == null) {
                return localizations.translate(
                  'enter_correct_number',
                );
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // Виджет для кнопки фото
  Widget _buildPhotoButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        size: ResponsiveUtils.getIconSize(context),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        minimumSize: Size(
          double.infinity,
          ResponsiveConstants.minTouchTarget,
        ),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConstants.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
          ),
        ),
      ),
      onPressed: onPressed,
    );
  }

  // Построитель карточки фото - адаптивный размер
  Widget _buildPhotoItem(String source, int index, bool isExisting) {
    final photoSize = ResponsiveUtils.getValueByBreakpoint(
      context,
      mobileSmall: 80.0,
      mobileMedium: 90.0,
      mobileLarge: 100.0,
      tabletSmall: 110.0,
      tabletLarge: 120.0,
      defaultValue: 100.0,
    );

    final iconSize = ResponsiveUtils.getIconSize(context, baseSize: 16);

    return Stack(
      children: [
        Container(
          width: photoSize,
          height: photoSize,
          margin: EdgeInsets.only(right: ResponsiveConstants.spacingXS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: 8),
            ),
            image: DecorationImage(
              image:
              isExisting
                  ? NetworkImage(source) as ImageProvider
                  : FileImage(File(source)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: ResponsiveConstants.spacingXXS,
          right: ResponsiveConstants.spacingXS + ResponsiveConstants.spacingXXS,
          child: GestureDetector(
            onTap: () => _removePhoto(index, isExisting),
            child: Container(
              width: ResponsiveConstants.minTouchTarget * 0.6,
              height: ResponsiveConstants.minTouchTarget * 0.6,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}