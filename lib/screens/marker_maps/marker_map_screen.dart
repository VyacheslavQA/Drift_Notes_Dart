// Путь: lib/screens/marker_maps/marker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/marker_map_repository.dart';
import '../../widgets/loading_overlay.dart';

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

  late MarkerMapModel _markerMap;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasChanges = false;

  // Текущий выбранный маркер для просмотра
  Map<String, dynamic>? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _markerMap = widget.markerMap;
  }

  // Получение названия типа маркера
  String _getMarkerTypeName(String? type) {
    switch (type) {
      case 'dropoff':
        return 'Свал';
      case 'weed':
        return 'Растительность';
      case 'sandbar':
        return 'Песчаная отмель';
      case 'structure':
        return 'Структура';
      default:
        return 'Обычный';
    }
  }

  // Показ диалога с деталями маркера
  void _showMarkerDetails(Map<String, dynamic> marker) {
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
                marker['name'] ?? 'Маркер',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Координаты
              Row(
                children: [
                  Icon(Icons.location_on, color: AppConstants.textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Координаты: ${marker['latitude'].toStringAsFixed(6)}, ${marker['longitude'].toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
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
                      'Глубина: ${marker['depth']} м',
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
              if (marker['description'] != null && marker['description'].isNotEmpty) ...[
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

              // Тип
              if (marker['type'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.category, color: AppConstants.textColor),
                    const SizedBox(width: 8),
                    Text(
                      'Тип: ${_getMarkerTypeName(marker['type'])}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  // Диалог подтверждения удаления маркера
  void _confirmDeleteMarker(Map<String, dynamic> marker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Удалить маркер',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить этот маркер?',
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
                'Отмена',
                style: TextStyle(
                  color: AppConstants.textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteMarker(marker);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Удалить',
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
    setState(() {
      _markerMap.markers.removeWhere((item) => item['id'] == marker['id']);
      _hasChanges = true;
    });
  }

  // Показать меню действий
  void _showActionMenu() {
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
                  'Изменить название карты',
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
                title: const Text(
                  'Удалить карту',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
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
    final nameController = TextEditingController(text: _markerMap.name);
    final sectorController = TextEditingController(text: _markerMap.sector ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Изменить информацию',
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
            ],
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
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название карты')),
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
              },
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: AppConstants.primaryColor,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Удалить карту',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить эту карту? Это действие нельзя отменить.',
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
                'Отмена',
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
              child: const Text(
                'Удалить',
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
    try {
      setState(() {
        _isLoading = true;
      });

      await _markerMapRepository.deleteMarkerMap(_markerMap.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Карта успешно удалена'),
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
            content: Text('Ошибка при удалении карты: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Сохранение изменений карты
  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _markerMapRepository.updateMarkerMap(_markerMap);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изменения сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении изменений: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Переключение режима редактирования
  void _toggleEditingMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Режим редактирования включен'
            : 'Режим просмотра включен'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Кнопка переключения режима
          IconButton(
            icon: Icon(
              _isEditing ? Icons.visibility : Icons.edit,
              color: AppConstants.textColor,
            ),
            tooltip: _isEditing ? 'Режим просмотра' : 'Режим редактирования',
            onPressed: _toggleEditingMode,
          ),
          // Кнопка сохранения (активна только при наличии изменений)
          IconButton(
            icon: Icon(
              Icons.save,
              color: _hasChanges ? AppConstants.textColor : AppConstants.textColor.withOpacity(0.3),
            ),
            tooltip: 'Сохранить изменения',
            onPressed: _hasChanges ? _saveChanges : null,
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
        message: 'Подождите...',
        child: _markerMap.markers.isEmpty
            ? _buildEmptyState()
            : _buildMarkersList(),
      ),
      // Убрана кнопка добавления маркера
      // Отображаем информацию о карте внизу экрана
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Дата: ${DateFormat('dd.MM.yyyy').format(_markerMap.date)}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (_markerMap.sector != null && _markerMap.sector!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.grid_on,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Сектор: ${_markerMap.sector}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (_markerMap.noteName != null && _markerMap.noteName!.isNotEmpty) ...[
              const SizedBox(height: 4),
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
                      'Заметка: ${_markerMap.noteName}',
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
          ],
        ),
      ),
    );
  }

  // Пустое состояние (когда нет маркеров)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            color: AppConstants.textColor.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'На этой карте пока нет маркеров',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Функция добавления маркеров временно недоступна',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Список маркеров
  Widget _buildMarkersList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Список маркеров (${_markerMap.markers.length})',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Отображаем все маркеры в виде списка
        ..._markerMap.markers.map((marker) => _buildMarkerItem(marker)).toList(),
      ],
    );
  }

  // Элемент списка маркеров
  Widget _buildMarkerItem(Map<String, dynamic> marker) {
    Color markerColor;
    switch (marker['type']) {
      case 'dropoff':
        markerColor = Colors.red;
        break;
      case 'weed':
        markerColor = Colors.green;
        break;
      case 'sandbar':
        markerColor = Colors.amber;
        break;
      case 'structure':
        markerColor = Colors.orange;
        break;
      default:
        markerColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: markerColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: markerColor,
            size: 24,
          ),
        ),
        title: Text(
          marker['name'] ?? 'Маркер',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Координаты: ${marker['latitude'].toStringAsFixed(6)}, ${marker['longitude'].toStringAsFixed(6)}',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            if (marker['depth'] != null)
              Text(
                'Глубина: ${marker['depth']} м',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _isEditing
            ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteMarker(marker),
        )
            : null,
        onTap: () => _showMarkerDetails(marker),
      ),
    );
  }
}