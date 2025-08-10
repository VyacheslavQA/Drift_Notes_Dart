// Путь: lib/screens/bait_programs/bait_programs_list_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/bait_program_model.dart';
import '../../repositories/bait_program_repository.dart';
import 'add_bait_program_screen.dart';
import 'edit_bait_program_screen.dart';
import 'bait_program_detail_screen.dart';

class BaitProgramsListScreen extends StatefulWidget {
  const BaitProgramsListScreen({super.key});

  @override
  State<BaitProgramsListScreen> createState() => _BaitProgramsListScreenState();
}

class _BaitProgramsListScreenState extends State<BaitProgramsListScreen> {
  final BaitProgramRepository _repository = BaitProgramRepository();
  final TextEditingController _searchController = TextEditingController();

  List<BaitProgramModel> _programs = [];
  List<BaitProgramModel> _filteredPrograms = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _searchController.addListener(_filterPrograms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final programs = await _repository.getUserBaitPrograms();
      setState(() {
        _programs = programs;
        _filteredPrograms = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPrograms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrograms = _programs.where((program) {
        final matchesSearch = program.title.toLowerCase().contains(query) ||
            program.description.toLowerCase().contains(query);
        final matchesFavorites = !_showFavoritesOnly || program.isFavorite;
        return matchesSearch && matchesFavorites;
      }).toList();
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    _filterPrograms();
  }

  Future<void> _toggleFavorite(String programId) async {
    try {
      await _repository.toggleFavorite(programId);
      _loadPrograms();
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

  Future<void> _copyProgram(BaitProgramModel program) async {
    try {
      await _repository.copyBaitProgram(program.id);
      _loadPrograms();

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('program_saved_successfully')),
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

  Future<void> _deleteProgram(BaitProgramModel program) async {
    final localizations = AppLocalizations.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_program'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Text(
          localizations.translate('delete_program_confirmation'),
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
              localizations.translate('delete_program'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _repository.deleteBaitProgram(program.id);
        _loadPrograms();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('program_deleted_successfully')),
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

  void _showProgramOptions(BaitProgramModel program) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.visibility, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('view_program'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BaitProgramDetailScreen(program: program),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('edit_bait_program'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBaitProgramScreen(program: program),
                    ),
                  ).then((_) => _loadPrograms());
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: AppConstants.textColor),
                title: Text(
                  localizations.translate('copy_bait_program'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyProgram(program);
                },
              ),
              ListTile(
                leading: Icon(
                  program.isFavorite ? Icons.star : Icons.star_border,
                  color: program.isFavorite ? AppConstants.primaryColor : AppConstants.textColor,
                ),
                title: Text(
                  program.isFavorite
                      ? localizations.translate('remove_from_favorites')
                      : localizations.translate('add_to_favorites'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(program.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.translate('delete_program'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProgram(program);
                },
              ),
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
          localizations.translate('bait_programs'),
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
                  builder: (context) => const AddBaitProgramScreen(),
                ),
              ).then((_) => _loadPrograms());
            },
          ),
        ],
      ),
      body: SafeArea(
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
                  hintText: localizations.translate('search_programs'),
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

            // Список программ
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
              )
                  : _filteredPrograms.isEmpty
                  ? _buildEmptyState(localizations)
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: _filteredPrograms.length,
                itemBuilder: (context, index) {
                  final program = _filteredPrograms[index];
                  return _buildProgramCard(program, localizations);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBaitProgramScreen(),
            ),
          ).then((_) => _loadPrograms());
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
                Icons.restaurant_menu_outlined,
                size: ResponsiveUtils.getIconSize(context, baseSize: 60),
                color: AppConstants.primaryColor,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingL),
            Text(
              _searchController.text.isNotEmpty
                  ? localizations.translate('no_programs_found')
                  : localizations.translate('no_programs_yet'),
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
                      builder: (context) => const AddBaitProgramScreen(),
                    ),
                  ).then((_) => _loadPrograms());
                },
                icon: Icon(
                  Icons.add,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                label: Text(
                  localizations.translate('create_new_program'),
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

  Widget _buildProgramCard(BaitProgramModel program, AppLocalizations localizations) {
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
              builder: (context) => BaitProgramDetailScreen(program: program),
            ),
          );
        },
        onLongPress: () => _showProgramOptions(program),
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
                  Icons.restaurant_menu_outlined,
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
                            program.title,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (program.isFavorite)
                          Icon(
                            Icons.star,
                            color: AppConstants.primaryColor,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                          ),
                      ],
                    ),
                    if (program.description.isNotEmpty) ...[
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        program.description,
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
                onPressed: () => _showProgramOptions(program),
              ),
            ],
          ),
        ),
      ),
    );
  }
}