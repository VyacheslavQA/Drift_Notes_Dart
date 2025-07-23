// Путь: lib/screens/fishing_note/fishing_notes_list_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/universal_image.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';
import 'fishing_type_selection_screen.dart';
import 'fishing_note_detail_screen.dart';
// ✅ ИСПРАВЛЕНО: Добавляем импорты для новой системы лимитов
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';
import '../subscription/paywall_screen.dart';
// ✅ ДОБАВЛЕНО: Импорты для Isar синхронизации
import '../../services/offline/sync_service.dart';
import '../../utils/network_utils.dart';

class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({super.key});

  @override
  State<FishingNotesListScreen> createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen>
    with SingleTickerProviderStateMixin {
  // ✅ ИСПРАВЛЕНО: Добавляем сервис для проверки лимитов
  final _fishingNoteRepository = FishingNoteRepository();
  final _subscriptionService = SubscriptionService();
  // ✅ ДОБАВЛЕНО: Новый SyncService для Isar
  final _syncService = SyncService.instance;

  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;
  // ✅ ДОБАВЛЕНО: Состояние синхронизации
  bool _isSyncing = false;
  Map<String, dynamic>? _syncStatus;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _loadNotes();
    // ✅ ДОБАВЛЕНО: Запускаем синхронизацию при открытии экрана
    _performInitialSync();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ НОВЫЙ МЕТОД: Начальная синхронизация при открытии экрана
  Future<void> _performInitialSync() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        debugPrint('🔄 FishingNotesListScreen: Запуск начальной синхронизации...');

        setState(() {
          _isSyncing = true;
        });

        // Запускаем полную синхронизацию
        final success = await _syncService.fullSync();

        if (success) {
          debugPrint('✅ FishingNotesListScreen: Синхронизация завершена успешно');
          // Обновляем список после синхронизации
          await _loadNotes();
        } else {
          debugPrint('⚠️ FishingNotesListScreen: Синхронизация завершена с ошибками');
        }

        // Получаем статус синхронизации
        final syncStatus = await _syncService.getSyncStatus();

        if (mounted) {
          setState(() {
            _syncStatus = syncStatus;
            _isSyncing = false;
          });
        }
      } else {
        debugPrint('📱 FishingNotesListScreen: Офлайн режим - синхронизация пропущена');
      }
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка синхронизации: $e');

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  // ✅ НОВЫЙ МЕТОД: Принудительная синхронизация
  Future<void> _forceSyncData() async {
    try {
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('no_internet_connection'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _isSyncing = true;
      });

      debugPrint('🔄 FishingNotesListScreen: Принудительная синхронизация...');

      final success = await _fishingNoteRepository.forceSyncData();

      if (success) {
        debugPrint('✅ FishingNotesListScreen: Принудительная синхронизация успешна');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('sync_completed'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Обновляем список
        await _loadNotes();
      } else {
        debugPrint('⚠️ FishingNotesListScreen: Принудительная синхронизация с ошибками');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('sync_error'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Обновляем статус синхронизации
      final syncStatus = await _fishingNoteRepository.getSyncStatus();

      if (mounted) {
        setState(() {
          _syncStatus = syncStatus;
          _isSyncing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка принудительной синхронизации: $e');

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('sync_error')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔄 FishingNotesListScreen: Загружаем заметки...');

      final notes = await _fishingNoteRepository.getUserFishingNotes();

      debugPrint('✅ FishingNotesListScreen: Получено заметок: ${notes.length}');

      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка загрузки: $e');

      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

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

  // ✅ ИСПРАВЛЕНО: Правильная проверка лимитов перед созданием заметки
  Future<void> _addNewNote() async {
    final localizations = AppLocalizations.of(context);

    try {
      debugPrint('🔍 FishingNotesListScreen: Проверяем лимиты перед созданием...');

      // ✅ ИСПРАВЛЕНО: Проверяем лимиты с использованием новой системы
      final canCreate = await _subscriptionService.canCreateContentOffline(ContentType.fishingNotes);

      debugPrint('📊 FishingNotesListScreen: Результат проверки лимитов: canCreate=$canCreate');

      if (!canCreate) {
        debugPrint('❌ FishingNotesListScreen: Лимит достигнут - показываем Paywall');

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaywallScreen(
                contentType: 'fishing_notes',
                blockedFeature: 'Заметки рыбалки',
              ),
            ),
          );
        }
        return;
      }

      debugPrint('✅ FishingNotesListScreen: Лимиты пройдены - переходим к созданию');

      // ✅ ИСПРАВЛЕНО: Переходим к созданию только после проверки лимитов
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FishingTypeSelectionScreen(),
        ),
      );

      if (result == true && mounted) {
        debugPrint('✅ FishingNotesListScreen: Заметка создана, обновляем данные...');

        // ✅ ИСПРАВЛЕНО: Обновляем SubscriptionProvider после создания заметки
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ FishingNotesListScreen: SubscriptionProvider обновлен');
        } catch (e) {
          debugPrint('❌ FishingNotesListScreen: Ошибка обновления SubscriptionProvider: $e');
        }

        // Показываем сообщение об успешном создании
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('note_created_successfully'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Обновляем список заметок
        await _loadNotes();

        // ✅ ДОБАВЛЕНО: Обновляем статус синхронизации после создания
        _updateSyncStatus();
      }
    } catch (e) {
      debugPrint('❌ FishingNotesListScreen: Ошибка при создании заметки: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_creating_note')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ НОВЫЙ МЕТОД: Обновление статуса синхронизации
  Future<void> _updateSyncStatus() async {
    try {
      final syncStatus = await _fishingNoteRepository.getSyncStatus();
      if (mounted) {
        setState(() {
          _syncStatus = syncStatus;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса синхронизации: $e');
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
        _loadNotes();
        _updateSyncStatus();
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
        title: Text(
          localizations.translate('my_notes'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 20 : (isTablet ? 26 : 24),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
        // ✅ ДОБАВЛЕНО: Кнопка синхронизации в AppBar
        actions: [
          // Индикатор статуса синхронизации
          if (_syncStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: _buildSyncStatusIndicator(),
              ),
            ),
          // Кнопка принудительной синхронизации
          IconButton(
            icon: _isSyncing
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
              ),
            )
                : Icon(
              Icons.sync,
              color: AppConstants.textColor,
              size: isSmallScreen ? 24 : 28,
            ),
            onPressed: _isSyncing ? null : _forceSyncData,
            tooltip: localizations.translate('sync_data'),
            constraints: BoxConstraints(
              minWidth: ResponsiveConstants.minTouchTarget,
              minHeight: ResponsiveConstants.minTouchTarget,
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadNotes();
            await _performInitialSync();
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
                return _buildNoteCard(_notes[index]);
              },
            ),
          ),
        ),
      ),
      // ✅ ИСПРАВЛЕНО: Floating Action Button с проверкой лимитов
      floatingActionButton: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          final canCreate = subscriptionProvider.canCreateContentSync(ContentType.fishingNotes);
          final usage = subscriptionProvider.getUsage(ContentType.fishingNotes) ?? 0;
          final limit = subscriptionProvider.getLimit(ContentType.fishingNotes);

          return Stack(
            alignment: Alignment.center,
            children: [
              FloatingActionButton(
                onPressed: _addNewNote,
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                heroTag: "add_fishing_note",
                child: const Icon(Icons.add, size: 28),
              ),
              // ✅ ИСПРАВЛЕНО: Показываем индикатор лимитов на FAB
              if (!subscriptionProvider.hasPremiumAccess) ...[
                // Индикатор блокировки
                if (!canCreate)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                // Индикатор использования
                if (canCreate)
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
                        '$usage/$limit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ✅ НОВЫЙ МЕТОД: Индикатор статуса синхронизации
  Widget _buildSyncStatusIndicator() {
    if (_syncStatus == null) return const SizedBox.shrink();

    final total = _syncStatus!['total'] as int? ?? 0;
    final unsynced = _syncStatus!['unsynced'] as int? ?? 0;
    final hasInternet = _syncStatus!['hasInternet'] as bool? ?? false;

    Color statusColor;
    IconData statusIcon;
    String tooltip;

    if (!hasInternet) {
      statusColor = Colors.orange;
      statusIcon = Icons.cloud_off;
      tooltip = 'Офлайн режим';
    } else if (unsynced > 0) {
      statusColor = Colors.yellow;
      statusIcon = Icons.sync_problem;
      tooltip = 'Не синхронизировано: $unsynced';
    } else if (total > 0) {
      statusColor = Colors.green;
      statusIcon = Icons.cloud_done;
      tooltip = 'Все синхронизировано';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cloud_queue;
      tooltip = 'Нет данных';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          if (unsynced > 0) ...[
            const SizedBox(width: 4),
            Text(
              unsynced.toString(),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
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
                  _loadNotes();
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

              // ✅ ИСПРАВЛЕНО: Кнопка создания с проверкой лимитов
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final canCreate = subscriptionProvider.canCreateContentSync(ContentType.fishingNotes);
                  final usage = subscriptionProvider.getUsage(ContentType.fishingNotes) ?? 0;
                  final limit = subscriptionProvider.getLimit(ContentType.fishingNotes);

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNewNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 20 : 24,
                          vertical: 16,
                        ),
                      ),
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          // Индикатор лимитов
                          if (!subscriptionProvider.hasPremiumAccess && !canCreate)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localizations.translate('create_first_note'),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Показываем лимиты для бесплатных пользователей
                          if (!subscriptionProvider.hasPremiumAccess)
                            Text(
                              canCreate
                                  ? '($usage/$limit)'
                                  : '(${localizations.translate('limit_reached')})',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppConstants.textColor.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Остальные методы остаются без изменений...
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
}