// Путь: lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'screens/splash_screen.dart';
import 'constants/app_constants.dart';
import 'screens/auth/auth_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/help/help_contact_screen.dart';
import 'screens/fishing_note/fishing_type_selection_screen.dart';
import 'screens/fishing_note/fishing_notes_list_screen.dart';
import 'screens/settings/accepted_agreements_screen.dart';
import 'screens/timer/timers_screen.dart';
import 'providers/timer_provider.dart';
import 'providers/language_provider.dart';
import 'providers/subscription_provider.dart';
import 'localization/app_localizations.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'providers/statistics_provider.dart';
import 'services/offline/offline_storage_service.dart';
import 'services/offline/sync_service.dart';
import 'utils/network_utils.dart';
import 'services/weather_notification_service.dart';
import 'services/notification_service.dart';
import 'services/local_push_notification_service.dart';
import 'services/weather_settings_service.dart';
import 'services/firebase/firebase_service.dart';
import 'services/user_consent_service.dart';
import 'services/scheduled_reminder_service.dart';
import 'services/tournament_service.dart';
import 'services/timer/timer_service.dart';
import 'screens/tournaments/tournament_detail_screen.dart';
import 'services/location_service.dart';
// ✅ ОБНОВЛЕНО: Импорты для новых Isar сервисов
import 'services/isar_service.dart';
import 'repositories/fishing_note_repository.dart';
import 'repositories/budget_notes_repository.dart';
import 'repositories/marker_map_repository.dart';

// Глобальная переменная для flutter_local_notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ОПТИМИЗИРОВАНО: Только критические операции для быстрого запуска UI
  await _initializeCriticalOnly();

  // Инициализация LanguageProvider ДО создания приложения
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // ✅ КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ: Запускаем приложение СРАЗУ - остальное в фоне
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimerProvider()),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (context) => SubscriptionProvider()),
      ],
      child: DriftNotesApp(consentService: UserConsentService()),
    ),
  );
}

// ✅ НОВАЯ ФУНКЦИЯ: Только критические операции для быстрого запуска
Future<void> _initializeCriticalOnly() async {
  try {
    // Инициализация локали для форматирования дат
    await initializeDateFormatting('ru_RU', null);
    await initializeDateFormatting('en_US', null);

    // Устанавливаем ориентацию экрана только на портретный режим
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Показываем системную навигацию
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

    // Инициализация Firebase с защитой от дублирования - ТОЛЬКО FIREBASE
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('✅ Критические сервисы инициализированы');
  } catch (e) {
    debugPrint('❌ Ошибка критической инициализации: $e');
  }
}

// ✅ НОВАЯ ФУНКЦИЯ: Асинхронная инициализация всех сервисов в фоне
Future<void> _initializeAllServicesAsync() async {
  try {
    debugPrint('🔄 Начинаем фоновую инициализацию сервисов...');

    // Этап 1: Разрешения и базовые уведомления (критично для работы)
    await _initializeCriticalServices();

    // Этап 2: App Check и debug тесты (важно для безопасности)
    await _initializeSecurityServices();

    // Этап 3: Базы данных и репозитории (параллельно)
    await _initializeDatabaseServices();

    // Этап 4: Сервисы приложения (параллельно с задержками)
    await _initializeApplicationServices();

    // Этап 5: Офлайн сервисы и сеть (последними)
    await _initializeNetworkServices();

    debugPrint('✅ Все сервисы инициализированы успешно');
  } catch (e) {
    debugPrint('❌ Ошибка фоновой инициализации: $e');
  }
}

// Этап 1: Критические сервисы для базовой работы
Future<void> _initializeCriticalServices() async {
  try {
    debugPrint('🔧 Инициализация критических сервисов...');

    // Разрешения на уведомления
    await _requestNotificationPermissions();

    // Базовые уведомления
    await _initializeNotifications();

    debugPrint('✅ Критические сервисы готовы');
  } catch (e) {
    debugPrint('❌ Ошибка критических сервисов: $e');
  }
}

