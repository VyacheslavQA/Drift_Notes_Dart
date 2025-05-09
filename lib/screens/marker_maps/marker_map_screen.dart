// Путь: lib/screens/marker_maps/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../widgets/loading_overlay.dart';

class MarkerMapScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const MarkerMapScreen({
    Key? key,
    required this.markerMap,
  }) : super(key: key);

  @override
  _MarkerMapScreenState createState() => _MarkerMapScreenState();
}

class _MarkerMapScreenState extends State<MarkerMapScreen> {
  final _markerMapRepository = MarkerMapRepository();

  late MarkerMapModel _markerMap;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasChanges = false;

  // Позиция для центра карты
  LatLng _mapCenter = const LatLng(55.751244, 37.618423); // Москва по умолчанию
  final double _defaultZoom = 14.0;

  // Текущий выбранный маркер для редактирования
  Map<String, dynamic>? _selectedMarker;

  // Контроллеры для текстовых полей маркера
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markerMap = widget.markerMap;

    // Если у карты уже есть маркеры, устанавливаем центр на первый маркер
    if (_markerMap.markers.isNotEmpty) {
      final firstMarker = _markerMap.markers.first;
      _mapCenter = LatLng(firstMarker['latitude'], firstMarker['longitude']);
    } else {
      // Иначе пытаемся определить текущее местоположение
      _determinePosition();
    }

