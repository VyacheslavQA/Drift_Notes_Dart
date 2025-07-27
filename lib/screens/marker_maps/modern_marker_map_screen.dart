// Путь: lib/screens/marker_maps/modern_marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../services/firebase/firebase_service.dart';
import '../../widgets/loading_overlay.dart';
import 'dart:math' as math;
import '../../localization/app_localizations.dart';
import 'depth_chart_screen.dart';
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';
import '../subscription/paywall_screen.dart';
import '../../repositories/marker_map_repository.dart';
import '../../providers/subscription_provider.dart';

// Импорты современных компонентов
import 'components/modern_map_background.dart';
import 'components/modern_map_grid.dart';
import 'components/modern_map_rays.dart';
import 'components/modern_map_labels.dart';
import 'components/modern_map_markers.dart';
import 'utils/map_calculations.dart';

class ModernMarkerMapScreen extends StatefulWidget {
  final MarkerMapModel markerMap;

  const ModernMarkerMapScreen({super.key, required this.markerMap});

  @override
  ModernMarkerMapScreenState createState() => ModernMarkerMapScreenState();
}

class ModernMarkerMapScreenState extends State<ModernMarkerMapScreen>
    with TickerProviderStateMixin {
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

  // 🔥 Флаг disposed для предотвращения утечек
  bool _isDisposed = false;

  // 🎬 Контроллеры анимаций
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;

  // Сохранение последнего выбранного луча
  int _lastSelectedRayIndex = 0;

  // Настройки карты (те же что в оригинале)
  final int _raysCount = 5;
  final double _maxDistance = 200.0;
  final double _distanceStep = 10.0;
  final double _leftAngle = 105.0;
  final double _rightAngle = 75.0;

  // Типы дна для маркеров (те же что в оригинале)
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

  // Цвета и иконки (те же что в оригинале)
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

    // 🎬 Инициализация анимаций
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 🎬 Запуск анимации загрузки
    _fadeController.forward();
    _staggerController.forward();

    debugPrint('🗺️ ModernMarkerMapScreen: Открываем современную карту маркеров ID: ${_markerMap.id}');
  }

  @override
  void dispose() {
    debugPrint('🗺️ ModernMarkerMapScreen: Начинаем dispose...');

    _isDisposed = true;

    // Освобождаем контроллеры
    _depthController.dispose();
    _notesController.dispose();
    _distanceController.dispose();

    // 🎬 Освобождаем контроллеры анимаций
    _fadeController.dispose();
    _staggerController.dispose();

    // Очищаем кэш Repository
    try {
      MarkerMapRepository.clearCache();
      debugPrint('🗺️ Кэш Repository очищен в dispose');
    } catch (e) {
      debugPrint('⚠️ Ошибка очистки кэша Repository: $e');
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    debugPrint('🗺️ ModernMarkerMapScreen: dispose завершен успешно');
    super.dispose();
  }

  // 🔥 Безопасный setState с проверкой disposed
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

  // Вычисление угла луча
  double _calculateRayAngle(int rayIndex) {
    final totalAngle = _leftAngle - _rightAngle;
    final angleStep = totalAngle / (_raysCount - 1);
    return (_leftAngle - (rayIndex * angleStep)) * (math.pi / 180);
  }

  // Автосохранение с проверкой disposed
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

      await _markerMapRepository.updateMarkerMap(markerMapToSave);

      MarkerMapRepository.clearCache();

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isAutoSaving = false;
          _saveMessage = '';
        });

        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action} - ${localizations.translate('saved')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка автосохранения: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isAutoSaving = false;
          _saveMessage = '';
        });

        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('save_error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Показ информации о маркерах с типами дна
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
                    color: AppConstants.primaryColor.withOpacity(0.1),
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
                          'Справочник карты маркеров',
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
                        // 📋 ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ
                        Text(
                          localizations.translate('how_to_use_guide'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          icon: Icons.add_location,
                          title: localizations.translate('adding_marker_title'),
                          description: localizations.translate('adding_marker_instruction'),
                        ),
                        _buildInstructionItem(
                          icon: Icons.touch_app,
                          title: localizations.translate('view_details_title'),
                          description: localizations.translate('view_details_instruction'),
                        ),
                        _buildInstructionItem(
                          icon: Icons.palette,
                          title: localizations.translate('marker_colors_title'),
                          description: localizations.translate('marker_colors_instruction'),
                        ),

                        const SizedBox(height: 24),

                        // 🎨 ТИПЫ ДНА
                        Text(
                          localizations.translate('bottom_types_guide'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Список типов дна с цветными кружками и иконками
                        ...(_bottomTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // Цветной кружок с иконкой (как настоящий маркер)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _bottomTypeColors[type] ?? Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _bottomTypeIcons[type] ?? Icons.location_on,
                                    color: Colors.black87,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Название типа дна
                                Expanded(
                                  child: Text(
                                    _getBottomTypeName(type),
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Цветная метка для дополнительной наглядности
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _bottomTypeColors[type] ?? Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()),

                        const SizedBox(height: 24),

                        // 💡 ДОПОЛНИТЕЛЬНЫЕ СОВЕТЫ
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: AppConstants.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.translate('useful_tips_title'),
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.translate('useful_tips_content'),
                                style: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.8),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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
                        color: AppConstants.textColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.translate('close'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w600,
                          ),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Показ деталей маркера
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
              Text(
                '${localizations.translate('ray')} ${(marker['rayIndex'] + 1).toInt()}, ${marker['distance'].toInt()} ${localizations.translate('distance_m')}',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
              ),
              if (marker['depth'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('depth')}: ${marker['depth']} ${localizations.translate('meters')}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
              if (marker['notes'] != null && marker['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  marker['notes'],
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
    );
  }

  // 🔥 НОВЫЙ ДИАЛОГ ДОБАВЛЕНИЯ МАРКЕРА В ПРАВИЛЬНОМ ПОРЯДКЕ
  Future<void> _showAddMarkerDialog() async {
    if (_isDisposed) return;

    final localizations = AppLocalizations.of(context);

    _depthController.text = '';
    _notesController.text = '';
    _distanceController.text = '';

    int selectedRayIndex = _lastSelectedRayIndex;
    String selectedBottomType = _currentBottomType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок
                    Container(
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
                            Icons.add_location,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.translate('add_marker'),
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
                            // 1️⃣ ВЫБОР ЛУЧА
                            Text(
                              '1. ${localizations.translate('ray_selection')}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppConstants.primaryColor.withOpacity(0.3),
                                ),
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
                                      setDialogState(() {
                                        selectedRayIndex = value;
                                      });
                                      _lastSelectedRayIndex = value;
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2️⃣ РАССТОЯНИЕ
                            Text(
                              '2. ${localizations.translate('distance_m')}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _distanceController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                hintText: localizations.translate('distance_hint'),
                                hintStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),

                            // 3️⃣ ГЛУБИНА
                            Text(
                              '3. ${localizations.translate('depth_m')}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _depthController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                hintText: localizations.translate('depth_hint'),
                                hintStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 20),

                            // 4️⃣ ЗАМЕТКИ
                            Text(
                              '4. ${localizations.translate('notes')}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                hintText: localizations.translate('notes_hint'),
                                hintStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                            const SizedBox(height: 20),

                            // 5️⃣ ВЫБОР ТИПА ДНА
                            Text(
                              '5. ${localizations.translate('marker_type')}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _bottomTypes.map((type) {
                                final isSelected = selectedBottomType == type;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedBottomType = type;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _bottomTypeColors[type] ?? Colors.grey
                                          : _bottomTypeColors[type]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? _bottomTypeColors[type] ?? Colors.grey
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _bottomTypeIcons[type],
                                          color: isSelected ? Colors.black : AppConstants.textColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getBottomTypeName(type),
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
                        ),
                      ),
                    ),

                    // Кнопки
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppConstants.textColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              localizations.translate('cancel'),
                              style: TextStyle(color: AppConstants.textColor),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: AppConstants.textColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              // Валидация
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
                              if (distance == null || distance <= 0) {
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
                              }

                              // Создание маркера
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

                              if (!_isDisposed) {
                                _safeSetState(() {
                                  _markerMap = _markerMap.copyWith(markers: updatedMarkers);
                                });
                              }

                              Navigator.pop(context);

                              await _autoSaveChanges(localizations.translate('marker_added'));
                            },
                            child: Text(
                              localizations.translate('add'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
      },
    );
  }

  // 🚀 ИНТЕГРАЦИЯ ГРАФИКОВ ГЛУБИНЫ - С ПРОВЕРКОЙ ПОДПИСКИ
  Future<void> _showDepthCharts() async {
    if (_isDisposed) return;

    debugPrint('📊 Проверяем доступ к графикам глубины...');

    // 🔒 ПРОВЕРКА ПОДПИСКИ
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subscriptionProvider.hasPremiumAccess) {
      debugPrint('🚫 Доступ к графикам заблокирован - показываем PaywallScreen');

      // Показываем PaywallScreen для графиков глубины
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            contentType: 'depth_charts',
            blockedFeature: 'Графики глубины',
          ),
        ),
      );
      return;
    }

    debugPrint('✅ Premium доступ подтвержден - переходим к графикам глубины с ${_markerMap.markers.length} маркерами');

    // 🎬 ПРОСТАЯ АНИМАЦИЯ slide справа налево
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => DepthChartScreen(markerMap: _markerMap),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0), // справа
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _exitScreen() async {
    debugPrint('🚪 Выходим из экрана современной карты');
    if (mounted && !_isDisposed) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1D),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: AppLocalizations.of(context).translate('please_wait'),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Stack(
                children: [
                  // 🎨 1. СОВРЕМЕННЫЙ ФОН
                  const ModernMapBackground(),

                  // 🎨 2. ОСНОВНАЯ КАРТА
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 🔥 ИСПРАВЛЕНО: Учитываем нижнюю навигацию
                        final bottomPadding = MediaQuery.of(context).padding.bottom;
                        final availableHeight = constraints.maxHeight - bottomPadding;
                        final screenSize = Size(constraints.maxWidth, availableHeight);

                        return Stack(
                          children: [
                            // 🎨 3. СЕТКА КОНЦЕНТРИЧЕСКИХ ОКРУЖНОСТЕЙ
                            ModernMapGrid(
                              maxDistance: _maxDistance,
                              distanceStep: _distanceStep,
                              screenSize: screenSize,
                            ),

                            // 🎨 4. ЛУЧИ
                            ModernMapRays(
                              rayCount: _raysCount,
                              maxDistance: _maxDistance,
                              leftAngle: _leftAngle,
                              rightAngle: _rightAngle,
                              screenSize: screenSize,
                            ),

                            // 🎨 5. ПОДПИСИ РАССТОЯНИЙ И ЛУЧЕЙ
                            ModernMapLabels(
                              maxDistance: _maxDistance,
                              rayCount: _raysCount,
                              leftAngle: _leftAngle,
                              rightAngle: _rightAngle,
                              screenSize: screenSize,
                            ),

                            // 🎨 6. МАРКЕРЫ С АНИМАЦИЯМИ
                            ModernMapMarkers(
                              markers: _markerMap.markers,
                              bottomTypeColors: _bottomTypeColors,
                              bottomTypeIcons: _bottomTypeIcons,
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

                  // 🎨 7. ИНДИКАТОР АВТОСОХРАНЕНИЯ
                  if (_isAutoSaving)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildModernSaveIndicator(),
                      ),
                    ),

                  // 🎨 8. СОВРЕМЕННЫЕ FLOATING КНОПКИ
                  ..._buildModernFloatingButtons(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🎨 Современный индикатор сохранения
  Widget _buildModernSaveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).translate('saving'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Современные floating кнопки с glassmorphism
  List<Widget> _buildModernFloatingButtons(BuildContext context) {
    final buttons = <Widget>[];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Кнопка информации
    buttons.add(_buildSingleFloatingButton(
      left: 20,
      bottom: 70 + bottomPadding,
      icon: Icons.info_outline,
      heroTag: "info_button",
      onPressed: _showMarkerInfo,
      delay: 0,
    ));

    // Кнопка выхода
    buttons.add(_buildSingleFloatingButton(
      right: 20,
      bottom: 220 + bottomPadding,
      icon: Icons.arrow_back,
      heroTag: "exit_button",
      onPressed: _exitScreen,
      delay: 100,
    ));

    // Кнопка графиков (ТЕПЕРЬ С ПРОВЕРКОЙ ПОДПИСКИ!)
    buttons.add(_buildSingleFloatingButton(
      right: 20,
      bottom: 145 + bottomPadding,
      icon: Icons.bar_chart,
      heroTag: "charts_button",
      onPressed: _showDepthCharts,
      delay: 200,
      isPremiumFeature: true, // 🔒 Помечаем как Premium функцию
      tooltip: AppLocalizations.of(context).translate('depth_charts'), // 📋 Подсказка
    ));

    // Кнопка добавления маркера
    buttons.add(_buildSingleFloatingButton(
      right: 20,
      bottom: 70 + bottomPadding,
      icon: Icons.add_location,
      heroTag: "add_marker_button",
      onPressed: _showAddMarkerDialog,
      delay: 300,
      isPrimary: true,
    ));

    return buttons;
  }

  /// 🎨 Отдельная современная floating кнопка
  Widget _buildSingleFloatingButton({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required IconData icon,
    required String heroTag,
    required VoidCallback onPressed,
    required int delay,
    bool isPrimary = false,
    bool isPremiumFeature = false, // 🔒 НОВЫЙ параметр для Premium функций
    String? tooltip, // 📋 НОВЫЙ параметр для подсказок
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _staggerController,
        builder: (context, child) {
          final delayedAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              delay / 1000,
              (delay + 300) / 1000,
              curve: Curves.elasticOut,
            ),
          ));

          return Transform.scale(
            scale: delayedAnimation.value,
            child: Consumer<SubscriptionProvider>(
              builder: (context, subscriptionProvider, _) {
                // 🔒 Проверяем нужно ли показывать замочек для Premium функций
                final showLock = isPremiumFeature && !subscriptionProvider.hasPremiumAccess;

                Widget buttonWidget = Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPrimary
                              ? [
                            AppConstants.primaryColor,
                            AppConstants.primaryColor.withOpacity(0.8),
                          ]
                              : showLock
                              ? [
                            Colors.orange.withOpacity(0.9),
                            Colors.orange.withOpacity(0.7),
                          ]
                              : [
                            AppConstants.primaryColor.withOpacity(0.9),
                            AppConstants.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: (showLock ? Colors.orange : AppConstants.primaryColor).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onPressed();
                          },
                          child: Hero(
                            tag: heroTag,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 🎯 ВСЕГДА показываем основную иконку
                                Icon(
                                  icon,
                                  color: Colors.white,
                                  size: isPrimary ? 28 : 24,
                                ),

                                // 🔒 Накладываем замочек ПОВЕРХ для Premium функций
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
                                        border: Border.all(
                                          color: Colors.orange,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock,
                                        color: Colors.orange,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 🔒 Индикатор Premium для платных функций
                    if (showLock)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                );

                // 📋 Добавляем Tooltip если задан
                if (tooltip != null) {
                  return Tooltip(
                    message: showLock
                        ? '${tooltip} - Premium'
                        : tooltip,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: buttonWidget,
                  );
                }

                return buttonWidget;
              },
            ),
          );
        },
      ),
    );
  }
}