// Этап 2: Сервисы безопасности (асинхронно)
Future<void> _initializeSecurityServices() async {
  try {
    debugPrint('🔐 Инициализация сервисов безопасности...');

    // ✅ ИСПРАВЛЕНО: App Check в микротаске чтобы не блокировать UI
    Future.microtask(() async {
      await _initializeAppCheck();
    });

    // Debug тесты тоже в микротаске
    if (kDebugMode) {
      Future.microtask(() async {
        await _testFirebaseAuthentication();
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.enableNetwork();
        } catch (e) {
          // Silent error handling
        }
      });
    }

    debugPrint('✅ Сервисы безопасности готовы');
  } catch (e) {
    debugPrint('❌ Ошибка сервисов безопасности: $e');
  }
}

// Этап 3: Базы данных (параллельно)
Future<void> _initializeDatabaseServices() async {
  try {
    debugPrint('🗄️ Инициализация баз данных...');

    // Инициализируем все БД параллельно
    final futures = [
      _initializeIsarServices(),
      _initializeOfflineServices(),
    ];

    await Future.wait(futures, eagerError: false);
    debugPrint('✅ Базы данных готовы');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации БД: $e');
  }
}

// Этап 4: Сервисы приложения (все в микротасках)
Future<void> _initializeApplicationServices() async {
  try {
    debugPrint('⚙️ Инициализация сервисов приложения...');

    // ✅ ИСПРАВЛЕНО: Все сервисы в микротасках с задержками
    final criticalServices = [
          () async {
        await Future.delayed(Duration(milliseconds: 10));
        await LocalPushNotificationService().initialize();
      },
          () async {
        await Future.delayed(Duration(milliseconds: 20));
        await NotificationService().initialize();
      },
    ];

    final secondaryServices = [
          () async {
        await Future.delayed(Duration(milliseconds: 30));
        await TimerService().initialize();
      },
          () async {
        await Future.delayed(Duration(milliseconds: 40));
        await WeatherNotificationService().initialize();
      },
          () async {
        await Future.delayed(Duration(milliseconds: 50));
        await WeatherSettingsService().initialize();
      },
          () async {
        await Future.delayed(Duration(milliseconds: 60));
        await ScheduledReminderService().initialize();
      },
          () async {
        await Future.delayed(Duration(milliseconds: 70));
        await LocationService().initialize();
      },
    ];

    // ✅ ИСПРАВЛЕНО: Заменил forEach на обычный for loop
    for (final service in criticalServices) {
      Future.microtask(service);
    }

    for (final service in secondaryServices) {
      Future.microtask(service);
    }

    // Ждем только первые критические (но не блокируем UI)
    await Future.delayed(Duration(milliseconds: 100));

    debugPrint('✅ Сервисы приложения готовы');
  } catch (e) {
    debugPrint('❌ Ошибка сервисов приложения: $e');
  }
}

// Этап 5: Сетевые сервисы
Future<void> _initializeNetworkServices() async {
  try {
    debugPrint('🌐 Инициализация сетевых сервисов...');

    // Запуск мониторинга сети (не блокирующий)
    _startNetworkMonitoring();

    debugPrint('✅ Сетевые сервисы готовы');
  } catch (e) {
    debugPrint('❌ Ошибка сетевых сервисов: $e');
  }
}

// ✅ ИСПРАВЛЕНО: Инициализация Isar сервисов с поддержкой MarkerMap
Future<void> _initializeIsarServices() async {
  try {
    // Инициализация IsarService (теперь поддерживает MarkerMap)
    await IsarService.instance.init();

    // Инициализация репозиториев параллельно
    final repoFutures = [
      FishingNoteRepository().initialize(),
      BudgetNotesRepository().initialize(),
    ];

    await Future.wait(repoFutures, eagerError: false);

    // ✅ ИСПРАВЛЕНО: Инициализация MarkerMapRepository (создадим если нет)
    try {
      await MarkerMapRepository().initialize();
    } catch (e) {
      // Silent error handling - markers may use legacy system
    }

  } catch (e) {
    // Silent error handling for production
  }
}

