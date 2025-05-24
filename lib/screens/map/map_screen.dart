// Путь: lib/screens/map/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../repositories/fishing_note_repository.dart';

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

  // Начальная позиция для карты (будет заменена текущей геолокацией)
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(55.751244, 37.618423), // Москва
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadFishingSpots();
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
                  ? 'Дата: ${note.date.day}.${note.date.month}.${note.date.year} - ${note.endDate!.day}.${note.endDate!.month}.${note.endDate!.year}'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Карта рыбалок'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
          : _errorLoadingMap
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                color: AppConstants.textColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserLocation,
                child: const Text('Повторить'),
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
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        compassEnabled: true,
        style: _mapStyle,
      ),
      floatingActionButton: !_isLoading && !_errorLoadingMap
          ? FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        onPressed: _loadUserLocation,
        child: const Icon(Icons.my_location),
      )
          : null,
    );
  }

  // Стиль для темной темы Google Maps
  static const String _mapStyle = '''
      [
        {
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "elementType": "labels.icon",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "administrative.country",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#9e9e9e"
            }
          ]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#bdbdbd"
            }
          ]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#181818"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#616161"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#1b1b1b"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry.fill",
          "stylers": [
            {
              "color": "#2c2c2c"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#8a8a8a"
            }
          ]
        },
        {
          "featureType": "road.arterial",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#373737"
            }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#3c3c3c"
            }
          ]
        },
        {
          "featureType": "road.highway.controlled_access",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#4e4e4e"
            }
          ]
        },
        {
          "featureType": "road.local",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#616161"
            }
          ]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#000814"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#3d3d3d"
            }
          ]
        }
      ]
    ''';
}