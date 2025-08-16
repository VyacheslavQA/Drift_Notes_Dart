// ЗАМЕНИ ВЕСЬ ФАЙЛ lib/screens/fishing_diary/fishing_diary_list_screen.dart НА:

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
// 🆕 НОВЫЕ ИМПОРТЫ для папок
import '../../repositories/fishing_diary_folder_repository.dart';
import '../../models/fishing_diary_folder_model.dart';
import '../../widgets/dialogs/fishing_diary_folder_dialog.dart';
import '../../widgets/dialogs/move_entry_dialog.dart';

class FishingDiaryListScreen extends StatefulWidget {
  const FishingDiaryListScreen({super.key});

  @override
  State<FishingDiaryListScreen> createState() => _FishingDiaryListScreenState();

  // 🚀 СТАТИЧЕСКИЙ МЕТОД: Обработка импорта записей дневника
  static Future<void> handleDiaryImport(BuildContext context, String filePath) async {
    debugPrint('🔍 handleDiaryImport: Перенаправляем в универсальный обработчик $filePath');
    await DriftNotesFileHandler.handleDriftNotesFile(context, filePath);
  }
}

class _FishingDiaryListScreenState extends State<FishingDiaryListScreen> {
  final FishingDiaryRepository _repository = FishingDiaryRepository();
  final FishingDiaryFolderRepository _folderRepository = FishingDiaryFolderRepository();
  final TextEditingController _searchController = TextEditingController();

  List<FishingDiaryModel> _entries = [];
  List<FishingDiaryModel> _filteredEntries = [];
  List<FishingDiaryFolderModel> _folders = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  // 🎯 УПРОЩЕННЫЕ ПОЛЯ - только для фильтрации по папкам
  String? _selectedFolderId; // null = показать все записи
  Set<String> _selectedEntries = {}; // для группового выбора
  bool _isSelectionMode = false;

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
    setState(() => _isLoading = true);

    try {
      debugPrint('📁 Загружаем записи и папки...');

      // Загружаем записи и папки параллельно
      final results = await Future.wait([
        _repository.getUserFishingDiaryEntries(),
        _folderRepository.getUserFishingDiaryFolders(),
      ]);

      final entries = results[0] as List<FishingDiaryModel>;
      final folders = results[1] as List<FishingDiaryFolderModel>;

      debugPrint('📁 Загружено: ${entries.length} записей, ${folders.length} папок');

      setState(() {
        _entries = entries;
        _folders = folders;
        _filteredEntries = _applyFilters(entries);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки данных: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries = _applyFilters(_entries);
    });
  }

  List<FishingDiaryModel> _applyFilters(List<FishingDiaryModel> entries) {
    var filtered = entries;

    // Фильтр по поиску
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((entry) {
        return entry.title.toLowerCase().contains(query) ||
            entry.description.toLowerCase().contains(query);
      }).toList();
    }

    // Фильтр по избранному
    if (_showFavoritesOnly) {
      filtered = filtered.where((entry) => entry.isFavorite).toList();
    }

    // 🔥 DEBUG: Логируем состояние фильтрации
    debugPrint('🔍 _applyFilters: _selectedFolderId = $_selectedFolderId');
    debugPrint('🔍 _applyFilters: Всего записей до фильтра папки: ${filtered.length}');

    for (var entry in filtered) {
      debugPrint('🔍 Запись: ${entry.title}, folderId: ${entry.folderId}');
    }

    // 🔥 ИСПРАВЛЕННЫЙ ФИЛЬТР ПО ПАПКЕ
    if (_selectedFolderId != null) {
      // Если выбрана папка - показываем только записи из этой папки
      filtered = filtered.where((entry) => entry.folderId == _selectedFolderId).toList();
      debugPrint('🔍 _applyFilters: После фильтра по папке $_selectedFolderId: ${filtered.length} записей');
    } else {
      // Если папка НЕ выбрана - показываем только записи БЕЗ папки
      final beforeCount = filtered.length;
      filtered = filtered.where((entry) => entry.folderId == null || entry.folderId!.isEmpty).toList();
      debugPrint('🔍 _applyFilters: Показываем записи БЕЗ папки: было $beforeCount, стало ${filtered.length}');
    }