// ✅ НОВАЯ ФУНКЦИЯ: Правильная инициализация App Check
Future<void> _initializeAppCheck() async {
  try {
    // Настройка провайдеров в зависимости от режима сборки
    if (kDebugMode) {
      // DEBUG режим: Используем Debug Provider для разработки
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } else {
      // RELEASE режим: Используем Play Integrity для продакшена
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    }

    // ✅ ИСПРАВЛЕНО: Убрал неиспользуемую переменную token
    await FirebaseAppCheck.instance.getToken();

  } catch (e) {
    // Silent error handling for production
  }
}

// Инициализация офлайн сервисов (СТАРЫЕ - для совместимости)
Future<void> _initializeOfflineServices() async {
  try {
    final offlineStorage = OfflineStorageService();
    await offlineStorage.initialize();
  } catch (e) {
    // Silent error handling for production
  }
}

// ✅ ИСПРАВЛЕНО: Запуск мониторинга сети с новым SyncService
void _startNetworkMonitoring() {
  try {
    final networkMonitor = NetworkUtils();
    networkMonitor.startNetworkMonitoring();

    networkMonitor.addConnectionListener((isConnected) {
      if (isConnected) {
        // ✅ ИСПРАВЛЕНО: Используем новый SyncService.instance для Isar
        SyncService.instance.fullSync().then((_) {
          // Silent success
        }).catchError((e) {
          // Silent error handling
        });
      }
    });

    // ✅ ИСПРАВЛЕНО: Запускаем периодическую синхронизацию через новый SyncService
    SyncService.instance.startPeriodicSync();

  } catch (e) {
    // Silent error handling for production
  }
}

// Функция для тестирования Firebase Authentication
Future<void> _testFirebaseAuthentication() async {
  if (!kDebugMode) return;

  try {
    final auth = FirebaseAuth.instance;

    // ✅ ИСПРАВЛЕНО: Убрал неиспользуемую переменную currentUser
    auth.currentUser;

    // 🔥 ИСПРАВЛЕНО: Убрали deprecated fetchSignInMethodsForEmail
    // Этот метод устарел по соображениям безопасности (защита от перечисления email)
    // Для debug целей достаточно проверить, что Auth инициализирован

    // Проверяем что Firebase Auth доступен
    if (auth.app.name.isNotEmpty) {
      // Firebase Auth успешно инициализирован
    }

  } catch (e) {
    // Silent error handling
  }
}

// Функция для запроса разрешений на уведомления
Future<void> _requestNotificationPermissions() async {
  try {
    if (Platform.isAndroid) {
      // Для Android 13+ запрашиваем разрешение на уведомления
      await Permission.notification.request();

      // Запрашиваем разрешение на точные будильники
      if (Platform.isAndroid) {
        try {
          await Permission.scheduleExactAlarm.request();
        } catch (e) {
          // Silent error handling - not supported on all Android versions
        }
      }
    } else if (Platform.isIOS) {
      // Для iOS запрашиваем разрешение через flutter_local_notifications
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
    }
  } catch (e) {
    // Silent error handling for production
  }
}

// Функция для инициализации flutter_local_notifications
Future<void> _initializeNotifications() async {
  try {
    // Настройки для Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // Настройки для iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    // Общие настройки инициализации
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    // Инициализируем плагин с обработчиком нажатий
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Создаем канал уведомлений для Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  } catch (e) {
    // Silent error handling for production
  }
}

// Создание канала уведомлений для Android
Future<void> _createNotificationChannel() async {
  try {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'timer_channel', // id
      'Таймеры рыбалки', // name
      description: 'Уведомления о завершении таймеров рыбалки',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2E7D32),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    // Silent error handling for production
  }
}

