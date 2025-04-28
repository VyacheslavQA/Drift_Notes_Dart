// Путь: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/firebase/firebase_service.dart';
import '../repositories/fishing_note_repository.dart';
import '../models/fishing_note_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _fishingNoteRepository = FishingNoteRepository();

  bool _isLoading = false;
  List<FishingNoteModel> _fishingNotes = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFishingNotes();
  }

  Future<void> _loadFishingNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      setState(() {
        _fishingNotes = notes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // В зависимости от выбранного индекса, выполняем соответствующие действия
    switch (index) {
      case 0:
      // Основной экран (уже отображен)
        break;
      case 1:
      // Экран погоды
        break;
      case 2:
      // Добавление новой заметки
        _navigateToAddNote();
        break;
      case 3:
      // Экран календаря
        break;
      case 4:
      // Экран уведомлений
        break;
    }
  }

  void _navigateToAddNote() {
    // Навигация на экран добавления заметки
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddFishingNoteScreen()));
  }

  Widget _buildUserStats() {
    return Card(
      color: const Color(0xFF1E2B23),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Моя статистика',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD7CCA1),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Всего рыбалок',
                    value: _fishingNotes.length.toString(),
                    subtitle: _getTripsText(_fishingNotes.length),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Последняя',
                    value: _fishingNotes.isNotEmpty ? _formatDate(_fishingNotes[0].date) : '--',
                    subtitle: _fishingNotes.isNotEmpty ? _fishingNotes[0].location : 'Нет данных',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotes() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fishingNotes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'У вас пока нет заметок о рыбалке. Нажмите + чтобы добавить первую!',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fishingNotes.length.clamp(0, 5), // Показываем максимум 5 последних заметок
      itemBuilder: (context, index) {
        final note = _fishingNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(FishingNoteModel note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E2B23),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Навигация на экран деталей заметки
          // Navigator.push(context, MaterialPageRoute(builder: (context) => FishingNoteDetailScreen(noteId: note.id)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.photoUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  note.photoUrls.first,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: Colors.grey[800],
                      alignment: Alignment.center,
                      child: const Icon(Icons.error, color: Colors.white),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD7CCA1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateRange(note),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.tackle.isNotEmpty ? note.tackle : 'Снасти не указаны',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateRange(FishingNoteModel note) {
    if (note.isMultiDay && note.endDate != null) {
      return '${_formatDate(note.date)} — ${_formatDate(note.endDate!)}';
    }
    return _formatDate(note.date);
  }

  String _getTripsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'рыбалка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'рыбалки';
    } else {
      return 'рыбалок';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DriftNotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Открываем drawer
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFishingNotes,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserStats(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Последние записи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Навигация на экран со всеми заметками
                    },
                    child: const Text('Смотреть все'),
                  ),
                ],
              ),
              _buildRecentNotes(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddNote,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Погода',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 30),
            label: 'Добавить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Уведомления',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF121C15),
        type: BottomNavigationBarType.fixed,
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    final user = _firebaseService.currentUser;
    final userName = user?.displayName ?? 'Пользователь';
    final userEmail = user?.email ?? '';

    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1E2B23),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFFD7CCA1),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Профиль', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Навигация на экран профиля
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white),
              title: const Text('Статистика', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Навигация на экран статистики
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt, color: Colors.white),
              title: const Text('Мои заметки', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Навигация на экран заметок
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Настройки', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Навигация на экран настроек
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.white),
              title: const Text('Помощь', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Навигация на экран помощи
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.white),
              title: const Text('Выйти', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await _firebaseService.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}