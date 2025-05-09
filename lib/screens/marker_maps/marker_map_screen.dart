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
import 'dart:math' show sin, cos, atan2, sqrt;
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
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();

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

  // Типы дна для маркеров
  final List<String> _bottomTypes = [
    'ил',
    'глубокий_ил',
    'ракушка',
    'ровно_твердо',
    'камни',
    'трава_водоросли',
    'зацеп',
    'бугор',
    'точка_кормления'
  ];

  // Текущий тип дна для нового маркера
  String _currentBottomType = 'ил';

  // Константные цвета для типов дна маркеров
  final Map<String, Color> _bottomTypeColors = {
    'ил': Colors.brown.shade400,
    'глубокий_ил': Colors.brown.shade800,
    'ракушка': Colors.cyan,
    'ровно_твердо': Colors.amber,
    'камни': Colors.grey,
    'трава_водоросли': Colors.green,
    'зацеп': Colors.red,
    'бугор': Colors.orange,
    'точка_кормления': Colors.deepPurple,
    'default': Colors.blue, // для обратной совместимости
  };

  // Иконки для типов дна
  final Map<String, IconData> _bottomTypeIcons = {
    'ил': Icons.terrain,
    'глубокий_ил': Icons.filter_hdr,
    'ракушка': Icons.waves,
    'ровно_твердо': Icons.view_agenda,
    'камни': Icons.circle,
    'трава_водоросли': Icons.grass,
    'зацеп': Icons.warning,
    'бугор': Icons.landscape,
    'точка_кормления': Icons.room_service,
    'default': Icons.location_on, // для обратной совместимости
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
    _notesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  // Получение названия типа дна
  String _getBottomTypeName(String? type) {
    if (type == null) return 'Ил';

    switch (type) {
      case 'ил':
        return 'Ил';
      case 'глубокий_ил':
        return 'Глубокий ил';
      case 'ракушка':
        return 'Ракушка';
      case 'ровно_твердо':
        return 'Ровно/Твердо';
      case 'камни':
        return 'Камни';
      case 'трава_водоросли':
        return 'Трава/Водоросли';
      case 'зацеп':
        return 'Зацеп';
      case 'бугор':
        return 'Бугор';
      case 'точка_кормления':
        return 'Точка кормления';
    // Для обратной совместимости со старыми типами
      case 'dropoff':
        return 'Свал';
      case 'weed':
        return 'Растительность';
      case 'sandbar':
        return 'Песчаная отмель';
      case 'structure':
        return 'Структура';
      case 'default':
        return 'Обычный';
      default:
        return 'Ил';
    }
  }

  // Конвертация старых типов в новые (для совместимости)
  String _convertLegacyTypeToNew(String? type) {
    if (type == null) return 'ил';

    switch (type) {
      case 'dropoff':
        return 'свал';
      case 'weed':
        return 'трава_водоросли';
      case 'sandbar':
        return 'ровно_твердо';
      case 'structure':
        return 'зацеп';
      case 'default':
        return 'ил';
      default:
        return type; // Возвращаем как есть, если это новый тип
    }
  }

  // Вычисление угла луча
  double _calculateRayAngle(int rayIndex) {
    // Распределяем лучи равномерно в диапазоне от 110° до 70° (где 90° - прямо вверх)
    // 0-й луч будет самым левым, последний - самым правым
    final totalAngle = 40.0; // общий угол охвата в градусах (110° - 70° = 40°)
    final angleStep = totalAngle / (_raysCount - 1);
    return (110 - (rayIndex * angleStep)) * (math.pi / 180); // конвертируем в радианы
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

              // Тип дна
              if (marker['bottomType'] != null || marker['type'] != null) ...[
                Row(
                  children: [
                    Icon(
                        _getBottomTypeIcon(marker['bottomType'] ?? marker['type']),
                        color: AppConstants.textColor
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Тип дна: ${_getBottomTypeName(marker['bottomType'] ?? marker['type'])}',
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
              if (marker['notes'] != null && marker['notes'].isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        marker['notes'],
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (marker['description'] != null && marker['description'].isNotEmpty) ...[
                // Для обратной совместимости
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

              const SizedBox(height: 16),

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

  // Получение иконки для типа дна
  IconData _getBottomTypeIcon(String? type) {
    if (type == null) return Icons.terrain;

    // Пробуем конвертировать старый тип в новый
    final newType = _convertLegacyTypeToNew(type);

    return _bottomTypeIcons[newType] ?? Icons.terrain;
  }

  // Диалог добавления нового маркера
  void _showAddMarkerDialog() {
    // Сбрасываем поля формы
    _nameController.text = '';
    _depthController.text = '';
    _notesController.text = '';
    _distanceController.text = '';

    // Настройки для выбора луча и дистанции
    int selectedRayIndex = 0;
    String selectedBottomType = 'ил';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                'Добавление маркера',
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

                    // Выбор луча через выпадающий список
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
                              value: selectedRayIndex,
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
                                    selectedRayIndex = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ввод дистанции цифрами
                    TextField(
                      controller: _distanceController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Дистанция (м)',
                        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
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

                    // Тип дна
                    Text(
                      'Тип дна:',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor: _bottomTypeColors[type]?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                          selectedColor: _bottomTypeColors[type]?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: selectedBottomType == type ? FontWeight.bold : FontWeight.normal,
                          ),
                          avatar: Icon(
                            _bottomTypeIcons[type],
                            color: selectedBottomType == type ?
                            AppConstants.textColor : AppConstants.textColor.withOpacity(0.7),
                            size: 18,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                selectedBottomType = type;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Заметки
                    TextField(
                      controller: _notesController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Заметки',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                  ),
                  onPressed: () {
                    // Проверка валидности ввода
                    if (_distanceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите дистанцию'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(_distanceController.text);
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите корректное числовое значение для дистанции'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Ограничиваем дистанцию максимальным значением
                    if (distance > _maxDistance) {
                      distance = _maxDistance;
                    } else if (distance < 0) {
                      distance = 0;
                    }

                    // Создаем новый маркер
                    final newMarker = {
                      'id': const Uuid().v4(),
                      'rayIndex': selectedRayIndex.toDouble(),
                      'distance': distance,
                      'name': _nameController.text.trim().isEmpty
                          ? 'Маркер'
                          : _nameController.text.trim(),
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'notes': _notesController.text.trim(),
                      'bottomType': selectedBottomType,
                      // Сохраняем также угол и соотношение для отображения
                      'angle': _calculateRayAngle(selectedRayIndex),
                      'ratio': distance / _maxDistance,
                    };

                    // Добавляем маркер
                    setState(() {
                      _markerMap.markers.add(newMarker);
                      _hasChanges = true;
                      _currentBottomType = selectedBottomType; // Запоминаем последний выбранный тип
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
                  child: const Text(
                    'Добавить',
                    style: TextStyle(
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

  // Диалог редактирования маркера
  void _showEditMarkerDialog(Map<String, dynamic> marker) {
    _nameController.text = marker['name'] ?? '';
    _depthController.text = marker['depth'] != null ? marker['depth'].toString() : '';
    _notesController.text = marker['notes'] ?? marker['description'] ?? '';
    _distanceController.text = marker['distance'].toString();

    // Определяем тип дна (с учетом обратной совместимости)
    String selectedBottomType = marker['bottomType'] ?? _convertLegacyTypeToNew(marker['type']) ?? 'ил';

    // Сохраняем текущие значения луча
    int currentRayIndex = marker['rayIndex'].toInt();

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

                    // Ввод дистанции цифрами
                    TextField(
                      controller: _distanceController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Дистанция (м)',
                        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
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

                    // Тип дна маркера
                    Text(
                      'Тип дна:',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor: _bottomTypeColors[type]?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                          selectedColor: _bottomTypeColors[type]?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: selectedBottomType == type ? FontWeight.bold : FontWeight.normal,
                          ),
                          avatar: Icon(
                            _bottomTypeIcons[type],
                            color: selectedBottomType == type ?
                            AppConstants.textColor : AppConstants.textColor.withOpacity(0.7),
                            size: 18,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                selectedBottomType = type;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Заметки
                    TextField(
                      controller: _notesController,
                      style: TextStyle(color: AppConstants.textColor),
                      decoration: InputDecoration(
                        labelText: 'Заметки',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                  ),
                  onPressed: () {
                    // Проверка валидности ввода
                    if (_distanceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите дистанцию'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(_distanceController.text);
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите корректное числовое значение для дистанции'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Ограничиваем дистанцию максимальным значением
                    if (distance > _maxDistance) {
                      distance = _maxDistance;
                    } else if (distance < 0) {
                      distance = 0;
                    }

                    // Обновляем маркер
                    final updatedMarker = {
                      ...marker,
                      'name': _nameController.text.trim().isEmpty
                          ? 'Маркер'
                          : _nameController.text.trim(),
                      'rayIndex': currentRayIndex.toDouble(),
                      'distance': distance,
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'notes': _notesController.text.trim(),
                      'bottomType': selectedBottomType,
                      // Обновляем угол и соотношение
                      'angle': _calculateRayAngle(currentRayIndex),
                      'ratio': distance / _maxDistance,
                    };

                    // Удаляем старые поля, если они существуют (для обратной совместимости)
                    updatedMarker.remove('type');
                    updatedMarker.remove('description');

                    // Обновляем в списке
                    _updateMarker(marker['id'], updatedMarker);

                    Navigator.pop(context);

                    // Показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Маркер обновлен'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
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

                // Показываем сообщение
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Маркер удален'),
                    backgroundColor: Colors.red,
                  ),
                );
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
              ),
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

                // Показываем сообщение
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Информация обновлена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(
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
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Карта на весь экран - основная часть
              Expanded(
                child: _buildMarkerMapView(),
              ),
            ],
          ),
        ),
      ),
      // Кнопка добавления маркера - доступна только в режиме редактирования
      floatingActionButton: _isEditing ? FloatingActionButton(
        onPressed: _showAddMarkerDialog,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add_location),
      ) : null,
      // Отображаем информацию о карте внизу экрана
      bottomNavigationBar: SizedBox(
        height: 40,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Дата: ${DateFormat('dd.MM.yyyy').format(_markerMap.date)}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (_markerMap.sector != null && _markerMap.sector!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.grid_on,
                      color: AppConstants.textColor.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Сектор: ${_markerMap.sector}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет маркерной карты во весь экран
  Widget _buildMarkerMapView() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F1D), // Темно-зеленый фон для глубины
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textColor.withOpacity(0.2),
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

            return Stack(
              children: [
                // Лучи и отметки
                CustomPaint(
                  size: Size(width, maxHeight),
                  painter: RaysAndMarkersPainter(
                    rayCount: _raysCount,
                    maxDistance: _maxDistance,
                    distanceStep: _distanceStep,
                    markers: _markerMap.markers,
                    bottomTypeColors: _bottomTypeColors,
                    bottomTypeIcons: _bottomTypeIcons,
                    isEditing: _isEditing,
                    onMarkerTap: _showMarkerDetails,
                    context: context,
                  ),
                ),

                // Подсказка при отсутствии маркеров
                if (_markerMap.markers.isEmpty)
                  Center(
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
                            'Нажмите на "+" чтобы добавить маркер',
                            style: TextStyle(
                              color: AppConstants.textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          }
      ),
    );
  }
}

// Кастомная отрисовка лучей и маркеров
class RaysAndMarkersPainter extends CustomPainter {
  final int rayCount;
  final double maxDistance;
  final double distanceStep;
  final List<Map<String, dynamic>> markers;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final bool isEditing;
  final Function(Map<String, dynamic>) onMarkerTap;
  final BuildContext context;

  RaysAndMarkersPainter({
    required this.rayCount,
    required this.maxDistance,
    required this.distanceStep,
    required this.markers,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.isEditing,
    required this.onMarkerTap,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final originY = size.height * 1.00; // Нижняя точка

    // Фон для маркерной карты
    paint.color = const Color(0xFF0B1F1D); // темно-зеленый фон
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Вычисляем масштаб для перевода метров в пиксели
    final pixelsPerMeter = (size.height * 0.9) / maxDistance;

    // Отрисовка лучей
    for (int i = 0; i < rayCount; i++) {
      // Вычисляем угол для текущего луча
      // Распределяем равномерно в диапазоне от 110° до 70°
      final totalAngle = 40.0; // общий угол охвата
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = 110 - (i * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);

      // Конечная точка луча (максимальная дистанция)
      final maxDy = originY - (maxDistance * pixelsPerMeter);
      final maxDx = centerX + (originY - maxDy) * math.tan(math.pi/2 - angleRadians);

      // Создаем кисть для луча
      final rayPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.0
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
          radius = 1.5;
        }

        // Рисуем точку
        final pointPaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(dx, dy),
          radius,
          pointPaint,
        );

        // Для круглых отметок дистанции добавляем текст
        if (d % (distanceStep * 5) == 0) {
          // Текстовые метки (50м, 100м, 150м, 200м)
          final textPainter = TextPainter(
            text: TextSpan(
              text: d.toInt().toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          );

          textPainter.layout();

          // Смещение текста в зависимости от положения луча
          double textOffsetX;
          if (i == 0) {
            textOffsetX = -textPainter.width - 5; // Крайний левый луч
          } else if (i == rayCount - 1) {
            textOffsetX = 5; // Крайний правый луч
          } else {
            textOffsetX = -textPainter.width / 2; // Центрирование для остальных лучей
          }

          textPainter.paint(
            canvas,
            Offset(dx + textOffsetX, dy - textPainter.height / 2),
          );
        }
      }

      // Надпись с номером луча сверху
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Луч ${i + 1}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      // Размещаем текст над лучом
      final textDx = maxDx - textPainter.width / 2;
      final textDy = maxDy - textPainter.height - 5;
      textPainter.paint(
        canvas,
        Offset(textDx, textDy),
      );
    }

    // Отрисовка маркеров
    for (final marker in markers) {
      // Получаем координаты из сохраненных в маркере данных
      final rayIndex = marker['rayIndex'] as double? ?? 0;
      final distance = marker['distance'] as double? ?? 0;

      // Вычисляем угол для луча
      final totalAngle = 40.0;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = 110 - (rayIndex * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);

      // Вычисляем позицию маркера
      final ratio = distance / maxDistance;
      final maxDy = originY - (maxDistance * pixelsPerMeter);
      final maxDx = centerX + (originY - maxDy) * math.tan(math.pi/2 - angleRadians);

      final dx = centerX + (maxDx - centerX) * ratio;
      final dy = originY - (originY - maxDy) * ratio;

      // Определяем цвет по типу дна (с учетом обратной совместимости)
      String bottomType = marker['bottomType'] ?? 'default';
      if (bottomType == 'default' && marker['type'] != null) {
        // Для обратной совместимости
        switch (marker['type']) {
          case 'dropoff': bottomType = 'свал'; break;
          case 'weed': bottomType = 'трава_водоросли'; break;
          case 'sandbar': bottomType = 'ровно_твердо'; break;
          case 'structure': bottomType = 'зацеп'; break;
          default: bottomType = 'ил';
        }
      }

      final markerColor = bottomTypeColors[bottomType] ?? Colors.blue;

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

      // Добавляем внутреннюю точку
      final centerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dx, dy),
        2,
        centerDotPaint,
      );

      // Сохраняем позицию маркера для обработки тапов (хитбокс)
      marker['_hitboxCenter'] = Offset(dx, dy);
      marker['_hitboxRadius'] = 15.0; // Увеличиваем зону нажатия
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool? hitTest(Offset position) {
    // Проверяем, нажал ли пользователь на маркер
    for (final marker in markers) {
      if (marker.containsKey('_hitboxCenter') && marker.containsKey('_hitboxRadius')) {
        final center = marker['_hitboxCenter'] as Offset;
        final radius = marker['_hitboxRadius'] as double;

        if ((center - position).distance <= radius) {
          // Нажатие на маркер
          onMarkerTap(marker);
          return true;
        }
      }
    }
    return null;
  }
}