    _updateMapMarkers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _depthController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Определение текущего местоположения
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Проверяем, включены ли службы геолокации
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Проверяем разрешения на доступ к геолокации
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Получаем текущее местоположение
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _mapCenter = LatLng(position.latitude, position.longitude);
        });

        // Перемещаем камеру к текущему местоположению
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _mapCenter,
              zoom: _defaultZoom,
            ),
          ),
        );
      }
    } catch (e) {
      print('Ошибка определения местоположения: $e');
    }
  }

  // Обновление маркеров на карте из модели
  void _updateMapMarkers() {
    Set<Marker> markers = {};

    for (var markerData in _markerMap.markers) {
      final markerId = markerData['id'].toString();
      final position = LatLng(
        markerData['latitude'],
        markerData['longitude'],
      );

      markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          infoWindow: InfoWindow(
            title: markerData['name'] ?? 'Маркер',
            snippet: markerData['depth'] != null
                ? 'Глубина: ${markerData['depth']} м'
                : 'Нажмите для подробностей',
          ),
          icon: _getMarkerIcon(markerData['type']),
          onTap: () {
            _showMarkerDetails(markerData);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Получение иконки маркера в зависимости от типа
  BitmapDescriptor _getMarkerIcon(String? type) {
    switch (type) {
      case 'dropoff':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'weed':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'sandbar':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'structure':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  // Получение названия типа маркера
  String _getMarkerTypeName(String? type) {
    switch (type) {
      case 'dropoff':
        return 'Свал';
      case 'weed':
        return 'Растительность';
      case 'sandbar':
        return 'Песчаная отмель';
      case 'structure':
        return 'Структура';
      default:
        return 'Обычный';
    }
  }

  // Показ диалога с деталями маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
    setState(() {
      _selectedMarker = marker;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marker['name'] ?? 'Маркер',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Глубина
              if (marker['depth'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.waves, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Text(
                      'Глубина: ${marker['depth']} м',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Описание
              if (marker['description'] != null && marker['description'].isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        marker['description'],
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Тип
              if (marker['type'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.category, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Text(
                      'Тип: ${_getMarkerTypeName(marker['type'])}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Изменить'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditMarkerDialog(marker);
                    },
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Удалить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteMarker(marker);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Диалог подтверждения удаления маркера
  void _confirmDeleteMarker(Map<String, dynamic> marker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Удалить маркер',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить этот маркер?',
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
                'Отмена',
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteMarker(marker);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Удалить',
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

  // Удаление маркера
  void _deleteMarker(Map<String, dynamic> marker) {
    setState(() {
      _markerMap.markers.removeWhere((item) => item['id'] == marker['id']);
      _hasChanges = true;
      _updateMapMarkers();
    });
  }

  // Показать диалог добавления/редактирования маркера
  void _showEditMarkerDialog(Map<String, dynamic>? marker) {
    final bool isEditing = marker != null;

    // Очищаем или заполняем поля в зависимости от режима
    if (isEditing) {
      _nameController.text = marker['name'] ?? '';
      _descriptionController.text = marker['description'] ?? '';
      _depthController.text = marker['depth'] != null ? marker['depth'].toString() : '';
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _depthController.clear();
    }

    // Выбранный тип маркера
    String selectedType = isEditing ? (marker!['type'] ?? 'default') : 'default';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                isEditing ? 'Редактировать маркер' : 'Новый маркер',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Название маркера
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Название маркера',
                        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Глубина
                    TextField(
                      controller: _depthController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Глубина (м)',
                        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Описание
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Выбор типа маркера
                    Row(
                      children: [
                        Text(
                          'Тип маркера:',
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Типы маркеров
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMarkerTypeOption(
                            'default',
                            'Обычный',
                            BitmapDescriptor.hueAzure,
                            selectedType,
                                (value) {
                              setState(() => selectedType = value);
                            }
                        ),
                        _buildMarkerTypeOption(
                            'dropoff',
                            'Свал',
                            BitmapDescriptor.hueRed,
                            selectedType,
                                (value) {
                              setState(() => selectedType = value);
                            }
                        ),
                        _buildMarkerTypeOption(
                            'weed',
                            'Растительность',
                            BitmapDescriptor.hueGreen,
                            selectedType,
                                (value) {
                              setState(() => selectedType = value);
                            }
                        ),
                        _buildMarkerTypeOption(
                            'sandbar',
                            'Отмель',
                            BitmapDescriptor.hueYellow,
                            selectedType,
                                (value) {
                              setState(() => selectedType = value);
                            }
                        ),
                        _buildMarkerTypeOption(
                            'structure',
                            'Структура',
                            BitmapDescriptor.hueOrange,
                            selectedType,
                                (value) {
                              setState(() => selectedType = value);
                            }
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Отмена',
                    style: TextStyle(
                      color: AppConstants.textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isEditing) {
                      _updateMarker(marker!, selectedType);
                    } else {
                      _addNewMarker(selectedType);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isEditing ? 'Сохранить' : 'Добавить',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Построение опции выбора типа маркера
  Widget _buildMarkerTypeOption(
      String type,
      String label,
      double hue,
      String selectedValue,
      Function(String) onSelect
      ) {
    final isSelected = selectedValue == type;

    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.2)
              : AppConstants.backgroundColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Обновление существующего маркера
  void _updateMarker(Map<String, dynamic> marker, String type) {
    final index = _markerMap.markers.indexWhere((m) => m['id'] == marker['id']);
    if (index != -1) {
      setState(() {
        _markerMap.markers[index] = {
          'id': marker['id'],
          'latitude': marker['latitude'],
          'longitude': marker['longitude'],
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'depth': _depthController.text.isEmpty
              ? null
              : double.tryParse(_depthController.text),
          'type': type,
        };
        _hasChanges = true;
        _updateMapMarkers();
      });
    }
  }

  // Добавление нового маркера
  void _addNewMarker(String type) {
    final id = const Uuid().v4();

    // Получаем текущий центр карты
    final position = _mapController?.cameraPosition?.target ?? _mapCenter;

    setState(() {
      _markerMap.markers.add({
        'id': id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'name': _nameController.text.trim().isEmpty
            ? 'Маркер ${_markerMap.markers.length + 1}'
            : _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'depth': _depthController.text.isEmpty
            ? null
            : double.tryParse(_depthController.text),
        'type': type,
      });
      _hasChanges = true;
      _updateMapMarkers();
    });

    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Маркер добавлен в центр карты'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Показать меню действий
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.add_location,
                  color: AppConstants.textColor,
                ),
                title: Text(
                  'Добавить маркер',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMarkerDialog(null);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: AppConstants.textColor,
                ),
                title: Text(
                  'Изменить название карты',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMapDialog();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Удалить карту',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMap();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Показать диалог редактирования карты
  void _showEditMapDialog() {
    final nameController = TextEditingController(text: _markerMap.name);
    final sectorController = TextEditingController(text: _markerMap.sector ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Изменить информацию',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  labelText: 'Название карты*',
                  labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectorController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  labelText: 'Номер сектора (необязательно)',
                  labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название карты')),
                  );
                  return;
                }

                setState(() {
                  _markerMap = _markerMap.copyWith(
                    name: nameController.text.trim(),
                    sector: sectorController.text.trim().isEmpty
                        ? null
                        : sectorController.text.trim(),
                  );
                  _hasChanges = true;
                });

                Navigator.pop(context);
              },
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Подтверждение удаления карты
  void _confirmDeleteMap() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Удалить карту',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить эту карту? Это действие нельзя отменить.',
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
    'Отмена',
    style: TextStyle(
    color: AppConstants.textColor,
    ),
    ),
    ),
    TextButton(
    onPressed: () {
    Navigator.of(context).pop();
    _deleteMap();
    },
    child: const Text(
    'Удалить',
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

  // Удаление карты
  Future<void> _deleteMap() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _markerMapRepository.deleteMarkerMap(_markerMap.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Карта успешно удалена'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Возвращаемся к списку карт
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении карты: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Сохранение изменений карты
  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _markerMapRepository.updateMarkerMap(_markerMap);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изменения сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении изменений: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Переключение режима редактирования
  void _toggleEditingMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Режим редактирования включен. Нажмите на карту, чтобы добавить маркер.'
            : 'Режим просмотра включен'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _markerMap.name,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Кнопка переключения режима
          IconButton(
            icon: Icon(
              _isEditing ? Icons.visibility : Icons.edit,
              color: AppConstants.textColor,
            ),
            tooltip: _isEditing ? 'Режим просмотра' : 'Режим редактирования',
            onPressed: _toggleEditingMode,
          ),
          // Кнопка сохранения (активна только при наличии изменений)
          IconButton(
            icon: Icon(
              Icons.save,
              color: _hasChanges ? AppConstants.textColor : AppConstants.textColor.withOpacity(0.3),
            ),
            tooltip: 'Сохранить изменения',
            onPressed: _hasChanges ? _saveChanges : null,
          ),
          // Меню действий
          IconButton(
            icon: Icon(Icons.more_vert, color: AppConstants.textColor),
            onPressed: _showActionMenu,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Подождите...',
        child: Stack(
          children: [
            // Карта Google Maps
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _mapCenter,
                zoom: _defaultZoom,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                // Устанавливаем темную тему карты
                _mapController!.setMapStyle(_mapStyle);
              },
              markers: _markers,
              onTap: _isEditing
                  ? (position) {
                // В режиме редактирования создаем новый маркер по клику
                _selectedMarker = {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                };
                _showEditMarkerDialog(null);
              }
                  : null,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapType: MapType.hybrid, // Карта со спутника с дорогами
              zoomControlsEnabled: false,
            ),

            // Информационная панель
            if (_markerMap.markers.isNotEmpty)
              Positioned(
                bottom: 90,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Маркеры: ${_markerMap.markers.length}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing
                            ? 'Нажмите на карту, чтобы добавить новый маркер.'
                            : 'Нажмите на маркер для просмотра деталей.',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Кнопки управления
            Positioned(
              bottom: 30,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка моего местоположения
                  FloatingActionButton(
                    heroTag: 'my_location',
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    mini: true,
                    onPressed: _determinePosition,
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  // Кнопка изменения типа карты (спутник/схема)
                  FloatingActionButton(
                    heroTag: 'map_type',
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    mini: true,
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    mini: true,
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Кнопка добавления маркера (только в режиме редактирования)
      floatingActionButton: _isEditing
          ? FloatingActionButton(
        onPressed: () => _showEditMarkerDialog(null),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add_location),
      )
          : null,
      // Отображаем информацию о карте внизу экрана
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Дата: ${DateFormat('dd.MM.yyyy').format(_markerMap.date)}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (_markerMap.sector != null && _markerMap.sector!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.grid_on,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Сектор: ${_markerMap.sector}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (_markerMap.noteName != null && _markerMap.noteName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.note,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Заметка: ${_markerMap.noteName}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Стиль для темной темы Google Maps
  static const _mapStyle = '''
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
      "featureType": "administrative.land_parcel",
      "stylers": [
        {
          "visibility": "off"
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