// Путь: lib/models/statistics_models.dart

import 'package:intl/intl.dart';
import '../utils/date_formatter.dart';

// Период для фильтрации статистики
enum StatisticsPeriod {
  week,     // Неделя
  month,    // Месяц
  year,     // Год
  allTime,  // Всё время
  custom    // Пользовательский интервал
}

// Модель для пользовательского интервала дат
class CustomDateRange {
  final DateTime startDate;
  final DateTime endDate;

  CustomDateRange({
    required this.startDate,
    required this.endDate,
  });

  // Копирование с частичным обновлением
  CustomDateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CustomDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Проверка, входит ли дата в пользовательский интервал
  bool containsDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
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
    BiggestFishInfo? biggestFish,
    LatestTripInfo? latestTrip,
    BestMonthInfo? bestMonth,
  }) {
    return FishingStatistics(
      totalTrips: totalTrips ?? this.totalTrips,
      longestTripDays: longestTripDays ?? this.longestTripDays,
      totalDaysOnFishing: totalDaysOnFishing ?? this.totalDaysOnFishing,
      totalFish: totalFish ?? this.totalFish,
      biggestFish: biggestFish ?? this.biggestFish,
      latestTrip: latestTrip ?? this.latestTrip,
      bestMonth: bestMonth ?? this.bestMonth,
    );
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

  // Форматированный вывод
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

  LatestTripInfo({
    required this.tripName,
    required this.tripDate,
  });

  // Форматированный вывод
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

  // Форматированный вывод
  String get formattedText {
    final monthName = DateFormatter.getMonthInNominative(month);
    return '$monthName $year — $fishCount ${DateFormatter.getFishText(fishCount)}';
  }
}