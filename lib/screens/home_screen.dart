// Путь: lib/screens/home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/firebase_service.dart';
import '../repositories/fishing_note_repository.dart';
import '../models/fishing_note_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_formatter.dart';
import '../utils/navigation.dart';
import 'timer/timers_screen.dart';
import 'fishing_note/fishing_type_selection_screen.dart';
import 'fishing_note/fishing_notes_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _fishingNoteRepository = FishingNoteRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  List<FishingNoteModel> _fishingNotes = [];

  int _selectedIndex = 2; // Центральная кнопка (рыбка) по умолчанию выбрана

  // URL YouTube канала для перехода
  final String _youtubeChannelUrl = 'https://www.youtube.com/channel/UCarpeDiem';

  @override
  void initState() {
    super.initState();
    _loadFishingNotes();

    // Синхронизируем офлайн заметки при запуске
    _fishingNoteRepository.syncOfflineDataOnStartup();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Метод для открытия URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при открытии ссылки: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Обработка нажатия на элементы меню
    switch (index) {
      case 0: // Таймер
      // Навигация на экран таймеров
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimersScreen()),
        );
        break;
      case 1: // Погода
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экран погоды в разработке')),
        );
        break;
      case 2: // Центральная кнопка - создание заметки
        _navigateToAddNote();
        break;
      case 3: // Календарь
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экран календаря в разработке')),
        );
        break;
      case 4: // Уведомления
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экран уведомлений в разработке')),
        );
        break;
    }
  }

  void _navigateToAddNote() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FishingTypeSelectionScreen())
    ).then((value) {
      if (value == true) {
        _loadFishingNotes(); // Обновить список заметок, если была создана новая
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Drift Notes',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppConstants.textColor),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadFishingNotes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Блок с рекламой канала YouTube
                _buildYoutubePromoCard(),

                const SizedBox(height: 24),

                // Заголовок "Моя статистика"
                Text(
                  'Моя статистика',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Статистика
                _buildStatsGrid(),

                const SizedBox(height: 24),

                // Недавние заметки (если есть)
                if (_fishingNotes.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Недавние заметки',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FishingNotesListScreen()),
                          );
                        },
                        child: Text(
                          'Все заметки',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Список недавних заметок (максимум 3)
                  _buildRecentNotesList(),
                ],

                const SizedBox(height: 100),
                // Большой отступ внизу для плавающей кнопки
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      // Позволяет контенту скроллиться под нижней панелью
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Виджет для отображения рекламы канала YouTube с возможностью перехода по ссылке
  Widget _buildYoutubePromoCard() {
    return GestureDetector(
      onTap: () =>
          _launchUrl('https://www.youtube.com/@Carpediem_hunting_fishing'),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/fishing_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Затемнение для лучшей читаемости текста
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Текст "Посетите наш YouTube канал"
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Посетите наш YouTube канал',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Сетка со статистикой
  Widget _buildStatsGrid() {
    // Подсчет значений статистики на основе заметок
    int totalTrips = _fishingNotes.length;
    double biggestFish = 0.0;
    DateTime? biggestFishDate;
    int totalFish = 0;
    int longestTripDays = 0;

    for (var note in _fishingNotes) {
      // Общее количество рыб
      totalFish += note.biteRecords.length;

      // Самая большая рыба
      for (var record in note.biteRecords) {
        if (record.weight > biggestFish) {
          biggestFish = record.weight;
          biggestFishDate = note.date;
        }
      }

      // Самая долгая рыбалка
      if (note.isMultiDay && note.endDate != null) {
        int days = note.endDate!.difference(note.date).inDays + 1;
        if (days > longestTripDays) {
          longestTripDays = days;
        }
      }
    }

    // Если нет данных, устанавливаем значения по умолчанию
    bool hasData = _fishingNotes.isNotEmpty;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Всего рыбалок
        _buildStatCard(
          title: 'Всего рыбалок',
          value: hasData ? totalTrips.toString() : '0',
          subtitle: DateFormatter.getFishingTripsText(hasData ? totalTrips : 0),
          icon: Icons.format_list_bulleted,
          chartData: hasData ? const [0.2, 0.4, 0.3, 0.5, 0.7, 0.2] : null,
          isEmpty: !hasData,
        ),

        // Самая большая рыба
        _buildStatCard(
          title: 'Самая большая рыба',
          value: biggestFish > 0 ? biggestFish.toString() : '0',
          subtitle: biggestFishDate != null
              ? 'кг, ${DateFormatter.formatShortDate(biggestFishDate)}'
              : 'кг',
          icon: Icons.catching_pokemon,
          isEmpty: biggestFish <= 0,
        ),

        // Всего рыб
        _buildStatCard(
          title: 'Всего поймано',
          value: hasData ? totalFish.toString() : '0',
          subtitle: DateFormatter.getFishText(hasData ? totalFish : 0),
          icon: Icons.set_meal,
          progressValue: hasData ? (totalFish / 100).clamp(0.0, 1.0) : 0.0,
          isEmpty: !hasData || totalFish <= 0,
        ),

        // Самая долгая рыбалка
        _buildStatCard(
          title: 'Самая долгая рыбалка',
          value: longestTripDays > 0 ? longestTripDays.toString() : '0',
          subtitle: DateFormatter.getDaysText(longestTripDays),
          icon: Icons.timer,
          isEmpty: longestTripDays <= 0,
        ),
      ],
    );
  }

  // Карточка со статистикой
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    List<double>? chartData,
    double? progressValue,
    bool isEmpty = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isEmpty
                      ? Colors.grey.withOpacity(0.5)
                      : AppConstants.textColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEmpty
                          ? Colors.grey.withOpacity(0.8)
                          : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isEmpty
                    ? Colors.grey.withOpacity(0.8)
                    : AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isEmpty
                    ? Colors.grey.withOpacity(0.7)
                    : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            if (chartData != null && chartData.isNotEmpty)
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: chartData.map((value) {
                    return Container(
                      width: 12,
                      height: value * 24,
                      decoration: BoxDecoration(
                        color: AppConstants.textColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (progressValue != null)
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.textColor.withOpacity(0.8),
                ),
              ),
            if (isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Нет данных',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Список недавних заметок
  Widget _buildRecentNotesList() {
    // Отображаем только последние 3 заметки
    final recentNotes = _fishingNotes.take(3).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentNotes.length,
      itemBuilder: (context, index) {
        final note = recentNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF12332E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              note.location,
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  note.isMultiDay && note.endDate != null
                      ? DateFormatter.formatDateRange(note.date, note.endDate!)
                      : DateFormatter.formatDate(note.date),
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.fishingType} • ${note.biteRecords.length} ${DateFormatter.getFishText(note.biteRecords.length)}',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: note.photoUrls.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: note.photoUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              )
                  : Icon(
                Icons.photo_camera,
                color: AppConstants.textColor,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppConstants.textColor,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/fishing_note_detail',
                arguments: note.id,
              ).then((value) {
                if (value == true) {
                  _loadFishingNotes();
                }
              });
            },
          ),
        );
      },
    );
  }

  // Боковое меню с исправленной проблемой отображения email
  Widget _buildDrawer() {
    final user = _firebaseService.currentUser;
    final userName = user?.displayName ?? 'Пользователь';
    final userEmail = user?.email ?? '';

    return Drawer(
      child: Container(
        color: AppConstants.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Обновленный DrawerHeader с исправленной проблемой overflow
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1F1C),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Аватар пользователя
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF12332E),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Icon(
                          Icons.person,
                          size: 40,
                          color: AppConstants.textColor,
                        )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Имя пользователя
                      Text(
                        userName,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Email пользователя - с исправлением overflow
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Основные разделы
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Личный кабинет',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(
                      'Экран личного кабинета будет доступен позже')),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Статистика',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Экран статистики будет доступен позже')),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.edit_note,
              title: 'Мои заметки',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FishingNotesListScreen()),
                ).then((value) {
                  if (value == true) {
                    _loadFishingNotes();
                  }
                });
              },
            ),

            _buildDrawerItem(
              icon: Icons.timer,
              title: 'Таймеры',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimersScreen()),
                );
              },
            ),

            const Divider(
              color: Colors.white24,
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            // Дополнительный раздел "Прочее"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Прочее',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Настройки',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Экран настроек будет доступен позже')),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Помощь/Связь',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Экран помощи будет доступен позже')),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.exit_to_app,
              title: 'Выйти',
              onTap: () async {
                Navigator.pop(context);
                await _firebaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Элемент бокового меню
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppConstants.textColor,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // Нижняя навигационная панель с выделенной кнопкой "Заметка"
  Widget _buildBottomNavigationBar() {
    return Container(
        height: 90, // Увеличиваем высоту для размещения большой центральной кнопки
        child: Stack(
        children: [
        // Основная панель с 4 кнопками (без центральной)
        Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
        height: 60, // Стандартная высота панели
        decoration: BoxDecoration(
        color: const Color(0xFF0B1F1D),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.3),
    spreadRadius: 1,
    blurRadius: 5,
    offset: const Offset(0, -1),
    ),
    ],
    borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    ),
    ),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
    // Таймер
    Expanded(
    child: InkWell(
    onTap: () => _onItemTapped(0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    Icons.access_time,
    color: _selectedIndex == 0
    ? AppConstants.textColor
        : Colors.white54,
    size: 22,
    ),
    const SizedBox(height: 4),
    Text(
    'Таймер',
    style: TextStyle(
    fontSize: 11,
    color: _selectedIndex == 0 ? AppConstants
        .textColor : Colors.white54,
    ),
    ),
    ],
    ),
    ),
    ),

    // Погода
    Expanded(
    child: InkWell(
    onTap: () => _onItemTapped(1),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    Icons.cloud,
    color: _selectedIndex == 1
    ? AppConstants.textColor
        : Colors.white54,
    size: 22,
    ),
    const SizedBox(height: 4),
    Text(
    'Погода',
    style: TextStyle(
    fontSize: 11,
    color: _selectedIndex == 1 ? AppConstants
        .textColor : Colors.white54,
    ),
    ),
    ],
    ),
    ),
    ),

    // Пустое место для центральной кнопки
    const Expanded(child: SizedBox()),

    // Календарь
    Expanded(
    child: InkWell(
    onTap: () => _onItemTapped(3),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    Icons.calendar_today,
    color: _selectedIndex == 3
    ? AppConstants.textColor
        : Colors.white54,
    size: 22,
    ),
    const SizedBox(height: 4),
    Text(
    'Календарь',
    style: TextStyle(
    fontSize: 11,
    color: _selectedIndex == 3 ? AppConstants
        .textColor : Colors.white54,
    ),
    ),
    ],
    ),
    ),
    ),

    // Уведомления
    Expanded(
    child: InkWell(
    onTap: () => _onItemTapped(4),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Stack(
    alignment: Alignment.center,
    children: [
    Icon(
    Icons.notifications,
    color: _selectedIndex == 4 ? AppConstants
        .textColor : Colors.white54,
    size: 22,
    ),
    Positioned(
    right: -2,
    top: 0,
    child: Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
    color: Colors.red,
    shape: BoxShape.circle,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 4),
    Text(
    'Уведомл...',
    style: TextStyle(
    fontSize: 11,
    color: _selectedIndex == 4 ? AppConstants
        .textColor : Colors.white54,
    ),
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    ),
    ),

    // Центральная кнопка, размещенная выше панели
    Positioned(
    top: 0, // Размещаем кнопку в верхней части Container
    left: 0,
    right: 0,
      child: GestureDetector(
        onTap: () => _onItemTapped(2),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 80,
            height: 80,
          ),
        ),
      ),
    ),
    ],
    ),
    );
  }
}