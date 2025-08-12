// Путь: lib/screens/fishing_diary/fishing_diary_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_diary_model.dart';
import '../../repositories/fishing_diary_repository.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../subscription/paywall_screen.dart';
import 'add_fishing_diary_screen.dart';
import 'edit_fishing_diary_screen.dart';
import 'fishing_diary_detail_screen.dart';
// 🚀 НОВЫЕ ИМПОРТЫ для шеринга
import '../../services/fishing_diary_share/fishing_diary_sharing_service.dart';
import '../../services/file_handler/driftnotes_file_handler.dart';
import 'fishing_diary_import_preview_screen.dart';

class FishingDiaryListScreen extends StatefulWidget {
  const FishingDiaryListScreen({super.key});

  @override
  State<FishingDiaryListScreen> createState() => _FishingDiaryListScreenState();

  // 🚀 НОВЫЙ СТАТИЧЕСКИЙ МЕТОД: Обработка импорта записей дневника
  static Future<void> handleDiaryImport(BuildContext context, String filePath) async {
    debugPrint('🔍 handleDiaryImport: Перенаправляем в универсальный обработчик $filePath');

    // Теперь просто вызываем универсальный обработчик
    await DriftNotesFileHandler.handleDriftNotesFile(context, filePath);
  }
}

class _FishingDiaryListScreenState extends State<FishingDiaryListScreen> {
  final FishingDiaryRepository _repository = FishingDiaryRepository();
  final TextEditingController _searchController = TextEditingController();

