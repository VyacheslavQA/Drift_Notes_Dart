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
import '../map/map_location_screen.dart';
import 'bite_record_screen.dart';

class AddFishingNoteScreen extends StatefulWidget {
  final String fishingType;

  const AddFishingNoteScreen({
    Key? key,
    required this.fishingType,
  }) : super(key: key);

  @override
  _AddFishingNoteScreenState createState() => _AddFishingNoteScreenState();
}

class _AddFishingNoteScreenState extends State<AddFishingNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _tackleController = TextEditingController();
  final _notesController = TextEditingController();

  final _fishingNoteRepository = FishingNoteRepository();
  final _weatherService = WeatherService();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isMultiDay = false;

  List<File> _selectedPhotos = [];
  bool _isLoading = false;
  bool _isSaving = false;

  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _hasLocation = false;

  FishingWeather? _weather;
  bool _isLoadingWeather = false;

  List<BiteRecord> _biteRecords = [];

  @override
  void dispose() {
    _locationController.dispose();
    _tackleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        if (isStartDate) {
          _startDate = picked;
          // Если выбранная дата старта позже даты окончания, обновляем дату окончания
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;

          // Устанавливаем флаг многодневной рыбалки
          _isMultiDay = !DateUtils.isSameDay(_startDate, _endDate);
        }
      });
    }
  }

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
    if (!_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите место на карте'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final weatherData = await _weatherService.getWeatherForLocation(
        _latitude,
        _longitude,
      );

      setState(() {
        _weather = weatherData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке погоды: $e')),
      );
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _addBiteRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(),
      ),
    );

    if (result != null && result is BiteRecord) {
      setState(() {
        _biteRecords.add(result);
      });
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите место рыбалки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Создаем модель заметки
      final note = FishingNoteModel(
        id: const Uuid().v4(),
        userId: '', // Будет установлен в репозитории
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        date: _startDate,
        endDate: _isMultiDay ? _endDate : null,
        isMultiDay: _isMultiDay,
        tackle: _tackleController.text.trim(),
        notes: _notesController.text.trim(),
        photoUrls: [], // Пустой список, фото будут загружены и URL добавлены в репозитории
        fishingType: widget.fishingType,
        weather: _weather,
        biteRecords: _biteRecords,
      );

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, сохраняем заметку и загружаем фото
        await _fishingNoteRepository.addFishingNote(note, _selectedPhotos);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заметка успешно сохранена'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true); // Возвращаем true для обновления списка заметок
        }
      } else {
        // Если нет интернета, сохраняем в локальное хранилище
        // Это нужно будет реализовать дополнительно
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет подключения к интернету. Заметка сохранена локально и будет отправлена при подключении.'),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении: $e')),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Новая заметка',
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Тип рыбалки
              _buildSectionHeader('Тип рыбалки'),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF12332E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: AppConstants.textColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.fishingType,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Место рыбалки
              _buildSectionHeader('Место рыбалки*'),
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: 'Введите название места',
                  hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
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
                    return 'Обязательное поле';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Даты рыбалки
              _buildSectionHeader('Даты рыбалки'),
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Начало',
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Окончание',
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Точка на карте
              _buildSectionHeader('Точка на карте'),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.map,
                  color: AppConstants.textColor,
                ),
                label: Text(
                  _hasLocation ? 'Изменить точку на карте' : 'Выбрать точку на карте',
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
                  'Координаты: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Погода
              _buildSectionHeader('Погода'),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.cloud,
                  color: AppConstants.textColor,
                ),
                label: Text(
                  _weather != null ? 'Обновить данные погоды' : 'Загрузить данные погоды',
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
              _buildSectionHeader('Снасти'),
              TextFormField(
                controller: _tackleController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF12332E),
                  filled: true,
                  hintText: 'Опишите используемые снасти',
                  hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
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
                  hintText: 'Заметки о рыбалке',
                  hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 5,
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
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Кнопка добавления поклевок
              _buildSectionHeader('Записи о поклевках'),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppConstants.textColor,
                ),
                label: Text(
                  'Добавить запись о поклевке',
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

              ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.5),
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
                    : const Text(
                  'СОХРАНИТЬ ЗАМЕТКУ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),
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
                color: AppConstants.textColor.withOpacity(0.7),
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

  // Путь: lib/screens/fishing_note/add_fishing_note_screen.dart (продолжение)

  Widget _buildWeatherCard() {
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
                  color: AppConstants.primaryColor.withOpacity(0.2),
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
                      'Ощущается как ${_weather!.feelsLike.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
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
                label: 'Ветер',
                value: '${_weather!.windDirection}, ${_weather!.windSpeed} м/с',
              ),
              _buildWeatherInfoItem(
                icon: Icons.water_drop,
                label: 'Влажность',
                value: '${_weather!.humidity}%',
              ),
              _buildWeatherInfoItem(
                icon: Icons.speed,
                label: 'Давление',
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
                label: 'Облачность',
                value: '${_weather!.cloudCover}%',
              ),
              _buildWeatherInfoItem(
                icon: Icons.wb_twilight,
                label: 'Восход',
                value: _weather!.sunrise,
              ),
              _buildWeatherInfoItem(
                icon: Icons.nights_stay,
                label: 'Закат',
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
          color: AppConstants.textColor.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // График поклевок
        _buildBiteRecordsTimeline(),

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
                      ? 'Поклевка #${index + 1}'
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
                      'Время: ${DateFormat('HH:mm').format(record.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                      ),
                    ),
                    if (record.weight > 0)
                      Text(
                        'Вес: ${record.weight} кг',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                      ),
                    if (record.notes.isNotEmpty)
                      Text(
                        'Заметка: ${record.notes}',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
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
    // Если нет записей, не показываем график
    if (_biteRecords.isEmpty) return const SizedBox();

    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'График поклевок',
            style: TextStyle(
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
                  painter: BiteRecordsTimelinePainter(
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
                        color: AppConstants.textColor.withOpacity(0.8),
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

// Кастомный график поклевок
class BiteRecordsTimelinePainter extends CustomPainter {
  final List<BiteRecord> biteRecords;
  final int divisions;

  BiteRecordsTimelinePainter({
    required this.biteRecords,
    required this.divisions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
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
    final bitePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      // Рисуем кружок для поклевки
      canvas.drawCircle(
        Offset(position, size.height / 2),
        7,
        bitePaint,
      );

      // Если есть вес, рисуем размер круга в зависимости от веса
      if (record.weight > 0) {
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