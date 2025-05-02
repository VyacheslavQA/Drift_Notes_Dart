// Путь: lib/screens/fishing_note/fishing_notes_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../utils/navigation.dart';
import 'fishing_type_selection_screen.dart';
import 'fishing_note_detail_screen.dart';

class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({Key? key}) : super(key: key);

  @override
  _FishingNotesListScreenState createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotes();
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        color: AppConstants.primaryColor,
        backgroundColor: AppConstants.surfaceColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
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
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notes.length,
          itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        onPressed: _addNewNote,
        child: Image.asset(
          'assets/images/app_logo.png',
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            color: AppConstants.textColor.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'У вас пока нет заметок',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите на кнопку добавления, чтобы создать первую заметку о рыбалке',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Создать заметку'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _addNewNote,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(FishingNoteModel note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewNoteDetails(note),
        splashColor: AppConstants.primaryColor.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фотография, если есть
            if (note.photoUrls.isNotEmpty)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: note.photoUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppConstants.backgroundColor,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Тип рыбалки и дата
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
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
                      Text(
                        note.isMultiDay
                            ? DateFormatter.formatDateRange(note.date, note.endDate!)
                            : DateFormatter.formatDate(note.date),
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Место рыбалки
                  Text(
                    note.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Количество поклевок и фотографий
                  Row(
                    children: [
                      Icon(
                        Icons.set_meal,
                        color: AppConstants.textColor.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${note.biteRecords.length} ${DateFormatter.getFishText(note.biteRecords.length)}',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.photo,
                        color: AppConstants.textColor.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${note.photoUrls.length} фото',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Если есть заметки, показываем начало
                  if (note.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      note.notes.length > 100
                          ? '${note.notes.substring(0, 100)}...'
                          : note.notes,
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}