// Обработчик нажатий на уведомления
void _onNotificationTap(NotificationResponse notificationResponse) {
  try {
    if (notificationResponse.payload != null) {
      final payload = notificationResponse.payload!;

      try {
        final payloadData = json.decode(payload);
        final notificationType = payloadData['type'];

        if (notificationType == 'timer_finished') {
          // Навигируем к экрану таймеров
          _navigateToTimers();
        }
      } catch (e) {
        // Silent error handling for malformed payload
      }
    }
  } catch (e) {
    // Silent error handling for production
  }
}

// Глобальный навигатор для обработки уведомлений
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void _navigateToTimers() {
  try {
    final navigator = globalNavigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed('/timers');
    }
  } catch (e) {
    // Silent error handling for production
  }
}

class DriftNotesApp extends StatefulWidget {
  final UserConsentService? consentService;

  const DriftNotesApp({super.key, this.consentService});

  @override
  State<DriftNotesApp> createState() => _DriftNotesAppState();
}

class _DriftNotesAppState extends State<DriftNotesApp>
    with WidgetsBindingObserver {
  final _firebaseService = FirebaseService();

  String? _pendingAction;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    // ✅ КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ: Запускаем инициализацию сервисов В ФОНЕ
    _initializeAllServicesInBackground();

    WeatherNotificationService.setNavigatorKey(globalNavigatorKey);

    _initializeQuickActions();
    _initializeDeepLinkHandling();
    _checkDocumentUpdatesAfterAuth();
    _setupNotificationHandlers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScheduledReminderContext();
      _initializeSubscriptionProvider();
    });
  }

  // ✅ НОВЫЙ МЕТОД: Фоновая инициализация без блокировки UI
  void _initializeAllServicesInBackground() {
    // Запускаем через микротаск чтобы не блокировать первый кадр
    Future.microtask(() async {
      await _initializeAllServicesAsync();
    });
  }

  // Инициализация SubscriptionProvider
  void _initializeSubscriptionProvider() {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Устанавливаем FirebaseService ПЕРЕД инициализацией
      subscriptionProvider.setFirebaseService(_firebaseService);

      subscriptionProvider.initialize().then((_) {
        // Silent success
      }).catchError((error) {
        // Silent error handling
      });
    } catch (e) {
      // Silent error handling for production
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    try {
      NotificationService().dispose();
      LocalPushNotificationService().dispose();
      WeatherNotificationService().dispose();
      ScheduledReminderService().dispose();
      TimerService().dispose();
    } catch (e) {
      // Silent error handling for production
    }

    super.dispose();
  }

  void _initializeScheduledReminderContext() {
    try {
      if (globalNavigatorKey.currentContext != null) {
        ScheduledReminderService().setContext(globalNavigatorKey.currentContext!);
        _ensureNotificationHandlerIsActive();
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _ensureNotificationHandlerIsActive() {
    try {
      _setupNotificationHandlers();
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _setupNotificationHandlers() {
    try {
      final pushService = LocalPushNotificationService();

      pushService.notificationTapStream.listen(
            (payload) {
          _handleNotificationTap(payload);
        },
        onError: (error) {
          // Silent error handling
        },
      );
    } catch (e) {
      _setupAlternativeNotificationHandler();
    }
  }

  void _setupAlternativeNotificationHandler() {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        final pushService = LocalPushNotificationService();
        pushService.notificationTapStream.listen((payload) {
          _handleNotificationTap(payload);
        });
      } catch (e) {
        // Silent error handling for production
      }
    });
  }

  void _handleNotificationTap(String payload) {
    try {
      if (globalNavigatorKey.currentContext == null) {
        return;
      }

      try {
        final payloadData = json.decode(payload);
        final notificationType = payloadData['type'];
        final notificationId = payloadData['id'];

        if (notificationType == 'timer_finished') {
          _handleTimerNotification(payloadData);
        } else if (notificationType == 'NotificationType.tournamentReminder') {
          _handleTournamentNotification(notificationId);
        } else if (notificationType == 'NotificationType.fishingReminder') {
          _navigateToFishingCalendar();
        } else {
          _navigateToNotifications();
        }
      } catch (e) {
        _navigateToNotifications();
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _handleTimerNotification(Map<String, dynamic> payloadData) {
    try {
      _navigateToTimers();
    } catch (e) {
      _navigateToNotifications();
    }
  }

  void _navigateToTimers() {
    globalNavigatorKey.currentState?.pushNamed('/timers');
  }

  void _handleTournamentNotification(String notificationId) {
    try {
      final notificationService = NotificationService();
      final notifications = notificationService.getAllNotifications();

      final notification = notifications.firstWhere(
            (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      final sourceId = notification.data['sourceId'] as String?;

      if (sourceId != null && sourceId.isNotEmpty) {
        _navigateToTournamentDetail(sourceId);
      } else {
        _navigateToNotifications();
      }
    } catch (e) {
      _navigateToNotifications();
    }
  }

  void _navigateToNotifications() {
    globalNavigatorKey.currentState?.pushNamed('/notifications');
  }

  void _navigateToTournamentDetail(String tournamentId) {
    try {
      final tournamentService = TournamentService();
      final tournament = tournamentService.getTournamentById(tournamentId);

      if (tournament == null) {
        _navigateToNotifications();
        return;
      }

      if (globalNavigatorKey.currentContext == null) {
        return;
      }

      Navigator.of(globalNavigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => TournamentDetailScreen(tournament: tournament),
        ),
      );
    } catch (e) {
      _navigateToNotifications();
    }
  }

  void _navigateToFishingCalendar() {
    globalNavigatorKey.currentState?.pushNamed('/fishing_calendar');
  }

  void _checkDocumentUpdatesAfterAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && widget.consentService != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeScheduledReminderContext();
        });
      }
    });
  }

  void _initializeQuickActions() {
    try {
      const QuickActions quickActions = QuickActions();

      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'create_note',
          localizedTitle: 'Создать заметку',
        ),
        const ShortcutItem(type: 'view_notes', localizedTitle: 'Мои заметки'),
        const ShortcutItem(type: 'timers', localizedTitle: 'Таймеры'),
      ]).catchError((error) {
        // Silent error handling
      });

      quickActions.initialize((String shortcutType) {
        _handleShortcutAction(shortcutType);
      });
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _initializeDeepLinkHandling() {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen(
          (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        // Silent error handling
      },
    );

    _handleInitialLink();
  }

  Future<void> _handleInitialLink() async {
    try {
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'driftnotes') {
      switch (uri.host) {
        case 'create_note':
          _handleShortcutAction('create_note');
          break;
        case 'view_notes':
          _handleShortcutAction('view_notes');
          break;
        case 'timers':
          _handleShortcutAction('timers');
          break;
      }
    }
  }

  void _handleShortcutAction(String actionType) {
    if (globalNavigatorKey.currentContext == null) {
      _pendingAction = actionType;
      return;
    }

    if (!_firebaseService.isUserLoggedIn) {
      _pendingAction = actionType;
      globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/auth_selection',
            (route) => false,
      );
      return;
    }

    _executeAction(actionType);
  }

  void _executeAction(String actionType) {
    switch (actionType) {
      case 'create_note':
        _navigateToCreateNote();
        break;
      case 'view_notes':
        _navigateToViewNotes();
        break;
      case 'timers':
        _navigateToTimersFromShortcut();
        break;
    }

    _pendingAction = null;
  }

  void _navigateToCreateNote() {
    globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (globalNavigatorKey.currentContext != null) {
        Navigator.of(globalNavigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const FishingTypeSelectionScreen(),
          ),
        );
      }
    });
  }

  void _navigateToViewNotes() {
    globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (globalNavigatorKey.currentContext != null) {
        Navigator.of(globalNavigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const FishingNotesListScreen(),
          ),
        );
      }
    });
  }

  void _navigateToTimersFromShortcut() {
    globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (globalNavigatorKey.currentContext != null) {
        Navigator.of(globalNavigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const TimersScreen(),
          ),
        );
      }
    });
  }

  void executePendingAction() {
    if (_pendingAction != null) {
      final action = _pendingAction!;
      _pendingAction = null;

      Future.delayed(const Duration(milliseconds: 1000), () {
        _executeAction(action);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      default:
        break;
    }
  }

  void _onAppResumed() {
    try {
      final notificationService = NotificationService();
      final unreadCount = notificationService.getUnreadCount();

      if (unreadCount == 0) {
        final pushService = LocalPushNotificationService();
        pushService.clearBadge();
      }

      _initializeScheduledReminderContext();
    } catch (e) {
      // Silent error handling for production
    }
  }

  void _onAppPaused() {
    // Сохранение состояния при паузе
  }

  void _onAppDetached() {
    // Ресурсы освобождаются в dispose()
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          navigatorKey: globalNavigatorKey,
          title: 'Drift Notes',
          debugShowCheckedModeBanner: false,

          // Настройки локализации
          locale: languageProvider.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          builder: (context, widget) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                ScheduledReminderService().setContext(context);
              } catch (e) {
                // Silent error handling for production
              }
            });

            return widget ?? const SizedBox();
          },

          theme: ThemeData(
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: AppConstants.backgroundColor,
            textTheme: GoogleFonts.montserratTextTheme(
              Theme.of(context).textTheme.apply(
                bodyColor: AppConstants.textColor,
                displayColor: AppConstants.textColor,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: AppConstants.textColor,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              titleTextStyle: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              iconTheme: IconThemeData(color: AppConstants.textColor),
            ),
            cardTheme: CardThemeData(
              color: AppConstants.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.2),
            ),
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              secondary: AppConstants.accentColor,
              surface: AppConstants.surfaceColor,
              onPrimary: AppConstants.textColor,
              onSecondary: Colors.black,
              onSurface: AppConstants.textColor,
              surfaceContainerHighest: AppConstants.backgroundColor,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.textColor,
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppConstants.surfaceColor,
              hintStyle: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                borderSide: BorderSide(color: AppConstants.textColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          home: SplashScreenWithPendingAction(
            onAppReady: () {
              if (_pendingAction != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _handleShortcutAction(_pendingAction!);
                });
              }
            },
          ),

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/auth_selection': (context) => AuthSelectionScreenWithCallback(
              onAuthSuccess: () => executePendingAction(),
            ),
            '/login': (context) => LoginScreenWithCallback(
              onAuthSuccess: () => executePendingAction(),
            ),
            '/register': (context) => RegisterScreenWithCallback(
              onAuthSuccess: () => executePendingAction(),
            ),
            '/home': (context) => const HomeScreen(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
            '/help_contact': (context) => const HelpContactScreen(),
            '/settings/accepted_agreements': (context) => const AcceptedAgreementsScreen(),
            '/timers': (context) => const TimersScreen(),
          },
        );
      },
    );
  }
}

// Обертка для SplashScreen с коллбэком
class SplashScreenWithPendingAction extends StatefulWidget {
  final VoidCallback onAppReady;

  const SplashScreenWithPendingAction({super.key, required this.onAppReady});

  @override
  State<SplashScreenWithPendingAction> createState() =>
      _SplashScreenWithPendingActionState();
}

class _SplashScreenWithPendingActionState
    extends State<SplashScreenWithPendingAction> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAppReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// Обертки для экранов авторизации с коллбэками
class AuthSelectionScreenWithCallback extends StatelessWidget {
  final VoidCallback onAuthSuccess;

  const AuthSelectionScreenWithCallback({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return AuthSelectionScreen(onAuthSuccess: onAuthSuccess);
  }
}

class LoginScreenWithCallback extends StatelessWidget {
  final VoidCallback onAuthSuccess;

  const LoginScreenWithCallback({super.key, required this.onAuthSuccess});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(onAuthSuccess: onAuthSuccess);
  }
}

class RegisterScreenWithCallback extends StatelessWidget {
  final VoidCallback onAuthSuccess;

  const RegisterScreenWithCallback({super.key, required this.onAuthSuccess});

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(onAuthSuccess: onAuthSuccess);
  }
}