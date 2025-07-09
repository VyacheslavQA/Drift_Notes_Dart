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

// Глобальная переменная для flutter_local_notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация локали для форматирования дат
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('en_US', null);

  // Устанавливаем ориентацию экрана только на портретный режим
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Показываем системную навигацию
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Запрос разрешений на уведомления ПЕРЕД инициализацией Firebase
  await _requestNotificationPermissions();

  // Инициализация flutter_local_notifications
  await _initializeNotifications();

  // Инициализация Firebase с защитой от дублирования
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        debugPrint('✅ Firebase инициализирован');
      }
    } else {
      if (kDebugMode) {
        debugPrint('🔥 Firebase уже был инициализирован, пропускаем');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка инициализации Firebase: $e');
    }
  }

  // ВРЕМЕННО ОТКЛЮЧАЕМ App Check для тестирования Firebase Auth
  if (kDebugMode) {
    try {
      debugPrint('');
      debugPrint('🎯 ========================================');
      debugPrint('⚠️  APP CHECK ВРЕМЕННО ОТКЛЮЧЕН');
      debugPrint('🧪 Тестируем Firebase Auth БЕЗ App Check');
      debugPrint('🔧 После успешного теста настроим App Check');
      debugPrint('🎯 ========================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
    }
  }

  // Тест Firebase Auth с диагностикой
  if (kDebugMode) {
    await _testFirebaseAuthentication();
  }

  // Тест подключения к Firebase
  if (kDebugMode) {
    try {
      debugPrint('🔍 Тестируем подключение к Firebase...');
      debugPrint('📱 Project ID: ${Firebase.app().options.projectId}');
      debugPrint('📱 App ID: ${Firebase.app().options.appId}');

      // Простой тест Auth
      final auth = FirebaseAuth.instance;
      debugPrint('🔐 Firebase Auth initialized: ${auth.app.name}');

      // Простой тест Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      debugPrint('✅ Firestore подключен');

      debugPrint('✅ Все сервисы Firebase доступны');
    } catch (e) {
      debugPrint('❌ Ошибка подключения к Firebase: $e');
    }
  }

  // Инициализация LanguageProvider ДО создания приложения
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();
  if (kDebugMode) {
    debugPrint('🌐 LanguageProvider инициализирован с языком: ${languageProvider.languageCode}');
  }

  // Инициализация сервисов уведомлений
  await _initializeServices();

  // Инициализация сервисов для офлайн режима
  await _initializeOfflineServices();

  // Запуск мониторинга сети
  _startNetworkMonitoring();

  if (kDebugMode) {
    debugPrint('🚀 Все сервисы инициализированы, запускаем приложение');
  }

  // Передаем уже инициализированный languageProvider
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

// Инициализация всех сервисов
Future<void> _initializeServices() async {
  final services = [
        () async {
      await LocalPushNotificationService().initialize();
      if (kDebugMode) debugPrint('✅ LocalPushNotificationService инициализирован');
    },
        () async {
      await NotificationService().initialize();
      if (kDebugMode) debugPrint('✅ NotificationService инициализирован');
    },
        () async {
      await TimerService().initialize();
      if (kDebugMode) debugPrint('✅ TimerService инициализирован');
    },
        () async {
      await WeatherNotificationService().initialize();
      if (kDebugMode) debugPrint('✅ WeatherNotificationService инициализирован');
    },
        () async {
      await WeatherSettingsService().initialize();
      if (kDebugMode) debugPrint('✅ WeatherSettingsService инициализирован');
    },
        () async {
      await ScheduledReminderService().initialize();
      if (kDebugMode) debugPrint('✅ ScheduledReminderService инициализирован');
    },
  ];

  for (final service in services) {
    try {
      await service();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка инициализации сервиса: $e');
      }
    }
  }
}

// Инициализация офлайн сервисов
Future<void> _initializeOfflineServices() async {
  try {
    final offlineStorage = OfflineStorageService();
    await offlineStorage.initialize();
    if (kDebugMode) {
      debugPrint('✅ OfflineStorageService инициализирован');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ OfflineStorageService не удалось инициализировать: $e');
    }
  }
}

// Запуск мониторинга сети
void _startNetworkMonitoring() {
  try {
    final networkMonitor = NetworkUtils();
    networkMonitor.startNetworkMonitoring();

    networkMonitor.addConnectionListener((isConnected) {
      if (isConnected) {
        SyncService().syncAll();
      }
    });

    SyncService().startPeriodicSync();
    if (kDebugMode) {
      debugPrint('✅ Мониторинг сети запущен');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Мониторинг сети не удалось запустить: $e');
    }
  }
}

