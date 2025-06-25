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

class FishingNotesListScreen extends StatefulWidget {
  const FishingNotesListScreen({super.key});

  @override
  State<FishingNotesListScreen> createState() => _FishingNotesListScreenState();
}

class _FishingNotesListScreenState extends State<FishingNotesListScreen>
    with SingleTickerProviderStateMixin {
  final _fishingNoteRepository = FishingNoteRepository();

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
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      if (!mounted) return;

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
        _errorMessage =
        '${AppLocalizations.of(context).translate('error_loading')}: $e';
        _isLoading = false;
      });
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

  Future<void> _refreshNotesList() async {
    if (!mounted) return;

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();

      if (!mounted) return;

      notes.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _notes = notes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).translate('error_loading')}: $e',
          ),
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
        title: Text(
          localizations.translate('my_notes'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 20 : (isTablet ? 26 : 24), // Адаптивный размер
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
                isSmallScreen ? 12 : 16, // Адаптивные отступы
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
      floatingActionButton: SizedBox(
        width: isTablet ? 64 : 56, // Адаптивный размер FAB
        height: isTablet ? 64 : 56,
        child: FloatingActionButton(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          onPressed: _addNewNote,
          elevation: 4,
          splashColor: Colors.white.withValues(alpha: 0.3),
          child: Container(
            width: isTablet ? 56 : 50,
            height: isTablet ? 56 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: isTablet ? 56 : 50,
              height: isTablet ? 56 : 50,
            ),
          ),
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
              SizedBox(
                height: ResponsiveConstants.minTouchTarget,
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.add,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  label: Text(
                    localizations.translate('create_first_note'),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _addNewNote,
                ),
              ),
            ],
          ),
        ),
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
        bottom: isSmallScreen ? 12 : 16, // Адаптивные отступы между карточками
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
                      ? Column( // На маленьких экранах - вертикально
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFishingTypeChip(note, localizations),
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      _buildDateChip(note, localizations),
                    ],
                  )
                      : Row( // На больших экранах - горизонтально
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
                      ? Column( // На маленьких экранах - вертикально
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBiteRecordsInfo(note),
                      if (note.photoUrls.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.spacingS),
                        _buildPhotosInfo(note, localizations),
                      ],
                    ],
                  )
                      : Wrap( // На больших экранах - горизонтально с переносом
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

  // Вспомогательные виджеты для компонентов карточки
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
          // Адаптивное расположение веса и длины
          isSmallScreen
              ? Column( // На маленьких экранах - вертикально
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
              : Row( // На больших экранах - горизонтально
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