// Путь: lib/widgets/bait_program_card.dart

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_utils.dart';
import '../models/bait_program_model.dart';

class BaitProgramCard extends StatelessWidget {
  final BaitProgramModel program;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showCheckbox;

  const BaitProgramCard({
    super.key,
    required this.program,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingM),
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withOpacity(0.1)
            : AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        border: isSelected
            ? Border.all(color: AppConstants.primaryColor, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusM),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
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
                  size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                ),
              ),

              SizedBox(width: ResponsiveConstants.spacingM),

              // Контент программы
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название с избранным
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

                    // Описание (если есть)
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

              // Checkbox для выбора или иконка меню
              if (showCheckbox)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap?.call(),
                  activeColor: AppConstants.primaryColor,
                  checkColor: AppConstants.textColor,
                  side: BorderSide(
                    color: AppConstants.textColor.withOpacity(0.5),
                    width: 2,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppConstants.textColor,
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  onPressed: onLongPress,
                ),
            ],
          ),
        ),
      ),
    );
  }
}