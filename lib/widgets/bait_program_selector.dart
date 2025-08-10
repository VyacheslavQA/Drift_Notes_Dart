// Путь: lib/widgets/bait_program_selector.dart

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_utils.dart';
import '../localization/app_localizations.dart';
import '../models/bait_program_model.dart';
import '../repositories/bait_program_repository.dart';
import '../screens/bait_programs/select_bait_programs_screen.dart';

class BaitProgramSelector extends StatefulWidget {
  final List<String> selectedProgramIds;
  final Function(List<String>) onProgramsChanged;
  final int maxSelection;

  const BaitProgramSelector({
    super.key,
    required this.selectedProgramIds,
    required this.onProgramsChanged,
    this.maxSelection = 5,
  });

  @override
  State<BaitProgramSelector> createState() => _BaitProgramSelectorState();
}

class _BaitProgramSelectorState extends State<BaitProgramSelector> {
  final BaitProgramRepository _repository = BaitProgramRepository();
  List<BaitProgramModel> _selectedPrograms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedPrograms();
  }

  @override
  void didUpdateWidget(BaitProgramSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedProgramIds != widget.selectedProgramIds) {
      _loadSelectedPrograms();
    }
  }

  Future<void> _loadSelectedPrograms() async {
    if (widget.selectedProgramIds.isEmpty) {
      setState(() {
        _selectedPrograms = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final programs = await _repository.getBaitProgramsByIds(widget.selectedProgramIds);
      setState(() {
        _selectedPrograms = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openProgramSelector() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectBaitProgramsScreen(
          selectedProgramIds: widget.selectedProgramIds,
          maxSelection: widget.maxSelection,
        ),
      ),
    );

    if (result != null) {
      widget.onProgramsChanged(result);
    }
  }

  void _removeProgram(String programId) {
    final updatedIds = widget.selectedProgramIds.where((id) => id != programId).toList();
    widget.onProgramsChanged(updatedIds);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        // Простая кнопка добавления программы
        if (widget.selectedProgramIds.length < widget.maxSelection)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openProgramSelector,
              icon: Icon(
                Icons.add,
                color: AppConstants.textColor,
                size: ResponsiveUtils.getIconSize(context, baseSize: 20),
              ),
              label: Text(
                localizations.translate('add_bait_program'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        SizedBox(height: ResponsiveConstants.spacingM),

        // Содержимое
        if (_isLoading)
          _buildLoadingState()
        else if (_selectedPrograms.isEmpty)
          _buildEmptyState(localizations)
        else
          _buildProgramsList(localizations),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return GestureDetector(
      onTap: _openProgramSelector,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveConstants.spacingL),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
          border: Border.all(
            color: AppConstants.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_outlined,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, baseSize: 32),
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingM),
            Text(
              localizations.translate('no_programs_attached'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveConstants.spacingS),
            Text(
              localizations.translate('add_bait_program'),
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsList(AppLocalizations localizations) {
    return Column(
      children: [
        // Список выбранных программ
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedPrograms.length,
          separatorBuilder: (context, index) => SizedBox(height: ResponsiveConstants.spacingS),
          itemBuilder: (context, index) {
            final program = _selectedPrograms[index];
            return _buildProgramItem(program, localizations);
          },
        ),

        // Кнопка добавления (если есть место)
        if (widget.selectedProgramIds.length < widget.maxSelection) ...[
          SizedBox(height: ResponsiveConstants.spacingM),
          _buildAddButton(localizations),
        ],

        // Информация о лимите
        if (widget.selectedProgramIds.isNotEmpty) ...[
          SizedBox(height: ResponsiveConstants.spacingS),
          Text(
            '${localizations.translate('selected_programs')}: ${widget.selectedProgramIds.length}/${widget.maxSelection}',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.6),
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildProgramItem(BaitProgramModel program, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(ResponsiveConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Иконка программы
          Container(
            padding: EdgeInsets.all(ResponsiveConstants.spacingS),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
            ),
            child: Icon(
              Icons.restaurant_menu_outlined,
              color: AppConstants.primaryColor,
              size: ResponsiveUtils.getIconSize(context, baseSize: 20),
            ),
          ),

          SizedBox(width: ResponsiveConstants.spacingM),

          // Информация о программе
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
                        size: ResponsiveUtils.getIconSize(context, baseSize: 16),
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

          // Кнопка удаления
          IconButton(
            onPressed: () => _removeProgram(program.id),
            icon: Icon(
              Icons.close,
              color: AppConstants.textColor.withOpacity(0.7),
              size: ResponsiveUtils.getIconSize(context, baseSize: 20),
            ),
            constraints: BoxConstraints(
              minWidth: ResponsiveConstants.minTouchTarget,
              minHeight: ResponsiveConstants.minTouchTarget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(AppLocalizations localizations) {
    return GestureDetector(
      onTap: _openProgramSelector,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveConstants.spacingM),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppConstants.primaryColor,
              size: ResponsiveUtils.getIconSize(context, baseSize: 20),
            ),
            SizedBox(width: ResponsiveConstants.spacingS),
            Text(
              localizations.translate('add_bait_program'),
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}