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
import 'config/api_keys.dart';
import 'services/weather_notification_service.dart';
import 'services/notification_service.dart';
import 'services/local_push_notification_service.dart';  // НОВЫЙ ИМПОРТ
import 'services/weather_settings_service.dart';
import 'services/firebase/firebase_service.dart';
import 'services/user_consent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ДОБАВЬТЕ ЭТИ СТРОКИ ДЛЯ ПРОВЕРКИ
  debugPrint('=== ПРОВЕРКА API КЛЮЧЕЙ ===');
  debugPrint('Google Maps ключ установлен: ${ApiKeys.hasGoogleMapsKey}');
  debugPrint('Weather ключ установлен: ${ApiKeys.hasWeatherKey}');
  debugPrint('==============================');

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

  // КРИТИЧЕСКИ ВАЖНО: Инициализация Firebase ПЕРВОЙ перед всеми другими сервисами
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase успешно инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации Firebase: $e');
    // Если Firebase не инициализируется, приложение не должно продолжать работу
    return;
  }

  // НОВОЕ: Инициализация сервисов уведомлений в правильном порядке
  try {
    // 1. Сначала инициализируем локальные push-уведомления
    await LocalPushNotificationService().initialize();
    debugPrint('✅ Сервис локальных push-уведомлений инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации локальных push-уведомлений: $e');
  }

  // ТОЛЬКО ПОСЛЕ успешной инициализации Firebase инициализируем другие сервисы
  try {
    // 2. Инициализация основного сервиса уведомлений (он теперь использует push-сервис)
    await NotificationService().initialize();
    debugPrint('✅ Сервис уведомлений инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации сервиса уведомлений: $e');
  }

  try {
    // 3. Инициализация погодных уведомлений
    await WeatherNotificationService().initialize();
    debugPrint('✅ Сервис погодных уведомлений инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации сервиса погодных уведомлений: $e');
  }

  try {
    await WeatherSettingsService().initialize();
    debugPrint('✅ Сервис настроек погоды инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации сервиса настроек погоды: $e');
  }

  // ТЕПЕРЬ можно безопасно создать UserConsentService
  UserConsentService? consentService;
  try {
    consentService = UserConsentService();
    debugPrint('✅ UserConsentService создан успешно');

    // ДИАГНОСТИКА ПЕРЕД ОЧИСТКОЙ
    final statusBefore = await consentService.getUserConsentStatus();
    debugPrint('🔍 ДО очистки: Privacy=${statusBefore.privacyPolicyAccepted}, Terms=${statusBefore.termsOfServiceAccepted}');
    debugPrint('🔍 ДО очистки: Version=${statusBefore.consentVersion}');

    // ОЧИСТКА
    await consentService.clearAllConsents();
    debugPrint('🧹 ТЕСТ: Выполнена очистка согласий');

    // ДИАГНОСТИКА ПОСЛЕ ОЧИСТКИ
    final statusAfter = await consentService.getUserConsentStatus();
    debugPrint('🔍 ПОСЛЕ очистки: Privacy=${statusAfter.privacyPolicyAccepted}, Terms=${statusAfter.termsOfServiceAccepted}');
    debugPrint('🔍 ПОСЛЕ очистки: Version=${statusAfter.consentVersion}');

  } catch (e) {
    debugPrint('❌ Ошибка создания UserConsentService: $e');
  }

  // Инициализация Google Sign-In (тихий вход)
  try {
    // Импорт будет добавлен автоматически
    // final googleSignInService = GoogleSignInService();
    // await googleSignInService.signInSilently();
    debugPrint('Google Sign-In будет инициализирован после создания сервиса');
  } catch (e) {
    debugPrint('Ошибка инициализации Google Sign-In: $e');
  }

  // Инициализация сервисов для офлайн режима
  try {
    final offlineStorage = OfflineStorageService();
    await offlineStorage.initialize();
    debugPrint('✅ Офлайн хранилище инициализировано');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации офлайн хранилища: $e');
  }

  // Запуск мониторинга сети
  try {
    final networkMonitor = NetworkUtils();
    networkMonitor.startNetworkMonitoring();

    // Добавление слушателя для запуска синхронизации при появлении сети
    networkMonitor.addConnectionListener((isConnected) {
      if (isConnected) {
        debugPrint('🌐 Соединение с интернетом восстановлено, запускаем синхронизацию');
        SyncService().syncAll();
      } else {
        debugPrint('🔴 Соединение с интернетом потеряно, переход в офлайн режим');
      }
    });

    // Запуск периодической синхронизации
    SyncService().startPeriodicSync();
    debugPrint('✅ Мониторинг сети и синхронизация запущены');
  } catch (e) {
    debugPrint('❌ Ошибка запуска мониторинга сети: $e');
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

class _DriftNotesAppState extends State<DriftNotesApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _firebaseService = FirebaseService();

  // Для отслеживания pending действий
  String? _pendingAction;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeQuickActions();
    _initializeDeepLinkHandling();
    _checkDocumentUpdatesAfterAuth();

    // НОВОЕ: Настройка обработчиков уведомлений
    _setupNotificationHandlers();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    // НОВОЕ: Освобождение ресурсов сервисов уведомлений
    try {
      NotificationService().dispose();
      LocalPushNotificationService().dispose();
      WeatherNotificationService().dispose();
    } catch (e) {
      debugPrint('❌ Ошибка освобождения ресурсов уведомлений: $e');
    }

    super.dispose();
  }

  // НОВАЯ ФУНКЦИЯ: Настройка обработчиков уведомлений
  void _setupNotificationHandlers() {
    try {
      final pushService = LocalPushNotificationService();

      // Обрабатываем нажатия на уведомления
      pushService.notificationTapStream.listen((payload) {
        debugPrint('📱 Приложение: получено нажатие на уведомление: $payload');
        _handleNotificationTap(payload);
      });

      debugPrint('✅ Обработчики уведомлений настроены');
    } catch (e) {
      debugPrint('❌ Ошибка настройки обработчиков уведомлений: $e');
    }
  }

  // НОВАЯ ФУНКЦИЯ: Обработка нажатий на уведомления
  void _handleNotificationTap(String payload) {
    try {
      debugPrint('📱 Обработка нажатия на уведомление: $payload');

      // Проверяем, готово ли приложение для навигации
      if (_navigatorKey.currentContext == null) {
        debugPrint('⏳ Приложение не готово для навигации');
        return;
      }

      // Простая навигация к экрану уведомлений
      // Здесь можно добавить более сложную логику на основе payload
      // Например, если это погодное уведомление, перейти к прогнозу погоды

    } catch (e) {
      debugPrint('❌ Ошибка обработки нажатия на уведомление: $e');
    }
  }

  void _checkDocumentUpdatesAfterAuth() {
    // Слушаем изменения состояния авторизации через FirebaseAuth напрямую
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && widget.consentService != null) {
        // Пользователь авторизован - можно добавить дополнительную логику если нужно
        debugPrint('✅ Пользователь авторизован: ${user.uid}');
      }
    });
  }

  void _initializeQuickActions() {
    try {
      const QuickActions quickActions = QuickActions();

      // Устанавливаем список быстрых действий
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'create_note',
          localizedTitle: 'Создать заметку',
        ),
        const ShortcutItem(
          type: 'view_notes',
          localizedTitle: 'Мои заметки',
        ),
      ]);

      // Обрабатываем нажатия на быстрые действия
      quickActions.initialize((String shortcutType) {
        debugPrint('🚀 Quick Action получен: $shortcutType');
        _handleShortcutAction(shortcutType);
      });

      debugPrint('✅ Quick Actions успешно инициализированы');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации Quick Actions: $e');
    }
  }

  void _initializeDeepLinkHandling() {
    final appLinks = AppLinks();

    // Обработка deep links когда приложение уже запущено
    appLinks.uriLinkStream.listen(
          (Uri uri) {
        debugPrint('🔗 Deep link получен: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ Ошибка deep link: $err');
      },
    );

    // Обработка deep link при запуске приложения
    _handleInitialLink();
  }

  Future<void> _handleInitialLink() async {
    try {
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🚀 Начальный deep link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения начального deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔍 Обработка deep link: ${uri.scheme}://${uri.host}${uri.path}');

    if (uri.scheme == 'driftnotes') {
      switch (uri.host) {
        case 'create_note':
          _handleShortcutAction('create_note');
          break;
        case 'view_notes':
          _handleShortcutAction('view_notes');
          break;
        default:
          debugPrint('❓ Неизвестный deep link: ${uri.host}');
      }
    }
  }

  void _handleShortcutAction(String actionType) {
    debugPrint('🎯 Обработка действия: $actionType');

    // Проверяем, готово ли приложение для навигации
    if (_navigatorKey.currentContext == null) {
      debugPrint('⏳ Приложение не готово, сохраняем действие: $actionType');
      _pendingAction = actionType;
      return;
    }

    // Проверяем авторизацию
    if (!_firebaseService.isUserLoggedIn) {
      debugPrint('🔐 Пользователь не авторизован, сохраняем действие и переходим к авторизации');
      _pendingAction = actionType;
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth_selection', (route) => false);
      return;
    }

    // Выполняем действие
    _executeAction(actionType);
  }

  void _executeAction(String actionType) {
    debugPrint('⚡ Выполняем действие: $actionType');

    switch (actionType) {
      case 'create_note':
        _navigateToCreateNote();
        break;
      case 'view_notes':
        _navigateToViewNotes();
        break;
      default:
        debugPrint('❓ Неизвестное действие: $actionType');
    }

    // Очищаем pending действие
    _pendingAction = null;
  }

  void _navigateToCreateNote() {
    debugPrint('📝 Переход к созданию заметки');

    // Сначала переходим на главный экран
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);

    // Небольшая задержка для завершения навигации
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
    debugPrint('📋 Переход к просмотру заметок');

    // Сначала переходим на главный экран
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);

    // Небольшая задержка для завершения навигации
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

  // Метод для выполнения отложенного действия после успешной авторизации
  void executePendingAction() {
    if (_pendingAction != null) {
      debugPrint('🔄 Выполняем отложенное действие: $_pendingAction');
      final action = _pendingAction!;
      _pendingAction = null;

      // Небольшая задержка, чтобы дать приложению время на переход к главному экрану
      Future.delayed(const Duration(milliseconds: 1000), () {
        _executeAction(action);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // НОВОЕ: Обработка изменений состояния приложения для уведомлений
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

  // НОВАЯ ФУНКЦИЯ: Обработка возобновления приложения
  void _onAppResumed() {
    debugPrint('📱 Приложение возобновлено');

    try {
      // Обновляем бейдж при возобновлении приложения
      final notificationService = NotificationService();
      final unreadCount = notificationService.getUnreadCount();

      if (unreadCount == 0) {
        final pushService = LocalPushNotificationService();
        pushService.clearBadge();
      }
    } catch (e) {
      debugPrint('❌ Ошибка обновления бейджа при возобновлении: $e');
    }
  }

  // НОВАЯ ФУНКЦИЯ: Обработка паузы приложения
  void _onAppPaused() {
    debugPrint('📱 Приложение на паузе');
    // Здесь можно сохранить текущее состояние
  }

  // НОВАЯ ФУНКЦИЯ: Обработка закрытия приложения
  void _onAppDetached() {
    debugPrint('📱 Приложение закрывается');
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

          // Добавляем обработчик для полной перезагрузки при смене языка
          builder: (context, widget) {
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
              iconTheme: IconThemeData(
                color: AppConstants.textColor,
              ),
            ),
            cardTheme: CardTheme(
              color: AppConstants.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.textColor,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppConstants.surfaceColor,
              hintStyle: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                borderSide: BorderSide(color: AppConstants.textColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          // Начальный экран приложения
          home: SplashScreenWithPendingAction(
            onAppReady: () {
              // Выполняем отложенное действие после загрузки приложения
              if (_pendingAction != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _handleShortcutAction(_pendingAction!);
                });
              }
            },
          ),

          // Определение маршрутов для навигации
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

  const SplashScreenWithPendingAction({
    super.key,
    required this.onAppReady,
  });

  @override
  State<SplashScreenWithPendingAction> createState() => _SplashScreenWithPendingActionState();
}

class _SplashScreenWithPendingActionState extends State<SplashScreenWithPendingAction> {
  @override
  void initState() {
    super.initState();
    // Вызываем коллбэк после инициализации
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

  const LoginScreenWithCallback({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return LoginScreen(onAuthSuccess: onAuthSuccess);
  }
}

class RegisterScreenWithCallback extends StatelessWidget {
  final VoidCallback onAuthSuccess;

  const RegisterScreenWithCallback({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(onAuthSuccess: onAuthSuccess);
  }
}