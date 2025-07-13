// Путь: lib/screens/home_screen.dart
// ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ ВЕРСИЯ с реактивностью счетчиков

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 ДОБАВЛЕНО для реактивности
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/firebase_service.dart';
import '../repositories/fishing_note_repository.dart';
import '../repositories/user_repository.dart';
import '../models/fishing_note_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_formatter.dart';
import '../utils/network_utils.dart';
import '../localization/app_localizations.dart';
import '../widgets/center_button_tooltip.dart';
import '../services/user_consent_service.dart';
import '../services/subscription/subscription_service.dart';
import '../constants/subscription_constants.dart';
import '../widgets/user_agreements_dialog.dart';
import '../widgets/subscription/usage_badge.dart';
import '../widgets/subscription/premium_create_button.dart';
import '../providers/subscription_provider.dart'; // 🔥 ДОБАВЛЕНО для реактивности
// ДОБАВЛЕНО: Импорт PaywallScreen
import 'subscription/paywall_screen.dart';
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
import 'budget/fishing_budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _firebaseService = FirebaseService();
  final _fishingNoteRepository = FishingNoteRepository();
  final _userRepository = UserRepository();
  final _subscriptionService = SubscriptionService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<FishingNoteModel> _fishingNotes = [];
  bool _hasNewNotifications = true;

  // Переменные для системы принудительного принятия политики
  ConsentRestrictionResult? _policyRestrictions;
  bool _hasPolicyBeenChecked = false;

  // ===== НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ ОФЛАЙН РЕЖИМА =====
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _offlineAuthStatus;
  bool _hasNetworkConnection = true;
  String? _offlineStatusMessage;

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Переменные для кэширования состояния подписки с ОФЛАЙН проверкой
  SubscriptionStatus _cachedSubscriptionStatus = SubscriptionStatus.none;
  bool _hasPremiumAccess = false;
  bool _subscriptionDataLoaded = false;
  bool? _cachedCanCreateContent; // 🚨 НОВОЕ: Кэшируем результат офлайн проверки лимитов
  int? _cachedTotalUsage; // 🚨 НОВОЕ: Кэшируем общее использование (серверное + офлайн)
  int? _cachedLimit; // 🚨 НОВОЕ: Кэшируем лимит

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

  // ДОБАВЛЕНО: Вычисление адаптивного отступа для Drawer
  double get _drawerBottomPadding {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    // Используем только высоту навигации + безопасная зона + минимальный буфер
    return _navBarHeight + bottomSafeArea + 8.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ===== НОВОЕ: Инициализация с поддержкой офлайн режима =====
    _initializeOfflineMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ===== НОВОЕ: Отслеживание когда приложение возвращается в фокус =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Когда пользователь возвращается в приложение, обновляем заметки
      debugPrint('🔄 Приложение вернулось в фокус - обновляем заметки');
      _loadFishingNotes();

      // 🔥 КРИТИЧЕСКИ ВАЖНО: Обновляем данные Provider при возврате в приложение
      _refreshProviderData();
    }
  }

  // 🔥 НОВЫЙ МЕТОД: Обновление данных Provider
  Future<void> _refreshProviderData() async {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.refreshUsageData();
      debugPrint('✅ HomeScreen: Provider обновлен при возврате в приложение');
    } catch (e) {
      debugPrint('❌ HomeScreen: Ошибка обновления Provider: $e');
    }
  }

  // ===== НОВЫЙ МЕТОД: Инициализация офлайн режима =====
  Future<void> _initializeOfflineMode() async {
    try {
      debugPrint('🚀 Инициализация HomeScreen с поддержкой офлайн режима...');

      // Проверяем подключение к сети
      _hasNetworkConnection = await NetworkUtils.isNetworkAvailable();
      debugPrint('🌐 Состояние сети: ${_hasNetworkConnection ? "онлайн" : "офлайн"}');

      if (_hasNetworkConnection) {
        // Онлайн режим
        await _initializeOnlineMode();
      } else {
        // Офлайн режим
        await _initializeOfflineOnly();
      }

      // Получаем статус офлайн авторизации
      _offlineAuthStatus = await _firebaseService.getOfflineAuthStatus();
      _isOfflineMode = _firebaseService.isOfflineMode;

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Загружаем данные подписки ОДИН РАЗ с офлайн проверкой
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

      // Fallback: пытаемся загрузить хотя бы кэшированные данные
      await _loadDataWithFallback();
      await _loadFishingNotes();

      _isInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Загрузка данных подписки с офлайн проверкой лимитов
  Future<void> _loadSubscriptionDataWithOfflineCheck() async {
    try {
      debugPrint('🔄 Загрузка данных подписки с офлайн проверкой...');

      // Загружаем текущую подписку
      final subscription = await _subscriptionService.loadCurrentSubscription();

      // Обновляем кэшированные данные
      _cachedSubscriptionStatus = subscription.status;
      _hasPremiumAccess = _subscriptionService.hasPremiumAccess();

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Получаем ОБЩЕЕ использование (серверное + офлайн)
      _cachedTotalUsage = await _subscriptionService.getCurrentOfflineUsage(ContentType.fishingNotes);
      _cachedLimit = _subscriptionService.getLimit(ContentType.fishingNotes);

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Проверяем возможность создания с учетом офлайн лимитов
      _cachedCanCreateContent = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

      _subscriptionDataLoaded = true;

      debugPrint('✅ Данные подписки загружены: $_cachedSubscriptionStatus, Premium: $_hasPremiumAccess');
      debugPrint('🔍 ПРОВЕРКА ЛИМИТОВ: usage=$_cachedTotalUsage, limit=$_cachedLimit, canCreate=$_cachedCanCreateContent');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки данных подписки: $e');
      _subscriptionDataLoaded = true; // Отмечаем как загруженные даже при ошибке
    }
  }

  // ===== НОВЫЙ МЕТОД: Инициализация онлайн режима =====
  Future<void> _initializeOnlineMode() async {
    try {
      debugPrint('🌐 Инициализация онлайн режима...');

      // Кэшируем данные подписки при онлайн режиме
      await _subscriptionService.cacheSubscriptionDataOnline();

      // Переключаемся в онлайн режим если были офлайн
      if (_firebaseService.isOfflineMode) {
        await _firebaseService.switchToOnlineMode();
      }

      debugPrint('✅ Онлайн режим инициализирован');

    } catch (e) {
      debugPrint('❌ Ошибка при инициализации онлайн режима: $e');
      // Продолжаем работу с кэшированными данными
    }
  }

  // ===== НОВЫЙ МЕТОД: Инициализация только офлайн режима =====
  Future<void> _initializeOfflineOnly() async {
    try {
      debugPrint('📱 Инициализация офлайн режима...');

      // Пытаемся инициализировать приложение с поддержкой офлайн
      final initialized = await _firebaseService.initializeWithOfflineSupport();

      if (initialized) {
        _isOfflineMode = true;
        _offlineStatusMessage = 'Работаете в офлайн режиме';
        debugPrint('✅ Офлайн режим активирован');
      } else {
        _offlineStatusMessage = 'Нет подключения к интернету';
        debugPrint('⚠️ Офлайн режим недоступен');
      }

    } catch (e) {
      debugPrint('❌ Ошибка при инициализации офлайн режима: $e');
      _offlineStatusMessage = 'Ошибка подключения';
    }
  }

  // ===== НОВЫЙ МЕТОД: Загрузка данных с fallback на кэш =====
  Future<void> _loadDataWithFallback() async {
    try {
      debugPrint('📊 Загрузка данных с fallback на кэш...');

      if (_hasNetworkConnection) {
        // Онлайн: загружаем с сервера и кэшируем
        debugPrint('🌐 Загрузка данных с сервера...');
        // Здесь можно добавить загрузку других данных профиля если нужно

      } else {
        // Офлайн: загружаем из кэша
        debugPrint('💾 Загрузка данных из кэша...');
        // Данные пользователя уже загружены через FirebaseService
      }

      debugPrint('✅ Данные загружены успешно');

    } catch (e) {
      debugPrint('❌ Ошибка при загрузке данных: $e');
      // Продолжаем работу с доступными данными
    }
  }

  // ===== НОВЫЙ МЕТОД: Показ статуса офлайн режима =====
  void _showOfflineStatusIfNeeded() {
    if (!_hasNetworkConnection || _isOfflineMode) {
      final localizations = AppLocalizations.of(context);

      // Показываем снэкбар только один раз при инициализации
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

  // ===== НОВЫЙ МЕТОД: Обновление подключения =====
  Future<void> _refreshConnection() async {
    try {
      debugPrint('🔄 Проверка подключения...');

      final hasConnection = await NetworkUtils.isNetworkAvailable();

      if (hasConnection != _hasNetworkConnection) {
        _hasNetworkConnection = hasConnection;

        if (_hasNetworkConnection) {
          // Восстановлено подключение
          debugPrint('🌐 Подключение восстановлено');
          await _initializeOnlineMode();

          // Перезагружаем данные подписки
          await _loadSubscriptionDataWithOfflineCheck();

          // 🔥 КРИТИЧЕСКИ ВАЖНО: Обновляем Provider при восстановлении сети
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

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Проверка возможности создания контента с кэшированными данными
  bool _canCreateContentCached() {
    // Проверяем политику
    final policyAllows = _policyRestrictions?.canCreateContent ?? true;
    if (!policyAllows) {
      return false;
    }

    // 🚨 ИСПРАВЛЕНО: Используем кэшированный результат офлайн проверки
    return _cachedCanCreateContent ?? false;
  }

  // ИСПРАВЛЕНО: Единый метод для показа PaywallScreen
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

  // 🚨 ИСПРАВЛЕНО: Показ сообщений о блокировке с правильными диалогами
  Future<void> _showContentCreationBlocked() async {
    final localizations = AppLocalizations.of(context);

    // Сначала проверяем политику
    if (_policyRestrictions?.canCreateContent != true) {
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

    // 🚨 ИСПРАВЛЕНО: Затем проверяем лимиты и показываем PaywallScreen
    final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);
    if (!canCreate) {
      _showPremiumRequired(ContentType.fishingNotes);
    }
  }

  // ===== КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Перезагрузка заметок после создания =====
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
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
    }
  }

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Навигация с проверкой офлайн лимитов и обновлением Provider
  Future<void> _navigateToAddNote() async {
    // 🚨 ИСПРАВЛЕНО: Проверяем политику
    if (!(_policyRestrictions?.canCreateContent ?? true)) {
      await _showContentCreationBlocked();
      return;
    }

    // 🚨 ИСПРАВЛЕНО: Проверяем офлайн лимиты перед навигацией
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

    // 🔥 КРИТИЧЕСКИ ВАЖНО: Обновляем данные Provider'а после возврата
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.refreshUsageData();
      debugPrint('✅ HomeScreen: Данные Provider обновлены после создания заметки');
    } catch (e) {
      debugPrint('❌ HomeScreen: Ошибка обновления Provider: $e');
    }

    // ИСПРАВЛЕНИЕ: ВСЕГДА обновляем заметки после возврата с экрана создания
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

  // ИСПРАВЛЕНО: АДАПТИВНАЯ сетка быстрых действий без обрезания + НОВЫЕ КНОПКИ
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
        // ИСПРАВЛЕНО: Маркерные карты БЕЗ проверки лимитов - всегда доступны для просмотра
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
        // ИСПРАВЛЕНО: Бюджет БЕЗ проверки лимитов - всегда доступен для просмотра
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

  // ИСПРАВЛЕНО: Элемент быстрого действия с адаптивным текстом
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
              height: isTablet ? 70 : 60,
              child: Icon(
                icon,
                color: AppConstants.textColor,
                size: isTablet ? 60 : 50,
              ),
            ),
            const SizedBox(height: 8),
            // ИСПРАВЛЕНО: Адаптивный контейнер для текста
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

  // ИСПРАВЛЕНО: Метод статистики БЕЗ карточки подписки (она перемещена выше)
  Widget _buildStatsGrid() {
    final localizations = AppLocalizations.of(context);

    final now = DateTime.now();
    final validNotes = _fishingNotes
        .where((note) => note.date.isBefore(now) || note.date.isAtSameMomentAs(now))
        .toList();

    final stats = _calculateStatistics(validNotes);

    return Column(
      children: [
        // УДАЛЕНО: Карточки политики и подписки перемещены выше
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

  // 🚨 ПОЛНОСТЬЮ ЗАМЕНЕНО: Карточка статуса подписки с Consumer для реактивности
  Widget _buildSubscriptionStatusCard() {
    final localizations = AppLocalizations.of(context);

    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Если данные подписки еще не загружены, показываем загрузку
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

        // ИСПРАВЛЕНО: Скрываем карточку для премиум пользователей
        if (subscriptionProvider.hasPremiumAccess) {
          return const SizedBox.shrink();
        }

        // Показываем лимиты только для бесплатных пользователей
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

              // 🔥 ИСПРАВЛЕНО: Реактивные прогресс-бары с данными Provider
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
              _buildUsageProgressBar(
                subscriptionProvider,
                ContentType.expenses,
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

  // 🔥 НОВЫЙ МЕТОД: Прогресс-бар использования с реактивными данными Provider
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

  // ===== НОВЫЙ ВИДЖЕТ: Индикатор офлайн статуса =====
  Widget _buildOfflineStatusIndicator() {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context);

    // Показываем только если есть проблемы с подключением или активен офлайн режим
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
                // Показываем информацию о сроке действия офлайн режима
                if (_isOfflineMode && _offlineAuthStatus != null && _offlineAuthStatus!['daysUntilExpiry'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Действует ${_offlineAuthStatus!['daysUntilExpiry']} дней',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: fontSize - 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Кнопка обновления подключения
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
          // 🚨 ИСПРАВЛЕНИЕ: Заголовок с реактивными данными через Consumer
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
                  // ===== НОВОЕ: Индикатор офлайн режима =====
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
                  // 🚨 ИСПРАВЛЕНИЕ: Реактивный бейдж статуса подписки
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
            // ===== ОБНОВЛЕНО: Обновление с проверкой подключения и Provider =====
            await _refreshConnection();
            await _checkPolicyCompliance();
            await _loadSubscriptionDataWithOfflineCheck();
            await _loadFishingNotes();

            // 🔥 КРИТИЧЕСКИ ВАЖНО: Обновляем Provider при pull-to-refresh
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

                  // ===== НОВОЕ: Индикатор офлайн статуса =====
                  _buildOfflineStatusIndicator(),

                  // ДОБАВЛЕНО: Карточки ограничений и подписки НАД статистикой
                  if (_policyRestrictions?.hasRestrictions == true)
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

  // ИСПРАВЛЕНО: Drawer с адаптивным отступом снизу и реактивными данными
  Widget _buildDrawer() {
    final localizations = AppLocalizations.of(context);
    final user = _firebaseService.currentUser;
    final userName = user?.displayName ?? localizations.translate('user');
    final userEmail = user?.email ?? '';

    return Drawer(
      child: Container(
        color: AppConstants.backgroundColor,
        // ИСПРАВЛЕНО: Используем адаптивный отступ вместо фиксированного
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
                      // ===== НОВОЕ: Индикатор офлайн режима в drawer =====
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
                  // ✅ ИСПРАВЛЕНО: Всегда обновляем при возврате из списка заметок
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
                  // ✅ ИСПРАВЛЕНО: Обновляем Provider при возврате из маркерных карт
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
                  // ✅ ДОБАВЛЕНО: Обновляем Provider при возврате из бюджета
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

  // 🚨 ПОЛНОСТЬЮ ИСПРАВЛЕНО: Нижняя навигация с реактивной центральной кнопкой
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

          // 🚨 ПОЛНОСТЬЮ ИСПРАВЛЕНА: Центральная кнопка с реактивными данными через Consumer
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
                        if (!(_policyRestrictions?.canCreateContent ?? true))
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
                        // 🚨 ИСПРАВЛЕНО: Реактивный индикатор лимитов (оранжевый замок)
                        if ((_policyRestrictions?.canCreateContent ?? true) &&
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
                        // 🚨 ИСПРАВЛЕНО: Реактивный мини-бейдж использования
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
                        // ===== НОВОЕ: Индикатор офлайн режима на центральной кнопке =====
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