// Путь: lib/screens/marker_maps/modern_marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../widgets/loading_overlay.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../localization/app_localizations.dart';
import 'depth_chart_screen.dart';
import '../../services/subscription/subscription_service.dart';
import '../subscription/paywall_screen.dart';
import '../../repositories/marker_map_repository.dart';
import '../../providers/subscription_provider.dart';

// Импорты современных компонентов
import 'components/modern_map_background.dart';
import 'components/modern_map_grid.dart';
import 'components/modern_map_rays.dart';
import 'components/modern_map_labels.dart';
import 'components/modern_map_markers.dart';
import 'helpers/ray_landmarks_helper.dart';
import 'dialogs/ray_landmark_dialog.dart';

// 🚀 НОВЫЙ КЛАСС - Дебаунсер для автосохранения
class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// 🚀 НОВЫЙ КЛАСС - Константы типов дна
class _BottomTypeConstants {
  static const List<String> types = [
    'ил', 'глубокий_ил', 'ракушка', 'ровно_твердо', 'камни',
    'трава_водоросли', 'зацеп', 'бугор', 'точка_кормления',
  ];

  static const Map<String, Color> colors = {
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

  static const Map<String, IconData> icons = {
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

  static String getLocalizedName(String? type, AppLocalizations localizations) {
    if (type == null) return localizations.translate('silt');

    const Map<String, String> typeToKey = {
      'ил': 'silt',
      'глубокий_ил': 'deep_silt',
      'ракушка': 'shell',
      'ровно_твердо': 'firm_bottom',
      'камни': 'stones',
      'трава_водоросли': 'grass_algae',
      'зацеп': 'snag',
      'бугор': 'hill',
      'точка_кормления': 'feeding_spot',
    };

    return localizations.translate(typeToKey[type] ?? 'silt');
  }
}

class ModernMarkerMapScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const ModernMarkerMapScreen({super.key, required this.markerMap});

  @override
  ModernMarkerMapScreenState createState() => ModernMarkerMapScreenState();
}

class ModernMarkerMapScreenState extends State<ModernMarkerMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // 🔥 ОПТИМИЗИРОВАННЫЕ ПЕРЕМЕННЫЕ
  final _markerMapRepository = MarkerMapRepository();
  late MarkerMapModel _markerMap;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late _Debouncer _saveDebouncer;

  bool _isDisposed = false;
  bool _isAutoSaving = false;
  bool _ignoreLifecycleChanges = false; // 🚀 НОВЫЙ флаг для игнорирования lifecycle
  int _lastSelectedRayIndex = 0;
  String _currentBottomType = 'ил';

  // Контроллеры для диалогов
  final _depthController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();

  // Настройки карты
  static const int _raysCount = 5;
  static const double _maxDistance = 200.0;
  static const double _distanceStep = 10.0;
  static const double _leftAngle = 105.0;
  static const double _rightAngle = 75.0;

  @override
  void initState() {
    super.initState();
    _markerMap = widget.markerMap;

    // 🚀 ОПТИМИЗИРОВАННАЯ ИНИЦИАЛИЗАЦИЯ
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _saveDebouncer = _Debouncer(milliseconds: 500);
    _initAnimations();

    debugPrint('🗺️ ModernMarkerMapScreen: Открываем карту ID: ${_markerMap.id}');
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    debugPrint('🗺️ ModernMarkerMapScreen: Начинаем dispose...');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);
    _depthController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    _fadeController.dispose();
    _saveDebouncer.dispose();

