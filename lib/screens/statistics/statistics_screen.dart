// Путь: lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  String _selectedPeriod = 'Месяц';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = true;
  List<FishingNoteModel> _filteredNotes = [];
  List<FishingNoteModel> _allNotes = [];

  // Обновленные периоды для фильтрации
  final List<String> _periods = ['Неделя', 'Месяц', 'Год', 'Все время', 'Период'];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      // Фильтруем только прошедшие и текущие заметки
      final now = DateTime.now();
      final validNotes = notes.where((note) =>
      note.date.isBefore(now) || note.date.isAtSameMomentAs(now)
      ).toList();

      setState(() {
        _allNotes = validNotes;
        _filterNotes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  void _filterNotes() {
    final now = DateTime.now();
    List<FishingNoteModel> filtered = List.from(_allNotes);

    switch (_selectedPeriod) {
      case 'Неделя':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((note) => note.date.isAfter(weekAgo)).toList();
        break;
      case 'Месяц':
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = filtered.where((note) => note.date.isAfter(monthAgo)).toList();
        break;
      case 'Год':
        final yearAgo = now.subtract(const Duration(days: 365));
        filtered = filtered.where((note) => note.date.isAfter(yearAgo)).toList();
        break;
      case 'Период':
        if (_customStartDate != null && _customEndDate != null) {
          filtered = filtered.where((note) {
            final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
            final startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
            final endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day);
            return !noteDate.isBefore(startDate) && !noteDate.isAfter(endDate);
          }).toList();
        }
        break;
      case 'Все время':
      // Показываем все заметки без фильтрации
        break;
    }

    setState(() {
      _filteredNotes = filtered;
    });
  }

  // Расчет статистики
  Map<String, dynamic> _calculateStatistics() {
    final stats = <String, dynamic>{};

    // 1. Всего рыбалок
    stats['totalTrips'] = _filteredNotes.length;

    // 2. Самая долгая рыбалка
    int longestTrip = 0;
    String longestTripName = '';
    for (var note in _filteredNotes) {
      if (note.isMultiDay && note.endDate != null) {
        int days = note.endDate!.difference(note.date).inDays + 1;
        if (days > longestTrip) {
          longestTrip = days;
          longestTripName = note.title.isNotEmpty ? note.title : note.location;
        }
      } else {
        if (longestTrip == 0) longestTrip = 1;
      }
    }
    stats['longestTrip'] = longestTrip;
    stats['longestTripName'] = longestTripName;

    // 3. Всего дней на рыбалке
    Set<DateTime> uniqueFishingDays = {};
    for (var note in _filteredNotes) {
      DateTime startDate = DateTime(note.date.year, note.date.month, note.date.day);
      DateTime endDate = note.endDate != null
          ? DateTime(note.endDate!.year, note.endDate!.month, note.endDate!.day)
          : startDate;

      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        uniqueFishingDays.add(startDate.add(Duration(days: i)));
      }
    }
    stats['totalDaysFishing'] = uniqueFishingDays.length;

    // 4. Всего поймано рыб
    int totalFish = 0;
    for (var note in _filteredNotes) {
      totalFish += note.biteRecords.length;
    }
    stats['totalFish'] = totalFish;

    // 5. Самая большая рыба
    BiteRecord? biggestFish;
    String biggestFishLocation = '';
    for (var note in _filteredNotes) {
      for (var record in note.biteRecords) {
        if (biggestFish == null || record.weight > biggestFish.weight) {
          biggestFish = record;
          biggestFishLocation = note.location;
        }
      }
    }
    stats['biggestFish'] = biggestFish;
    stats['biggestFishLocation'] = biggestFishLocation;

    // 6. Последний выезд
    FishingNoteModel? lastTrip;
    if (_filteredNotes.isNotEmpty) {
      lastTrip = _filteredNotes.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    }
    stats['lastTrip'] = lastTrip;

    // 7. Лучший месяц по количеству рыбы
    Map<String, int> fishByMonth = {};
    for (var note in _filteredNotes) {
      for (var record in note.biteRecords) {
        String monthKey = DateFormat('MMMM yyyy', 'ru').format(record.time);
        fishByMonth[monthKey] = (fishByMonth[monthKey] ?? 0) + 1;
      }
    }

    String bestMonth = '';
    int bestMonthFish = 0;
    fishByMonth.forEach((month, count) {
      if (count > bestMonthFish) {
        bestMonthFish = count;
        bestMonth = month;
      }
    });
    stats['bestMonth'] = bestMonth;
    stats['bestMonthFish'] = bestMonthFish;

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        title: Text(
          'Статистика',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фильтр периода
            _buildPeriodFilter(),
            const SizedBox(height: 24),

            // Статистические карточки
            _buildStatCard(
              icon: Icons.format_list_bulleted,
              title: 'Всего рыбалок',
              value: stats['totalTrips'].toString(),
              subtitle: DateFormatter.getFishingTripsText(stats['totalTrips']),
            ),

            const SizedBox(height: 16),

            _buildStatCard(
              icon: Icons.access_time,
              title: 'Самая долгая',
              value: stats['longestTrip'].toString(),
              subtitle: DateFormatter.getDaysText(stats['longestTrip']),
            ),

            const SizedBox(height: 16),

            _buildStatCard(
              icon: Icons.calendar_today,
              title: 'Всего дней на рыбалке',
              value: stats['totalDaysFishing'].toString(),
              subtitle: 'дней на рыбалке',
            ),

            const SizedBox(height: 16),

            _buildStatCard(
              icon: Icons.set_meal,
              title: 'Всего поймано рыб',
              value: stats['totalFish'].toString(),
              subtitle: DateFormatter.getFishText(stats['totalFish']),
            ),

            const SizedBox(height: 16),

            if (stats['biggestFish'] != null)
              _buildStatCard(
                icon: Icons.emoji_events,
                title: 'Самая большая рыба',
                value: '${stats['biggestFish'].weight} кг',
                subtitle: '${stats['biggestFish'].fishType}, ${DateFormat('d MMMM yyyy', 'ru').format(stats['biggestFish'].time)}',
                valueColor: Colors.amber,
              ),

            const SizedBox(height: 16),

            if (stats['lastTrip'] != null)
              _buildStatCard(
                icon: Icons.directions_car,
                title: 'Последний выезд',
                value: stats['lastTrip'].title.isNotEmpty
                    ? '«${stats['lastTrip'].title}»'
                    : stats['lastTrip'].location,
                subtitle: DateFormat('d MMMM yyyy', 'ru').format(stats['lastTrip'].date),
              ),

            const SizedBox(height: 16),

            if (stats['bestMonth'].isNotEmpty)
              _buildStatCard(
                icon: Icons.star,
                title: 'Лучший месяц',
                value: stats['bestMonth'],
                subtitle: '${stats['bestMonthFish']} ${DateFormatter.getFishText(stats['bestMonthFish'])}',
                valueColor: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: _selectedPeriod == period,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                            if (period == 'Период') {
                              _selectDateRange();
                            } else {
                              _filterNotes();
                            }
                          });
                        }
                      },
                      selectedColor: AppConstants.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedPeriod == period
                            ? AppConstants.textColor
                            : AppConstants.textColor.withOpacity(0.7),
                      ),
                      backgroundColor: AppConstants.surfaceColor,
                    ),
                  ),
              ).toList(),
            ),
          ),
          if (_selectedPeriod == 'Период' && _customStartDate != null && _customEndDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${DateFormat('dd.MM.yyyy').format(_customStartDate!)} - ${DateFormat('dd.MM.yyyy').format(_customEndDate!)}',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _filterNotes();
      });
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: valueColor ?? AppConstants.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}