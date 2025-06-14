// Путь: lib/enums/forecast_period.dart

enum ForecastPeriod {
  today,
  tomorrow,
  dayAfterTomorrow,
  threeDays,
  sevenDays,
  fourteenDays;

  String getDisplayName(String Function(String) translate) {
    switch (this) {
      case ForecastPeriod.today:
        return translate('today');
      case ForecastPeriod.tomorrow:
        return translate('tomorrow');
      case ForecastPeriod.dayAfterTomorrow:
        return translate('day_after_tomorrow');
      case ForecastPeriod.threeDays:
        return translate('3_days');
      case ForecastPeriod.sevenDays:
        return translate('7_days');
      case ForecastPeriod.fourteenDays:
        return translate('14_days');
    }
  }

  int getDaysCount() {
    switch (this) {
      case ForecastPeriod.today:
      case ForecastPeriod.tomorrow:
      case ForecastPeriod.dayAfterTomorrow:
        return 3; // Минимум для получения нужных дней
      case ForecastPeriod.threeDays:
        return 3;
      case ForecastPeriod.sevenDays:
        return 7;
      case ForecastPeriod.fourteenDays:
        return 14;
    }
  }

  bool get isSpecificDay => [
    ForecastPeriod.today,
    ForecastPeriod.tomorrow,
    ForecastPeriod.dayAfterTomorrow
  ].contains(this);
}