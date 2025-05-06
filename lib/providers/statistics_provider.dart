// Путь: lib/providers/statistics_provider.dart

import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/statistics_models.dart';
import '../models/fishing_note_model.dart';
import '../repositories/fishing_note_repository.dart';

class StatisticsProvider extends ChangeNotifier {
  late final FishingNoteRepository _fishingNoteRepository;

  // Конструктор без необходимости внешней зависимости
  StatisticsProvider() : _fishingNoteRepository = FishingNoteRepository();

  // Выбранный период
  StatisticsPeriod _selectedPeriod = StatisticsPeriod.month;
  StatisticsPeriod get selectedPeriod => _selectedPeriod;

  // Пользовательский интервал дат
  CustomDateRange _customDateRange = CustomDateRange(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );
  CustomDateRange get customDateRange => _customDateRange;

  // Все заметки, загруженные из репозитория
  List<FishingNoteModel> _allNotes = [];
  // Отфильтрованные заметки для текущего периода
  List<FishingNoteModel> _filteredNotes = [];

  // Рассчитанная статистика для текущего периода
  FishingStatistics _statistics = FishingStatistics();
  FishingStatistics get statistics => _statistics;

  // Флаг загрузки
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Возможная ошибка
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Загрузка данных
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Получаем все заметки пользователя
      _allNotes = await _fishingNoteRepository.getUserFishingNotes();

      // Фильтруем и рассчитываем статистику
      _filterNotesAndCalculateStatistics();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ошибка загрузки данных: $e';
      notifyListeners();
    }
  }

  // Изменение периода
  void changePeriod(StatisticsPeriod period) {
    _selectedPeriod = period;
    _filterNotesAndCalculateStatistics();
    notifyListeners();
  }

  // Изменение пользовательского интервала дат
  void updateCustomDateRange(DateTime startDate, DateTime endDate) {
    _customDateRange = CustomDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    // Если выбран пользовательский период, обновляем статистику
    if (_selectedPeriod == StatisticsPeriod.custom) {
      _filterNotesAndCalculateStatistics();
    }

    notifyListeners();
  }

  // Фильтрация заметок и расчет статистики
  void _filterNotesAndCalculateStatistics() {
    // Сначала фильтруем заметки по выбранному периоду
    _filteredNotes = _filterNotesByPeriod();

    // Затем рассчитываем статистику на основе отфильтрованных заметок
    _calculateStatistics();
  }

  // Фильтрация заметок в зависимости от выбранного периода
  List<FishingNoteModel> _filterNotesByPeriod() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Исключаем запланированные рыбалки (те, у которых дата начала в будущем)
    final pastNotes = _allNotes.where((note) {
      final noteStartDate = DateTime(note.date.year, note.date.month, note.date.day);
      return !noteStartDate.isAfter(today);
    }).toList();

    // Применяем фильтр по выбранному периоду
    switch (_selectedPeriod) {
      case StatisticsPeriod.week:
      // Последние 7 дней
        final weekAgo = today.subtract(const Duration(days: 7));
        return pastNotes.where((note) {
          final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
          return !noteDate.isBefore(weekAgo);
        }).toList();

      case StatisticsPeriod.month:
      // Последние 30 дней
        final monthAgo = today.subtract(const Duration(days: 30));
        return pastNotes.where((note) {
          final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
          return !noteDate.isBefore(monthAgo);
        }).toList();

      case StatisticsPeriod.year:
      // Текущий год
        final startOfYear = DateTime(now.year, 1, 1);
        return pastNotes.where((note) {
          final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
          return !noteDate.isBefore(startOfYear);
        }).toList();

      case StatisticsPeriod.allTime:
      // Все заметки без фильтрации
        return pastNotes;

      case StatisticsPeriod.custom:
      // Пользовательский интервал
        return pastNotes.where((note) {
          final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
          return _customDateRange.containsDate(noteDate);
        }).toList();
    }
  }

  // Расчет статистики на основе отфильтрованных заметок
  void _calculateStatistics() {
    if (_filteredNotes.isEmpty) {
      _statistics = FishingStatistics();
      return;
    }

    // 1. Всего рыбалок
    final totalTrips = _filteredNotes.length;

    // 2. Самая долгая рыбалка
    int longestTripDays = 0;
    for (var note in _filteredNotes) {
      if (note.isMultiDay && note.endDate != null) {
        final days = note.endDate!.difference(note.date).inDays + 1;
        if (days > longestTripDays) {
          longestTripDays = days;
        }
      } else {
        // Если однодневная рыбалка, считаем её за 1 день
        if (longestTripDays < 1) {
          longestTripDays = 1;
        }
      }
    }

    // 3. Общее количество дней на рыбалке (уникальных)
    final Set<String> uniqueFishingDays = {};
    for (var note in _filteredNotes) {
      DateTime currentDate = note.date;
      final endDate = note.endDate ?? note.date;

      while (!currentDate.isAfter(endDate)) {
        // Добавляем дату в формате строки YYYY-MM-DD в множество
        uniqueFishingDays.add(
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}'
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    final totalDaysOnFishing = uniqueFishingDays.length;

    // 4. Всего поймано рыб
    int totalFish = 0;
    for (var note in _filteredNotes) {
      totalFish += note.biteRecords.length;
    }

    // 5. Самая большая рыба
    BiggestFishInfo? biggestFish;
    double maxWeight = 0.0;
    for (var note in _filteredNotes) {
      for (var record in note.biteRecords) {
        if (record.weight > maxWeight) {
          maxWeight = record.weight;
          biggestFish = BiggestFishInfo(
            fishType: record.fishType,
            weight: record.weight,
            catchDate: record.time,
          );
        }
      }
    }

    // 6. Последний выезд
    LatestTripInfo? latestTrip;
    if (_filteredNotes.isNotEmpty) {
      // Сортируем заметки по дате (от новых к старым)
      final sortedNotes = List<FishingNoteModel>.from(_filteredNotes)
        ..sort((a, b) => b.date.compareTo(a.date));

      latestTrip = LatestTripInfo(
        tripName: sortedNotes[0].location,
        tripDate: sortedNotes[0].date,
      );
    }

    // 7. Лучший месяц по количеству рыбы
    BestMonthInfo? bestMonth;
    if (totalFish > 0) {
      // Создаем словарь для подсчета рыбы по месяцам
      final Map<String, int> fishCountByMonth = {};

      for (var note in _filteredNotes) {
        for (var record in note.biteRecords) {
          final key = '${record.time.year}-${record.time.month}';
          fishCountByMonth[key] = (fishCountByMonth[key] ?? 0) + 1;
        }
      }

      // Находим месяц с максимальным количеством рыбы
      String bestMonthKey = '';
      int maxFishCount = 0;

      fishCountByMonth.forEach((key, count) {
        if (count > maxFishCount) {
          maxFishCount = count;
          bestMonthKey = key;
        }
      });

      if (bestMonthKey.isNotEmpty) {
        final parts = bestMonthKey.split('-');
        bestMonth = BestMonthInfo(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          fishCount: maxFishCount,
        );
      }
    }

    // Обновляем статистику
    _statistics = FishingStatistics(
      totalTrips: totalTrips,
      longestTripDays: longestTripDays,
      totalDaysOnFishing: totalDaysOnFishing,
      totalFish: totalFish,
      biggestFish: biggestFish,
      latestTrip: latestTrip,
      bestMonth: bestMonth,
    );
  }
}