// Путь: lib/screens/calendar/fishing_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../localization/app_localizations.dart';
import '../fishing_note/fishing_note_detail_screen.dart';
import '../fishing_note/add_fishing_note_screen.dart';
import '../../services/calendar_event_service.dart';
import '../tournaments/tournament_detail_screen.dart';
import '../../services/tournament_service.dart';

class FishingCalendarScreen extends StatefulWidget {
  const FishingCalendarScreen({super.key});

  @override
  State<FishingCalendarScreen> createState() => _FishingCalendarScreenState();
}

class _FishingCalendarScreenState extends State<FishingCalendarScreen>
    with SingleTickerProviderStateMixin {
  final _fishingNoteRepository = FishingNoteRepository();
  final CalendarEventService _calendarEventService = CalendarEventService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Изменено: сделал final, так как карта только инициализируется один раз
  final Map<DateTime, List<FishingNoteModel>> _fishingEvents = {};
  List<CalendarEvent> _calendarEvents = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Цвета для разных состояний
  final Color _pastFishingColor = const Color(
    0xFF2E7D32,
  ); // Зеленый для прошедших
  final Color _futureFishingColor = const Color(
    0xFFFF8F00,
  ); // Оранжевый для запланированных
  final Color _tournamentColor = Colors.blue; // Синий для турниров

  @override
  void initState() {
    super.initState();

    // Настройка анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadFishingNotes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFishingNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      final events = await _calendarEventService.getCalendarEvents();
      _calendarEvents = events;
      _processNotesForCalendar(notes);

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading')}: $e',
            ),
          ),
        );
      }
    }
  }

  void _processNotesForCalendar(List<FishingNoteModel> notes) {
    _fishingEvents.clear();

    for (var note in notes) {
      // Если рыбалка однодневная
      if (!note.isMultiDay) {
        final dateKey = DateTime(
          note.date.year,
          note.date.month,
          note.date.day,
        );
        _fishingEvents[dateKey] = _fishingEvents[dateKey] ?? [];
        _fishingEvents[dateKey]!.add(note);
      } else {
        // Если рыбалка многодневная - ИСПРАВЛЕНО
        DateTime startDate = DateTime(
          note.date.year,
          note.date.month,
          note.date.day,
        );
        DateTime endDate =
        note.endDate != null
            ? DateTime(
          note.endDate!.year,
          note.endDate!.month,
          note.endDate!.day,
        )
            : startDate;

        // ИСПРАВЛЕННАЯ ЛОГИКА: используем количество дней между датами
        int totalDays =
            endDate.difference(startDate).inDays +
                1; // +1 чтобы включить последний день

        for (int i = 0; i < totalDays; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dateKey = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          );

          _fishingEvents[dateKey] = _fishingEvents[dateKey] ?? [];
          _fishingEvents[dateKey]!.add(note);

          // Отладочная информация
          debugPrint(
            'Добавлена дата в календарь: ${dateKey.day}.${dateKey.month}.${dateKey.year} для заметки: ${note.title.isNotEmpty ? note.title : note.location}',
          );
        }
      }
    }
  }

  List<FishingNoteModel> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _fishingEvents[dateKey] ?? [];
  }

  List<CalendarEvent> _getCalendarEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _calendarEvents.where((event) {
      final eventStartDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final eventEndDate = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );

      return dateKey.isAtSameMomentAs(eventStartDate) ||
          dateKey.isAtSameMomentAs(eventEndDate) ||
          (dateKey.isAfter(eventStartDate) && dateKey.isBefore(eventEndDate));
    }).toList();
  }

  bool _isPastFishing(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  // Обновленный метод для планирования рыбалки с передачей выбранной даты
  void _planNewFishing() async {
    // Используем выбранную дату или текущую, если дата не выбрана
    final selectedDate = _selectedDay ?? DateTime.now();

    // Переходим сразу на экран создания заметки с выбранным типом и датой
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddFishingNoteScreen(
          fishingType:
          AppConstants
              .fishingTypes
              .first, // Используем первый тип по умолчанию
          initialDate: selectedDate, // Передаем выбранную дату
        ),
      ),
    );

    if (result == true) {
      _loadFishingNotes();
    }
  }

  // Обновленный метод для планирования рыбалки с конкретной датой
  void _planNewFishingForDate(DateTime date) async {
    // Переходим сразу на экран создания заметки с выбранной датой
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddFishingNoteScreen(
          fishingType:
          AppConstants
              .fishingTypes
              .first, // Используем первый тип по умолчанию
          initialDate: date, // Передаем конкретную дату
        ),
      ),
    );

    if (result == true) {
      _loadFishingNotes();
    }
  }

  void _viewNoteDetails(FishingNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingNoteDetailScreen(noteId: note.id),
      ),
    ).then((value) {
      if (value == true) {
        _loadFishingNotes();
      }
    });
  }

  // НОВЫЙ МЕТОД: для просмотра деталей турнира
  void _viewTournamentDetails(CalendarEvent event) async {
    try {
      // Получаем полную информацию о турнире из сервиса турниров
      final tournamentService = TournamentService();
      final tournament = tournamentService.getTournamentById(event.sourceId ?? event.id);

      if (tournament != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailScreen(tournament: tournament),
          ),
        );

        // Если турнир был удален из календаря, обновляем наш календарь
        if (result == true) {
          _loadFishingNotes();
        }
      } else {
        // Если турнир не найден, показываем сообщение об ошибке
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('tournament_not_found'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Добавляем метод для быстрого выбора месяца и года
  void _showMonthYearPicker() async {
    final localizations = AppLocalizations.of(context);
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = _focusedDay.year;
        int selectedMonth = _focusedDay.month;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                localizations.translate('select_date_to_view'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Выбор года
                  DropdownButton<int>(
                    value: selectedYear,
                    dropdownColor: AppConstants.cardColor,
                    style: TextStyle(color: AppConstants.textColor),
                    items:
                    List.generate(11, (index) => 2020 + index)
                        .map(
                          (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Выбор месяца
                  DropdownButton<int>(
                    value: selectedMonth,
                    dropdownColor: AppConstants.cardColor,
                    style: TextStyle(color: AppConstants.textColor),
                    items:
                    List.generate(12, (index) => index + 1)
                        .map(
                          (month) => DropdownMenuItem(
                        value: month,
                        child: Text(
                          localizations.translate(_getMonthKey(month)),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.translate('cancel'),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: Text(localizations.translate('continue')),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _focusedDay = selectedDate;
      });
    }
  }

  String _getMonthKey(int month) {
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
    return monthKeys[month];
  }

  String _getTitleText() {
    final localizations = AppLocalizations.of(context);
    final monthKey = _getMonthKey(_focusedDay.month);
    return '${localizations.translate(monthKey)} ${_focusedDay.year}';
  }

  // Метод для перевода дней недели
  String _getDayOfWeekText(int weekday, {bool short = false}) {
    final localizations = AppLocalizations.of(context);
    final isEnglish = localizations.locale.languageCode == 'en';

    if (short) {
      // Короткие названия для маленьких экранов
      if (isEnglish) {
        switch (weekday) {
          case DateTime.monday:
            return 'Mo';
          case DateTime.tuesday:
            return 'Tu';
          case DateTime.wednesday:
            return 'We';
          case DateTime.thursday:
            return 'Th';
          case DateTime.friday:
            return 'Fr';
          case DateTime.saturday:
            return 'Sa';
          case DateTime.sunday:
            return 'Su';
          default:
            return '';
        }
      } else {
        switch (weekday) {
          case DateTime.monday:
            return 'Пн';
          case DateTime.tuesday:
            return 'Вт';
          case DateTime.wednesday:
            return 'Ср';
          case DateTime.thursday:
            return 'Чт';
          case DateTime.friday:
            return 'Пт';
          case DateTime.saturday:
            return 'Сб';
          case DateTime.sunday:
            return 'Вс';
          default:
            return '';
        }
      }
    } else {
      // Полные названия
      if (isEnglish) {
        switch (weekday) {
          case DateTime.monday:
            return 'Mon';
          case DateTime.tuesday:
            return 'Tue';
          case DateTime.wednesday:
            return 'Wed';
          case DateTime.thursday:
            return 'Thu';
          case DateTime.friday:
            return 'Fri';
          case DateTime.saturday:
            return 'Sat';
          case DateTime.sunday:
            return 'Sun';
          default:
            return '';
        }
      } else {
        switch (weekday) {
          case DateTime.monday:
            return 'Пн';
          case DateTime.tuesday:
            return 'Вт';
          case DateTime.wednesday:
            return 'Ср';
          case DateTime.thursday:
            return 'Чт';
          case DateTime.friday:
            return 'Пт';
          case DateTime.saturday:
            return 'Сб';
          case DateTime.sunday:
            return 'Вс';
          default:
            return '';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('fishing_calendar'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppConstants.textColor),
            tooltip: localizations.translate('plan_fishing'),
            onPressed: _planNewFishing,
          ),
        ],
      ),
      body:
      _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppConstants.textColor,
          ),
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildCalendarHeader(),
            _buildCalendar(),
            const SizedBox(height: 16),
            _buildEventsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLegendItem(
                localizations.translate('past'),
                _pastFishingColor,
              ),
              const SizedBox(width: 12),
              _buildLegendItem(
                localizations.translate('planned'),
                _futureFishingColor,
              ),
              const SizedBox(width: 12),
              _buildLegendItem(
                localizations.translate('tournaments'),
                _tournamentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<FishingNoteModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        // Убираем locale отсюда, так как будем переводить вручную
        rowHeight: 52,
        daysOfWeekHeight: 40,
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: AppConstants.textColor),
          weekendTextStyle: TextStyle(color: AppConstants.textColor),
          selectedTextStyle: const TextStyle(color: Colors.white),
          todayTextStyle: const TextStyle(color: Colors.white),
          outsideTextStyle: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.3),
          ),
          defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
          weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextFormatter: (date, locale) => _getTitleText(),
          titleTextStyle: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppConstants.textColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppConstants.textColor,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          weekendStyle: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppConstants.textColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            return _buildDayOfWeekWidget(day);
          },
          headerTitleBuilder: (context, date) {
            return InkWell(
              onTap: _showMonthYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getTitleText(),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, color: AppConstants.textColor),
                  ],
                ),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            final fishingEvents = _getEventsForDay(day);
            final calendarEvents = _getCalendarEventsForDay(day);

            if (fishingEvents.isEmpty && calendarEvents.isEmpty) return null;

            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (fishingEvents.isNotEmpty)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color:
                        _isPastFishing(day)
                            ? _pastFishingColor
                            : _futureFishingColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (calendarEvents.isNotEmpty)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _tournamentColor, // Цвет для турниров
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildDayOfWeekWidget(DateTime day) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Используем наш метод перевода
    String text;
    if (screenWidth < 320) {
      text = _getDayOfWeekText(day.weekday, short: true);
    } else {
      text = _getDayOfWeekText(day.weekday);
    }

    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return Container(
      height: 35,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color:
          isWeekend
              ? AppConstants.textColor.withValues(alpha: 0.9)
              : AppConstants.textColor.withValues(alpha: 0.7),
          fontSize: 14.0,
          fontWeight: isWeekend ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final localizations = AppLocalizations.of(context);
    final eventsForDay =
    _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    final calendarEventsForDay =
    _selectedDay != null ? _getCalendarEventsForDay(_selectedDay!) : [];

    if (eventsForDay.isEmpty && calendarEventsForDay.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppConstants.textColor.withValues(alpha: 0.3),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedDay != null
                    ? localizations.translate('no_fishing_on_date')
                    : localizations.translate('select_date_to_view'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              if (_selectedDay != null &&
                  _selectedDay!.isAfter(DateTime.now())) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _planNewFishingForDate(_selectedDay!),
                  icon: const Icon(Icons.add),
                  label: Text(localizations.translate('plan_fishing_for_date')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // Рыбалки
          ...eventsForDay.map((note) => _buildEventCard(note)),

          // Турниры
          ...calendarEventsForDay.map(
                (event) => _buildTournamentEventCard(event),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);
    final isPast = _isPastFishing(note.date);
    final statusColor = isPast ? _pastFishingColor : _futureFishingColor;
    final statusText =
    isPast
        ? localizations.translate('past')
        : localizations.translate('planned');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewNoteDetails(note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.location,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.isMultiDay
                    ? DateFormatter.formatDateRange(
                  note.date,
                  note.endDate!,
                  context,
                )
                    : DateFormatter.formatDate(note.date, context),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.water,
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    localizations.translate(
                      note.fishingType,
                    ), // ИСПРАВЛЕНО: добавлен перевод
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (isPast && note.biteRecords.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.set_meal,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.biteRecords.length} ${DateFormatter.getFishText(note.biteRecords.length, context)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              if (note.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentEventCard(CalendarEvent event) {
    final localizations = AppLocalizations.of(context);
    final isPast = event.endDate.isBefore(DateTime.now());
    final statusColor = _tournamentColor;
    final statusText = isPast
        ? localizations.translate('completed')
        : localizations.translate('tournament');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewTournamentDetails(event), // ДОБАВЛЕНО: обычное нажатие
        onLongPress: () => _showTournamentEventOptions(context, event, localizations), // Оставляем длинное нажатие для удаления
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.location != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              if (event.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // ОБНОВЛЕНО: изменили текст подсказки
              Text(
                localizations.translate('tap_for_details'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Новый метод для показа опций турнира
  void _showTournamentEventOptions(
      BuildContext context,
      CalendarEvent event,
      AppLocalizations localizations,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                event.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Кнопка просмотра деталей
              ListTile(
                leading: Icon(Icons.info, color: AppConstants.primaryColor),
                title: Text(
                  localizations.translate('view_details'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewTournamentDetails(event);
                },
              ),

              // Кнопка удаления из календаря
              ListTile(
                leading: Icon(Icons.event_busy, color: Colors.red),
                title: Text(
                  localizations.translate('remove_from_calendar'),
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeTournamentFromCalendar(context, event, localizations);
                },
              ),

              const SizedBox(height: 8),

              // Кнопка отмены
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.translate('cancel'),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Метод для удаления турнира из календаря
  void _removeTournamentFromCalendar(
      BuildContext context,
      CalendarEvent event,
      AppLocalizations localizations,
      ) async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('remove_from_calendar'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        content: Text(
          localizations.translate('remove_tournament_confirmation'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.translate('remove'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarEventService.removeEvent(event.id);

        // Обновляем список событий
        await _loadFishingNotes();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('tournament_removed_from_calendar'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error_loading')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}