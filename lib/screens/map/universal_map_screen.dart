// Путь: lib/screens/map/universal_map_screen.dart
// УНИВЕРСАЛЬНАЯ КАРТА - заменяет map_screen.dart и map_location_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../../constants/app_constants.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../config/api_keys.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_note_model.dart';
import '../fishing_note/fishing_type_selection_screen.dart';

// 🎯 РЕЖИМЫ РАБОТЫ УНИВЕРСАЛЬНОЙ КАРТЫ
enum MapMode {
  homeView,        // Главная карта - просмотр всех заметок (заменяет MapScreen)
  selectLocation,  // Выбор точки для новой заметки (заменяет MapLocationScreen)
  editLocation,    // Изменение точки существующей заметки
}

class UniversalMapScreen extends StatefulWidget {
  final MapMode mode;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? noteId;  // Для режима редактирования

  const UniversalMapScreen({
    super.key,
    required this.mode,
    this.initialLatitude,
    this.initialLongitude,
    this.noteId,
  });

  @override
  State<UniversalMapScreen> createState() => _UniversalMapScreenState();
}

class _UniversalMapScreenState extends State<UniversalMapScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _errorLoadingMap = false;
  String _errorMessage = '';

  // Общие настройки карты
  MapType _currentMapType = MapType.normal;
  bool _showCoordinates = false;

  // Начальная позиция для карты
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(52.2788, 76.9419), // Павлодар
    zoom: 11.0,
  );

  // Для режима homeView - заметки рыбалки
  List<FishingNoteModel> _fishingNotes = [];

  // Для режимов selectLocation и editLocation - выбранная позиция
  LatLng _selectedPosition = const LatLng(52.2788, 76.9419);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем ошибки с локализацией
    if (_errorLoadingMap && _errorMessage == 'Google Maps API ключ не настроен') {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _errorMessage = localizations.translate('google_maps_not_configured');
      });
    }
  }

  // 🚀 ИНИЦИАЛИЗАЦИЯ КАРТЫ В ЗАВИСИМОСТИ ОТ РЕЖИМА
  Future<void> _initializeMap() async {
    await _loadSavedMapType();

    // Проверяем API ключ
    if (!ApiKeys.hasGoogleMapsKey) {
      setState(() {
        _isLoading = false;
        _errorLoadingMap = true;
        _errorMessage = 'Google Maps API ключ не настроен';
      });
      return;
    }

    // Устанавливаем начальную позицию если есть
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _initialPosition = CameraPosition(
        target: _selectedPosition,
        zoom: widget.mode == MapMode.homeView ? 11.0 : 15.0,
      );
    }

    // Инициализируем в зависимости от режима
    switch (widget.mode) {
      case MapMode.homeView:
        await _initializeHomeView();
        break;
      case MapMode.selectLocation:
        await _initializeLocationSelection();
        break;
      case MapMode.editLocation:
        await _initializeLocationEditing();
        break;
    }
  }

  // 🏠 ИНИЦИАЛИЗАЦИЯ РЕЖИМА ПРОСМОТРА ЗАМЕТОК
  Future<void> _initializeHomeView() async {
    try {
      await _loadUserLocationWithoutLocalization();
      await _loadFishingSpotsWithoutLocalization();
    } catch (e) {
      debugPrint('Ошибка инициализации режима просмотра: $e');
      setState(() {
        _isLoading = false;
        _errorLoadingMap = true;
        _errorMessage = 'Ошибка загрузки карты: $e';
      });
    }
  }

  // 📍 ИНИЦИАЛИЗАЦИЯ РЕЖИМА ВЫБОРА ТОЧКИ
  Future<void> _initializeLocationSelection() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        // Есть начальные координаты - используем их
        _updateLocationMarker();
        setState(() {
          _isLoading = false;
        });
      } else {
        // Определяем текущее местоположение
        await _determineCurrentPosition();
      }
    } catch (e) {
      debugPrint('Ошибка инициализации выбора точки: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✏️ ИНИЦИАЛИЗАЦИЯ РЕЖИМА РЕДАКТИРОВАНИЯ ТОЧКИ
  Future<void> _initializeLocationEditing() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _updateLocationMarker();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка инициализации редактирования: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 💾 ЗАГРУЗКА/СОХРАНЕНИЕ НАСТРОЕК КАРТЫ
  Future<void> _loadSavedMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = widget.mode == MapMode.homeView ? 'map_type' : 'location_map_type';
      final savedMapTypeIndex = prefs.getInt(key) ?? 0;
      setState(() {
        _currentMapType = MapType.values[savedMapTypeIndex];
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке типа карты: $e');
    }
  }

  Future<void> _saveMapType(MapType mapType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = widget.mode == MapMode.homeView ? 'map_type' : 'location_map_type';
      await prefs.setInt(key, mapType.index);
    } catch (e) {
      debugPrint('Ошибка при сохранении типа карты: $e');
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
    _saveMapType(_currentMapType);
  }

  // 🌍 РАБОТА С ГЕОЛОКАЦИЕЙ
  Future<void> _loadUserLocationWithoutLocalization() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = 'Службы геолокации отключены';
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
              _errorMessage = 'Разрешение на геолокацию отклонено';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = 'Разрешение на геолокацию отклонено навсегда';
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _initialPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 11.0,
          );

          // Добавляем маркер текущей позиции только в режиме homeView
          if (widget.mode == MapMode.homeView) {
            _markers.add(
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(position.latitude, position.longitude),
                infoWindow: const InfoWindow(title: 'Ваше местоположение'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
          }

          _isLoading = false;
        });

        _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingMap = true;
          _errorMessage = 'Ошибка определения местоположения: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserLocation() async {
    final localizations = AppLocalizations.of(context);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = localizations.translate('location_services_disabled');
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
              _errorMessage = localizations.translate('location_permission_denied');
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = localizations.translate('location_permission_denied_forever');
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        if (widget.mode == MapMode.homeView) {
          // В режиме просмотра - обновляем маркер текущей позиции
          setState(() {
            _initialPosition = CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 11.0,
            );

            _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
            _markers.add(
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(position.latitude, position.longitude),
                infoWindow: InfoWindow(title: localizations.translate('your_location')),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );

            _isLoading = false;
            _errorLoadingMap = false;
            _errorMessage = '';
          });
        } else {
          // В режимах выбора/редактирования - перемещаем выбранную точку
          setState(() {
            _selectedPosition = LatLng(position.latitude, position.longitude);
            _isLoading = false;
            _errorLoadingMap = false;
            _errorMessage = '';
          });
          _updateLocationMarker();
        }

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: widget.mode == MapMode.homeView
                  ? LatLng(position.latitude, position.longitude)
                  : _selectedPosition,
              zoom: widget.mode == MapMode.homeView ? 11.0 : 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingMap = true;
          _errorMessage = '${localizations.translate('location_error')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _determineCurrentPosition() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showLocationError('Location services are disabled');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _selectedPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        _updateLocationMarker();

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

  // 🎣 РАБОТА С ЗАМЕТКАМИ РЫБАЛКИ (для режима homeView)
  Future<void> _loadFishingSpotsWithoutLocalization() async {
    try {
      final fishingNotes = await _fishingNoteRepository.getUserFishingNotes();
      final notesWithCoordinates = fishingNotes
          .where((note) => note.latitude != 0 && note.longitude != 0)
          .toList();

      _fishingNotes = notesWithCoordinates;

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
            onTap: () => _showFishingNoteInfo(note),
          ),
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке точек рыбалки: $e');
    }
  }

  Future<void> _loadFishingSpots() async {
    final localizations = AppLocalizations.of(context);

    try {
      final fishingNotes = await _fishingNoteRepository.getUserFishingNotes();
      final notesWithCoordinates = fishingNotes
          .where((note) => note.latitude != 0 && note.longitude != 0)
          .toList();

      _fishingNotes = notesWithCoordinates;

      _markers.removeWhere((marker) => marker.markerId.value != 'currentLocation');

      for (var note in notesWithCoordinates) {
        _markers.add(
          Marker(
            markerId: MarkerId(note.id),
            position: LatLng(note.latitude, note.longitude),
            infoWindow: InfoWindow(
              title: note.location,
              snippet: note.isMultiDay
                  ? '${localizations.translate('date')}: ${note.date.day}.${note.date.month}.${note.date.year} - ${note.endDate!.day}.${note.endDate!.month}.${note.endDate!.day}'
                  : '${localizations.translate('date')}: ${note.date.day}.${note.date.month}.${note.date.year}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            onTap: () => _showFishingNoteInfo(note),
          ),
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_loading_fishing_spots')}: $e'),
          ),
        );
      }
    }
  }

  // 📍 РАБОТА С ВЫБОРОМ ТОЧКИ (для режимов selectLocation и editLocation)
  void _updateLocationMarker() {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'selected_location');
      _markers.add(
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
      );
    });
  }

  void _onMapTapped(LatLng position) {
    if (widget.mode == MapMode.selectLocation || widget.mode == MapMode.editLocation) {
      setState(() {
        _selectedPosition = position;
      });
      _updateLocationMarker();
    }
  }

  // 💾 СОХРАНЕНИЕ ВЫБРАННОЙ ТОЧКИ
  void _saveLocation() {
    Navigator.pop(context, {
      'latitude': _selectedPosition.latitude,
      'longitude': _selectedPosition.longitude,
    });
  }

  // 🗺️ УПРАВЛЕНИЕ КАРТОЙ
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  // 🔄 ПОВТОРНАЯ ЗАГРУЗКА
  void _retryLoading() {
    final localizations = AppLocalizations.of(context);

    if (!ApiKeys.hasGoogleMapsKey) {
      _showApiKeyInfo();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorLoadingMap = false;
      _errorMessage = '';
    });

    switch (widget.mode) {
      case MapMode.homeView:
        _loadUserLocation();
        _loadFishingSpots();
        break;
      case MapMode.selectLocation:
      case MapMode.editLocation:
        _loadUserLocation();
        break;
    }
  }

  void _showApiKeyInfo() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Text(
            localizations.translate('google_maps_setup'),
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
                localizations.translate('google_maps_api_key_required'),
                style: TextStyle(color: AppConstants.textColor),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.translate('api_key_setup_instructions'),
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
                localizations.translate('understood'),
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🎣 ИНФОРМАЦИЯ О ЗАМЕТКЕ РЫБАЛКИ (только для режима homeView)
  void _showFishingNoteInfo(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    Icons.location_on,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.location,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        localizations.translate(note.fishingType),
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppConstants.textColor),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.calendar_today,
              localizations.translate('date'),
              note.isMultiDay && note.endDate != null
                  ? '${_formatDate(note.date)} - ${_formatDate(note.endDate!)}'
                  : _formatDate(note.date),
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.set_meal,
              localizations.translate('bite_records'),
              '${note.biteRecords.length} ${_getBiteRecordsText(note.biteRecords.length)}',
            ),

            const SizedBox(height: 12),

            if (note.photoUrls.isNotEmpty)
              _buildInfoRow(
                Icons.photo_library,
                localizations.translate('photos'),
                '${note.photoUrls.length} ${localizations.translate('photos')}',
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToFishingSpot(note);
                    },
                    icon: Icon(
                      Icons.navigation,
                      color: AppConstants.textColor,
                      size: 20,
                    ),
                    label: Text(
                      localizations.translate('build_route'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getBiteRecordsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поклевка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'поклевки';
    } else {
      return 'поклевок';
    }
  }

  // 🧭 НАВИГАЦИЯ К МЕСТУ РЫБАЛКИ
  Future<void> _navigateToFishingSpot(FishingNoteModel note) async {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNavigationOptionsSheet(note),
    );
  }

  Widget _buildNavigationOptionsSheet(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('choose_map'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppConstants.textColor),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildNavigationOption(
            title: 'Google Maps',
            subtitle: localizations.translate('universal_navigation'),
            icon: Icons.map,
            onTap: () => _openGoogleMaps(note),
          ),

          const SizedBox(height: 12),

          if (Platform.isIOS)
            _buildNavigationOption(
              title: 'Apple Maps',
              subtitle: localizations.translate('ios_navigation'),
              icon: Icons.map_outlined,
              onTap: () => _openAppleMaps(note),
            ),

          if (Platform.isIOS) const SizedBox(height: 12),

          _buildNavigationOption(
            title: localizations.translate('yandex_maps'),
            subtitle: localizations.translate('detailed_russian_maps'),
            icon: Icons.alt_route,
            onTap: () => _openYandexMaps(note),
          ),

          const SizedBox(height: 12),

          _buildNavigationOption(
            title: '2GIS',
            subtitle: localizations.translate('detailed_city_maps'),
            icon: Icons.location_city,
            onTap: () => _open2GIS(note),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavigationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.launch,
              color: AppConstants.textColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(FishingNoteModel note) async {
    Navigator.pop(context);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${note.latitude},${note.longitude}';
    await _launchURL(url, 'Google Maps');
  }

  Future<void> _openAppleMaps(FishingNoteModel note) async {
    Navigator.pop(context);
    final url = 'http://maps.apple.com/?daddr=${note.latitude},${note.longitude}&dirflg=d';
    await _launchURL(url, 'Apple Maps');
  }

  Future<void> _openYandexMaps(FishingNoteModel note) async {
    Navigator.pop(context);
    final url = 'yandexmaps://maps.yandex.ru/?rtext=~${note.latitude},${note.longitude}&rtt=auto';
    await _launchURL(url, 'Яндекс.Карты');
  }

  Future<void> _open2GIS(FishingNoteModel note) async {
    Navigator.pop(context);
    final url = 'dgis://2gis.ru/routeSearch/rsType/car/to/${note.longitude},${note.latitude}';
    await _launchURL(url, '2GIS');
  }

  Future<void> _launchURL(String url, String appName) async {
    final localizations = AppLocalizations.of(context);

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('app_not_installed')}: $appName'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: localizations.translate('install'),
                textColor: Colors.white,
                onPressed: () => _openAppStore(appName),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_opening_app')}: $appName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAppStore(String appName) async {
    String storeUrl = '';

    if (Platform.isAndroid) {
      switch (appName) {
        case 'Google Maps':
          storeUrl = 'https://play.google.com/store/apps/details?id=com.google.android.apps.maps';
          break;
        case 'Яндекс.Карты':
          storeUrl = 'https://play.google.com/store/apps/details?id=ru.yandex.yandexmaps';
          break;
        case '2GIS':
          storeUrl = 'https://play.google.com/store/apps/details?id=ru.dublgis.dgismobile';
          break;
      }
    } else if (Platform.isIOS) {
      switch (appName) {
        case 'Google Maps':
          storeUrl = 'https://apps.apple.com/app/google-maps/id585027354';
          break;
        case 'Яндекс.Карты':
          storeUrl = 'https://apps.apple.com/app/yandex-maps/id313877526';
          break;
        case '2GIS':
          storeUrl = 'https://apps.apple.com/app/2gis/id481627348';
          break;
      }
    }

    if (storeUrl.isNotEmpty) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // 🎯 ДИНАМИЧЕСКИЙ ЗАГОЛОВОК В ЗАВИСИМОСТИ ОТ РЕЖИМА
  String _getAppBarTitle() {
    final localizations = AppLocalizations.of(context);

    switch (widget.mode) {
      case MapMode.homeView:
        return localizations.translate('map');
      case MapMode.selectLocation:
        return localizations.translate('select_map_point');
      case MapMode.editLocation:
        return localizations.translate('edit_location') ?? 'Изменить место';
    }
  }

  // 🎨 ДИНАМИЧЕСКИЕ ДЕЙСТВИЯ В ЗАВИСИМОСТИ ОТ РЕЖИМА
  List<Widget> _getAppBarActions() {
    final localizations = AppLocalizations.of(context);

    switch (widget.mode) {
      case MapMode.homeView:
        return [
          if (ApiKeys.hasGoogleMapsKey)
            IconButton(
              icon: Icon(Icons.refresh, color: AppConstants.textColor),
              onPressed: _retryLoading,
              tooltip: localizations.translate('refresh_map'),
            ),
        ];
      case MapMode.selectLocation:
      case MapMode.editLocation:
        return [
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveLocation,
          ),
        ];
    }
  }

  // 🎈 ДИНАМИЧЕСКИЙ FAB В ЗАВИСИМОСТИ ОТ РЕЖИМА
  Widget? _getFloatingActionButton() {
    final localizations = AppLocalizations.of(context);

    if (_isLoading || _errorLoadingMap || !ApiKeys.hasGoogleMapsKey) {
      return null;
    }

    switch (widget.mode) {
      case MapMode.homeView:
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: FloatingActionButton(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textColor,
            onPressed: _loadUserLocation,
            tooltip: localizations.translate('my_location'),
            child: const Icon(Icons.my_location),
          ),
        );
      case MapMode.selectLocation:
      case MapMode.editLocation:
        return FloatingActionButton(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          onPressed: _determineCurrentPosition,
          heroTag: 'location_button',
          child: const Icon(Icons.my_location),
        );
    }
  }

  FloatingActionButtonLocation? _getFABLocation() {
    switch (widget.mode) {
      case MapMode.homeView:
        return FloatingActionButtonLocation.startFloat;
      case MapMode.selectLocation:
      case MapMode.editLocation:
        return FloatingActionButtonLocation.startFloat;
    }
  }

  // 🎯 СОЗДАНИЕ ЗАМЕТКИ (только для режима homeView)
  void _navigateToCreateNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishingTypeSelectionScreen(),
      ),
    ).then((_) {
      // Обновляем карту после создания заметки
      _loadFishingSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
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
        actions: _getAppBarActions(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Основное содержимое карты
            _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('loading_map'),
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
                          ? localizations.translate('google_maps_not_configured')
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
                          ? localizations.translate('api_key_needed_for_map')
                          : localizations.translate('check_internet_and_location_permissions'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoading,
                      icon: Icon(
                        !ApiKeys.hasGoogleMapsKey ? Icons.info : Icons.refresh,
                      ),
                      label: Text(
                        !ApiKeys.hasGoogleMapsKey
                            ? localizations.translate('more_details')
                            : localizations.translate('try_again'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              mapType: _currentMapType,
              padding: EdgeInsets.only(
                top: 80,
                bottom: MediaQuery.of(context).padding.bottom +
                    (widget.mode == MapMode.homeView ? 80 : 160),
                right: 16,
              ),
            ),

            // Кнопка переключения типа карты
            if (!_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey)
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
                              style: const TextStyle(
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

            // Кнопки зума (только для режимов выбора точки)
            if ((widget.mode == MapMode.selectLocation || widget.mode == MapMode.editLocation) &&
                !_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey)
              Positioned(
                top: 90,
                right: 16,
                child: Column(
                  children: [
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
                    Container(
                      width: 44,
                      height: 1,
                      color: AppConstants.textColor.withValues(alpha: 0.2),
                    ),
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
                            child: Icon(Icons.remove, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Кнопка показа координат (только для режимов выбора точки)
            if ((widget.mode == MapMode.selectLocation || widget.mode == MapMode.editLocation) &&
                !_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey)
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

            // Панель координат (только для режимов выбора точки)
            if (_showCoordinates &&
                (widget.mode == MapMode.selectLocation || widget.mode == MapMode.editLocation))
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
          ],
        ),
      ),
      floatingActionButton: _getFloatingActionButton(),
      floatingActionButtonLocation: _getFABLocation(),

      // Нижняя панель для режимов выбора точки
      bottomNavigationBar: (widget.mode == MapMode.selectLocation || widget.mode == MapMode.editLocation)
          ? Container(
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
      )
          : null,

      // FAB для создания заметки (только в режиме homeView)
      extendBody: widget.mode == MapMode.homeView,
    );
  }
}