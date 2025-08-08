// Путь: lib/screens/marker_maps/marker_maps_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/subscription_constants.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../services/subscription/subscription_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/subscription/usage_badge.dart';
import '../subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';
// 🚀 ИНТЕГРАЦИЯ: Заменяем старый экран на современный
import 'modern_marker_map_screen.dart';
// 🆕 НОВОЕ: Импорт экрана фильтрации
import 'water_body_filter_screen.dart';
// 🚀 НОВЫЕ ИМПОРТЫ для экспорта/импорта карт
import '../../services/marker_map_share/marker_map_share_service.dart';
import 'marker_map_import_preview_screen.dart';

class MarkerMapsListScreen extends StatefulWidget {
  const MarkerMapsListScreen({super.key});

  @override
  State<MarkerMapsListScreen> createState() => _MarkerMapsListScreenState();

  // 🚀 УПРОЩЕНО: Статический метод теперь проще и надежнее
  static Future<void> handleMarkerMapImport(BuildContext context, String filePath) async {
    debugPrint('🔍 handleMarkerMapImport: Начинаем импорт файла $filePath');

    try {
      // 1. Проверка Premium статуса
      debugPrint('📋 Проверяем Premium статус...');
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final hasPremium = subscriptionProvider.hasPremiumAccess;
      debugPrint('📋 Premium статус: $hasPremium');

      if (!hasPremium) {
        debugPrint('❌ Нет Premium - показываем PaywallScreen');

        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaywallScreen(
                contentType: 'marker_map_sharing',
                blockedFeature: 'Импорт маркерных карт',
              ),
            ),
          );
        }
        return;
      }

      // 2. Парсинг файла
      debugPrint('📄 Парсим файл...');
      final importResult = await MarkerMapShareService.parseMarkerMapFile(filePath);
      debugPrint('✅ Результат парсинга: success=${importResult.isSuccess}, error=${importResult.error}');

      if (!importResult.isSuccess || importResult.markerMap == null) {
        debugPrint('❌ Ошибка парсинга файла: ${importResult.error}');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(importResult.error ?? 'Ошибка импорта файла'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 3. Переход к экрану превью
      debugPrint('🚀 Переходим к экрану превью импорта...');

      if (!context.mounted) {
        debugPrint('❌ Контекст недоступен для навигации');
        return;
      }

      // 🚀 УПРОЩЕНО: Убрали сложную логику навигации
      // Теперь просто показываем превью экран
      // Вся навигация после импорта происходит внутри превью экрана
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkerMapImportPreviewScreen(
            importResult: importResult,
            sourceFilePath: filePath,
          ),
        ),
      );

      debugPrint('✅ Процесс импорта завершен (навигация управляется превью экраном)');

    } catch (e) {
      debugPrint('❌ Критическая ошибка обработки импорта файла: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка импорта: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _MarkerMapsListScreenState extends State<MarkerMapsListScreen> {
  final _markerMapRepository = MarkerMapRepository();
  final _subscriptionService = SubscriptionService();

  List<MarkerMapModel> _allMaps = [];
  List<MarkerMapModel> _filteredMaps = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 🆕 НОВОЕ: Простая фильтрация по водоему
  String? _selectedWaterBody;

  // 🚀 НОВЫЕ ПЕРЕМЕННЫЕ для контроля обновлений
  bool _hasDataLoaded = false;
  double _lastKeyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (kDebugMode) {
      debugPrint('🗺️ MarkerMapsListScreen: Инициализация экрана списка карт с фильтрацией по водоемам');
    }
  }

  // 🚀 КАРДИНАЛЬНО ИСПРАВЛЕНО: Умное обновление данных только когда нужно
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔥 АГРЕССИВНАЯ ЗАЩИТА ОТ ИЗБЫТОЧНЫХ ОБНОВЛЕНИЙ
    final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 🚫 НЕ ОБНОВЛЯЕМ ДАННЫЕ если:
    // 1. Клавиатура открыта/закрыта (изменилась высота)
    // 2. Данные уже загружены ранее
    // 3. Это первый запуск (данные загружаются в initState)
    if (currentKeyboardHeight != _lastKeyboardHeight || !_hasDataLoaded) {
      _lastKeyboardHeight = currentKeyboardHeight;

      // Если клавиатура видима - НЕ обновляем данные
      if (currentKeyboardHeight > 0) {
        if (kDebugMode) {
          debugPrint('🚫 Клавиатура открыта ($currentKeyboardHeight) - обновление данных отменено');
        }
        return;
      }

      // Если данные еще не загружались - не дублируем initState
      if (!_hasDataLoaded) {
        if (kDebugMode) {
          debugPrint('🚫 Первый запуск - данные загружаются в initState');
        }
        return;
      }
    }

    // ✅ ОБНОВЛЯЕМ только при реальном возврате на экран (когда клавиатура скрыта)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && currentKeyboardHeight == 0 && _hasDataLoaded) {
        _loadData();
        if (kDebugMode) {
          debugPrint('🔄 Автообновление данных после возврата на экран (клавиатура скрыта)');
        }
      }
    });
  }

  // Оптимизация: Универсальный метод для async операций с loading
  Future<void> _performAsyncOperation(
      Future<void> Function() operation, {
        String? successMessage,
        String? errorPrefix,
      }) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await operation();

      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка операции: $e');
      }

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        final message = errorPrefix != null ? '$errorPrefix: $e' : '$e';

        if (e.toString().contains('лимит') || e.toString().contains('limit')) {
          _showPaywallScreen();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    await _performAsyncOperation(() async {
      // 🚀 МИНИМАЛЬНОЕ логирование только при реальной загрузке
      if (kDebugMode && !_hasDataLoaded) {
        debugPrint('📥 Загружаем маркерные карты через Repository...');
      }

      final maps = await _markerMapRepository.getUserMarkerMaps();

      if (mounted) {
        setState(() {
          _allMaps = maps;
          _hasDataLoaded = true; // 🚀 ПОМЕЧАЕМ что данные загружены
        });
        _applyFilter();

        // 🚀 ЛОГИРУЕМ только при первой загрузке или значительных изменениях
        if (kDebugMode) {
          debugPrint('✅ Загружено ${maps.length} маркерных карт через Repository');
        }
      }
    }, errorPrefix: 'Ошибка загрузки данных');
  }

  // 🆕 НОВОЕ: Простое применение фильтра по водоему
  void _applyFilter() {
    if (_selectedWaterBody == null) {
      _filteredMaps = List.from(_allMaps);
    } else {
      _filteredMaps = _allMaps.where((map) => map.name == _selectedWaterBody).toList();
    }

    // Сортировка по дате (новые сначала)
    _filteredMaps.sort((a, b) => b.date.compareTo(a.date));

    setState(() {});

    // 🚀 ОПТИМИЗИРОВАННОЕ логирование фильтрации
    if (kDebugMode && _selectedWaterBody != null) {
      debugPrint('🔍 Фильтрация по водоему "$_selectedWaterBody": ${_filteredMaps.length} из ${_allMaps.length} карт');
    }
  }

  // 🆕 НОВОЕ: Открытие экрана фильтрации
  Future<void> _openFilterScreen() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => WaterBodyFilterScreen(
          allMaps: _allMaps,
          currentFilter: _selectedWaterBody,
        ),
      ),
    );

    if (result != _selectedWaterBody) {
      setState(() {
        _selectedWaterBody = result;
      });
      _applyFilter();
    }
  }

  Future<void> _handleCreateMapPress() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Проверяем возможность создания маркерной карты...');
      }

      final canCreate = await _markerMapRepository.canCreateMarkerMap();

      if (kDebugMode) {
        debugPrint('✅ Результат canCreateMarkerMap: $canCreate');
      }

      if (!canCreate) {
        if (kDebugMode) {
          debugPrint('❌ Лимит превышен, показываем PaywallScreen');
        }
        _showPaywallScreen();
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ Лимиты позволяют создать карту, переходим к созданию');
      }
      _showMapFormDialog();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка при проверке лимитов: $e');
      }
      _showPaywallScreen();
    }
  }

  void _showPaywallScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: ContentType.markerMaps.name,
        ),
      ),
    );
  }

  // 🚀 ОБНОВЛЕНО: Меню настроек карты с активной кнопкой экспорта
  Future<void> _showMapSettingsMenu(MarkerMapModel map) async {
    final localizations = AppLocalizations.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.translate('map_settings'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingsMenuItem(
                  icon: Icons.edit,
                  title: localizations.translate('edit_map'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMapFormDialog(existingMap: map);
                  },
                ),

                // 🚀 ИСПРАВЛЕНО: Унифицированная проверка Premium
                Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, _) {
                    final hasPremium = subscriptionProvider.hasPremiumAccess;

                    return _buildSettingsMenuItem(
                      icon: hasPremium ? Icons.share : Icons.share_outlined,
                      title: localizations.translate('share_map'),
                      isEnabled: hasPremium,
                      onTap: () {
                        Navigator.pop(context);
                        if (hasPremium) {
                          _shareMarkerMap(map);
                        } else {
                          _showSharePaywall();
                        }
                      },
                    );
                  },
                ),

                const Divider(color: Colors.grey),
                _buildSettingsMenuItem(
                  icon: Icons.delete,
                  title: localizations.translate('delete_map'),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMap(map);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Оптимизация: Вынесли повторяющийся элемент меню
  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isEnabled = true,
  }) {
    final effectiveColor = isEnabled
        ? (color ?? AppConstants.primaryColor)
        : AppConstants.textColor.withOpacity(0.4);

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        title,
        style: TextStyle(color: effectiveColor, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  // 🚀 НОВЫЙ МЕТОД: Экспорт маркерной карты
  Future<void> _shareMarkerMap(MarkerMapModel map) async {
    final localizations = AppLocalizations.of(context);

    try {
      setState(() => _isLoading = true);

      debugPrint('📤 Начинаем экспорт карты: ${map.name}');

      final success = await MarkerMapShareService.exportMarkerMap(
        markerMap: map,
        context: context,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('map_exported_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('export_error')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка экспорта карты: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('export_error')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🚀 НОВЫЙ МЕТОД: Показ Paywall для экспорта карт
  void _showSharePaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(
          contentType: 'marker_map_sharing',
          blockedFeature: 'Экспорт маркерных карт',
        ),
      ),
    );
  }

  // Упрощенный диалог для создания/редактирования БЕЗ выбора заметок
  Future<void> _showMapFormDialog({MarkerMapModel? existingMap}) async {
    final localizations = AppLocalizations.of(context);
    final isEditing = existingMap != null;

    final nameController = TextEditingController(text: existingMap?.name ?? '');
    final sectorController = TextEditingController(text: existingMap?.sector ?? '');

    DateTime selectedDate = existingMap?.date ?? DateTime.now();

    final result = await showDialog<MarkerMapModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: AppConstants.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(
                      isEditing
                          ? localizations.translate('edit_map_information')
                          : localizations.translate('create_marker_map'),
                      isEditing ? Icons.edit : Icons.map,
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNameField(nameController, localizations),
                            const SizedBox(height: 20),
                            _buildDateField(selectedDate, dialogSetState, localizations),
                            const SizedBox(height: 20),
                            _buildSectorField(sectorController, localizations),
                          ],
                        ),
                      ),
                    ),
                    _buildDialogButtons(
                      nameController,
                      selectedDate,
                      sectorController,
                      existingMap,
                      localizations,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      if (isEditing) {
        await _updateMap(result);
      } else {
        await _createMap(result);
      }
    }
  }

  // Оптимизация: Вынесли компоненты диалога
  Widget _buildDialogHeader(String title, IconData icon) {
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
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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

  // 🚀 ОБНОВЛЕНО: Новый современный дизайн поля без звездочки
  Widget _buildNameField(TextEditingController controller, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryColor,
              width: 2,
            ),
            color: AppConstants.primaryColor.withOpacity(0.05),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: localizations.translate('water_body_name'),
              labelStyle: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.translate('required_field'),
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(DateTime selectedDate, StateSetter dialogSetState, AppLocalizations localizations) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppConstants.primaryColor,
                  onPrimary: AppConstants.textColor,
                  surface: AppConstants.surfaceColor,
                  onSurface: AppConstants.textColor,
                ),
                dialogTheme: DialogThemeData(backgroundColor: AppConstants.backgroundColor),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          dialogSetState(() {
            selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppConstants.textColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppConstants.textColor, size: 18),
            const SizedBox(width: 12),
            Text(
              '${localizations.translate('date')}: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
              style: TextStyle(color: AppConstants.textColor, fontSize: 16),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: AppConstants.textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorField(TextEditingController controller, AppLocalizations localizations) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppConstants.textColor),
      decoration: InputDecoration(
        labelText: '${localizations.translate('sector')}',
        labelStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
      ),
    );
  }

  Widget _buildDialogButtons(
      TextEditingController nameController,
      DateTime selectedDate,
      TextEditingController sectorController,
      MarkerMapModel? existingMap,
      AppLocalizations localizations,
      ) {
    return Container(
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existingMap != null
                          ? localizations.translate('map_name_required')
                          : localizations.translate('required_field'),
                    ),
                  ),
                );
                return;
              }

              final mapData = existingMap?.copyWith(
                name: nameController.text.trim(),
                date: selectedDate,
                sector: sectorController.text.trim().isEmpty ? null : sectorController.text.trim(),
              ) ?? MarkerMapModel(
                id: const Uuid().v4(),
                userId: '',
                name: nameController.text.trim(),
                date: selectedDate,
                sector: sectorController.text.trim().isEmpty ? null : sectorController.text.trim(),
                markers: [],
              );

              Navigator.pop(context, mapData);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: Text(
              existingMap != null
                  ? localizations.translate('save')
                  : localizations.translate('add'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMap(MarkerMapModel updatedMap) async {
    final localizations = AppLocalizations.of(context);

    await _performAsyncOperation(
          () async {
        await _markerMapRepository.updateMarkerMap(updatedMap);
        await _loadData();
      },
      successMessage: localizations.translate('info_updated'),
      errorPrefix: localizations.translate('error_saving'),
    );
  }

  // 🚀 ИНТЕГРАЦИЯ: Создание карты теперь переходит на ModernMarkerMapScreen
  Future<void> _createMap(MarkerMapModel newMap) async {
    final localizations = AppLocalizations.of(context);

    await _performAsyncOperation(
          () async {
        final mapId = await _markerMapRepository.addMarkerMap(newMap);

        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          if (kDebugMode) {
            debugPrint('✅ SubscriptionProvider обновлен после создания маркерной карты');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
          }
        }

        if (mounted) {
          final map = newMap.copyWith(id: mapId);

          // 🚀 НОВОЕ: Переходим на ModernMarkerMapScreen вместо старого
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernMarkerMapScreen(markerMap: map),
            ),
          ).then((_) => _loadData());
        }
      },
      errorPrefix: localizations.translate('error_saving'),
    );
  }

  Future<void> _confirmDeleteMap(MarkerMapModel map) async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final localizations = AppLocalizations.of(context);

      await _performAsyncOperation(
            () async {
          await _markerMapRepository.deleteMarkerMap(map.id);

          try {
            final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
            await subscriptionProvider.refreshUsageData();
            if (kDebugMode) {
              debugPrint('✅ SubscriptionProvider обновлен после удаления маркерной карты');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
            }
          }

          await _loadData();
        },
        successMessage: localizations.translate('map_deleted_successfully'),
        errorPrefix: localizations.translate('error_deleting_map'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      // 🚀 ИСПРАВЛЕНО: Добавляем extendBody: false для предотвращения перекрытия
      extendBody: false,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                localizations.translate('marker_maps'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isSmallScreen ? 20 : (isTablet ? 26 : 24),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            UsageBadge(
              contentType: ContentType.markerMaps,
              fontSize: isSmallScreen ? 10 : 12,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 2 : 4,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isTablet ? kToolbarHeight + 8 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: isSmallScreen ? 24 : 28,
          ),
          onPressed: () => Navigator.pop(context),
          constraints: BoxConstraints(
            minWidth: ResponsiveConstants.minTouchTarget,
            minHeight: ResponsiveConstants.minTouchTarget,
          ),
        ),
        // 🆕 НОВОЕ: Кнопка фильтра с иконкой filter_list
        actions: [
          if (_allMaps.isNotEmpty) ...[
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: AppConstants.textColor,
                    size: isSmallScreen ? 24 : 28,
                  ),
                  if (_selectedWaterBody != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _openFilterScreen,
              tooltip: localizations.translate('filter'),
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: Column(
          children: [
            // 🆕 НОВОЕ: Индикатор выбранного водоема
            if (_selectedWaterBody != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppConstants.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${localizations.translate('water_body')}: $_selectedWaterBody',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWaterBody = null;
                          });
                          _applyFilter();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: AppConstants.textColor.withOpacity(0.6),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Основной контент
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorState()
                  : _allMaps.isEmpty
                  ? _buildEmptyState()
                  : _filteredMaps.isEmpty
                  ? _buildNoResultsState()
                  : _buildMapsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateMapPress,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        elevation: 6,
        heroTag: "create_map_fab_main",
        child: Icon(
          Icons.add_location_alt,
          size: isSmallScreen ? 24 : 28,
        ),
        tooltip: localizations.translate('create_marker_map'),
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? 40 : 48,
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            SizedBox(
              height: ResponsiveConstants.minTouchTarget,
              child: ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                ),
                child: Text(
                  localizations.translate('try_again'),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 24 : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: AppConstants.textColor.withOpacity(0.5),
              size: isSmallScreen ? 60 : (isTablet ? 100 : 80),
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            Text(
              localizations.translate('no_marker_maps'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 18 : (isTablet ? 26 : 22),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              localizations.translate('start_mapping'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveConstants.spacingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleCreateMapPress,
                icon: const Icon(Icons.add),
                label: Text(
                  localizations.translate('create_marker_map'),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 НОВОЕ: Состояние "нет результатов для выбранного водоема"
  Widget _buildNoResultsState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppConstants.textColor.withOpacity(0.5),
              size: isSmallScreen ? 48 : 64,
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            Text(
              localizations.translate('no_maps_for_water_body'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              '${localizations.translate('selected_water_body')}: $_selectedWaterBody',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.spacingXL),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedWaterBody = null;
                });
                _applyFilter();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
              ),
              child: Text(localizations.translate('show_all_maps')),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 ИСПРАВЛЕНО: Добавлен правильный отступ снизу для списка карт
  Widget _buildMapsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        // 🚀 ИСПРАВЛЕНО: Комплексный отступ снизу
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // Отступ снизу = системная панель навигации + высота FAB + дополнительный отступ
          bottom: MediaQuery.of(context).viewPadding.bottom + // Системная панель
              56 + // Высота FloatingActionButton
              16 + // Дополнительный отступ
              16,  // Базовый отступ
        ),
        itemCount: _filteredMaps.length,
        itemBuilder: (context, index) {
          final map = _filteredMaps[index];
          return _buildMapCard(map);
        },
      ),
    );
  }

  // 🚀 ИНТЕГРАЦИЯ: Открытие существующих карт теперь через ModernMarkerMapScreen
  Widget _buildMapCard(MarkerMapModel map) {
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppConstants.cardColor,
      child: InkWell(
        onTap: () {
          // 🚀 НОВОЕ: Переходим на ModernMarkerMapScreen для всех карт
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernMarkerMapScreen(markerMap: map),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                          Icons.map,
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
                              map.name,
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy').format(map.date),
                              style: TextStyle(
                                color: AppConstants.textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${map.markers.length} ${_getMarkersText(map.markers.length, localizations)}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (map.sector != null && map.sector!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_on,
                            color: AppConstants.textColor.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${localizations.translate('sector')}: ${map.sector}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: () => _showMapSettingsMenu(map),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMarkersText(int count, AppLocalizations localizations) {
    if (localizations.locale.languageCode == 'en') {
      return count == 1
          ? localizations.translate('marker')
          : localizations.translate('markers');
    }

    if (count % 10 == 1 && count % 100 != 11) {
      return localizations.translate('marker');
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return localizations.translate('markers_2_4');
    } else {
      return localizations.translate('markers');
    }
  }
}