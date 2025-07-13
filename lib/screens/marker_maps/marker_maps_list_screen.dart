// Путь: lib/screens/marker_maps/marker_maps_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
// ✅ ДОБАВЛЕНО: Импорты для обновления SubscriptionProvider
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/subscription_constants.dart';
import '../../models/marker_map_model.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../services/subscription/subscription_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/subscription/usage_badge.dart';
import '../subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';
import 'marker_map_screen.dart';

class MarkerMapsListScreen extends StatefulWidget {
  const MarkerMapsListScreen({super.key});

  @override
  State<MarkerMapsListScreen> createState() => _MarkerMapsListScreenState();
}

class _MarkerMapsListScreenState extends State<MarkerMapsListScreen> {
  // ✅ ИСПРАВЛЕНО: Используем Repository вместо прямых Firebase вызовов
  final _markerMapRepository = MarkerMapRepository();
  final _fishingNoteRepository = FishingNoteRepository();
  final _subscriptionService = SubscriptionService();

  List<MarkerMapModel> _maps = [];
  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    debugPrint('🗺️ MarkerMapsListScreen: Инициализация экрана списка карт');
  }

  // ✅ ИСПРАВЛЕНО: Загрузка данных через Repository
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📥 Загружаем маркерные карты через Repository...');

      // Загружаем карты через Repository
      final maps = await _markerMapRepository.getUserMarkerMaps();

      // Загружаем заметки через Repository для диалога создания
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      if (mounted) {
        setState(() {
          _maps = maps;
          _notes = notes;
          _isLoading = false;
        });

        debugPrint('✅ Загружено ${maps.length} маркерных карт и ${notes.length} заметок через Repository');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке данных через Repository: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Проверка лимитов с офлайн поддержкой и PaywallScreen
  Future<void> _handleCreateMapPress() async {
    final localizations = AppLocalizations.of(context);

    try {
      debugPrint('🔍 Проверяем возможность создания маркерной карты...');

      // Проверяем лимиты через Repository
      final canCreate = await _markerMapRepository.canCreateMarkerMap();
      debugPrint('✅ Результат canCreateMarkerMap: $canCreate');

      if (!canCreate) {
        debugPrint('❌ Лимит превышен, показываем PaywallScreen');
        _showPaywallScreen();
        return;
      }

      debugPrint('✅ Лимиты позволяют создать карту, переходим к созданию');
      _showCreateMapDialog();

    } catch (e) {
      debugPrint('❌ Ошибка при проверке лимитов: $e');
      // В случае ошибки показываем PaywallScreen (безопасный подход)
      _showPaywallScreen();
    }
  }

  // ✅ ИСПРАВЛЕНО: Единый метод для показа PaywallScreen
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

  // Показ меню настроек карты
  Future<void> _showMapSettingsMenu(MarkerMapModel map) async {
    final localizations = AppLocalizations.of(context);

    await showModalBottomSheet(
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
            children: [
              // Заголовок
              Text(
                localizations.translate('map_settings'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Редактировать информацию
              ListTile(
                leading: Icon(Icons.edit, color: AppConstants.primaryColor),
                title: Text(
                  localizations.translate('edit_map_info'),
                  style: TextStyle(color: AppConstants.textColor, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMapInfoDialog(map);
                },
              ),

              // Поделиться картой (неактивная)
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: AppConstants.textColor.withOpacity(0.4),
                ),
                title: Text(
                  localizations.translate('share_map'),
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.4),
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.translate('feature_coming_soon'),
                      ),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                },
              ),

              const Divider(color: Colors.grey),

              // Удалить карту
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.translate('delete_map'),
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMap(map);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ✅ ИСПРАВЛЕНО: Диалог редактирования через Repository
  Future<void> _showEditMapInfoDialog(MarkerMapModel map) async {
    final localizations = AppLocalizations.of(context);
    final nameController = TextEditingController(text: map.name);
    final sectorController = TextEditingController(text: map.sector ?? '');

    DateTime selectedDate = map.date;
    List<FishingNoteModel> selectedNotes = [];

    // Предварительно выбираем привязанные заметки
    for (String noteId in map.noteIds) {
      final note = _notes.firstWhere(
            (n) => n.id == noteId,
        orElse: () => FishingNoteModel(
          id: '',
          userId: '',
          location: '',
          fishingType: '',
          date: DateTime.now(),
        ),
      );
      if (note.id.isNotEmpty) {
        selectedNotes.add(note);
      }
    }

    final result = await showDialog<MarkerMapModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: AppConstants.surfaceColor,
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
                            Icons.edit,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.translate('edit_map_information'),
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
                            // Название карты
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                labelText: '${localizations.translate('map_name')}*',
                                labelStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.textColor.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Выбор даты
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppConstants.primaryColor,
                                          onPrimary: AppConstants.textColor,
                                          surface: AppConstants.surfaceColor,
                                          onSurface: AppConstants.textColor,
                                        ),
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: AppConstants.backgroundColor,
                                        ),
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
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppConstants.textColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${localizations.translate('date')}: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppConstants.textColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Номер сектора (опционально)
                            TextField(
                              controller: sectorController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                labelText: '${localizations.translate('sector')} (${localizations.translate('other').toLowerCase()})',
                                labelStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.textColor.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Привязка к заметкам (множественный выбор)
                            if (_notes.isNotEmpty) ...[
                              Text(
                                '${localizations.translate('my_notes')} (${localizations.translate('other').toLowerCase()}):',
                                style: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Показываем список заметок с чекбоксами
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: AppConstants.backgroundColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.textColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: _notes.isEmpty
                                    ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      localizations.translate('no_notes_available'),
                                      style: TextStyle(
                                        color: AppConstants.textColor.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                                    : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _notes.length,
                                  itemBuilder: (context, index) {
                                    final note = _notes[index];
                                    final title = note.title.isNotEmpty ? note.title : note.location;
                                    final isSelected = selectedNotes.contains(note);

                                    return CheckboxListTile(
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        dialogSetState(() {
                                          if (value == true) {
                                            selectedNotes.add(note);
                                          } else {
                                            selectedNotes.remove(note);
                                          }
                                        });
                                      },
                                      activeColor: AppConstants.primaryColor,
                                      checkColor: AppConstants.textColor,
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                              ),

                              if (selectedNotes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${localizations.translate('selected')}: ${selectedNotes.length}',
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
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
                                      localizations.translate('map_name_required'),
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Создаем обновленную карту
                              final updatedMap = map.copyWith(
                                name: nameController.text.trim(),
                                date: selectedDate,
                                sector: sectorController.text.trim().isEmpty
                                    ? null
                                    : sectorController.text.trim(),
                                noteIds: selectedNotes.map((note) => note.id).toList(),
                                noteNames: selectedNotes
                                    .map(
                                      (note) => note.title.isNotEmpty ? note.title : note.location,
                                )
                                    .toList(),
                              );

                              Navigator.pop(context, updatedMap);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                            ),
                            child: Text(
                              localizations.translate('save'),
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
      },
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // ✅ ИСПРАВЛЕНО: Сохраняем через Repository
        await _markerMapRepository.updateMarkerMap(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('info_updated')),
              backgroundColor: Colors.green,
            ),
          );

          // Перезагружаем данные
          _loadData();
        }
      } catch (e) {
        debugPrint('❌ Ошибка при сохранении карты через Repository: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error_saving')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Подтверждение удаления через Repository с обновлением Provider
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
      try {
        setState(() => _isLoading = true);

        // ✅ ИСПРАВЛЕНО: Удаляем через Repository
        await _markerMapRepository.deleteMarkerMap(map.id);

        // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider после удаления
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после удаления маркерной карты');
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('map_deleted_successfully'),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Перезагружаем данные
          _loadData();
        }
      } catch (e) {
        debugPrint('❌ Ошибка при удалении карты через Repository: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations.translate('error_deleting_map')}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Создание карты через Repository с обновлением Provider
  Future<void> _showCreateMapDialog() async {
    final localizations = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final sectorController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    List<FishingNoteModel> selectedNotes = [];

    final result = await showDialog<MarkerMapModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: AppConstants.surfaceColor,
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
                            Icons.map,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.translate('create_marker_map'),
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

                    // Содержимое аналогично edit диалогу
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название карты
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                labelText: '${localizations.translate('map_name')}*',
                                labelStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.textColor.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Выбор даты
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppConstants.primaryColor,
                                          onPrimary: AppConstants.textColor,
                                          surface: AppConstants.surfaceColor,
                                          onSurface: AppConstants.textColor,
                                        ),
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: AppConstants.backgroundColor,
                                        ),
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
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppConstants.textColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${localizations.translate('date')}: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppConstants.textColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Номер сектора (опционально)
                            TextField(
                              controller: sectorController,
                              style: TextStyle(color: AppConstants.textColor),
                              decoration: InputDecoration(
                                labelText: '${localizations.translate('sector')} (${localizations.translate('other').toLowerCase()})',
                                labelStyle: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.textColor.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Привязка к заметкам (аналогично edit диалогу)
                            if (_notes.isNotEmpty) ...[
                              Text(
                                '${localizations.translate('my_notes')} (${localizations.translate('other').toLowerCase()}):',
                                style: TextStyle(
                                  color: AppConstants.textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: AppConstants.backgroundColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.textColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _notes.length,
                                  itemBuilder: (context, index) {
                                    final note = _notes[index];
                                    final title = note.title.isNotEmpty ? note.title : note.location;
                                    final isSelected = selectedNotes.contains(note);

                                    return CheckboxListTile(
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          color: AppConstants.textColor,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        dialogSetState(() {
                                          if (value == true) {
                                            selectedNotes.add(note);
                                          } else {
                                            selectedNotes.remove(note);
                                          }
                                        });
                                      },
                                      activeColor: AppConstants.primaryColor,
                                      checkColor: AppConstants.textColor,
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                              ),

                              if (selectedNotes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${localizations.translate('selected')}: ${selectedNotes.length}',
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
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
                                      localizations.translate('required_field'),
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Создаем новую карту
                              final newMap = MarkerMapModel(
                                id: const Uuid().v4(),
                                userId: '',
                                name: nameController.text.trim(),
                                date: selectedDate,
                                sector: sectorController.text.trim().isEmpty
                                    ? null
                                    : sectorController.text.trim(),
                                noteIds: selectedNotes.map((note) => note.id).toList(),
                                noteNames: selectedNotes
                                    .map(
                                      (note) => note.title.isNotEmpty ? note.title : note.location,
                                )
                                    .toList(),
                                markers: [],
                              );

                              Navigator.pop(context, newMap);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                            ),
                            child: Text(
                              localizations.translate('add'),
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
      },
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // ✅ ИСПРАВЛЕНО: Создаем карту через Repository
        final mapId = await _markerMapRepository.addMarkerMap(result);

        // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider после создания
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после создания маркерной карты');
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
        }

        // Открываем экран редактирования карты
        if (mounted) {
          setState(() => _isLoading = false);
          final map = result.copyWith(id: mapId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkerMapScreen(markerMap: map),
            ),
          ).then((_) => _loadData());
        }
      } catch (e) {
        debugPrint('❌ Ошибка при создании карты через Repository: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          final localizations = AppLocalizations.of(context);

          // Проверяем, не превышен ли лимит
          if (e.toString().contains('лимит') || e.toString().contains('limit')) {
            _showPaywallScreen();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${localizations.translate('error_saving')}: $e'),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
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
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: _errorMessage != null
            ? _buildErrorState()
            : _maps.isEmpty
            ? _buildEmptyState()
            : _buildMapsList(),
      ),
      // ✅ ОСНОВНАЯ КНОПКА: Всегда показывается в правом нижнем углу
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateMapPress,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        elevation: 6,
        heroTag: "create_map_fab_main",
        child: Icon(
          Icons.add_location_alt, // Иконка маркера
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
            // ✅ ДОПОЛНИТЕЛЬНАЯ КНОПКА: Показывается только когда нет карт
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

  Widget _buildMapsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _maps.length,
        itemBuilder: (context, index) {
          final map = _maps[index];
          return _buildMapCard(map);
        },
      ),
    );
  }

  Widget _buildMapCard(MarkerMapModel map) {
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppConstants.cardColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkerMapScreen(markerMap: map),
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
                      // Иконка маркерной карты
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

                      // Название и дата
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

                      // Количество маркеров
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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

                  // Сектор (если есть)
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

                  // Привязанные заметки
                  if (map.noteNames.isNotEmpty)
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
                            '${localizations.translate('notes')}: ${map.attachedNotesText}',
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
              ),
            ),

            // Кнопка настроек в правом нижнем углу
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

    // Русская логика склонений
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