    try {
      MarkerMapRepository.clearCache();
    } catch (e) {
      debugPrint('⚠️ Ошибка очистки кэша: $e');
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // 🚀 АГРЕССИВНО ОПТИМИЗИРОВАННОЕ управление lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔥 ПОЛНОСТЬЮ ИГНОРИРУЕМ lifecycle изменения когда:
    if (_isDisposed ||
        _ignoreLifecycleChanges ||
        _isAutoSaving ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      return; // 🚫 НЕ РЕАГИРУЕМ на эти состояния
    }

    // Логируем только критические изменения и БЕЗ дополнительных действий
    if (state == AppLifecycleState.resumed) {
      // Только лог, никаких обновлений данных!
      debugPrint('🔄 Экран карты активен');
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  double _calculateRayAngle(int rayIndex) {
    final totalAngle = _leftAngle - _rightAngle;
    final angleStep = totalAngle / (_raysCount - 1);
    return (_leftAngle - (rayIndex * angleStep)) * (math.pi / 180);
  }

  // 🚀 ОПТИМИЗИРОВАННОЕ АВТОСОХРАНЕНИЕ с дебаунсингом
  Future<void> _autoSaveChanges(String action) async {
    if (_isDisposed || !mounted || _ignoreLifecycleChanges) return;

    _saveDebouncer.run(() async {
      if (_isDisposed || !mounted || _ignoreLifecycleChanges) return;

      try {
        _safeSetState(() => _isAutoSaving = true);

        final markerMapToSave = _markerMap.copyWith(
          markers: _markerMap.markers.map((marker) {
            final cleanMarker = Map<String, dynamic>.from(marker);
            cleanMarker.remove('_hitboxCenter');
            cleanMarker.remove('_hitboxRadius');
            return cleanMarker;
          }).toList(),
          rayLandmarks: _markerMap.rayLandmarks,
        );

        await _markerMapRepository.updateMarkerMap(markerMapToSave);
        MarkerMapRepository.clearCache();

        if (!_isDisposed && mounted && !_ignoreLifecycleChanges) {
          _safeSetState(() => _isAutoSaving = false);
          _showSuccessSnackBar('$action - ${AppLocalizations.of(context).translate('saved')}');
        }
      } catch (e) {
        // 🔥 МИНИМАЛЬНОЕ логирование ошибок
        debugPrint('❌ Автосохранение: $e');
        if (!_isDisposed && mounted && !_ignoreLifecycleChanges) {
          _safeSetState(() => _isAutoSaving = false);
          _showErrorSnackBar('${AppLocalizations.of(context).translate('save_error')}: $e');
        }
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🚀 УНИВЕРСАЛЬНЫЙ ДИАЛОГ для добавления/редактирования маркера
  Future<void> _showMarkerDialog({Map<String, dynamic>? existingMarker}) async {
    if (_isDisposed) return;

    // 🔥 БЛОКИРУЕМ lifecycle обновления во время показа диалога
    _ignoreLifecycleChanges = true;

    final localizations = AppLocalizations.of(context);
    final isEditing = existingMarker != null;

    // Предзаполнение полей
    _depthController.text = existingMarker?['depth']?.toString() ?? '';
    _notesController.text = existingMarker?['notes'] ?? '';
    _distanceController.text = existingMarker?['distance']?.toString() ?? '';

    int selectedRayIndex = existingMarker?['rayIndex']?.toInt() ?? _lastSelectedRayIndex;
    String selectedBottomType = existingMarker?['bottomType'] ?? _currentBottomType;

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppConstants.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(isEditing, localizations),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1. ${localizations.translate('ray_selection')}',
                                  style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedRayIndex,
                                      isExpanded: true,
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
                                          _lastSelectedRayIndex = value;
                                          setDialogState(() {
                                            selectedRayIndex = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(_distanceController, 'distance_m', 'distance_hint', localizations, TextInputType.number),
                            const SizedBox(height: 20),
                            _buildTextField(_depthController, 'depth_m', 'depth_hint', localizations, TextInputType.numberWithOptions(decimal: true)),
                            const SizedBox(height: 20),
                            _buildTextField(_notesController, 'notes', 'notes_hint', localizations, TextInputType.text, maxLines: 3),
                            const SizedBox(height: 20),
                            _buildBottomTypeSelector(selectedBottomType, setDialogState, localizations),
                          ],
                        ),
                      ),
                    ),
                    _buildDialogButtons(isEditing, existingMarker, selectedRayIndex, selectedBottomType, localizations),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // 🔥 РАЗБЛОКИРУЕМ lifecycle обновления после закрытия диалога
    _ignoreLifecycleChanges = false;
  }

  Widget _buildDialogHeader(bool isEditing, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add_location,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.translate(isEditing ? 'edit_marker' : 'add_marker'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaySelector(int selectedRayIndex, StateSetter setDialogState, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. ${localizations.translate('ray_selection')}',
          style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedRayIndex,
              isExpanded: true,
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
                  _lastSelectedRayIndex = value;
                  setDialogState(() {
                    selectedRayIndex = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelKey, String hintKey,
      AppLocalizations localizations, TextInputType keyboardType, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${maxLines > 1 ? '4' : (labelKey == 'distance_m' ? '2' : '3')}. ${localizations.translate(labelKey)}',
          style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: AppConstants.textColor),
          decoration: InputDecoration(
            hintText: localizations.translate(hintKey),
            hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildBottomTypeSelector(String selectedBottomType, StateSetter setDialogState, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5. ${localizations.translate('marker_type')}',
          style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _BottomTypeConstants.types.map((type) {
            final isSelected = selectedBottomType == type;
            return GestureDetector(
              onTap: () => setDialogState(() => selectedBottomType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _BottomTypeConstants.colors[type]
                      : _BottomTypeConstants.colors[type]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _BottomTypeConstants.colors[type]! : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _BottomTypeConstants.icons[type],
                      color: isSelected ? Colors.black : AppConstants.textColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _BottomTypeConstants.getLocalizedName(type, localizations),
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppConstants.textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDialogButtons(bool isEditing, Map<String, dynamic>? existingMarker,
      int selectedRayIndex, String selectedBottomType, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppConstants.textColor.withOpacity(0.1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel'), style: TextStyle(color: AppConstants.textColor)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _saveMarker(isEditing, existingMarker, selectedRayIndex, selectedBottomType, localizations),
            child: Text(
              localizations.translate(isEditing ? 'save_changes' : 'add'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMarker(bool isEditing, Map<String, dynamic>? existingMarker,
      int selectedRayIndex, String selectedBottomType, AppLocalizations localizations) async {
    // Валидация
    if (_distanceController.text.isEmpty) {
      _showErrorSnackBar(localizations.translate('enter_distance'));
      return;
    }

    double? distance = double.tryParse(_distanceController.text);
    if (distance == null || distance <= 0) {
      _showErrorSnackBar(localizations.translate('enter_valid_distance'));
      return;
    }

    if (distance > _maxDistance) distance = _maxDistance;

    // Создание/обновление маркера
    final markerData = {
      'id': isEditing ? existingMarker!['id'] : const Uuid().v4(),
      'rayIndex': selectedRayIndex.toDouble(),
      'distance': distance,
      'name': localizations.translate('marker'),
      'depth': _depthController.text.isEmpty ? null : double.tryParse(_depthController.text),
      'notes': _notesController.text.trim(),
      'bottomType': selectedBottomType,
      'angle': _calculateRayAngle(selectedRayIndex),
      'ratio': distance / _maxDistance,
    };

    _lastSelectedRayIndex = selectedRayIndex;
    _currentBottomType = selectedBottomType;

    final updatedMarkers = List<Map<String, dynamic>>.from(_markerMap.markers);

    if (isEditing) {
      final markerIndex = updatedMarkers.indexWhere((m) => m['id'] == existingMarker!['id']);
      if (markerIndex != -1) {
        updatedMarkers[markerIndex] = markerData;
      }
    } else {
      updatedMarkers.add(markerData);
    }

    _safeSetState(() => _markerMap = _markerMap.copyWith(markers: updatedMarkers));
    Navigator.pop(context);

    await _autoSaveChanges(localizations.translate(isEditing ? 'marker_updated' : 'marker_added'));
  }

  // 🚀 УПРОЩЕННЫЙ показ деталей маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
    if (_isDisposed) return;

    // 🔥 БЛОКИРУЕМ lifecycle обновления во время показа деталей
    _ignoreLifecycleChanges = true;

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
                style: TextStyle(color: AppConstants.textColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMarkerDetailRow(Icons.straighten, 'ray', '${(marker['rayIndex'] + 1).toInt()}', localizations),
              _buildMarkerDetailRow(Icons.straighten, 'distance', '${marker['distance'].toInt()} ${localizations.translate('meters')}', localizations),
              if (marker['depth'] != null)
                _buildMarkerDetailRow(Icons.waves, 'depth', '${marker['depth']} ${localizations.translate('meters')}', localizations),
              _buildMarkerDetailRowWithIcon('bottom_type', _BottomTypeConstants.getLocalizedName(marker['bottomType'], localizations),
                  _BottomTypeConstants.icons[marker['bottomType']] ?? Icons.location_on,
                  _BottomTypeConstants.colors[marker['bottomType']] ?? Colors.blue, localizations),
              if (marker['notes'] != null && marker['notes'].isNotEmpty)
                _buildMarkerDetailRow(Icons.note, 'notes', marker['notes'], localizations),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMarkerDialog(existingMarker: marker);
                        },
                        icon: Icon(Icons.edit, color: AppConstants.primaryColor),
                        label: Text(localizations.translate('edit'), style: TextStyle(color: AppConstants.primaryColor)),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteMarker(marker['id']);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(localizations.translate('delete'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizations.translate('close')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // 🔥 РАЗБЛОКИРУЕМ lifecycle обновления после закрытия деталей
      _ignoreLifecycleChanges = false;
    });
  }

  Widget _buildMarkerDetailRow(IconData icon, String labelKey, String value, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text('${localizations.translate(labelKey)}: ', style: TextStyle(color: AppConstants.textColor, fontSize: 16)),
          Text(value, style: TextStyle(color: AppConstants.textColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMarkerDetailRowWithIcon(String labelKey, String value, IconData markerIcon, Color markerColor, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Icon(markerIcon, color: Colors.black87, size: 12),
          ),
          Text('${localizations.translate(labelKey)}: ', style: TextStyle(color: AppConstants.textColor, fontSize: 16)),
          Text(value, style: TextStyle(color: AppConstants.textColor, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _deleteMarker(String markerId) async {
    if (_isDisposed) return;

    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localizations.translate('delete_marker'), style: TextStyle(color: AppConstants.textColor)),
        content: Text(localizations.translate('delete_marker_confirmation'), style: TextStyle(color: AppConstants.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.translate('cancel'), style: TextStyle(color: AppConstants.textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.translate('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedMarkers = _markerMap.markers.where((marker) => marker['id'] != markerId).toList();
      _safeSetState(() => _markerMap = _markerMap.copyWith(markers: updatedMarkers));
      await _autoSaveChanges(localizations.translate('marker_deleted'));
    }
  }

  // 🚀 УПРОЩЕННАЯ справочная информация
  void _showMarkerInfo() {
    if (_isDisposed) return;

    // 🔥 БЛОКИРУЕМ lifecycle обновления во время показа справки
    _ignoreLifecycleChanges = true;

    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppConstants.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Справочник карты маркеров',
                        style: TextStyle(color: AppConstants.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('bottom_types_guide'),
                        style: TextStyle(color: AppConstants.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._BottomTypeConstants.types.map((type) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _BottomTypeConstants.colors[type],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: Icon(_BottomTypeConstants.icons[type], color: Colors.black87, size: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _BottomTypeConstants.getLocalizedName(type, localizations),
                                style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(localizations.translate('close'), style: TextStyle(color: AppConstants.textColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // 🔥 РАЗБЛОКИРУЕМ lifecycle обновления после закрытия справки
      _ignoreLifecycleChanges = false;
    });
  }

  Future<void> _showDepthCharts() async {
    if (_isDisposed) return;

    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.hasPremiumAccess) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const PaywallScreen(contentType: 'depth_charts', blockedFeature: 'Графики глубины'),
      ));
      return;
    }

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, _) => DepthChartScreen(markerMap: _markerMap),
      transitionsBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  // 🎯 ОБРАБОТКА КЛИКА НА ЛУЧ
  Future<void> _handleRayTap(int rayIndex) async {
    if (_isDisposed) return;

    // 🔥 БЛОКИРУЕМ lifecycle обновления во время работы с ориентирами
    _ignoreLifecycleChanges = true;

    try {
      final existingLandmark = RayLandmarksHelper.getLandmark(_markerMap.rayLandmarks, rayIndex);
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => RayLandmarkDialog(rayIndex: rayIndex, existingLandmark: existingLandmark),
      );

      if (result != null && !_isDisposed) {
        final action = result['action'] as String;
        if (action == 'save') {
          await _saveLandmark(rayIndex, result['iconType'] as String, result['comment'] as String);
        } else if (action == 'delete') {
          await _deleteLandmark(rayIndex);
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка обработки клика на луч: $e');
    } finally {
      // 🔥 РАЗБЛОКИРУЕМ lifecycle обновления после завершения работы
      _ignoreLifecycleChanges = false;
    }
  }

  Future<void> _saveLandmark(int rayIndex, String iconType, String comment) async {
    if (_isDisposed) return;

    try {
      final updatedLandmarks = RayLandmarksHelper.addLandmark(_markerMap.rayLandmarks, rayIndex, iconType, comment);
      _safeSetState(() => _markerMap = _markerMap.copyWith(rayLandmarks: updatedLandmarks));
      await _autoSaveChanges(AppLocalizations.of(context).translate('landmark_added'));
    } catch (e) {
      debugPrint('❌ Ошибка сохранения ориентира: $e');
    }
  }

  Future<void> _deleteLandmark(int rayIndex) async {
    if (_isDisposed) return;

    try {
      final updatedLandmarks = RayLandmarksHelper.removeLandmark(_markerMap.rayLandmarks, rayIndex);
      _safeSetState(() => _markerMap = _markerMap.copyWith(rayLandmarks: updatedLandmarks));
      await _autoSaveChanges(AppLocalizations.of(context).translate('landmark_deleted'));
    } catch (e) {
      debugPrint('❌ Ошибка удаления ориентира: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D),
      // 🚀 ИСПРАВЛЕНИЕ: Клавиатура НЕ сжимает карту, а накладывается поверх
      resizeToAvoidBottomInset: false,
      body: LoadingOverlay(
        isLoading: false,
        message: AppLocalizations.of(context).translate('please_wait'),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Stack(
                children: [
                  const ModernMapBackground(),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bottomPadding = MediaQuery.of(context).padding.bottom;
                        final availableHeight = constraints.maxHeight - bottomPadding;
                        final screenSize = Size(constraints.maxWidth, availableHeight);

                        return Stack(
                          children: [
                            ModernMapGrid(maxDistance: _maxDistance, distanceStep: _distanceStep, screenSize: screenSize),
                            ModernMapRays(
                              rayCount: _raysCount,
                              maxDistance: _maxDistance,
                              leftAngle: _leftAngle,
                              rightAngle: _rightAngle,
                              screenSize: screenSize,
                            ),
                            ModernMapLabels(
                              maxDistance: _maxDistance,
                              rayCount: _raysCount,
                              leftAngle: _leftAngle,
                              rightAngle: _rightAngle,
                              screenSize: screenSize,
                              rayLandmarks: _markerMap.rayLandmarks,
                              onRayTap: _handleRayTap,
                            ),
                            ModernMapMarkers(
                              markers: _markerMap.markers,
                              bottomTypeColors: _BottomTypeConstants.colors,
                              bottomTypeIcons: _BottomTypeConstants.icons,
                              onMarkerTap: _showMarkerDetails,
                              maxDistance: _maxDistance,
                              rayCount: _raysCount,
                              leftAngle: _leftAngle,
                              rightAngle: _rightAngle,
                              screenSize: screenSize,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_isAutoSaving) _buildSaveIndicator(),
                  ..._buildFloatingButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaveIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).translate('saving'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingButtons() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final baseBottom = 70.0 + bottomPadding;

    return [
      _buildFloatingButton(left: 20, bottom: baseBottom, icon: Icons.info_outline, onPressed: _showMarkerInfo),
      _buildFloatingButton(right: 20, bottom: baseBottom + 150, icon: Icons.arrow_back, onPressed: () => Navigator.pop(context, true)),
      _buildFloatingButton(right: 20, bottom: baseBottom + 75, icon: Icons.bar_chart, onPressed: _showDepthCharts, isPremium: true),
      _buildFloatingButton(right: 20, bottom: baseBottom, icon: Icons.add_location, onPressed: () => _showMarkerDialog(), isPrimary: true),
    ];
  }

  Widget _buildFloatingButton({
    double? left,
    double? right,
    required double bottom,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isPremium = false,
  }) {
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, _) {
          final showLock = isPremium && !subscriptionProvider.hasPremiumAccess;

          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: showLock
                    ? [Colors.orange.withOpacity(0.9), Colors.orange.withOpacity(0.7)]
                    : isPrimary
                    ? [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.8)]
                    : [AppConstants.primaryColor.withOpacity(0.9), AppConstants.primaryColor.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: isPrimary ? 28 : 24),
                    if (showLock)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 1.5),
                          ),
                          child: const Icon(Icons.lock, color: Colors.orange, size: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}