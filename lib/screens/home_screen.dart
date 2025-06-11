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
  bool _hasNewNotifications = true; // Временно устанавливаем в true для демонстрации

  // ДОБАВЛЕНО: Переменные для системы принудительного принятия политики
  ConsentRestrictionResult? _policyRestrictions;
  bool _hasPolicyBeenChecked = false; // Флаг для предотвращения повторных проверок

  int _selectedIndex = 2; // Центральная кнопка (рыбка) по умолчанию выбрана

  @override
  void initState() {
    super.initState();
    // ИЗМЕНЕНО: Убираем проверку политики из initState
    _loadFishingNotes();
    _fishingNoteRepository.syncOfflineDataOnStartup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ДОБАВЛЕНО: Проверяем политику здесь, когда контекст готов
    if (!_hasPolicyBeenChecked) {
      _hasPolicyBeenChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPolicyCompliance();
      });
    }
  }

  /// НОВЫЙ МЕТОД: Проверяет соблюдение политики конфиденциальности
  Future<void> _checkPolicyCompliance() async {
    try {
      if (!mounted) return;

      String languageCode = 'ru'; // Дефолтный язык

      // Безопасно получаем язык из локализации
      try {
        final localizations = AppLocalizations.of(context);
        languageCode = localizations.translate('language_code') ?? 'ru';
      } catch (e) {
        debugPrint('⚠️ Локализация недоступна, используем русский язык');
      }

      final consentResult = await UserConsentService().checkUserConsents(languageCode);

      if (!consentResult.allValid) {
        debugPrint('🚫 Политика не принята - показываем принудительный диалог');
        if (mounted) {
          await _showPolicyUpdateDialog();
        }
      }

      // Получаем текущие ограничения с правильным языком
      _policyRestrictions = await UserConsentService().getConsentRestrictions(languageCode);

      if (mounted && _policyRestrictions!.hasRestrictions) {
        debugPrint('⚠️ Действуют ограничения: ${_policyRestrictions!.level}');
        _showPolicyRestrictionBanner();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке политики: $e');
    }
  }

  /// НОВЫЙ МЕТОД: Показывает диалог обновления политики
  Future<void> _showPolicyUpdateDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Запрещаем закрытие диалога
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

  /// НОВЫЙ МЕТОД: Обновляет статус политики после изменений
  Future<void> _refreshPolicyStatus() async {
    if (!mounted) return;

    String languageCode = 'ru'; // Дефолтный язык

    // Безопасно получаем язык из локализации
    try {
      final localizations = AppLocalizations.of(context);
      languageCode = localizations.translate('language_code') ?? 'ru';
    } catch (e) {
      debugPrint('⚠️ Локализация недоступна при обновлении статуса');
    }

    _policyRestrictions = await UserConsentService().getConsentRestrictions(languageCode);

    if (mounted && _policyRestrictions!.hasRestrictions) {
      _showPolicyRestrictionBanner();
    }

    if (mounted) {
      setState(() {}); // Обновляем UI
    }
  }

  /// НОВЫЙ МЕТОД: Показывает баннер с ограничениями политики
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

    // Показываем баннер через SnackBar
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
                        localizations.translate('policy_restrictions_title') ?? 'Ограничения доступа',
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

  /// НОВЫЙ МЕТОД: Проверяет возможность создания контента
  bool get _canCreateContent => _policyRestrictions?.canCreateContent ?? true;

  /// НОВЫЙ МЕТОД: Показывает сообщение о блокировке создания контента
  void _showContentCreationBlocked() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            localizations.translate('create_note_blocked') ??
                'Создание заметок заблокировано. Примите политику конфиденциальности.'
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
          SnackBar(content: Text(
              '${localizations.translate('loading_error')}: ${e.toString()}')),
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
                content: Text(localizations.translate('failed_to_open_link'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              '${localizations.translate('link_open_error')}: ${e
                  .toString()}')),
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
    // ДОБАВЛЕНО: Проверяем ограничения политики перед созданием заметки
    if (!_canCreateContent) {
      _showContentCreationBlocked();
      return;
    }

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

  // Показ сообщения о том, что раздел в разработке
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
      DateTime startDate = DateTime(
          note.date.year, note.date.month, note.date.day);
      DateTime endDate = note.endDate != null
          ? DateTime(note.endDate!.year, note.endDate!.month, note.endDate!.day)
          : startDate;

      for (int i = 0; i <= endDate
          .difference(startDate)
          .inDays; i++) {
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
    Map<String, Map<String, int>> monthDetails = {
    }; // Для хранения номера месяца и года

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

  // Новый метод для создания блока быстрых действий
  Widget _buildQuickActionsGrid() {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        // Первая строка
        Row(
          children: [
            // Новости
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0, // Квадратные кнопки
                child: _buildQuickActionItem(
                  icon: Icons.newspaper_outlined,
                  // Более интересная иконка газеты
                  label: localizations.translate('news'),
                  onTap: () =>
                      _showComingSoonMessage(localizations.translate('news')),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Статьи
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0, // Квадратные кнопки
                child: _buildQuickActionItem(
                  icon: Icons.menu_book_outlined, // Красивая книга с закладкой
                  label: localizations.translate('articles'),
                  onTap: () =>
                      _showComingSoonMessage(
                          localizations.translate('articles')),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12), // Отступ между строками

        // Вторая строка
        Row(
          children: [
            // Магазины
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0, // Квадратные кнопки
                child: _buildQuickActionItem(
                  icon: Icons.local_mall_outlined,
                  // Современная иконка торгового центра
                  label: localizations.translate('shops'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ShopsScreen()),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Турниры
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0, // Квадратные кнопки
                child: _buildQuickActionItem(
                  icon: Icons.emoji_events_outlined,
                  // Красивый кубок с контуром
                  label: localizations.translate('tournaments'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TournamentsScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Элемент быстрого действия
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3, // Больше места для иконки
              child: Icon(
                icon,
                color: AppConstants.textColor,
                size: 80, // Увеличил иконку в 2 раза - с 40px до 80px
              ),
            ),
            Expanded(
              flex: 1, // Меньше места для текста (опускаем вниз)
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        // ДОБАВЛЕНО: Показываем баннер ограничений если есть
        if (_policyRestrictions?.hasRestrictions == true)
          _buildPolicyRestrictionCard(),

        // 1. Самая большая рыба
        if (stats['biggestFish'] != null)
          _buildStatCard(
            icon: Icons.emoji_events,
            title: localizations.translate('biggest_fish'),
            value: '${stats['biggestFish'].weight} ${localizations.translate(
                'kg')}',
            subtitle: '${stats['biggestFish'].fishType}, ${DateFormatter
                .formatDate(stats['biggestFish'].time, context)}',
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
          value: '${stats['totalWeight'].toStringAsFixed(1)} ${localizations
              .translate('kg')}',
          subtitle: localizations.translate('total_weight_caught_fish'),
          valueColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // 6. Всего рыбалок
        _buildStatCard(
          icon: Icons.format_list_bulleted,
          title: localizations.translate('total_fishing_trips'),
          value: stats['totalTrips'].toString(),
          subtitle: DateFormatter.getFishingTripsText(
              stats['totalTrips'], context),
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
            value: '${DateFormatter.getMonthInNominative(
                stats['bestMonthNumber'], context)} ${stats['bestYear']}',
            subtitle: '${stats['bestMonthFish']} ${DateFormatter.getFishText(
                stats['bestMonthFish'], context)}',
            valueColor: Colors.amber,
          ),
      ],
    );
  }

  /// НОВЫЙ МЕТОД: Строит карточку с ограничениями политики
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
      padding: const EdgeInsets.all(16),
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
                child: Icon(
                  cardIcon,
                  color: cardColor,
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
                        color: cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restrictions.restrictionMessage,
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
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

  // Метод для определения цвета в зависимости от процента реализации
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
                Icons.menu_rounded, color: AppConstants.textColor, size: 26),
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
          // ИЗМЕНЕНО: Добавлена проверка политики при обновлении
          onRefresh: () async {
            await _checkPolicyCompliance();
            await _loadFishingNotes();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              // Уменьшил отступы по краям с 12 до 8
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Блок с рекламой канала YouTube
                  _buildYoutubePromoCard(),

                  const SizedBox(height: 16),

                  // Новый блок быстрых действий
                  _buildQuickActionsGrid(),

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
                  const SizedBox(height: 90),
                  // Высота равна высоте bottomNavigationBar
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
        padding: const EdgeInsets.only(bottom: 60), // Добавляем отступ снизу для системных кнопок
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
                          // Только логотип без контейнера
                          Image.asset(
                            'assets/images/drawer_logo.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
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

                    // ДОБАВЛЕНО: Проверяем ограничения перед редактированием профиля
                    if (_policyRestrictions?.canEditProfile != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              localizations.translate('edit_profile_blocked') ??
                                  'Редактирование профиля заблокировано. Примите политику конфиденциальности.'
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
                      MaterialPageRoute(
                          builder: (context) => const TimersScreen()),
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
    final bottomPadding = MediaQuery
        .of(context)
        .padding
        .bottom;

    return SizedBox(
      height: 90 + bottomPadding,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60 + bottomPadding,
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
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
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

                    // Карта
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
          ),

          // Центральная кнопка (ваш оригинальный стиль)
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
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 80,
                        height: 80,
                      ),
                      // ДОБАВЛЕНО: Показываем индикатор блокировки если создание контента заблокировано
                      if (!_canCreateContent)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
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
}