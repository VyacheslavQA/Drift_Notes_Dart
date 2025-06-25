// Путь: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:convert';
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
import 'providers/timer_provider.dart';
import 'providers/language_provider.dart';
import 'localization/app_localizations.dart';
import 'firebase_options.dart';
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

  // Настройка системного UI (статус бар и навигационная панель)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1F1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Инициализация Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    return;
  }

  // Инициализация сервисов уведомлений
  try {
    await LocalPushNotificationService().initialize();
  } catch (e) {
    // Продолжаем работу без push-уведомлений
  }

  try {
    await NotificationService().initialize();
  } catch (e) {
    // Продолжаем работу без сервиса уведомлений
  }

  try {
    await TimerService().initialize();
  } catch (e) {
    // Продолжаем работу без TimerService
  }

  try {
    await WeatherNotificationService().initialize();
  } catch (e) {
    // Продолжаем работу без погодных уведомлений
  }

  try {
    await WeatherSettingsService().initialize();
  } catch (e) {
    // Продолжаем работу без настроек погоды
  }

  try {
    await ScheduledReminderService().initialize();
  } catch (e) {
    // Продолжаем работу без точных напоминаний
  }

  // Инициализация UserConsentService
  UserConsentService? consentService;
  try {
    consentService = UserConsentService();
  } catch (e) {
    // Продолжаем работу без сервиса согласий
  }

  // Инициализация сервисов для офлайн режима
  try {
    final offlineStorage = OfflineStorageService();
    await offlineStorage.initialize();
  } catch (e) {
    // Продолжаем работу без офлайн хранилища
  }

  // Запуск мониторинга сети
  try {
    final networkMonitor = NetworkUtils();
    networkMonitor.startNetworkMonitoring();

    networkMonitor.addConnectionListener((isConnected) {
      if (isConnected) {
        SyncService().syncAll();
      }
    });

    SyncService().startPeriodicSync();
  } catch (e) {
    // Продолжаем работу без мониторинга сети
  }

  // Запуск приложения
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimerProvider()),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: DriftNotesApp(consentService: consentService),
    ),
  );
}

class DriftNotesApp extends StatefulWidget {
  final UserConsentService? consentService;

  const DriftNotesApp({super.key, this.consentService});

  @override
  State<DriftNotesApp> createState() => _DriftNotesAppState();
}

class _DriftNotesAppState extends State<DriftNotesApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _firebaseService = FirebaseService();

  String? _pendingAction;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    WeatherNotificationService.setNavigatorKey(_navigatorKey);

    _initializeQuickActions();
    _initializeDeepLinkHandling();
    _checkDocumentUpdatesAfterAuth();
    _setupNotificationHandlers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScheduledReminderContext();
    });
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
      // Ошибки при освобождении ресурсов не критичны
    }

    super.dispose();
  }

  void _initializeScheduledReminderContext() {
    try {
      if (_navigatorKey.currentContext != null) {
        ScheduledReminderService().setContext(_navigatorKey.currentContext!);
        _ensureNotificationHandlerIsActive();
      }
    } catch (e) {
      // Ошибка установки контекста не критична
    }
  }

  void _ensureNotificationHandlerIsActive() {
    try {
      _setupNotificationHandlers();
    } catch (e) {
      // Ошибка проверки обработчика не критична
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
          // Ошибки в stream уведомлений не критичны
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
        // Альтернативный обработчик тоже не критичен
      }
    });
  }

  void _handleNotificationTap(String payload) {
    try {
      if (_navigatorKey.currentContext == null) {
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
      // Ошибка обработки уведомления не критична
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
    _navigatorKey.currentState?.pushNamed('/timers');
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
    _navigatorKey.currentState?.pushNamed('/notifications');
  }

  void _navigateToTournamentDetail(String tournamentId) {
    try {
      final tournamentService = TournamentService();
      final tournament = tournamentService.getTournamentById(tournamentId);

      if (tournament == null) {
        _navigateToNotifications();
        return;
      }

      if (_navigatorKey.currentContext == null) {
        return;
      }

      Navigator.of(_navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => TournamentDetailScreen(tournament: tournament),
        ),
      );
    } catch (e) {
      _navigateToNotifications();
    }
  }

  void _navigateToFishingCalendar() {
    _navigatorKey.currentState?.pushNamed('/fishing_calendar');
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
      ]).catchError((error) {
        // Ошибка установки shortcuts не критична
      });

      quickActions.initialize((String shortcutType) {
        _handleShortcutAction(shortcutType);
      });
    } catch (e) {
      // Ошибка инициализации Quick Actions не критична
    }
  }

  void _initializeDeepLinkHandling() {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen(
          (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        // Ошибка deep link не критична
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
      // Ошибка получения начального deep link не критична
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
      }
    }
  }

  void _handleShortcutAction(String actionType) {
    if (_navigatorKey.currentContext == null) {
      _pendingAction = actionType;
      return;
    }

    if (!_firebaseService.isUserLoggedIn) {
      _pendingAction = actionType;
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
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
    }

    _pendingAction = null;
  }

  void _navigateToCreateNote() {
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_navigatorKey.currentContext != null) {
        Navigator.of(_navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const FishingTypeSelectionScreen(),
          ),
        );
      }
    });
  }

  void _navigateToViewNotes() {
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_navigatorKey.currentContext != null) {
        Navigator.of(_navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const FishingNotesListScreen(),
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
      // Ошибка обновления бейджа не критична
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
          navigatorKey: _navigatorKey,
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
                // Ошибка установки контекста не критична
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