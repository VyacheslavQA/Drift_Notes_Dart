// Путь: lib/screens/home_screen.dart
// ИСПРАВЛЕНИЯ: YouTube карточка и навигация

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
import '../widgets/center_button_tooltip.dart';
import '../services/user_consent_service.dart';
import '../widgets/user_agreements_dialog.dart';
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
import 'tournaments/tournaments_screen.dart';
import 'shops/shops_screen.dart';

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
  bool _hasNewNotifications = true;

  // Переменные для системы принудительного принятия политики
  ConsentRestrictionResult? _policyRestrictions;
  bool _hasPolicyBeenChecked = false;

  int _selectedIndex = 2; // Центральная кнопка (рыбка) по умолчанию выбрана

  // ХАРДКОР: Фиксированные размеры навигации (не зависят от адаптивности)
  static const double _navBarHeight = 60.0; // Всегда 60px
  static const double _centerButtonSize = 80.0; // УВЕЛИЧЕНО: 80px вместо 70px
  static const double _navIconSize = 22.0; // УМЕНЬШЕНО: 22px вместо 24px
  static const double _navTextSize = 10.0; // УМЕНЬШЕНО: 10px вместо 11px
  static const double _navItemMinTouchTarget = 48.0; // Минимум для accessibility

  // ХАРДКОР: Фиксированные размеры AppBar
  static const double _appBarHeight = kToolbarHeight; // 56px стандарт
  static const double _appBarTitleSize = 24.0; // Всегда 24px
  static const double _appBarIconSize = 26.0; // Всегда 26px

  // Простые адаптивные утилиты (БЕЗ навигации и AppBar)
  bool get isTablet => MediaQuery.of(context).size.width >= 768;
  double get screenWidth => MediaQuery.of(context).size.width;
  double get horizontalPadding => isTablet ? 32.0 : 16.0;
  double get cardPadding => isTablet ? 20.0 : 16.0;
  double get iconSize => isTablet ? 28.0 : 24.0;
  double get fontSize => isTablet ? 18.0 : 16.0;
  double get buttonHeight => isTablet ? 56.0 : 48.0;
  int get gridColumns => isTablet ? 4 : 2;

  @override
  void initState() {
    super.initState();
    _loadFishingNotes();
    _fishingNoteRepository.syncOfflineDataOnStartup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPolicyBeenChecked) {
      _hasPolicyBeenChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPolicyCompliance();
      });
    }
  }

  // Проверяет соблюдение политики конфиденциальности
  Future<void> _checkPolicyCompliance() async {
    try {
      if (!mounted) return;

      String languageCode = 'ru';

      try {
        final localizations = AppLocalizations.of(context);
        languageCode = localizations.translate('language_code') ?? 'ru';
      } catch (e) {
        debugPrint('⚠️ Локализация недоступна, используем русский язык');
      }

      final consentResult = await UserConsentService().checkUserConsents(
        languageCode,
      );

      if (!consentResult.allValid) {
        debugPrint('🚫 Политика не принята - показываем принудительный диалог');
        if (mounted) {
          await _showPolicyUpdateDialog();
        }
      }

      _policyRestrictions = await UserConsentService().getConsentRestrictions(
        languageCode,
      );

      if (mounted && _policyRestrictions!.hasRestrictions) {
        debugPrint('⚠️ Действуют ограничения: ${_policyRestrictions!.level}');
        _showPolicyRestrictionBanner();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке политики: $e');
    }
  }

  Future<void> _showPolicyUpdateDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: UserAgreementsDialog(
            onAgreementsAccepted: () async {
              debugPrint('✅ Политика принята пользователем');
              await _refreshPolicyStatus();
            },
            onCancel: () async {
              debugPrint('❌ Пользователь отказался от принятия политики');
              await UserConsentService().recordPolicyRejection();
              await _refreshPolicyStatus();
            },
          ),
        );
      },
    );
  }

  Future<void> _refreshPolicyStatus() async {
    if (!mounted) return;

    String languageCode = 'ru';

    try {
      final localizations = AppLocalizations.of(context);
      languageCode = localizations.translate('language_code') ?? 'ru';
    } catch (e) {
      debugPrint('⚠️ Локализация недоступна при обновлении статуса');
    }

    _policyRestrictions = await UserConsentService().getConsentRestrictions(
      languageCode,
    );

    if (mounted && _policyRestrictions!.hasRestrictions) {
      _showPolicyRestrictionBanner();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showPolicyRestrictionBanner() {
    if (!mounted || _policyRestrictions == null) return;

    final localizations = AppLocalizations.of(context);
    final restrictions = _policyRestrictions!;

    Color bannerColor;
    IconData bannerIcon;

    switch (restrictions.level) {
      case ConsentRestrictionLevel.soft:
        bannerColor = Colors.orange;
        bannerIcon = Icons.warning_amber;
        break;
      case ConsentRestrictionLevel.hard:
        bannerColor = Colors.red;
        bannerIcon = Icons.warning;
        break;
      case ConsentRestrictionLevel.final_:
        bannerColor = Colors.red[800]!;
        bannerIcon = Icons.error;
        break;
      case ConsentRestrictionLevel.deletion:
        bannerColor = Colors.red[900]!;
        bannerIcon = Icons.delete_forever;
        break;
      default:
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(bannerIcon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localizations.translate('policy_restrictions_title') ??
                            'Ограничения доступа',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        restrictions.restrictionMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: bannerColor,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: localizations.translate('accept_policy') ?? 'Принять политику',
              textColor: Colors.white,
              onPressed: () => _showPolicyUpdateDialog(),
            ),
          ),
        );
      }
    });
  }

  bool get _canCreateContent => _policyRestrictions?.canCreateContent ?? true;

  void _showContentCreationBlocked() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('create_note_blocked') ??
              'Создание заметок заблокировано. Примите политику конфиденциальности.',
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: localizations.translate('accept_policy') ?? 'Принять политику',
          textColor: Colors.white,
          onPressed: () => _showPolicyUpdateDialog(),
        ),
      ),
    );
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
          SnackBar(
            content: Text(
              '${localizations.translate('loading_error')}: ${e.toString()}',
            ),
          ),
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
            SnackBar(
              content: Text(localizations.translate('failed_to_open_link')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('link_open_error')}: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimersScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
        break;
      case 2:
        _navigateToAddNote();
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FishingCalendarScreen(),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
    }
  }

  void _navigateToAddNote() {
    if (!_canCreateContent) {
      _showContentCreationBlocked();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishingTypeSelectionScreen(),
      ),
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
        _hasNewNotifications = false;
      });
    });
  }

  void _showComingSoonMessage(String sectionName) {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$sectionName ${localizations.translate('coming_soon')}'),
        backgroundColor: AppConstants.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics(List<FishingNoteModel> notes) {
    final stats = <String, dynamic>{};
    stats['totalTrips'] = notes.length;

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

    Set<DateTime> uniqueFishingDays = {};
    for (var note in notes) {
      DateTime startDate = DateTime(
        note.date.year,
        note.date.month,
        note.date.day,
      );
      DateTime endDate =
      note.endDate != null
          ? DateTime(
        note.endDate!.year,
        note.endDate!.month,
        note.endDate!.day,
      )
          : startDate;

      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        uniqueFishingDays.add(startDate.add(Duration(days: i)));
      }
    }
    stats['totalDaysFishing'] = uniqueFishingDays.length;

    int totalFish = 0;
    int missedBites = 0;
    double totalWeight = 0.0;

    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty && record.weight > 0) {
          totalFish++;
          totalWeight += record.weight;
        } else {
          missedBites++;
        }
      }
    }
    stats['totalFish'] = totalFish;
    stats['missedBites'] = missedBites;
    stats['totalWeight'] = totalWeight;

    BiteRecord? biggestFish;
    String biggestFishLocation = '';
    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty &&
            record.weight > 0 &&
            (biggestFish == null || record.weight > biggestFish.weight)) {
          biggestFish = record;
          biggestFishLocation = note.location;
        }
      }
    }
    stats['biggestFish'] = biggestFish;
    stats['biggestFishLocation'] = biggestFishLocation;

    FishingNoteModel? lastTrip;
    if (notes.isNotEmpty) {
      lastTrip = notes.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    }
    stats['lastTrip'] = lastTrip;

    Map<String, int> fishByMonth = {};
    Map<String, Map<String, int>> monthDetails = {};

    for (var note in notes) {
      for (var record in note.biteRecords) {
        if (record.fishType.isNotEmpty && record.weight > 0) {
          String monthKey = '${record.time.year}-${record.time.month}';
          fishByMonth[monthKey] = (fishByMonth[monthKey] ?? 0) + 1;

          if (!monthDetails.containsKey(monthKey)) {
            monthDetails[monthKey] = {
              'month': record.time.month,
              'year': record.time.year,
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

    final totalBites = totalFish + missedBites;
    double realizationRate = 0;
    if (totalBites > 0) {
      realizationRate = (totalFish / totalBites) * 100;
    }
    stats['realizationRate'] = realizationRate;

    return stats;
  }

  // ИСПРАВЛЕНО: АДАПТИВНАЯ сетка быстрых действий без обрезания
  Widget _buildQuickActionsGrid() {
    final localizations = AppLocalizations.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: gridColumns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      childAspectRatio: isTablet ? 1.1 : 1.0, // ИСПРАВЛЕНО: больше высоты для текста
      children: [
        _buildQuickActionItem(
          icon: Icons.newspaper_outlined,
          label: localizations.translate('news'),
          onTap: () => _showComingSoonMessage(localizations.translate('news')),
        ),
        _buildQuickActionItem(
          icon: Icons.menu_book_outlined,
          label: localizations.translate('articles'),
          onTap: () => _showComingSoonMessage(localizations.translate('articles')),
        ),
        _buildQuickActionItem(
          icon: Icons.local_mall_outlined,
          label: localizations.translate('shops'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopsScreen()),
            );
          },
        ),
        _buildQuickActionItem(
          icon: Icons.emoji_events_outlined,
          label: localizations.translate('tournaments'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TournamentsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ИСПРАВЛЕНО: Элемент быстрого действия с БОЛЬШИМИ иконками
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ИСПРАВЛЕНО: УВЕЛИЧЕНЫ иконки
            Container(
              height: isTablet ? 70 : 60, // ИСПРАВЛЕНО: больше места для иконки
              child: Icon(
                icon,
                color: AppConstants.textColor,
                size: isTablet ? 60 : 50, // ИСПРАВЛЕНО: УВЕЛИЧЕНЫ иконки значительно
              ),
            ),
            const SizedBox(height: 8),
            // Контейнер для текста
            Container(
              height: isTablet ? 40 : 32,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final localizations = AppLocalizations.of(context);

    final now = DateTime.now();
    final validNotes = _fishingNotes
        .where((note) => note.date.isBefore(now) || note.date.isAtSameMomentAs(now))
        .toList();

    final stats = _calculateStatistics(validNotes);

    return Column(
      children: [
        if (_policyRestrictions?.hasRestrictions == true)
          _buildPolicyRestrictionCard(),

        if (stats['biggestFish'] != null) ...[
          _buildStatCard(
            icon: Icons.emoji_events,
            title: localizations.translate('biggest_fish'),
            value: '${stats['biggestFish'].weight} ${localizations.translate('kg')}',
            subtitle: '${stats['biggestFish'].fishType}, ${DateFormatter.formatDate(stats['biggestFish'].time, context)}',
            valueColor: Colors.amber,
          ),
          const SizedBox(height: 16),
        ],

        _buildStatCard(
          icon: Icons.set_meal,
          title: localizations.translate('total_fish_caught'),
          value: stats['totalFish'].toString(),
          subtitle: DateFormatter.getFishText(stats['totalFish'], context),
          valueColor: Colors.green,
        ),
        const SizedBox(height: 16),

        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: localizations.translate('missed_bites'),
          value: stats['missedBites'].toString(),
          subtitle: localizations.translate('bites_without_catch'),
          valueColor: Colors.red,
        ),
        const SizedBox(height: 16),

        if (stats['totalFish'] > 0 || stats['missedBites'] > 0) ...[
          _buildStatCard(
            icon: Icons.percent,
            title: localizations.translate('bite_realization'),
            value: '${stats['realizationRate'].toStringAsFixed(1)}%',
            subtitle: localizations.translate('fishing_efficiency'),
            valueColor: _getRealizationColor(stats['realizationRate']),
          ),
          const SizedBox(height: 16),
        ],

        _buildStatCard(
          icon: Icons.scale,
          title: localizations.translate('total_catch_weight'),
          value: '${stats['totalWeight'].toStringAsFixed(1)} ${localizations.translate('kg')}',
          subtitle: localizations.translate('total_weight_caught_fish'),
          valueColor: Colors.green,
        ),
        const SizedBox(height: 16),

        _buildStatCard(
          icon: Icons.format_list_bulleted,
          title: localizations.translate('total_fishing_trips'),
          value: stats['totalTrips'].toString(),
          subtitle: DateFormatter.getFishingTripsText(stats['totalTrips'], context),
        ),
        const SizedBox(height: 16),

        _buildStatCard(
          icon: Icons.access_time,
          title: localizations.translate('longest_trip'),
          value: stats['longestTrip'].toString(),
          subtitle: DateFormatter.getDaysText(stats['longestTrip'], context),
        ),
        const SizedBox(height: 16),

        _buildStatCard(
          icon: Icons.calendar_today,
          title: localizations.translate('total_fishing_days'),
          value: stats['totalDaysFishing'].toString(),
          subtitle: localizations.translate('days_fishing'),
        ),
        const SizedBox(height: 16),

        if (stats['lastTrip'] != null) ...[
          _buildStatCard(
            icon: Icons.directions_car,
            title: localizations.translate('last_trip'),
            value: stats['lastTrip'].title.isNotEmpty
                ? '«${stats['lastTrip'].title}»'
                : stats['lastTrip'].location,
            subtitle: DateFormatter.formatDate(stats['lastTrip'].date, context),
          ),
          const SizedBox(height: 16),
        ],

        if (stats['bestMonth'].isNotEmpty) ...[
          _buildStatCard(
            icon: Icons.star,
            title: localizations.translate('best_month'),
            value: '${DateFormatter.getMonthInNominative(stats['bestMonthNumber'], context)} ${stats['bestYear']}',
            subtitle: '${stats['bestMonthFish']} ${DateFormatter.getFishText(stats['bestMonthFish'], context)}',
            valueColor: Colors.amber,
          ),
        ],
      ],
    );
  }

  Widget _buildPolicyRestrictionCard() {
    if (_policyRestrictions == null || !_policyRestrictions!.hasRestrictions) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context);
    final restrictions = _policyRestrictions!;

    Color cardColor;
    IconData cardIcon;
    String title;

    switch (restrictions.level) {
      case ConsentRestrictionLevel.soft:
        cardColor = Colors.orange;
        cardIcon = Icons.warning_amber;
        title = localizations.translate('soft_restrictions_title') ?? 'Мягкие ограничения';
        break;
      case ConsentRestrictionLevel.hard:
        cardColor = Colors.red;
        cardIcon = Icons.warning;
        title = localizations.translate('hard_restrictions_title') ?? 'Жесткие ограничения';
        break;
      case ConsentRestrictionLevel.final_:
        cardColor = Colors.red[800]!;
        cardIcon = Icons.error;
        title = localizations.translate('final_warning_title') ?? 'Финальное предупреждение';
        break;
      case ConsentRestrictionLevel.deletion:
        cardColor = Colors.red[900]!;
        cardIcon = Icons.delete_forever;
        title = localizations.translate('deletion_warning_title') ?? 'Запланировано удаление';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cardIcon, color: cardColor, size: iconSize),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: cardColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restrictions.restrictionMessage,
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: fontSize - 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () => _showPolicyUpdateDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localizations.translate('accept_policy') ?? 'Принять политику',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRealizationColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return CenterButtonTooltip(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Drift Notes',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: _appBarTitleSize, // ХАРДКОР: Фиксированный размер
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: _appBarHeight, // ХАРДКОР: Фиксированная высота
          leading: IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppConstants.textColor,
              size: _appBarIconSize, // ХАРДКОР: Фиксированный размер
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_rounded,
                    color: AppConstants.textColor,
                    size: _appBarIconSize, // ХАРДКОР: Фиксированный размер
                  ),
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
          onRefresh: () async {
            await _checkPolicyCompliance();
            await _loadFishingNotes();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildYoutubePromoCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 24),
                  Text(
                    localizations.translate('my_statistics'),
                    style: TextStyle(
                      fontSize: isTablet ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 40),
                  // ХАРДКОР ИСПРАВЛЕНО: Учитываем правильную высоту навигации
                  SizedBox(height: _navBarHeight + (_centerButtonSize / 2) + 40),
                ],
              ),
            ),
          ),
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // ИСПРАВЛЕНО: YouTube карточка БЕЗ текста
  Widget _buildYoutubePromoCard() {
    return GestureDetector(
      onTap: () => _launchUrl('https://www.youtube.com/@Carpediem_hunting_fishing'),
      child: Container(
        height: isTablet ? 200 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/fishing_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          // УБРАНО: весь текст удален
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
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: valueColor ?? AppConstants.textColor,
              size: iconSize,
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
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: fontSize - 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppConstants.textColor,
                    fontSize: fontSize + 4,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: fontSize - 2,
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
        padding: EdgeInsets.only(bottom: _navBarHeight + (_centerButtonSize / 2) + 20), // ХАРДКОР ИСПРАВЛЕНО
        child: StreamBuilder<UserModel?>(
          stream: _userRepository.getUserStream(),
          builder: (context, snapshot) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF0A1F1C)),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/drawer_logo.png',
                            width: 110.0, // ХАРДКОР: Фиксированный размер
                            height: 110.0,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 20.0, // ХАРДКОР: Фиксированный размер
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
                              fontSize: 14.0, // ХАРДКОР: Фиксированный размер
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
                    if (_policyRestrictions?.canEditProfile != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.translate('edit_profile_blocked') ??
                                'Редактирование профиля заблокировано. Примите политику конфиденциальности.',
                          ),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: localizations.translate('accept_policy') ?? 'Принять политику',
                            textColor: Colors.white,
                            onPressed: () => _showPolicyUpdateDialog(),
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
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
                      MaterialPageRoute(builder: (context) => const FishingCalendarScreen()),
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
                      MaterialPageRoute(builder: (context) => const MarkerMapsListScreen()),
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
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3), // ХАРДКОР: Фиксированный цвет
                      fontSize: 14.0, // ХАРДКОР: Фиксированный размер
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
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: localizations.translate('help_contact'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help_contact');
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
      leading: Icon(icon, color: AppConstants.textColor, size: 22.0), // ХАРДКОР: Фиксированный размер
      title: Text(
        title,
        style: TextStyle(color: AppConstants.textColor, fontSize: 16.0), // ХАРДКОР: Фиксированный размер
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ХАРДКОР ИСПРАВЛЕНО: Фиксированная навигационная панель с правильным расположением
  Widget _buildBottomNavigationBar() {
    final localizations = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _navBarHeight + (_centerButtonSize / 2) + bottomPadding, // ИСПРАВЛЕНО: учитываем высоту центральной кнопки
      child: Stack(
        children: [
          // Нижняя панель
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _navBarHeight + bottomPadding,
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
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: [
                    // ИСПРАВЛЕНО: Используем Expanded для равномерного распределения
                    _buildNavItem(0, Icons.timelapse_rounded, localizations.translate('timer')),
                    _buildNavItem(1, Icons.cloud_queue_rounded, localizations.translate('weather')),
                    Expanded(child: Container()), // ИСПРАВЛЕНО: Пустое место для центральной кнопки
                    _buildNavItem(3, Icons.event_note_rounded, localizations.translate('calendar')),
                    _buildNavItem(4, Icons.explore_rounded, localizations.translate('map')),
                  ],
                ),
              ),
            ),
          ),

          // ИСПРАВЛЕНО: Центральная кнопка ВЫШЕ панели
          Positioned(
            top: 0, // ИСПРАВЛЕНО: Начинается с самого верха
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Center(
                child: Container(
                  width: _centerButtonSize,
                  height: _centerButtonSize,
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
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: _centerButtonSize,
                        height: _centerButtonSize,
                      ),
                      if (!_canCreateContent)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 22.0,
                            height: 22.0,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 14.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ХАРДКОР ИСПРАВЛЕНО: Фиксированные элементы навигации без overflow
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Container(
        height: _navItemMinTouchTarget, // 48px
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // ИСПРАВЛЕНО: минимальный размер
            children: [
              Icon(
                icon,
                color: isSelected ? AppConstants.textColor : Colors.white54,
                size: _navIconSize, // 22px
              ),
              const SizedBox(height: 2), // ИСПРАВЛЕНО: уменьшен отступ с 4 до 2
              Flexible( // ИСПРАВЛЕНО: добавлен Flexible для текста
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _navTextSize, // 10px
                    color: isSelected ? AppConstants.textColor : Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}