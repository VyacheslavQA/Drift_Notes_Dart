// Путь: lib/main.dart
// ✅ ИСПРАВЛЕНО ДЛЯ ПРОДАКШЕНА: Правильная инициализация с IsarService в критических сервисах

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
import 'package:shared_preferences/shared_preferences.dart';
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
import 'screens/onboarding/first_launch_language_screen.dart';
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

  // 🔥 ИСПРАВЛЕНО: Критические сервисы теперь включают IsarService
  await _initializeCriticalServices();

  // Инициализация LanguageProvider ДО создания приложения
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // ✅ ИСПРАВЛЕНО: Запускаем приложение после инициализации критических сервисов
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

  // 🔥 НОВОЕ: Остальные сервисы инициализируем в фоне ПОСЛЕ запуска UI
  _initializeSecondaryServicesInBackground();
}

// 🔥 ИСПРАВЛЕНО: Критические сервисы теперь включают IsarService и базовые зависимости
Future<void> _initializeCriticalServices() async {
  try {
    debugPrint('🔧 Инициализация критических сервисов...');

    // 1. ПЕРВЫМ делом инициализируем Isar - он нужен сразу для SyncService
    await IsarService.instance.init();
    debugPrint('✅ IsarService инициализирован');

    // 2. Инициализация локали для форматирования дат
    await initializeDateFormatting('ru_RU', null);
    await initializeDateFormatting('en_US', null);

    // 3. Устанавливаем ориентацию экрана только на портретный режим
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 4. Показываем системную навигацию
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

    // 5. Инициализация Firebase с защитой от дублирования
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase инициализирован');
    }

    // 6. Инициализация базовых репозиториев (нужны для работы с данными)
    await _initializeBasicRepositories();

    // 7. Базовые разрешения и уведомления (критично для пользовательского опыта)
    await _requestNotificationPermissions();
    await _initializeNotifications();

    debugPrint('✅ Критические сервисы инициализированы');
  } catch (e, stackTrace) {
    debugPrint('❌ Критическая ошибка инициализации: $e');
    debugPrint('Stack trace: $stackTrace');
    // В продакшене продолжаем работу даже при ошибках
  }
}

// 🔥 НОВОЕ: Инициализация базовых репозиториев
Future<void> _initializeBasicRepositories() async {
  try {
    // Инициализируем репозитории параллельно для быстроты
    final futures = [
          () async {
        try {
          await FishingNoteRepository().initialize();
          debugPrint('✅ FishingNoteRepository инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка FishingNoteRepository: $e');
        }
      }(),
          () async {
        try {
          await BudgetNotesRepository().initialize();
          debugPrint('✅ BudgetNotesRepository инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка BudgetNotesRepository: $e');
        }
      }(),
          () async {
        try {
          await MarkerMapRepository().initialize();
          debugPrint('✅ MarkerMapRepository инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка MarkerMapRepository: $e');
          // MarkerMap может использовать legacy систему
        }
      }(),
    ];

    await Future.wait(futures, eagerError: false);
    debugPrint('✅ Базовые репозитории инициализированы');
  } catch (e) {
    debugPrint('⚠️ Ошибка инициализации репозиториев: $e');
    // Продолжаем работу - репозитории могут инициализироваться позже
  }
}

// 🔥 НОВОЕ: Вторичные сервисы в фоне ПОСЛЕ запуска UI
void _initializeSecondaryServicesInBackground() {
  // Запускаем через микротаск чтобы не блокировать отрисовку первого кадра
  Future.microtask(() async {
    try {
      debugPrint('🔄 Начинаем фоновую инициализацию вторичных сервисов...');

      // Этап 1: App Check и безопасность
      await _initializeSecurityServices();

      // Этап 2: Совместимость со старыми сервисами
      await _initializeLegacyServices();

      // Этап 3: Сервисы приложения (параллельно с задержками)
      await _initializeApplicationServices();

      // Этап 4: Сетевые сервисы (последними)
      await _initializeNetworkServices();

      debugPrint('✅ Все вторичные сервисы инициализированы успешно');
    } catch (e) {
      debugPrint('❌ Ошибка фоновой инициализации: $e');
      // В продакшене не крашим приложение из-за ошибок вторичных сервисов
    }
  });
}