// Функция для тестирования Firebase Authentication (только в debug)
Future<void> _testFirebaseAuthentication() async {
  if (!kDebugMode) return;

  try {
    debugPrint('🧪 Тестируем Firebase Authentication БЕЗ App Check...');

    final auth = FirebaseAuth.instance;

    // Проверяем текущего пользователя
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      debugPrint('👤 Текущий пользователь: ${currentUser.email}');
    } else {
      debugPrint('👤 Пользователь не авторизован');
    }

    // Проверяем доступность методов Auth
    try {
      // Попробуем получить провайдеры для несуществующего email
      await auth.fetchSignInMethodsForEmail('test@nonexistent.com');
      debugPrint('✅ Firebase Auth методы ДОСТУПНЫ без App Check!');
      debugPrint('🎉 Авторизация должна работать нормально');
    } catch (e) {
      if (e.toString().contains('blocked')) {
        debugPrint('❌ Firebase Auth методы все еще заблокированы: $e');
        debugPrint('🔧 Возможно проблема в настройках проекта Firebase');
      } else {
        debugPrint('✅ Firebase Auth работает (ошибка ожидаема для тестового email)');
        debugPrint('🎉 Можно тестировать авторизацию с реальными данными');
      }
    }

  } catch (e) {
    debugPrint('❌ Ошибка тестирования Firebase Auth: $e');
  }
}

// Функция для запроса разрешений на уведомления
Future<void> _requestNotificationPermissions() async {
  try {
    if (kDebugMode) {
      debugPrint('📱 Запрашиваем разрешения на уведомления...');
    }

    if (Platform.isAndroid) {
      // Для Android 13+ запрашиваем разрешение на уведомления
      final notificationStatus = await Permission.notification.request();
      if (kDebugMode) {
        debugPrint('📱 Android notification permission: $notificationStatus');
      }

      // Запрашиваем разрешение на точные будильники
      if (Platform.isAndroid) {
        try {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
          if (kDebugMode) {
            debugPrint('⏰ Android exact alarm permission: $exactAlarmStatus');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Exact alarm permission не поддерживается на этой версии Android');
          }
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
      if (kDebugMode) {
        debugPrint('📱 iOS notification permissions requested');
      }
    }

    if (kDebugMode) {
      debugPrint('✅ Разрешения на уведомления запрошены');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка запроса разрешений на уведомления: $e');
    }
  }
}

// Функция для инициализации flutter_local_notifications
Future<void> _initializeNotifications() async {
  try {
    if (kDebugMode) {
      debugPrint('🔔 Инициализируем flutter_local_notifications...');
    }

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

    if (kDebugMode) {
      debugPrint('✅ flutter_local_notifications инициализирован');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка инициализации flutter_local_notifications: $e');
    }
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

    if (kDebugMode) {
      debugPrint('✅ Канал уведомлений таймеров создан');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка создания канала уведомлений: $e');
    }
  }
}

// Обработчик нажатий на уведомления
void _onNotificationTap(NotificationResponse notificationResponse) {
  try {
    if (kDebugMode) {
      debugPrint('🔔 Нажатие на уведомление: ${notificationResponse.payload}');
    }

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
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка парсинга payload уведомления: $e');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка обработки нажатия на уведомление: $e');
    }
  }
}

// Глобальный навигатор для обработки уведомлений
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void _navigateToTimers() {
  try {
    final navigator = globalNavigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed('/timers');
      if (kDebugMode) {
        debugPrint('✅ Навигация к таймерам выполнена');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ Навигатор недоступен');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Ошибка навигации к таймерам: $e');
    }
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

  // Инициализация SubscriptionProvider
  void _initializeSubscriptionProvider() {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.initialize().then((_) {
        if (kDebugMode) {
          debugPrint('✅ SubscriptionProvider инициализирован в приложении');
        }
      }).catchError((error) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка инициализации SubscriptionProvider: $error');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Не удалось инициализировать SubscriptionProvider: $e');
      }
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
      if (kDebugMode) {
        debugPrint('⚠️ Ошибки при освобождении ресурсов: $e');
      }
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
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка установки контекста: $e');
      }
    }
  }

  void _ensureNotificationHandlerIsActive() {
    try {
      _setupNotificationHandlers();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка проверки обработчика: $e');
      }
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
          if (kDebugMode) {
            debugPrint('⚠️ Ошибки в stream уведомлений: $error');
          }
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
        if (kDebugMode) {
          debugPrint('⚠️ Альтернативный обработчик не удалось установить: $e');
        }
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
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка обработки уведомления: $e');
      }
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
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка установки shortcuts: $error');
        }
      });

      quickActions.initialize((String shortcutType) {
        _handleShortcutAction(shortcutType);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка инициализации Quick Actions: $e');
      }
    }
  }

  void _initializeDeepLinkHandling() {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen(
          (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        if (kDebugMode) {
          debugPrint('⚠️ Ошибка deep link: $err');
        }
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
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка получения начального deep link: $e');
      }
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
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка обновления при возврате в приложение: $e');
      }
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
                if (kDebugMode) {
                  debugPrint('⚠️ Ошибка установки контекста: $e');
                }
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
            cardTheme: CardTheme(
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