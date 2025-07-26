// Путь: lib/screens/marker_maps/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../widgets/loading_overlay.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../localization/app_localizations.dart';
import 'depth_chart_screen.dart';
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';
import '../../models/offline_usage_result.dart';
import '../subscription/paywall_screen.dart';
import '../../repositories/marker_map_repository.dart';

class MarkerMapScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const MarkerMapScreen({super.key, required this.markerMap});

  @override
  MarkerMapScreenState createState() => MarkerMapScreenState();
}

class MarkerMapScreenState extends State<MarkerMapScreen> {
  final _firebaseService = FirebaseService();
  final _depthController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();
  final _subscriptionService = SubscriptionService();
  final _markerMapRepository = MarkerMapRepository();

  late MarkerMapModel _markerMap;
  bool _isLoading = false;
  bool _isAutoSaving = false;
  String _saveMessage = '';

  // 🔥 ДОБАВЛЕНО: Флаг disposed для предотвращения утечек
  bool _isDisposed = false;

  // Сохранение последнего выбранного луча
  int _lastSelectedRayIndex = 0;

  // Настройки лучей
  final int _raysCount = 5;
  final double _maxDistance = 200.0;
  final double _distanceStep = 10.0;
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

  String _currentBottomType = 'ил';

  // Обновленные цвета для типов дна маркеров
  final Map<String, Color> _bottomTypeColors = {
    'ил': Color(0xFFD4A574),
    'глубокий_ил': Color(0xFF8B4513),
    'ракушка': Colors.white,
    'ровно_твердо': Colors.yellow,
    'камни': Colors.grey,
    'трава_водоросли': Color(0xFF90EE90),
    'зацеп': Colors.red,
    'бугор': Color(0xFFFF8C00),
    'точка_кормления': Color(0xFF00BFFF),
    'default': Colors.blue,
  };

  final Map<String, IconData> _bottomTypeIcons = {
    'ил': Icons.view_headline,
    'глубокий_ил': Icons.waves_outlined,
    'ракушка': Icons.wifi,
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    debugPrint('🗺️ MarkerMapScreen: Открываем карту маркеров ID: ${_markerMap.id}');
  }

  @override
  void dispose() {
    debugPrint('🗺️ MarkerMapScreen: Начинаем dispose...');

    // 🔥 ДОБАВЛЕНО: Устанавливаем флаг disposed
    _isDisposed = true;

    // Освобождаем контроллеры
    _depthController.dispose();
    _notesController.dispose();
    _distanceController.dispose();

    // 🔥 ДОБАВЛЕНО: Очищаем кэш Repository
    try {
      MarkerMapRepository.clearCache();
      debugPrint('🗺️ Кэш Repository очищен в dispose');
    } catch (e) {
      debugPrint('⚠️ Ошибка очистки кэша Repository: $e');
    }

    // Восстанавливаем системные панели
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    debugPrint('🗺️ MarkerMapScreen: dispose завершен успешно');
    super.dispose();
  }

