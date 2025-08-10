// Путь: lib/screens/bait_programs/select_bait_programs_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/bait_program_model.dart';
import '../../repositories/bait_program_repository.dart';
import '../../widgets/bait_program_card.dart';
import 'add_bait_program_screen.dart';

class SelectBaitProgramsScreen extends StatefulWidget {
  final List<String> selectedProgramIds;
  final int maxSelection;

  const SelectBaitProgramsScreen({
    super.key,
    this.selectedProgramIds = const [],
    this.maxSelection = 5,
  });

  @override
  State<SelectBaitProgramsScreen> createState() => _SelectBaitProgramsScreenState();
}

class _SelectBaitProgramsScreenState extends State<SelectBaitProgramsScreen> {
  final BaitProgramRepository _repository = BaitProgramRepository();
  final TextEditingController _searchController = TextEditingController();

  List<BaitProgramModel> _allPrograms = [];
  List<BaitProgramModel> _filteredPrograms = [];
  List<String> _selectedProgramIds = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedProgramIds = List.from(widget.selectedProgramIds);
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
        _allPrograms = programs;
        _filteredPrograms = programs;
        _isLoading = false;
      });
      _filterPrograms();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPrograms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrograms = _allPrograms.where((program) {
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

  void _toggleProgramSelection(String programId) {
    final localizations = AppLocalizations.of(context);

    setState(() {
      if (_selectedProgramIds.contains(programId)) {
        _selectedProgramIds.remove(programId);
      } else {
        if (_selectedProgramIds.length >= widget.maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('max_programs_selected')),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _selectedProgramIds.add(programId);
      }
    });
  }

  void _applySelection() {
    Navigator.pop(context, _selectedProgramIds);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('select_bait_programs'),
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

            // Счетчик выбранных программ
            if (_selectedProgramIds.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                padding: EdgeInsets.all(ResponsiveConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${localizations.translate('selected_programs')}: ${_selectedProgramIds.length}/${widget.maxSelection}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: ResponsiveConstants.spacingM),

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
                  final isSelected = _selectedProgramIds.contains(program.id);

                  return BaitProgramCard(
                    program: program,
                    isSelected: isSelected,
                    showCheckbox: true,
                    onTap: () => _toggleProgramSelection(program.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedProgramIds.isNotEmpty
          ? Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          border: Border(
            top: BorderSide(
              color: AppConstants.textColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _applySelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveConstants.radiusXL),
              ),
            ),
            child: Text(
              '${localizations.translate('apply_programs')} (${_selectedProgramIds.length})',
              style: TextStyle(
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      )
          : null,
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
}