// Этап 1: Сервисы безопасности (асинхронно)
Future<void> _initializeSecurityServices() async {
  try {
    debugPrint('🔐 Инициализация сервисов безопасности...');

    // App Check в микротаске чтобы не блокировать UI
    Future.microtask(() async {
      try {
        await _initializeAppCheck();
        debugPrint('✅ App Check инициализирован');
      } catch (e) {
        debugPrint('⚠️ Ошибка App Check: $e');
      }
    });

    // Debug тесты тоже в микротаске
    if (kDebugMode) {
      Future.microtask(() async {
        try {
          await _testFirebaseAuthentication();
          final firestore = FirebaseFirestore.instance;
          await firestore.enableNetwork();
          debugPrint('✅ Firebase debug тесты пройдены');
        } catch (e) {
          debugPrint('⚠️ Ошибка Firebase debug тестов: $e');
        }
      });
    }

    debugPrint('✅ Сервисы безопасности готовы');
  } catch (e) {
    debugPrint('❌ Ошибка сервисов безопасности: $e');
  }
}

// Этап 2: Инициализация legacy сервисов для совместимости
Future<void> _initializeLegacyServices() async {
  try {
    debugPrint('🗄️ Инициализация legacy сервисов...');

    // Инициализируем старый OfflineStorageService для совместимости
    try {
      final offlineStorage = OfflineStorageService();
      await offlineStorage.initialize();
      debugPrint('✅ OfflineStorageService (legacy) инициализирован');
    } catch (e) {
      debugPrint('⚠️ Ошибка OfflineStorageService: $e');
    }

    debugPrint('✅ Legacy сервисы готовы');
  } catch (e) {
    debugPrint('❌ Ошибка legacy сервисов: $e');
  }
}

// Этап 3: Сервисы приложения (все в микротасках)
Future<void> _initializeApplicationServices() async {
  try {
    debugPrint('⚙️ Инициализация сервисов приложения...');

    // Критически важные сервисы уведомлений
    final criticalServices = [
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 10));
          await LocalPushNotificationService().initialize();
          debugPrint('✅ LocalPushNotificationService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка LocalPushNotificationService: $e');
        }
      },
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 20));
          await NotificationService().initialize();
          debugPrint('✅ NotificationService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка NotificationService: $e');
        }
      },
    ];

    // Вторичные сервисы
    final secondaryServices = [
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 30));
          await TimerService().initialize();
          debugPrint('✅ TimerService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка TimerService: $e');
        }
      },
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 40));
          await WeatherNotificationService().initialize();
          debugPrint('✅ WeatherNotificationService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка WeatherNotificationService: $e');
        }
      },
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 50));
          await WeatherSettingsService().initialize();
          debugPrint('✅ WeatherSettingsService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка WeatherSettingsService: $e');
        }
      },
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 60));
          await ScheduledReminderService().initialize();
          debugPrint('✅ ScheduledReminderService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка ScheduledReminderService: $e');
        }
      },
          () async {
        try {
          await Future.delayed(Duration(milliseconds: 70));
          await LocationService().initialize();
          debugPrint('✅ LocationService инициализирован');
        } catch (e) {
          debugPrint('⚠️ Ошибка LocationService: $e');
        }
      },
    ];

    // Запускаем критические сервисы
    for (final service in criticalServices) {
      Future.microtask(service);
    }

    // Запускаем вторичные сервисы
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

// Этап 4: Сетевые сервисы
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

// ✅ ИСПРАВЛЕНО: Инициализация App Check
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

    // Получаем токен для проверки работоспособности
    await FirebaseAppCheck.instance.getToken();

  } catch (e) {
    debugPrint('⚠️ Ошибка App Check: $e');
    // В продакшене не крашим приложение из-за App Check
  }
}

// ✅ ИСПРАВЛЕНО: Запуск мониторинга сети с новым SyncService
void _startNetworkMonitoring() {
  try {
    final networkMonitor = NetworkUtils();
    networkMonitor.startNetworkMonitoring();

    networkMonitor.addConnectionListener((isConnected) {
      if (isConnected) {
        // 🔥 ИСПРАВЛЕНО: Проверяем готовность IsarService перед синхронизацией
        if (IsarService.instance.isInitialized) {
          SyncService.instance.fullSync().then((_) {
            debugPrint('✅ Автоматическая синхронизация выполнена');
          }).catchError((e) {
            debugPrint('⚠️ Ошибка автоматической синхронизации: $e');
          });
        } else {
          debugPrint('⚠️ IsarService не готов для синхронизации');
        }
      }
    });

    // ✅ ИСПРАВЛЕНО: Запускаем периодическую синхронизацию через новый SyncService
    SyncService.instance.startPeriodicSync();

  } catch (e) {
    debugPrint('⚠️ Ошибка мониторинга сети: $e');
  }
}

