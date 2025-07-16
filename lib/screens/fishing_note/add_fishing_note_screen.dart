// Путь: lib/screens/fishing_note/add_fishing_note_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/weather/weather_service.dart';
import '../../utils/network_utils.dart';
import '../../utils/date_formatter.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import '../map/map_location_screen.dart';
import 'bite_record_screen.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../services/weather_settings_service.dart';
// ✅ ИСПРАВЛЕНО: правильные импорты для новой системы лимитов
import '../../services/subscription/subscription_service.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../constants/subscription_constants.dart';
import '../../models/offline_usage_result.dart';
import '../subscription/paywall_screen.dart';
// ✅ ИСПРАВЛЕНО: Добавляем импорты для Provider
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';

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

  final _firebaseService = FirebaseService();
  final _weatherService = WeatherService();
  final _aiService = AIBitePredictionService();
  final _weatherSettings = WeatherSettingsService();

  // ✅ ИСПРАВЛЕНО: правильные сервисы для новой системы лимитов
  final _subscriptionService = SubscriptionService();
  final _offlineStorage = OfflineStorageService();

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
  String _selectedFishingType = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedFishingType = widget.fishingType ?? AppConstants.fishingTypes.first;
    _startDate = widget.initialDate ?? DateTime.now();
    _endDate = widget.initialDate ?? DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _tripDays = 1;

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

  void _updateTripDays() {
    if (_isMultiDay) {
      setState(() {
        _tripDays = _endDate.difference(_startDate).inDays + 1;
      });
    } else {
      setState(() {
        _tripDays = 1;
      });
    }
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

  Future<void> _pickImages() async {
    final localizations = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 70);

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedPhotos.addAll(
            pickedFiles.map((xFile) => File(xFile.path)).toList(),
          );
        });
        _markAsChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('error_selecting_images'),
            ),
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
        setState(() {
          _selectedPhotos.add(File(pickedFile.path));
        });
        _markAsChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('error_taking_photo'),
            ),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationScreen(
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
        _weather = null;
        _aiPrediction = null;
      });
      _markAsChanged();
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

    // Сначала проверяем подключение к интернету
    final hasInternet = await NetworkUtils.isNetworkAvailable();

    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _isLoadingAI = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('no_internet_connection')),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: localizations.translate('retry'),
              textColor: Colors.white,
              onPressed: _fetchWeatherAndAI,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    try {
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
        _markAsChanged();
      }

      try {
        final aiResult = await _aiService.getPredictionForFishingType(
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('ai_analysis_failed')),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: localizations.translate('retry'),
                textColor: Colors.white,
                onPressed: _fetchWeatherAndAI,
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _isLoadingAI = false;
        });

        String errorMessage;
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('ClientException')) {
          errorMessage = localizations.translate('weather_service_unavailable');
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('TimeoutException')) {
          errorMessage = localizations.translate('request_timeout');
        } else if (e.toString().contains('HttpException') ||
            e.toString().contains('400') ||
            e.toString().contains('401') ||
            e.toString().contains('403') ||
            e.toString().contains('404') ||
            e.toString().contains('500')) {
          errorMessage = localizations.translate('weather_service_error');
        } else {
          errorMessage = localizations.translate('weather_loading_failed');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: localizations.translate('retry'),
              textColor: Colors.white,
              onPressed: _fetchWeatherAndAI,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
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

  // ✅ ИСПРАВЛЕНО: Правильная проверка лимитов с использованием новой системы
  Future<bool> _checkLimitsBeforeCreating() async {
    final localizations = AppLocalizations.of(context);

    try {
      debugPrint('🔍 Проверка лимитов перед созданием заметки (новая система)...');

      // ✅ ИСПРАВЛЕНО: Используем новую систему с правильным подсчетом
      final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

      debugPrint('📊 Результат проверки лимитов: canCreate=$canCreate');

      if (!canCreate) {
        debugPrint('❌ Лимит достигнут - показываем Paywall');

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

      debugPrint('✅ Проверка лимитов пройдена - можно создавать');
      return true;

    } catch (e) {
      debugPrint('❌ Ошибка при проверке лимитов: $e');

      // ✅ ИСПРАВЛЕНО: При ошибке проверки лимитов - разрешаем создание как fallback
      debugPrint('🔄 Ошибка проверки лимитов - разрешаем создание как fallback');
      return true;
    }
  }

  // ✅ ИСПРАВЛЕНО: Правильный порядок операций и обработка офлайн режима
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

    // ✅ ИСПРАВЛЕНО: Проверяем лимиты ПЕРЕД началом сохранения
    final canCreate = await _checkLimitsBeforeCreating();
    if (!canCreate) {
      debugPrint('❌ Создание заметки отменено - лимиты не пройдены');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Получаем userId в начале
      final userId = _firebaseService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Проверка подключения к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Статус сети: ${isOnline ? "онлайн" : "офлайн"}');

      // Подготовка данных для ИИ-предсказания
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

      // Подготовка данных погоды
      Map<String, dynamic>? weatherMap;
      if (_weather != null) {
        weatherMap = {
          'temperature': _weather!.temperature,
          'feelsLike': _weather!.feelsLike,
          'humidity': _weather!.humidity,
          'pressure': _weather!.pressure,
          'windSpeed': _weather!.windSpeed,
          'windDirection': _weather!.windDirection,
          'cloudCover': _weather!.cloudCover,
          'sunrise': _weather!.sunrise,
          'sunset': _weather!.sunset,
          'isDay': _weather!.isDay,
          'observationTime': _weather!.observationTime,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }

      // Подготовка данных поклевок
      List<Map<String, dynamic>> biteRecordsData = _biteRecords.map((record) => {
        'id': record.id,
        'time': record.time.millisecondsSinceEpoch,
        'fishType': record.fishType,
        'weight': record.weight,
        'length': record.length,
        'notes': record.notes,
        'photoUrls': record.photoUrls,
      }).toList();

      // Подготовка данных заметки
      final noteData = {
        'id': const Uuid().v4(),
        'userId': userId,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'date': _startDate.millisecondsSinceEpoch,
        'endDate': _isMultiDay ? _endDate.millisecondsSinceEpoch : null,
        'isMultiDay': _isMultiDay,
        'tackle': _tackleController.text.trim(),
        'notes': _notesController.text.trim(),
        'fishingType': _selectedFishingType,
        'weather': weatherMap,
        'biteRecords': biteRecordsData,
        'aiPrediction': aiPredictionMap,
        'photoUrls': <String>[], // Будет заполнено после загрузки фотографий
        'mapMarkers': <Map<String, dynamic>>[], // Пустой список маркеров
        'isOffline': !isOnline, // Помечаем как офлайн запись
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      bool saveSuccessful = false;

      if (isOnline) {
        // ОНЛАЙН СОХРАНЕНИЕ
        debugPrint('💾 Сохранение заметки онлайн...');

        // Загружаем фотографии и обновляем URLs
        if (_selectedPhotos.isNotEmpty) {
          final List<String> photoUrls = [];

          for (int i = 0; i < _selectedPhotos.length; i++) {
            final file = _selectedPhotos[i];
            final fileName = '${noteData['id']}_photo_$i.jpg';
            final path = 'fishing_notes/$userId/$fileName';

            try {
              final bytes = await file.readAsBytes();
              final photoUrl = await _firebaseService.uploadImage(path, bytes);
              photoUrls.add(photoUrl);
            } catch (e) {
              debugPrint('❌ Ошибка загрузки фото $i: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${localizations.translate('error_uploading_photo')} ${i + 1}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

          noteData['photoUrls'] = photoUrls;
        }

        // ✅ ИСПРАВЛЕНО: Сохраняем заметку в Firebase
        await _firebaseService.addFishingNoteNew(noteData);

        debugPrint('✅ Заметка сохранена онлайн в Firebase');
        saveSuccessful = true;

      } else {
        // ОФЛАЙН СОХРАНЕНИЕ
        debugPrint('📱 Сохранение заметки офлайн...');

        // Сохраняем фотографии локально
        if (_selectedPhotos.isNotEmpty) {
          final List<String> localPhotoPaths = [];

          for (int i = 0; i < _selectedPhotos.length; i++) {
            final file = _selectedPhotos[i];
            try {
              localPhotoPaths.add(file.path);
            } catch (e) {
              debugPrint('❌ Ошибка подготовки фото офлайн $i: $e');
            }
          }

          noteData['photoUrls'] = localPhotoPaths;
          noteData['localPhotoPaths'] = localPhotoPaths;
        }

        // ✅ ИСПРАВЛЕНО: Сохраняем заметку в локальное хранилище
        await _offlineStorage.saveOfflineFishingNote(noteData);

        debugPrint('✅ Заметка сохранена офлайн');
        saveSuccessful = true;
      }

      // ✅ ИСПРАВЛЕНО: Обновляем Provider ПОСЛЕ успешного сохранения
      if (mounted && saveSuccessful) {
        try {
          // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Сначала обновляем локальный счетчик Provider
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.incrementUsage(ContentType.fishingNotes);

          // Обновляем полные данные Provider
          await subscriptionProvider.refreshUsageData();

          debugPrint('✅ SubscriptionProvider обновлен после создания заметки');
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
          // Не прерываем выполнение, заметка уже создана
        }

        // ✅ ИСПРАВЛЕНО: Убираем увеличение счетчика Firebase
        // Теперь мы считаем реальные заметки, не счетчики
        debugPrint('✅ Система лимитов обновлена без увеличения счетчиков Firebase');

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

        // ✅ ИСПРАВЛЕНО: Возвращаем результат после успешного сохранения
        debugPrint('🎯 Возвращаем результат true - заметка успешно создана');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении заметки: $e');

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
            duration: const Duration(seconds: 5),
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
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('cancel_creation'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('cancel_creation_confirmation'),
            style: TextStyle(color: AppConstants.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations.translate('no'),
                style: TextStyle(color: AppConstants.textColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations.translate('yes_cancel'),
                style: TextStyle(color: Colors.redAccent),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Text(
                  localizations.translate('select_fishing_type'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: AppConstants.fishingTypes.length,
                  itemBuilder: (context, index) {
                    final typeKey = AppConstants.fishingTypes[index];
                    return ListTile(
                      title: Text(
                        localizations.translate(typeKey),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                      leading: FishingTypeIcons.getIconWidget(typeKey),
                      trailing: _selectedFishingType == typeKey
                          ? Icon(
                        Icons.check_circle,
                        color: AppConstants.primaryColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localizations.translate('cancel'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
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
                icon: Icon(Icons.check, color: AppConstants.textColor),
                onPressed: _saveNote,
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.textColor,
                    ),
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
                  InkWell(
                    onTap: _showFishingTypeDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12332E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: FishingTypeIcons.getIconWidget(
                              _selectedFishingType,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.translate(_selectedFishingType),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: AppConstants.textColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Место рыбалки
                  _buildSectionHeader(
                    '${localizations.translate('fishing_location')}*',
                  ),
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(color: AppConstants.textColor),
                    decoration: InputDecoration(
                      fillColor: const Color(0xFF12332E),
                      filled: true,
                      hintText: localizations.translate('enter_location_name'),
                      hintStyle: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: AppConstants.textColor,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Остальные поля формы...
                  _buildSectionHeader(localizations.translate('fishing_dates')),
                  if (isSmallScreen)
                    Column(
                      children: [
                        _buildDateSelector(
                          label: localizations.translate('start'),
                          date: _startDate,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 16),
                        _buildDateSelector(
                          label: localizations.translate('end'),
                          date: _endDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateSelector(
                            label: localizations.translate('start'),
                            date: _startDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateSelector(
                            label: localizations.translate('end'),
                            date: _endDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),

                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${localizations.translate('duration')}: $_tripDays ${DateFormatter.getDaysText(_tripDays, context)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Кнопки внизу экрана
                  if (isSmallScreen)
                    Column(
                      children: [
                        _buildCancelButton(),
                        const SizedBox(height: 16),
                        _buildSaveButton(),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _buildCancelButton()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSaveButton()),
                      ],
                    ),

                  const SizedBox(height: 40),
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

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(date),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(
          localizations.translate('cancel'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveNote,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: _isSaving
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppConstants.textColor,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          localizations.translate('save'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}