  // 🔥 ДОБАВЛЕНО: Безопасный setState с проверкой disposed
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
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
        return type;
    }
  }

  // Вычисление угла луча
  double _calculateRayAngle(int rayIndex) {
    final totalAngle = _leftAngle - _rightAngle;
    final angleStep = totalAngle / (_raysCount - 1);
    return (_leftAngle - (rayIndex * angleStep)) * (math.pi / 180);
  }

  // 🔥 ИСПРАВЛЕНО: Автосохранение с проверкой disposed
  Future<void> _autoSaveChanges(String action) async {
    if (_isDisposed || !mounted) return;

    try {
      _safeSetState(() {
        _isAutoSaving = true;
        _saveMessage = action;
      });

      debugPrint('💾 Автосохранение: $action');

      final markerMapToSave = _markerMap.copyWith(
        markers: _markerMap.markers.map((marker) {
          final cleanMarker = Map<String, dynamic>.from(marker);
          cleanMarker.remove('_hitboxCenter');
          cleanMarker.remove('_hitboxRadius');
          return cleanMarker;
        }).toList(),
      );

      final mapData = {
        'name': markerMapToSave.name,
        'date': markerMapToSave.date.millisecondsSinceEpoch,
        'sector': markerMapToSave.sector,
        'markers': markerMapToSave.markers,
        'userId': markerMapToSave.userId,
        'createdAt': markerMapToSave.date.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _markerMapRepository.updateMarkerMap(markerMapToSave);

      // 🔥 ДОБАВЛЕНО: Очищаем кэш после сохранения
      try {
        MarkerMapRepository.clearCache();
        debugPrint('💾 Кэш Repository очищен после автосохранения');
      } catch (e) {
        debugPrint('⚠️ Не удалось очистить кэш Repository: $e');
      }

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isAutoSaving = false;
          _saveMessage = '';
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action - сохранено'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        debugPrint('✅ Автосохранение завершено: $action');
      }
    } catch (e) {
      debugPrint('❌ Ошибка автосохранения: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isAutoSaving = false;
          _saveMessage = '';
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Показ информации о маркерах
  void _showMarkerInfo() {
    if (_isDisposed) return;

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
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _bottomTypeColors[type] ?? Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  _bottomTypeIcons[type] ?? Icons.location_on,
                                  color: AppConstants.textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
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
                          description: localizations.translate('adding_marker_desc'),
                        ),

                        _buildInstructionItem(
                          icon: Icons.visibility,
                          title: localizations.translate('view_details'),
                          description: localizations.translate('view_details_desc'),
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
    if (_isDisposed) return;

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

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
    final newType = _convertLegacyTypeToNew(type);
    return _bottomTypeIcons[newType] ?? Icons.terrain;
  }

  // Диалог добавления нового маркера
  Future<void> _showAddMarkerDialog() async {
    if (_isDisposed) return;

    final localizations = AppLocalizations.of(context);

    debugPrint('✅ Открываем диалог добавления маркера с автосохранением');

    _depthController.text = '';
    _notesController.text = '';
    _distanceController.text = '';

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
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('ray')}:',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
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
                                  _lastSelectedRayIndex = value;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

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
                      children: _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor: _bottomTypeColors[type] ?? Colors.grey,
                          selectedColor: _bottomTypeColors[type] ?? Colors.grey,
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: selectedBottomType == type
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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
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
                  onPressed: () async {
                    if (_distanceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('enter_distance')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

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

                    if (distance > _maxDistance) {
                      distance = _maxDistance;
                    } else if (distance < 0) {
                      distance = 0;
                    }

                    final newMarker = {
                      'id': const Uuid().v4(),
                      'rayIndex': selectedRayIndex.toDouble(),
                      'distance': distance,
                      'name': localizations.translate('marker'),
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'notes': _notesController.text.trim(),
                      'bottomType': selectedBottomType,
                      'angle': _calculateRayAngle(selectedRayIndex),
                      'ratio': distance / _maxDistance,
                    };

                    _lastSelectedRayIndex = selectedRayIndex;
                    _currentBottomType = selectedBottomType;

                    final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
                    updatedMarkers.add(newMarker);

                    // 🔥 ИСПРАВЛЕНО: Используем безопасный setState
                    if (!_isDisposed) {
                      _safeSetState(() {
                        _markerMap = _markerMap.copyWith(markers: updatedMarkers);
                      });
                    }

                    Navigator.pop(context);

                    debugPrint('✅ Добавлен новый маркер: ${newMarker['id']}');

                    await _autoSaveChanges('Маркер добавлен');

                    // 🔥 ИСПРАВЛЕНО: Безопасное обновление UI
                    if (!_isDisposed && mounted) {
                      Future.microtask(() => _safeSetState(() {}));
                    }
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
    if (_isDisposed) return;

    final localizations = AppLocalizations.of(context);
    _depthController.text = marker['depth'] != null ? marker['depth'].toString() : '';
    _notesController.text = marker['notes'] ?? marker['description'] ?? '';
    _distanceController.text = marker['distance'].toString();

    String selectedBottomType =
        marker['bottomType'] ?? _convertLegacyTypeToNew(marker['type']) ?? 'ил';

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
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('ray')}:',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
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
                                  _lastSelectedRayIndex = value;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

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
                      children: _bottomTypes.map((type) {
                        return ChoiceChip(
                          label: Text(_getBottomTypeName(type)),
                          selected: selectedBottomType == type,
                          backgroundColor: _bottomTypeColors[type] ?? Colors.grey,
                          selectedColor: _bottomTypeColors[type] ?? Colors.grey,
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: selectedBottomType == type
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
                              _currentBottomType = type;
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

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
                            color: AppConstants.textColor.withValues(alpha: 0.5),
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
                  onPressed: () async {
                    if (_distanceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('enter_distance')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

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

                    if (distance > _maxDistance) {
                      distance = _maxDistance;
                    } else if (distance < 0) {
                      distance = 0;
                    }

                    final updatedMarker = {
                      ...marker,
                      'rayIndex': currentRayIndex.toDouble(),
                      'distance': distance,
                      'depth': _depthController.text.isEmpty
                          ? null
                          : double.tryParse(_depthController.text),
                      'notes': _notesController.text.trim(),
                      'bottomType': selectedBottomType,
                      'angle': _calculateRayAngle(currentRayIndex),
                      'ratio': distance / _maxDistance,
                    };

                    updatedMarker.remove('type');
                    updatedMarker.remove('description');

                    _updateMarker(marker['id'], updatedMarker);

                    Navigator.pop(context);

                    debugPrint('✅ Маркер обновлен: ${marker['id']}');

                    await _autoSaveChanges('Маркер обновлен');

                    // 🔥 ИСПРАВЛЕНО: Безопасное обновление UI
                    if (!_isDisposed && mounted) {
                      Future.microtask(() => _safeSetState(() {}));
                    }
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
    if (_isDisposed) return;

    final index = _markerMap.markers.indexWhere((m) => m['id'] == markerId);
    if (index != -1) {
      final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
      updatedMarkers[index] = updatedMarker;

      _safeSetState(() {
        _markerMap = _markerMap.copyWith(markers: updatedMarkers);
      });
    }
  }

  // Диалог подтверждения удаления маркера
  void _confirmDeleteMarker(Map<String, dynamic> marker) {
    if (_isDisposed) return;

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
              onPressed: () async {
                Navigator.of(context).pop();

                _deleteMarker(marker);

                debugPrint('🗑️ Маркер удален: ${marker['id']}');

                await _autoSaveChanges('Маркер удален');

                // 🔥 ИСПРАВЛЕНО: Безопасное обновление UI
                if (!_isDisposed && mounted) {
                  Future.microtask(() => _safeSetState(() {}));
                }
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
    if (_isDisposed) return;

    final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);
    updatedMarkers.removeWhere((item) => item['id'] == marker['id']);

    _safeSetState(() {
      _markerMap = _markerMap.copyWith(markers: updatedMarkers);
    });
  }

  // Переход к экрану графиков глубин
  Future<void> _showDepthCharts() async {
    if (_isDisposed) return;

    try {
      final localizations = AppLocalizations.of(context);

      debugPrint('📊 Проверяем доступ к графикам глубины...');

      final hasActiveSubscription = _subscriptionService.isPremium;

      debugPrint('📊 Результат проверки подписки: $hasActiveSubscription');

      if (hasActiveSubscription) {
        debugPrint('✅ Есть активная подписка - открываем графики глубины');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepthChartScreen(markerMap: _markerMap),
          ),
        );
      } else {
        debugPrint('❌ Нет активной подписки - показываем Paywall');

        _showPremiumRequired(ContentType.depthChart);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке доступа к графику глубины: $e');
      _showPremiumRequired(ContentType.depthChart);
    }
  }

  // Единый метод для показа PaywallScreen
  void _showPremiumRequired(ContentType contentType) {
    if (_isDisposed) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: contentType.name,
        ),
      ),
    );
  }

  // Простой выход без автосохранения
  Future<void> _exitScreen() async {
    debugPrint('🚪 Выходим из экрана маркерной карты (автосохранение уже работает)');
    if (mounted && !_isDisposed) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ДОБАВЛЕНО: Проверка disposed в build
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: AppLocalizations.of(context).translate('please_wait'),
        child: Stack(
          children: [
            // 🔥 ОПТИМИЗИРОВАНО: Упрощенная карта с кэшированием
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
                child: OptimizedMarkerMapPainter(
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
                  isDisposed: _isDisposed,
                ),
              ),
            ),

            // Индикатор автосохранения
            if (_isAutoSaving)
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Сохранение...',
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

            // Кнопка информации
            Positioned(
              left: 16,
              bottom: 55 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton(
                heroTag: "info_button",
                onPressed: _showMarkerInfo,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                child: const Icon(Icons.info_outline),
              ),
            ),

            // Кнопка выхода
            Positioned(
              right: 16,
              bottom: 205 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton(
                heroTag: "exit_button",
                onPressed: _exitScreen,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                child: const Icon(Icons.arrow_back),
              ),
            ),

            // Кнопка графиков
            Positioned(
              right: 16,
              bottom: 130 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton(
                heroTag: "charts_button",
                onPressed: _showDepthCharts,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                child: const Icon(Icons.bar_chart),
              ),
            ),

            // Кнопка добавления маркера
            Positioned(
              right: 16,
              bottom: 55 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton(
                heroTag: "add_marker_button",
                onPressed: _showAddMarkerDialog,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 НОВЫЙ ОПТИМИЗИРОВАННЫЙ PAINTER
class OptimizedMarkerMapPainter extends StatefulWidget {
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
  final bool isDisposed;

  const OptimizedMarkerMapPainter({
    super.key,
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
    required this.isDisposed,
  });

  @override
  State<OptimizedMarkerMapPainter> createState() => _OptimizedMarkerMapPainterState();
}

class _OptimizedMarkerMapPainterState extends State<OptimizedMarkerMapPainter> {
  // 🔥 ДОБАВЛЕНО: Кэшированные Paint объекты для переиспользования
  late final Paint _gridPaint;
  late final Paint _rayPaint;
  late final Paint _pointPaint;
  late final Paint _markerPaint;
  late final Paint _centerDotPaint;

  // 🔥 ДОБАВЛЕНО: Кэшированные TextPainter для переиспользования
  late final TextPainter _textPainter;

  // 🔥 ДОБАВЛЕНО: Кэшированные углы лучей
  late final List<double> _rayAngles;

  @override
  void initState() {
    super.initState();

    // 🔥 ОПТИМИЗАЦИЯ: Инициализируем Paint объекты один раз
    _gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3);

    _rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3);

    _pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.5);

    _markerPaint = Paint()..style = PaintingStyle.fill;

    _centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 🔥 ОПТИМИЗАЦИЯ: Инициализируем TextPainter один раз
    _textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // 🔥 ОПТИМИЗАЦИЯ: Вычисляем углы лучей один раз
    _rayAngles = [];
    for (int i = 0; i < widget.rayCount; i++) {
      final totalAngle = widget.leftAngle - widget.rightAngle;
      final angleStep = totalAngle / (widget.rayCount - 1);
      final angleDegrees = widget.leftAngle - (i * angleStep);
      final angleRadians = angleDegrees * (math.pi / 180);
      _rayAngles.add(angleRadians);
    }
  }

  @override
  void dispose() {
    // 🔥 ДОБАВЛЕНО: Очищаем TextPainter ресурсы
    _textPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ДОБАВЛЕНО: Проверка disposed
    if (widget.isDisposed) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        size: Size.infinite,
        painter: _OptimizedMapPainter(
          rayCount: widget.rayCount,
          maxDistance: widget.maxDistance,
          distanceStep: widget.distanceStep,
          markers: widget.markers,
          bottomTypeColors: widget.bottomTypeColors,
          bottomTypeIcons: widget.bottomTypeIcons,
          context: widget.context,
          leftAngle: widget.leftAngle,
          rightAngle: widget.rightAngle,
          gridPaint: _gridPaint,
          rayPaint: _rayPaint,
          pointPaint: _pointPaint,
          markerPaint: _markerPaint,
          centerDotPaint: _centerDotPaint,
          textPainter: _textPainter,
          rayAngles: _rayAngles,
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    if (widget.isDisposed) return;

    final position = details.localPosition;

    // Проверяем нажатие на маркеры
    for (final marker in widget.markers) {
      if (marker.containsKey('_hitboxCenter') && marker.containsKey('_hitboxRadius')) {
        final center = marker['_hitboxCenter'] as Offset;
        final radius = marker['_hitboxRadius'] as double;

        if ((center - position).distance <= radius) {
          widget.onMarkerTap(marker);
          return;
        }
      }
    }
  }
}

// 🔥 УПРОЩЕННЫЙ PAINTER С ОПТИМИЗАЦИЯМИ
class _OptimizedMapPainter extends CustomPainter {
  final int rayCount;
  final double maxDistance;
  final double distanceStep;
  final List<Map<String, dynamic>> markers;
  final Map<String, Color> bottomTypeColors;
  final Map<String, IconData> bottomTypeIcons;
  final BuildContext context;
  final double leftAngle;
  final double rightAngle;

  // 🔥 ДОБАВЛЕНО: Переиспользуемые Paint объекты
  final Paint gridPaint;
  final Paint rayPaint;
  final Paint pointPaint;
  final Paint markerPaint;
  final Paint centerDotPaint;
  final TextPainter textPainter;
  final List<double> rayAngles;

  _OptimizedMapPainter({
    required this.rayCount,
    required this.maxDistance,
    required this.distanceStep,
    required this.markers,
    required this.bottomTypeColors,
    required this.bottomTypeIcons,
    required this.context,
    required this.leftAngle,
    required this.rightAngle,
    required this.gridPaint,
    required this.rayPaint,
    required this.pointPaint,
    required this.markerPaint,
    required this.centerDotPaint,
    required this.textPainter,
    required this.rayAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🔥 ОПТИМИЗАЦИЯ: Базовые вычисления один раз
    final centerX = size.width / 2;
    final originY = size.height - 5;
    final pixelsPerMeter = size.height / (maxDistance * 1.1);

    // Отрисовка полукругов (оптимизированная)
    _drawOptimizedGrid(canvas, centerX, originY, pixelsPerMeter);

    // Отрисовка лучей (оптимизированная)
    _drawOptimizedRays(canvas, centerX, originY, pixelsPerMeter);

    // Отрисовка точек пересечения (оптимизированная)
    _drawOptimizedPoints(canvas, centerX, originY, pixelsPerMeter);

    // Отрисовка подписей (оптимизированная)
    _drawOptimizedLabels(canvas, size, centerX, originY, pixelsPerMeter);

    // Отрисовка маркеров (оптимизированная)
    _drawOptimizedMarkers(canvas, size, centerX, originY, pixelsPerMeter);
  }

  void _drawOptimizedGrid(Canvas canvas, double centerX, double originY, double pixelsPerMeter) {
    // 🔥 ОПТИМИЗАЦИЯ: Упрощенная отрисовка сетки
    for (int distance = 10; distance <= maxDistance.toInt(); distance += 10) {
      final radius = distance * pixelsPerMeter;

      // Упрощенная пунктирная дуга
      final path = Path();
      final dashLength = 3.0;
      final gapLength = 6.0;
      final circumference = math.pi * radius;
      final numDashes = (circumference / (dashLength + gapLength)).floor();

      for (int i = 0; i < numDashes; i++) {
        final startAngle = math.pi + (i * (dashLength + gapLength) / radius);
        final endAngle = math.pi + ((i * (dashLength + gapLength) + dashLength) / radius);

        if (endAngle > math.pi * 2) break;

        final startX = centerX + radius * math.cos(startAngle);
        final startY = originY + radius * math.sin(startAngle);
        final endX = centerX + radius * math.cos(endAngle);
        final endY = originY + radius * math.sin(endAngle);

        path.moveTo(startX, startY);
        path.arcToPoint(Offset(endX, endY), radius: Radius.circular(radius));
      }

      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawOptimizedRays(Canvas canvas, double centerX, double originY, double pixelsPerMeter) {
    // 🔥 ОПТИМИЗАЦИЯ: Используем кэшированные углы
    final rayLength = maxDistance * pixelsPerMeter;

    for (final angle in rayAngles) {
      final endX = centerX + rayLength * math.cos(angle);
      final endY = originY - rayLength * math.sin(angle);
      canvas.drawLine(Offset(centerX, originY), Offset(endX, endY), rayPaint);
    }
  }

  void _drawOptimizedPoints(Canvas canvas, double centerX, double originY, double pixelsPerMeter) {
    // 🔥 ОПТИМИЗАЦИЯ: Упрощенная отрисовка точек
    for (final angle in rayAngles) {
      for (int distance = 10; distance <= maxDistance.toInt(); distance += 10) {
        final radius = distance * pixelsPerMeter;
        final pointX = centerX + radius * math.cos(angle);
        final pointY = originY - radius * math.sin(angle);

        if (pointY > 30) {
          canvas.drawCircle(Offset(pointX, pointY), 1.5, pointPaint);
        }
      }
    }
  }

  void _drawOptimizedLabels(Canvas canvas, Size size, double centerX, double originY, double pixelsPerMeter) {
    // 🔥 ОПТИМИЗАЦИЯ: Упрощенная отрисовка подписей

    // Подписи 10-50м
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
        centerX - distance * pixelsPerMeter + 4,
        originY - 20,
      );
      canvas.rotate(-math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Подписи 60-200м с фиксированными позициями
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

    // Подписи лучей
    final localizations = AppLocalizations.of(context);

    for (int i = 0; i < rayAngles.length && i < rayCount; i++) {
      final angle = rayAngles[i];

      double labelY = 50.0;
      final rayAtLabelY = (originY - labelY);
      double labelX = centerX + rayAtLabelY / math.tan(angle);

      // Индивидуальные корректировки для каждого луча
      switch (i) {
        case 0:
          labelY += 20.0;
          labelX -= 50.0;
          labelX = math.max(labelX, 35.0);
          break;
        case 1:
          labelY += 5.0;
          break;
        case 2:
          break;
        case 3:
          labelY += 5.0;
          break;
        case 4:
          labelY += 20.0;
          labelX += 50.0;
          labelX = math.min(labelX, size.width - 35.0);
          break;
      }

      textPainter.text = TextSpan(
        text: '${localizations.translate('ray')} ${i + 1}',
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

      if (i == 0) {
        labelX = math.max(labelX, textPainter.width / 2 + 10);
      } else if (i == rayCount - 1) {
        labelX = math.min(labelX, size.width - textPainter.width / 2 - 10);
      }

      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }
  }

  void _drawOptimizedMarkers(Canvas canvas, Size size, double centerX, double originY, double pixelsPerMeter) {
    // 🔥 ОПТИМИЗАЦИЯ: Упрощенная отрисовка маркеров
    for (final marker in markers) {
      final rayIndex = (marker['rayIndex'] as double? ?? 0).toInt();
      final distance = marker['distance'] as double? ?? 0;

      if (rayIndex >= rayAngles.length) continue;

      final angle = rayAngles[rayIndex];
      final ratio = distance / maxDistance;
      final maxRayLength = maxDistance * pixelsPerMeter;

      final dx = centerX + maxRayLength * ratio * math.cos(angle);
      final dy = originY - maxRayLength * ratio * math.sin(angle);

      // Определяем цвет маркера
      String bottomType = marker['bottomType'] ?? 'default';
      if (bottomType == 'default' && marker['type'] != null) {
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

      // 🔥 ОПТИМИЗАЦИЯ: Переиспользуем Paint объект
      markerPaint.color = markerColor;
      canvas.drawCircle(Offset(dx, dy), 8, markerPaint);
      canvas.drawCircle(Offset(dx, dy), 2, centerDotPaint);

      // Отрисовка подписей
      final labelOffsetX = 15.0;
      final labelX = dx + labelOffsetX;

      // Подпись глубины
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
        textPainter.paint(canvas, Offset(labelX, dy - 10));
      }

      // Подпись дистанции
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
      textPainter.paint(canvas, Offset(labelX, dy + 2));

      // Сохраняем хитбокс для тапов
      marker['_hitboxCenter'] = Offset(dx, dy);
      marker['_hitboxRadius'] = 15.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 🔥 ОПТИМИЗАЦИЯ: Перерисовываем только при изменении маркеров
    if (oldDelegate is _OptimizedMapPainter) {
      return markers.length != oldDelegate.markers.length ||
          markers.hashCode != oldDelegate.markers.hashCode;
    }
    return true;
  }
}