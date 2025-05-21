// Путь: lib/screens/fishing_note/fishing_notes_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../utils/navigation.dart';
import '../../widgets/universal_image.dart';
import '../../widgets/loading_overlay.dart';
import 'fishing_type_selection_screen.dart';
import 'fishing_note_detail_screen.dart';

class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({Key? key}) : super(key: key);

  @override
  _FishingNotesListScreenState createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen> with SingleTickerProviderStateMixin {
  final _fishingNoteRepository = FishingNoteRepository();

  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Контроллер анимации для плавного появления элементов
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Настройка анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        )
    );

    _loadNotes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      // Сортируем заметки по дате (сначала новые)
      notes.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _notes = notes;
        _isLoading = false;
      });

      // Запускаем анимацию после загрузки данных
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки заметок: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FishingTypeSelectionScreen()),
    );

    if (result == true) {
      // Сбрасываем анимацию перед обновлением данных
      _animationController.reset();
      _loadNotes();
    }
  }

  void _viewNoteDetails(FishingNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingNoteDetailScreen(noteId: note.id),
      ),
    ).then((value) {
      if (value == true) {
        // Сбрасываем анимацию перед обновлением данных
        _animationController.reset();
        _loadNotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Мои заметки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        // Убрали кнопку настроек из списка действий
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Загрузка...',
        child: RefreshIndicator(
          onRefresh: _loadNotes,
          color: AppConstants.primaryColor,
          backgroundColor: AppConstants.surfaceColor,
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
                  onPressed: _loadNotes,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
              : _notes.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                // Добавляем задержку для каскадной анимации
                Future.delayed(Duration(milliseconds: 50 * index), () {
                  if (mounted) setState(() {});
                });
                return _buildNoteCard(_notes[index]);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        onPressed: _addNewNote,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.textColor.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 50,
            height: 50,
          ),
        ),
        elevation: 4,
        // Добавляем эффект нажатия
        splashColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.set_meal,  // Используем иконку рыбы вместо несуществующей fishing
              color: AppConstants.textColor.withOpacity(0.5),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Ещё нет заметок о рыбалке',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Начните вести дневник ваших рыбалок, чтобы отслеживать самые удачные уловы',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Создать первую заметку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
              ),
              onPressed: _addNewNote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(FishingNoteModel note) {
    // Информация о самой крупной рыбе
    final biggestFish = note.biggestFish;

    // URL фотографии (обложки или первое фото)
    String photoUrl = '';
    if (note.coverPhotoUrl.isNotEmpty) {
      photoUrl = note.coverPhotoUrl;
    } else if (note.photoUrls.isNotEmpty) {
      photoUrl = note.photoUrls.first;
    }

    // Настройки кадрирования для обложки
    final cropSettings = note.coverCropSettings;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: () => _viewNoteDetails(note),
        splashColor: AppConstants.primaryColor.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фотография, если есть
            if (photoUrl.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 170,  // Увеличили размер для лучшего отображения
                    width: double.infinity,
                    child: _buildCoverImage(photoUrl, cropSettings),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,  // Увеличили градиент для лучшего перехода
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Показываем тип рыбалки и дату внизу фотографии
                  Positioned(
                    bottom: 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.textColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            note.fishingType,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.textColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            note.isMultiDay
                                ? DateFormatter.formatDateRange(note.date, note.endDate!)
                                : DateFormatter.formatDate(note.date),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Если фото не было, показываем тип рыбалки и дату в основном блоке
                  if (photoUrl.isEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            note.fishingType,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            note.isMultiDay
                                ? DateFormatter.formatDateRange(note.date, note.endDate!)
                                : DateFormatter.formatDate(note.date),
                            style: TextStyle(
                              color: AppConstants.textColor.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (photoUrl.isEmpty)
                    const SizedBox(height: 12),

                  // Место рыбалки / название
                  Text(
                    note.title.isNotEmpty ? note.title : note.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Количество поклевок и фото
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.set_meal,
                          color: AppConstants.textColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${note.biteRecords.length} ${_getBiteRecordsText(note.biteRecords.length)}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (note.photoUrls.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: AppConstants.textColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${note.photoUrls.length} фото',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Если есть самая крупная рыба, показываем информацию о ней
                  if (biggestFish != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.15),
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
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Самая крупная рыба:',
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (biggestFish.fishType.isNotEmpty) ...[
                                Expanded(
                                  child: Text(
                                    biggestFish.fishType,
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.scale,
                                color: AppConstants.textColor.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${biggestFish.weight} кг',
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (biggestFish.length > 0) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.straighten,
                                  color: AppConstants.textColor.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${biggestFish.length} см',
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Новая функция для получения правильного текста для поклевок
  String _getBiteRecordsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поклевка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'поклевки';
    } else {
      return 'поклевок';
    }
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
                  'Изображение недоступно',
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
                      'Изображение недоступно',
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
}