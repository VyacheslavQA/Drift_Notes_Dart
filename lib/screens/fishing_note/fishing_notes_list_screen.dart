// Путь: lib/screens/fishing_note/fishing_notes_list_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../models/subscription_model.dart';
import '../../services/firebase/firebase_service.dart'; // ИЗМЕНЕНО: заменил repository на service
import '../../services/subscription/subscription_service.dart';
import '../../constants/subscription_constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/universal_image.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/subscription/premium_create_button.dart';
import '../../widgets/subscription/usage_badge.dart';
import '../../localization/app_localizations.dart';
import 'fishing_type_selection_screen.dart';
import 'fishing_note_detail_screen.dart';


class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({super.key});

  @override
  State<FishingNotesListScreen> createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _subscriptionService = SubscriptionService();

  List<FishingNoteModel> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_firebaseService.currentUserId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Пользователь не авторизован. Войдите в аккаунт.';
            _isLoading = false;
          });
        }
        return;
      }

      final querySnapshot = await _firebaseService.getUserFishingNotesNew();

      // Преобразуем QuerySnapshot в List<FishingNoteModel>
      final List<FishingNoteModel> notes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Преобразуем данные поклевок
        List<BiteRecord> biteRecords = [];
        if (data['biteRecords'] is List) {
          biteRecords = (data['biteRecords'] as List).map((record) {
            if (record is Map<String, dynamic>) {
              return BiteRecord(
                id: record['id'] ?? '',
                time: record['time'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(record['time'])
                    : DateTime.now(),
                fishType: record['fishType'] ?? '',
                weight: (record['weight'] ?? 0).toDouble(),
                length: (record['length'] ?? 0).toDouble(),
                notes: record['notes'] ?? '',
                photoUrls: List<String>.from(record['photoUrls'] ?? []),
              );
            }
            return BiteRecord(
              id: '',
              time: DateTime.now(),
              fishType: '',
              weight: 0.0,
              length: 0.0,
              notes: '',
              photoUrls: [],
            );
          }).toList();
        }

        // Создаем модель FishingNoteModel используя конструктор
        return FishingNoteModel(
          id: doc.id,
          userId: _firebaseService.currentUserId!,
          location: data['location'] ?? '',
          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          date: data['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['date'])
              : DateTime.now(),
          endDate: data['endDate'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
              : null,
          isMultiDay: data['isMultiDay'] ?? false,
          tackle: data['tackle'] ?? '',
          notes: data['notes'] ?? '',
          photoUrls: List<String>.from(data['photoUrls'] ?? []),
          fishingType: data['fishingType'] ?? '',
          weather: data['weather'] != null
              ? _createFishingWeather(data['weather'])
              : null,
          biteRecords: biteRecords,
          mapMarkers: List<Map<String, dynamic>>.from(data['mapMarkers'] ?? []),
          aiPrediction: data['aiPrediction'],
        );
      }).toList();

      if (!mounted) return;

      // Сортируем по дате создания (самые новые сверху)
      notes.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _notes = notes;
        _isLoading = false;
      });

      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {

      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
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

  Future<void> _addNewNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishingTypeSelectionScreen(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('note_created_successfully'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _refreshNotesList();
    }
  }

  // Обновлен метод для новой структуры Firebase
  Future<void> _refreshNotesList() async {
    if (!mounted) return;

    try {
      // Используем getUserFishingNotesNew() без параметра userId
      final querySnapshot = await _firebaseService.getUserFishingNotesNew();

      // Преобразуем QuerySnapshot в List<FishingNoteModel>
      final List<FishingNoteModel> notes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Преобразуем данные поклевок
        List<BiteRecord> biteRecords = [];
        if (data['biteRecords'] is List) {
          biteRecords = (data['biteRecords'] as List).map((record) {
            if (record is Map<String, dynamic>) {
              return BiteRecord(
                id: record['id'] ?? '',
                time: record['time'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(record['time'])
                    : DateTime.now(),
                fishType: record['fishType'] ?? '',
                weight: (record['weight'] ?? 0).toDouble(),
                length: (record['length'] ?? 0).toDouble(),
                notes: record['notes'] ?? '',
                photoUrls: List<String>.from(record['photoUrls'] ?? []),
              );
            }
            return BiteRecord(
              id: '',
              time: DateTime.now(),
              fishType: '',
              weight: 0.0,
              length: 0.0,
              notes: '',
              photoUrls: [],
            );
          }).toList();
        }

        // Создаем модель FishingNoteModel используя конструктор
        return FishingNoteModel(
          id: doc.id,
          userId: _firebaseService.currentUserId!,
          location: data['location'] ?? '',
          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          date: data['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['date'])
              : DateTime.now(),
          endDate: data['endDate'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
              : null,
          isMultiDay: data['isMultiDay'] ?? false,
          tackle: data['tackle'] ?? '',
          notes: data['notes'] ?? '',
          photoUrls: List<String>.from(data['photoUrls'] ?? []),
          fishingType: data['fishingType'] ?? '',
          weather: data['weather'] != null
              ? _createFishingWeather(data['weather'])
              : null,
          biteRecords: biteRecords,
          mapMarkers: List<Map<String, dynamic>>.from(data['mapMarkers'] ?? []),
          aiPrediction: data['aiPrediction'],
        );
      }).toList();

      if (!mounted) return;

      // Сортируем по дате создания (самые новые сверху)
      notes.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _notes = notes;
      });
    } catch (e) {
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
            // Бейдж использования в заголовке
            UsageBadge(
              contentType: ContentType.fishingNotes,
              fontSize: isSmallScreen ? 10 : 12,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 2 : 4,
              ),
            ),
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
            await _loadNotes();
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
                Future.delayed(Duration(milliseconds: 50 * index), () {
                  if (mounted) setState(() {});
                });
                return _buildNoteCard(_notes[index]);
              },
            ),
          ),
        ),
      ),
      // FloatingActionButton с проверкой лимитов
      floatingActionButton: PremiumFloatingActionButton(
        contentType: ContentType.fishingNotes,
        onPressed: _addNewNote,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        heroTag: "add_fishing_note",
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

              // Кнопка создания первой заметки с проверкой лимитов
              SizedBox(
                width: double.infinity,
                child: PremiumCreateButton(
                  contentType: ContentType.fishingNotes,
                  onCreatePressed: _addNewNote,
                  customText: localizations.translate('create_first_note'),
                  customIcon: Icons.add,
                  showUsageBadge: false, // В пустом состоянии не показываем бейдж
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  borderRadius: 24,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: 16,
                  ),
                ),
              ),

              // Индикатор лимитов под кнопкой
              SizedBox(height: ResponsiveConstants.spacingM),
              _buildLimitIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // Индикатор лимитов для пустого состояния
  Widget _buildLimitIndicator() {
    return StreamBuilder<SubscriptionStatus>(
      stream: _subscriptionService.subscriptionStatusStream,
      builder: (context, snapshot) {
        final localizations = AppLocalizations.of(context);
        final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

        if (_subscriptionService.hasPremiumAccess()) {
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

        // Используем синхронную версию
        final currentUsage = _subscriptionService.getCurrentUsageSync(ContentType.fishingNotes);
        final limit = _subscriptionService.getLimit(ContentType.fishingNotes);
        final remaining = limit - currentUsage;

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
                    '${localizations.translate('you_can_create')} $remaining ${localizations.translate('more_notes')}',
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
                  value: limit > 0 ? (currentUsage / limit).clamp(0.0, 1.0) : 0.0,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    limit > 0 && (currentUsage / limit) >= 0.8
                        ? Colors.orange
                        : AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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