// Функция для тестирования Firebase Authentication
Future<void> _testFirebaseAuthentication() async {
  if (!kDebugMode) return;

  try {
    final auth = FirebaseAuth.instance;

    // Проверяем что Firebase Auth доступен
    if (auth.app.name.isNotEmpty) {
      debugPrint('✅ Firebase Auth готов');
    }

  } catch (e) {
    debugPrint('⚠️ Ошибка тестирования Firebase Auth: $e');
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
          debugPrint('⚠️ scheduleExactAlarm не поддерживается: $e');
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
    debugPrint('✅ Разрешения на уведомления запрошены');
  } catch (e) {
    debugPrint('⚠️ Ошибка запроса разрешений: $e');
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

    debugPrint('✅ Flutter Local Notifications инициализированы');
  } catch (e) {
    debugPrint('⚠️ Ошибка инициализации уведомлений: $e');
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
    debugPrint('⚠️ Ошибка создания канала уведомлений: $e');
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
        debugPrint('⚠️ Ошибка обработки payload уведомления: $e');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Ошибка обработки нажатия на уведомление: $e');
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
    debugPrint('⚠️ Ошибка навигации к таймерам: $e');
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

  // ДОБАВЛЕНО: Проверка первого запуска приложения
  Future<bool> _checkIfFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageSelectionCompleted = prefs.getBool('language_selection_completed') ?? false;
      return !languageSelectionCompleted;
    } catch (e) {
      debugPrint('❌ Ошибка проверки первого запуска: $e');
      return false;
    }
  }

  // Инициализация SubscriptionProvider
  void _initializeSubscriptionProvider() {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Устанавливаем FirebaseService ПЕРЕД инициализацией
      subscriptionProvider.setFirebaseService(_firebaseService);

      subscriptionProvider.initialize().then((_) {
        debugPrint('✅ SubscriptionProvider инициализирован');
      }).catchError((error) {
        debugPrint('⚠️ Ошибка SubscriptionProvider: $error');
      });
    } catch (e) {
      debugPrint('⚠️ Ошибка инициализации SubscriptionProvider: $e');
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
      debugPrint('⚠️ Ошибка dispose сервисов: $e');
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
      debugPrint('⚠️ Ошибка инициализации ScheduledReminder контекста: $e');
    }
  }

  void _ensureNotificationHandlerIsActive() {
    try {
      _setupNotificationHandlers();
    } catch (e) {
      debugPrint('⚠️ Ошибка активации обработчика уведомлений: $e');
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
          debugPrint('⚠️ Ошибка потока уведомлений: $error');
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
        debugPrint('⚠️ Ошибка альтернативного обработчика уведомлений: $e');
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
      debugPrint('⚠️ Ошибка обработки нажатия на уведомление: $e');
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
        debugPrint('⚠️ Ошибка установки Quick Actions: $error');
      });

      quickActions.initialize((String shortcutType) {
        _handleShortcutAction(shortcutType);
      });
    } catch (e) {
      debugPrint('⚠️ Ошибка инициализации Quick Actions: $e');
    }
  }

  void _initializeDeepLinkHandling() {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen(
          (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('⚠️ Ошибка Deep Link: $err');
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
      debugPrint('⚠️ Ошибка обработки начального Deep Link: $e');
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
      debugPrint('⚠️ Ошибка при возобновлении приложения: $e');
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
                debugPrint('⚠️ Ошибка установки контекста ScheduledReminderService: $e');
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

          // 🔥 ИСПРАВЛЕНО: Динамическое определение первого экрана
          home: FutureBuilder<bool>(
            future: _checkIfFirstLaunch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Показываем простой загрузочный экран пока проверяем
                return Scaffold(
                  body: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/splash_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final isFirstLaunch = snapshot.data ?? false;

              if (isFirstLaunch) {
                // Первый запуск - показываем выбор языка
                return const FirstLaunchLanguageScreen();
              } else {
                // Обычный запуск - показываем splash
                return SplashScreenWithPendingAction(
                  onAppReady: () {
                    if (_pendingAction != null) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _handleShortcutAction(_pendingAction!);
                      });
                    }
                  },
                );
              }
            },
          ),

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/first_launch_language': (context) => const FirstLaunchLanguageScreen(),
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