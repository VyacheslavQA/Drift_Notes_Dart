// Путь: lib/models/statistics_models.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';
import '../localization/app_localizations.dart';

// Период для фильтрации статистики
enum StatisticsPeriod {
  week, // Неделя
  month, // Месяц
  year, // Год
  allTime, // Всё время
  custom, // Пользовательский интервал
}

// Модель для пользовательского интервала дат
class CustomDateRange {
  final DateTime startDate;
  final DateTime endDate;

  CustomDateRange({required this.startDate, required this.endDate});

  // Копирование с частичным обновлением
  CustomDateRange copyWith({DateTime? startDate, DateTime? endDate}) {
    return CustomDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Проверка, входит ли дата в пользовательский интервал
  bool containsDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }

  // Форматирование для отображения
  String format() {
    return '${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}';
  }
}

// Основная модель статистики
class FishingStatistics {
  // Общее количество рыбалок
  final int totalTrips;

  // Самая долгая рыбалка в днях
  final int longestTripDays;

  // Общее количество дней на рыбалке
  final int totalDaysOnFishing;

  // Общее количество пойманных рыб
  final int totalFish;

  // Количество нереализованных поклевок
  final int missedBites;

  // Общий вес пойманных рыб
  final double totalWeight;

  // Информация о самой большой рыбе
  final BiggestFishInfo? biggestFish;

  // Информация о последнем выезде
  final LatestTripInfo? latestTrip;

  // Лучший месяц по количеству рыбы
  final BestMonthInfo? bestMonth;

  FishingStatistics({
    this.totalTrips = 0,
    this.longestTripDays = 0,
    this.totalDaysOnFishing = 0,
    this.totalFish = 0,
    this.missedBites = 0,
    this.totalWeight = 0.0,
    this.biggestFish,
    this.latestTrip,
    this.bestMonth,
  });

  // Проверка отсутствия данных
  bool get hasNoData => totalTrips == 0 && totalFish == 0;

  // Копирование с частичным обновлением
  FishingStatistics copyWith({
    int? totalTrips,
    int? longestTripDays,
    int? totalDaysOnFishing,
    int? totalFish,
    int? missedBites,
    double? totalWeight,
    BiggestFishInfo? biggestFish,
    LatestTripInfo? latestTrip,
    BestMonthInfo? bestMonth,
  }) {
    return FishingStatistics(
      totalTrips: totalTrips ?? this.totalTrips,
      longestTripDays: longestTripDays ?? this.longestTripDays,
      totalDaysOnFishing: totalDaysOnFishing ?? this.totalDaysOnFishing,
      totalFish: totalFish ?? this.totalFish,
      missedBites: missedBites ?? this.missedBites,
      totalWeight: totalWeight ?? this.totalWeight,
      biggestFish: biggestFish ?? this.biggestFish,
      latestTrip: latestTrip ?? this.latestTrip,
      bestMonth: bestMonth ?? this.bestMonth,
    );
  }

  // Расчет процента реализации поклевок
  double get realizationRate {
    final totalBites = totalFish + missedBites;
    if (totalBites == 0) return 0;
    return totalFish / totalBites * 100;
  }
}

// Информация о самой большой рыбе
class BiggestFishInfo {
  final String fishType;
  final double weight;
  final DateTime catchDate;

  BiggestFishInfo({
    required this.fishType,
    required this.weight,
    required this.catchDate,
  });

  // Форматированный вывод с поддержкой локализации
  String getFormattedText(BuildContext context) {
    final weightText = weight.toStringAsFixed(1).replaceAll('.0', '');
    final dateText = DateFormatter.formatDate(catchDate, context);

    String fishName =
        fishType.isNotEmpty
            ? fishType
            : AppLocalizations.of(context).translate('fish');
    return '$weightText ${AppLocalizations.of(context).translate('kg')} — $fishName, $dateText';
  }

  // Старый метод для обратной совместимости (без локализации)
  String get formattedText {
    final weightText = weight.toStringAsFixed(1).replaceAll('.0', '');
    final dateText = DateFormatter.formatDate(catchDate);

    String fishName = fishType.isNotEmpty ? fishType : 'Рыба';
    return '$weightText кг — $fishName, $dateText';
  }
}

// Информация о последнем выезде
class LatestTripInfo {
  final String tripName;
  final DateTime tripDate;

  LatestTripInfo({required this.tripName, required this.tripDate});

  // Форматированный вывод с поддержкой локализации
  String getFormattedText(BuildContext context) {
    final dateText = DateFormatter.formatDate(tripDate, context);
    return '«$tripName» — $dateText';
  }

  // Старый метод для обратной совместимости (без локализации)
  String get formattedText {
    final dateText = DateFormatter.formatDate(tripDate);
    return '«$tripName» — $dateText';
  }
}

// Информация о лучшем месяце по количеству рыбы
class BestMonthInfo {
  final int month; // 1-12
  final int year;
  final int fishCount;

  BestMonthInfo({
    required this.month,
    required this.year,
    required this.fishCount,
  });

  // Форматированный вывод с поддержкой локализации
  String getFormattedText(BuildContext context) {
    final monthName = DateFormatter.getMonthInNominative(month, context);
    return '$monthName $year — $fishCount ${DateFormatter.getFishText(fishCount, context)}';
  }

  // Старый метод для обратной совместимости (без локализации)
  String get formattedText {
    final monthName = DateFormatter.getMonthInNominative(month);
    return '$monthName $year — $fishCount ${DateFormatter.getFishText(fishCount)}';
  }
}
