// Путь: lib/widgets/weather/forecast_period_selector.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../enums/forecast_period.dart';
import '../../localization/app_localizations.dart';

class ForecastPeriodSelector extends StatelessWidget {
  final ForecastPeriod selectedPeriod;
  final Function(ForecastPeriod) onPeriodChanged;
  final List<ForecastPeriod> availablePeriods;

  const ForecastPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.availablePeriods = const [
      ForecastPeriod.today,
      ForecastPeriod.tomorrow,
      ForecastPeriod.threeDays,
      ForecastPeriod.sevenDays,
    ],
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availablePeriods.map((period) {
            final isSelected = period == selectedPeriod;
            final displayName = _getShortDisplayName(period, localizations);

            return GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getShortDisplayName(ForecastPeriod period, AppLocalizations localizations) {
    switch (period) {
      case ForecastPeriod.today:
        return localizations.translate('today');
      case ForecastPeriod.tomorrow:
        return localizations.translate('tomorrow');
      case ForecastPeriod.dayAfterTomorrow:
      // Показываем день недели для послезавтра
        final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));
        return _getShortDayName(dayAfterTomorrow.weekday, localizations);
      case ForecastPeriod.threeDays:
        return localizations.translate('3_days');
      case ForecastPeriod.sevenDays:
        return localizations.translate('7_days');
      case ForecastPeriod.fourteenDays:
        return localizations.translate('14_days');
    }
  }

  String _getShortDayName(int weekday, AppLocalizations localizations) {
    switch (weekday) {
      case 1: return localizations.translate('mon_short');
      case 2: return localizations.translate('tue_short');
      case 3: return localizations.translate('wed_short');
      case 4: return localizations.translate('thu_short');
      case 5: return localizations.translate('fri_short');
      case 6: return localizations.translate('sat_short');
      case 7: return localizations.translate('sun_short');
      default: return '';
    }
  }
}