    return filtered;
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    _filterEntries();
  }

  // ========================================
  // 🎯 УПРОЩЕННЫЕ МЕТОДЫ ДЛЯ ПАПОК
  // ========================================

  void _selectFolder(String? folderId) {
    setState(() {
      _selectedFolderId = folderId;
      _filterEntries();
    });
  }

  void _clearFolderFilter() {
    setState(() {
      _selectedFolderId = null;
      _filterEntries();
    });
  }

  Future<void> _createFolder() async {
    final localizations = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => FishingDiaryFolderDialog(
        onSave: (folderData) async {
          try {
            setState(() => _isLoading = true);
            await _folderRepository.addFishingDiaryFolder(folderData);
            await _loadEntries();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('folder_created_successfully')),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ Ошибка создания папки: $e');
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${localizations.translate('error')}: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _editFolder(FishingDiaryFolderModel folder) async {
    final localizations = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => FishingDiaryFolderDialog(
        folder: folder,
        onSave: (folderData) async {
          try {
            setState(() => _isLoading = true);
            await _folderRepository.updateFishingDiaryFolder(folderData);
            await _loadEntries();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('folder_updated_successfully')),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ Ошибка обновления папки: $e');
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${localizations.translate('error')}: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteFolder(FishingDiaryFolderModel folder) async {
    final localizations = AppLocalizations.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_folder'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Text(
          localizations.translate('delete_folder_confirmation'),
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
              localizations.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        setState(() => _isLoading = true);
        await _folderRepository.deleteFishingDiaryFolder(folder.id);

        // Если была выбрана удаляемая папка, сбрасываем выбор
        if (_selectedFolderId == folder.id) {
          _selectedFolderId = null;
        }

        await _loadEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('folder_deleted_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Ошибка удаления папки: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showFolderOptions(FishingDiaryFolderModel folder) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.translate('folder_options'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.edit, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('edit_folder'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editFolder(folder);
                },
              ),

              const Divider(color: Colors.grey),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.translate('delete_folder'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFolder(folder);
                },
              ),

              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // МЕТОДЫ ДЛЯ ЗАПИСЕЙ
  // ========================================

  // 🆕 НОВЫЙ МЕТОД: Убрать запись из папки
  Future<void> _removeFromFolder(FishingDiaryModel entry) async {
    final localizations = AppLocalizations.of(context);

    debugPrint('🔥 _removeFromFolder: Убираем запись ${entry.title} из папки');

    try {
      setState(() => _isLoading = true);

      // Устанавливаем folderId = null (убираем из папки)
      await _repository.moveFishingDiaryEntryToFolder(entry.id, null);

      debugPrint('🔥 _removeFromFolder: Запись перемещена, сбрасываем фильтр');

      setState(() {
        _selectedFolderId = null;
      });

      // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Принудительная перезагрузка с задержкой
      await Future.delayed(Duration(milliseconds: 500));

      // Принудительно загружаем данные напрямую
      final freshEntries = await _repository.getUserFishingDiaryEntries();
      final freshFolders = await _folderRepository.getUserFishingDiaryFolders();

      setState(() {
        _entries = freshEntries;
        _folders = freshFolders;
        _filteredEntries = _applyFilters(freshEntries);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_removed_from_folder')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка удаления записи из папки: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // 🚀 МЕТОД: Экспорт записи дневника
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

  // 🚀 МЕТОД: Показ Paywall для экспорта записей
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

  void _showEntryOptions(FishingDiaryModel entry) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // 🆕 КНОПКА: Переместить в папку / Убрать из папки
              ListTile(
                leading: Icon(
                    entry.folderId != null ? Icons.folder_open : Icons.drive_file_move,
                    color: AppConstants.textColor
                ),
                title: Text(
                  entry.folderId != null
                      ? localizations.translate('remove_from_folder')
                      : localizations.translate('move_to_folder'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);

                  if (entry.folderId != null) {
                    // Убираем из папки - устанавливаем folderId = null
                    _removeFromFolder(entry);
                  } else {
                    // Перемещаем в папку - показываем диалог выбора папки
                    BulkMoveHelper.showMoveDialog(
                      context: context,
                      entries: [entry],
                      availableFolders: _folders,
                      onMove: (targetFolderId) async {
                        try {
                          setState(() => _isLoading = true);
                          await _repository.moveFishingDiaryEntryToFolder(entry.id, targetFolderId);
                          await _loadEntries();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('entry_moved_successfully')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('❌ Ошибка перемещения записи: $e');
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${localizations.translate('error')}: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  }
                },
              ),

              // 🚀 КНОПКА: Поделиться записью с проверкой Premium
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

              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
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
          // Кнопка избранного
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? AppConstants.primaryColor : AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _toggleFavoritesFilter,
          ),

          // Кнопка создания папки
          IconButton(
            icon: Icon(
              Icons.create_new_folder,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _createFolder,
            tooltip: localizations.translate('create_folder'),
          ),

          // Кнопка добавления записи
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
                      borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
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
                      onPressed: () => _searchController.clear(),
                    )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConstants.spacingM,
                      vertical: ResponsiveConstants.spacingM,
                    ),
                  ),
                ),
              ),

              // 🎯 ПРОСТОЕ ОТОБРАЖЕНИЕ ФИЛЬТРА ПО ПАПКЕ
              if (_selectedFolderId != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                    border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: _getFolderColor(_selectedFolderId!),
                        size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                      ),
                      SizedBox(width: ResponsiveConstants.spacingS),
                      Expanded(
                        child: Text(
                          'Папка: ${_getFolderName(_selectedFolderId!)}',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppConstants.primaryColor,
                          size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                        ),
                        onPressed: _clearFolderFilter,
                      ),
                    ],
                  ),
                ),

              if (_selectedFolderId != null)
                SizedBox(height: ResponsiveConstants.spacingS),

              // Основной контент
              Expanded(
                child: _buildMainContent(localizations),
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

  // 🎯 ГЛАВНЫЙ КОНТЕНТ - ПРОСТАЯ СТРУКТУРА
  Widget _buildMainContent(AppLocalizations localizations) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      color: AppConstants.primaryColor,
      backgroundColor: AppConstants.surfaceColor,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
        children: [
          // 📁 ПАПКИ СВЕРХУ (только если есть папки и не выбрана папка)
          if (_folders.isNotEmpty && _selectedFolderId == null) ...[
            Text(
              'Папки',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            ..._folders.map((folder) => _buildFolderCard(folder)),
            SizedBox(height: ResponsiveConstants.spacingL),
          ],

          // 📝 ЗАПИСИ СНИЗУ
          if (_filteredEntries.isNotEmpty) ...[
            Text(
              _selectedFolderId == null ? 'Записи без папки' : 'Записи в папке',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 18, maxSize: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            ..._filteredEntries.map((entry) => _buildEntryCard(entry)),
          ],

          // Пустое состояние
          if (_filteredEntries.isEmpty && (_folders.isEmpty || _selectedFolderId != null))
            _buildEmptyState(localizations),

          // Отступ снизу для FAB
          SizedBox(height: 100),
        ],
      ),
    );
  }

  // 🎯 ПРОСТАЯ КАРТОЧКА ПАПКИ
  Widget _buildFolderCard(FishingDiaryFolderModel folder) {
    final entriesCount = _entries.where((entry) => entry.folderId == folder.id).length;
    final folderColor = Color(int.parse(folder.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: InkWell(
        onTap: () => _selectFolder(folder.id),
        onLongPress: () => _showFolderOptions(folder),
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
          child: Row(
            children: [
              // Иконка папки
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                decoration: BoxDecoration(
                  color: folderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  Icons.folder,
                  color: folderColor,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingM),

              // Информация о папке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (folder.description != null && folder.description!.isNotEmpty) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        folder.description!,
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Количество записей
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConstants.spacingS,
                  vertical: ResponsiveConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: folderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Text(
                  entriesCount.toString(),
                  style: TextStyle(
                    color: folderColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingS),

              // Кнопка опций
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: AppConstants.textColor.withOpacity(0.7),
                  size: ResponsiveUtils.getIconSize(context),
                ),
                onPressed: () => _showFolderOptions(folder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 ПРОСТАЯ КАРТОЧКА ЗАПИСИ
  Widget _buildEntryCard(FishingDiaryModel entry) {
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
              // Иконка записи
              Container(
                padding: EdgeInsets.all(ResponsiveConstants.spacingS),
                decoration: BoxDecoration(
                  color: entry.folderId != null
                      ? _getFolderColor(entry.folderId!).withOpacity(0.2)
                      : AppConstants.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: entry.folderId != null
                      ? _getFolderColor(entry.folderId!)
                      : AppConstants.primaryColor,
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingM),

              // Информация о записи
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

              // Кнопка опций
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

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        children: [
          SizedBox(height: ResponsiveConstants.spacingXL),
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
          SizedBox(height: ResponsiveConstants.spacingXL),
        ],
      ),
    );
  }

  Color _getFolderColor(String folderId) {
    final folder = _folders.firstWhere(
          (f) => f.id == folderId,
      orElse: () => FishingDiaryFolderModel(
        id: '',
        userId: '',
        name: '',
        colorHex: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return Color(int.parse(folder.colorHex.replaceFirst('#', '0xFF')));
  }

  String _getFolderName(String folderId) {
    final folder = _folders.firstWhere(
          (f) => f.id == folderId,
      orElse: () => FishingDiaryFolderModel(
        id: '',
        userId: '',
        name: 'Неизвестная папка',
        colorHex: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return folder.name;
  }
}