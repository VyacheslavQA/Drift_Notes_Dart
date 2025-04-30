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
import 'timer/timers_screen.dart'; // Правильный импорт для экрана таймеров

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
    // Навигация на экран добавления заметки
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddFishingNoteScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(
          'Функция создания заметки будет доступна в ближайшее время')),
    );
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
          value: '0',
          subtitle: 'рыбалок',
          icon: Icons.format_list_bulleted,
          chartData: const [0.2, 0.4, 0.3, 0.5, 0.7, 0.2],
        ),

        // Самая большая рыба
        _buildStatCard(
          title: 'Самая большая рыба',
          value: '12,5',
          subtitle: 'кг, 12 марта',
          icon: Icons.catching_pokemon,
        ),

        // Всего рыб
        _buildStatCard(
          title: 'Всего поймано',
          value: '8',
          subtitle: 'рыб',
          icon: Icons.set_meal,
          progressValue: 0.6,
        ),

        // Самая долгая рыбалка
        _buildStatCard(
          title: 'Самая долгая рыбалка',
          value: '0',
          subtitle: 'дней',
          icon: Icons.timer,
          isEmpty: true,
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

  // Боковое меню
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1F1C),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),

                  // Имя пользователя
                  Text(
                    userName,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Email пользователя
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(
                      'Экран со всеми заметками будет доступен позже')),
                );
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
            child: Center(
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
          ),
        ],
      ),
    );
  }
}