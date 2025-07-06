// Путь: lib/screens/marker_maps/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../widgets/loading_overlay.dart';
// Необходимые импорты для функций
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../localization/app_localizations.dart';
import 'depth_chart_screen.dart';
// ДОБАВЛЕНО: Импорты для проверки лимитов
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';

class MarkerMapScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const MarkerMapScreen({super.key, required this.markerMap});

  @override
  MarkerMapScreenState createState() => MarkerMapScreenState();
}

class MarkerMapScreenState extends State<MarkerMapScreen> {
  final _markerMapRepository = MarkerMapRepository();
  final _fishingNoteRepository = FishingNoteRepository();
  final _depthController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();

  late MarkerMapModel _markerMap;
  List<FishingNoteModel> _availableNotes = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  // Сохранение последнего выбранного луча
  int _lastSelectedRayIndex = 0;

  // Настройки лучей
  final int _raysCount = 5;
  final double _maxDistance = 200.0;
  final double _distanceStep = 10.0;

  // Параметры угла лучей (скорректированные)
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
    'точка_кормления',
  ];

  // Текущий тип дна для нового маркера
  String _currentBottomType = 'ил';

  // Обновленные цвета для типов дна маркеров
  final Map<String, Color> _bottomTypeColors = {
    'ил': Color(0xFFD4A574), // Светло ярко коричневый
    'глубокий_ил': Color(0xFF8B4513), // Темно коричневый
    'ракушка': Colors.white, // Белый
    'ровно_твердо': Colors.yellow, // Желтый
    'камни': Colors.grey, // Серый
    'трава_водоросли': Color(0xFF90EE90), // Светло зеленый
    'зацеп': Colors.red, // Красный
    'бугор': Color(0xFFFF8C00), // Ярко оранжевый
    'точка_кормления': Color(0xFF00BFFF), // Ярко голубой
    'default': Colors.blue, // для обратной совместимости
  };

  final Map<String, IconData> _bottomTypeIcons = {
    'ил': Icons.view_headline, // горизонтальные линии для ила
    'глубокий_ил': Icons.waves_outlined,
    'ракушка': Icons.wifi, // волнистые линии WiFi для ракушки
    'ровно_твердо': Icons.remove,
    'камни': Icons.more_horiz,
    'трава_водоросли': Icons.grass,
    'зацеп': Icons.warning,
    'бугор': Icons.landscape,
    'точка_кормления': Icons.gps_fixed,
    'default': Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    _markerMap = widget.markerMap;
    _loadAvailableNotes();

    // Скрываем системные панели для полноэкранного режима
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _depthController.dispose();
    _notesController.dispose();
    _distanceController.dispose();

    // Восстанавливаем системные панели при выходе
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Загрузка доступных заметок для привязки
  Future<void> _loadAvailableNotes() async {
    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      if (mounted) {
        setState(() {
          _availableNotes = notes;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке заметок: $e');
    }
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
        return localizations.translate('hill');
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
        return 'бугор';
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
    return (_leftAngle - (rayIndex * angleStep)) *
        (math.pi / 180); // конвертируем в радианы
  }

  // Показ информации о маркерах
  void _showMarkerInfo() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate('marker_info'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Содержимое
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Секция "Типы маркеров"
                        Text(
                          localizations.translate('marker_types'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Список типов маркеров с цветными точками
                        ...(_bottomTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                // Цветная точка
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color:
                                    _bottomTypeColors[type] ?? Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Иконка
                                Icon(
                                  _bottomTypeIcons[type] ?? Icons.location_on,
                                  color: AppConstants.textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                // Название типа
                                Expanded(
                                  child: Text(
                                    _getBottomTypeName(type),
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()),

                        const SizedBox(height: 24),

                        // Секция "Как пользоваться"
                        Text(
                          localizations.translate('how_to_use'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Инструкции
                        _buildInstructionItem(
                          icon: Icons.add_location,
                          title: localizations.translate('adding_marker'),
                          description: localizations.translate(
                            'adding_marker_desc',
                          ),
                        ),

                        _buildInstructionItem(
                          icon: Icons.visibility,
                          title: localizations.translate('view_details'),
                          description: localizations.translate(
                            'view_details_desc',
                          ),
                        ),

                        _buildInstructionItem(
                          icon: Icons.edit,
                          title: localizations.translate('editing'),
                          description: localizations.translate('editing_desc'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Кнопка закрытия
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppConstants.textColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: Text(
                          localizations.translate('close'),
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Построение пункта инструкции
  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
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
                    fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  // Показ диалога с деталями маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
    final localizations = AppLocalizations.of(context);

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
                      '${localizations.translate('depth')}: ${marker['depth']} м',
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
                      _getBottomTypeIcon(
                        marker['bottomType'] ?? marker['type'],
                      ),
                      color: AppConstants.textColor,
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
              ] else if (marker['description'] != null &&
                  marker['description'].isNotEmpty) ...[
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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                localizations.translate('add_marker'),
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
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
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
                                  child: Text(
                                    '${localizations.translate('ray')} ${index + 1}',
                                  ),
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Тип дна
                    Text(
                      '${localizations.translate('marker_type')}:',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor:
                          _bottomTypeColors[type] ?? Colors.grey,
                          selectedColor:
                          _bottomTypeColors[type] ?? Colors.grey,
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight:
                            selectedBottomType == type
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: Icon(
                            _bottomTypeIcons[type],
                            color: Colors.black,
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
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
                    style: TextStyle(color: AppConstants.textColor),
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
                          content: Text(
                            localizations.translate('enter_distance'),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(
                      _distanceController.text,
                    );
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.translate('enter_valid_distance'),
                          ),
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
                      'name': localizations.translate(
                        'marker',
                      ), // Установка дефолтного названия
                      'depth':
                      _depthController.text.isEmpty
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
                    final updatedMarkers = List<Map<String, dynamic>>.from(
                      _markerMap.markers,
                    );
                    updatedMarkers.add(newMarker);

                    this.setState(() {
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
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    // Обновляем UI чтобы кнопка сохранения стала активной
                    Future.microtask(() => this.setState(() {}));
                  },
                  child: Text(
                    localizations.translate('add'),
                    style: TextStyle(fontWeight: FontWeight.bold),
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
    _depthController.text =
    marker['depth'] != null ? marker['depth'].toString() : '';
    _notesController.text = marker['notes'] ?? marker['description'] ?? '';
    _distanceController.text = marker['distance'].toString();

    // Определяем тип дна (с учетом обратной совместимости)
    String selectedBottomType =
        marker['bottomType'] ?? _convertLegacyTypeToNew(marker['type']) ?? 'ил';

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
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
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
                                  child: Text(
                                    '${localizations.translate('ray')} ${index + 1}',
                                  ),
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Тип дна маркера
                    Text(
                      localizations.translate('marker_type'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor:
                          _bottomTypeColors[type] ?? Colors.grey,
                          selectedColor:
                          _bottomTypeColors[type] ?? Colors.grey,
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight:
                            selectedBottomType == type
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: Icon(
                            _bottomTypeIcons[type],
                            color: Colors.black,
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
                        labelStyle: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
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
                    style: TextStyle(color: AppConstants.textColor),
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
                          content: Text(
                            localizations.translate('enter_distance'),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Парсим введенную дистанцию
                    double? distance = double.tryParse(
                      _distanceController.text,
                    );
                    if (distance == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.translate('enter_valid_distance'),
                          ),
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
                      'depth':
                      _depthController.text.isEmpty
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
                        content: Text(
                          localizations.translate('marker_updated'),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    // Обновляем UI чтобы кнопка сохранения стала активной
                    Future.microtask(() => this.setState(() {}));
                  },
                  child: Text(
                    localizations.translate('save'),
                    style: TextStyle(fontWeight: FontWeight.bold),
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
      final updatedMarkers = List<Map<String, dynamic>>.from(
        _markerMap.markers,
      );
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
            style: TextStyle(color: AppConstants.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.translate('cancel'),
                style: TextStyle(color: AppConstants.textColor),
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
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                localizations.translate('delete'),
                style: TextStyle(color: Colors.redAccent),
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

    // Обновляем UI чтобы кнопка сохранения стала активная
    Future.microtask(() => setState(() {}));
  }

  // ИСПРАВЛЕНО: Переход к экрану графиков глубин с проверкой премиума
  Future<void> _showDepthCharts() async {
    try {
      final localizations = AppLocalizations.of(context);

      // ДОБАВЛЕНО: Проверка доступа к графику глубины
      final subscriptionService = SubscriptionService();
      final canAccessDepthChart = await subscriptionService.canCreateContent(ContentType.depthChart);

      if (!canAccessDepthChart) {
        // Показываем диалог с предложением премиума
        _showDepthChartPremiumDialog();
        return;
      }

      // Если доступ разрешен - переходим к графику
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepthChartScreen(markerMap: _markerMap),
        ),
      );
    } catch (e) {
      debugPrint('Ошибка при проверке доступа к графику глубины: $e');
      // В случае ошибки показываем диалог премиума (безопасный подход)
      _showDepthChartPremiumDialog();
    }
  }

  // ДОБАВЛЕНО: Диалог с предложением премиума для графика глубины
  void _showDepthChartPremiumDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.translate('premium_feature') ?? 'Премиум функция',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.translate('depth_chart_premium_title') ?? 'График глубин',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('depth_chart_premium_description') ??
                    'График глубин доступен только для пользователей с премиум подпиской. Обновитесь до премиума, чтобы получить доступ к расширенной аналитике ваших маркерных карт.',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
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
                      Icons.info_outline,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.translate('premium_benefits_hint') ??
                            'С премиумом вы получите безлимитный доступ ко всем функциям',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.translate('cancel') ?? 'Отмена',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Навигация к экрану подписки
                debugPrint('Переход к экрану покупки премиума');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localizations.translate('premium_screen_coming_soon') ??
                          'Экран покупки премиума скоро будет добавлен',
                    ),
                    backgroundColor: AppConstants.primaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.upgrade, size: 18),
              label: Text(
                localizations.translate('upgrade_to_premium') ?? 'Обновить до Премиум',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Сохранение изменений карты
  Future<void> _saveChanges() async {
    final localizations = AppLocalizations.of(context);
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Создаем копию модели карты для сохранения
      final markerMapToSave = _markerMap.copyWith(
        // Очищаем временные поля с объектами Offset из маркеров
        markers:
        _markerMap.markers.map((marker) {
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

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('save_changes')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
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
            content: Text(
              '${localizations.translate('error_saving_changes')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Кнопка выхода с сохранением
  Future<void> _exitWithSave() async {
    if (_hasChanges || _markerMap.markers.isNotEmpty) {
      await _saveChanges();
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D), // Темно-зеленый фон как в HTML
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: AppLocalizations.of(context).translate('please_wait'),
        child: Stack(
          children: [
            // Карта на весь экран с учетом системных отступов
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B1F1D), Color(0xFF0F2823)],
                  ),
                ),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: FullscreenMarkerMapPainter(
                    rayCount: _raysCount,
                    maxDistance: _maxDistance,
                    distanceStep: _distanceStep,
                    markers: _markerMap.markers,
                    bottomTypeColors: _bottomTypeColors,
                    bottomTypeIcons: _bottomTypeIcons,
                    onMarkerTap: _showMarkerDetails,
                    context: context,
                    leftAngle: _leftAngle,
                    rightAngle: _rightAngle,
                  ),
                ),
              ),
            ),

            // Информационная кнопка в левом нижнем углу
            Positioned(
              left: 16,
              bottom:
              55 +
                  MediaQuery.of(
                    context,
                  ).padding.bottom, // Добавляем отступ для системных кнопок
              child: FloatingActionButton(
                heroTag: "info_button",
                onPressed: _showMarkerInfo,
                backgroundColor: AppConstants.primaryColor.withValues(
                  alpha: 0.9,
                ),
                foregroundColor: Colors.white,
                child: const Icon(Icons.info_outline),
              ),
            ),

            // Три кнопки справа
            Positioned(
              right: 16,
              bottom:
              180 + MediaQuery.of(context).padding.bottom, // Верхняя кнопка
              child: FloatingActionButton(
                heroTag: "exit_button",
                onPressed: _exitWithSave,
                backgroundColor: AppConstants.primaryColor.withValues(
                  alpha: 0.9,
                ),
                foregroundColor: Colors.white,
                child: const Icon(Icons.arrow_back),
              ),
            ),

            Positioned(
              right: 16,
              bottom:
              105 + MediaQuery.of(context).padding.bottom, // Средняя кнопка
              child: FloatingActionButton(
                heroTag: "charts_button",
                onPressed: _showDepthCharts,
                backgroundColor: AppConstants.primaryColor.withValues(
                  alpha: 0.9,
                ),
                foregroundColor: Colors.white,
                child: const Icon(Icons.bar_chart),
              ),
            ),

            Positioned(
              right: 16,
              bottom:
              30 + MediaQuery.of(context).padding.bottom, // Нижняя кнопка
              child: FloatingActionButton(
                heroTag: "add_marker_button",
                onPressed: _showAddMarkerDialog,
                backgroundColor: AppConstants.primaryColor.withValues(
                  alpha: 0.9,
                ),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Новый painter для полноэкранной карты
class FullscreenMarkerMapPainter extends CustomPainter {
  final int rayCount;
  final double maxDistance;
  final double distanceStep;
  final List<Map<String, dynamic>> markers;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final Function(Map<String, dynamic>) onMarkerTap;
  final BuildContext context;
  final double leftAngle;
  final double rightAngle;

  FullscreenMarkerMapPainter({
    required this.rayCount,
    required this.maxDistance,
    required this.distanceStep,
    required this.markers,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.onMarkerTap,
    required this.context,
    this.leftAngle = 105.0,
    this.rightAngle = 75.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final originY = size.height - 5; // Почти в самом низу
    final pixelsPerMeter = size.height / (maxDistance * 1.1);

    // Отрисовка полукругов (концентрических дуг) с одинаковым мелким пунктиром
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    paint.color = Colors.white.withValues(alpha: 0.3);

    for (int distance = 10; distance <= maxDistance.toInt(); distance += 10) {
      final radius = distance * pixelsPerMeter;

      // Рисуем пунктирную дугу с одинаковыми отрезками в пикселях
      final path = Path();
      final dashLengthPx = 3.0; // Длина штриха в пикселях
      final gapLengthPx = 6.0; // Длина пробела в пикселях
      final circumference = math.pi * radius; // Длина полукруга
      final segmentLength = dashLengthPx + gapLengthPx;
      final numSegments = (circumference / segmentLength).floor();

      for (int i = 0; i < numSegments; i++) {
        // Вычисляем углы для каждого штриха
        final startAngle = math.pi + (i * segmentLength / radius);
        final endAngle =
            math.pi + ((i * segmentLength + dashLengthPx) / radius);

        if (endAngle > math.pi * 2) break; // Не выходим за пределы полукруга

        final startX = centerX + radius * math.cos(startAngle);
        final startY = originY + radius * math.sin(startAngle);
        final endX = centerX + radius * math.cos(endAngle);
        final endY = originY + radius * math.sin(endAngle);

        path.moveTo(startX, startY);
        path.arcToPoint(Offset(endX, endY), radius: Radius.circular(radius));
      }

      canvas.drawPath(path, paint);
    }

    final rayAngles = <double>[];
    for (int i = 0; i < rayCount; i++) {
      final totalAngle = leftAngle - rightAngle;
      final angleStep = totalAngle / (rayCount - 1);
      final angleDegrees = leftAngle - (i * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);
      rayAngles.add(angleRadians);
    }

    for (final angle in rayAngles) {
      final rayLength = maxDistance * pixelsPerMeter;
      final endX = centerX + rayLength * math.cos(angle);
      final endY = originY - rayLength * math.sin(angle);

      canvas.drawLine(Offset(centerX, originY), Offset(endX, endY), paint);
    }

    // Отрисовка точек на пересечениях
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withValues(alpha: 0.5);

    for (final angle in rayAngles) {
      for (int distance = 10; distance <= maxDistance.toInt(); distance += 10) {
        final radius = distance * pixelsPerMeter;
        final pointX = centerX + radius * math.cos(angle);
        final pointY = originY - radius * math.sin(angle);

        if (pointY > 30) {
          // Не рисуем точки слишком близко к верху
          canvas.drawCircle(Offset(pointX, pointY), 1.5, paint);
        }
      }
    }

    // Отрисовка подписей дистанций
    _drawDistanceLabels(canvas, size, centerX, originY, pixelsPerMeter);

    // Отрисовка подписей лучей
    _drawRayLabels(canvas, size, centerX, originY, pixelsPerMeter, rayAngles);

    // Отрисовка маркеров с подписями
    _drawMarkersWithLabels(
      canvas,
      size,
      centerX,
      originY,
      pixelsPerMeter,
      rayAngles,
    );
  }

  void _drawDistanceLabels(
      Canvas canvas,
      Size size,
      double centerX,
      double originY,
      double pixelsPerMeter,
      ) {
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Подписи 10-50м (поперек внизу с поворотом) - СДВИНУТО ПРАВЕЕ
    for (int distance = 10; distance <= 50; distance += 10) {
      textPainter.text = TextSpan(
        text: distance.toString(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 3,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(
        centerX -
            distance * pixelsPerMeter +
            4, // ИЗМЕНЕНО: было -4, стало +10 (сдвиг на 14px правее)
        originY - 20,
      );
      canvas.rotate(-math.pi / 2); // Поворот на 270°
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Подписи 60-200м (по левому краю) - точные позиции как в HTML
    final distancePositions = [
      {'distance': 60, 'offset': 95.0},
      {'distance': 70, 'offset': 70.0},
      {'distance': 80, 'offset': 55.0},
      {'distance': 90, 'offset': 50.0},
      {'distance': 100, 'offset': 40.0},
      {'distance': 110, 'offset': 35.0},
      {'distance': 120, 'offset': 30.0},
      {'distance': 130, 'offset': 25.0},
      {'distance': 140, 'offset': 22.0},
      {'distance': 150, 'offset': 22.0},
      {'distance': 160, 'offset': 18.0},
      {'distance': 170, 'offset': 18.0},
      {'distance': 180, 'offset': 15.0},
      {'distance': 190, 'offset': 15.0},
      {'distance': 200, 'offset': 15.0},
    ];

    for (final pos in distancePositions) {
      final distance = pos['distance'] as int;
      final offset = pos['offset'] as double;

      textPainter.text = TextSpan(
        text: distance.toString(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 3,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(8, originY - distance * pixelsPerMeter + offset),
      );
    }
  }

  void _drawRayLabels(
      Canvas canvas,
      Size size,
      double centerX,
      double originY,
      double pixelsPerMeter,
      List<double> rayAngles,
      ) {
    final localizations = AppLocalizations.of(context);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Размещаем названия лучей точно над каждым лучом в верхней части
    for (int i = 0; i < rayAngles.length && i < rayCount; i++) {
      final angle = rayAngles[i];

      // Фиксированное расстояние от верха экрана с индивидуальными корректировками
      double labelY = 50.0; // Базовый отступ от верха экрана

      // Вычисляем X координату на основе угла луча
      final rayAtLabelY = (originY - labelY);
      double labelX = centerX + rayAtLabelY / math.tan(angle);

      // Индивидуальные корректировки для каждого луча
      switch (i) {
        case 0: // Луч 1 - еще немного левее
          labelY += 20.0; // Еще чуть ниже
          labelX -= 50.0; // Еще немного левее (было 45.0)
          labelX = math.max(labelX, 35.0); // Минимальный отступ от левого края
          break;
        case 1: // Луч 2 - чутка ниже
          labelY += 5.0; // Чутка ниже
          break;
        case 2: // Луч 3 - без изменений
          break;
        case 3: // Луч 4 - чутка ниже
          labelY += 5.0; // Чутка ниже
          break;
        case 4: // Луч 5 - еще немного правее
          labelY += 20.0; // Чутка ниже
          labelX += 50.0; // Еще немного правее (было 45.0)
          labelX = math.min(
            labelX,
            size.width - 35.0,
          ); // Максимальный отступ от правого края
          break;
      }

      textPainter.text = TextSpan(
        text:
        '${localizations.translate('ray')} ${i + 1}', // ИСПРАВЛЕНО: теперь через локализацию
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 3,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      );
      textPainter.layout();

      // Дополнительная корректировка для учета ширины текста
      if (i == 0) {
        // Луч 1
        labelX = math.max(labelX, textPainter.width / 2 + 10);
      } else if (i == rayCount - 1) {
        // Луч 5
        labelX = math.min(labelX, size.width - textPainter.width / 2 - 10);
      }

      // Центрируем текст относительно позиции
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }
  }

  void _drawMarkersWithLabels(
      Canvas canvas,
      Size size,
      double centerX,
      double originY,
      double pixelsPerMeter,
      List<double> rayAngles,
      ) {
    for (final marker in markers) {
      // Получаем координаты из сохраненных в маркере данных
      final rayIndex = (marker['rayIndex'] as double? ?? 0).toInt();
      final distance = marker['distance'] as double? ?? 0;

      if (rayIndex >= rayAngles.length) continue;

      // Вычисляем позицию маркера
      final angle = rayAngles[rayIndex];
      final ratio = distance / maxDistance;
      final maxRayLength = maxDistance * pixelsPerMeter;

      final dx = centerX + maxRayLength * ratio * math.cos(angle);
      final dy = originY - maxRayLength * ratio * math.sin(angle);

      // Определяем цвет по типу дна (с учетом обратной совместимости)
      String bottomType = marker['bottomType'] ?? 'default';
      if (bottomType == 'default' && marker['type'] != null) {
        // Для обратной совместимости
        switch (marker['type']) {
          case 'dropoff':
            bottomType = 'бугор';
            break;
          case 'weed':
            bottomType = 'трава_водоросли';
            break;
          case 'sandbar':
            bottomType = 'ровно_твердо';
            break;
          case 'structure':
            bottomType = 'зацеп';
            break;
          default:
            bottomType = 'ил';
        }
      }

      final markerColor = bottomTypeColors[bottomType] ?? Colors.blue;

      // Рисуем маркер
      final markerPaint =
      Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      // Рисуем кружок без обводки
      canvas.drawCircle(Offset(dx, dy), 8, markerPaint);

      // Добавляем внутреннюю точку
      final centerDotPaint =
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), 2, centerDotPaint);

      // Отрисовка подписей справа от луча
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

      // Вычисляем позицию справа от луча
      final labelOffsetX = 15.0; // Отступ от маркера
      final labelX = dx + labelOffsetX;

      // Подпись глубины сверху (желтый цвет)
      if (marker['depth'] != null) {
        textPainter.text = TextSpan(
          text: '${marker['depth'].toStringAsFixed(1)}м',
          style: TextStyle(
            color: Colors.yellow.shade300,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ],
          ),
        );
        textPainter.layout();

        // Размещаем глубину сверху
        textPainter.paint(
          canvas,
          Offset(labelX, dy - 10), // Выше маркера
        );
      }

      // Подпись дистанции снизу (белый цвет)
      textPainter.text = TextSpan(
        text: '${distance.toInt()}м',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      );
      textPainter.layout();

      // Размещаем дистанцию снизу
      textPainter.paint(
        canvas,
        Offset(labelX, dy + 2), // Ниже маркера
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
      if (marker.containsKey('_hitboxCenter') &&
          marker.containsKey('_hitboxRadius')) {
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