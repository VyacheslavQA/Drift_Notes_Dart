// Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../repositories/marker_map_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';
import 'photo_gallery_screen.dart';
import 'bite_records_section.dart';
import 'cover_photo_selection_screen.dart';
import 'edit_fishing_note_screen.dart';
import '../marker_maps/marker_map_screen.dart';
import '../../widgets/fishing_photo_grid.dart';
import '../../widgets/universal_image.dart';

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
  final _markerMapRepository = MarkerMapRepository();

  FishingNoteModel? _note;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Список маркерных карт, привязанных к этой заметке
  List<MarkerMapModel> _linkedMarkerMaps = [];
  bool _isLoadingMarkerMaps = false;

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

      // После загрузки заметки загружаем связанные маркерные карты
      _loadLinkedMarkerMaps();
    } catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context).translate('error_loading')}: $e';
        _isLoading = false;
      });
    }
  }

  // Метод для загрузки связанных маркерных карт
  Future<void> _loadLinkedMarkerMaps() async {
    if (_note == null) return;

    setState(() {
      _isLoadingMarkerMaps = true;
    });

    try {
      // Получаем все маркерные карты пользователя
      final allMaps = await _markerMapRepository.getUserMarkerMaps();

      // Фильтруем только те, которые привязаны к текущей заметке
      final linkedMaps = allMaps.where((map) => map.noteId == _note!.id).toList();

      setState(() {
        _linkedMarkerMaps = linkedMaps;
        _isLoadingMarkerMaps = false;
      });
    } catch (e) {
      print('${AppLocalizations.of(context).translate('error_loading')}: $e');
      setState(() {
        _isLoadingMarkerMaps = false;
      });
    }
  }

  // Обработчики для работы с записями о поклёвках
  Future<void> _addBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и добавляем новую запись
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
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('bite_record_saved')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('error_adding_bite')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и обновляем запись
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
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('bite_record_updated')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('bite_not_found')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('error_updating_bite')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBiteRecord(String recordId) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и удаляем запись
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
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('bite_record_deleted')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('error_deleting_bite')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Метод для перехода к просмотру маркерной карты
  void _viewMarkerMap(MarkerMapModel map) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerMapScreen(markerMap: map),
      ),
    ).then((_) {
      // Обновляем список маркерных карт после возвращения
      _loadLinkedMarkerMaps();
    });
  }

  // Метод для перехода к редактированию заметки
  Future<void> _editNote() async {
    if (_note == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFishingNoteScreen(note: _note!),
      ),
    );

    if (result == true) {
      // Перезагружаем заметку, чтобы отобразить изменения
      _loadNote();
    }
  }

  // Выбор обложки
  Future<void> _selectCoverPhoto() async {
    if (_note == null || _note!.photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('first_add_photos')),
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
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('cover_updated_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_updating_cover')}: $e'),
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
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_note'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('delete_note_confirmation'),
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

        await _fishingNoteRepository.deleteFishingNote(widget.noteId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('note_deleted_successfully')),
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
              content: Text('${AppLocalizations.of(context).translate('error_deleting_note')}: $e'),
              backgroundColor: Colors.red,
            ),
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
          _note?.title?.isNotEmpty == true
              ? _note!.title
              : _note?.location ?? localizations.translate('fishing_details'),
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
            // Кнопка редактирования
            IconButton(
              icon: Icon(Icons.edit, color: AppConstants.textColor),
              tooltip: localizations.translate('edit'),
              onPressed: _editNote,
            ),
            // Кнопка для выбора обложки
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: localizations.translate('select_cover'),
              onPressed: _selectCoverPhoto,
            ),
            // Кнопка удаления
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: localizations.translate('delete_note'),
              onPressed: _deleteNote,
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        message: _isLoading ? localizations.translate('loading') : localizations.translate('saving'),
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
                child: Text(localizations.translate('try_again')),
              ),
            ],
          ),
        )
            : _note == null
            ? Center(
          child: Text(
            localizations.translate('bite_not_found'),
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

  // Метод для построения изображения обложки с учётом настроек кадрирования
  Widget _buildCoverImage(String photoUrl, Map<String, dynamic>? cropSettings) {
    // Если нет настроек кадрирования, просто показываем изображение
    if (cropSettings == null) {
      return UniversalImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
            strokeWidth: 2.0,
          ),
        ),
        errorWidget: Container(
          color: AppConstants.backgroundColor.withOpacity(0.7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[400],
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('image_unavailable'),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Если есть настройки кадрирования, применяем их
    final offsetX = cropSettings['offsetX'] as double? ?? 0.0;
    final offsetY = cropSettings['offsetY'] as double? ?? 0.0;
    final scale = cropSettings['scale'] as double? ?? 1.0;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: UniversalImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                strokeWidth: 2.0,
              ),
            ),
            errorWidget: Container(
              color: AppConstants.backgroundColor.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).translate('image_unavailable'),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteDetails() {
    if (_note == null) return const SizedBox();

    final localizations = AppLocalizations.of(context);

    // Подсчет пойманных рыб и нереализованных поклевок
    final caughtFishCount = _note!.biteRecords
        .where((record) => record.fishType.isNotEmpty && record.weight > 0)
        .length;
    final missedBitesCount = _note!.biteRecords.length - caughtFishCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фотогалерея
          if (_note!.photoUrls.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(localizations.translate('photos')),
                    TextButton.icon(
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: Text(localizations.translate('view')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                      onPressed: () => _viewPhotoGallery(0),
                    ),
                  ],
                ),
                FishingPhotoGrid(
                  photoUrls: _note!.photoUrls,
                  onViewAllPressed: () => _viewPhotoGallery(0),
                ),
              ],
            ),

          // Общая информация
          _buildInfoCard(
              caughtFishCount: caughtFishCount,
              missedBitesCount: missedBitesCount
          ),

          const SizedBox(height: 20),

          // Если есть погода, показываем её
          if (_note!.weather != null) ...[
            _buildWeatherCard(),
            const SizedBox(height: 20),
          ],

          // Маркерные карты
          if (_linkedMarkerMaps.isNotEmpty || _isLoadingMarkerMaps) ...[
            _buildMarkerMapsSection(),
            const SizedBox(height: 20),
          ],

          // Снасти
          if (_note!.tackle.isNotEmpty) ...[
            _buildSectionHeader(localizations.translate('tackle')),
            _buildContentCard(_note!.tackle),
            const SizedBox(height: 20),
          ],

          // Заметки
          if (_note!.notes.isNotEmpty) ...[
            _buildSectionHeader(localizations.translate('notes')),
            _buildContentCard(_note!.notes),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),

          // Поклевки
          BiteRecordsSection(
            note: _note!,
            onAddRecord: _addBiteRecord,
            onUpdateRecord: _updateBiteRecord,
            onDeleteRecord: _deleteBiteRecord,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Секция маркерных карт
  Widget _buildMarkerMapsSection() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('marker_maps')),

        if (_isLoadingMarkerMaps)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
              ),
            ),
          )
        else
          Column(
            children: _linkedMarkerMaps.map((map) => _buildMarkerMapCard(map)).toList(),
          ),
      ],
    );
  }

  // Карточка для маркерной карты
  Widget _buildMarkerMapCard(MarkerMapModel map) {
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewMarkerMap(map),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      '${map.markers.length} ${_getMarkerText(map.markers.length)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Сектор (если есть)
              if (map.sector != null && map.sector!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Метод для правильного склонения слова "маркер"
  String _getMarkerText(int count) {
    final localizations = AppLocalizations.of(context);

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
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(localizations.translate('photos')),
            TextButton.icon(
              icon: const Icon(Icons.fullscreen, size: 18),
              label: Text(localizations.translate('view')),
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
                '${AppLocalizations.of(context).translate('photo_gallery')} (${_note!.photoUrls.length})',
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

  Widget _buildInfoCard({required int caughtFishCount, required int missedBitesCount}) {
    final localizations = AppLocalizations.of(context);

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
                  '${localizations.translate('fishing_type')}:',
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
                  '${localizations.translate('location')}:',
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
                  '${localizations.translate('dates')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.isMultiDay
                        ? DateFormatter.formatDateRange(_note!.date, _note!.endDate!, context)
                        : DateFormatter.formatDate(_note!.date, context),
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

            /// Пойманные рыбы
            Row(
              children: [
                Icon(
                  Icons.set_meal,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('caught')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$caughtFishCount ${DateFormatter.getFishText(caughtFishCount, context)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Нереализованные поклевки
            Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('not_realized')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$missedBitesCount ${_getBiteText(missedBitesCount)}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Общий вес улова
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.scale,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('total_catch_weight')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_note!.totalFishWeight.toStringAsFixed(1)} ${localizations.translate('kg')}',
                    style: TextStyle(
                      color: Colors.green,
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
                    '${localizations.translate('biggest_fish_caught')}:',
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
                          '${localizations.translate('weight')}: ${biggestFish.weight} ${localizations.translate('kg')}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 15,
                          ),
                        ),
                        if (biggestFish.length > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${localizations.translate('length')}: ${biggestFish.length} см',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${localizations.translate('bite_time')}: ${DateFormat('dd.MM.yyyy HH:mm').format(biggestFish.time)}',
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
                    '${localizations.translate('coordinates')}:',
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

  // Метод для правильного склонения слова "поклевка"
  String _getBiteText(int count) {
    final localizations = AppLocalizations.of(context);

    if (localizations.locale.languageCode == 'en') {
      return count == 1 ? 'bite' : 'bites';
    }

    // Русская логика склонений
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поклевка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'поклевки';
    } else {
      return 'поклевок';
    }
  }

  Widget _buildWeatherCard() {
    final localizations = AppLocalizations.of(context);
    final weather = _note!.weather;
    if (weather == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('weather')),
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
                            '${localizations.translate('clear')} ${weather.feelsLike.toStringAsFixed(1)}°C',
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
                      label: localizations.translate('wind'),
                      value: '${weather.windDirection}, ${weather.windSpeed} м/с',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.water_drop,
                      label: localizations.translate('humidity'),
                      value: '${weather.humidity}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.speed,
                      label: localizations.translate('pressure'),
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
                      label: localizations.translate('cloudiness'),
                      value: '${weather.cloudCover}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.wb_twilight,
                      label: localizations.translate('sunrise'),
                      value: weather.sunrise,
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.nights_stay,
                      label: localizations.translate('sunset'),
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