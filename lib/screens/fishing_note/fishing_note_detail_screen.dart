// Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_overlay.dart';
import 'photo_gallery_screen.dart';
import 'bite_records_section.dart';
import 'bite_charts_section.dart';
import 'cover_photo_selection_screen.dart';

class FishingNoteDetailScreen extends StatefulWidget {
  final String noteId;

  const FishingNoteDetailScreen({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  _FishingNoteDetailScreenState createState() => _FishingNoteDetailScreenState();
}

class _FishingNoteDetailScreenState extends State<FishingNoteDetailScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  FishingNoteModel? _note;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = await _fishingNoteRepository.getFishingNoteById(widget.noteId);

      setState(() {
        _note = note;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки заметки: $e';
        _isLoading = false;
      });
    }
  }

  // Обработчики для работы с записями о поклёвках
  Future<void> _addBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Добавляем новую запись в список
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords)..add(record);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(
        biteRecords: updatedBiteRecords,
      );

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      setState(() {
        _note = updatedNote;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись о поклёвке успешно добавлена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при добавлении записи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Обновляем запись в списке
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords);
      final index = updatedBiteRecords.indexWhere((r) => r.id == record.id);

      if (index != -1) {
        updatedBiteRecords[index] = record;

        // Создаем обновленную модель заметки
        final updatedNote = _note!.copyWith(
          biteRecords: updatedBiteRecords,
        );

        // Сохраняем в репозитории
        await _fishingNoteRepository.updateFishingNote(updatedNote);

        // Обновляем локальное состояние
        setState(() {
          _note = updatedNote;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись о поклёвке успешно обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении записи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBiteRecord(String recordId) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Удаляем запись из списка
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords)
        ..removeWhere((r) => r.id == recordId);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(
        biteRecords: updatedBiteRecords,
      );

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      setState(() {
        _note = updatedNote;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись о поклёвке успешно удалена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении записи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Обработчики для работы с графиками клёва
  Future<void> _addBiteChart(Map<String, dynamic> chart) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Добавляем новый график в список
      final updatedBiteCharts = List<Map<String, dynamic>>.from(_note!.biteCharts)..add(chart);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(
        biteCharts: updatedBiteCharts,
      );

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      setState(() {
        _note = updatedNote;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('График клёва успешно добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при добавлении графика: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBiteChart(Map<String, dynamic> chart) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Обновляем график в списке
      final updatedBiteCharts = List<Map<String, dynamic>>.from(_note!.biteCharts);
      final index = updatedBiteCharts.indexWhere((c) => c['id'] == chart['id']);

      if (index != -1) {
        updatedBiteCharts[index] = chart;

        // Создаем обновленную модель заметки
        final updatedNote = _note!.copyWith(
          biteCharts: updatedBiteCharts,
        );

        // Сохраняем в репозитории
        await _fishingNoteRepository.updateFishingNote(updatedNote);

        // Обновляем локальное состояние
        setState(() {
          _note = updatedNote;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('График клёва успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении графика: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBiteChart(String chartId) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Удаляем график из списка
      final updatedBiteCharts = List<Map<String, dynamic>>.from(_note!.biteCharts)
        ..removeWhere((c) => c['id'] == chartId);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(
        biteCharts: updatedBiteCharts,
      );

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      setState(() {
        _note = updatedNote;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('График клёва успешно удален'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении графика: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Выбор обложки
  Future<void> _selectCoverPhoto() async {
    if (_note == null || _note!.photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала добавьте фотографии к заметке'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoverPhotoSelectionScreen(
          photoUrls: _note!.photoUrls,
          currentCoverPhotoUrl: _note!.coverPhotoUrl.isNotEmpty
              ? _note!.coverPhotoUrl
              : null,
          currentCropSettings: _note!.coverCropSettings,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() => _isSaving = true);

      try {
        // Создаем обновленную модель заметки с новой обложкой
        final updatedNote = _note!.copyWith(
          coverPhotoUrl: result['coverPhotoUrl'],
          coverCropSettings: result['cropSettings'],
        );

        // Сохраняем в репозитории
        await _fishingNoteRepository.updateFishingNote(updatedNote);

        // Обновляем локальное состояние
        setState(() {
          _note = updatedNote;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Обложка успешно обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении обложки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewPhotoGallery(int initialIndex) {
    if (_note == null || _note!.photoUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: _note!.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Удаление заметки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить эту заметку? Это действие нельзя отменить.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
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
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        await _fishingNoteRepository.deleteFishingNote(widget.noteId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заметка успешно удалена'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true); // true для обновления списка заметок
        }
      } catch (e) {
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении заметки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _note?.title?.isNotEmpty == true
              ? _note!.title
              : _note?.location ?? 'Детали рыбалки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _note != null) ...[
            // Кнопка для выбора обложки
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Выбрать обложку',
              onPressed: _selectCoverPhoto,
            ),
            // Кнопка удаления
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить заметку',
              onPressed: _deleteNote,
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        message: _isLoading ? 'Загрузка...' : 'Сохранение...',
        child: _errorMessage != null
            ? Center(
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
                onPressed: _loadNote,
                child: const Text('Повторить'),
              ),
            ],
          ),
        )
            : _note == null
            ? Center(
          child: Text(
            'Заметка не найдена',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
            ),
          ),
        )
            : _buildNoteDetails(),
      ),
    );
  }

  Widget _buildNoteDetails() {
    if (_note == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фотогалерея
          if (_note!.photoUrls.isNotEmpty)
            _buildPhotoGallery(),

          const SizedBox(height: 20),

          // Общая информация
          _buildInfoCard(),

          const SizedBox(height: 20),

          // Если есть погода, показываем её
          if (_note!.weather != null) ...[
            _buildWeatherCard(),
            const SizedBox(height: 20),
          ],

          // Снасти
          if (_note!.tackle.isNotEmpty) ...[
            _buildSectionHeader('Снасти'),
            _buildContentCard(_note!.tackle),
            const SizedBox(height: 20),
          ],

          // Заметки
          if (_note!.notes.isNotEmpty) ...[
            _buildSectionHeader('Заметки'),
            _buildContentCard(_note!.notes),
            const SizedBox(height: 20),
          ],

          // Графики клёва
          BiteChartsSection(
            note: _note!,
            onAddChart: _addBiteChart,
            onUpdateChart: _updateBiteChart,
            onDeleteChart: _deleteBiteChart,
          ),

          const SizedBox(height: 20),

          // Поклевки
          BiteRecordsSection(
            note: _note!,
            onAddRecord: _addBiteRecord,
            onUpdateRecord: _updateBiteRecord,
            onDeleteRecord: _deleteBiteRecord,
          ),

          const SizedBox(height: 20),

          // Если это карповая рыбалка, показываем кнопку "Маркерная карта"
          if (_note!.fishingType == 'Карповая рыбалка') ...[
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Маркерная карта'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция маркерной карты будет доступна в ближайшее время'),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart (продолжение)

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Фотографии'),
            TextButton.icon(
              icon: const Icon(Icons.fullscreen, size: 18),
              label: const Text('Просмотр'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
              ),
              onPressed: () => _viewPhotoGallery(0),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: _note!.photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewPhotoGallery(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: _note!.photoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Индикатор количества фотографий
        if (_note!.photoUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Свайпните для просмотра всех фото (${_note!.photoUrls.length})',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    // Получение самой крупной рыбы
    final biggestFish = _note!.biggestFish;

    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип рыбалки
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Тип рыбалки:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.fishingType,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Место
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Место:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Даты
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Даты:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.isMultiDay
                        ? DateFormatter.formatDateRange(_note!.date, _note!.endDate!)
                        : DateFormatter.formatDate(_note!.date),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Количество рыб
            Row(
              children: [
                Icon(
                  Icons.set_meal,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Поклёвок:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_note!.biteRecords.length} ${DateFormatter.getFishText(_note!.biteRecords.length)}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Самая крупная рыба, если есть
            if (biggestFish != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Самая крупная рыба:',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (biggestFish.fishType.isNotEmpty)
                      Text(
                        biggestFish.fishType,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          'Вес: ${biggestFish.weight} кг',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 15,
                          ),
                        ),
                        if (biggestFish.length > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Длина: ${biggestFish.length} см',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Время: ${DateFormat('dd.MM.yyyy HH:mm').format(biggestFish.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Если есть координаты
            if (_note!.latitude != 0 && _note!.longitude != 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.map,
                    color: AppConstants.textColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Координаты:',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_note!.latitude.toStringAsFixed(6)}, ${_note!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildWeatherCard() {
    final weather = _note!.weather;
    if (weather == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Погода'),
        Card(
          color: const Color(0xFF12332E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                        weather.isDay
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        color: weather.isDay
                            ? Colors.amber
                            : Colors.indigo[300],
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.toStringAsFixed(1)}°C, ${weather.weatherDescription}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ощущается как ${weather.feelsLike.toStringAsFixed(1)}°C',
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherInfoItem(
                      icon: Icons.air,
                      label: 'Ветер',
                      value: '${weather.windDirection}, ${weather.windSpeed} м/с',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.water_drop,
                      label: 'Влажность',
                      value: '${weather.humidity}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.speed,
                      label: 'Давление',
                      value: '${(weather.pressure / 1.333).toInt()} мм',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherInfoItem(
                      icon: Icons.cloud,
                      label: 'Облачность',
                      value: '${weather.cloudCover}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.wb_twilight,
                      label: 'Восход',
                      value: weather.sunrise,
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.nights_stay,
                      label: 'Закат',
                      value: weather.sunset,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(String content) {
    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}