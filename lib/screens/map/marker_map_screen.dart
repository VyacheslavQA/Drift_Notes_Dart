// Путь: lib/screens/map/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';

class MarkerMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> existingMarkers;

  const MarkerMapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.existingMarkers,
  }) : super(key: key);

  @override
  _MarkerMapScreenState createState() => _MarkerMapScreenState();
}

class _MarkerMapScreenState extends State<MarkerMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Список маркеров для хранения всех данных
  List<Map<String, dynamic>> _markerData = [];

  // Текущий выбранный маркер
  Map<String, dynamic>? _selectedMarker;

  // Контроллеры для текстовых полей при добавлении/редактировании маркера
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Если есть существующие маркеры, добавляем их
    if (widget.existingMarkers.isNotEmpty) {
      _markerData = List.from(widget.existingMarkers);
      _updateMapMarkers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  // Метод для обновления маркеров на карте
  void _updateMapMarkers() {
    setState(() {
      _markers = _markerData.map((data) {
        return Marker(
          markerId: MarkerId(data['id'].toString()),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(
            title: data['name'] ?? 'Маркер',
            snippet: data['depth'] != null
                ? 'Глубина: ${data['depth']} м'
                : 'Нажмите для подробностей',
          ),
          icon: _getMarkerIcon(data['type']),
          onTap: () {
            _showMarkerDetails(data);
          },
        );
      }).toSet();
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

  // Отображение диалога подтверждения удаления маркера
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
      _markerData.removeWhere((item) => item['id'] == marker['id']);
      _updateMapMarkers();
    });
  }

  // Показ диалога добавления/редактирования маркера
  void _showEditMarkerDialog(Map<String, dynamic>? marker) {
    final bool isEditing = marker != null;

    // Если редактируем существующий маркер, заполняем поля
    if (isEditing) {
      _nameController.text = marker['name'] ?? '';
      _descriptionController.text = marker['description'] ?? '';
      _depthController.text = marker['depth'] != null ? marker['depth'].toString() : '';
    } else {
      // Если создаем новый маркер, очищаем поля
      _nameController.clear();
      _descriptionController.clear();
      _depthController.clear();
    }

    // Выбранный тип маркера
    String selectedType = isEditing ? (marker['type'] ?? 'default') : 'default';

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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
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
                      _updateMarker(marker, selectedType);
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
    final index = _markerData.indexWhere((m) => m['id'] == marker['id']);
    if (index != -1) {
      setState(() {
        _markerData[index] = {
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
        _updateMapMarkers();
      });
    }
  }

  // Добавление нового маркера
  void _addNewMarker(String type) {
    final id = const Uuid().v4();
    setState(() {
      _markerData.add({
        'id': id,
        'latitude': _selectedMarker != null
            ? _selectedMarker!['latitude']
            : widget.latitude,
        'longitude': _selectedMarker != null
            ? _selectedMarker!['longitude']
            : widget.longitude,
        'name': _nameController.text.trim().isEmpty
            ? 'Маркер ${_markerData.length + 1}'
            : _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'depth': _depthController.text.isEmpty
            ? null
            : double.tryParse(_depthController.text),
        'type': type,
      });
      _updateMapMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Маркерная карта',
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
          // Кнопка сохранения маркеров
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: () {
              Navigator.pop(context, _markerData);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Устанавливаем темную тему карты
              _mapController!.setMapStyle(_mapStyle);

              setState(() {
                _isLoading = false;
              });

              // Обновляем маркеры на карте
              _updateMapMarkers();
            },
            markers: _markers,
            onTap: (position) {
              setState(() {
                _selectedMarker = {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                };
              });
              _showEditMarkerDialog(null);
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: MapType.hybrid,
          ),

          // Индикатор загрузки
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                ),
              ),
            ),

          // Информационная панель
          Positioned(
            bottom: 100,
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
                    'Маркеры: ${_markerData.length}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите на карту, чтобы добавить новый маркер. Нажмите на существующий маркер для просмотра деталей.',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Кнопка моего местоположения
          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location_button',
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(widget.latitude, widget.longitude),
                    15.0,
                  ),
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Кнопка добавления нового маркера
          Positioned(
            bottom: 30,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'add_button',
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              onPressed: () {
                setState(() {
                  _selectedMarker = {
                    'latitude': widget.latitude,
                    'longitude': widget.longitude,
                  };
                });
                _showEditMarkerDialog(null);
              },
              child: const Icon(Icons.add_location_alt),
            ),
          ),
        ],
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
          "color": "#000000"
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