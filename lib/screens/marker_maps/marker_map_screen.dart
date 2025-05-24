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
import 'dart:ui' as ui;
import '../../localization/app_localizations.dart';

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
  final _depthController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();

  late MarkerMapModel _markerMap;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Текущий выбранный маркер для просмотра
  Map<String, dynamic>? _selectedMarker;

  // Сохранение последнего выбранного луча
  int _lastSelectedRayIndex = 0;

  // Настройки лучей
  final int _raysCount = 7;
  final double _maxDistance = 200.0;
  final double _distanceStep = 10.0;

  // Параметры угла лучей (скорректированные)
  // Изменено с 110-70 на 105-75 для лучшей видимости крайних лучей
  final double _leftAngle = 105.0;
  final double _rightAngle = 75.0;

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
    _depthController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  // Получение названия типа дна
  String _getBottomTypeName(String? type) {
    final localizations = AppLocalizations.of(context);
    if (type == null) return localizations.translate('silt');

    switch (type) {
      case 'ил':
        return localizations.translate('silt');
      case 'глубокий_ил':
        return localizations.translate('deep_silt');
      case 'ракушка':
        return localizations.translate('shell');
      case 'ровно_твердо':
        return localizations.translate('firm_bottom');
      case 'камни':
        return localizations.translate('stones');
      case 'трава_водоросли':
        return localizations.translate('grass_algae');
      case 'зацеп':
        return localizations.translate('snag');
      case 'бугор':
        return localizations.translate('hill');
      case 'точка_кормления':
        return localizations.translate('feeding_spot');
    // Для обратной совместимости со старыми типами
      case 'dropoff':
        return 'Свал';
      case 'weed':
        return localizations.translate('grass_algae');
      case 'sandbar':
        return localizations.translate('firm_bottom');
      case 'structure':
        return localizations.translate('snag');
      case 'default':
        return localizations.translate('silt');
      default:
        return localizations.translate('silt');
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
    // Распределяем лучи равномерно в диапазоне от _leftAngle до _rightAngle (где 90° - прямо вверх)
    // 0-й луч будет самым левым, последний - самым правым
    final totalAngle = _leftAngle - _rightAngle; // общий угол охвата в градусах
    final angleStep = totalAngle / (_raysCount - 1);
    return (_leftAngle - (rayIndex * angleStep)) * (math.pi / 180); // конвертируем в радианы
  }

  // Показ диалога с деталями маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
    final localizations = AppLocalizations.of(context);
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
                marker['name'] ?? localizations.translate('marker'),
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
                    '${localizations.translate('ray')} ${(marker['rayIndex'] + 1).toInt()}, ${marker['distance'].toInt()} ${localizations.translate('distance_m')}',
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
                      '${localizations.translate('depth')}: ${marker['depth']} ${localizations.translate('m')}',
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
                      '${localizations.translate('marker_type')}: ${_getBottomTypeName(marker['bottomType'] ?? marker['type'])}',
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
                  // Кнопка редактирования
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(localizations.translate('edit')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditMarkerDialog(marker);
                    },
                  ),
                  const SizedBox(width: 16),
                  // Кнопка удаления
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(localizations.translate('delete')),
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

  // Показ информации о маркерах и помощи
  void _showMarkerInfo() {
    final localizations = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('marker_map'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                localizations.translate('marker_types'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Список типов маркеров
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _bottomTypes.map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bottomTypeColors[type]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _bottomTypeColors[type] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _bottomTypeIcons[type],
                          color: _bottomTypeColors[type],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getBottomTypeName(type),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                localizations.translate('how_to_use'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.add_location,
                title: localizations.translate('adding_marker'),
                description: localizations.translate('adding_marker_desc'),
              ),

              _buildInfoItem(
                icon: Icons.touch_app,
                title: localizations.translate('view_details'),
                description: localizations.translate('view_details_desc'),
              ),

              _buildInfoItem(
                icon: Icons.edit,
                title: localizations.translate('editing'),
                description: localizations.translate('editing_desc'),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                  ),
                  child: Text(localizations.translate('close')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Вспомогательный метод для создания элемента справки
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                  description,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final localizations = AppLocalizations.of(context);
    // Сбрасываем поля формы
    _depthController.text = '';
    _notesController.text = '';
    _distanceController.text = '';

    // Используем последний выбранный луч по умолчанию
    int selectedRayIndex = _lastSelectedRayIndex;
    String selectedBottomType = _currentBottomType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                localizations.translate('add_marker_dialog_title'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Выбор луча через выпадающий список
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('ray')}:',
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
                                  child: Text('${localizations.translate('ray')} ${index + 1}'),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedRayIndex = value;
                                  });
                                  // Сохраняем выбранный луч
                                  _lastSelectedRayIndex = value;
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
                       labelText: localizations.translate('distance_m'),
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
                        labelText: localizations.translate('depth_m'),
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
                      '${localizations.translate('marker_type')}:',
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
                        labelText: localizations.translate('notes'),
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
                    localizations.translate('cancel'),
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
                        SnackBar(
                          content: Text(localizations.translate('enter_distance')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(_distanceController.text);
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('enter_valid_distance')),
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
                      'name': localizations.translate('marker'), // Установка дефолтного названия
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'notes': _notesController.text.trim(),
                      'bottomType': selectedBottomType,
                      // Сохраняем также угол и соотношение для отображения
                      'angle': _calculateRayAngle(selectedRayIndex),
                      'ratio': distance / _maxDistance,
                    };

                    // Сохраняем последний выбранный луч и тип дна для следующего добавления
                    _lastSelectedRayIndex = selectedRayIndex;
                    _currentBottomType = selectedBottomType;

                    // Создаем копию списка маркеров и добавляем новый маркер
                    final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
                    updatedMarkers.add(newMarker);

                    setState(() {
                      // Вместо модификации списка создаем новую модель
                      _markerMap = _markerMap.copyWith(markers: updatedMarkers);
                      _hasChanges = true;
                    });

                    Navigator.pop(context);

                    // Показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.translate('marker_added')),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Обновляем UI чтобы кнопка сохранения стала активной
                    Future.microtask(() => this.setState(() {}));
                  },
                  child: Text(
                    localizations.translate('add'),
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
    final localizations = AppLocalizations.of(context);
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
                localizations.translate('edit_marker'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Выбор луча
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('ray')}:',
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
                                  child: Text('${localizations.translate('ray')} ${index + 1}'),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    currentRayIndex = value;
                                  });
                                  // Сохраняем выбранный луч для последующих добавлений
                                  _lastSelectedRayIndex = value;
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
                        labelText: localizations.translate('distance_m'),
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
                        labelText: localizations.translate('depth_m'),
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
                      localizations.translate('marker_type'),
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
                              // Сохраняем выбранный тип дна
                              _currentBottomType = type;
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
                        labelText: localizations.translate('notes'),
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
                    localizations.translate('cancel'),
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
                        SnackBar(
                          content: Text(localizations.translate('enter_distance')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(_distanceController.text);
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('enter_valid_distance')),
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
                      SnackBar(
                        content: Text(localizations.translate('marker_updated')),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Обновляем UI чтобы кнопка сохранения стала активной
                    Future.microtask(() => this.setState(() {}));
                  },
                  child: Text(
                    localizations.translate('save'),
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
    final index = _markerMap.markers.indexWhere((m) => m['id'] == markerId);
    if (index != -1) {
      final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
      updatedMarkers[index] = updatedMarker;

      setState(() {
        _markerMap = _markerMap.copyWith(markers: updatedMarkers);
        _hasChanges = true;
      });
    }
  }

  // Диалог подтверждения удаления маркера
  void _confirmDeleteMarker(Map<String, dynamic> marker) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('delete_marker'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('delete_marker_confirmation'),
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
                localizations.translate('cancel'),
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
                  SnackBar(
                    content: Text(localizations.translate('marker_deleted')),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text(
                localizations.translate('delete'),
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
    final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
    updatedMarkers.removeWhere((item) => item['id'] == marker['id']);

    setState(() {
      _markerMap = _markerMap.copyWith(markers: updatedMarkers);
      _hasChanges = true;
    });

    // Обновляем UI чтобы кнопка сохранения стала активной
    Future.microtask(() => setState(() {}));
  }

  // Показать меню действий
  void _showActionMenu() {
    final localizations = AppLocalizations.of(context);
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
                  localizations.translate('change_map_info'),
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
                title: Text(
                  localizations.translate('delete_map'),
                  style: const TextStyle(
                    color: Colors.red,
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
    final localizations = AppLocalizations.of(context);
    final nameController = TextEditingController(text: _markerMap.name);
    final sectorController = TextEditingController(text: _markerMap.sector ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('change_map_info'),
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
                  labelText: localizations.translate('map_name'),
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
                  labelText: localizations.translate('sector_number'),
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
                localizations.translate('cancel'),
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
                    SnackBar(content: Text(localizations.translate('map_name_required'))),
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
                  SnackBar(
                    content: Text(localizations.translate('info_updated')),
                    backgroundColor: Colors.green,
                  ),
                );

                // Обновляем UI чтобы кнопка сохранения стала активной
                Future.microtask(() => setState(() {}));
              },
              child: Text(
                localizations.translate('save'),
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
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            localizations.translate('delete_map'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.translate('delete_map_confirmation'),
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
                localizations.translate('cancel'),
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
              child: Text(
                localizations.translate('delete'),
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
    final localizations = AppLocalizations.of(context);
    try {
      setState(() {
        _isLoading = true;
      });

      await _markerMapRepository.deleteMarkerMap(_markerMap.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('map_deleted_successfully')),
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
            content: Text('${localizations.translate('error_deleting_map')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Сохранение изменений карты
  Future<void> _saveChanges() async {
    final localizations = AppLocalizations.of(context);
    try {
      setState(() {
        _isLoading = true;
      });

      // Создаем копию модели карты для сохранения
      final markerMapToSave = _markerMap.copyWith(
        // Очищаем временные поля с объектами Offset из маркеров
        markers: _markerMap.markers.map((marker) {
          // Создаем копию маркера без полей для UI
          final cleanMarker = Map<String, dynamic>.from(marker);
          // Удаляем поля хитбоксов, которые не должны сохраняться
          cleanMarker.remove('_hitboxCenter');
          cleanMarker.remove('_hitboxRadius');
          return cleanMarker;
        }).toList(),
      );

      // Сохраняем очищенную модель
      await _markerMapRepository.updateMarkerMap(markerMapToSave);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('changes_saved')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('error_saving_changes')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
          // Кнопка информации о маркерах
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppConstants.textColor,
            ),
            tooltip: localizations.translate('marker_info'),
            onPressed: _showMarkerInfo,
          ),
          // Кнопка сохранения - всегда активна если есть маркеры или изменения
          IconButton(
            icon: Icon(
              Icons.save,
              color: (_hasChanges || _markerMap.markers.isNotEmpty)
                  ? AppConstants.textColor
                  : AppConstants.textColor.withOpacity(0.3),
            ),
            tooltip: localizations.translate('save_changes'),
            onPressed: (_hasChanges || _markerMap.markers.isNotEmpty)
                ? _saveChanges
                : null,
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
        message: localizations.translate('please_wait'),
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
      // Кнопка добавления маркера
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMarkerDialog,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add_location),
      ),
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
                    '${localizations.translate('date')}: ${DateFormat('dd.MM.yyyy').format(_markerMap.date)}',
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
                      '${localizations.translate('sector')}: ${_markerMap.sector}',
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
                    isEditing: true, // Всегда в режиме редактирования
                    onMarkerTap: _showMarkerDetails,
                    context: context,
                    leftAngle: _leftAngle,
                    rightAngle: _rightAngle,
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
  final double leftAngle;
  final double rightAngle;

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
    this.leftAngle = 105.0,
    this.rightAngle = 75.0,
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
      // Распределяем равномерно в диапазоне от leftAngle до rightAngle
      final totalAngle = leftAngle - rightAngle; // общий угол охвата
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = leftAngle - (i * angleStep);
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
                color: Colors.greenAccent, // Яркий зеленый
                fontSize: 12,
                fontWeight: FontWeight.bold, // Жирный шрифт
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
          text: '${AppLocalizations.of(context).translate('ray')} ${i + 1}',
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
      final totalAngle = leftAngle - rightAngle;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = leftAngle - (rayIndex * angleStep);
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