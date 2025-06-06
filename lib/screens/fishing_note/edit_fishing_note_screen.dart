// Путь: lib/screens/fishing_note/edit_fishing_note_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../services/weather/weather_service.dart';
import '../../services/weather_settings_service.dart';
import '../../utils/network_utils.dart';
import '../../utils/date_formatter.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import '../map/map_location_screen.dart';
import 'bite_record_screen.dart';
import 'edit_bite_record_screen.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/ai_bite_prediction_service.dart';

class EditFishingNoteScreen extends StatefulWidget {
  final FishingNoteModel note;

  const EditFishingNoteScreen({
    super.key,
    required this.note,
  });

  @override
  State<EditFishingNoteScreen> createState() => _EditFishingNoteScreenState();
}

class _EditFishingNoteScreenState extends State<EditFishingNoteScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationController;
  late TextEditingController _tackleController;
  late TextEditingController _notesController;

  final _fishingNoteRepository = FishingNoteRepository();
  final _weatherService = WeatherService();
  final _weatherSettings = WeatherSettingsService();

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
    _tripDays = _isMultiDay ? _endDate.difference(_startDate).inDays + 1 : 1;

    _existingPhotoUrls = List.from(widget.note.photoUrls);

    _latitude = widget.note.latitude;
    _longitude = widget.note.longitude;
    _hasLocation = _latitude != 0.0 && _longitude != 0.0;

    _weather = widget.note.weather;

    _biteRecords = List.from(widget.note.biteRecords);
    _selectedFishingType = widget.note.fishingType;

    // ИСПРАВЛЕНО: Загружаем ИИ-анализ из заметки, если он есть
    if (widget.note.aiPrediction != null) {
      _loadAIFromMap(widget.note.aiPrediction!);
    }

    // Настраиваем анимацию для плавного появления элементов
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        )
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tackleController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // НОВЫЙ МЕТОД: Загрузка ИИ-анализа из сохраненных данных
  void _loadAIFromMap(Map<String, dynamic> aiMap) {
    try {
      final activityLevelString = aiMap['activityLevel'] as String? ?? 'moderate';
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
        confidence: (aiMap['confidencePercent'] as int? ?? 50) / 100.0, // Конвертируем в double
        recommendation: aiMap['recommendation'] as String? ?? '',
        tips: List<String>.from(aiMap['tips'] ?? []),
        fishingType: aiMap['fishingType'] as String? ?? _selectedFishingType,
      );

      debugPrint('🧠 ИИ-анализ загружен из сохраненных данных: ${_aiPrediction!.overallScore} баллов');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ИИ-анализа из сохраненных данных: $e');
    }
  }

  // Обновление количества дней рыбалки
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
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 70, // Компрессия для оптимизации размера
      );

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          // Добавляем новые фото к уже существующим
          _newPhotos.addAll(
              pickedFiles.map((xFile) => File(xFile.path)).toList()
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_selecting_images')}: $e')),
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
          _newPhotos.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_taking_photo')}: $e')),
        );
      }
    }
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
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
          date: _startDate,
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
          SnackBar(content: Text('${AppLocalizations.of(context).translate('error_loading')}: $e')),
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
        photoUrls: _existingPhotoUrls, // Существующие URL фото
        fishingType: _selectedFishingType,
        weather: _weather,
        biteRecords: _biteRecords,
        mapMarkers: [],
        aiPrediction: aiPredictionMap, // ДОБАВЛЕНО сохранение ИИ-анализа
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем заметку и загружаем новые фото, если они есть
        if (_newPhotos.isNotEmpty) {
          // Загрузка новых фото и добавление их URL к заметке
          await _fishingNoteRepository.updateFishingNoteWithPhotos(
              updatedNote,
              _newPhotos
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('note_updated_successfully')),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context, true); // Возвращаем true для обновления списка заметок
          }
        } else {
          // Просто обновляем заметку без новых фото
          await _fishingNoteRepository.updateFishingNote(updatedNote);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('note_updated_successfully')),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context, true); // Возвращаем true для обновления списка заметок
          }
        }
      } else {
        // Если нет интернета
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('no_internet_changes_saved_locally')),
              backgroundColor: Colors.orange,
            ),
          );
        }

        await _fishingNoteRepository.saveOfflineNoteUpdate(updatedNote, _newPhotos);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('error_saving')}: $e')),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                          // Сбрасываем ИИ-анализ при смене типа
                          _aiPrediction = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('cancel_editing_confirmation'),
            style: TextStyle(
              color: AppConstants.textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text(
                localizations.translate('no'),
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
                Navigator.of(context).pop(); // Вернуться на предыдущий экран
              },
              child: Text(
                localizations.translate('yes_cancel'),
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Создание кнопки "Отмена"
  Widget _buildCancelButton() {
    final localizations = AppLocalizations.of(context);

    return ElevatedButton(
      onPressed: _showCancelConfirmationDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        localizations.translate('cancel').toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Построение карточки ИИ-анализа
  Widget _buildAIAnalysisCard() {
    final localizations = AppLocalizations.of(context);

    if (_aiPrediction == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getScoreColor(_aiPrediction!.overallScore).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: _getScoreColor(_aiPrediction!.overallScore),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.translate('ai_bite_forecast')} (${_aiPrediction!.overallScore}/100)',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getActivityLevelText(_aiPrediction!.activityLevel, localizations),
                      style: TextStyle(
                        color: _getScoreColor(_aiPrediction!.overallScore),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(_aiPrediction!.overallScore).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_aiPrediction!.confidencePercent}%',
                  style: TextStyle(
                    color: _getScoreColor(_aiPrediction!.overallScore),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiPrediction!.recommendation,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (_aiPrediction!.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              localizations.translate('recommendations'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...(_aiPrediction!.tips.take(2).map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ],
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

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('edit_note'),
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
          onPressed: _showCancelConfirmationDialog,
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
              padding: const EdgeInsets.all(16.0),
              children: [
                // Тип рыбалки (с иконкой)
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
                            color: AppConstants.primaryColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: FishingTypeIcons.getIconWidget(_selectedFishingType, size: 24),
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
                _buildSectionHeader('${localizations.translate('fishing_location')}*'),
                TextFormField(
                  controller: _locationController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: localizations.translate('enter_location_name'),
                    hintStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.5)),
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

                // Даты рыбалки с информацией о продолжительности
                _buildSectionHeader(localizations.translate('fishing_dates')),
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

                // Информация о продолжительности
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

                // Точка на карте
                _buildSectionHeader(localizations.translate('map_point')),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.map,
                    color: AppConstants.textColor,
                  ),
                  label: Text(
                    _hasLocation ? localizations.translate('change_map_point') : localizations.translate('select_map_point'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12332E),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selectLocation,
                ),

                if (_hasLocation) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('coordinates')}: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Погода + ИИ-анализ
                _buildSectionHeader(localizations.translate('weather_and_ai_analysis')),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.psychology,
                    color: AppConstants.textColor,
                  ),
                  label: Text(
                    _weather != null || _aiPrediction != null
                        ? localizations.translate('update_weather_and_ai')
                        : localizations.translate('load_weather_ai'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12332E),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (_isLoadingWeather || _isLoadingAI) ? null : _fetchWeatherAndAI,
                ),

                if (_isLoadingWeather || _isLoadingAI)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLoadingAI ? localizations.translate('ai_analyzing') : localizations.translate('loading_weather'),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_weather != null) ...[
                  const SizedBox(height: 12),
                  _buildWeatherCard(localizations),
                ],

                // Отображение ИИ-анализа
                if (_aiPrediction != null)
                  _buildAIAnalysisCard(),

                const SizedBox(height: 20),

                // Снасти
                _buildSectionHeader(localizations.translate('tackle')),
                TextFormField(
                  controller: _tackleController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: localizations.translate('describe_tackle'),
                    hintStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Заметки
                _buildSectionHeader(localizations.translate('notes')),
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: localizations.translate('notes_desc'),
                    hintStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 5,
                ),

                const SizedBox(height: 20),

                // Фотографии
                _buildSectionHeader(localizations.translate('photos')),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: Text(localizations.translate('gallery')),
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
                        label: Text(localizations.translate('camera')),
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
                  _buildSectionHeader(localizations.translate('existing_photos')),
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
                if (_newPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader(localizations.translate('new_photos')),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newPhotos.length,
                      itemBuilder: (context, index) {
                        return _buildPhotoItem(_newPhotos[index].path, index, false);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Записи о поклевках
                _buildSectionHeader(localizations.translate('bite_records')),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppConstants.textColor,
                  ),
                  label: Text(
                    localizations.translate('add_bite_record'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12332E),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _addBiteRecord,
                ),

                if (_biteRecords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBiteRecordsSection(localizations),
                ],

                const SizedBox(height: 40),

                // Кнопки внизу экрана
                Row(
                  children: [
                    Expanded(
                      child: _buildCancelButton(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: AppConstants.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          disabledBackgroundColor: AppConstants.primaryColor.withValues(alpha: 0.5),
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
                          localizations.translate('save').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
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
                Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
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

  // ИСПРАВЛЕННАЯ карточка погоды - убрано дублирование
  Widget _buildWeatherCard(AppLocalizations localizations) {
    if (_weather == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ВЕРХНЯЯ ЧАСТЬ: только температура и ощущается как (без дублирования)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _weather!.isDay
                      ? Icons.wb_sunny
                      : Icons.nightlight_round,
                  color: _weather!.isDay
                      ? Colors.amber
                      : Colors.indigo[300],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTemperature(_weather!.temperature),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.translate('feels_like_short')}: ${_formatTemperature(_weather!.feelsLike)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // НИЖНЯЯ ЧАСТЬ: сетка 2x3 с остальными данными
          _buildWeatherGrid(localizations),
        ],
      ),
    );
  }

  // Новый метод для построения сетки погоды 2x3
  Widget _buildWeatherGrid(AppLocalizations localizations) {
    return Column(
      children: [
        // Первая строка
        Row(
          children: [
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.air,
                label: localizations.translate('wind_short'),
                value: '${_weather!.windDirection}\n${_formatWindSpeed(_weather!.windSpeed)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.water_drop,
                label: localizations.translate('humidity_short'),
                value: '${_weather!.humidity}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.speed,
                label: localizations.translate('pressure_short'),
                value: _formatPressure(_weather!.pressure),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Вторая строка
        Row(
          children: [
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.cloud,
                label: localizations.translate('cloudiness_short'),
                value: '${_weather!.cloudCover}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.wb_twilight,
                label: localizations.translate('sunrise'),
                value: _weather!.sunrise,
              ),
            ),
            const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBiteRecordsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // График поклевок
        _buildBiteRecordsTimeline(localizations),

        const SizedBox(height: 12),

        // Список поклевок
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _biteRecords.length,
          itemBuilder: (context, index) {
            final record = _biteRecords[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFF12332E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  record.fishType.isEmpty
                      ? '${localizations.translate('bite_occurred')} #${index + 1}'
                      : record.fishType,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.translate('bite_time')}: ${DateFormat('HH:mm').format(record.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    if (record.weight > 0)
                      Text(
                        '${localizations.translate('weight')}: ${record.weight} ${localizations.translate('kg')}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    if (record.notes.isNotEmpty)
                      Text(
                        '${localizations.translate('notes')}: ${record.notes}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
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
                      icon: Icon(Icons.edit, color: AppConstants.textColor),
                      onPressed: () => _editBiteRecord(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _biteRecords.removeAt(index);
                        });
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

  Widget _buildBiteRecordsTimeline(AppLocalizations localizations) {
    // Если нет записей, не показываем график
    if (_biteRecords.isEmpty) return const SizedBox();

    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            localizations.translate('bite_chart'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width - 50, 40),
                  painter: _BiteRecordsTimelinePainter(
                    biteRecords: _biteRecords,
                    divisions: divisions,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < hoursInDay; i += 3)
                    Text(
                      '$i:00',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            onTap: () => isExisting ? _removeExistingPhoto(index) : _removeNewPhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
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
      canvas.drawCircle(
        Offset(position, size.height / 2),
        7,
        dotPaint,
      );

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