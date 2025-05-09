// Путь: lib/screens/marker_maps/marker_maps_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/navigation.dart';
import 'marker_map_screen.dart';

class MarkerMapsListScreen extends StatefulWidget {
  const MarkerMapsListScreen({Key? key}) : super(key: key);

  @override
  _MarkerMapsListScreenState createState() => _MarkerMapsListScreenState();
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

      setState(() {
        _maps = maps;
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateMapDialog() async {
    final nameController = TextEditingController();
    final sectorController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    FishingNoteModel? selectedNote;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppConstants.surfaceColor,
            title: Text(
              'Создать маркерную карту',
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Название карты
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
                              dialogBackgroundColor: AppConstants.backgroundColor,
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppConstants.textColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
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

                  const SizedBox(height: 16),

                  // Номер сектора (опционально)
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

                  const SizedBox(height: 16),

                  // Привязка к заметке (опционально)
                  if (_notes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привязать к заметке (необязательно):',
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppConstants.backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppConstants.textColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<FishingNoteModel>(
                            isExpanded: true,
                            dropdownColor: AppConstants.surfaceColor,
                            value: selectedNote,
                            hint: Text(
                              'Выберите заметку',
                              style: TextStyle(
                                color: AppConstants.textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppConstants.textColor,
                            ),
                            underline: const SizedBox(),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 14,
                            ),
                            items: [
                              const DropdownMenuItem<FishingNoteModel>(
                                value: null,
                                child: Text('Без привязки'),
                              ),
                              ..._notes.map((note) {
                                final title = note.title.isNotEmpty ? note.title : note.location;
                                return DropdownMenuItem<FishingNoteModel>(
                                  value: note,
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedNote = value;
                              });
                            },
                          ),
                        ),
                      ],
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
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Введите название карты')),
                    );
                    return;
                  }

                  // Создаем новую карту и закрываем диалог
                  final newMap = MarkerMapModel(
                    id: const Uuid().v4(),
                    userId: '',
                    name: nameController.text.trim(),
                    date: selectedDate,
                    sector: sectorController.text.trim().isEmpty
                        ? null
                        : sectorController.text.trim(),
                    noteId: selectedNote?.id,
                    noteName: selectedNote != null
                        ? (selectedNote!.title.isNotEmpty
                        ? selectedNote!.title
                        : selectedNote!.location)
                        : null,
                    markers: [],
                  );

                  Navigator.pop(context, newMap);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: Text(
                  'Создать',
                  style: TextStyle(
                    color: AppConstants.textColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ).then((result) async {
      if (result != null && result is MarkerMapModel) {
        try {
          // Сохраняем новую карту
          final mapId = await _markerMapRepository.addMarkerMap(result);

          // Открываем экран редактирования карты
          if (context.mounted) {
            final map = result.copyWith(id: mapId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkerMapScreen(markerMap: map),
              ),
            ).then((_) => _loadData());
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка создания карты: $e')),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Маркерные карты',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
          : _errorMessage != null
          ? _buildErrorState()
          : _maps.isEmpty
          ? _buildEmptyState()
          : _buildMapsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMapDialog,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState() {
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
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            color: AppConstants.textColor.withOpacity(0.5),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'У вас пока нет маркерных карт',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Нажмите на кнопку "+" внизу, чтобы создать новую карту',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _showCreateMapDialog,
            icon: const Icon(Icons.add),
            label: const Text('Создать маркерную карту'),
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
                      '${map.markers.length} маркеров',
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
                        'Сектор: ${map.sector}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Привязанная заметка (если есть)
              if (map.noteName != null && map.noteName!.isNotEmpty)
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
                        'Заметка: ${map.noteName}',
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
}