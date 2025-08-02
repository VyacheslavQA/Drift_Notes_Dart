// Путь: lib/widgets/weather/forecast_period_selector.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/weather_api_model.dart';

class ForecastPeriodSelector extends StatelessWidget {
  final WeatherApiResponse weather;
  final int selectedDayIndex;
  final Function(int) onDayChanged;

  const ForecastPeriodSelector({
    super.key,
    required this.weather,
    required this.selectedDayIndex,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (weather.forecast.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ограничиваем до 7 дней согласно плану API
    final availableDays = weather.forecast.length > 7 ? 7 : weather.forecast.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(availableDays, (index) {
            final forecastDay = weather.forecast[index];
            final isSelected = index == selectedDayIndex;

            return GestureDetector(
              onTap: () => onDayChanged(index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.surfaceColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getTabText(index, forecastDay.date, localizations),
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
          }),
        ),
      ),
    );
  }

  String _getTabText(int index, String dateString, AppLocalizations localizations) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();

    // Сегодня
    if (index == 0) {
      return localizations.translate('today');
    }

    // Завтра
    if (index == 1) {
      return localizations.translate('tomorrow');
    }

    // Остальные дни - день недели + число
    final dayName = _getDayName(date.weekday, localizations);
    final dayNumber = date.day;

    return '$dayName, $dayNumber';
  }

  String _getDayName(int weekday, AppLocalizations localizations) {
    switch (weekday) {
      case 1: return localizations.translate('monday_short') ?? 'Пн';
      case 2: return localizations.translate('tuesday_short') ?? 'Вт';
      case 3: return localizations.translate('wednesday_short') ?? 'Ср';
      case 4: return localizations.translate('thursday_short') ?? 'Чт';
      case 5: return localizations.translate('friday_short') ?? 'Пт';
      case 6: return localizations.translate('saturday_short') ?? 'Сб';
      case 7: return localizations.translate('sunday_short') ?? 'Вс';
      default: return 'Пн';
    }
  }
}