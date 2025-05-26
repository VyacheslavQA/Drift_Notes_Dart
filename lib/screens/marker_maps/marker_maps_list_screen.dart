// Путь: lib/screens/marker_maps/marker_maps_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';
import 'marker_map_screen.dart';

class MarkerMapsListScreen extends StatefulWidget {
  const MarkerMapsListScreen({super.key});

  @override
  State<MarkerMapsListScreen> createState() => _MarkerMapsListScreenState();
}

class _MarkerMapsListScreenState extends State<MarkerMapsListScreen> {
  final _markerMapRepository = MarkerMapRepository();
  final _fishingNoteRepository = FishingNoteRepository();

  List<MarkerMapModel> _maps = [];
  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Загружаем все маркерные карты
      final maps = await _markerMapRepository.getUserMarkerMaps();

      // Загружаем список заметок для диалога создания новой карты
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      if (mounted) {
        setState(() {
          _maps = maps;
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAllMaps() async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('clear_all_data_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('clear_all_data_message'),
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        await _markerMapRepository.clearAllMarkerMaps();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('data_cleared_success')),
              backgroundColor: Colors.green,
            ),
          );

          // Перезагружаем данные
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error_loading')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
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
                                labelStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppConstants.textColor.withValues(alpha: 0.5)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppConstants.primaryColor),
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
                                      color: AppConstants.textColor.withValues(alpha: 0.5),
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
                                labelStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppConstants.textColor.withValues(alpha: 0.5)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppConstants.primaryColor),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Привязка к заметкам (множественный выбор)
                            if (_notes.isNotEmpty) ...[
                              Text(
                                '${localizations.translate('my_notes')} (${localizations.translate('other').toLowerCase()}):',
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Показываем список заметок с чекбоксами
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: AppConstants.backgroundColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.textColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: _notes.isEmpty
                                    ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      localizations.translate('no_notes'),
                                      style: TextStyle(
                                        color: AppConstants.textColor.withValues(alpha: 0.7),
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
                            color: AppConstants.textColor.withValues(alpha: 0.1),
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
                              style: TextStyle(
                                color: AppConstants.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(localizations.translate('required_field'))),
                                );
                                return;
                              }

                              // Создаем новую карту с множественными привязками
                              final newMap = MarkerMapModel(
                                id: const Uuid().v4(),
                                userId: '',
                                name: nameController.text.trim(),
                                date: selectedDate,
                                sector: sectorController.text.trim().isEmpty
                                    ? null
                                    : sectorController.text.trim(),
                                noteIds: selectedNotes.map((note) => note.id).toList(),
                                noteNames: selectedNotes.map((note) =>
                                note.title.isNotEmpty ? note.title : note.location).toList(),
                                markers: [],
                              );

                              Navigator.pop(context, newMap);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                            ),
                            child: Text(
                              localizations.translate('add'),
                              style: TextStyle(
                                color: AppConstants.textColor,
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
      },
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // Сохраняем новую карту
        final mapId = await _markerMapRepository.addMarkerMap(result);

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
        if (mounted) {
          setState(() => _isLoading = false);
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizations.translate('error_saving')}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('marker_maps'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Добавляем кнопку очистки карт
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppConstants.textColor),
            color: AppConstants.cardColor,
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllMaps();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      localizations.translate('clear_all_data'),
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMapDialog,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text(localizations.translate('try_again')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            color: AppConstants.textColor.withValues(alpha: 0.5),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('no_notes'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('start_journal'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _showCreateMapDialog,
            icon: const Icon(Icons.add),
            label: Text(localizations.translate('create_marker_map')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        child: Padding(
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
                      color: AppConstants.primaryColor.withValues(alpha: 0.2),
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
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Количество маркеров
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
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
                        color: AppConstants.textColor.withValues(alpha: 0.7),
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

              // Привязанные заметки (обновлено для множественных привязок)
              if (map.noteNames.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.note,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
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
      ),
    );
  }

  String _getMarkersText(int count, AppLocalizations localizations) {
    if (localizations.locale.languageCode == 'en') {
      return count == 1 ? localizations.translate('marker') : localizations.translate('markers');
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