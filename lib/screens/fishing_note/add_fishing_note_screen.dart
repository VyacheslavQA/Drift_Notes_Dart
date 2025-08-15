// Путь: lib/screens/fishing_note/add_fishing_note_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../services/firebase/firebase_service.dart';
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
import '../../services/subscription/subscription_service.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../constants/subscription_constants.dart';
import '../subscription/paywall_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/calendar_event_service.dart';
import '../../services/photo/photo_service.dart'; // ДОБАВИТЬ ЭТУ СТРОКУ
import '../../services/firebase/firebase_analytics_service.dart';
import '../../widgets/bait_program_selector.dart';


class AddFishingNoteScreen extends StatefulWidget {
  final String? fishingType;
  final DateTime? initialDate;

  const AddFishingNoteScreen({super.key, this.fishingType, this.initialDate});

  @override
  State<AddFishingNoteScreen> createState() => _AddFishingNoteScreenState();
}

class _AddFishingNoteScreenState extends State<AddFishingNoteScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _tackleController = TextEditingController();
  final _notesController = TextEditingController();

  // ✅ ОПТИМИЗАЦИЯ 1: ЛЕНИВАЯ ЗАГРУЗКА СЕРВИСОВ (экономия ~7MB)
  FirebaseService? _firebaseService;
  WeatherService? _weatherService;
  AIBitePredictionService? _aiService;
  SubscriptionService? _subscriptionService;
  FishingNoteRepository? _repository;
  PhotoService? _photoService;


  final _weatherSettings = WeatherSettingsService();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isMultiDay = false;
  int _tripDays = 1;

  final List<File> _selectedPhotos = [];
  bool _isSaving = false;

  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _hasLocation = false;

  FishingWeather? _weather;
  bool _isLoadingWeather = false;

  AIBitePrediction? _aiPrediction;
  bool _isLoadingAI = false;

  final List<BiteRecord> _biteRecords = [];
  List<String> _selectedBaitProgramIds = [];
  String _selectedFishingType = '';

  // ✅ НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ СЕЛЕКТОРА ДНЯ
  int _selectedDayIndex = 0;
  final List<DateTime> _fishingDays = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _hasUnsavedChanges = false;
  bool _showAIDetails = false;

  @override
  void initState() {
    super.initState();
    _selectedFishingType = widget.fishingType ?? AppConstants.fishingTypes.first;
    _startDate = widget.initialDate ?? DateTime.now();
    _endDate = widget.initialDate ?? DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: ResponsiveConstants.animationNormal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _tripDays = 1;

    // ✅ ИНИЦИАЛИЗАЦИЯ ДНЕЙ РЫБАЛКИ
    _initializeFishingDays();

    _locationController.addListener(_markAsChanged);
    _tackleController.addListener(_markAsChanged);
    _notesController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tackleController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
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
    _markAsChanged();
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
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }

        _isMultiDay = !DateUtils.isSameDay(_startDate, _endDate);
        _updateTripDays();
      });
    }
  }

  // ✅ ОПТИМИЗАЦИЯ 2: СЖАТИЕ ФОТО (экономия ~27MB на 3 фото)
  Future<File> _createPermanentFile(Uint8List bytes) async {
    _photoService ??= PhotoService();
    return await _photoService!.savePermanentPhoto(bytes);
  }

  Future<void> _addCompressedPhoto(XFile pickedFile) async {
    try {
      _photoService ??= PhotoService();

      // Умное сжатие и сохранение в постоянную папку
      final permanentFile = await _photoService!.processAndSavePhoto(pickedFile);

      setState(() {
        _selectedPhotos.add(permanentFile);
      });
      _markAsChanged();

      // Показываем информацию о сжатии
      final originalBytes = await pickedFile.readAsBytes();
      final compressedBytes = await permanentFile.readAsBytes();
      final originalSizeMB = (originalBytes.length / (1024 * 1024)).toStringAsFixed(1);
      final compressedSizeMB = (compressedBytes.length / (1024 * 1024)).toStringAsFixed(1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Фото добавлено: $originalSizeMB MB → $compressedSizeMB MB'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_compressing_photo')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final localizations = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 70);

      if (pickedFiles.isNotEmpty && mounted) {
        for (final pickedFile in pickedFiles) {
          await _addCompressedPhoto(pickedFile);
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
        imageQuality: 70,
      );

      if (pickedFile != null && mounted) {
        await _addCompressedPhoto(pickedFile);
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

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    _markAsChanged();
  }

  Future<void> _selectLocation() async {
    try {
      // 1. Останавливаем анимации
      _animationController.stop();

      // 2. Очищаем кеши
      setState(() {
        _weather = null;
        _aiPrediction = null;
      });

      // 3. Принудительная сборка мусора
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. ТЕПЕРЬ безопасно открываем УНИВЕРСАЛЬНУЮ карту
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniversalMapScreen(
            mode: MapMode.selectLocation,
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
        });
        _markAsChanged();
      }
    } catch (e) {
      // 5. Если карта крашится - показываем fallback
      if (mounted) {
        _showLocationFallback();
      }
    } finally {
      // 6. Восстанавливаем анимации
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  // ✅ ОПТИМИЗАЦИЯ 5: FALLBACK ДЛЯ СЛАБЫХ УСТРОЙСТВ
  void _showLocationFallback() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('select_fishing_location'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GPS координаты
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(localizations.translate('use_current_location')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _useCurrentLocation();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Сохраненные места из других заметок
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: Text(localizations.translate('use_saved_location')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12332E),
                  foregroundColor: AppConstants.textColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showSavedLocations();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final localizations = AppLocalizations.of(context);

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _hasLocation = true;
      });
      _markAsChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('location_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_getting_location')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSavedLocations() {
    final localizations = AppLocalizations.of(context);

    // Простой пример - можно расширить для загрузки реальных сохраненных мест
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('saved_locations'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Text(
          localizations.translate('no_saved_locations'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('ok'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ОПТИМИЗАЦИЯ 1: ЛЕНИВАЯ ЗАГРУЗКА СЕРВИСОВ
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
      // Создаем сервисы только когда нужно
      _weatherService ??= WeatherService();
      _aiService ??= AIBitePredictionService();

      final weatherData = await _weatherService!.getWeatherForLocation(
        _latitude,
        _longitude,
        context,
      );

      if (mounted) {
        setState(() {
          _weather = weatherData;
          _isLoadingWeather = false;
        });
        _markAsChanged();
      }

      try {
        final aiResult = await _aiService!.getPredictionForFishingType(
          fishingType: _selectedFishingType,
          latitude: _latitude,
          longitude: _longitude,
          date: _startDate,
          l10n: AppLocalizations.of(context),
        );

        if (mounted) {
          setState(() {
            _aiPrediction = aiResult;
            _isLoadingAI = false;
          });
          _markAsChanged();
        }
      } catch (aiError) {
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
            content: Text('${AppLocalizations.of(context).translate('error_loading')}: $e'),
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

    if (result != null && result is BiteRecord && mounted) {

      setState(() {
        _biteRecords.add(result);
      });
      _markAsChanged();
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
      _markAsChanged();
    }
  }


  Future<bool> _checkLimitsBeforeCreating() async {
    try {
      // Создаем сервис только когда нужно
      _subscriptionService ??= SubscriptionService();

      final canCreate = await _subscriptionService!.canCreateContentOffline(ContentType.fishingNotes);

      if (!canCreate) {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaywallScreen(
                contentType: 'fishing_notes',
                blockedFeature: 'Заметки рыбалки',
              ),
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      return true;
    }
  }

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

    final canCreate = await _checkLimitsBeforeCreating();
    if (!canCreate) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ✅ ИСПРАВЛЕНИЕ: Создаем Repository только когда нужно
      _repository ??= FishingNoteRepository();
      _firebaseService ??= FirebaseService();

      final userId = _firebaseService!.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // ✅ ИСПРАВЛЕНИЕ: Создаем FishingNoteModel из данных формы
      final model = _createFishingNoteModel(userId, localizations);

      // ✅ ИСПРАВЛЕНИЕ: Repository сам решает онлайн/офлайн сохранение
      final noteId = await _repository!.addFishingNote(model, _selectedPhotos);
      ;
      if (mounted) {
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.incrementUsage(ContentType.fishingNotes);
          await subscriptionProvider.refreshUsageData();
        } catch (e) {
          // Handle error
        }

        final isOnline = await NetworkUtils.isNetworkAvailable();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.offline_bolt,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnline
                        ? localizations.translate('note_saved_successfully')
                        : 'Заметка сохранена офлайн и будет синхронизирована при подключении к сети',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        _hasUnsavedChanges = false;

        // Отслеживание создания заметки (с отдельной обработкой ошибок)
        try {
          print('🧪 ТЕСТ: Готовимся вызвать trackFishingNoteCreated');
          await FirebaseAnalyticsService().trackFishingNoteCreated(
            fishingType: _selectedFishingType,
            isMultiDay: _isMultiDay,
            photosCount: _selectedPhotos.length,
            biteRecordsCount: _biteRecords.length,
            hasWeather: _weather != null,
            hasAIPrediction: _aiPrediction != null,
            hasLocation: _hasLocation,
            tripDays: _tripDays,
          );
          print('🧪 ТЕСТ: trackFishingNoteCreated завершен');
        } catch (analyticsError) {
          print('❌ Ошибка аналитики: $analyticsError');
        }
        Navigator.pop(context, true);


      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('Пользователь не авторизован')) {
          errorMessage = localizations.translate('user_not_authorized');
        } else if (e.toString().contains('No internet') ||
            e.toString().contains('network')) {
          errorMessage = localizations.translate('no_internet_connection');
        } else {
          errorMessage = localizations.translate('error_saving_note');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: localizations.translate('retry'),
              textColor: Colors.white,
              onPressed: _saveNote,
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

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД:
  FishingNoteModel _createFishingNoteModel(String userId, AppLocalizations localizations) {
    // AI предсказание в правильном формате
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
    }

    // Погода в правильном формате
    FishingWeather? weather;
    if (_weather != null) {
      weather = FishingWeather(
        temperature: _weather!.temperature,
        feelsLike: _weather!.feelsLike,
        humidity: _weather!.humidity,
        pressure: _weather!.pressure,
        windSpeed: _weather!.windSpeed,
        windDirection: _weather!.windDirection,
        weatherDescription: _weather!.weatherDescription,
        cloudCover: _weather!.cloudCover,
        sunrise: _weather!.sunrise,
        sunset: _weather!.sunset,
        isDay: _weather!.isDay,
        observationTime: _weather!.observationTime,
        moonPhase: '', // Пустое значение для совместимости
      );
    }

    // Поклевки в правильном формате
    List<BiteRecord> biteRecords = _biteRecords.map((record) => BiteRecord(
      id: record.id,
      time: record.time,
      fishType: record.fishType,
      weight: record.weight,
      length: record.length,
      notes: record.notes,
      photoUrls: record.photoUrls,
      dayIndex: record.dayIndex,
      spotIndex: record.spotIndex,
    )).toList();

    return FishingNoteModel(
      id: const Uuid().v4(),
      userId: userId,
      location: _locationController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      date: _startDate,
      endDate: _isMultiDay ? _endDate : null,
      isMultiDay: _isMultiDay,
      tackle: _tackleController.text.trim(),
      notes: _notesController.text.trim(),
      fishingType: _selectedFishingType,
      weather: weather,
      biteRecords: biteRecords,
      aiPrediction: aiPredictionMap,
      photoUrls: const [], // ✅ ИСПРАВЛЕНИЕ: Пустой список! Repository сам добавит фото
      mapMarkers: const [],
      title: _locationController.text.trim(),

      // Поля которые есть только в старой модели (значения по умолчанию)
      dayBiteMaps: const {},
      fishingSpots: const ['Основная точка'],
      coverPhotoUrl: '',
      coverCropSettings: null,
      reminderEnabled: false,
      reminderType: ReminderType.none,
      reminderTime: null,
      baitProgramIds: _selectedBaitProgramIds,
    );
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
          backgroundColor: AppConstants.cardColor,
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
                padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
                child: Text(
                  localizations.translate('select_fishing_type'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.fishingTypes.length,
                  itemBuilder: (context, index) {
                    final typeKey = AppConstants.fishingTypes[index];
                    return ListTile(
                      title: Text(
                        localizations.translate(typeKey),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
                      ),
                      leading: FishingTypeIcons.getIconWidget(typeKey),
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
                          _aiPrediction = null;
                        });
                        _markAsChanged();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localizations.translate('cancel'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
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

  // Получение цвета по скору
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  // Получение текста уровня активности
  String _getActivityLevelText(ActivityLevel level, AppLocalizations localizations) {
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

  // Форматирование температуры
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

  // Форматирование скорости ветра
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

  // Форматирование давления
  String _formatPressure(double hpa) {
    final unit = _weatherSettings.pressureUnit;
    final calibration = _weatherSettings.barometerCalibration;
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
            localizations.translate('new_note'),
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
                  // Тип рыбалки
                  _buildSectionHeader(localizations.translate('fishing_type')),
                  _buildFishingTypeSelector(localizations),
                  SizedBox(height: ResponsiveConstants.spacingL),

                  // Место рыбалки
                  _buildSectionHeader('${localizations.translate('fishing_location')}*'),
                  _buildLocationField(localizations),
                  SizedBox(height: ResponsiveConstants.spacingL),

                  // Даты рыбалки
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
                  if (_aiPrediction != null) _buildAIAnalysisCard(localizations),
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
                  if (_selectedPhotos.isNotEmpty) _buildPhotosSection(localizations),
                  SizedBox(height: ResponsiveConstants.spacingL),

                  // Прикормочные программы
                  _buildSectionHeader(localizations.translate('bait_programs')),
                  _buildBaitProgramsSection(localizations),
                  SizedBox(height: ResponsiveConstants.spacingL),

                  // Записи о поклевках
                  _buildSectionHeader(localizations.translate('bite_records')),
                  _buildAddBiteRecordButton(localizations),
                  if (_biteRecords.isNotEmpty) _buildBiteRecordsSection(localizations),
                  SizedBox(height: ResponsiveConstants.spacingXXL),

                  // Кнопки
                  _buildBottomButtons(localizations),
                  SizedBox(height: ResponsiveConstants.spacingXXL),
                ],
              ),
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
            ? Column(
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
            : Row(
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
                Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                    fontWeight: FontWeight.w500,
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
                    ),
                    Text(
                      '${localizations.translate('feels_like_short')}: ${_formatTemperature(_weather!.feelsLike)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConstants.spacingM),
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
            : Column(
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
            SizedBox(height: ResponsiveConstants.spacingS),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard(AppLocalizations localizations) {
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
          // ✅ КОМПАКТНАЯ ВЕРСИЯ (всегда видна)
          Row(
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
                    ),
                    Text(
                      _getActivityLevelText(_aiPrediction!.activityLevel, localizations),
                      style: TextStyle(
                        color: _getScoreColor(_aiPrediction!.overallScore),
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
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
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingS),
              IconButton(
                icon: Icon(
                  _showAIDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppConstants.textColor,
                ),
                onPressed: () {
                  setState(() {
                    _showAIDetails = !_showAIDetails;
                  });
                },
              ),
            ],
          ),

          // ✅ ПОДРОБНОСТИ (показываются по условию)
          if (_showAIDetails) ...[
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              _aiPrediction!.recommendation,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                height: ResponsiveConstants.lineHeightNormal,
              ),
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
              ),
              SizedBox(height: ResponsiveConstants.spacingS),
              ...(_aiPrediction!.tips.take(2).map(
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
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
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
        ? Column(
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
        : Row(
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

  Widget _buildPhotosSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveConstants.spacingM),
        SizedBox(
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 100,
            tablet: 120,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedPhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoItem(int index) {
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
              image: FileImage(_selectedPhotos[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: ResponsiveConstants.spacingXS,
          right: ResponsiveConstants.spacingS + ResponsiveConstants.spacingXS,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
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

  Widget _buildBiteRecordsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveConstants.spacingM),
        // ✅ ГРАФИК ПОКЛЕВОК С ФИЛЬТРАЦИЕЙ ПО ДНЮ
        if (_biteRecords.isNotEmpty && _hasLocation)
          _buildBiteRecordsTimeline(localizations),
        if (_biteRecords.isNotEmpty && _hasLocation)
          SizedBox(height: ResponsiveConstants.spacingM),
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
                title: Text(
                  record.fishType.isEmpty
                      ? '${localizations.translate('bite_occurred')} #${index + 1}'
                      : record.fishType,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppConstants.textColor,
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      onPressed: () => _editBiteRecord(index),
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
                        _markAsChanged();
                      },
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

    const hoursInDay = 24;
    const divisions = 48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ ЗАГОЛОВОК С УКАЗАНИЕМ ДНЯ
        Text(
          _isMultiDay && _tripDays > 1
              ? '${localizations.translate('bite_chart')} - ${_getDayName(_selectedDayIndex)}'
              : localizations.translate('bite_chart'),
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
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

  Widget _buildBaitProgramsSection(AppLocalizations localizations) {
    return BaitProgramSelector(
      selectedProgramIds: _selectedBaitProgramIds,
      onProgramsChanged: (List<String> programIds) {
        // ✅ ДОБАВИТЬ ЭТИ СТРОКИ ДЛЯ ОТЛАДКИ

        setState(() {
          _selectedBaitProgramIds = programIds;
        });

        _markAsChanged();
      },
      maxSelection: 5,
    );
  }
}
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

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

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

    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      final bool isCaught = record.fishType.isNotEmpty && record.weight > 0;
      final Color dotColor = isCaught ? Colors.green : Colors.red;

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(position, size.height / 2), 7, dotPaint);

      if (isCaught) {
        final weightPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        const maxWeight = 15.0;
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