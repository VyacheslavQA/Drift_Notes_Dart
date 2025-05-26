// Путь: lib/screens/map/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../config/api_keys.dart';
import '../../localization/app_localizations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _errorLoadingMap = false;
  String _errorMessage = '';

  // Переменная для типа карты
  MapType _currentMapType = MapType.normal;

  // Начальная позиция для карты (будет заменена текущей геолокацией)
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(52.2788, 76.9419), // Павлодар
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedMapType();

    // Проверяем API ключ при инициализации
    if (ApiKeys.hasGoogleMapsKey) {
      _loadUserLocation();
      _loadFishingSpots();
    } else {
      // Если ключа нет, сразу показываем ошибку
      setState(() {
        _isLoading = false;
        _errorLoadingMap = true;
        _errorMessage = 'Google Maps API ключ не настроен';
      });
    }
  }

  // Загрузка сохраненного типа карты
  Future<void> _loadSavedMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMapTypeIndex = prefs.getInt('map_type') ?? 0;

      setState(() {
        _currentMapType = MapType.values[savedMapTypeIndex];
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке типа карты: $e');
    }
  }

  // Сохранение выбранного типа карты
  Future<void> _saveMapType(MapType mapType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('map_type', mapType.index);
    } catch (e) {
      debugPrint('Ошибка при сохранении типа карты: $e');
    }
  }

  // Переключение типа карты
  void _changeMapType(MapType newMapType) {
    setState(() {
      _currentMapType = newMapType;
    });
    _saveMapType(newMapType);
    Navigator.pop(context); // Закрываем BottomSheet
  }

  // Показ селектора типов карты
  void _showMapTypeSelector() {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMapTypeSelectorSheet(),
    );
  }

  // BottomSheet с выбором типов карты
  Widget _buildMapTypeSelectorSheet() {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Тип карты',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppConstants.textColor,
                  ),
                ),
              ],
            ),
          ),

          // Разделитель
          Divider(
            color: AppConstants.textColor.withValues(alpha: 0.2),
            height: 1,
          ),

          // Список типов карт
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMapTypeOption(
                  MapType.normal,
                  'Схема',
                  'Дороги, названия улиц и достопримечательности',
                  Icons.map_outlined,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.satellite,
                  'Спутник',
                  'Спутниковые снимки без названий',
                  Icons.satellite_alt,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.hybrid,
                  'Гибрид',
                  'Спутниковые снимки с названиями дорог и объектов',
                  Icons.layers,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.terrain,
                  'Рельеф',
                  'Топографическая карта с высотами и рельефом',
                  Icons.terrain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Опция выбора типа карты
  Widget _buildMapTypeOption(
      MapType mapType,
      String title,
      String description,
      IconData icon
      ) {
    final isSelected = _currentMapType == mapType;

    return InkWell(
      onTap: () => _changeMapType(mapType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Превью/иконка
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppConstants.textColor
                    : AppConstants.textColor.withValues(alpha: 0.7),
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Индикатор выбора
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: AppConstants.textColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Загрузка текущей геолокации пользователя
  Future<void> _loadUserLocation() async {
    try {
      // Проверяем разрешения геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = 'Службы геолокации отключены. Пожалуйста, включите их.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _errorLoadingMap = true;
              _errorMessage = 'Разрешение на использование геолокации отклонено.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = 'Разрешение на использование геолокации отклонено навсегда. Измените настройки в приложении.';
          });
        }
        return;
      }

      // Получаем текущую позицию
      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _initialPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 11.0,
          );

          // Добавляем маркер текущей позиции
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: 'Ваше местоположение'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );

          _isLoading = false;
        });

        // Перемещаем камеру на текущую позицию
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(_initialPosition),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingMap = true;
          _errorMessage = 'Ошибка при определении местоположения: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Загрузка точек рыбалки пользователя
  Future<void> _loadFishingSpots() async {
    try {
      final fishingNotes = await _fishingNoteRepository.getUserFishingNotes();

      // Фильтруем заметки, у которых есть координаты
      final notesWithCoordinates = fishingNotes.where(
            (note) => note.latitude != 0 && note.longitude != 0,
      ).toList();

      // Создаем маркеры для каждой точки рыбалки
      for (var note in notesWithCoordinates) {
        _markers.add(
          Marker(
            markerId: MarkerId(note.id),
            position: LatLng(note.latitude, note.longitude),
            infoWindow: InfoWindow(
              title: note.location,
              snippet: note.isMultiDay
                  ? 'Дата: ${note.date.day}.${note.date.month}.${note.date.year} - ${note.endDate!.day}.${note.endDate!.month}.${note.endDate!.day}'
                  : 'Дата: ${note.date.day}.${note.date.month}.${note.date.year}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке точек рыбалки: $e')),
        );
      }
    }
  }

  // Обработчик создания карты
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Повторная попытка загрузки (для случая с отсутствующим API ключом)
  void _retryLoading() {
    if (!ApiKeys.hasGoogleMapsKey) {
      // Показываем информацию о настройке ключа
      _showApiKeyInfo();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorLoadingMap = false;
      _errorMessage = '';
    });

    _loadUserLocation();
    _loadFishingSpots();
  }

  // Показ информации о настройке API ключа
  void _showApiKeyInfo() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Text(
            'Настройка Google Maps',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Для работы карты необходимо настроить Google Maps API ключ:',
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Получите ключ в Google Cloud Console\n'
                    '2. Добавьте его в файл lib/config/api_keys.dart\n'
                    '3. Перезапустите приложение',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Понятно',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('map'),
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
          // Кнопка информации о статусе API ключей (только в debug режиме)
          if (ApiKeys.hasGoogleMapsKey)
            IconButton(
              icon: Icon(Icons.refresh, color: AppConstants.textColor),
              onPressed: _retryLoading,
              tooltip: 'Обновить карту',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Основное содержимое
          _isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppConstants.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Загрузка карты...',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : _errorLoadingMap
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !ApiKeys.hasGoogleMapsKey
                        ? Icons.warning_amber_rounded
                        : Icons.location_off,
                    color: !ApiKeys.hasGoogleMapsKey
                        ? Colors.orange
                        : AppConstants.textColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    !ApiKeys.hasGoogleMapsKey
                        ? 'Google Maps API ключ не настроен'
                        : _errorMessage,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    !ApiKeys.hasGoogleMapsKey
                        ? 'Для работы карты необходимо добавить API ключ в настройки приложения'
                        : 'Проверьте подключение к интернету и разрешения геолокации',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryLoading,
                    icon: Icon(!ApiKeys.hasGoogleMapsKey ? Icons.info : Icons.refresh),
                    label: Text(!ApiKeys.hasGoogleMapsKey ? 'Подробнее' : 'Повторить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Отключаем стандартную кнопку
            mapType: _currentMapType, // Используем выбранный тип карты
            zoomControlsEnabled: true, // Включаем стандартные кнопки зума
            compassEnabled: true,
          ),

          // Кнопка выбора типа карты (поверх карты, справа вверху)
          if (!_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey)
            Positioned(
              top: 20,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showMapTypeSelector,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.layers,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Слои',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // FAB для местоположения (слева внизу, чтобы не мешать кнопкам зума)
      floatingActionButton: !_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey
          ? FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        onPressed: _loadUserLocation,
        tooltip: 'Моё местоположение',
        child: const Icon(Icons.my_location),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Слева внизу
    );
  }
}