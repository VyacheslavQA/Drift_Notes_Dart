// Путь: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/firebase_service.dart';
import '../repositories/fishing_note_repository.dart';
import '../repositories/user_repository.dart';
import '../models/fishing_note_model.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_formatter.dart';
import '../localization/app_localizations.dart';
import 'timer/timers_screen.dart';
import 'fishing_note/fishing_type_selection_screen.dart';
import 'fishing_note/fishing_notes_list_screen.dart';
import 'calendar/fishing_calendar_screen.dart';
import 'profile/profile_screen.dart';
import 'map/map_screen.dart';
import 'notifications/notifications_screen.dart';
import 'statistics/statistics_screen.dart';
import 'marker_maps/marker_maps_list_screen.dart';
import 'settings/settings_screen.dart';
import 'weather/weather_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _fishingNoteRepository = FishingNoteRepository();
  final _userRepository = UserRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<FishingNoteModel> _fishingNotes = [];
  bool _hasNewNotifications = true; // Временно устанавливаем в true для демонстрации

  int _selectedIndex = 2; // Центральная кнопка (рыбка) по умолчанию выбрана

  @override
  void initState() {
    super.initState();
    _loadFishingNotes(); // Оставляем для статистики
    _fishingNoteRepository.syncOfflineDataOnStartup();
  }

  Future<void> _loadFishingNotes() async {
    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      if (mounted) {
        setState(() {
          _fishingNotes = notes;
        });
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('loading_error')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.translate('failed_to_open_link'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('link_open_error')}: ${e.toString()}')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final localizations = AppLocalizations.of(context);

    switch (index) {
      case 0: // Таймер
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimersScreen()),
        );
        break;
      case 1: // Погода
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
        break;
      case 2: // Центральная кнопка - создание заметки
        _navigateToAddNote();
        break;
      case 3: // Календарь
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const FishingCalendarScreen()),
        );
        break;
      case 4: // Карта
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
    }
  }

  void _navigateToAddNote() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const FishingTypeSelectionScreen())
    ).then((value) {
      if (value == true) {
        _loadFishingNotes();
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    ).then((_) {
      setState(() {
        _hasNewNotifications = false; // Сбрасываем индикатор после посещения
      });
    });
  }

  // Изменения в методе _calculateStatistics
  Map<String, dynamic> _calculateStatistics(List<FishingNoteModel> notes) {
    final stats = <String, dynamic>{};

    // 1. Всего рыбалок
    stats['totalTrips'] = notes.length;

    // 2. Самая долгая рыбалка
    int longestTrip = 0;
    String longestTripName = '';
    for (var note in notes) {
      if (note.isMultiDay && note.endDate != null) {
        int days = note.endDate!.difference(note.date).inDays + 1;
        if (days > longestTrip) {
          longestTrip = days;
          longestTripName = note.title.isNotEmpty ? note.title : note.location;
        }
      } else {
        if (longestTrip == 0) longestTrip = 1;
      }
    }
    stats['longestTrip'] = longestTrip;
    stats['longestTripName'] = longestTripName;

    // 3. Всего дней на рыбалке
    Set<DateTime> uniqueFishingDays = {};
    for (var note in notes) {
      DateTime startDate = DateTime(note.date.year, note.date.month, note.date.day);
      DateTime endDate = note.endDate != null
          ? DateTime(note.endDate!.year, note.endDate!.month, note.endDate!.day)
          : startDate;

      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        uniqueFishingDays.add(startDate.add(Duration(days: i)));
      }
    }
    stats['totalDaysFishing'] = uniqueFishingDays.length;

    // 4. Всего поймано рыб и нереализованных поклевок
    int totalFish = 0;
    int missedBites = 0;
    double totalWeight = 0.0; // Новая переменная для общего веса

    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty && record.weight > 0) {
          totalFish++;
          totalWeight += record.weight; // Добавляем вес к общему
        } else {
          missedBites++;
        }
      }
    }
    stats['totalFish'] = totalFish;
    stats['missedBites'] = missedBites;
    stats['totalWeight'] = totalWeight; // Новое поле

    // 5. Самая большая рыба
    BiteRecord? biggestFish;
    String biggestFishLocation = '';
    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty && record.weight > 0 &&
            (biggestFish == null || record.weight > biggestFish.weight)) {
          biggestFish = record;
          biggestFishLocation = note.location;
        }
      }
    }
    stats['biggestFish'] = biggestFish;
    stats['biggestFishLocation'] = biggestFishLocation;

    // 6. Последний выезд
    FishingNoteModel? lastTrip;
    if (notes.isNotEmpty) {
      lastTrip = notes.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    }
    stats['lastTrip'] = lastTrip;

    // 7. Лучший месяц по количеству рыбы - ИЗМЕНЕНО
    Map<String, int> fishByMonth = {};
    Map<String, Map<String, int>> monthDetails = {}; // Для хранения номера месяца и года

    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty && record.weight > 0) {
          // Создаем ключ для группировки по месяцам
          String monthKey = '${record.time.year}-${record.time.month}';
          fishByMonth[monthKey] = (fishByMonth[monthKey] ?? 0) + 1;

          // Сохраняем номер месяца и год для каждого ключа
          if (!monthDetails.containsKey(monthKey)) {
            monthDetails[monthKey] = {
              'month': record.time.month,
              'year': record.time.year
            };
          }
        }
      }
    }

    String bestMonthKey = '';
    int bestMonthFish = 0;
    int bestMonthNumber = 0;
    int bestYear = 0;

    fishByMonth.forEach((monthKey, count) {
      if (count > bestMonthFish) {
        bestMonthFish = count;
        bestMonthKey = monthKey;

        // Получаем номер месяца и год из сохраненных данных
        if (monthDetails.containsKey(monthKey)) {
          bestMonthNumber = monthDetails[monthKey]!['month']!;
          bestYear = monthDetails[monthKey]!['year']!;
        }
      }
    });

    stats['bestMonth'] = bestMonthKey.isNotEmpty ? bestMonthKey : '';
    stats['bestMonthNumber'] = bestMonthNumber;
    stats['bestYear'] = bestYear;
    stats['bestMonthFish'] = bestMonthFish;

    // 8. Процент реализации поклевок
    final totalBites = totalFish + missedBites;
    double realizationRate = 0;
    if (totalBites > 0) {
      realizationRate = (totalFish / totalBites) * 100;
    }
    stats['realizationRate'] = realizationRate;

    return stats;
  }

  // Обновлённый метод _buildStatsGrid() с локализацией
  Widget _buildStatsGrid() {
    final localizations = AppLocalizations.of(context);

    // Фильтруем только прошедшие и текущие заметки
    final now = DateTime.now();
    final validNotes = _fishingNotes.where((note) =>
    note.date.isBefore(now) || note.date.isAtSameMomentAs(now)
    ).toList();

    // Расчет статистики
    final stats = _calculateStatistics(validNotes);

    return Column(
      children: [
        // 1. Самая большая рыба
        if (stats['biggestFish'] != null)
          _buildStatCard(
            icon: Icons.emoji_events,
            title: localizations.translate('biggest_fish'),
            value: '${stats['biggestFish'].weight} ${localizations.translate('kg')}',
            subtitle: '${stats['biggestFish'].fishType}, ${DateFormatter.formatDate(stats['biggestFish'].time, context)}',
            valueColor: Colors.amber,
          ),

        const SizedBox(height: 16),

        // 2. Всего поймано рыб
        _buildStatCard(
          icon: Icons.set_meal,
          title: localizations.translate('total_fish_caught'),
          value: stats['totalFish'].toString(),
          subtitle: DateFormatter.getFishText(stats['totalFish'], context),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 3. Нереализованные поклевки
        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: localizations.translate('missed_bites'),
          value: stats['missedBites'].toString(),
          subtitle: localizations.translate('bites_without_catch'),
          valueColor: Colors.red,
        ),

        const SizedBox(height: 16),

        // 4. Реализация поклевок
        if (stats['totalFish'] > 0 || stats['missedBites'] > 0)
          _buildStatCard(
            icon: Icons.percent,
            title: localizations.translate('bite_realization'),
            value: '${stats['realizationRate'].toStringAsFixed(1)}%',
            subtitle: localizations.translate('fishing_efficiency'),
            valueColor: _getRealizationColor(stats['realizationRate']),
          ),

        const SizedBox(height: 16),

        // 5. Общий вес пойманных рыб
        _buildStatCard(
          icon: Icons.scale,
          title: localizations.translate('total_catch_weight'),
          value: '${stats['totalWeight'].toStringAsFixed(1)} ${localizations.translate('kg')}',
          subtitle: localizations.translate('total_weight_caught_fish'),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 6. Всего рыбалок
        _buildStatCard(
          icon: Icons.format_list_bulleted,
          title: localizations.translate('total_fishing_trips'),
          value: stats['totalTrips'].toString(),
          subtitle: DateFormatter.getFishingTripsText(stats['totalTrips'], context),
        ),

        const SizedBox(height: 16),

        // 7. Самая долгая рыбалка
        _buildStatCard(
          icon: Icons.access_time,
          title: localizations.translate('longest_trip'),
          value: stats['longestTrip'].toString(),
          subtitle: DateFormatter.getDaysText(stats['longestTrip'], context),
        ),

        const SizedBox(height: 16),

        // 8. Всего дней на рыбалке
        _buildStatCard(
          icon: Icons.calendar_today,
          title: localizations.translate('total_fishing_days'),
          value: stats['totalDaysFishing'].toString(),
          subtitle: localizations.translate('days_fishing'),
        ),

        const SizedBox(height: 16),

        // 9. Последний выезд
        if (stats['lastTrip'] != null)
          _buildStatCard(
            icon: Icons.directions_car,
            title: localizations.translate('last_trip'),
            value: stats['lastTrip'].title.isNotEmpty
                ? '«${stats['lastTrip'].title}»'
                : stats['lastTrip'].location,
            subtitle: DateFormatter.formatDate(stats['lastTrip'].date, context),
          ),

        const SizedBox(height: 16),

        // 10. Лучший месяц
        if (stats['bestMonth'].isNotEmpty)
          _buildStatCard(
            icon: Icons.star,
            title: localizations.translate('best_month'),
            value: '${DateFormatter.getMonthInNominative(stats['bestMonthNumber'], context)} ${stats['bestYear']}',
            subtitle: '${stats['bestMonthFish']} ${DateFormatter.getFishText(stats['bestMonthFish'], context)}',
            valueColor: Colors.amber,
          ),
      ],
    );
  }

  // Метод для определения цвета в зависимости от процента реализации
  Color _getRealizationColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
          icon: Icon(Icons.menu_rounded, color: AppConstants.textColor, size: 26),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_rounded,
                    color: AppConstants.textColor,
                    size: 26),
                onPressed: _navigateToNotifications,
              ),
              if (_hasNewNotifications)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
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
                  localizations.translate('my_statistics'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Статистика
                _buildStatsGrid(),

                const SizedBox(height: 40),
                // Убрали отображение заметок
                // Добавляем дополнительный отступ снизу для компенсации навигационной панели
                const SizedBox(height: 90), // Высота равна высоте bottomNavigationBar
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildYoutubePromoCard() {
    final localizations = AppLocalizations.of(context);

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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  localizations.translate('visit_youtube_channel'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: valueColor ?? AppConstants.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final localizations = AppLocalizations.of(context);
    final user = _firebaseService.currentUser;
    final userName = user?.displayName ?? localizations.translate('user');
    final userEmail = user?.email ?? '';

    return Drawer(
      child: Container(
        color: AppConstants.backgroundColor,
        child: StreamBuilder<UserModel?>(
          stream: _userRepository.getUserStream(),
          builder: (context, snapshot) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1F1C),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Логотип приложения вместо аватара
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF12332E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/drawer_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
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

                _buildDrawerItem(
                  icon: Icons.person,
                  title: localizations.translate('profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: localizations.translate('statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.edit_note,
                  title: localizations.translate('my_notes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FishingNotesListScreen()),
                    ).then((value) {
                      if (value == true) {
                        _loadFishingNotes();
                      }
                    });
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.timer,
                  title: localizations.translate('timers'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TimersScreen()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: localizations.translate('calendar'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FishingCalendarScreen()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.map,
                  title: localizations.translate('marker_maps'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarkerMapsListScreen(),
                      ),
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

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    localizations.translate('other'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),

                _buildDrawerItem(
                  icon: Icons.settings,
                  title: localizations.translate('settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: localizations.translate('help_contact'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(localizations.translate('help_screen_coming_soon'))),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.exit_to_app,
                  title: localizations.translate('logout'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _firebaseService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

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

  Widget _buildBottomNavigationBar() {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 90,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F1D),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                            Icons.timelapse_rounded,
                            color: _selectedIndex == 0
                                ? AppConstants.textColor
                                : Colors.white54,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.translate('timer'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedIndex == 0
                                  ? AppConstants.textColor
                                  : Colors.white54,
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
                            Icons.cloud_queue_rounded,
                            color: _selectedIndex == 1
                                ? AppConstants.textColor
                                : Colors.white54,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.translate('weather'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedIndex == 1
                                  ? AppConstants.textColor
                                  : Colors.white54,
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
                            Icons.event_note_rounded,
                            color: _selectedIndex == 3
                                ? AppConstants.textColor
                                : Colors.white54,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.translate('calendar'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedIndex == 3
                                  ? AppConstants.textColor
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Карта (вместо уведомлений)
                  Expanded(
                    child: InkWell(
                      onTap: () => _onItemTapped(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            color: _selectedIndex == 4
                                ? AppConstants.textColor
                                : Colors.white54,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.translate('map'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedIndex == 4
                                  ? AppConstants.textColor
                                  : Colors.white54,
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

          // Центральная кнопка
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
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