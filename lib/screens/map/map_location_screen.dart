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

  // ✅ ИСПРАВЛЕНО: MapType.normal по умолчанию вместо hybrid
  MapType _currentMapType = MapType.normal;
  bool _showCoordinates = false; // Для показа/скрытия координат

  @override
  void initState() {
    super.initState();
    _loadSavedMapType();

    // Если есть начальные координаты, используем их
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _updateMarker();
    } else {
      _determinePosition();
    }
  }

  // ✅ ДОБАВЛЕНО: dispose() для очистки контроллера
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Загрузка сохраненного типа карты
  Future<void> _loadSavedMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ ИСПРАВЛЕНО: По умолчанию 0 (normal) вместо 2 (hybrid)
      final savedMapTypeIndex = prefs.getInt('location_map_type') ?? 0;

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

  // ✅ РАДИКАЛЬНО УПРОЩЕНО: Простое переключение Normal ↔ Hybrid
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
    _saveMapType(_currentMapType);
  }

  // Определение текущего местоположения
  Future<void> _determinePosition() async {
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
        if (mounted) {
          _showLocationError('Location services are disabled');
        }
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
          if (mounted) {
            _showLocationError('Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showLocationError('Location permissions are permanently denied');
        }
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
            CameraPosition(target: _selectedPosition, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showLocationError('Error getting location: $e');
      }
    }
  }

  // Умная обработка ошибок с локализацией
  void _showLocationError(String fallbackMessage) {
    try {
      final localizations = AppLocalizations.of(context);
      final localizedMessage = _getLocalizedError(fallbackMessage, localizations);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizedMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Помощник для получения локализованных ошибок
  String _getLocalizedError(String fallbackMessage, AppLocalizations localizations) {
    if (fallbackMessage.contains('disabled')) {
      return localizations.translate('location_services_disabled') ?? 'Location services are disabled';
    } else if (fallbackMessage.contains('denied')) {
      return localizations.translate('location_permissions_denied') ?? 'Location permissions denied';
    } else if (fallbackMessage.contains('permanently')) {
      return localizations.translate('location_permissions_permanently_denied') ?? 'Location permissions permanently denied';
    } else {
      return localizations.translate('error_loading') ?? fallbackMessage;
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
          // ✅ ИСПРАВЛЕНО: Google Maps с оптимизированными настройками
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
            // ✅ ИСПРАВЛЕНО: Отключаем GPU-тяжелые функции
            tiltGesturesEnabled: false,        // Нет 3D наклонов
            rotateGesturesEnabled: false,      // Нет поворотов
            zoomControlsEnabled: false,        // Кастомные кнопки зума
            myLocationEnabled: true,
            myLocationButtonEnabled: false,    // Кастомная кнопка местоположения
            compassEnabled: true,              // Компас оставляем
            mapToolbarEnabled: false,          // Убираем Google Maps toolbar
            mapType: _currentMapType,          // Используем выбранный тип карты
          ),

          // ✅ УПРОЩЕНО: Простая кнопка переключения Normal ↔ Hybrid
          Positioned(
            top: 20,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _toggleMapType,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentMapType == MapType.normal
                              ? Icons.map_outlined
                              : Icons.layers,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentMapType == MapType.normal ? 'Обычная' : 'Гибрид',
                          style: TextStyle(
                            color: Colors.white,
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
                        child: Icon(Icons.add, color: Colors.white, size: 24),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.textColor,
                  ),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}