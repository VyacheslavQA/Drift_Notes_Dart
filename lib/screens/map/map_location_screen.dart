// Путь: lib/screens/map/map_location_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

class MapLocationScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(52.2788, 76.9419); // Павлодар
  bool _isLoading = true;
  Set<Marker> _markers = {};

  // Переменные для переключателя типов карты
  MapType _currentMapType = MapType.hybrid;
  bool _showCoordinates = false; // Для показа/скрытия координат

  @override
  void initState() {
    super.initState();
    _loadSavedMapType();

    // Если есть начальные координаты, используем их
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _updateMarker();
    } else {
      // Иначе пытаемся определить текущее местоположение
      _determinePosition();
    }
  }

  // Загрузка сохраненного типа карты
  Future<void> _loadSavedMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMapTypeIndex = prefs.getInt('location_map_type') ?? 2; // По умолчанию hybrid

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
      await prefs.setInt('location_map_type', mapType.index);
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
                  localizations.translate('map_type'),
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
                  localizations.translate('normal_map'),
                  localizations.translate('normal_map_desc'),
                  Icons.map_outlined,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.satellite,
                  localizations.translate('satellite_map'),
                  localizations.translate('satellite_map_desc'),
                  Icons.satellite_alt,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.hybrid,
                  localizations.translate('hybrid_map'),
                  localizations.translate('hybrid_map_desc'),
                  Icons.layers,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  MapType.terrain,
                  localizations.translate('terrain_map'),
                  localizations.translate('terrain_map_desc'),
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

  // Определение текущего местоположения
  Future<void> _determinePosition() async {
    final localizations = AppLocalizations.of(context);
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем, включены ли службы геолокации
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Проверяем разрешения на доступ к геолокации
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Получаем текущее местоположение
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _selectedPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Обновляем маркер
        _updateMarker();

        // Перемещаем камеру к текущему местоположению
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _selectedPosition,
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_loading')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Обновление маркера на карте
  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedPosition = newPosition;
            });
          },
        ),
      };
    });
  }

  // Сохранение выбранной локации
  void _saveLocation() {
    Navigator.pop(context, {
      'latitude': _selectedPosition.latitude,
      'longitude': _selectedPosition.longitude,
    });
  }

  // Зум в карту
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  // Зум из карты
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('select_map_point'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
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
            onPressed: _saveLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;

              setState(() {
                _isLoading = false;
              });

              _updateMarker();
            },
            markers: _markers,
            onTap: (position) {
              setState(() {
                _selectedPosition = position;
              });
              _updateMarker();
            },
            zoomControlsEnabled: false, // Отключаем стандартные кнопки зума
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Отключаем стандартную кнопку местоположения
            compassEnabled: true,
            mapType: _currentMapType, // Используем выбранный тип карты
          ),

          // Кнопка выбора типа карты (справа вверху, под AppBar)
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
                          localizations.translate('layers'),
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

          // Кнопки зума (справа, под кнопкой слоев)
          Positioned(
            top: 90,
            right: 16,
            child: Column(
              children: [
                // Кнопка приближения
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomIn,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Разделитель
                Container(
                  width: 44,
                  height: 1,
                  color: AppConstants.textColor.withValues(alpha: 0.2),
                ),

                // Кнопка отдаления
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomOut,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Кнопка моего местоположения (слева внизу, ниже)
          Positioned(
            bottom: 30,
            left: 16,
            child: FloatingActionButton(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              onPressed: _determinePosition,
              heroTag: 'location_button',
              child: const Icon(Icons.my_location),
            ),
          ),

          // Кнопка показа координат (справа внизу, чуть больше)
          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: AppConstants.textColor,
              onPressed: () {
                setState(() {
                  _showCoordinates = !_showCoordinates;
                });
              },
              heroTag: 'coordinates_button',
              child: Icon(
                _showCoordinates ? Icons.info : Icons.info_outline,
                size: 24,
              ),
            ),
          ),

          // Панель координат (показывается только при нажатии, выше кнопок)
          if (_showCoordinates)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.translate('coordinates'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showCoordinates = false;
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: AppConstants.textColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      '${localizations.translate('latitude')}: ${_selectedPosition.latitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${localizations.translate('longitude')}: ${_selectedPosition.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Индикатор загрузки
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppConstants.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _saveLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            child: Text(
              localizations.translate('select_this_point').toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}