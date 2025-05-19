// Путь: lib/screens/settings/storage_cleanup_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../services/offline/offline_storage_service.dart';
import '../../widgets/loading_overlay.dart';

class StorageCleanupScreen extends StatefulWidget {
  const StorageCleanupScreen({Key? key}) : super(key: key);

  @override
  _StorageCleanupScreenState createState() => _StorageCleanupScreenState();
}

class _StorageCleanupScreenState extends State<StorageCleanupScreen> {
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  List<Map<String, dynamic>> _offlineNotes = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _noteIdController = TextEditingController();

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
      setState(() {
        _errorMessage = 'Ошибка при загрузке данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNoteById(String noteId) async {
    if (noteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите ID заметки')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _offlineStorage.clearCorruptedNote(noteId);

      setState(() => _isLoading = false);

      if (result) {
        // Перезагружаем список заметок
        await _loadOfflineNotes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заметка $noteId успешно удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заметка $noteId не найдена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Очистка хранилища',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Загрузка...',
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
                      const Text(
                        'Удаление проблемной заметки',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteIdController,
                        decoration: InputDecoration(
                          labelText: 'ID заметки',
                          hintText: 'Введите ID заметки для удаления',
                          filled: true,
                          fillColor: const Color(0xFF12332E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Удалить заметку'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                'Заметки в локальном хранилище (${_offlineNotes.length}):',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Нет заметок в локальном хранилище',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _offlineNotes.length,
                  itemBuilder: (context, index) {
                    final note = _offlineNotes[index];
                    final noteId = note['id'] ?? 'Нет ID';
                    String title = note['title'] ?? note['location'] ?? 'Без названия';

                    // Пытаемся получить дату заметки
                    String date = 'Нет даты';
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
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'ID: $noteId\nДата: $date',
                          style: const TextStyle(color: Colors.white70),
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
                  label: const Text('Обновить список'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
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