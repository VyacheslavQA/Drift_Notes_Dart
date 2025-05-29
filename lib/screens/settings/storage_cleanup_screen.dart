// Путь: lib/screens/settings/storage_cleanup_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';

class StorageCleanupScreen extends StatefulWidget {
  const StorageCleanupScreen({super.key});

  @override
  StorageCleanupScreenState createState() => StorageCleanupScreenState();
}

class StorageCleanupScreenState extends State<StorageCleanupScreen> {
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  List<Map<String, dynamic>> _offlineNotes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _noteIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOfflineNotes();
  }

  @override
  void dispose() {
    _noteIdController.dispose();
    super.dispose();
  }

  Future<void> _loadOfflineNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allNotes = await _offlineStorage.getAllOfflineNotes();
      setState(() {
        _offlineNotes = allNotes;
        _isLoading = false;
      });
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _errorMessage = '${localizations.translate('error_loading')}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNoteById(String noteId) async {
    final localizations = AppLocalizations.of(context);

    if (noteId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('enter_note_id'))),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _offlineStorage.clearCorruptedNote(noteId);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result) {
          // Перезагружаем список заметок
          await _loadOfflineNotes();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('note_deleted_by_id')}: $noteId'),
              backgroundColor: Colors.green,
            ),
          );

          // Очищаем поле ввода
          _noteIdController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('note_not_found_by_id')}: $noteId'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_deleting_note_by_id')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          localizations.translate('storage_cleanup_screen'),
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
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('delete_problematic_note'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteIdController,
                        style: TextStyle(color: AppConstants.textColor),
                        decoration: InputDecoration(
                          labelText: localizations.translate('note_id'),
                          labelStyle: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                          ),
                          hintText: localizations.translate('enter_note_id_to_delete'),
                          hintStyle: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF12332E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: Text(localizations.translate('delete_note_by_id')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _deleteNoteById(_noteIdController.text.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '${localizations.translate('notes_in_local_storage')} (${_offlineNotes.length}):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),

              const SizedBox(height: 12),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_offlineNotes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    localizations.translate('no_notes_in_local_storage'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _offlineNotes.length,
                  itemBuilder: (context, index) {
                    final note = _offlineNotes[index];
                    final noteId = note['id'] ?? localizations.translate('no_id');
                    String title = note['title'] ?? note['location'] ?? localizations.translate('no_title');

                    // Пытаемся получить дату заметки
                    String date = localizations.translate('no_date');
                    try {
                      if (note['date'] != null) {
                        final timestamp = note['date'] is int
                            ? note['date']
                            : int.tryParse(note['date'].toString()) ?? 0;
                        if (timestamp > 0) {
                          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                          date = DateFormat('dd.MM.yyyy').format(dateTime);
                        }
                      }
                    } catch (e) {
                      // Игнорируем ошибки при попытке получить дату
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: const Color(0xFF12332E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          title,
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                        subtitle: Text(
                          'ID: $noteId\n${localizations.translate('date')}: $date',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNoteById(noteId.toString()),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.translate('refresh_list')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loadOfflineNotes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}