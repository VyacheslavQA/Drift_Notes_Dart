// Путь: lib/screens/marker_maps/quick_import_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/marker_map_share/marker_map_share_service.dart';
import '../../repositories/marker_map_repository.dart';
import 'marker_map_import_preview_screen.dart';
import '../auth/auth_selection_screen.dart';
import '../subscription/paywall_screen.dart';

class QuickImportScreen extends StatefulWidget {
  final String filePath;

  const QuickImportScreen({
    super.key,
    required this.filePath,
  });

  @override
  State<QuickImportScreen> createState() => _QuickImportScreenState();
}

class _QuickImportScreenState extends State<QuickImportScreen>
    with TickerProviderStateMixin {

  // Контроллеры для анимаций
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // Состояние процесса
  String _currentStep = 'initializing';
  String _statusMessage = '';
  bool _hasError = false;
  String? _errorMessage;
  double _progress = 0.0;
  bool _importStarted = false;

  // Сервисы
  final _firebaseService = FirebaseService();
  final _markerMapRepository = MarkerMapRepository();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // НЕ вызываем _startImportProcess здесь!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Безопасно вызываем импорт здесь
    if (!_importStarted) {
      _importStarted = true;
      _startImportProcess();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Инициализация анимаций
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  /// 🚀 Главный процесс быстрого импорта
  Future<void> _startImportProcess() async {
    try {
      debugPrint('🚀 QuickImportScreen: Начинаем быстрый импорт ${widget.filePath}');

      final localizations = AppLocalizations.of(context);

      // Шаг 1: Проверка файла
      await _updateProgress('file_check', localizations.translate('checking_file'), 0.1);
      await _checkFile();

      // Шаг 2: Инициализация критических сервисов
      await _updateProgress('services_init', localizations.translate('initializing_services'), 0.3);
      await _initializeCriticalServices();

      // Шаг 3: Проверка авторизации (быстро)
      await _updateProgress('auth_check', localizations.translate('checking_authorization'), 0.5);
      final authResult = await _checkAuthentication();

      if (!authResult) {
        // Пользователь не авторизован - показываем специальный экран
        await _showUnauthenticatedImport();
        return;
      }

      // Шаг 4: Проверка Premium статуса
      await _updateProgress('premium_check', localizations.translate('checking_subscription'), 0.7);
      final premiumResult = await _checkPremiumAccess();

      if (!premiumResult) {
        // Нет Premium - показываем paywall
        await _showPremiumRequired();
        return;
      }

      // Шаг 5: Парсинг файла
      await _updateProgress('file_parse', localizations.translate('processing_map'), 0.9);
      final importResult = await _parseImportFile();

      // Шаг 6: Переход к превью
      await _updateProgress('complete', localizations.translate('ready'), 1.0);
      await _navigateToPreview(importResult);

    } catch (e) {
      debugPrint('❌ Ошибка быстрого импорта: $e');
      final localizations = AppLocalizations.of(context);
      _showError('${localizations.translate('import_error_title')}: $e');
    }
  }

  /// Обновление прогресса с анимацией
  Future<void> _updateProgress(String step, String message, double progress) async {
    if (!mounted) return;

    setState(() {
      _currentStep = step;
      _statusMessage = message;
      _progress = progress;
    });

    debugPrint('📊 QuickImport progress: $step ($progress) - $message');

    // Анимируем прогресс
    _progressController.animateTo(progress);

    // Небольшая задержка для визуального эффекта
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Проверка существования файла
  Future<void> _checkFile() async {
    final file = File(widget.filePath);

    if (!await file.exists()) {
      throw Exception('Файл карты не найден');
    }

    // 🚀 ИСПРАВЛЕНО: Проверяем .driftnotes вместо .fmm
    if (!widget.filePath.toLowerCase().endsWith('.driftnotes')) {
      throw Exception('Неверный формат файла. Ожидается .driftnotes файл');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('Файл карты пустой');
    }

    debugPrint('✅ Файл проверен: ${fileSize} байт');
  }

  /// Инициализация только критических сервисов для импорта
  Future<void> _initializeCriticalServices() async {
    try {
      // Всегда инициализируем MarkerMapRepository (метод сам проверяет нужно ли)
      await _markerMapRepository.initialize();
      debugPrint('✅ MarkerMapRepository инициализирован');
    } catch (e) {
      debugPrint('⚠️ Ошибка инициализации сервисов: $e');
      // Продолжаем - репозиторий может работать в legacy режиме
    }
  }

  /// Быстрая проверка авторизации
  Future<bool> _checkAuthentication() async {
    try {
      return _firebaseService.isUserLoggedIn;
    } catch (e) {
      debugPrint('⚠️ Ошибка проверки авторизации: $e');
      return false;
    }
  }

  /// Проверка Premium доступа
  Future<bool> _checkPremiumAccess() async {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      // Всегда инициализируем SubscriptionProvider (он сам проверяет что нужно)
      subscriptionProvider.setFirebaseService(_firebaseService);
      await subscriptionProvider.initialize();

      return subscriptionProvider.hasPremiumAccess;
    } catch (e) {
      debugPrint('⚠️ Ошибка проверки Premium статуса: $e');
      return false;
    }
  }

  /// Парсинг файла импорта
  Future<ImportResult> _parseImportFile() async {
    final importResult = await MarkerMapShareService.parseMarkerMapFile(widget.filePath);

    if (!importResult.isSuccess || importResult.markerMap == null) {
      throw Exception(importResult.error ?? 'Не удалось обработать файл карты');
    }

    debugPrint('✅ Файл успешно обработан: ${importResult.markerMap!.markers.length} маркеров');
    return importResult;
  }

  /// Переход к экрану превью импорта
  Future<void> _navigateToPreview(ImportResult importResult) async {
    if (!mounted) return;

    // Небольшая задержка для завершения анимации
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerMapImportPreviewScreen(
          importResult: importResult,
          sourceFilePath: widget.filePath,
        ),
      ),
    );
  }

  /// Показ экрана для неавторизованных пользователей
  Future<void> _showUnauthenticatedImport() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);

    // Можно создать специальный экран или показать диалог
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('authorization_required'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('authorization_required_message'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAuth();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text(
              localizations.translate('login'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Показ экрана Premium required
  Future<void> _showPremiumRequired() async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(
          contentType: 'marker_map_sharing',
          blockedFeature: 'Импорт маркерных карт',
        ),
      ),
    );
  }

  /// Переход к авторизации
  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AuthSelectionScreen(
          onAuthSuccess: () {
            // После успешной авторизации перезапускаем импорт
            _importStarted = false;
            _startImportProcess();
          },
        ),
      ),
    );
  }

  /// Показ ошибки
  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    debugPrint('❌ QuickImport error: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
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
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: _hasError ? _buildErrorScreen() : _buildImportScreen(),
          ),
        ),
      ),
    );
  }

  /// Экран импорта с прогрессом
  Widget _buildImportScreen() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированная иконка
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.primaryColor.withOpacity(0.2),
                      border: Border.all(
                        color: AppConstants.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: AppConstants.primaryColor,
                      size: 60,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Заголовок
            Text(
              localizations.translate('import_in_progress'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Статус
            Text(
              _statusMessage,
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Прогресс бар
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppConstants.textColor.withOpacity(0.2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                AppConstants.primaryColor,
                                AppConstants.primaryColor.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(_progressAnimation.value * 100).round()}%',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Подсказка
            Text(
              localizations.translate('preparing_import'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Экран ошибки
  Widget _buildErrorScreen() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка ошибки
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
                border: Border.all(
                  color: Colors.red,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 60,
              ),
            ),

            const SizedBox(height: 40),

            // Заголовок ошибки
            Text(
              localizations.translate('import_error_title'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Сообщение об ошибке
            Text(
              _errorMessage ?? localizations.translate('unknown_error'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Кнопки действий
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = null;
                        _progress = 0;
                        _importStarted = false;
                      });
                      _startImportProcess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localizations.translate('retry'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Закрываем приложение или переходим на главный экран
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/splash',
                            (route) => false,
                      );
                    },
                    child: Text(
                      localizations.translate('close'),
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}