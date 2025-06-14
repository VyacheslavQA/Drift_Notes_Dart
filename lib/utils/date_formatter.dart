// Путь: lib/utils/date_formatter.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class DateFormatter {
  // Форматирует дату в формате "31 декабря 2023"
  static String formatDate(DateTime date, [BuildContext? context]) {
    final locale =
        context != null
            ? AppLocalizations.of(context).locale.languageCode
            : 'ru';
    return DateFormat('dd MMMM yyyy', locale).format(date);
  }

  // Форматирует дату в формате "31.12.2023"
  static String formatShortDate(DateTime date, [BuildContext? context]) {
    final locale =
        context != null
            ? AppLocalizations.of(context).locale.languageCode
            : 'ru';
    return DateFormat('dd.MM.yyyy', locale).format(date);
  }

  // Форматирует диапазон дат
  static String formatDateRange(
    DateTime startDate,
    DateTime endDate, [
    BuildContext? context,
  ]) {
    final locale =
        context != null
            ? AppLocalizations.of(context).locale.languageCode
            : 'ru';

    // Если год и месяц одинаковые
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      final dayFormat = DateFormat('dd', locale);
      final monthYearFormat = DateFormat('MMMM yyyy', locale);
      return '${dayFormat.format(startDate)}–${dayFormat.format(endDate)} ${monthYearFormat.format(endDate)}';
    }

    // Если год одинаковый, но месяцы разные
    if (startDate.year == endDate.year) {
      final startDateShort = DateFormat('dd MMMM', locale).format(startDate);
      final endDateShort = DateFormat('dd MMMM', locale).format(endDate);
      final year = DateFormat('yyyy', locale).format(endDate);
      return '$startDateShort – $endDateShort $year';
    }

    // Если годы разные
    final fullFormat = DateFormat('dd MMMM yyyy', locale);
    return '${fullFormat.format(startDate)} – ${fullFormat.format(endDate)}';
  }

  // Возвращает правильную форму слова "день" в зависимости от количества
  static String getDaysText(int days, [BuildContext? context]) {
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations.locale.languageCode == 'en') {
        return days == 1
            ? localizations.translate('day')
            : localizations.translate('days_many');
      }
    }

    // Русская логика склонений
    if (days % 10 == 1 && days % 100 != 11) {
      return context != null
          ? AppLocalizations.of(context).translate('day')
          : 'день';
    } else if ((days % 10 >= 2 && days % 10 <= 4) &&
        (days % 100 < 10 || days % 100 >= 20)) {
      return context != null
          ? AppLocalizations.of(context).translate('days_2_4')
          : 'дня';
    } else {
      return context != null
          ? AppLocalizations.of(context).translate('days_many')
          : 'дней';
    }
  }

  // Возвращает правильную форму слова "рыба" в зависимости от количества
  static String getFishText(int count, [BuildContext? context]) {
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations.locale.languageCode == 'en') {
        return count == 1
            ? localizations.translate('fish')
            : localizations.translate('fish_many');
      }
    }

    // Русская логика склонений
    if (count % 10 == 1 && count % 100 != 11) {
      return context != null
          ? AppLocalizations.of(context).translate('fish')
          : 'рыба';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return context != null
          ? AppLocalizations.of(context).translate('fish_2_4')
          : 'рыбы';
    } else {
      return context != null
          ? AppLocalizations.of(context).translate('fish_many')
          : 'рыб';
    }
  }

  // Возвращает правильную форму слова "рыбалка" в зависимости от количества
  static String getFishingTripsText(int count, [BuildContext? context]) {
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations.locale.languageCode == 'en') {
        return count == 1
            ? localizations.translate('fishing_trip')
            : localizations.translate('fishing_trips_many');
      }
    }

    // Русская логика склонений
    if (count % 10 == 1 && count % 100 != 11) {
      return context != null
          ? AppLocalizations.of(context).translate('fishing_trip')
          : 'рыбалка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return context != null
          ? AppLocalizations.of(context).translate('fishing_trips_2_4')
          : 'рыбалки';
    } else {
      return context != null
          ? AppLocalizations.of(context).translate('fishing_trips_many')
          : 'рыбалок';
    }
  }

  // Получает месяц в именительном падеже
  static String getMonthInNominative(int monthIndex, [BuildContext? context]) {
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      const monthKeys = [
        '',
        'january',
        'february',
        'march',
        'april',
        'may',
        'june',
        'july',
        'august',
        'september',
        'october',
        'november',
        'december',
      ];

      if (monthIndex >= 1 && monthIndex <= 12) {
        return localizations.translate(monthKeys[monthIndex]);
      }
      return localizations.translate('unknown_month');
    }

    // Fallback для русского
    const monthsInNominative = {
      1: 'Январь',
      2: 'Февраль',
      3: 'Март',
      4: 'Апрель',
      5: 'Май',
      6: 'Июнь',
      7: 'Июль',
      8: 'Август',
      9: 'Сентябрь',
      10: 'Октябрь',
      11: 'Ноябрь',
      12: 'Декабрь',
    };
    return monthsInNominative[monthIndex] ?? 'Неизвестный месяц';
  }

  // Форматирует время в формате "HH:mm"
  static String formatTime(DateTime dateTime, [BuildContext? context]) {
    final locale =
        context != null
            ? AppLocalizations.of(context).locale.languageCode
            : 'ru';
    return DateFormat('HH:mm', locale).format(dateTime);
  }

  // Форматирует дату и время в формате "31 декабря 2023, 15:30"
  static String formatDateTime(DateTime dateTime, [BuildContext? context]) {
    final date = formatDate(dateTime, context);
    final time = formatTime(dateTime, context);
    return '$date, $time';
  }

  // Возвращает относительное время ("сегодня", "вчера", "2 дня назад")
  static String getRelativeDate(DateTime date, [BuildContext? context]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (context != null) {
      final localizations = AppLocalizations.of(context);

      if (difference == 0) {
        return localizations.translate('today');
      } else if (difference == 1) {
        return localizations.translate('yesterday');
      } else if (difference == -1) {
        return localizations.translate('tomorrow');
      } else if (difference > 1 && difference <= 7) {
        return '${difference} ${getDaysText(difference, context)} назад';
      } else if (difference < -1 && difference >= -7) {
        final absDifference = difference.abs();
        return 'через ${absDifference} ${getDaysText(absDifference, context)}';
      }
    }

    // Fallback - возвращаем обычную дату
    return formatDate(date, context);
  }
}
