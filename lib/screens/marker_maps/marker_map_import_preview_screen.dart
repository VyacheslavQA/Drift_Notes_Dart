// Путь: lib/screens/marker_maps/marker_map_import_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../services/marker_map_share/marker_map_share_service.dart';
import '../../repositories/marker_map_repository.dart';
import '../../providers/subscription_provider.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/loading_overlay.dart';
import '../subscription/paywall_screen.dart';
import '../../constants/subscription_constants.dart';
import 'marker_maps_list_screen.dart';

class MarkerMapImportPreviewScreen extends StatefulWidget {
  final ImportResult importResult;
  final String sourceFilePath;

  const MarkerMapImportPreviewScreen({
    super.key,
    required this.importResult,
    required this.sourceFilePath,
  });

  @override
  State<MarkerMapImportPreviewScreen> createState() => _MarkerMapImportPreviewScreenState();
}

class _MarkerMapImportPreviewScreenState extends State<MarkerMapImportPreviewScreen> {
  final _markerMapRepository = MarkerMapRepository();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _nameConflict = false;
  List<MarkerMapModel> _existingMaps = [];

  // Типы дна для отображения маркеров
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
    _nameController.text = widget.importResult.markerMap?.name ?? '';
    _loadExistingMaps();
    _checkPremiumAccess();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 🔒 Проверка Premium доступа при инициализации
  void _checkPremiumAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      if (!subscriptionProvider.hasPremiumAccess) {
        debugPrint('🚫 Доступ к импорту карт заблокирован - показываем PaywallScreen');

        // Показываем PaywallScreen для импорта карт
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(
              contentType: 'marker_map_sharing',
              blockedFeature: 'Импорт маркерных карт',
            ),
          ),
        );
      }
    });
  }

  /// Загрузка существующих карт для проверки конфликтов имен
  Future<void> _loadExistingMaps() async {
    try {
      setState(() => _isLoading = true);

      _existingMaps = await _markerMapRepository.getUserMarkerMaps();
      _checkNameConflict();

    } catch (e) {
      debugPrint('❌ Ошибка загрузки существующих карт: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Проверка конфликта имен
  void _checkNameConflict() {
    final currentName = _nameController.text.trim();
    final hasConflict = _existingMaps.any((map) => map.name.toLowerCase() == currentName.toLowerCase());

    setState(() {
      _nameConflict = hasConflict;
    });
  }

  /// Получение названия типа дна
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
      default:
        return localizations.translate('silt');
    }
  }

  /// 🚀 ИСПРАВЛЕНО: Импорт карты с правильной навигацией
  Future<void> _importMap() async {
    final localizations = AppLocalizations.of(context);

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('enter_water_body_name')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Финальная проверка Premium доступа
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.hasPremiumAccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            contentType: 'marker_map_sharing',
            blockedFeature: 'Импорт маркерных карт',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Создаем обновленную карту с новым именем
      final updatedMap = widget.importResult.markerMap!.copyWith(
        name: _nameController.text.trim(),
      );

      // Импортируем через сервис
      final success = await MarkerMapShareService.importMarkerMap(
        markerMap: updatedMap,
        onImport: (map) async {
          // Сохраняем через Repository с кастомным ID
          await _markerMapRepository.addMarkerMap(map);
        },
      );

      if (success && mounted) {
        // Обновляем данные подписки
        try {
          await subscriptionProvider.refreshUsageData();
        } catch (e) {
          debugPrint('⚠️ Не удалось обновить данные подписки: $e');
        }

        debugPrint('✅ Карта успешно импортирована, переходим к списку карт');

        // 🚀 ИСПРАВЛЕНО: Принудительный переход к списку карт
        // Заменили Navigator.pop на pushAndRemoveUntil
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MarkerMapsListScreen(),
          ),
              (route) => false, // Очищаем весь стек навигации
        );

        // Показываем сообщение об успешном импорте
        // Используем delayed, чтобы экран успел загрузиться
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('map_imported_successfully')),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });

      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('import_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка импорта: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('import_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final importResult = widget.importResult;

    if (!importResult.isSuccess || importResult.markerMap == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.translate('import_error'),
            style: TextStyle(color: AppConstants.textColor),
          ),
          backgroundColor: AppConstants.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  importResult.error ?? localizations.translate('unknown_error'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
        ),
      );
    }

    final markerMap = importResult.markerMap!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('import_marker_map'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('importing_map'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 Карточка с информацией о файле
              _buildFileInfoCard(),

              const SizedBox(height: 16),

              // ✏️ Поле редактирования названия
              _buildNameEditField(),

              const SizedBox(height: 20),

              // 📊 Статистика карты
              _buildMapStatistics(),

              const SizedBox(height: 20),

              // 🎯 Список маркеров
              _buildMarkersList(),

              const SizedBox(height: 100), // Отступ для кнопки
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nameController.text.trim().isNotEmpty ? _importMap : null,
        backgroundColor: _nameController.text.trim().isNotEmpty
            ? AppConstants.primaryColor
            : Colors.grey,
        foregroundColor: AppConstants.textColor,
        icon: const Icon(Icons.download),
        label: Text(
          localizations.translate('import_map'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 📋 Карточка с информацией о файле
  Widget _buildFileInfoCard() {
    final localizations = AppLocalizations.of(context);
    final importResult = widget.importResult;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.file_download,
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
                        localizations.translate('received_marker_map'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (importResult.originalFileName != null)
                        Text(
                          importResult.originalFileName!,
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (importResult.exportDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${localizations.translate('exported')}: ${DateFormat('dd.MM.yyyy HH:mm').format(importResult.exportDate!)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
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

  /// ✏️ Поле редактирования названия
  Widget _buildNameEditField() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('water_body_name'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(color: AppConstants.textColor),
          decoration: InputDecoration(
            hintText: localizations.translate('enter_water_body_name'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppConstants.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (_) => _checkNameConflict(),
        ),
        if (_nameConflict) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  localizations.translate('map_name_exists'),
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 📊 Статистика карты
  Widget _buildMapStatistics() {
    final localizations = AppLocalizations.of(context);
    final markerMap = widget.importResult.markerMap!;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('map_information'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildStatItem(
              icon: Icons.calendar_today,
              label: localizations.translate('date'),
              value: DateFormat('dd.MM.yyyy').format(markerMap.date),
            ),

            if (markerMap.sector != null && markerMap.sector!.isNotEmpty)
              _buildStatItem(
                icon: Icons.grid_on,
                label: localizations.translate('sector'),
                value: markerMap.sector!,
              ),

            _buildStatItem(
              icon: Icons.location_on,
              label: localizations.translate('markers_count'),
              value: '${markerMap.markers.length}',
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Элемент статистики
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
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
      ),
    );
  }

  /// 🎯 Список маркеров
  Widget _buildMarkersList() {
    final localizations = AppLocalizations.of(context);
    final markers = widget.importResult.markerMap!.markers;

    if (markers.isEmpty) {
      return Card(
        color: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              localizations.translate('no_markers'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('markers_list'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Ограничиваем высоту списка
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: markers.length,
              separatorBuilder: (context, index) => Divider(
                color: AppConstants.textColor.withOpacity(0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final marker = markers[index];
                return _buildMarkerItem(marker, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Элемент маркера
  Widget _buildMarkerItem(Map<String, dynamic> marker, int number) {
    final localizations = AppLocalizations.of(context);
    final bottomType = marker['bottomType'] as String?;
    final distance = marker['distance'] as num?;
    final depth = marker['depth'] as num?;
    final rayIndex = marker['rayIndex'] as num?;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _bottomTypeColors[bottomType] ?? _bottomTypeColors['default']!,
        child: Icon(
          _bottomTypeIcons[bottomType] ?? _bottomTypeIcons['default']!,
          color: Colors.black87,
          size: 18,
        ),
      ),
      title: Text(
        '${localizations.translate('marker')} $number',
        style: TextStyle(
          color: AppConstants.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rayIndex != null && distance != null)
            Text(
              '${localizations.translate('ray')} ${(rayIndex.toInt() + 1)}, ${distance.toInt()} ${localizations.translate('distance_m')}',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          if (depth != null)
            Text(
              '${localizations.translate('depth')}: ${depth.toString()} ${localizations.translate('meters')}',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          Text(
            _getBottomTypeName(bottomType),
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}