  List<FishingDiaryModel> _entries = [];
  List<FishingDiaryModel> _filteredEntries = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _repository.getUserFishingDiaryEntries();
      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((entry) {
        final matchesSearch = entry.title.toLowerCase().contains(query) ||
            entry.description.toLowerCase().contains(query);
        final matchesFavorites = !_showFavoritesOnly || entry.isFavorite;
        return matchesSearch && matchesFavorites;
      }).toList();
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    _filterEntries();
  }

  Future<void> _toggleFavorite(String entryId) async {
    try {
      await _repository.toggleFavorite(entryId);
      _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyEntry(FishingDiaryModel entry) async {
    try {
      await _repository.copyFishingDiaryEntry(entry.id);

      // Принудительно обновляем список записей
      await _loadEntries();

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(FishingDiaryModel entry) async {
    final localizations = AppLocalizations.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_entry'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Text(
          localizations.translate('delete_entry_confirmation'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.translate('delete_entry'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _repository.deleteFishingDiaryEntry(entry.id);
        _loadEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('entry_deleted_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 🚀 НОВЫЙ МЕТОД: Экспорт записи дневника
  Future<void> _shareDiaryEntry(FishingDiaryModel entry) async {
    final localizations = AppLocalizations.of(context);

    try {
      setState(() => _isLoading = true);

      debugPrint('📤 Начинаем экспорт записи: ${entry.title}');

      final success = await FishingDiarySharingService.exportDiaryEntry(
        diaryEntry: entry,
        context: context,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_exported_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('export_error')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка экспорта записи: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('export_error')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🚀 НОВЫЙ МЕТОД: Показ Paywall для экспорта записей
  void _showSharePaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(
          contentType: 'fishing_diary_sharing',
          blockedFeature: 'Экспорт записей дневника',
        ),
      ),
    );
  }

  // 🚀 ИСПРАВЛЕННЫЙ МЕТОД: Меню настроек записи с увеличенной высотой (без скролла)
  void _showEntryOptions(FishingDiaryModel entry) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      isScrollControlled: true, // 🚀 ДОБАВЛЕНО: Позволяет контролировать размер модального окна
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
      ),
      builder: (context) {
        return Container(
          // 🚀 ОПТИМАЛЬНО: Фиксированная высота 60% экрана - достаточно для всех элементов
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.only(
            left: ResponsiveUtils.getHorizontalPadding(context),
            right: ResponsiveUtils.getHorizontalPadding(context),
            top: ResponsiveUtils.getHorizontalPadding(context),
            bottom: ResponsiveUtils.getHorizontalPadding(context) + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            children: [
              // Заголовок меню
              Text(
                localizations.translate('entry_settings'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Просмотр записи
              ListTile(
                leading: Icon(Icons.visibility, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('entry_details'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FishingDiaryDetailScreen(entry: entry),
                    ),
                  );
                },
              ),

              // Редактирование записи
              ListTile(
                leading: Icon(Icons.edit, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('edit_diary_entry'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFishingDiaryScreen(entry: entry),
                    ),
                  ).then((_) => _loadEntries());
                },
              ),

              // 🚀 НОВАЯ КНОПКА: Поделиться записью с проверкой Premium
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, _) {
                  final hasPremium = subscriptionProvider.hasPremiumAccess;

                  return ListTile(
                    leading: Icon(
                      hasPremium ? Icons.share : Icons.share_outlined,
                      color: hasPremium
                          ? AppConstants.primaryColor
                          : AppConstants.textColor.withOpacity(0.4),
                    ),
                    title: Text(
                      localizations.translate('share_entry'),
                      style: TextStyle(
                        color: hasPremium
                            ? AppConstants.textColor
                            : AppConstants.textColor.withOpacity(0.4),
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (hasPremium) {
                        _shareDiaryEntry(entry);
                      } else {
                        _showSharePaywall();
                      }
                    },
                  );
                },
              ),

              // Копирование записи
              ListTile(
                leading: Icon(Icons.copy, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('copy_diary_entry'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyEntry(entry);
                },
              ),

              // Избранное
              ListTile(
                leading: Icon(
                  entry.isFavorite ? Icons.star : Icons.star_border,
                  color: entry.isFavorite ? AppConstants.primaryColor : AppConstants.textColor,
                ),
                title: Text(
                  entry.isFavorite
                      ? localizations.translate('remove_from_favorites')
                      : localizations.translate('add_to_favorites'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(entry.id);
                },
              ),

              const Divider(color: Colors.grey),

              // Удаление записи
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.translate('delete_entry'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEntry(entry);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('fishing_diary'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 22),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? AppConstants.primaryColor : AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _toggleFavoritesFilter,
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFishingDiaryScreen(),
                ),
              ).then((_) => _loadEntries());
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: SafeArea(
          child: Column(
            children: [
              // Поиск
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                  ),
                  decoration: InputDecoration(
                    fillColor: AppConstants.surfaceColor,
                    filled: true,
                    hintText: localizations.translate('search_diary_entries'),
                    hintStyle: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.5),
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppConstants.textColor,
                      size: ResponsiveUtils.getIconSize(context),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppConstants.textColor,
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConstants.spacingM,
                      vertical: ResponsiveConstants.spacingM,
                    ),
                  ),
                ),
              ),

              // Список записей
              Expanded(
                child: _filteredEntries.isEmpty
                    ? _buildEmptyState(localizations)
                    : RefreshIndicator(
                  onRefresh: _loadEntries,
                  color: AppConstants.primaryColor,
                  backgroundColor: AppConstants.surfaceColor,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];
                      return _buildEntryCard(entry, localizations);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFishingDiaryScreen(),
            ),
          ).then((_) => _loadEntries());
        },
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textColor,
        child: Icon(
          Icons.add,
          size: ResponsiveUtils.getIconSize(context),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingXL),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: ResponsiveUtils.getIconSize(context, baseSize: 60),
                color: AppConstants.primaryColor,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            Text(
              _searchController.text.isNotEmpty
                  ? localizations.translate('no_entries_found')
                  : localizations.translate('no_diary_entries'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            if (_searchController.text.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFishingDiaryScreen(),
                    ),
                  ).then((_) => _loadEntries());
                },
                icon: Icon(
                  Icons.add,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                label: Text(
                  localizations.translate('create_new_entry'),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveConstants.spacingL,
                    vertical: ResponsiveConstants.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🚀 ОБНОВЛЕННЫЙ МЕТОД: Карточка записи с единообразным дизайном
  Widget _buildEntryCard(FishingDiaryModel entry, AppLocalizations localizations) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FishingDiaryDetailScreen(entry: entry),
            ),
          );
        },
        onLongPress: () => _showEntryOptions(entry),
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: AppConstants.primaryColor,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isFavorite)
                          Icon(
                            Icons.star,
                            color: AppConstants.primaryColor,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                          ),
                      ],
                    ),
                    if (entry.description.isNotEmpty) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        entry.description,
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: ResponsiveConstants.spacingS),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: AppConstants.textColor,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                onPressed: () => _showEntryOptions(entry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}