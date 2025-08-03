// Путь: lib/screens/fishing_note/edit_fishing_note_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../repositories/fishing_note_repository.dart'; // 🚨 ДОБАВЛЕНО: используем Repository
import '../../services/weather/weather_service.dart';
import '../../services/weather_settings_service.dart';
import '../../utils/network_utils.dart';
import '../../utils/date_formatter.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import '../map/universal_map_screen.dart';
import 'bite_record_screen.dart';
import 'edit_bite_record_screen.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/ai_bite_prediction_service.dart';
// 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Добавляем импорты для Provider
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/photo/photo_service.dart'; // ДОБАВИТЬ ЭТУ СТРОКУ

class EditFishingNoteScreen extends StatefulWidget {
  final FishingNoteModel note;

  const EditFishingNoteScreen({super.key, required this.note});

  @override
  State<EditFishingNoteScreen> createState() => _EditFishingNoteScreenState();
}

class _EditFishingNoteScreenState extends State<EditFishingNoteScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationController;
  late TextEditingController _tackleController;
  late TextEditingController _notesController;

  final _firebaseService = FirebaseService();
  final _weatherService = WeatherService();
  final _weatherSettings = WeatherSettingsService();
  final _fishingNoteRepository = FishingNoteRepository(); // 🚨 ДОБАВЛЕНО: Repository
  final _photoService = PhotoService();

  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isMultiDay;
  late int _tripDays;

  final List<File> _newPhotos = [];
  List<String> _existingPhotoUrls = [];
  bool _isSaving = false;

  late double _latitude;
  late double _longitude;
  late bool _hasLocation;

  FishingWeather? _weather;
  bool _isLoadingWeather = false;

  late List<BiteRecord> _biteRecords;
  late String _selectedFishingType;

  // ✅ НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ СЕЛЕКТОРА ДНЯ
  int _selectedDayIndex = 0;
  final List<DateTime> _fishingDays = [];

  // Переменные для ИИ-анализа
  AIBitePrediction? _aiPrediction;
  bool _isLoadingAI = false;
  final _aiService = AIBitePredictionService();

  // Для анимаций
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Инициализация контроллеров
    _locationController = TextEditingController(text: widget.note.location);
    _tackleController = TextEditingController(text: widget.note.tackle);
    _notesController = TextEditingController(text: widget.note.notes);

    // Инициализация данных из заметки
    _startDate = widget.note.date;
    _endDate = widget.note.endDate ?? widget.note.date;
    _isMultiDay = widget.note.isMultiDay;
    // Приводим даты к началу дня для корректного подсчета
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
    _tripDays = _isMultiDay ? endDay.difference(startDay).inDays + 1 : 1;

    _existingPhotoUrls = List.from(widget.note.photoUrls);

    _latitude = widget.note.latitude;
    _longitude = widget.note.longitude;
    _hasLocation = _latitude != 0.0 && _longitude != 0.0;

    _weather = widget.note.weather;

    _biteRecords = List.from(widget.note.biteRecords);
    _selectedFishingType = widget.note.fishingType;

    // ✅ ИНИЦИАЛИЗАЦИЯ ДНЕЙ РЫБАЛКИ
    _initializeFishingDays();

    // ИСПРАВЛЕНО: Загружаем ИИ-анализ из заметки, если он есть
    if (widget.note.aiPrediction != null) {
      _loadAIFromMap(widget.note.aiPrediction!);
    }

    // Настраиваем анимацию для плавного появления элементов
    _animationController = AnimationController(
      vsync: this,
      duration: ResponsiveConstants.animationNormal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    debugPrint('🔧 EditFishingNoteScreen: Редактируем заметку ID: ${widget.note.id}');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tackleController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С ДНЯМИ РЫБАЛКИ
  void _initializeFishingDays() {
    _fishingDays.clear();
    DateTime currentDay = DateTime(_startDate.year, _startDate.month, _startDate.day);

    if (_isMultiDay) {
      DateTime endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
      while (!currentDay.isAfter(endDay)) {
        _fishingDays.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
    } else {
      _fishingDays.add(currentDay);
    }

    // Выбираем текущий день или первый день рыбалки
    _selectedDayIndex = _determineCurrentFishingDay();
  }

  int _determineCurrentFishingDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < _fishingDays.length; i++) {
      if (_fishingDays[i].isAtSameMomentAs(todayDate)) {
        return i;
      }
    }

    // Если сегодня не в диапазоне рыбалки, выбираем первый день
    return 0;
  }

  String _getDayName(int index) {
    final localizations = AppLocalizations.of(context);
    if (index < _fishingDays.length) {
      final date = _fishingDays[index];
      return '${localizations.translate('day_fishing')} ${index + 1} (${DateFormat('dd.MM.yyyy').format(date)})';
    }
    return '${localizations.translate('day_fishing')} ${index + 1}';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  // НОВЫЙ МЕТОД: Загрузка ИИ-анализа из сохраненных данных
  void _loadAIFromMap(Map<String, dynamic> aiMap) {
    try {
      final activityLevelString =
          aiMap['activityLevel'] as String? ?? 'moderate';
      ActivityLevel activityLevel = ActivityLevel.moderate;

      switch (activityLevelString.split('.').last) {
        case 'excellent':
          activityLevel = ActivityLevel.excellent;
          break;
        case 'good':
          activityLevel = ActivityLevel.good;
          break;
        case 'moderate':
          activityLevel = ActivityLevel.moderate;
          break;
        case 'poor':
          activityLevel = ActivityLevel.poor;
          break;
        case 'veryPoor':
          activityLevel = ActivityLevel.veryPoor;
          break;
      }

      // ИСПРАВЛЕНО: Используем правильный конструктор
      _aiPrediction = AIBitePrediction(
        overallScore: aiMap['overallScore'] as int? ?? 50,
        activityLevel: activityLevel,
        confidence:
        (aiMap['confidencePercent'] as int? ?? 50) /
            100.0, // Конвертируем в double
        recommendation: aiMap['recommendation'] as String? ?? '',
        tips: List<String>.from(aiMap['tips'] ?? []),
        fishingType: aiMap['fishingType'] as String? ?? _selectedFishingType,
      );

      debugPrint(
        '🧠 ИИ-анализ загружен из сохраненных данных: ${_aiPrediction!.overallScore} баллов',
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ИИ-анализа из сохраненных данных: $e');
    }
  }

  void _updateTripDays() {
    if (_isMultiDay) {
      // Приводим даты к началу дня для корректного подсчета
      final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
      setState(() {
        _tripDays = endDay.difference(startDay).inDays + 1;
      });
    } else {
      setState(() {
        _tripDays = 1;
      });
    }

    // ✅ ПЕРЕСЧИТЫВАЕМ ДНИ РЫБАЛКИ
    _initializeFishingDays();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Если выбранная дата старта позже даты окончания, обновляем дату окончания
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }

        // Устанавливаем флаг многодневной рыбалки
        _isMultiDay = !DateUtils.isSameDay(_startDate, _endDate);

        // Обновляем счетчик дней
        _updateTripDays();
      });
    }
  }

  Future<void> _pickImages() async {
    final localizations = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

      if (pickedFiles.isNotEmpty && mounted) {
        for (final pickedFile in pickedFiles) {
          try {
            // Умное сжатие и сохранение в постоянную папку
            final permanentFile = await _photoService.processAndSavePhoto(pickedFile);

            setState(() {
              _newPhotos.add(permanentFile);
            });

            // Показываем информацию о сжатии
            final originalBytes = await pickedFile.readAsBytes();
            final compressedBytes = await permanentFile.readAsBytes();
            final originalSizeMB = (originalBytes.length / (1024 * 1024)).toStringAsFixed(1);
            final compressedSizeMB = (compressedBytes.length / (1024 * 1024)).toStringAsFixed(1);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Фото обработано: $originalSizeMB MB → $compressedSizeMB MB'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            debugPrint('Ошибка обработки фото: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_selecting_images')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final localizations = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        try {
          // Умное сжатие и сохранение в постоянную папку
          final permanentFile = await _photoService.processAndSavePhoto(pickedFile);

          setState(() {
            _newPhotos.add(permanentFile);
          });

          // Показываем информацию о сжатии
          final originalBytes = await pickedFile.readAsBytes();
          final compressedBytes = await permanentFile.readAsBytes();
          final originalSizeMB = (originalBytes.length / (1024 * 1024)).toStringAsFixed(1);
          final compressedSizeMB = (compressedBytes.length / (1024 * 1024)).toStringAsFixed(1);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Фото сделано: $originalSizeMB MB → $compressedSizeMB MB'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${localizations.translate('error_compressing_photo')}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_taking_photo')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД: Удаление существующих фото
  Future<void> _removeExistingPhoto(int index) async {
    final localizations = AppLocalizations.of(context);

    // Показываем диалог подтверждения
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('delete_photo'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('delete_photo_confirmation'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations.translate('cancel'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations.translate('delete'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Получаем URL фото для удаления
      final photoUrl = _existingPhotoUrls[index];

      debugPrint('🗑️ Удаляем фото: $photoUrl');

      // Показываем индикатор загрузки
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text(localizations.translate('deleting_photo')),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // ✅ УДАЛЯЕМ ФОТО ИЗ FIREBASE STORAGE
      await _photoService.deletePhotosFromFirebase([photoUrl]);

      // ✅ УДАЛЯЕМ ЛОКАЛЬНЫЕ ФАЙЛЫ (если есть)
      await _photoService.deleteLocalPhotos([photoUrl]);

      // Удаляем из списка UI
      setState(() {
        _existingPhotoUrls.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('photo_deleted_successfully')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Фото успешно удалено из Firebase и UI');

    } catch (e) {
      debugPrint('❌ Ошибка удаления фото: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_deleting_photo')}: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ ОБНОВЛЕННЫЙ МЕТОД: Удаление новых фото (локальных файлов)
  Future<void> _removeNewPhoto(int index) async {
    final localizations = AppLocalizations.of(context);

    try {
      // Получаем файл для удаления
      final photoFile = _newPhotos[index];

      debugPrint('🗑️ Удаляем локальное фото: ${photoFile.path}');

      // ✅ УДАЛЯЕМ ЛОКАЛЬНЫЙ ФАЙЛ
      await _photoService.deleteLocalPhotos([photoFile.path]);

      // Удаляем из списка UI
      setState(() {
        _newPhotos.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('photo_deleted_successfully')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      debugPrint('✅ Локальное фото успешно удалено');

    } catch (e) {
      debugPrint('❌ Ошибка удаления локального фото: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_deleting_photo')}: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversalMapScreen(
          mode: MapMode.editLocation,
          initialLatitude: _hasLocation ? _latitude : null,
          initialLongitude: _hasLocation ? _longitude : null,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _hasLocation = true;
        // Сбрасываем ИИ-анализ при смене местоположения
        _aiPrediction = null;
      });
    }
  }

  Future<void> _fetchWeatherAndAI() async {
    final localizations = AppLocalizations.of(context);

    if (!_hasLocation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('select_map_point')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _isLoadingAI = true;
    });

    try {
      debugPrint('🌤️ Загружаем погоду и ИИ-анализ...');

      // Загружаем погоду
      final weatherData = await _weatherService.getWeatherForLocation(
        _latitude,
        _longitude,
        context,
      );

      if (mounted) {
        setState(() {
          _weather = weatherData;
          _isLoadingWeather = false;
        });
      }

      // Загружаем ИИ-анализ для выбранного типа рыбалки
      try {
        final aiResult = await _aiService.getPredictionForFishingType(
          fishingType: _selectedFishingType,
          latitude: _latitude,
          longitude: _longitude,
          l10n: AppLocalizations.of(context),
        );

        if (mounted) {
          setState(() {
            _aiPrediction = aiResult;
            _isLoadingAI = false;
          });
          debugPrint('🧠 ИИ-анализ загружен: ${aiResult.overallScore} баллов');
        }
      } catch (aiError) {
        debugPrint('❌ Ошибка ИИ-анализа: $aiError');
        if (mounted) {
          setState(() {
            _isLoadingAI = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading')}: $e',
            ),
          ),
        );
        setState(() {
          _isLoadingWeather = false;
          _isLoadingAI = false;
        });
      }
    }
  }

  Future<void> _addBiteRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(
          fishingStartDate: _startDate,
          fishingEndDate: _isMultiDay ? _endDate : null,
          isMultiDay: _isMultiDay,
          dayIndex: _selectedDayIndex, // ✅ ПЕРЕДАЕМ ВЫБРАННЫЙ ДЕНЬ
        ),
      ),
    );

    if (result != null && result is BiteRecord) {
      setState(() {
        _biteRecords.add(result);
      });
    }
  }

  Future<void> _editBiteRecord(int index) async {
    final record = _biteRecords[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBiteRecordScreen(biteRecord: record),
      ),
    );

    if (result != null && result is BiteRecord) {
      setState(() {
        _biteRecords[index] = result;
      });
    }
  }

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем Repository вместо Firebase
  Future<void> _saveNote() async {
    final localizations = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('enter_location_name')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('💾 Начинаем сохранение заметки ID: ${widget.note.id}');

      // ИСПРАВЛЕНО: Сохраняем ИИ-анализ в заметку
      Map<String, dynamic>? aiPredictionMap;
      if (_aiPrediction != null) {
        aiPredictionMap = {
          'overallScore': _aiPrediction!.overallScore,
          'activityLevel': _aiPrediction!.activityLevel.toString(),
          'confidencePercent': _aiPrediction!.confidencePercent,
          'recommendation': _aiPrediction!.recommendation,
          'tips': _aiPrediction!.tips,
          'fishingType': _aiPrediction!.fishingType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        debugPrint('🧠 Сохраняем ИИ-анализ: ${_aiPrediction!.overallScore} баллов');
      }

      // Создаем список всех URL фото (существующие + новые, если есть)
      List<String> allPhotoUrls = List.from(_existingPhotoUrls);

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Подключение к интернету: ${isOnline ? "есть" : "нет"}');

      if (isOnline && _newPhotos.isNotEmpty) {
        // Если есть интернет и новые фото, загружаем их через PhotoService
        debugPrint('📸 Загружаем ${_newPhotos.length} новых фото...');
        final uploadedUrls = await _photoService.uploadPhotosToFirebase(
          _newPhotos,
          widget.note.id,
        );
        allPhotoUrls.addAll(uploadedUrls);
        debugPrint('✅ Загружено ${uploadedUrls.length} из ${_newPhotos.length} фото');
      } else if (_newPhotos.isNotEmpty) {
        debugPrint('⚠️ Новые фото сохранены локально - нет интернета');
        // Добавляем локальные пути для офлайн режима
        allPhotoUrls.addAll(_newPhotos.map((file) => file.path));
      }

      // Обновляем модель заметки
      final updatedNote = widget.note.copyWith(
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        date: _startDate,
        endDate: _isMultiDay ? _endDate : null,
        isMultiDay: _isMultiDay,
        tackle: _tackleController.text.trim(),
        notes: _notesController.text.trim(),
        photoUrls: allPhotoUrls,
        fishingType: _selectedFishingType,
        weather: _weather,
        biteRecords: _biteRecords,
        aiPrediction: aiPredictionMap,
      );

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем Repository для сохранения
      debugPrint('🔄 Сохраняем заметку через Repository...');
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Обновляем SubscriptionProvider после успешного редактирования
      if (mounted) {
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после редактирования заметки');
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
          // Не прерываем выполнение, заметка уже обновлена
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('note_updated_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        debugPrint('✅ Заметка успешно обновлена через Repository');
        Navigator.pop(context, true); // Возвращаем true для обновления списка заметок
      }
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении заметки: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_saving')}: $e',
            ),
            backgroundColor: Colors.red,
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

  // Диалог выбора типа рыбалки
  void _showFishingTypeDialog() {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveConstants.spacingM,
                ),
                child: Text(
                  localizations.translate('select_fishing_type'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Divider(color: Colors.white24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.fishingTypes.length,
                  itemBuilder: (context, index) {
                    final typeKey = AppConstants.fishingTypes[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingXS),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ResponsiveConstants.spacingM,
                          vertical: ResponsiveConstants.spacingS,
                        ),
                        minTileHeight: ResponsiveConstants.minTouchTarget,
                        title: Text(
                          localizations.translate(typeKey),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        leading: Container(
                          width: ResponsiveConstants.minTouchTarget,
                          height: ResponsiveConstants.minTouchTarget,
                          alignment: Alignment.center,
                          child: FishingTypeIcons.getIconWidget(typeKey),
                        ),
                        trailing: _selectedFishingType == typeKey
                            ? Icon(
                          Icons.check_circle,
                          color: AppConstants.primaryColor,
                          size: ResponsiveUtils.getIconSize(context),
                        )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedFishingType = typeKey;
                            // Сбрасываем ИИ-анализ при смене типа
                            _aiPrediction = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveConstants.spacingM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: Size(
                          ResponsiveConstants.minTouchTarget * 2,
                          ResponsiveConstants.minTouchTarget,
                        ),
                      ),
                      child: Text(
                        localizations.translate('cancel'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Диалог подтверждения отмены редактирования
  void _showCancelConfirmationDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('cancel_editing'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          content: Text(
            localizations.translate('cancel_editing_confirmation'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: Size(
                  ResponsiveConstants.minTouchTarget * 1.5,
                  ResponsiveConstants.minTouchTarget,
                ),
              ),
              child: Text(
                localizations.translate('no'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
                Navigator.of(context).pop(); // Вернуться на предыдущий экран
              },
              style: TextButton.styleFrom(
                minimumSize: Size(
                  ResponsiveConstants.minTouchTarget * 1.5,
                  ResponsiveConstants.minTouchTarget,
                ),
              ),
              child: Text(
                localizations.translate('yes_cancel'),
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  // Построение карточки ИИ-анализа
  Widget _buildAIAnalysisCard() {
    final localizations = AppLocalizations.of(context);

    if (_aiPrediction == null) return const SizedBox();

    return Container(
      margin: EdgeInsets.only(top: ResponsiveConstants.spacingM),
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Используем адаптивную разметку для заголовка
          ResponsiveUtils.isSmallScreen(context)
              ? Column( // На маленьких экранах - вертикально
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAIHeader(localizations),
              SizedBox(height: ResponsiveConstants.spacingS),
              _buildAIScore(),
            ],
          )
              : Row( // На больших экранах - горизонтально
            children: [
              Expanded(child: _buildAIHeader(localizations)),
              _buildAIScore(),
            ],
          ),
          SizedBox(height: ResponsiveConstants.spacingM),
          Text(
            _aiPrediction!.recommendation,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
              height: ResponsiveConstants.lineHeightNormal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          if (_aiPrediction!.tips.isNotEmpty) ...[
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              localizations.translate('recommendations'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            ...(_aiPrediction!.tips
                .take(2)
                .map(
                  (tip) => Padding(
                padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingXS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.9),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 11, maxSize: 13),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAIHeader(AppLocalizations localizations) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveConstants.spacingS),
          decoration: BoxDecoration(
            color: _getScoreColor(_aiPrediction!.overallScore).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
          ),
          child: Icon(
            Icons.psychology,
            color: _getScoreColor(_aiPrediction!.overallScore),
            size: ResponsiveUtils.getIconSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('ai_bite_forecast')} (${_aiPrediction!.overallScore}/100)',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                _getActivityLevelText(_aiPrediction!.activityLevel, localizations),
                style: TextStyle(
                  color: _getScoreColor(_aiPrediction!.overallScore),
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIScore() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.spacingS,
        vertical: ResponsiveConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getScoreColor(_aiPrediction!.overallScore).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: Text(
        '${_aiPrediction!.confidencePercent}%',
        style: TextStyle(
          color: _getScoreColor(_aiPrediction!.overallScore),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 10, maxSize: 12),
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // Получение цвета по скору
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  // Получение текста уровня активности с правильной локализацией
  String _getActivityLevelText(
      ActivityLevel level,
      AppLocalizations localizations,
      ) {
    switch (level) {
      case ActivityLevel.excellent:
        return localizations.translate('excellent_activity');
      case ActivityLevel.good:
        return localizations.translate('good_activity');
      case ActivityLevel.moderate:
        return localizations.translate('moderate_activity');
      case ActivityLevel.poor:
        return localizations.translate('poor_activity');
      case ActivityLevel.veryPoor:
        return localizations.translate('very_poor_activity');
    }
  }

  // Метод для форматирования температуры согласно настройкам
  String _formatTemperature(double celsius) {
    final unit = _weatherSettings.temperatureUnit;
    switch (unit) {
      case TemperatureUnit.celsius:
        return '${celsius.toStringAsFixed(1)}°C';
      case TemperatureUnit.fahrenheit:
        final fahrenheit = (celsius * 9 / 5) + 32;
        return '${fahrenheit.toStringAsFixed(1)}°F';
    }
  }

  // Метод для форматирования скорости ветра согласно настройкам
  String _formatWindSpeed(double meterPerSecond) {
    final unit = _weatherSettings.windSpeedUnit;
    switch (unit) {
      case WindSpeedUnit.ms:
        return '${meterPerSecond.toStringAsFixed(1)} м/с';
      case WindSpeedUnit.kmh:
        final kmh = meterPerSecond * 3.6;
        return '${kmh.toStringAsFixed(1)} км/ч';
      case WindSpeedUnit.mph:
        final mph = meterPerSecond * 2.237;
        return '${mph.toStringAsFixed(1)} mph';
    }
  }

  // Метод для форматирования давления согласно настройкам
  String _formatPressure(double hpa) {
    final unit = _weatherSettings.pressureUnit;
    final calibration = _weatherSettings.barometerCalibration;

    // Применяем калибровку (калибровка хранится в гПа)
    final calibratedHpa = hpa + calibration;

    switch (unit) {
      case PressureUnit.hpa:
        return '${calibratedHpa.toStringAsFixed(0)} гПа';
      case PressureUnit.mmhg:
        final mmhg = calibratedHpa / 1.333;
        return '${mmhg.toStringAsFixed(0)} мм рт.ст.';
      case PressureUnit.inhg:
        final inhg = calibratedHpa / 33.8639;
        return '${inhg.toStringAsFixed(2)} inHg';
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
          localizations.translate('edit_note'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 22),
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
          onPressed: _showCancelConfirmationDialog,
        ),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: Icon(
                Icons.check,
                color: AppConstants.textColor,
                size: ResponsiveUtils.getIconSize(context),
              ),
              onPressed: _saveNote,
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                // Тип рыбалки (с иконкой)
                _buildSectionHeader(localizations.translate('fishing_type')),
                _buildFishingTypeSelector(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Место рыбалки
                _buildSectionHeader('${localizations.translate('fishing_location')}*'),
                _buildLocationField(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Даты рыбалки с информацией о продолжительности
                _buildSectionHeader(localizations.translate('fishing_dates')),
                _buildDateSelectors(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),


                // Точка на карте
                _buildSectionHeader(localizations.translate('map_point')),
                _buildMapPointButton(localizations),
                if (_hasLocation) _buildCoordinatesInfo(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Погода + ИИ-анализ
                _buildSectionHeader(localizations.translate('weather_and_ai_analysis')),
                _buildWeatherAIButton(localizations),
                if (_isLoadingWeather || _isLoadingAI) _buildLoadingIndicator(localizations),
                if (_weather != null) _buildWeatherCard(localizations),
                if (_aiPrediction != null) _buildAIAnalysisCard(),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Снасти
                _buildSectionHeader(localizations.translate('tackle')),
                _buildTackleField(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Заметки
                _buildSectionHeader(localizations.translate('notes')),
                _buildNotesField(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Фотографии
                _buildSectionHeader(localizations.translate('photos')),
                _buildPhotoButtons(localizations),
                if (_existingPhotoUrls.isNotEmpty) _buildExistingPhotos(localizations),
                if (_newPhotos.isNotEmpty) _buildNewPhotos(localizations),
                SizedBox(height: ResponsiveConstants.spacingL),

                // Записи о поклевках
                _buildSectionHeader(localizations.translate('bite_records')),
                _buildAddBiteRecordButton(localizations),
                if (_biteRecords.isNotEmpty) _buildBiteRecordsSection(localizations),
                SizedBox(height: ResponsiveConstants.spacingXXL),

                // Кнопки внизу экрана
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
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildFishingTypeSelector(AppLocalizations localizations) {
    return InkWell(
      onTap: _showFishingTypeDialog,
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveConstants.spacingM),
        decoration: BoxDecoration(
          color: const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingS),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: FishingTypeIcons.getIconWidget(
                _selectedFishingType,
                size: ResponsiveUtils.getIconSize(context, baseSize: 24),
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: Text(
                localizations.translate(_selectedFishingType),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
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

  Widget _buildLocationField(AppLocalizations localizations) {
    return TextFormField(
      controller: _locationController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
      ),
      decoration: InputDecoration(
        fillColor: const Color(0xFF12332E),
        filled: true,
        hintText: localizations.translate('enter_location_name'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.location_on,
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
          return localizations.translate('required_field');
        }
        return null;
      },
    );
  }

  Widget _buildDateSelectors(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveUtils.isSmallScreen(context)
            ? Column( // На маленьких экранах - вертикально
          children: [
            _buildDateSelector(
              label: localizations.translate('start'),
              date: _startDate,
              onTap: () => _selectDate(context, true),
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            _buildDateSelector(
              label: localizations.translate('end'),
              date: _endDate,
              onTap: () => _selectDate(context, false),
            ),
          ],
        )
            : Row( // На больших экранах - горизонтально
          children: [
            Expanded(
              child: _buildDateSelector(
                label: localizations.translate('start'),
                date: _startDate,
                onTap: () => _selectDate(context, true),
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: _buildDateSelector(
                label: localizations.translate('end'),
                date: _endDate,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
        Text(
          '${localizations.translate('duration')}: $_tripDays ${DateFormatter.getDaysText(_tripDays, context)}',
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: ResponsiveConstants.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 18),
                ),
                SizedBox(width: ResponsiveConstants.spacingS),
                Expanded(
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(date),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPointButton(AppLocalizations localizations) {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.map,
        color: AppConstants.textColor,
        size: ResponsiveUtils.getIconSize(context),
      ),
      label: Text(
        _hasLocation
            ? localizations.translate('change_map_point')
            : localizations.translate('select_map_point'),
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF12332E),
        minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConstants.spacingM,
          horizontal: ResponsiveConstants.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
      ),
      onPressed: _selectLocation,
    );
  }

  Widget _buildCoordinatesInfo(AppLocalizations localizations) {
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveConstants.spacingS),
      child: Text(
        '${localizations.translate('coordinates')}: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
        style: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.7),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildWeatherAIButton(AppLocalizations localizations) {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.psychology,
        color: AppConstants.textColor,
        size: ResponsiveUtils.getIconSize(context),
      ),
      label: Text(
        _weather != null || _aiPrediction != null
            ? localizations.translate('update_weather_and_ai')
            : localizations.translate('load_weather_ai'),
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF12332E),
        minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConstants.spacingM,
          horizontal: ResponsiveConstants.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
      ),
      onPressed: (_isLoadingWeather || _isLoadingAI) ? null : _fetchWeatherAndAI,
    );
  }

  Widget _buildLoadingIndicator(AppLocalizations localizations) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveConstants.spacingM),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            Text(
              _isLoadingAI
                  ? localizations.translate('ai_analyzing')
                  : localizations.translate('loading_weather'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(AppLocalizations localizations) {
    if (_weather == null) return const SizedBox();

    return Container(
      margin: EdgeInsets.only(top: ResponsiveConstants.spacingM),
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ВЕРХНЯЯ ЧАСТЬ: температура и ощущается как
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  _weather!.isDay ? Icons.wb_sunny : Icons.nightlight_round,
                  color: _weather!.isDay ? Colors.amber : Colors.indigo[300],
                  size: ResponsiveUtils.getIconSize(context, baseSize: 30),
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTemperature(_weather!.temperature),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 22, maxSize: 24),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: ResponsiveConstants.spacingXS),
                    Text(
                      '${localizations.translate('feels_like_short')}: ${_formatTemperature(_weather!.feelsLike)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConstants.spacingM),
          // НИЖНЯЯ ЧАСТЬ: сетка с данными
          _buildWeatherGrid(localizations),
        ],
      ),
    );
  }

  Widget _buildWeatherGrid(AppLocalizations localizations) {
    return Column(
      children: [
        ResponsiveUtils.isSmallScreen(context)
            ? Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.air,
                    label: localizations.translate('wind_short'),
                    value: '${_weather!.windDirection}\n${_formatWindSpeed(_weather!.windSpeed)}',
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.water_drop,
                    label: localizations.translate('humidity_short'),
                    value: '${_weather!.humidity}%',
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.speed,
                    label: localizations.translate('pressure_short'),
                    value: _formatPressure(_weather!.pressure),
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.cloud,
                    label: localizations.translate('cloudiness_short'),
                    value: '${_weather!.cloudCover}%',
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.wb_twilight,
                    label: localizations.translate('sunrise'),
                    value: _weather!.sunrise,
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: _buildWeatherInfoItem(
                    icon: Icons.nights_stay,
                    label: localizations.translate('sunset'),
                    value: _weather!.sunset,
                  ),
                ),
              ],
            ),
          ],
        )
            : Row( // На больших экранах - горизонтально
          children: [
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.air,
                label: localizations.translate('wind_short'),
                value: '${_weather!.windDirection}\n${_formatWindSpeed(_weather!.windSpeed)}',
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.water_drop,
                label: localizations.translate('humidity_short'),
                value: '${_weather!.humidity}%',
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingM),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.speed,
                label: localizations.translate('pressure_short'),
                value: _formatPressure(_weather!.pressure),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveConstants.spacingM),
        // Вторая строка для больших экранов
        if (!ResponsiveUtils.isSmallScreen(context))
          Row(
            children: [
              Expanded(
                child: _buildWeatherInfoItem(
                  icon: Icons.cloud,
                  label: localizations.translate('cloudiness_short'),
                  value: '${_weather!.cloudCover}%',
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              Expanded(
                child: _buildWeatherInfoItem(
                  icon: Icons.wb_twilight,
                  label: localizations.translate('sunrise'),
                  value: _weather!.sunrise,
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              Expanded(
                child: _buildWeatherInfoItem(
                  icon: Icons.nights_stay,
                  label: localizations.translate('sunset'),
                  value: _weather!.sunset,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withValues(alpha: 0.8),
            size: ResponsiveUtils.getIconSize(context, baseSize: 20),
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 9, maxSize: 11),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: ResponsiveConstants.spacingXS),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 10, maxSize: 12),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTackleField(AppLocalizations localizations) {
    return TextFormField(
      controller: _tackleController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
      ),
      decoration: InputDecoration(
        fillColor: const Color(0xFF12332E),
        filled: true,
        hintText: localizations.translate('describe_tackle'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
      ),
      maxLines: 3,
    );
  }

  Widget _buildNotesField(AppLocalizations localizations) {
    return TextFormField(
      controller: _notesController,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
      ),
      decoration: InputDecoration(
        fillColor: const Color(0xFF12332E),
        filled: true,
        hintText: localizations.translate('notes_desc'),
        hintStyle: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.5),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
      ),
      maxLines: 5,
    );
  }

  Widget _buildPhotoButtons(AppLocalizations localizations) {
    return ResponsiveUtils.isSmallScreen(context)
        ? Column( // На маленьких экранах - вертикально
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.photo_library,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('gallery'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
              ),
            ),
            onPressed: _pickImages,
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.camera_alt,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('camera'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
              ),
            ),
            onPressed: _takePhoto,
          ),
        ),
      ],
    )
        : Row( // На больших экранах - горизонтально
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.photo_library,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('gallery'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
              ),
            ),
            onPressed: _pickImages,
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingM),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.camera_alt,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              localizations.translate('camera'),
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
              ),
            ),
            onPressed: _takePhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildExistingPhotos(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveConstants.spacingM),
        _buildSectionHeader(localizations.translate('existing_photos')),
        SizedBox(
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 100,
            tablet: 120,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingPhotoUrls.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(_existingPhotoUrls[index], index, true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewPhotos(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveConstants.spacingM),
        _buildSectionHeader(localizations.translate('new_photos')),
        SizedBox(
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 100,
            tablet: 120,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _newPhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(_newPhotos[index].path, index, false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddBiteRecordButton(AppLocalizations localizations) {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.add_circle_outline,
        color: AppConstants.textColor,
        size: ResponsiveUtils.getIconSize(context),
      ),
      label: Text(
        localizations.translate('add_bite_record'),
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF12332E),
        minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConstants.spacingM,
          horizontal: ResponsiveConstants.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
      ),
      onPressed: _addBiteRecord,
    );
  }

  Widget _buildBottomButtons(AppLocalizations localizations) {
    return ResponsiveUtils.isSmallScreen(context)
        ? Column( // На маленьких экранах - вертикально
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showCancelConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusXL),
                ),
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
            onPressed: _isSaving ? null : _saveNote,
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
              disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
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
        : Row( // На больших экранах - горизонтально
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _showCancelConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusXL),
                ),
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
            onPressed: _isSaving ? null : _saveNote,
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
              disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
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

  Widget _buildBiteRecordsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveConstants.spacingM),
        // ✅ ГРАФИК ПОКЛЕВОК С ФИЛЬТРАЦИЕЙ ПО ДНЮ
        _buildBiteRecordsTimeline(localizations),
        SizedBox(height: ResponsiveConstants.spacingM),
        // Список поклевок
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _biteRecords.length,
          itemBuilder: (context, index) {
            final record = _biteRecords[index];
            return Card(
              margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingS),
              color: const Color(0xFF12332E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(ResponsiveConstants.spacingM),
                minTileHeight: ResponsiveConstants.minTouchTarget,
                title: Text(
                  record.fishType.isEmpty
                      ? '${localizations.translate('bite_occurred')} #${index + 1}'
                      : record.fishType,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ ПОКАЗЫВАЕМ ДЕНЬ ПОКЛЕВКИ
                    if (_isMultiDay && _tripDays > 1)
                      Text(
                        '${localizations.translate('day_fishing')} ${record.dayIndex + 1}',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      '${localizations.translate('bite_time')}: ${DateFormat('HH:mm').format(record.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                      ),
                    ),
                    if (record.weight > 0)
                      Text(
                        '${localizations.translate('weight')}: ${record.weight} ${localizations.translate('kg')}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                        ),
                      ),
                    if (record.notes.isNotEmpty)
                      Text(
                        '${localizations.translate('notes')}: ${record.notes}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: ResponsiveUtils.isSmallScreen(context)
                    ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppConstants.textColor,
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppConstants.textColor),
                          SizedBox(width: ResponsiveConstants.spacingS),
                          Text(
                            localizations.translate('edit'),
                            style: TextStyle(color: AppConstants.textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: ResponsiveConstants.spacingS),
                          Text(
                            localizations.translate('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editBiteRecord(index);
                    } else if (value == 'delete') {
                      setState(() {
                        _biteRecords.removeAt(index);
                      });
                    }
                  },
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppConstants.textColor,
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      onPressed: () => _editBiteRecord(index),
                      constraints: BoxConstraints.tightFor(
                        width: ResponsiveConstants.minTouchTarget,
                        height: ResponsiveConstants.minTouchTarget,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _biteRecords.removeAt(index);
                        });
                      },
                      constraints: BoxConstraints.tightFor(
                        width: ResponsiveConstants.minTouchTarget,
                        height: ResponsiveConstants.minTouchTarget,
                      ),
                    ),
                  ],
                ),
                onTap: () => _editBiteRecord(index),
              ),
            );
          },
        ),
      ],
    );
  }

  // ✅ ОБНОВЛЕННЫЙ МЕТОД С ФИЛЬТРАЦИЕЙ ПО ДНЮ
  Widget _buildBiteRecordsTimeline(AppLocalizations localizations) {
    if (_biteRecords.isEmpty) return const SizedBox();

    // ✅ ФИЛЬТРУЕМ ПОКЛЕВКИ ПО ВЫБРАННОМУ ДНЮ
    final filteredBiteRecords = _biteRecords.where((record) {
      return record.dayIndex == _selectedDayIndex;
    }).toList();

    if (filteredBiteRecords.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('bite_chart'),
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          Container(
            height: 60,
            padding: EdgeInsets.all(ResponsiveConstants.spacingM),
            decoration: BoxDecoration(
              color: const Color(0xFF12332E),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
              ),
            ),
            child: Center(
              child: Text(
                _isMultiDay && _tripDays > 1
                    ? '${localizations.translate('no_bites_for_day')} ${_selectedDayIndex + 1}'
                    : localizations.translate('no_bites_yet'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingS),
          child: Text(
            _isMultiDay && _tripDays > 1
                ? '${localizations.translate('bite_chart')} - ${_getDayName(_selectedDayIndex)}'
                : localizations.translate('bite_chart'),
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 100,
            tablet: 120,
          ),
          padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingS),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width - (ResponsiveUtils.getHorizontalPadding(context) * 4),
                    40,
                  ),
                  painter: _BiteRecordsTimelinePainter(
                    biteRecords: filteredBiteRecords, // ✅ ПЕРЕДАЕМ ОТФИЛЬТРОВАННЫЕ ПОКЛЕВКИ
                    divisions: divisions,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConstants.spacingXS),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < hoursInDay; i += 3)
                      Text(
                        '$i:00',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.8),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 8, maxSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Построитель карточки фото
  Widget _buildPhotoItem(String source, int index, bool isExisting) {
    final photoSize = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 100.0,
      tablet: 120.0,
    );

    return Stack(
      children: [
        Container(
          width: photoSize,
          height: photoSize,
          margin: EdgeInsets.only(right: ResponsiveConstants.spacingS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusS),
            ),
            image: DecorationImage(
              image: isExisting ? NetworkImage(source) as ImageProvider : FileImage(File(source)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: ResponsiveConstants.spacingXS,
          right: ResponsiveConstants.spacingS + ResponsiveConstants.spacingXS,
          child: GestureDetector(
            onTap: () => isExisting ? _removeExistingPhoto(index) : _removeNewPhoto(index),
            child: Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingXS),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context, baseSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Внутренний класс для рисования графика поклевок (ИСПРАВЛЕН)
class _BiteRecordsTimelinePainter extends CustomPainter {
  final List<BiteRecord> biteRecords;
  final int divisions;

  _BiteRecordsTimelinePainter({
    required this.biteRecords,
    required this.divisions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Рисуем горизонтальную линию
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Рисуем деления
    final divisionWidth = size.width / divisions;
    for (int i = 0; i <= divisions; i++) {
      final x = i * divisionWidth;
      final height = i % 2 == 0 ? 10.0 : 5.0;

      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }

    // Рисуем точки поклевок
    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      final bool isCaught = record.fishType.isNotEmpty && record.weight > 0;

      // Используем разные цвета для пойманных рыб и просто поклевок
      final Color dotColor = isCaught ? Colors.green : Colors.red;

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      // Рисуем кружок для поклевки
      canvas.drawCircle(Offset(position, size.height / 2), 7, dotPaint);

      // Для пойманных рыб рисуем обводку, размер которой зависит от веса
      if (isCaught) {
        final weightPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        // Максимальный вес для отображения (15 кг)
        const maxWeight = 15.0;
        // Минимальный и максимальный радиус
        const minRadius = 8.0;
        const maxRadius = 18.0;

        final weight = record.weight.clamp(0.1, maxWeight);
        final radius = minRadius + (weight / maxWeight) * (maxRadius - minRadius);

        canvas.drawCircle(
          Offset(position, size.height / 2),
          radius,
          weightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}