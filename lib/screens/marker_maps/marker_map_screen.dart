// Путь: lib/screens/marker_maps/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../widgets/loading_overlay.dart';
// Необходимые импорты для функций
import 'dart:math' as math;
import 'dart:math' show sin, cos, atan2;
import 'dart:ui' as ui;

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
  final _nameController = TextEditingController();
  final _depthController = TextEditingController();
  final _descriptionController = TextEditingController();

  late MarkerMapModel _markerMap;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasChanges = false;

  // Текущий выбранный маркер для просмотра
  Map<String, dynamic>? _selectedMarker;

  // Настройки лучей
  final int _raysCount = 7;
  final double _maxDistance = 200.0;
  final double _distanceStep = 10.0;
  int _selectedRayIndex = -1;
  double _selectedDistance = 0.0;

  // Текущий новый маркер
  String _newMarkerType = 'default';

  // Константные цвета для типов маркеров
  final Map<String, Color> _markerTypeColors = {
    'default': Colors.blue,
    'dropoff': Colors.red,
    'weed': Colors.green,
    'sandbar': Colors.amber,
    'structure': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _markerMap = widget.markerMap;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _depthController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  // Вычисление координат маркера на луче
  Map<String, double> _calculateMarkerPosition(int rayIndex, double distance) {
    // Вычисляем координаты относительно центра лучей внизу экрана
    final angle = _calculateRayAngle(rayIndex);

    // Пропорция расстояния к максимальному расстоянию
    final distanceRatio = distance / _maxDistance;

    // Нормализуем в координаты от 0 до 1, где 0 - нижняя точка, 1 - верхняя граница
    return {
      'rayIndex': rayIndex.toDouble(),
      'distance': distance,
      'ratio': distanceRatio,
      'angle': angle,
    };
  }

  // Вычисление угла луча
  double _calculateRayAngle(int rayIndex) {
    // Распределяем лучи равномерно в диапазоне от 135° до 45° (где 90° - прямо вверх)
    // 0-й луч будет самым левым, последний - самым правым
    final totalAngle = 90.0; // общий угол охвата в градусах (135° - 45° = 90°)
    final angleStep = totalAngle / (_raysCount - 1);
    return (135 - (rayIndex * angleStep)) * (3.14159 / 180); // конвертируем в радианы
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

              // Отображение луча и дистанции
              Row(
                children: [
                  Icon(Icons.straighten, color: AppConstants.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'Луч ${(marker['rayIndex'] + 1).toInt()}, ${marker['distance'].toInt()} м',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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

              // Кнопки управления
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Кнопка редактирования - доступна только в режиме редактирования
                  if (_isEditing)
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditMarkerDialog(marker);
                      },
                    ),
                  const SizedBox(width: 16),
                  // Кнопка удаления - доступна только в режиме редактирования
                  if (_isEditing)
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Удалить'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
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

  // Диалог редактирования маркера
  void _showEditMarkerDialog(Map<String, dynamic> marker) {
    _nameController.text = marker['name'] ?? '';
    _depthController.text = marker['depth'] != null ? marker['depth'].toString() : '';
    _descriptionController.text = marker['description'] ?? '';
    String selectedType = marker['type'] ?? 'default';

    // Сохраняем текущие значения луча и дистанции
    int currentRayIndex = marker['rayIndex'].toInt();
    double currentDistance = marker['distance'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                'Редактирование маркера',
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

                    // Выбор луча
                    Row(
                      children: [
                        Text(
                          'Луч:',
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: currentRayIndex,
                              dropdownColor: AppConstants.surfaceColor,
                              style: TextStyle(color: AppConstants.textColor),
                              items: List.generate(_raysCount, (index) {
                                return DropdownMenuItem<int>(
                                  value: index,
                                  child: Text('Луч ${index + 1}'),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    currentRayIndex = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Дистанция
                    Row(
                      children: [
                        Text(
                          'Дистанция (м):',
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: currentDistance,
                            min: 0,
                            max: _maxDistance,
                            divisions: (_maxDistance / _distanceStep).toInt(),
                            label: currentDistance.toInt().toString(),
                            activeColor: AppConstants.primaryColor,
                            inactiveColor: AppConstants.textColor.withOpacity(0.3),
                            onChanged: (value) {
                              setState(() {
                                currentDistance = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${currentDistance.toInt()} м',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

                    // Тип маркера
                    Text(
                      'Тип маркера:',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: _markerTypeColors.entries.map((entry) {
                        return ChoiceChip(
                          label: Text(_getMarkerTypeName(entry.key)),
                          selected: selectedType == entry.key,
                          backgroundColor: entry.value.withOpacity(0.2),
                          selectedColor: entry.value.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: selectedType == entry.key ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                selectedType = entry.key;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                    // Обновляем маркер
                    final updatedMarker = {
                      ...marker,
                      'name': _nameController.text.trim().isEmpty
                          ? 'Маркер'
                          : _nameController.text.trim(),
                      'rayIndex': currentRayIndex.toDouble(),
                      'distance': currentDistance,
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'description': _descriptionController.text.trim(),
                      'type': selectedType,
                    };

                    // Обновляем в списке
                    _updateMarker(marker['id'], updatedMarker);

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
      },
    );
  }

  // Обновление маркера
  void _updateMarker(String markerId, Map<String, dynamic> updatedMarker) {
    setState(() {
      final index = _markerMap.markers.indexWhere((m) => m['id'] == markerId);
      if (index != -1) {
        _markerMap.markers[index] = updatedMarker;
        _hasChanges = true;
      }
    });
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
    });
  }

  // Добавление нового маркера
  void _addNewMarker() {
    if (_selectedRayIndex < 0 || _selectedDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите луч и дистанцию для добавления маркера'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _nameController.text = '';
    _depthController.text = '';
    _descriptionController.text = '';
    String selectedType = _newMarkerType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                'Новый маркер',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Информация о выбранной позиции
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Луч ${_selectedRayIndex + 1}, ${_selectedDistance.toInt()} м',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    // Тип маркера
                    Text(
                      'Тип маркера:',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: _markerTypeColors.entries.map((entry) {
                        return ChoiceChip(
                          label: Text(_getMarkerTypeName(entry.key)),
                          selected: selectedType == entry.key,
                          backgroundColor: entry.value.withOpacity(0.2),
                          selectedColor: entry.value.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: selectedType == entry.key ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                selectedType = entry.key;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                    // Создаем новый маркер
                    final newMarker = {
                      'id': const Uuid().v4(),
                      'rayIndex': _selectedRayIndex.toDouble(),
                      'distance': _selectedDistance,
                      'name': _nameController.text.trim().isEmpty
                          ? 'Маркер'
                          : _nameController.text.trim(),
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'description': _descriptionController.text.trim(),
                      'type': selectedType,
                      // Сохраняем также угол и соотношение для отображения
                      'angle': _calculateRayAngle(_selectedRayIndex),
                      'ratio': _selectedDistance / _maxDistance,
                    };

                    // Добавляем маркер
                    setState(() {
                      _markerMap.markers.add(newMarker);
                      _hasChanges = true;
                      _newMarkerType = selectedType; // Запоминаем последний выбранный тип
                    });

                    Navigator.pop(context);

                    // Показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Маркер добавлен'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(
                    'Добавить',
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
            ? 'Режим редактирования включен'
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
        child: Column(
          children: [
            // Верхняя часть - маркерная карта и панель управления
            Expanded(
              flex: 3,
              child: _buildMarkerMapView(),
            ),

            // Нижняя часть - список маркеров
            Expanded(
              flex: 2,
              child: _markerMap.markers.isEmpty
                  ? _buildEmptyMarkersState()
                  : _buildMarkersList(),
            ),
          ],
        ),
      ),
      // Кнопка добавления маркера - доступна только в режиме редактирования
      floatingActionButton: _isEditing ? FloatingActionButton(
        onPressed: _selectedRayIndex >= 0 ? _addNewMarker : null,
        backgroundColor: _selectedRayIndex >= 0
            ? AppConstants.primaryColor
            : AppConstants.primaryColor.withOpacity(0.5),
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add_location),
      ) : null,
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

  // Виджет маркерной карты
  Widget _buildMarkerMapView() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
          builder: (context, constraints) {
            // Определяем размеры карты
            final maxHeight = constraints.maxHeight;
            final width = constraints.maxWidth;
            final centerX = width / 2;
            // Нижняя точка лучей (точка 0)
            final originY = maxHeight * 0.95;

            // Сохраняем текущие значения для проверки
            bool hasSelectedRay = _selectedRayIndex >= 0;

            return Stack(
              children: [
                // Лучи и отметки
                CustomPaint(
                  size: Size(width, maxHeight),
                  painter: RaysAndMarkersPainter(
                    rayCount: _raysCount,
                    maxDistance: _maxDistance,
                    distanceStep: _distanceStep,
                    selectedRayIndex: _selectedRayIndex,
                    selectedDistance: _selectedDistance,
                    markers: _markerMap.markers,
                    markerColors: _markerTypeColors,
                    isEditing: _isEditing,
                  ),
                ),

                // Интерактивная область для выбора луча и дистанции
                if (_isEditing)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (details) {
                        // Определяем координаты нажатия относительно центра
                        final touchX = details.localPosition.dx;
                        final touchY = details.localPosition.dy;

                        // Вычисляем расстояние от нижней центральной точки
                        final dx = touchX - centerX;
                        final dy = originY - touchY;

                        if (dy <= 0) return; // Нажатие ниже точки отсчета

                        // Вычисляем угол в радианах
                        double angle = atan2(dy, dx);
                        if (angle < 0) angle += 2 * 3.14159; // Приводим к положительному углу

                        // Проверяем, попадает ли угол в диапазон лучей
                        // Конвертируем угол в градусы
                        double angleDegrees = (angle * 180 / 3.14159) % 360;

                        // Проверяем, находится ли угол в допустимом диапазоне (от 45° до 135°)
                        if (angleDegrees >= 45 && angleDegrees <= 135) {
                          // Находим ближайший луч
                          double rayFraction = (_raysCount - 1) * (135 - angleDegrees) / 90;
                          int rayIndex = rayFraction.round();
                          rayIndex = rayIndex.clamp(0, _raysCount - 1);

                          // Вычисляем дистанцию в метрах
                          // Гипотенуза треугольника - это дистанция
                          double distance = sqrt(dx * dx + dy * dy);
                          // Нормализуем относительно максимальной высоты карты
                          distance = (distance / maxHeight) * _maxDistance * 1.05; // Коэффициент для компенсации
                          // Округляем до шага дистанции
                          distance = (distance / _distanceStep).round() * _distanceStep;
                          // Ограничиваем значением максимальной дистанции
                          distance = distance.clamp(0.0, _maxDistance);

                          setState(() {
                            _selectedRayIndex = rayIndex;
                            _selectedDistance = distance;
                          });
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        color: Colors.transparent, // Важно добавить цвет, чтобы GestureDetector работал
                      ),
                    ),
                  ),

                // Текущие выбранные параметры
                if (_isEditing && hasSelectedRay)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Луч: ${_selectedRayIndex + 1}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Дистанция: ${_selectedDistance.toInt()} м',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
      ),
    );
  }

  // Пустое состояние, когда нет маркеров
  Widget _buildEmptyMarkersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            color: AppConstants.textColor.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'На этой карте пока нет маркеров',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            Text(
              'Выберите луч и дистанцию на карте,\nзатем добавьте маркер',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Список маркеров
  Widget _buildMarkersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Список маркеров (${_markerMap.markers.length})',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Отображаем все маркеры в виде списка
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _markerMap.markers.length,
            itemBuilder: (context, index) {
              final marker = _markerMap.markers[index];
              return _buildMarkerItem(marker);
            },
          ),
        ),
      ],
    );
  }

  // Элемент списка маркеров
  Widget _buildMarkerItem(Map<String, dynamic> marker) {
    final markerType = marker['type'] ?? 'default';
    final Color markerColor = _markerTypeColors[markerType] ?? Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: markerColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: markerColor,
            size: 24,
          ),
        ),
        title: Text(
          marker['name'] ?? 'Маркер',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Луч ${(marker['rayIndex'] + 1).toInt()}, ${marker['distance'].toInt()} м',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            if (marker['depth'] != null)
              Text(
                'Глубина: ${marker['depth']} м',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _isEditing
            ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteMarker(marker),
        )
            : null,
        onTap: () => _showMarkerDetails(marker),
      ),
    );
  }
}

// Кастомная отрисовка лучей и маркеров
class RaysAndMarkersPainter extends CustomPainter {
  final int rayCount;
  final double maxDistance;
  final double distanceStep;
  final int selectedRayIndex;
  final double selectedDistance;
  final List<Map<String, dynamic>> markers;
  final Map<String, Color> markerColors;
  final bool isEditing;

  RaysAndMarkersPainter({
    required this.rayCount,
    required this.maxDistance,
    required this.distanceStep,
    required this.selectedRayIndex,
    required this.selectedDistance,
    required this.markers,
    required this.markerColors,
    required this.isEditing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final originY = size.height * 0.95; // Нижняя точка

    // Фон для маркерной карты (добавлено)
    paint.color = AppConstants.surfaceColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Вычисляем масштаб для перевода метров в пиксели
    final pixelsPerMeter = (size.height * 0.9) / maxDistance;

    // Отрисовка лучей
    for (int i = 0; i < rayCount; i++) {
      final isSelected = i == selectedRayIndex;

      // Вычисляем угол для текущего луча
      // Распределяем равномерно в диапазоне от 135° до 45°
      final totalAngle = 90.0; // общий угол охвата
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = 135 - (i * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);

      // Конечная точка луча (максимальная дистанция)
      final maxDy = originY - (maxDistance * pixelsPerMeter);
      final maxDx = centerX + (originY - maxDy) * math.tan(math.pi/2 - angleRadians);

      // Создаем кисть для луча (выбранный луч выделяем)
      final rayPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white.withOpacity(0.4)
        ..strokeWidth = isSelected ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      // Рисуем основной луч
      canvas.drawLine(
        Offset(centerX, originY),
        Offset(maxDx, maxDy),
        rayPaint,
      );

      // Рисуем отметки дистанции на луче
      for (double d = distanceStep; d <= maxDistance; d += distanceStep) {
        // Находим точку на луче
        final ratio = d / maxDistance;
        final dx = centerX + (maxDx - centerX) * ratio;
        final dy = originY - (originY - maxDy) * ratio;

        // Радиус точки зависит от шага
        double radius;
        if (d % (distanceStep * 5) == 0) {
          // Каждые 50 метров - большая точка
          radius = 4.0;
        } else {
          // Обычные точки
          radius = 2.0;
        }

        // Если это выбранное расстояние на выбранном луче, выделяем
        bool isSelectedDistance = isSelected && (d == selectedDistance);

        // Рисуем точку
        final pointPaint = Paint()
          ..color = isSelectedDistance ? Colors.yellow : (isSelected ? Colors.white : Colors.white.withOpacity(0.4))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(dx, dy),
          isSelectedDistance ? radius * 1.5 : radius,
          pointPaint,
        );

        // Для круглых отметок дистанции добавляем текст
        if (d % (distanceStep * 5) == 0) {
          // Вычисляем смещение для текста
          final textOffsetX = (dx > centerX) ? 14.0 : -34.0;

          // Рисуем текст
          final textPainter = TextPainter(
            text: TextSpan(
              text: d.toInt().toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(dx + textOffsetX, dy - 6),
          );
        }
      }

      // Надпись с номером луча
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Луч ${i + 1}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      // Размещаем текст над лучом
      final textDx = maxDx + ((maxDx > centerX) ? 5 : -textPainter.width - 5);
      textPainter.paint(
        canvas,
        Offset(textDx, maxDy - textPainter.height - 5),
      );
    }

    // Отрисовка маркеров
    for (final marker in markers) {
      // Получаем координаты из сохраненных в маркере данных
      final rayIndex = marker['rayIndex'] as double? ?? 0;
      final distance = marker['distance'] as double? ?? 0;

      // Вычисляем угол для луча
      final totalAngle = 90.0;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = 135 - (rayIndex * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);

      // Вычисляем позицию маркера
      final ratio = distance / maxDistance;
      final maxDy = originY - (maxDistance * pixelsPerMeter);
      final maxDx = centerX + (originY - maxDy) * math.tan(math.pi/2 - angleRadians);

      final dx = centerX + (maxDx - centerX) * ratio;
      final dy = originY - (originY - maxDy) * ratio;

      // Определяем цвет по типу маркера
      final markerType = marker['type'] ?? 'default';
      final markerColor = markerColors[markerType] ?? Colors.blue;

      // Рисуем маркер
      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      // Рисуем кружок
      canvas.drawCircle(
        Offset(dx, dy),
        8,
        markerPaint,
      );

      // Добавляем обводку
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(
        Offset(dx, dy),
        8,
        strokePaint,
      );
    }

    // Выделяем выбранную точку (в режиме редактирования)
    if (isEditing && selectedRayIndex >= 0 && selectedDistance > 0) {
      // Вычисляем позицию выбранной точки
      final totalAngle = 90.0;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = 135 - (selectedRayIndex * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);

      final ratio = selectedDistance / maxDistance;
      final maxDy = originY - (maxDistance * pixelsPerMeter);
      final maxDx = centerX + (originY - maxDy) * math.tan(math.pi/2 - angleRadians);

      final dx = centerX + (maxDx - centerX) * ratio;
      final dy = originY - (originY - maxDy) * ratio;

      // Рисуем маркер выбранной точки
      final selectedPointPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dx, dy),
        6,
        selectedPointPaint,
      );

      // Добавляем пульсирующую обводку
      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
        Offset(dx, dy),
        10,
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Вспомогательная функция для вычисления тангенса
double tan(double radians) {
  return sin(radians) / cos(radians);
}

// Вспомогательная функция для вычисления квадратного корня
double sqrt(double value) {
  return value <= 0 ? 0 : math.sqrt(value);
}

