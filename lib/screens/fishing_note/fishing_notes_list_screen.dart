// Путь: lib/screens/fishing_note/fishing_notes_list_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../models/subscription_model.dart';
import '../../repositories/fishing_note_repository.dart'; // ИСПРАВЛЕНО: используем repository для офлайн поддержки
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/universal_image.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/subscription/premium_create_button.dart';
import '../../widgets/subscription/usage_badge.dart';
import '../../localization/app_localizations.dart';
import '../subscription/paywall_screen.dart';
import 'fishing_type_selection_screen.dart';
import 'fishing_note_detail_screen.dart';
// 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Добавляем импорты для Provider
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';

class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({super.key});

  @override
  State<FishingNotesListScreen> createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen>
    with SingleTickerProviderStateMixin {
  // ИСПРАВЛЕНО: используем FishingNoteRepository вместо FirebaseService
  final _fishingNoteRepository = FishingNoteRepository();
  final _subscriptionService = SubscriptionService();

  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 🔥 ДОБАВЛЕНО: Кэширование для предотвращения множественных вызовов
  SubscriptionStatus? _cachedSubscriptionStatus;
  int? _cachedTotalUsage; // 🚨 ИСПРАВЛЕНО: серверное + офлайн использование
  int? _cachedLimit;
  bool _subscriptionDataLoaded = false;
  bool? _cachedHasPremium;
  bool? _cachedCanCreate; // 🚨 НОВОЕ: кэшируем результат проверки лимитов

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 🚨 ИСПРАВЛЕНО: Сначала загружаем данные подписки, ПОТОМ заметки
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Объединенная загрузка данных
  Future<void> _loadData() async {
    try {
      debugPrint('🔄 FishingNotesListScreen: Начинаем загрузку данных...');

      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Загружаем данные подписки
      await _loadSubscriptionData();

      // 2. 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Загружаем заметки из Repository
      await _loadNotesFromRepository();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }

      debugPrint('✅ FishingNotesListScreen: Все данные загружены успешно');
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка загрузки: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Получение ОБЩЕГО использования (серверное + офлайн)
  Future<void> _loadSubscriptionData() async {
    try {
      debugPrint('🔄 Загружаем данные подписки...');

      final subscription = await _subscriptionService.loadCurrentSubscription();
      _cachedSubscriptionStatus = subscription.status;
      _cachedHasPremium = _subscriptionService.hasPremiumAccess();

      // 🚨 ИСПРАВЛЕНО: Получаем ОБЩЕЕ использование с учетом офлайн счетчиков
      _cachedTotalUsage = await _subscriptionService.getCurrentOfflineUsage(ContentType.fishingNotes);
      _cachedLimit = _subscriptionService.getLimit(ContentType.fishingNotes);

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем офлайн проверку лимитов
      _cachedCanCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

      _subscriptionDataLoaded = true;

      debugPrint('🔍 ПРОВЕРКА ЛИМИТОВ: usage=$_cachedTotalUsage, limit=$_cachedLimit, canCreate=$_cachedCanCreate, premium=$_cachedHasPremium');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки данных подписки: $e');
      _subscriptionDataLoaded = true;
    }
  }

  // 🚨 НОВЫЙ МЕТОД: Загрузка заметок из Repository
  Future<void> _loadNotesFromRepository() async {
    try {
      debugPrint('🔄 Загружаем заметки из Repository...');

      // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Получаем заметки из Repository
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      debugPrint('✅ Получено заметок из Repository: ${notes.length}');

      // Выводим список полученных заметок для отладки
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        debugPrint('📋 Заметка ${i + 1}: ${note.id} - ${note.location} (${note.date})');
      }

      if (mounted) {
        setState(() {
          _notes = notes; // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Устанавливаем заметки в состояние!
        });
      }

      debugPrint('✅ Заметки успешно установлены в UI состояние');
    } catch (e) {
      debugPrint('❌ КРИТИЧЕСКАЯ ошибка загрузки заметок из Repository: $e');

      // В случае ошибки устанавливаем пустой список
      if (mounted) {
        setState(() {
          _notes = [];
        });
      }

      rethrow;
    }
  }

  // 🚨 УПРОЩЕН: Теперь только обновляем данные
  Future<void> _loadNotes() async {
    await _loadData();
  }

  // Обработка ошибок с более понятными сообщениями
  String _getErrorMessage(dynamic error) {
    final localizations = AppLocalizations.of(context);

    if (error.toString().contains('Пользователь не авторизован')) {
      return localizations.translate('user_not_authorized');
    } else if (error.toString().contains('permission-denied')) {
      return localizations.translate('access_denied');
    } else if (error.toString().contains('network') ||
        error.toString().contains('No internet')) {
      return localizations.translate('no_internet_connection');
    } else {
      return '${localizations.translate('error_loading')}: ${error.toString()}';
    }
  }

  // 🚨 ИСПРАВЛЕНО: Проверяем лимиты ПЕРЕД созданием заметки
  Future<void> _addNewNote() async {
    // 🚨 КРИТИЧЕСКАЯ ПРОВЕРКА: можем ли создать заметку?
    final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

    if (!canCreate) {
      // 🚨 БЛОКИРУЕМ и показываем PaywallScreen
      _showPremiumRequired(ContentType.fishingNotes);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishingTypeSelectionScreen(),
      ),
    );

    if (result == true && mounted) {
      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Обновляем SubscriptionProvider после создания заметки
      try {
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        await subscriptionProvider.refreshUsageData();
        debugPrint('✅ SubscriptionProvider обновлен после создания заметки в списке');
      } catch (e) {
        debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
        // Не прерываем выполнение, заметка уже создана
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('note_created_successfully'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 🔥 ДОБАВЛЕНО: Обновляем кэш после создания заметки
      await _refreshNotesList();
    }
  }

  // 🚨 ИСПРАВЛЕН: Полная перезагрузка данных и заметок
  Future<void> _refreshNotesList() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 FishingNotesListScreen: Обновление данных и заметок...');

      // 🚨 ИСПРАВЛЕНО: Полная перезагрузка всех данных
      await _loadData();

      debugPrint('✅ FishingNotesListScreen: Данные и заметки обновлены');
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка обновления: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _viewNoteDetails(FishingNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingNoteDetailScreen(noteId: note.id),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _refreshNotesList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        // Заголовок с бейджем использования
        title: Row(
          children: [
            Expanded(
              child: Text(
                localizations.translate('my_notes'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isSmallScreen ? 20 : (isTablet ? 26 : 24),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // 🔥 ИСПРАВЛЕНО: Кэшированный бейдж использования с ОБЩИМ счетчиком
            if (_subscriptionDataLoaded) _buildUsageBadge(isSmallScreen),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isTablet ? kToolbarHeight + 8 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: isSmallScreen ? 24 : 28,
          ),
          onPressed: () => Navigator.pop(context),
          constraints: BoxConstraints(
            minWidth: ResponsiveConstants.minTouchTarget,
            minHeight: ResponsiveConstants.minTouchTarget,
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: RefreshIndicator(
          onRefresh: () async {
            _animationController.reset();
            await _loadData(); // 🚨 ИСПРАВЛЕНО: Загружаем ВСЕ данные
          },
          color: AppConstants.primaryColor,
          backgroundColor: AppConstants.surfaceColor,
          child: _errorMessage != null
              ? _buildErrorState()
              : _notes.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: EdgeInsets.all(
                isSmallScreen ? 12 : 16,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                // 🚨 ИСПРАВЛЕНО: Убрали бесконечные перестройки
                return _buildNoteCard(_notes[index]);
              },
            ),
          ),
        ),
      ),
      // 🚨 ИСПРАВЛЕНО: Используем кэшированный результат проверки лимитов
      floatingActionButton: _subscriptionDataLoaded
          ? _buildFloatingActionButton()
          : null,
    );
  }

  // 🔥 ИСПРАВЛЕНО: Бейдж использования показывает ОБЩЕЕ использование
  Widget _buildUsageBadge(bool isSmallScreen) {
    if (_cachedHasPremium == true) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 8,
          vertical: isSmallScreen ? 2 : 4,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars,
              color: Colors.white,
              size: isSmallScreen ? 12 : 14,
            ),
            const SizedBox(width: 4),
            Text(
              '∞',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final usage = _cachedTotalUsage ?? 0; // 🚨 ИСПРАВЛЕНО: ОБЩЕЕ использование
    final limit = _cachedLimit ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: limit > 0 && (usage / limit) >= 0.8
            ? Colors.orange.withOpacity(0.9)
            : AppConstants.primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$usage/$limit',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🚨 ИСПРАВЛЕНО: Используем кэшированный результат проверки лимитов
  Widget _buildFloatingActionButton() {
    final canCreate = _cachedCanCreate ?? false; // 🚨 ИСПРАВЛЕНО: используем кэшированный результат

    return FloatingActionButton(
      onPressed: canCreate ? _addNewNote : () => _showPremiumRequired(ContentType.fishingNotes), // 🚨 ИСПРАВЛЕНО: показываем PaywallScreen
      backgroundColor: canCreate
          ? AppConstants.primaryColor
          : Colors.grey,
      foregroundColor: AppConstants.textColor,
      heroTag: "add_fishing_note",
      child: Icon(
        canCreate ? Icons.add : Icons.lock,
        size: 28,
      ),
    );
  }

  // 🚨 ИСПРАВЛЕНО: Показываем PaywallScreen как в HomeScreen
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

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? 40 : 48,
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            SizedBox(
              height: ResponsiveConstants.minTouchTarget,
              child: ElevatedButton(
                onPressed: () {
                  _animationController.reset();
                  _loadData(); // 🚨 ИСПРАВЛЕНО: Загружаем ВСЕ данные
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                ),
                child: Text(
                  localizations.translate('try_again'),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.set_meal,
                color: AppConstants.textColor.withValues(alpha: 0.5),
                size: isSmallScreen ? 60 : (isTablet ? 100 : 80),
              ),
              SizedBox(height: ResponsiveConstants.spacingL),
              Text(
                localizations.translate('no_notes'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isSmallScreen ? 18 : (isTablet ? 26 : 22),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveConstants.spacingM),
              Text(
                localizations.translate('start_journal'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveConstants.spacingXL),

              // 🚨 ИСПРАВЛЕНО: Используем кэшированный результат проверки лимитов
              if (_subscriptionDataLoaded)
                SizedBox(
                  width: double.infinity,
                  child: _buildCreateButton(localizations, isSmallScreen),
                ),

              // Индикатор лимитов под кнопкой
              SizedBox(height: ResponsiveConstants.spacingM),
              if (_subscriptionDataLoaded) _buildLimitIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // 🚨 ИСПРАВЛЕНО: Используем кэшированный результат проверки лимитов
  Widget _buildCreateButton(AppLocalizations localizations, bool isSmallScreen) {
    final canCreate = _cachedCanCreate ?? false; // 🚨 ИСПРАВЛЕНО: используем кэш

    return ElevatedButton.icon(
      onPressed: canCreate ? _addNewNote : () => _showPremiumRequired(ContentType.fishingNotes), // 🚨 ИСПРАВЛЕНО: PaywallScreen
      style: ElevatedButton.styleFrom(
        backgroundColor: canCreate
            ? AppConstants.primaryColor
            : Colors.grey,
        foregroundColor: AppConstants.textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 24,
          vertical: 16,
        ),
      ),
      icon: Icon(
        canCreate ? Icons.add : Icons.lock,
        size: isSmallScreen ? 20 : 24,
      ),
      label: Text(
        canCreate
            ? localizations.translate('create_first_note')
            : localizations.translate('upgrade_to_premium'),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔥 ИСПРАВЛЕНО: Индикатор лимитов с ОБЩИМ использованием
  Widget _buildLimitIndicator() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    if (_cachedHasPremium == true) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars,
              color: Colors.white,
              size: isSmallScreen ? 16 : 20,
            ),
            SizedBox(width: ResponsiveConstants.spacingS),
            Text(
              localizations.translate('premium_unlimited_notes'),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final usage = _cachedTotalUsage ?? 0; // 🚨 ИСПРАВЛЕНО: ОБЩЕЕ использование
    final limit = _cachedLimit ?? 0;
    final remaining = limit - usage;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: isSmallScreen ? 16 : 20,
              ),
              SizedBox(width: ResponsiveConstants.spacingS),
              Text(
                remaining > 0
                    ? '${localizations.translate('you_can_create')} $remaining ${localizations.translate('more_notes')}'
                    : localizations.translate('limit_reached'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit > 0 ? (usage / limit).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                limit > 0 && (usage / limit) >= 0.8
                    ? Colors.orange
                    : AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    final biggestFish = note.biggestFish;

    String photoUrl = '';
    if (note.coverPhotoUrl.isNotEmpty) {
      photoUrl = note.coverPhotoUrl;
    } else if (note.photoUrls.isNotEmpty) {
      photoUrl = note.photoUrls.first;
    }

    final cropSettings = note.coverCropSettings;

    return Card(
      margin: EdgeInsets.only(
        bottom: isSmallScreen ? 12 : 16,
      ),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () => _viewNoteDetails(note),
        splashColor: AppConstants.primaryColor.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фотография - адаптивная высота
            if (photoUrl.isNotEmpty)
              SizedBox(
                height: isSmallScreen ? 140 : (isTablet ? 200 : 170),
                width: double.infinity,
                child: _buildCoverImage(photoUrl, cropSettings),
              ),

            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Тип рыбалки и дата - адаптивная обертка
                  isSmallScreen
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFishingTypeChip(note, localizations),
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      _buildDateChip(note, localizations),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildFishingTypeChip(note, localizations),
                      ),
                      SizedBox(width: ResponsiveConstants.spacingS),
                      _buildDateChip(note, localizations),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 8 : 12),

                  // Место рыбалки / название
                  Text(
                    note.title.isNotEmpty ? note.title : note.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isSmallScreen ? 16 : (isTablet ? 22 : 20),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: isSmallScreen ? 8 : 12),

                  // Количество поклевок и фото - адаптивная обертка
                  isSmallScreen
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBiteRecordsInfo(note),
                      if (note.photoUrls.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.spacingS),
                        _buildPhotosInfo(note, localizations),
                      ],
                    ],
                  )
                      : Wrap(
                    spacing: ResponsiveConstants.spacingM,
                    runSpacing: ResponsiveConstants.spacingS,
                    children: [
                      _buildBiteRecordsInfo(note),
                      if (note.photoUrls.isNotEmpty)
                        _buildPhotosInfo(note, localizations),
                    ],
                  ),

                  // Информация о самой крупной рыбе
                  if (biggestFish != null) ...[
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildBiggestFishInfo(biggestFish, localizations),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Все остальные helper методы остаются без изменений
  Widget _buildFishingTypeChip(FishingNoteModel note, AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        localizations.translate(note.fishingType),
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildDateChip(FishingNoteModel note, AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        note.isMultiDay
            ? DateFormatter.formatDateRange(note.date, note.endDate!, context)
            : DateFormatter.formatDate(note.date, context),
        style: TextStyle(
          color: AppConstants.textColor.withValues(alpha: 0.9),
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildBiteRecordsInfo(FishingNoteModel note) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.set_meal,
            color: AppConstants.textColor,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingS),
        Flexible(
          child: Text(
            '${note.biteRecords.length} ${_getBiteRecordsText(note.biteRecords.length)}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosInfo(FishingNoteModel note, AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.photo_library,
            color: AppConstants.textColor,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingS),
        Flexible(
          child: Text(
            '${note.photoUrls.length} ${localizations.translate('photos')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBiggestFishInfo(dynamic biggestFish, AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: ResponsiveConstants.spacingS),
              Expanded(
                child: Text(
                  localizations.translate('biggest_fish_caught'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          if (biggestFish.fishType.isNotEmpty)
            Text(
              biggestFish.fishType,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          SizedBox(height: ResponsiveConstants.spacingXS),
          isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFishMeasurement(
                Icons.scale,
                '${biggestFish.weight} ${localizations.translate('kg')}',
              ),
              if (biggestFish.length > 0) ...[
                SizedBox(height: ResponsiveConstants.spacingXS),
                _buildFishMeasurement(
                  Icons.straighten,
                  '${biggestFish.length} см',
                ),
              ],
            ],
          )
              : Row(
            children: [
              _buildFishMeasurement(
                Icons.scale,
                '${biggestFish.weight} ${localizations.translate('kg')}',
              ),
              if (biggestFish.length > 0) ...[
                SizedBox(width: ResponsiveConstants.spacingM),
                _buildFishMeasurement(
                  Icons.straighten,
                  '${biggestFish.length} см',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFishMeasurement(IconData icon, String text) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withValues(alpha: 0.7),
          size: isSmallScreen ? 14 : 16,
        ),
        SizedBox(width: ResponsiveConstants.spacingXS),
        Text(
          text,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getBiteRecordsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поклевка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'поклевки';
    } else {
      return 'поклевок';
    }
  }

  Widget _buildCoverImage(String photoUrl, Map<String, dynamic>? cropSettings) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    if (cropSettings == null) {
      return UniversalImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
            strokeWidth: isSmallScreen ? 2.0 : 3.0,
          ),
        ),
        errorWidget: Container(
          color: AppConstants.backgroundColor.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[400],
                  size: isSmallScreen ? 32 : 40,
                ),
                SizedBox(height: ResponsiveConstants.spacingS),
                Text(
                  AppLocalizations.of(context).translate('image_unavailable'),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final offsetX = cropSettings['offsetX'] as double? ?? 0.0;
    final offsetY = cropSettings['offsetY'] as double? ?? 0.0;
    final scale = cropSettings['scale'] as double? ?? 1.0;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: UniversalImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                strokeWidth: isSmallScreen ? 2.0 : 3.0,
              ),
            ),
            errorWidget: Container(
              color: AppConstants.backgroundColor.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey[400],
                      size: isSmallScreen ? 32 : 40,
                    ),
                    SizedBox(height: ResponsiveConstants.spacingS),
                    Text(
                      AppLocalizations.of(context).translate('image_unavailable'),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательный метод для создания FishingWeather из Map данных
  FishingWeather _createFishingWeather(Map<String, dynamic> weatherData) {
    // Обрабатываем observationTime правильно
    DateTime observationTime;

    final observationTimeData = weatherData['observationTime'];
    if (observationTimeData is int) {
      // Если это timestamp (миллисекунды)
      observationTime = DateTime.fromMillisecondsSinceEpoch(observationTimeData);
    } else if (observationTimeData is String) {
      // Если это строка ISO 8601
      try {
        observationTime = DateTime.parse(observationTimeData);
      } catch (e) {
        observationTime = DateTime.now();
      }
    } else {
      // Fallback значение
      observationTime = DateTime.now();
    }

    return FishingWeather(
      temperature: (weatherData['temperature'] ?? 0.0).toDouble(),
      feelsLike: (weatherData['feelsLike'] ?? 0.0).toDouble(),
      humidity: (weatherData['humidity'] ?? 0).toInt(),
      pressure: (weatherData['pressure'] ?? 0.0).toDouble(),
      windSpeed: (weatherData['windSpeed'] ?? 0.0).toDouble(),
      windDirection: weatherData['windDirection'] ?? '',
      cloudCover: (weatherData['cloudCover'] ?? 0).toInt(),
      sunrise: weatherData['sunrise'] ?? '',
      sunset: weatherData['sunset'] ?? '',
      isDay: weatherData['isDay'] ?? true,
      observationTime: observationTime, // Передаем DateTime вместо строки
    );
  }
}