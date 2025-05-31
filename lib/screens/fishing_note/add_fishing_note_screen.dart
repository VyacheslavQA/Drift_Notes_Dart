// Путь: lib/screens/fishing_note/add_fishing_note_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../services/weather/weather_service.dart';
import '../../utils/network_utils.dart';
import '../../utils/date_formatter.dart';
import '../../utils/fishing_type_icons.dart';
import '../../localization/app_localizations.dart';
import '../map/map_location_screen.dart';
import 'bite_record_screen.dart';

class AddFishingNoteScreen extends StatefulWidget {
  final String? fishingType;
  final DateTime? initialDate;

  const AddFishingNoteScreen({
    super.key,
    this.fishingType,
    this.initialDate,
  });

  @override
  State<AddFishingNoteScreen> createState() => _AddFishingNoteScreenState();
}

class _AddFishingNoteScreenState extends State<AddFishingNoteScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _tackleController = TextEditingController();
  final _notesController = TextEditingController();

  final _fishingNoteRepository = FishingNoteRepository();
  final _weatherService = WeatherService();

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

  final List<BiteRecord> _biteRecords = [];
  String _selectedFishingType = '';

  // Для анимаций
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        )
    );

    _animationController.forward();
    _tripDays = 1;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tackleController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
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
            dialogTheme: DialogTheme(
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
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedPhotos.addAll(
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
          _selectedPhotos.add(File(pickedFile.path));
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

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
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
      });
    }
  }

  Future<void> _fetchWeather() async {
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
    });

    try {
      final weatherData = await _weatherService.getWeatherForLocation(
        _latitude,
        _longitude,
        context,
      );

      if (mounted) {
        setState(() {
          _weather = weatherData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_loading')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
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
      final note = FishingNoteModel(
        id: const Uuid().v4(),
        userId: '',
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        date: _startDate,
        endDate: _isMultiDay ? _endDate : null,
        isMultiDay: _isMultiDay,
        tackle: _tackleController.text.trim(),
        notes: _notesController.text.trim(),
        photoUrls: [],
        fishingType: _selectedFishingType,
        weather: _weather,
        biteRecords: _biteRecords,
        mapMarkers: [], // Пустой список маркеров
      );

      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        await _fishingNoteRepository.addFishingNote(note, _selectedPhotos);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('note_saved_successfully')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
        }
      } else {
        await _fishingNoteRepository.addFishingNote(note, _selectedPhotos);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('no_internet_saved_locally')),
              backgroundColor: Colors.orange,
            ),
          );

          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_saving')}: $e')),
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

  Widget _buildCancelButton() {
    final localizations = AppLocalizations.of(context);

    return ElevatedButton(
      onPressed: () {
        showDialog(
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
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
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
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        localizations.translate('cancel'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
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

                // Даты рыбалки
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
                    _hasLocation
                        ? localizations.translate('change_map_point')
                        : localizations.translate('select_map_point'),
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

                // Погода
                _buildSectionHeader(localizations.translate('weather')),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.cloud,
                    color: AppConstants.textColor,
                  ),
                  label: Text(
                    _weather != null
                        ? localizations.translate('update_weather_data')
                        : localizations.translate('load_weather_data'),
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
                  onPressed: _isLoadingWeather ? null : _fetchWeather,
                ),

                if (_isLoadingWeather)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                      ),
                    ),
                  ),

                if (_weather != null) ...[
                  const SizedBox(height: 12),
                  _buildWeatherCard(),
                ],

                const SizedBox(height: 20),

                // Снасти
                _buildSectionHeader(localizations.translate('tackle')),
                TextFormField(
                  controller: _tackleController,
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF12332E),
                    filled: true,
                    hintText: localizations.translate('tackle_desc'),
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

                if (_selectedPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedPhotos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
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
                  _buildBiteRecordsSection(),
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
                          localizations.translate('save'),
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

  Widget _buildWeatherCard() {
    final localizations = AppLocalizations.of(context);
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
                      '${_weather!.temperature.toStringAsFixed(1)}°C, ${_weather!.weatherDescription}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.translate('feels_like')} ${_weather!.feelsLike.toStringAsFixed(1)}°C',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfoItem(
                icon: Icons.air,
                label: localizations.translate('wind'),
                value: '${_weather!.windDirection}, ${_weather!.windSpeed} м/с',
              ),
              _buildWeatherInfoItem(
                icon: Icons.water_drop,
                label: localizations.translate('humidity'),
                value: '${_weather!.humidity}%',
              ),
              _buildWeatherInfoItem(
                icon: Icons.speed,
                label: localizations.translate('pressure'),
                value: '${(_weather!.pressure / 1.333).toInt()} мм',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfoItem(
                icon: Icons.cloud,
                label: localizations.translate('clouds'),
                value: '${_weather!.cloudCover}%',
              ),
              _buildWeatherInfoItem(
                icon: Icons.wb_twilight,
                label: localizations.translate('sunrise'),
                value: _weather!.sunrise,
              ),
              _buildWeatherInfoItem(
                icon: Icons.nights_stay,
                label: localizations.translate('sunset'),
                value: _weather!.sunset,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBiteRecordsSection() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBiteRecordsTimeline(),
        const SizedBox(height: 12),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _biteRecords.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBiteRecordsTimeline() {
    final localizations = AppLocalizations.of(context);

    if (_biteRecords.isEmpty) return const SizedBox();

    const hoursInDay = 24;
    const divisions = 48;

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

    final bitePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      canvas.drawCircle(
        Offset(position, size.height / 2),
        7,
        bitePaint,
      );

      if (record.weight > 0) {
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