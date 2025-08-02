// Путь: lib/screens/home_screen.dart
// ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ ВЕРСИЯ с реактивностью счетчиков

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/firebase_service.dart';
import '../repositories/fishing_note_repository.dart';
import '../repositories/user_repository.dart';
import '../models/fishing_note_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_formatter.dart';
import '../utils/network_utils.dart';
import '../localization/app_localizations.dart';
import '../widgets/center_button_tooltip.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';
import '../mixins/policy_enforcement_mixin.dart';
import 'subscription/paywall_screen.dart';
import 'timer/timers_screen.dart';
import 'fishing_note/fishing_type_selection_screen.dart';
import 'fishing_note/fishing_notes_list_screen.dart';
import 'calendar/fishing_calendar_screen.dart';
import 'profile/profile_screen.dart';
import 'map/universal_map_screen.dart';
import 'notifications/notifications_screen.dart';
import 'statistics/statistics_screen.dart';
import 'marker_maps/marker_maps_list_screen.dart';
import 'settings/settings_screen.dart';
import 'weather/weather_screen.dart';
import 'tournaments/tournaments_screen.dart';
import 'shops/shops_screen.dart';
import 'budget/fishing_budget_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, PolicyEnforcementMixin {
  final _firebaseService = FirebaseService();
  final _fishingNoteRepository = FishingNoteRepository();
  final _userRepository = UserRepository();
  final _subscriptionService = SubscriptionService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<FishingNoteModel> _fishingNotes = [];
  bool _hasNewNotifications = true;

  // ✅ ИСПРАВЛЕНО: Упрощенные переменные для системы согласий
  bool _hasPolicyBeenChecked = false;
  bool _policyAccepted = true; // По умолчанию считаем что политика принята

  // Переменные для офлайн режима
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  bool _hasNetworkConnection = true;
  String? _offlineStatusMessage;

  // Переменные для кэширования состояния подписки
  SubscriptionStatus _cachedSubscriptionStatus = SubscriptionStatus.none;
  bool _hasPremiumAccess = false;
  bool _subscriptionDataLoaded = false;
  bool? _cachedCanCreateContent;
  int? _cachedTotalUsage;
  int? _cachedLimit;

  int _selectedIndex = 2; // Центральная кнопка (рыбка) по умолчанию выбрана

  // Фиксированные размеры навигации
  static const double _navBarHeight = 60.0;
  static const double _centerButtonSize = 80.0;
  static const double _navIconSize = 22.0;
  static const double _navTextSize = 10.0;
  static const double _navItemMinTouchTarget = 48.0;

  // Фиксированные размеры AppBar
  static const double _appBarHeight = kToolbarHeight;
  static const double _appBarTitleSize = 24.0;
  static const double _appBarIconSize = 26.0;

  // Адаптивные утилиты
  bool get isTablet => MediaQuery.of(context).size.width >= 768;
  double get screenWidth => MediaQuery.of(context).size.width;
  double get horizontalPadding => isTablet ? 32.0 : 16.0;
  double get cardPadding => isTablet ? 20.0 : 16.0;
  double get iconSize => isTablet ? 28.0 : 24.0;
  double get fontSize => isTablet ? 18.0 : 16.0;
  double get buttonHeight => isTablet ? 56.0 : 48.0;
  int get gridColumns => isTablet ? 4 : 2;

  double get _drawerBottomPadding {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    return _navBarHeight + bottomSafeArea + 8.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOfflineMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 Приложение вернулось в фокус - обновляем заметки');
      _loadFishingNotes();
      _refreshProviderData();
    }
  }

  Future<void> _refreshProviderData() async {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.refreshUsageData();
      debugPrint('✅ HomeScreen: Provider обновлен при возврате в приложение');
    } catch (e) {
      debugPrint('❌ HomeScreen: Ошибка обновления Provider: $e');
    }
  }

  // ✅ ИСПРАВЛЕНО: Инициализация офлайн режима без отсутствующих методов
  Future<void> _initializeOfflineMode() async {
    try {
      debugPrint('🚀 Инициализация HomeScreen с поддержкой офлайн режима...');

      // ✅ ДОБАВИТЬ ЭТИ ДВЕ СТРОКИ:
      _subscriptionService.setFirebaseService(_firebaseService);
      debugPrint('🔗 FirebaseService установлен в SubscriptionService');

      // ✅ ДОБАВЬТЕ ЭТИ 2 СТРОКИ:
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.setFirebaseService(_firebaseService);

      // Проверяем подключение к сети
      _hasNetworkConnection = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${_hasNetworkConnection ? "онлайн" : "офлайн"}');


      if (_hasNetworkConnection) {
        // ✅ ДОБАВЬТЕ ЭТИ 2 СТРОКИ:
        await subscriptionProvider.updateCacheAfterAuth();
        debugPrint('✅ Кэш обновлен после инициализации');

        await _initializeOnlineMode();
      } else {
        // ✅ ДОБАВЬТЕ ЭТИ 2 СТРОКИ:
        await subscriptionProvider.refreshUsageDataOffline();
        debugPrint('✅ Данные обновлены для офлайн режима');

        await _initializeOfflineOnly();
      }

      // ✅ ИСПРАВЛЕНО: Убрано обращение к несуществующему методу getOfflineAuthStatus
      _isOfflineMode = _firebaseService.isOfflineMode;

      // Загружаем данные подписки с офлайн проверкой
      await _loadSubscriptionDataWithOfflineCheck();

      // Загружаем данные с fallback на кэш
      await _loadDataWithFallback();

      // Загружаем заметки
      await _loadFishingNotes();

      // Синхронизируем офлайн данные
      await _fishingNoteRepository.syncOfflineDataOnStartup();

      _isInitialized = true;

      if (mounted) {
        setState(() {});
        _showOfflineStatusIfNeeded();
      }

      debugPrint('✅ Инициализация завершена успешно');

    } catch (e) {
      debugPrint('❌ Ошибка при инициализации: $e');

      await _loadDataWithFallback();
      await _loadFishingNotes();

      _isInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Загрузка данных подписки без getCurrentOfflineUsage
  Future<void> _loadSubscriptionDataWithOfflineCheck() async {
    try {
      debugPrint('🔄 Загрузка данных подписки с офлайн проверкой...');

      final subscription = await _subscriptionService.loadCurrentSubscription();

      _cachedSubscriptionStatus = subscription.status;
      _hasPremiumAccess = _subscriptionService.hasPremiumAccess();

      // ✅ ИСПРАВЛЕНО: Используем существующий метод getCurrentUsage
      _cachedTotalUsage = await _subscriptionService.getCurrentUsage(ContentType.fishingNotes);
      _cachedLimit = _subscriptionService.getLimit(ContentType.fishingNotes);

      _cachedCanCreateContent = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

      _subscriptionDataLoaded = true;

      debugPrint('✅ Данные подписки загружены: $_cachedSubscriptionStatus, Premium: $_hasPremiumAccess');
      debugPrint('🔍 ПРОВЕРКА ЛИМИТОВ: usage=$_cachedTotalUsage, limit=$_cachedLimit, canCreate=$_cachedCanCreateContent');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки данных подписки: $e');
      _subscriptionDataLoaded = true;
    }
  }

  Future<void> _initializeOnlineMode() async {
    try {
      debugPrint('🌐 Инициализация онлайн режима...');

      await _subscriptionService.cacheSubscriptionDataOnline();

      if (_firebaseService.isOfflineMode) {
        await _firebaseService.switchToOnlineMode();
      }

      debugPrint('✅ Онлайн режим инициализирован');

    } catch (e) {
      debugPrint('❌ Ошибка при инициализации онлайн режима: $e');
    }
  }

  // ✅ ИСПРАВЛЕНО: Инициализация офлайн режима без initializeWithOfflineSupport
  Future<void> _initializeOfflineOnly() async {
    try {
      debugPrint('📱 Инициализация офлайн режима...');

      // ✅ ИСПРАВЛЕНО: Проверяем офлайн режим через существующие методы
      final canAuthOffline = await _firebaseService.canAuthenticateOffline();

      if (canAuthOffline) {
        final offlineSuccess = await _firebaseService.tryOfflineAuthentication();

        if (offlineSuccess) {
          _isOfflineMode = true;
          _offlineStatusMessage = 'Работаете в офлайн режиме';
          debugPrint('✅ Офлайн режим активирован');
        } else {
          _offlineStatusMessage = 'Офлайн авторизация недоступна';
          debugPrint('⚠️ Офлайн авторизация не удалась');
        }
      } else {
        _offlineStatusMessage = 'Нет подключения к интернету';
        debugPrint('⚠️ Офлайн режим недоступен');
      }

    } catch (e) {
      debugPrint('❌ Ошибка при инициализации офлайн режима: $e');
      _offlineStatusMessage = 'Ошибка подключения';
    }
  }

  Future<void> _loadDataWithFallback() async {
    try {
      debugPrint('📊 Загрузка данных с fallback на кэш...');

      if (_hasNetworkConnection) {
        debugPrint('🌐 Загрузка данных с сервера...');
      } else {
        debugPrint('💾 Загрузка данных из кэша...');
      }

      debugPrint('✅ Данные загружены успешно');

    } catch (e) {
      debugPrint('❌ Ошибка при загрузке данных: $e');
    }
  }

  void _showOfflineStatusIfNeeded() {
    if (!_hasNetworkConnection || _isOfflineMode) {
      final localizations = AppLocalizations.of(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    _isOfflineMode ? Icons.offline_bolt : Icons.wifi_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _offlineStatusMessage ??
                          localizations.translate('offline_mode_active') ??
                          'Офлайн режим активен',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: _isOfflineMode ? Colors.blue : Colors.orange,
              duration: const Duration(seconds: 4),
              action: !_hasNetworkConnection ? SnackBarAction(
                label: localizations.translate('retry') ?? 'Повторить',
                textColor: Colors.white,
                onPressed: () => _refreshConnection(),
              ) : null,
            ),
          );
        }
      });
    }
  }

  Future<void> _refreshConnection() async {
    try {
      debugPrint('🔄 Проверка подключения...');

      final hasConnection = await NetworkUtils.isNetworkAvailable();

      if (hasConnection != _hasNetworkConnection) {
        _hasNetworkConnection = hasConnection;

        if (_hasNetworkConnection) {
          debugPrint('🌐 Подключение восстановлено');
          await _initializeOnlineMode();

          // ✅ ДОБАВИТЬ ЭТИ СТРОКИ:
          _isOfflineMode = false; // Выключаем офлайн режим
          _offlineStatusMessage = null; // Очищаем сообщение
          await _loadSubscriptionDataWithOfflineCheck();
          await _refreshProviderData();

          if (mounted) {
            final localizations = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      localizations.translate('connection_restored') ??
                          'Подключение восстановлено',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        if (mounted) {
          setState(() {});
        }
      }

    } catch (e) {
      debugPrint('❌ Ошибка при проверке подключения: $e');
    }
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

  // ✅ ИСПРАВЛЕНО: Используем PolicyEnforcementMixin
  Future<void> _checkPolicyCompliance() async {
    try {
      if (!mounted) return;

      debugPrint('🔍 Проверка политики через PolicyEnforcementMixin...');

      // ✅ ИСПРАВЛЕНО: правильное название метода
      await checkPolicyCompliance();

      // ✅ Получаем статус из mixin
      _policyAccepted = consentsValid;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке политики: $e');
      _policyAccepted = false;
    }
  }


  Future<void> _refreshPolicyStatus() async {
    if (!mounted) return;

    try {
      // ✅ ИСПРАВЛЕНО: используем метод из mixin
      await recheckConsents();
      _policyAccepted = consentsValid;

      if (mounted) {
        setState(() {});
      }

      debugPrint('🔄 Статус политики обновлен: $_policyAccepted');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении статуса политики: $e');
      _policyAccepted = false;
    }
  }

  // ✅ ДОБАВЬТЕ ЭТО:
  Future<void> _showPolicyUpdateDialog() async {
    await _checkPolicyCompliance();
  }

  // ✅ ИСПРАВЛЕНО: Упрощенная проверка возможности создания контента
  bool _canCreateContentCached() {
    // Проверяем политику
    if (!_policyAccepted) {
      return false;
    }

    // Используем кэшированный результат офлайн проверки
    return _cachedCanCreateContent ?? false;
  }

  void _showPremiumRequired(ContentType contentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: contentType.name,
        ),
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: Упрощенные сообщения о блокировке
  Future<void> _showContentCreationBlocked() async {
    final localizations = AppLocalizations.of(context);

    // Сначала проверяем политику
    if (!_policyAccepted) {
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
      return;
    }

    // Затем проверяем лимиты и показываем PaywallScreen
    final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);
    if (!canCreate) {
      _showPremiumRequired(ContentType.fishingNotes);
    }
  }

  Future<void> _loadFishingNotes() async {
    try {
      debugPrint('📝 Загрузка заметок о рыбалке...');

      final notes = await _fishingNoteRepository.getUserFishingNotes();

      if (mounted) {
        setState(() {
          _fishingNotes = notes;
        });
      }

      debugPrint('✅ Загружено ${notes.length} заметок');

    } catch (e) {
      debugPrint('❌ Ошибка при загрузке заметок: $e');

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('loading_error')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: localizations.translate('retry') ?? 'Повторить',
              textColor: Colors.white,
              onPressed: () => _loadFishingNotes(),
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
          MaterialPageRoute(
            builder: (context) => const UniversalMapScreen(
              mode: MapMode.homeView,
            ),
          ),
        );
        break;
    }
  }

  Future<void> _navigateToAddNote() async {
    // Проверяем политику
    if (!_policyAccepted) {
      await _showContentCreationBlocked();
      return;
    }

    // Проверяем офлайн лимиты перед навигацией
    final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);
    if (!canCreate) {
      _showPremiumRequired(ContentType.fishingNotes);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishingTypeSelectionScreen(),
      ),
    );

    // Обновляем данные Provider'а после возврата
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.refreshUsageData();
      debugPrint('✅ HomeScreen: Данные Provider обновлены после создания заметки');
    } catch (e) {
      debugPrint('❌ HomeScreen: Ошибка обновления Provider: $e');
    }

    // Всегда обновляем заметки после возврата с экрана создания
    debugPrint('🔄 Возврат с экрана создания заметки, обновляем список...');
    await _loadFishingNotes();

    // Дополнительно обновляем данные подписки (для счетчиков лимитов)
    await _loadSubscriptionDataWithOfflineCheck();
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

  Widget _buildQuickActionsGrid() {
    final localizations = AppLocalizations.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: gridColumns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      childAspectRatio: isTablet ? 1.1 : 1.0,
      children: [
        _buildQuickActionItem(
          icon: Icons.map_outlined,
          label: localizations.translate('marker_map'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarkerMapsListScreen()),
            );
          },
        ),
        _buildQuickActionItem(
          icon: Icons.account_balance_wallet_outlined,
          label: localizations.translate('fishing_budget'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FishingBudgetScreen()),
            );
          },
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
            Container(
              height: isTablet ? 70 : 60,
              child: Icon(
                icon,
                color: AppConstants.textColor,
                size: isTablet ? 60 : 50,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
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

  Widget _buildSubscriptionStatusCard() {
    final localizations = AppLocalizations.of(context);

    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        if (subscriptionProvider.isLoading) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (subscriptionProvider.hasPremiumAccess) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppConstants.primaryColor,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('free_plan'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.translate('limited_access'),
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: fontSize - 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildUsageProgressBar(
                subscriptionProvider,
                ContentType.fishingNotes,
                localizations.translate('fishing_notes'),
              ),
              const SizedBox(height: 12),
              _buildUsageProgressBar(
                subscriptionProvider,
                ContentType.markerMaps,
                localizations.translate('marker_maps'),
              ),
              const SizedBox(height: 12),
              // ✅ ИСПРАВЛЕНО: ContentType.expenses → ContentType.budgetNotes
              _buildUsageProgressBar(
                subscriptionProvider,
                ContentType.budgetNotes,
                localizations.translate('fishing_budget'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: buttonHeight + 4,
                child: ElevatedButton(
                  onPressed: () {
                    _showPremiumRequired(ContentType.fishingNotes);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    localizations.translate('upgrade_to_premium'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageProgressBar(
      SubscriptionProvider provider,
      ContentType contentType,
      String label,
      ) {
    final currentUsage = provider.getUsage(contentType) ?? 0;
    final limit = provider.getLimit(contentType) ?? 0;
    final progress = limit > 0 ? (currentUsage / limit).clamp(0.0, 1.0) : 0.0;
    final color = provider.getUsageIndicatorColor(contentType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                provider.getUsageText(contentType),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: Упрощенная карточка политики без удаленных классов
  Widget _buildPolicyRestrictionCard() {
    if (_policyAccepted) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber, color: Colors.orange, size: iconSize),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('policy_required') ?? 'Требуется принятие политики',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.translate('accept_policy_to_continue') ?? 'Примите политику конфиденциальности для продолжения работы',
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
                backgroundColor: Colors.orange,
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

  Widget _buildOfflineStatusIndicator() {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context);

    if (_hasNetworkConnection && !_isOfflineMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _isOfflineMode ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOfflineMode ? Colors.blue : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isOfflineMode ? Colors.blue : Colors.orange).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isOfflineMode ? Icons.offline_bolt : Icons.wifi_off,
              color: _isOfflineMode ? Colors.blue : Colors.orange,
              size: iconSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOfflineMode
                      ? (localizations.translate('offline_mode') ?? 'Офлайн режим')
                      : (localizations.translate('no_connection') ?? 'Нет подключения'),
                  style: TextStyle(
                    color: _isOfflineMode ? Colors.blue : Colors.orange,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOfflineMode
                      ? (localizations.translate('offline_mode_description') ?? 'Данные сохраняются локально')
                      : (localizations.translate('connection_required') ?? 'Для полной функциональности требуется интернет'),
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: fontSize - 2,
                  ),
                ),
              ],
            ),
          ),
          if (!_hasNetworkConnection)
            IconButton(
              onPressed: _refreshConnection,
              icon: const Icon(Icons.refresh),
              color: Colors.orange,
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
          title: Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Drift Notes',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: _appBarTitleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isOfflineMode || !_hasNetworkConnection)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isOfflineMode ? Colors.blue : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOfflineMode ? Icons.offline_bolt : Icons.wifi_off,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isOfflineMode ? 'OFF' : 'NO NET',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (subscriptionProvider.hasPremiumAccess)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: _appBarHeight,
          leading: IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppConstants.textColor,
              size: _appBarIconSize,
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
                    size: _appBarIconSize,
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
            await _refreshConnection();
            await _checkPolicyCompliance();
            await _loadSubscriptionDataWithOfflineCheck();
            await _loadFishingNotes();
            await _refreshProviderData();
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

                  _buildOfflineStatusIndicator(),
                  if (!_policyAccepted)
                    _buildPolicyRestrictionCard(),
                  _buildSubscriptionStatusCard(),

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
                  SizedBox(height: _navBarHeight + (_centerButtonSize / 2) + 80),
                ],
              ),
            ),
          ),
        ),
        extendBody: false,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

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
        padding: EdgeInsets.only(bottom: _drawerBottomPadding),
        child: ListView(
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
                      if (_isOfflineMode || !_hasNetworkConnection)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOfflineMode ? Colors.blue : Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isOfflineMode ? Icons.offline_bolt : Icons.wifi_off,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOfflineMode
                                    ? (localizations.translate('offline_mode') ?? 'Офлайн режим')
                                    : (localizations.translate('no_connection') ?? 'Нет сети'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Image.asset(
                        'assets/images/drawer_logo.png',
                        width: 110.0,
                        height: 110.0,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 20.0,
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
                          fontSize: 14.0,
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
                // ✅ ИСПРАВЛЕНО: Упрощенная проверка политики
                if (!_policyAccepted) {
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
                  _loadFishingNotes();
                  _refreshProviderData();
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
                ).then((_) {
                  _refreshProviderData();
                });
              },
            ),

            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              title: localizations.translate('fishing_budget'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FishingBudgetScreen()),
                ).then((_) {
                  _refreshProviderData();
                });
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
                  color: Color(0xFFB3B3B3),
                  fontSize: 14.0,
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
      leading: Icon(icon, color: AppConstants.textColor, size: 22.0),
      title: Text(
        title,
        style: TextStyle(color: AppConstants.textColor, fontSize: 16.0),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildBottomNavigationBar() {
    final localizations = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _navBarHeight + (_centerButtonSize / 2) + bottomPadding,
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
                    _buildNavItem(0, Icons.timelapse_rounded, localizations.translate('timer')),
                    _buildNavItem(1, Icons.cloud_queue_rounded, localizations.translate('weather')),
                    Expanded(child: Container()),
                    _buildNavItem(3, Icons.event_note_rounded, localizations.translate('calendar')),
                    _buildNavItem(4, Icons.explore_rounded, localizations.translate('map')),
                  ],
                ),
              ),
            ),
          ),

          // Центральная кнопка с реактивными данными через Consumer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Center(
                child: Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, child) {
                    return Stack(
                      children: [
                        Container(
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
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: _centerButtonSize,
                            height: _centerButtonSize,
                          ),
                        ),
                        // Индикатор политики (красный замок)
                        if (!_policyAccepted)
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
                        // Реактивный индикатор лимитов (оранжевый замок)
                        if (_policyAccepted &&
                            !subscriptionProvider.canCreateContentSync(ContentType.fishingNotes))
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 22.0,
                              height: 22.0,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 14.0,
                              ),
                            ),
                          ),
                        // Реактивный мини-бейдж использования
                        if (subscriptionProvider.canCreateContentSync(ContentType.fishingNotes) &&
                            !subscriptionProvider.hasPremiumAccess)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: subscriptionProvider.getUsageIndicatorColor(ContentType.fishingNotes),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                subscriptionProvider.getUsageText(ContentType.fishingNotes),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Индикатор офлайн режима на центральной кнопке
                        if (_isOfflineMode || !_hasNetworkConnection)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                color: _isOfflineMode ? Colors.blue : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isOfflineMode ? Icons.offline_bolt : Icons.wifi_off,
                                color: Colors.white,
                                size: 12.0,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Container(
        height: _navItemMinTouchTarget,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppConstants.textColor : Colors.white54,
                size: _navIconSize,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _navTextSize,
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