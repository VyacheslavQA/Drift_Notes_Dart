// Путь: lib/screens/map/map_screen.dart

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

  // НОВОЕ: Список заметок для построения маршрутов
  List<FishingNoteModel> _fishingNotes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMapType();

    // Проверяем API ключ при инициализации
    if (ApiKeys.hasGoogleMapsKey) {
      // Не вызываем методы с локализацией здесь
      _loadUserLocationWithoutLocalization();
      _loadFishingSpotsWithoutLocalization();
    } else {
      // Если ключа нет, сразу показываем ошибку
      setState(() {
        _isLoading = false;
        _errorLoadingMap = true;
        _errorMessage = 'Google Maps API ключ не настроен';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Здесь уже можно безопасно использовать локализацию
    if (_errorLoadingMap &&
        _errorMessage == 'Google Maps API ключ не настроен') {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _errorMessage = localizations.translate('google_maps_not_configured');
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

    return SafeArea(
      child: Container(
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
                    icon: Icon(Icons.close, color: AppConstants.textColor),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
      ),
    );
  }

  // Опция выбора типа карты
  Widget _buildMapTypeOption(
      MapType mapType,
      String title,
      String description,
      IconData icon,
      ) {
    final isSelected = _currentMapType == mapType;

    return InkWell(
      onTap: () => _changeMapType(mapType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
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
                color:
                isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color:
                isSelected
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

  // НОВЫЙ МЕТОД: Показ информации о заметке рыбалки с возможностью построения маршрута
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
            // Заголовок
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

            // Информация о рыбалке
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

            // Кнопки действий
            Row(
              children: [
                // Кнопка "Построить маршрут"
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

  // НОВЫЙ МЕТОД: Построение строки информации
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

  // НОВЫЙ МЕТОД: Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // НОВЫЙ МЕТОД: Склонение слова "поклевка"
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

  // НОВЫЙ МЕТОД: Построение маршрута до места рыбалки
  Future<void> _navigateToFishingSpot(FishingNoteModel note) async {
    final localizations = AppLocalizations.of(context);

    // Показываем выбор навигационных приложений
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNavigationOptionsSheet(note),
    );
  }

  // НОВЫЙ МЕТОД: BottomSheet с выбором навигационных приложений
  Widget _buildNavigationOptionsSheet(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
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

          // Google Maps
          _buildNavigationOption(
            title: 'Google Maps',
            subtitle: localizations.translate('universal_navigation'),
            icon: Icons.map,
            onTap: () => _openGoogleMaps(note),
          ),

          const SizedBox(height: 12),

          // Apple Maps (только для iOS)
          if (Platform.isIOS)
            _buildNavigationOption(
              title: 'Apple Maps',
              subtitle: localizations.translate('ios_navigation'),
              icon: Icons.map_outlined,
              onTap: () => _openAppleMaps(note),
            ),

          if (Platform.isIOS) const SizedBox(height: 12),

          // Яндекс.Карты
          _buildNavigationOption(
            title: localizations.translate('yandex_maps'),
            subtitle: localizations.translate('detailed_russian_maps'),
            icon: Icons.alt_route,
            onTap: () => _openYandexMaps(note),
          ),

          const SizedBox(height: 12),

          // 2GIS
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

  // НОВЫЙ МЕТОД: Построение опции навигации
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

  // НОВЫЕ МЕТОДЫ: Открытие различных навигационных приложений
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

  // НОВЫЙ МЕТОД: Универсальный запуск URL
  Future<void> _launchURL(String url, String appName) async {
    final localizations = AppLocalizations.of(context);

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Если приложение не установлено, показываем сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations.translate('app_not_installed')}: $appName',
              ),
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
            content: Text(
              '${localizations.translate('error_opening_app')}: $appName',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // НОВЫЙ МЕТОД: Открытие магазина приложений
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

  // Загрузка текущей геолокации пользователя БЕЗ локализации (для initState)
  Future<void> _loadUserLocationWithoutLocalization() async {
    try {
      // Проверяем разрешения геолокации
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
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
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
          _errorMessage = 'Ошибка определения местоположения: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Загрузка текущей геолокации пользователя С локализацией (для кнопок)
  Future<void> _loadUserLocation() async {
    final localizations = AppLocalizations.of(context);

    try {
      // Проверяем разрешения геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = localizations.translate(
              'location_services_disabled',
            );
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
              _errorMessage = localizations.translate(
                'location_permission_denied',
              );
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorLoadingMap = true;
            _errorMessage = localizations.translate(
              'location_permission_denied_forever',
            );
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

          // Обновляем маркер текущей позиции
          _markers.removeWhere(
                (marker) => marker.markerId.value == 'currentLocation',
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(
                title: localizations.translate('your_location'),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );

          _isLoading = false;
          _errorLoadingMap = false;
          _errorMessage = '';
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
          _errorMessage = '${localizations.translate('location_error')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ОБНОВЛЕНО: Загрузка точек рыбалки пользователя БЕЗ локализации (для initState)
  Future<void> _loadFishingSpotsWithoutLocalization() async {
    try {
      final fishingNotes = await _fishingNoteRepository.getUserFishingNotes();

      // Фильтруем заметки, у которых есть координаты
      final notesWithCoordinates =
      fishingNotes
          .where((note) => note.latitude != 0 && note.longitude != 0)
          .toList();

      // НОВОЕ: Сохраняем заметки для построения маршрутов
      _fishingNotes = notesWithCoordinates;

      // Создаем маркеры для каждой точки рыбалки
      for (var note in notesWithCoordinates) {
        _markers.add(
          Marker(
            markerId: MarkerId(note.id),
            position: LatLng(note.latitude, note.longitude),
            infoWindow: InfoWindow(
              title: note.location,
              snippet:
              note.isMultiDay
                  ? 'Дата: ${note.date.day}.${note.date.month}.${note.date.year} - ${note.endDate!.day}.${note.endDate!.month}.${note.endDate!.day}'
                  : 'Дата: ${note.date.day}.${note.date.month}.${note.date.year}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            // НОВОЕ: Обработчик нажатия на маркер
            onTap: () {
              _showFishingNoteInfo(note);
            },
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

  // ОБНОВЛЕНО: Загрузка точек рыбалки пользователя С локализацией
  Future<void> _loadFishingSpots() async {
    final localizations = AppLocalizations.of(context);

    try {
      final fishingNotes = await _fishingNoteRepository.getUserFishingNotes();

      // Фильтруем заметки, у которых есть координаты
      final notesWithCoordinates =
      fishingNotes
          .where((note) => note.latitude != 0 && note.longitude != 0)
          .toList();

      // НОВОЕ: Сохраняем заметки для построения маршрутов
      _fishingNotes = notesWithCoordinates;

      // Очищаем старые маркеры рыбалки
      _markers.removeWhere(
            (marker) => marker.markerId.value != 'currentLocation',
      );

      // Создаем маркеры для каждой точки рыбалки
      for (var note in notesWithCoordinates) {
        _markers.add(
          Marker(
            markerId: MarkerId(note.id),
            position: LatLng(note.latitude, note.longitude),
            infoWindow: InfoWindow(
              title: note.location,
              snippet:
              note.isMultiDay
                  ? '${localizations.translate('date')}: ${note.date.day}.${note.date.month}.${note.date.year} - ${note.endDate!.day}.${note.endDate!.month}.${note.endDate!.day}'
                  : '${localizations.translate('date')}: ${note.date.day}.${note.date.month}.${note.date.year}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            // НОВОЕ: Обработчик нажатия на маркер
            onTap: () {
              _showFishingNoteInfo(note);
            },
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
            content: Text(
              '${localizations.translate('error_loading_fishing_spots')}: $e',
            ),
          ),
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
    final localizations = AppLocalizations.of(context);

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
              tooltip: localizations.translate('refresh_map'),
            ),
        ],
      ),
      body: SafeArea(
        // ИСПРАВЛЕНИЕ: Используем SafeArea для учета системных зон
        child: Stack(
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
                      color:
                      !ApiKeys.hasGoogleMapsKey
                          ? Colors.orange
                          : AppConstants.textColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      !ApiKeys.hasGoogleMapsKey
                          ? localizations.translate(
                        'google_maps_not_configured',
                      )
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
                          : localizations.translate(
                        'check_internet_and_location_permissions',
                      ),
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
                        !ApiKeys.hasGoogleMapsKey
                            ? Icons.info
                            : Icons.refresh,
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
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Отключаем стандартную кнопку
              mapType: _currentMapType, // Используем выбранный тип карты
              zoomControlsEnabled: true, // Включаем стандартные кнопки зума
              compassEnabled: true,
              // ИСПРАВЛЕНИЕ: Добавляем отступы для кнопок зума
              padding: EdgeInsets.only(
                top: 80, // Отступ сверху для кнопки "Слои"
                bottom: MediaQuery.of(context).padding.bottom + 80, // Отступ снизу для навигации + FAB
                right: 16, // Небольшой отступ справа
              ),
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
          ],
        ),
      ),

      // FAB для местоположения (слева внизу, но с учетом навигации)
      floatingActionButton:
      !_isLoading && !_errorLoadingMap && ApiKeys.hasGoogleMapsKey
          ? Padding(
        // ИСПРАВЛЕНИЕ: Добавляем отступ снизу для FAB
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10, // Отступ от навигации
        ),
        child: FloatingActionButton(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          onPressed: _loadUserLocation,
          tooltip: localizations.translate('my_location'),
          child: const Icon(Icons.my_location),
        ),
      )
          : null,
      floatingActionButtonLocation:
      FloatingActionButtonLocation.startFloat, // Слева внизу
    );
  }
}